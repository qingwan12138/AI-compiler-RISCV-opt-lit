	.file	"bench.c"
	.text
	.p2align 4
	.type	branch_kernel, @function
branch_kernel:
.LFB29:
	.cfi_startproc
	testq	%rdi, %rdi
	je	.L6
	xorl	%ecx, %ecx
	movl	$-2128831035, %eax
	xorl	%esi, %esi
	movl	$3088515809, %r8d
	jmp	.L5
	.p2align 4,,10
	.p2align 3
.L9:
	movl	%eax, %r9d
	movl	%eax, %edx
	incq	%rcx
	imulq	$1372618415, %r9, %r9
	shrq	$32, %r9
	subl	%r9d, %edx
	shrl	%edx
	addl	%r9d, %edx
	movl	%eax, %r9d
	shrl	$6, %edx
	imull	$97, %edx, %edx
	subl	%edx, %r9d
	addq	%r9, %rsi
	cmpq	%rcx, %rdi
	je	.L1
.L5:
	leal	-1640531527(%rcx), %edx
	xorl	%edx, %eax
	imull	$16777619, %eax, %eax
	movl	%eax, %edx
	andl	$7, %edx
	cmpl	$2, %edx
	jbe	.L9
	movl	%eax, %edx
	movl	%eax, %r9d
	imulq	%r8, %rdx
	shrq	$38, %rdx
	imull	$89, %edx, %edx
	subl	%edx, %r9d
	leaq	(%r9,%rcx), %rdx
	incq	%rcx
	xorq	%rdx, %rsi
	cmpq	%rcx, %rdi
	jne	.L5
.L1:
	movq	%rsi, %rax
	ret
.L6:
	xorl	%esi, %esi
	jmp	.L1
	.cfi_endproc
.LFE29:
	.size	branch_kernel, .-branch_kernel
	.p2align 4
	.type	vector_kernel, @function
vector_kernel:
.LFB30:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	pushq	%r14
	.cfi_offset 14, -24
	movq	%rdi, %r14
	pushq	%r13
	.cfi_offset 13, -32
	leaq	0(,%rdi,4), %r13
	movq	%r13, %rdi
	pushq	%r12
	pushq	%rbx
	andq	$-32, %rsp
	.cfi_offset 12, -40
	.cfi_offset 3, -48
	call	malloc@PLT
	movq	%r13, %rdi
	movq	%rax, %r12
	call	malloc@PLT
	movq	%r13, %rdi
	movq	%rax, %rbx
	call	malloc@PLT
	testq	%r12, %r12
	movq	%rax, %r13
	sete	%al
	testq	%rbx, %rbx
	sete	%dl
	orb	%dl, %al
	jne	.L11
	testq	%r13, %r13
	je	.L11
	xorl	%esi, %esi
	xorl	%ecx, %ecx
	movabsq	$-9086255505087856445, %r8
	movabsq	$-9123216960442729871, %rdi
	testq	%r14, %r14
	je	.L13
	.p2align 4,,10
	.p2align 3
.L12:
	movq	%rcx, %rax
	movq	%rcx, %r9
	mulq	%r8
	movq	%rcx, %rax
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
	movl	%eax, (%rbx,%rcx,4)
	incq	%rcx
	cmpq	%rcx, %r14
	jne	.L12
	cmpq	$6, %r9
	jbe	.L28
	movq	%rcx, %rdx
	xorl	%eax, %eax
	shrq	$3, %rdx
	salq	$5, %rdx
	.p2align 4,,10
	.p2align 3
.L16:
	vmovdqu	(%r12,%rax), %ymm1
	vmovdqu	(%rbx,%rax), %ymm2
	vpslld	$1, %ymm1, %ymm0
	vpaddd	%ymm1, %ymm0, %ymm0
	vpslld	$2, %ymm2, %ymm1
	vpaddd	%ymm2, %ymm1, %ymm1
	vpaddd	%ymm1, %ymm0, %ymm0
	vmovdqu	%ymm0, 0(%r13,%rax)
	addq	$32, %rax
	cmpq	%rdx, %rax
	jne	.L16
	movq	%rcx, %rdx
	andq	$-8, %rdx
	testb	$7, %cl
	je	.L17
