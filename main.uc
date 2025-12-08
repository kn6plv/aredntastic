#!/usr/bin/ucode

import * as multicasthandler from "./multicasthandler.uc";
import * as parse from "./parse.uc";

multicasthandler.setup();
for (;;) {
    const pkt = multicasthandler.wait();
    if (pkt) {
        const msg = parse.parsePacket(pkt);
        printf("%.2J\n", msg);
    }
}
