{ ... }:

# AWDL (AirDrop, Sidecar) hops the Wi-Fi radio between channels, which causes
# latency spikes in Moonlight streams. macOS brings awdl0 back up on demand,
# so we keep forcing it down for as long as Moonlight runs.
{
  launchd.daemons.moonlight-awdl = {
    script = ''
      awdl_was_up=0
      moonlight_running=0

      awdl_is_up() {
        /sbin/ifconfig awdl0 2>/dev/null | /usr/bin/head -n 1 | /usr/bin/grep -q '<UP'
      }

      restore_awdl() {
        if [ "$awdl_was_up" -eq 1 ]; then
          /sbin/ifconfig awdl0 up
        fi
        awdl_was_up=0
        moonlight_running=0
      }

      trap restore_awdl EXIT
      trap 'exit 0' TERM INT HUP

      while :; do
        if /usr/bin/pgrep -x Moonlight >/dev/null; then
          if [ "$moonlight_running" -eq 0 ]; then
            moonlight_running=1
            awdl_is_up && awdl_was_up=1
          fi
          awdl_is_up && /sbin/ifconfig awdl0 down
        elif [ "$moonlight_running" -eq 1 ]; then
          restore_awdl
        fi
        /bin/sleep 0.25
      done
    '';
    serviceConfig = {
      KeepAlive = true;
      ProcessType = "Background";
      RunAtLoad = true;
    };
  };
}
