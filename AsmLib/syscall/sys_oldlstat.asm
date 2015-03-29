;--------------------------------------------------------------
;>1 syscall
; sys_oldlstat - kernel function                            
;
;    INPUTS 
;     see AsmRef function -> sys_oldlstat                                        
;
;    Note: functon call consists of four instructions
;          
;          sys_oldlstat:                                     
;              mov  eax,84     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_oldlstat
sys_oldlstat:
	mov	eax,84
	int	byte 80h
	or	eax,eax
	ret