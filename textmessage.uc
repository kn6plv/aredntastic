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
        namekey: msg.namekey,
        when: msg.rx_time,
        text: msg.data.text_message
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
