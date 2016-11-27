
parseMnemonic

    return
    
parseAssemblerLine
    ;read words until end of line or ';'
    ;first word is mnemonic, others are hex up to 4 hex chars
    call parseMnemonic
    
    call parseHexNib
    movwf parsedWord2
    swapf parsedWord2, f
    call parseHexNib
    andwf parsedWord2, f
    
    
    
    return