;--------------------------------------------------------------
;>1 syscall
; sys_pipe - kernel function                                
;
;    INPUTS 
;     see AsmRef function -> sys_pipe                                            
;
;    Note: functon call consists of four instructions
;          
;          sys_pipe:                                         
;              mov  eax,42     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_pipe
sys_pipe:
	mov	eax,42
	int	byte 80h
	or	eax,eax
	ret