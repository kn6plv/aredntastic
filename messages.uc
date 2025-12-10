import * as math from "math";
import * as fs from "fs";

const MAX_TEXT_MESSAGE_LENGTH = 200;

const ROOT = "/tmp/at";

let messages;

function getMessages()
{
    if (!messages) {
        messages = json(fs.readfile(`${ROOT}/messages.json`) ?? "[]");
    }
    return messages;
}

function saveMessages()
{
    fs.writefile(`${ROOT}/messages.json`, sprintf("%.2J", messages));
}

export function createMessage(from, to, type, payload)
{
    return {
        from: from.id(),
        to: to?.id() ?? 0xffffffff, // Broadcast by default
        channel: 31,
        id: math.rand(),
        rx_time: time(),
        rx_snr: 0,
        hop_limit: 5,
        priority: 64,
        rx_rssi: 0,
        hop_start: 5,
        relay_node: from.id() & 255,
        transport_mechanism: 6, // multicast udp
        data: {
            bitfield: 0,
            [type]: payload
        }
    };
};

export function createTextMessage(from, to, text)
{
    return createMessage(from, to, "text_message", substr(text, 0, MAX_TEXT_MESSAGE_LENGTH));
};

export function updateMessage(msg)
{
    const text = msg.data?.text_message;
    if (text) {
        getMessages();
        push(messages, {
            from: msg.from,
            when: msg.rx_time,
            text: text
        });
        sort(messages, (a, b) => a.when - b.when);
        saveMessages();
    }
};
