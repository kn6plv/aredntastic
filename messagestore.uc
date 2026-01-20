import * as ipmesh from "ipmesh";
import * as channel from "channel";
import * as router from "router";
import * as message from "message";
import * as textmessage from "textmessage";
import * as timers from "timers";

let enabled = false;

const SAVE_INTERVAL = 5 * 60;
const SYNC_DELAY = 30;
const MAX_RESEND = 50;
const stores = {};
const dirty = {};
let maxStoreSize;

function loadStore(namekey)
{
    if (!stores[namekey]) {
        stores[namekey] = platform.load(`messagestore.${namekey}`) ?? {
            index: {},
            messages: []
        };
    }
    return stores[namekey];
}

function saveToPlatform()
{
    for (let namekey in stores) {
        if (dirty[namekey]) {
            dirty[namekey] = false;
            platform.store(`messagestore.${namekey}`, stores[namekey]);
        }
    }
}

function addMessage(msg)
{
    const store = loadStore(msg.namekey);
    const idx = `${msg.from}:${msg.id}`;
    if (!store.index[idx]) {
        store.index[idx] = true;
        msg.stored = true;
        push(store.messages, json(sprintf("%J", msg)));
        sort(store.messages, (a, b) => a.rx_time - b.rx_time);
        while (length(store.messages) > maxStoreSize) {
            const m = shift(store.messages);
            delete store.index[m.id];
        }
        dirty[msg.namekey] = true;
    }
}

function resendMessages(msg)
{
    const resend = msg.data.resend_messages;

    const store = loadStore(resend.namekey);
    const messages = store.messages;
    const mlength = length(messages);

    let start = 0;
    let limit = min(resend.limit, maxStoreSize);
    const cursor = resend.cursor;

    if (cursor && store.index[cursor]) {
        for (let i = mlength - 1; i >= 0; i--) {
            const msg = messages[i];
            if (cursor === `${msg.from}:${msg.id}`) {
                start = i + 1;
                break;
            }
        }
    }
    if (start + limit < mlength) {
        start = mlength - limit;
    }
    else if (start + limit > mlength) {
        limit = mlength - start;
    }
    for (let i = 0; i < limit; i++) {
        ipmesh.send(msg.from, messages[start + i], false);
    }
}

function syncMessages()
{
    const all = channel.getAllChannels();
    for (let i = 0; i < length(all); i++) {
        const namekey = all[i].namekey;
        const stores = platform.getStoresByNamekey(namekey);
        if (stores[0]) {
            const to = stores[0].id;
            const state = textmessage.state(namekey);
            router.queue(message.createMessage(to, null, namekey, "resend_messages", {
                namekey: namekey,
                cursor: state.cursor,
                limit: state.max
            }));
        }
    }
}

export function setup(config)
{
    if (config.messagestore) {
        enabled = true;
        maxStoreSize = config.messagestore.size ?? MAX_RESEND;
        timers.setInterval("messagestore", SAVE_INTERVAL);
    }
    timers.setTimeout("messagesync", SYNC_DELAY);
};

export function tick()
{
    if (timers.tick("messagestore")) {
        saveToPlatform();
    }
    if (timers.tick("messagesync")) {
        syncMessages();
    }
};

export function process(msg)
{
    if (!enabled) {
        return;
    }
    if (msg.data?.text_message) {
        addMessage(msg);
    }
    else if (msg.data?.resend_messages) {
        resendMessages(msg);
    }
};

export function shutdown()
{
    if (enabled) {
        saveToPlatform();
    }
};
