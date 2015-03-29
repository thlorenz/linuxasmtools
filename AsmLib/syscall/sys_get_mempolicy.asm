;--------------------------------------------------------------
;>1 syscall
; sys_get_mempolicy - kernel function                       
;
;    INPUTS 
;     see AsmRef function -> sys_get_mempolicy                                   
;
;    Note: functon call consists of four instructions
;          
;          sys_get_mempolicy:                                
;              mov  eax,275    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_get_mempolicy
sys_get_mempolicy:
	mov	eax,275
	int	byte 80h
	or	eax,eax
	ret