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
	mv	a7,a0
	beq	a0,zero,.L6
	li	t4,-2128830464
	li	a2,-1640529920
	li	a1,16777216
	andi	a5,a0,3
	li	a3,0
	addi	t4,t4,-571
	li	a0,0
	addiw	t0,a2,-1607
	addiw	t2,a1,403
	li	a6,2
	li	t1,89
	li	t3,97
	beq	a5,zero,.L5
	li	a4,1
	beq	a5,a4,.L23
	beq	a5,a6,.L24
	xor	a0,t4,t0
	mulw	a3,t2,a0
	andi	t5,a3,7
	sext.w	t4,a3
	bgtu	t5,a6,.L40
	remuw	a2,a3,t3
	li	a3,1
	slli	a1,a2,32
	srli	a0,a1,32
.L24:
	addw	a5,a3,t0
	xor	t4,t4,a5
	mulw	t5,t2,t4
	andi	a4,t5,7
	sext.w	t4,t5
	bleu	a4,a6,.L30
	remuw	t6,t5,t1
	slli	a2,t6,32
	srli	a1,a2,32
	add	a5,a1,a3
	xor	a0,a0,a5
	addi	a3,a3,1
.L23:
	addw	a2,a3,t0
	xor	t4,t4,a2
	mulw	a1,t2,t4
	andi	a5,a1,7
	sext.w	t4,a1
	bleu	a5,a6,.L32
	remuw	t5,a1,t1
	slli	a4,t5,32
	srli	t6,a4,32
	add	a2,t6,a3
	xor	a0,a0,a2
.L33:
	addi	a3,a3,1
	bne	a7,a3,.L5
	ret
.L42:
	remuw	a2,t6,t3
	addi	a3,a3,1
	slli	a5,a2,32
	srli	t5,a5,32
	add	t6,a0,t5
	addw	a0,t0,a3
	xor	a1,a1,a0
	mulw	a4,t2,a1
	andi	t4,a4,7
	sext.w	a2,a4
	bgtu	t4,a6,.L17
.L43:
	remuw	a4,a4,t3
	addi	a1,a3,1
	addw	t5,a1,t0
	xor	a2,a2,t5
	mulw	a0,t2,a2
	slli	t4,a4,32
	srli	a5,t4,32
	add	t6,t6,a5
	andi	t4,a0,7
	sext.w	a4,a0
	bleu	t4,a6,.L35
.L44:
	remuw	a5,a0,t1
	slli	t5,a5,32
	srli	a2,t5,32
	add	a1,a2,a1
	addi	a2,a3,2
	addw	t5,a2,t0
	xor	a4,a4,t5
	xor	t6,t6,a1
	mulw	a1,t2,a4
	andi	a0,a1,7
	sext.w	t4,a1
	bleu	a0,a6,.L37
.L45:
	remuw	a5,a1,t1
	addi	a3,a3,3
	slli	t5,a5,32
	srli	a4,t5,32
	add	a2,a4,a2
	xor	a0,t6,a2
	beq	a7,a3,.L41
.L5:
	addw	a4,a3,t0
	xor	t4,t4,a4
	mulw	t6,t2,t4
	andi	a2,t6,7
	sext.w	a1,t6
	bleu	a2,a6,.L42
	remuw	a5,t6,t1
	slli	t5,a5,32
	srli	a4,t5,32
	add	t4,a4,a3
	addi	a3,a3,1
	xor	t6,a0,t4
	addw	a0,t0,a3
	xor	a1,a1,a0
	mulw	a4,t2,a1
	andi	t4,a4,7
	sext.w	a2,a4
	bleu	t4,a6,.L43
.L17:
	remuw	a5,a4,t1
	slli	t5,a5,32
	srli	a0,t5,32
	add	a1,a0,a3
	xor	t6,t6,a1
	addi	a1,a3,1
	addw	t5,a1,t0
	xor	a2,a2,t5
	mulw	a0,t2,a2
	andi	t4,a0,7
	sext.w	a4,a0
	bgtu	t4,a6,.L44
