;--------------------------------------------------------------
;>1 syscall
; sys_set_thread_area - kernel function                     
;
;    INPUTS 
;     see AsmRef function -> sys_set_thread_area                                 
;
;    Note: functon call consists of four instructions
;          
;          sys_set_thread_area:                              
;              mov  eax,243    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_set_thread_area
sys_set_thread_area:
	mov	eax,243
	int	byte 80h
	or	eax,eax
	ret