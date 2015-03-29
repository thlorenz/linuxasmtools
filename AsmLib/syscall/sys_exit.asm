;--------------------------------------------------------------
;>1 syscall
; sys_exit - kernel function                                
;
;    INPUTS 
;     see AsmRef function -> sys_exit                                            
;
;    Note: functon call consists of four instructions
;          
;          sys_exit:                                         
;              mov  eax,1      
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_exit
sys_exit:
	mov	eax,1
	int	byte 80h
	or	eax,eax
	ret