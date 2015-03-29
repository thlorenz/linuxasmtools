;--------------------------------------------------------------
;>1 syscall
; sys_sysinfo - kernel function                             
;
;    INPUTS 
;     see AsmRef function -> sys_sysinfo                                         
;
;    Note: functon call consists of four instructions
;          
;          sys_sysinfo:                                      
;              mov  eax,116    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_sysinfo
sys_sysinfo:
	mov	eax,116
	int	byte 80h
	or	eax,eax
	ret