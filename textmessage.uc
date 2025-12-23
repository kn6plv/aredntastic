import * as node from "node";
import * as channel from "channel";
import * as message from "message";

let enabled = false;

function loadMessages(namekey)
{
    return platform.load(`messages.${namekey}`) ?? {
        index: {},
        cursor: null,
        messages: []
    };
}

function saveMessages(namekey, chanmessages)
{
    let count = 0;
    if (!chanmessages.cursor) {
        count = length(chanmessages.messages);
    }
    else {
        const messages = chanmessages.messages;
        const cursor = chanmessages.cursor;
        for (let i = length(messages) - 1; i >= 0; i--) {
            if (messages[i].id === cursor) {
                break;
            }
            count++;
        }
    }
    chanmessages.count = count;
    platform.store(`messages.${namekey}`, chanmessages);
    platform.badge(`messages.${namekey}`, count);
}

function addMessage(msg)
{
    const chanmessages = loadMessages(msg.namekey);
    const idx = `${msg.from}:${msg.id}`;
    if (!chanmessages.index[idx]) {
        chanmessages.index[idx] = true;
        push(chanmessages.messages, {
            id: idx,
            from: msg.from,
            when: msg.rx_time,
            text: msg.data.text_message
        });
        sort(chanmessages.messages, (a, b) => a.when - b.when);
        saveMessages(msg.namekey, chanmessages);
        cmd.notify(`text ${msg.namekey} ${idx}`);
    }
};

export function getMessages(namekey)
{
    return loadMessages(namekey).messages;
};

export function getMessage(namekey, id)
{
    const chanmessages = loadMessages(namekey);
    if (chanmessages && chanmessages.index[id]) {
        const messages = chanmessages.messages;
        for (let i = length(messages) - 1; i >= 0; i--) {
            const message = messages[i];
            if (message.id === id) {
                return message;
            }
        }
    }
    return null;
};

export function createMessage(to, namekey, text)
{
    return message.createTextMessage(to, null, namekey, text);
};

export function catchUpMessagesTo(namekey, id)
{
    const chanmessages = loadMessages(namekey);
    if (chanmessages.index[id] && id !== chanmessages.cursor) {
        chanmessages.cursor = id;
        saveMessages(chanmessages);
    }
    return chanmessages.count;
};

export function unread(namekey)
{
    return loadMessages(namekey).count;
};

export function setup(config)
{
    if (config.messages) {
        enabled = true;
    }
};

export function isMessagable()
{
    return enabled;
};

export function tick()
{
};

export function process(msg)
{
    if (enabled && msg.data?.text_message && node.forMe(msg) && channel.getLocalChannelByNameKey(msg.namekey)) {
        addMessage(msg);
    }
};
