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


#######################################
# Display a macOS notification banner.
# Arguments:
#   Message body (required).
#   Title (optional; defaults to "Notification").
#######################################
notify() {
  local -r message="$1"
  local -r title="${2:-Notification}"
  osascript -e "display notification \"${message}\" with title \"${title}\""
}


#######################################
# List the 30 apps using the most memory, summing each app's processes.
# Outputs:
#   Writes "<MB>  <app>" lines to stdout, largest first.
#######################################
appmem() {
  top -l 1 -stats pid,mem | awk '
    NR == FNR {
      pid = $1
      $1 = ""
      sub(/^ /, "")
      path[pid] = $0
      next
    }
    /^PID/ { in_table = 1; next }
    in_table {
      unit = $2
      gsub(/[0-9.+-]/, "", unit)
      amount = $2 + 0
      megabytes = (unit == "G") ? amount * 1024 : (unit == "K") ? amount / 1024 : (unit == "B") ? amount / 1048576 : amount
      process_path = path[$1]
      if (match(process_path, /[^\/]+\.app\//)) name = substr(process_path, RSTART, RLENGTH - 5)
      else { part_count = split(process_path, parts, "/"); name = parts[part_count] }
      total[name] += megabytes
    }
    END { for (name in total) printf "%8.1f MB  %s\n", total[name], name }
  ' <(ps -axo pid=,comm=) - | sort -rn | head -30
}
