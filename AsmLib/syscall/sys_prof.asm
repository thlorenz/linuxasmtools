;--------------------------------------------------------------
;>1 syscall
; sys_prof - kernel function                                
;
;    INPUTS 
;     see AsmRef function -> sys_prof                                            
;
;    Note: functon call consists of four instructions
;          
;          sys_prof:                                         
;              mov  eax,44     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_prof
sys_prof:
	mov	eax,44
	int	byte 80h
	or	eax,eax
	ret