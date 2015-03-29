;--------------------------------------------------------------
;>1 syscall
; sys_readlinkat - kernel function                          
;
;    INPUTS 
;     see AsmRef function -> sys_readlinkat                                      
;
;    Note: functon call consists of four instructions
;          
;          sys_readlinkat:                                   
;              mov  eax,305    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_readlinkat
sys_readlinkat:
	mov	eax,305
	int	byte 80h
	or	eax,eax
	ret