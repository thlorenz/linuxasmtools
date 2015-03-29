;--------------------------------------------------------------
;>1 syscall
; sys_getpmsg - kernel function                             
;
;    INPUTS 
;     see AsmRef function -> sys_getpmsg                                         
;
;    Note: functon call consists of four instructions
;          
;          sys_getpmsg:                                      
;              mov  eax,188    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_getpmsg
sys_getpmsg:
	mov	eax,188
	int	byte 80h
	or	eax,eax
	ret