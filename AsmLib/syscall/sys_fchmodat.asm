;--------------------------------------------------------------
;>1 syscall
; sys_fchmodat - kernel function                            
;
;    INPUTS 
;     see AsmRef function -> sys_fchmodat                                        
;
;    Note: functon call consists of four instructions
;          
;          sys_fchmodat:                                     
;              mov  eax,306    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_fchmodat
sys_fchmodat:
	mov	eax,306
	int	byte 80h
	or	eax,eax
	ret