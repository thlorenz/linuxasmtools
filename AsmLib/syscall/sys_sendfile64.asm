;--------------------------------------------------------------
;>1 syscall
; sys_sendfile64 - kernel function                          
;
;    INPUTS 
;     see AsmRef function -> sys_sendfile64                                      
;
;    Note: functon call consists of four instructions
;          
;          sys_sendfile64:                                   
;              mov  eax,239    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_sendfile64
sys_sendfile64:
	mov	eax,239
	int	byte 80h
	or	eax,eax
	ret