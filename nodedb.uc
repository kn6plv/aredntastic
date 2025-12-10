import * as fs from "fs";
import * as router from "router";

const ROOT = "/tmp/at";

let nodedb;

export function getNode(id)
{
    if (!nodedb) {
        nodedb = json(fs.readfile(`${ROOT}/nodedb.json`) ?? "{}");
    }
    return nodedb[id] ?? { id: id };
};

function saveNode(id, node)
{
    nodedb[id] = node;
    fs.writefile(`${ROOT}/nodedb.json`, sprintf("%.2J", nodedb));
}

function isdiff(a, b)
{
    return sprintf("%J", a) != sprintf("%J", b);
}

export function process(msg)
{
    let update = false;

    if (!router.forMe(msg)) {
        return;
    }

    const from = getNode(msg.from);

    if (msg.hop_start && msg.hop_limit) {
        const distance = msg.hop_start - msg.hop_limit;
        if (from.distance != distance) {
            from.distance = distance;
            update = true;
        }
    }
    const data = msg.data;
    if (data) {
        if (data.user && isdiff(from.user, data.user)) {
            from.user = data.user;
            update = true;
        }
        if (data.position && isdiff(from.position, data.position)) {
            from.position = data.position;
            update = true;
        }
        const tdata = data.telemetry;
        if (tdata) {
            const telemetry = from.telemetry ?? (from.telemetry = {});
            if (tdata.device_metrics && isdiff(telemetry.device_metrics, tdata.device_metrics)) {
                telemetry.device_metrics = tdata.device_metrics;
                update = true;
            }
            if (tdata.environment_metrics && isdiff(telemetry.environment_metrics, tdata.environment_metrics)) {
                telemetry.environment_metrics = tdata.environment_metrics;
                update = true;
            }
        }
    }
    if (update) {
        saveNode(msg.from, from);
    }
};

