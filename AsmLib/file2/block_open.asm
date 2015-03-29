
;   Copyright (C) 2007 Jeff Owens
;
;   This program is free software: you can redistribute it and/or modify
;   it under the terms of the GNU General Public License as published by
;   the Free Software Foundation, either version 3 of the License, or
;   (at your option) any later version.
;
;   This program is distributed in the hope that it will be useful,
;   but WITHOUT ANY WARRANTY; without even the implied warranty of
;   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;   GNU General Public License for more details.
;
;   You should have received a copy of the GNU General Public License
;   along with this program.  If not, see <http://www.gnu.org/licenses/>.


  [section .text align=1]
  extern lib_buf
  extern env_home2
  extern str_move

  [section .text]

;---------------------------------------------------
;>1 file2
;  block_open_write - open truncated file for read/write
; INPUTS
;    ebx = ptr to full file path or local file.
;          full path is indicated by a '/' at start of name.
;    edx = optional file permissions.
;          can be set to zero for default permissions
; 
; OUTPUT
;    eax = negative if error (error number)
;        = positive file handle if success
;          flags are set for js jns jump
;    ebx = file handle if eax positive
;
; PROCESSING
;    If file does not exist it will be created.
;    If file exists it will be truncated.
;       Existing files will be checked for symlinks and
;       the target file opened.  If permissions are
;       provided they will be applied to file
;    Origional data in file can not be read, but subsquent
;    data written can be read back.     
; NOTES
;    source file:  block_open.asm
;<
;  * ----------------------------------------------
;*******
  global block_open_write
block_open_write:
  mov	eax,102q	;create + read/write
  mov	ecx,1002q	;truncate + read/write
  call	block_open
  ret

;---------------------------------------------------
;>1 file2
;  block_open_home_write - open truncated file in $HOME dir for read/write
; INPUTS
;    ebx = ptr to path for append to %HOME/
;    edx = optional file permissions.
;          can be set to zero for default permissions
; 
; OUTPUT
;    eax = negative if error (error number)
;        = positive file handle if success
;          flags are set for js jns jump
;    ebx = file handle if eax positive
;
; PROCESSING
;    If file does not exist it will be created.
;    If file exists it will be truncated.
;       Existing files will be checked for symlinks and
;       the target file opened.  If permissions are
;       provided they will be applied to file
;    Origional data in file can not be read, but subsquent
;    data written can be read back.     
; NOTES
;    source file:  block_open.asm
;<
;  * ----------------------------------------------
;*******
  global block_open_home_write
block_open_home_write:
  push	edx
  push	ebx
  mov	edi,lib_buf+200	;location to build filename
  call	env_home2
  pop	esi		;get input filename
  call	str_move
  mov	ebx,lib_buf+200	;restore pointer to full file name
  pop	edx		;resore file permissions

  mov	eax,102q	;create + read/write
  mov	ecx,1002q	;truncate + read/write
  call	block_open
  ret
;----------------------------------------------------
;>1 file2
;  block_open_append - open file for appended writes
; INPUTS
;    ebx = ptr to full file path or local file.
;          full path is indicated by a '/' at start of name.
;    edx = optional file permissions.
;          can be set to zero for default permissions
; 
; OUTPUT
;    eax = negative if error (error number)
;        = positive file handle if success
;          flags are set for js jns jump
;    ebx = file handle if eax positive
;
; PROCESSING
;    If file does not exist it will be created.
;    If file exists it will be opened at end of data.
;       Existing files will be checked for symlinks and
;       the target file opened.  If permissions are
;       provided they will be applied to file
;    Writes append data to end of existing file data.
; NOTES
;    source file:  block_open.asm
;<
;  * ----------------------------------------------
;*******
  global block_open_append
block_open_append:
  mov	eax,2102q	;create + append + read/write
  mov	ecx,2002q	;append + read/write
  call	block_open
  ret

