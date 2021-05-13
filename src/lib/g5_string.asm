    .text

.globl g5_strlen
g5_strlen:						# int g5_strlen(const char *str);
	sw $ra, -4($sp) 		# return address
	sw $fp, -8($sp) 		# frame pointer of caller
	move $fp, $sp 			# begin new frame
	subu $sp, $sp, 44 	# expad frame - expect address of formatter
	sw $s0, -12($fp) 		# callee saved register
	sw $s1, -16($fp) 		# callee saved register
	sw $s2, -20($fp) 		# callee saved register
	sw $s3, -24($fp) 		# callee saved register
	sw $s4, -28($fp) 		# callee saved register
	sw $s5, -32($fp) 		# callee saved register
	sw $s6, -36($fp) 		# callee saved register
	sw $s7, -40($fp) 		# callee saved register

  lw $a0, 0($sp)			# $a0 = str
  li $v0, 0						# return value (length of string = i)
  
	g5_strlen_loop:
		addu $a1, $a0, $v0					# $a1 = (str + i)
		lb $a2, 0($a1)							# $a2 = str[i]
		beq $a2, $0, g5_strlen_ret	# NULL terminated
		addu $v0, $v0, 1						# increase length
		b g5_strlen_loop						# while loop

g5_strlen_ret:
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


.globl g5_strcmp
g5_strcmp:						# int g5_strcmp(const char *str1, const char *str2);
	sw $ra, -4($sp) 		# return address
	sw $fp, -8($sp) 		# frame pointer of caller
	move $fp, $sp 			# begin new frame
	subu $sp, $sp, 44 	# expad frame - expect address of formatter
	sw $s0, -12($fp) 		# callee saved register
	sw $s1, -16($fp) 		# callee saved register
	sw $s2, -20($fp) 		# callee saved register
	sw $s3, -24($fp) 		# callee saved register
	sw $s4, -28($fp) 		# callee saved register
	sw $s5, -32($fp) 		# callee saved register
	sw $s6, -36($fp) 		# callee saved register
	sw $s7, -40($fp) 		# callee saved register

  lw $s1, 0($sp)			# $s1 = str1
  lw $s2, -4($sp)			# $s2 = str2
  li $a0, 0						# index i of both strings
  li $v0, 0						# default return value
  
	g5_strcmp_loop:
		addu $a1, $s1, $a0	# $a1 = str1 + i
		lb $a1, 0($a1)			# $a1 = str1[i]
		addu $a2, $s2, $a0	# $a2 = str2 + i
		lb $a2, 0($a2)			# $a2 = str2[i]
		subu $v0, $a1, $a2	# $v0 = str[1] - str[2] (difference)

		beq $a1, $0, g5_strcmp_ret	# return previous index difference
		beq $a2, $0, g5_strcmp_ret	# return previous index difference
		bne $v0, $0, g5_strcmp_ret	# return current index difference
		addu $a0, $a0, 1						# move to next index
		b g5_strcmp_loop						# while loop

g5_strcmp_ret:
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


.globl g5_strupr
g5_strupr:						# int g5_strupr(const char *str);
	sw $ra, -4($sp) 		# return address
	sw $fp, -8($sp) 		# frame pointer of caller
	move $fp, $sp 			# begin new frame
	subu $sp, $sp, 44 	# expad frame - expect address of formatter
	sw $s0, -12($fp) 		# callee saved register
	sw $s1, -16($fp) 		# callee saved register
	sw $s2, -20($fp) 		# callee saved register
	sw $s3, -24($fp) 		# callee saved register
	sw $s4, -28($fp) 		# callee saved register
	sw $s5, -32($fp) 		# callee saved register
	sw $s6, -36($fp) 		# callee saved register
	sw $s7, -40($fp) 		# callee saved register

  lw $s0, 0($sp)			# $s0 = str
  li $a0, 0						# $a0 = index i of str
  li $v0, 0						# default return value (no conversions)
  
	g5_strupr_loop:
		addu $a1, $s0, $a0						# $a1 = str + i
		lb $a2, 0($a1)								# $a2 = str[i]
		beq $a2, $0, g5_strupr_ret		# end of string : return $v0 as it is
		bge $a2, 97, g5_strupr_conv		# possible conversion if str[i] >= 'a' (97)
		b g5_strupr_index_add

		g5_strupr_conv:
			bgt $a2, 122, g5_strupr_index_add		# do nothing if str[i] > 'z'
			subu $a2, $a2, 32										# convert to capital letter
			sb $a2, 0($a1)											# str[i] = capital letter
			addu $v0, $v0, 1										# increment number of conversions
			b g5_strupr_index_add

		g5_strupr_index_add:
			addu, $a0, $a0, 1		# simply increment the index
			b g5_strupr_loop		# while loop continuation

g5_strupr_ret:
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


