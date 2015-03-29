;--------------------------------------------------------------
;>1 syscall
; sys_stat64 - kernel function                              
;
;    INPUTS 
;     see AsmRef function -> sys_stat64                                          
;
;    Note: functon call consists of four instructions
;          
;          sys_stat64:                                       
;              mov  eax,195    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_stat64
sys_stat64:
	mov	eax,195
	int	byte 80h
	or	eax,eax
	ret