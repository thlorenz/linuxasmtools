;--------------------------------------------------------------
;>1 syscall
; sys_socketcall - kernel function                          
;
;    INPUTS 
;     see AsmRef function -> sys_socketcall                                      
;
;    Note: functon call consists of four instructions
;          
;          sys_socketcall:                                   
;              mov  eax,102    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_socketcall
sys_socketcall:
	mov	eax,102
	int	byte 80h
	or	eax,eax
	ret