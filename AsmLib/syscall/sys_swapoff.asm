;--------------------------------------------------------------
;>1 syscall
; sys_swapoff - kernel function                             
;
;    INPUTS 
;     see AsmRef function -> sys_swapoff                                         
;
;    Note: functon call consists of four instructions
;          
;          sys_swapoff:                                      
;              mov  eax,115    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_swapoff
sys_swapoff:
	mov	eax,115
	int	byte 80h
	or	eax,eax
	ret