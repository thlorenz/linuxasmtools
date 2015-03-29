
  extern get_raw_time
  extern raw2ascii
  extern env_home2
  extern str_move
  extern file_status_handle
  extern block_close
  extern block_open_read
  extern read_window_size
  extern crt_rows,crt_columns

;2a setup *************
;-------------------------------
; initial program setup
;  inputs: esp = entry stack with one push of return address
;  output:
;
setup:
  mov	[entry_esp],esp		;save stack pointer
  call	read_window_size	;pre compute window sizes
  pop	eax			;clear return address from stack
  pop	eax			;get parameter count
  mov	[parameter_count],eax
  pop	eax			;get pointer to program name
  mov	[prog_name_ptr],eax
  mov	esp,[entry_esp]		;move esp back to entry to preserve return address
;
;
  mov	ebx,fbuf		;work buffer

  call	date_setup

  call	init_variables  
  call	find_paths		;in [prog_name_ptr], [enviro_ptrs]
  call	check_if_installed
  call	get_project_names
  call	parse_command_line	;get project and point to project_list
  mov	esp,[entry_esp]
  ret


;2b init_project ******
;----------------------
; read current todo project
;  inputs:
;  output:  carry set = error in todo file data, error displayed
;           no carry = fbuf contains valid todo data file
init_project:
  mov	byte [exit_program_flg],0	;initialize for noraml processing
  call	get_todo_file		;
  jc	ip_exit			;jmp if fatal error
  call	check_todo_file		;set carry if error in todo data file
  jc	ip_exit
ip_exit:
  ret

;-----------------------------------------------------------------
; find executable path and default path
;  inputs: [enviro_ptrs] ebx = pointer to enviornment
; output:
;          home_path = home path + /.asmplan/plan/
;          edi = ptr to end of path
;
find_paths:
;
; look for home path
;
  mov	edi,home_path		;storage for "HOME" path
  call	env_home2
;create ptr to /plan
  mov	eax,edi
  add	eax,8
  mov	[path_ptr],eax

  mov	esi,path_append
  call	str_move
  ret


;2g parse_command_line ****************************
;--------------------------------------------------
; check program parameters for file name, init files
;  input:  [parameter_count] = parameter count (1=only program name)
;          [prog_name_ptr] = pointer to first parameter (program name)
; output: parsed_project - has name of project to start with
;         project_ptr - set if parsed_project is on project_list
;
parse_command_line:
  mov	ecx,[parameter_count]
  mov	esi,[prog_name_ptr]
pcl_10:
  lodsb
  or	al,al
  jnz	pcl_10			;move past program name
;
; check if any parameters entered
;
  dec	ecx
  jecxz	pcl_done		;jmp if no more parameters
  mov	edi,parsed_project
pcl_20:
  lodsb
  stosb
  or	al,al
  jnz	pcl_20			;loop till project name moved
;
; check if project is on project list
;
  mov	eax,dword [parsed_project]
  mov	esi,project_list
pcl_30:
  cmp	[esi],eax
  je	pcl_60			;jmp if project found
pcl_40:
  lodsb
  or	al,al
  jnz	pcl_40			;move past current project
  cmp	byte [esi],0		;check for end of list
  je	pcl_done
  jmp	short pcl_30
pcl_60:
  mov	[project_ptr],esi
pcl_done:
  ret

;2h create_project *************************************
;--------------------------------------------------------
; create project file
;  input: edi = ptr to project name

create_project:
  push	edi
  mov	edi,lib_buf
  mov	esi,home_path
  call	str_move
  pop	esi
  call	str_move
  mov	ebx,lib_buf		;file name
  xor	edx,edx			;default permissions
  mov	ecx,example_project
  mov	esi,(example_project_end - example_project)
  call	block_write_all
  ret

project_name	db	'sample',0

;2i get_project_names **********************************
;--------------------------------------------------------
;  read list of projects from /home/xxxx/a/projects/
;   ecx = 0 if error
get_project_names:
  call	read_directory
  call	extract_projects
  or	ecx,ecx
  jnz	gpn_exit		;jmp if projects found
  mov	edi,project_name
  call	create_project
  mov	byte [exit_program_flg],0	;disable restart
  call	read_directory
  call	extract_projects
gpn_exit:
  ret  

;------------------------

