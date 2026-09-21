# Claude Code Workflow

A small, file-driven workflow for making Claude Code development more structured and reviewable.

The repository provides five reusable slash commands that separate discovery, specification, implementation, architecture decisions, and review:

```text
/audit → /spec → /build → /review
                ↘ /architect (when needed)
```

The commands communicate through files under `specs/`, so work can be resumed, reviewed, and audited without relying on hidden conversational state.

> This is an independent community project. It is not an official Anthropic repository.

## What it provides

| Command | Purpose | Main output |
| --- | --- | --- |
| `/audit` | Inspect an existing codebase without changing it | `specs/audit.md` |
| `/spec` | Turn a request into an explicit implementation specification | `specs/projet.md` |
| `/build` | Implement the specification with checkpoints and validation | code + `specs/test-report.md` |
| `/review` | Review correctness, security, regressions, performance, and maintainability | `specs/review.md` |
| `/architect` | Record architecture decisions for larger changes | `specs/architecture.md` |

The default day-to-day workflow is:

```text
/audit → /spec → /build → /review
```

For a focused bug fix where the problem is already clear:

```text
/audit → /build → /review
```

For a larger structural change:

```text
/audit → /spec → /architect → /build → /review
```

## Why file-driven?

Each stage produces a durable artifact that the next stage can read. This makes it easier to:

- inspect what Claude understood before code is changed;
- keep implementation aligned with an explicit specification;
- resume work in a later session;
- distinguish tests that passed, failed, or were not executed;
- keep review findings and remediation state visible;
- avoid treating a conversational summary as the only source of truth.

## Repository layout

```text
.claude/commands/
  architect.md
  audit.md
  build.md
  review.md
  spec.md

scripts/
  validate_repo.py

install.sh
install.ps1
WORKFLOWS.md
CHANGELOG.md
LICENSE
```

## Installation

### macOS / Linux

Install into the current project:

```bash
git clone https://github.com/LoopingOfficial/claude-workflow-v1.git
cd claude-workflow-v1
./install.sh --project /path/to/your/project
```

Install globally for your user:

```bash
./install.sh --global
```

### Windows PowerShell

Install into a project:

```powershell
git clone https://github.com/LoopingOfficial/claude-workflow-v1.git
cd claude-workflow-v1
.\install.ps1 -ProjectPath "C:\path\to\your\project"
```

Install globally:

```powershell
.\install.ps1 -Global
```

### Manual installation

Copy the Markdown command files into either:

```text
<project>/.claude/commands/
```

or:

```text
~/.claude/commands/
```

Then open Claude Code in the target project and invoke `/audit`.

## Validation

The repository includes a dependency-free validator:

```bash
python3 scripts/validate_repo.py
```

It verifies that the expected command files and project metadata are present and non-empty. GitHub Actions runs the same validation on pushes and pull requests.

## Workflow contract

The generated files form a simple contract between stages:

| File | Produced by | Used by |
| --- | --- | --- |
| `specs/audit.md` | `/audit` | `/build`, `/review`, `/architect` |
| `specs/projet.md` | `/spec` | `/build`, `/review`, `/architect` |
| `specs/architecture.md` | `/architect` | `/build`, `/review`, `/audit` |
| `specs/test-report.md` | `/build` | `/review` |
| `specs/review.md` | `/review` | `/build`, `/audit`, `/review` |

See [WORKFLOWS.md](WORKFLOWS.md) for the detailed workflow rules.

## Design principles

The commands intentionally favor:

- observable work over implicit state;
- reversible changes over one-shot edits;
- explicit test outcomes over vague validation claims;
- small, reviewable iterations;
- security checks before risky operations;
- human confirmation when requirements or architecture are ambiguous.

## Contributing

Bug reports, documentation improvements, portability fixes, and workflow improvements are welcome.

Please read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.

Security-sensitive issues should follow [SECURITY.md](SECURITY.md).

## Versioning

The original stable workflow is tagged as `v1.0.0`. Future releases should document user-visible changes in [CHANGELOG.md](CHANGELOG.md).

## License

MIT. See [LICENSE](LICENSE).
