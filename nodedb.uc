import * as datastore from "datastore";

let nodedb;

export function getNode(id)
{
    if (!nodedb) {
        nodedb = datastore.load("nodedb") ?? {};
    }
    return nodedb[id] ?? { id: id };
};

function saveNode(node)
{
    nodedb[node.id] = node;
    datastore.store("nodedb", nodedb);
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

export function updateDeviceMetrics(id, device)
{
    const node = getNode(id);
    const telemetry = node.telemetry ?? (node.telemetry = {});
    if (isdiff(telemetry.device_metrics, device)) {
        telemetry.device_metrics = device;  
        saveNode(node);
    }
};

export function updateEnvironmentMetrics(id, environment)
{
    const node = getNode(id);
    const telemetry = node.telemetry ?? (node.telemetry = {});
    if (isdiff(telemetry.environment_metrics, environment)) {
        telemetry.environment_metrics = environment;  
        saveNode(node);
    }
};
