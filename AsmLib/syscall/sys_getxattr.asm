;--------------------------------------------------------------
;>1 syscall
; sys_getxattr - kernel function                            
;
;    INPUTS 
;     see AsmRef function -> sys_getxattr                                        
;
;    Note: functon call consists of four instructions
;          
;          sys_getxattr:                                     
;              mov  eax,229    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_getxattr
sys_getxattr:
	mov	eax,229
	int	byte 80h
	or	eax,eax
	ret