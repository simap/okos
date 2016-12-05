
    ;cli starts executing here
cliReset:
    rcall setFsr2ToLine
    rcall resetBufferFsr
    movlw CHAR_ENTER
    movwf INDF0 ; start with empty line
    setf keyboardAscii ; set to garbage so we don't try to handle leftover keystrokes
    clrf oledRow
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
    setf keyboardAscii
    movff POSTINC0, assemblerArg+2 ; save first char as command
    
    rcall parseArg
    movwf currentFile ; save 2nd arg as file number

    ;if there is a 3rd arg (e.g. assembler) parse it now
    rcall parseArg
    
    ;open the file now (will nuke buffer, which had our cli text)
    movf currentFile, w
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
    movf assemblerArg, w
    rcall openFile
    ;buffer has text to parse, tblptr has location to write assembled binary
    bra assemblerStart
    
cliEditor:
    bra startEditor
cliRun:
    movf currentFile, w
    rcall openFile
    movff TBLPTRH, PCLATH
    clrf PCL
    
    