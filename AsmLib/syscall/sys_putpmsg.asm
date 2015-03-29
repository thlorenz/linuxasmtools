;--------------------------------------------------------------
;>1 syscall
; sys_putpmsg - kernel function                             
;
;    INPUTS 
;     see AsmRef function -> sys_putpmsg                                         
;
;    Note: functon call consists of four instructions
;          
;          sys_putpmsg:                                      
;              mov  eax,189    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_putpmsg
sys_putpmsg:
	mov	eax,189
	int	byte 80h
	or	eax,eax
	ret