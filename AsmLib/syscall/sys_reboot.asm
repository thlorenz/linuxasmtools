;--------------------------------------------------------------
;>1 syscall
; sys_reboot - kernel function                              
;
;    INPUTS 
;     see AsmRef function -> sys_reboot                                          
;
;    Note: functon call consists of four instructions
;          
;          sys_reboot:                                       
;              mov  eax,88     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_reboot
sys_reboot:
	mov	eax,88
	int	byte 80h
	or	eax,eax
	ret