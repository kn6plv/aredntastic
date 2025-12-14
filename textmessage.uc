import * as datastore from "datastore";
import * as node from "node";
import * as channel from "channel";

let messages;

function loadMessages(namekey)
{
    return datastore.load(`messages.${namekey}`) ?? {
        index: {},
        messages: []
    };
}

function saveMessages(namekey, messages)
{
    datastore.store(`messages.${namekey}`, messages);
}

function addMessage(msg)
{
    const chanmessages = loadMessages(msg.namekey);
    const idx = `${msg.from}:${msg.id}`;
    if (!chanmessages.index[idx]) {
        chanmessages.index[idx] = true;
        push(chanmessages.messages, {
            from: msg.from,
            when: msg.rx_time,
            text: msg.data.text_message
        });
        sort(chanmessages.messages, (a, b) => a.when - b.when);
        saveMessages(msg.namekey, chanmessages);
    }
};

export function tick()
{
};

export function process(msg)
{
    if (msg.data?.text_message && node.forMe(msg) && channel.getLocalChannelByNameKey(msg.namekey)) {
        addMessage(msg);
    }
};
