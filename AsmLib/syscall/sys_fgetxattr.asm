;--------------------------------------------------------------
;>1 syscall
; sys_fgetxattr - kernel function                           
;
;    INPUTS 
;     see AsmRef function -> sys_fgetxattr                                       
;
;    Note: functon call consists of four instructions
;          
;          sys_fgetxattr:                                    
;              mov  eax,231    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_fgetxattr
sys_fgetxattr:
	mov	eax,231
	int	byte 80h
	or	eax,eax
	ret