import * as timers from "timers";
import * as router from "router";
import * as message from "message";
import * as node from "node";
import * as nodedb from "nodedb";
import * as telemetry from "telemetry";
import * as environmental from "telemetry_environmental";

let weewxurl;

export function setup(config)
{
    weewxurl = config.telemetry?.environmental?.url;
    if (weewxurl) {
        timers.setInterval("environmental_metrics", config.telemetry?.environmental?.interval ?? telemetry.DEFAULT_INTERVAL);
    }
};

export function tick()
{
    if (timers.tick("environmental_metrics")) {
        try {
            const j = json(platform.fetch(weewxurl));
            const c = j.current;
            const d = j.day;
            router.queue(message.createMessage(null, null, null, "telemetry", {
                time: time(),
                environment_metrics: {
                    temperature: environmental.convert("C", c.temperature),
                    relative_humidity: c.humidity?.value,
                    barometric_pressure: environmental.convert("hPA", c.barometer),
                    wind_direction: c["wind direction"]?.value,
                    wind_speed: environmental.convert("m/s", c["wind speed"]),
                    wind_gust: environmental.convert("m/s", c["wind gust"]),
                    rainfall_1h: environmental.convert("mm/h", c["rain rate"]),
                    rainfall_24h: environmental.convert("mm", d["rain total"])
                }
            }));
        }
        catch (_) {
        }
    }
};

export function process(msg)
{
    if (msg.data?.telemetry?.environment_metrics && node.forMe(msg)) {
        nodedb.updateEnvironmentMetrics(msg.from, msg.data.telemetry.environment_metrics);
    }
};
