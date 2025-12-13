import * as fs from "fs";
import * as timers from "timers";
import * as router from "router";
import * as message from "message";
import * as node from "node";
import * as nodedb from "nodedb";
import * as parse from "parse";
import * as telemetry from "telemetry";

timers.setTimeout("environmental_metrics", 30 * 60);

parse.registerProto(
    "environment_metrics", null,
    {
        "1": "float temperature",
        "2": "float relative_humidity",
        "3": "float barometric_pressure",
        "4": "float gas_resistance",
        "5": "float voltage",
        "6": "float current",
        "7": "uint32 iaq",
        "8": "float distance",
        "9": "float lux",
        "10": "float white_lux",
        "11": "float ir_lux",
        "12": "float uv_lux",
        "13": "uint32 wind_direction",
        "14": "float wind_speed",
        "15": "float weight",
        "16": "float wind_gust",
        "17": "float wind_lull",
        "18": "float radiation",
        "19": "float rainfall_1h",
        "20": "float rainfall_24h",
        "21": "uint32 soil_moisture",
        "22": "float soil_temperature"
    }
);

const CURL = "/usr/bin/curl";
let weewxurl;

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
        const p = fs.popen(`${CURL} --max-time 2 --silent --output - ${weewxurl}`);
        if (p) {
            const all = p.read("all");
            p.close();
            try {
                const c = json(all).current;
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
    }
};

export function process(msg)
{
    if (node.forMe(msg) && msg.data?.telemetry?.environment_metrics) {
        nodedb.updateEnvironmentMetrics(msg.from, msg.data.telemetry.environment_metrics);
    }
};

