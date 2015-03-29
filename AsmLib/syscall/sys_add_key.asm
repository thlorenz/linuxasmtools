;--------------------------------------------------------------
;>1 syscall
; sys_add_key - kernel function                             
;
;    INPUTS 
;     see AsmRef function -> sys_add_key                                         
;
;    Note: functon call consists of four instructions
;          
;          sys_add_key:                                      
;              mov  eax,286    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_add_key
sys_add_key:
	mov	eax,286
	int	byte 80h
	or	eax,eax
	ret