;--------------------------------------------------------------
;>1 syscall
; sys_ugetrlimit - kernel function                          
;
;    INPUTS 
;     see AsmRef function -> sys_ugetrlimit                                      
;
;    Note: functon call consists of four instructions
;          
;          sys_ugetrlimit:                                   
;              mov  eax,191    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_ugetrlimit
sys_ugetrlimit:
	mov	eax,191
	int	byte 80h
	or	eax,eax
	ret