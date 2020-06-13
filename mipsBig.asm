#########Register usage##########
# $s0 - low half of first input
# $s1 - high
# $s2 - low half of second input
# $s3 - high 

# $s4 - low half of sum
# $s5 - high half of sum

#################################


		.data
msg0:		.asciiz "Give two numbers: "
msg1:		.asciiz "Addition or multiplication?(+/*)"

res: 		.asciiz "Result: "
cont: 		.asciiz "Continue?(Y/N)\n"
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

rem_arr:	.space 40

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
	la $t2, ($a0) #pointer to string
	li $t0, 0     #low 
	li $t1, 0     #high
		
loop:
	lb $t3, ($t2) #loading next byte
	beq $t3, 10, done
	blt $t3, '0', done
	bgt $t3, '9', done
	addiu $t3, $t3, -48 #convert from ascii
		
	srl $t6, $t0, 31 #t6 is used for the spilled bit
	sll $t4, $t0, 1  #shift low half
	sll $t5, $t1, 1  #shift high half
	or $t5, $t5, $t6 #put in the spilled bit
		
	srl $t6, $t0, 29 #the 3 spilled bits
	sll $t0, $t0, 3  #shift low half
	sll $t1, $t1, 3  #shift high half
	or $t1, $t1, $t6 #put in the spilled bits

	addu $t0, $t0, $t4 #add low halves
	addu $t1, $t1, $t5 #add high halves
	sltu $t6, $t0, $t4 #t6 = (t0 < t4), that is the carry
	addu $t1, $t1, $t6 #add the carry if any
		
	addu $t0, $t0, $t3 #adding the digit now
	sltu $t6, $t0, $t3 #the carry
	addu $t1, $t1, $t6 #add the carry if any
			
	addiu $t2, $t2, 1 #increment pointer
	b loop
				
done:
	move $v0, $t0
	move $v1, $t1
	
	jr $ra
		
addition:
	
	#t1 high half
	#t0 lowhalf
	addu $t4, $s0, $s2
	sltu $t5, $t4, $s0 #simulate the carry flag
	addu $t5, $t5, $s1
	addu $t1, $t5, $s3 
		
	move $s7, $t4
	move $a1, $t1
		
	b itos
		
multiplication:
	#CLL -  low 32-bits of low 64-bits of 128-bit result C ##$t0
	#CLH = high 32-bits of low 64-bits of 128-bit result C ##$t6
	#CHL = low 32-bits of high 64-bits of 128-bit result C ##$t9
	#CHH = high 32-bits of high 64-bits of 128-bit result C ##$t8
	
	#CLL = low(AL*BL)
	multu $s0, $s2
	mflo $t0
	mfhi $t1

	#CLH = high(AL*BL) + low(AH*BL) + low (AL*BH)
	#high(AL*BL) - $t1
	#low(AH*BL) - $t2
	#low(AL*BH) - $t4
			
	multu $s1, $s2
	mflo $t2
	mfhi $t3
		
	multu $s0, $s3
	mflo $t4
	mfhi $t5
		
	addu $t6, $t2, $t1
	addu $t6, $t6, $t4
		
	#CHL = high(AH*BL) + high(AL*BH) + low(AH*BH)
	#high(AH*BL) - $t3
	#high(AL*BH) - $t5
	#low(AH*BH) - $t7
		
	multu $s1, $s3
	mflo $t7
	mfhi $t8
		
	addu $t9, $t3, $t5
	addu $t9, $t9, $t7
		
	jr $ra	

itos:
 				#a0 low
  				#a1 high
  				
	la 	$s6, out 	#output
	li 	$s0, 10 	#divisor		
	lw 	$t7, num 	#first quotient of 2^32/10	
	li 	$s5, 6 		#first remainder of 2^32/10
	li	$t8, 0		#counter
	li	$t3, 0
	li	$s1, 0

	beqz 	$a1, onlylow	#if there is no high part
