;--------------------------------------------------------------
;>1 syscall
; sys_mq_open - kernel function                             
;
;    INPUTS 
;     see AsmRef function -> sys_mq_open                                         
;
;    Note: functon call consists of four instructions
;          
;          sys_mq_open:                                      
;              mov  eax,277    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_mq_open
sys_mq_open:
	mov	eax,277
	int	byte 80h
	or	eax,eax
	ret