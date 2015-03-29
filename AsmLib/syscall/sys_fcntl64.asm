;--------------------------------------------------------------
;>1 syscall
; sys_fcntl64 - kernel function                             
;
;    INPUTS 
;     see AsmRef function -> sys_fcntl64                                         
;
;    Note: functon call consists of four instructions
;          
;          sys_fcntl64:                                      
;              mov  eax,221    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_fcntl64
sys_fcntl64:
	mov	eax,221
	int	byte 80h
	or	eax,eax
	ret