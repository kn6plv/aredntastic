import * as parse from "parse";


parse.registerProto(
    "heartbeat", null,
    {
        "1": "uint32 period",
        "2": "uint32 secondary"
    }
);
parse.registerProto(
    "storeandforward", 65,
    {
        "1": "enum rr",
        "2": "proto statistics stats",
        "3": "proto history history",
        "4": "proto heartbeat heartbeat",
        "5": "bytes text"
    }
);

export function setup(config)
{
};

export function tick()
{
};

export function process(msg)
{
};