.L15:
	movq	%rcx, %rax
	subq	%rdx, %rax
	leaq	-1(%rax), %rsi
	cmpq	$2, %rsi
	jbe	.L18
	vmovdqu	(%r12,%rdx,4), %xmm1
	vmovdqu	(%rbx,%rdx,4), %xmm2
	movq	%rax, %rsi
	andq	$-4, %rsi
	vpslld	$1, %xmm1, %xmm0
	vpaddd	%xmm1, %xmm0, %xmm0
	vpslld	$2, %xmm2, %xmm1
	vpaddd	%xmm2, %xmm1, %xmm1
	vpaddd	%xmm1, %xmm0, %xmm0
	vmovdqu	%xmm0, 0(%r13,%rdx,4)
	addq	%rsi, %rdx
	andl	$3, %eax
	je	.L48
.L18:
	imull	$3, (%r12,%rdx,4), %eax
	leaq	0(,%rdx,4), %rsi
	imull	$5, (%rbx,%rdx,4), %edi
	addl	%edi, %eax
	movl	%eax, 0(%r13,%rdx,4)
	leaq	1(%rdx), %rax
	cmpq	%rcx, %rax
	jnb	.L20
	imull	$5, 4(%rbx,%rsi), %eax
	imull	$3, 4(%r12,%rsi), %edi
	addl	%edi, %eax
	movl	%eax, 4(%r13,%rsi)
	leaq	2(%rdx), %rax
	cmpq	%rcx, %rax
	jnb	.L20
	imull	$3, 8(%r12,%rsi), %eax
	imull	$5, 8(%rbx,%rsi), %edx
	addl	%edx, %eax
	movl	%eax, 8(%r13,%rsi)
.L20:
	cmpq	$6, %r9
	jbe	.L30
.L17:
	movq	%rcx, %rdx
	movq	%r13, %rax
	vpxor	%xmm2, %xmm2, %xmm2
	shrq	$3, %rdx
	salq	$5, %rdx
	addq	%r13, %rdx
	.p2align 4,,10
	.p2align 3
.L22:
	vmovdqu	(%rax), %ymm0
	addq	$32, %rax
	vextracti128	$0x1, %ymm0, %xmm1
	vpmovzxdq	%xmm0, %ymm0
	vpmovzxdq	%xmm1, %ymm1
	vpaddq	%ymm0, %ymm1, %ymm0
	vpaddq	%ymm0, %ymm2, %ymm2
	cmpq	%rdx, %rax
	jne	.L22
	vextracti128	$0x1, %ymm2, %xmm0
	movq	%rcx, %rax
	vpaddq	%xmm2, %xmm0, %xmm2
	andq	$-8, %rax
	vpsrldq	$8, %xmm2, %xmm0
	vpaddq	%xmm0, %xmm2, %xmm0
	vmovq	%xmm0, %r14
	testb	$7, %cl
	je	.L46
.L21:
	movq	%rcx, %rdx
	subq	%rax, %rdx
	leaq	-1(%rdx), %rsi
	cmpq	$2, %rsi
	jbe	.L25
.L19:
	vmovdqu	0(%r13,%rax,4), %xmm1
	movq	%rdx, %rsi
	andq	$-4, %rsi
	vpmovzxdq	%xmm1, %xmm0
	vpsrldq	$8, %xmm1, %xmm1
	addq	%rsi, %rax
	andl	$3, %edx
	vpmovzxdq	%xmm1, %xmm1
	vpaddq	%xmm1, %xmm0, %xmm0
	vpaddq	%xmm2, %xmm0, %xmm0
	vpsrldq	$8, %xmm0, %xmm1
	vpaddq	%xmm1, %xmm0, %xmm0
	vmovq	%xmm0, %r14
	je	.L46
.L25:
	movl	0(%r13,%rax,4), %esi
	leaq	0(,%rax,4), %rdx
	addq	%rsi, %r14
	leaq	1(%rax), %rsi
	cmpq	%rcx, %rsi
	jnb	.L46
	movl	4(%r13,%rdx), %esi
	addq	$2, %rax
	addq	%rsi, %r14
	cmpq	%rcx, %rax
	jnb	.L46
	movl	8(%r13,%rdx), %eax
	addq	%rax, %r14
	vzeroupper
.L13:
	movq	%r12, %rdi
	call	free@PLT
	movq	%rbx, %rdi
	call	free@PLT
	movq	%r13, %rdi
	call	free@PLT
.L10:
	leaq	-32(%rbp), %rsp
	movq	%r14, %rax
	popq	%rbx
	popq	%r12
	popq	%r13
	popq	%r14
	popq	%rbp
	.cfi_remember_state
	.cfi_def_cfa 7, 8
	ret
