{ config, ... }:

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
          ".claude/settings.json".source = dotfile "claude/settings.json";
          ".hushlogin".source = dotfile ".hushlogin";
          ".zshrc".source = dotfile ".zshrc";
        };

        xdg.configFile = {
          "zed/keymap.json".source = dotfile "zed/keymap.json";
          "zed/ruff.toml".source = dotfile "zed/ruff.toml";
        };

        # Merges the baseline into Zed's own settings on every rebuild, so local tweaks stay out of the repo.
        programs.zed-editor = {
          enable = true;
          package = null; # Installed as a Homebrew cask
          userSettings = builtins.fromJSON (builtins.readFile ../zed/settings.json);
        };
      };
  };
}
