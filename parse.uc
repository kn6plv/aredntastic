
import * as protobuf from "protobuf";
import * as crypto from "crypto";

const defaultKey = [ 0xd4, 0xf1, 0xbb, 0x3a, 0x20, 0x29, 0x07, 0x59, 0xf0, 0xbc, 0xff, 0xab, 0xcf, 0x4e, 0x69, 0x01 ];

const packetProto = {
    "1": "from",
    "2": "to",
    "3": "channel",
    "4": "decoded",
    "5": "encrypted",
    "6": "id",
    "7": "rx_time",
    "8": "f:rx_snr",
    "9": "hop_limit",
    "10": "b:want_ack",
    "11": "priority",
    "12": "i:rx_rssi",
    "13": "delayed",
    "14": "b:via_mqtt",
    "15": "hop_start",
    "16": "public_key",
    "17": "b:pki_encrypted",
    "18": "next_hop",
    "19": "relay_node",
    "20": "tx_after",
    "21": "transport_mechanism"
};
const dataProto = {
    "1": "portnum",
    "2": "payload",
    "3": "want_response",
    "4": "dest",
    "5": "source",
    "6": "request_id",
    "7": "reply_id",
    "8": "emoji",
    "9": "bitfield"
};
const positionProto = {
    "1": "i:latitude_i",
    "2": "i:longitude_i",
    "3": "i:altitude",
    "4": "time",
    "5": "location_source",
    "6": "altitude_source",
    "7": "timestamp",
    "8": "timestamp_millis_adjust",
    "9": "altitude_hae",
    "10": "altitude_geoidal_separation",
    "11": "PDOP",
    "12": "HDOP",
    "13": "VDOP",
    "14": "gps_accuracy",
    "15": "ground_speed",
    "16": "ground_track",
    "17": "fix_quality",
    "18": "fix_type",
    "19": "sats_in_view",
    "20": "sensor_id",
    "21": "next_update",
    "22": "seq_number",
    "23": "precision_bits"
};
const userProto = {
    "1": "id",
    "2": "long_name",
    "3": "short_name",
    "4": "macaddr",
    "5": "hw_model",
    "6": "b:is_licensed",
    "7": "role",
    "8": "public_key",
    "9": "b:is_unmessagable"
};
const storeAndForwardProto = {
    "1": "rr",
    "2": "stats",
    "3": "history",
    "4": "p:heartbeat:heartbeat",
    "5": "text"
};
const heartbeatProto = {
    "1": "period",
    "2": "secondary"
};
const deviceMetrics = {
    "1": "battery_level",
    "2": "f:voltage",
    "3": "f:channel_utilization",
    "4": "f:air_util_tx",
    "5": "uptime_seconds"
};
const environmentProto = {
    "1": "f:temperature",
    "2": "f:relative_humidity",
    "3": "f:barometric_pressure",
    "4": "f:gas_resistance",
    "5": "f:voltage",
    "6": "f:current",
    "7": "iaq",
    "8": "f:distance",
    "9": "f:lux",
    "10": "f:white_lux",
    "11": "f:ir_lux",
    "12": "f:uv_lux",
    "13": "f:wind_direction",
    "14": "f:wind_speed",
    "15": "f:weight",
    "16": "f:wind_gust",
    "17": "f:wind_lull",
    "18": "f:radiation",
    "19": "f:rainfall_1h",
    "20": "f:rainfall_24h",
    "21": "soil_moisture",
    "22": "f:soil_temperature"
};
const powerProto = {
    "1": "f:ch1_voltage",
    "2": "f:ch1_current",
    "3": "f:ch2_voltage",
    "4": "f:ch2_current",
    "5": "f:ch3_voltage",
    "6": "f:ch3_current",
    "7": "f:ch4_voltage",
    "8": "f:ch4_current",
    "9": "f:ch5_voltage",
    "10": "f:ch5_current",
    "11": "f:ch6_voltage",
    "12": "f:ch6_current",
    "13": "f:ch7_voltage",
    "14": "f:ch7_current",
    "15": "f:ch8_voltage",
    "16": "f:ch8_current"
};
const telemetryProto = {
    "1": "time",
    "2": "p:device:device_metrics",
    "3": "p:environment:environment_metrics",
    "4": "p:all:air_quality_metrics",
    "5": "p:power:power_metrics",
    "6": "p:all:local_stats",
    "7": "p:all:health_metrics",
    "8": "p:all:host_metrics"
};
const tracerouteProto = {
    "1": "r:fixed32:route",
    "2": "r:int32:snr_towards",
    "3": "r:fixed32:route_back",
    "4": "r:int32:snr_back"
};
const allProtos = {
    packet: packetProto,
    data: dataProto,
    position: positionProto,
    user: userProto,
    storeandforward: storeAndForwardProto,
    telemetry: telemetryProto,
    traceroute: tracerouteProto,
    device: deviceMetrics,
    environment: environmentProto,
    heartbeat: heartbeatProto,
    power: powerProto
};
const portnum2Proto = {
    "1": "textmessage",
    "2": "hardware",
    "3": "position",
    "4": "user",
    "5": "routing",
    "6": "admin",
    "7": "compressed",
    "8": "waypoint",
    "9": "audio",
    "10": "detectionsensor",
    "11": "alert",
    "12": "keyverification",
    "32": "reply",
    "33": "iptunnel",
    "34": "paxcounter",
    "64": "serial",
    "65": "storeandforward",
    "66": "rangetest",
    "67": "telemetry",
    "68": "zps",
    "69": "simulator",
    "70": "traceroute",
    "71": "neighborinfo",
    "72": "atak",
    "73": "mapreport",
    "74": "powerstress",
    "76": "reticulumtunnel",
    "77": "cayenne",
    "257": "atakforwarder"
};

export function parsePacket(pkt) {
    const msg = protobuf.decode(pkt, "packet", allProtos);
    if (msg.encrypted && msg.channel === 31) {
        msg.decoded = crypto.decrypt(msg.from, msg.id, defaultKey, msg.encrypted);
    }
    if (msg.decoded) {
        msg.data = protobuf.decode(msg.decoded, "data", allProtos);
        if (msg.data) {
            delete msg.decoded;
            if (msg.data.payload) {
                if (msg.data.portnum === 1) {
                    msg.data.text = msg.data.payload;
                    delete msg.data.payload;
                }
                else {
                    const protoname = portnum2Proto[`${msg.data.portnum}`] ?? "unknown";
                    msg.data[protoname] = protobuf.decode(msg.data.payload, protoname, allProtos);
                    if (msg.data[protoname]) {
                        //msg.data.payload_bytes = "";
                        //for (let i = 0; i < length(msg.data.payload); i++) {
                        //    msg.data.payload_bytes += sprintf("%02x ", ord(msg.data.payload, i));
                        //}
                        delete msg.data.payload;
                    }
                }
            }
        }
        else {
            delete msg.data;
        }
    }
    return msg;
};
