import * as router from "router";
import * as messages from "messages";
import * as node from "node";
import * as timers from "timers";
import * as nodedb from "nodedb";

const GRID_POWER = 101;
 
timers.setTimeout("device_metrics", 30 * 60);

export function tick()
{
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

export function process(msg)
{
    if (node.forMe(msg) && msg.data?.telemetry?.device_metrics) {
        nodedb.updateDeviceMetrics(msg.from, msg.data.telemetry.device_metrics);
    }
};
