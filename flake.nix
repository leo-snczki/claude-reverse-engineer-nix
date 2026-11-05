{
  description = "Claude Code for reverse engineering (REA, replica, reverse-api-engineer), pinned and isolated with Nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Claude Code itself, pinned by flake.lock.
    claude-code = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # agent-browser (one of reverse-api-engineer's browser providers).
    llm-agents.url = "github:numtide/llm-agents.nix";

    # REA skill source; pinned to a release so it matches the rea-agents MCP server.
    rea = {
      url = "github:morluto/rea/rea-agents-6.8.0";
      flake = false;
    };

    # replica-* app-cloning skills (no release tags).
    replica-skill = {
      url = "github:Jakeschincariol/replica-skill";
      flake = false;
    };

    # reverse-api-engineer CLI and skill. The skill is newer than the last
    # release (v0.14.0), so follow main; flake.lock pins the commit.
    reverse-api-engineer = {
      url = "github:kalil0321/reverse-api-engineer";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, claude-code, llm-agents, rea, replica-skill, reverse-api-engineer }:
    let
      lib = nixpkgs.lib;
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: lib.genAttrs systems (system: f (import nixpkgs {
        inherit system;
        overlays = [ claude-code.overlays.default ];
        config.allowUnfreePredicate = pkg: lib.getName pkg == "claude-code";
      }));

      name = "claude-reverse-engineer";
    in
    {
      packages = forAllSystems (pkgs:
        let
          py = pkgs.python3Packages;
          agent-browser = llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.agent-browser;

          # Not in nixpkgs. Its version floors run a little ahead of nixpkgs,
          # so relax them.
          rae = py.buildPythonApplication {
            pname = "reverse-api-engineer";
            version = (lib.importTOML "${reverse-api-engineer}/pyproject.toml").project.version;
            pyproject = true;
            src = reverse-api-engineer;
            build-system = [ py.hatchling ];
            pythonRelaxDeps = true;
            dependencies = with py; [
              click claude-agent-sdk rich markdown-it-py prompt-toolkit questionary
              watchdog setproctitle requests aiohttp pygments cryptography httpx2
              anyio certifi multidict opentelemetry-api pyjwt python-multipart
              starlette urllib3
              # The `manual` extra: capture with a local Playwright browser.
              playwright playwright-stealth
            ];
            doCheck = false;
          };

          # rea-agents (the MCP server) is not in nixpkgs; npx runs the release
          # that matches the pinned skill source.
          reaVersion = (lib.importJSON "${rea}/package.json").version;
          rea-mcp = pkgs.writeShellScriptBin "rea-mcp" ''
            # rea's scripts use `#!/usr/bin/env node`, so node must be on PATH.
            export PATH=${pkgs.nodejs_26}/bin:$PATH
            exec npx -y rea-agents@${reaVersion} mcp "$@"
          '';

          # One plugin with every skill, copied in as a real directory tree.
          plugin = pkgs.runCommand "${name}-plugin" { } ''
            mkdir -p $out/.claude-plugin $out/skills
            echo '{"name": "${name}", "description": "Reverse-engineering skills"}' > $out/.claude-plugin/plugin.json
            cp -r ${rea}/.agents/skills/reverse-engineer-anything $out/skills/
            cp -r ${reverse-api-engineer}/skills/reverse-api-engineer $out/skills/
            for skill in ${replica-skill}/*/SKILL.md; do
              cp -r "$(dirname "$skill")" $out/skills/
            done
          '';

          mcpConfig = pkgs.writeText "mcp.json" (builtins.toJSON {
            mcpServers.rea = {
              type = "stdio";
              command = "${rea-mcp}/bin/rea-mcp";
            };
          });

          # What the skills and MCP servers call, on Claude's PATH.
          tools = with pkgs; [
            rae
            rea-mcp
            agent-browser
            nodejs_26
            python3
            chromium
            # Native analysis tools REA drives when they are present
            file
            binutils
            gdb
            rizin
          ];

          # Claude Code with only this flake's CLAUDE.md, plugin, MCP servers
          # and settings. Its own config dir keeps ~/.claude (global CLAUDE.md,
          # skills, MCP servers, hooks) out, and holds a separate login.
          mkClaude = claudeMd: pkgs.writeShellScriptBin "claude" ''
            export CLAUDE_CONFIG_DIR="''${XDG_DATA_HOME:-$HOME/.local/share}/${name}"
            mkdir -p "$CLAUDE_CONFIG_DIR"
            ln -sfn ${claudeMd} "$CLAUDE_CONFIG_DIR/CLAUDE.md"
            export PATH=${lib.makeBinPath tools}:$PATH
            export CHROME_PATH=${lib.getExe pkgs.chromium}
            export PLAYWRIGHT_BROWSERS_PATH=${pkgs.playwright-driver.browsers-chromium}
            export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true
            exec ${pkgs.claude-code}/bin/claude \
              --plugin-dir ${plugin} \
              --strict-mcp-config --mcp-config ${mcpConfig} \
              --settings ${./settings.json} \
              "$@"
          '';

          claude = mkClaude ./CLAUDE.md;
        in
        {
          inherit claude plugin rae rea-mcp;
          default = claude;
          # Optional: the same Claude in a Docker container (docker/).
          docker = import ./docker { inherit pkgs lib name mkClaude tools; };
        });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [ self.packages.${pkgs.stdenv.hostPlatform.system}.claude ];
        };
      });

      apps = forAllSystems (pkgs:
        let packages = self.packages.${pkgs.stdenv.hostPlatform.system}; in
        {
          default = {
            type = "app";
            program = "${packages.claude}/bin/claude";
          };
          docker = {
            type = "app";
            program = "${packages.docker}/bin/${name}-docker";
          };
        });
    };
}
