;--------------------------------------------------------------
;>1 syscall
; sys_sendfile - kernel function                            
;
;    INPUTS 
;     see AsmRef function -> sys_sendfile                                        
;
;    Note: functon call consists of four instructions
;          
;          sys_sendfile:                                     
;              mov  eax,187    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_sendfile
sys_sendfile:
	mov	eax,187
	int	byte 80h
	or	eax,eax
	ret