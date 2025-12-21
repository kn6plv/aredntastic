import * as socket from "socket";

const PORT = 4404;

let s = null;

export function setup(config)
{
    if (!config.unicast) {
        return;
    }
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

export function send(to, namekey, data)
{
    const targets = platform.getTargetsByIdAndNamekey(to, namekey);
    for (let i = 0; i < length(targets); i++) {
        const r = s.send(data, 0, {
            address: targets[i].ip,
            port: PORT
        });
        if (r === null) {
            printf("unicast:send error: %s\n", socket.error());
        }
    }
};
