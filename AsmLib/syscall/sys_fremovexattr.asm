;--------------------------------------------------------------
;>1 syscall
; sys_fremovexattr - kernel function                        
;
;    INPUTS 
;     see AsmRef function -> sys_fremovexattr                                    
;
;    Note: functon call consists of four instructions
;          
;          sys_fremovexattr:                                 
;              mov  eax,237    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_fremovexattr
sys_fremovexattr:
	mov	eax,237
	int	byte 80h
	or	eax,eax
	ret