;--------------------------------------------------------------
;>1 syscall
; sys_prctl - kernel function                               
;
;    INPUTS 
;     see AsmRef function -> sys_prctl                                           
;
;    Note: functon call consists of four instructions
;          
;          sys_prctl:                                        
;              mov  eax,172    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_prctl
sys_prctl:
	mov	eax,172
	int	byte 80h
	or	eax,eax
	ret