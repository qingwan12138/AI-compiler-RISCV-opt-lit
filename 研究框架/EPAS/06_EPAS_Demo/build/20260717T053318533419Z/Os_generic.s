	.file	"bench.c"
	.text
	.type	branch_kernel, @function
branch_kernel:
.LFB22:
	.cfi_startproc
	movq	%rdi, %r8
	movl	$-2128831035, %ecx
	xorl	%edi, %edi
	xorl	%esi, %esi
	movl	$89, %r9d
	movl	$97, %r10d
.L2:
	cmpq	%r8, %rdi
	je	.L7
	leal	-1640531527(%rdi), %eax
	movl	$0, %edx
	xorl	%ecx, %eax
	imull	$16777619, %eax, %ecx
	movl	%ecx, %eax
	andl	$7, %eax
	cmpl	$2, %eax
	movl	%ecx, %eax
	ja	.L3
	divl	%r10d
	movl	%edx, %edx
	addq	%rdx, %rsi
	jmp	.L4
.L3:
	divl	%r9d
	movl	%edx, %edx
	addq	%rdi, %rdx
	xorq	%rdx, %rsi
.L4:
	incq	%rdi
	jmp	.L2
.L7:
	movq	%rsi, %rax
	ret
	.cfi_endproc
.LFE22:
	.size	branch_kernel, .-branch_kernel
	.type	vector_kernel, @function
vector_kernel:
.LFB23:
	.cfi_startproc
	pushq	%r14
	.cfi_def_cfa_offset 16
	.cfi_offset 14, -16
	pushq	%r13
	.cfi_def_cfa_offset 24
	.cfi_offset 13, -24
	movq	%rdi, %r13
	pushq	%r12
	.cfi_def_cfa_offset 32
	.cfi_offset 12, -32
	pushq	%rbp
	.cfi_def_cfa_offset 40
	.cfi_offset 6, -40
	pushq	%rbx
	.cfi_def_cfa_offset 48
	.cfi_offset 3, -48
	leaq	0(,%rdi,4), %rbx
	movq	%rbx, %rdi
	call	malloc@PLT
	movq	%rbx, %rdi
	movq	%rax, %r12
	call	malloc@PLT
	movq	%rbx, %rdi
	movq	%rax, %rbp
	call	malloc@PLT
	testq	%r12, %r12
	movq	%rax, %rbx
	sete	%al
	testq	%rbp, %rbp
	sete	%dl
	orb	%dl, %al
	jne	.L18
	xorl	%ecx, %ecx
	testq	%rbx, %rbx
	je	.L18
	movl	$1009, %esi
	movl	$1013, %edi
	jmp	.L9
.L18:
	movq	%r12, %rdi
	orq	$-1, %r14
	call	free@PLT
	movq	%rbp, %rdi
	call	free@PLT
	movq	%rbx, %rdi
	call	free@PLT
	jmp	.L8
.L9:
	cmpq	%r13, %rcx
	je	.L21
	movq	%rcx, %rax
	xorl	%edx, %edx
	divq	%rsi
	imulq	$7, %rcx, %rax
	movl	%edx, (%r12,%rcx,4)
	xorl	%edx, %edx
	divq	%rdi
	movl	%edx, 0(%rbp,%rcx,4)
	incq	%rcx
	jmp	.L9
.L21:
	xorl	%eax, %eax
.L13:
	cmpq	%r13, %rax
	je	.L22
	imull	$3, (%r12,%rax,4), %edx
	imull	$5, 0(%rbp,%rax,4), %ecx
	addl	%ecx, %edx
	movl	%edx, (%rbx,%rax,4)
	incq	%rax
	jmp	.L13
.L22:
	xorl	%eax, %eax
	xorl	%r14d, %r14d
.L15:
	cmpq	%r13, %rax
	je	.L23
	movl	(%rbx,%rax,4), %edx
	incq	%rax
	addq	%rdx, %r14
	jmp	.L15
.L23:
	movq	%r12, %rdi
	call	free@PLT
	movq	%rbp, %rdi
	call	free@PLT
	movq	%rbx, %rdi
	call	free@PLT
