#!/usr/bin/env bash
# Fetch the GCP Cloud NAT static IP from terraform output, then connect to
# MongoDB Atlas using credentials read from environment variables.
#
# Required env vars:
#   MONGO_USER      Atlas database username
#   MONGO_PASS      Atlas database password
#   ATLAS_HOST      Atlas SRV host (e.g. cluster0.abcde.mongodb.net)
#
# Optional env vars:
#   MONGO_DB        Default database name      (default: admin)
#   MONGO_APP_NAME  appName query param        (default: pass-nat-check)
#   TF_DIR          Terraform working dir      (default: this script's parent)
#
# Usage:
#   export MONGO_USER='myuser'
#   export MONGO_PASS='mypass'
#   export ATLAS_HOST='cluster0.abcde.mongodb.net'
#   ./connect-mongo-atlas.sh

set -euo pipefail

: "${MONGO_USER:?MONGO_USER env var is required}"
: "${MONGO_PASS:?MONGO_PASS env var is required}"
: "${ATLAS_HOST:?ATLAS_HOST env var is required (e.g. cluster0.abcde.mongodb.net)}"

MONGO_DB="${MONGO_DB:-admin}"
MONGO_APP_NAME="${MONGO_APP_NAME:-pass-nat-check}"
TF_DIR="${TF_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

command -v terraform >/dev/null || { echo "ERROR: terraform not found in PATH" >&2; exit 1; }
command -v jq        >/dev/null || { echo "ERROR: jq not found in PATH"        >&2; exit 1; }
command -v mongosh   >/dev/null || { echo "ERROR: mongosh not found in PATH"   >&2; exit 1; }

echo ">> Fetching Cloud NAT IPs from terraform (dir: $TF_DIR)"
NAT_IPS_JSON="$(terraform -chdir="$TF_DIR" output -json nat_ip_addresses)"
mapfile -t NAT_IPS < <(echo "$NAT_IPS_JSON" | jq -r '.[]')

if [[ "${#NAT_IPS[@]}" -eq 0 ]]; then
  echo "ERROR: no NAT IPs returned from 'terraform output nat_ip_addresses'" >&2
  exit 1
fi

echo ">> Cloud NAT egress IPs (whitelist these in Atlas Network Access):"
for ip in "${NAT_IPS[@]}"; do
  echo "   - $ip"
done

urlencode() {
  local s="$1" i c out=""
  for (( i=0; i<${#s}; i++ )); do
    c="${s:i:1}"
    case "$c" in
      [a-zA-Z0-9.~_-]) out+="$c" ;;
      *) printf -v c '%%%02X' "'$c"; out+="$c" ;;
    esac
  done
  printf '%s' "$out"
}

USER_ENC="$(urlencode "$MONGO_USER")"
PASS_ENC="$(urlencode "$MONGO_PASS")"

URI="mongodb+srv://${USER_ENC}:${PASS_ENC}@${ATLAS_HOST}/${MONGO_DB}?retryWrites=true&w=majority&appName=${MONGO_APP_NAME}"

REDACTED_URI="mongodb+srv://${USER_ENC}:***@${ATLAS_HOST}/${MONGO_DB}?retryWrites=true&w=majority&appName=${MONGO_APP_NAME}"
echo ">> Connecting: $REDACTED_URI"

mongosh "$URI" --quiet --eval '
  const r = db.runCommand({ ping: 1 });
  print("ping        : " + JSON.stringify(r));
  print("hello.me    : " + db.runCommand({ hello: 1 }).me);
  print("currentDb   : " + db.getName());
  print("connected OK");
'
