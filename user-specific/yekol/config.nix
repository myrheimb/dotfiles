{ pkgs, unstablePkgs, ... }:

{
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
    pkgs.localsend # Open source cross-platform alternative to AirDrop
    pkgs.mkvtoolnix # Cross-platform tools for Matroska video containers
    pkgs.ngrok # Expose a web server running on your local machine to the internet
    # pkgs.oci-cli  # Command Line Interface for Oracle Cloud Infrastructure
    pkgs.pdsh # Issue commands to groups of hosts in parallel
    pkgs.yt-dlp # Download video files from YouTube
    # pkgs.vobsub2srt  # Converts VobSub subtitles into SRT subtitles
    unstablePkgs.zuse # CLI IRC client written in Go
  ];

  homebrew = {
    casks = [
      "anki"
      "discord"
      "heroic"
      "nvidia-geforce-now"
      "plex"
      "raspberry-pi-imager"
      "steam"
    ];
    # App store apps
    masApps = {
      "AutoInvert" = 6443480300;
      "FileZilla" = 1298486723;
      "Goodnotes" = 1444383602;
      "Keynote" = 361285480;
      "Line" = 539883307;
      "NordVPN" = 905953485;
      "Numbers" = 361304891;
      "Pages" = 361309726;
      "SteamLink" = 1246969117;
      "Wireguard" = 1451685025;
    };
  };
}
