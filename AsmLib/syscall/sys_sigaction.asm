;--------------------------------------------------------------
;>1 syscall
; sys_sigaction - kernel function                           
;
;    INPUTS 
;     see AsmRef function -> sys_sigaction                                       
;
;    Note: functon call consists of four instructions
;          
;          sys_sigaction:                                    
;              mov  eax,67     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_sigaction
sys_sigaction:
	mov	eax,67
	int	byte 80h
	or	eax,eax
	ret