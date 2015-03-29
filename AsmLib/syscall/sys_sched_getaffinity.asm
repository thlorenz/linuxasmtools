;--------------------------------------------------------------
;>1 syscall
; sys_sched_getaffinity - kernel function                   
;
;    INPUTS 
;     see AsmRef function -> sys_sched_getaffinity                               
;
;    Note: functon call consists of four instructions
;          
;          sys_sched_getaffinity:                            
;              mov  eax,242    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_sched_getaffinity
sys_sched_getaffinity:
	mov	eax,242
	int	byte 80h
	or	eax,eax
	ret