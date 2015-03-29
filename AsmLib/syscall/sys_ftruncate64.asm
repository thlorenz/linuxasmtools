;--------------------------------------------------------------
;>1 syscall
; sys_ftruncate64 - kernel function                         
;
;    INPUTS 
;     see AsmRef function -> sys_ftruncate64                                     
;
;    Note: functon call consists of four instructions
;          
;          sys_ftruncate64:                                  
;              mov  eax,194    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_ftruncate64
sys_ftruncate64:
	mov	eax,194
	int	byte 80h
	or	eax,eax
	ret