##################################
#q1(h) 	 	$s2
#r1(h)	  	$s3
#q1(2^32)	$s4
#r1(2^32) 	$s5
#r2(2^32)	$s6
#r(q(h)) 	$s7
#q(r1(h)*r1(2^32)) $t9
##################################	
fill_h_arr:
	la 	$s2, hq_arr
	la 	$s3, hr_arr
	la	$s4, sr_arr
	lw 	$t1, iterator
	lw	$t2, size
lop:	
	bgt	$t1, $t2, firstpart
	sll 	$t9, $t1, 2	#multiply iterator by size of one digit
	addu	$t3, $t9, $s2	#4i = 4i + memory location of hq_arr
	addu	$t5, $t9, $s3	#hr_arr
	addu	$t6, $t9, $s4	#sr_arr
	
	divu 	$a1, $s0	#h/10
	mflo 	$a1		#quotient
	mfhi	$t4		#remainder

	
	sw	$s5, 0($t6)	
	sw	$a1, 0($t3)
	sw	$t4, 0($t5)
	
	divu	$t7, $s0
	mflo	$t7
	mfhi	$s5
	
	addiu	$t1, $t1, 1
	b lop

	
#printarrs:
	#beqz $t1, firstpart
	
	#li $v0, 4
	#la $a0, newline
	#syscall
	
	#lw $t0,  0($t6)
	#li $v0, 1
	#move $a0, $t0
	#syscall
	
	#li $v0, 4
	#la $a0, newline
	#syscall
	
	
	#li $v0, 4
	#la $a0, newline
	#syscall
	
	#lw $t0,  0($t5)
	#li $v0, 1
	#move $a0, $t0
	#syscall
	
	#subiu $t6, $t6, 4
	#subiu $t5, $t5, 4
	#subiu $t1, $t1, 1
	#b printarrs
firstpart:

	sll	$t5, $t8, 2
	addu	$t5, $t5, $s4

	la 	$s5, ($s3)
	
	lw	$t2, 0($t5) #2^32
	lw	$t1, 0($s5) #high
	beqz	$t2, highpart
	b conti
	
highpart:
	li $t9, 1#flag
	subiu $t5, $t5, 4
	move $a3, $t5
	
	li $v1, 1 #counter
high_cont:
	lw $t2, 0($a3) #rlast(2^32)
	move $t5, $a3
	sll $s5, $v1, 2
	addu $s5, $s5, $s3
	lw $t1, 0($s5)#rn(h)
	
	
	
	multu $t1, $t2 
	mflo $t3
	divu $t3, $s0
	mfhi $s4 #r(rn(h)*rlast(2^32))
	
	subiu $s5, $s5, 4
	lw $t1, 0($s5) #rn-1(h)
	addiu $s5, $s5, 4
	
	multu $t1, $t2
	mflo $t3
	divu $t3, $s0
	mflo $t3 #q(rn-1(h)*rlast(2^32))
	
	addu $s4, $s4, $t3 #r(rn(h)*rlast(2^32)) + q(rn-1(h)*rlast(2^32))
	
	beqz $t1, enddd
	
	move $t0, $t8
high_loop:
	beqz $t0, breaker
	lw $t6, 0($s5)	#rn(h)
	addiu $s5, $s5, 4
	lw $t4, 0($s5) #rn+1(h)
	
	
	subiu $t5, $t5, 4
	lw $t2, 0($t5) #rlast-1(2^32)
	
	multu $t4, $t2 #rn+1(h)*rlast-1(2^32)
	mflo $t3
	divu $t3, $s0
	mfhi $t3 #r(rn+1(h)*rlast-1(2^32))
	
	addu $s4, $s4, $t3 #r(rn(h)*rlast(2^32)) + q(rn-1(h)*rlast(2^32))+r(rn+1(h)*rlast-1(2^32))
	
	multu $t6, $t2
	mflo $t3
	
	divu $t3, $s0
	mflo $t3
	
	addu $s4, $s4, $t3 #r(rn(h)*rlast(2^32)) + q(rn-1(h)*rlast(2^32))+r(rn+1(h)*rlast-1(2^32))
	beqz $t4, breaker
	
	subiu $t0, $t0, 1
	
	b high_loop
	