.L35:
	remuw	a0,a0,t3
	addi	a2,a3,2
	addw	t5,a2,t0
	xor	a4,a4,t5
	mulw	a1,t2,a4
	slli	t4,a0,32
	srli	a5,t4,32
	add	t6,t6,a5
	andi	a0,a1,7
	sext.w	t4,a1
	bgtu	a0,a6,.L45
.L37:
	remuw	a1,a1,t3
	addi	a3,a3,3
	slli	a0,a1,32
	srli	a5,a0,32
	add	a0,t6,a5
	bne	a7,a3,.L5
.L41:
	ret
.L32:
	remuw	a1,a1,t3
	slli	a5,a1,32
	srli	t5,a5,32
	add	a0,a0,t5
	j	.L33
.L30:
	remuw	t5,t5,t3
	addi	a3,a3,1
	slli	a4,t5,32
	srli	t6,a4,32
	add	a0,a0,t6
	j	.L23
.L40:
	remuw	t6,a3,t1
	li	a3,1
	andi	a0,t6,127
	j	.L24
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
	addi	sp,sp,-128
	.cfi_def_cfa_offset 128
	sd	s0,112(sp)
	.cfi_offset 8, -16
	slli	s0,a0,2
	sd	s3,88(sp)
	.cfi_offset 19, -40
	mv	s3,a0
	mv	a0,s0
	sd	ra,120(sp)
	sd	s1,104(sp)
	sd	s2,96(sp)
	sd	s4,80(sp)
	.cfi_offset 1, -8
	.cfi_offset 9, -24
	.cfi_offset 18, -32
	.cfi_offset 20, -48
	call	malloc@plt
	mv	s1,a0
	mv	a0,s0
	call	malloc@plt
	mv	s4,a0
	mv	a0,s0
	call	malloc@plt
	mv	s2,a0
	beq	s1,zero,.L47
	beq	s4,zero,.L47
	beq	a0,zero,.L47
	beq	s3,zero,.L49
	andi	a0,s3,7
	mv	a1,s1
	mv	a6,s4
	mv	a3,s4
	mv	a2,s1
	li	a4,0
	li	a5,0
	li	t1,1009
	li	a7,1013
	beq	a0,zero,.L144
	li	t3,1
	beq	a0,t3,.L114
	li	ra,2
	beq	a0,ra,.L115
	li	t0,3
	beq	a0,t0,.L116
	li	t2,4
	beq	a0,t2,.L117
	li	t4,5
	beq	a0,t4,.L118
	li	t5,6
	bne	a0,t5,.L148
.L119:
	remu	t6,a5,t1
	addi	a5,a5,1
	remu	a0,a4,a7
	sw	t6,0(a2)
	addi	a4,a4,7
	addi	a2,a2,4
	sw	a0,0(a3)
	addi	a3,a3,4
.L118:
	remu	t3,a5,t1
	addi	a5,a5,1
	remu	ra,a4,a7
	sw	t3,0(a2)
	addi	a4,a4,7
	addi	a2,a2,4
	sw	ra,0(a3)
	addi	a3,a3,4
.L117:
	remu	t0,a5,t1
	addi	a5,a5,1
	remu	t2,a4,a7
	sw	t0,0(a2)
	addi	a4,a4,7
	addi	a2,a2,4
	sw	t2,0(a3)
	addi	a3,a3,4
.L116:
	remu	t4,a5,t1
	addi	a5,a5,1
	remu	t5,a4,a7
	sw	t4,0(a2)
	addi	a4,a4,7
	addi	a2,a2,4
	sw	t5,0(a3)
	addi	a3,a3,4
.L115:
	remu	t6,a5,t1
	addi	a2,a2,4
	addi	a5,a5,1
	addi	a3,a3,4
	remu	a0,a4,a7
	sw	t6,-4(a2)
	addi	a4,a4,7
	sw	a0,-4(a3)
