;--------------------------------------------------------------
;>1 syscall
; sys_sigpending - kernel function                          
;
;    INPUTS 
;     see AsmRef function -> sys_sigpending                                      
;
;    Note: functon call consists of four instructions
;          
;          sys_sigpending:                                   
;              mov  eax,73     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_sigpending
sys_sigpending:
	mov	eax,73
	int	byte 80h
	or	eax,eax
	ret