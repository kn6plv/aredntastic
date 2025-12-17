
const timers = {};

export function setInterval(name, timeout)
{
    if (type(timeout) === "string") {
        switch (substr(timeout, -1)) {
            case "m":
                timeout = int(v) * 60;
                break;
            case "h":
                timeout = int(v) * 60 * 60;
                break;
            case "s":
            default:
                timeout = int(v);
                break;
        }
    }
    timers[name] = { next: clock()[0], timeout: timeout };
};

export function tick(name)
{
    const now = clock()[0];
    const timer = timers[name];
    if (now > timer.next) {
        timer.next = timer.next + timer.timeout;
        return true;
    }
    return false;
};

export function minTimeout(limit)
{
    let next = 0xffffffff;
    map(values(timers), timer => next = min(timer.next, next));
    return min(limit, max(0, next - clock()[0]));
};
