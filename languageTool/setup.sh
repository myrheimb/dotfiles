create_properties_file() {
  local dst="$HOME/.dotfiles/languageTool/server.properties"

  # File exists and is consistent with the logged in user
  if [[ -f "$dst" && $(grep -c "$USER" "$dst") -eq 1 ]]; then
    return 0
  fi

  cat > "$dst" <<EOF
fasttextModel=$HOME/.dotfiles/languageTool/fasttext.176.bin
fasttextBinary=/run/current-system/sw/bin/fasttext
EOF
}

download_fasttext_model() {
  local dst="$HOME/.dotfiles/languageTool/fasttext.176.bin"
  local url="https://dl.fbaipublicfiles.com/fasttext/supervised-models/lid.176.bin"

  # File exists
  if [[ -f "$dst" ]]; then
    return 0
  fi

  echo "Downloading fasttext model for languageTool..."
  mkdir -p "$(dirname "$dst")"

  local tmp="${dst}.tmp"
  wget -qO "$tmp" "$url"
  mv -f "$tmp" "$dst"
}
