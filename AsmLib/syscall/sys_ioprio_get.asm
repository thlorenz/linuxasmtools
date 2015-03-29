;--------------------------------------------------------------
;>1 syscall
; sys_ioprio_get - kernel function                          
;
;    INPUTS 
;     see AsmRef function -> sys_ioprio_get                                      
;
;    Note: functon call consists of four instructions
;          
;          sys_ioprio_get:                                   
;              mov  eax,290    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_ioprio_get
sys_ioprio_get:
	mov	eax,290
	int	byte 80h
	or	eax,eax
	ret