;2j extract_projects *****************************************
;--------------------------------------------------------------
; move raw data in fbuf to project_list
;  output:  ecx = 0 if error
;           
extract_projects:
  cld
  mov	edx,fbuf
  mov	edi,project_list
  xor	ebx,ebx			;clear for later
ffs_loop1:
  cmp	dword [edx+4],0		;check if offset zero
  je	ffs_done		;jmp if done
  cmp	word [edx+8],0
  je	ffs_done		;jmp if record length zero
  mov	esi,edx			;get pointer to this entry
  add	esi,8			;move past inode and offset
  mov	bx,[esi]		;get length of this record
  add	esi,2			;move forward to filename
  cmp	byte [esi],'.'
  jne	ffs_ok			;jmp if not possible header entry
  cmp	byte [esi+1],0
  je	ffs_next		;skip this "." header entry
  cmp	byte [esi+1],'.'
  jne	ffs_ok			;jmp if not possible header entry
  cmp	byte [esi+2],0
  je	ffs_next		;skip this ".." header entry
ffs_ok:
;
; move the name
;
ffs_loop2:
  lodsb
  stosb
  or	al,al
  jnz	ffs_loop2		;move the filename
ffs_next:
  add	edx,ebx			;move to next record
  jmp	ffs_loop1
ffs_done:
  xor	edx,edx
  mov	[edi],edx		;put zeros at end of project list
;
; check if any entries found
;
  mov	ecx,[project_list]
  ret

;2k read_directory ********************************************
;---------------------------------------------------------------
; read directory at /home/xxxx/.asmplan/plan
;
read_directory:
  cld
  mov	ecx,max			;clear buffer
  mov	edi,fbuf		;
  mov	al,0
  rep	stosb


rd_open: 
  mov	eax,5			;open
  mov	ebx,home_path
  mov	ecx,2000h		;directory
  int	80h

  mov	ebx,eax
  mov	eax,141
  mov	ecx,fbuf
  mov	edx,max			;buffer max size
  int	80h			;read

  mov	eax,6
  int	80h			;close
  ret

;2l init_variables *****************************************
;--------------------------------------------------------------
; init_variables
;
init_variables:
  mov	eax,seg_end
  mov	[seg_end_ptr],eax

  mov	eax,fbuf
  mov	[current_edit_todo],eax

  mov	byte [exit_program_flg],0
  
  mov	eax,[year]		;get current year
  push	eax
  mov	edi,example_project + year_field	;storage point for ascii
  mov	esi,4
  call	dword_to_l_ascii  
  pop	eax
  ret



;2n get_todo_file ********************************
;--------------------------------------------------------------------
get_todo_file:
  mov	edi,parsed_project
  cmp	byte [edi],0		;check if project specified by caller
  jz	gtf_30			;jmp if no project specified
;
; user has provided a project name, check if file exists (on list)
;
  mov	esi,project_list
  mov	ebx,esi			;save project ptr
gtf_08:
  mov	edi,parsed_project
gtf_10:
  lodsb
  or	al,al
  jnz	gtf_12			;jmp if still looking at project name
  cmp	byte [edi],0		;check if at end of both strings
  je	gtf_40			;jmp if match, both strings at end point
  jmp	short gtf_22		;go try next name
gtf_12:
  cmp	[edi],al		;match?
  jne	gtf_20			;jmp if no match
  inc	edi
  jmp	gtf_10
;
; this name does not match, move to next name
;
gtf_20:
  lodsb
  or	al,al
  jnz	gtf_20			;loop till end of name
  mov	ebx,esi			;save ptr to start of name
gtf_22:
  cmp	byte [esi],0		;check if end of list
  jne	gtf_08			;go try next name
;
; user did not supply a project name, or name not valid
;
gtf_30:
  mov	ebx,project_list	;point at first project on list
;
; we found a match, initialize project_ptr
;
gtf_40:
  mov	[project_ptr],ebx
;  mov	edi,ebx			;get ptr to project name
;gtf_50:
  mov	edi,lib_buf
  mov	esi,home_path
  call	str_move
  mov	esi,ebx
  call	str_move

  mov	ebx,lib_buf
gf_2:
  call	block_open_read
  js gf_errj
;  ebx = filehandle
  call	file_status_handle
  mov	eax,[ecx+stat_struc.st_size]	;get file length

  mov	ebp,[file_end_ptr]	;check if segment big enoug
  add	ebp,eax			;add in current file length
  add	ebp,1000		;add in room for edits
  cmp	ebp,[seg_end_ptr]
  jb	gf_10			;jmp if room for this file
