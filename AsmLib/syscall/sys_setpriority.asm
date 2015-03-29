;--------------------------------------------------------------
;>1 syscall
; sys_setpriority - kernel function                         
;
;    INPUTS 
;     see AsmRef function -> sys_setpriority                                     
;
;    Note: functon call consists of four instructions
;          
;          sys_setpriority:                                  
;              mov  eax,97     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_setpriority
sys_setpriority:
	mov	eax,97
	int	byte 80h
	or	eax,eax
	ret