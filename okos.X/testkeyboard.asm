
testKeyboardLoop:
    
    rcall readKey
    xorlw KEY_BAD
    bz testKeyboardLoop
    movf keyboardAscii, w
    rcall oledDrawChar
    
    bra testKeyboardLoop
    