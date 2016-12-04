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
    
skipNLines:
    movwf editorTemp
    bsf editorSkipDraw
skipNLinesLoop:
    rcall drawLine
    decfsz editorTemp, f
    bra skipNLinesLoop
    bcf editorSkipDraw
    return
    
previousNLines:
    movwf editorTemp
previousNLinesLoop:
    rcall previousLine
    decfsz editorTemp, f
    bra previousNLinesLoop
    return
    
drawLine:
    ;draw a space for cursor (a gutter)
    movlw CHAR_SPACE
    rcall oledDrawChar
    movf POSTINC0, w
    xorlw CHAR_ENTER
    bz drawLineDone ; return if char is newline
    xorlw CHAR_ENTER ;repair bits
    btfss editorSkipDraw
    rcall oledDrawChar
    bra drawLine
drawLineDone:
    return


;drawGutter:
;    clrf editorTemp
;    bsf oledDontSetStart
;drawGutterLoop:
;    incf oledRow, f
;    bcf oledRow, 3
;    rcall oledSetRow
;    
;    movf cursorY
;    xorwf editorTemp, w
;    
;    movlw CHAR_SPACE
;    btfsc STATUS, Z
;    movlw CHAR_RIGHT_ARROW
;    rcall oledDrawChar
;    
;    incf editorTemp, f
;    btfss editorTemp, 3
;    bra drawGutterLoop
;    return
    
moveUp:
;    cursorY--
    decf cursorY, f
    btfss cursorY, 7 ;if negative
    return
    incf cursorY, f
    bra scrollUp
    
moveDown:
;    cursorY++
    incf cursorY, f
    btfss cursorY, 3
    return
    decf cursorY, f
    bra scrollDown

    
scrollDown:
    movlw .8
    rcall skipNLines
    rcall oledNewLine
    rcall drawLine
    movlw .8
    rcall previousNLines
    return
    
scrollUp:
    rcall checkFsr0
    btfsc editorAtStartOfFile
    return

    rcall previousLine
    
    bsf oledStartTop
    rcall oledLineNoInc
    rcall drawLine
    rcall previousLine
    
    ;subtract one from oledRow
    movlw .7
    addwf oledRow, f
    bcf oledRow, 3

    bcf oledStartTop
    
    return
    
    
startEditor:
    clrf cursorY
    clrf oledRow ; also contains row setting flags
    rcall resetBufferFsr
    ;draw all lines initially
    ;if we use newLine + draw for scroll down, same code can be reused for initial draw
    
editoDrawAllLines:
    movlw .8
    movwf editorTemp
editoDrawAllLinesLoop:
    rcall oledNewLine
    rcall drawLine
