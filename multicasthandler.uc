import * as socket from "socket";

let s = null;

function init()
{
    s = socket.create(socket.AF_INET, socket.SOCK_DGRAM, 0);
    s.bind({
        port: 4403
    });
    s.setopt(socket.IPPROTO_IP, socket.IP_ADD_MEMBERSHIP, {
        multiaddr: "224.0.0.69"
    });
    s.listen();
}

export function setup()
{
    init();
};

export function wait()
{
    const v = socket.poll(10000, [ s, socket.POLLIN ]);
    if (v[0][1]) {
        return s.recvmsg(512).data;
    }
    return null;
};

