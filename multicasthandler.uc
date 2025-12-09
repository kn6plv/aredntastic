import * as socket from "socket";

let s = null;

export function setup()
{
    s = socket.create(socket.AF_INET, socket.SOCK_DGRAM, 0);
    s.bind({
        port: 4403
    });
    s.setopt(socket.IPPROTO_IP, socket.IP_ADD_MEMBERSHIP, {
        multiaddr: "224.0.0.69"
    });
    s.listen();
};

export function wait(timeout)
{
    const v = socket.poll(timeout * 1000, [ s, socket.POLLIN ]);
    if (v[0][1]) {
        return s.recvmsg(512).data;
    }
    return null;
};

export function send(data)
{
    const r = s.send(data, 0, {
        address: "224.0.0.69",
        port: 4403
    });
    if (r == null) {
        print(socket.error(), "\n");
    }
    return r;
};
