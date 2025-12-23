let nodedb;

export function setup(config)
{
};

export function getNode(id, create)
{
    if (!nodedb) {
        nodedb = platform.load("nodedb") ?? {};
    }
    return nodedb[id] ?? (create === false ? null : { id: id });
};

function saveNode(node)
{
    nodedb[node.id] = node;
    node.lastseen = time();
    platform.store("nodedb", nodedb);
    cmd.notify("nodes");
}

export function createNode(id)
{
    if (!nodedb[id]) {
        saveNode(getNode(id));
    }
};

export function updateNodeinfo(id, nodeinfo)
{
    const node = getNode(id);
    node.nodeinfo = nodeinfo;
    saveNode(node);
};

export function updatePosition(id, position)
{
    const node = getNode(id);
    node.position = position;
    saveNode(node);
};

export function updateDeviceMetrics(id, metrics)
{
    const node = getNode(id);
    const telemetry = node.telemetry ?? (node.telemetry = {});
    telemetry.device_metrics = metrics;  
    saveNode(node);
};

export function updateEnvironmentMetrics(id, metrics)
{
    const node = getNode(id);
    const telemetry = node.telemetry ?? (node.telemetry = {});
    telemetry.environment_metrics = metrics;  
    saveNode(node);
};

export function getNodes()
{
    return values(nodedb);
};

export function tick()
{
};

export function process(msg)
{
    const node = getNode(msg.from, false);
    if (node && msg.hop_start && msg.hop_limit) {
        node.hops = msg.hop_start - msg.hop_limit;
        saveNode(node);
    }
};
