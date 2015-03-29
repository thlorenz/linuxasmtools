;color format.
;   aafffbbb  aa-attr fff-foreground  bbb-background
;    0-blk 1-red 2-grn 3-brwn 4-blu 5-purple 6-cyan 7-gry
;    attributes 0-normal 1-bold 4-underscore 7-inverse
bright	equ	01000000b

black_char	equ	00000000b
red_char	equ	00001000b
green_char	equ	00010000b
brown_char	equ	00011000b
blue_char	equ	00100000b
purple_char	equ	00101000b
cyan_char	equ	00110000b
grey_char	equ	00111000b

black_back	equ	00000000b
red_back	equ	00000001b
green_back	equ	00000010b
brown_back	equ	00000011b
blue_back	equ	00000100b
purple_back	equ	00000101b
cyan_back	equ	00000110b
grey_back	equ	00000111b
