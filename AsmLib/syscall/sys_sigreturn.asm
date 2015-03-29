;--------------------------------------------------------------
;>1 syscall
; sys_sigreturn - kernel function                           
;
;    INPUTS 
;     see AsmRef function -> sys_sigreturn                                       
;
;    Note: functon call consists of four instructions
;          
;          sys_sigreturn:                                    
;              mov  eax,119    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_sigreturn
sys_sigreturn:
	mov	eax,119
	int	byte 80h
	or	eax,eax
	ret