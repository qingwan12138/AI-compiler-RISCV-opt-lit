	.file	"bench.c"
	.option pic
	.text
	.align	1
	.type	branch_kernel, @function
branch_kernel:
	mv	a1,a0
	beqz	a0,.L6
	li	a2,-2128830464
	li	a7,-1640529920
	li	a6,16777216
	li	a3,0
	addi	a2,a2,-571
	li	a0,0
	addiw	a7,a7,-1607
	addiw	a6,a6,403
	li	t1,2
	li	t4,89
	li	t3,97
	j	.L5
.L10:
	remuw	a4,a5,t3
	addi	a3,a3,1
	slli	a4,a4,32
	srli	a4,a4,32
	add	a0,a0,a4
	beq	a1,a3,.L9
.L5:
	addw	a5,a3,a7
	xor	a5,a2,a5
	mulw	a5,a6,a5
	andi	a4,a5,7
	sext.w	a2,a5
	bleu	a4,t1,.L10
	remuw	a4,a5,t4
	slli	a4,a4,32
	srli	a4,a4,32
	add	a4,a4,a3
	addi	a3,a3,1
	xor	a0,a0,a4
	bne	a1,a3,.L5
.L9:
	ret
.L6:
	li	a0,0
	ret
	.size	branch_kernel, .-branch_kernel
	.align	1
	.type	vector_kernel, @function
vector_kernel:
	addi	sp,sp,-48
	sd	s0,32(sp)
	slli	s0,a0,2
	sd	s1,24(sp)
	mv	s1,a0
	mv	a0,s0
	sd	ra,40(sp)
	sd	s2,16(sp)
	sd	s3,8(sp)
	sd	s4,0(sp)
	call	malloc@plt
	mv	s3,a0
	mv	a0,s0
	call	malloc@plt
	mv	s4,a0
	mv	a0,s0
	call	malloc@plt
	mv	s2,a0
	beqz	s3,.L12
	beqz	s4,.L12
	beqz	a0,.L12
	beqz	s1,.L32
	mv	a3,s3
	mv	a6,s4
	mv	a7,s4
	mv	a1,s3
	li	a2,0
	li	a5,0
	li	t3,1009
	li	a0,1013
.L16:
	remu	t1,a5,t3
	addi	a7,a7,4
	addi	a5,a5,1
	addi	a1,a1,4
	remu	a4,a2,a0
	sw	t1,-4(a1)
	addi	a2,a2,7
	sw	a4,-4(a7)
	bne	s1,a5,.L16
	mv	a4,s2
	add	a0,s3,s0
	mv	a1,s2
.L17:
	lw	t1,0(a3)
	lw	a7,0(a6)
	addi	a3,a3,4
	slliw	a5,t1,1
	slliw	a2,a7,2
	addw	a5,a5,t1
	addw	a2,a2,a7
	addw	a5,a5,a2
	sw	a5,0(a1)
	addi	a6,a6,4
	addi	a1,a1,4
	bne	a0,a3,.L17
	add	a3,s2,s0
	li	s0,0
.L18:
	lwu	a5,0(a4)
	addi	a4,a4,4
	add	s0,s0,a5
	bne	a3,a4,.L18
.L14:
	mv	a0,s3
	call	free@plt
	mv	a0,s4
	call	free@plt
	mv	a0,s2
	call	free@plt
.L11:
	ld	ra,40(sp)
	mv	a0,s0
	ld	s0,32(sp)
	ld	s1,24(sp)
	ld	s2,16(sp)
	ld	s3,8(sp)
	ld	s4,0(sp)
	addi	sp,sp,48
	jr	ra
.L32:
	li	s0,0
	j	.L14
.L12:
	mv	a0,s3
	call	free@plt
	mv	a0,s4
	call	free@plt
	mv	a0,s2
	call	free@plt
	li	s0,-1
	j	.L11
	.size	vector_kernel, .-vector_kernel
	.section	.rodata.str1.8,"aMS",@progbits,1
	.align	3
.LC0:
	.string	"usage: %s <branch|vector> <positive-size>\n"
	.align	3
.LC1:
	.string	"size must be a positive integer within size_t range\n"
	.align	3
.LC2:
	.string	"branch"
	.align	3
.LC3:
	.string	"vector"
	.align	3
.LC4:
	.string	"allocation failed\n"
	.align	3
.LC5:
	.string	"unknown kernel: %s\n"
	.align	3
.LC6:
	.string	"%lu\n"
	.section	.text.startup,"ax",@progbits
	.align	1
	.globl	main
	.type	main, @function
main:
	addi	sp,sp,-48
	sd	s1,24(sp)
	la	s1,__stack_chk_guard
	ld	a5,0(s1)
	sd	s0,32(sp)
	sd	ra,40(sp)
	sd	a5,8(sp)
	sd	s2,16(sp)
	sd	zero,0(sp)
	li	a5,3
	mv	s0,a1
	bne	a0,a5,.L43
	ld	a0,16(a1)
	li	a2,10
	mv	a1,sp
	call	strtoull@plt
	ld	a5,0(sp)
	ld	a4,16(s0)
	mv	s2,a0
	beq	a4,a5,.L36
	lbu	a5,0(a5)
	bnez	a5,.L36
	beqz	a0,.L36
	ld	s0,8(s0)
	lla	a1,.LC2
	mv	a0,s0
	call	strcmp@plt
	beqz	a0,.L44
	lla	a1,.LC3
	mv	a0,s0
	call	strcmp@plt
	bnez	a0,.L40
	mv	a0,s2
	call	vector_kernel
	li	a5,-1
	mv	a2,a0
	beq	a0,a5,.L45
.L39:
	lla	a1,.LC6
	li	a0,1
	call	__printf_chk@plt
	li	a0,0
	j	.L35
.L36:
	la	a5,stderr
	ld	a0,0(a5)
	lla	a2,.LC1
	li	a1,1
	call	__fprintf_chk@plt
	li	a0,2
.L35:
	ld	a4,8(sp)
	ld	a5,0(s1)
	bne	a4,a5,.L46
	ld	ra,40(sp)
	ld	s0,32(sp)
	ld	s1,24(sp)
	ld	s2,16(sp)
	addi	sp,sp,48
	jr	ra
.L43:
	la	a5,stderr
	ld	a3,0(a1)
	ld	a0,0(a5)
	lla	a2,.LC0
	li	a1,1
	call	__fprintf_chk@plt
	li	a0,2
	j	.L35
.L44:
	mv	a0,s2
	call	branch_kernel
	mv	a2,a0
	j	.L39
.L40:
	la	a5,stderr
	ld	a0,0(a5)
	mv	a3,s0
	lla	a2,.LC5
	li	a1,1
	call	__fprintf_chk@plt
	li	a0,2
	j	.L35
.L45:
	la	a5,stderr
	ld	a0,0(a5)
	lla	a2,.LC4
	li	a1,1
	call	__fprintf_chk@plt
	li	a0,3
	j	.L35
.L46:
	call	__stack_chk_fail@plt
	.size	main, .-main
	.ident	"GCC: (Ubuntu 9.4.0-1ubuntu1~20.04) 9.4.0"
	.section	.note.GNU-stack,"",@progbits
