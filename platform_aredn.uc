import * as fs from "fs";
import * as timers from "timers";

const PUB = "/var/run/arednlink/publish";
const CURL = "/usr/bin/curl";

let id2address = {};

export function setup()
{
    fs.mkdir("/etc/aredntastic.d/");
    fs.mkdir("/tmp/aredntastic.d/");
    timers.setTimeout("aredn", 1 * 60);
};

function path(name)
{
    switch (name) {
        case "node":
            return `/etc/aredntastic.d/${node}.json`;
        default:
            return `/tmp/aredntastic.d/${name}.json`;
    }
}

export function load(name)
{
    const data = fs.readfile(path(name));
    return data ? json(data) : null;
};

export function store(name, data)
{
    fs.writefile(path(name), sprintf("%.02J", data));
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
    const loc = {
        latitide: 0, longitude: 0, altitude: 0
    };
    // Don't use uci as this may be loaded on non-uci platforms and we dont want it to error.
    const f = fs.open("/etc/config/aredn");
    if (f) {
        for (let line = f.read("line"); length(line); line = f.read("line")) {
            let m = match(line, /option lat '(.*)'/);
            if (m) {
                loc.latitide = 0.0 + m[1];
                loc.precision = 0;
            }
            m = match(line, /option lon '(.*)'/);
            if (m) {
                loc.longitude = 0.0 + m[1];
                loc.precision = 0;
            }
            m = match(line, /option height '(.*)'/);
            if (m) {
                loc.altitude = 0.0 + m[1];
                loc.precision = 0;
            }
        }
        f.close();
    }
    return loc;
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