.L114:
	remu	t3,a5,t1
	addi	a3,a3,4
	addi	a5,a5,1
	addi	a2,a2,4
	remu	ra,a4,a7
	sw	t3,-4(a2)
	addi	a4,a4,7
	sw	ra,-4(a3)
	beq	s3,a5,.L138
.L144:
	sd	s5,72(sp)
	sd	s6,64(sp)
	sd	s7,56(sp)
	sd	s8,48(sp)
	sd	s9,40(sp)
	sd	s10,32(sp)
	sd	s11,24(sp)
	sd	s0,8(sp)
	.cfi_offset 21, -56
	.cfi_offset 22, -64
	.cfi_offset 23, -72
	.cfi_offset 24, -80
	.cfi_offset 25, -88
	.cfi_offset 26, -96
	.cfi_offset 27, -104
.L51:
	addi	s9,a5,1
	addi	t2,a4,7
	addi	s8,a5,2
	addi	t0,a4,14
	addi	s7,a5,3
	addi	t6,a4,21
	addi	s6,a5,4
	addi	t5,a4,28
	addi	s5,a5,5
	addi	t4,a4,35
	addi	s0,a5,6
	addi	t3,a4,42
	addi	ra,a5,7
	addi	a0,a4,49
	remu	s11,a5,t1
	addi	a3,a3,32
	addi	a5,a5,8
	addi	a2,a2,32
	remu	s10,a4,a7
	sw	s11,-32(a2)
	addi	a4,a4,56
	remu	s9,s9,t1
	sw	s10,-32(a3)
	remu	t2,t2,a7
	sw	s9,-28(a2)
	remu	s8,s8,t1
	sw	t2,-28(a3)
	remu	t0,t0,a7
	sw	s8,-24(a2)
	remu	s7,s7,t1
	sw	t0,-24(a3)
	remu	t6,t6,a7
	sw	s7,-20(a2)
	remu	s6,s6,t1
	sw	t6,-20(a3)
	remu	t5,t5,a7
	sw	s6,-16(a2)
	remu	s5,s5,t1
	sw	t5,-16(a3)
	remu	t4,t4,a7
	sw	s5,-12(a2)
	remu	s0,s0,t1
	sw	t4,-12(a3)
	remu	t3,t3,a7
	sw	s0,-8(a2)
	remu	ra,ra,t1
	sw	t3,-8(a3)
	remu	a0,a0,a7
	sw	ra,-4(a2)
	sw	a0,-4(a3)
	bne	s3,a5,.L51
	ld	s0,8(sp)
	ld	s5,72(sp)
	.cfi_restore 21
	ld	s6,64(sp)
	.cfi_restore 22
	ld	s7,56(sp)
	.cfi_restore 23
	ld	s8,48(sp)
	.cfi_restore 24
	ld	s9,40(sp)
	.cfi_restore 25
	ld	s10,32(sp)
	.cfi_restore 26
	ld	s11,24(sp)
	.cfi_restore 27
.L138:
	addi	s3,s0,-4
	srli	t1,s3,2
	addi	a7,t1,1
	andi	a3,a7,3
	mv	a4,s2
	add	t6,s1,s0
	mv	a5,s2
	beq	a3,zero,.L147
	li	a2,1
	beq	a3,a2,.L120
	li	t2,2
	beq	a3,t2,.L121
	lw	a6,0(s1)
	lw	t0,0(s4)
	addi	a1,s1,4
	slliw	a5,a6,1
	slliw	t5,t0,2
	addw	t4,a5,a6
	addw	t3,t5,t0
	addw	ra,t4,t3
	sw	ra,0(s2)
	addi	a6,s4,4
	addi	a5,s2,4
.L121:
	lw	s3,0(a1)
	lw	a0,0(a6)
	addi	a1,a1,4
	slliw	t1,s3,1
	slliw	a7,a0,2
	addw	a3,t1,s3
	addw	a2,a7,a0
	addw	t2,a3,a2
	sw	t2,0(a5)
	addi	a6,a6,4
	addi	a5,a5,4
