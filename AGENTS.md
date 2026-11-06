# AGENTS.md

This file provides guidance to AI agents and contributors working in this repo.

## Command Policy

- Use Bun for repository commands. Do not use npm or npx. Use `bunx` when a package binary is needed.

## Timeout Policy

- Keep CI, script, and runtime timeouts at 10 minutes or less. Use `timeout-minutes: 10` or lower in GitHub Actions and cap timeout values at `600000` ms, `600` seconds, or `10m` unless explicitly requested.
