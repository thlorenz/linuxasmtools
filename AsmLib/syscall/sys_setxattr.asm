;--------------------------------------------------------------
;>1 syscall
; sys_setxattr - kernel function                            
;
;    INPUTS 
;     see AsmRef function -> sys_setxattr                                        
;
;    Note: functon call consists of four instructions
;          
;          sys_setxattr:                                     
;              mov  eax,226    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_setxattr
sys_setxattr:
	mov	eax,226
	int	byte 80h
	or	eax,eax
	ret