		.data
msg0:		.asciiz "Give two numbers: "
msg1:		.asciiz "Addition or multiplication?(+/*)"
msg2:		.asciiz "Perform tests or run normally?(T/N)"
msg3: 		.asciiz "Result: "
msg4: 		.asciiz "Continue?(Y/N)\n"
newline:	.asciiz "\n"
	
input:		.space 64
out:		.space 64

		.align 2
hq_arr:		.space 44
		.align 2
hr_arr:		.space 44
		.align 2
sr_arr:		.space 44


iterator:	.word 0
size:		.word 9


answ:		.space 2
num:		.word 429496729 #2^32/10

		.text
main:
	li 	$v0, 4
	la 	$a0, newline
	syscall
	
	li 	$v0, 4
	la 	$a0, msg0
	syscall
	
	li 	$v0, 4
	la 	$a0, newline
	syscall
	
	jal read_numbers
	move $s0, $v0
	move $s1, $v1
	
	jal read_numbers
	move $s2, $v0
	move $s3, $v1
		
	la 	$a0, newline
	li 	$v0, 4
	syscall
		
	la 	$a0, msg1
	li 	$v0, 4
	syscall
	
	la 	$a0, newline
	li 	$v0, 4
	syscall
	
	la	$a0, answ
	li 	$a1, 2
	li 	$v0, 8
	syscall

	la 	$t0, answ
	lbu 	$t0, ($t0)
	beq,	$t0, '+', addition
	beq, 	$t0, '*', multiplication
	
	b end_program
	
read_numbers:
	
	li $v0, 8
	la $a0, input
	la $a1, 20
	syscall	
	
s64toi32:
	#string to intger put in two 32-bit registers
	la $t2, ($a0) 		#pointer to string
	li $t0, 0     		#low
	li $t1, 0    		#high
		
loop:
	lb $t3, ($t2) 		#loading next byte
	beq $t3, 10, done
	blt $t3, '0', done
	bgt $t3, '9', done
	addu $t3, $t3, -48 	#convert from ascii
		
	srl $t6, $t0, 31 	#t6 is used for the spilled bit
	sll $t4, $t0, 1  	#shift low half
	sll $t5, $t1, 1  	#shift high half
	or $t5, $t5, $t6 	#put in the spilled bit
		
	srl $t6, $t0, 29 	#the 3 spilled bits
	sll $t0, $t0, 3  	#shift low half
	sll $t1, $t1, 3  	#shift high half
	or $t1, $t1, $t6 	#put in the spilled bits

	addu $t0, $t0, $t4 	#add low halves
	addu $t1, $t1, $t5 	#add high halves
	sltu $t6, $t0, $t4 	#t6 = (t0 < t4), that is the carry
	addu $t1, $t1, $t6 	#add the carry if any
		
	addu $t0, $t0, $t3 	#adding the digit now
	sltu $t6, $t0, $t3 	#the carry
	addu $t1, $t1, $t6 	#add the carry if any
			
	addu $t2, $t2, 1 	#increment pointer
	b loop
				
done:
	move $v0, $t0
	move $v1, $t1
	
	jr $ra
			
addition:
	addu $t0, $s0, $s2 	#add low bytes
	sltu $t2, $t0, $s0 	#the carry
	addu $t2, $t2, $s1 	#carry + high
	addu $t1, $t2, $s3 	#+high
		
	move $s5, $t0 		#low
	move $s6, $t1 		#high
		
	b itos

multiplication:
	#low 32-bits of 64-bit result = low(AL*BL)
	#high 32-bits of 64-bit result = high(AL*BL) + low(AH*BL) + low(AL*BH)
	
	multu $s0, $s2 		#AL*BL
	mflo $t0 		#low(AL*BL)
	mfhi $t1 		#high(AL*BL)

	multu $s1, $s2 		#AH*BL
	mflo $t2 		#low(AH*BL)
	
	addu $t1, $t1, $t2 	#high(AL*BL) + low(AH*BL)
	
	multu $s0, $s3 		#AL*BH
	mflo $t2 		#low(AL*BH)
	
	addu $t1, $t1, $t2 	#high(AL*BL) + low(AH*BL) + low(AL*BH)

	move $s5, $t0 		#low
	move $s6, $t1 		#high

