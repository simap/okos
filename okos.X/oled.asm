
#define OLED_I2C_ADDRESS   0x78

#define OLED_CONTROL_BYTE_CMD_SINGLE	0x80
#define OLED_CONTROL_BYTE_CMD_STREAM	0x00
#define OLED_CONTROL_BYTE_DATA_STREAM	0x40

; Fundamental commands (pg.28)
#define OLED_CMD_SET_CONTRAST			0x81	; follow with 0x7F
#define OLED_CMD_DISPLAY_RAM			0xA4
#define OLED_CMD_DISPLAY_ALLON			0xA5
#define OLED_CMD_DISPLAY_NORMAL			0xA6
#define OLED_CMD_DISPLAY_INVERTED 		0xA7
#define OLED_CMD_DISPLAY_OFF			0xAE
#define OLED_CMD_DISPLAY_ON			0xAF

; Addressing Command Table (pg.30)
#define OLED_CMD_SET_MEMORY_ADDR_MODE	0x20	; follow with 0x00 = HORZ mode = Behave like a KS108 graphic LCD
#define OLED_CMD_SET_COLUMN_RANGE		0x21	; can be used only in HORZ/VERT mode - follow with 0x00 + 0x7F = COL127
#define OLED_CMD_SET_PAGE_RANGE			0x22	; can be used only in HORZ/VERT mode - follow with 0x00 + 0x07 = PAGE7
#define OLED_CMD_SET_PAGE_START			0xB0	; can be used only in PAGE mode - add 0-7 for page
#define OLED_CMD_SET_COL_START_LOW		0x00	; can be used only in PAGE mode - add low 4 bits 
#define OLED_CMD_SET_COL_START_HIGH		0x10	; can be used only in PAGE mode - add low 4 bits

; Hardware Config (pg.31)
#define OLED_CMD_SET_DISPLAY_START_LINE		0x40
#define OLED_CMD_SET_SEGMENT_REMAP		0xA1	
#define OLED_CMD_SET_MUX_RATIO			0xA8	; follow with 0x3F = 64 MUX
#define OLED_CMD_SET_COM_SCAN_MODE		0xC8	
#define OLED_CMD_SET_DISPLAY_OFFSET		0xD3	; follow with 0x00
#define OLED_CMD_SET_COM_PIN_MAP		0xDA	; follow with 0x12

; Timing and Driving Scheme (pg.32)
#define OLED_CMD_SET_DISPLAY_CLK_DIV		0xD5	; follow with 0x80
#define OLED_CMD_SET_PRECHARGE			0xD9	; follow with 0x22
#define OLED_CMD_SET_VCOMH_DESELCT		0xDB	; follow with 0x30

; Charge Pump (pg.62)
#define OLED_CMD_SET_CHARGE_PUMP		0x8D	; follow with 0x14

; NOP
#define OLED_CMD_NOP 				0xE3
    
    ;take ascii char in WREG, get 3x5 pixels from font table, unpack and send to display
oledDrawChar
   ;load font data
    addlw .224 ;subtract 32 TODO non-ascii charset could avoid this
    rlncf WREG
    addlw font3x5
    movwf TBLPTRL, access
;    clrf TBLPTRU, access ; no need
    movlw high(font3x5)
    movwf TBLPTRH, access
    tblrd*+
    movff TABLAT, oledFontData
    tblrd* ; keep high byte in TABLAT
    movff TABLAT, oledFontData+1
    
    ;remove descender bit from display (would show on 4th segment)
    bcf oledFontData+1, 7
    
    rcall i2cStart
    movlw OLED_CONTROL_BYTE_DATA_STREAM
    rcall i2cWrite
    clrf oledSegment, access
oledDrawCharLoop
    ;write low 5 bits, one segment of font pixels
    movlw 0x1f
        
    andwf oledFontData, w, access
    ;shift to center on line
    rlncf WREG

    ;check for descender bit (tablat still has untouched high byte of font data)
    btfsc TABLAT, 7
    rlncf WREG
    
    btfsc oledDrawCursor
    bsf WREG, 7
    
    rcall i2cWrite
    
    ;shift everything 5 bits to the right to get the next col of font pixels
    movlw .5
