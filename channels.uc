
const primaryChannelPresets = [
    "ShortTurbo",
    "ShortSlow",
    "ShortFast",
    "MediumSlow",
    "MediumFast",
    "LongSlow",
    "LongFast",
    "LongMod"
];

const channelByName = {};
const channelByHash = {};
let primaryChannel;

export function setChannel(name, key)
{
    let nkey = [];
    key = b64dec(key);
    if (length(key) === 1) {
        nkey = [ 0xd4, 0xf1, 0xbb, 0x3a, 0x20, 0x29, 0x07, 0x59, 0xf0, 0xbc, 0xff, 0xab, 0xcf, 0x4e, 0x69, ord(key, 0) ];
        if (nkey[-1] === 1) {
            if (index(primaryChannelPresets, name) == -1) {
                print("Bad primary channel name\n");
            }
            primaryChannel = name;
        }
    }
    else {
        for (let i = 0; i < length(key); i++) {
            nkey[i] = ord(key, i);
        }
    }
    let hash = 0;
    for (let i = 0; i < length(nkey); i++) {
        hash ^= nkey[i];
    }
    for (let i = 0; i < length(name); i++) {
        hash ^= ord(name, i);
    }
    const channel = { name: name, key: nkey, hash: hash };
    channelByName[name] = channel;
    channelByHash[hash] = channel;
};

export function getChannelByHash(hash)
{
    return channelByHash[hash];
};

export function getChannelByName(name)
{
    return channelByName[name ?? primaryChannel];
};
