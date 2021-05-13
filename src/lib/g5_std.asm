    .text

.globl g5_exit
g5_exit:
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

  lw $a0, 0($sp) # return value
  li $v0, 17 # "exit2" syscall
  syscall
  li $v0, -1  # return -1 if not exiting

g5_exit_ret:
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


.globl g5_atoi
g5_atoi:					# int g5_atoi(const char *str);
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

  lw $s0, 0($sp)	# $s0 = str
	li $v0, 0				# return value (will progressively construct)
	li $a0, 0				# index i of str
	li $s7, 1				# $s7 = sign

	addu $a1, $s0, $a0						# $a1 = str + i
	lb $s1, 0($a1)								# $s1 = str[i]
	beq $s1, 45, g5_atoi_minus		# minus sign ('-' = 45)
	b g5_atoi_loop

	g5_atoi_minus:
		li $s7, -1					# sign = -1
		addu $a0, $a0, 1		# i++ (bump up (increment) index i)
		b g5_atoi_loop

	g5_atoi_loop:
		addu $a1, $s0, $a0						# $a1 = str + i
		lb $s1, 0($a1)								# $s1 = str[i]
		blt $s1, 48, g5_atoi_ret			# str[i] < '0' : so nothing to do : return
		bgt $s1, 57, g5_atoi_ret			# str[i] > '9' : so nothing to do : return
		subu $s1, $s1, 48							# str[i] - '0' ('0' - '9' become 0 - 9)
		mul $v0, $v0, 10							# multiply by 10
		addu $v0, $v0, $s1						# and add the digit (str[i] - '0')
		addu $a0, $a0, 1							# i++ (bump up (increment) index i)
		b g5_atoi_loop								# while loop

g5_atoi_ret:
	mul $v0, $s7, $v0	# multiply by appropriate sign
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


.globl g5_malloc
g5_malloc:				# void *g5_malloc(int x);
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

	# requires storing address and size in a global hidden data structure

	li $v0, 0											# default = NULL pointer
  lw $a0, 0($sp)								# $a0 = x (amount)
	ble $a0, $0, g5_malloc_ret		# non-positive amount : return NULL
	li $v0, 9											# sbrk syscall
	syscall												# $v0 = required dynamically allocated address

g5_malloc_ret:
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


.globl g5_free
g5_free:				# void *g5_free(int x);
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

	# requires storing address and size in a global hidden data structure
	# for now : does nothing

g5_free_ret:
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


.globl g5_calloc
g5_calloc:				# void *g5_calloc(int n, int size);
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

	# requires storing address and size in a global hidden data structure

	li $v0, 0											# default return value = NULL pointer
	lw $s0, 0($sp)								# $s0 = n (number of items)
	ble $s0, $0, g5_calloc_ret		# non-positive amount given : return NULL
	lw $s1, -4($sp)								# $s1 = size (size of each item)
	ble $s1, $0, g5_calloc_ret		# non-positive amount given : return NULL
	mul $a0, $s0, $s1							# $a0 = total bytes to allocate
	li $v0, 9											# sbrk syscall
	syscall												# $v0 = M = required dynamically allocated address
	li $a1, 0											# index i of allocated memory

	# set all bytes to 0
	g5_calloc_loop:
		addu $s7, $v0, $a1						# M + i
		sb $0, 0($s7)									# M[i] = 0
		addu $a1, $a1, 1							# i++
		beq $a1, $a0, g5_calloc_ret		# i == n * size : nothing more to do
		b g5_calloc_loop							# while loop

g5_calloc_ret:
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


# .globl g5_realloc
# g5_realloc:				# void *g5_realloc(void *ptr, int size);
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

# 	# requires storing address and size in a global hidden data structure

# 	# ptr == NULL, then do like malloc(size)
# 	# size <= 0, free(ptr)
# 	# else new = malloc(size), copy stuff, free(ptr), return new

# 	li $v0, 0											# default return value = NULL pointer
# 	lw $s0, 0($sp)								# $s0 = n (number of items)
# 	ble $s0, $0, g5_realloc_ret		# non-positive amount given : return NULL
# 	lw $s1, -4($sp)								# $s1 = size (size of each item)
# 	ble $s1, $0, g5_realloc_ret		# non-positive amount given : return NULL
# 	mul $a0, $s0, $s1							# $a0 = total bytes to allocate
# 	li $v0, 9											# sbrk syscall
# 	syscall												# $v0 = M = required dynamically allocated address
# 	li $a1, 0											# index i of allocated memory

# 	# set all bytes to 0
# 	g5_realloc_loop:
# 		addu $s7, $v0, $a1						# M + i
# 		sb $0, 0($s7)									# M[i] = 0
# 		addu $a1, $a1, 1							# i++
# 		beq $a1, $a0, g5_realloc_ret		# i == n * size : nothing more to do
# 		b g5_realloc_loop							# while loop

# g5_realloc_ret:
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
