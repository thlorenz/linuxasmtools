;--------------------------------------------------------------
;>1 syscall
; sys_sigprocmask - kernel function                         
;
;    INPUTS 
;     see AsmRef function -> sys_sigprocmask                                     
;
;    Note: functon call consists of four instructions
;          
;          sys_sigprocmask:                                  
;              mov  eax,126    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_sigprocmask
sys_sigprocmask:
	mov	eax,126
	int	byte 80h
	or	eax,eax
	ret