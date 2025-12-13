import * as math from "math";
import * as datastore from "datastore";
import * as node from "node";
import * as channels from "channels";
import * as parse from "parse";

const MAX_TEXT_MESSAGE_LENGTH = 200;
const DEFAULT_HOPS = 5;
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

let messages;

function getMessages()
{
    if (!messages) {
        messages = datastore.load("messages") ?? [];
    }
    return messages;
}

function saveMessages()
{
    datastore.store("messages", messages);
}

export function createMessage(to, from, channel_name, type, payload, extra)
{
    const channel = channels.getChannelByName(channel_name);
    const fid = from ?? node.id(); // From me by default;
    const msg = {
        from: fid,
        to: to ?? node.BROADCAST,
        channel_name: channel.name,
        channel_key: channel.key,
        channel: channel.hash,
        id: math.rand(),
        rx_time: time(),
        rx_snr: 0,
        hop_limit: DEFAULT_HOPS,
        priority: DEFAULT_PRIORITY,
        rx_rssi: 0,
        hop_start: DEFAULT_HOPS,
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
    return createMessage(msg.from, msg.to, msg.channel_name, type, payload, {
        data: {
            request_id: msg.id
        }
    });
};

export function createTextMessage(to, from, channel, text)
{
    return createMessage(to, from, channel, "text_message", substr(text, 0, MAX_TEXT_MESSAGE_LENGTH));
};

export function createAckMessage(msg, reason)
{
    return createMessage(msg.from, msg.to, msg.channel_name, "routing", {
        error_reason: reason ?? 0
    }, {
        priority: ACK_PRIORITY,
        data: {
            request_id: msg.id
        }
    });
};

export function tick()
{
};

export function process(msg)
{
    if (!node.forMe(msg)) {
        return;
    }
    const text = msg.data?.text_message;
    if (text) {
        getMessages();
        push(messages, {
            from: msg.from,
            channel_name: msg.channel_name,
            channel_key: msg.channel_key,
            when: msg.rx_time,
            text: text
        });
        sort(messages, (a, b) => a.when - b.when);
        saveMessages();
    }
};
