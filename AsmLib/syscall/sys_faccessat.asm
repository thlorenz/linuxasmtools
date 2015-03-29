;--------------------------------------------------------------
;>1 syscall
; sys_faccessat - kernel function                           
;
;    INPUTS 
;     see AsmRef function -> sys_faccessat                                       
;
;    Note: functon call consists of four instructions
;          
;          sys_faccessat:                                    
;              mov  eax,307    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_faccessat
sys_faccessat:
	mov	eax,307
	int	byte 80h
	or	eax,eax
	ret