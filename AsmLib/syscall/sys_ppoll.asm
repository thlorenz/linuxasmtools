;--------------------------------------------------------------
;>1 syscall
; sys_ppoll - kernel function                               
;
;    INPUTS 
;     see AsmRef function -> sys_ppoll                                           
;
;    Note: functon call consists of four instructions
;          
;          sys_ppoll:                                        
;              mov  eax,309    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_ppoll
sys_ppoll:
	mov	eax,309
	int	byte 80h
	or	eax,eax
	ret