import * as fs from "fs";
import * as node from "node";

let ROOT = "/tmp";
const CURL = "/usr/bin/curl";

let id2address = {};

export function setup(config)
{
    ROOT = config.platform.store;
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
    const p = fs.popen(`${CURL} --max-time 2 --silent --output - ${url}`);
    if (!p) {
        return null;
    }
    const all = p.read("all");
    p.close();
    return all;
};

export function getAllInstances()
{
    return id2address;
};

export function getInstance(id)
{
    return id2address[id];
};

export function tick()
{
};

export function process(msg)
{
};
