;--------------------------------------------------------------
;>1 syscall
; sys_setfsgid32 - kernel function                          
;
;    INPUTS 
;     see AsmRef function -> sys_setfsgid32                                      
;
;    Note: functon call consists of four instructions
;          
;          sys_setfsgid32:                                   
;              mov  eax,216    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_setfsgid32
sys_setfsgid32:
	mov	eax,216
	int	byte 80h
	or	eax,eax
	ret