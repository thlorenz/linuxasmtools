;--------------------------------------------------------------
;>1 syscall
; sys_delete_module - kernel function                       
;
;    INPUTS 
;     see AsmRef function -> sys_delete_module                                   
;
;    Note: functon call consists of four instructions
;          
;          sys_delete_module:                                
;              mov  eax,129    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_delete_module
sys_delete_module:
	mov	eax,129
	int	byte 80h
	or	eax,eax
	ret