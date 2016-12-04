
    ;cli starts executing here
cliReset:
    rcall resetBufferFsr
    movlw CHAR_ENTER
    movwf INDF0 ; start with empty line
    setf keyboardAscii ; set to garbage so we don't try to handle leftover keystrokes
    clrf oledRow
    clrf cursorY
cliLoop:
    
    rcall nextLine
    rcall resetBufferFsr
    rcall drawLine
    rcall resetBufferFsr
    
    rcall readKey
    
    ;if enter key, parse line
    xorlw CHAR_ENTER
    bz cliExecLine
    ;otherwise loop and try to insert/delete
    bra cliLoop
    
cliExecLine:
    rcall parseArg
    movff assemblerArg, assemblerArg+2 ; save first char as command
    
    rcall parseArg
    ;2nd param is always the file to open
    movwf currentFile
    rcall loadFile ; probably not super helpful if this is going to be a run command
    
    ;parse first param as command
    movf assemblerArg+2, w
    xorlw CHAR_A
    bz cliAssembler
    xorlw CHAR_E ^ CHAR_A
    bz cliEditor
    xorlw CHAR_R ^ CHAR_E
    bz cliRun
    
    ; not a recognized command
    bra cliReset
    
cliAssembler:
    rcall parseArg
    ;protect file 0
;    bz cliReset
    rcall openFile
    bra assemblerStart
    
cliEditor:
    bra startEditor
cliRun:
    movff TBLPTRH, PCLATH
    clrf PCL
    
    