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
	addq	$1, %rcx
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
	addq	$1, %rcx
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
	pushq	%r14
	.cfi_def_cfa_offset 16
	.cfi_offset 14, -16
	pushq	%r13
	.cfi_def_cfa_offset 24
	.cfi_offset 13, -24
	leaq	0(,%rdi,4), %r13
	pushq	%r12
	.cfi_def_cfa_offset 32
	.cfi_offset 12, -32
	pushq	%rbp
	.cfi_def_cfa_offset 40
	.cfi_offset 6, -40
	pushq	%rbx
	.cfi_def_cfa_offset 48
	.cfi_offset 3, -48
	movq	%rdi, %rbx
	movq	%r13, %rdi
	call	malloc@PLT
	movq	%r13, %rdi
	movq	%rax, %rbp
	call	malloc@PLT
	movq	%r13, %rdi
	movq	%rax, %r12
	call	malloc@PLT
	testq	%rbp, %rbp
	sete	%dl
	testq	%r12, %r12
	movq	%rax, %r13
	sete	%al
	orb	%al, %dl
	jne	.L11
	testq	%r13, %r13
	je	.L11
	xorl	%esi, %esi
	xorl	%ecx, %ecx
	xorl	%r14d, %r14d
	movabsq	$-9086255505087856445, %r8
	movabsq	$-9123216960442729871, %rdi
	testq	%rbx, %rbx
	je	.L13
	.p2align 4,,10
	.p2align 3
.L12:
	movq	%rcx, %rax
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
	movq	%rcx, %rdx
	movl	%eax, (%r12,%rcx,4)
	addq	$1, %rcx
	cmpq	%rcx, %rbx
	jne	.L12
	cmpq	$2, %rdx
	jbe	.L27
	movq	%rcx, %rsi
	xorl	%eax, %eax
	shrq	$2, %rsi
	salq	$4, %rsi
	.p2align 4,,10
	.p2align 3
.L16:
	movdqu	0(%rbp,%rax), %xmm0
	movdqu	(%r12,%rax), %xmm1
	movdqu	0(%rbp,%rax), %xmm4
	movdqu	(%r12,%rax), %xmm5
	pslld	$1, %xmm0
	pslld	$2, %xmm1
	paddd	%xmm4, %xmm0
	paddd	%xmm5, %xmm1
	paddd	%xmm1, %xmm0
	movups	%xmm0, 0(%r13,%rax)
	addq	$16, %rax
	cmpq	%rsi, %rax
	jne	.L16
	movq	%rcx, %rax
	andq	$-4, %rax
	testb	$3, %cl
	je	.L17
.L15:
	movl	0(%rbp,%rax,4), %esi
	movl	(%r12,%rax,4), %edi
	leal	(%rsi,%rsi,2), %esi
	leal	(%rdi,%rdi,4), %edi
	addl	%edi, %esi
	movl	%esi, 0(%r13,%rax,4)
	leaq	1(%rax), %rsi
	cmpq	%rsi, %rcx
	jbe	.L18
	imull	$3, 0(%rbp,%rsi,4), %edi
	addq	$2, %rax
	imull	$5, (%r12,%rsi,4), %r8d
	addl	%r8d, %edi
	movl	%edi, 0(%r13,%rsi,4)
	cmpq	%rax, %rcx
	jbe	.L19
	imull	$5, (%r12,%rax,4), %esi
	imull	$3, 0(%rbp,%rax,4), %edi
	addl	%edi, %esi
	movl	%esi, 0(%r13,%rax,4)
.L19:
	cmpq	$2, %rdx
	jbe	.L34
.L17:
	movq	%rcx, %rdx
	pxor	%xmm1, %xmm1
	pxor	%xmm2, %xmm2
	movq	%r13, %rax
	shrq	$2, %rdx
	salq	$4, %rdx
	addq	%r13, %rdx
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
	movq	%rcx, %rax
	psrldq	$8, %xmm0
	andq	$-4, %rax
	paddq	%xmm0, %xmm1
	movq	%xmm1, %r14
	testb	$3, %cl
	je	.L13
.L20:
	movl	0(%r13,%rax,4), %edx
	addq	$1, %rax
	addq	%rdx, %r14
	cmpq	%rcx, %rax
	jnb	.L13
.L24:
	movl	0(%r13,%rax,4), %edx
	addq	$1, %rax
	addq	%rdx, %r14
	cmpq	%rcx, %rax
	jnb	.L13
	movl	0(%r13,%rax,4), %eax
	addq	%rax, %r14
.L13:
	movq	%rbp, %rdi
	call	free@PLT
	movq	%r12, %rdi
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
.L27:
	.cfi_restore_state
	xorl	%eax, %eax
	jmp	.L15
.L34:
	movl	0(%r13), %r14d
	movl	$1, %eax
	jmp	.L24
.L18:
	cmpq	$2, %rdx
	ja	.L17
	xorl	%eax, %eax
	xorl	%r14d, %r14d
	jmp	.L20
.L11:
	movq	%rbp, %rdi
	orq	$-1, %r14
	call	free@PLT
	movq	%r12, %rdi
	call	free@PLT
	movq	%r13, %rdi
	call	free@PLT
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
	jne	.L46
	movq	16(%rbx), %rdi
	movq	%rsp, %rsi
	movl	$10, %edx
	call	strtoull@PLT
	movq	%rax, %rbp
	movq	(%rsp), %rax
	cmpq	%rax, 16(%rbx)
	je	.L38
	cmpb	$0, (%rax)
	jne	.L38
	testq	%rbp, %rbp
	je	.L38
	movq	8(%rbx), %r12
	leaq	.LC2(%rip), %rsi
	movq	%r12, %rdi
	call	strcmp@PLT
	testl	%eax, %eax
	je	.L47
	leaq	.LC3(%rip), %rsi
	movq	%r12, %rdi
	call	strcmp@PLT
	testl	%eax, %eax
	jne	.L43
	movq	%rbp, %rdi
	call	vector_kernel
	movq	%rax, %rdx
	cmpq	$-1, %rax
	je	.L48
.L42:
	leaq	.LC6(%rip), %rsi
	movl	$1, %edi
	xorl	%eax, %eax
	call	__printf_chk@PLT
	xorl	%eax, %eax
	jmp	.L35
.L38:
	movq	stderr(%rip), %rdi
	leaq	.LC1(%rip), %rdx
	movl	$1, %esi
	xorl	%eax, %eax
	call	__fprintf_chk@PLT
	movl	$2, %eax
.L35:
	movq	8(%rsp), %rcx
	xorq	%fs:40, %rcx
	jne	.L49
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
.L46:
	.cfi_restore_state
	movq	(%rsi), %rcx
	movq	stderr(%rip), %rdi
	leaq	.LC0(%rip), %rdx
	movl	$1, %esi
	call	__fprintf_chk@PLT
	movl	$2, %eax
	jmp	.L35
.L47:
	movq	%rbp, %rdi
	call	branch_kernel
	movq	%rax, %rdx
	jmp	.L42
.L43:
	movq	stderr(%rip), %rdi
	movq	%r12, %rcx
	movl	$1, %esi
	xorl	%eax, %eax
	leaq	.LC5(%rip), %rdx
	call	__fprintf_chk@PLT
	movl	$2, %eax
	jmp	.L35
.L48:
	movq	stderr(%rip), %rdi
	leaq	.LC4(%rip), %rdx
	movl	$1, %esi
	xorl	%eax, %eax
	call	__fprintf_chk@PLT
	movl	$3, %eax
	jmp	.L35
.L49:
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
