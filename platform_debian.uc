import * as fs from "fs";

let ROOT = "/tmp";

export function setup(config)
{
    ROOT = config.platform.store;
    fs.mkdir(ROOT);
};

export function load(name)
{
    const data = fs.readfile(`${ROOT}/${name}.json`);
    return data ? json(data) : null;
};

export function store(name, data)
{
    fs.writefile(`${ROOT}/${name}.json`, sprintf("%.02J", data));
};

export function fetch(url)
{
    const p = fs.popen(`curl --max-time 2 --silent --output - ${url}`);
    if (!p) {
        return null;
    }
    const all = p.read("all");
    p.close();
    return all;
};

export function getAllInstances()
{
    return {};
};

export function getInstance(id)
{
    return null;
};

export function getLocation()
{
    print("Location not set\n");
    return null;
};

export function getMulticastDeviceIP()
{
    return null;
};

export function tick()
{
};

export function process(msg)
{
};