.globl g5_strlwr
g5_strlwr:						# int g5_strlwr(const char *str);
	sw $ra, -4($sp) 		# return address
	sw $fp, -8($sp) 		# frame pointer of caller
	move $fp, $sp 			# begin new frame
	subu $sp, $sp, 44 	# expad frame - expect address of formatter
	sw $s0, -12($fp) 		# callee saved register
	sw $s1, -16($fp) 		# callee saved register
	sw $s2, -20($fp) 		# callee saved register
	sw $s3, -24($fp) 		# callee saved register
	sw $s4, -28($fp) 		# callee saved register
	sw $s5, -32($fp) 		# callee saved register
	sw $s6, -36($fp) 		# callee saved register
	sw $s7, -40($fp) 		# callee saved register

  lw $s0, 0($sp)			# $s0 = str
  li $a0, 0						# $a0 = index i of str
  li $v0, 0						# default return value (no conversions)
  
	g5_strlwr_loop:
		addu $a1, $s0, $a0						# $a1 = str + i
		lb $a2, 0($a1)								# $a2 = str[i]
		beq $a2, $0, g5_strlwr_ret		# end of string : return $v0 as it is
		bge $a2, 65, g5_strlwr_conv		# possible conversion if str[i] >= 'A' (65)
		b g5_strlwr_index_add

		g5_strlwr_conv:
			bgt $a2, 90, g5_strlwr_index_add		# do nothing if str[i] > 'Z'
			addu $a2, $a2, 32										# convert to small letter
			sb $a2, 0($a1)											# str[i] = small letter
			addu $v0, $v0, 1										# increment number of conversions
			b g5_strlwr_index_add

		g5_strlwr_index_add:
			addu, $a0, $a0, 1		# simply increment the index
			b g5_strlwr_loop		# while loop continuation

g5_strlwr_ret:
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


.globl g5_strcat
g5_strcat:						# int g5_strcat(const char *dst, const char *src);
	sw $ra, -4($sp) 		# return address
	sw $fp, -8($sp) 		# frame pointer of caller
	move $fp, $sp 			# begin new frame
	subu $sp, $sp, 44 	# expad frame - expect address of formatter
	sw $s0, -12($fp) 		# callee saved register
	sw $s1, -16($fp) 		# callee saved register
	sw $s2, -20($fp) 		# callee saved register
	sw $s3, -24($fp) 		# callee saved register
	sw $s4, -28($fp) 		# callee saved register
	sw $s5, -32($fp) 		# callee saved register
	sw $s6, -36($fp) 		# callee saved register
	sw $s7, -40($fp) 		# callee saved register

  lw $s0, -4($sp)			# $s0 = src
  li $a0, 0						# $a0 = index i of src
  lw $s1, 0($sp)			# $s1 = dst
  li $a1, 0						# $a1 = index j of dst
  li $v0, 0						# return value (no. of appends)
  
	g5_strcat_find_dst_len:
		addu $s2, $s1, $a1							# $s2 = dst + j
		lb $a3, 0($s2)									# $a3 = dst[j]
		beq $a3, $0, g5_strcat_loop			# $a1 = j = len(dst), start concatenation
		addu $a1, $a1, 1								# j++
		b g5_strcat_find_dst_len				# while loop

	# $a1 = j = len(dst)
	g5_strcat_loop:
		addu $s3, $s0, $a0						# $s3 = src + i
		lb $a2, 0($s3)								# $a2 = src[i]
		addu $s2, $s1, $a1						# $s2 = dst + j
		sb $a2, 0($s2)								# dst[j] = $a2 = src[i]
		beq $a2, $0, g5_strcat_ret		# return from here - concatenation complete
		addu $a0, $a0, 1							# i++
		addu $a1, $a1, 1							# j++
		addu $v0, $v0, 1							# increment number of appends
		b g5_strcat_loop							# while loop

g5_strcat_ret:
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


.globl g5_strcpy
g5_strcpy:						# int g5_strcpy(const char *dst, const char *src);
	sw $ra, -4($sp) 		# return address
	sw $fp, -8($sp) 		# frame pointer of caller
	move $fp, $sp 			# begin new frame
	subu $sp, $sp, 44 	# expad frame - expect address of formatter
	sw $s0, -12($fp) 		# callee saved register
	sw $s1, -16($fp) 		# callee saved register
	sw $s2, -20($fp) 		# callee saved register
	sw $s3, -24($fp) 		# callee saved register
	sw $s4, -28($fp) 		# callee saved register
	sw $s5, -32($fp) 		# callee saved register
	sw $s6, -36($fp) 		# callee saved register
	sw $s7, -40($fp) 		# callee saved register

  lw $s0, -4($sp)			# $s0 = src
  lw $s1, 0($sp)			# $s1 = dst
  li $a0, 0						# $a0 = index i
  li $v0, 0						# return value (no. of appends)

	g5_strcpy_loop:
		addu $s3, $s0, $a0						# $s3 = src + i
		lb $a2, 0($s3)								# $a2 = src[i]
		addu $s2, $s1, $a0						# $s2 = dst + i
		sb $a2, 0($s2)								# dst[i] = $a2 = src[i]
		beq $a2, $0, g5_strcpy_ret		# return from here - copying complete
		addu $a0, $a0, 1							# i++
		addu $v0, $v0, 1							# increment number of appends
		b g5_strcpy_loop							# while loop

