;
;   Copyright (C) 2007 Jeff Owens
;
;   This program is free software: you can redistribute it and/or modify
;   it under the terms of the GNU General Public License as published by
;   the Free Software Foundation, either version 3 of the License, or
;   (at your option) any later version.
;
;   This program is distributed in the hope that it will be useful,
;   but WITHOUT ANY WARRANTY; without even the implied warranty of
;   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;   GNU General Public License for more details.
;
;   You should have received a copy of the GNU General Public License
;   along with this program.  If not, see <http://www.gnu.org/licenses/>.


  [section .text align=1]
;-------------------------------------------------------------
;>1 utility
; key_echo - display codes for keys
; inputs:
;   All keys on keyboard result in a display except
;   for the "q" key which exits the program.
; ouptut:
;   the hex codes returned by a key press are displayed
;   along with the name of key.
; purpose:
;   key_echo is useful for programmers to determine how
;   keys function.
; notes:
;   source file: key_echo.asm
;<
; This program reads a keystroke and uses table to decode it

  extern terminfo_read
  extern terminfo_str_index
  extern env_stack
  extern terminfo_strings
  extern str_compare
  extern word_to_ascii

 [section .text]

global	_start
global main
global exit

_start:
main:
	call	env_stack
	mov	eax,work_buf
	call	terminfo_read

        nop
        nop
        nop
jeff:	mov	ecx,msg
	call	strout
blp1:
	call	mouse_enable

	call	read_stdin

	mov	ecx,eol
	call	strout
	call	display_key_string
	call	decode_key			;ecx = index or err(0)
	jecxz	skip1				;jmp if not in table
	call	display_key_name
skip1:	call	display_terminfo_index	
	cmp	byte [kbuf],'q'
	jne	blp1			;loop till 'q' pressed
exit:
	mov	eax,1
	mov	ebx,0			;normal exit
	int	0x80			;exit

;--------------------------------------------------------------
display_terminfo_index:
	xor	ecx,ecx		;start index counter
        mov	esi,[terminfo_str_index]
dti_lp:
	xor	eax,eax
	lodsw			;get index
	or	ax,ax
	js	dti_next
	add	eax,[terminfo_strings]
	push	esi	
	mov	esi,eax		;get string ptr

	mov	edi,kbuf	;get ptr to key
	call	str_compare
	pop	esi
	je	got_match
dti_next:
	inc	ecx
	cmp	esi,[terminfo_strings]	;end of table?
	jb	dti_lp		;loop
;no match was found, show results
        mov	ecx,no_match
	call	strout
	jmp	short dti_exit
got_match:
	mov	[stuff],dword '    '	;clear build area
	mov	eax,ecx
	mov	edi,stuff
	call	word_to_ascii
	mov	ecx,terminfo_msg
	call	strout
dti_exit:
	ret
;--------
  [section .data]
no_match: db 'no entry in terminfo database for this key',0ah,0
terminfo_msg:
	 db 'Terminfo database index# '
stuff:	db	'    was found for this key',0ah,0

  [section .text]
;--------------------------------------------------------------
;
display_key_string:			
	mov	ecx,9				; 8 bytes
	mov	esi,bufx			;storage for ascii
	mov	edi,kbuf			;get ptr to char
lp1:
	mov	al,byte [edi]			;get char
	cmp	al,0
	je	done1				;jmp if end of char
	call	BYTE_TO_HEX_STR
	inc	edi
	dec	ecx
	jnz	lp1

done1:	mov	byte [esi],0ah
	sub	esi,bufx-3
	mov	edx,esi				;amount of data to display
	
	mov	eax,4				;sys_write
	mov	ebx,1
	mov	ecx,prefix
	int	0x80
	ret
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -( CONVERT )
;BYTE_TO_HEX_STR - convert hex byte to two ascii characters
;
; inputs:    al = hex byte
;          esi = storage buffer for ascii
;         
; output:   esi = points past last store (bumped by 2)
;* * * * * * * * * * * * * *

BYTE_TO_HEX_STR:
	push	eax
	mov	ah,al		;save for later
	shr	al,1
	shr	al,1
	shr	al,1
	shr	al,1
	call	btha		;convert one nibble
	xchg	ah,al
	call	btha
	pop	eax
	ret
