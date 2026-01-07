import * as node from "node";
import * as channel from "channel";
import * as message from "message";
import * as timers from "timers";

let enabled = false;

const MAX_MESSAGES = 100;
const SAVE_INTERVAL = 5 * 60;

const channelmessages = {};
const channelmessagesdirty = {};

function loadMessages(namekey)
{
    if (!channelmessages[namekey]) {
        channelmessages[namekey] = platform.load(`messages.${namekey}`) ?? {
            max: MAX_MESSAGES,
            index: {},
            count: 0,
            cursor: null,
            messages: []
        };
    }
    return channelmessages[namekey];
}

function saveMessages(namekey, chanmessages)
{
    const messages = chanmessages.messages;
    const cursor = chanmessages.cursor;
    let count = 0;
    for (let i = length(messages) - 1; i >= 0; i--) {
        if (messages[i].id === cursor) {
            break;
        }
        count++;
    }
    chanmessages.count = count;
    if (count === length(messages)) {
        chanmessages.cursor = null;
    }
    channelmessagesdirty[namekey] = true;
    platform.badge(`messages.${namekey}`, chanmessages.count);
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
        while (length(chanmessages.messages) > chanmessages.max) {
            const m = shift(chanmessages.messages);
            delete chanmessages.index[m.id];
        }
        sort(chanmessages.messages, (a, b) => a.when - b.when);
        saveMessages(msg.namekey, chanmessages);
        event.notify({ cmd: "text", namekey: msg.namekey, id: idx }, `text ${msg.namekey} ${idx}`);
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
    const cm = loadMessages(namekey);
    if (cm.index[id] && id !== cm.cursor) {
        cm.cursor = id;
        saveMessages(namekey, cm);
    }
    return { count: cm.count, cursor: cm.cursor, max: cm.max };
};

export function unread(namekey)
{
    const cm = loadMessages(namekey);
    return { count: cm.count, cursor: cm.cursor, max: cm.max };
};

export function setup(config)
{
    if (config.messages) {
        enabled = true;
        timers.setInterval("textmessages", SAVE_INTERVAL);
    }
};

function saveToPlatform()
{
    for (let namekey in channelmessages) {
        if (channelmessagesdirty[namekey]) {
            channelmessagesdirty[namekey] = false;
            platform.store(`messages.${namekey}`, channelmessages[namekey]);
        }
    }
}

export function shutdown()
{
    saveToPlatform();
};

export function isMessagable()
{
    return enabled;
};

export function tick()
{
    if (timers.tick("textmessages")) {
        saveToPlatform();
    }
};

export function process(msg)
{
    if (enabled && msg.data?.text_message && node.forMe(msg) && channel.getLocalChannelByNameKey(msg.namekey)) {
        addMessage(msg);
    }
};
