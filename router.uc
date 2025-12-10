import * as multicasthandler from "multicasthandler";
import * as keys from "keys";
import * as parse from "parse";
import * as node from "node";
import * as nodedb from "nodedb";
import * as messages from "messages";

const me = node.getNode();

const MAX_RECENT = 32;
const recent = [];

export function process(msg)
{
    const key = `${msg.from}:${msg.id}`;
    if (index(recent, key) !== -1) {
        return;
    }
    push(recent, key);
    if (length(recent) > MAX_RECENT) {
        shift(recent);
    }

    printf("%.2J\n", msg);

    if (msg.from == me.id()) {
        multicasthandler.send(parse.encodePacket(msg, keys.defaultKey));
    }
    nodedb.updateNode(msg);
    messages.updateMessage(msg);
};

export function wait(timeout)
{
    const pkt = multicasthandler.wait(timeout);
    if (pkt) {
        process(parse.decodePacket(pkt, keys.defaultKey));
    }
};
