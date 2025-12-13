import * as router from "router";
import * as message from "message";
import * as node from "node";
import * as timers from "timers";
import * as nodedb from "nodedb";
import * as parse from "parse";
import * as telemetry from "telemetry";

const GRID_POWER = 101;
 
timers.setTimeout("device_metrics", 30 * 60);

parse.registerProto(
    "device_metrics", null,
    {
        "1": "uint32 battery_level",
        "2": "float voltage",
        "3": "float channel_utilization",
        "4": "float air_util_tx",
        "5": "uint32 uptime_seconds"
    }
);

export function tick()
{
    if (timers.tick("device_metrics")) {
        router.queue(message.createMessage(null, null, null, "telemetry", {
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
