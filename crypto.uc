import * as struct from "struct";
import * as math from "math";
import * as aes from "aes";
import * as x25519 from "x25519";

export function decrypt(from, id, key, encrypted)
{
    let plain = "";

    aes.AES_Init();

    const ekey = aes.AES_ExpandKey(slice(key));

    const counter = struct.unpack("16B", struct.pack("QIII", id, from, 0, 0));
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
    const kpublic = x25519.curve25519(kprivate);
    return {
        public: kpublic,
        private: kprivate
    };
};

export function generateSharedKey(myprivatekey, theirpublickey)
{
    return x25519.curve25519(myprivatekey, theirpublickey);
};
