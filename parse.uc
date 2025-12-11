
import * as protobuf from "protobuf";
import * as crypto from "crypto";
import * as channels from "channels";

const portnum2Proto = {
    "2": "hardware",
    //"3": "position",
    //"4": "user",
    //"5": "routing",
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
    //"65": "storeandforward",
    "66": "rangetest",
    //"67": "telemetry",
    "68": "zps",
    "69": "simulator",
    //"70": "traceroute",
    "71": "neighborinfo",
    "72": "atak",
    "73": "mapreport",
    "74": "powerstress",
    "76": "reticulumtunnel",
    "77": "cayenne",
    "257": "atakforwarder"
};
const proto2Portnum = {};

export function registerProto(name, decode, portnum)
{
    protobuf.registerProto(name, decode);
    if (portnum) {
        portnum2Proto[`${portnum}`] = name;
        proto2Portnum[name] = portnum;
    }
};

registerProto(
    "packet",
    {
        "1": "fixed32 from",
        "2": "fixed32 to",
        "3": "uint32 channel",
        "4": "bytes decoded",
        "5": "bytes encrypted",
        "6": "fixed32 id",
        "7": "fixed32 rx_time",
        "8": "float rx_snr",
        "9": "uint32 hop_limit",
        "10": "bool want_ack",
        "11": "enum priority",
        "12": "int32 rx_rssi",
        "13": "enum delayed",
        "14": "bool via_mqtt",
        "15": "uint32 hop_start",
        "16": "bytes public_key",
        "17": "bool pki_encrypted",
        "18": "uint32 next_hop",
        "19": "uint32 relay_node",
        "20": "uint32 tx_after",
        "21": "enum transport_mechanism"
    }
);
registerProto(
    "data",
    {
        "1": "enum portnum",
        "2": "bytes payload",
        "3": "bool want_response",
        "4": "fixed32 dest",
        "5": "fixed32 source",
        "6": "fixed32 request_id",
        "7": "fixed32 reply_id",
        "8": "fixed32 emoji",
        "9": "uint32 bitfield"
    }
);
registerProto(
    "position",
    {
        "1": "sfixed32 latitude_i",
        "2": "sfixed32 longitude_i",
        "3": "int32 altitude",
        "4": "fixed32 time",
        "5": "enum location_source",
        "6": "enum altitude_source",
        "7": "fixed32 timestamp",
        "8": "int32 timestamp_millis_adjust",
        "9": "sint32 altitude_hae",
        "10": "sint32 altitude_geoidal_separation",
        "11": "uint32 PDOP",
        "12": "uint32 HDOP",
        "13": "uint32 VDOP",
        "14": "uint32 gps_accuracy",
        "15": "uint32 ground_speed",
        "16": "uint32 ground_track",
        "17": "uint32 fix_quality",
        "18": "uint32 fix_type",
        "19": "uint32 sats_in_view",
        "20": "uint32 sensor_id",
        "21": "uint32 next_update",
        "22": "uint32 seq_number",
        "23": "uint32 precision_bits"
    },
    3
);
registerProto(
    "user",
    {
        "1": "string id",
        "2": "string long_name",
        "3": "string short_name",
        "4": "bytes macaddr",
        "5": "enum hw_model",
        "6": "bool is_licensed",
        "7": "enum role",
        "8": "bytes public_key",
        "9": "bool is_unmessagable"
    },
    4
);
registerProto(
    "routediscovery",
    {
        "1": "repeated fixed32 route",
        "2": "repeated int32 snr_towards",
        "3": "repeated fixed32 route_back",
        "4": "repeated int32 snr_back"
    }
);
registerProto(
    "routing",
    {
        "1": "proto routediscovery route_request",
        "2": "proto routediscovery route_reply",
        "3": "enum error_reason"
    },
    5
);
registerProto(
    "storeandforward",
    {
        "1": "enum rr",
        "2": "proto statistics stats",
        "3": "proto history history",
        "4": "proto heartbeat heartbeat",
        "5": "bytes text"
    },
    65
);
registerProto(
    "heartbeat",
    {
        "1": "uint32 period",
        "2": "uint32 secondary"
    }
);
registerProto(
    "device",
    {
        "1": "uint32 battery_level",
        "2": "float voltage",
        "3": "float channel_utilization",
        "4": "float air_util_tx",
        "5": "uint32 uptime_seconds"
    }
);
registerProto(
    "environment",
    {
        "1": "float temperature",
        "2": "float relative_humidity",
        "3": "float barometric_pressure",
        "4": "float gas_resistance",
        "5": "float voltage",
        "6": "float current",
        "7": "uint32 iaq",
        "8": "float distance",
        "9": "float lux",
        "10": "float white_lux",
        "11": "float ir_lux",
        "12": "float uv_lux",
        "13": "uint32 wind_direction",
        "14": "float wind_speed",
        "15": "float weight",
        "16": "float wind_gust",
        "17": "float wind_lull",
        "18": "float radiation",
        "19": "float rainfall_1h",
        "20": "float rainfall_24h",
        "21": "uint32 soil_moisture",
        "22": "float soil_temperature"
    }
);
registerProto(
    "power",
    {
        "1": "float ch1_voltage",
        "2": "float ch1_current",
        "3": "float ch2_voltage",
        "4": "float ch2_current",
        "5": "float ch3_voltage",
        "6": "float ch3_current",
        "7": "float ch4_voltage",
        "8": "float ch4_current",
        "9": "float ch5_voltage",
        "10": "float ch5_current",
        "11": "float ch6_voltage",
        "12": "float ch6_current",
        "13": "float ch7_voltage",
        "14": "float ch7_current",
        "15": "float ch8_voltage",
        "16": "float ch8_current"
    }
);
registerProto(
    "telemetry",
    {
        "1": "fixed32 time",
        "2": "proto device device_metrics",
        "3": "proto environment environment_metrics",
        "4": "proto unknown air_quality_metrics",
        "5": "proto power power_metrics",
        "6": "proto unknown local_stats",
        "7": "proto unknown health_metrics",
        "8": "proto unknown host_metrics"
    },
    67
);
registerProto(
    "traceroute",
    {
        "1": "repeated fixed32 route",
        "2": "repeated int32 snr_towards",
        "3": "repeated fixed32 route_back",
        "4": "repeated int32 snr_back"
    },
    70
);

