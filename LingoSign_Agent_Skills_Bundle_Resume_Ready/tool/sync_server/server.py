"""Local demo only: authenticated metadata sync over loopback HTTP, stdlib only."""
import argparse
import hashlib
import hmac
import json
import os
import sqlite3
from contextlib import contextmanager
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse


class Store:
    def __init__(self, path):
        self.path = path
        with self.connect() as db:
            db.executescript('''
                CREATE TABLE IF NOT EXISTS records (id TEXT PRIMARY KEY, payload TEXT NOT NULL);
                CREATE TABLE IF NOT EXISTS operations (id TEXT PRIMARY KEY, fingerprint TEXT NOT NULL);
                CREATE TABLE IF NOT EXISTS changes (seq INTEGER PRIMARY KEY AUTOINCREMENT, payload TEXT NOT NULL);
            ''')

    @contextmanager
    def connect(self):
        db = sqlite3.connect(self.path, timeout=10)
        db.execute('PRAGMA journal_mode=WAL')
        db.execute('PRAGMA synchronous=FULL')
        try:
            with db:
                yield db
        finally:
            db.close()

    def push(self, op):
        if not isinstance(op, dict) or set(op) != {'opId', 'operation', 'record'}:
            raise ValueError('Invalid operation')
        if not isinstance(op['opId'], str) or not 1 <= len(op['opId']) <= 250:
            raise ValueError('Invalid operation id')
        record = op['record']
        if not isinstance(record, dict) or set(record) != {'id', 'signCode', 'label', 'confirmedAt', 'deletedAt'}:
            raise ValueError('Only history metadata is accepted')
        for key in ('id', 'signCode', 'label'):
            if not isinstance(record[key], str) or not 1 <= len(record[key]) <= 200:
                raise ValueError('Invalid text')
        if type(record['confirmedAt']) is not int or record['confirmedAt'] < 0:
            raise ValueError('Invalid timestamp')
        if op['operation'] not in ('upsert', 'delete'):
            raise ValueError('Invalid operation')
        if op['operation'] == 'delete':
            if type(record['deletedAt']) is not int or record['deletedAt'] < 0:
                raise ValueError('Missing deletion timestamp')
        elif record['deletedAt'] is not None:
            raise ValueError('Upsert must not contain tombstone')
        fingerprint = hashlib.sha256(json.dumps(op, sort_keys=True).encode()).hexdigest()
        with self.connect() as db:
            db.execute('BEGIN IMMEDIATE')
            prior = db.execute('SELECT fingerprint FROM operations WHERE id=?', (op['opId'],)).fetchone()
            if prior:
                if prior[0] != fingerprint:
                    raise ValueError('Operation id reused with different payload')
                return
            current = db.execute('SELECT payload FROM records WHERE id=?', (record['id'],)).fetchone()
            # Record identities are immutable. Deletes always win over stale upserts.
            if current:
                old = json.loads(current[0])
                if op['operation'] == 'delete' and old['deletedAt'] is None:
                    old['deletedAt'] = record['deletedAt']
                    record = old
                else:
                    record = old
            payload = json.dumps(record, sort_keys=True)
            if not current or current[0] != payload:
                db.execute('INSERT OR REPLACE INTO records VALUES (?,?)', (record['id'], payload))
                db.execute('INSERT INTO changes(payload) VALUES (?)', (payload,))
            db.execute('INSERT INTO operations VALUES (?,?)', (op['opId'], fingerprint))

    def pull(self, cursor):
        if cursor < 0:
            raise ValueError('Invalid cursor')
        with self.connect() as db:
            rows = db.execute('SELECT seq,payload FROM changes WHERE seq>? ORDER BY seq LIMIT 101', (cursor,)).fetchall()
        page = rows[:100]
        return {'records': [json.loads(row[1]) for row in page],
                'cursor': str(page[-1][0] if page else cursor), 'hasMore': len(rows) > 100}


def make_server(path, token, host='127.0.0.1', port=8765):
    if len(token) < 16:
        raise ValueError('SYNC_TOKEN must contain at least 16 characters')
    store = Store(path)

    class Handler(BaseHTTPRequestHandler):
        def log_message(self, *_):
            pass  # No tokens/history in request logs.

        def send_json(self, status, body):
            payload = json.dumps(body).encode()
            self.send_response(status)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Content-Length', str(len(payload)))
            self.end_headers()
            self.wfile.write(payload)

        def dispatch(self):
            if not hmac.compare_digest(self.headers.get('Authorization', ''), 'Bearer ' + token):
                self.send_json(401, {'error': 'Unauthorized'})
                return
            parsed = urlparse(self.path)
            try:
                if self.command == 'POST' and parsed.path == '/v1/operations':
                    size = int(self.headers.get('Content-Length', '0'))
                    if not 0 < size <= 16384:
                        raise ValueError('Invalid body size')
                    op = json.loads(self.rfile.read(size))
                    store.push(op)
                    self.send_json(200, {'opId': op['opId']})
                elif self.command == 'GET' and parsed.path == '/v1/changes':
                    cursor = int(parse_qs(parsed.query).get('cursor', ['0'])[0])
                    self.send_json(200, store.pull(cursor))
                else:
                    self.send_json(404, {'error': 'Not found'})
            except (ValueError, TypeError, KeyError, OverflowError):
                self.send_json(400, {'error': 'Invalid sync request'})
            except sqlite3.Error:
                self.send_json(503, {'error': 'Storage unavailable'})

        def setup(self):
            super().setup()
            self.connection.settimeout(10)

        do_GET = dispatch
        do_POST = dispatch

    return ThreadingHTTPServer((host, port), Handler)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--db', default='sync-demo.sqlite')
    parser.add_argument('--host', default='127.0.0.1')
    parser.add_argument('--port', type=int, default=8765)
    args = parser.parse_args()
    server = make_server(args.db, os.environ.get('SYNC_TOKEN', ''), args.host, args.port)
    print(f'READY {server.server_port}', flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
