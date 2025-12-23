import * as node from "node";
import * as channel from "channel";

let enabled = false;

function loadMessages(namekey)
{
    return platform.load(`messages.${namekey}`) ?? {
        index: {},
        messages: []
    };
}

function saveMessages(namekey, messages)
{
    platform.store(`messages.${namekey}`, messages);
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
        cmd.notify(`newtext ${msg.namekey} ${idx}`);
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
