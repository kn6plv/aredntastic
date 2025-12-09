#!/usr/bin/ucode

import * as multicasthandler from "./multicasthandler.uc";
import * as parse from "./parse.uc";
import * as nodedb from "./nodedb.uc";
import * as keys from "./keys.uc";

multicasthandler.setup();
for (;;) {
    const pkt = multicasthandler.wait();
    if (pkt) {
        const msg = parse.decodePacket(pkt, keys.defaultKey);
        printf("%.2J\n", msg);
        nodedb.updateNode(msg);
    }
}
