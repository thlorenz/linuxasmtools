;--------------------------------------------------------------
;>1 syscall
; sys_lremovexattr - kernel function                        
;
;    INPUTS 
;     see AsmRef function -> sys_lremovexattr                                    
;
;    Note: functon call consists of four instructions
;          
;          sys_lremovexattr:                                 
;              mov  eax,236    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_lremovexattr
sys_lremovexattr:
	mov	eax,236
	int	byte 80h
	or	eax,eax
	ret