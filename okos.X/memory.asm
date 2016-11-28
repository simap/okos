    udata

    udata_acs
    
flags		res 1; flag bit register

currentFile	res 1; which bank of memory is active

;tableSearch	res 1
;tableRes	res 1
keyboardCode	res 1
keyboardAscii	res 1

oledWriteCount	res 1
oledRow		res 1
oledCol		res 1
oledSegment	res 1
oledFontData	res 2
	
;editorTemp	res 1
	
cursorX		res 1
cursorY		res 1

;parsedWord1	res 1
;parsedWord2	res 2
;parsedWord3	res 1
	
stringsTemp	res 1
	
bitbucket	res 1 ; a memory location just before buffer, allows underruning by 1 to save code space
buffer		res 1 ; the rest of memory

#define keyboardIgnore flags,1,access
#define oledDrawCursor flags,2,access
#define editorEditMode flags,3,access
