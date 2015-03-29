  [section .text align=1]

;---------------------------------------------------
;>1 vt
;  vt_setup - setup for vt window
; INPUTS
;   esi = input block pointer. The block
;         is must be filled in by caller. It
;         is copied to globals as follows:
;
;         vt_rows: dd 0 ;rows in display
;         vt_columns: dd 0 ;columns for display
;         vt_image dd 0 ;ptr to buffer of size
;                (window size) * 2 + 4
;                buffer holds display image, each
;                display char. is one word as follows
;                   bit 15 = color/data changed flag
;                   14-8 = color code
;                   7-0  = char
;         vt_fd: dd 0 set to 0 for /dev/tty, 1 for stdout
;         vt_top_row: dd 0	;window starting row, 0+
;         vt_top_left_col: dd 0	;window starting column, 0+
;         default_color	    db grey_char + black_back
;                  see dcache_colors.inc for color format.
;
; OUTPUT
;   sign flag set for "js" if error
; NOTES
;    source file: vt_setup.asm
;
;    The vt funcitons keep a vt_image of display data and
;    only update the display when vt_flush is called.
;
;    Typically the vt functions are used as follows:
;  call	env_stack
;  call	read_window_size	;needed for vt_flush
;  mov	esi,vt_setup_block      ;defines window
;  call	vt_setup
;  mov	eax,launch_name         ;program to run in window
;  call	vt_ptty_setup           ;setup to run program
;  call	vt_flush                ;clear window
;  call	vt_ptty_launch          ;launch program in window
;  (wait for input on stdin or ptty_fd)
;  (send ptty_fd data to vt_out)
;  (send stdin to ptty_fd)
;  call	vt_flush
;  (loop back to input for more data)
;  (when done, call vt_close)
;
;<
; * ----------------------------------------------
  [section .text align=1]

%include "../include/signal.inc"

  extern sys_open
  extern sys_close
  extern read_winsize_x
  extern output_winsize_x
  extern default_color
  extern vt_rows
  extern vt_columns
  extern open_tty
  extern vt_display_size
  extern vt_fd
  extern vt_clear
  extern ptty_fd
  extern color_byte_expand
  extern crt_str
  extern read_termios_0,output_termios_0
  extern vt_str
  extern vt_image_write_color

in_block_size	equ 25
;termio_struc_size:
  global vt_setup
vt_setup:
  mov	ecx,in_block_size
  mov	edi,vt_rows
  cld
  rep	movsb		;save input parameters
;save termios
  mov	edx,saved_termios
  call	read_termios_0
;compute display size
  mov	eax,[vt_rows]
  mul	dword [vt_columns]
  mov	[vt_display_size],eax

  mov	dh,[vt_fd]
  or	dh,dh
  jnz	ds_size
  call	open_tty
  or	eax,eax
  js	vt_setup_exit
  mov	[vt_fd],ebx	;set new fd
ds_size:
;fill buffers
  mov	al,[default_color]
  mov	[vt_image_write_color],al
  call	vt_clear
;set wrap state
  mov	ecx,wrap_cmd
  call	crt_str
;write default cursor position, out buffer ptrs
  call	winsize_set
  cmp	al,al			;clear sign flag
vt_setup_exit:
  ret
;---------------------------------------------------
  [section .data]
wrap_cmd: db 1bh,'[?7h'   ;no wrap
          db 1bh,'[?1049l' ;normal win
          db 1bh,'[;r'     ;default scroll region
          db 1bh,'(B'     ;char set
          db 0            ;end of list
  [section .text]
;---------------------------------------------------
;>1 vt
;  vt_close - close open vt display
; INPUTS
;   none
; OUTPUT
;   none
; NOTES
;    source file: vt_setup.asm
;
;<
; * ----------------------------------------------
  global vt_close
vt_close:
  mov	ebx,[ptty_fd]
  call	sys_close
  call	winsize_restore
  mov	ebx,[vt_fd]
  cmp	ebx,2
  jbe	vc_10		;jmp if stdout,stderr
  call	sys_close
vc_10:
  mov	edx,saved_termios
  call	output_termios_0
  mov	ecx,reset_strings
  call	vt_str
  ret

;-------------
  [section .data]
reset_strings: db 1bh,"[m" ;default color
  db 1bh,"[?7l" ;no wrap
  db 1bh,"[?1049l"  ;normal window
  db 0

;----------------------------------------------------
;input vt_rows=rows vt_columns

winsize_set:
  
  mov	ebx,[vt_fd]
  mov	edx,savwin
  call	read_winsize_x

  call	winch_block

  mov	ah,[vt_rows]
  mov	al,[vt_columns]
  mov	[setwin],ah
  mov	[set_col],al
  mov	edx,setwin
  mov	ebx,[vt_fd]
  call	output_winsize_x

  call	winch_restore
  ret

;----------------
  [section .data]
;    struc wnsize_struc
;    .ws_row:resw 1
;    .ws_col:resw 1
;    .ws_xpixel:resw 1
;    .ws_ypixel:resw 1
;    endstruc
setwin:	dw 0	;rows
set_col:dw 0	;columns
        dw 0
        dw 0

savwin: dw 0	;rows
        dw 0	;columns
        dw 0
        dw 0

  [section .text]
;----------------------------------------------------
winsize_restore:
  call	winch_block
  mov	ebx,[vt_fd]
  mov	edx,savwin
  call	output_winsize_x
  call	winch_restore
  ret
;----------------------------------------------------
winch_block:
  mov	ebx,SIGWINCH
  mov	ecx,sa_handler
  mov	eax,67		;sigaction
  mov	edx,sa_save	;save of previous state
  int	byte 80h
  ret
;----------------------------------------------------
winch_restore:
  mov	ebx,SIGWINCH
  mov	ecx,sa_save
  mov	eax,67		;sigaction
  xor	edx,edx
  int	byte 80h
  ret
  

;----------------
  [section .data]
;If we set SA_RESTART then, interrupted system calls
;do not fail and return -4 (interrupted call error).
sa_handler  dd 1	;handler or SIG_DFL(0) or SIG_IGN(1)
sa_mask     dd -1 	;signals to block while handler executes
sa_flags    dd  0x10000004 ; SA_RESTART,;SA_SIGINFO=4
sa_restoref dd 0  	;(unused)

sa_save     dd 0	;handler or SIG_DFL(0) or SIG_IGN(1)
 dd 0 	;signals to block while handler executes
 dd 0        ; SA_RESTART,;SA_SIGINFO=4
 dd 0  	;(unused)

saved_termios times 36 db 0


  [section .text]

