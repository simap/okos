
resetBufferFsr:
    LFSR 0, buffer
    return
fsr0to1:
    movff FSR0L, FSR1L
    movff FSR0H, FSR1H
    return
    
startEditor:
    bcf editorEditMode
    rcall resetBufferFsr
editorClearMemoryLoop
    movlw '\n'
    movwf POSTINC0
    btfss FSR0H, 3 ; outside of implemented memory range
    bra editorClearMemoryLoop
    rcall resetBufferFsr
    
editorDisplay:
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
    bnz editorDisplayNotSelectedLine

    
    ;TODO if cursorX > oledCol and next char is newline, set cursorX
    ;if cursorX < oledCol go to editorDisplayNotSelectedLine
    ;if next char == newline, setCursorX
    ;if next char == newline or cursorX = oledCol, handleCursor (and set cursorX)
        
    movf cursorX, w
    xorwf oledCol, w ; and the right column
    btfsc STATUS, Z
    
    rcall editorHandleCursor ;handles setting cursor flags, inserting/deleting characters, etc
editorDisplayNotSelectedLine:
    movf POSTINC1, w
    rcall oledDrawChar
    movf oledRow, w
    xorlw 0x7
    bnz editorDisplayLoop
    
    ;read key and check for commands or edits
editorReadKey:
    rcall readKey
    
    ;check for esc
    movlw 0x1b
    xorwf keyboardAscii, w
    bnz editorHandleModes
    bcf editorEditMode
    bra editorDisplay
editorHandleModes:
    btfss editorEditMode
    rcall editorCommands
    bra editorDisplay

editorCommands:
    ;use lower 3 bits of ascii to get 8 different commands spread across keys
    movf keyboardAscii, w
    andlw 0x7
    rlncf WREG
    addwf PCL
    return		    ;space hpx
    bra editorSetEditMode   ;aiqy
    bra moveUp		    ;jbrz
    bra moveDown	    ;kcs
    return		    ;dlt
    return		    ;emu
    return		    ;fnv
    bra saveFile	    ;gow

editorSetEditMode:
    clrf keyboardAscii ; don't try to "type" the key used to enter edit mode
    bsf editorEditMode
    return
    
editorHandleCursor:
    bsf oledDrawCursor
    ;check to see if we're in edit mode
    btfss editorEditMode
    return
    
    movff FSR1L, FSR2L
    movff FSR1H, FSR2H
    
    movf keyboardAscii, w
    bz editorHandleCursorDone ; check for zero (bad char)
    xorlw 0x8 ;check for  backspace
    bz deleteChar ;will return for us
    bra insertChar ; will return for us
deleteChar:
    ;copy all characters left overwriting previous char (copying last char to 2nd to last)
    movf POSTDEC2, w ;copy curent char
    movwf POSTINC2 ; overwrite previous char ; NOTE this may overwrite memory just before buffer starts
    movf POSTINC2, w ; go to next char
    btfss FSR2H, 3 ; outside of implemented memory range
    bra deleteChar
    
    return
insertChar:
    ;set cursor to inserted char
    incf cursorX, f
    bcf oledDrawCursor
insertCharLoop:
    ;copy all characters right (overwriting last char)
    movf POSTINC2, w
    btfsc FSR2H, 3 ; outside of implemented memory range
    return
    movwf INDF2
    bra insertCharLoop
    
editorHandleCursorDone: 
    return

    
moveUp:
;    cursorY--
    decf cursorY, f
    btfss cursorY, 7 ;if negative
    return
    incf cursorY, f
    bra previousLine
    
moveDown:
;    cursorY++
    incf cursorY, f
    btfss cursorY, 3
    return
    decf cursorY, f
    bra nextLine

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
    

