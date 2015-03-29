;--------------------------------------------------------------
;>1 syscall
; sys_idle - kernel function                                
;
;    INPUTS 
;     see AsmRef function -> sys_idle                                            
;
;    Note: functon call consists of four instructions
;          
;          sys_idle:                                         
;              mov  eax,112    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_idle
sys_idle:
	mov	eax,112
	int	byte 80h
	or	eax,eax
	ret