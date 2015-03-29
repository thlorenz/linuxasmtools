;--------------------------------------------------------------
;>1 syscall
; sys_getdents64 - kernel function                          
;
;    INPUTS 
;     see AsmRef function -> sys_getdents64                                      
;
;    Note: functon call consists of four instructions
;          
;          sys_getdents64:                                   
;              mov  eax,220    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_getdents64
sys_getdents64:
	mov	eax,220
	int	byte 80h
	or	eax,eax
	ret