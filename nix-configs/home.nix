{ config, unstablePkgs, ... }:

{
  users.users.${config.user.name}.home = "/Users/${config.user.name}";

  home-manager = {
    useGlobalPkgs = true;
    backupFileExtension = "before-home-manager";

    users.${config.user.name} =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        # Link to the checkout, not a store copy, so edits apply without a rebuild.
        dotfile =
          path: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/${path}";
      in
      {
        home.stateVersion = "26.05";

        home.activation.dotfilesGitHooks = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run ${pkgs.git}/bin/git -C ${config.home.homeDirectory}/.dotfiles config core.hooksPath .githooks
        '';

        # Nix's Swift lacks the macOS SDK with Apple's Translation framework, so Apple's compiler builds it.
        home.activation.translate = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run mkdir -p ${config.home.homeDirectory}/.local/bin
          run /usr/bin/swiftc -O ${config.home.homeDirectory}/.dotfiles/scripts/translate.swift -o ${config.home.homeDirectory}/.local/bin/translate
        '';

        home.file = {
          ".claude/CLAUDE.md".source = dotfile "claude/CLAUDE.md";
          ".claude/hooks/devenv-exports.sh".source = dotfile "claude/hooks/devenv-exports.sh";
          ".claude/settings.json".source = dotfile "claude/settings.json";
          ".hushlogin".source = dotfile ".hushlogin";
          ".zshrc".source = dotfile ".zshrc";
        };

        # Home Manager hands MCP servers to Claude Code as a plugin, so they live here, not in ~/.claude.json.
        programs.claude-code = {
          enable = true;
          package = unstablePkgs.claude-code;
          # Headless with an in-memory profile, so pages see none of my logins.
          mcpServers.playwright = {
            type = "stdio";
            command = lib.getExe pkgs.playwright-mcp;
            args = [
              "--browser"
              "chromium"
              "--executable-path"
              "/Applications/Chromium.app/Contents/MacOS/Chromium"
              "--headless"
              "--isolated"
            ];
          };
        };

        xdg.configFile = {
          "zed/keymap.json".source = dotfile "zed/keymap.json";
          "zed/ruff.toml".source = dotfile "zed/ruff.toml";
        };

        # Merges the baseline into Zed's own settings on every rebuild, so local tweaks stay out of the repo.
        programs.zed-editor = {
          enable = true;
          package = null; # Installed as a Homebrew cask
          # Zed's bundled Claude lacks the Home Manager plugin, and Zed doesn't expand ~ in this path.
          userSettings = lib.recursiveUpdate (builtins.fromJSON (builtins.readFile ../zed/settings.json)) {
            agent_servers.claude-acp.env.CLAUDE_CODE_EXECUTABLE = "${config.home.profileDirectory}/bin/claude";
          };
        };
      };
  };
}
