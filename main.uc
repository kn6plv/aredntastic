#!/usr/bin/ucode

import * as multicasthandler from "./multicasthandler.uc";
import * as node from "./node.uc";
import * as messages from "./messages.uc";
import * as router from "./router.uc";

const me = node.getNode();

multicasthandler.setup();

let nodeupdatetime = 0;

//router.process(payloads.createTextMessage(me, null, "Testing"));

for (;;) {
    const now = clock()[0];
    if (now > nodeupdatetime) {
        nodeupdatetime = now + 30 * 60;
        router.process(messages.createMessage(me, null, "user", me.info()));
        router.process(messages.createMessage(me, null, "position", me.position()));
        router.process(messages.createMessage(me, null, "telemetry", me.deviceTelemetry()));
    }
    router.wait(60);
}

