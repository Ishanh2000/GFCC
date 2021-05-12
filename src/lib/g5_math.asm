    .text

.globl g5_abs					# int g5_abs(int x);
g5_abs:
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

	lw $t0, 0($sp)						# $t0 = x;
	bge $t0, $0, g5_abs_ret		# x >= 0 (so do nothing)
	subu $t0, $0, $t0					# x = -x

g5_abs_ret:
	move $v0, $t0
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


.globl g5_fact					# int g5_fact(int x);
g5_fact:
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

	lw $s0, 0($sp)              # $t0 = x;
	blt $s0, $0, g5_fact_ret_0  # x < 0
	ble $s0,  1, g5_fact_ret_1  # x <= 1

	move $s1, $s0          # $s1 = $s0 = x
	subu $s1, $s1, 1       # $s1 = x - 1
	sw $s1, -44($sp)       # load parameter (x-1) as argument (function call)
	jal g5_fact            # recursive call
	# now, $v0 = g5_fact(x-1)
	mul $v0, $s0, $v0      # $v0 = x * g5_fabs(x-1) = g5_fabs(x)
	b g5_fact_ret

	g5_fact_ret_0:         # return 0
	li $v0, 0
	b g5_fact_ret

	g5_fact_ret_1:         # return 1
	li $v0, 1
	b g5_fact_ret

g5_fact_ret:
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


.globl g5_fib					# int g5_fib(int x);
g5_fib:
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

	lw $s0, 0($sp)              # $t0 = x;
	blt $s0, $0, g5_fib_neg  		# x < 0
	ble $s0,  1, g5_fib_01 			# x <= 1

	# $t0 = y, $t1 = y_1, $t2 = y_2, $t3 = tmp, $t4 = curr
	li $t2, 0 							# y_2  = 0
	li $t1, 1 							# y_1  = 1
	li $t0, 1 							# y    = 1
	li $t4, 2 							# curr = 2

	g5_fib_loop:											# while loop
		beq $t4, $s0, g5_fib_reg_ret 		# curr == x
		addu $t3, $t1, $t0 							# tmp = y_1 + y
		move $t2, $t1										# y_2 = y_1
		move $t1, $t0										# y_1 = y
		move $t0, $t3										# y   = tmp
		addi $t4, $t4, 1								# curr++
		b g5_fib_loop										# goto while-loop condition check

	g5_fib_reg_ret:
		move $v0, $t0	# $v0 = $t0 = y
		b g5_fib_ret	# return y

	g5_fib_neg:								# x < 0
		subu $s1, $0, $s0 			# $s1 = -x
		sw $s1, -44($sp)  			# load func param (-x)
		jal g5_fib        			# now, $v0 = fib(-x)
		andi $t0, $s0, 0x1 			# $t0 = isOdd(x)
		beq $t0, 1, g5_fib_ret 	# return fib(-x)
		subu $v0, $0, $v0				# $v0 = -fib(-x)
		b g5_fib_ret						# return -fib(-x)

	g5_fib_01:								# x <= 1
		move $v0, $s0						# $v0 = x
		b g5_fib_ret						# return x

g5_fib_ret:
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


