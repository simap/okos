resetBufferFsr:
    LFSR 0, buffer
    return
fsr0to1:
    movff FSR0L, FSR1L
    movff FSR0H, FSR1H
    return
    
checkFsr0:
    bcf editorAtStartOfFile
    movf FSR0H, f
    bnz checkFsr0Done ;nonzero high byte means there's plenty to go
    movlw low(buffer+1)
    cpfslt FSR0L ; make sure low byte >= start address
    bra checkFsr0Done ;reset it back to the start, and this will return for us
    bsf editorAtStartOfFile
    rcall resetBufferFsr
checkFsr0Done:
    return
    
;scan fsr0 to previous newline, up until buffer address starts
previousLine:
    movf POSTDEC0, w ;jump past the first newline
previousLineLoop:
    rcall checkFsr0
    btfsc editorAtStartOfFile
    return
    movf POSTDEC0, w ;no pre-dec, still faster
    movlw CHAR_ENTER
    xorwf INDF0, w
    bnz previousLineLoop
    movf POSTINC0, w ; adjust to just after the previous newline
    return

nextLine:
    bsf editorSkipDraw
    rcall drawLine
    bcf editorSkipDraw
    return

drawLine:
    ;draw the gutter, an arror for the cursor line
    movf cursorY, w
    xorwf oledRow, w
    movlw CHAR_RIGHT_ARROW
    btfss STATUS, Z
    movlw CHAR_SPACE
    btfss editorSkipDraw
    movwf POSTINC2

drawLineLoop:
    movf INDF0, w
    xorlw CHAR_ENTER
    bz drawLineDone ; return if char is newline
    movf INDF0, w ; reload
    btfss editorSkipDraw
    movwf POSTINC2
    movf POSTINC0, w ; next char
    bra drawLineLoop
drawLineDone:
    ;skip draw also indicates pending edit/insert
    btfsc editorSkipDraw
    rcall checkInsertOrDelete
    ;skip over newline
    movf POSTINC0, w
    btfss editorSkipDraw
    rcall oledDrawFlushLine
checkInsertOrDeleteDone: ; borrowing this return instruction
    return
    
checkInsertOrDelete:
    ;only do this at the tail end of the cursor line
    movf cursorY, w
    xorwf oledRow, w
    bnz checkInsertOrDeleteDone
    
    ;check and handle a pending insert/delete
    rcall fsr0to1 ; fsr1 used for modifications calls
    ;see if its an insertable char
    movf keyboardAscii, w
    sublw CHAR_BKSP
    bz deleteChar
    bnc checkInsertOrDeleteDone
    bra insertChar
    
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

;assumes fsr1 points the location to delete (shift left) a character
deleteChar:
    ;copy all characters left overwriting previous char (copying last char to 2nd to last)
    movf POSTDEC1, w ;copy curent char
    movwf POSTINC1 ; overwrite previous char ; NOTE this may overwrite memory just before buffer starts
    movf POSTINC1, w ; go to next char
    btfss FSR1H, 3 ; outside of implemented memory range
    bra deleteChar
    return

;assumes fsr0 and fsr1 point to same location, the place to insert the character in keyboardAscii
    
insertChar:
    ;load the first char, point to next
    movf POSTINC1, w    
insertCharLoop:
    btfsc FSR1H, 3 ; outside of implemented memory range
    bra insertCharDone
    ;swap w with INDF1, and point to next
    xorwf INDF1, w ; W := A^B; X = B
    xorwf INDF1, f ; W = A^B, X := B^(A^B) = A
    xorwf POSTINC1, w ; W := (A^B)^A = B; X = A
    bra insertCharLoop
insertCharDone:
    movff keyboardAscii, INDF0
    return

startEditor:    
editorMainLoop:
    rcall setFsr2ToLine ; fsr2 could be dirty from file operations (load/save)
    ; dry run display to handle inserts
    bsf editorSkipDraw
    rcall editoDrawAllLines
    ; then actually display
    bcf editorSkipDraw
    rcall editoDrawAllLines
    
    ;check keys and loop to draw
    rcall editorDoKeyboard
    bra editorMainLoop
    
editoDrawAllLines:
    clrf oledRow
    movff FSR0L, fsr0_save
    movff FSR0H, fsr0_save+1
editoDrawAllLinesLoop:
    rcall drawLine
    incf oledRow, f
    btfss oledRow, 3
    bra editoDrawAllLinesLoop
;    bcf oledRow, 3
    ;reset fsr0 back to where we started (undo the 8 lines worth of fsr0 incrementing)
    movff fsr0_save, FSR0L
    movff fsr0_save+1, FSR0H
    return
    
editorDoKeyboard:
    rcall readKey
    
    xorlw CHAR_UP
    bz moveUp
    xorlw CHAR_DOWN ^ CHAR_UP
    bz moveDown
    xorlw CHAR_F1 ^ CHAR_DOWN
    bz saveFile
    ;otherwise, assume it is an insert/delete at cursor location (end of cursor line) 
    return
