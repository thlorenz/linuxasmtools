;--------------------------------------------------------------
;>1 syscall
; sys_getrlimit - kernel function                           
;
;    INPUTS 
;     see AsmRef function -> sys_getrlimit                                       
;
;    Note: functon call consists of four instructions
;          
;          sys_getrlimit:                                    
;              mov  eax,76     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_getrlimit
sys_getrlimit:
	mov	eax,76
	int	byte 80h
	or	eax,eax
	ret