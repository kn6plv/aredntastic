#!/usr/bin/ucode

import * as multicast from "./multicast.uc";
import * as node from "./node.uc";
import * as router from "./router.uc";
import * as channels from "./channels.uc";

import * as user from "./user.uc";
import * as messages from "./messages.uc";
import * as position from "./position.uc";
import * as traceroute from "./traceroute.uc";
import * as device from "./device.uc";
import * as environmental from "./environmental_weewx.uc";

node.setup();
multicast.setup();

router.registerApp(user);
router.registerApp(messages);
router.registerApp(position);
router.registerApp(traceroute);
router.registerApp(device);
router.registerApp(environmental);

channels.setChannel("MediumFast", "AQ==");
channels.setChannel("AREDN", "og==");

//router.queue(messages.createTextMessage(null, null, "AREDN", "Testing"));

node.setLocation(37.2113000, -121.9362000, 10, 16);
node.setRole(node.ROLE_CLIENT);
environmental.setURL("http://192.168.51.130/current_minimal.json");

for (;;) {
    router.tick();
}
