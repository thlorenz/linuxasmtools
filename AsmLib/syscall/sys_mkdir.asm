;--------------------------------------------------------------
;>1 syscall
; sys_mkdir - kernel function                               
;
;    INPUTS 
;     see AsmRef function -> sys_mkdir                                           
;
;    Note: functon call consists of four instructions
;          
;          sys_mkdir:                                        
;              mov  eax,39     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_mkdir
sys_mkdir:
	mov	eax,39
	int	byte 80h
	or	eax,eax
	ret