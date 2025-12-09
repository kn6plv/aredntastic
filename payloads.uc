import * as math from "math";

export function createPayload(from, to, type, payload)
{
    return {
        from: from.id(),
        to: to?.id() ?? 0xffffffff, // Broadcast by default
        channel: 31,
        id: math.rand(),
        rx_time: time(),
        rx_snr: 0,
        hop_limit: 5,
        priority: 64,
        rx_rssi: 0,
        hop_start: 5,
        relay_node: from.id() & 255,
        transport_mechanism: 6, // multicast udp
        data: {
            bitfield: 0,
            [type]: payload
        }
    };
};
