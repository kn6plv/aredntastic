#!/usr/bin/ucode

import * as multicasthandler from "./multicasthandler.uc";
import * as parse from "./parse.uc";
import * as nodedb from "./nodedb.uc";
import * as keys from "./keys.uc";
import * as node from "./node.uc";
import * as payloads from "./payloads.uc";

const me = node.getNode();

multicasthandler.setup();

let nodeupdatetime = 0;

for (;;) {
    const now = clock()[0];

    if (now > nodeupdatetime) {
        nodeupdatetime = now + 10 * 60;
        multicasthandler.send(
            parse.encodePacket(
                payloads.createPayload(me, null, "user", me.info()),
                keys.defaultKey
            )
        );
        multicasthandler.send(
            parse.encodePacket(
                payloads.createPayload(me, null, "position", me.position()),
                keys.defaultKey
            )
        );
    }

    const pkt = multicasthandler.wait(60);
    if (pkt) {
        const msg = parse.decodePacket(pkt, keys.defaultKey);
        printf("%.2J\n", msg);
        nodedb.updateNode(msg);
    }
}