;----------------------------------------------------
;>1 file2
;  block_open_home_append - open file at $HOME for appended writes
; INPUTS
;    ebx = ptr to full file path or local file.
;          full path is indicated by a '/' at start of name.
;    edx = optional file permissions.
;          can be set to zero for default permissions
; 
; OUTPUT
;    eax = negative if error (error number)
;        = positive file handle if success
;          flags are set for js jns jump
;    ebx = file handle if eax positive
;
; PROCESSING
;    If file does not exist it will be created.
;    If file exists it will be opened at end of data.
;       Existing files will be checked for symlinks and
;       the target file opened.  If permissions are
;       provided they will be applied to file
;    Writes append data to end of existing file data.
; NOTES
;    source file:  block_open.asm
;<
;  * ----------------------------------------------
;*******
  global block_open_home_append
block_open_home_append:
  push	edx
  push	ebx
  mov	edi,lib_buf+200	;location to build filename
  call	env_home2
  pop	esi		;get input filename
  call	str_move
  mov	ebx,lib_buf+200	;restore pointer to full file name
  pop	edx		;resore file permissions

  mov	eax,2102q	;create + append + read/write
  mov	ecx,2002q	;append + read/write
  call	block_open
  ret

;---------------------------------------------------
;>1 file2
;  block_open_update - open file for reading/writing records
; INPUTS
;    ebx = ptr to full file path or local file.
;          full path is indicated by a '/' at start of name.
;    edx = optional file permissions.
;          can be set to zero for default permissions
; 
; OUTPUT
;    eax = negative if error (error number)
;        = positive file handle if success
;          flags are set for js jns jump
;    ebx = file handle if eax positive
;
; PROCESSING
;    If file does not exist it will be created.
;    If file exists it will be opened with pointer at start of data
;       Existing files will be checked for symlinks and
;       the target file opened.  If permissions are
;       provided they will be applied to file
;    Data can be read or written to file and positons for reading
;    or writing selected by block_seek 
; NOTES
;    source file:  block_open.asm
;<
;  * ----------------------------------------------
;*******
  global block_open_update
block_open_update:
  mov	eax,102q	;mode for new files = create + read/write
  mov	ecx,002q	;existing file modes=  read/write
  call	block_open
  ret
;---------------------------------------------------
;>1 file2
;  block_open_home_update - open file at $HOME for reading/writing records
; INPUTS
;    ebx = ptr to full file path or local file.
;          full path is indicated by a '/' at start of name.
;    edx = optional file permissions.
;          can be set to zero for default permissions
; 
; OUTPUT
;    eax = negative if error (error number)
;        = positive file handle if success
;          flags are set for js jns jump
;    ebx = file handle if eax positive
;
; PROCESSING
;    If file does not exist it will be created.
;    If file exists it will be opened with pointer at end
;       Existing files will be checked for symlinks and
;       the target file opened.  If permissions are
;       provided they will be applied to file
;    Data can be read or written to file and positons for reading
;    or writing selected by block_seek 
; NOTES
;    source file:  block_open.asm
;<
;  * ----------------------------------------------
;*******
  global block_open_home_update
block_open_home_update:
  push	edx
  push	ebx
  mov	edi,lib_buf+200	;location to build filename
  call	env_home2
  pop	esi		;get input filename
  call	str_move
  mov	ebx,lib_buf+200	;restore pointer to full file name
  pop	edx		;resore file permissions

  mov	eax,102q	;create + read/write
  mov	ecx,002q	; read/write
  call	block_open
  ret

;---------------------------------------------------
; inputs:  ebx = filename ptr
;          edx = file permissions or zero
;          eax = new file creation mode flag
;          ecx = existing file mode flag
; output:  eax = return code
;          ebx = filehandle if eax positive
block_open:
  mov	[new_file_mode],eax
  mov	[existing_file_mode],ecx
  mov	[fname_ptr],ebx
  mov	eax,107
  mov	ecx,lib_buf + 400	;use lib_buf for fstat buffer
  int	80h
  or	eax,eax
  jns	bow_50			;jmp if file exists
;
; file does not exist, check if caller supplied permissions.
;
  or	edx,edx
  jz	bow_10			;jmp if no permissions supplied
