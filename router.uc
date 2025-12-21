import * as multicast from "multicast";
import * as unicast from "unicast";
import * as parse from "parse";
import * as node from "node";
import * as message from "message";
import * as socket from "socket";
import * as timers from "timers";
import * as channel from "channel";

const MAX_RECENT = 128;
const recent = [];
const apps = [];
const q = [];

export function registerApp(app)
{
    push(apps, app);
};

export function process()
{
    while (length(q) > 0) {
        const msg = shift(q);

        DEBUG("%.2J\n", msg);

        // Give each app a chance at the message
        for (let i = 0; i < length(apps); i++) {
            apps[i].process(msg);
        }

        // Forward the message if it's not just to me. We never forward encrypted traffic.
        if (!node.toMe(msg) && !msg.encrypted) {
            if (!node.fromMe(msg)) {
                if (!node.canForward()) {
                    return;
                }
                msg.hop_limit--;
                if (msg.hop_limit <= 0) {
                    return;
                }
            }
            const transport = msg.transport_mechanism;
            if (transport === message.TRANSPORT_MECHANISM_MULTICAST_UDP || node.fromMe(msg)) {
                msg.transport_mechanism = message.TRANSPORT_MECHANISM_UNICAST_UDP;
                unicast.send(msg.to, msg.namekey, sprintf("%J", msg));
            }
            if (transport === message.TRANSPORT_MECHANISM_UNICAST_UDP || node.fromMe(msg)) {
                if (node.isBroadcast(msg) || !platform.getTargetById(node.to)) {
                    msg.transport_mechanism = message.TRANSPORT_MECHANISM_MULTICAST_UDP;
                    const pkt = parse.encodePacket(msg);
                    if (pkt) {
                        multicast.send(pkt);
                    }
                }
            }
        }
    }
};

export function queue(msg)
{
    // Remember messages we queued for a little while and don't queue them again.
    const key = `${msg.from}:${msg.id}`;
    if (index(recent, key) === -1) {
        push(recent, key);
        if (length(recent) > MAX_RECENT) {
            shift(recent);
        }
        push(q, msg);
    }
};

export function tick()
{
    for (let i = 0; i < length(apps); i++) {
        apps[i].tick();
    }
    process();
    const sockets = [];
    const us = unicast.handle();
    if (us) {
        push(sockets, [ us, socket.POLLIN, "unicast" ]);
    }
    const ms = multicast.handle();
    if (ms) {
        push(sockets, [ ms, socket.POLLIN, "multicast" ])
    }
    const v = socket.poll(timers.minTimeout(60) * 1000, ...sockets);
    for (let i = 0; i < length(v); i++) {
        if (v[i] && v[i][1]) {
            switch (v[i][2]) {
                case "unicast":
                    try {
                        const msg = json(unicast.recv());
                        msg.transport_mechanism = message.TRANSPORT_MECHANISM_UNICAST_UDP;
                        queue(msg);
                    }
                    catch (_) {
                    }
                    break;
                case "multicast":
                    try {
                        const msg = parse.decodePacket(multicast.recv());
                        if (msg) {
                            msg.transport_mechanism = message.TRANSPORT_MECHANISM_MULTICAST_UDP;
                            queue(msg);
                        }
                    }
                    catch (_)
                    {
                    }
                    break;
            }
        }
    }
};
