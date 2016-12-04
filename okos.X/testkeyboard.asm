
testKeyboardLoop:
    
    rcall readKey
    xorlw CHAR_BAD
    bz testKeyboardLoop
    movf keyboardAscii, w
    rcall oledDrawChar
    
    bra testKeyboardLoop
    