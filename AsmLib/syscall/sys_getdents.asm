;--------------------------------------------------------------
;>1 syscall
; sys_getdents - kernel function                            
;
;    INPUTS 
;     see AsmRef function -> sys_getdents                                        
;
;    Note: functon call consists of four instructions
;          
;          sys_getdents:                                     
;              mov  eax,141    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_getdents
sys_getdents:
	mov	eax,141
	int	byte 80h
	or	eax,eax
	ret