
; each traced process has a status description 
; called "pids" which is defined below:

struc pids
.pid		resd 1 ;traced process id (pid)
.pid_status	resd 1 ;1=fork 2=stop1 4=stop2 8=dead 10h=run
                       ;20h=ffork  40h=show 80h=signal
.wait_status	resd 1 ;status from the "trace_wait" function
.r_sav_old_eax	resd 1
.r_old_eip	resd 1

.r_sav_ebx resd 1
.r_sav_ecx resd 1
;-- regsiter block start
.r_ebx	resd	1 
.r_ecx	resd	1

.r_edx	resd	1
.r_esi	resd	1
.r_edi	resd	1
.r_ebp	resd	1

.r_eax	resd	1 ;at start of fuction trap this register
                  ;contains 0ffffffdah (documented?).  We
                  ;use this information to detect starts.
.r_ds	resd	1

.r_es	resd	1
.r_fs	resd	1

.r_gs	resd	1
.r_old_eax resd	1 ;at start of function trap this register
                  ;contains function code (documented?)
.r_eip	resd	1
.r_cs	resd	1

.r_efl	resd	1
.r_esp	resd	1
.r_ss	resd	1
pids_struc_size:
endstruc
  