;-----------------------
btha:	and	al,0fh
	add	al,90h		;convert
	daa			;  -al- bits 0-3
	adc	al,40h		;     to hex
	daa			;        ascii
;	cmp	cs:crt_direct,0
;	je	btha_stuff
;	int	29h
;	ret
btha_stuff:	
	mov	byte [esi],al
	inc	esi
	ret	
;********************************** decode logic ********************
; lookup_key - scan key strings looking for match
;   ecx - index if found, 0 if not found
;
lookup_key:
	mov	esi,keystring_tbl
	xor	ecx,ecx
k1:	mov	edi,kbuf
	mov	al,byte [edi]		;get kbuf entry
	cmp	al,byte [esi]		;compare to keystring
	je	k4			;initial char. match
k2:	inc	esi
k3:	cmp	byte [esi],0		;end of tbl entry
	jne	k2			;loop if not end of tbl str
k3a:	inc	esi
	inc	ecx
	cmp	byte [esi],0		;check if end of table
	jne	k1			;jmp if more strings
	xor	ecx,ecx			;flag no match
	jmp	k6
;
; we have a match
;
k4:	inc	esi
	inc	edi
	mov	al,byte [edi]		;get next kbuf entry
	cmp	byte [esi],al		;match?
	jne	k3			;jmp if no match
	cmp	al,0			;end of kbuf string
	je	k5			;jmp if match at zero in both
	cmp	byte [esi],0		;end of table string
	jne	k4			;keep comparing if more data
;
; are we at end of this string

	jmp	k3a		
k5:	inc	ecx			;point ecx at match
k6:	ret
;---------------------
; decode_key - look up processing for this key
;  input - kbuf - has char zero terminated
;  output - ecx = ptr to processing or zero if no match
;           eax,ebx modified
decode_key:
	call	lookup_key
	jcxz	dk_end		;exit if no match
;	mov	eax,ecx		;save index in -eax-;
	mov	dword [keystr_index],ecx	;; temp save
;	mov	ecx,pmode	;get mode
;	mov	ebx,edit_index_tbl-1
;	jecxz	dk3		;jmp if edit mode
;	mov	ebx,view_index_tbl-1
;	dec	ecx
;	jecxz	dk3		;jmp if view mode
;	mov	ebx,cmd_index_tbl-1 ;we must be in cmd mode
	
;dk3:	add	ebx,eax		;index into table
;	xor	eax,eax
;	mov	byte al,[ebx]	;get byte index to processing

;	mov	dword [process_index],eax	;; temp save of index
	
;	shl	eax,2		;convert to dword index
;	mov	ecx,process_adr_tbl
;	add	ecx,eax
dk_end:	ret
	
;-------------------------------
; strout - output string
;  input: ecx - ponter to string
;
	%define stdin 0x0
	%define stdout 0x1
	%define stderr 0x2

strout:
	xor edx, edx
    .count_again:	
	cmp [ecx + edx], byte 0x0
	je .done_count
	inc edx
	jmp .count_again
    .done_count:	
	mov eax, 0x4			; system call 0x4 (write)
	mov ebx, stdout			; file desc. is stdout
	int 0x80
	ret
;--------------------------------
; display_key_name:
; input: keystr_index - index into key names
;
display_key_name:
	mov	word [plug2],'00'		;clear storage
	mov	eax,[keystr_index]
	mov	esi,plug2
	call	BYTE_TO_HEX_STR
	mov	ecx,msg2
;	call	strout
	mov	ecx,msg3
;	call	strout
	mov	eax,[keystr_index]
	mov	esi,keyname_tbl
	call	index_into_strings
	mov	ecx,esi
	call	strout
	mov	ecx,eol
	call	strout
	ret
;------------------------------------
;index_into_strings - get string by indexing into table
; input: eax = index
;        esi = table pointer
; output: esi = string ptr

index_into_strings:
iis1:	dec	eax
	jz	iis3
iis2	inc	esi
	cmp	byte [esi],ah		;end of string?
	jne	iis2
	inc	esi			;loop till zero found
	jmp	iis1	
iis3:
	ret	
;-------------------------------------------------------
mouse_enable:
  mov	ecx,mouse_escape
  call	strout
  ret  

mouse_escape	db   1bh,"[?1000h",0	;enables mouse reporting
;-------------------------------------------------------------
;  extern key_status
  extern kbuf
  extern key_flush
