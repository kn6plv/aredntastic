import * as socket from "socket";
import * as node from "node";
import * as aredn from "aredn";

const PORT = 4404;

let s = null;

export function setup()
{
    s = socket.create(socket.AF_INET, socket.SOCK_DGRAM, 0);
    s.bind({
        port: PORT
    });
    s.listen();
};

export function handle()
{
    return s;
};

export function recv()
{
    return s.recvmsg(65535).data;
};

export function send(to, data)
{
    if (to === node.BROADCAST) {
        const addresses = aredn.getOtherInstances();
        for (let i = 0; i < length(addresses); i++) {
            const r = s.send(data, 0, {
                address: addresses[i],
                port: PORT
            });
            if (r == null) {
                print(socket.error(), "\n");
            }
        }
    }
    else {
        const address = aredn.getInstance(to);
        if (address) {
            const r = s.send(data, 0, {
                address: address,
                port: PORT
            });
            if (r == null) {
                print(socket.error(), "\n");
            }
        }
    }
};
