;--------------------------------------------------------------
;>1 syscall
; sys_quotactl - kernel function                            
;
;    INPUTS 
;     see AsmRef function -> sys_quotactl                                        
;
;    Note: functon call consists of four instructions
;          
;          sys_quotactl:                                     
;              mov  eax,131    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_quotactl
sys_quotactl:
	mov	eax,131
	int	byte 80h
	or	eax,eax
	ret