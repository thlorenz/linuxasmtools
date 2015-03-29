;--------------------------------------------------------------
;>1 syscall
; sys_setrlimit - kernel function                           
;
;    INPUTS 
;     see AsmRef function -> sys_setrlimit                                       
;
;    Note: functon call consists of four instructions
;          
;          sys_setrlimit:                                    
;              mov  eax,75     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_setrlimit
sys_setrlimit:
	mov	eax,75
	int	byte 80h
	or	eax,eax
	ret