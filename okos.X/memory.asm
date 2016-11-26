    udata

		
    access_ovr
flags		res 1; flag bit register
;fsr0_temp	res 2; for isr
;W_TEMP		res 1    
;STATUS_TEMP	res 1
;BSR_TEMP	res 1
;TBLPTR_TEMP	res 2
;
;mainTemp	res 1 
		
keyboardCode	res 1
keyboardAscii	res 1

oledWriteCount	res 1
;oledState	res 1
;oledCharX	res 1
;oledCharY	res 1
oledRow		res 1
oledSegment	res 1
;oledCol		res 1
oledChar	res 1
oledFontData	res 2
;oledOutPixels	res 1
;oledTemp	res 1
	
;tableOffset	res 1
;tableCounter	res 1
;tableTemp	res 1
	
#define tableGoDone flags,0,access
#define keyboardIgnore flags,1,access
