	.file	"bench.c"
	.text
	.p2align 4
	.type	branch_kernel, @function
branch_kernel:
.LFB34:
	.cfi_startproc
	testq	%rdi, %rdi
	je	.L6
	xorl	%ecx, %ecx
	movl	$-2128831035, %eax
	xorl	%r8d, %r8d
	movl	$3088515809, %esi
	jmp	.L5
	.p2align 4,,10
	.p2align 3
.L9:
	imulq	$1372618415, %rdx, %rdx
	movl	%eax, %r10d
	incq	%rcx
	shrq	$32, %rdx
	movq	%rdx, %r9
	movl	%eax, %edx
	subl	%r9d, %edx
	shrl	%edx
	addl	%r9d, %edx
	shrl	$6, %edx
	imull	$97, %edx, %edx
	subl	%edx, %r10d
	addq	%r10, %r8
	cmpq	%rcx, %rdi
	je	.L1
.L5:
	leal	-1640531527(%rcx), %edx
	xorl	%edx, %eax
	imull	$16777619, %eax, %eax
	movl	%eax, %edx
	andl	$7, %edx
	cmpl	$2, %edx
	movl	%eax, %edx
	jbe	.L9
	imulq	%rsi, %rdx
	movl	%eax, %r11d
	shrq	$38, %rdx
	imull	$89, %edx, %edx
	subl	%edx, %r11d
	movq	%r11, %rdx
	addq	%rcx, %rdx
	incq	%rcx
	xorq	%rdx, %r8
	cmpq	%rcx, %rdi
	jne	.L5
.L1:
	movq	%r8, %rax
	ret
.L6:
	xorl	%r8d, %r8d
	jmp	.L1
	.cfi_endproc
.LFE34:
	.size	branch_kernel, .-branch_kernel
	.p2align 4
	.type	vector_kernel, @function
vector_kernel:
.LFB35:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	pushq	%r15
	pushq	%r14
	.cfi_offset 15, -24
	.cfi_offset 14, -32
	leaq	0(,%rdi,4), %r14
	pushq	%r13
	pushq	%r12
	pushq	%rbx
	.cfi_offset 13, -40
	.cfi_offset 12, -48
	.cfi_offset 3, -56
	movq	%rdi, %rbx
	movq	%r14, %rdi
	andq	$-32, %rsp
	call	malloc@PLT
	movq	%r14, %rdi
	movq	%rax, %r12
	call	malloc@PLT
	movq	%r14, %rdi
	movq	%rax, %r13
	call	malloc@PLT
	testq	%r12, %r12
	sete	%dl
	testq	%r13, %r13
	movq	%rax, %r14
	sete	%al
	orb	%al, %dl
	jne	.L11
	testq	%r14, %r14
	je	.L11
	xorl	%esi, %esi
	xorl	%ecx, %ecx
	movabsq	$-9086255505087856445, %r8
	movabsq	$-9123216960442729871, %rdi
	xorl	%r15d, %r15d
	testq	%rbx, %rbx
	je	.L13
	.p2align 4,,10
	.p2align 3
.L12:
	movq	%rcx, %rax
	mulq	%r8
	movq	%rcx, %rax
	movq	%rcx, %r9
	shrq	$9, %rdx
	imulq	$1009, %rdx, %rdx
	subq	%rdx, %rax
	movl	%eax, (%r12,%rcx,4)
	movq	%rsi, %rax
	mulq	%rdi
	movq	%rsi, %rax
	addq	$7, %rsi
	shrq	$9, %rdx
	imulq	$1013, %rdx, %rdx
	subq	%rdx, %rax
	movl	%eax, 0(%r13,%rcx,4)
	incq	%rcx
	cmpq	%rcx, %rbx
	jne	.L12
	cmpq	$6, %r9
	jbe	.L27
	movq	%rcx, %rdx
	shrq	$3, %rdx
	salq	$5, %rdx
	xorl	%eax, %eax
	.p2align 4,,10
	.p2align 3
.L16:
	vmovdqu	(%r12,%rax), %ymm1
	vmovdqu	0(%r13,%rax), %ymm2
	vpslld	$1, %ymm1, %ymm0
	vpaddd	%ymm1, %ymm0, %ymm0
	vpslld	$2, %ymm2, %ymm1
	vpaddd	%ymm2, %ymm1, %ymm1
	vpaddd	%ymm1, %ymm0, %ymm0
	vmovdqu	%ymm0, (%r14,%rax)
	addq	$32, %rax
	cmpq	%rdx, %rax
	jne	.L16
	movq	%rcx, %rax
	andq	$-8, %rax
	testb	$7, %cl
	je	.L17
