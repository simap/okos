;*******************************************************************************
; OKOS Capacitive Touch Keyboard Controller
;
; 60 instructions x 14 bits = 105 bytes of program flash
; and 1 byte of memory
;
; A PS2 keyboard was easier for others to use, but was disqualifying
; for the 1k challege rules.
;
; So here's a keyboard controller that can read 8 capacitive touch keys.
; Since multiple microcontrollers running duplicate code is allowed, a bunch
; are linked together in a daisy chain to form a full keyboard.
; 
; Key press messages (0-7) are sent to the next controller, which is then 
; forwarded after 8 is added to the message. 
;
; In this way controllers don't need a configurable ID, and their address is set
; by their location in the chain. By careful key routing and placement of the 
; controllers in the chain, the desired character set can be achieved without
; any extra translation or lookup code.
;
; This would work with up to to 256 keys using 32 controllers.
;
; NOTE: I switched to absolute linker mode to avoid the .cinit bullshit
;*******************************************************************************
    
    radix dec
#include "p16F1574.inc"
    
#define CALIBRATE_MODE 0

; adjust these to fit the capacitive touch pad
    
;1 key - a9/5a
;space 9a/51
    
#define TOUCH_THRESHOLD_RELEASE 0x87
#define TOUCH_THRESHOLD_PRESS 0x6a
    
; CONFIG1
; __config 0xFF84
 __CONFIG _CONFIG1, _FOSC_INTOSC & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _BOREN_ON & _CLKOUTEN_OFF
; CONFIG2
; __config 0xFFFB
 __CONFIG _CONFIG2, _WRT_OFF & _PPS1WAY_OFF & _PLLEN_ON & _STVREN_ON & _BORV_LO & _LPBOREN_OFF & _LVP_OFF

 
    CBLOCK  0x70 ; common ram
	adconNext
    ENDC
 
;*******************************************************************************
; Reset vector
;*******************************************************************************
    
    ORG     0x0000 ; processor reset vector
reset_init:
    ;bank3 reg setup
    movlb 3
    ;set up uart
    bsf RCSTA, SPEN
    bsf TXSTA, TXEN
    ;right after reset clock is 500khz, BRG16=0, BRGH=0, SPBRGL=0, SPBRGH=0, which is 7812.5 baud
    ;even at the far edge, it should take a character ~8ms to propagate 
    ;setting either BRG16 or BRGH will bring that to 31250 baud. setting both will get 125000 baud.
    goto init

;*******************************************************************************
; Interrupt vector
;*******************************************************************************

    ORG     0x0004 ; interrupt vector location
isr:
    ;the only interrupt is the serial port forward
    movlb 3; uart stuff in bank 3
    ;when we receive a byte, add 8 and pass it along.
    ;this makes each chip in the sequence have a unique id that is sequential on top of the key pressed
    movf RCREG, w
    addlw .8
    
;waits for TRMT flag, sends byte in WREG
sendByte:
    bcf INTCON, GIE ; HACK during ISR this does nothing, as a subroutine this prevents ISR TXREG collision
    ;wait for transmit to finish
waitTrmt:
    btfss TXSTA, TRMT
    goto waitTrmt
    movwf TXREG
    ; HACK during ISR retfie is normal, as a subroutine this returns and re-enables GIE.
    ; as subroutine this also corrupts BSR, WREG, and PCLATH because the 
    ; shadow register may not be initialized
    retfie 
    
;*******************************************************************************
; Main code
;*******************************************************************************

init:
    bsf RCSTA, CREN ; continued from reset vector, already in bank 3

    ;bank2 reg setup
    movlb 2
    ;after reset all analog pins are in analog mode, tris set for input, no need to repeat that
    ;using DAC to charge holding cap
    bsf DACCON0, DACEN
    comf DACCON1, f ; set to all 1s
    clrf LATA
    clrf LATC
    
    ;set uart pins
    ;RC5 defaults to RX, which is nice
    ;Of all the ports, RA5 and RC4 can be an output, and not used for analog
    ;use RA5 for symmetry
    ;RxyPPS = 1001 = TX
    movlb .29
    movlw b'00001001'
    movwf RA5PPS
    
    movlb 1 ; bank 1 has TRISx, PIE1, ADC stuff, the only bank we'll ever need
    ;enable interrupts for serial forwards
    bsf INTCON, PEIE
    bsf INTCON, GIE
    ;enable RX interrupts
    bsf PIE1, RCIE
    
scanInit:    
    ;set up adconNext, with CHS = 00000, GO = 0, ADON = 1, also happens to be 1
    movlw 1
    movwf adconNext
    
scanLoop:
    
#if CALIBRATE_MODE
    ;in calibrate mode, send each key and adc value
    ;send current key to uart
    movlb 3; uart stuff in bank 3
    ;get key from CHS by shifting right twice (gets rid of ADON too)
    lsrf adconNext, w
    lsrf WREG, w
    call sendByte
    clrf PCLATH
    movlb 1 ; back to bank 1
    call sampleButton
    movlb 3; uart stuff in bank 3
    call sendByte
    clrf PCLATH
    movlb 1 ; back to bank 1
    goto keyPressedDone ; skip press detection stuff
#endif
    
    ;regular run mode, check current key and check it against threshold, and
    ;send key if touched, then wait for release
    call sampleButton
    sublw TOUCH_THRESHOLD_PRESS
    btfss STATUS, C ;a value lower than threshold indiates high capacitance, a touch
    goto keyPressedDone
    
    ;send key to uart
    movlb 3; uart stuff in bank 3
    ;get key from CHS by shifting right twice (gets rid of ADON too)
    lsrf adconNext, w
    lsrf WREG, w
    call sendByte
    clrf PCLATH ; fix corrupted PCLATH so call still works
    movlb 1 ; back to bank 1
    
keyPressedLoop:
    ;wait for key up
    ;this was much simpler (less code) than maintaining state and handling multiple
    ;simultaneous keypresses.
    call sampleButton
    sublw TOUCH_THRESHOLD_RELEASE
    btfsc STATUS, C ;a value higher than threshold indiates low capacitance, no touch
    goto keyPressedLoop
    
keyPressedDone:
    ;after each loop increment to next CHS
    ;remember CHS is 2 bits left in ADCON0
    movlw 0x4
    addwf adconNext, f
    ;restart loop when CHS == 8
    btfsc adconNext, 5 
    goto scanInit
    goto scanLoop
    
sampleButton:
    ;set ADC channel to the DAC (set to VDD) to charge the sample and hold cap
    ; x | CHS = 11110 (DAC) | GO = 0 | ADON = 1
    movlw b'01111001'
    movwf ADCON0
    
    
    ;at 500khz, each instruction takes 8us, so we probably don't need extra wait for TACQ
    
    ;set all touch input pins low to ground the touch capacitor
    ;don't mess with ra5/rc5, as those are tx/rx
    movlw b'11100000'
    andwf TRISA, f
    andwf TRISC, f
    
    ;set back to inputs
    movlw b'00011111'
    iorwf TRISA, f
    iorwf TRISC, f
    
    ;set ADCON0 CHS to the pin to check, this connects the charged sample and hold cap
    ;with the discharged touch cap. 
    movf adconNext, w
    movwf ADCON0
    
    ;at 500khz, each instruction takes 8us, so we probably don't need extra wait for TACQ
    
    ;sample the ADC
    bsf ADCON0, GO
    ;wait for done
waitAdcDone:
    btfsc ADCON0, GO
    goto waitAdcDone
    
    movf ADRESH, w ; load result in w for caller
    return
    
endOfProgram:

    END