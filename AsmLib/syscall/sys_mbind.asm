;--------------------------------------------------------------
;>1 syscall
; sys_mbind - kernel function                               
;
;    INPUTS 
;     see AsmRef function -> sys_mbind                                           
;
;    Note: functon call consists of four instructions
;          
;          sys_mbind:                                        
;              mov  eax,274    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_mbind
sys_mbind:
	mov	eax,274
	int	byte 80h
	or	eax,eax
	ret