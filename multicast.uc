import * as socket from "socket";

const ADDRESS = "224.0.0.69";
const PORT = 4403;

let s = null;

export function setup(config)
{
    if (!config.multicast) {
        return;
    }
    const address = config.multicast.address;
    s = socket.create(socket.AF_INET, socket.SOCK_DGRAM, 0);
    s.bind({
        port: PORT
    });
    if (!address) {
        s.setopt(socket.IPPROTO_IP, socket.IP_ADD_MEMBERSHIP, {
            multiaddr: ADDRESS
        });
    }
    else {
        s.setopt(socket.IPPROTO_IP, socket.IP_MULTICAST_IF, {
            address: address
        });
        s.setopt(socket.IPPROTO_IP, socket.IP_ADD_MEMBERSHIP, {
            address: address,
            multiaddr: ADDRESS
        });
    }
    s.setopt(socket.IPPROTO_IP, socket.IP_MULTICAST_LOOP, 0);
    s.listen();
};

export function handle()
{
    return s;
};

export function recv()
{
    return s.recvmsg(512).data;
};

export function send(data)
{
    if (s !== null) {
        const r = s.send(data, 0, {
            address: ADDRESS,
            port: PORT
        });
        if (r == null) {
            print(socket.error(), "\n");
        }
    }
};
