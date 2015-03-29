;--------------------------------------------------------------
;>1 syscall
; sys_exit_group - kernel function                          
;
;    INPUTS 
;     see AsmRef function -> sys_exit_group                                      
;
;    Note: functon call consists of four instructions
;          
;          sys_exit_group:                                   
;              mov  eax,252    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_exit_group
sys_exit_group:
	mov	eax,252
	int	byte 80h
	or	eax,eax
	ret