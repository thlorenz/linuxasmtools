;
; put 0ah in log file
; call with:  logeol
%macro logeol 0
  extern log_eol
  call	log_eol
%endmacro

;
; display text message with 0ah at end
; call with:  say "hello world"
%macro say 1
  [section .data]
  %%str: db %1
  db 0ah
  %%str_end:
  [section .text]
;----
  mov	eax,4
  xor	ebx,ebx
  mov	ecx,%%str
  mov	edx,%%str_end - %%str
  int	byte 80h
%endmacro

;
; put string in log file
; call with:  logstr "hello world"
%macro logstr 1
  [section .data]
  %%str: db %1
         db 0
  [section .text]
;----
  extern log_str
  push	esi
  mov	esi,%%str	;data to write
  call	log_str
  pop	esi

%endmacro

;
; put hex value of number in log file
; call with: logmem [label]
%macro logmem 1
  extern log_hex
  push	eax
  mov	eax,%1
  call	log_hex
  pop	eax
;-----------
%endmacro

; put hex value of eax in log file
; call with: logeax
%macro logeax 0
  extern log_hex
  call	log_hex
;-----------
%endmacro

