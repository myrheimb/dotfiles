#######################################
# Save a secret to the macOS keychain.
# Arguments:
#   key (required)
#   value (required)
#######################################
set_keychain_secret() {
  # Usage: set_keychain_secret KEY_NAME secret_value
  local key=${1:?Usage: set_keychain_secret 'KEY_NAME' 'secret_value'}
  local value=${2:?Please provide a secret}

  security add-generic-password \
    -a "$USER" \
    -s "$key" \
    -w "$value" \
    -U
}


#######################################
# Get a secret from the macOS keychain.
# Arguments:
#   key (required)
# Outputs:
#   Writes value of $key to stdout
#######################################
get_keychain_secret() {
  # Usage: get_keychain_secret KEY_NAME
  local key=${1:?Usage: get_keychain_secret 'KEY_NAME'}

  security find-generic-password \
    -a "$USER" \
    -s "$key" \
    -w 2>/dev/null || {
      echo "Error: $key not found in keychain."
      echo "Please set it by running: set_keychain_secret '$key' 'your_secret'"
      return 1
    }
}


#######################################
# Translate supplied text using Google Translate CLI (`trans`).
# Arguments:
#   text (required)
#   languages (optional)
# Outputs:
#   Writes translation to stdout
#######################################
translate() {
  # Usage: translate "text" [from:to]
  local text=${1:?Usage: translate 'text' [from:to] (default: ja:en)}
  local languages=${2:-ja:en}
  trans --brief "$languages" "$text"
}


#######################################
# Send a push notification using Pushover.
# Arguments:
#   message (required)
#######################################
pushover() {
  # Usage: pushover "message"
  # Ref: https://pushover.net/api
  local message=${1:?Usage: pushover 'Message to send'}

  PUSHOVER_API_TOKEN=$(get_keychain_secret PUSHOVER_API_TOKEN)
  if [[ $? -ne 0 ]]; then echo $PUSHOVER_API_TOKEN && return 1; fi

  PUSHOVER_USER_KEY=$(get_keychain_secret PUSHOVER_USER_KEY)
  if [[ $? -ne 0 ]]; then echo $PUSHOVER_USER_KEY && return 1; fi

  curl -s \
    --form-string "token=${PUSHOVER_API_TOKEN}" \
    --form-string "user=${PUSHOVER_USER_KEY}" \
    --form-string "message=${message}" \
    https://api.pushover.net/1/messages.json
}
