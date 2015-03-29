;--------------------------------------------------------------
;>1 syscall
; sys_lsetxattr - kernel function                           
;
;    INPUTS 
;     see AsmRef function -> sys_lsetxattr                                       
;
;    Note: functon call consists of four instructions
;          
;          sys_lsetxattr:                                    
;              mov  eax,227    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_lsetxattr
sys_lsetxattr:
	mov	eax,227
	int	byte 80h
	or	eax,eax
	ret