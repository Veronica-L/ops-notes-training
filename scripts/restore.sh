#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
BACKUP=$(realpath -- "${1:?Usage: bash scripts/restore.sh backups/notes-TIMESTAMP.db}")
BACKUP_ROOT=$(realpath -- backups)
case "$BACKUP" in "$BACKUP_ROOT"/*.db) ;; *) echo 'Only backups/*.db accepted.' >&2; exit 1;; esac
test -f "$BACKUP"
python3 - "$BACKUP" <<'PY'
import sqlite3, sys
c=sqlite3.connect('file:'+sys.argv[1]+'?mode=ro',uri=True)
assert c.execute('PRAGMA integrity_check').fetchone()[0] == 'ok'
c.execute('SELECT count(*) FROM notes').fetchone()
PY
echo 'This replaces the lab database. Make a fresh backup first.'
read -r -p 'Type RESTORE to continue: ' ANSWER
test "$ANSWER" = RESTORE || exit 1
sudo docker compose -f "${COMPOSE_FILE:-compose.yaml}" stop gateway app
sudo docker compose -f "${COMPOSE_FILE:-compose.yaml}" run --rm --no-deps --user 0:0 \
  -v "$BACKUP:/backup/restore.db:ro" --entrypoint python app -c \
  "import sqlite3,os; s=sqlite3.connect('/backup/restore.db'); d=sqlite3.connect('/data/notes.db'); s.backup(d); d.close(); s.close(); os.chown('/data/notes.db',10001,10001)"
sudo docker compose -f "${COMPOSE_FILE:-compose.yaml}" up -d
echo 'Restored. Verify health, version and records using the manual.'
