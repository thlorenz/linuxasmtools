;--------------------------------------------------------------
;>1 syscall
; sys_eventfd - kernel function                             
;
;    INPUTS 
;     see AsmRef function -> sys_eventfd                                         
;
;    Note: functon call consists of four instructions
;          
;          sys_eventfd:                                      
;              mov  eax,323    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_eventfd
sys_eventfd:
	mov	eax,323
	int	byte 80h
	or	eax,eax
	ret