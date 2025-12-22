import * as fs from "fs";
import * as timers from "timers";
import * as uci from "uci";
import * as services from "aredn.services";
import * as node from "node";
import * as channel from "channel";

const CURL = "/usr/bin/curl";

const pubID = "KN6PLV.meshchatter.v1.1";
const pubTopic = "KN6PLV.meshchatter.v1";

const ucdata = {};
let bynamekey = {};
let byid = {};
let forwarders = [];
let myid;
let unicastEnabled = false;

/* export */ function setup(config)
{
    fs.mkdir("/etc/meshchatter/");
    fs.mkdir("/tmp/meshchatter/");

    const c = uci.cursor();
    ucdata.latitide = c.get("aredn", "@location[0]", "lat");
    ucdata.longitude = c.get("aredn", "@location[0]", "lat");
    ucdata.height = c.get("aredn", "@location[0]", "height") ?? 0;

    const cm = uci.cursor("/etc/config.mesh");
    ucdata.main_ip = cm.get("setup", "globals", "wifi_ip");
    ucdata.lan_ip = cm.get("setup", "globals", "dmz_lan_ip");

    if (config.unicast) {
        unicastEnabled = true;
    }

    timers.setInterval("aredn", 1 * 60);
}

function path(name)
{
    switch (name) {
        case "node":
            return `/etc/meshchatter/${name}.json`;
        default:
            return `/tmp/meshchatter/${name}.json`;
    }
}

/* export */ function load(name)
{
    const data = fs.readfile(path(name));
    return data ? json(data) : null;
}

/* export */ function store(name, data)
{
    fs.writefile(path(name), sprintf("%.02J", data));
}

/* export */ function fetch(url)
{
    const p = fs.popen(`${CURL} --max-time 2 --silent --output - ${url}`);
    if (!p) {
        return null;
    }
    const all = p.read("all");
    p.close();
    return all;
}

/* export */ function getTargetsByIdAndNamekey(id, namekey)
{
    if (id === node.BROADCAST) {
        const services = bynamekey[namekey];
        if (services) {
            const targets = slice(services);
            for (let i = 0; i < length(forwarders); i++) {
                const forwarder = forwarders[i];
                if (!forwarder.channels[namekey]) {
                    push(targets, forwarder);
                }
            }
            return targets;
        }
        else {
            return forwarders;
        }
    }
    else {
        const target = byid[id];
        if (target) {
            if (target.channels[namekey]) {
                return [ target ];
            }
            else {
                return [];
            }
        }
        else {
            return forwarders;
        }
    }
}

/* export */ function getTargetById(id)
{
    return byid[id];
}

/* export */ function getLocation()
{
    return {
        latitide: ucdata.latitide, longitude: ucdata.longitude, altitude: ucdata.height, precision: 0
    };
}

/* export */ function getMulticastDeviceIP()
{
    return ucdata.lan_ip;
}

/* export */ function publish(me, channels)
{
    if (!unicastEnabled) {
        return;
    }
    myid = me.id;
    services.publish(pubID, pubTopic, { id: myid, ip: ucdata.main_ip, role: me.role, key: me.private_key, channels: map(channels, c => c.namekey) });
    function unpublish()
    {
        services.unpublish(pubID);
        exit(0);
    }
    signal("SIGHUP", unpublish);
    signal("SIGINT", unpublish);
    signal("SIGTERM", unpublish);
}

/* export */ function tick()
{
    if (timers.tick("aredn")) {
        const published = services.published(pubTopic);
        byid = {};
        bynamekey = {};
        forwarders = [];
        for (let i = 0; i < length(published); i++) {
            const service = published[i];
            if (service.id !== myid) {
                byid[service.id] = service;
                const nchannels = {};
                for (let j = 0; j < length(service.channels); j++) {
                    const namekey = service.channels[j];
                    if (!bynamekey[namekey]) {
                        bynamekey[namekey] = [];
                        channel.addMessageNameKey(namekey);
                    }
                    pushd(bynamekey[namekey], service);
                    nchannels[namekey] = true;
                }
                service.channels = nchannels;
                if (node.canRoleForward(service.role)) {
                    push(forwarders, service);
                }
            }
        }
    }
}

/* export */ function process(msg)
{
}

return {
    setup,
    load,
    store,
    fetch,
    getTargetsByIdAndNamekey,
    getTargetById,
    getLocation,
    getMulticastDeviceIP,
    publish,
    tick,
    process
};
