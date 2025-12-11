import * as timers from "timers";
import * as messages from "messages";
import * as router from "router";
import * as nodedb from "nodedb";
import * as node from "node";

const LOCATION_SOURCE_MANUAL = 1;

timers.setTimeout("position", 15 * 60);

function position()
{
    const me = node.getInfo();
    return {
        latitude_i: me.lat * 10000000,
        longitude_i: me.lon * 10000000,
        altitude: me.alt,
        time: time(),
        location_source: LOCATION_SOURCE_MANUAL,
        precision_bits: me.percision
    };
}

export function tick()
{
    if (timers.tick("position")) {
        router.queue(messages.createMessage(null, null, null, "position", position()));
    }
};

export function process(msg)
{
    if (node.forMe(msg) && msg.data?.position) {
        nodedb.updatePosition(msg.from, msg.data.position);
        if (node.toMe(msg) && msg.data.want_response) {
            router.queue(messages.createMessage(msg.from, null, null, "position", position()));
        }
    }
};
