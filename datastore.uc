import * as fs from "fs";

const ROOT = "/tmp/at";

export function load(name)
{
    const data = fs.readfile(`${ROOT}/${name}.json`);
    return data ? json(data) : null;
};

export function store(name, data)
{
    fs.writefile(`${ROOT}/${name}.json`, sprintf("%.02J", data));
};
