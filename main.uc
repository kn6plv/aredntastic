#!/usr/bin/ucode

import * as multicast from "./multicast.uc";
import * as node from "./node.uc";
import * as channels from "./channels.uc";
import * as apps from "./apps.uc";
import * as environmental from "./environmental_weewx.uc";

node.setup();
multicast.setup();
apps.setup();

channels.setChannel("MediumFast", "AQ==");
channels.setChannel("AREDN", "og==");

node.setLocation(37.888, -122.268, 10, 16);
node.setRole(node.ROLE_CLIENT);
environmental.setURL("http://192.168.51.130/current_minimal.json");

for (;;) {
    apps.tick();
}
