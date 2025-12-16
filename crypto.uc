import * as struct from "struct";
import * as math from "math";
import * as aes from "aes";
import * as x25519 from "x25519";

export function decryptCTR(from, id, key, encrypted)
{
    let plain = "";

    aes.AES_Init();

    const ekey = aes.AES_ExpandKey(slice(key));

    const counter = struct.unpack("16B", struct.pack("<IIII", id, 0, from, 0));
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

export function encryptCTR(from, id, key, plain)
{
    return decryptCTR(from, id, key, plain);
};

export function decryptCCM(from, id, key, encrypted, xnonce, auth)
{
    let plain = "";

    aes.AES_Init();

    const ekey = aes.AES_ExpandKey(slice(key));

    const nonce = struct.pack("<I", id) + xnonce + struct.pack("<II", from, 0);
    const counter = struct.unpack("16B", struct.pack("B", 1) + substr(nonce, 0, 13) + struct.pack("2B", 0, 0));
    const a = aes.AES_Encrypt(slice(counter), ekey);
    let cauth = [];
    for (let i = 0; i < 8; i++) {
        push(cauth, ord(auth, i) ^ a[i]);
    }
    counter[15]++;

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

export function encryptCCM(from, id, key, plain, xnonce, auth)
{
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
    const key = x25519.curve25519(myprivatekey, theirpublickey);
    let str = "";
    for (let i = 0; i < length(key); i++) {
        const v = key[i];
        str += chr(v & 255, (v >> 8) & 255);
    }
    return str;
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
