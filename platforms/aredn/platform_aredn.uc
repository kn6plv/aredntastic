import * as fs from "fs";
import * as timers from "timers";
import * as uci from "uci";
import * as services from "aredn.services";

const CURL = "/usr/bin/curl";

const pubID = "KN6PLV.AREDNtastic.v1.1";
const pubTopic = "KN6PLV.AREDNtastic.v1";

const ucdata = {};
let published = {};

/* export */ function setup()
{
    fs.mkdir("/etc/aredntastic/");
    fs.mkdir("/tmp/aredntastic/");

    const c = uci.cursor();
    ucdata.latitide = c.get("aredn", "@location[0]", "lat");
    ucdata.longitude = c.get("aredn", "@location[0]", "lat");
    ucdata.height = c.get("aredn", "@location[0]", "height") ?? 0;

    const cm = uci.cursor("/etc/config.mesh");
    ucdata.main_ip = cm.get("setup", "globals", "wifi_ip");
    ucdata.lan_ip = cm.get("setup", "globals", "dmz_lan_ip");

    timers.setInterval("aredn", 1 * 60);
}

function path(name)
{
    switch (name) {
        case "node":
            return `/etc/aredntastic/${node}.json`;
        default:
            return `/tmp/aredntastic/${name}.json`;
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

/* export */ function getAllTargets()
{
    return published;
}

/* export */ function getTarget(id)
{
    return filter(published, i => i.id === id)[0];
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

/* export */ function publish(me)
{
    services.publish(pubID, pubTopic, { id: me.id(), ip: ucdata.main_ip, role: me.role, key: me.private_key });
    function unpublish()
    {
        services.unpublish(pubID);
    }
    signal("SIGHUP", unpublish);
    signal("SIGINT", unpublish);
    signal("SIGTERM", unpublish);
}

/* export */ function tick()
{
    if (timers.tick("aredn")) {
        published = services.published(pubTopic);
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
    getAllTargets,
    getTarget,
    getLocation,
    getMulticastDeviceIP,
    publish,
    tick,
    process
};
