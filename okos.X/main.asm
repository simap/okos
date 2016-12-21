;*******************************************************************************
; OKOS - One Kilobyte Operating System
;
; A user operating system in 1kB.
; OKOS us just OK because OKOS is just OK.
; 
; Hacked together using the Hackaday Superconference Badge
;*******************************************************************************
#include p18f25k50.inc

#define INCLUDE_EXAMPLE_FILES 0
#define PS2_KEYBOARD 0

#include <charset.h>
    
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
; config DEBUG = ON         ; Bkgnd debugger disabled, RB6 and RB7 configured as gp I/O pins
 config ICPRT = OFF
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

;*******************************************************************************
; Memory allocations
;*******************************************************************************

#include <memory.asm>

;*******************************************************************************
; Reset Vector
;*******************************************************************************

RES_VECT  CODE    0x0000            ; processor reset vector
resetvector:
    clrf flags
    clrf cursorY
    bsf OSCCON, IRCF2 ; set for 16Mhz x3 = 48mhz
    bra    START                   ; go to beginning of program

;*******************************************************************************
; Interrupt Vector
; OKOS doesn't use ISRs, but supports user ISRS offset by 4.
; The code to support that is hidden in the area usually occupied by the high
; priority interrupt vector.
;*******************************************************************************

HIGHISR       CODE    0x0008
       ; don't suport high priority interrupts, instead, hide some code here that calls the user's ISR
userIsr:
    movf currentFile, w ;load current file and multiple by 8 to get it's 2k offset
    rlncf WREG, f
    rlncf WREG, f
    rlncf WREG, f
    movwf PCLATH
    movlw .4 ; user ISR vector. TODO offset by 1 page (64 bytes) to reserve some room for file metadata.
    movwf PCL
return_bra: ; HACK: user can jump to this location in order to effect a return from subroutine (instead of supporting a 'return' mnemonic)
    return

LOWISR       CODE    0x0018
isr:
    ;TODO check for running program, call its ISR offset
    ;interrupts won't be enabled unless a user program is run and enables them
    ;user's ISR is responsible for saving and restoring registers used beyond WREG, STATUS, and BSR (done automatically)
    ;user's ISR must then return (retfie is not supported by the assembler)
    
    rcall userIsr
    RETFIE FAST ; restores STATUS, WREG, BSR. only usable if high priority interrupts are not enabled

;*******************************************************************************
; Table Data
; tables are put in the first page of flash to make access easier
; this is placed just after the ISR code
;*******************************************************************************

TABLE_DATA CODE 0x1c
     #include <font.asm>
#if PS2_KEYBOARD
     #include <keycodesPs2.asm>
#endif
     #include <opcodes.asm>

;*******************************************************************************
; MAIN PROGRAM
;*******************************************************************************    
    
MAIN_PROG CODE 
    #include <oled.asm>
#if PS2_KEYBOARD
    #include <keyboardPs2.asm>
#else
    #include <keyboardTouch.asm>
#endif
    #include <strings.asm>
    #include <editor.asm>
    #include <files.asm>
    #include <assembler.asm>

START
    
    
;    #include <testassembler.asm>

    keyboardInit
    oledInit

;    #include <testkeyboard.asm>
    
    #include <cli.asm>
    
#if INCLUDE_EXAMPLE_FILES
    #include <examplefiles.asm>
#endif
    
endofmain
    end
    