;  extern key_poll
  extern mouse_check
  extern raw_set2,raw_unset2

 [section .text]
read_stdin:
  call	raw_set2
km_10:
poll_keyboard:
  mov	ecx,kbuf
read_more:
  mov	edx,36			;read 20 keys
  mov	eax,3				;sys_read
  mov	ebx,0				;stdin
  int	byte 0x80
  or	eax,eax
  js	rm_exit
  add	ecx,eax
  mov	byte [ecx],0		;terminate char

  push	ecx
  mov	eax,162			;nano sleep
  mov	ebx,delay_struc
  xor	ecx,ecx
  int	byte 80h

  mov	word [kpoll_rtn],0
  mov	eax,168			;poll
  mov	ebx,kpoll_tbl
  mov	ecx,1			;one structure at poll_tbl
  mov	edx,20			;wait xx ms
  int	byte 80h
  test	byte [kpoll_rtn],01h
  pop	ecx
  jnz	read_more
;strip any extra data from end
  mov	esi,kbuf
  cmp	byte [esi],1bh
  je	mb_loop
  cmp	byte [esi],0c2h
  je	mb_loop			;jmp if meta char
  cmp	byte [esi],0c3h
  je	mb_loop
  inc	esi
  jmp	short rm_20
;check for end of escape char
mb_loop:
  inc	esi
  cmp	[esi],byte 0
  je	rm_exit			;jmp if end of char
  cmp	byte [esi],0c2h
  je	rm_20			;jmp if meta char
  cmp	byte [esi],0c3h
  je	rm_20			;jmp if meta char
  cmp	byte [esi],1bh
  jne	mb_loop			;loop till end of escape sequence
rm_20:
  mov	byte [esi],0		;terminate string
rm_exit:
  call	raw_unset2
  ret 
;------------------
  [section .data]
kpoll_tbl	dd	0	;stdin
		dw	-1	;events of interest
kpoll_rtn	dw	-1	;return from poll

delay_struc:
  dd	0	;seconds
  dd	1	;nanoeconds
  [section .text]

;---------------------------------------------------------------------------	
 [section .data]

msg	db   'press key, press q to quit',0ah
	db   'hex character encodinging will be displayed',0ah,0
msg2	db   'keystr_index = '
plug2	db   'xx',0ah,0
msg3	db   'key name = ',0
eol	db   0ah,0
eol2	db   ' ',0ah,' ',0

keystr_index  dd 0		;index to processing 1=first entry
process_index dd 0		;index to processing 1=first entry

pmode	dd	0		;0=edit 1=view 2=cmd
;keylen	dd	0		;lenght of key string

prefix:
	db	"0","x"
bufx	db	0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0

	db	77h
	
oldtermios:
c_iflag	dd	0
c_oflag dd	0
c_cflag dd	0
c_lflag dd	0
c_line	dd	0
cc_c	db	0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0
	db	0,0,0


newtermios:
c_iflg dd	0
c_oflg dd	0
c_cflg dd	0
c_lflg dd	0
c_lin	dd	0
c_c	db	0,0,0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0
	db	0,0,0

;---- key decode tables
;
;# AVAILABLE KEYS:
;#   up, down, left, right - CURSOR ARROWS
;#   home, end		  - HOME & END KEYS
;#   backspace, del	  - BS & DEL
;#   ins			  - INSERT
;#   pgup		  - PAGE UP
;#   pgdn		  - PAGE DOWN
;#   a1,a3,b2,c1,c3        - NUMPAD (7, 9, 5, 1, 3)
;#   f1 - f24              - FUNCTION KEYS
;#   #code		  - SPECIFIED ASCII CHARACTER
;# AVAILABLE MODIFIERS:
;#   lalt		- LEFT ALT   example: alt-up
;#   lalt		- RIGHT ALT
;#   lshift	- SHIFT
;#   rshift
;#   control	- CTRL
;#   WARNING, WHEN CONSIDERING SOME SPECIAL KEYS (eg. PGUP, PGDN, LEFT, RIGHT)
;#   CTRL IS ACTUALLY lalt !

