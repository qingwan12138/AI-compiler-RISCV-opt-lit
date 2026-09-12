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
	addq	$1, %rcx
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
	addq	$1, %rcx
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
	pushq	%r13
	.cfi_def_cfa_offset 16
	.cfi_offset 13, -16
	movq	%rdi, %r13
	pushq	%r12
	.cfi_def_cfa_offset 24
	.cfi_offset 12, -24
	leaq	0(,%rdi,4), %r12
	pushq	%rbp
	.cfi_def_cfa_offset 32
	.cfi_offset 6, -32
	movq	%r12, %rdi
	pushq	%rbx
	.cfi_def_cfa_offset 40
	.cfi_offset 3, -40
	subq	$8, %rsp
	.cfi_def_cfa_offset 48
	call	malloc@PLT
	movq	%r12, %rdi
	movq	%rax, %rbp
	call	malloc@PLT
	movq	%r12, %rdi
	movq	%rax, %rbx
	call	malloc@PLT
	testq	%rbp, %rbp
	movq	%rax, %r12
	sete	%al
	testq	%rbx, %rbx
	sete	%dl
	orb	%dl, %al
	jne	.L11
	testq	%r12, %r12
	je	.L11
	movabsq	$-9086255505087856445, %r8
	xorl	%esi, %esi
	xorl	%ecx, %ecx
	movabsq	$-9123216960442729871, %rdi
	testq	%r13, %r13
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
	movl	%eax, 0(%rbp,%rcx,4)
	movq	%rsi, %rax
	mulq	%rdi
	movq	%rsi, %rax
	addq	$7, %rsi
	shrq	$9, %rdx
	imulq	$1013, %rdx, %rdx
	subq	%rdx, %rax
	movl	%eax, (%rbx,%rcx,4)
	addq	$1, %rcx
	cmpq	%rcx, %r13
	jne	.L12
	cmpq	$2, %r9
	jbe	.L25
	movq	%rcx, %rdx
	xorl	%eax, %eax
	shrq	$2, %rdx
	salq	$4, %rdx
	.p2align 4,,10
	.p2align 3
.L16:
	movdqu	0(%rbp,%rax), %xmm0
	movdqu	(%rbx,%rax), %xmm1
	movdqu	0(%rbp,%rax), %xmm4
	movdqu	(%rbx,%rax), %xmm5
	pslld	$1, %xmm0
	pslld	$2, %xmm1
	paddd	%xmm4, %xmm0
	paddd	%xmm5, %xmm1
	paddd	%xmm1, %xmm0
	movups	%xmm0, (%r12,%rax)
	addq	$16, %rax
	cmpq	%rdx, %rax
	jne	.L16
	testb	$3, %cl
	je	.L17
	movq	%rcx, %rax
	andq	$-4, %rax
.L15:
	movq	%rcx, %rdx
	subq	%rax, %rdx
	cmpq	$1, %rdx
	je	.L18
	movq	0(%rbp,%rax,4), %xmm1
	movq	(%rbx,%rax,4), %xmm2
	movdqa	%xmm1, %xmm0
	pslld	$1, %xmm0
	paddd	%xmm1, %xmm0
	movdqa	%xmm2, %xmm1
	pslld	$2, %xmm1
	paddd	%xmm2, %xmm1
	paddd	%xmm1, %xmm0
	movq	%xmm0, (%r12,%rax,4)
	testb	$1, %dl
	je	.L19
	andq	$-2, %rdx
	addq	%rdx, %rax
.L18:
	movl	0(%rbp,%rax,4), %edx
	movl	(%rbx,%rax,4), %esi
	leal	(%rdx,%rdx,2), %edx
	leal	(%rsi,%rsi,4), %esi
	addl	%esi, %edx
	movl	%edx, (%r12,%rax,4)
.L19:
	cmpq	$2, %r9
	jbe	.L26
.L17:
	movq	%rcx, %rdx
	pxor	%xmm1, %xmm1
	pxor	%xmm2, %xmm2
	movq	%r12, %rax
	shrq	$2, %rdx
	salq	$4, %rdx
	addq	%r12, %rdx
	.p2align 4,,10
	.p2align 3
