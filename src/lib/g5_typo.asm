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
    subu	$s3, $s3, 4	# 4 = roundup[ sizeof (*) ]
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
    move $v0, $v1    # will see how to manage return value later
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


.globl g5_getc # TODO: bad working of this function -- will troubleshoot later
g5_getc:
    sw $ra, -4($sp) # return address
    sw $fp, -8($sp) # frame pointer of caller
    move $fp, $sp # begin new frame
    subu $sp, $sp, 40 # expad frame - expect address of formatter
    sw $s0, -12($fp) # callee saved register
    sw $s1, -16($fp) # callee saved register
    sw $s2, -20($fp) # callee saved register
    sw $s3, -24($fp) # callee saved register
    sw $s4, -28($fp) # callee saved register
    sw $s5, -32($fp) # callee saved register
    sw $s6, -36($fp) # callee saved register
    sw $s7, -40($fp) # callee saved register

    li $v0, 12
    syscall # $v0 = char
    
  g5_getc_ret:
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


.globl g5_scanf
g5_scanf:
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
    li  $v1,  0      # retval = number of formatters scanned so far

  g5_scanf_loop:                      # process each character in the fmt:
    # RISKY TO PUT CHARS INTO $a0
    lb    $s1,  0($s0)      # get the next character, and then
    addu  $s0,  $s0,  1     # bump up $s0 to the next character.
    beq   $s1,  '%',  g5_scanf_fmt  # formatting directive
    beq   $s1,  $0,   g5_scanf_ret  # if zero, then go to return
    b g5_scanf_loop # nothing to do, simply go to next char

  g5_scanf_fmt:
    lb    $s1,  0($s0)   # see what the fmt character is,
    addu  $s0,  $s0,  1  # and bump up the pointer.
    beq   $s1,  'd',  g5_scanf_int   # scan as a decimal integer.
    beq   $s1,  's',  g5_scanf_str   # scan as a string.
    beq   $s1,  'c',  g5_scanf_char  # scan as an ASCII char.
    beq   $s1,  'f',  g5_scanf_float # scan as a float
    beq   $s1,  'p',  g5_scanf_ptr   # scan as a pointer (but like a string - will need explanation)
    b     g5_scanf_loop # continue if not matched

  g5_scanf_char:
    subu	$s3,  $s3,  4	    # 4 = sizeof (address)
    add   $s4,  $sp,  $s3   # $s4 = argument address
    lw    $s4,  0($s4)      # $s4 = destination of contents
    li    $v0,  12          # read character
    syscall                 # $v0 = char
    sw    $v0,  0($s4)      # store into desired location
    addu  $v1,  $v1,  1
    b     g5_scanf_loop     # conitnue

  g5_scanf_int:
    subu	$s3,  $s3,  4	    # 4 = sizeof (address)
    add   $s4,  $sp,  $s3   # $s4 = argument address
    lw    $s4,  0($s4)      # $s4 = destination of contents
    li    $v0,  5           # read int
    syscall                 # $v0 = int
    sw    $v0,  0($s4)      # store into desired location
    addu  $v1,  $v1,  1
    b     g5_scanf_loop     # conitnue

  g5_scanf_float:
    subu	$s3,  $s3,  4	    # 4 = sizeof (address)
    add   $s4,  $sp,  $s3   # $s4 = argument address
    lw    $s4,  0($s4)      # $s4 = destination of contents
    li    $v0,  6           # read float
    syscall                 # $f0 = float
    s.s   $f0,  0($s4)      # store into desired location
    addu  $v1,  $v1,  1
    b     g5_scanf_loop     # conitnue

  g5_scanf_str:             # deal with a %s:
    subu	$s3,  $s3,  4	    # 4 = sizeof (address)
    add   $s4,  $sp,  $s3   # $s4 = argument address
    lw    $s4,  0($s4)      # $s4 = destination of contents
    
    g5_scanf_str_loop:
      # RISKY LOOPING - MAY OVERWRITE UNINTENDED MEMORY AREAS
      li    $v0,  12        # get char
      syscall
      # \0, \t, \b, \v, \n, [SPACE] (add more ...)
      beq   $v0,  0x00,  g5_scanf_str_terminate   # \0 (EOF/NULL)
      beq   $v0,  0x08,  g5_scanf_str_terminate   # \b
      beq   $v0,  0x09,  g5_scanf_str_terminate   # \t
      beq   $v0,  0x0b,  g5_scanf_str_terminate   # \v
      beq   $v0,  0x0a,  g5_scanf_str_terminate   # \n
      beq   $v0,  0x20,  g5_scanf_str_terminate   # [SPACE]
      sb    $v0,  0($s4)        # *($s4) = char
      addi  $s4,  $s4,  1
      b     g5_scanf_str_loop

    g5_scanf_str_terminate:
      li    $v0,  0         # simply append '\0' at the end
      sb    $v0,  0($s4)
      addu  $v1,  $v1,  1
    b     g5_scanf_loop   # conitnue    

  g5_scanf_ptr:             # deal with a %p:
    subu	$s3,  $s3,  4	    # 4 = sizeof (address)
    add   $s4,  $sp,  $s3   # $s4 = argument address
    lw    $s4,  0($s4)      # $s4 = destination of contents
    li    $s6,  0x0         # clear contents - progressively compute pointer

    g5_scanf_ptr_loop:
      # RISKY LOOPING - MAY OVERWRITE UNINTENDED MEMORY AREAS
      li    $v0,  12        # get char
      syscall

      ble   $v0,  47, g5_scanf_ptr_cond_1
      bge   $v0,  58, g5_scanf_ptr_cond_1
      sub   $v0,  $v0,  48  # $v0 now ranges 0 to 9
      b     g5_scanf_ptr_append

    g5_scanf_ptr_cond_1:
      ble   $v0,  64, g5_scanf_ptr_cond_2
      bge   $v0,  71, g5_scanf_ptr_cond_2
      sub   $v0,  $v0,  55  # $v0 now ranges 10 to 15
      b     g5_scanf_ptr_append
    
    g5_scanf_ptr_cond_2:
      ble   $v0,  96, g5_scanf_ptr_terminate
      bge   $v0, 103, g5_scanf_ptr_terminate
      sub   $v0,  $v0,  87  # $v0 now ranges 10 to 15
      b     g5_scanf_ptr_append
    
    g5_scanf_ptr_append:
      sll   $s6,  $s6,  4     # shift left by 4 bits (aka multiply by 16)
      add   $s6,  $s6,  $v0   # add appropriate 4 bits to the cleared space
      b     g5_scanf_ptr_loop
    
    g5_scanf_ptr_terminate:
      sw    $s6,  0($s4)      # finally store word at desired location
      b     g5_scanf_loop     # conitnue

  g5_scanf_ret:
    move $v0, $v1    # will see how to manage return value later
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

