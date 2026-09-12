	.file	"bench.c"
	.text
	.type	branch_kernel, @function
branch_kernel:
.LFB23:
	.cfi_startproc
	xorl	%esi, %esi
	movl	$-2128831035, %ecx
	xorl	%r8d, %r8d
	movl	$89, %r9d
	movl	$97, %r10d
.L2:
	cmpq	%rdi, %rsi
	je	.L7
	leal	-1640531527(%rsi), %eax
	movl	$0, %edx
	xorl	%eax, %ecx
	imull	$16777619, %ecx, %ecx
	movl	%ecx, %eax
	andl	$7, %eax
	cmpl	$2, %eax
	movl	%ecx, %eax
	ja	.L3
	divl	%r10d
	movl	%edx, %edx
	addq	%rdx, %r8
	jmp	.L4
.L3:
	divl	%r9d
	movl	%edx, %edx
	addq	%rsi, %rdx
	xorq	%rdx, %r8
.L4:
	incq	%rsi
	jmp	.L2
.L7:
	movq	%r8, %rax
	ret
	.cfi_endproc
.LFE23:
	.size	branch_kernel, .-branch_kernel
	.type	vector_kernel, @function
vector_kernel:
.LFB24:
	.cfi_startproc
	pushq	%r14
	.cfi_def_cfa_offset 16
	.cfi_offset 14, -16
	pushq	%r13
	.cfi_def_cfa_offset 24
	.cfi_offset 13, -24
	pushq	%r12
	.cfi_def_cfa_offset 32
	.cfi_offset 12, -32
	pushq	%rbp
	.cfi_def_cfa_offset 40
	.cfi_offset 6, -40
	leaq	0(,%rdi,4), %rbp
	pushq	%rbx
	.cfi_def_cfa_offset 48
	.cfi_offset 3, -48
	movq	%rdi, %rbx
	movq	%rbp, %rdi
	call	malloc@PLT
	movq	%rbp, %rdi
	movq	%rax, %r13
	call	malloc@PLT
	movq	%rbp, %rdi
	movq	%rax, %r12
	call	malloc@PLT
	testq	%r13, %r13
	sete	%dl
	testq	%r12, %r12
	movq	%rax, %rbp
	sete	%al
	orb	%al, %dl
	jne	.L18
	xorl	%ecx, %ecx
	testq	%rbp, %rbp
	je	.L18
	movl	$1009, %esi
	movl	$1013, %edi
	jmp	.L9
.L18:
	movq	%r13, %rdi
	orq	$-1, %r14
	call	free@PLT
	movq	%r12, %rdi
	call	free@PLT
	movq	%rbp, %rdi
	call	free@PLT
	jmp	.L8
.L9:
	cmpq	%rbx, %rcx
	je	.L21
	movq	%rcx, %rax
	xorl	%edx, %edx
	divq	%rsi
	imulq	$7, %rcx, %rax
	movl	%edx, 0(%r13,%rcx,4)
	xorl	%edx, %edx
	divq	%rdi
	movl	%edx, (%r12,%rcx,4)
	incq	%rcx
	jmp	.L9
.L21:
	xorl	%eax, %eax
.L13:
	cmpq	%rbx, %rax
	je	.L22
	imull	$3, 0(%r13,%rax,4), %edx
	imull	$5, (%r12,%rax,4), %ecx
	addl	%ecx, %edx
	movl	%edx, 0(%rbp,%rax,4)
	incq	%rax
	jmp	.L13
.L22:
	xorl	%eax, %eax
	xorl	%r14d, %r14d
.L15:
	cmpq	%rbx, %rax
	je	.L23
	movl	0(%rbp,%rax,4), %edx
	incq	%rax
	addq	%rdx, %r14
	jmp	.L15
.L23:
	movq	%r13, %rdi
	call	free@PLT
	movq	%r12, %rdi
	call	free@PLT
	movq	%rbp, %rdi
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
.LFE24:
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
.LFB25:
	.cfi_startproc
	endbr64
	pushq	%r13
	.cfi_def_cfa_offset 16
	.cfi_offset 13, -16
	pushq	%r12
	.cfi_def_cfa_offset 24
	.cfi_offset 12, -24
	pushq	%rbp
	.cfi_def_cfa_offset 32
	.cfi_offset 6, -32
	pushq	%rbx
	.cfi_def_cfa_offset 40
	.cfi_offset 3, -40
	movq	%rsi, %rbx
	subq	$24, %rsp
	.cfi_def_cfa_offset 64
	movq	%fs:40, %rax
	movq	%rax, 8(%rsp)
	xorl	%eax, %eax
	movq	$0, (%rsp)
	cmpl	$3, %edi
	je	.L25
	movq	(%rsi), %rcx
	movq	stderr(%rip), %rdi
	leaq	.LC0(%rip), %rdx
	movl	$1, %esi
	jmp	.L36
.L25:
	movl	%edi, %r12d
	movq	16(%rbx), %rdi
	movq	%rsp, %rsi
	movl	$10, %edx
	call	strtoull@PLT
	movq	%rax, %rbp
	movq	(%rsp), %rax
	cmpq	%rax, 16(%rbx)
	je	.L27
	cmpb	$0, (%rax)
	jne	.L27
	testq	%rbp, %rbp
	jne	.L28
.L27:
	movq	stderr(%rip), %rdi
	leaq	.LC1(%rip), %rdx
	movl	$1, %esi
	xorl	%eax, %eax
	call	__fprintf_chk@PLT
.L35:
	movl	$2, %r12d
	jmp	.L26
.L28:
	movq	8(%rbx), %r13
	leaq	.LC2(%rip), %rsi
	movq	%r13, %rdi
	call	strcmp@PLT
	testl	%eax, %eax
	jne	.L30
	movq	%rbp, %rdi
	call	branch_kernel
	movq	%rax, %rdx
	jmp	.L31
.L30:
	leaq	.LC3(%rip), %rsi
	movq	%r13, %rdi
	call	strcmp@PLT
	testl	%eax, %eax
	jne	.L32
	movq	%rbp, %rdi
	call	vector_kernel
	movq	%rax, %rdx
	cmpq	$-1, %rax
	jne	.L31
	movq	stderr(%rip), %rdi
	leaq	.LC4(%rip), %rdx
	movl	$1, %esi
	xorl	%eax, %eax
	call	__fprintf_chk@PLT
	jmp	.L26
.L32:
	movq	stderr(%rip), %rdi
	movq	%r13, %rcx
	movl	$1, %esi
	xorl	%eax, %eax
	leaq	.LC5(%rip), %rdx
.L36:
	call	__fprintf_chk@PLT
	jmp	.L35
.L31:
	leaq	.LC6(%rip), %rsi
	movl	$1, %edi
	xorl	%eax, %eax
	xorl	%r12d, %r12d
	call	__printf_chk@PLT
.L26:
	movq	8(%rsp), %rax
	xorq	%fs:40, %rax
	je	.L33
	call	__stack_chk_fail@PLT
.L33:
	addq	$24, %rsp
	.cfi_def_cfa_offset 40
	movl	%r12d, %eax
	popq	%rbx
	.cfi_def_cfa_offset 32
	popq	%rbp
	.cfi_def_cfa_offset 24
	popq	%r12
	.cfi_def_cfa_offset 16
	popq	%r13
	.cfi_def_cfa_offset 8
	ret
	.cfi_endproc
.LFE25:
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
