;--------------------------------------------------------------
;>1 syscall
; sys_poll - kernel function                                
;
;    INPUTS 
;     see AsmRef function -> sys_poll                                            
;
;    Note: functon call consists of four instructions
;          
;          sys_poll:                                         
;              mov  eax,168    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_poll
sys_poll:
	mov	eax,168
	int	byte 80h
	or	eax,eax
	ret