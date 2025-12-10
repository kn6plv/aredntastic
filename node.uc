import * as struct from "struct";
import * as math from "math";
import * as crypto from "crypto";
import * as datastore from "datastore";

const ROLE_CLIENT = 0;
const PRIVATE_HW = 255;
const GRID_POWER = 101;
const LOCATION_SOURCE_MANUAL = 1;
const LOCATION_PRECISION = 16;

let me = null;

function save()
{
    datastore.store("node", me);
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
        percision: LOCATION_PRECISION
    };
    save();
};

export function setup()
{
    me = datastore.load("node") ?? createNode();
};

export function getInfo()
{
    return {
        id: () => me.id,
        info: () => {
            return {
                id: sprintf("!%08x", me.id),
                long_name: me.long_name,
                short_name: me.short_name,
                macaddr: me.macaddr,
                hw_model: PRIVATE_HW,
                role: ROLE_CLIENT,
                public_key: substr(me.public_key, -32),
                is_unmessagable: false
            };
        },
        position: () => {
            return {
                latitude_i: me.lat * 10000000,
                longitude_i: me.lon * 10000000,
                altitude: me.alt,
                time: time(),
                location_source: LOCATION_SOURCE_MANUAL,
                precision_bits: me.percision

            };
        },
        deviceTelemetry: () => {
            return {
                time: time(),
                device_metrics: {
                    battery_level: GRID_POWER,
                    uptime_seconds: clock(true)[0]
                }
            };
        }
    };
};

export function id()
{
    return me.id;
};

export function setLocation(lat, lon, alt, percision)
{
    me.lat = lat ?? me.lat;
    me.lon = lon ?? me.lon;
    me.alt = alt ?? me.alt;
    me.percision = percision ?? me.percision;
    save();
};

export function setNames(long_name, short_name)
{
    me.long_name = long_name ?? me.long_name;
    me.short_name = short_name ?? me.short_name;
    save();
};
