;--------------------------------------------------------------
;>1 syscall
; sys_nice - kernel function                                
;
;    INPUTS 
;     see AsmRef function -> sys_nice                                            
;
;    Note: functon call consists of four instructions
;          
;          sys_nice:                                         
;              mov  eax,34     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_nice
sys_nice:
	mov	eax,34
	int	byte 80h
	or	eax,eax
	ret