;--------------------------------------------------------------
;>1 syscall
; sys_fchdir - kernel function                              
;
;    INPUTS 
;     see AsmRef function -> sys_fchdir                                          
;
;    Note: functon call consists of four instructions
;          
;          sys_fchdir:                                       
;              mov  eax,133    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_fchdir
sys_fchdir:
	mov	eax,133
	int	byte 80h
	or	eax,eax
	ret