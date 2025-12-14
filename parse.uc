
import * as protobuf from "protobuf";
import * as crypto from "crypto";
import * as channel from "channel";

/*
 * Known port numbers
 *
 *  2 - hardware
 *  3 - position
 *  4 - user
 *  5 - routing
 *  6 - admin
 *  7 - compressed
 *  8 - waypoint
 *  9 - audio
 * 10 - detectionsensor
 * 11 - alert
 * 12 - keyverification
 * 32 - reply
 * 33 - iptunnel
 * 34 - paxcounter
 * 64 - serial
 * 65 - storeandforward
 * 66 - rangetest
 * 67 - telemetry
 * 68 - zps
 * 69 - simulator
 * 70 - traceroute
 * 71 - neighborinfo
 * 72 - atak
 * 73 - mapreport
 * 74 - powerstress
 * 76 - reticulumtunnel
 * 77 - cayenne
 * 257 - atakforwarder
 */

const portnum2Proto = {};
const proto2Portnum = {};

export function registerProto(name, portnum, decode)
{
    protobuf.registerProto(name, decode);
    if (portnum) {
        portnum2Proto[portnum] = name;
        proto2Portnum[name] = portnum;
    }
};

registerProto(
    "packet", null,
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
    "data", null,
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

/* --- Unused ---

registerProto(
    "storeandforward", 65,
    {
        "1": "enum rr",
        "2": "proto statistics stats",
        "3": "proto history history",
        "4": "proto heartbeat heartbeat",
        "5": "bytes text"
    }
);
registerProto(
    "heartbeat", null,
    {
        "1": "uint32 period",
        "2": "uint32 secondary"
    }
);
registerProto(
    "power_metrics", null,
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

 --- */

 function decodePacketData(msg)
 {
    if (msg.decoded) {
        const data = protobuf.decode("data", msg.decoded);
        if (data && data.portnum !== null && data.payload && data.bitfield !== null) {
            delete msg.decoded;
            if (data.portnum === 1) {
                data.text_message = data.payload;
                delete data.payload;
                msg.data = data;
                return msg;
            }
            const protoname = portnum2Proto[`${data.portnum}`];
            if (protoname) {
                data[protoname] = protobuf.decode(protoname, data.payload);
                if (data[protoname]) {
                    delete data.payload;
                    msg.data = data;
                    return msg;
                }
            }
        }
    }
    return null;
 }

export function decodePacket(pkt)
{
    const msg = protobuf.decode("packet", pkt);
    if (!msg.encrypted) {
        return decodePacketData(msg);
    }
    const hashchannels = channel.getChannelsByHash(msg.channel);
    if (!hashchannels) {
        return null;
    }
    for (let i = 0; i < length(hashchannels); i++) {
        const chan = hashchannels[i];
        msg.decoded = crypto.decrypt(msg.from, msg.id, chan.crypto, msg.encrypted);
        msg.namekey = chan.namekey;
        if (decodePacketData(msg)) {
            return msg;
        }
    }
    return null;
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
    const chan = channel.getChannelByNameKey(msg.namekey);
    if (chan) {
        msg.encrypted = crypto.encrypt(msg.from, msg.id, chan.crypto, msg.decoded);
        delete msg.decoded;
    }
    return protobuf.encode("packet", msg);
};
