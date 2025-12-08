import * as struct from "struct";

export function decode(buf, name, allProtos)
{
    const proto = allProtos[name] ?? {};
    const r = {};
    const len = length(buf);
    let i = 0;

    function varint()
    {
        let d = 0;
        let s = 0;
        while (i < len) {
            const n = ord(buf, i++);
            d += (n & 127) << s;
            if (n < 128) {
                return d;
            }
            s += 7;
        }
        return null;
    }

    while (i < len) {
        const v = varint();
        if (v === null) {
            return null;
        }
        let d = null;
        switch (v & 7) {
            case 0: // 
            {
                d = varint();
                break;
            }
            case 1: // I64
                d = ord(buf, i) + (ord(buf, i + 1) << 8) + (ord(buf, i + 2) << 16) + (ord(buf, i + 3) << 24) + (ord(buf, i) << 32) + (ord(buf, i + 1) << 40) + (ord(buf, i + 2) << 48) + (ord(buf, i + 3) << 56);
                i += 8;
                break;
            case 2: // LEN
            {
                const l = varint();
                d = substr(buf, i, l);
                i += l;
                break;
            }
            case 5: // I32
                d = ord(buf, i) + (ord(buf, i + 1) << 8) + (ord(buf, i + 2) << 16) + (ord(buf, i + 3) << 24);
                i += 4;
                break;
            default:
                return null;
        }
        if (d === null) {
            return null;
        }
        const vi = `${v >> 3}`;
        let k = proto[vi] ?? vi;
        if (ord(k, 1) == 58) { // :
            const t = ord(k, 0);
            k = substr(k, 2);
            switch (t) {
                case 98: // b
                    d = !!d;
                    break;
                case 102: // f
                    if (d <= 0xffffffff) {
                        d = struct.unpack("f", struct.pack("I", d))[0];
                    }
                    else {
                        d = struct.unpack("d", struct.pack("Q", d))[0];
                    }
                    break;
                case 105: // i
                    if (d <= 0xffffffff) {
                        d = struct.unpack("i", struct.pack("I", d))[0];
                    }
                    else {
                        d = struct.unpack("q", struct.pack("Q", d))[0];
                    }
                    break;
                case 112: // p
                {
                    const tn = split(k, ":");
                    if (length(tn) === 2) {
                        k = tn[1];
                        d = decode(d, tn[0], allProtos);
                    }
                    break;
                }
                default:
                    break;
            }
        }
        r[k] = d;
    }
    return r;
};
