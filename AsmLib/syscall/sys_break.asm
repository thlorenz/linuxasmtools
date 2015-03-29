;--------------------------------------------------------------
;>1 syscall
; sys_break - kernel function                               
;
;    INPUTS 
;     see AsmRef function -> sys_break                                           
;
;    Note: functon call consists of four instructions
;          
;          sys_break:                                        
;              mov  eax,17     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_break
sys_break:
	mov	eax,17
	int	byte 80h
	or	eax,eax
	ret