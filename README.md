# claude-reverse-engineer

Claude Code for reverse engineering, pinned and isolated with Nix:

- **Claude Code** at the version pinned in `flake.lock` (sadjow/claude-code-nix).
- **Skills** in one plugin: [REA](https://github.com/morluto/rea)'s
  `reverse-engineer-anything`, [replica-*](https://github.com/Jakeschincariol/replica-skill)
  and [reverse-api-engineer](https://github.com/kalil0321/reverse-api-engineer).
- **MCP**: the `rea` server, and nothing else (`--strict-mcp-config`).
- **Tools** on Claude's PATH: the `reverse-api-engineer` CLI, agent-browser,
  Node, Python, Chromium, Playwright browsers, gdb, rizin, binutils.

It is isolated from your own Claude Code setup: it uses its own config
directory (`~/.local/share/claude-reverse-engineer`, via
`CLAUDE_CONFIG_DIR`), so your `~/.claude` (global CLAUDE.md, skills, MCP
servers, hooks) isn't loaded, and it has its own login (`/login` once).

## What it can do

It is a Linux environment. It can:

- Turn a website's private API into a typed client (reverse-api-engineer,
  with a headless browser).
- Clone a web app end to end (replica-*: recon, design, build, Playwright
  tests, deploy).
- Analyze binaries statically, from any platform: Windows PE (`.exe`,
  `.dll`), macOS Mach-O, Linux ELF, Android APKs, Electron apps, firmware
  (rizin, binutils, REA).
- Run and debug Linux binaries (gdb, REA).

It can't run or debug Windows or macOS programs, drive apps open on a
Windows or macOS desktop, or use your logged-in Chrome from inside a
container or WSL (reverse-api-engineer's `chrome-mcp` provider).

## Use

Needs Nix with flakes. From the directory to work on:

```sh
nix run github:leo-snczki/claude-reverse-engineer
```

Arguments go to `claude` (`nix run ... -- --resume`). In a project, a
devShell puts the same `claude` on PATH:

```sh
nix develop github:leo-snczki/claude-reverse-engineer
# or, with direnv, in .envrc:
use flake github:leo-snczki/claude-reverse-engineer
```

Without flakes enabled in your Nix config, add
`--extra-experimental-features 'nix-command flakes'` to the `nix` command.

## Platforms

| Platform | How | Status |
|---|---|---|
| Linux x86_64 (NixOS or Nix) | `nix run` | tested |
| Windows | Nix in WSL2, then `nix run` (below) | same as Linux x86_64 |
| Linux aarch64 | `nix run` | not tested; Node 26 compiles from source |
| macOS | Docker only (the flake has no Darwin build) | aarch64 image not tested |

### Windows

Use [NixOS-WSL](https://github.com/nix-community/NixOS-WSL) (NixOS in WSL2:
the closest to a NixOS machine), or install Nix in another WSL distro such
as Ubuntu. Then, in the WSL shell, run `nix run` as above.

Keep your projects in the WSL filesystem (`~/...`, not `/mnt/c/...`):
Windows drives are much slower from WSL, and Git for Windows may have
converted line endings.

## Docker sandbox

For working with code or binaries you don't trust, run the same Claude in
a Docker container: it only sees the current directory, not your home, SSH
keys or tokens, so `--dangerously-skip-permissions` is a smaller risk. See
[docker/](docker/README.md).

## Update

```sh
nix flake update                 # everything
nix flake update claude-code     # just Claude Code
```
