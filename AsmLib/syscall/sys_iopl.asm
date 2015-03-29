;--------------------------------------------------------------
;>1 syscall
; sys_iopl - kernel function                                
;
;    INPUTS 
;     see AsmRef function -> sys_iopl                                            
;
;    Note: functon call consists of four instructions
;          
;          sys_iopl:                                         
;              mov  eax,110    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_iopl
sys_iopl:
	mov	eax,110
	int	byte 80h
	or	eax,eax
	ret