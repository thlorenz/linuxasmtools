;--------------------------------------------------------------
;>1 syscall
; sys_io_submit - kernel function                           
;
;    INPUTS 
;     see AsmRef function -> sys_io_submit                                       
;
;    Note: functon call consists of four instructions
;          
;          sys_io_submit:                                    
;              mov  eax,248    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_io_submit
sys_io_submit:
	mov	eax,248
	int	byte 80h
	or	eax,eax
	ret