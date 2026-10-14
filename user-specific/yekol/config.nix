{ pkgs, unstablePkgs, ... }:

{
  imports = [ ./moonlight-awdl.nix ];

  system.defaults.dock.persistent-apps = [
    { app = "/Applications/Zen.app"; }
    { app = "/System/Applications/Mail.app"; }
    { app = "/Applications/Zed.app"; }
    { app = "/Applications/Notion.app"; }
    { app = "/Applications/Goodnotes.app"; }
    { app = "/System/Applications/Notes.app"; }
    { app = "/System/Applications/Reminders.app"; }
    { app = "/System/Applications/Calendar.app"; }
    { app = "/Applications/Slack.app"; }
    { app = "/Applications/Discord.app"; }
    { app = "/System/Applications/Messages.app"; }
    { app = "/Applications/LINE.app"; }
    { app = "/System/Applications/FaceTime.app"; }
    { app = "/System/Applications/Music.app"; }
    { app = "/System/Applications/Utilities/Terminal.app"; }
    { app = "/Applications/Bitwarden.app"; }
  ];

  environment.systemPackages = [
    pkgs.exercism # A Go based command line tool for exercism.io
    pkgs.id3v2 # A command line editor for id3v2 tags
    pkgs.mkvtoolnix # Cross-platform tools for Matroska video containers
    pkgs.ngrok # Expose a web server running on your local machine to the internet
    pkgs.pdsh # Issue commands to groups of hosts in parallel
    pkgs.yt-dlp # Download video files from YouTube
    unstablePkgs.zuse # CLI IRC client written in Go
  ];

  homebrew = {
    casks = [
      "anki"
      "discord"
      "heroic"
      "moonlight"
      "plex"
      "steam"
    ];
    # App store apps
    masApps = {
      "AutoInvert" = 6443480300;
      "Goodnotes" = 1444383602;
      "Keynote" = 361285480;
      "Line" = 539883307;
      "Numbers" = 361304891;
      "Pages" = 361309726;
      "SteamLink" = 1246969117;
      "Tailscale" = 1475387142;
    };
  };

  security.pam.services.sudo_local.watchIdAuth = true;
}
