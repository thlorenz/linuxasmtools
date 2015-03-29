;--------------------------------------------------------------
;>1 syscall
; sys_setregid - kernel function                            
;
;    INPUTS 
;     see AsmRef function -> sys_setregid                                        
;
;    Note: functon call consists of four instructions
;          
;          sys_setregid:                                     
;              mov  eax,71     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_setregid
sys_setregid:
	mov	eax,71
	int	byte 80h
	or	eax,eax
	ret