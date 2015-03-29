;--------------------------------------------------------------
;>1 syscall
; sys_ftime - kernel function                               
;
;    INPUTS 
;     see AsmRef function -> sys_ftime                                           
;
;    Note: functon call consists of four instructions
;          
;          sys_ftime:                                        
;              mov  eax,35     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_ftime
sys_ftime:
	mov	eax,35
	int	byte 80h
	or	eax,eax
	ret