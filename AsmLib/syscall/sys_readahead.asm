;--------------------------------------------------------------
;>1 syscall
; sys_readahead - kernel function                           
;
;    INPUTS 
;     see AsmRef function -> sys_readahead                                       
;
;    Note: functon call consists of four instructions
;          
;          sys_readahead:                                    
;              mov  eax,225    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_readahead
sys_readahead:
	mov	eax,225
	int	byte 80h
	or	eax,eax
	ret