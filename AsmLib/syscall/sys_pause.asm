;--------------------------------------------------------------
;>1 syscall
; sys_pause - kernel function                               
;
;    INPUTS 
;     see AsmRef function -> sys_pause                                           
;
;    Note: functon call consists of four instructions
;          
;          sys_pause:                                        
;              mov  eax,29     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_pause
sys_pause:
	mov	eax,29
	int	byte 80h
	or	eax,eax
	ret