.L46:
	.cfi_restore_state
	vzeroupper
	jmp	.L13
.L48:
	cmpq	$6, %r9
	ja	.L17
	vpxor	%xmm2, %xmm2, %xmm2
	movl	$4, %edx
	jmp	.L19
.L28:
	xorl	%edx, %edx
	jmp	.L15
.L30:
	vpxor	%xmm2, %xmm2, %xmm2
	xorl	%eax, %eax
	xorl	%r14d, %r14d
	jmp	.L21
.L11:
	movq	%r12, %rdi
	orq	$-1, %r14
	call	free@PLT
	movq	%rbx, %rdi
	call	free@PLT
	movq	%r13, %rdi
	call	free@PLT
	jmp	.L10
	.cfi_endproc
.LFE30:
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
.LFB31:
	.cfi_startproc
	endbr64
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	pushq	%rbx
	.cfi_def_cfa_offset 24
	.cfi_offset 3, -24
	movq	%rsi, %rbx
	subq	$24, %rsp
	.cfi_def_cfa_offset 48
	movq	%fs:40, %rax
	movq	%rax, 8(%rsp)
	xorl	%eax, %eax
	movq	$0, (%rsp)
	cmpl	$3, %edi
	jne	.L61
	movq	16(%rbx), %rdi
	movq	%rsp, %rsi
	movl	$10, %edx
	call	strtoull@PLT
	movq	%rax, %rbp
	movq	(%rsp), %rax
	cmpq	%rax, 16(%rbx)
	je	.L52
	cmpb	$0, (%rax)
	jne	.L52
	testq	%rbp, %rbp
	je	.L52
	movq	8(%rbx), %rbx
	leaq	.LC2(%rip), %rsi
	movq	%rbx, %rdi
	call	strcmp@PLT
	testl	%eax, %eax
	je	.L62
	leaq	.LC3(%rip), %rsi
	movq	%rbx, %rdi
	call	strcmp@PLT
	testl	%eax, %eax
	jne	.L58
	movq	%rbp, %rdi
	call	vector_kernel
	movq	%rax, %rdx
	cmpq	$-1, %rax
	je	.L63
.L57:
	leaq	.LC6(%rip), %rsi
	movl	$2, %edi
	xorl	%eax, %eax
	call	__printf_chk@PLT
	xorl	%eax, %eax
	jmp	.L49
.L52:
	movq	stderr(%rip), %rdi
	leaq	.LC1(%rip), %rdx
	movl	$2, %esi
	xorl	%eax, %eax
	call	__fprintf_chk@PLT
.L51:
	movl	$2, %eax
.L49:
	movq	8(%rsp), %rdx
	subq	%fs:40, %rdx
	jne	.L64
	addq	$24, %rsp
	.cfi_remember_state
	.cfi_def_cfa_offset 24
	popq	%rbx
	.cfi_def_cfa_offset 16
	popq	%rbp
	.cfi_def_cfa_offset 8
	ret
.L61:
	.cfi_restore_state
	movq	(%rsi), %rcx
	movq	stderr(%rip), %rdi
	leaq	.LC0(%rip), %rdx
	movl	$2, %esi
	call	__fprintf_chk@PLT
	jmp	.L51
.L62:
	movq	%rbp, %rdi
	call	branch_kernel
	movq	%rax, %rdx
	jmp	.L57
.L58:
	movq	stderr(%rip), %rdi
	movq	%rbx, %rcx
	leaq	.LC5(%rip), %rdx
	movl	$2, %esi
	xorl	%eax, %eax
	call	__fprintf_chk@PLT
	jmp	.L51
.L63:
	movq	stderr(%rip), %rdi
	leaq	.LC4(%rip), %rdx
	movl	$2, %esi
	xorl	%eax, %eax
	call	__fprintf_chk@PLT
	movl	$3, %eax
	jmp	.L49
.L64:
	call	__stack_chk_fail@PLT
	.cfi_endproc
.LFE31:
	.size	main, .-main
	.ident	"GCC: (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0"
	.section	.note.GNU-stack,"",@progbits
	.section	.note.gnu.property,"a"
	.align 8
	.long	1f - 0f
	.long	4f - 1f
	.long	5
0:
	.string	"GNU"
1:
	.align 8
	.long	0xc0000002
	.long	3f - 2f
2:
	.long	0x3
3:
	.align 8
4:
