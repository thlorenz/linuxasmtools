;--------------------------------------------------------------
;>1 syscall
; sys_readlink - kernel function                            
;
;    INPUTS 
;     see AsmRef function -> sys_readlink                                        
;
;    Note: functon call consists of four instructions
;          
;          sys_readlink:                                     
;              mov  eax,85     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_readlink
sys_readlink:
	mov	eax,85
	int	byte 80h
	or	eax,eax
	ret