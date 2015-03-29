;--------------------------------------------------------------
;>1 syscall
; sys_setfsuid - kernel function                            
;
;    INPUTS 
;     see AsmRef function -> sys_setfsuid                                        
;
;    Note: functon call consists of four instructions
;          
;          sys_setfsuid:                                     
;              mov  eax,138    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_setfsuid
sys_setfsuid:
	mov	eax,138
	int	byte 80h
	or	eax,eax
	ret