
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
oledWriteChar        
   ;load font data
    rlncf WREG
    addlw font3x5
    movwf TBLPTRL
    clrf TBLPTRH
    tblrd*+
    movff TABLAT, oledFontData
    tblrd* ; keep high byte in TABLAT

#if USE_LOWERCASE
    movff TABLAT, oledFontData+1
    
    ;remove descender bit from display (would show on 4th segment)
    bcf oledFontData+1, 7
#endif
    
    clrf oledSegment
oledDrawCharLoop
    ;write low 5 bits, one segment of font pixels
    movlw 0x1f
    andwf oledFontData, w
    ;shift to center on line
    rlncf WREG

#if USE_LOWERCASE    
    ;check for descender bit (tablat still has untouched high byte of font data)
    btfsc TABLAT, 7
    rlncf WREG
#endif
    
    rcall i2cWrite
    ;shift everything 5 bits to the right to get the next col of font pixels
    movlw .5
oledFontShiftLoop
    bcf STATUS, C ; avoid shifting garbage into high bits so that on the 4th segment is empty
#if USE_LOWERCASE
    rrcf oledFontData+1, f
    rrcf oledFontData, f
#else
    rrcf TABLAT, f
    rrcf oledFontData, f
#endif
    
    decfsz WREG, f
    bra oledFontShiftLoop
    incf oledSegment, f
    btfss oledSegment, 2 ; 0-3, stop at 4
    bra oledDrawCharLoop ;more segments to draw
    incf oledCol, f
    bcf oledCol, 5 ; keep it 0-31
    return
    
i2cWait
    btfss PIR1, SSPIF
    bra i2cWait
    bcf PIR1, SSPIF
    return

;oled ssd1306 doesn't seem to like restarts, so do a stop then start
i2cRestart
    rcall i2cWait
    bsf SSP1CON2, PEN	    ;initate stop condition
    rcall i2cWait
    bsf SSP1CON2, SEN	    ;initate start condition
i2cWriteAddress
    movlw OLED_I2C_ADDRESS
    rcall i2cWrite
    return
    
i2cWrite
    rcall i2cWait
    movwf SSP1BUF
    return

oledInit macro
    bsf SSP1CON1, SSPM3	    ; i2c master mode
    movlw 0x1d		    ; 400khz @ 48mhz
    movwf SSP1ADD
    bsf SSP1CON1, SSPEN	    ; enable mssp
    bsf SSP1CON2, SEN	    ;initate start condition
    rcall i2cWriteAddress
    movlw OLED_CONTROL_BYTE_CMD_STREAM
    rcall i2cWrite
    movlw OLED_CMD_SET_CHARGE_PUMP
    rcall i2cWrite
    movlw 0x14
    rcall i2cWrite
    movlw OLED_CMD_DISPLAY_ON
    rcall i2cWrite
    endm

setFsr2ToLine:
    lfsr 2, line
    return
    
oledDrawFlushLine:
    rcall i2cRestart
    movlw OLED_CONTROL_BYTE_CMD_STREAM
    rcall i2cWrite
    movf oledRow, w
    iorlw OLED_CMD_SET_PAGE_START
    rcall i2cWrite
    movlw OLED_CMD_SET_COL_START_LOW
    rcall i2cWrite
    movlw OLED_CMD_SET_COL_START_HIGH
    rcall i2cWrite
    rcall i2cRestart
    movlw OLED_CONTROL_BYTE_DATA_STREAM
    rcall i2cWrite
    rcall setFsr2ToLine
    movlw .32
    movwf oledWriteCount
oledDrawFlushLineLoop:
    movf INDF2, w
    rcall oledWriteChar
    movlw CHAR_SPACE
    movwf POSTINC2
    decfsz oledWriteCount, f
    bra oledDrawFlushLineLoop
    rcall setFsr2ToLine
    return
    