
;ideas for filesystem included all kinds of things, but the simpliest is just chunks of memory
;32k flash in 2k segments works well, about as much as we can hold in ram, and that gives 16 files.
;could store metadata in eeprom, or perhaps first block (64b) for filename, flags, etc
;files that are 2048 - 64 = 1984 bytes will also fit in ram better

;writes the next byte in WREG to the holding registers
;if a 64b page boundary is crossed, the page is flushed
fputc:
    bsf pageDirty
    movwf TABLAT
    tblwt*+
    movlw 0x3f
    andwf TBLPTRL, w
    bz flushLastPage
    return
;flushes the page the previous TBLPTR address points to
flushLastPage:
;    bcf INTCON, GIE
    tblrd*-; go back to previous page
    ; erase a page of program flash
    ; EEPGD = 1 | CFGS = 0 | x | FREE = 1 | x | WREN = 1 | WR = 0 | RD = 0
    movlw b'10010100'
    rcall startFlashWrite
    
    ;write the page in the holding registers
    ; EEPGD = 1 | CFGS = 0 | x | FREE = 0 | x | WREN = 1 | WR = 1 | RD = 0
    movlw b'10000100'
    rcall startFlashWrite
    
    tblrd*+; repair tblptr
;    bsf INTCON, GIE
    bcf pageDirty
    return
    
closeFlush macro
    btfsc pageDirty
    rcall flushLastPage
    endm
    
;copies buffer data to the "file" referenced by file in WREG
saveFile:
    ;set up tblptr for writing
    movf currentFile, w
    rcall openFile
saveFileLoop:
    movf POSTINC2, w
    rcall fputc
    btfss FSR2H, 3 ; outside of implemented memory range
    bra saveFileLoop
    reset
    
loadFile:
    ;set up tblptr for writing
    rcall openFile
loadFileLoop:
    tblrd*+
    movf TABLAT, w
    btfsc WREG, 7 ;this is only called on text files, so if we load erased pages (0xff), make them into newlines
    movlw CHAR_ENTER
    movwf POSTINC2
    btfss FSR2H, 3 ; outside of implemented memory range
    bra loadFileLoop
    rcall resetBufferFsr
    return
    

;sets TBLPTR to the section of memory pointed to by file in WREG
openFile:
    mullw 0x8
    movff PRODL, TBLPTRH
    ;TODO offset by 1 page (64 bytes) to reserve some room for file metadata.
    clrf TBLPTRL
    lfsr 2, buffer
    return
    
;sets EECON1 to WREG value
;flash write/erase required sequence
;will stall for ~2ms
startFlashWrite:
    movwf EECON1
    movlw 0x55
    movwf EECON2
    movlw 0xaa
    movwf EECON2
    bsf EECON1, WR
    return