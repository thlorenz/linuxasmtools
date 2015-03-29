;*****************  header1.inc ************************
;
; used by: AsmPre & AsmDis & AsmBug1 & AsmBug2
;
.load_phys_top	resd 1
.code_phys_start resd 1
.code_phys_end	 resd 1 ;points one byte beyond last used location
.data_phys_start resd 1 ;if zero, no data section found
.data_phys_end   resd 1 ;points one byte beyond last used location
.bss_phys_start  resd 1 ;if zero, no bss section found
.bss_phys_end	 resd 1 ;points one byte beyond last used location
.load_phys_end	resd 1	;does not include .bss section
;
.run_physical_entry resd 1 ;execution starts here
.app_main           resd 1 ;set if lib setup at run_physical_entry

.elf_type_flag	 resd 1 ;00000001h - dynamic section found
                        ;00000002h - lib wrapper for HLL found
                        ;00000004h - symbol table found
                        ;00000008h - debug section found
                        ;00000010h - source file found
                        ;00000020h - debug comments found
                        ;00000040h - no sections found (bit set)

.font_width:	resb 1 ;if font is 12x24 this will contain 12
.font_height:	resb 1 ;if font is 12x24 this will contain 24
.font_string:   resb 6 ;	'12x24',0

.target_file:	resb 200
.target_time:	resd 2
;
.win_config:	resb 1	;0=swap 1=overlap 2=side-by-side
.term_type:	resb 1	;0=unknown 1=console 2=xterm-clone 3=xterm

