;TODO test to see if turnaround time is low enough we can avoid holding clock low
    
keyboardInit macro
    ; pull clock latch low
    bcf LATB, 4
    ;HACK after first time keyboard is read this will fix itself
    ; worse case is a key is comming in while PIC is starting up and misses first bytes
    ; since there is no timeout waiting for bits
;    bcf TRISB, 4
    endm

;reads 1 key worth of codes from the keyboard (ps2 keyboards have 16 byte buffer)
;blocks until data arrives
readKey:
    ; release ps2 clock line and wait for a code
    bsf TRISB, 4
    
    ;HACK: start bit should be zero, so it won't mess up the 8 data bits
    clrf keyboardCode
    movlw .9
    rcall readBits

    btfsc keyboardIgnore
    bra keyParseDone
    
    ;look up keycode in table to find charset value
    clrf TBLPTRH
    movlw low(keyCodeTable)
    movwf TBLPTRL
    
keyScanLoop:
    tblrd*+
    movf TABLAT, w
    xorwf keyboardCode, w
    tstfsz TABLAT
    bnz keyScanLoop
    
    movlw keyCodeTable+1
    subwf TBLPTRL, w
    movwf keyboardAscii
    
keyParseDone:
    bcf keyboardIgnore
    ;if its anything higher than a0, ignore the sequence
    movlw 0xa0
    cpfslt keyboardCode
    bsf keyboardIgnore
    
    ; wait for parity and stop bits 
    movlw 2
    rcall readBits
    
    ; if this was a leading code, wait for the next key
    btfsc keyboardIgnore
    rcall readKey ;this can recurse twice for extended break codes
    
    ; hold ps2 clock line until we are ready to read more codes
    bsf TRISB, 4
    movf keyboardAscii, w
    return
    
readBits:
    ;wait for clock to go low
    btfsc PORTB, 4
    bra readBits
    ;read data bit
    rrncf keyboardCode, f
    btfsc PORTB, 3
    bsf keyboardCode, 7
    ;wait for clock to go high
readBitWaitClockH:
    btfss PORTB, 4
    bra readBitWaitClockH
    decfsz WREG, f
    bra readBits
    return
