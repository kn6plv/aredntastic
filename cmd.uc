import * as websocket from "websocket";
import * as timers from "timers";
import * as nodedb from "nodedb";
import * as channel from "channel";
import * as textmessage from "textmessage";

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
                    const node = raw[i];
                    const nodeinfo = node.nodeinfo;
                    if (nodeinfo) {
                        push(nodes, {
                            id: nodeinfo.id,
                            short_name: nodeinfo.short_name,
                            long_name: nodeinfo.long_name,
                            role: nodeinfo.role,
                            lastseen: node.lastseen,
                            hops: node.hops
                        });
                    }
                }
                sort(nodes, (a, b) => b.lastseen - a.lastseen);
                send({ reply: msg.cmd, nodes: nodes });
            }
            else if (msg.cmd === "channels") {
                const channels = map(channel.getAllChannels(), c => c.namekey);
                send({ reply: msg.cmd, channels: channels });
            }
            else if (substr(msg.cmd, 0, 6) === "texts ") {
                const texts = textmessage.getMessages(substr(msg.cmd, 6));
                if (texts) {
                    send({ reply: msg.cmd, texts: texts });
                }
            }
            else if (substr(msg.cmd, 0, 8) === "newtext ") {
                const v = split(msg.cmd, " ");
                const text = textmessage.getMessage(`${v[1]} ${v[2]}`, v[3]);
                if (text) {
                    send({ reply: msg.cmd, text: text });
                }
            }
        }
        merge = {};
    }
};

export function process(msg)
{
};
