import * as math from "math";

const sha256h = [];
const sha256k = [];

function rightRotate(value, amount)
{
	return (((value >> 1) & 0x7fffffff) >> (amount - 1)) | (value << (32 - amount));
};

function rightShift(value, amount)
{
	return (((value >> 1) & 0x7fffffff) >> (amount - 1));
}

export function sha256(data)
{
	const maxWord = 0x100000000;
	const words = [];
	const dataBitLength = length(data) * 8;

	//* caching results is optional - remove/add slash from front of this line to toggle
	// Initial hash value: first 32 bits of the fractional parts of the square roots of the first 8 primes
	// (we actually calculate the first 64, but extra values are just ignored)
	let hash = sha256h;
	// Round constants: first 32 bits of the fractional parts of the cube roots of the first 64 primes
	const k = sha256k;
	let primeCounter = length(k);

	const isComposite = {};
	for (let candidate = 2; primeCounter < 64; candidate++) {
		if (!isComposite[candidate]) {
			for (let i = 0; i < 313; i += candidate) {
				isComposite[i] = candidate;
			}
			hash[primeCounter] = (math.pow(candidate, 0.5) * maxWord | 0);
			k[primeCounter++] = (math.pow(candidate, 1.0 / 3) * maxWord | 0);
		}
	}

	data += '\x80'; // Append '1' bit (plus zero padding)
	while (length(data) % 64 - 56) {
		data += '\x00'; // More zero padding
	}
	for (let i = 0; i < length(data); i++) {
		const j = ord(data, i);
		words[i >> 2] |= j << ((3 - i) & 3) * 8;
	}
	words[length(words)] = ((dataBitLength / maxWord) | 0);
	words[length(words)] = (dataBitLength);

	// process each chunk
	for (let j = 0; j < length(words);) {
		const w = slice(words, j, j += 16); // The message is expanded into 64 words as part of the iteration
		const oldHash = hash;
		// This is now the "working hash", often labelled as variables a...g
		// (we have to truncate as well, otherwise extra entries at the end accumulate
		hash = slice(hash, 0, 8);

		for (let i = 0; i < 64; i++) {
			const i2 = i + j;
			// Expand the message into 64 words
			// Used below if 
			const w15 = w[i - 15], w2 = w[i - 2];

			// Iterate
			const a = hash[0], e = hash[4];
			const temp1 = hash[7]
				+ (rightRotate(e, 6) ^ rightRotate(e, 11) ^ rightRotate(e, 25)) // S1
				+ ((e & hash[5]) ^ ((~e) & hash[6])) // ch
				+ k[i]
				// Expand the message schedule if needed
				+ (w[i] = (i < 16) ? w[i] : (
					w[i - 16]
					+ (rightRotate(w15, 7) ^ rightRotate(w15, 18) ^ rightShift(w15, 3)) // s0
					+ w[i - 7]
					+ (rightRotate(w2, 17) ^ rightRotate(w2, 19) ^ rightShift(w2, 10)) // s1
				) | 0
				);
			// This is only used once, so *could* be moved below, but it only saves 4 bytes and makes things unreadble
			const temp2 = (rightRotate(a, 2) ^ rightRotate(a, 13) ^ rightRotate(a, 22)) // S0
				+ ((a & hash[1]) ^ (a & hash[2]) ^ (hash[1] & hash[2])); // maj

			const ohash = hash;
			hash = [0xffffffff & (temp1 + temp2) | 0];
			for (let h = 0; h < length(ohash); h++) {
				push(hash, ohash[h]);
			}
			hash[4] = (hash[4] + temp1) | 0;
		}

		for (let i = 0; i < 8; i++) {
			hash[i] = (hash[i] + oldHash[i]) | 0;
		}
	}

	let result = "";
	for (let i = 0; i < 8; i++) {
		for (let j = 3; j + 1; j--) {
			const b = (hash[i] >> (j * 8)) & 255;
			result += sprintf("%02x", b);
		}
	}
	return result;
};
