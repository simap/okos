
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
    clrf keyboardCode
    movlw .9
    rcall readBit
    decfsz WREG, f
    bra readBit

    ;TODO check start bit (in carry)
    ;TODO parse code, set flags, etc
    
    ;if its anything higher than a0, ignore the sequence
    movlw 0xa0
    subwf keyboardCode, w
    btfsc STATUS, C
    bsf keyboardIgnore
    
;    btfsc keyboardIgnore
;    bra keyParseDone
    
    ;look up keycode in table to find charset value
    movlw high(keyCodeTable)
    movwf TBLPTRH
    movlw low(keyCodeTable)
    movwf TBLPTRL

keyScanLoop:
    tblrd*+
    movff TABLAT, keyboardAscii
    tblrd*+
    movf TABLAT, w
    xorwf keyboardCode, w
    tstfsz keyboardAscii
    bnz keyScanLoop
    
    
keyParseDone:
    ; wait for parity and stop bits 
    rcall readBit
    rcall readBit
    
    ; if this was a leading code, wait for the next key
    btfsc keyboardIgnore
    rcall readKey ;this can recurse twice for extended break codes
    bcf keyboardIgnore  
    return
    
readBit:
    ;wait for clock to go low
    btfsc PORTB, 4
    bra readBit
    ;read data bit
    rlncf keyboardCode, f
    btfsc PORTB, 3
    bsf keyboardCode, 0
    ;wait for clock to go high
readBitWaitClockH:
    btfss PORTB, 4
    bra readBitWaitClockH
    return
    
keyCodeTable:
    db	61,1C	;a
    db	62,32	;b
    db	63,21	;c
    db	64,23	;d
    db	65,24	;e
    db	66,2B	;f
    db	67,34	;g
    db	68,33	;h
    db	69,43	;i
    db	6A,3B	;j
    db	6B,42	;k
    db	6C,4B	;l
    db	6D,3A	;m
    db	6E,31	;n
    db	6F,44	;o
    db	70,4D	;p
    db	71,15	;q
    db	72,2D	;r
    db	73,1B	;s
    db	74,2C	;t
    db	75,3C	;u
    db	76,2A	;v
    db	77,1D	;w
    db	78,22	;x
    db	79,35	;y
    db	7A,1A	;z
    db	30,45	;0
    db	31,16	;1
    db	32,1E	;2
    db	33,26	;3
    db	34,25	;4
    db	35,2E	;5
    db	36,36	;6
    db	37,3D	;7
    db	38,3E	;8
    db	39,46	;9
    db	3B,4C	;;
    db	2E,49	;.
    db	A,5A	;ENTER
    db	8,66	;BKSP
    db	20,29	;SPACE
    db	1b,76	;ESC
    db	9,0D	;TAB
    db	00,00	;not found, end of table