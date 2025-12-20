import * as socket from "socket";
import * as node from "node";

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
    const targets = platform.getAllTargets();
    const target = to === node.BROADCAST ? null : filter(targets, i => i.id === to)[0];
    if (!target) {
        const mid = node.id();
        for (let i = 0; i < length(targets); i++) {
            const target = targets[i];
            if (target.id !== mid) {
                const r = s.send(data, 0, {
                    address: target.ip,
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
            address: target.ip,
            port: PORT
        });
        if (r == null) {
            print(socket.error(), "\n");
        }
    }
};
