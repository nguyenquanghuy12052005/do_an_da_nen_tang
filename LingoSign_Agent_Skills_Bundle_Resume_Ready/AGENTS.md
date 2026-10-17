# AGENTS.md — Codex rules for LingoSign AI

## Automatic skills and task orchestration

- At session start, read `SKILLS_AGENT_RUNBOOK.md` together with this file and `PLAN.md`. Treat the runbook as the skills inventory, installation and task-selection guide; this file and `PLAN.md` override third-party skill guidance.
- Inspect installed skills; do not claim a skill is installed without confirming it. Load only the relevant `SKILL.md` for the current TASK ID; do not preload every skill.
- Choose the next dependency-ready task from `PLAN.md` automatically. Implement **one task at a time**, verify its acceptance evidence, update `docs/agent/PROGRESS.md`, then select the next unblocked task if the session and permissions allow.
- Never bypass installation/permission approvals, invent model artifacts or benchmark data, or claim real-device/release tests happened when they did not. Stop at credentials, destructive operations, publishing, or missing hardware/model blockers.

## Mandatory session checkpoints and recovery (NON-NEGOTIABLE)

**Persistent handoff file:** `docs/agent/PROGRESS.md` is the current, resumable state; `PLAN.md` is the scope/acceptance checklist, **not** a substitute for a handoff. Create `docs/agent/PROGRESS.md` at the start of the first coding session if missing, using the template and procedure in `SKILLS_AGENT_RUNBOOK.md` §7.5. Do not assume this file exists or contains verified facts before checking.

- **On every new session or context reset:** read `docs/agent/PROGRESS.md` **before selecting a task**, then read `AGENTS.md`, the relevant `PLAN.md` section, and `SKILLS_AGENT_RUNBOOK.md`; inspect `git status --short`, diff, pertinent files, and the actual test state. A handoff is a navigation aid, not evidence: reconcile discrepancies with the repository. Continue the saved `IN_PROGRESS`/`NEEDS_VERIFY` task before starting an unrelated task, unless blocked or superseded by explicit instructions.
- **Checkpoint early and often:** write/update `docs/agent/PROGRESS.md` when a task starts, after each meaningful implementation/test milestone, on task completion, after encountering a blocker, and **before intentionally stopping, handing control back to the user, switching agents/models, or approaching context/token limits**. Make an extra checkpoint before high-risk edits. A user stop may occur without warning, so never rely solely on an end-of-session update.
- Each checkpoint must state: timestamp/timezone, TASK ID and status (`NOT_STARTED`, `IN_PROGRESS`, `NEEDS_VERIFY`, `BLOCKED`, `DONE`), what is verified finished vs partially implemented, paths modified, relevant branch/commit and **uncommitted** work, commands/tests **actually** run with results, errors/blockers, precise next 1–3 actions, and required prerequisites/skills. Include file locations and exact commands to resume; write **NOT_RUN/NOT_VERIFIED/UNKNOWN** instead of guessing. Keep the newest snapshot near the top and a short append-only history below.
- **Never erase or overwrite someone else's in-progress edits** merely because a checkpoint disagrees with Git. Never mark a task `DONE` or check `[x]` in `PLAN.md` until all acceptance evidence is present. Keep secrets, tokens, credentials and private camera/audio content out of progress logs.
- If a stop/context warning arrives, **prioritize writing a truthful checkpoint over starting more code**; provide a brief handoff in the final response. If a process is killed suddenly before a checkpoint can be saved, the next agent must reconstruct from Git and test evidence: a flawless handoff cannot be guaranteed.

## Always read first

1. Read `docs/agent/PROGRESS.md` first when present; reconcile its claims with actual Git/code/test state. Then read `PLAN.md` in its entirety (or the relevant sections plus dependent tasks).
2. Inspect the current project, changes (`git status`, diff) and dependency versions before edits.
3. Implement **one TASK ID at a time**. Do not add features beyond task scope without a clear dependency and a short explanation.

## Non-negotiable architecture

- Flutter + Dart; Material 3; Riverpod; Clean Architecture with **Domain, Data, Presentation** under features.
- **Domain is pure Dart**. Do not import Flutter, material.dart, Drift, Supabase, MediaPipe, TFLite or state management into Domain.
- Interface/ports in Domain; implementations in Data; UI and providers in Presentation; DI at composition root.
- UI reads application data from local SQLite/Drift via repositories. Do not make Widgets depend directly on Supabase, SQLite or TFLite interpreters.
- Avoid God Widgets, gigantic providers, global mutable state and duplicating the same business rule across layers.

## AI and safety of claims

- Inspect `docs/research/model_contract.md` or model metadata before adding inference. Do not assume a 21-landmark model if the artifact expects RGB or a time sequence.
- MediaPipe hand landmarks are geometric data, not sign-language translation by themselves.
- Do not fake model output, confidence, evaluation metrics, time measurements or experimental results.
- If needed assets/model are missing, implement testable interfaces/fixtures clearly marked **mock** and report the blocker. Do not claim the end-to-end feature is done.
- Camera frames remain on-device by default; do not transmit raw audio/video to a cloud endpoint.
- Handle permissions, camera lifecycle, unknown classes, backpressure and resource disposal.

## Offline-first and privacy

- SQLite/Drift is the source of truth for UI. Local transaction + outbox first, sync later when online.
- Use idempotency keys, retry/backoff, tombstones or a documented equivalent; preserve local data through process death/reconnect.
- Do not embed Supabase service-role keys, release signing keys or API credentials in source control.
- All per-user Supabase tables require RLS with tests preventing cross-user reads and writes.
- Guest mode must not be blocked by sign-in. Sync history only with user opt-in.

## Code quality and definition of done

- Prefer small focused changes; do not rewrite unrelated files.
- For every new use case/business rule, add unit tests. For new UI states, add widget tests. For native camera/ML, state manual device validation steps.
- Run `dart format`, `flutter analyze`, and `flutter test` when tooling is available. Report exact results; never claim tests ran if they did not.
- Avoid adding packages merely for convenience; check documented and compatible versions.
- Explain changed files, key decisions, tests, warnings/blockers and smallest next task.
- Mark checklist item `[x]` in `PLAN.md` **only after acceptance criteria and evidence are satisfied**.
- Android release signing only via CI secrets or local ignored configuration; never check in keystore or passwords.

## Task response template

```
TASK ID:
Summary:
Files changed:
Architecture decisions:
Tests run and results:
Manual device checks still needed:
Known blockers/risks:
PLAN.md checklist updated? Why:
Next smallest task:
Checkpoint saved at (`docs/agent/PROGRESS.md`):
Resume from (concrete next action):
```
