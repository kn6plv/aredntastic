import * as websocket from "websocket";
import * as timers from "timers";
import * as nodedb from "nodedb";
import * as channel from "channel";
import * as textmessage from "textmessage";
import * as router from "router";

const q = [];
let merge = {};

export function setup(config)
{
    timers.setInterval("cmd", 10 * 60);
};

function send(msg)
{
    websocket.send(sprintf("%J", msg));
}

export function queue(msg)
{
    push(q, msg);
    timers.trigger("cmd");
};

export function notify(event, delay)
{
    if (!merge[event]) {
        merge[event] = true;
        push(q, { cmd: event });
    }
    timers.trigger("cmd", delay);
};

function basicNode(node)
{
    const nodeinfo = node?.nodeinfo;
    if (nodeinfo) {
        return {
            id: nodeinfo.id,
            short_name: nodeinfo.short_name,
            long_name: nodeinfo.long_name,
            role: nodeinfo.role,
            lastseen: node.lastseen,
            hops: node.hops
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
    if (timers.tick("cmd")) {
        while (length(q) > 0) {
            const msg = shift(q);

            DEBUG("%J\n", msg);

            if (msg.cmd === "connected") {
                notify("nodes");
                notify("channels");
                notify(`texts ${channel.getLocalChannelByName().namekey}`);
            }
            else if (msg.cmd === "nodes")
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
                send({ reply: msg.cmd, nodes: nodes });
            }
            else if (substr(msg.cmd, 0, 5) === "node ") {
                const node = basicNode(nodedb.getNode(substr(msg.cmd, 5), false));
                if (node) {
                    send({ reply: msg.cmd, node: node });
                }
            }
            else if (substr(msg.cmd, 0, 9) === "fullnode ") {
                const node = fullNode(nodedb.getNode(substr(msg.cmd, 9), false));
                if (node) {
                    send({ reply: msg.cmd, node: node });
                }
            }
            else if (msg.cmd === "channels") {
                const channels = map(channel.getAllChannels(), c => {
                    return { namekey: c.namekey, unread: textmessage.unread(c.namekey) };
                });
                send({ reply: msg.cmd, channels: channels });
            }
            else if (substr(msg.cmd, 0, 8) === "catchup ") {
                const v = split(msg.cmd, " ");
                const unread = textmessages.catchUpMessagesTo(`${v[1]} ${v[2]}`, v[3]);
                send({ reply: msg.cmd, unread: unread });
            }
            else if (substr(msg.cmd, 0, 6) === "texts ") {
                const namekey = substr(msg.cmd, 6);
                const texts = textmessage.getMessages(namekey);
                if (texts) {
                    send({ reply: msg.cmd, texts: texts, unread: textmessage.unread(namekey) });
                }
            }
            else if (substr(msg.cmd, 0, 5) === "text ") {
                const v = split(msg.cmd, " ");
                const namekey = `${v[1]} ${v[2]}`;
                const text = textmessage.getMessage(namekey, v[3]);
                if (text) {
                    send({ reply: msg.cmd, text: text, unread: textmessage.unread(namekey) });
                }
            }
            else if (msg.cmd === "post") {
                if (channel.getLocalChannelByNameKey(msg.namekey)) {
                    const tmsg = textmessage.createMessage(null, msg.namekey, msg.text);
                    router.queue(tmsg);
                } 
            }
        }
        merge = {};
    }
};

export function process(msg)
{
};
