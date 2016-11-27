
;search a table of bytes for a specific value until found or end of table (zero)
tableIndexOf: ;20 bytes
    movwf tableSearch
    clrf tableRes
tableIndexOfLoop:
    incf tableRes, f
    tblrd*+
    movf TABLAT, w
    xorwf tableSearch, w
    tstfsz TABLAT
    bnz tableIndexOfLoop
    decf tableRes, w
    return

;tableOffset:
;    addwf TBLPTRL
;    btfsc STATUS, C
;    incf TBLPTRH, f
;    return
;    
;;index of tables, such that it would be easy to identify a table with a single byte    
;tableLoad: ;18 bytes
;    movwf TBLPTRL
;    clrf TBLPTRH
;    tblrd*+
;    movf TABLAT, w
;    tblrd*
;    movff TABLAT, TBLPTRH
;    movwf TBLPTRL
;    return
;    
;
;tableLookup:
;    movwf tableSearch
;tableLookupLoop:
;    tblrd*+
;    movff TABLAT, tableRes
;    tblrd*+
;    movf TABLAT, w
;    xorwf tableSearch, w
;    tstfsz tableRes
;    bnz tableLookupLoop
;    return

;each data table first byte is number of bytes to read (0=256)
;Go/Done bit flag controls function behavior. 
;setting flag uses wreg to look up the table in the index
;flag is returned clear as long as there is more data to read
;assumes control of TBLPTR
; e.g.:

;    movlw TABLE1_INDEX
;    bsf tableGoDone
;readLoop
;    rcall tableByte
;    ; do something with wreg
;    btfss tableGoDone
;    bra readLoop
;    ; done!
    

;    ;support tableOffset
;    movf tableOffset, w
;    addwf TBLPTRL
;    btfsc STATUS, C
;    incf TBLPTRH, f
;    clrf tableOffset
;    
;    ;read byte counter
;    tblrd*+
;    movff TABLAT, tableCounter
    