;--------------------------------------------------------------
;>1 syscall
; sys_sync - kernel function                                
;
;    INPUTS 
;     see AsmRef function -> sys_sync                                            
;
;    Note: functon call consists of four instructions
;          
;          sys_sync:                                         
;              mov  eax,36     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_sync
sys_sync:
	mov	eax,36
	int	byte 80h
	or	eax,eax
	ret