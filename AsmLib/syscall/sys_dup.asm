;--------------------------------------------------------------
;>1 syscall
; sys_dup - kernel function                                 
;
;    INPUTS 
;     see AsmRef function -> sys_dup                                             
;
;    Note: functon call consists of four instructions
;          
;          sys_dup:                                          
;              mov  eax,41     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_dup
sys_dup:
	mov	eax,41
	int	byte 80h
	or	eax,eax
	ret