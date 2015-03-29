;--------------------------------------------------------------
;>1 syscall
; sys_execve - kernel function                              
;
;    INPUTS 
;     see AsmRef function -> sys_execve                                          
;
;    Note: functon call consists of four instructions
;          
;          sys_execve:                                       
;              mov  eax,11     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_execve
sys_execve:
	mov	eax,11
	int	byte 80h
	or	eax,eax
	ret