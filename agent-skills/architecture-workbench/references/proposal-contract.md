# Proposed change and approval contract

Architecture proposals live under `docs/architecture-workbench/proposed/<proposal-id>/`. They never
change `current/` merely by existing or by being rendered. Each bundle contains:

- `proposal.md`: stable proposal/feedback identity, exact base commit, summary, and typed file set.
- `snapshot/*.md`: the complete To-Be architecture documents, with `status: proposed`.
- `files/*`: reviewable replacement files referenced by `proposal.md`.

The `# Files` table has `targetPath`, bundle-relative `proposedPath`, the target's exact
`expectedSHA256`, and a `role` of `code`, `current-markdown`, or `test`. Paths must be repository
relative and cannot traverse the repository or enter `.git`. Any proposal that changes code must
include current Markdown in the same atomic apply set.

Run proposal validation and preview without mutating source:

```bash
python3 agent-skills/architecture-workbench/scripts/proposal_workbench.py validate --root . --proposal docs/architecture-workbench/proposed/<id>/proposal.md
python3 agent-skills/architecture-workbench/scripts/proposal_workbench.py preview --root . --proposal docs/architecture-workbench/proposed/<id>/proposal.md
```

The preview compares stable node, relationship, hierarchy, and trace identities and renders
As-Is, To-Be, and Diff in the generated explorer.

## Approval gate

Feedback and a proposal are not approval. After a person explicitly approves the exact proposal in
the current Agent turn, record a separate JSON approval with exactly these fields:

```json
{
  "schemaVersion": "1",
  "proposalId": "proposal.example",
  "proposalDigest": "<sha256 emitted by preview>",
  "baseGitCommit": "<exact proposal base SHA>",
  "approvedInCurrentTurn": true,
  "approvedAt": "2026-08-11T00:00:00Z",
  "approvalNote": "Exact user approval from the current turn.",
  "turnNonceHash": "<sha256 of a fresh non-committed 32+ character turn nonce>"
}
```

`apply` rejects a missing or older-than-30-minutes approval, a missing/mismatched transient turn nonce,
mismatched digest/base/identity, drifted target, or incomplete
code/current set. It stages every replacement before switching targets and restores already-written
targets if a filesystem write fails. Approval files are execution evidence, not canonical architecture,
and should not be committed unless repository policy explicitly requires it.

```bash
python3 agent-skills/architecture-workbench/scripts/proposal_workbench.py apply --root . --proposal <proposal.md> --approval <approval.json> --turn-nonce-file <uncommitted-nonce-file>
python3 agent-skills/architecture-workbench/scripts/proposal_workbench.py reconcile --root . --proposal <proposal.md>
```

Reconcile reports implemented only when every declared target equals its proposed file and the
resulting current Markdown validates. A partial or later-diverged result stays unimplemented.
