;--------------------------------------------------------------
;>1 syscall
; sys_getpriority - kernel function                         
;
;    INPUTS 
;     see AsmRef function -> sys_getpriority                                     
;
;    Note: functon call consists of four instructions
;          
;          sys_getpriority:                                  
;              mov  eax,96     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_getpriority
sys_getpriority:
	mov	eax,96
	int	byte 80h
	or	eax,eax
	ret