
parseMnemonic

    return
    
parseAssemblerLine
    ;read words until end of line or ';'
    ;first word is mnemonic, others are hex up to 4 hex chars
    call parseMnemonic
    

    return
