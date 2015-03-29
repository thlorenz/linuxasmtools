;--------------------------------------------------------------
;>1 syscall
; sys_setuid - kernel function                              
;
;    INPUTS 
;     see AsmRef function -> sys_setuid                                          
;
;    Note: functon call consists of four instructions
;          
;          sys_setuid:                                       
;              mov  eax,23     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_setuid
sys_setuid:
	mov	eax,23
	int	byte 80h
	or	eax,eax
	ret