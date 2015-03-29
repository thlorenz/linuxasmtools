;--------------------------------------------------------------
;>1 syscall
; sys_io_cancel - kernel function                           
;
;    INPUTS 
;     see AsmRef function -> sys_io_cancel                                       
;
;    Note: functon call consists of four instructions
;          
;          sys_io_cancel:                                    
;              mov  eax,249    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_io_cancel
sys_io_cancel:
	mov	eax,249
	int	byte 80h
	or	eax,eax
	ret