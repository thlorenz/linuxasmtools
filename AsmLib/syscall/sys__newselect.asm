;--------------------------------------------------------------
;>1 syscall
; sys__newselect - kernel function                          
;
;    INPUTS 
;     see AsmRef function -> sys__newselect                                      
;
;    Note: functon call consists of four instructions
;          
;          sys__newselect:                                   
;              mov  eax,142    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys__newselect
sys__newselect:
	mov	eax,142
	int	byte 80h
	or	eax,eax
	ret