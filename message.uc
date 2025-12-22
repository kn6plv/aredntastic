import * as math from "math";
import * as node from "node";
import * as channel from "channel";
import * as parse from "parse";

const MAX_TEXT_MESSAGE_LENGTH = 200;
const DEFAULT_PRIORITY = 64;
const ACK_PRIORITY = 120;
const BITFIELD_MQTT_OKAY = 1;

export const TRANSPORT_MECHANISM_UNICAST_UDP = 251;
export const TRANSPORT_MECHANISM_MULTICAST_UDP = 6;

parse.registerProto(
    "routediscovery", null,
    {
        "1": "repeated fixed32 route",
        "2": "repeated int32 snr_towards",
        "3": "repeated fixed32 route_back",
        "4": "repeated int32 snr_back"
    }
);
parse.registerProto(
    "routing", 5,
    {
        "1": "proto routediscovery route_request",
        "2": "proto routediscovery route_reply",
        "3": "enum error_reason"
    }
);

export function createMessage(to, from, namekey, type, payload, extra)
{
    const chan = channel.getChannelByNameKey(namekey);
    const fid = from ?? node.id(); // From me by default;
    const hops = node.hopLimit();
    const msg = {
        from: fid,
        to: to ?? node.BROADCAST,
        namekey: namekey,
        channel: chan?.hash ?? 0,
        id: math.rand(),
        rx_time: time(),
        rx_snr: 0,
        hop_limit: hops,
        priority: DEFAULT_PRIORITY,
        rx_rssi: 0,
        hop_start: hops,
        relay_node: fid & 255,
        transport_mechanism: TRANSPORT_MECHANISM_MULTICAST_UDP,
        data: {
            bitfield: BITFIELD_MQTT_OKAY,
            [type]: payload
        }
    };
    if (extra) {
        for (let k in extra) {
            if (k === "data") {
                for (let j in extra.data) {
                    msg.data[j] = extra.data[j];
                }
            }
            else {
                msg[k] = extra[k];
            }
        }
    }
    return msg;
};

export function createReplyMessage(msg, type, payload)
{
    return createMessage(msg.from, msg.to, msg.namekey, type, payload, {
        data: {
            request_id: msg.id
        }
    });
};

export function createTextMessage(to, from, namekey, text)
{
    return createMessage(to, from, namekey, "text_message", substr(text, 0, MAX_TEXT_MESSAGE_LENGTH));
};

export function createAckMessage(msg, reason)
{
    return createMessage(msg.from, msg.to, msg.namekey, "routing", {
        error_reason: reason ?? 0
    }, {
        priority: ACK_PRIORITY,
        data: {
            request_id: msg.id
        }
    });
};
