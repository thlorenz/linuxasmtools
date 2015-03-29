;--------------------------------------------------------------
;>1 syscall
; sys_capset - kernel function                              
;
;    INPUTS 
;     see AsmRef function -> sys_capset                                          
;
;    Note: functon call consists of four instructions
;          
;          sys_capset:                                       
;              mov  eax,185    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_capset
sys_capset:
	mov	eax,185
	int	byte 80h
	or	eax,eax
	ret