;--------------------------------------------------------------
;>1 syscall
; sys_lstat64 - kernel function                             
;
;    INPUTS 
;     see AsmRef function -> sys_lstat64                                         
;
;    Note: functon call consists of four instructions
;          
;          sys_lstat64:                                      
;              mov  eax,196    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_lstat64
sys_lstat64:
	mov	eax,196
	int	byte 80h
	or	eax,eax
	ret