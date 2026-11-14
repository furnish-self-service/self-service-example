#!/bin/sh
# Example.Hosts/Entry: DSC v3 command resource. Properties arrive as env vars ($ip, $hostname, $_exist).
# stdout: exactly one JSON object (the actual state). Everything else goes to stderr.
set -eu
HOSTS=${HOSTS_FILE:-/etc/hosts}   # override for testing

# Own exit codes are 10+ and mapped in the manifest; tool failures keep their code so DSC shows stderr.
[ -n "${ip:-}" ] && [ -n "${hostname:-}" ] || { echo '{"error":"ip and hostname are required"}' >&2; exit 10; }

present() { grep -Eq "^[[:space:]]*$ip[[:space:]]+$hostname([[:space:]]|\$)" "$HOSTS" 2>/dev/null; }

state() {   # Always a boolean _exist, also when absent. Include key properties.
    if present; then e=true; else e=false; fi
    printf '{"ip":"%s","hostname":"%s","_exist":%s}\n' "$ip" "$hostname" "$e"
}

case "${1:-}" in
get) state ;;
set)
    # implementsPretest: DSC did not test first, so set must be idempotent itself.
    [ -w "$HOSTS" ] || { echo "{\"error\":\"$HOSTS is not writable\"}" >&2; exit 11; }
    if [ "${_exist:-true}" = true ]; then
        present || { echo '{"info":"adding hosts entry"}' >&2; printf '%s %s\n' "$ip" "$hostname" >> "$HOSTS"; }
    elif present; then
        echo '{"info":"removing hosts entry"}' >&2
        tmp=$(mktemp)
        grep -Ev "^[[:space:]]*$ip[[:space:]]+$hostname([[:space:]]|\$)" "$HOSTS" > "$tmp" || true
        cat "$tmp" > "$HOSTS" && rm -f "$tmp"   # rewrite in place: keeps owner and mode
    fi
    state   # return: state → print the after-state
    ;;
*) echo '{"error":"usage: get|set"}' >&2; exit 10 ;;
esac
