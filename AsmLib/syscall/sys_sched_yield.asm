;--------------------------------------------------------------
;>1 syscall
; sys_sched_yield - kernel function                         
;
;    INPUTS 
;     see AsmRef function -> sys_sched_yield                                     
;
;    Note: functon call consists of four instructions
;          
;          sys_sched_yield:                                  
;              mov  eax,158    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_sched_yield
sys_sched_yield:
	mov	eax,158
	int	byte 80h
	or	eax,eax
	ret