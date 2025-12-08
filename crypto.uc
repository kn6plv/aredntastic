import * as struct from "struct";
import * as aes from "./aes.uc";

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
