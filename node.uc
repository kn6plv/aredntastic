import * as struct from "struct";
import * as math from "math";
import * as crypto from "crypto";

const LOCATION_PRECISION = 16;

export const ROLE_CLIENT = 0;
export const ROLE_CLIENT_MUTE = 1;

let me = null;

export const BROADCAST = 0xffffffff;

export function id()
{
    return me.id;
};

export function forMe(msg)
{
    return msg.to === BROADCAST || msg.to === me.id;
};

export function isBroadcast(msg)
{
    return msg.to === BROADCAST;
};

export function toMe(msg)
{
    return msg.to === me.id;
};

export function fromMe(msg)
{
    return msg.from === me.id;
};

function save()
{
    platform.store("node", me);
};

function createNode()
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
        public_key: keypair.public,
        lat: 0.0,
        lon: 0.0,
        alt: 0,
        percision: LOCATION_PRECISION,
        role: ROLE_CLIENT_MUTE
    };
    save();
    return me;
};

export function setup(config)
{
    me = platform.load("node") ?? createNode();
    const location = config?.location ?? platform.getLocation();
    me.lat = location.latitude ?? me.lat;
    me.lon = location.longitude ?? me.lon;
    me.alt = location.altitude ?? me.alt;
    me.percision = location.percision ?? me.percision;
    if (config?.long_name) {
        me.long_name = config.long_name;
    }
    if (config?.short_name) {
        me.short_name = config.short_name;
    }
    switch (config?.role) {
        case "client":
            me.role = ROLE_CLIENT;
            break;
        case "client_mute":
            me.role = ROLE_CLIENT_MUTE;
            break;
        default:
            print(`Unknown role: ${config?.role}\n`);
            break;
    }
    save();
};

export function getInfo()
{
    return me;
};
