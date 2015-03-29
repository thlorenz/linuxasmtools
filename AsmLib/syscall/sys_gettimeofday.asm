;--------------------------------------------------------------
;>1 syscall
; sys_gettimeofday - kernel function                        
;
;    INPUTS 
;     see AsmRef function -> sys_gettimeofday                                    
;
;    Note: functon call consists of four instructions
;          
;          sys_gettimeofday:                                 
;              mov  eax,78     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_gettimeofday
sys_gettimeofday:
	mov	eax,78
	int	byte 80h
	or	eax,eax
	ret