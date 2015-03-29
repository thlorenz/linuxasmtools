;--------------------------------------------------------------
;>1 syscall
; sys_madvise1 - kernel function                            
;
;    INPUTS 
;     see AsmRef function -> sys_madvise1                                        
;
;    Note: functon call consists of four instructions
;          
;          sys_madvise1:                                     
;              mov  eax,219    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_madvise1
sys_madvise1:
	mov	eax,219
	int	byte 80h
	or	eax,eax
	ret