.L15:
	movl	(%r12,%rax,4), %edx
	movl	0(%r13,%rax,4), %esi
	leal	(%rdx,%rdx,2), %edx
	leal	(%rsi,%rsi,4), %esi
	addl	%esi, %edx
	movl	%edx, (%r14,%rax,4)
	leaq	1(%rax), %rdx
	cmpq	%rdx, %rcx
	jbe	.L18
	movl	(%r12,%rdx,4), %esi
	movl	0(%r13,%rdx,4), %edi
	leal	(%rsi,%rsi,2), %esi
	leal	(%rdi,%rdi,4), %edi
	addl	%edi, %esi
	movl	%esi, (%r14,%rdx,4)
	leaq	2(%rax), %rdx
	cmpq	%rdx, %rcx
	jbe	.L19
	imull	$3, (%r12,%rdx,4), %esi
	imull	$5, 0(%r13,%rdx,4), %edi
	addl	%edi, %esi
	movl	%esi, (%r14,%rdx,4)
	leaq	3(%rax), %rdx
	cmpq	%rdx, %rcx
	jbe	.L19
	imull	$3, (%r12,%rdx,4), %esi
	imull	$5, 0(%r13,%rdx,4), %edi
	addl	%edi, %esi
	movl	%esi, (%r14,%rdx,4)
	leaq	4(%rax), %rdx
	cmpq	%rdx, %rcx
	jbe	.L19
	imull	$3, (%r12,%rdx,4), %esi
	imull	$5, 0(%r13,%rdx,4), %edi
	addl	%edi, %esi
	movl	%esi, (%r14,%rdx,4)
	leaq	5(%rax), %rdx
	cmpq	%rdx, %rcx
	jbe	.L19
	imull	$3, (%r12,%rdx,4), %esi
	imull	$5, 0(%r13,%rdx,4), %edi
	addq	$6, %rax
	addl	%edi, %esi
	movl	%esi, (%r14,%rdx,4)
	cmpq	%rax, %rcx
	jbe	.L19
	imull	$5, 0(%r13,%rax,4), %edx
	imull	$3, (%r12,%rax,4), %esi
	addl	%esi, %edx
	movl	%edx, (%r14,%rax,4)
.L19:
	cmpq	$6, %r9
	jbe	.L40
.L17:
	movq	%rcx, %rdx
	shrq	$3, %rdx
	salq	$5, %rdx
	movq	%r14, %rax
	addq	%r14, %rdx
	vpxor	%xmm2, %xmm2, %xmm2
	.p2align 4,,10
	.p2align 3
.L21:
	vmovdqu	(%rax), %ymm0
	addq	$32, %rax
	vextracti128	$0x1, %ymm0, %xmm1
	vpmovzxdq	%xmm1, %ymm1
	vpmovzxdq	%xmm0, %ymm0
	vpaddq	%ymm0, %ymm1, %ymm0
	vpaddq	%ymm0, %ymm2, %ymm2
	cmpq	%rdx, %rax
	jne	.L21
	vextracti128	$0x1, %ymm2, %xmm0
	vpaddq	%xmm2, %xmm0, %xmm2
	vpsrldq	$8, %xmm2, %xmm0
	vpaddq	%xmm0, %xmm2, %xmm2
	movq	%rcx, %rax
	vmovq	%xmm2, %r15
	andq	$-8, %rax
	testb	$7, %cl
	je	.L38
.L20:
	movl	(%r14,%rax,4), %edx
	incq	%rax
	addq	%rdx, %r15
	cmpq	%rcx, %rax
	jnb	.L38
.L24:
	movl	(%r14,%rax,4), %edx
	addq	%rdx, %r15
	leaq	1(%rax), %rdx
	cmpq	%rcx, %rdx
	jnb	.L38
	movl	(%r14,%rdx,4), %edx
	addq	%rdx, %r15
	leaq	2(%rax), %rdx
	cmpq	%rdx, %rcx
	jbe	.L38
	movl	(%r14,%rdx,4), %edx
	addq	%rdx, %r15
	leaq	3(%rax), %rdx
	cmpq	%rdx, %rcx
	jbe	.L38
	movl	(%r14,%rdx,4), %edx
	addq	%rdx, %r15
	leaq	4(%rax), %rdx
	cmpq	%rdx, %rcx
	jbe	.L38
	movl	(%r14,%rdx,4), %edx
	addq	$5, %rax
	addq	%rdx, %r15
	cmpq	%rax, %rcx
	jbe	.L38
	movl	(%r14,%rax,4), %eax
	addq	%rax, %r15
	vzeroupper
.L13:
	movq	%r12, %rdi
	call	free@PLT
	movq	%r13, %rdi
	call	free@PLT
	movq	%r14, %rdi
	call	free@PLT
.L10:
	leaq	-40(%rbp), %rsp
	popq	%rbx
	popq	%r12
	popq	%r13
	popq	%r14
	movq	%r15, %rax
	popq	%r15
	popq	%rbp
	.cfi_remember_state
	.cfi_def_cfa 7, 8
	ret
.L38:
	.cfi_restore_state
	vzeroupper
	jmp	.L13
.L27:
	xorl	%eax, %eax
	jmp	.L15
.L18:
	cmpq	$6, %r9
	ja	.L17
	xorl	%eax, %eax
	xorl	%r15d, %r15d
	jmp	.L20
