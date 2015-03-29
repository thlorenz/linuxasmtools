;--------------------------------------------------------------
;>1 syscall
; sys_unshare - kernel function                             
;
;    INPUTS 
;     see AsmRef function -> sys_unshare                                         
;
;    Note: functon call consists of four instructions
;          
;          sys_unshare:                                      
;              mov  eax,310    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_unshare
sys_unshare:
	mov	eax,310
	int	byte 80h
	or	eax,eax
	ret