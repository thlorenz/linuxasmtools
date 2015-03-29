;--------------------------------------------------------------
;>1 syscall
; sys_truncate64 - kernel function                          
;
;    INPUTS 
;     see AsmRef function -> sys_truncate64                                      
;
;    Note: functon call consists of four instructions
;          
;          sys_truncate64:                                   
;              mov  eax,193    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_truncate64
sys_truncate64:
	mov	eax,193
	int	byte 80h
	or	eax,eax
	ret