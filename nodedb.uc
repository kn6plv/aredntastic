import * as platform from "platform";

let nodedb;

export function getNode(id)
{
    if (!nodedb) {
        nodedb = platform.load("nodedb") ?? {};
    }
    return nodedb[id] ?? { id: id };
};

function saveNode(node)
{
    nodedb[node.id] = node;
    platform.store("nodedb", nodedb);
}

function isdiff(a, b)
{
    return sprintf("%J", a) != sprintf("%J", b);
}

export function updateUser(id, user)
{
    const node = getNode(id);
    if (isdiff(node.user, user)) {
        node.user = user;
        saveNode(node);
    }
};

export function updatePosition(id, position)
{
    const node = getNode(id);
    if (isdiff(node.position, position)) {
        node.position = position;
        saveNode(node);
    }
};

export function updateDeviceMetrics(id, metrics)
{
    const node = getNode(id);
    const telemetry = node.telemetry ?? (node.telemetry = {});
    if (isdiff(telemetry.device_metrics, metrics)) {
        telemetry.device_metrics = metrics;  
        saveNode(node);
    }
};

export function updateEnvironmentMetrics(id, metrics)
{
    const node = getNode(id);
    const telemetry = node.telemetry ?? (node.telemetry = {});
    if (isdiff(telemetry.environment_metrics, metrics)) {
        telemetry.environment_metrics = metrics;  
        saveNode(node);
    }
};