;
; permissions are in edx, enable umask
;
  mov	ebx,0			;new umask
  mov	eax,60			;kernel umask code
  int	80h
  push	eax			;save old umask
;
; create file with new permissions
;
  mov	ecx,[new_file_mode]	;access = create + read/write
  mov	eax,5			;kernel open call
  mov	ebx,[fname_ptr]		;get file name
  int	80h			;open file
;
; restore origional umask
;
  pop	ebx			;get old umask
  push	eax			;save results of open
  mov	eax,60
  int	80h			;restore origional umask
  pop	eax
  jmp	bow_exit
;
; open file with default permissions, create, read/write
;
bow_10:
  mov	edx,666q		;default permissions (masked by umask)
  mov	ecx,[new_file_mode]	;access = create + read/write
  mov	eax,5			;kernel open call
  mov	ebx,[fname_ptr]		;get file name
  int	80h			;open file
  jmp	bow_exit
;
; file exists. check for symlinks
;
bow_50:
  push	edx			;save file permissions
  mov	eax,85			;read link sys-call code
  mov	ebx,[fname_ptr]		;path
  mov	ecx,lib_buf		;temp buffer to hold symlink name
  mov	edx,600			;lib_buf_size
  int	80h			;call kernel
  pop	edx			;retore file permisssions
  or	eax,eax
  js	bow_70			;jmp if not symlink
;
; existing file is a symlink, new name at lib_buf, check if permissions provided
;
  or	edx,edx
  jz	bow_60			;jmp if no permissions supplied
;
; permissions are in edx, enable umask
;
  mov	ebx,0			;new umask
  mov	eax,60			;kernel umask code
  int	80h
  push	eax			;save old umask
;
; change permissions on file
;
  mov	eax,15			;kernel call to change permissions
  mov	ebx,lib_buf    
  mov	ecx,edx			;permissons to ecx
  int	80h
;
; create file with new permissions, access = create + read/write
;
  xor	edx,edx			;permissions already set
  mov	ecx,[existing_file_mode];access =  truncate + read/write
  mov	eax,5			;kernel open call
; mov	ebx,lib_buf		;file name
  int	80h			;open file
;
; restore origional umask
;
  pop	ebx			;get old umask
  push	eax			;save results of open
  mov	eax,60
  int	80h			;restore origional umask
  pop	eax			;restore results of open
  jmp	short bow_exit
;
; no permissions provided, file is symlink
;
bow_60:
  mov	ecx,[existing_file_mode];access = read/write
  mov	eax,5			;kernel open call
  mov	ebx,lib_buf		;file name
  int	80h			;open file
  jmp	short bow_exit
;
; file exists, it is not a symlink, check if permissions provided
;
bow_70:
  or	edx,edx
  jz	bow_80			;jmp if no permissions supplied
;
; permissions are in edx, enable umask
;
  mov	ebx,0			;new umask
  mov	eax,60			;kernel umask code
  int	80h
  push	eax			;save old umask
;
; change permissions on file
;
  mov	eax,15			;kernel call to change permissions
  mov	ebx,[fname_ptr]
  mov	ecx,edx			;permissions to ecx
  int	80h
;
; open with new permissions, access = read/write
;
  mov	ecx,[existing_file_mode]; read/write
  mov	eax,5			;kernel open call
  mov	ebx,[fname_ptr]		;file name
  int	80h			;open file
;
; restore origional umask
;
  pop	ebx			;get old umask
  push	eax			;save results of open
  mov	eax,60
  int	80h			;restore origional umask
  pop	eax
  jmp	short bow_exit
;
; no permissions provided, file is not a symlink
;
bow_80:
  mov	ecx,[existing_file_mode];access =  read/write
  mov	eax,5			;kernel open call
  mov	ebx,[fname_ptr]		;file name
  int	80h			;open file
  jmp	short bow_exit

bow_exit:
  mov	ebx,eax		;move file handle to ebx
  or	eax,eax		;set flags for error jumps
  ret

;-----------
  [section .data]
fname_ptr:		dd	0
new_file_mode		dd	0
existing_file_mode	dd	0
  [section .text]