keyname_tbl:
 db 'esc',0		;1
 db 'f1',0		;2
 db 'f2',0		;3
 db 'f3',0		;4
 db 'f4',0		;5
 db 'f5',0		;6
 db 'f6',0		;7
 db 'f7',0		;8
 db 'f8',0		;9
 db 'f9',0		;10
 db 'f10',0		;11
 db 'f11',0		;12
 db 'f12',0		;13
 db 'home',0	;14
 db 'up',0		;15
 db 'pgup',0	;16
 db 'left',0	;17
 db 'right',0	;18
 db 'end',0		;19
 db 'down',0	;20
 db 'pgdn',0	;21
 db 'ins',0		;22
 db 'del',0		;23
 db 'backspace',0	;24
 db 'ctrl_z',0		;25
 db 'ctrl_a',0		;26
 db 'lquote',0		;27
 db '~',0		;28
 db 'tab',0		;29 tab
 db '@',0		;30
 db '#',0		;31
 db '$',0		;32
 db '%',0		;33
 db '^',0		;34
 db '&',0		;35
 db '*',0		;36
 db '(',0		;37
 db ')',0		;38
 db '_',0		;39
 db '+',0		;40
 db '1',0		;41
 db '2',0		;42
 db '3',0		;43
 db '4',0		;44
 db '5',0		;45
 db '6',0		;46
 db '7',0		;47
 db '8',0		;48
 db '9',0		;49
 db '0',0		;50
 db '-',0		;51
 db '=',0		;52
 db 'q',0		;53
 db 'w',0		;54
 db 'e',0		;55
 db 'r',0		;56
 db 't',0		;57
 db 'y',0		;58
 db 'u',0		;59
 db 'i',0		;60
 db 'o',0		;61
 db 'p',0		;62
 db '[',0		;63
 db ']',0		;64
 db '\',0		;65
 db 'Q',0		;66
 db 'W',0		;67
 db 'E',0		;68
 db 'R',0		;69
 db 'T',0		;70
 db 'Y',0		;71
 db 'U',0		;72
 db 'I',0		;73
 db 'O',0		;74
 db 'P',0		;75
 db '{',0		;76
 db '}',0		;77
 db '|',0		;78
 db 'a',0		;79
 db 's',0		;80
 db 'd',0		;81
 db 'f',0		;82
 db 'g',0		;83
 db 'h',0		;84
 db 'j',0		;85
 db 'k',0		;86
 db 'l',0		;87
 db ';',0		;88
 db 'rquote',0		;89 single quote 
 db 'enter',0		;90  enter 
 db 'A',0		;91
 db 'S',0		;92
 db 'D',0		;93
 db 'F',0		;94
 db 'G',0		;95
 db 'H',0		;96
 db 'J',0		;97
 db 'K',0		;98
 db 'L',0		;99
 db ':',0		;100
 db 'double-quote',0	;101 double quote
 db 'z',0			;102
 db 'x',0			;103
 db 'c',0			;104
 db 'v',0			;105
 db 'b',0			;106
 db 'n',0			;107
 db 'm',0			;108
 db 'comma',0		;109
 db 'period',0			;110
 db '/',0			;111
 db 'Z',0			;112
 db 'X',0			;113
 db 'C',0			;114
 db 'V',0			;115
 db 'B',0			;116
 db 'N',0			;117
 db 'M',0			;118
 db '<',0			;119
 db '>',0			;120
 db '?',0			;121
 db 'space',0		;122 space
; the above are vt100, next is xterm unique keys
 db 'f1',0		;123 F1
 db 'f2',0		;124 F2
 db 'f3',0		;125 F3
 db 'f4',0		;126 F4
;the above are xterm unique, next is linux-console unique
 db 'f1',0		;127 F1
 db 'f2',0		;128 f2
 db 'f3',0		;129 f3
 db 'f4',0		;130 f4
 db 'f5',0		;131 f5
 db 'return',0		;132 0ah
 db 0	;end of table

