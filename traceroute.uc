import * as messages from "messages";
import * as router from "router";

const ROUTE_SIZE = 8;

export function process(msg)
{
    if (msg.data?.traceroute) {
        const traceroute = msg.data.traceroute;
        let routes;
        let snrs;
        if (msg.data.request_id) {
            // Back
            routes = traceroute.route_back;
            snrs = traceroute.snr_back;
        }
        else {
            // Toward
            routes = traceroute.route;
            snrs = traceroute.snr_towards;
        }

        // Fill in missing traceroute pieces (from nodes which dont support this?)
        if (msg.hop_start && msg.hop_limit && msg.hop_limit <= msg.hop_start) {
            const rdiff = msg.hop_start - msg.hop_limit - length(routes);
            for (let i = 0; i < rdiff; i++) {
                if (length(routes) < ROUTE_SIZE) {
                    push(routes, router.BROADCAST);
                }
            }
            const sdiff = length(routes) - length(snrs);
            for (let i = 0; i < sdiff; i++) {
                if (length(snrs) < ROUTE_SIZE) {
                    push(snrs, -128);
                }
            }
        }

        if (length(snrs) < ROUTE_SIZE) {
            push(snrs, 0); // snr == 0
        }
    
        if (!router.toMe(msg)) {
            if (length(routes) < ROUTE_SIZE) {
                push(routes, router.id());
            }
        }
        else {
            router.queue(messages.createReplyMessage(msg, "traceroute", traceroute));
        }
    }
};
