
var string = process.argv[2].split("");
var db = [];

function encode(c) {
	if (c >= chr('0') && c <= chr('9'))
		return c - chr('0');
	if (c >= chr('a') && c <= chr('z'))
		return 10 + c - chr('a');
	if (c >= chr('A') && c <= chr('Z'))
		return 10 + c - chr('A');
	if (c == chr(";"))
		return 36;
	if (c == chr("."))
		return 37;
	if (c == chr(" "))
		return 38;


	// if (c == chr("\n"))
		return 39; //anything else is a newline
}

function chr(s) {
	return s.charCodeAt(0)
}

function hex(c) {
	return ("00" + encode(chr(c)).toString(16)).substr(-2);
}

var opcodes = [
	["bcf", "90"], // bcf
	["bsf", "80"], // bsf
	["btc", "B0"], // btfsc
	["bts", "A0"], // btfss
	["mvl", "0E"], // movlw
	["mvw", "6E"], // movwf
	["mvf", "50"], // movf
	["add", "24"], // addwf
	["and", "14"], // andwf
	["ior", "10"], // iorwf
	["xor", "18"], // xorwf
	["rlc", "34"], // rlcf
	["rrc", "30"], // rrcf
	["bra", "EF"], // goto
	["cal", "EC"], // call
	["ret", "00"], // return
]

// opcodes.forEach(function(v) {

// 	// var res = encode(chr(o[0]));
// 	// res <<=1;
// 	// res = res ^ encode(chr(o[1]))
// 	// res <<=1;
// 	// res = res ^ encode(chr(o[2]));

// 	// res = encode(chr(o[0])) + encode(chr(o[1])) + encode(chr(o[2]));

// 	var k = v[0];
// 	console.log("db 0x" + hex(k[0]) + ", 0x" + hex(k[1]) + "\ndb 0x" + hex(k[2]) + ", 0x" + v[1]);
// })

while (string.length) {
	var c = string.shift();
	db.push(hex(c));
}

while (db.length) {
	console.log("db 0x" + db.shift() + ", 0x" + (db.shift() || 0) );
}
