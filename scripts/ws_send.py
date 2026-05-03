"""OneBot WebSocket 消息发送 — 最小依赖，纯标准库"""
import socket, random, struct, json, sys, time

def ws_handshake(sock, host, port):
    """发送 WebSocket HTTP upgrade 请求"""
    key = "dGhlIHNhbXBsZSBub25jZQ=="  # 固定 key，合法
    req = (
        f"GET / HTTP/1.1\r\n"
        f"Host: {host}:{port}\r\n"
        f"Upgrade: websocket\r\n"
        f"Connection: Upgrade\r\n"
        f"Sec-WebSocket-Key: {key}\r\n"
        f"Sec-WebSocket-Version: 13\r\n"
        f"\r\n"
    )
    sock.sendall(req.encode())
    resp = sock.recv(4096)
    if b"101" not in resp:
        raise Exception(f"WS handshake failed: {resp.decode(errors='replace')[:200]}")

def ws_send(sock, text):
    """发送 masked WebSocket 文本帧"""
    data = text.encode("utf-8")
    mask = bytes(random.randint(0, 255) for _ in range(4))
    # FIN=1, opcode=1 (text)
    frame = bytearray([0b10000001])
    length = len(data)
    if length < 126:
        frame.append(0b10000000 | length)
    elif length < 65536:
        frame.append(0b10000000 | 126)
        frame += struct.pack(">H", length)
    else:
        frame.append(0b10000000 | 127)
        frame += struct.pack(">Q", length)
    frame += mask
    frame += bytes(b ^ mask[i % 4] for i, b in enumerate(data))
    sock.sendall(frame)

def ws_recv(sock):
    """接收 WebSocket 帧，返回 payload"""
    head = sock.recv(2)
    if len(head) < 2:
        return ""
    opcode = head[0] & 0x0F
    masked = head[1] & 0x80
    length = head[1] & 0x7F
    if length == 126:
        length = struct.unpack(">H", sock.recv(2))[0]
    elif length == 127:
        length = struct.unpack(">Q", sock.recv(8))[0]
    if masked:
        mask = sock.recv(4)
    payload = bytearray()
    while len(payload) < length:
        chunk = sock.recv(min(length - len(payload), 4096))
        if not chunk:
            break
        payload += chunk
    if masked:
        payload = bytearray(b ^ mask[i % 4] for i, b in enumerate(payload))
    return payload.decode("utf-8", errors="replace")

def main():
    target_qq = int(sys.argv[1])
    message = sys.argv[2]
    payload = json.dumps({
        "action": "send_private_msg",
        "params": {
            "user_id": target_qq,
            "message": message
        }
    })

    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(10)
    try:
        sock.connect(("127.0.0.1", 3001))
        ws_handshake(sock, "127.0.0.1", 3001)
        ws_send(sock, payload)
        resp = ws_recv(sock)
        print(resp)
    finally:
        sock.close()

if __name__ == "__main__":
    main()
