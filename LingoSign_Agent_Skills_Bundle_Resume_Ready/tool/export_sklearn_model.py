"""Export the supplied sklearn artifacts for offline Dart inference.

Only run this with model files from a trusted source: joblib.load executes pickle.
No model fitting or training takes place here.
"""

import hashlib
import json
import struct
from pathlib import Path

import joblib
import numpy as np


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "model"
DEST = Path(__file__).resolve().parents[1] / "assets" / "model"
FIXTURES = Path(__file__).resolve().parents[1] / "test" / "fixtures"


def digest(path: Path) -> str:
    sha = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            sha.update(chunk)
    return sha.hexdigest()


def main() -> None:
    params_path = SOURCE / "chuan_hoa_params.json"
    pca_path = SOURCE / "pca_model.pkl"
    rf_path = SOURCE / "rf_model.pkl"
    params = json.loads(params_path.read_text(encoding="utf-8"))
    pca = joblib.load(pca_path)
    forest = joblib.load(rf_path)

    assert len(params["mean"]) == len(params["std"]) == 42
    assert pca.components_.shape == (16, 42)
    assert pca.mean_.shape == (42,)
    assert forest.n_features_in_ == 16
    labels = forest.classes_.tolist()
    class_count = len(labels)
    assert class_count == 29

    DEST.mkdir(parents=True, exist_ok=True)
    metadata = {
        "format_version": 1,
        "labels": labels,
        "standardizer_mean": params["mean"],
        "standardizer_std": params["std"],
        "pca_mean": pca.mean_.tolist(),
        "pca_components": pca.components_.tolist(),
        "source_sha256": {
            "chuan_hoa_params.json": digest(params_path),
            "pca_model.pkl": digest(pca_path),
            "rf_model.pkl": digest(rf_path),
        },
    }
    (DEST / "model.json").write_text(
        json.dumps(metadata, separators=(",", ":")), encoding="utf-8"
    )

    with (DEST / "forest.bin").open("wb") as out:
        out.write(struct.pack("<4sIIII", b"LSRF", 1, 16, class_count, len(forest.estimators_)))
        for estimator in forest.estimators_:
            tree = estimator.tree_
            leaves = np.flatnonzero(tree.children_left == -1)
            leaf_ids = {int(node): index for index, node in enumerate(leaves)}
            out.write(struct.pack("<II", tree.node_count, len(leaves)))
            for node in range(tree.node_count):
                if node in leaf_ids:
                    out.write(struct.pack("<iiid", leaf_ids[node], -1, -1, 0.0))
                else:
                    out.write(
                        struct.pack(
                            "<iiid",
                            int(tree.children_left[node]),
                            int(tree.children_right[node]),
                            int(tree.feature[node]),
                            float(tree.threshold[node]),
                        )
                    )
            for node in leaves:
                probabilities = tree.value[node, 0]
                probabilities = probabilities / probabilities.sum()
                out.write(struct.pack(f"<{class_count}f", *probabilities))

    mean = np.asarray(params["mean"])
    std = np.asarray(params["std"])
    generator = np.random.default_rng(42)
    vectors = [mean, mean + std * 0.5, mean - std * 0.25]
    vectors.extend(mean + std * offsets for offsets in generator.normal(size=(32, 42)))
    standardized = np.stack([(row - mean) / std for row in vectors])
    projected = pca.transform(standardized)
    probabilities = forest.predict_proba(projected)
    fixture = {
        "description": "Synthetic vectors for parity only; not accuracy evidence.",
        "cases": [
            {"features": row.tolist(), "probabilities": scores.tolist()}
            for row, scores in zip(vectors, probabilities)
        ],
    }
    FIXTURES.mkdir(parents=True, exist_ok=True)
    (FIXTURES / "model_parity_vectors.json").write_text(
        json.dumps(fixture, separators=(",", ":")), encoding="utf-8"
    )
    print(f"Exported {len(forest.estimators_)} trees, {class_count} labels")
    print(f"forest.bin: {(DEST / 'forest.bin').stat().st_size} bytes")


if __name__ == "__main__":
    main()
