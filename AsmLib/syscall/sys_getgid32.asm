;--------------------------------------------------------------
;>1 syscall
; sys_getgid32 - kernel function                            
;
;    INPUTS 
;     see AsmRef function -> sys_getgid32                                        
;
;    Note: functon call consists of four instructions
;          
;          sys_getgid32:                                     
;              mov  eax,200    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_getgid32
sys_getgid32:
	mov	eax,200
	int	byte 80h
	or	eax,eax
	ret