#define CHAR_A .10
#define CHAR_E .14
#define CHAR_R .27

#define CHAR_SEMICOLON .36
#define CHAR_PERIOD .37
    
#define CHAR_SPACE .38
#define CHAR_RIGHT_ARROW .39
    
#define CHAR_ENTER .40
#define CHAR_BKSP .41

;up arrow is an extended key, but the non-extended is the 8 key on the keypad (often also used as up arrow)
#define CHAR_UP .42
;down arrow is an extended key, but the non-extended is the 2 key on the keypad (often also used as down arrow)
#define CHAR_DOWN .43

#define CHAR_F1 .44
#define CHAR_BAD .45

keyCodeTable:
    db 0x45, 0x16  ; 0 1
    db 0x1E, 0x26  ; 2 3
    db 0x25, 0x2E  ; 4 5
    db 0x36, 0x3D  ; 6 7
    db 0x3E, 0x46  ; 8 9
    db 0x1C, 0x32  ; a b
    db 0x21, 0x23  ; c d
    db 0x24, 0x2B  ; e f
    db 0x34, 0x33  ; g h
    db 0x43, 0x3B  ; i j
    db 0x42, 0x4B  ; k l
    db 0x3A, 0x31  ; m n
    db 0x44, 0x4D  ; o p
    db 0x15, 0x2D  ; q r
    db 0x1B, 0x2C  ; s t
    db 0x3C, 0x2A  ; u v
    db 0x1D, 0x22  ; w x
    db 0x35, 0x1A  ; y z
    db 0x4C, 0x49  ; ; .
    db 0x29, 0x74  ; SPACE, KP 6 (right)
    db 0x5A, 0x66  ; ENTER, BKSP
    db 0x75, 0x72  ; KP 8 (up), KP 2 (down)
    db 0x05, 0x00  ; F1 (save), end of table
    