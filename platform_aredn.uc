import * as fs from "fs";
import * as timers from "timers";
import * as node from "node";

const PUB = "/var/run/arednlink/publish";

let id2address = {};
let addresses = [];

timers.setTimeout("aredn", 1 * 60);

export function getOtherInstances()
{
    return addresses;
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
        const alist = [];
        const pubs = fs.lsdir(PUB);
        if (pubs) {
            const mid = node.id();
            for (let i = 0; i < length(pubs); i++) {
                const file = `${PUB}/${pubs[i]}`;
                if (fs.lstat(file).size) {
                    try {
                        const pub = json(fs.readfile(file));
                        for (let i = 0; i < length(pub.data); i++) {
                            const record = pub.data[i];
                            if (record.type == "KN6PLV.aredntastic" && record.ip && record.id && record.id !== mid) {
                                push(alist, record.ip);
                                ilist[record.id] = record.ip;
                            }
                        }
                    }
                    catch (_) {
                    }
                }
            }
        }
        id2address = ilist;
        addresses = alist;
    }
};

export function process(msg)
{
};
