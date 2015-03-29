;--------------------------------------------------------------
;>1 syscall
; sys__llseek - kernel function                             
;
;    INPUTS 
;     see AsmRef function -> sys__llseek                                         
;
;    Note: functon call consists of four instructions
;          
;          sys__llseek:                                      
;              mov  eax,140    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys__llseek
sys__llseek:
	mov	eax,140
	int	byte 80h
	or	eax,eax
	ret