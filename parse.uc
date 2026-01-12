import * as struct from "struct";
import * as protobuf from "protobuf";
import * as crypto from "crypto.crypto";
import * as channel from "channel";
import * as node from "node";
import * as nodedb from "nodedb";

/*
 * Known port numbers
 *
 *  2 - hardware
 *  3 - position
 *  4 - nodeinfo
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
    if (hashchannels) {
        for (let i = 0; i < length(hashchannels); i++) {
            const chan = hashchannels[i];
            msg.decoded = crypto.decryptCTR(msg.from, msg.id, chan.crypto, msg.encrypted);
            msg.namekey = chan.namekey;
            if (decodePacketData(msg)) {
                delete msg.encrypted;
                return msg;
            }
        }
    }
    if (!node.isBroadcast(msg)) {
        const frompublic = nodedb.getNode(msg.from)?.nodeinfo?.public_key;
        const toprivate = node.toMe(msg) ? node.getInfo().private_key : platform.getTargetById(msg.to)?.key;
        if (frompublic && toprivate) {
            const sharedkey = crypto.getSharedKey(toprivate, crypto.stringToPKey(frompublic));
            const hash = crypto.sha256hash(sharedkey);
            const ciphertext = substr(msg.encrypted, 0, -12);
            const auth = substr(msg.encrypted, -12, 8);
            const xnonce = substr(msg.encrypted, -4);
            msg.decoded = crypto.decryptCCM(msg.from, msg.id, hash, ciphertext, xnonce, auth);
            if (decodePacketData(msg)) {
                msg.namekey = `Private Private`;
                delete msg.encrypted;
                return msg;
            }
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
    if (!data.payload) {
        return null;
    }
    msg.decoded = protobuf.encode("data", msg.data);
    delete msg.data;
    const chan = channel.getChannelByNameKey(msg.namekey);
    if (chan) {
        msg.encrypted = crypto.encryptCTR(msg.from, msg.id, chan.crypto, msg.decoded);
        delete msg.decoded;
        return protobuf.encode("packet", msg);
    }
    else if (!node.isBroadcast(msg)) {
        const topublic = nodedb.getNode(msg.to)?.nodeinfo?.public_key;
        const fromprivate = node.fromMe(msg) ? node.getInfo().private_key : platform.getTargetById(msg.from)?.key;
        if (topublic && fromprivate) {
            const sharedkey = crypto.getSharedKey(fromprivate, crypto.stringToPKey(topublic));
            const hash = crypto.sha256hash(sharedkey);
            const xnonce = struct.pack("4B", math.rand() & 255, math.rand() & 255, math.rand() & 255, math.rand() & 255);
            msg.encrypted = crypto.encryptCCM(msg.from, msg.id, hash, msg.decoded, xnonce, 8) + xnonce;
            delete msg.decoded;
            return protobuf.encode("packet", msg);
        }
    }
    return null;
};
