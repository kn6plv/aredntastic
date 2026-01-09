
const primaryChannelPresets = [
    "ShortTurbo",
    "ShortSlow",
    "ShortFast",
    "MediumSlow",
    "MediumFast",
    "LongSlow",
    "LongFast",
    "LongMod",
    "LongTurbo"
];

const MAX_NAME_LENGTH = 13;

global.channelByNameKey = {};
global.channelsByHash = {};
let primaryChannel;
let channelByName = {};

function getCryptoKey(key)
{
    key = b64dec(key);
    if (length(key) === 1) {
        return [ 0xd4, 0xf1, 0xbb, 0x3a, 0x20, 0x29, 0x07, 0x59, 0xf0, 0xbc, 0xff, 0xab, 0xcf, 0x4e, 0x69, ord(key, 0) ];
    }
    else {
        const crypto = [];
        for (let i = 0; i < length(key); i++) {
            crypto[i] = ord(key, i);
        }
        return crypto;
    }
}

function getHash(name, crypto)
{
    let hash = 0;
    for (let i = 0; i < length(name); i++) {
        hash ^= ord(name, i);
    }
    for (let i = 0; i < length(crypto); i++) {
        hash ^= crypto[i];
    }
    return hash;
}

export function addMessageNameKey(namekey)
{
    if (channelByNameKey[namekey]) {
        return channelByNameKey[namekey];
    }
    const nk = split(namekey, " ");
    const crypto = getCryptoKey(nk[1]);
    const hash = getHash(nk[0], crypto);
    const chan = { namekey: namekey, crypto: crypto, hash: hash };
    channelByNameKey[namekey] = chan;
    const bucket = channelsByHash[hash] ?? (channelsByHash[hash] = []);
    push(bucket, chan);
    return chan;
};

function setChannel(name, key)
{
    name = substr(replace(name, /[ \t\r\n]/g, ""), 0, MAX_NAME_LENGTH);
    const chan = addMessageNameKey(`${name} ${key}`);
    if (chan.crypto[-1] === 1) {
        if (index(primaryChannelPresets, name) == -1) {
            print("Bad primary channel name\n");
        }
        primaryChannel = chan;
        chan.primary = true;
    }
    channelByName[name] = chan;
};

export function getChannelsByHash(hash)
{
    if (!hash) {
        return [ primaryChannel ];
    }
    return channelsByHash[hash];
};

export function getLocalChannelByName(name)
{
    if (!name) {
        return primaryChannel;
    }
    return channelByName[name];
};

export function getLocalChannelByNameKey(namekey)
{
    return getLocalChannelByName(split(namekey, " ")[0]);
};

export function getChannelByNameKey(namekey)
{
    if (!namekey) {
        return primaryChannel;
    }
    return channelByNameKey[namekey];
};

export function getAllChannels()
{
    return values(channelByName);
};

export function updateChannels(channels)
{
    channelByName = {};
    for (let i = 0; i < length(channels); i++) {
        const kn = split(channels[i].namekey, " ");
        setChannel(kn[0], kn[1]);
    }
};

export function setup(config)
{
    if (!config.preset) {
        print("No preset\n");
    }
    else {
        setChannel(config.preset, "AQ==");
    }
    const channels = config.channels;
    if (channels) {
        for (let name in channels) {
            setChannel(name, channels[name]);
        }
    }
};

export function tick()
{
};

export function process(msg)
{
};
