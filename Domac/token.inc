  [section .text]
;
; token definitions and tables
;  type bits = 01h filename
;              02h string
;              04h number (dword at .end)
;              08h output data buffer
;              10h keyword
;              80h dedicated data buffer
;  legal bits =
;               01h find cmd can set
;               02h copy cmd -from-
;               04h copy cmd -to-
;               08h expand front ok
;               10h expand end ok
;               20h legal for replace
;               40h 
struc token
.begin		resd 1 ;start of token data
.end		resd 1 ;end of token data
.buf_end	resd 1 ;end of buffer
.tok#		resb 1 ;token number
.host#		resb 1 ;token# if data string inside token
.type		resb 1 ;
.legal		resb 1
endstruc

;                                                          .legal-for-use-in-these-commands
;descript .begin   .end  .buf_end  .tok#  ,host#  .type    ifeq,ifne  find  copy  expand  shrink replace dolist shell
;-------  ------   ----- --------  ------ ------  -----    ---------  ----  ----  ------  ------ ------- ------ -----
;filename   adr     adr     adr      x      x     03,83       yes      yes   yes    yes     yes    yes    no     yes  
;string     adr     adr     adr      x      x     02,+        yes      yes   yes    yes     yes    yes    yes    yes   
;number     adr     adr    value     x      x     04          no       no    no     no      no     no     no     no
;keyword    ---     ---    index     x      x     10          yes      no    yes    no      no     no     no     no

;infilename  adr    adr     adr      1      1     83          yes      yes   yes    yes     yes    yes    no     yes
;outfilename adr    adr     adr      2      2     83          yes      yes   yes    yes     yes    yes    no     yes
;temp        adr    adr     adr      3      3     x           yes      yes   yes    yes     yes    yes    no     yes
;infile      adr    adr     adr      4      4     8a          no       yes   no     yes     yes    yes    no     no
;findptr      x      x       x       5      x     82          yes      yes   yes    yes     yes    yes    yes    yes
;doptr       adr    adr     adr      6      6     x2          yes      yes   yes    yes     yes    yes    yes    yes
;work         x      x       x       7      7     x           yes      yes   yes    yes     yes    yes    no     yes

  [section .data]
;----
; user accessable tokens
;----
tokens:
 db '$infilename',0	;token #1 (not zero)
 db '$outfilename',0
 db '$temp',0	 	;ptr to dofile name
 db '$infile',0		;infile buffer
 db '$findptr',0 	;ptr to last find match (=0 if no match)
 db '$doptr',0 		;ptr to current dofile token
 db '$work',0  		;work pointer
 db 0

;----
; tokens acessable by user commands
;----
;-------token 1 -----------
_infilename:	dd infilename_buf ;ptr to input file name
_infilename_end:dd 0 ;ptr to end of filename
		dd infilename_buf + infilename_buf_size ;infile buffer end
		db 1 ;token#
		db 0 ;host token#
		db 83h ;type dedicated buffer, filename, string
		db 3fh ;legal

;-------token 2 -----------
_outfilename:	dd outfilename_buf ;ptr to outfile name
_outfilename_end:dd 0 ;ptr to end of filename
		dd outfilename_buf + outfilename_buf_size ;buffer end
		db 2 ;token#
		db 0 ;host token#
		db 83h ;type = dedicated buffer, filename, string
		db 3fh ;legal

;-------token 3 -----------
_temp:	dd temp_buf ;ptr to dofile name
_temp_end:dd temp_buf ;ptr to end of filename
		dd temp_buf + temp_buf_size ;buffer end
		db 3 ;token#
		db 0 ;host token#
		db 83h ;type = dedicated buffer, filename, string
		db 3fh ;legal

;-------token 4 -----------
_infile:	dd 0 ;input file buffer
_infile_end:	dd 0 ;end of data
_infile_buf_end:dd 0 ;buffer end
		db 4 ;token#
		db 0 ;host token#
		db 08h ;type = allocated buffer, used as output file
		db 3fh ;legal

;-------token 5 -----------
_findptr:	dd 0 ;ptr to last find match (=0 if no match)
_findptr_end:	dd 0 ;prt to end of last find string
		dd 0 ;unused
		db 5 ;token#
		db 0 ;host token#
		db 01;type = string
		db 3fh ;legal

;-------token 6 -----------
next_dolist:	dd 0 ;ptr to next line
dolist_end:	dd 0 ;end of current line
dobuf_end:	dd 0 ;buffer end
		db 6 ;token#
		db 0 ;host token#
		db 2 ;type = string
		db 3fh ;legal

;-------token 7 -----------
_work:		dd work_buf ;ptr to work_buf
_work_end:	dd work_buf ;end of work buf entry
		dd work_buf + work_buf_size ;buffer end
		db 7 ;token#
		db 0 ;host token#
		db 82h ;type = dedicated buffer, string
		db 3fh ;legal

;----
; tokens not user accessable
;----

;-------token 8 -----------
_local_tok:
      		dd 0 ;ptr to work_buf
_local_end:    	dd 0 ;end of work buf entry
_local_buf_end:	dd 0 ;buffer end
_local_tok#	db 8 ;token#
_local_host	db 0 ;host token#
_local_type	db 82h ;type = dedicated buffer, string
_local_legal    db 0 ;legal

;-------token 9 -----------
;-------token 10 -----------
;-------token 11 -----------
;-------token 12 -----------
;-------token 13 -----------
;-------token 14 -----------
;-------token 15 -----------
;-------token 16 -----------

;-----------------------------------------------------------------------
;we could allocate in memory manager and put in token ddrectly !!!!
;----
; buffers dedicated to specific token
;----

  [section .bss]

infilename_buf_size equ 200
infilename_buf	resb infilename_buf_size

outfilename_buf_size equ 200
outfilename_buf resb outfilename_buf_size

temp_file_buf_size equ 200
temp_file_buf	resb temp_file_buf_size

temp_buf_size	equ 4000
temp_buf	resb temp_buf_size

work_buf_size	equ 16000
work_buf	resb work_buf_size

  [section .text]


