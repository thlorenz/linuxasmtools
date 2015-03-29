;
; this is a modified version to ignore scroll and let crt line handle it.
; 
;;  extern crt_line
;---------------------------------------------
;****f* crt/crt_win_from_ptrs *
; NAME
;>1 crt
;  crt_win_from_ptrs - display window using ptrs to lines
; INPUTS
;    ebx = ptr to color table
;    ch  = starting row
;    cl  = starting col
;    dl = number of cols
;    dh = number of rows
;    ebp = ptr to list of line ptrs
;    edi = adjustment to pointers in pointer list (ebp).
;          negative number ok, display starts at [ptr + edi]       
;    each line terminated with 0ah or 0
;    codes 1-9 found in line are color info.
; OUTPUT
;
; NOTES
;   source file: crt_ptr_window.asm
;<
; * ----------------------------------------------
;*******
  global crt_win_from_ptrs
crt_win_from_ptrs:
swfp_lp:
  mov	esi,[ebp]	;get ptr to next line
  or	esi,esi		;check if end of table
  jnz	swfp_10		;jmp if line ok
  mov	esi,swfp_blank
  sub	ebp,4		;move to prev line
  jmp	short swfp_20
swfp_10:
;  add	esi,edi		;move to desired column
swfp_20:
  push	edi
  push	ecx
  push	edx
  push	ebx
  call	crt_line
  pop	ebx
  pop	edx
  pop	ecx
  pop	edi
  inc	ch		;move to next row
  add	ebp,4		;move to next line
  dec	dh
  jnz	swfp_lp		;loop till done
  ret

swfp_blank:  db ' ',0ah

