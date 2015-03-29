;--------------------------------------------------------------
;>1 syscall
; sys_lookup_dcookie - kernel function                      
;
;    INPUTS 
;     see AsmRef function -> sys_lookup_dcookie                                  
;
;    Note: functon call consists of four instructions
;          
;          sys_lookup_dcookie:                               
;              mov  eax,253    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_lookup_dcookie
sys_lookup_dcookie:
	mov	eax,253
	int	byte 80h
	or	eax,eax
	ret