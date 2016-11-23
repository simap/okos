
;index of tables, such that it would be easy to identify a table of arbitrary size with a single byte
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
    
