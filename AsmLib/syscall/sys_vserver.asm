;--------------------------------------------------------------
;>1 syscall
; sys_vserver - kernel function                             
;
;    INPUTS 
;     see AsmRef function -> sys_vserver                                         
;
;    Note: functon call consists of four instructions
;          
;          sys_vserver:                                      
;              mov  eax,273    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_vserver
sys_vserver:
	mov	eax,273
	int	byte 80h
	or	eax,eax
	ret