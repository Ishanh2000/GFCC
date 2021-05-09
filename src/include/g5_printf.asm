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
  lb    $s1,  0($s0)              # see what the fmt character is,
  addu  $s0,  $s0,  1             # and bump up the pointer.
  beq   $s1,  'd',  g5_printf_int    # print as a decimal integer.
  beq   $s1,  's',  g5_printf_str    # print as a string.
  beq   $s1,  'c',  g5_printf_char   # print as an ASCII char.
  beq   $s1,  'f',  g5_printf_float   # print as a float
  beq   $s1,  'p',  g5_printf_ptr   # print as a pointer
  li    $a0,  '%'    # if not matched, print as it is
  li  $v0,  11 # print character
  syscall
  move  $a0,  $s1
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
  add  $s4, $sp,  $s3   # $s4 = argument address
  lw  $a0,  0($s4)
  li  $v0,  4 # print string
  syscall
  addu  $v1,  $v1,  1
  b     g5_printf_loop   # conitnue

g5_printf_ptr:
	subu	$s3, $s3, 4	# 4 = roundup[ sizeof (char *) ]
  add  $s4, $sp,  $s3   # $s4 = argument address
  lw  $a1,  0($s4) # load required pointer value

  li $v0, 11 # will only print characters throughout
  li $a0, '0' # print initial "0x"
  syscall
  li $a0, 'x'
  syscall

  li $s7, 28 # counter

  g5_printf_ptr_loop:
    srlv $a0, $a1, $s7
    andi $a0, $a0, 0xf # four LSBs

    bge $a0, 10, g5_printf_ptr_87
    addi $a0, $a0, 48 # 0 -> '0' = 48
    b g5_printf_ptr_hex

  g5_printf_ptr_87:
    addi $a0, $a0, 87 # 10 -> 'a' = 97

  g5_printf_ptr_hex:
    syscall
    addi $s7, $s7, -4
    bge $s7, 0, g5_printf_ptr_loop
    b g5_printf_loop

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


.globl g5_putc
g5_putc:
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

  lw $a0, 0($sp) # $s0 = character to print
  li $v0, 11 # print character
  syscall

g5_putc_ret:
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

