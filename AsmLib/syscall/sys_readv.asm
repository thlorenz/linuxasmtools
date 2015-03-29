;--------------------------------------------------------------
;>1 syscall
; sys_readv - kernel function                               
;
;    INPUTS 
;     see AsmRef function -> sys_readv                                           
;
;    Note: functon call consists of four instructions
;          
;          sys_readv:                                        
;              mov  eax,145    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_readv
sys_readv:
	mov	eax,145
	int	byte 80h
	or	eax,eax
	ret