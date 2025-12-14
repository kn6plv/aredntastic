import * as fs from "fs";
import * as timers from "timers";

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
            for (let i = 0; i < length(pubs); i++) {
                const file = `${PUB}/${pubs[i]}`;
                if (fs.lstat(file).size) {
                    const f = fs.open(file);
                    if (f) {
                        for (let line = f.read("line"); length(line); line = f.read("line")) {
                            try {
                                const record = json(line);
                                if (record.type == "aredntastic" && record.ip && record.id) {
                                    push(alist, record.ip);
                                    ilist[record.id] = record.ip;
                                }
                            }
                            catch (_) {
                            }
                        }
                        f.close();
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
