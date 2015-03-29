;--------------------------------------------------------------
;>1 syscall
; sys_sigaltstack - kernel function                         
;
;    INPUTS 
;     see AsmRef function -> sys_sigaltstack                                     
;
;    Note: functon call consists of four instructions
;          
;          sys_sigaltstack:                                  
;              mov  eax,186    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_sigaltstack
sys_sigaltstack:
	mov	eax,186
	int	byte 80h
	or	eax,eax
	ret