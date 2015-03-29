;--------------------------------------------------------------
;>1 syscall
; sys_adjtimex - kernel function                            
;
;    INPUTS 
;     see AsmRef function -> sys_adjtimex                                        
;
;    Note: functon call consists of four instructions
;          
;          sys_adjtimex:                                     
;              mov  eax,124    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_adjtimex
sys_adjtimex:
	mov	eax,124
	int	byte 80h
	or	eax,eax
	ret