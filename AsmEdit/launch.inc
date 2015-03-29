;--------------------------------------------------------------------
;****f* sys/sys_ex *
; NAME
;>1 sys
;  sys_ex - call execve kernel function  
; INPUTS
;    [enviro_ptrs] - global var set by function env_stack
;    esi = ptr to input string
;          string byte 1 = separator character
;          string byte 2+ = full path ending with separator
;          string next    = first parameter ending with separator
;          etc.         (last parameter ends with zero)
;    example:  db "|/bin/name|parameter1|parameter2",0
; OUTPUT
;    al = byte two of execve_status
;    [execve_status] - contains results from execve
;      al = 0 success
;      al = 11 could not launch child
;      al = negative (system error code)
;      flags set for jz,js,jnz,jns jumps
;    note: input string modified by replacing separator
;          characters with value of zero, thus, string
;          must be writable.
; NOTES
;   source file: sys_ex.asm
;<
; * ----------------------------------------------
;*******
;;  extern enviro_ptrs
  global sys_ex
sys_ex:
  mov	edi,exc_args		;parameter ptrs build area
  lodsb		;get separator
  mov	dl,al	;save separator
  mov	[execve_full_path],esi	;ptr to full path
; scan to end of full path
ee_lp1:
  lodsb
  or	al,al			;check if end of parameters
  je	ee_20			;jmp if end of parameters
  cmp	al,dl
  jne	ee_lp1	;loop till end of full path
;
  mov	byte [esi-1],0		;terminate full path
  mov	[edi],esi		;store ptr to parameter
  add	edi,4
  jmp	ee_lp1			;go do next parameter
; terminate parameter ptr array
ee_20:
  mov	dword [edi],0
;
; fork our program into two parts
;  returns:  eax = zero to child, pid to parent or negative error
;
  mov	eax,2
  int	80h		;fork
  mov	ebx,eax		;save PID
  or	eax,eax		;check if we are child process
  jnz	parent		;jmp if parent
;
; kick off the requested program
;
child_process:
  mov	ebx,[execve_full_path]
;  mov	ecx,exc_args
  mov	ecx,execve_full_path
  mov	edx,[enviro_ptrs]
  mov	eax,11		;execve
  int	80h
;
; if we get here all attempts to execute a program failed
;
  mov	ebx,11h			;no child process
  mov	eax,1
  int	80h			;abort out
;
; wait for external program to complete
;  input: ebx = process id to wait for
;  returns: eax = id of job exiting, or negative error
;
parent:
  mov	ecx,execve_status
  xor	edx,edx
  mov	eax,7
  int	80h			;wait for child, PID in ebx
  mov	al,byte [execve_status +1]
  or	al,al
  ret
;--------------------------------------------
 [section .data]

execve_full_path:	dd	0

exc_args:		dd	0	;ptr to executable name
			dd	0	;ptr to parameter1
			dd	0	;ptr to parameter2
			dd	0	;ptr to parameter3
			dd	0,0,0,0	;additional parameters

execve_status		db	0,0,0,0,0,0,0,0

;--------------------------------------------------------------------