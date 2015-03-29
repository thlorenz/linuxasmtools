;--------------------------------------------------------------
;>1 syscall
; sys_uname - kernel function                               
;
;    INPUTS 
;     see AsmRef function -> sys_uname                                           
;
;    Note: functon call consists of four instructions
;          
;          sys_uname:                                        
;              mov  eax,122    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_uname
sys_uname:
	mov	eax,122
	int	byte 80h
	or	eax,eax
	ret