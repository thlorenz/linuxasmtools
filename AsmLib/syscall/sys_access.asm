;--------------------------------------------------------------
;>1 syscall
; sys_access - kernel function                              
;
;    INPUTS 
;     see AsmRef function -> sys_access                                          
;
;    Note: functon call consists of four instructions
;          
;          sys_access:                                       
;              mov  eax,33     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_access
sys_access:
	mov	eax,33
	int	byte 80h
	or	eax,eax
	ret