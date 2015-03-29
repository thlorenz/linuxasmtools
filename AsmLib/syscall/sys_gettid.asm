;--------------------------------------------------------------
;>1 syscall
; sys_gettid - kernel function                              
;
;    INPUTS 
;     see AsmRef function -> sys_gettid                                          
;
;    Note: functon call consists of four instructions
;          
;          sys_gettid:                                       
;              mov  eax,224    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_gettid
sys_gettid:
	mov	eax,224
	int	byte 80h
	or	eax,eax
	ret