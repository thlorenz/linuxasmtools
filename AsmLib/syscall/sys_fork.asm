;--------------------------------------------------------------
;>1 syscall
; sys_fork - kernel function                                
;
;    INPUTS 
;     see AsmRef function -> sys_fork                                            
;
;    Note: functon call consists of four instructions
;          
;          sys_fork:                                         
;              mov  eax,2      
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_fork
sys_fork:
	mov	eax,2
	int	byte 80h
	or	eax,eax
	ret