g5_strcpy_ret:
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


.globl g5_strncpy
g5_strncpy:						# int g5_strncpy(const char *dst, const char *src, int n);
	sw $ra, -4($sp) 		# return address
	sw $fp, -8($sp) 		# frame pointer of caller
	move $fp, $sp 			# begin new frame
	subu $sp, $sp, 44 	# expad frame - expect address of formatter
	sw $s0, -12($fp) 		# callee saved register
	sw $s1, -16($fp) 		# callee saved register
	sw $s2, -20($fp) 		# callee saved register
	sw $s3, -24($fp) 		# callee saved register
	sw $s4, -28($fp) 		# callee saved register
	sw $s5, -32($fp) 		# callee saved register
	sw $s6, -36($fp) 		# callee saved register
	sw $s7, -40($fp) 		# callee saved register

  lw $s0, -4($sp)			# $s0 = src
  lw $s1, 0($sp)			# $s1 = dst
  lw $s7, -8($sp)			# $s7 = n
  li $a0, 0						# $a0 = index i
  li $v0, 0						# return value (no. of appends)

	blt $s7, $0, g5_strncpy_ret		# n < 0 : nothing to do

	g5_strncpy_loop:
		beq $a0, $s7, g5_strncpy_ret	# last time was the final char to be pushed
		addu $s3, $s0, $a0						# $s3 = src + i
		lb $a2, 0($s3)								# $a2 = src[i]
		addu $s2, $s1, $a0						# $s2 = dst + i
		sb $a2, 0($s2)								# dst[i] = $a2 = src[i]
		beq $a2, $0, g5_strncpy_ret		# return from here - copying complete
		addu $a0, $a0, 1							# i++
		addu $v0, $v0, 1							# increment number of appends
		b g5_strncpy_loop							# while loop

g5_strncpy_ret:
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
	
	
	.globl g5_strrev
g5_strrev:						# char *g5_strrev(const char *str);
	sw $ra, -4($sp) 		# return address
	sw $fp, -8($sp) 		# frame pointer of caller
	move $fp, $sp 			# begin new frame
	subu $sp, $sp, 44 	# expad frame - expect address of formatter
	sw $s0, -12($fp) 		# callee saved register
	sw $s1, -16($fp) 		# callee saved register
	sw $s2, -20($fp) 		# callee saved register
	sw $s3, -24($fp) 		# callee saved register
	sw $s4, -28($fp) 		# callee saved register
	sw $s5, -32($fp) 		# callee saved register
	sw $s6, -36($fp) 		# callee saved register
	sw $s7, -40($fp) 		# callee saved register

  lw $s0, 0($sp)			# $s0 = str
	li $a0, 0						# i = 0 (will compute len(str) here)

	g5_strrev_len_str:
		addu $s1, $s0, $a0						# $s1 = str + i
		lb $s2, 0($s1)								# $s2 = str[i]
		beq $s2, $0, g5_strrev_start	# length computed : start actual reversing
		addu $a0, $a0, 1							# i++
		b g5_strrev_len_str						# while loop

	# $a0 = n = len(str)
	g5_strrev_start:
		beq $a0, $0, g5_strrev_ret		# empty string : nothing to do : so return
		subu $a1, $a0, 1							# $a1 = len(str) - 1 = n - 1
		li $a0, 0											# index i = 0
	
	# $a0 = i, $a1 = (n-1) - i // now exchange these indeices one by one
	g5_strrev_loop:
		bge $a0, $a1, g5_strrev_ret		# swapping complete : so return
		addu $a2, $s0, $a0						# $a2 = str + i
		addu $a3, $s0, $a1						# $a3 = str + (n-1) - i
		lb $s2, 0($a2)								# $s2 = str[i]
		lb $s3, 0($a3)								# $s3 = str[n-1-i]
		sb $s2, 0($a3)								# str[n-1-i] = $a3 (previously str[i])
		sb $s3, 0($a2)								# str[i]     = $a2 (previously str[n-1-i])
		addu $a0, $a0, 1							# $a0 = i + 1
		subu $a1, $a1, 1							# $a1 = (n-1) - (i+1)
		b g5_strrev_loop							# while loop

g5_strrev_ret:
	move $v0, $s0		 # return value is original pointer itself (useless)
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



