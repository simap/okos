One Kilobyte Operating System (OKOS)
================

Tiny OS for 1kB challenge

MVP
---

* filesystem (8.3, even numbered/named file slots is ok, anything really), extent/linkedlist based
* keyboard driver (ps2?) and api
	* isr for keyboard clock pin
	* scan code map/table
	* handle keyup or keydown at minimum, fifo buffer
* display driver and api
	* probably need a minimal font - remember Apple ][ uppercase only font (but perhaps lowercase)
	* Use 3x5 tiny font
	* text drawing api
* cli with some built-ins
	* minimal assembler
	* editor
	* run
	* ls

Notes
----

### keyboard

ps2 

* simple protocol, keyboard will spam
* can ignore keydown, listen for keyup events. ignore most special keys

### filesystem

* pic18f25k50 has 32k flash. flash is written in 64B blocks. 64B = 512 bits. 512 * 64 = 32k. A single 64B block can be used to map a file to any number of non contiguous 64B blocks in available memory. It won't order them, but could provide a non-contigous sequential mapping.


### display

* The 2 decent res color LCDs I have both require almost 100 bytes of commands and init code
* the 128x64 oled needs about 35 bytes of setup. give 32x10 display, plus 4 pixels
* Font can be 128 or 192 bytes. Each face is 15 bits, can use the 16th bit to shift down for subscript
* Would need to render characters on the fly


### MCU

pic18f25k50

* uses 16-bit instruction words, and can store 2-8bit bytes per word easily.
* has 32k of flash, leaving 31k for filesystem
* has 1k eeprom, could be used for fs metadata given better write durability

### Assembler

movf
movwf

addwf

andwf
iorwf
xorwf

rlcf
rrcf

movlw

bcf
bsf
btfsc
btfss

goto
call
return

