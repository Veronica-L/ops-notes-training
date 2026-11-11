#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
mkdir -p backups
umask 077
STAMP=$(date -u +%Y%m%dT%H%M%SZ)
OUT="backups/notes-$STAMP.db"
test ! -e "$OUT" || { echo 'Backup already exists; retry in one second.' >&2; exit 1; }
sudo docker compose -f "${COMPOSE_FILE:-compose.yaml}" exec -T app python -c "import sqlite3; s=sqlite3.connect('/data/notes.db'); d=sqlite3.connect('/data/backup.db'); s.backup(d); d.close(); s.close()"
sudo docker compose -f "${COMPOSE_FILE:-compose.yaml}" cp app:/data/backup.db "$OUT"
sudo chown "$(id -u):$(id -g)" "$OUT"
chmod 600 "$OUT"
python3 - "$OUT" <<'PY'
import sqlite3, sys
c=sqlite3.connect(sys.argv[1]); result=c.execute('PRAGMA integrity_check').fetchone()[0]
assert result == 'ok', result
print('rows:', c.execute('SELECT count(*) FROM notes').fetchone()[0])
PY
sha256sum "$OUT" > "$OUT.sha256"
echo "Backup saved: $OUT"
