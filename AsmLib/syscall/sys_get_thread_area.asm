;--------------------------------------------------------------
;>1 syscall
; sys_get_thread_area - kernel function                     
;
;    INPUTS 
;     see AsmRef function -> sys_get_thread_area                                 
;
;    Note: functon call consists of four instructions
;          
;          sys_get_thread_area:                              
;              mov  eax,244    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_get_thread_area
sys_get_thread_area:
	mov	eax,244
	int	byte 80h
	or	eax,eax
	ret