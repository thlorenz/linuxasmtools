;--------------------------------------------------------------
;>1 syscall
; sys_mpx - kernel function                                 
;
;    INPUTS 
;     see AsmRef function -> sys_mpx                                             
;
;    Note: functon call consists of four instructions
;          
;          sys_mpx:                                          
;              mov  eax,56     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_mpx
sys_mpx:
	mov	eax,56
	int	byte 80h
	or	eax,eax
	ret