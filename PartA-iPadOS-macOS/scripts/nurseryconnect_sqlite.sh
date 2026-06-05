#!/usr/bin/env bash
# Locate the Core Data SQLite store for NurseryConnect (Simulator) and run helper commands.
# Use this when you want to view or UPDATE rows outside the app (advanced / dev only).
#
# Core Data tables in this project (from NurseryConnect.xcdatamodeld):
#   ZCHILD      — children (Z_PK primary key)
#   ZINCIDENT   — incidents; ZCHILD column = ZCHILD.Z_PK (which child)
#   ZDIARYENTRY — diary; ZCHILD column = ZCHILD.Z_PK
#
# Important:
#   • Z_OPT — Core Data row version; after any manual UPDATE, bump it: SET Z_OPT = Z_OPT + 1
#   • ZID — UUID stored as 16-byte BLOB; avoid editing unless you replace with another valid UUID blob
#   • TIMESTAMP columns — Core Data stores NSDate as CFAbsoluteTime (seconds since 2001-01-01 00:00 UTC)
#   • Booleans — INTEGER 0 or 1 (e.g. ZPHOTOCONSENT, ZISPARENTNOTIFIED)
#   • Quit the Simulator app or stop the app before editing, or the DB may be locked / overwritten
#
# Examples (sqlite3):
#   UPDATE ZCHILD SET ZFIRSTNAME = 'Jane', ZLASTNAME = 'Doe', Z_OPT = Z_OPT + 1 WHERE Z_PK = 1;
#   UPDATE ZINCIDENT SET ZSTATUS = 'draft', Z_OPT = Z_OPT + 1 WHERE Z_PK = 1;
#
# Incident.status (ZSTATUS) should match IncidentStatus raw values: draft, submitted, managerReviewed,
# parentNotified, acknowledged. Incident.category / severity must match IncidentCategory / IncidentSeverity
# raw strings used in code (see those enums in the Xcode project).

set -euo pipefail

ROOT="${NURSERYCONNECT_SQLITE:-}"

if [[ -z "$ROOT" ]]; then
  while IFS= read -r line; do
    ROOT="$line"
  done < <(find "${HOME}/Library/Developer/CoreSimulator/Devices" -name "NurseryConnect.sqlite" 2>/dev/null | while read -r f; do
    printf '%s\t%s\n' "$(stat -f '%m' "$f" 2>/dev/null || echo 0)" "$f"
  done | sort -nr | head -1 | cut -f2-)
fi

usage() {
  cat <<EOF
Usage:
  NURSERYCONNECT_SQLITE=/path/to/NurseryConnect.sqlite $0 <command>

Commands:
  path      Print path to the newest Simulator NurseryConnect.sqlite (or set NURSERYCONNECT_SQLITE).
  schema    Show CREATE TABLE for ZCHILD, ZINCIDENT, ZDIARYENTRY.
  sample    Show a few rows (read-only).
  sql       Open interactive sqlite3 on the store (READWRITE; quit Simulator / app first).

Column notes and UPDATE examples are in the comment block at the top of this script.
EOF
}

if [[ -z "${1:-}" ]]; then
  usage
  exit 1
fi

if [[ -z "$ROOT" || ! -f "$ROOT" ]]; then
  echo "Could not find NurseryConnect.sqlite. Run the app once in Simulator, or set:" >&2
  echo "  export NURSERYCONNECT_SQLITE=/path/to/Library/Application Support/NurseryConnect.sqlite" >&2
  exit 1
fi

cmd="$1"
shift || true

case "$cmd" in
  path)
    printf '%s\n' "$ROOT"
    ;;
  schema)
    sqlite3 "$ROOT" ".schema ZCHILD" ".schema ZINCIDENT" ".schema ZDIARYENTRY"
    ;;
  sample)
    sqlite3 -header -column "$ROOT" \
      "SELECT Z_PK, ZFIRSTNAME, ZLASTNAME, ZROOMNAME, ZKEYWORKERNAME FROM ZCHILD LIMIT 20;" \
      "SELECT Z_PK, ZCHILD, ZSTATUS, ZCATEGORY, ZSEVERITY, ZTIMESTAMP FROM ZINCIDENT LIMIT 20;"
    ;;
  sql)
    exec sqlite3 "$ROOT" "$@"
    ;;
  *)
    echo "Unknown command: $cmd" >&2
    usage
    exit 1
    ;;
esac
