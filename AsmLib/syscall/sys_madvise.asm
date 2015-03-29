;--------------------------------------------------------------
;>1 syscall
; sys_madvise - kernel function                             
;
;    INPUTS 
;     see AsmRef function -> sys_madvise                                         
;
;    Note: functon call consists of four instructions
;          
;          sys_madvise:                                      
;              mov  eax,219    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_madvise
sys_madvise:
	mov	eax,219
	int	byte 80h
	or	eax,eax
	ret