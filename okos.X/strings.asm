
;insert line at line number, moving bytes to the right to make room
insertLine

;delete line at line number
deleteLine

;fsr0 is pointed to hex digit
;return wreg with hex value, fsr0 is incremented
parseHexNib
    ;adjust for start of 'a'
    movlw 'a'
    subwf stringsTemp, w
    btfss STATUS, C ;see if that was too much, give back difference to '0'
    addlw ('a' - '0') - 0xa
    addlw 0xa
    return
    
