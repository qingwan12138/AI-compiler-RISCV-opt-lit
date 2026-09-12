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
	pushq	%r14
	.cfi_def_cfa_offset 16
	.cfi_offset 14, -16
	movq	%rdi, %r14
	pushq	%r13
	.cfi_def_cfa_offset 24
	.cfi_offset 13, -24
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
	movq	%rax, %r13
	sete	%al
	testq	%rbp, %rbp
	sete	%dl
	orb	%dl, %al
	jne	.L11
	testq	%r13, %r13
	je	.L11
	movabsq	$-9086255505087856445, %r8
	xorl	%esi, %esi
	xorl	%ecx, %ecx
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
	movl	%eax, 0(%rbp,%rcx,4)
	leaq	1(%rcx), %rcx
	cmpq	%rcx, %r14
	jne	.L12
	xorl	%eax, %eax
	.p2align 4,,10
	.p2align 3
.L15:
	movl	(%r12,%rax,4), %edx
	movl	0(%rbp,%rax,4), %ecx
	leal	(%rdx,%rdx,2), %edx
	leal	(%rcx,%rcx,4), %ecx
	addl	%ecx, %edx
	movl	%edx, 0(%r13,%rax,4)
	movq	%rax, %rdx
	addq	$1, %rax
	cmpq	%rdx, %r9
	jne	.L15
	movq	%r13, %rax
	addq	%r13, %rbx
	xorl	%r14d, %r14d
	.p2align 4,,10
	.p2align 3
.L16:
	movl	(%rax), %edx
	addq	$4, %rax
	addq	%rdx, %r14
	cmpq	%rax, %rbx
	jne	.L16
.L13:
	movq	%r12, %rdi
	call	free@PLT
	movq	%rbp, %rdi
	call	free@PLT
	movq	%r13, %rdi
	call	free@PLT
.L10:
	popq	%rbx
	.cfi_remember_state
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
.L11:
	.cfi_restore_state
	movq	%r12, %rdi
	orq	$-1, %r14
	call	free@PLT
	movq	%rbp, %rdi
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
	jne	.L35
	movq	16(%rbx), %rdi
	movq	%rsp, %rsi
	movl	$10, %edx
	call	strtoull@PLT
	movq	%rax, %rbp
	movq	(%rsp), %rax
	cmpq	%rax, 16(%rbx)
	je	.L26
	cmpb	$0, (%rax)
	jne	.L26
	testq	%rbp, %rbp
	je	.L26
	movq	8(%rbx), %rbx
	leaq	.LC2(%rip), %rsi
	movq	%rbx, %rdi
	call	strcmp@PLT
	testl	%eax, %eax
	je	.L36
	leaq	.LC3(%rip), %rsi
	movq	%rbx, %rdi
	call	strcmp@PLT
	testl	%eax, %eax
	jne	.L32
	movq	%rbp, %rdi
	call	vector_kernel
	movq	%rax, %rdx
	cmpq	$-1, %rax
	je	.L37
.L31:
	leaq	.LC6(%rip), %rsi
	movl	$2, %edi
	xorl	%eax, %eax
	call	__printf_chk@PLT
	xorl	%eax, %eax
	jmp	.L23
.L26:
	movq	stderr(%rip), %rdi
	leaq	.LC1(%rip), %rdx
	movl	$2, %esi
	xorl	%eax, %eax
	call	__fprintf_chk@PLT
.L25:
	movl	$2, %eax
.L23:
	movq	8(%rsp), %rdx
	subq	%fs:40, %rdx
	jne	.L38
	addq	$24, %rsp
	.cfi_remember_state
	.cfi_def_cfa_offset 24
	popq	%rbx
	.cfi_def_cfa_offset 16
	popq	%rbp
	.cfi_def_cfa_offset 8
	ret
.L35:
	.cfi_restore_state
	movq	(%rsi), %rcx
	movq	stderr(%rip), %rdi
	leaq	.LC0(%rip), %rdx
	movl	$2, %esi
	call	__fprintf_chk@PLT
	jmp	.L25
.L36:
	movq	%rbp, %rdi
	call	branch_kernel
	movq	%rax, %rdx
	jmp	.L31
.L32:
	movq	stderr(%rip), %rdi
	movq	%rbx, %rcx
	movl	$2, %esi
	xorl	%eax, %eax
	leaq	.LC5(%rip), %rdx
	call	__fprintf_chk@PLT
	jmp	.L25
.L37:
	movq	stderr(%rip), %rdi
	leaq	.LC4(%rip), %rdx
	movl	$2, %esi
	xorl	%eax, %eax
	call	__fprintf_chk@PLT
	movl	$3, %eax
	jmp	.L23
.L38:
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
