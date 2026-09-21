# Contributing

Thanks for considering a contribution to Claude Code Workflow.

## Good contributions

Useful changes include:

- fixes for ambiguous or contradictory command instructions;
- portability improvements;
- safer installation behavior;
- documentation and examples;
- validation and CI improvements;
- reproducible bug reports from real Claude Code usage.

## Development process

1. Create a focused branch.
2. Explain the concrete problem being solved.
3. Keep unrelated refactors out of the same pull request.
4. Run:

```bash
python3 scripts/validate_repo.py
```

5. If you change command behavior, update the README or `WORKFLOWS.md` when relevant.
6. Add a changelog entry for user-visible changes.

## Pull request checklist

- [ ] The change addresses a specific problem.
- [ ] The workflow remains understandable without hidden context.
- [ ] Installation instructions still match the repository.
- [ ] `python3 scripts/validate_repo.py` passes.
- [ ] No secrets, private data, generated project specs, or local machine files are committed.
- [ ] User-visible behavior is documented.

## Scope

This project intentionally stays small. New commands or process steps should only be added when they solve a demonstrated problem that cannot be handled cleanly by the existing workflow.

## License

By contributing, you agree that your contribution may be distributed under the repository's MIT license.
