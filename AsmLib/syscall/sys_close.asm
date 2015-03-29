;--------------------------------------------------------------
;>1 syscall
; sys_close - kernel function                               
;
;    INPUTS 
;     see AsmRef function -> sys_close                                           
;
;    Note: functon call consists of four instructions
;          
;          sys_close:                                        
;              mov  eax,6      
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_close
sys_close:
	mov	eax,6
	int	byte 80h
	or	eax,eax
	ret