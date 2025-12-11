import * as router from "router";
import * as messages from "messages";
import * as node from "node";
import * as timers from "timers";

const ROLE_CLIENT = 0;
const PRIVATE_HW = 255;
const GRID_POWER = 101;
const LOCATION_SOURCE_MANUAL = 1;

timers.setTimeout("user", 30 * 60);
timers.setTimeout("position", 15 * 60);
timers.setTimeout("device_metrics", 30 * 60);

export function tick()
{
    const me = node.getInfo();
    if (timers.tick("user")) {
        router.queue(messages.createMessage(null, null, null, "user", {
            id: sprintf("!%08x", me.id),
            long_name: me.long_name,
            short_name: me.short_name,
            macaddr: me.macaddr,
            hw_model: PRIVATE_HW,
            role: ROLE_CLIENT,
            public_key: substr(me.public_key, -32),
            is_unmessagable: false
        }));
    }
    if (timers.tick("position")) {
        router.queue(messages.createMessage(null, null, null, "position", {
            latitude_i: me.lat * 10000000,
            longitude_i: me.lon * 10000000,
            altitude: me.alt,
            time: time(),
            location_source: LOCATION_SOURCE_MANUAL,
            precision_bits: me.percision
        }));
    }
    if (timers.tick("device_metrics")) {
        router.queue(messages.createMessage(null, null, null, "telemetry", {
            time: time(),
            device_metrics: {
                battery_level: GRID_POWER,
                uptime_seconds: clock(true)[0]
            }
        }));
    }
};
