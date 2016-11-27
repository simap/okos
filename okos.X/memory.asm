    udata
line		res 32
buffer		res 1

    udata_acs
    
flags		res 1; flag bit register
tableSearch	res 1
tableRes	res 1
keyboardCode	res 1
keyboardAscii	res 1

oledWriteCount	res 1
oledRow		res 1
oledCol		res 1
oledSegment	res 1
oledFontData	res 2

	
editorTemp	res 1
	
cursorX		res 1
cursorY		res 1

parsedWord1	res 1
parsedWord2	res 2
parsedWord3	res 1
	
stringsTemp	res 1

#define BUFFER_MAX_ADDR (buffer+1900)

#define keyboardIgnore flags,1,access
#define oledDrawCursor flags,2,access
