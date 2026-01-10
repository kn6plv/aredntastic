import * as socket from "socket";
import * as struct from "struct";
import * as crypto from "crypto.crypto";

const PORT = 4404;

const MAGIC_KEY = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";

const S_HTTPHEADER = 0;
const S_MSGRECV = 1;

const OP_TEXT = 1;
const OP_BINARY = 2;
const OP_PING = 9;
const OP_PONG = 10;
const FIN = 128;

let s = null;
let allhandles = [];
const states = {};

export function setup(config)
{
    if (!config.websocket) {
        return;
    }
    s = socket.create(socket.AF_INET, socket.SOCK_STRAM, 0);
    s.setopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1);
    s.bind({
        port: config.websocket.port ?? PORT
    });
    s.listen();
    push(allhandles, s);
};

export function handles()
{
    return allhandles;
};

function close(handle)
{
    delete states[handle];
    const i = index(allhandles, handle);
    if (i !== -1) {
        splice(allhandles, i, 1);
    }
    handle.close();
}

function accept()
{
    const ns = s.accept();
    if (ns) {
        push(allhandles, ns);
        states[ns] = {
            state: S_HTTPHEADER,
            s: ns,
            incoming: "",
            msg: "",
            opcode: 0
        };
    }
    return [];
}

function decode(state)
{
    const messages = [];
    for (;;) {
        if (length(state.incoming) < 6) {
            break;
        }
        else {
            let mask;
            let off;
            const opcode = ord(state.incoming, 0);
            let len = ord(state.incoming, 1) & 127;
            if (len === 126) {
                if (length(state.incoming) >= 8) {
                    len = (ord(state.incoming, 2) << 8) | ord(state.incoming, 3);
                    mask = [ ord(state.incoming, 4), ord(state.incoming, 5), ord(state.incoming, 6), ord(state.incoming, 7) ];
                    off = 8;
                }
                else {
                    len = -1;
                }
            }
            else if (len === 127) {
                if (length(state.incoming) >= 14) {
                    len = (ord(state.incoming, 2) << 56) | (ord(state.incoming, 3) << 48) | (ord(state.incoming, 4) << 40) | (ord(state.incoming, 5) << 32) |
                          (ord(state.incoming, 6) << 24) | (ord(state.incoming, 7) << 16) | (ord(state.incoming, 8) << 8) | ord(state.incoming, 9);
                    mask = [ ord(state.incoming, 10), ord(state.incoming, 11), ord(state.incoming, 12), ord(state.incoming, 13) ];
                    off = 14;
                }
                else {
                    len = -1;
                }
            }
            else {
                mask = [ ord(state.incoming, 2), ord(state.incoming, 3), ord(state.incoming, 4), ord(state.incoming, 5) ];
                off = 6;
            }
            if (len >= 0 && off + len <= length(state.incoming)) {
                for (let i = 0; i < len; i++) {
                    state.msg += chr(ord(state.incoming, off + i) ^ mask[i & 3]);
                }
                state.incoming = substr(state.incoming, off + len);
                if (opcode & 15) {
                    state.opcode = opcode & 15;
                }
                if (opcode & 128) {
                    switch (state.opcode) {
                        case OP_TEXT:
                            push(messages, state.msg);
                            break;
                        case OP_PING:
                            state.s.send(struct.pack("2B", FIN | OP_PONG, l) + state.msg);
                            break;
                        case OP_BINARY:
                        default:
                            break;
                    }
                    state.opcode = 0;
                    state.msg = "";
                }
            }
            else {
                break;
            }
        }
    }
    return messages;
}

function encodeHeader(msg)
{
    const l = length(msg);
    if (l < 126) {
        return struct.pack(">BB", FIN | OP_TEXT, l);
    }
    else if (l < 65536) {
        return struct.pack(">BBH", FIN | OP_TEXT, 126, l);
    }
    else {
        return struct.pack(">BBQ", FIN | OP_TEXT, 127, l);
    }
}

function read(ns)
{
    const state = states[ns];
    if (!state) {
        return [];
    }
    switch (state.state) {
        case S_HTTPHEADER:
        {
            const data = ns.recv();
            if (!data || length(data) === 0) {
                close(ns);
                return [];
            }
            state.incoming += data;
            const i = index(state.incoming, "\r\n\r\n");
            if (i !== -1) {
                let key = null;
                const lines = split(substr(state.incoming, 0, i), "\r\n");
                if (platform.auth(lines)) {
                    for (let l = 0; l < length(lines); l++) {
                        const line = lines[l];
                        const kv = split(line, ": ");
                        if (lc(kv[0]) === "sec-websocket-key") {
                            key = kv[1];
                        }
                    }
                }
                if (!key) {
                    close(ns);
                }
                else {
                    const digest = b64enc(crypto.sha1hash(`${key}${MAGIC_KEY}`));
                    ns.send(`HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Accept: ${digest}\r\n\r\n`);
                    state.state = S_MSGRECV;
                    state.incoming = substr(state.incoming, i + 4);
                    return [ '{"cmd":"connected"}', ...decode(state) ];
                }
            }
            break;
        }
        case S_MSGRECV:
        {
            const data = ns.recv();
            if (!data || length(data) === 0) {
                close(ns);
                return;
            }
            state.incoming += data;
            return decode(state);
        }
        default:
            break;
    }
    return [];
}

export function recv(handle)
{
    return handle === s ? accept() : read(handle);
};

export function send(msg)
{
    const hdr = encodeHeader(msg);
    for (let i = 1; i < length(allhandles); i++) {
        const r = allhandles[i].sendmsg([ hdr, msg ]);
        if (r === null) {
            printf("websocket:send error: %s\n", socket.error());
        }
    }
};
