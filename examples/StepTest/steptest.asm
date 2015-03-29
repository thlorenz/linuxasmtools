
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

;  extern metronome
%include "metronome.inc"

  extern crt_clear
  extern crt_write
  extern read_stdin
  extern key_flush
  extern raw_set1,raw_unset1
  extern kbuf

   global _start
_start:
  cld
  mov	eax,[color]
  call	crt_clear

  mov	ecx,intro_msg
  mov	edx,intro_msg_length
  call	crt_write
step_ignore:
  call	read_stdin
  mov	al,[kbuf]
  cmp	al,1bh			;esc?
  je	step_skip
  mov	ebx,2500		;2.5 seconds per beat
  mov	ecx,72
  cmp	al,'1'
  je	step_set		;jmp if 2.5
  mov	ebx,1250
  mov	ecx,144
  cmp	al,'2'
  je	step_set
  mov	ebx,625
  mov	ecx,288
  cmp	al,'4'
  je	step_set
  jmp	step_ignore

step_set:
  mov	[block+8],ebx
  mov	[block+12],ecx
	  
  mov	ecx,start_msg
  mov	edx,start_msg_length
  call	crt_write
  mov	esi,block
  call	metronome
step_skip:

  call	raw_set1
  call	key_flush
  call	raw_unset1

  mov	eax,[color]
  call	crt_clear

  mov	ecx,post_msg
  mov	edx,post_msg_length
  call	crt_write

  call	read_stdin
step_exit:
  mov	eax,1
  int	byte 80h
;------------
  [section .data]
block:
         dd 400	;tone frequency
         dd 50	;tone length in ms
         dd 2000 ;repeat every 2 seconds
         dd 90	;repeat for 3 minutes

color:	dd	30003734h

intro_msg:
 db 'STEP TEST',0ah,0ah
 db 'This test will measure cardiovascular endurance using a 12 inch',0ah
 db 'bench.  Step on and off the bench for 3 minutes using a rate of one',0ah
 db 'on-off step every 2.5 seconds.  After 3 minutes, count pulse to',0ah
 db 'deterine score.',0ah
 db 'Metronome will sound for 3 minutes then a table will be displayed',0ah
 db 0ah
 db 'To start the test, select the metronome style as follows:',0ah
 db '   1 beat per up-down step',0ah
 db '   2 beats per up-down step',0ah
 db '   4 beats per up-down step',0ah
 db 0ah
 db 'Enter (1,2,4 or ESC to skip metronome) '
intro_msg_end:
intro_msg_length equ intro_msg_end - intro_msg

start_msg:
 db 0ah
 db '-- TEST STARTED --  (any key aborts)',0ah
start_msg_end:
start_msg_length equ start_msg_end - start_msg
post_msg:
 db 0ah
 db 'MEASURE PULSE - Either count pulse for minute, or wait 5',0ah
 db 'seconds then count pulse for 15 seconds and multiply by 4',0ah
 db 'Use sex/age column to find score',0ah,0ah
 db '             ______________________males____________________ ',0ah
 db 'age->        18-25    26-35   36-45   46-55   56-65   65+    ',0ah
 db '             ----------------------------------------------- ',0ah
 db 'excel pulse   <79      <81     <83     <87     <86     <88   ',0ah
 db 'good pulse   79-89    81-89   83-96   87-97   86-97   88-96  ',0ah
 db 'aver+ pulse  90-99    90-99   97-103  98-105  98-103  97-103 ',0ah
 db 'aver pulse   100-105 100-107 104-112 106-116 104-112 104-113 ',0ah
 db 'aver- pulse  106-116 108-117 113-119 117-122 113-120 114-120 ',0ah 
 db 'poor pulse   117-128 118-128 120-130 123-132 121-129 121-130 ',0ah
 db 'bad pulse     >128    >128    >130    >132    >129    >130   ',0ah
 db 0ah
 db '             _________________females____________________',0ah
 db 'age->        18-25   26-35   36-45   46-55   56-65    65+',0ah
 db '             ----------------------------------------------',0ah
 db 'excel pulse   <85     <88     <90     <94     <95     <90',0ah
 db 'good pulse    85-98   88-99   90-102  94-104  95-104  90-102',0ah
 db 'aver+ pulse   99-108 100-111 103-110 105-115 105-112 103-115',0ah
 db 'aver pulse   109-117 112-119 111-118 116-120 113-118 116-122',0ah
 db 'aver- pulse  118-126 120-126 119-128 121-129 119-128 123-128',0ah 
 db 'poor pulse   127-140 127-138 129-140 130-135 129-139 120-134',0ah
 db 'bad pulse     >140    >138    >140    >135    >139    >134',0ah
 db 0ah
 db 'press any key to exit',0ah
post_msg_end:
post_msg_length equ post_msg_end - post_msg
 
  [section .text]


