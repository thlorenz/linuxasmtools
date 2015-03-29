;
; this is a modified version of key_string to use STDERR and
; not recognize the right,left,home,end keys
;

  [section .text]

  extern move_cursor
;  extern read_stdin
  extern kbuf
  extern lib_buf
  extern crt_color_at
  extern key_decode1
  extern kbuf_end

;****f* key_mouse/key_string1 *
; NAME
;>1 key_mouse
;  key_string1 - get string (preloaded string in buffer)
; INPUTS
;    ebp= pointer to table with following:
;      data buffer ptr    +0    (dword) cleared or preload with text
;      max string length  +4    (dword) buffer must be 1 byte bigger
;      color ptr          +8    (dword) (see file crt_data.asm)
;      display row        +12   (db)	;row (1-x)
;      display column     +13   (db)  ;column (1-x)
;      allow 0d/0a in str +14   (db)	;0=no 1=yes
;      initial curosr col +15   (db)  ;must be within data area
;    notes: user can signal "done" by typing ESC-key. If allow 0d flag
;      is set=0 a string can also be terminated by <Enter> key.
;    notes: The Initial cursor column must equal the display column
;      or within the range of "display_column" + "max string length"
;      Thus, if "display_column=5" and "max string length"=2 then
;      "initial cursor" can be 5 or 6
;           
; OUTPUT
;    al=0 data in buffer, unknown char in kbuf
;    al=1 data in buffer. mouse click
;    ah=current cursor column
; NOTES
;   source file: key_string.asm
;   function crt_open must be called before using!
;<
; * ----------------------------------------------
;*******
 global key_string1
key_string1:
  xor	ebx,ebx
  mov	bl,byte [ebp + 15]		;get initial row
  sub	bl,[ebp + 13]			; compute positon of starting cursor

  mov	edi,[ebp]			;get buffer start
  mov	[str_begin],edi			;save entry string start
  add	edi,ebx				;compute initial cursor posn
  mov	[str_ptr],edi			;set initial cursor ptr

  mov	edi,[ebp]			;get buffer start
  add	edi,[ebp +4]
  mov	[str_end],edi			;set entry string end
  mov	ax,[edi]			;get data at end of buffer
  mov	word [char_out],ax		;save temporarily
  mov	word [edi],'  '			;put spaces at end of buffer

  mov	byte [get_string_flg],0		;set first time flag
  mov	al,[ebp +12]			;get row
  mov	[str_cursor_row],al		;save row
  mov	al,[ebp +13]			;get cursor for left edge
  add	al,bl				;move to current positon
  mov	[str_cursor_col],al		;save column
  jmp	short key_string_entry

;****f* key_mouse/key_string2 *
; NAME
;>1 key_mouse
;  key_string2 - get string (no preloaded string displayed)
; INPUTS
;    ebp= pointer to table with following:
;      data buffer ptr    +0    (dword) cleared or preload with text
;      max string length  +4    (dword) buffer must be 1 byte bigger
;      color ptr          +8    (dword) (see file crt_data.asm)
;      display row        +12   (db)	;row (1-x)
;      display column     +13   (db)  ;column (1-x)
;      allow 0d/0a in str +14   (db)	;0=no 1=yes
;    notes: user can signal "done" by typing ESC-key. If allow 0d flag
;      is set=0 a string can also be terminated by <Enter> key.
; OUTPUT
;    al=0 data in buffer, unknown char in kbuf
;    al=1 data in buffer. mouse click
; NOTES
;   source file: key_string.asm
;   function crt_open must be called before using!
;<
; * ----------------------------------------------
;*******
 global key_string2
key_string2:
  mov	edi,[ebp]			;get buffer start
  mov	[str_begin],edi			;save entry string start
  mov	[str_ptr],edi			;set initial cursor ptr
  add	edi,[ebp +4]
  mov	[str_end],edi			;set entry string end
  mov	ax,[edi]			;get data at end of buffer
  mov	word [char_out],ax		;save temporarily
  mov	word [edi],'  '			;put spaces at end of buffer

  mov	byte [get_string_flg],0		;set first time flag
  mov	al,[ebp +12]			;get row
  mov	[str_cursor_row],al		;save row
  mov	al,[ebp +13]
  mov	[str_cursor_col],al		;save column
