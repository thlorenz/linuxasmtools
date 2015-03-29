;--------------------------------------------------------------
;>1 syscall
; sys_flistxattr - kernel function                          
;
;    INPUTS 
;     see AsmRef function -> sys_flistxattr                                      
;
;    Note: functon call consists of four instructions
;          
;          sys_flistxattr:                                   
;              mov  eax,234    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_flistxattr
sys_flistxattr:
	mov	eax,234
	int	byte 80h
	or	eax,eax
	ret