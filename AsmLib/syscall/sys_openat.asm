;--------------------------------------------------------------
;>1 syscall
; sys_openat - kernel function                              
;
;    INPUTS 
;     see AsmRef function -> sys_openat                                          
;
;    Note: functon call consists of four instructions
;          
;          sys_openat:                                       
;              mov  eax,295    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_openat
sys_openat:
	mov	eax,295
	int	byte 80h
	or	eax,eax
	ret