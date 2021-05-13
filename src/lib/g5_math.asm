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


.globl g5_intpow					# float g5_intpow(float x, int N);
g5_intpow:
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

	lw $s0, -4($sp)              		# $s0 = N;
	l.s $f0, 0($sp)              		# $f0 = x; (float)
	cvt.d.s $f0, $f0								# $f0 = x; (double)
	li.d $f8, 1.0										# $f8 = ret = 1.0

	beq $s0, $0, g5_intpow_ret_1    # N == 0
	bgt $s0, $0, g5_intpow_loop			# N > 0
	# reached here : means N < 0
	subu $s0, $0, $s0								# N = -N
	div.d $f0, $f8, $f0							# x = 1.0 / x

	g5_intpow_loop:											# while loop
		beq $s0, 0, g5_intpow_reg_ret			# N == 0 => exit while loop
		mul.d $f8, $f8, $f0								# ret *= x
		subu $s0, $s0, 1									# N--
		b g5_intpow_loop									# goto while-loop condition check

	g5_intpow_reg_ret:
		mov.d $f0, $f8			# $f0 = ret (double)
		cvt.s.d $f0, $f0		# $f0 = ret (float)
		b g5_intpow_ret			# return ret

	g5_intpow_ret_1:
		li.s $f0, 1.0 				# $f0 = 1.0 (float)
		b g5_intpow_ret				# return 1.0 (float)

g5_intpow_ret:
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


.globl g5_fabs					# float g5_fabs(float x);
g5_fabs:
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
	
	l.s $f0, 0($sp)           # $f0 = x; (float)
	cvt.d.s $f0, $f0					# $f0 = x; (double)
	abs.d $f0, $f0						# $f0 = abs(x) (double)
	cvt.s.d $f0, $f0					# $f0 = abs(x) (float)

g5_fabs_ret:
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



.globl g5_sqrt					# float g5_sqrt(float x);
g5_sqrt:
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

	li $s0, 0              							# $s0 = count = 0;
	l.s $f2, 0($sp)           					# $f2 = x; (float)
	cvt.d.s $f2, $f2										# $f2 = x; (double)
	li.d $f0, 0.0												# $f0 = 0.0 (double) for comparison
	l.s $f12, global___GFCC_M_PREC__		# $f12 = precision (float)
	cvt.d.s $f12, $f12									# $f12 = precision (double)
	li.d $f10, 2.0											# $f10 = 2.0 (double) for division

	c.le.d $f2, $f0						# x <= 0.0 : then return 0.0
	bc1t g5_sqrt_ret_0

	mov.d $f4, $f2						# ($f4 = r) = ($f2 = x)

	g5_sqrt_loop:
		mul.d $f6, $f4, $f4								# r * r
		sub.d $f6, $f2, $f6								# x - r * r
		abs.d $f6, $f6										# |x - r*r|
		c.le.d $f6, $f12									# |x - r*r| <= precision
		bc1t g5_sqrt_reg_ret							# return r normally
		move $s1, $s0											# $s1 = count (copied)
		addu $s0, $s0, 1									# count++
		bgt $s0, 1024, g5_sqrt_reg_ret 		# return r normally
		div.d $f6, $f2, $f4								# $f6 = x / r
		add.d $f6, $f4, $f6								# $f6 = r + (x / r)
		div.d $f4, $f6, $f10							# r = (r + (x/r))/2.0
		b g5_sqrt_loop
	
	g5_sqrt_reg_ret:
		mov.d $f0, $f4			# $f0 = r (double)
		cvt.s.d $f0, $f0		# $f0 = r (float)
		b g5_sqrt_ret			# return ret

	g5_sqrt_ret_0:
		li.s $f0, 0.0 			# $f0 = 0.0 (float)
		b g5_sqrt_ret				# return 0.0 (float)

g5_sqrt_ret:
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


.globl g5_exp					# float g5_exp(float x);
g5_exp:
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

	li.d $f0, 0.0			# $f0 = 0.0 (double) for comparison
	l.s $f12, global___GFCC_M_PREC__		# $f12 = precision (float)
	cvt.d.s $f12, $f12									# $f12 = precision (double)
	li.d $f14, 500.0	# $f14 = 500.0 (double) for comparison
	li.d $f16, 1.0		# $f16 = 1.0 (double) for incrementing N
	
	l.s $f2, 0($sp)   # $f2 = x; (float)
	cvt.d.s $f2, $f2	# $f2 = x; (double)

	c.lt.d $f2, $f0				# x < 0.0
	bc1t g5_exp_neg
	c.le.d $f2, $f14			# x <= 500.0
	bc1f g5_exp_ret_500		# x > 500.0 : then return INFINITY

	# $f2 = x, $f4 = ret, $f6 = term_N, $f8 = N
	li.d $f4, 0.0							# $f4 = ret = 0.0 (double)
	li.d $f6, 1.0							# $f6 = term_N = 1.0 (double)
	li.d $f8, 0.0							# $f8 = N = 0.0 (double)
	
	g5_exp_loop:
		c.le.d $f6, $f12
		bc1t g5_exp_reg_ret
		add.d $f4, $f4, $f6			# ret += term_N
		add.d $f8, $f8, $f16		# ++N
		mul.d $f6, $f6, $f2			# term_N *= x
		div.d $f6, $f6, $f8			# term_N /= N
		b g5_exp_loop

	g5_exp_reg_ret:
		mov.d $f0, $f4			# $f0 = ret (double)
		cvt.s.d $f0, $f0		# $f0 = ret (float)
		b g5_exp_ret				# return ret

	g5_exp_ret_0:
		li.s $f0, 0.0 			# $f0 = 0.0 (float)
		b g5_exp_ret				# return 0.0 (float)

	g5_exp_neg:
		sub.d $f2, $f0, $f2		# $f2 = -x (double)
		cvt.s.d $f2, $f2			# $f2 = x (float)
		s.s $f2, -44($sp)			# load func param (-x)
		jal g5_exp						# $f0 = g5_exp(-x) (float)
		cvt.d.s $f0, $f0			# $f0 = g5_exp(-x) (double)
		div.d $f0, $f16, $f0	# $f0 = 1.0 / g5_exp(-x) (double)
		cvt.s.d $f0, $f0			# $f0 = 1.0 / g5_exp(-x) (float)
		b g5_exp_ret

	g5_exp_ret_500:
		l.s $f0, global___GFCC_M_INFTY__
		b g5_exp_ret					# return INFINITY