oledFontShiftLoop
    bcf STATUS, C ; avoid shifting garbage into high bits so that on the 4th segment is empty
    rrcf oledFontData+1, f, access
    rrcf oledFontData, f, access
    decfsz WREG, f, access
    bra oledFontShiftLoop
    incf oledSegment, f, access
    btfss oledSegment, 2, access
    bra oledDrawCharLoop
    rcall i2cStop
    incf oledCol, f
    bcf oledCol, 5 ; keep it 0-31
    return
    
i2cWait
;    btfss PIR1, SSPIF, access
;    bra i2cWait
;    bcf PIR1, SSPIF, access
    return
    
i2cStart
    bsf SSP1CON2, SEN, access	    ;initate start condition
    movlw OLED_I2C_ADDRESS
    rcall i2cWrite
    return
    
i2cStop
    rcall i2cWait
    bsf SSP1CON2, PEN, access	    ;initate stop condition
    rcall i2cWait
    return
    
i2cWrite
    rcall i2cWait
    movwf SSP1BUF, access
    return

;W = number of bytes to send
;TBLPTR = sequence table
oledWriteSequence
    movwf oledWriteCount, access
    rcall i2cStart
oledWriteSequenceLoop
    tblrd*+
    movf TABLAT, w, access
    rcall i2cWrite
    decfsz oledWriteCount, f, access
    bra oledWriteSequenceLoop
    rcall i2cStop
    return

oledInit macro
;    bcf SSP1CON1, SSPEN, access	    ; disable mssp
    bsf SSP1CON1, SSPM3, access	    ; i2c master mode
    movlw 0x1d			    ; 400khz @ 48mhz
    movwf SSP1ADD, access
;    bcf PIR1, SSPIF, access
    bsf SSP1CON1, SSPEN, access	    ; enable mssp
    
;    clrf TBLPTRU, access
    movlw high(oledInitSequence)
    movwf TBLPTRH, access
    movlw low(oledInitSequence)
    movwf TBLPTRL, access
    movlw .9
    rcall oledWriteSequence
    endm

; increment oled row, reset column pos, set start line to simulate infinite scroll, and clear the new line
oledNewLine
    rcall i2cStart
    movlw OLED_CONTROL_BYTE_CMD_STREAM
    rcall i2cWrite
    incf oledRow, w, access
    andlw 0x07
    movwf oledRow, access
    iorlw OLED_CMD_SET_PAGE_START
    rcall i2cWrite
    movlw OLED_CMD_SET_COL_START_LOW
    rcall i2cWrite
    movlw OLED_CMD_SET_COL_START_HIGH
    rcall i2cWrite
    movf oledRow, w
    addlw .1
    mullw .8
    movf PRODL, w, access
    andlw 0x3f
    addlw OLED_CMD_SET_DISPLAY_START_LINE
    rcall i2cWrite
    rcall i2cStop
    movlw .32
    movwf oledWriteCount
    clrf oledCol
oledBlankLineLoop
    movlw ' '
    rcall oledDrawChar
    decfsz oledWriteCount, f
    bra oledBlankLineLoop
    return
    
;oledPrepDraw
;    movlw high(oledDrawSequence)
;    movwf TBLPTRH, access
;    movlw low(oledDrawSequence)
;    movwf TBLPTRL, access
;    movlw .7
;    rcall oledWriteSequence
;    return
    
;oledDrawSequence ; 7 bytes
;    db OLED_CONTROL_BYTE_CMD_STREAM, OLED_CMD_SET_COLUMN_RANGE
;    db 0x00, 0x7F
;    db OLED_CMD_SET_PAGE_RANGE, 0
;    db 0x07

oledInitSequence ; 10 bytes

    db OLED_CONTROL_BYTE_CMD_STREAM, OLED_CMD_DISPLAY_OFF
    db OLED_CMD_SET_SEGMENT_REMAP, OLED_CMD_SET_COM_SCAN_MODE
    db OLED_CMD_SET_CHARGE_PUMP, 0x14
    db OLED_CMD_SET_VCOMH_DESELCT, 0x30
    db OLED_CMD_DISPLAY_ON, OLED_CMD_DISPLAY_ON
    
