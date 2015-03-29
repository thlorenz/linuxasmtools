;--------------------------------------------------------------
;>1 syscall
; sys_futex - kernel function                               
;
;    INPUTS 
;     see AsmRef function -> sys_futex                                           
;
;    Note: functon call consists of four instructions
;          
;          sys_futex:                                        
;              mov  eax,240    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_futex
sys_futex:
	mov	eax,240
	int	byte 80h
	or	eax,eax
	ret