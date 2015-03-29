;--------------------------------------------------------------
;>1 syscall
; sys_open - kernel function                                
;
;    INPUTS 
;     see AsmRef function -> sys_open                                            
;
;    Note: functon call consists of four instructions
;          
;          sys_open:                                         
;              mov  eax,5      
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_open
sys_open:
	mov	eax,5
	int	byte 80h
	or	eax,eax
	ret