g5_exp_ret:
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


# .globl g5_sin					# float g5_sin(float x);
# g5_sin:
# 	sw $ra, -4($sp) # return address
# 	sw $fp, -8($sp) # frame pointer of caller
# 	move $fp, $sp # begin new frame
# 	subu $sp, $sp, 44 # expad frame - expect address of formatter
# 	sw $s0, -12($fp) # callee saved register
# 	sw $s1, -16($fp) # callee saved register
# 	sw $s2, -20($fp) # callee saved register
# 	sw $s3, -24($fp) # callee saved register
# 	sw $s4, -28($fp) # callee saved register
# 	sw $s5, -32($fp) # callee saved register
# 	sw $s6, -36($fp) # callee saved register
# 	sw $s7, -40($fp) # callee saved register

# 	li.d $f0, 0.0												# $f0 = 0.0 (double) for comparison
# 	l.s $f12, global___GFCC_M_PREC__		# $f12 = precision (float)
# 	cvt.d.s $f12, $f12									# $f12 = precision (double)
	
# 	l.s $f2, 0($sp)   # $f2 = x; (float)
# 	cvt.d.s $f2, $f2	# $f2 = x; (double)

# 	c.lt.d $f2, $f0				# x < 0.0
# 	bc1t g5_sin_neg
	
# 	# $f2 = x, $f4 = ret, $f6 = term_N, $s0 = N
# 	li.d $f4, 0.0							# $f4 = ret = 0.0 (double)
# 	mov.d $f6, $f2						# $f6 = term_N = x (double)
# 	li $s0, 0									# $s0 = N = 0 (int)
	
# 	g5_sin_loop:
# 		c.le.d $f6, $f12
# 		bc1t g5_sin_reg_ret
# 		andi $s1, $s0, 0x1			# $s1 = isOdd(N)
# 		beq $s1, 1, g5_sin_minus
# 		mov.d $f8, $f6					# $f8 = term_N (if N is even)
# 		b g5_sin_add_to_ret
	
# 		g5_sin_minus:
# 			sub.d $f8, $f0, $f6		# $f8 = -term_N (if N is odd)
# 			b g5_sin_add_to_ret

# 		g5_sin_add_to_ret:
# 			add.d $f4, $f4, $f8		# ret += $f8
		
# 		addi $s0, $s0, 1				# N++;
# 		mul $s1, $s0, 2					# $s1 = 2N
# 		addi $s2, $s1, 1				# $s2 = 2N + 1
# 		mul $s1, $s1, $s2				# $s1 = 2N(2N+1)
# 		mtc1.d $s1, $f20				# $f20 = 2N(2N+1) (double)
# 		mul.d $f18, $f2, $f2		# $f18 = x * x
# 		div.d $f18, $f18, $f20	# $f18 = x*x / 2N(2N+1)
# 		mul.d $f6, $f6, $f18		# term_N *= (x * x) / (2N(2N+1))
# 		b g5_sin_loop

# 	g5_sin_reg_ret:
# 		mov.d $f0, $f4			# $f0 = ret (double)
# 		cvt.s.d $f0, $f0		# $f0 = ret (float)
# 		b g5_sin_ret				# return ret

# 	g5_sin_neg:
# 		sub.d $f2, $f0, $f2		# $f2 = -x (double)
# 		cvt.s.d $f2, $f2			# $f2 = x (float)
# 		s.s $f2, -44($sp)			# load func param (-x)
# 		jal g5_sin						# $f0 = g5_sin(-x) (float)
# 		cvt.d.s $f0, $f0			# $f0 = g5_sin(-x) (double)
# 		li.d $f2, 0.0					# $f0 = 0.0 (double) for subtraction
# 		sub.d $f0, $f2, $f0		# $f0 = -g5_sin(-x) (double)
# 		cvt.s.d $f0, $f0			# $f0 = -g5_sin(-x) (float)
# 		b g5_sin_ret

# g5_sin_ret:
# 	lw $s7, -40($fp) # restore callee saved register
# 	lw $s6, -36($fp) # restore callee saved register
# 	lw $s5, -32($fp) # restore callee saved register
# 	lw $s4, -28($fp) # restore callee saved register
# 	lw $s3, -24($fp) # restore callee saved register
# 	lw $s2, -20($fp) # restore callee saved register
# 	lw $s1, -16($fp) # restore callee saved register
# 	lw $s0, -12($fp) # restore frame pointer of caller
# 	move $sp, $fp # close current frame
# 	lw $fp, -8($sp) # restore frame pointer of caller
# 	lw $ra, -4($sp) # restore return address
# 	jr $ra # return to caller



