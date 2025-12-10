#!/usr/bin/ucode

import * as multicast from "./multicast.uc";
import * as node from "./node.uc";
import * as router from "./router.uc";

import * as messages from "./messages.uc";
import * as nodedb from "./nodedb.uc";
import * as traceroute from "./traceroute.uc";

node.setup();
multicast.setup();

router.registerApp(messages);
router.registerApp(nodedb);
router.registerApp(traceroute);

let nodeupdatetime = 0;

//router.queue(payloads.createTextMessage(null, null, "Testing"));

for (;;) {
    const now = clock()[0];
    if (now > nodeupdatetime) {
        nodeupdatetime = now + 30 * 60;
        const me = node.getInfo();
        router.queue(messages.createMessage(null, null, "user", me.info()));
        router.queue(messages.createMessage(null, null, "position", me.position()));
        router.queue(messages.createMessage(null, null, "telemetry", me.deviceTelemetry()));
    }
    router.wait(60);
}
