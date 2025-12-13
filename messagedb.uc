import * as datastore from "datastore";

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

export function addMessage(msg)
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
