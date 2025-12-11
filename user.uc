import * as router from "router";
import * as messages from "messages";
import * as node from "node";
import * as nodedb from "nodedb";
import * as timers from "timers";

const PRIVATE_HW = 255;
 
timers.setTimeout("user", 30 * 60);

export function tick()
{
    if (timers.tick("user")) {
        const me = node.getInfo();
        router.queue(messages.createMessage(null, null, null, "user", {
            id: sprintf("!%08x", me.id),
            long_name: me.long_name,
            short_name: me.short_name,
            macaddr: me.macaddr,
            hw_model: PRIVATE_HW,
            role: me.role,
            public_key: substr(me.public_key, -32),
            is_unmessagable: false
        }));
    }
};

export function process(msg)
{
    if (node.forMe(msg) && msg.data?.user) {
        nodedb.updateUser(msg.from, msg.data.user);
    }
};
