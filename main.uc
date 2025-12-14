#!/usr/bin/ucode

import * as unicast from "./unicast.uc";
import * as multicast from "./multicast.uc";
import * as node from "./node.uc";
import * as channel from "./channel.uc";
import * as apps from "./apps.uc";
import * as platform from "./platform.uc";
import * as environmental from "./environmental_weewx.uc";

node.setup();
unicast.setup();
multicast.setup();
apps.setup();

channel.setChannel("MediumFast", "AQ==");
channel.setChannel("AREDN", "og==");

const loc = platform.getLocation();
node.setLocation(loc[0], loc[1], loc[2], 0);
node.setRole(node.ROLE_CLIENT);
environmental.setURL("http://192.168.51.130/current_minimal.json");

for (;;) {
    apps.tick();
}
