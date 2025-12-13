import * as multicast from "multicast";
import * as unicast from "unicast";
import * as parse from "parse";
import * as node from "node";
import * as messages from "messages";
import * as socket from "socket";
import * as timers from "timers";

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

        printf("%.2J\n", msg);

        // Give each app a chance at the message
        for (let i = 0; i < length(apps); i++) {
            apps[i].process(msg);
        }

        // Forward the message if it's not just to me. We never forward encrypted traffic.
        if (!node.toMe(msg) && !msg.encrypted) {
            const transport = msg.transport_mechanism;
            if (transport === messages.TRANSPORT_MECHANISM_MULTICAST_UDP || node.fromMe(msg)) {
                msg.transport_mechanism = messages.TRANSPORT_MECHANISM_UNICAST_UDP;
                unicast.send(msg.to, sprintf("%J", msg));
            }
            if (transport === messages.TRANSPORT_MECHANISM_UNICAST_UDP || node.fromMe(msg)) {
                msg.transport_mechanism = messages.TRANSPORT_MECHANISM_MULTICAST_UDP;
                multicast.send(parse.encodePacket(msg));
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
    const us = unicast.handle();
    const ms = multicast.handle();
    const v = socket.poll(timers.minTimeout(60) * 1000, [ us, socket.POLLIN ], [ ms, socket.POLLIN ]);
    if (v[0][1]) {
            const pkt = unicast.recv();
            try {
                const msg = json(pkt);
                msg.transport_mechanism = messages.TRANSPORT_MECHANISM_UNICAST_UDP;
                queue(msg);
            }
            catch (_) {
            }
    }
    if (v[1][1]) {
        const msg = parse.decodePacket(multicast.recv());
        msg.transport_mechanism = messages.TRANSPORT_MECHANISM_MULTICAST_UDP;
        queue(msg);
    }
};
