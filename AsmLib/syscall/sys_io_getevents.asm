;--------------------------------------------------------------
;>1 syscall
; sys_io_getevents - kernel function                        
;
;    INPUTS 
;     see AsmRef function -> sys_io_getevents                                    
;
;    Note: functon call consists of four instructions
;          
;          sys_io_getevents:                                 
;              mov  eax,247    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_io_getevents
sys_io_getevents:
	mov	eax,247
	int	byte 80h
	or	eax,eax
	ret