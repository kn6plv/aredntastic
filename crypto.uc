import * as struct from "struct";
import * as math from "math";
import * as aes from "aes";
import * as x25519 from "x25519";

export function decrypt(from, id, key, encrypted, xnonce)
{
    let plain = "";

    aes.AES_Init();

    const ekey = aes.AES_ExpandKey(slice(key));

    const counter = struct.unpack("16B", struct.pack("QIII", id, from, 0, 0));
    if (xnonce) {
        counter[4] = ord(xnonce, 0);
        counter[5] = ord(xnonce, 1);
        counter[6] = ord(xnonce, 2);
        counter[7] = ord(xnonce, 3);
    }
    let ecounterIdx = 16;
    let ecounter;

    for (let i = 0; i < length(encrypted); i++) {
        if (ecounterIdx === 16) {
            ecounter = aes.AES_Encrypt(slice(counter), ekey);
            ecounterIdx = 0;
            for (let j = 15; j >= 0; j--) {
                if (counter[j] !== 255) {
                    counter[j]++;
                    break;
                }
                counter[j] = 0;
            }
        }
        plain += chr(ord(encrypted, i) ^ ecounter[ecounterIdx++]);
    }

    aes.AES_Done();

    return plain;
};

export function encrypt(from, id, key, plain)
{
    return decrypt(from, id, key, plain);
};

export function generateKeyPair()
{
    const kprivate = [];
    for (let i = 0; i < 16; i++) {
        kprivate[i] = (math.rand(255) << 8) | math.rand(255);
    }
    return {
        private: kprivate,
        public: x25519.curve25519(kprivate)
    };
};

export function getSharedKey(myprivatekey, theirpublickey)
{
    const sk = x25519.curve25519(myprivatekey, theirpublickey);
    const bk = [];
    for (let i = 0; i < length(sk); i++) {
        push(bk, sk[i] & 255, (sk[i] >> 8) & 255);
    }
    return bk;
};

export function pKeyToString(key)
{
    let str = "";
    for (let i = 0; i < length(key); i++) {
        const v = key[i];
        str += chr(v & 255, (v >> 8) & 255);
    }
    return str;
};

export function stringToPKey(str)
{
    const key = [];
    for (let i = 0; i < length(str); i += 2) {
        push(key, ord(str, i) | (ord(str, i + 1) << 8));
    }
    return key;
};
