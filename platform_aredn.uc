import * as fs from "fs";
import * as timers from "timers";

const ROOT = "/tmp/at";
const PUB = "/var/run/arednlink/publish";
const CURL = "/usr/bin/curl";

let id2address = {};

export function setup()
{
    timers.setTimeout("aredn", 1 * 60);
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

export function getLocation()
{
    return [ 37.888, -122.268, 10 ];
};

export function tick()
{
    if (timers.tick("aredn")) {
        const ilist = {};
        const pubs = fs.lsdir(PUB);
        if (pubs) {
            for (let i = 0; i < length(pubs); i++) {
                const file = `${PUB}/${pubs[i]}`;
                if (fs.lstat(file).size) {
                    try {
                        const pub = json(fs.readfile(file));
                        for (let i = 0; i < length(pub.data); i++) {
                            const record = pub.data[i];
                            if (record.type == "KN6PLV.aredntastic" && record.ip && record.id) {
                                ilist[record.id] = { ip: record.ip, private_key: record.private_key };
                            }
                        }
                    }
                    catch (_) {
                    }
                }
            }
        }
        id2address = ilist;
    }
};

export function process(msg)
{
};
