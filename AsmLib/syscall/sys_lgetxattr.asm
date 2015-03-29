;--------------------------------------------------------------
;>1 syscall
; sys_lgetxattr - kernel function                           
;
;    INPUTS 
;     see AsmRef function -> sys_lgetxattr                                       
;
;    Note: functon call consists of four instructions
;          
;          sys_lgetxattr:                                    
;              mov  eax,230    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_lgetxattr
sys_lgetxattr:
	mov	eax,230
	int	byte 80h
	or	eax,eax
	ret