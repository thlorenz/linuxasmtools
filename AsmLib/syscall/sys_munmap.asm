;--------------------------------------------------------------
;>1 syscall
; sys_munmap - kernel function                              
;
;    INPUTS 
;     see AsmRef function -> sys_munmap                                          
;
;    Note: functon call consists of four instructions
;          
;          sys_munmap:                                       
;              mov  eax,91     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_munmap
sys_munmap:
	mov	eax,91
	int	byte 80h
	or	eax,eax
	ret