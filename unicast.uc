import * as socket from "socket";
import * as node from "node";
import * as platform from "platform";

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
    const address = platform.getInstance(to);
    if (to === node.BROADCAST || !address) {
        const mid = node.id();
        const instances = platform.getAllInstances();
        for (let id in instances) {
            if (id !== mid) {
                const r = s.send(data, 0, {
                    address: instances[id].ip,
                    port: PORT
                });
                if (r == null) {
                    print(socket.error(), "\n");
                }
            }
        }
    }
    else {
        const r = s.send(data, 0, {
            address: address.ip,
            port: PORT
        });
        if (r == null) {
            print(socket.error(), "\n");
        }
    }
};
