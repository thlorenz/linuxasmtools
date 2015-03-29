;--------------------------------------------------------------
;>1 syscall
; sys_getpid - kernel function                              
;
;    INPUTS 
;     see AsmRef function -> sys_getpid                                          
;
;    Note: functon call consists of four instructions
;          
;          sys_getpid:                                       
;              mov  eax,20     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_getpid
sys_getpid:
	mov	eax,20
	int	byte 80h
	or	eax,eax
	ret