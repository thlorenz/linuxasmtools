;--------------------------------------------------------------
;>1 syscall
; sys_listxattr - kernel function                           
;
;    INPUTS 
;     see AsmRef function -> sys_listxattr                                       
;
;    Note: functon call consists of four instructions
;          
;          sys_listxattr:                                    
;              mov  eax,232    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_listxattr
sys_listxattr:
	mov	eax,232
	int	byte 80h
	or	eax,eax
	ret