;--------------------------------------------------------------
;>1 syscall
; sys_sysfs - kernel function                               
;
;    INPUTS 
;     see AsmRef function -> sys_sysfs                                           
;
;    Note: functon call consists of four instructions
;          
;          sys_sysfs:                                        
;              mov  eax,135    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_sysfs
sys_sysfs:
	mov	eax,135
	int	byte 80h
	or	eax,eax
	ret