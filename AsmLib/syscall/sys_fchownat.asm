;--------------------------------------------------------------
;>1 syscall
; sys_fchownat - kernel function                            
;
;    INPUTS 
;     see AsmRef function -> sys_fchownat                                        
;
;    Note: functon call consists of four instructions
;          
;          sys_fchownat:                                     
;              mov  eax,298    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_fchownat
sys_fchownat:
	mov	eax,298
	int	byte 80h
	or	eax,eax
	ret