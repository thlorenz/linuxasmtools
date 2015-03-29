;--------------------------------------------------------------
;>1 syscall
; sys_utimensat - kernel function                           
;
;    INPUTS 
;     see AsmRef function -> sys_utimensat                                       
;
;    Note: functon call consists of four instructions
;          
;          sys_utimensat:                                    
;              mov  eax,320    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_utimensat
sys_utimensat:
	mov	eax,320
	int	byte 80h
	or	eax,eax
	ret