export function decodePacket(pkt)
{
    const msg = protobuf.decode("packet", pkt);
    const channel = channels.getChannelByHash(msg.channel);
    if (channel && msg.encrypted) {
        msg.decoded = crypto.decrypt(msg.from, msg.id, channel.key, msg.encrypted);
        msg.channelname = channel.name;
    }
    if (msg.decoded) {
        const data = protobuf.decode("data", msg.decoded);
        if (data) {
            delete msg.decoded;
            if (data.payload) {
                if (data.portnum === 1) {
                    data.text_message = data.payload;
                    delete data.payload;
                }
                else {
                    const protoname = portnum2Proto[`${data.portnum}`] ?? "unknown";
                    data[protoname] = protobuf.decode(protoname, data.payload);
                    if (data[protoname]) {
                        delete data.payload;
                    }
                }
            }
            msg.data = data;
        }
    }
    return msg;
};

export function encodePacket(msg)
{
    const data = msg.data;
    if (data.text_message) {
        data.portnum = 1;
        data.payload = data.text_message;
        delete data.text_message;
    }
    else {
        for (let protoname in proto2Portnum) {
            if (data[protoname]) {
                data.portnum = proto2Portnum[protoname];
                data.payload = protobuf.encode(protoname, data[protoname]);
                delete data[protoname];
                break;
            }
        }
    }
    msg.decoded = protobuf.encode("data", msg.data);
    delete msg.data;
    const channel = channels.getChannelByName(msg.channelname);
    if (channel) {
        msg.channel = channel.hash;
        msg.encrypted = crypto.encrypt(msg.from, msg.id, channel.key, msg.decoded);
        delete msg.decoded;
    }
    return protobuf.encode("packet", msg);
};
