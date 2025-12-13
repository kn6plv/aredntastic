import * as router from "router";

import * as user from "user";
import * as textmessage from "textmessage";
import * as position from "position";
import * as traceroute from "traceroute";
import * as device from "device";
import * as environmental from "environmental_weewx";
import * as aredn from "aredn";

export function setup()
{
    router.registerApp(user);
    router.registerApp(textmessage);
    router.registerApp(position);
    router.registerApp(traceroute);
    router.registerApp(device);
    router.registerApp(environmental);
    router.registerApp(aredn);
};

export function tick()
{
    router.tick();
    gc("collect");
};
