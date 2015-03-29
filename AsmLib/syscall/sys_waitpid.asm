;--------------------------------------------------------------
;>1 syscall
; sys_waitpid - kernel function                             
;
;    INPUTS 
;     see AsmRef function -> sys_waitpid                                         
;
;    Note: functon call consists of four instructions
;          
;          sys_waitpid:                                      
;              mov  eax,7      
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_waitpid
sys_waitpid:
	mov	eax,7
	int	byte 80h
	or	eax,eax
	ret