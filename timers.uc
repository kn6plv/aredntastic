
const timers = {};

export function setTimeout(name, timeout)
{
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
