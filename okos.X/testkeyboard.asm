
    clrf oledRow
testKeyboardLoop:
    
    rcall readKey
    
    sublw CHAR_BKSP
    bz testKeyboardLoop
    bnc testKeyboardLoop

    movf keyboardAscii, w
    appendChar

    rcall oledDrawFlushLine

    incf oledRow, f
    bcf oledRow, 3
    
    bra testKeyboardLoop
    