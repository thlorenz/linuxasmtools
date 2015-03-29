;--------------------------------------------------------------
;>1 syscall
; sys_symlinkat - kernel function                           
;
;    INPUTS 
;     see AsmRef function -> sys_symlinkat                                       
;
;    Note: functon call consists of four instructions
;          
;          sys_symlinkat:                                    
;              mov  eax,304    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_symlinkat
sys_symlinkat:
	mov	eax,304
	int	byte 80h
	or	eax,eax
	ret