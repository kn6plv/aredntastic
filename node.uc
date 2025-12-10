import * as fs from "fs";
import * as struct from "struct";
import * as math from "math";
import * as crypto from "crypto";

const ROOT = "/tmp/at";

const ROLE_CLIENT_MUTE = 1;
const PRIVATE_HW = 255;

let me = null;

export function createNode()
{
    const id = [
        math.rand() & 255, math.rand() & 255, math.rand() & 255, math.rand() & 255, math.rand() & 255, math.rand() & 255
    ];
    const keypair = crypto.generateKeyPair();
    me = {
        id: (id[2] << 24) + (id[3] << 16) + (id[4] << 8) + id[5],
        long_name: sprintf("Meshtastic %02x%02x", id[4], id[5]),
        short_name: sprintf("%02x%02x", id[4], id[5]),
        macaddr: struct.pack("6B", id[0], id[1], id[2], id[3], id[4], id[5]),
        private_key: keypair.private,
        public_key: keypair.public
    };
    fs.writefile(`${ROOT}/node.json`, sprintf("%.2J", me));
};

export function getNode()
{
    if (!me) {
        const n = fs.readfile(`${ROOT}/node.json`);
        if (!n) {
            createNode();
        }
        else {
            me = json(n);
        }
    }
    return {
        id: () => me.id,
        info: () => {
            return {
                id: sprintf("!%08x", me.id),
                long_name: me.long_name,
                short_name: me.short_name,
                macaddr: me.macaddr,
                hw_model: PRIVATE_HW,
                role: ROLE_CLIENT_MUTE,
                public_key: substr(me.public_key, -32),
                is_unmessagable: false
            };
        },
        position: () => {
            return {
                latitude_i: 372113000,
                longitude_i: -1219362000,
                altitude: 0,
                time: time(),
                location_source: 1,
                precision_bits: 24

            };
        },
        deviceTelemetry: () => {
            return {
                time: time(),
                device_metrics: {
                    battery_level: 101, // 101 == Grid power
                    uptime_seconds: clock(true)[0]
                }
            };
        }
    };
};
