{
  pkgs,
  unstablePkgs,
  config,
  ...
}:

{
  environment.systemPackages = [
    pkgs._7zz # Command line archiver utility
    pkgs.bat # A cat(1) clone with syntax highlighting and Git integration
    pkgs.bats # Bash Automated Testing System
    unstablePkgs.bitwarden-cli # Secure and free password manager for all of your devices
    pkgs.cachix # CLI client for Nix binary cache hosting https://cachix.org
    pkgs.comma # Runs programs without installing them
    pkgs.coreutils # The basic file, shell and text manipulation utilities of the GNU operating system
    unstablePkgs.devenv # Fast, Declarative, Reproducible, and Composable Developer Environments
    pkgs.dig # DNS lookup utility
    pkgs.docker-compose # Docker CLI plugin to define and run multi-container applications with Docker
    pkgs.ext4fuse # FUSE driver for ext2, 3, and 4
    pkgs.eza # Modern, maintained replacement for ls
    pkgs.fasttext # Library for text classification and representation learning
    pkgs.fdupes # Identifies duplicate files residing within specified directories
    pkgs.geckodriver # Headless browser
    pkgs.git # Distributed version control system
    pkgs.go-task # Task runner / simpler Make alternative written in Go
    pkgs.grc # Generic text colouriser
    pkgs.htop # An interactive process viewer
    pkgs.languagetool # A proofreading program, similar to Grammarly
    unstablePkgs.mactop # Terminal-based monitoring tool for Apple Silicon chips
    pkgs.mc # CLI-based file manager like Norton Commander
    pkgs.mozjpeg # Mozilla JPEG Encoder Project (compress image files)
    pkgs.mtr # Network diagnostics tool
    pkgs.nano # macOS built-in nano sucks (pico)
    unstablePkgs.netwatch # Real-time network diagnostics in your terminal.
    pkgs.nil # Yet another language server for Nix
    pkgs.nixd # Feature-rich Nix language server interoperating with C++ nix
    pkgs.nmap # A utility for network discovery and security auditing
    pkgs.parallel # Shell tool for executing jobs in parallel
    pkgs.pgweb # A web-based database browser for PostgreSQL
    pkgs.pgcli # A CLI-based database browser for PostgreSQL
    pkgs.pngquant # Tool to convert 24/32-bit RGBA PNGs to 8-bit palette with alpha channel preserved
    pkgs.qrencode # Create QR-codes e.g. `qrencode -o conf.png -t png < wireguard.conf`
    pkgs.ripgrep # Utility that combines the usability of The Silver Searcher with the raw speed of grep
    pkgs.rsync # Transfer files over SSH
    pkgs.smartmontools # Tools for monitoring the health of hard drives
    pkgs.speedtest-cli # CLI tool for testing internet bandwidth using speedtest.net
    pkgs.translate-shell # Command-line translator using Google Translate, Bing Translator, Yandex.Translate, and Apertium
    pkgs.tree # Command to produce a depth indented directory listing
    pkgs.unrar # Extract .rar archives
    pkgs.upx # The Ultimate Packer for eXecutables
    pkgs.websocat # Command-line client for WebSockets
    pkgs.wget # CLI tool for retrieving files using HTTP, HTTPS, and FTP
    pkgs.wpscan # Black box WordPress vulnerability scanner
    pkgs.yara # Scan for malicious software in files
    pkgs.zbar # Read bar codes from various sources
    pkgs.zstd # Manage zstd archives. E.g. 'zstd --decompress archive.zst'
    unstablePkgs.zuban # Mypy-compatible Python Language Server built in Rust
    # GUI apps
    unstablePkgs.claude-code # Agentic coding tool that lives in your terminal, understands your codebase, and helps you code faster
    pkgs.maccy # Simple clipboard manager for macOS
    pkgs.keka # macOS file archiver
    pkgs.appcleaner # Uninstall unwanted apps
    pkgs.moonlight-qt
  ];

  homebrew = {
    enable = true;
    user = config.user.name;
    brews = [
      # Homebrew installs mas on its own for masApps, but cleanup would remove it.
      "mas"
    ];
    casks = [
      "alt-tab"
      "docker-desktop"
      "gimp"
      "hot"
      "logi-options+"
      "megasync"
      "notion"
      "plexamp"
      "protonvpn"
      "raspberry-pi-imager"
      "tiles"
      "ungoogled-chromium"
      "vlc"
      "zed"
      "zen"
    ];
    # App store apps
    masApps = {
      "Bitwarden" = 1352778147;
      "Slack" = 803453959;
      "Speedtest by Ookla" = 1153157709;
    };
    onActivation.autoUpdate = true; # runs brew update first
    onActivation.cleanup = "uninstall"; # remove formulae/casks not listed here
    onActivation.upgrade = true;   # upgrades formulae/casks on rebuild
  };

  programs.zsh = {
    enable = true;
    enableSyntaxHighlighting = true;
    enableAutosuggestions = true;
    enableBashCompletion = true;
    enableCompletion = true;
  };

  # Exported to every zsh, including the non-login shells devenv spawns.
  environment.variables = {
    LC_ALL = "en_US.UTF-8";
    LANG = "en_US.UTF-8";

    # Enable OMZ
    ZSH = "${pkgs.oh-my-zsh}/share/oh-my-zsh";
    ZSH_THEME = "aussiegeek";
    ZSH_CUSTOM = "${./..}/zsh";

    # Enable a few neat features
    HYPHEN_INSENSITIVE = "true";
    COMPLETION_WAITING_DOTS = "true";

    # Disable generation of .pyc files
    # https://docs.python-guide.org/writing/gotchas/#disabling-bytecode-pyc-files
    PYTHONDONTWRITEBYTECODE = "1";
  };
}
