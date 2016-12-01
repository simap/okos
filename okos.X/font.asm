
;it would be a shame not to showcase the descender support, but it takes 10 more bytes
#define USE_LOWERCASE 0
;if < 32 or > 126 set black. take ascii subtract 32, use table lookup
;works as long as this remains in the same TBLPTRL space
font3x5:
    db	0x3e,0x3e	;48 '0'
    db	0xe2,0x03	;49 '1'
    db	0xb9,0x4a	;50 '2'
    db	0xb1,0x2a	;51 '3'
    db	0x87,0x7c	;52 '4'
    db	0xb7,0x26	;53 '5'
    db	0xbe,0x76	;54 '6'
    db	0xb9,0x0c	;55 '7'
    db	0xbf,0x7e	;56 '8'
    db	0xb7,0x3e	;57 '9'
#if !USE_LOWERCASE
    db	0xbe,0x78	;65 'A'
    db	0xbf,0x2a	;66 'B'
    db	0x2e,0x46	;67 'C'
    db	0x3f,0x3a	;68 'D'
    db	0xbf,0x56	;69 'E'
    db	0xbf,0x14	;70 'F'
    db	0xae,0x76	;71 'G'
    db	0x9f,0x7c	;72 'H'
    db	0xf1,0x47	;73 'I'
    db	0x08,0x3e	;74 'J'
    db	0x9f,0x6c	;75 'K'
    db	0x1f,0x42	;76 'L'
    db	0xdf,0x7c	;77 'M'
    db	0xdf,0x7d	;78 'N'
    db	0x2e,0x3a	;79 'O'
    db	0xbf,0x08	;80 'P'
    db	0x2e,0x7b	;81 'Q'
    db	0xbf,0x59	;82 'R'
    db	0xb2,0x26	;83 'S'
    db	0xe1,0x07	;84 'T'
    db	0x0f,0x7e	;85 'U'
    db	0x07,0x1f	;86 'V'
    db	0x9f,0x7d	;87 'W'
    db	0x9b,0x6c	;88 'X'
    db	0x83,0x0f	;89 'Y'
    db	0xb9,0x4e	;90 'Z'
#else
    db	0xda,0x72	;97 'a'
    db	0x5f,0x32	;98 'b'
    db	0x4c,0x4a	;99 'c'
    db	0x4c,0x7e	;100 'd'
    db	0x4c,0x5b	;101 'e'
    db	0xc4,0x17	;102 'f'
    db	0xa6,0xbe	;103 'g'
    db	0x5f,0x70	;104 'h'
    db	0xa0,0x03	;105 'i'
    db	0x08,0xb6	;106 'j'
    db	0x9f,0x49	;107 'k'
    db	0xf1,0x43	;108 'l'
    db	0xde,0x79	;109 'm'
    db	0x5e,0x70	;110 'n'
    db	0x4c,0x32	;111 'o'
    db	0x5e,0x91	;112 'p'
    db	0x44,0xf9	;113 'q'
    db	0x5c,0x08	;114 'r'
    db	0xd4,0x2b	;115 's'
    db	0xe2,0x4b	;116 't'
    db	0x0e,0x7a	;117 'u'
    db	0x0e,0x3b	;118 'v'
    db	0x9e,0x7b	;119 'w'
    db	0x92,0x49	;120 'x'
    db	0x06,0xf9	;121 'y'
    db	0xda,0x5b	;122 'z'
#endif
    db	0x50,0x01	;59 ';'
    db	0x00,0x02	;46 '.'
    db	0x00,0x00	;32 ' '
