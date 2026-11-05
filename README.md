# claude-reverse-engineer

Claude Code for reverse engineering, pinned and isolated with Nix:

- **Claude Code** at the version pinned in `flake.lock` (sadjow/claude-code-nix).
- **Skills** in one plugin: [REA](https://github.com/morluto/rea)'s
  `reverse-engineer-anything`, [replica-*](https://github.com/Jakeschincariol/replica-skill)
  and [reverse-api-engineer](https://github.com/kalil0321/reverse-api-engineer).
- **MCP**: the `rea` server, and nothing else (`--strict-mcp-config`).
- **Tools** on Claude's PATH: the `reverse-api-engineer` CLI, agent-browser,
  Node, Python, Playwright browsers, rizin with the Ghidra decompiler,
  Frida, plus per platform: gdb, binutils and Chromium on Linux; lldb,
  cctools, LLVM, ipsw and clang on macOS.

It is isolated from your own Claude Code setup: it uses its own config
directory (`~/.local/share/claude-reverse-engineer`, via
`CLAUDE_CONFIG_DIR`), so your `~/.claude` (global CLAUDE.md, skills, MCP
servers, hooks) isn't loaded, and it has its own login (`/login` once).

## What it can do

On Linux and macOS:

- Turn a website's private API into a typed client (reverse-api-engineer).
- Clone a web app end to end (replica-*: recon, design, build, Playwright
  tests, deploy).
- Analyze and decompile binaries from any platform: Windows PE (`.exe`,
  `.dll`), macOS Mach-O, Linux ELF, Android APKs, Electron apps, firmware
  (rizin with the Ghidra decompiler, REA).
- Run, debug and instrument the platform's own programs: Linux binaries
  with gdb and Frida; macOS apps with lldb and Frida.

On macOS, also: Objective-C and Swift metadata (`ipsw class-dump`,
`ipsw swift-dump`), Mach-O tools (otool, lipo, install_name_tool), and
compiling C, C++ and Objective-C with clang. Swift and Xcode projects use
the system Xcode. Apps with the hardened runtime can only be debugged or
instrumented once re-signed or with SIP off.

Nowhere can it run or debug Windows programs (see the Windows notes
below). In a container or WSL, it can't drive desktop apps or use your
logged-in Chrome (reverse-api-engineer's `chrome-mcp` provider).

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
| macOS, Apple Silicon | `nix run` | not tested; Node 26 compiles from source |
| macOS, Intel | not supported (nixpkgs dropped x86_64-darwin) | |

### Windows

Use [NixOS-WSL](https://github.com/nix-community/NixOS-WSL) (NixOS in WSL2:
the closest to a NixOS machine), or install Nix in another WSL distro such
as Ubuntu. Then, in the WSL shell, run `nix run` as above.

Keep your projects in the WSL filesystem (`~/...`, not `/mnt/c/...`):
Windows drives are much slower from WSL, and Git for Windows may have
converted line endings.

> [!IMPORTANT]
> WSL is Linux: it analyzes and decompiles Windows programs, but can't run or
> debug them.

### macOS

Run `nix run` as above. For lldb and Swift, install Xcode or the Command
Line Tools (`xcode-select --install`). The Docker variant (`#docker`) is
Linux only.

## Docker

`#docker` runs the same Claude in a Docker container that only sees the
current directory. See [docker/](docker/README.md).

## Update

```sh
nix flake update                 # everything
nix flake update claude-code     # just Claude Code
```
