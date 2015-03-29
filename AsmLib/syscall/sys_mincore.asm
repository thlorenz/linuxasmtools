;--------------------------------------------------------------
;>1 syscall
; sys_mincore - kernel function                             
;
;    INPUTS 
;     see AsmRef function -> sys_mincore                                         
;
;    Note: functon call consists of four instructions
;          
;          sys_mincore:                                      
;              mov  eax,218    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_mincore
sys_mincore:
	mov	eax,218
	int	byte 80h
	or	eax,eax
	ret