import * as datastore from "datastore";
import * as node from "node";

let messages;

function loadMessages()
{
    if (!messages) {
        messages = datastore.load("messages") ?? [];
    }
}

function saveMessages()
{
    datastore.store("messages", messages);
}

function addMessage(msg)
{
    loadMessages();
    push(messages, {
        from: msg.from,
        channel_name: msg.channel_name,
        channel_key: msg.channel_key,
        when: msg.rx_time,
        text: text
    });
    sort(messages, (a, b) => a.when - b.when);
    saveMessages();
};

export function tick()
{
};

export function process(msg)
{
    if (node.forMe(msg) && msg.data?.text_message) {
        addMessage(msg);
    }
};
