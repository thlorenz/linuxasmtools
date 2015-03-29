decode_index:
 dd access               ;                                                              (000)
 dd exit                 ; terminate the current process -----------------------------  (001)
 dd fork                 ; create a child process ------------------------------------  (002)
 dd read                 ; read from a file descriptor -------------------------------  (003)
 dd write                ; write to a file descriptor --------------------------------  (004)
 dd open                 ; open and possibly create a file or device -----------------  (005)
 dd close                ; close a file descriptor -----------------------------------  (006)
 dd waitpid              ; wait for process termination ------------------------------  (007)
 dd creat                ; create a file
 dd link                 ; make a new name for a file
 dd unlink               ; delete a name and possibly the file it refers to
 dd execve               ; execute program
 dd chdir                ; change working directory
 dd time                 ; get time in seconds
 dd mknod                ; create a special or ordinary file
 dd chmod                ; change permissions of a file
 dd lchown               ; change ownership of a file
 dd break                ; UNIMPLEMENTED
 dd oldstat              ; obsolete
 dd lseek                ; reposition read/write file offset
 dd getpid               ; process identification
 dd mount                ; mount and unmount filesystems --------------------------------(21)
 dd umount               ; mount and unmount filesystems
 dd setuid               ; set user identity
 dd getuid               ; get user identity 
 dd stime                ; set time
 dd ptrace               ; process trace
 dd alarm                ; set an alarm clock for delivery of a signal
 dd oldfstat             ; obsolete DO NOT USE
 dd pause_               ; wait for signal -----------------------------------------   (29)
 dd utime                ; change access and/or modification times
 dd stty                 ; UNIMPLEMENTED
 dd gtty                 ; UNIMPLEMENTED
 dd access_               ; check user's permissions for a file
 dd nice                 ; change process priority
 dd ftime                ; UNIMPLEMENTED return date and time
 dd sync                 ; commit buffer cache to disk
 dd kill                 ; send signal to a process
 dd rename               ; change the name or location of a file
 dd mkdir                ; create a directory
 dd rmdir                ; delete a directory
 dd dup                  ; duplicate a file descriptor
 dd pipe                 ; create pipe
 dd times_               ; get process times
 dd prof                 ; UNIMPLEMENTED
 dd brk                  ; change data segment size
 dd setgid               ; set group identity
 dd getgid               ; get group identity ----------------------------------------------  (47)
 dd signal               ; ANSI C signal handling
 dd geteuid              ; get user identity
 dd getegid              ; get group identity
 dd acct                 ; switch process accounting on or off
 dd umount2              ; mount and unmount filesystems
 dd lock_                ; UNIMPLEMENTED
 dd ioctl                ; control device
 dd fcntl                ; manipulate file descriptor
 dd mpx                  ; UNIMPLEMENTED
 dd setpgid              ; set process group 
 dd ulimit               ; UNIMPLEMENTED
 dd oldolduname          ; obsolete
 dd umask                ; set file creation mask
 dd chroot               ; change root directory
 dd ustat                ; get file system statistics 
 dd dup2                 ; duplicate a file descriptor
 dd getppid              ; get process identification -----------------------------------  (64)
 dd getpgrp              ; set/get process group
 dd setsid               ; creates a session and sets the process group ID
 dd sigaction            ; POSIX signal handling
 dd sgetmask             ; retrieves the signal mask of the set of currently blocked signals
 dd ssetmask             ; sets the signal mask of the set of currently blocked signals
 dd setreuid             ; set real and/or effective user ID
 dd setregid             ; set real and / or effective group ID
 dd sigsuspend           ; POSIX signal handling functionsx
 dd sigpending           ; POSIX signal handling functions
 dd sethostname          ; set host name 
 dd setrlimit            ; set resource limits and usage
 dd getrlimit            ; get resource limits and usage
 dd getrusage            ; get resource limits and usage
 dd gettimeofday         ; get time
 dd settimeofday         ; set time
 dd getgroups            ; get list of supplementary group IDs
 dd setgroups            ; set list of supplementary group IDs
 dd select               ; synchronous I/O -----------------------------------------------------  (82)
 dd symlink              ; make a new name for a file
 dd oldlstat             ; obsolete
 dd readlink             ; read value of a symbolic link
 dd uselib               ; select shared library
 dd swapon               ; start/stop swapping to file/device
 dd reboot               ; reboot or enable/disable Ctrl-Alt-Del
 dd readdir              ; read directory entry
 dd mmap                 ; map or unmap files or devices into memory
 dd munmap               ; unmap files or devices into memory
 dd truncate             ; truncate file to specified length 
 dd ftruncate            ; truncate file to specified length 
 dd fchmod               ; change permissions of a file
 dd fchown               ; change ownership of a file 
 dd getpriority          ; get program scheduling priority
 dd setpriority          ; set program scheduling priority
 dd profil               ; UNIMPLEMENTED execution time profile
 dd statfs               ; get file system statistics
 dd fstatfs              ; get file system statistics
 dd ioperm               ; set port input/output permissions  -----------------------------------  (101)
 dd socketcall           ; socket system calls
 dd syslog               ; read and/or clear kernel message ring buffer
 dd setitimer            ; set an interval timer
 dd getitimer            ; get  value of an interval timer
 dd stat                 ; get file status
 dd lstat                ; get file status
 dd fstat                ; get file status
 dd olduname             ; obsolete
 dd iopl                 ; change I/O privilege level
 dd vhangup              ; virtually hangup the current tty
 dd idle                 ; make process 0 idle
 dd vm86old              ; enter virtual 8086 mode
 dd wait4                ; wait for process termination, BSD style -------------------------------  (114)
 dd swapoff              ; stop swapping to file/device
 dd sysinfo              ; returns information on overall system statistics
 dd ipc                  ; System V IPC system calls
 dd fsync                ; synchronize  a file's complete in-core state with
 dd sigreturn            ; return from signal handler and cleanup stack frame
 dd clone                ; create a child process
 dd setdomainname        ; get/set domain name
 dd uname                ; get name and information about current kernel
 dd modify_ldt           ; get or set ldt
 dd adjtimex             ; tune kernel clock  (124)
 dd mprotect             ; control allowable accesses to a region of memory
 dd sigprocmask          ; POSIX signal handling functions
 dd create_module        ; create a loadable module entry
 dd init_module          ; initialize a loadable module entry
 dd delete_module        ; delete a loadable module entry 
 dd get_kernel_syms      ; retrieve exported kernel and module symbols  ------------------------ (130)
 dd quotactl             ; manipulate disk quotas
 dd getpgid              ; set/get process group
 dd fchdir               ; change working directory
 dd bdflush              ; start, flush, or tune buffer-dirty-flush daemon
 dd sysfs                ; get file system type information -------------------------------------  (135)
 dd personality          ; set the process execution domain
 dd afs_syscall          ; UNIMPLEMENTED 
 dd setfsuid             ; set user identity used for file system checks
 dd setfsgid             ; set group identity used for file system checks
 dd llseek               ; reposition read/write file offset
 dd getdents             ; get directory entries
 dd newselect            ; sync I/O multiplexing
 dd flock                ; apply or remove an advisory lock on an open file
 dd msync                ; synchronize a file with a memory map
 dd readv                ; read data into multiple buffers  -------------------------------------- (145)
 dd writev               ; read or write a vector
 dd getsid               ; get session ID
 dd fdatasync            ; synchronize a file's in-core data with that on disk
 dd sysctl               ; read/write system parameters
 dd mlock                ; disable paging for some parts of memory 
 dd munlock              ; reenable paging for some parts of memory
 dd mlockall             ; disable paging for calling process
 dd munlockall           ; reenable paging for calling process
 dd sched_setparam       ; set scheduling parameters
 dd sched_getparam       ; get scheduling parameters
 dd sched_setscheduler   ; set scheduling algo/param
 dd sched_getscheduler   ; get scheduling algo/param
 dd sched_yield          ; yield the processor
 dd sched_get_priority_max ;get maximum priority value
 dd sched_get_priority_min ; get minimum priority value ----------------------------------------------- (160)
 dd sched_rr_get_interval; get the SCHED_RR interval for the named process
 dd nanosleep            ; pause execution for a specified time
 dd mremap               ; re-map a virtual memory address
 dd setresuid            ; set real user ID
 dd getresuid            ; get real, effective and saved user or group ID
 dd vm86                 ; enter virtual 8086 mode
 dd query_module         ; query the kernel for bits pertaining to modules
 dd poll                 ; wait for some event on a file descriptor
 dd nfsservctl           ; syscall interface to kernel nfs daemon
 dd setresgid            ; set real/effective/saved set-group ID
 dd getresgid            ; get real/effective/saved set-group ID
 dd prctl                ; operations on a process
 dd rt_sigreturn         ; real time sigreturn  -------------------------------------------------------- (173)
 dd rt_sigaction         ; setup rt sighnd (RTL)
 dd rt_sigprocmask       ; real time sigprocmask
 dd rt_sigpending        ; real time sigaction
 dd rt_sigtimedwait      ; real time sigtimedwait
 dd rt_sigqueueinfo      ; real time sigqueueingo
 dd rt_sigsuspend        ; real time sigsuspend
 dd pread64              ; read/write without moving file descriptor
 dd pwrite64             ; write to file descriptor at offset
 dd chown                ; change ownership of a file
 dd getcwd               ; get current working directory
 dd capget               ; get process capabilities
 dd capset               ; set process capabilities
 dd sigaltstack          ; get or set alternate signal stack content
 dd sendfile             ; transfer data between file descriptors  ---------------------------------------- (187)
 dd getpmsg              ; UNIMPLEMENTED
 dd putpmsg              ; UNIMPLEMENTED
 dd vfork                ; create a child process and block parent
 dd ugetrlimit           ; UNIMPLEMENTED
 dd mmap2                ; map files or devices into memory
 dd truncate64           ; truncates file to the specified length (LFS version of truncate)
 dd ftruncate64          ; truncates file to the specified length (LFS version of ftruncate)
 dd stat64               ; obtains information about a file (LFS version of stat)
 dd lstat64              ; obtains information about a file (LFS version of lstat)
 dd fstat64              ; obtains information about a file (LFS version of fstat) --------------------------- (197)
 dd lchown32             ; UNIMPLEMENTED
 dd getuid32             ; UNIMPLEMENTED
 dd getgid32             ; UNIMPLEMENTED
 dd geteuid32            ; UNIMPLEMENTED
 dd getegid32            ; UNIMPLEMENTED
 dd setreuid32           ; UNIMPLEMENTED
 dd setregid32           ; UNIMPLEMENTED
 dd getgroups32          ; UNIMPLEMENTED
 dd setgroups32          ; UNIMPLEMENTED
 dd fchown32             ; UNIMPLEMENTED
 dd setresuid32          ; UNIMPLEMENTED
 dd getresuid32          ; UNIMPLEMENTED
 dd setresgid32          ; UNIMPLEMENTED
 dd getresgid32          ; UNIMPLEMENTED
 dd chown32              ; UNIMPLEMENTED
 dd setuid32             ; UNIMPLEMENTED  ------------------------------------------------------------------------ (213)
 dd setgid32             ; UNIMPLEMENTED
 dd setfsuid32           ; UNIMPLEMENTED
 dd setfsgid32           ; UNIMPLEMENTED
 dd pivot_root           ; change the root file system
 dd mincore              ; get information on whether pages are in core 
 dd madvise              ; give advice about use of memory  ------------------------------------------------------ (219)
 dd getdents64           ; get directory entries (LFS version of getdents)
 dd fcntl64              ; do operations on a file descriptor (LFS version of fcntl)
 dd rsbac                ; 
 dd security             ;                              ----------------------------------------------------------- (223)
 dd gettid               ; get thread identification  (224)
 dd readahead            ; read in advance one or more pages
 dd setxattr             ; set an extended attribute value
 dd lsetxattr            ; set extended attributes
 dd fsetxattr            ; set extended attribute
 dd getxattr             ; retrieve an extended attribute value
 dd lgetxattr            ; get extended attribute
 dd fgetxattr            ; get extended attribute
 dd listxattr            ; list extended attribute names
 dd llistxattr           ; list extended attributes
 dd flistxattr           ; list extended attribute
 dd removexattr          ; remove an extended attribute
 dd lremovexattr         ; remove extended attributes  (236)
 dd fremovexattr         ; remove extended attribute
 dd tkill                ; send a signal to a single process
 dd sendfile64           ; transfer data between file descriptors (LFS version of sendfile)
 dd futex                ; Fast Userspace Locking system call
 dd sched_setaffinity    ; set a process's CPU affinity mask
 dd sched_getaffinity    ; get a process's CPU affinity mask
 dd set_thread_area      ; set a Thread Local Storage (TLS) area
 dd get_thread_area      ; get a Thread Local Storage (TLS) area 
 dd io_setup             ; Create an asynchronous I/O context
 dd io_destroy           ; Destroy an asynchronous I/O context 
 dd io_getevents         ; Read asynchronous I/O events from the completion queue
 dd io_submit            ; Submit asynchronous I/O blocks for processing  (248)
 dd io_cancel            ; Cancel an outstanding asynchronous I/O operation
 dd fadvise64            ; gives the kernel an 'advice' on how it should use a file handle
 dd unknown              ; 
 dd exit_group           ; exit all process's in group
 dd lookup_dcookie       ; return a directory entry's path
 dd epoll_create         ; open an epoll file descriptor
 dd epoll_ctl            ; control interface for an epoll descriptor
 dd epoll_wait           ; wait for an I/O event on an epoll file descriptor
 dd remap_file_pages     ; create a non-linear file mapping
 dd set_tid_address      ; set pointer to thread ID
 dd timer_create         ;                              (259)
 dd timer_settime        ; 
 dd timer_gettime        ; 
 dd timer_getoverrun     ; 
 dd timer_delete         ; 
 dd clock_settime        ; set specified time
 dd clock_gettime        ; get specified time
 dd clock_getres         ; get clock precision 
 dd clock_nanosleep      ; process sleep
 dd statfs64             ; obtain information about mounted file system (LFS version of statfs)
 dd fstatfs64            ; obtain information about mounted file system (LFS version of fstatfs)
 dd tgkill               ; send signal to one specific thread            (270)
 dd utimes               ; change access and/or modification times of an inodetimes    
 dd fadvise64_64         ; gives the kernel an 'advice' on how it should use a file handle
 dd vserver              ; UNIMPLEMENTED
 dd mbind                ; set NUMA memory policy for a memory range
 dd get_mempolicy        ; get NUMA memory policy for a process
 dd set_mempolicy        ; set NUMA memory policy for a process  (276)
 dd mq_open              ; create a new POSIX message queue or open an existing queue
 dd mq_unlink            ; 
 dd mq_timedsend         ; 
 dd mq_timedreceive      ; 
 dd mq_notify            ; enable/disable notifications for POSIX message queues
 dd mq_getsetattr        ; get or set message queue attributes
 dd kexec_load           ; 
 dd waitid               ; suspend execution of the current process until a child has changed state (284)
 dd unknown
 dd add_key              ; creates a new key and add it to the nominated keyring (286)
 dd unknown
 dd keyctl               ; kernel's key management facility manipulation functions
 dd ioprio_set           ; set the I/O scheduling class and priority of one or more processes
 dd ioprio_get           ; get the I/O scheduling class and priority of one or more processes
 dd inotify_init         ; initialize a new inotify instance 
 dd inotify_add_watch    ; add a watch to or modify an existing watch of an initialized inotify instance
 dd inotify_rm_watch     ; removes an existing watch from an inotify instance (293)
 dd unknown
 dd openat               ; opens and possibly creates a file or device relative to a directory file descriptor (295)
 dd mkdirat              ; create a directory relative to a directory file descriptor
 dd mknodat              ; create a filesystem node relative to a directory file descriptor
 dd fchownat             ; change ownership of a file relative to a directory file descriptor
 dd futimesat            ; change the access/modification times of an file relative to a directory desriptor
 dd unknown
 dd unlinkat             ; remove a directory entry relative to a directory file descriptor (301)
 dd renameat             ; rename a file relative to directory file descriptors
 dd linkat               ; create a file link relative to directory file descriptors
 dd symlinkat            ; create a symbolic link relative to a directory file descriptor
 dd readlink_            ; reads value of a symbolic link relative to a directory file descriptor
 dd fchmodat             ; change S_ISUID, S_ISGID, S_ISVTX, and permission bits of a file 
 dd faccessat            ; determine accessibility of a file relative to a directory file descriptor
 dd unknown
 dd ppoll                ; wait for an event on a file descriptor or until a signal is caught
 dd unshare              ; allow a process to disassociate parts of its execution context 
 dd unknown		;(311)
 dd unknown		;(312)
 dd unknown		;(313)
 dd sync_file_range      ; synchronize a file segment with disk  (314)
 dd unknown		;(315)
 dd unknown
 dd unknown
 dd unknown
 dd unknown
 dd unknown
 dd unknown
 dd unknown
 dd unknown


