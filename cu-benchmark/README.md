# CU Benchmark Report

Posts a PR comment with per-instruction **Avg CU deltas vs `main`** from your program's compute-unit report, and optionally keeps a committed baseline in sync.

## Contract: what your tests must produce

A **`cu_report.md`** file with a Markdown table that has (at least) `Instruction` and `Avg CUs` columns:

```markdown
| Instruction | Avg CUs |
| ----------- | ------- |
| create_plan | 1250    |
| claim       | 1980    |

*Generated: 2026-06-08*
```

- Column order is free; extra columns (`Min CUs`, `Est Cost`, …) are passed through to the comment.
- `Avg CUs` must be a plain integer. The `Δ` is computed on it, joined by `Instruction`.
- An optional `*Generated:` line is carried into the comment footer.

**Reference implementations:**

- See how the subscriptions program does it: [`cu_tracker.rs`](https://github.com/solana-foundation/subscriptions/blob/main/tests/integration-tests/src/utils/cu_tracker.rs)
- See how the rewards program does it: [`cu_utils.rs`](https://github.com/solana-foundation/rewards/blob/main/tests/integration-tests/src/utils/cu_utils.rs)

## How it works

1. Auto-locate one `cu_report.md` (ignoring `target/`, `node_modules/`, `.git/`); baseline is its sibling `cu_baseline.md`.
2. Diff against the baseline committed on `main`, upsert a comment: `🔺 +N` · `🔻 -N` · `–` unchanged · `🆕` new · `🗑` removed. No baseline → all `🆕`.
3. If `commit-baseline` is on (and same-repo PR), commit the refreshed baseline to the **PR's head branch** — it reaches `main` via the normal merge, never a direct push. Fork PRs skip.

## Inputs

| input             | default              | notes                                                                    |
| ----------------- | -------------------- | ------------------------------------------------------------------------ |
| `report-path`     | `""` (auto-discover) | Set only if a repo emits several `cu_report.md`.                          |
| `commit-baseline` | `false`              | Opt-in baseline refresh. Needs `contents: write` + a same-repo check.    |

## Usage

```yaml
on: pull_request
permissions:
  contents: write        # only if commit-baseline is enabled
  pull-requests: write
jobs:
  compute-units:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
        with: { fetch-depth: 0 }
      - uses: ./.github/actions/setup
      - run: just test-and-benchmark        # must write cu_report.md (see contract)
      - uses: solana-foundation/github-actions/cu-benchmark@vX
        with:
          commit-baseline: ${{ github.event.pull_request.head.repo.full_name == github.repository }}
```

Comment-only mode needs just `pull-requests: write`.
