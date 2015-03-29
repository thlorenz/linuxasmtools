;--------------------------------------------------------------
;>1 syscall
; sys_link - kernel function                                
;
;    INPUTS 
;     see AsmRef function -> sys_link                                            
;
;    Note: functon call consists of four instructions
;          
;          sys_link:                                         
;              mov  eax,9      
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_link
sys_link:
	mov	eax,9
	int	byte 80h
	or	eax,eax
	ret