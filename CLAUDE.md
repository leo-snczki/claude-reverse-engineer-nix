# Reverse-engineering workspace

This Claude Code comes from the claude-reverse-engineer Nix flake: its
skills, MCP servers and tools are pinned there, and nothing from the user's
~/.claude is loaded. The tools below are
on PATH; don't install others globally (pip, npm -g): add them there
instead.

Skills (from this flake's plugin):

- `reverse-engineer-anything`: reverse engineer binaries, packaged and
  Electron/JS apps, firmware and web apps when the answer depends on the
  shipped artifact rather than source code. The skill gives the workflow;
  the `rea` MCP server gives the tools, so use both together. `file`,
  `binutils`, `gdb` and `rizin` are installed.
- `reverse-api-engineer`: turn a website's private HTTP API into a typed
  client with the `reverse-api-engineer` CLI (installed).
- `replica-*`: clone an app end to end (recon, architecture, design,
  build, backend, tests, parity diff, reviews, rebranding, launch, deploy).

Browsers: Chromium is at `$CHROME_PATH` and Playwright's at
`$PLAYWRIGHT_BROWSERS_PATH`. For Playwright, install `@playwright/test` at
the version matching the nixpkgs browsers and skip `npx playwright install`.