; entry point from key_string1
key_string_entry:
  mov	al,[ebp+14]			;get flag
  mov	[str_term_flg],al
  
gs_10:				;********* entry point for get_edit_string
  call	display_get_string
gs_12:
  mov	al,[str_cursor_col]
  mov	ah,[str_cursor_row]
  call	move_cursor			;position cursor
gs_20:
  call	read_stderr
  mov	esi,key_action_tbl
  call	key_decode1
;  call	decode_get_string_key
  jmp	eax
gs_ignore_char:
  jmp	short gs_20
gs_normal_char:
  mov	eax,[str_ptr]
  cmp	eax,[str_end]			;check if room for another char
  je	gs_ignore_char			;jmp if no room
;
; make hole to stuff char
;
  std
  mov	edi,[str_end]
  mov	esi,edi
  inc	edi
gs_21:
  movsb
  cmp	edi,eax				;are we at hole
  jne	gs_21
  cld
  mov	al,[kbuf]			;get char
  mov	byte [edi],al
  mov	edi,[str_end]
  mov	byte [edi+1],0			;zero out any overflow char
gs_23:
  mov	eax,[str_ptr]			;check if at
  inc	eax				;  end of field
  cmp	eax,[str_end]
  je	gs_10				;jmp if at end of field
  inc	byte [str_cursor_col]		;move cursor fwd
  inc	dword [str_ptr]			;move ptr fwd
  jmp	gs_10
gs_backspace:
  mov	esi,[str_ptr]
  mov	edi,esi
  dec	edi
  cmp	esi,[str_begin]
  je	gs_10				;ignore operation if at beginning
  movsb
  mov	byte [edi],' '			;blank prev. position
  dec	byte [str_cursor_col]
  dec	dword [str_ptr]
  jmp	gs_10
gs_enter_key:
  cmp	byte [str_term_flg],0
  je	gs_passkey_done			;jmp if enter key terminates string
  mov	byte [kbuf],0ah			;substitute 0a for 0d
  jmp	gs_normal_char
gs_home:
gs_end:
  jmp	gs_10				;ignore home/end for now
gs_right:
  mov	eax,[str_ptr]
  inc	eax
  cmp	eax,[str_end]
  jae	gs_end				;jmp if at right edge already
  inc	byte [str_cursor_col]		;move cursor fwd
  inc	dword [str_ptr]			;move ptr fwd
  jmp	gs_12
gs_left:
  mov	eax,[str_ptr]
  cmp	eax,[str_begin]
  je	gs_home				;jmp if at left edge already
  dec	byte [str_cursor_col]
  dec	dword [str_ptr]
  jmp	gs_12
gs_del:
  mov	ebx,[str_end]
  mov	byte [ebx],' '			;put space at end
  mov	esi,[str_ptr]
  mov	edi,esi
  inc	esi
gs_27:
  movsb
  cmp	edi,ebx				;[str_end]
  jne	gs_27
  jmp	gs_10

gs_passkey_done:
  mov	al,0
  jmp	short gs_exit
gs_mouse_exit:
  mov	al,1
gs_exit:
  mov	bx,[char_out]		;restore data at end of string
  mov	edi,[str_end]		;  buffer that was clobbered
  mov	word [edi],bx
  mov	ah,[str_cursor_col]
  ret
;----------------------------------------------
; set str_cursor_row str_cursor_col to click location
;
position_string_cursor:
  mov	al,byte [kbuf + 2]	;get click location
  mov	bh,[ebp +13]		;get left edge
  mov	bl,bh
  add	bl,[ebp + 4]		;compute right edge
psc_loop:
  mov	ah,[str_cursor_col]
  cmp	al,ah
  jb	psc_go_left
  ja	psc_go_right
  jmp	psc_done
psc_go_left:
  cmp	al,bh			;are we at left edge yet
  je	psc_done
  dec	byte [str_cursor_col]
  dec	dword [str_ptr]
  jmp	psc_loop
psc_go_right:
  cmp	al,bl
  je	psc_done
  inc	byte [str_cursor_col]
  inc	dword [str_ptr]
  jmp	psc_loop
