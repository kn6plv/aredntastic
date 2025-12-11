import * as math from "math";
import * as datastore from "datastore";
import * as node from "node";

const MAX_TEXT_MESSAGE_LENGTH = 200;
const TRANSPORT_MECHANISM_MULTICAST_UDP = 6;
const DEFAULT_HOPS = 5;
const DEFAULT_PRIORITY = 64;
const BITFIELD_MQTT_OKAY = 1;

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

export function createMessage(to, from, channelname, type, payload, extra)
{
    const fid = from ?? node.id(); // From me by default;
    const msg = {
        from: fid,
        to: to ?? node.BROADCAST,
        channelname: channelname,
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
    return createMessage(msg.from, msg.to, msg.channelname, type, payload, {
        data: {
            request_id: msg.id
        }
    });
};

export function createTextMessage(to, from, channel, text)
{
    return createMessage(to, from, channel, "text_message", substr(text, 0, MAX_TEXT_MESSAGE_LENGTH));
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
            channelname: msg.channelname,
            when: msg.rx_time,
            text: text
        });
        sort(messages, (a, b) => a.when - b.when);
        saveMessages();
    }
};
