;--------------------------------------------------------------
;>1 syscall
; sys_fsetxattr - kernel function                           
;
;    INPUTS 
;     see AsmRef function -> sys_fsetxattr                                       
;
;    Note: functon call consists of four instructions
;          
;          sys_fsetxattr:                                    
;              mov  eax,228    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_fsetxattr
sys_fsetxattr:
	mov	eax,228
	int	byte 80h
	or	eax,eax
	ret