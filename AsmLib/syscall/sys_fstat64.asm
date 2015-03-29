;--------------------------------------------------------------
;>1 syscall
; sys_fstat64 - kernel function                             
;
;    INPUTS 
;     see AsmRef function -> sys_fstat64                                         
;
;    Note: functon call consists of four instructions
;          
;          sys_fstat64:                                      
;              mov  eax,197    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_fstat64
sys_fstat64:
	mov	eax,197
	int	byte 80h
	or	eax,eax
	ret