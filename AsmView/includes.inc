
;
;asm/termbits.h
;

; c_cc characters
%assign VINTR	0
%assign VQUIT	1
%assign VERASE	2
%assign VKILL	3
%assign VEOF	4
%assign VTIME	5
%assign VMIN	6
%assign VSWTC	7
%assign VSTART	8
%assign VSTOP	9
%assign VSUSP	10
%assign VEOL	11
%assign VREPRINT 12
%assign VDISCARD 13
%assign VWERASE	14
%assign VLNEXT	15
%assign VEOL2	16

; c_iflag bits
%assign IGNBRK	0000001q
%assign BRKINT	0000002q
%assign IGNPAR	0000004q
%assign PARMRK	0000010q
%assign INPCK	0000020q
%assign ISTRIP	0000040q
%assign INLCR	0000100q
%assign IGNCR	0000200q
%assign ICRNL	0000400q
%assign IUCLC	0001000q
%assign IXON	0002000q
%assign IXANY	0004000q
%assign IXOFF	0010000q
%assign IMAXBEL	0020000q

; c_oflag bits
%assign OPOST	0000001q
%assign OLCUC	0000002q
%assign ONLCR	0000004q
%assign OCRNL	0000010q
%assign ONOCR	0000020q
%assign ONLRET	0000040q
%assign OFILL	0000100q
%assign OFDEL	0000200q
%assign NLDLY	0000400q
%assign   NL0	0000000q
%assign   NL1	0000400q
%assign CRDLY	0003000q
%assign   CR0	0000000q
%assign   CR1	0001000q
%assign   CR2	0002000q
%assign   CR3	0003000q
%assign TABDLY	0014000q
%assign   TAB0	0000000q
%assign   TAB1	0004000q
%assign   TAB2	0010000q
%assign   TAB3	0014000q
%assign   XTABS	0014000q
%assign BSDLY	0020000q
%assign   BS0	0000000q
%assign   BS1	0020000q
%assign VTDLY	0040000q
%assign   VT0	0000000q
%assign   VT1	0040000q
%assign FFDLY	0100000q
%assign   FF0	0000000q
%assign   FF1	0100000q

; c_cflag bit meaning
%assign CBAUD	0010017q
%assign  B0	0000000q	;hang up
%assign  B50	0000001q
%assign  B75	0000002q
%assign  B110	0000003q
%assign  B134	0000004q
%assign  B150	0000005q
%assign  B200	0000006q
%assign  B300	0000007q
%assign  B600	0000010q
%assign  B1200	0000011q
%assign  B1800	0000012q
%assign  B2400	0000013q
%assign  B4800	0000014q
%assign  B9600	0000015q
%assign  B19200	0000016q
%assign  B38400	0000017q
%assign EXTA	B19200
%assign EXTB	B38400
%assign CSIZE	0000060q
%assign   CS5	0000000q
%assign   CS6	0000020q
%assign   CS7	0000040q
%assign   CS8	0000060q
%assign CSTOPB	0000100q
%assign CREAD	0000200q
%assign PARENB	0000400q
%assign PARODD	0001000q
%assign HUPCL	0002000q
%assign CLOCAL	0004000q
%assign CBAUDEX 0010000q
%assign    B57600 0010001q
%assign   B115200 0010002q
%assign   B230400 0010003q
%assign   B460800 0010004q
%assign   B500000 0010005q
%assign   B576000 0010006q
%assign   B921600 0010007q
%assign  B1000000 0010010q
%assign  B1152000 0010011q
%assign  B1500000 0010012q
%assign  B2000000 0010013q
%assign  B2500000 0010014q
%assign  B3000000 0010015q
%assign  B3500000 0010016q
%assign  B4000000 0010017q
%assign CIBAUD	  002003600000q	;input baud rate (not used)
%assign CMSPAR	  010000000000q	;mark or space (stick) parity
%assign CRTSCTS	  020000000000q	;flow control

; c_lflag bits
%assign ISIG	0000001q
%assign ICANON	0000002q
%assign XCASE	0000004q
%assign ECHO	0000010q
%assign ECHOE	0000020q
%assign ECHOK	0000040q
%assign ECHONL	0000100q
%assign NOFLSH	0000200q
%assign TOSTOP	0000400q
%assign ECHOCTL	0001000q
%assign ECHOPRT	0002000q
%assign ECHOKE	0004000q
%assign FLUSHO	0010000q
%assign PENDIN	0040000q
%assign IEXTEN	0100000q

; B_STRUC is a more succinct method for using a Nasm structure
; definition within a DATA section. The first argument names a
; previously defined structure. The following arguments indicate
; the members of that structure to declare here.
;
; Please note that the fields of the structure must have been defined
; as local labels (i.e., with a dot prefix).

%macro B_STRUC 1-*
%push foo
%define %$strucname %1
%%top_%$strucname:
%rep %0 - 1
%rotate 1
resb %{$strucname}%1 - ($ - %%top_%$strucname)
%1:
%endrep
resb %{$strucname}_size - ($ - %%top_%$strucname)
%pop
%endmacro


BUFF_IN_LEN	equ	8192

struc winsize
.ws_row		resw	1
.ws_col		resw	1
.ws_xpixel	resw	1
.ws_ypixel	resw	1
endstruc

%assign NCCS 19
struc termios
.c_iflag	resd	1	;input mode flags
.c_oflag	resd	1	;output mode flags
.c_cflag	resd	1	;control mode flags
.c_lflag	resd	1	;local mode flags
.c_line		resb	1	;line discipline
.c_cc		resb	NCCS	;control characters
endstruc

;-- section ---> .text   ;08048080
;src_top:    ;08048080

KEY_DOWN		equ	0x00425b1b
KEY_UP			equ	0x00415b1b
KEY_PGDOWN		equ	0x7e365b1b
KEY_PGUP		equ	0x7e355b1b
KEY_HOME		equ	0x7e315b1b
KEY_END			equ	0x7e345b1b

KEY_ENTER		equ	0xa
KEY_SPACE		equ	" "
KEY_b			equ	"b"
KEY_q			equ	"q"
KEY_Q			equ	"Q"
