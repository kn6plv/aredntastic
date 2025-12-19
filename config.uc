import * as fs from "fs";
import * as router from "router";
import * as channel from "channel";
import * as node from "node";
import * as unicast from "unicast";
import * as multicast from "multicast";

import * as nodeinfo from "nodeinfo";
import * as textmessage from "textmessage";
import * as position from "position";
import * as traceroute from "traceroute";
import * as device from "telemetry_device";
import * as environmental_weewx from "telemetry_environmental_weewx";

export function setup()
{
    push(REQUIRE_SEARCH_PATH, `${fs.dirname(SCRIPT_NAME)}/*.uc`);

    const config = json(fs.readfile("/etc/aredntastic.conf") ?? fs.readfile(`${fs.dirname(SCRIPT_NAME)}/aredntastic.conf`));

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

    unicast.setup(config);
    multicast.setup(config);
    node.setup(config);

    platform.publish();

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

    if (!config.preset) {
        print("No preset\n");
        exit(-1);
    }
    channel.setChannel(config.preset, "AQ==");
    const channels = config.channels?.shared;
    if (channels) {
        for (let name in channels) {
            channel.setChannel(name, channels[name]);
        }
    }
};

export function tick()
{
    router.tick();
    gc("collect");
};
