
    
assemblerStart:
parseAssemblerLine:
;    rcall fsr0to1
    
    ;TODO if first char is [0-9a-z], its a label line
    rcall nextWord
    
    ;see if this is a comment or newline
    movf INDF0, w
    xorlw CHAR_SEMICOLON
    bz parseAssemblerLineDone
    xorlw CHAR_SEMICOLON ^ CHAR_ENTER
    bz parseAssemblerLineDone
    xorlw CHAR_ENTER ^ CHAR_PERIOD ; period is end of file marker
    bz parseAssemblerDone
    
    ;save tblptr so we can use it to look up opcodes
    movff TBLPTRL, tblptr_save
    movff TBLPTRH, tblptr_save+1
    
    movlw opcodeTable
    movwf TBLPTRL
    clrf TBLPTRH
    setf opcodeIndex ; on firt pass, will become zero
parseMnemonicTableLoop:
    incf opcodeIndex, f
    clrf mismatches
    movlw 3
    movwf assemblerTemp
    rcall fsr0to1
parseMnemonicCharLoop:
    tblrd*+
    movf TABLAT, w
    xorwf POSTINC1, w
    addwf mismatches, f ; if they didn't match, will start to accumulate nonzero junk
    decfsz assemblerTemp, f
    bra parseMnemonicCharLoop
    
    ;load opcode
    tblrd*+
    movf TABLAT, w
    movwf opcode
    xorlw 0xEC ; check for the last opcode in table
    bz parseMnemonicDone
    
    ; loop until we find a match
    tstfsz mismatches
    bra parseMnemonicTableLoop
parseMnemonicDone:
    
    ;TODO if mismatches is nonzero, we have a parse error
    
    ;restore tblptr so file operations work again
    movff tblptr_save, TBLPTRL
    movff tblptr_save+1, TBLPTRH
    
    ;move fsr0 past mnemonic
    movf POSTINC0, w
    movf POSTINC0, w
    movf POSTINC0, w
    
    rcall parseArg
    rcall fputc
    
    movff assemblerArg+1, assemblerArg+2 ; save this in case of GOTO/CALL
    
    rcall parseArg
    ;skip the access flag for 2nd arg (low bit of high nibble)
    rlncf assemblerArg, w
    iorwf opcode, w
    rcall fputc
    
    ;if index > 12, write 2nd part of arg
    movlw .13
    subwf opcodeIndex, w
    bnc parseAssemblerLineDone
    movf assemblerArg+2, w
    rcall fputc
    movlw 0xf0
    rcall fputc
parseAssemblerLineDone:  ; go here if newline or comment char
    
    rcall nextLine
    bra parseAssemblerLine
    
parseAssemblerDone:    
    ;flush out any dirty pages not already written still in holding area
    closeFlush
    
    bra START

parseArg:
    rcall nextWord
    clrf assemblerArg
    clrf assemblerArg+1
parseArgChar:
    movf INDF0, w
    andlw 0xf0
    bnz parseDone
    movlw .4
shiftLoop:
    bcf STATUS, C
    rlcf assemblerArg, f
    rlcf assemblerArg+1, f
    decfsz WREG, f
    bra shiftLoop
    movf POSTINC0, w
    iorwf assemblerArg, f
    bra parseArgChar
parseDone:
    movf assemblerArg, w
    return
    
    
;copies a hex arg [0-f]{2}
writeArg:

;scan fsr0 past spaces
nextWord:
    movlw CHAR_SPACE
    xorwf POSTINC0, w
    bz nextWord
    movf POSTDEC0, w ; go back to non-space char
    return

