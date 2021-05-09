    .text



.globl g5_printf
g5_printf:
	sw $ra, -4($sp) # return address
	sw $fp, -8($sp) # frame pointer of caller
	move $fp, $sp # begin new frame
	subu $sp, $sp, 44 # expad frame - expect address of formatter
	sw $s0, -12($fp) # callee saved register
	sw $s1, -16($fp) # callee saved register
	sw $s2, -20($fp) # callee saved register
	sw $s3, -24($fp) # callee saved register
	sw $s4, -28($fp) # callee saved register
	sw $s5, -32($fp) # callee saved register
	sw $s6, -36($fp) # callee saved register
	sw $s7, -40($fp) # callee saved register

  lw  $s0,  0($sp) # $s0 = formatter
  li  $s3,  0      # storing offset from $sp for current argument

  # NOT using C-like return value
  li  $v1,  0   # retval = number of formatters printed so far

g5_printf_loop:                      # process each character in the fmt:
  # RISKY TO PUT CHARS INTO $a0
  lb    $s1,  0($s0)      # get the next character, and then
  addu  $s0,  $s0,  1     # bump up $s0 to the next character.
  beq   $s1,  '%',  g5_printf_fmt  # formatting directive
  beq   $s1,  $0,   g5_printf_ret  # if zero, then go to return

g5_printf_putc:
	move  $a0, $s1 # print character
  li  $v0,  11
  syscall
  b     g5_printf_loop       # loop on.

# %c, %s, %b, %o, %d, %ld, %lld, %x, %lx, %u, %lu, %llu, %%, %f, %lf, %Lf, %p
g5_printf_fmt:
  lb    $s2,  0($s0)              # see what the fmt character is,
  addu  $s0,  $s0,  1             # and bump up the pointer.
  beq   $s2,  'd',  g5_printf_int    # print as a decimal integer.
  beq   $s2,  's',  g5_printf_str    # print as a string.
  beq   $s2,  'c',  g5_printf_char   # print as an ASCII char.
  beq   $s2,  'f',  g5_printf_float   # print as a float
  li    $a0,  '%'    # if not matched, print as it is
  li  $v0,  11 # print character
  syscall
  move  $a0,  $s2
  li  $v0,  11 # print character
  syscall
  b     g5_printf_loop               # continue

g5_printf_char:
	subu	$s3, $s3, 4	# 4 = roundup[ sizeof (char) ]
  add  $s4, $sp,  $s3   # $s4 = argument address
  lb  $a0,  0($s4)
  li  $v0,  11 # print character
  syscall
  addu  $v1,  $v1,  1
  b     g5_printf_loop   # conitnue

g5_printf_int:
	subu	$s3, $s3, 4	# 4 = roundup[ sizeof (int) ]
  add  $s4, $sp,  $s3   # $s4 = argument address
  lw  $a0,  0($s4)
  li  $v0,  1 # print int
  syscall
  addu  $v1,  $v1,  1
  b     g5_printf_loop   # conitnue

g5_printf_float:
	subu	$s3, $s3, 4	# 4 = roundup[ sizeof (float) ]
  add  $s4, $sp,  $s3   # $s4 = argument address
  l.s  $f12,  0($s4)
  li  $v0,  2 # print float
  syscall
  addu  $v1,  $v1,  1
  b     g5_printf_loop   # conitnue

g5_printf_str:                     # deal with a %s:
	subu	$s3, $s3, 4	# 4 = roundup[ sizeof (char *) ]
  add  $s4, $sp,  $s3   # 
  lw  $a0,  0($s4)
  li  $v0,  4 # print string
  syscall
  addu  $v1,  $v1,  1
  b     g5_printf_loop   # conitnue

g5_printf_ret:
  move  $v0, $v1      # will see how to manage return value later
	lw $s7, -40($fp) # restore callee saved register
	lw $s6, -36($fp) # restore callee saved register
	lw $s5, -32($fp) # restore callee saved register
	lw $s4, -28($fp) # restore callee saved register
	lw $s3, -24($fp) # restore callee saved register
	lw $s2, -20($fp) # restore callee saved register
	lw $s1, -16($fp) # restore callee saved register
	lw $s0, -12($fp) # restore frame pointer of caller
	move $sp, $fp # close current frame
	lw $fp, -8($sp) # restore frame pointer of caller
	lw $ra, -4($sp) # restore return address
	jr $ra # return to caller

