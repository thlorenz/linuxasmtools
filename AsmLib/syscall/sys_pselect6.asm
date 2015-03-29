;--------------------------------------------------------------
;>1 syscall
; sys_pselect6 - kernel function                            
;
;    INPUTS 
;     see AsmRef function -> sys_pselect6                                        
;
;    Note: functon call consists of four instructions
;          
;          sys_pselect6:                                     
;              mov  eax,308    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_pselect6
sys_pselect6:
	mov	eax,308
	int	byte 80h
	or	eax,eax
	ret