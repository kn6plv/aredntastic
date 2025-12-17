import * as socket from "socket";

const ADDRESS = "224.0.0.69";
const PORT = 4403;

let s = null;

export function setup(config)
{
    const address = config.network?.address;
    s = socket.create(socket.AF_INET, socket.SOCK_DGRAM, 0);
    if (!address) {
        s.bind({
            port: PORT
        });
    }
    else {
        let r = s.bind({
            address: address,
            port: PORT
        });
        print(r,"\n");
        r = s.setopt(socket.IPPROTO_IP, socket.IP_MULTICAST_IF, {
            address: address
        });
        print(r, "\n");
    }
    s.setopt(socket.IPPROTO_IP, socket.IP_ADD_MEMBERSHIP, {
        multiaddr: ADDRESS
    });
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
    const r = s.send(data, 0, {
        address: ADDRESS,
        port: PORT
    });
    if (r == null) {
        print(socket.error(), "\n");
    }
};