keystring_tbl:
 db 1bh,0			;1 esc
 db 1bh,5bh,31h,31h,7eh,0	;2 f1
 db 1bh,5bh,31h,32h,7eh,0	;3 f2
 db 1bh,5bh,31h,33h,7eh,0	;4 f3
 db 1bh,5bh,31h,34h,7eh,0	;5 f4
 db 1bh,5bh,31h,35h,7eh,0	;6 f5
 db 1bh,5bh,31h,37h,7eh,0	;7 f6
 db 1bh,5bh,31h,38h,7eh,0	;8 f7
 db 1bh,5bh,31h,39h,7eh,0	;9 f8
 db 1bh,5bh,32h,30h,7eh,0	;10 f9
 db 1bh,5bh,32h,31h,7eh,0	;11 f10
 db 1bh,5bh,32h,33h,7eh,0	;12 f11
 db 1bh,5bh,32h,34h,7eh,0	;13 f12
 db 1bh,5bh,48h,0		;14 pad_home
 db 1bh,5bh,41h,0		;15 pad_up
 db 1bh,5bh,35h,7eh,0		;16 pad_pgup
 db 1bh,5bh,44h,0			;17 pad_left
 db 1bh,5bh,43h,0			;18 pad_right
 db 1bh,5bh,46h,0			;19 pad_end
 db 1bh,5bh,42h,0			;20 pad_down
 db 1bh,5bh,36h,7eh,0		;21 pad_pgdn
 db 1bh,5bh,32h,7eh,0		;22 pad_ins
 db 1bh,5bh,33h,7eh,0		;23 pad_del
 db 7fh,0			;24 backspace
 db 1ah,0			;25 ctrl_z
 db 01h,0			;26 ctrl_a
 db 60h,0			;27 lquote
 db 7eh,0			;28 ~
 db 09h,0			;29 tab
 db 40h,0			;30 @
 db 23h,0			;31 #
 db 24h,0			;32 $
 db 26h,0			;33 %
 db 5eh,0			;34 ^
 db 26h,0			;35 &
 db 2ah,0			;36 *
 db 28h,0			;37 (
 db 29h,0			;38 )
 db 5fh,0			;39 _ underscore
 db 2bh,0			;40 +
 db 31h,0			;41 1
 db 32h,0			;42 2
 db 33h,0			;43 3
 db 34h,0			;44 4
 db 35h,0			;45 5
 db 36h,0			;46 6
 db 37h,0			;47 7
 db 38h,0			;48 8
 db 39h,0			;49 9
 db 30h,0			;50 0
 db 2dh,0			;51 - dash
 db 3dh,0			;52 =
 db 'q',0			;53 q
 db "w",0			;54 w
 db "e",0			;55 e
 db "r",0			;56 r
 db "t",0			;57 t
 db "y",0			;58 y
 db "u",0			;59 u
 db "i",0			;60 i
 db "o",0			;61 o
 db "p",0			;62 p
 db "[",0			;63 [
 db "]",0			;64 ]
 db "\",0			;65 \ -
 db 'Q',0		;66
 db 'W',0		;67
 db 'E',0		;68
 db 'R',0		;69
 db 'T',0		;70
 db 'Y',0		;71
 db 'U',0		;72
 db 'I',0		;73
 db 'O',0		;74
 db 'P',0		;75
 db '{',0		;76
 db '}',0		;77
 db '|',0		;78
 db 'a',0		;79
 db 's',0		;80
 db 'd',0		;81
 db 'f',0		;82
 db 'g',0		;83
 db 'h',0		;84
 db 'j',0		;85
 db 'k',0		;86
 db 'l',0		;87
 db ';',0		;88
 db 27h,0		;89 single quote 
 db 0dh,0		;90  enter 
 db 'A',0		;91
 db 'S',0		;92
 db 'D',0		;93
 db 'F',0		;94
 db 'G',0		;95
 db 'H',0		;96
 db 'J',0		;97
 db 'K',0		;98
 db 'L',0		;99
 db ':',0		;100
 db 22h,0		;101 double quote
 db 'z',0		;102
 db 'x',0			;103
 db 'c',0			;104
 db 'v',0			;105
 db 'b',0			;106
 db 'n',0			;107
 db 'm',0			;108
 db ',',0			;109
 db '.',0			;110
 db '/',0			;111
 db 'Z',0			;112
 db 'X',0			;113
 db 'C',0			;114
 db 'V',0			;115
 db 'B',0			;116
 db 'N',0			;117
 db 'M',0			;118
 db '<',0			;119
 db '>',0			;120
 db '?',0			;121
 db ' ',0			;122 space
; the above are vt100, next is xterm unique keys
 db 1bh,4fh,50h,0		;123 F1
 db 1bh,4fh,51h,0		;123 F2
 db 1bh,4fh,52h,0		;123 F3
 db 1bh,4fh,53h,0		;123 F4
