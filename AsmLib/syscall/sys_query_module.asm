;--------------------------------------------------------------
;>1 syscall
; sys_query_module - kernel function                        
;
;    INPUTS 
;     see AsmRef function -> sys_query_module                                    
;
;    Note: functon call consists of four instructions
;          
;          sys_query_module:                                 
;              mov  eax,167    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_query_module
sys_query_module:
	mov	eax,167
	int	byte 80h
	or	eax,eax
	ret