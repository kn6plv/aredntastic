import * as fs from "fs";
import * as router from "router";
import * as channel from "channel";
import * as node from "node";
import * as unicast from "unicast";
import * as multicast from "multicast";
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
import * as device from "telemetry_device";
import * as environmental_weewx from "telemetry_environmental_weewx";
import * as power from "telemetry_power";

export function setup()
{
    push(REQUIRE_SEARCH_PATH, `${fs.dirname(SCRIPT_NAME)}/*.uc`);

    const config = json(fs.readfile("/etc/raven.conf") ?? fs.readfile(`${fs.dirname(SCRIPT_NAME)}/raven.conf`));
    const override = json(fs.readfile("/etc/raven.conf.override") ?? fs.readfile(`${fs.dirname(SCRIPT_NAME)}/raven.conf.override`) ?? "[]");
    if (type(override) === "object") {
        function f(c, o)
        {
            for (let k in o) {
                if (o[k] === null) {
                    delete c[k];
                }
                else switch (type(o[k])) {
                    case "object":
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

    if (config.debug) {
        global.DEBUG = function(...a)
        {
            printf(...a);
        };
    }
    else {
        global.DEBUG = function(){};
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

    unicast.setup(config);
    multicast.setup(config);
    
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
