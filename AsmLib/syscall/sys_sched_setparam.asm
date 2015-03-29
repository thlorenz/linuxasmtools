;--------------------------------------------------------------
;>1 syscall
; sys_sched_setparam - kernel function                      
;
;    INPUTS 
;     see AsmRef function -> sys_sched_setparam                                  
;
;    Note: functon call consists of four instructions
;          
;          sys_sched_setparam:                               
;              mov  eax,154    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_sched_setparam
sys_sched_setparam:
	mov	eax,154
	int	byte 80h
	or	eax,eax
	ret