;    rcall nextLine
    decfsz editorTemp, f
    bra editoDrawAllLinesLoop
    ;go back to where we started (undo the 8 next lines
    movlw .8
    rcall previousNLines
    
    
    
editorMainLoop:
    
    rcall editorDoKeyboard
;    rcall drawGutter
    
    bra editorMainLoop
    
editorDoKeyboard:
    rcall readKey
    
    ;if char <= space, then insert char
    ;else
    
    xorlw CHAR_UP
    bz scrollUp
    xorlw CHAR_DOWN ^ CHAR_UP
    bz scrollDown
    xorlw CHAR_F1 ^ CHAR_DOWN
    bz saveFile
    
    return
    ;after initial redraw, row=cursor row, setRow oledDontSetStart=1, and redraw line before newline    
    ;scroll down: row = lastRow setRow oledStartTop=0, draw line, fill remaining with blanks
    ;scroll up: row = firstRow, setRow oledStartTop=1, draw line, fill remaining with blanks
    ;when inserting, just draw the char
    ;when backspace, redraw the cursor line
    ;when typing enter, insert a newline and increment cursor (scrolling down if needed), then back to redraw cursor line
    
    
    
 
    
;startEditor:
;    rcall loadFile
;    rcall resetBufferFsr
;    
;;    /*
;;    display lines:
;;	draw until eol
;;	place cursor at eol
;;	handle pending insert/delete
;;    
;;    */
;    
;    
;    
;    
;    
;    
;    
;    
;    
;editorDisplay:
;    ;redraw display
;;    clrf oledRow
;    rcall oledNewLine
;    rcall fsr0to1
;    ;display characters and newlines until oledRow is 7
;editorDisplayLoop:
;    ;draw line cursor
;    bcf oledDrawCursor
;    movf cursorY, w
;    xorwf oledRow, w ; only on the right row
;    bnz editorDisplayContinue
;    
;;    if (row == cursorY)
;;	
;;	if (curChar == enter_key)
;;	    cursorX = col
;;	    set cursor bit
;;	    
;;	if (editormode)
;;	    if (key==bs)
;;		deleteChar
;;	    else
;;		insertChar
;	    
;    
;    btfsc editorEditMode
;    bra editorCheckCursor
;    
;    movlw CHAR_ENTER
;    xorwf INDF0, w
;    bnz editorDisplayContinue
;    movff oledCol, cursorX
;    
;editorCheckCursor:
;    movf cursorX, w
;    xorwf oledCol, w ; and the right column
;    btfsc STATUS, Z
;    
;    rcall editorHandleCursor ;handles setting cursor flags, inserting/deleting characters, etc
;editorDisplayContinue:
;    movf POSTINC1, w
;    rcall oledDrawChar
;    movf oledRow, w
;    xorlw 0x7
;    bnz editorDisplayLoop
;    
;    ;read key and check for commands or edits
;editorReadKey:
;    rcall readKey
;    
;    ;check for esc
;    xorlw 0x1b
;    btfss STATUS, Z
;    bcf editorEditMode
;    btfss editorEditMode
;    rcall editorCommands
;    bra editorDisplay
;
;editorCommands:
;    ;bail out if not 0-3
;    movlw 4
;    cpfslt keyboardAscii
;    return
;    ;read PCL to prime PCLAT
;    movf PCL, w
;    movf keyboardAscii, w
;    rlncf WREG
;    addwf PCL, f
;    bra saveFile	    ;gow
;    bra moveUp		    ;jbrz
;    bra moveDown	    ;kcs
;    bra editorSetEditMode   ;aiqy
;    
;
;editorSetEditMode:
;    clrf keyboardAscii ; don't try to "type" the key used to enter edit mode
;    bsf editorEditMode
;    return
;    
;editorHandleCursor:
;    bsf oledDrawCursor
;    ;check to see if we're in edit mode
;    btfss editorEditMode
;    return
;    
;    movff FSR1L, FSR2L
;    movff FSR1H, FSR2H
;    
;    movf keyboardAscii, w
;    xorlw CHAR_BAD ; check for bad char
;    bz editorHandleCursorDone
;    ;NEAT HACK: xor the last test with a new test
;    xorlw CHAR_BAD ^ CHAR_BKSP ;check for backspace
;    bz deleteChar ;will return for us
;    bra insertChar ; will return for us
;deleteChar:
;    ;copy all characters left overwriting previous char (copying last char to 2nd to last)
;    movf POSTDEC2, w ;copy curent char
;    movwf POSTINC2 ; overwrite previous char ; NOTE this may overwrite memory just before buffer starts
;    movf POSTINC2, w ; go to next char
;    btfss FSR2H, 3 ; outside of implemented memory range
;    bra deleteChar
;    
;    return
;insertChar:
;    ;set cursor to inserted char
;    incf cursorX, f
;    bcf oledDrawCursor
;insertCharLoop:
;    ;copy all characters right (overwriting last char)
;    movf POSTINC2, w
;    btfsc FSR2H, 3 ; outside of implemented memory range
;    return
;    movwf INDF2
;    bra insertCharLoop
;    
;editorHandleCursorDone: 
;    return
;
;moveUp:
;;    cursorY--
;    decf cursorY, f
;    btfss cursorY, 7 ;if negative
;    return
;    incf cursorY, f
;    bra previousLine
;    
;moveDown:
;;    cursorY++
;    incf cursorY, f
;    btfss cursorY, 3
;    return
;    decf cursorY, f
;    bra nextLine
;