psc_done:  
  ret
;----------------------------------------------
;  input:  ebp -> data buffer ptr         +0    (dword)  has zero or preload
;                 max string length       +4    (dword)
;                 color ptr               +8    (dword)
;                 display row             +12   (db)	;str display loc
;                 display column          +13   (db)
display_get_string:
  mov	edi,lib_buf
  mov	esi,[ebp]		;get buffer to display
  mov	ecx,[ebp +4]		;get max string length
;
; build string in lib_buf buffer
;
dgs_10:
  cmp	byte [esi],0		;end of data found
  je	dgs_30			;jmp if at end of preloaded data
  lodsb
  jmp	short dsg_40		;go store data
dgs_30:
  mov	al,' '			;store blank
dsg_40:
  cmp	al,20h
  jb	dsg_42			;jmp if non ascii
  cmp	al,7fh
  jb	dsg_44			;jmp if char normal ascii
dsg_42:
  mov	al,'.'			;substitute "." for char
dsg_44:
  stosb
  dec	ecx
  jnz	dgs_10			;loop till done
  mov	byte [edi],0		;terminate string
;
; display string area
;  
  mov	eax,[ebp +8]		;get color ptr
  mov	eax,[eax]		;get color
  mov	bh,[ebp + 12]		;get row
  mov	bl,[ebp + 13]		;display column
  mov	ecx,lib_buf		;get msg address
  call	crt_color_at		;display message
  ret
;--------------------------------------
read_stderr:
  mov	eax,[tty_fd]
  mov	[poll_tbl],eax
  mov	ecx,kbuf
read_more:
  mov	edx,36			;read 20 keys
  mov	eax,3				;sys_read
  mov	ebx,[tty_fd]			;stdin
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

  mov	word [poll_rtn],0
  mov	eax,168			;poll
  mov	ebx,poll_tbl
  mov	ecx,1			;one structure at poll_tbl
  mov	edx,20			;wait xx ms
  int	byte 80h
  test	byte [poll_rtn],01h
  pop	ecx
  jnz	read_more
;strip any extra data from end
  mov	esi,kbuf
  cmp	byte [esi],1bh
  je	mb_loop
  inc	esi
  jmp	short rm_20
;check for end of escape char
mb_loop:
  inc	esi
  cmp	esi,ecx
  je	rm_20			;jmp if end of char
  cmp	byte [esi],1bh
  jne	mb_loop			;loop till end of escape sequence
rm_20:
  mov	byte [esi],0		;terminate string
rm_exit:
  ret


  [section .data]
delay_struc:
  dd	0	;seconds
  dd	8	;nanoeconds

poll_tbl	dd	2	;stderr
		dw	-1	;events of interest
poll_rtn	dw	-1	;return from poll
  [section .text]



;--------------------------------------
; This  table is used by get_string to decode keys
;  format: 1. first dword = process for normal text
;          2. series of key-strings & process's
;          3. zero - end of key-strings
;          4. dword = process for no previous match
;
key_action_tbl:
  dd	gs_normal_char		;alpha key process
;  db 1bh,5bh,48h,0		; pad_home
;   dd gs_home
;  db 1bh,5bh,44h,0		; pad_left
;   dd gs_left
;  db 1bh,5bh,43h,0		; pad_right
;   dd gs_right
;  db 1bh,5bh,46h,0		; pad_end
;   dd gs_end
  db 1bh,5bh,33h,7eh,0		; pad_del
   dd gs_del
  db 7fh,0			; backspace
   dd gs_backspace
  db 80h,0
   dd gs_backspace
  db 0dh,0			; enter key
   dd gs_enter_key
  db 0		;end of table
  dd gs_passkey_done		;no-match process

 [section .data]

;-----------------------------------------------------------

get_string_flg	db	0	;set each time get_string entered
str_cursor_row	db	0	;current cursor row
str_cursor_col	db	0	;current cursor column
str_term_flg	db	0	;0=(enter key terminates) 1=only esc terminates
str_begin	dd	0	;start of string
str_ptr		dd	0	;current string edit point
str_end		dd	0	;max string ptr

char_out	db	0,0,0

 [section .text]
