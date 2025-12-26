import * as websocket from "websocket";
import * as timers from "timers";
import * as node from "node";
import * as nodedb from "nodedb";
import * as channel from "channel";
import * as textmessage from "textmessage";
import * as router from "router";

const q = [];
let merge = {};

export function setup(config)
{
    timers.setInterval("event", 10 * 60);
};

function send(msg)
{
    websocket.send(sprintf("%J", msg));
}

export function queue(msg)
{
    push(q, msg);
    timers.trigger("event");
};

export function notify(event, mergekey)
{
    if (!mergekey) {
        mergekey = event.cmd;
    }
    if (!merge[mergekey]) {
        merge[mergekey] = true;
        push(q, event);
    }
    timers.trigger("event");
};

function basicNode(node)
{
    const nodeinfo = node?.nodeinfo;
    if (nodeinfo) {
        return {
            id: nodeinfo.id,
            short_name: nodeinfo.short_name,
            long_name: nodeinfo.long_name,
            role: nodeinfo.role ?? 0,
            lastseen: node.lastseen,
            hops: node.hops,
            hw_model: nodeinfo.hw_model ?? 0
        };
    }
    return null;
}

function fullNode(node)
{
    const nodeinfo = node?.nodeinfo;
    if (nodeinfo) {
    }
    return null;
}

export function tick()
{
    if (timers.tick("event")) {
        while (length(q) > 0) {
            const msg = shift(q);

            DEBUG("%J\n", msg);

            switch (msg.cmd) {
                case "connected":
                {
                    notify({ cmd: "me" });
                    notify({ cmd: "channels" });
                    notify({ cmd: "nodes" });
                    const namekey = channel.getLocalChannelByName().namekey;
                    notify({ cmd: "texts", namekey: namekey }, `texts ${namekey}`);
                    break;
                }
                case "me":
                {
                    const me = node.getInfo();
                    send({ event: msg.cmd, me: { id: me.id }});
                    break;
                }
                case "nodes":
                {
                    const raw = nodedb.getNodes();
                    const nodes = [];
                    for (let i = 0; i < length(raw); i++) {
                        const node = basicNode(raw[i]);
                        if (node) {
                            push(nodes, node);
                        }
                    }
                    sort(nodes, (a, b) => b.lastseen - a.lastseen);
                    send({ event: msg.cmd, nodes: nodes });
                    break;
                }
                case "node":
                {
                    const node = basicNode(nodedb.getNode(msg.id, false));
                    if (node) {
                        send({ event: msg.cmd, node: node });
                    }
                    break;
                }
                case "fullnode":
                {
                    const node = fullNode(nodedb.getNode(msg.id, false));
                    if (node) {
                        send({ event: msg.cmd, node: node });
                    }
                    break;
                }
                case "channels":
                {
                    const channels = map(channel.getAllChannels(), c => {
                        return { namekey: c.namekey, unread: textmessage.unread(c.namekey) };
                    });
                    send({ event: msg.cmd, channels: channels });
                    break;
                }
                case "catchup":
                {
                    const unread = textmessages.catchUpMessagesTo(msg.namekey, msg.id);
                    send({ event: msg.cmd, namekey: msg.namekey, unread: unread });
                    break;
                }
                case "texts":
                {
                    const texts = textmessage.getMessages(msg.namekey);
                    if (texts) {
                        send({ event: msg.cmd, namekey: msg.namekey, texts: texts, unread: textmessage.unread(msg.namekey) });
                    }
                    break;
                }
                case "text":
                {
                    const text = textmessage.getMessage(msg.namekey, msg.id);
                    if (text) {
                        send({ event: msg.cmd, namekey: msg.namekey, text: text, unread: textmessage.unread(msg.namekey) });
                    }
                    break;
                }
                case "post":
                {
                    if (channel.getLocalChannelByNameKey(msg.namekey)) {
                        const tmsg = textmessage.createMessage(null, msg.namekey, msg.text);
                        if (tmsg) {
                            router.queue(tmsg);
                        }
                    }
                    break;
                }
            }
        }
        merge = {};
    }
};

export function process(msg)
{
};
