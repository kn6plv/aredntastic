import * as fs from "fs";
import * as timers from "timers";
import * as router from "router";
import * as messages from "messages";

timers.setTimeout("environmental_metrics", 30 * 60);

const CURL = "/usr/bin/curl";
let weewxurl;

function convert(tounit, value)
{
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
                router.queue(messages.createMessage(null, null, null, "telemetry", {
                    time: time(),
                    environment_metrics: {
                        temperature: convert("C", c.temperature),
                        relative_humidity: c.humidity.value,
                        barometric_pressure: convert("hPA", c.barometer),
                        wind_direction: c["wind direction"].value,
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