;
; request more memory
;
  push	ebx
  push	eax
  mov	ebx,ebp
  mov	eax,45
  int	80h			;sysbrk kernel call
  or	eax,eax			;set sign flag
  mov	edi,eax			;save eax
  pop	eax
  pop	ebx
gf_errj:
  js	gf_err
  mov	[seg_end_ptr],edi	;update end of memory
gf_10:
  mov	edx,max  
  mov ecx,fbuf
gf_20:
  mov	eax,3
  int	80h			;read file
  or	eax,eax
  jns	gf_50			;jmp if no error
  cmp	eax,byte -4		;is this a signal problem
  je	gf_10			;try again if signal interference
  jmp   short gf_err
gf_50:
  jz	gf_60			;jmp if end of file reached
  add  ecx,eax			;move buffer pointer forward
  jmp  short gf_20
gf_60:
  mov	[file_end_ptr],ecx	;store file end pointer
;  sub  ecx,fbuf			;compute length of read
  call	block_close
  or	eax,eax
  jns gf_out
gf_err:
  call	err_msg
  stc
  jmp	gf_exit
gf_out:
  clc
gf_exit:
  ret


;2o check_todo_file **********************************
;-----------------------------------------------------
; check format of todo data
;  inputs:   fbuf = file data
;            [file_end_ptr] = ptr to char. beyond end of file
;            raw_record_length - length of records, including 0ah at end
;            raw_note_offset - position of note in record
; output: carry set - error
;         no carry - file ok
check_todo_file:
  mov	esi,fbuf		;get data ptr
  cmp	esi,[file_end_ptr]	;check if zero lenght file
  je	ctf_ok			;exit if null file
ctf_lp:
  cmp	byte [esi],'_'		;check if no records
  jne	ctf_err			;jmp if invalid record at start
  mov	ax,[esi +  year_field]
  cmp	al,"2"
  ja	ctf_err			;jmp if year out of range
  mov	ax,[esi + month_field]
  cmp	al,'1'
  ja	ctf_err			;jmp if month out of range
  jb	ctf_10			;jmp if 0x
  cmp	ah,'2'
  ja	ctf_err			;jmp if moth out of range
ctf_10:
  mov	ax,[esi + day_field]
  cmp	al,'3'
  ja	ctf_err			;jmp if day out of range
  jb	ctf_20
  cmp	ah,'1'
  ja	ctf_err			;jmp if day out of range
ctf_20:
  call	next_todo
  jnc	ctf_lp			;loop till done

ctf_50:
  mov	esi,[file_end_ptr]
  cmp	byte [esi -1],0ah
  je	ctf_ok			;jmp if end of file found as expected
ctf_err:
  mov	eax,125
  call	err_msg
  mov	byte [parsed_project],0 ;invalidated any parsed file name
  stc
  jmp	short ctf_exit
ctf_ok:
  clc
ctf_exit:
  ret
;
; The collection of values associated with times and dates
;
struc time
.ct:		resd	1	; raw C time (seconds since the Epoch)
.at:		resd	1	; zone adjusted seconds since last Epoch
.zo:		resd	1	; time zone offset
.zi:		resb	6	; time zone identifier
.tz:		resb	10	; time zone name
; fields set by seconds2bins follow this comment. 
.dc:		resd	1	; days since last Epoch
.sc:		resd	1	; seconds
.mn:		resd	1	; minutes
.hr:		resd	1	; hours
.yr:		resd	1	; year
.mr:		resd	1	; meridian (0 for AM)
.wd:		resd	1	; day of the week (Sunday=0, Saturday=6)
.dy:		resd	1	; day of the month
.mo:		resd	1	; month (one-based)
endstruc
  
;-----------------------------------------------------------
date_setup:
  call	get_raw_time	;raw weconds in eax
  mov	edi,ascii_year	;destination for data
  mov	ebx,format
  call	raw2ascii

  mov	eax,[ebx+time.yr]
  mov	[year],eax

  mov	eax,[ebx+time.dy]
  mov	[day_of_month],eax

  mov	eax,[ebx+time.mo]
  mov	[month_number],eax

  ret

format: db "012",0
;-----------------------------------------------------------
check_if_installed:

;
; check if project directory exists
;
  mov	ebx,home_path
  xor	ecx,ecx			;exist flag
  mov	eax,33
  int	80h			;check access

  or	eax,eax			;check if path exists
  jz	chf_exit		;exit if found
;
; create directories, first create path /home/xxxx/.asmplan
;
  mov	eax,[path_ptr]
  mov	byte [eax],0		;terminate paths
  mov	byte [eax+5],0		;terminate /plan

  mov	eax,39
  mov	ebx,home_path
  mov	ecx,40755q		;read/write flag
  int	80h			;create /home/xxxx/.asmplan
  mov	eax,[path_ptr]
  mov	byte [eax],'/'		;restore '/'

  mov	eax,39
  mov	ebx,home_path
  mov	ecx,40755q		;read/write flag
  int	80h			;create /home/xxxx/.asmplan/plan

  mov	eax,[path_ptr]
  mov	byte [eax+5],'/'	;restore '/'

  call	copy_project_files
chf_exit:  
  ret
;--------------------------------------------------------
; copy project files
;  input: edi = ptr to project name

copy_project_files:
  mov	edi,lib_buf
  mov	esi,home_path
  call	str_move
  mov	esi,demo_proj
  call	str_move

  mov	ebx,lib_buf
  xor	edx,edx		;use default permissions
  mov	ecx,demo_project ;get data buffer
  mov	esi,(demo_project_end - demo_project)
  call	block_write_all

  mov	edi,lib_buf
  mov	esi,home_path
  call	str_move
  mov	esi,hints_proj
  call	str_move

  mov	ebx,lib_buf
  xor	edx,edx		;use default permissions
  mov	ecx,hints_project ;get data buffer
  mov	esi,(hints_project_end - hints_project)
  call	block_write_all
  ret

demo_proj:	db	'demo',0
hints_proj:	db	'hints',0
  
;-----------------------------------------------------------
;----   local data -----------------------------------------
;-----------------------------------------------------------

 [section .data]

entry_esp	dd	0	;entery stack pointer

prog_name_ptr	dd	0	;stack ptr to executable name
parameter_count	dd	0	;command line

new_proj_msg1	db	'New projects are stored at /.asmplan',0
new_proj_msg2	db	' Enter name :',0
del_proj_msg1	db	'select project to delete',0ah
		db	'ESC aborts without deleting',0
open_proj_msg1	db	'select project to open',0ah
		db	'ESC aborts without selecting',0
get_todo_msg	db	'No valid project names supplied, click on project',0

parsed_project	times	20 db (0)
project_ptr	dd	project_list

;used to create new project
example_project:
  db '_Y120040101Sample todo entry - click to edit or delete',0ah,0ah
example_project_end:

;used by install
demo_project:
  db '_Y120060101This is a demo project/note file for AsmPlan',0ah,0ah
  db '_Y120060102.',0ah,0ah
  db '_Y120060103Additional help is available at the following:',0ah,0ah
  db '_Y120060104Subscribe to DesktopLinuxAsm-subscribe@yahoogroups.com by sending blank email',0ah,0ah
  db '_Y120060105Web page at http://linuxasmtools.net/',0ah,0ah
  db '_Y120060106 email contact is  jko@bsn1.net (Jeff Owens)',0ah,0ah
  db '_Y120060107Delete this project/topic or add your activities',0ah,0ah
demo_project_end:

;used by install
hints_project:
  db '_Y120060101This is a hint project/note file for AsmPlan',0ah,0ah
  db '_Y120060102.',0ah,0ah
  db '_Y120060103Left click todo date to indicate completion',0ah,0ah
  db '_Y120060104Right click todo date to delete todo',0ah,0ah
  db '_Y120060105Click on todo body to edit it',0ah,0ah
  db '_Y120060106.',0ah,0ah
  db '_Y120060107AsmPlan can be started with name of existing project',0ah,0ah
  db '_Y120060108Projects are shown on top line, click to select',0ah,0ah
  db '_Y120060109.',0ah,0ah
  db '_Y120060111Use help button to see keyboard commands',0ah,0ah
  db '_Y120060121Add your own hints here.',0ah,0ah
hints_project_end:
  
path_append:
 db '.asmplan/plan/',0
path_ptr	dd	0	;ptr to "/" after .asmplan

  [section .text]