.L21:
	movdqu	(%rax), %xmm0
	addq	$16, %rax
	movdqa	%xmm0, %xmm3
	punpckldq	%xmm2, %xmm0
	punpckhdq	%xmm2, %xmm3
	paddq	%xmm3, %xmm0
	paddq	%xmm0, %xmm1
	cmpq	%rdx, %rax
	jne	.L21
	movdqa	%xmm1, %xmm0
	psrldq	$8, %xmm0
	paddq	%xmm0, %xmm1
	movq	%xmm1, %r13
	testb	$3, %cl
	je	.L13
	movq	%rcx, %rax
	andq	$-4, %rax
.L20:
	movl	(%r12,%rax,4), %esi
	leaq	0(,%rax,4), %rdx
	addq	%rsi, %r13
	leaq	1(%rax), %rsi
	cmpq	%rcx, %rsi
	jnb	.L13
	movl	4(%r12,%rdx), %esi
	addq	$2, %rax
	addq	%rsi, %r13
	cmpq	%rcx, %rax
	jnb	.L13
	movl	8(%r12,%rdx), %eax
	addq	%rax, %r13
.L13:
	movq	%rbp, %rdi
	call	free@PLT
	movq	%rbx, %rdi
	call	free@PLT
	movq	%r12, %rdi
	call	free@PLT
.L10:
	addq	$8, %rsp
	.cfi_remember_state
	.cfi_def_cfa_offset 40
	movq	%r13, %rax
	popq	%rbx
	.cfi_def_cfa_offset 32
	popq	%rbp
	.cfi_def_cfa_offset 24
	popq	%r12
	.cfi_def_cfa_offset 16
	popq	%r13
	.cfi_def_cfa_offset 8
	ret
.L25:
	.cfi_restore_state
	xorl	%eax, %eax
	jmp	.L15
.L26:
	xorl	%eax, %eax
	xorl	%r13d, %r13d
	jmp	.L20
.L11:
	movq	%rbp, %rdi
	orq	$-1, %r13
	call	free@PLT
	movq	%rbx, %rdi
	call	free@PLT
	movq	%r12, %rdi
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
	jne	.L56
	movq	16(%rbx), %rdi
	movq	%rsp, %rsi
	movl	$10, %edx
	call	strtoull@PLT
	movq	%rax, %rbp
	movq	(%rsp), %rax
	cmpq	%rax, 16(%rbx)
	je	.L47
	cmpb	$0, (%rax)
	jne	.L47
	testq	%rbp, %rbp
	je	.L47
	movq	8(%rbx), %rbx
	leaq	.LC2(%rip), %rsi
	movq	%rbx, %rdi
	call	strcmp@PLT
	testl	%eax, %eax
	je	.L57
	leaq	.LC3(%rip), %rsi
	movq	%rbx, %rdi
	call	strcmp@PLT
	testl	%eax, %eax
	jne	.L53
	movq	%rbp, %rdi
	call	vector_kernel
	movq	%rax, %rdx
	cmpq	$-1, %rax
	je	.L58
.L52:
	leaq	.LC6(%rip), %rsi
	movl	$2, %edi
	xorl	%eax, %eax
	call	__printf_chk@PLT
	xorl	%eax, %eax
	jmp	.L44
.L47:
	movq	stderr(%rip), %rdi
	leaq	.LC1(%rip), %rdx
	movl	$2, %esi
	xorl	%eax, %eax
	call	__fprintf_chk@PLT
.L46:
	movl	$2, %eax
.L44:
	movq	8(%rsp), %rdx
	subq	%fs:40, %rdx
	jne	.L59
	addq	$24, %rsp
	.cfi_remember_state
	.cfi_def_cfa_offset 24
	popq	%rbx
	.cfi_def_cfa_offset 16
	popq	%rbp
	.cfi_def_cfa_offset 8
	ret
.L56:
	.cfi_restore_state
	movq	(%rsi), %rcx
	movq	stderr(%rip), %rdi
	leaq	.LC0(%rip), %rdx
	movl	$2, %esi
	call	__fprintf_chk@PLT
	jmp	.L46
.L57:
	movq	%rbp, %rdi
	call	branch_kernel
	movq	%rax, %rdx
	jmp	.L52
.L53:
	movq	stderr(%rip), %rdi
	movq	%rbx, %rcx
	movl	$2, %esi
	xorl	%eax, %eax
	leaq	.LC5(%rip), %rdx
	call	__fprintf_chk@PLT
	jmp	.L46
.L58:
	movq	stderr(%rip), %rdi
	leaq	.LC4(%rip), %rdx
	movl	$2, %esi
	xorl	%eax, %eax
	call	__fprintf_chk@PLT
	movl	$3, %eax
	jmp	.L44
.L59:
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