.L120:
	lw	t0,0(a1)
	lw	t5,0(a6)
	addi	a1,a1,4
	slliw	t4,t0,1
	slliw	t3,t5,2
	addw	ra,t4,t0
	addw	s3,t3,t5
	addw	a0,ra,s3
	sw	a0,0(a5)
	addi	a6,a6,4
	addi	a5,a5,4
	beq	t6,a1,.L137
.L147:
	sd	s5,72(sp)
	sd	s6,64(sp)
	sd	s7,56(sp)
	sd	s8,48(sp)
	.cfi_offset 21, -56
	.cfi_offset 22, -64
	.cfi_offset 23, -72
	.cfi_offset 24, -80
.L52:
	lw	s8,0(a1)
	lw	s7,0(a6)
	lw	s6,4(a1)
	lw	s5,4(a6)
	lw	s3,8(a1)
	lw	ra,8(a6)
	lw	t2,12(a1)
	lw	t0,12(a6)
	slliw	a7,s8,1
	slliw	t5,s7,2
	slliw	a0,s6,1
	slliw	t4,s5,2
	slliw	a2,s3,1
	slliw	t3,ra,2
	slliw	a3,t2,1
	slliw	t1,t0,2
	addw	s7,t5,s7
	addw	s6,a0,s6
	addw	s5,t4,s5
	addw	s8,a7,s8
	addw	s3,a2,s3
	addw	ra,t3,ra
	addw	t2,a3,t2
	addw	t0,t1,t0
	addw	a7,s8,s7
	addw	t5,s6,s5
	addw	a0,s3,ra
	addw	t4,t2,t0
	sw	a7,0(a5)
	sw	t5,4(a5)
	sw	a0,8(a5)
	sw	t4,12(a5)
	addi	a1,a1,16
	addi	a6,a6,16
	addi	a5,a5,16
	bne	t6,a1,.L52
	ld	s5,72(sp)
	.cfi_restore 21
	ld	s6,64(sp)
	.cfi_restore 22
	ld	s7,56(sp)
	.cfi_restore 23
	ld	s8,48(sp)
	.cfi_restore 24
.L137:
	addi	t6,s0,-4
	srli	a1,t6,2
	addi	a6,a1,1
	andi	a5,a6,7
	add	s0,s2,s0
	li	s3,0
	beq	a5,zero,.L53
	li	a2,1
	beq	a5,a2,.L122
	li	t3,2
	beq	a5,t3,.L123
	li	a3,3
	beq	a5,a3,.L124
	li	t1,4
	beq	a5,t1,.L125
	li	ra,5
	beq	a5,ra,.L126
	li	t2,6
	bne	a5,t2,.L149
.L127:
	lwu	t0,0(a4)
	addi	a4,a4,4
	add	s3,s3,t0
.L126:
	lwu	a7,0(a4)
	addi	a4,a4,4
	add	s3,s3,a7
.L125:
	lwu	t5,0(a4)
	addi	a4,a4,4
	add	s3,s3,t5
.L124:
	lwu	a0,0(a4)
	addi	a4,a4,4
	add	s3,s3,a0
.L123:
	lwu	t4,0(a4)
	addi	a4,a4,4
	add	s3,s3,t4
.L122:
	lwu	t6,0(a4)
	addi	a4,a4,4
	add	s3,s3,t6
	beq	s0,a4,.L49
.L53:
	lwu	a1,0(a4)
	lwu	a6,4(a4)
	lwu	t3,8(a4)
	lwu	a5,12(a4)
	add	a2,s3,a1
	lwu	t1,16(a4)
	add	a3,a2,a6
	lwu	ra,20(a4)
	add	t2,a3,t3
	lwu	t0,24(a4)
	add	a7,t2,a5
	lwu	t5,28(a4)
	add	a0,a7,t1
	add	t4,a0,ra
	add	t6,t4,t0
	addi	a4,a4,32
	add	s3,t6,t5
	bne	s0,a4,.L53
