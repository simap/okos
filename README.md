One Kilobyte Operating System (OKOS)
================

Tiny OS for 1kB challenge

MVP
---

* display driver and api
	* minimal font - remember original Apple ][ uppercase only font
	* Use 3x5 tiny font
	* text drawing api
		* oledDrawChar
		* oledNewLine
	* optional lowercase font, with descender support 3x5.5!
* filesystem (if you can call it that)
	* Actually just chopping 32k flash into 16 2k files.
* keyboard driver and api
	* ps2 keyboard interface
	* scan code map/table
	* handle only keyup. Keyboard gives you repeat for free
* cli/menu with some built-ins
	* minimal assembler
		* what kind of OS doesn't let you write code?!?
		* minimal, but workable, instruction set support
	* editor
		* Hopefully better than edlin
	* run
		* user program takes over
		* core API available
		* user ISR supported

Notes
----

### keyboard

Supports PS2 keyboards, decode scancodes.

* simple protocol
* can ignore keyup. 
* ignore most special keys.

### filesystem

* pic18f25k50 has 32k flash. Split into 16 "files" of 2k each. file 0 (half of it anyway) contains okos.
* TODO reserve first page, 64b, for metadata.


### display

* the 128x64 oled needs very little setup.
* could get 10 lines of text (+ 4 pixels spare), but requires extra bit shifting. 8 lines of 8 pixels is easy w/ the displays 8 bit tall row x 128 segments.
* Full 7-bit ASCII support (96 chars) is 192 bytes. Each face is 15 bits, can use the 16th bit to shift down for descenders.
* Unbuffered, render characters on the fly and send to display


### MCU

pic18f25k50

* uses 16-bit instruction words, and can store 2-8bit bytes per word easily.
* has 32k of flash, leaving 31k for filesystem
* has 1k eeprom
* Has almost enough RAM to fit entire 2k file into memory. 

### Assembler

Minimal usable PIC instruction set.

3 character mnemonics to save space.

* `;` for comments, can be anywhere
* `.` on a line alone to end the file/parsing

| PIC instruction | short mnemonic | args | notes |
| --- | --- | --- | --- |
| bcf | bcf | f, b | 1 instruction |
| bsf | bsf | f, b | 1 instruction |
| btfsc | btc | f, b | 1 instruction |
| btfss | bts | f, b | 1 instruction |
| movlw | mvl | k | 1 instruction |
| movwf | mvw | f | 1 instruction |
| movf | mvf | f, d | 1 instruction |
| addwf | add | f, d | 1 instruction |
| andwf | and | f, d | 1 instruction |
| iorwf | ior | f, d | 1 instruction |
| xorwf | xor | f, d | 1 instruction |
| rlcf | rlc | f, d | 1 instruction |
| rrcf | rrc | f, d | 1 instruction |
| goto | bra | k | 2 instructions<br>target address is doubled. Think of them as instruction word addresses instead of byte addresses. File 1 starts at `0x400`|
| call | cal | k | 2 instructions. Same addressing as goto |
| return | - | - | NOT IMPLEMENTED<br>Use **`bra b`** |

**NOTE** return is not implemented, but a return instruction is placed at address 0x16 (word 0xb), jumping there will effect a return.

User ISR starts at offset **`0x04`**, the second instruction. Boilerplate program with an ISR:

```
bra 0012 ; jump past ISR
; insert your ISR code here
; ...
bra 000b ; execute a return
; at word 12. insert your code here
. ; EOF
```

User memory starts at address 0x16, anything before that is needed by the core API. If you don't use the API, feel free to reclaim this memory! Note that if you use ISRs, address 0x00 controls which file block the ISR jumps to.

TODO support labels. Yes without this its a pain.