################## Register Usage in itos ##################
#-$s0 constant 10
#-$s1 carry
#-$s2 hq_arr
#-$s3 hr_arr
#-$s4 sr_arr
#-$s5 low part of 64-bit integer
#-$s6 high part of 64-bit integer
#-$s7 resulting 64-bit string
############################################################
itos:	
	li $s0, 10 		#divisor
	li $s1, 0			
	la $s7, out 		#output
		
	li $t3, 0	
	li $t6, 6 		#first remainder of 2^32/10
	li $t8, 0
		
	beqz $s6, onlylow	#if there is no high part
	
fill_h_arr:
	lw $t0, num 		#first quotient of 2^32/10
	la $s2, hq_arr
	la $s3, hr_arr
	la $s4, sr_arr
	lw $t2, iterator
	lw $t3, size
	li $t9, 0
rep:	
	bgt $t2, $t3, firstpart
	sll $t4, $t2, 2		#multiply iterator by size of one digit
	
	divu $s6, $s0		#h/10
	mflo $s6		#quotient
	
	addu $t5, $t4, $s2	#memory location of hq_arr
	sw $t1, 0($t5) 		#store quo(h)
	
	mfhi $t1
	addu $t5, $t4, $s3
	sw $t1, 0($t5)
	
	addu $t5, $t4, $s4
	sw $t6, 0($t5)
	
	divu $t0, $s0		#2^32/10
	mflo $t0		#quotient
	mfhi $t6		#remainder
	
	addu $t2, $t2, 1	#iterator
	b rep

firstpart:
	sll $t5, $t8, 2
	addu $t4, $t5, $s3	#memory location of hr_arr
	addu $t5, $t5, $s4 	#memory location of sr_arr
	lw $t2, 0($t5) 		#rem(2^32)	
	lw $t1, 0($s3) 		#rem(high)
	
	beqz $t2, highpart	#if 2^32 is done
	
	multu $t1, $t2		#r(h)*r(2^32)
	mflo $t3
	
	divu $t3, $s0
	mfhi $t3		#rem(r(h)*r(2^32)
	
	beqz $t8, low		#if it is first iteration, go straight to addition of low
	
	lw $t1, iterator
	move $t0, $t8
	
rv_loop:
	beqz $t0, low	
	
	sll $t2, $t1, 2		#shift iterator
	addu $t4, $t2, $s3	#memory location of hr_arr
	addu $t4, $t4, 4	
	lw $t4, 0($t4)		#rn(h)
	
	
	addu $t5, $t5, -4
	lw $t7, 0($t5)		#rn-1(2^32)
	
	multu $t4, $t7		#rn(h)*rn-1(2^32)
	mflo $t4
	
	divu $t4, $s0
	mfhi $t4		#rem(rn(h)*rn-1(2^32))
	
	addu $t3, $t3, $t4
	
	addu $t4, $t2, $s3	
	lw $t6, 0($t4) 		#r(h)
	
	multu $t6, $t7
	mflo $t4
	
	divu $t4, $s0
	mflo $t4
	
	addu $t3, $t3, $t4
	addu $t1, $t1, 1
	addu $t0, $t0, -1
	b rv_loop
	
highpart:
	li $t9, 1		#set flag
	addu $t5, $t5, -4
	move $a3, $t5
	
	li $t8, 1		#initialize counter
high_cont:
	lw $t2, 0($a3) 		#rlast(2^32)
	move $t5, $a3
	sll $t7, $t8, 2
	addu $t6, $t7, $s2
	
	addu $t7, $t7, $s3
	lw $t1, 0($t7)		#rn(h)
	
	
	multu $t1, $t2 
	mflo $t3
	divu $t3, $s0
	mfhi $t3 		#r(rn(h)*rlast(2^32))
	
	addu $t7, $t7, -4
	lw $t1, 0($t7) 		#rn-1(h)
	addu $t7, $t7, 4
	
	multu $t1, $t2
	mflo $t4
	divu $t4, $s0
	mflo $t4 		#q(rn-1(h)*rlast(2^32))
	
	addu $t3, $t3, $t4 	#r(rn(h)*rlast(2^32)) + q(rn-1(h)*rlast(2^32))
	
	addu $t6, $t6, 4
	lw $t0, 0($t6)
	beqz $t0, finish_itos
	
	
