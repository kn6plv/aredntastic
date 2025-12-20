import * as fs from "fs";

let rootdir = "/tmp/aredntastic";

/* export */ function setup(config)
{
    rootdir = config.platform?.store ?? rootdir;
    function mkdirp(p)
    {
        const d = fs.dirname(p);
        if (d && d !== "." && d !== "/") {
            mkdirp(d);
        }
        fs.mkdir(p);
    }
    mkdirp(rootdir);
}

/* export */ function load(name)
{
    const data = fs.readfile(`${rootdir}/${name}.json`);
    return data ? json(data) : null;
}

/* export */ function store(name, data)
{
    fs.writefile(`${rootdir}/${name}.json`, sprintf("%.02J", data));
}

/* export */ function fetch(url)
{
    const p = fs.popen(`curl --max-time 2 --silent --output - ${url}`);
    if (!p) {
        return null;
    }
    const all = p.read("all");
    p.close();
    return all;
}

/* export */ function getAllTargets()
{
    return [];
}

/* export */ function getTarget(id)
{
    return null;
}

/* export */ function getLocation()
{
    print("Location not set\n");
    return null;
}

/* export */ function getMulticastDeviceIP()
{
    return null;
}

/* export */ function publish()
{
}

/* export */ function tick()
{
}

/* export */ function process(msg)
{
}

return {
    setup,
    load,
    store,
    fetch,
    getAllTargets,
    getTarget,
    getLocation,
    getMulticastDeviceIP,
    publish,
    tick,
    process
};
