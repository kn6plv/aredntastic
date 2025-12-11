import * as multicast from "multicast";
import * as parse from "parse";
import * as node from "node";
import * as timers from "timers";

const MAX_RECENT = 32;
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

        // Forward the message as necessary
        if (!node.toMe(msg)) {
            if (msg.from == node.id()) {
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
    process();
    const pkt = multicast.wait(timers.minTimeout(60));
    if (pkt) {
        queue(parse.decodePacket(pkt));
    }
};
