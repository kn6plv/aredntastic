import * as math from "math";
import * as node from "node";
import * as channel from "channel";
import * as meshtastic from "meshtastic";

const MAX_TEXT_MESSAGE_LENGTH = 200;
const DEFAULT_PRIORITY = 64;
const ACK_PRIORITY = 120;

meshtastic.registerProto(
    "routediscovery", null,
    {
        "1": "repeated fixed32 route",
        "2": "repeated int32 snr_towards",
        "3": "repeated fixed32 route_back",
        "4": "repeated int32 snr_back"
    }
);
meshtastic.registerProto(
    "routing", 5,
    {
        "1": "proto routediscovery route_request",
        "2": "proto routediscovery route_reply",
        "3": "enum error_reason"
    }
);

export function createMessage(to, from, namekey, type, payload, extra)
{
    const hops = node.hopLimit();
    const msg = {
        from: from ?? node.id(), // From me by default
        to: to ?? node.BROADCAST,
        namekey: channel.getChannelByNameKey(namekey)?.namekey,
        id: math.rand(),
        rx_time: time(),
        hop_limit: hops,
        priority: DEFAULT_PRIORITY,
        hop_start: hops,
        data: {
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
