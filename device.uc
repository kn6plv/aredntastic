import * as router from "router";
import * as message from "message";
import * as node from "node";
import * as timers from "timers";
import * as nodedb from "nodedb";
import * as parse from "parse";
import * as telemetry from "telemetry";

const GRID_POWER = 101;
let startTime = 0;
 
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

export function setup(config)
{
    startTime = clock(true)[0];
    timers.setInterval("device_metrics", config.telemetry?.device?.interval ?? 30 * 60);
};

export function tick()
{
    if (timers.tick("device_metrics")) {
        router.queue(message.createMessage(null, null, null, "telemetry", {
            time: time(),
            device_metrics: {
                battery_level: GRID_POWER,
                uptime_seconds: clock(true)[0] - startTime
            }
        }));
    }
};

export function process(msg)
{
    if (msg.data?.telemetry?.device_metrics && node.forMe(msg)) {
        nodedb.updateDeviceMetrics(msg.from, msg.data.telemetry.device_metrics);
    }
};
