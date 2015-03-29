;--------------------------------------------------------------
;>1 syscall
; sys_time - kernel function                                
;
;    INPUTS 
;     see AsmRef function -> sys_time                                            
;
;    Note: functon call consists of four instructions
;          
;          sys_time:                                         
;              mov  eax,13     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_time
sys_time:
	mov	eax,13
	int	byte 80h
	or	eax,eax
	ret