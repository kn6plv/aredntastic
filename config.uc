import * as fs from "fs";
import * as router from "router";
import * as channel from "channel";
import * as node from "node";
import * as ipmesh from "ipmesh";
import * as meshtastic from "meshtastic";
import * as websocket from "websocket";
import * as event from "event";

import * as nodedb from "nodedb";
import * as nodeinfo from "nodeinfo";
import * as textmessage from "textmessage";
import * as position from "position";
import * as favorite from "favorite";
import * as storeandforward from "storeandforward";
import * as neighborinfo from "neighborinfo";
import * as traceroute from "traceroute";
import * as messagestore from "messagestore";
import * as device from "telemetry_device";
import * as environmental_weewx from "telemetry_environmental_weewx";
import * as power from "telemetry_power";

let bconfig;
let config;
let override;

function jsonEq(a, b)
{
    return sprintf("%J", a) === sprintf("%J", b);
}

function clone(a)
{
    return json(sprintf("%J", a));
}

function update(option)
{
    let write = false;

    switch (option) {
        case "channels":
        {
            const channels = channel.getAllChannels();
            const nchannels = {};
            let primary = null;
            for (let i = 0; i < length(channels); i++) {
                const nk = split(channels[i].namekey, " ");
                if (channels[i].primary) {
                    primary = nk[0];
                }
                else {
                    nchannels[nk[0]] = nk[1];
                }
            }
            if (primary != config.preset) {
                config.preset = primary;
                if (primary == bconfig.preset) {
                    delete override.preset;
                }
                else {
                    override.preset = primary;
                }
                write = true;
            }
            if (!jsonEq(nchannels, config.channels)) {
                if (jsonEq(nchannels, bconfig.channels)) {
                    delete override.channels;
                }
                else {
                    override.channels = nchannels;
                }
                write = true;
            }
            break;
        }
        default:
            break;
    }

    if (write) {
        const data = sprintf("%.2J", override);
        if (fs.access("/etc/raven.conf.override")) {
            fs.writefile("/etc/raven.conf.override", data);
        }
        else if (fs.access(`${fs.dirname(SCRIPT_NAME)}/raven.conf.override`)) {
            fs.writefile(`${fs.dirname(SCRIPT_NAME)}/raven.conf.override`, data);
        }
        else if (fs.access("/etc/raven.conf")) {
            fs.writefile("/etc/raven.conf.override", data);
        }
        else if (fs.access(`${fs.dirname(SCRIPT_NAME)}/raven.conf`)) {
            fs.writefile(`${fs.dirname(SCRIPT_NAME)}/raven.conf.override`, data);
        }
    }
}

export function setup()
{
    push(REQUIRE_SEARCH_PATH, `${fs.dirname(SCRIPT_NAME)}/*.uc`);

    bconfig = json(fs.readfile("/etc/raven.conf") ?? fs.readfile(`${fs.dirname(SCRIPT_NAME)}/raven.conf`));
    config = clone(bconfig);
    override = json(fs.readfile("/etc/raven.conf.override") ?? fs.readfile(`${fs.dirname(SCRIPT_NAME)}/raven.conf.override`) ?? "[]");
    if (type(override) === "object") {
        function f(c, o)
        {
            for (let k in o) {
                if (o[k] === null) {
                    delete c[k];
                }
                else switch (type(o[k])) {
                    case "object":
                        if (!c[k]) {
                            c[k] = {};
                        }
                        f(c[k], o[k]);
                        break;
                    default:
                        c[k] = o[k];
                        break;
                }
            }
        }
        f(config, override);
    }
    else {
        override = {};
    }

    config.update = update;

    global.DEBUG0 = function(){};
    global.DEBUG1 = function(){};
    global.DEBUG2 = function(){};
    switch (config.debug)
    {
        case 2:
            global.DEBUG2 = printf;
        case 1:
            global.DEBUG1 = printf;
        case 0:
            global.DEBUG0 = printf;
            break;
        default:
            break;
    }

    switch (config.platform?.type) {
        case "aredn":
        case "debian":
            global.platform = require(`platforms.${config.platform?.type}.platform_${config.platform?.type}`);
            break;
        default:
            print(`Unknown platform: ${config.platform?.type}\n`);
            exit(-1);
    }
    global.platform.setup(config);
    router.registerApp(global.platform);

    global.platform.mergePlatformConfig(config);

    ipmesh.setup(config);
    meshtastic.setup(config);
    
    event.setup(config);
    global.event = event;
    router.registerApp(event);

    websocket.setup(config);
    nodedb.setup(config);
    router.registerApp(nodedb);
    node.setup(config);

    nodeinfo.setup(config);
    router.registerApp(nodeinfo);
    textmessage.setup(config);
    router.registerApp(textmessage);
    position.setup(config);
    router.registerApp(position);
    traceroute.setup(config);
    router.registerApp(traceroute);
    device.setup(config);
    router.registerApp(device);
    neighborinfo.setup(config);
    router.registerApp(neighborinfo);
    storeandforward.setup(config);
    router.registerApp(storeandforward);
    channel.setup(config);
    router.registerApp(channel);
    messagestore.setup(config);
    router.registerApp(messagestore);

    if (config.telemetry?.environmental) {
        switch (config.telemetry.environmental.type) {
            case "weewx":
                environmental_weewx.setup(config);
                router.registerApp(environmental_weewx);
                break;
            default:
                print(`Unknown environmental: ${config.environmental?.type}\n`);
                exit(-1);
        }
    }

    power.setup(config);
    router.registerApp(power);

    favorite.setup(config);
    router.registerApp(favorite);

    platform.publish(node.getInfo(), channel.getAllChannels());

    function shutdown()
    {
        nodedb.shutdown();
        textmessage.shutdown();
        messagestore.shutdown();
        platform.shutdown();
        exit(0);
    }
    signal("SIGHUP", shutdown);
    signal("SIGINT", shutdown);
    signal("SIGTERM", shutdown);
};

export function tick()
{
    router.tick();
    gc("collect");
};