.L8:
	popq	%rbx
	.cfi_def_cfa_offset 40
	movq	%r14, %rax
	popq	%rbp
	.cfi_def_cfa_offset 32
	popq	%r12
	.cfi_def_cfa_offset 24
	popq	%r13
	.cfi_def_cfa_offset 16
	popq	%r14
	.cfi_def_cfa_offset 8
	ret
	.cfi_endproc
.LFE23:
	.size	vector_kernel, .-vector_kernel
	.section	.rodata.str1.1,"aMS",@progbits,1
.LC0:
	.string	"usage: %s <branch|vector> <positive-size>\n"
.LC1:
	.string	"size must be a positive integer within size_t range\n"
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
	.globl	main
	.type	main, @function
main:
.LFB24:
	.cfi_startproc
	endbr64
	pushq	%r12
	.cfi_def_cfa_offset 16
	.cfi_offset 12, -16
	xorl	%r9d, %r9d
	pushq	%rbp
	.cfi_def_cfa_offset 24
	.cfi_offset 6, -24
	movq	%rsi, %rbp
	pushq	%rbx
	.cfi_def_cfa_offset 32
	.cfi_offset 3, -32
	subq	$16, %rsp
	.cfi_def_cfa_offset 48
	movq	%fs:40, %rax
	movq	%rax, 8(%rsp)
	xorl	%eax, %eax
	movq	%r9, (%rsp)
	cmpl	$3, %edi
	je	.L25
	movq	(%rsi), %rcx
	movq	stderr(%rip), %rdi
	leaq	.LC0(%rip), %rdx
	movl	$2, %esi
	jmp	.L36
.L25:
	movl	%edi, %ebx
	movq	16(%rbp), %rdi
	movq	%rsp, %rsi
	movl	$10, %edx
	call	strtoull@PLT
	movq	%rax, %r12
	movq	(%rsp), %rax
	cmpq	%rax, 16(%rbp)
	je	.L27
	cmpb	$0, (%rax)
	jne	.L27
	testq	%r12, %r12
	jne	.L28
.L27:
	movq	stderr(%rip), %rdi
	leaq	.LC1(%rip), %rdx
	movl	$2, %esi
	xorl	%eax, %eax
	call	__fprintf_chk@PLT
.L26:
	movl	$2, %ebx
	jmp	.L30
.L28:
	movq	8(%rbp), %rbp
	leaq	.LC2(%rip), %rsi
	movq	%rbp, %rdi
	call	strcmp@PLT
	testl	%eax, %eax
	jne	.L31
	movq	%r12, %rdi
	call	branch_kernel
	jmp	.L32
.L31:
	leaq	.LC3(%rip), %rsi
	movq	%rbp, %rdi
	call	strcmp@PLT
	testl	%eax, %eax
	jne	.L33
	movq	%r12, %rdi
	call	vector_kernel
	cmpq	$-1, %rax
	jne	.L32
	movq	stderr(%rip), %rdi
	leaq	.LC4(%rip), %rdx
	movl	$2, %esi
	xorl	%eax, %eax
	call	__fprintf_chk@PLT
	jmp	.L30
.L33:
	movq	stderr(%rip), %rdi
	movq	%rbp, %rcx
	movl	$2, %esi
	xorl	%eax, %eax
	leaq	.LC5(%rip), %rdx
.L36:
	call	__fprintf_chk@PLT
	jmp	.L26
.L32:
	movq	%rax, %rdx
	leaq	.LC6(%rip), %rsi
	movl	$2, %edi
	xorl	%eax, %eax
	call	__printf_chk@PLT
	xorl	%ebx, %ebx
.L30:
	movq	8(%rsp), %rax
	subq	%fs:40, %rax
	je	.L34
	call	__stack_chk_fail@PLT
.L34:
	addq	$16, %rsp
	.cfi_def_cfa_offset 32
	movl	%ebx, %eax
	popq	%rbx
	.cfi_def_cfa_offset 24
	popq	%rbp
	.cfi_def_cfa_offset 16
	popq	%r12
	.cfi_def_cfa_offset 8
	ret
	.cfi_endproc
.LFE24:
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
