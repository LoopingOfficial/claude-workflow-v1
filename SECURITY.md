# Security Policy

This repository contains workflow instructions used by an AI coding tool. A workflow change can influence shell commands, file edits, Git operations, and security-sensitive development decisions, so unsafe instructions are treated as security issues.

## Reporting

Please do not publish a working exploit or credential in a public issue.

For a suspected vulnerability, provide:

- the affected command file;
- the instruction or behavior that is unsafe;
- a minimal reproduction;
- the possible impact;
- a safer alternative, if known.

If GitHub private vulnerability reporting is available for this repository, use it. Otherwise, open a minimal issue requesting a private contact channel without including exploit details.

## Examples of security-relevant issues

- instructions that can expose secrets or credentials;
- destructive Git or filesystem operations without an explicit checkpoint;
- command injection through untrusted project content;
- instructions that weaken authentication or access controls;
- validation steps that falsely report success after tests were skipped;
- unsafe handling of production data.

## Supported versions

Security fixes are applied to the current `main` branch and documented in the next release notes.
