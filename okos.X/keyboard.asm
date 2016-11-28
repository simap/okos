
keyboardInit macro
    ;TODO add pull up resistors so we don't have to use wpu in code
    ; pull clock low
    bcf LATB, 4
    bcf TRISB, 4
    ; set data pin as input
    bsf TRISB, 3    
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
    
    movlw keyCodeTable
    subwf TBLPTRL, w
    movwf keyboardAscii
    
keyParseDone:
    bcf keyboardIgnore
    ;if its anything higher than a0, ignore the sequence
    movlw 0xa0
    subwf keyboardCode, w
    btfsc STATUS, C
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
    rlncf keyboardCode, f
    btfsc PORTB, 3
    bsf keyboardCode, 0
    ;wait for clock to go high
readBitWaitClockH:
    btfss PORTB, 4
    bra readBitWaitClockH
    decfsz WREG, f
    bra readBits
    return
