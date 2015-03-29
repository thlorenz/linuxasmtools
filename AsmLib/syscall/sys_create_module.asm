;--------------------------------------------------------------
;>1 syscall
; sys_create_module - kernel function                       
;
;    INPUTS 
;     see AsmRef function -> sys_create_module                                   
;
;    Note: functon call consists of four instructions
;          
;          sys_create_module:                                
;              mov  eax,127    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_create_module
sys_create_module:
	mov	eax,127
	int	byte 80h
	or	eax,eax
	ret