;--------------------------------------------------------------
;>1 syscall
; sys_vfork - kernel function                               
;
;    INPUTS 
;     see AsmRef function -> sys_vfork                                           
;
;    Note: functon call consists of four instructions
;          
;          sys_vfork:                                        
;              mov  eax,190    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_vfork
sys_vfork:
	mov	eax,190
	int	byte 80h
	or	eax,eax
	ret