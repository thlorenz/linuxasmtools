;--------------------------------------------------------------
;>1 syscall
; sys_ptrace - kernel function                              
;
;    INPUTS 
;     see AsmRef function -> sys_ptrace                                          
;
;    Note: functon call consists of four instructions
;          
;          sys_ptrace:                                       
;              mov  eax,26     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_ptrace
sys_ptrace:
	mov	eax,26
	int	byte 80h
	or	eax,eax
	ret