"""Training-only HTTP service. Bind to loopback or an isolated lab network."""
import json
import os
import sqlite3
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

ROOT = Path(__file__).resolve().parent
DATA = Path(os.environ.get('DATA_DIR', str(ROOT / 'data')))
DATA.mkdir(parents=True, exist_ok=True)
DB = DATA / 'notes.db'
VERSION = (ROOT / 'VERSION').read_text().strip()
DEBUG = os.environ.get('APP_DEBUG', '0') == '1'
with sqlite3.connect(DB) as con:
    con.execute('CREATE TABLE IF NOT EXISTS notes (id INTEGER PRIMARY KEY, text TEXT NOT NULL)')

class Handler(BaseHTTPRequestHandler):
    def respond(self, status, data):
        body = json.dumps(data, ensure_ascii=False).encode('utf-8')
        self.send_response(status)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        try:
            if self.path in ('/', '/version'):
                return self.respond(200, {'service': 'ops-notes', 'version': VERSION})
            if self.path == '/health':
                with sqlite3.connect(DB) as con:
                    con.execute('SELECT count(*) FROM notes').fetchone()
                return self.respond(200, {'status': 'ok'})
            if self.path == '/notes':
                with sqlite3.connect(DB) as con:
                    rows = con.execute('SELECT id,text FROM notes ORDER BY id').fetchall()
                return self.respond(200, {'notes': [{'id': r[0], 'text': r[1]} for r in rows]})
            if self.path == '/debug/config' and DEBUG:
                return self.respond(200, {'debug': True, 'data_dir': str(DATA)})
            return self.respond(404, {'error': 'not found'})
        except sqlite3.Error:
            self.log_error('database operation failed')
            self.respond(503, {'error': 'database unavailable'})

    def do_POST(self):
        if self.path != '/notes':
            return self.respond(404, {'error': 'not found'})
        try:
            size = int(self.headers.get('Content-Length', '0'))
            if not 0 < size <= 4096:
                return self.respond(400, {'error': 'body size must be 1..4096 bytes'})
            data = json.loads(self.rfile.read(size))
            value = data.get('text') if isinstance(data, dict) else None
            if not isinstance(value, str) or not 1 <= len(value.strip()) <= 200:
                return self.respond(400, {'error': 'text must be 1..200 characters'})
            with sqlite3.connect(DB) as con:
                cur = con.execute('INSERT INTO notes(text) VALUES (?)', (value.strip(),))
                record_id = cur.lastrowid
            return self.respond(201, {'id': record_id, 'text': value.strip()})
        except (ValueError, UnicodeError):
            return self.respond(400, {'error': 'invalid JSON'})
        except sqlite3.Error:
            self.log_error('database operation failed')
            return self.respond(503, {'error': 'database unavailable'})

if __name__ == '__main__':
    host = os.environ.get('APP_HOST', '127.0.0.1')
    port = int(os.environ.get('APP_PORT', '8000'))
    print(f'ops-notes {VERSION} listening on {host}:{port}', flush=True)
    ThreadingHTTPServer((host, port), Handler).serve_forever()
