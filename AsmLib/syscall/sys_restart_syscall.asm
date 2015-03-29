;--------------------------------------------------------------
;>1 syscall
; sys_restart_syscall - kernel function                     
;
;    INPUTS 
;     see AsmRef function -> sys_restart_syscall                                 
;
;    Note: functon call consists of four instructions
;          
;          sys_restart_syscall:                              
;              mov  eax,0      
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_restart_syscall
sys_restart_syscall:
	mov	eax,0
	int	byte 80h
	or	eax,eax
	ret