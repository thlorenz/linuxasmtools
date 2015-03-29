;--------------------------------------------------------------
;>1 syscall
; sys_setregid32 - kernel function                          
;
;    INPUTS 
;     see AsmRef function -> sys_setregid32                                      
;
;    Note: functon call consists of four instructions
;          
;          sys_setregid32:                                   
;              mov  eax,204    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_setregid32
sys_setregid32:
	mov	eax,204
	int	byte 80h
	or	eax,eax
	ret