high_loop:
	beqz $t0, conv_store
	
	lw $t0, 0($t7)		#rn(h)
	
	addu $t7, $t7, 4
	lw $t1, 0($t7) 		#rn+1(h)
	
	addu $t5, $t5, -4
	lw $t2, 0($t5)		#rlast-1(2^32)
	
	multu $t1, $t2 		#rn+1(h)*rlast-1(2^32)
	mflo $t4
	divu $t4, $s0
	mfhi $t4 		#r(rn+1(h)*rlast-1(2^32))
	
	addu $t3, $t3, $t4 	#r(rn(h)*rlast(2^32)) + q(rn-1(h)*rlast(2^32))+r(rn+1(h)*rlast-1(2^32))
	
	multu $t0, $t2
	mflo $t4
	
	divu $t4, $s0
	mflo $t4
	
	addu $t3, $t3, $t4 	#r(rn(h)*rlast(2^32)) + q(rn-1(h)*rlast(2^32))+r(rn+1(h)*rlast-1(2^32))
	
	
	addu $t6, $t6, 4
	lw $t0, 0($t6)
	
	
	b high_loop
	
low:
	beqz $s5, conv_store
	
	divu $s5, $s0		#low/10
	mflo $s5 		#q1(l)
	mfhi $t1		#r1(l)

	addu $t3, $t3, $t1	#add r(l)
	
conv_store:
	addu $t3, $t3, $s1	#add carry
	
	divu $t3, $s0		#rem of sum
	mfhi $t3
	mflo $s1		#the carry

	addu $t3, $t3, 48	#convert to ascii
	sb $t3, ($s7)		#store char
	addu $s7, $s7, 1	#increment pointer to out
	addu $t8, $t8, 1	#increment counter
	beq $t9, 1, high_cont																																																																																						
	b firstpart
	
onlylow:
	divu $s7, $s0		#low/10
	mflo $s7 		
	mfhi $t4 		
	
	addu $t4, $t4, 48
	sb $t4, ($s7)
	addu $s7, $s7, 1
	
	bnez $s7, onlylow
	sb $zero, ($s7)	
	b reverse

finish_itos:	
	bnez $s1, store_rest
	bnez $t3, store_rest
	sb $zero, ($s7)
	b reverse
	
store_rest:
	addu $t3, $t3, $s1	#add carry
	
	divu $t3, $s0	
	mfhi $t3		#remainder to be converted to char and stored
	mflo $s1		#the carry

	addu $t3, $t3, 48	#convert to ascii
	sb $t3, ($s7)	#store char
	addu $s7, $s7, 1	#increment pointer to out
	sb $zero, ($s7)
	
##################################################
reverse:
	li $s2, 0
	li $s3, 0
	li $s4, 0
	li $s7, 0
	la $t0, out
	move $t1, $t0
	
find_end:
	lbu $t2, ($t1)
	bltu $t2, ' ', end_found
	addu $t1, $t1, 1
	b find_end
	
end_found:
	sb $zero, ($t1)
	addu $t1, $t1, -1
	
revloop:
	bleu $t1, $t0, finish
	lbu $t2, ($t0)
	lbu $t3, ($t1)
	sb $t2, ($t1)
	sb $t3, ($t0)
	addu $t0, $t0, 1
	addu $t1, $t1, -1
	b revloop
##################################################
finish:
	la $a0, newline
	li $v0, 4
	syscall
	
	la $a0, msg3
	li $v0, 4
	syscall

	la $a0, out
	li $v0, 4
	syscall
	
	
	la $a0, newline
	li $v0, 4
	syscall 
	
	la $a0,	msg4
	li $v0, 4
	syscall
	
	la $a0, answ
	li $a1, 2
	li $v0, 8
	syscall
	
	la $t0, answ
	lbu $t0, ($t0)
	beq $t0, 'Y', main
	beq $t0, 'y', main
	
end_program:
	li $v0, 10
	syscall