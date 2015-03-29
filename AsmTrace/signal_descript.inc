
  [section .data]

SIGHUP_msg: db    'SIGHUP  ' ;1
SIGINT_msg: db    'SIGINT  '
SIGQUIT_msg: db   'SIGQUIT '
SIGILL_msg: db    'SIGILL  '
SIGTRAP_msg: db   'SIGTRAP ' ;5
SIGABRT_msg: db   'SIGABRT '
SIGBUS_msg: db    'SIGBUS  '
SIGFPE_msg: db    'SIGFPE  '
SIGKILL_msg: db   'SIGKILL '
SIGUSR1_msg: db   'SIGUSR1 ' ;10
SIGSEGV_msg: db   'SIGSEGV ' ;11
SIGUSR2_msg: db   'SIGUSR2 ' ;12
SIGPIPE_msg: db   'SIGPIPE '
SIGALRM_msg: db   'SIGALRM '
SIGTERM_msg: db   'SIGTERM '
SIGSTKFLT_msg: db 'SIGSTKFL'
SIGCHLD_msg: db   'SIGCHLD ' ;17
SIGCONT_msg: db   'SIGCONT '
SIGSTOP_msg: db   'SIGSTOP '
SIGTSTP_msg: db   'SIGTSTP '
SIGTTIN_msg: db   'SIGTTIN '
SIGTTOU_msg: db   'SIGTTOU '
SIGURG_msg: db    'SIGURG  '
SIGXCPU_msg: db   'SIGXCPU '
SIGXFSZ_msg: db   'SIGXFSZ '
SIGVTALRM_msg: db 'SIGVTALR'
SIGPROF_msg: db   'SIGPROF '
SIGWINCH_msg: db  'SIGWINCH'
SIGIO_msg: db     'SIGIO   '
  [section .text]