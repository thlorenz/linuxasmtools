;--------------------------------------------------------------
;>1 syscall
; sys_tkill - kernel function                               
;
;    INPUTS 
;     see AsmRef function -> sys_tkill                                           
;
;    Note: functon call consists of four instructions
;          
;          sys_tkill:                                        
;              mov  eax,238    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_tkill
sys_tkill:
	mov	eax,238
	int	byte 80h
	or	eax,eax
	ret