;--------------------------------------------------------------
;>1 syscall
; sys_syslog - kernel function                              
;
;    INPUTS 
;     see AsmRef function -> sys_syslog                                          
;
;    Note: functon call consists of four instructions
;          
;          sys_syslog:                                       
;              mov  eax,103    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_syslog
sys_syslog:
	mov	eax,103
	int	byte 80h
	or	eax,eax
	ret