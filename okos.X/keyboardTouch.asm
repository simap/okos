    
keyboardInit macro
    ;enable serial port UART RX to read keyboard
    ;TRIS should already be input
    ;set for 7812.5 baud (match keyboard, which is 96x slower clock)
    movlw .95
    movwf BAUDCON1
    ;enable serial port and rx
    bsf RCSTA1, CREN
    bsf RCSTA1, SPEN
    
    endm

;reads 1 key worth of codes from the keyboard
;blocks until data arrives
;unlike the PS2 keyboard version, we don't have a way to tell the keyboard to 
;hold off, though we do get a 2 byte FIFO in RCREG1
;that could fill up in 5.1ms
readKey:
   ;wait for a key in to appear in the buffer
   btfss PIR1, RCIF
   bra readKey
   movf RCREG1, w
   movwf keyboardAscii
   return
