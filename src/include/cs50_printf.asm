## Daniel J. Ellard -- 03/13/94
## g5_printf.asm -- an implementation of a simple g5_printf work-alike.
## g5_printf-- A simple g5_printf-like function. Understands just the basic
## forms of the %s, %d, %c, and %% formats, and can only have 3 embedded
## formats (so that all of the parameters are passed in registers).
## If there are more than 3 embedded formats, all but the first 3 are
## completely ignored (not even printed).
##
## Register Usage:
##   $a0, $s0 - pointer to format string
##   $a1, $s1 - format argument 1 (optional)
##   $a2, $s2 - format argument 2 (optional)
##   $a3, $s3 - format argument 3 (optional)
##        $s4 - count of formats processed.
##        $s5 - char at $s4.
##        $s6 - pointer to g5_printf buffer
##
          .text
          .globl g5_g5_printf

g5_g5_printf:
          subu  $sp,  $sp,  36    # set up the stack frame,
          sw    $ra,  32($sp)     # saving the local environment.
          sw    $fp,  28($sp)
          sw    $s0,  24($sp)
          sw    $s1,  20($sp)
          sw    $s2,  16($sp)
          sw    $s3,  12($sp)
          sw    $s4,  8($sp)
          sw    $s5,  4($sp)

          sw    $s6,  0($sp)
          addu  $fp,  $sp,  36


                                  # grab the arguments:
          move  $s0,  $a0         # fmt string
          move  $s1,  $a1         # arg1 (optional)
          move  $s2,  $a2         # arg2 (optional)
          move  $s3,  $a3         # arg3 (optional)

          li    $s4,  0           # set # of formats = 0
          la    $s6,  g5_printf_buf  # set s6 = base of g5_printf buffer.

g5_printf_loop:                      # process each character in the fmt:
          lb    $s5,  0($s0)      # get the next character, and then
          addu  $s0,  $s0,  1     # bump up $s0 to the next character.

          beq   $s5,  '%',  g5_printf_fmt  # if the fmt character, then do fmt.
          beq   $0,   $s5,  g5_printf_end  # if zero, then go to end.

g5_printf_putc:
          sb    $s5,  0($s6)      # otherwise, just put this char
          sb    $0,   1($s6)      # into the g5_printf buffer,
          move  $a0,  $s6         # and then print it with the
          li    $v0,  4           # print_str syscall
          syscall

          b     g5_printf_loop       # loop on.

g5_printf_fmt:
          lb    $s5,  0($s0)              # see what the fmt character is,
          addu  $s0,  $s0,  1             # and bump up the pointer.
          beq   $s4,  3,  g5_printf_loop     # if we’ve already processed 3 args,
                                          # then *ignore* this fmt.
          beq   $s5,  'd',  g5_printf_int    # print as a decimal integer.
          beq   $s5,  's',  g5_printf_str    # print as a string.
          beq   $s5,  'c',  g5_printf_char   # print as an ASCII char.
          beq   $s5,  '%',  g5_printf_perc   # print a '%'.
          b     g5_printf_loop               # otherwise, just continue

g5_printf_shift_args:              # shift over the fmt args.
          move  $s1,  $s2       # $s1 = $s2
          move  $s2,  $s3       # $s2 = $s3
          add   $s4,  $s4,  1   # increment # of args processed.

          b     g5_printf_loop     # and continue the main loop.

g5_printf_int:                     # deal with a %d:
          move  $a0,  $s1       # do a print_int syscall of $s1.
          li    $v0,  1
          syscall
          b g5_printf_shift_args   # branch to g5_printf_shift_args

g5_printf_str:                     # deal with a %s:
          move  $a0,  $s1       # do a print_string syscall of $s1.
          li    $v0,  4
          syscall
          b     g5_printf_shift_args   # branch to g5_printf_shift_args

g5_printf_char:                    # deal with a %c:
          sb    $s1,  0($s6)    # fill the buffer in with byte $s1,
          sb    $0,   1($s6)    # and then a null.
          move  $a0,  $s6       # and then do a print_str syscall
          li    $v0,  4         # on the buffer.
          syscall
          b     g5_printf_shift_args   # branch to g5_printf_shift_args

g5_printf_perc:                    # deal with a %%:
          li    $s5,  '%'       # (this is redundant)
          sb    $s5,  0($s6)    # fill the buffer in with byte %,
          sb    $0,   1($s6)    # and then a null.
          move  $a0,  $s6       # and then do a print_str syscall
          li    $v0,  4         # on the buffer.
          syscall
          b     g5_printf_loop     # branch to g5_printf_loop (WHY?? -- ISHANH MISRA)

## SIMILARLY TRY FOR FLOAT (%f), DOUBLE (%lf), BACKSLASH (\\), INVERTED COMMAS (\', \"), etc.

g5_printf_end:
        lw      $ra,  32($sp)   # restore the prior environment:
        lw      $fp,  28($sp)
        lw      $s0,  24($sp)
        lw      $s1,  20($sp)
        lw      $s2,  16($sp)
        lw      $s3,  12($sp)
        lw      $s4,  8($sp)
        lw      $s5,  4($sp)
        lw      $s6,  0($sp)
        addu    $sp,  $sp,  36  # release the stack frame.
        jr      $ra             # return

        .data
g5_printf_buf:     .space  2
## end of g5_printf.asm



