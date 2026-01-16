import * as timers from "timers";
import * as router from "router";
import * as message from "message";
import * as node from "node";
import * as nodedb from "nodedb";
import * as telemetry from "telemetry";
import * as airquality from "telemetry_airquality";

let purpleairurl;

export function setup(config)
{
    purpleairurl = config.telemetry?.airquality?.url;
    if (purpleairurl) {
        timers.setInterval("airquality_metrics", 60, config.telemetry?.airquality?.interval ?? telemetry.DEFAULT_INTERVAL);
    }
};

export function tick()
{
    if (timers.tick("airquality_metrics")) {
        try {
            const j = json(platform.fetch(purpleairurl));
            router.queue(message.createMessage(null, null, null, "telemetry", {
                time: time(),
                airquality_metrics: {
                    particles_25um: j.p_2_5_um,
                    particles_50um: j.p_5_0_um,
                    particles_100um: j.p_10_0_um,
                    pm_temperature: telemetry.convert("C", `${j.current_temp_f}F`),
                    pm_humidity: j.current_humidity
                }
            }));
        }
        catch (_) {
        }
    }
};

export function process(msg)
{
    if (msg.data?.telemetry?.airquality_metrics && node.forMe(msg)) {
        nodedb.updateAirQualityMetrics(msg.from, msg.data.telemetry.airquality_metrics);
    }
};
