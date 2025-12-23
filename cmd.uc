import * as websocket from "websocket";
import * as timers from "timers";
import * as nodedb from "nodedb";

const q = [];

export function setup(config)
{
    timers.setInterval("cmd", 1 * 60);
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

export function tick()
{
    if (timers.tick("cmd")) {
        while (length(q) > 0) {
            const msg = shift(q);

            DEBUG("%.2J\n", msg);

            switch (msg.cmd) {
                case "nodes":
                {
                    const raw = nodedb.getNodes();
                    const nodes = [];
                    for (let i = 0; i < length(raw); i++) {
                        const nodeinfo = raw[i].nodeinfo;
                        if (nodeinfo) {
                            push(nodes, {
                                id: nodeinfo.id,
                                short_name: nodeinfo.short_name,
                                long_name: nodeinfo.long_name,
                                role: nodeinfo.role,
                                lastseen: raw[i].lastseen
                            });
                        }
                    }
                    send({ reply: "nodes", nodes: nodes });
                    break;
                }
                default:
                    break;
            }
        }
    }
};

export function process(msg)
{

};
