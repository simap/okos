
;    LIST	 P=18LF25K50

#include p18f25k50.inc

    
 config PLLSEL = PLL3X      ; 3x clock multiplier
 config CFGPLLEN = ON       ; PLL Enabled
 config CPUDIV = NOCLKDIV   ; 1:1 mode
 config LS48MHZ = SYS48X8   ; System clock at 48 MHz, USB clock divider is set to 8
 config FOSC = INTOSCIO     ; Internal oscillator
 config PCLKEN = OFF        ; Primary oscillator disabled
 config FCMEN = OFF         ; Fail-Safe Clock Monitor disabled
 config IESO = OFF          ; Oscillator Switchover mode disabled
 config nPWRTEN = ON        ; Power up timer enabled
 config BOREN = OFF         ; BOR disabled
 config nLPBOR = OFF        ; Low-Power Brown-out Reset disabled
 config WDTEN = OFF         ; WDT disabled in hardware (SWDTEN ignored)
 config CCP2MX = RC1        ; CCP2 input/output is multiplexed with RC1
 config PBADEN = OFF        ; PORTB<5:0> pins are configured as digital I/O on Reset
 config MCLRE = ON          ; MCLR pin enabled; RE3 input disabled
 config STVREN = OFF        ; Stack full/underflow will not cause Reset
 config LVP = OFF           ; Single-Supply ICSP disabled
 config XINST = OFF         ; Instruction set extension and Indexed Addressing mode disabled
 config DEBUG = OFF         ; Bkgnd debugger disabled, RB6 and RB7 configured as gp I/O pins
 config CP0 = OFF           ; Block 0 is not code-protected
 config CP1 = OFF           ; Block 1 is not code-protected
 config CPB = OFF           ; Boot block is not code-protected
 config CPD = OFF           ; Data EEPROM is not code-protected
 config WRT0 = OFF          ; Block 0 (0800-1FFFh) is not write-protected
 config WRT1 = OFF          ; Block 1 (2000-3FFFh) is not write-protected
 config WRTC = OFF          ; Configuration registers (300000-3000FFh) are not write-protected
 config WRTB = OFF          ; Boot block (0000-7FFh) is not write-protected
 config WRTD = OFF          ; Data EEPROM is not write-protected
 config EBTR0 = OFF         ; Block 0 is not protected from table reads executed in other blocks
 config EBTRB = OFF         ; Boot block is not protected from table reads executed in other blocks

access	equ	0
banked	equ	1
	
; TODO PLACE VARIABLE DEFINITIONS GO HERE

#include <memory.asm>

#include <bensmacros.asm>



;*******************************************************************************
; Reset Vector
;*******************************************************************************

RES_VECT  CODE    0x0000            ; processor reset vector
resetvector:
    ;set up tmr0 as 16 bit w/ 256 prescaler. overflows every 1.4s. tmr0H can be used for 1/183rds
    ; TMR0ON = 1 | T08BIT = 0 | T0CS = 0 | T0SE = x | PSA = 0 (enabled) | T0PS = 111 (1:256)
    movlw b'10000111'
    movwf T0CON
    bsf OSCCON, IRCF2, access ; set for 16Mhz x3 = 48mhz
    bra    START                   ; go to beginning of program
    
HIGHISR       CODE    0x0008
highisr:
    ;TODO maybe hide some data here, perhaps the 16 opcodes
    db 0x11, 0x11
    db 0x11, 0x11
    db 0x11, 0x11
    db 0x11, 0x11
    db 0x11, 0x11
    db 0x11, 0x11
    db 0x11, 0x11
    db 0x11, 0x11

LOWISR       CODE    0x0018
isr:
    ;TODO check for running program, call its ISR offset

    
    ;TODO handle timers?
    ; TODO use 8 byte keyboard buffer, and single byte for head,tail so that it can be updated atomically. (increment nibble, clear bits 7 and 3)
    
    ; handle keyboard clock IOC
;keyboardIsr:
;    btfss INTCON, IOCIF
;    bra notKeyboard
;    btfsc PORTB, 4
;    bra endKeyboardIsr
;    
;    ;check for timeout
;    ;load tmr0h by reading tmr0l
;    movf TMR0L, w
;    movf keyboardBitTimer, w
;    subwf TMR0H, w
;    ;sublw 2 ???
;endKeyboardIsr:
;    bcf INTCON, IOCIF
;notKeyboard:
;    movff FSR0L, fsr0_temp
;    movff FSR0H, fsr0_temp+1
;    movff TBLPTRL, TBLPTR_TEMP+0
;    movff TBLPTRH, TBLPTR_TEMP+1
;    
;    movff TBLPTR_TEMP+0, TBLPTRL
;    movff TBLPTR_TEMP+1, TBLPTRH
    
;    movff fsr0_temp, FSR0L
;    movff fsr0_temp+1, FSR0H
    RETFIE FAST ; restores STATUS, WREG, BSR. only usable if high priority interrupts are not enabled

;----------------------------------PIC18's--------------------------------------
;
; ISRHV     CODE    0x0008
;     GOTO    HIGH_ISR
; ISRLV     CODE    0x0018
;     GOTO    LOW_ISR
;
; ISRH      CODE                     ; let linker place high ISR routine
; HIGH_ISR
;     <Insert High Priority ISR Here - no SW context saving>
;     RETFIE  FAST
;
; ISRL      CODE                     ; let linker place low ISR routine
; LOW_ISR
;       <Search the device datasheet for 'context' and copy interrupt
;       context saving code here>
;     RETFIE
;
;*******************************************************************************

; TODO INSERT ISR HERE

;*******************************************************************************
; MAIN PROGRAM
;*******************************************************************************    
    

FONT_TABLE CODE 0x1a
;FONT_TABLE CODE
     #include <font.asm>

;TABLE_INDEX CODE
;table_index:
;    db 0,0
 
MAIN_PROG CODE                      ; let linker place main program
;    #include <tables.asm>
    #include <oled.asm>
    #include <keyboard.asm>
    #include <strings.asm>
    #include <editor.asm>

START    
    
    keyboardInit
    oledInit
        
    goto $

endofmain
    end
    