.L49:
	mv	a0,s1
	call	free@plt
	mv	a0,s4
	call	free@plt
	mv	a0,s2
	call	free@plt
.L46:
	ld	ra,120(sp)
	.cfi_remember_state
	.cfi_restore 1
	ld	s0,112(sp)
	.cfi_restore 8
	ld	s1,104(sp)
	.cfi_restore 9
	ld	s2,96(sp)
	.cfi_restore 18
	ld	s4,80(sp)
	.cfi_restore 20
	mv	a0,s3
	ld	s3,88(sp)
	.cfi_restore 19
	addi	sp,sp,128
	.cfi_def_cfa_offset 0
	jr	ra
.L148:
	.cfi_restore_state
	sw	zero,0(s1)
	sw	zero,0(s4)
	li	a5,1
	addi	a2,s1,4
	li	a4,7
	addi	a3,s4,4
	j	.L119
.L149:
	lwu	s3,0(s2)
	addi	a4,s2,4
	j	.L127
.L47:
	mv	a0,s1
	call	free@plt
	mv	a0,s4
	call	free@plt
	mv	a0,s2
	call	free@plt
	li	s3,-1
	j	.L46
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
	bne	a0,a5,.L161
	ld	a0,16(a1)
	li	a2,10
	mv	a1,sp
	sd	s2,16(sp)
	.cfi_offset 18, -32
	call	strtoull@plt
	ld	t0,0(sp)
	ld	a4,16(s0)
	mv	s2,a0
	beq	a4,t0,.L153
	lbu	ra,0(t0)
	bne	ra,zero,.L153
	beq	a0,zero,.L153
	ld	s0,8(s0)
	lla	a1,.LC2
	mv	a0,s0
	call	strcmp@plt
	beq	a0,zero,.L162
	lla	a1,.LC3
	mv	a0,s0
	call	strcmp@plt
	bne	a0,zero,.L158
	mv	a0,s2
	call	vector_kernel
	li	t2,-1
	mv	a2,a0
	beq	a0,t2,.L163
.L157:
	lla	a1,.LC6
	li	a0,2
	call	__printf_chk@plt
	li	a0,0
	ld	s2,16(sp)
	.cfi_remember_state
	.cfi_restore 18
	j	.L155
.L153:
	.cfi_restore_state
	la	a1,stderr
	ld	a0,0(a1)
	lla	a2,.LC1
	li	a1,2
	call	__fprintf_chk@plt
	ld	s2,16(sp)
	.cfi_restore 18
.L152:
	li	a0,2
.L155:
	ld	a4, 8(sp)
	ld	a3, 0(s1)
	xor	a3, a4, a3
	li	a4, 0
	bne	a3,zero,.L164
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
.L161:
	.cfi_restore_state
	la	a2,stderr
	ld	a3,0(a1)
	ld	a0,0(a2)
	li	a1,2
	lla	a2,.LC0
	call	__fprintf_chk@plt
	j	.L152
.L162:
	.cfi_offset 18, -32
	mv	a0,s2
	call	branch_kernel
	mv	a2,a0
	j	.L157
.L158:
	la	t1,stderr
	ld	a0,0(t1)
	mv	a3,s0
	lla	a2,.LC5
	li	a1,2
	call	__fprintf_chk@plt
	ld	s2,16(sp)
	.cfi_remember_state
	.cfi_restore 18
	j	.L152
.L163:
	.cfi_restore_state
	la	a0,stderr
	ld	a0,0(a0)
	lla	a2,.LC4
	li	a1,2
	call	__fprintf_chk@plt
	li	a0,3
	ld	s2,16(sp)
	.cfi_restore 18
	j	.L155
.L164:
	sd	s2,16(sp)
	.cfi_offset 18, -32
	call	__stack_chk_fail@plt
	.cfi_endproc
.LFE31:
	.size	main, .-main
	.ident	"GCC: (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0"
	.section	.note.GNU-stack,"",@progbits
