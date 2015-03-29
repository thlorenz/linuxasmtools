;--------------------------------------------------------------
;>1 syscall
; sys_init_module - kernel function                         
;
;    INPUTS 
;     see AsmRef function -> sys_init_module                                     
;
;    Note: functon call consists of four instructions
;          
;          sys_init_module:                                  
;              mov  eax,128    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_init_module
sys_init_module:
	mov	eax,128
	int	byte 80h
	or	eax,eax
	ret