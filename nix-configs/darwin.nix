{ config, pkgs, ... }:

# https://nix-darwin.github.io/nix-darwin/manual/

let
  # LanguageTool only accepts 2-letter language labels, which rules out newer models like lid218e and GlotLID.
  fasttextModel = pkgs.fetchurl {
    url = "https://dl.fbaipublicfiles.com/fasttext/supervised-models/lid.176.bin";
    hash = "sha256-fmnsVFG8JhzHhE5J5HkqhdfwnAZ4nsgA/EpErsNidk4=";
  };
  languageToolProperties = pkgs.writeText "server.properties" ''
    fasttextModel=${fasttextModel}
    fasttextBinary=${pkgs.fasttext}/bin/fasttext
  '';
  claudeManagedSettings = pkgs.writeText "managed-settings.json" (
    builtins.toJSON {
      sandbox = {
        allowUnsandboxedCommands = false;
        enabled = true;
        # Nix needs its daemon, which sandboxed commands can't reach. Full paths keep a repo's own `nix` on PATH from matching.
        excludedCommands = [
          "/run/current-system/sw/bin/nix *"
          "/run/current-system/sw/bin/nix-instantiate *"
          "/run/current-system/sw/bin/nix-shell *"
        ];
        failIfUnavailable = true;
      };
    }
  );
in
{
  imports = [
    ./apps.nix
    ./home.nix
    ./nix-settings.nix
    ./python.nix
    ./python-binaries.nix
    ./user-options.nix
  ];

  # macOS services
  launchd.user.agents.languageToolServer = {
    command = "${pkgs.languagetool}/bin/languagetool-server --config ${languageToolProperties} --allow-origin '*'";
    serviceConfig = {
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/languageToolServer.log";
      StandardErrorPath = "/tmp/languageToolServer.err.log";
    };
  };

  # Keep Terminal.app from copying each tab's shell history into ~/.bash_sessions and ~/.zsh_sessions.
  environment.variables.SHELL_SESSIONS_DISABLE = "1";

  # Root owns this file, so nothing Claude runs can loosen the sandbox, and as managed settings it stops repo settings from widening it.
  system.activationScripts.postActivation.text = ''
    install -d -o root -g wheel -m 0755 "/Library/Application Support/ClaudeCode"
    install -o root -g wheel -m 0444 ${claudeManagedSettings} "/Library/Application Support/ClaudeCode/managed-settings.json"
  '';

  # macOS settings
  # Ref: https://nix-darwin.github.io/nix-darwin/manual/index.html
  # NSGlobalDomain = all users
  networking = {
    hostName = config.user.hostname;
    localHostName = config.user.hostname;
    computerName = config.user.hostname;
    # make sure firewall is up & running
    applicationFirewall.enable = true;
    applicationFirewall.enableStealthMode = true;
  };

  system.defaults.loginwindow.PowerOffDisabledWhileLoggedIn = false;
  system.defaults.loginwindow.ShutDownDisabledWhileLoggedIn = false;
  system.defaults.loginwindow.RestartDisabledWhileLoggedIn = false;

  system.defaults = {
    iCal."first day of week" = "Monday";

    smb.NetBIOSName = config.user.hostname;

    dock = {
      autohide = false;
      orientation = "left";
      tilesize = 32;
      minimize-to-application = true;
      show-recents = false;
      # Disable hot corners
      wvous-tl-corner = 1;
      wvous-tr-corner = 1;
      wvous-bl-corner = 1;
      wvous-br-corner = 1;
    };

    finder = {
      _FXShowPosixPathInTitle = true;
      # Auto-resize columns to fit filenames
      _FXEnableColumnAutoSizing = true;
      AppleShowAllExtensions = true;
      # Restrict searches in Finder to current folder
      FXDefaultSearchScope = "SCcf";
      # Default to List view in Finder
      FXPreferredViewStyle = "Nlsv";
      NewWindowTarget = "Home";
      ShowPathbar = true;
      ShowStatusBar = true;
      # Keep folders on top when sorting by name
      _FXSortFoldersFirst = true;
      _FXSortFoldersFirstOnDesktop = true;
      # Allow quitting Finder
      QuitMenuItem = true;
    };

    # What happens when you press the Fn key
    hitoolbox.AppleFnUsageType = "Do Nothing";

    menuExtraClock = {
      # Flash clock colon separator on and off each second
      FlashDateSeparators = false;
      ShowSeconds = true;
      Show24Hour = true;
    };

    NSGlobalDomain = {
      AppleMeasurementUnits = "Centimeters";
      AppleMetricUnits = 1;
      AppleShowAllExtensions = true;
      AppleShowScrollBars = "Always";
      AppleTemperatureUnit = "Celsius";
      # Disable double space = period.
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      # Force 24-hour clock
      AppleICUForce24HourTime = true;
      # Enable natural scrolling direction
      "com.apple.swipescrolldirection" = true;
      # Two-finger tap to right click
      "com.apple.trackpad.enableSecondaryClick" = true;
      # Enable trackpad tap to click
      "com.apple.mouse.tapBehavior" = 1;
    };

    SoftwareUpdate.AutomaticallyInstallMacOSUpdates = false;

    trackpad.Clicking = true;

    WindowManager = {
      # Click wallpaper to reveal desktop -> false = "Only in Stage Manager".
      EnableStandardClickToShowDesktop = false;
      # Disable macOS tiling manager
      EnableTilingByEdgeDrag = false;
      EnableTiledWindowMargins = false;
      EnableTilingOptionAccelerator = false;
      EnableTopTilingByEdgeDrag = false;
    };
  };

  # Enable TouchID unlock for sudo
  security.pam.services.sudo_local.touchIdAuth = true;
}
