import * as fs from "fs";
import * as timers from "timers";
import * as uci from "uci";
import * as services from "aredn.services";
import * as node from "node";
import * as channel from "channel";

const CURL = "/usr/bin/curl";

const pubID = "KN6PLV.raven.v1.1";
const pubTopic = "KN6PLV.raven.v1";

const LOCATION_SOURCE_INTERNAL = 2;

const ucdata = {};
let bynamekey = {};
let byid = {};
let forwarders = [];
let myid;
let unicastEnabled = false;
const badges = {};

/* export */ function setup(config)
{
    fs.mkdir("/etc/raven/");
    fs.mkdir("/tmp/raven/");

    const c = uci.cursor();
    ucdata.latitide = c.get("aredn", "@location[0]", "lat");
    ucdata.longitude = c.get("aredn", "@location[0]", "lat");
    ucdata.height = c.get("aredn", "@location[0]", "height");
    ucdata.hostname = c.get("system", "@system[0]", "hostname");

    const cm = uci.cursor("/etc/config.mesh");
    ucdata.main_ip = cm.get("setup", "globals", "wifi_ip");
    ucdata.lan_ip = cm.get("setup", "globals", "dmz_lan_ip");

    const cu = uci.cursor("/etc/local/uci");
    ucdata.macaddress = map(split(cu.get("hsmmmesh", "settings", "wifimac"), ":"), v => hex(v));

    if (config.unicast) {
        unicastEnabled = true;
    }

    timers.setInterval("aredn", 1 * 60);
}

/* export */ function mergePlatformConfig(config)
{
    const location = config.location ?? (config.location = {});
    if (location.latitude === null) {
        location.latitide = ucdata.latitide;
    }
    if (location.longitude === null) {
        location.longitude = ucdata.longitude;
    }
    if (location.altitude === null) {
        location.altitude = ucdata.height;
    }
    if (location.precision === null) {
        location.precision = 0;
    }
    if (location.source === null && fs.readfile("/tmp/timesync") === "gps") {
        location.source = LOCATION_SOURCE_INTERNAL;
    }

    if (config.multicast && config.multicast?.address === null) {
        config.multicast.address = ucdata.lan_ip;
    }

    if (config.channels?.AREDN === null) {
        if (!config.channels) {
            config.channels = {};
        }
        config.channels.AREDN = "og==";
    }

    if (config.long_name === null) {
        config.long_name = ucdata.hostname;
    }
    if (config.short_name === null) {
        config.short_name = substr(split(ucdata.hostname, "-", 2)[0], -4);
    }

    if (config.macaddress === null) {
        config.macaddress = ucdata.macaddress;
    }
}

function path(name)
{
    switch (name) {
        case "node":
            return `/etc/raven/${name}.json`;
        default:
            return `/tmp/raven/${name}.json`;
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

/* export */ function badge(key, count)
{
    if (count === null) {
        delete badges[key];
    }
    else {
        badges[key] = count;
    }
    let total = 0;
    for (let k in badges) {
        total += badges[k];
    }
    fs.writefile("/tmp/apps/raven/badge", total ? "" : `${total}`);
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
    mergePlatformConfig,
    load,
    store,
    fetch,
    getTargetsByIdAndNamekey,
    getTargetById,
    publish,
    badge,
    tick,
    process
};
