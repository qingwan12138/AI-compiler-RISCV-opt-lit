	.file	"bench.c"
	.option pic
	.attribute arch, "rv64i2p1_m2p0_a2p1_f2p2_d2p2_c2p0_zicsr2p0_zifencei2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.align	1
	.type	branch_kernel, @function
branch_kernel:
.LFB22:
	.cfi_startproc
	li	a4,-2128830464
	li	a1,-1640529920
	li	a6,16777216
	mv	a2,a0
	li	a3,0
	addi	a4,a4,-571
	li	a0,0
	addiw	a1,a1,-1607
	addiw	a6,a6,403
	li	a7,2
	li	t1,89
	li	t3,97
.L2:
	bne	a3,a2,.L5
	ret
.L5:
	addw	a5,a3,a1
	xor	a4,a4,a5
	mulw	a5,a6,a4
	andi	t4,a5,7
	sext.w	a4,a5
	bgtu	t4,a7,.L3
	remuw	a5,a5,t3
	slli	a5,a5,32
	srli	a5,a5,32
	add	a0,a0,a5
.L4:
	addi	a3,a3,1
	j	.L2
.L3:
	remuw	a5,a5,t1
	slli	a5,a5,32
	srli	a5,a5,32
	add	a5,a5,a3
	xor	a0,a0,a5
	j	.L4
	.cfi_endproc
.LFE22:
	.size	branch_kernel, .-branch_kernel
	.align	1
	.type	vector_kernel, @function
vector_kernel:
.LFB23:
	.cfi_startproc
	addi	sp,sp,-48
	.cfi_def_cfa_offset 48
	sd	s4,0(sp)
	.cfi_offset 20, -48
	slli	s4,a0,2
	sd	s3,8(sp)
	.cfi_offset 19, -40
	mv	s3,a0
	mv	a0,s4
	sd	ra,40(sp)
	sd	s0,32(sp)
	sd	s1,24(sp)
	sd	s2,16(sp)
	.cfi_offset 1, -8
	.cfi_offset 8, -16
	.cfi_offset 9, -24
	.cfi_offset 18, -32
	call	malloc@plt
	mv	s2,a0
	mv	a0,s4
	call	malloc@plt
	mv	s1,a0
	mv	a0,s4
	call	malloc@plt
	mv	s0,a0
	beq	s2,zero,.L7
	beq	s1,zero,.L7
	li	a5,0
	beq	a0,zero,.L7
	li	a2,1009
	li	a1,7
	li	a0,1013
.L8:
	bne	a5,s3,.L10
	li	a5,0
	li	a2,3
	li	a1,5
.L11:
	bne	s4,a5,.L12
	li	a5,0
	li	s4,0
.L13:
	bne	a5,s3,.L14
	mv	a0,s2
	call	free@plt
	mv	a0,s1
	call	free@plt
	mv	a0,s0
	call	free@plt
	j	.L6
.L7:
	mv	a0,s2
	call	free@plt
	mv	a0,s1
	call	free@plt
	mv	a0,s0
	call	free@plt
	li	s4,-1
.L6:
	ld	ra,40(sp)
	.cfi_remember_state
	.cfi_restore 1
	ld	s0,32(sp)
	.cfi_restore 8
	ld	s1,24(sp)
	.cfi_restore 9
	ld	s2,16(sp)
	.cfi_restore 18
	ld	s3,8(sp)
	.cfi_restore 19
	mv	a0,s4
	ld	s4,0(sp)
	.cfi_restore 20
	addi	sp,sp,48
	.cfi_def_cfa_offset 0
	jr	ra
.L10:
	.cfi_restore_state
	remu	a6,a5,a2
	slli	a4,a5,2
	add	a3,s2,a4
	add	a4,s1,a4
	sw	a6,0(a3)
	mul	a3,a5,a1
	addi	a5,a5,1
	remu	a3,a3,a0
	sw	a3,0(a4)
	j	.L8
.L12:
	add	a4,s2,a5
	add	a3,s1,a5
	lw	a4,0(a4)
	lw	a3,0(a3)
	add	a0,s0,a5
	mulw	a4,a2,a4
	addi	a5,a5,4
	mulw	a3,a1,a3
	addw	a4,a4,a3
	sw	a4,0(a0)
	j	.L11
.L14:
	slli	a4,a5,2
	add	a4,s0,a4
	lwu	a4,0(a4)
	addi	a5,a5,1
	add	s4,s4,a4
	j	.L13
	.cfi_endproc
.LFE23:
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
.LFB24:
	.cfi_startproc
	addi	sp,sp,-64
	.cfi_def_cfa_offset 64
	sd	s3,24(sp)
	.cfi_offset 19, -40
	la	s3,__stack_chk_guard
	ld	a5, 0(s3)
	sd	a5, 8(sp)
	li	a5, 0
	sd	s1,40(sp)
	sd	ra,56(sp)
	sd	s0,48(sp)
	sd	s2,32(sp)
	.cfi_offset 9, -24
	.cfi_offset 1, -8
	.cfi_offset 8, -16
	.cfi_offset 18, -32
	sd	zero,0(sp)
	li	a5,3
	mv	s1,a1
	beq	a0,a5,.L25
	ld	a3,0(a1)
	lla	a2,.LC0
.L35:
	la	a5,stderr
	ld	a0,0(a5)
	li	a1,2
	call	__fprintf_chk@plt
	j	.L26
.L25:
	mv	s0,a0
	ld	a0,16(s1)
	li	a2,10
	mv	a1,sp
	call	strtoull@plt
	ld	a5,0(sp)
	ld	a4,16(s1)
	mv	s2,a0
	beq	a4,a5,.L27
	lbu	a5,0(a5)
	bne	a5,zero,.L27
	bne	a0,zero,.L28
.L27:
	la	a5,stderr
	ld	a0,0(a5)
	lla	a2,.LC1
	li	a1,2
	call	__fprintf_chk@plt
.L26:
	li	s0,2
.L29:
	ld	a4, 8(sp)
	ld	a5, 0(s3)
	xor	a5, a4, a5
	li	a4, 0
	beq	a5,zero,.L33
	call	__stack_chk_fail@plt
.L28:
	ld	s1,8(s1)
	lla	a1,.LC2
	mv	a0,s1
	call	strcmp@plt
	bne	a0,zero,.L30
	mv	a0,s2
	call	branch_kernel
	mv	a2,a0
.L31:
	lla	a1,.LC6
	li	a0,2
	call	__printf_chk@plt
	li	s0,0
	j	.L29
.L30:
	lla	a1,.LC3
	mv	a0,s1
	call	strcmp@plt
	bne	a0,zero,.L32
	mv	a0,s2
	call	vector_kernel
	li	a5,-1
	mv	a2,a0
	bne	a0,a5,.L31
	la	a5,stderr
	ld	a0,0(a5)
	lla	a2,.LC4
	li	a1,2
	call	__fprintf_chk@plt
	j	.L29
.L32:
	mv	a3,s1
	lla	a2,.LC5
	j	.L35
.L33:
	ld	ra,56(sp)
	.cfi_restore 1
	mv	a0,s0
	ld	s0,48(sp)
	.cfi_restore 8
	ld	s1,40(sp)
	.cfi_restore 9
	ld	s2,32(sp)
	.cfi_restore 18
	ld	s3,24(sp)
	.cfi_restore 19
	addi	sp,sp,64
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE24:
	.size	main, .-main
	.ident	"GCC: (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0"
	.section	.note.GNU-stack,"",@progbits
