;--------------------------------------------------------------
;>1 syscall
; sys_ioprio_set - kernel function                          
;
;    INPUTS 
;     see AsmRef function -> sys_ioprio_set                                      
;
;    Note: functon call consists of four instructions
;          
;          sys_ioprio_set:                                   
;              mov  eax,289    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_ioprio_set
sys_ioprio_set:
	mov	eax,289
	int	byte 80h
	or	eax,eax
	ret