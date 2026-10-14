{ config, ... }:

{
  users.users.${config.user.name}.home = "/Users/${config.user.name}";

  home-manager = {
    useGlobalPkgs = true;
    backupFileExtension = "before-home-manager";

    users.${config.user.name} =
      { config, ... }:
      let
        # Link to the checkout, not a store copy, so edits apply without a rebuild.
        dotfile =
          path: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/${path}";
      in
      {
        home.stateVersion = "26.05";

        home.file = {
          ".claude/CLAUDE.md".source = dotfile "claude/CLAUDE.md";
          ".claude/settings.json".source = dotfile "claude/settings.json";
          ".hushlogin".source = dotfile ".hushlogin";
          ".zshrc".source = dotfile ".zshrc";
        };

        xdg.configFile = {
          "zed/keymap.json".source = dotfile "zed/keymap.json";
          "zed/ruff.toml".source = dotfile "zed/ruff.toml";
          "zed/settings.json".source = dotfile "zed/settings.json";
        };
      };
  };
}
