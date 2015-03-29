;--------------------------------------------------------------
;>1 syscall
; sys_futimesat - kernel function                           
;
;    INPUTS 
;     see AsmRef function -> sys_futimesat                                       
;
;    Note: functon call consists of four instructions
;          
;          sys_futimesat:                                    
;              mov  eax,299    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_futimesat
sys_futimesat:
	mov	eax,299
	int	byte 80h
	or	eax,eax
	ret