breaker:
	move $t3, $s4
	b conv_store
flag:
	li $t9, 2
	
conti:	
	multu $t1, $t2
	mflo $t3
	
	divu $t3, $s0
	mfhi $t3	#sum in t3
	
	beqz $t8, low
	
	lw	$t1, iterator
	move	$t0, $t8
rv_loop:
	#t1 iterator starting from 0
	#t0 counter of iterations
	#t3 sum
	#t5 address of current element in s4 array
	
	beqz	$t0, low
	
	sll	$t2, $t1, 2
	addu	$a3, $t2, $s3
	addiu	$a3, $a3, 4
	lw	$t4, 0($a3)	#q(h)
	
	
	subiu	$t5, $t5, 4
	lw	$t7, 0($t5)	#r(2^32)
	
	multu	$t4, $t7
	mflo	$t4
	
	divu	$t4, $s0
	mfhi	$t4
	
	addu 	$t3, $t3, $t4
	
	addu	$t4, $t2, $s3
	lw	$t6, 0($t4) 	#r(h)
	
	multu $t6, $t7
	mflo $t4
	
	divu $t4, $s0
	mflo $t4
	
	addu	$t3, $t3, $t4
	addiu	$t1, $t1, 1
	subiu	$t0, $t0, 1
	b rv_loop
		
low:
	beqz	$s7, conv_store
	
	divu 	$s7, $s0	#low/10
	mflo 	$s7 		#q1(l)
	mfhi 	$t1		#r1(l)

	addu 	$t3, $t3, $t1	#add r(l)
	
conv_store:
	addu 	$t3, $t3, $s1	#add carry
	
	divu 	$t3, $s0	#rem of sum
	mfhi 	$t3
	mflo 	$s1		#the carry

	addiu 	$t3, $t3, 48	#convert to ascii
	sb 	$t3, ($s6)	#store char
	addiu 	$s6, $s6, 1	#increment pointer to out
	addiu	$t8, $t8, 1	
	addiu	$t4, $t4, 1	#increment iterator
	addiu 	$v1, $v1, 1
	beq $t9, 1, high_cont
	beq $t9, 2, enddd																																																																																							
	b firstpart
	
onlylow:
	#C/10
	divu $s7, $s0
	mflo $s7 #quotient of C 
	mfhi $t4 #remainder of C
	
	addiu $t4, $t4, 48
	sb $t4, ($s6)
	addiu $s6, $s6, 1
	
	bnez $s7, onlylow
	sb $zero, ($s6)	
	b reverse

enddd:	
	bnez $t3, store_rest
	b reverse
store_rest:
	addu 	$t3, $t3, $s1	#add carry
	
	divu 	$t3, $s0	#rem of sum
	mfhi 	$t3
	mflo 	$s1		#the carry

	addiu 	$t3, $t3, 48	#convert to ascii
	sb 	$t3, ($s6)	#store char
	addiu 	$s6, $s6, 1	#increment pointer to out
	sb $zero, ($s6)

	
	

reverse:
	la $t0, out
	move $t1, $t0
	
find_end:
	lbu $t2, ($t1)
	bltu $t2, ' ', end_found
	addiu $t1, $t1, 1
	b find_end
	
end_found:
	sb $zero, ($t1)
	addiu $t1, $t1, -1
	
revloop:
	bleu $t1, $t0, finish
	lbu $t2, ($t0)
	lbu $t3, ($t1)
	sb $t2, ($t1)
	sb $t3, ($t0)
	addiu $t0, $t0, 1
	addiu $t1, $t1, -1
	b revloop
	
finish:
	la 	$a0, newline
	li 	$v0, 4
	syscall
	
	la $a0, res
	li $v0, 4
	syscall

	la $a0, out
	li $v0, 4
	syscall
	
	la $a0, newline
	li $v0, 4
	syscall 
	
	la $a0, cont
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
	

	


   		  
   		  
