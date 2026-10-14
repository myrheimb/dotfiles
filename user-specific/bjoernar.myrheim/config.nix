{ config, pkgs, ... }:

{
  system.defaults.dock.persistent-apps = [
    { app = "/Applications/Zen.app"; }
    { app = "/Applications/Zed.app"; }
    { app = "/System/Applications/Reminders.app"; }
    { app = "/Applications/Notion.app"; }
    { app = "/Applications/Slack.app"; }
    { app = "/Applications/Microsoft Teams.app"; }
    { app = "/System/Applications/Music.app"; }
    { app = "/Applications/Plexamp.app"; }
    { app = "/System/Applications/Utilities/Terminal.app"; }
    { app = "/Applications/Bitwarden.app"; }
  ];

  environment.systemPackages = [
    pkgs.gnupg # GNU Privacy Guard
    pkgs.trivy # Simple and comprehensive vulnerability scanner for containers
  ];

  home-manager.users.${config.user.name}.services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry_mac;
  };

  homebrew = {
    brews = [
    ];

    casks = [
      "onedrive"
      "openvpn-connect"
    ];
    masApps = {
      # "AppName" = 12345;
    };
  };
}
