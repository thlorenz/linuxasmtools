;--------------------------------------------------------------
;>1 syscall
; sys_llistxattr - kernel function                          
;
;    INPUTS 
;     see AsmRef function -> sys_llistxattr                                      
;
;    Note: functon call consists of four instructions
;          
;          sys_llistxattr:                                   
;              mov  eax,233    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_llistxattr
sys_llistxattr:
	mov	eax,233
	int	byte 80h
	or	eax,eax
	ret