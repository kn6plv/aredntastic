import * as struct from "struct";
import * as fs from "fs";
import * as aes from "./aes.uc";

const OPENSSL = "/usr/bin/openssl";

export const defaultKey = [ 0xd4, 0xf1, 0xbb, 0x3a, 0x20, 0x29, 0x07, 0x59, 0xf0, 0xbc, 0xff, 0xab, 0xcf, 0x4e, 0x69, 0x01 ];

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
    const privatefile = "/tmp/private_key.der";
    const publicfile = "/tmp/public_key.der";
    system(`${OPENSSL} genpkey -algorithm X25519 -outform DER -out ${privatefile}; ${OPENSSL} pkey -inform DER -in ${privatefile} -pubout -outform DER -out ${publicfile}`);
    const keys = {
        public: fs.readfile(publicfile),
        private: fs.readfile(privatefile)
    };
    fs.unlink(privatefile);
    fs.unlink(publicfile);
    return keys;
};
