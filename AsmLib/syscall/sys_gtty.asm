;--------------------------------------------------------------
;>1 syscall
; sys_gtty - kernel function                                
;
;    INPUTS 
;     see AsmRef function -> sys_gtty                                            
;
;    Note: functon call consists of four instructions
;          
;          sys_gtty:                                         
;              mov  eax,32     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_gtty
sys_gtty:
	mov	eax,32
	int	byte 80h
	or	eax,eax
	ret