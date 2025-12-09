import * as fs from "fs";

const ROOT = "/tmp/at";

let nodedb;

function getNode(id)
{
    if (!nodedb) {
        nodedb = json(fs.readfile(`${ROOT}/nodedb.json`) ?? "{}");
    }
    return nodedb[id] ?? {};
}

function saveNode(id, node)
{
    nodedb[id] = node;
    fs.writefile(`${ROOT}/nodedb.json`, sprintf("%.2J", nodedb));
}

function isdiff(a, b)
{
    return sprintf("%J", a) != sprintf("%J", b);
}

export function updateNode(msg)
{
    let update = false;

    const node = getNode(msg.from);

    if (msg.hop_start && msg.hop_limit) {
        const distance = msg.hop_start - msg.hop_limit;
        if (node.distance != distance) {
            node.distance = distance;
            update = true;
        }
    }
    const data = msg.data;
    if (data) {
        if (data.user && isdiff(node.user, data.user)) {
            node.user = data.user;
            update = true;
        }
        if (data.position && isdiff(node.position, data.position)) {
            node.position = data.position;
            update = true;
        }
        const tdata = data.telemetry;
        if (tdata) {
            const telemetry = node.telemetry ?? (node.telemetry = {});
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
        saveNode(msg.from, node);
    }
};

