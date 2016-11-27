
resetBufferFsr:
    LFSR 0, buffer
    return
fsr0to1:
    movff FSR0L, FSR1L
    movff FSR0H, FSR1H
    return
    
startEditor:
    rcall resetBufferFsr
editorClearMemoryLoop
    movlw '\n'
    movwf POSTINC0
    btfss FSR0H, 3 ; outside of implemented memory range
    bra editorClearMemoryLoop
    rcall resetBufferFsr
    
editorCommandMode:
    ;redraw display
    clrf oledRow
    rcall oledNewLine
    rcall fsr0to1
    ;display characters and newlines until oledRow is 7
editorDisplayLoop:
    ;draw line cursor
    bcf oledDrawCursor
    movf cursorY, w
    xorwf oledRow, w ; only on the right row
    addwf oledCol, w ; and the 0th column
    btfsc STATUS, Z
    bsf oledDrawCursor
    
    
    movf POSTINC1, w
    rcall oledDrawChar
    movf oledRow, w
    xorlw 0x7
    bnz editorDisplayLoop
    
    ;read key and check for commands
    rcall readKey    
    rcall editorCommands
    bra editorCommandMode
    
editorCommands:
    movf keyboardAscii, w
    andlw 0x7
    rlncf WREG
    addwf PCL
    return
    bra editorEditMode	;happens to occur on 'a' and 'i' qy
    bra moveUp		;happens to occur on 'j' brz
    bra moveDown	;happens to occur on 'k' cs
    return ;dlt
    return ;emu
    return ;fnv
    return ;gow
    
moveUp:
;    cursorY--
    
moveDown:
;    cursorY++

;scan fsr0 to previous newline, up until buffer address starts
previousLine:
    movf POSTDEC0, w ;jump past the first newline
previousLineLoop:
    ;check for at beginning address
    movf FSR0H, f
    bnz previousLineDec ;nonzero high byte means there's plenty to go
    movlw low(buffer -1)
    cpfsgt FSR0L ; make sure low byte >= start address
    bra resetBufferFsr ;reset it back to the start, and this will return for us
previousLineDec:
    movf POSTDEC0, w ;no pre-dec, still faster
    movlw '\n'
    xorwf INDF0, w
    bnz previousLineLoop
    movf POSTINC0, w ; adjust to just after the previous newline
    return
    
;scan fsr0 past next newline, up until BUFFER_MAX_ADDR
nextLine:
    movlw '\n'
    xorwf PREINC0, w
    btfsc FSR0H, 3 ; outside of implemented memory range
    bra previousLine
    bnz nextLine
    return
    
editorEditMode:
    rcall fsr0to1
    
    
    
    
    
insertChar:
    rcall fsr0to1