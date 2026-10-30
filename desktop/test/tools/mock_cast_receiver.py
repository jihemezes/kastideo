#!/usr/bin/env python3
"""Faux récepteur Chromecast pour les tests : TLS, CASTV2, répond comme un Chromecast et télécharge le flux demandé.

Usage : mock_cast_receiver.py PORT CERT KEY
Chaque événement est écrit en JSON sur la sortie standard (une ligne)."""
import json, socket, ssl, struct, sys, threading, urllib.request


def varint(n):
    out = bytearray()
    while n > 0x7F:
        out.append((n & 0x7F) | 0x80)
        n >>= 7
    out.append(n)
    return bytes(out)


def text(field, value):
    b = value.encode()
    return bytes([(field << 3) | 2]) + varint(len(b)) + b


def encode(src, dst, ns, payload):
    body = b"\x08\x00" + text(2, src) + text(3, dst) + text(4, ns) + b"\x28\x00" + text(6, payload)
    return struct.pack(">I", len(body)) + body


def decode(data):
    i, out = 0, {}
    def rv():
        nonlocal i
        r = s = 0
        while True:
            b = data[i]; i += 1
            r |= (b & 0x7F) << s
            if not b & 0x80:
                return r
            s += 7
    while i < len(data):
        tag = rv(); f, w = tag >> 3, tag & 7
        if w == 0:
            rv()
        else:
            n = rv(); out[f] = data[i:i + n].decode(); i += n
    return out


def emit(**kw):
    print(json.dumps(kw), flush=True)


def serve(conn):
    buf = b""
    media_id = 1
    def send(src, dst, ns, obj):
        conn.sendall(encode(src, dst, ns, json.dumps(obj)))
    while True:
        try:
            chunk = conn.recv(65536)
        except Exception:
            return
        if not chunk:
            return
        buf += chunk
        while len(buf) >= 4:
            n = struct.unpack(">I", buf[:4])[0]
            if len(buf) < 4 + n:
                break
            m = decode(buf[4:4 + n]); buf = buf[4 + n:]
            p = json.loads(m.get(6, "{}")); t = p.get("type")
            ns = m.get(4, "")
            if t != "PING":
                emit(event=t, ns=ns, to=m.get(3), payload=p)
            if t == "PING":
                send("receiver-0", m[2], ns, {"type": "PONG"})
            elif t == "LAUNCH":
                send("receiver-0", m[2], "urn:x-cast:com.google.cast.receiver", {
                    "type": "RECEIVER_STATUS", "requestId": p["requestId"],
                    "status": {"volume": {"level": 1.0, "muted": False}, "applications": [
                        {"appId": p["appId"], "transportId": "web-1", "sessionId": "sess-1"}]}})
            elif t == "LOAD":
                url = p["media"]["contentId"]
                send("web-1", m[2], "urn:x-cast:com.google.cast.media", {
                    "type": "MEDIA_STATUS", "requestId": p["requestId"],
                    "status": [{"mediaSessionId": media_id, "playerState": "PLAYING", "currentTime": 3.5, "media": {}}]})
                def fetch(url=url):
                    try:
                        with urllib.request.urlopen(url, timeout=20) as r:
                            data = r.read(200000)
                            emit(event="FETCHED", bytes=len(data), type=r.headers.get("Content-Type"), head=data[4:8].decode("latin1"))
                    except Exception as e:
                        emit(event="FETCH_ERROR", error=str(e))
                threading.Thread(target=fetch, daemon=True).start()
            elif t in ("PAUSE", "PLAY"):
                send("web-1", m[2], "urn:x-cast:com.google.cast.media", {
                    "type": "MEDIA_STATUS", "requestId": p["requestId"],
                    "status": [{"mediaSessionId": media_id, "playerState": "PAUSED" if t == "PAUSE" else "PLAYING", "currentTime": 4.0}]})


def main():
    port, cert, key = int(sys.argv[1]), sys.argv[2], sys.argv[3]
    ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ctx.load_cert_chain(cert, key)
    s = socket.socket(); s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind(("127.0.0.1", port)); s.listen(4)
    emit(event="READY")
    while True:
        c, _ = s.accept()
        try:
            threading.Thread(target=serve, args=(ctx.wrap_socket(c, server_side=True),), daemon=True).start()
        except Exception as e:
            emit(event="TLS_ERROR", error=str(e))


main()
