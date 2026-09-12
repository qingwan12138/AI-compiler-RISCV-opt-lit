	.file	"bench.c"
	.option pic
	.attribute arch, "rv64i2p1_m2p0_a2p1_f2p2_d2p2_c2p0_zicsr2p0_zifencei2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.align	1
	.type	branch_kernel, @function
branch_kernel:
.LFB29:
	.cfi_startproc
	mv	a1,a0
	beq	a0,zero,.L6
	li	a3,-2128830464
	li	a7,-1640529920
	li	a6,16777216
	li	a4,0
	addi	a3,a3,-571
	li	a0,0
	addiw	a7,a7,-1607
	addiw	a6,a6,403
	li	t1,2
	li	t4,89
	li	t3,97
	j	.L5
.L10:
	remuw	a5,a5,t3
	addi	a4,a4,1
	slli	a5,a5,32
	srli	a5,a5,32
	add	a0,a0,a5
	beq	a1,a4,.L9
.L5:
	addw	a5,a4,a7
	xor	a3,a3,a5
	mulw	a5,a6,a3
	andi	a2,a5,7
	sext.w	a3,a5
	bleu	a2,t1,.L10
	remuw	a5,a5,t4
	slli	a5,a5,32
	srli	a5,a5,32
	add	a5,a5,a4
	addi	a4,a4,1
	xor	a0,a0,a5
	bne	a1,a4,.L5
.L9:
	ret
.L6:
	li	a0,0
	ret
	.cfi_endproc
.LFE29:
	.size	branch_kernel, .-branch_kernel
	.align	1
	.type	vector_kernel, @function
vector_kernel:
.LFB30:
	.cfi_startproc
	addi	sp,sp,-48
	.cfi_def_cfa_offset 48
	sd	s0,32(sp)
	.cfi_offset 8, -16
	slli	s0,a0,2
	sd	s1,24(sp)
	.cfi_offset 9, -24
	mv	s1,a0
	mv	a0,s0
	sd	ra,40(sp)
	sd	s2,16(sp)
	sd	s3,8(sp)
	sd	s4,0(sp)
	.cfi_offset 1, -8
	.cfi_offset 18, -32
	.cfi_offset 19, -40
	.cfi_offset 20, -48
	call	malloc@plt
	mv	s3,a0
	mv	a0,s0
	call	malloc@plt
	mv	s4,a0
	mv	a0,s0
	call	malloc@plt
	mv	s2,a0
	beq	s3,zero,.L12
	beq	s4,zero,.L12
	beq	a0,zero,.L12
	beq	s1,zero,.L14
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
	add	s0,s2,s0
	li	s1,0
.L18:
	lwu	a5,0(a4)
	addi	a4,a4,4
	add	s1,s1,a5
	bne	s0,a4,.L18
.L14:
	mv	a0,s3
	call	free@plt
	mv	a0,s4
	call	free@plt
	mv	a0,s2
	call	free@plt
.L11:
	ld	ra,40(sp)
	.cfi_remember_state
	.cfi_restore 1
	ld	s0,32(sp)
	.cfi_restore 8
	ld	s2,16(sp)
	.cfi_restore 18
	ld	s3,8(sp)
	.cfi_restore 19
	ld	s4,0(sp)
	.cfi_restore 20
	mv	a0,s1
	ld	s1,24(sp)
	.cfi_restore 9
	addi	sp,sp,48
	.cfi_def_cfa_offset 0
	jr	ra
.L12:
	.cfi_restore_state
	mv	a0,s3
	call	free@plt
	mv	a0,s4
	call	free@plt
	mv	a0,s2
	call	free@plt
	li	s1,-1
	j	.L11
	.cfi_endproc
.LFE30:
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
.LFB31:
	.cfi_startproc
	addi	sp,sp,-48
	.cfi_def_cfa_offset 48
	sd	s1,24(sp)
	.cfi_offset 9, -24
	la	s1,__stack_chk_guard
	ld	a5, 0(s1)
	sd	a5, 8(sp)
	li	a5, 0
	sd	s0,32(sp)
	sd	ra,40(sp)
	sd	zero,0(sp)
	li	a5,3
	.cfi_offset 8, -16
	.cfi_offset 1, -8
	mv	s0,a1
	bne	a0,a5,.L43
	ld	a0,16(a1)
	li	a2,10
	mv	a1,sp
	sd	s2,16(sp)
	.cfi_offset 18, -32
	call	strtoull@plt
	ld	a5,0(sp)
	ld	a4,16(s0)
	mv	s2,a0
	beq	a4,a5,.L35
	lbu	a5,0(a5)
	bne	a5,zero,.L35
	beq	a0,zero,.L35
	ld	s0,8(s0)
	lla	a1,.LC2
	mv	a0,s0
	call	strcmp@plt
	beq	a0,zero,.L44
	lla	a1,.LC3
	mv	a0,s0
	call	strcmp@plt
	bne	a0,zero,.L40
	mv	a0,s2
	call	vector_kernel
	li	a5,-1
	mv	a2,a0
	beq	a0,a5,.L45
.L39:
	lla	a1,.LC6
	li	a0,2
	call	__printf_chk@plt
	li	a0,0
	ld	s2,16(sp)
	.cfi_remember_state
	.cfi_restore 18
	j	.L37
.L35:
	.cfi_restore_state
	la	a5,stderr
	ld	a0,0(a5)
	lla	a2,.LC1
	li	a1,2
	call	__fprintf_chk@plt
	ld	s2,16(sp)
	.cfi_restore 18
.L34:
	li	a0,2
.L37:
	ld	a4, 8(sp)
	ld	a5, 0(s1)
	xor	a5, a4, a5
	li	a4, 0
	bne	a5,zero,.L46
	ld	ra,40(sp)
	.cfi_remember_state
	.cfi_restore 1
	ld	s0,32(sp)
	.cfi_restore 8
	ld	s1,24(sp)
	.cfi_restore 9
	addi	sp,sp,48
	.cfi_def_cfa_offset 0
	jr	ra
.L43:
	.cfi_restore_state
	la	a5,stderr
	ld	a3,0(a1)
	ld	a0,0(a5)
	lla	a2,.LC0
	li	a1,2
	call	__fprintf_chk@plt
	j	.L34
.L44:
	.cfi_offset 18, -32
	mv	a0,s2
	call	branch_kernel
	mv	a2,a0
	j	.L39
.L40:
	la	a5,stderr
	ld	a0,0(a5)
	mv	a3,s0
	lla	a2,.LC5
	li	a1,2
	call	__fprintf_chk@plt
	ld	s2,16(sp)
	.cfi_remember_state
	.cfi_restore 18
	j	.L34
.L45:
	.cfi_restore_state
	la	a5,stderr
	ld	a0,0(a5)
	lla	a2,.LC4
	li	a1,2
	call	__fprintf_chk@plt
	li	a0,3
	ld	s2,16(sp)
	.cfi_restore 18
	j	.L37
.L46:
	sd	s2,16(sp)
	.cfi_offset 18, -32
	call	__stack_chk_fail@plt
	.cfi_endproc
.LFE31:
	.size	main, .-main
	.ident	"GCC: (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0"
	.section	.note.GNU-stack,"",@progbits
