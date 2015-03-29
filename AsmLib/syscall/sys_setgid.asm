;--------------------------------------------------------------
;>1 syscall
; sys_setgid - kernel function                              
;
;    INPUTS 
;     see AsmRef function -> sys_setgid                                          
;
;    Note: functon call consists of four instructions
;          
;          sys_setgid:                                       
;              mov  eax,46     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_setgid
sys_setgid:
	mov	eax,46
	int	byte 80h
	or	eax,eax
	ret