;the above are xterm unique, next is linux-console unique
 db 1bh,5bh,5bh,41h,0		;127 F1
 db 1bh,5bh,5bh,42h,0		;128 f2
 db 1bh,5bh,5bh,43h,0		;129 f3
 db 1bh,5bh,5bh,44h,0		;130 f4
 db 1bh,5bh,5bh,45h,0		;131 f5
 db 0ah,0			;132 return
 db 0		;end of table

view_index_tbl:
 db 1		;esc points at process # 1

cmd_index_tbl:
 db 1

edit_index_tbl:
 db 1

;# AVAILABLE ACTIONS
;#   up, down, left, right	- MOVE CURSOR ONE LINE / ONE CHARACTER
;#   word_left, word_right	- MOVE CURSOR ONE WORD
;#   enter			- MAKE A NEWLINE
;#   return			- MAKE A FORCED NEWLINE (w/o indent)
;#   scroll_up, scroll_down	- SCROLL BUFFER ONE LINE UP / DOWN
;#   page_up, page_down		- SCROLL BUFFER ONE PAGE UP / DOWN
;#   paragraph_up, paragraph_down- SCROLL BUFFER ONE PARA UP / DOWN
;#   home, end			- GO TO BEGINNING OR END OF LINE
;#   beginning_of_text		- GO TO BEGINNING OF TEXT
;#   end_of_text			- GO TO END OF TEXT
;#   begin_page, end_page	- GO TO BEGINNING OR END OF PAGE
;#   backspace			- REMOVE CHARACTER ON LEFT
;#   delete			- REMOVE CHARACTER UNDER CURSOR
;#   delete_word_left		- DELETE A WORD ON LEFT
;#   delete_word_right		- DELETE A WORD ON RIGHT
;#   tab				- INSERT \t
;#
;#   new				- CREATE NEW WINDOW
;#   close			- DELETE CURRENT WINDOW
;#   next_window, prev_window	- SWITCH WINDOWS
;#   size_plus, size_minus	- RESIZE CURRENT WINDOW
;#   fullscreen			- TOGGLE FULLSCREEN
;#   quit			- QUIT
;#
;#   clear			- DISCARD BUFFER CONTENTS
;#   load, save, save_as		- LOAD OR SAVE FROM/TO A FILE
;#   toggle_ro			- TOGGLE READ ONLY
;#
;#   mark			- TOGGLE BLOCK MARKING ON/OFF
;#   unmark			- UNMARK CURRENT BLOCK
;#   copy, move			- COPY OR MOVE BLOCK
;#   remove			- DELETE CURRENT BLOCK OR CURRENT LINE IF NO BLOCK
;#   find, find_again		- SEARCH OPERATIONS
;#   replace, replace_again	- REPLACE OPERATIONS
;#
;#   about			- SHOW THE ABOUT DIALOG
;#   insertliteral		- INSERT LITERAL
;#   options			- OPEN OPTIONS DIALOG
;#   wrap			- WORD WRAP
;#   insert_file			- INCLUDE A FILE
;#   help			- SHOW CURRENT KEY MAPPING
;#   toggle_insert		- TOGGLE INSERT / OVERWRITE
;#   date			- INSERT DATE
;#   refresh			- DO A SCREEN REFRESH
;#   goto			- OPEN GOTO LINE DIALOG
;#   delete_line			- DELETE CURRENT LINE
;#   delete_to_line_end		- DELETE AFTER CURSOR
;#   delete_to_line_begin	- DELETE BEFORE CURSOR
;#   sort			- SORT BLOCK (using external 'sort' command)
;#   mail			- MAIL BUFFER (using external 'mail' command)
;#   paragraph_format		- FORMAT BLOCK
;#   toggle_syntax		- TOGGLE SYNTAX CHECKING
;#
;#   begin_record_macro		- BEGIN RECORDING A MACRO
;#   end_record_macro		- END RECORDING A MACRO
;#   delete_macro		- DELETE A MACRO
;#   execute_macro		- EXECUTE A MACRO

process_name_tbl:
 db 'xxxx'		;01 process 1
 db 0			;end of table

process_adr_tbl:
 dd 0			;1 ptr to xxxx

work_buf:	times 4096 db 0


