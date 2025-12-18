import * as router from "router";
import * as message from "message";
import * as node from "node";
import * as nodedb from "nodedb";
import * as timers from "timers";
import * as parse from "parse";
import * as crypto from "crypto";

const PRIVATE_HW = 255;
const DEFAULT_INTERVAL = 3 * 60 * 60;
 
parse.registerProto(
    "nodeinfo", 4,
    {
        "1": "string id",
        "2": "string long_name",
        "3": "string short_name",
        "4": "bytes macaddr",
        "5": "enum hw_model",
        "6": "bool is_licensed",
        "7": "enum role",
        "8": "bytes public_key",
        "9": "bool is_unmessagable"
    }
);

export function setup(config)
{
    timers.setInterval("nodeinfo", config.user?.interval ?? DEFAULT_INTERVAL);
};

export function tick()
{
    if (timers.tick("nodeinfo")) {
        const me = node.getInfo();
        router.queue(message.createMessage(null, null, null, "nodeinfo", {
            id: sprintf("!%08x", me.id),
            long_name: me.long_name,
            short_name: me.short_name,
            macaddr: me.macaddr,
            hw_model: PRIVATE_HW,
            role: me.role,
            public_key: crypto.pKeyToString(me.public_key),
            is_unmessagable: false
        }));
    }
};

export function process(msg)
{
    if (msg.data?.user && node.forMe(msg)) {
        nodedb.updateUser(msg.from, msg.data.user);
    }
};
