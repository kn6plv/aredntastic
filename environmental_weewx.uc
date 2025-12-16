import * as timers from "timers";
import * as router from "router";
import * as message from "message";
import * as node from "node";
import * as nodedb from "nodedb";
import * as parse from "parse";
import * as environmental from "environmental";

let weewxurl;

export function setup(config)
{
    timers.setTimeout("environmental_metrics", 30 * 60);
    weewxurl = config.environmental.url;
};

function convert(tounit, value)
{
    if (!value) {
        return null;
    }
    const fromunit = value.units;
    let v = value.value;
    switch (tounit) {
        case "C":
            switch(substr(fromunit, -1)) {
                case "F":
                    v = (v - 32) / 1.8;
                    break;
                default:
                    break;
            }
        case "hPA":
            switch (fromunit) {
                case "inHg":
                    v *= 33.86389;
                    break;
                default:
                    break;
            }
        case "m/s":
            switch (fromunit) {
                case "mph":
                    v *= 0.44704;
                    break;
                default:
                    break;
            }
        case "mm/h":
            switch (fromunit) {
                case "in/h":
                    v *= 25.4;
                    break;
                default:
                    break;
            }
        default:
            break;
    }
    return v;
}

export function setURL(url)
{
    weewxurl = url;
};

export function tick()
{
    if (timers.tick("environmental_metrics")) {
        try {
            const c = json(platform.fetch(weewxurl)).current;
            router.queue(message.createMessage(null, null, null, "telemetry", {
                time: time(),
                environment_metrics: {
                    temperature: convert("C", c.temperature),
                    relative_humidity: c.humidity?.value,
                    barometric_pressure: convert("hPA", c.barometer),
                    wind_direction: c["wind direction"]?.value,
                    wind_speed: convert("m/s", c["wind speed"]),
                    wind_gust: convert("m/s", c["wind gust"]),
                    rainfall_1h: convert("mm/h", c["rain rate"])
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
