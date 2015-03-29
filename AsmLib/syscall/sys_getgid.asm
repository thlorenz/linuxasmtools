;--------------------------------------------------------------
;>1 syscall
; sys_getgid - kernel function                              
;
;    INPUTS 
;     see AsmRef function -> sys_getgid                                          
;
;    Note: functon call consists of four instructions
;          
;          sys_getgid:                                       
;              mov  eax,47     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_getgid
sys_getgid:
	mov	eax,47
	int	byte 80h
	or	eax,eax
	ret