.L40:
	movl	(%r14), %r15d
	movl	$1, %eax
	jmp	.L24
.L11:
	movq	%r12, %rdi
	call	free@PLT
	movq	%r13, %rdi
	call	free@PLT
	movq	%r14, %rdi
	call	free@PLT
	orq	$-1, %r15
	jmp	.L10
	.cfi_endproc
.LFE35:
	.size	vector_kernel, .-vector_kernel
	.section	.rodata.str1.8,"aMS",@progbits,1
	.align 8
.LC0:
	.string	"usage: %s <branch|vector> <positive-size>\n"
	.align 8
.LC1:
	.string	"size must be a positive integer within size_t range\n"
	.section	.rodata.str1.1,"aMS",@progbits,1
.LC2:
	.string	"branch"
.LC3:
	.string	"vector"
.LC4:
	.string	"allocation failed\n"
.LC5:
	.string	"unknown kernel: %s\n"
.LC6:
	.string	"%lu\n"
	.section	.text.startup,"ax",@progbits
	.p2align 4
	.globl	main
	.type	main, @function
main:
.LFB36:
	.cfi_startproc
	endbr64
	pushq	%r12
	.cfi_def_cfa_offset 16
	.cfi_offset 12, -16
	pushq	%rbp
	.cfi_def_cfa_offset 24
	.cfi_offset 6, -24
	pushq	%rbx
	.cfi_def_cfa_offset 32
	.cfi_offset 3, -32
	movq	%rsi, %rbx
	subq	$16, %rsp
	.cfi_def_cfa_offset 48
	movq	%fs:40, %rax
	movq	%rax, 8(%rsp)
	xorl	%eax, %eax
	movq	$0, (%rsp)
	cmpl	$3, %edi
	jne	.L53
	movq	16(%rbx), %rdi
	movq	%rsp, %rsi
	movl	$10, %edx
	call	strtoull@PLT
	movq	%rax, %rbp
	movq	(%rsp), %rax
	cmpq	%rax, 16(%rbx)
	je	.L44
	cmpb	$0, (%rax)
	jne	.L44
	testq	%rbp, %rbp
	je	.L44
	movq	8(%rbx), %r12
	leaq	.LC2(%rip), %rsi
	movq	%r12, %rdi
	call	strcmp@PLT
	testl	%eax, %eax
	je	.L54
	leaq	.LC3(%rip), %rsi
	movq	%r12, %rdi
	call	strcmp@PLT
	testl	%eax, %eax
	jne	.L49
	movq	%rbp, %rdi
	call	vector_kernel
	movq	%rax, %rdx
	cmpq	$-1, %rax
	je	.L55
.L48:
	leaq	.LC6(%rip), %rsi
	movl	$1, %edi
	xorl	%eax, %eax
	call	__printf_chk@PLT
	xorl	%eax, %eax
	jmp	.L41
.L44:
	movq	stderr(%rip), %rdi
	leaq	.LC1(%rip), %rdx
	movl	$1, %esi
	xorl	%eax, %eax
	call	__fprintf_chk@PLT
	movl	$2, %eax
.L41:
	movq	8(%rsp), %rcx
	xorq	%fs:40, %rcx
	jne	.L56
	addq	$16, %rsp
	.cfi_remember_state
	.cfi_def_cfa_offset 32
	popq	%rbx
	.cfi_def_cfa_offset 24
	popq	%rbp
	.cfi_def_cfa_offset 16
	popq	%r12
	.cfi_def_cfa_offset 8
	ret
.L53:
	.cfi_restore_state
	movq	(%rsi), %rcx
	movq	stderr(%rip), %rdi
	leaq	.LC0(%rip), %rdx
	movl	$1, %esi
	call	__fprintf_chk@PLT
	movl	$2, %eax
	jmp	.L41
.L54:
	movq	%rbp, %rdi
	call	branch_kernel
	movq	%rax, %rdx
	jmp	.L48
.L49:
	movq	stderr(%rip), %rdi
	movq	%r12, %rcx
	leaq	.LC5(%rip), %rdx
	movl	$1, %esi
	xorl	%eax, %eax
	call	__fprintf_chk@PLT
	movl	$2, %eax
	jmp	.L41
.L55:
	movq	stderr(%rip), %rdi
	leaq	.LC4(%rip), %rdx
	movl	$1, %esi
	xorl	%eax, %eax
	call	__fprintf_chk@PLT
	movl	$3, %eax
	jmp	.L41
.L56:
	call	__stack_chk_fail@PLT
	.cfi_endproc
.LFE36:
	.size	main, .-main
	.ident	"GCC: (Ubuntu 9.4.0-1ubuntu1~20.04.2) 9.4.0"
	.section	.note.GNU-stack,"",@progbits
	.section	.note.gnu.property,"a"
	.align 8
	.long	 1f - 0f
	.long	 4f - 1f
	.long	 5
0:
	.string	 "GNU"
1:
	.align 8
	.long	 0xc0000002
	.long	 3f - 2f
2:
	.long	 0x3
3:
	.align 8
4:
