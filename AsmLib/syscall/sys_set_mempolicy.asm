;--------------------------------------------------------------
;>1 syscall
; sys_set_mempolicy - kernel function                       
;
;    INPUTS 
;     see AsmRef function -> sys_set_mempolicy                                   
;
;    Note: functon call consists of four instructions
;          
;          sys_set_mempolicy:                                
;              mov  eax,276    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_set_mempolicy
sys_set_mempolicy:
	mov	eax,276
	int	byte 80h
	or	eax,eax
	ret