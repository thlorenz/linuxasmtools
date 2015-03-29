;--------------------------------------------------------------
;>1 syscall
; sys_msync - kernel function                               
;
;    INPUTS 
;     see AsmRef function -> sys_msync                                           
;
;    Note: functon call consists of four instructions
;          
;          sys_msync:                                        
;              mov  eax,144    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_msync
sys_msync:
	mov	eax,144
	int	byte 80h
	or	eax,eax
	ret