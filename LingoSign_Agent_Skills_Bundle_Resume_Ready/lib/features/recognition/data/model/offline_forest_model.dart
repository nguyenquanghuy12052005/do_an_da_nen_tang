import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import 'landmark_standardizer.dart';

/// Portable inference for the supplied sklearn PCA and Random Forest.
/// The exporter owns the binary format; this class never reads a pickle.
class OfflineForestModel {
  OfflineForestModel._(
    this._standardizer,
    this._pcaMean,
    this._components,
    this.labels,
    this._binary,
    this._trees,
  );

  final LandmarkStandardizer _standardizer;
  final List<double> _pcaMean;
  final List<List<double>> _components;
  final List<String> labels;
  final ByteData _binary;
  final List<_Tree> _trees;

  static Future<OfflineForestModel> load({AssetBundle? bundle}) async {
    final assets = bundle ?? rootBundle;
    final metadata = jsonDecode(
      await assets.loadString('assets/model/model.json'),
    ) as Map<String, dynamic>;
    final binary = await assets.load('assets/model/forest.bin');
    return OfflineForestModel.fromData(metadata, binary);
  }

  /// Exposed for deterministic parity tests without camera or platform APIs.
  factory OfflineForestModel.fromData(
    Map<String, dynamic> metadata,
    ByteData binary,
  ) {
    if (metadata['format_version'] != 1 || binary.lengthInBytes < 20) {
      throw const FormatException('Unsupported model format');
    }
    final labels = List<String>.unmodifiable(
      (metadata['labels'] as List).cast<String>(),
    );
    final mean = _numbers(metadata['standardizer_mean']);
    final std = _numbers(metadata['standardizer_std']);
    final pcaMean = _numbers(metadata['pca_mean']);
    final components = List<List<double>>.unmodifiable(
      (metadata['pca_components'] as List).map(_numbers),
    );
    final standardizer = LandmarkStandardizer(mean: mean, std: std);
    if (pcaMean.length != 42 ||
        components.isEmpty ||
        components.any((row) => row.length != 42) ||
        pcaMean.any((value) => !value.isFinite) ||
        components.expand((row) => row).any((value) => !value.isFinite)) {
      throw const FormatException('Invalid PCA metadata');
    }
    if (binary.getUint32(0, Endian.little) != 0x4652534c ||
        binary.getUint32(4, Endian.little) != 1 ||
        binary.getUint32(8, Endian.little) != components.length ||
        binary.getUint32(12, Endian.little) != labels.length ||
        labels.isEmpty) {
      throw const FormatException('Model binary/metadata mismatch');
    }
    final treeCount = binary.getUint32(16, Endian.little);
    if (treeCount == 0) throw const FormatException('Empty forest');
    var offset = 20;
    final trees = <_Tree>[];
    for (var treeIndex = 0; treeIndex < treeCount; treeIndex++) {
      if (offset + 8 > binary.lengthInBytes) {
        throw const FormatException('Truncated forest header');
      }
      final nodeCount = binary.getUint32(offset, Endian.little);
      final leafCount = binary.getUint32(offset + 4, Endian.little);
      offset += 8;
      final leafOffset = offset + nodeCount * 20;
      final end = leafOffset + leafCount * labels.length * 4;
      if (nodeCount == 0 || leafCount == 0 || end > binary.lengthInBytes) {
        throw const FormatException('Invalid forest tree size');
      }
      trees.add(_Tree(offset, nodeCount, leafOffset, leafCount));
      offset = end;
    }
    if (offset != binary.lengthInBytes) {
      throw const FormatException('Trailing forest data');
    }
    return OfflineForestModel._(
      standardizer,
      pcaMean,
      components,
      labels,
      binary,
      List<_Tree>.unmodifiable(trees),
    );
  }

  static List<double> _numbers(Object? value) => List<double>.unmodifiable(
    (value as List).map((number) => (number as num).toDouble()),
  );

  ModelPrediction predict(List<double> features) {
    final standardized = _standardizer.transform(features);
    final projected = Float32List(_components.length);
    for (var component = 0; component < _components.length; component++) {
      var value = 0.0;
      for (var feature = 0; feature < 42; feature++) {
        value +=
            (standardized[feature] - _pcaMean[feature]) *
            _components[component][feature];
      }
      projected[component] = value;
    }

    final probabilities = List<double>.filled(labels.length, 0);
    for (final tree in _trees) {
      var node = 0;
      while (true) {
        if (node < 0 || node >= tree.nodeCount) {
          throw const FormatException('Invalid forest child index');
        }
        final offset = tree.nodeOffset + node * 20;
        final left = _binary.getInt32(offset, Endian.little);
        final right = _binary.getInt32(offset + 4, Endian.little);
        final feature = _binary.getInt32(offset + 8, Endian.little);
        if (feature == -1) {
          if (left < 0 || left >= tree.leafCount) {
            throw const FormatException('Invalid forest leaf index');
          }
          final leafOffset = tree.leafOffset + left * labels.length * 4;
          for (var label = 0; label < labels.length; label++) {
            probabilities[label] += _binary.getFloat32(
              leafOffset + label * 4,
              Endian.little,
            );
          }
          break;
        }
        if (feature < 0 || feature >= projected.length) {
          throw const FormatException('Invalid forest feature index');
        }
        final threshold = _binary.getFloat64(offset + 12, Endian.little);
        node = projected[feature] <= threshold ? left : right;
      }
    }
    var best = 0;
    for (var label = 0; label < labels.length; label++) {
      probabilities[label] /= _trees.length;
      if (probabilities[label] > probabilities[best]) best = label;
    }
    return ModelPrediction(
      label: labels[best],
      confidence: probabilities[best],
      probabilities: List<double>.unmodifiable(probabilities),
    );
  }
}

class _Tree {
  const _Tree(this.nodeOffset, this.nodeCount, this.leafOffset, this.leafCount);
  final int nodeOffset;
  final int nodeCount;
  final int leafOffset;
  final int leafCount;
}

class ModelPrediction {
  const ModelPrediction({
    required this.label,
    required this.confidence,
    required this.probabilities,
  });
  final String label;
  final double confidence;
  final List<double> probabilities;
}