;26 bytes
;    db OLED_CONTROL_BYTE_CMD_STREAM, OLED_CMD_DISPLAY_OFF
;    db OLED_CMD_SET_MUX_RATIO, 0x3F ; DELETE ME, default is 63 (0x3f)
;    db OLED_CMD_SET_DISPLAY_OFFSET, 0x00 ; DELETE ME, default is 0
;    db OLED_CMD_SET_DISPLAY_START_LINE, OLED_CMD_SET_SEGMENT_REMAP ; DELETE ME start line is default, seg remap needs to stay
;    db OLED_CMD_SET_COM_SCAN_MODE, OLED_CMD_SET_COM_PIN_MAP ; delete pin map (defaults) and 0x12
;    db 0x12, OLED_CMD_SET_CONTRAST ; delete contrast and 7f ,defaults
;    db 0x7F, OLED_CMD_DISPLAY_RAM ; delete display ram, its default
;    db OLED_CMD_DISPLAY_NORMAL, OLED_CMD_SET_DISPLAY_CLK_DIV; delete normal, its default, delete clock div and 0x80, its default
;    db 0x80, OLED_CMD_SET_CHARGE_PUMP
;    db 0x14, OLED_CMD_SET_PRECHARGE ; delete precharge and 0x22, defaults
;    db 0x22, OLED_CMD_SET_VCOMH_DESELCT ;TODO try with out chaning this to 0x30 (.83 x vcc) default is 0x77 vcc
;    db 0x30, OLED_CMD_SET_MEMORY_ADDR_MODE ;TODO could use page mode, write setup is simplier too
;    db 0x00, OLED_CMD_DISPLAY_ON
;    
;    ; Tell the SSD1306 that a command stream is incoming
;    db OLED_CONTROL_BYTE_CMD_STREAM
;
;    ; Follow instructions on pg.64 of the dataSheet for software configuration of the SSD1306
;    ; Turn the Display OFF
;    db OLED_CMD_DISPLAY_OFF
;    ; Set mux ration tp select max number of rows - 64
;    db OLED_CMD_SET_MUX_RATIO
;    db 0x3F
;    ; Set the display offset to 0
;    db OLED_CMD_SET_DISPLAY_OFFSET
;    db 0x00
;    ; Display start line to 0
;    db OLED_CMD_SET_DISPLAY_START_LINE
;
;    ; Mirror the x-axis. In case you set it up such that the pins are north.
;    ; db 0xA0 - in case pins are south - default
;    db OLED_CMD_SET_SEGMENT_REMAP
;
;    ; Mirror the y-axis. In case you set it up such that the pins are north.
;    ; db 0xC0 - in case pins are south - default
;    db OLED_CMD_SET_COM_SCAN_MODE
;
;    ; Default - alternate COM pin map
;    db OLED_CMD_SET_COM_PIN_MAP
;    db 0x12
;    ; set contrast
;    db OLED_CMD_SET_CONTRAST
;    db 0x7F
;    ; Set display to enable rendering from GDDRAM (Graphic Display Data RAM)
;    db OLED_CMD_DISPLAY_RAM
;    ; Normal mode!
;    db OLED_CMD_DISPLAY_NORMAL
;    ; Default oscillator clock
;    db OLED_CMD_SET_DISPLAY_CLK_DIV
;    db 0x80
;    ; Enable the charge pump
;    db OLED_CMD_SET_CHARGE_PUMP
;    db 0x14
;    ; Set precharge cycles to high cap type
;    db OLED_CMD_SET_PRECHARGE
;    db 0x22
;    ; Set the V_COMH deselect volatage to max
;    db OLED_CMD_SET_VCOMH_DESELCT
;    db 0x30
;    ; Horizonatal addressing mode - same as the KS108 GLCD
;    db OLED_CMD_SET_MEMORY_ADDR_MODE
;    db 0x00
;    ; Turn the Display ON
;    db OLED_CMD_DISPLAY_ON
