;--------------------------------------------------------------
;>1 syscall
; sys_settimeofday - kernel function                        
;
;    INPUTS 
;     see AsmRef function -> sys_settimeofday                                    
;
;    Note: functon call consists of four instructions
;          
;          sys_settimeofday:                                 
;              mov  eax,79     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_settimeofday
sys_settimeofday:
	mov	eax,79
	int	byte 80h
	or	eax,eax
	ret