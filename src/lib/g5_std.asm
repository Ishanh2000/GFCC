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
