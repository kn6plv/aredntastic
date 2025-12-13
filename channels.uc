
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
const channelsByHash = {};
let primaryChannel;

export function setChannel(name, key)
{
    let crypto = [];
    const nkey = b64dec(key);
    if (length(nkey) === 1) {
        crypto = [ 0xd4, 0xf1, 0xbb, 0x3a, 0x20, 0x29, 0x07, 0x59, 0xf0, 0xbc, 0xff, 0xab, 0xcf, 0x4e, 0x69, ord(nkey, 0) ];
        if (crypto[-1] === 1) {
            if (index(primaryChannelPresets, name) == -1) {
                print("Bad primary channel name\n");
            }
            primaryChannel = name;
        }
    }
    else {
        for (let i = 0; i < length(nkey); i++) {
            crypto[i] = ord(nkey, i);
        }
    }
    let hash = 0;
    for (let i = 0; i < length(crypto); i++) {
        hash ^= crypto[i];
    }
    for (let i = 0; i < length(name); i++) {
        hash ^= ord(name, i);
    }
    const channel = { name: name, key: key, crypto: crypto, hash: hash };
    channelByName[name] = channel;
    channelsByHash[hash] = [ channel ];
};

export function getChannelsByHash(hash)
{
    if (!hash) {
        return [ channelByName[primaryChannel] ];
    }
    return channelsByHash[hash];
};

export function getChannelByName(name)
{
    return channelByName[name ?? primaryChannel];
};
