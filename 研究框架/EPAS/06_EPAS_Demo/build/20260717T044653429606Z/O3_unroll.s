	.file	"bench.c"
	.text
	.p2align 4
	.type	branch_kernel, @function
branch_kernel:
.LFB34:
	.cfi_startproc
	testq	%rdi, %rdi
	je	.L6
	movq	%rdi, %rsi
	xorl	%ecx, %ecx
	movl	$-2128831035, %edx
	xorl	%eax, %eax
	movl	$3088515809, %r8d
	andl	$3, %esi
	je	.L5
	cmpq	$1, %rsi
	je	.L23
	cmpq	$2, %rsi
	movl	$1, %r11d
	movl	$-1910984908, %r9d
	movl	$86, %r10d
	cmovne	%r11, %rcx
	cmovne	%r9d, %edx
	cmovne	%r10, %rax
	leal	-1640531527(%rcx), %esi
	xorl	%esi, %edx
	imull	$16777619, %edx, %edx
	movl	%edx, %r9d
	andl	$7, %r9d
	cmpl	$2, %r9d
	ja	.L11
	movl	%edx, %r9d
	movl	%edx, %esi
	imulq	$1372618415, %r9, %r9
	shrq	$32, %r9
	subl	%r9d, %esi
	shrl	%esi
	addl	%r9d, %esi
	shrl	$6, %esi
	imull	$97, %esi, %r11d
	movl	%edx, %esi
	subl	%r11d, %esi
	addq	%rsi, %rax
.L30:
	addq	$1, %rcx
.L23:
	leal	-1640531527(%rcx), %r10d
	xorl	%r10d, %edx
	imull	$16777619, %edx, %edx
	movl	%edx, %r11d
	movl	%edx, %esi
	andl	$7, %r11d
	cmpl	$2, %r11d
	jbe	.L31
	imulq	%r8, %rsi
	shrq	$38, %rsi
	imull	$89, %esi, %r9d
	movl	%edx, %esi
	subl	%r9d, %esi
	movq	%rsi, %r10
	addq	%rcx, %r10
	xorq	%r10, %rax
.L32:
	addq	$1, %rcx
	cmpq	%rcx, %rdi
	jne	.L5
	ret
	.p2align 4,,10
	.p2align 3
.L40:
	imulq	$1372618415, %rsi, %r9
	movl	%edx, %esi
	shrq	$32, %r9
	subl	%r9d, %esi
	shrl	%esi
	addl	%r9d, %esi
	shrl	$6, %esi
	imull	$97, %esi, %r9d
	movl	%edx, %esi
	subl	%r9d, %esi
	addq	%rsi, %rax
.L4:
	leaq	1(%rcx), %rsi
	subl	$1640531526, %ecx
	xorl	%ecx, %edx
	imull	$16777619, %edx, %edx
	movl	%edx, %ecx
	andl	$7, %ecx
	cmpl	$2, %ecx
	ja	.L17
	movl	%edx, %r10d
	movl	%edx, %ecx
	imulq	$1372618415, %r10, %r9
	shrq	$32, %r9
	subl	%r9d, %ecx
	shrl	%ecx
	addl	%r9d, %ecx
	shrl	$6, %ecx
	imull	$97, %ecx, %r10d
	movl	%edx, %ecx
	subl	%r10d, %ecx
	addq	%rcx, %rax
.L33:
	leal	-1640531526(%rsi), %r11d
	leaq	1(%rsi), %r10
	xorl	%r11d, %edx
	imull	$16777619, %edx, %edx
	movl	%edx, %r9d
	movl	%edx, %ecx
	andl	$7, %r9d
	cmpl	$2, %r9d
	jbe	.L34
	imulq	%r8, %rcx
	shrq	$38, %rcx
	imull	$89, %ecx, %r9d
	movl	%edx, %ecx
	subl	%r9d, %ecx
	movq	%rcx, %r11
	addq	%r10, %r11
	xorq	%r11, %rax
.L35:
	leal	-1640531525(%rsi), %r11d
	leaq	2(%rsi), %r10
	xorl	%r11d, %edx
	imull	$16777619, %edx, %edx
	movl	%edx, %r9d
	movl	%edx, %ecx
	andl	$7, %r9d
	cmpl	$2, %r9d
	jbe	.L36
	imulq	%r8, %rcx
	shrq	$38, %rcx
	imull	$89, %ecx, %r9d
	movl	%edx, %ecx
	subl	%r9d, %ecx
	movq	%rcx, %r11
	leaq	3(%rsi), %rcx
	addq	%r10, %r11
	xorq	%r11, %rax
	cmpq	%rcx, %rdi
	je	.L39
.L5:
	leal	-1640531527(%rcx), %r11d
	xorl	%r11d, %edx
	imull	$16777619, %edx, %edx
	movl	%edx, %r9d
	movl	%edx, %esi
	andl	$7, %r9d
	cmpl	$2, %r9d
	jbe	.L40
	imulq	%r8, %rsi
	shrq	$38, %rsi
	imull	$89, %esi, %r10d
	movl	%edx, %esi
	subl	%r10d, %esi
	movq	%rsi, %r11
	addq	%rcx, %r11
	xorq	%r11, %rax
	jmp	.L4
	.p2align 4,,10
	.p2align 3
.L36:
	imulq	$1372618415, %rcx, %r9
	movl	%edx, %ecx
	shrq	$32, %r9
	subl	%r9d, %ecx
	shrl	%ecx
	addl	%r9d, %ecx
	shrl	$6, %ecx
	imull	$97, %ecx, %r11d
	movl	%edx, %ecx
	subl	%r11d, %ecx
	addq	%rcx, %rax
	leaq	3(%rsi), %rcx
	cmpq	%rcx, %rdi
	jne	.L5
.L39:
	ret
	.p2align 4,,10
	.p2align 3
.L34:
	imulq	$1372618415, %rcx, %r9
	movl	%edx, %ecx
	shrq	$32, %r9
	subl	%r9d, %ecx
	shrl	%ecx
	addl	%r9d, %ecx
	shrl	$6, %ecx
	imull	$97, %ecx, %r11d
	movl	%edx, %ecx
	subl	%r11d, %ecx
	addq	%rcx, %rax
	jmp	.L35
	.p2align 4,,10
	.p2align 3
.L17:
	movl	%edx, %r10d
	movl	%edx, %ecx
	imulq	%r8, %r10
	shrq	$38, %r10
	imull	$89, %r10d, %r9d
	subl	%r9d, %ecx
	movq	%rcx, %r11
	addq	%rsi, %r11
	xorq	%r11, %rax
	jmp	.L33
.L31:
	imulq	$1372618415, %rsi, %r9
	movl	%edx, %esi
	shrq	$32, %r9
	subl	%r9d, %esi
	shrl	%esi
	addl	%r9d, %esi
	shrl	$6, %esi
	imull	$97, %esi, %r9d
	movl	%edx, %esi
	subl	%r9d, %esi
	addq	%rsi, %rax
	jmp	.L32
.L11:
	movl	%edx, %r10d
	movl	%edx, %r11d
	imulq	%r8, %r10
	shrq	$38, %r10
	imull	$89, %r10d, %esi
	subl	%esi, %r11d
	addq	%rcx, %r11
	xorq	%r11, %rax
	jmp	.L30
.L6:
	xorl	%eax, %eax
	ret
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
	jne	.L42
	testq	%r13, %r13
	je	.L42
	xorl	%esi, %esi
	xorl	%ecx, %ecx
	testq	%rbx, %rbx
	je	.L126
	movabsq	$-9086255505087856445, %r9
	movq	%rbx, %rdi
	movabsq	$-9123216960442729871, %r8
	andl	$3, %edi
	je	.L43
	cmpq	$1, %rdi
	je	.L103
	cmpq	$2, %rdi
	je	.L104
	movl	$0, 0(%rbp)
	movl	$1, %ecx
	movl	$7, %esi
	movl	$0, (%r12)
.L104:
	movq	%rcx, %rax
	movq	%rcx, %r11
	movq	%rsi, %rdi
	mulq	%r9
	movq	%rsi, %rax
	addq	$7, %rsi
	shrq	$9, %rdx
	imulq	$1009, %rdx, %r10
	mulq	%r8
	subq	%r10, %r11
	shrq	$9, %rdx
	movl	%r11d, 0(%rbp,%rcx,4)
	imulq	$1013, %rdx, %r14
	subq	%r14, %rdi
	movl	%edi, (%r12,%rcx,4)
	addq	$1, %rcx
.L103:
	movq	%rcx, %rax
	movq	%rcx, %r11
	movq	%rsi, %rdi
	mulq	%r9
	movq	%rsi, %rax
	addq	$7, %rsi
	shrq	$9, %rdx
	imulq	$1009, %rdx, %r10
	mulq	%r8
	subq	%r10, %r11
	shrq	$9, %rdx
	movl	%r11d, 0(%rbp,%rcx,4)
	movq	%rcx, %r11
	imulq	$1013, %rdx, %r14
	subq	%r14, %rdi
	movl	%edi, (%r12,%rcx,4)
	addq	$1, %rcx
	cmpq	%rcx, %rbx
	je	.L132
.L43:
	movq	%rcx, %rax
	movq	%rcx, %r14
	movq	%rsi, %r11
	mulq	%r9
	movq	%rsi, %rax
	shrq	$9, %rdx
	imulq	$1009, %rdx, %r10
	mulq	%r8
	subq	%r10, %r14
	leaq	7(%rsi), %r10
	movl	%r14d, 0(%rbp,%rcx,4)
	leaq	1(%rcx), %r14
	shrq	$9, %rdx
	movq	%r14, %rax
	imulq	$1013, %rdx, %rdi
	mulq	%r9
	movq	%r10, %rax
	subq	%rdi, %r11
	shrq	$9, %rdx
	movl	%r11d, (%r12,%rcx,4)
	movq	%r14, %r11
	imulq	$1009, %rdx, %rdi
	mulq	%r8
	subq	%rdi, %r11
	shrq	$9, %rdx
	movl	%r11d, 0(%rbp,%r14,4)
	imulq	$1013, %rdx, %rdi
	subq	%rdi, %r10
	movl	%r10d, (%r12,%r14,4)
	leaq	2(%rcx), %r14
	leaq	14(%rsi), %r10
	movq	%r14, %rax
	movq	%r14, %rdi
	mulq	%r9
	movq	%r10, %rax
	shrq	$9, %rdx
	imulq	$1009, %rdx, %r11
	mulq	%r8
	subq	%r11, %rdi
	shrq	$9, %rdx
	movl	%edi, 0(%rbp,%r14,4)
	imulq	$1013, %rdx, %r11
	subq	%r11, %r10
	leaq	3(%rcx), %r11
	movq	%r11, %rax
	movl	%r10d, (%r12,%r14,4)
	leaq	21(%rsi), %r14
	movq	%r11, %rdi
	mulq	%r9
	movq	%r14, %rax
	shrq	$9, %rdx
	imulq	$1009, %rdx, %r10
	mulq	%r8
	subq	%r10, %rdi
	shrq	$9, %rdx
	movl	%edi, 0(%rbp,%r11,4)
	imulq	$1013, %rdx, %r10
	subq	%r10, %r14
	addq	$4, %rcx
	addq	$28, %rsi
	movl	%r14d, (%r12,%r11,4)
	cmpq	%rcx, %rbx
	jne	.L43
.L132:
	cmpq	$2, %r11
	jbe	.L58
	movq	%rcx, %r9
	xorl	%esi, %esi
	shrq	$2, %r9
	salq	$4, %r9
	leaq	-16(%r9), %r8
	shrq	$4, %r8
	addq	$1, %r8
	andl	$3, %r8d
	je	.L47
	cmpq	$1, %r8
	je	.L105
	cmpq	$2, %r8
	je	.L106
	movdqu	0(%rbp), %xmm0
	movdqu	0(%rbp), %xmm5
	movl	$16, %esi
	movdqu	(%r12), %xmm1
	movdqu	(%r12), %xmm6
	pslld	$1, %xmm0
	pslld	$2, %xmm1
	paddd	%xmm5, %xmm0
	paddd	%xmm6, %xmm1
	paddd	%xmm1, %xmm0
	movups	%xmm0, 0(%r13)
.L106:
	movdqu	0(%rbp,%rsi), %xmm2
	movdqu	(%r12,%rsi), %xmm3
	movdqu	0(%rbp,%rsi), %xmm7
	movdqu	(%r12,%rsi), %xmm4
	pslld	$1, %xmm2
	pslld	$2, %xmm3
	paddd	%xmm7, %xmm2
	paddd	%xmm4, %xmm3
	paddd	%xmm3, %xmm2
	movups	%xmm2, 0(%r13,%rsi)
	addq	$16, %rsi
.L105:
	movdqu	0(%rbp,%rsi), %xmm8
	movdqu	(%r12,%rsi), %xmm10
	movdqu	0(%rbp,%rsi), %xmm9
	movdqu	(%r12,%rsi), %xmm11
	pslld	$1, %xmm8
	pslld	$2, %xmm10
	paddd	%xmm9, %xmm8
	paddd	%xmm11, %xmm10
	paddd	%xmm10, %xmm8
	movups	%xmm8, 0(%r13,%rsi)
	addq	$16, %rsi
	cmpq	%r9, %rsi
	je	.L131
.L47:
	movdqu	0(%rbp,%rsi), %xmm12
	movdqu	(%r12,%rsi), %xmm14
	movdqu	16(%rbp,%rsi), %xmm0
	movdqu	16(%r12,%rsi), %xmm1
	movdqu	32(%rbp,%rsi), %xmm2
	movdqu	32(%r12,%rsi), %xmm3
	pslld	$1, %xmm12
	pslld	$2, %xmm14
	movdqu	48(%rbp,%rsi), %xmm8
	movdqu	48(%r12,%rsi), %xmm10
	pslld	$1, %xmm0
	pslld	$2, %xmm1
	movdqu	0(%rbp,%rsi), %xmm13
	movdqu	(%r12,%rsi), %xmm15
	pslld	$1, %xmm2
	pslld	$2, %xmm3
	movdqu	16(%rbp,%rsi), %xmm5
	movdqu	16(%r12,%rsi), %xmm6
	pslld	$1, %xmm8
	pslld	$2, %xmm10
	movdqu	32(%rbp,%rsi), %xmm7
	movdqu	32(%r12,%rsi), %xmm4
	paddd	%xmm13, %xmm12
	paddd	%xmm15, %xmm14
	movdqu	48(%rbp,%rsi), %xmm9
	movdqu	48(%r12,%rsi), %xmm11
	paddd	%xmm5, %xmm0
	paddd	%xmm6, %xmm1
	paddd	%xmm7, %xmm2
	paddd	%xmm4, %xmm3
	paddd	%xmm9, %xmm8
	paddd	%xmm11, %xmm10
	paddd	%xmm14, %xmm12
	paddd	%xmm1, %xmm0
	paddd	%xmm3, %xmm2
	paddd	%xmm10, %xmm8
	movups	%xmm12, 0(%r13,%rsi)
	movups	%xmm0, 16(%r13,%rsi)
	movups	%xmm2, 32(%r13,%rsi)
	movups	%xmm8, 48(%r13,%rsi)
	addq	$64, %rsi
	cmpq	%r9, %rsi
	jne	.L47
.L131:
	movq	%rcx, %rbx
	andq	$-4, %rbx
	testb	$3, %cl
	je	.L48
.L46:
	movl	0(%rbp,%rbx,4), %r14d
	movl	(%r12,%rbx,4), %eax
	leaq	1(%rbx), %r10
	leal	(%r14,%r14,2), %edi
	leal	(%rax,%rax,4), %edx
	addl	%edx, %edi
	movl	%edi, 0(%r13,%rbx,4)
	cmpq	%r10, %rcx
	jbe	.L49
	imull	$3, 0(%rbp,%r10,4), %r9d
	addq	$2, %rbx
	imull	$5, (%r12,%r10,4), %r8d
	addl	%r8d, %r9d
	movl	%r9d, 0(%r13,%r10,4)
	cmpq	%rbx, %rcx
	jbe	.L50
	imull	$5, (%r12,%rbx,4), %r14d
	imull	$3, 0(%rbp,%rbx,4), %esi
	addl	%esi, %r14d
	movl	%r14d, 0(%r13,%rbx,4)
.L50:
	cmpq	$2, %r11
	jbe	.L134
.L48:
	movq	%rcx, %rdi
	pxor	%xmm13, %xmm13
	pxor	%xmm12, %xmm12
	movq	%r13, %rax
	shrq	$2, %rdi
	salq	$4, %rdi
	leaq	(%rdi,%r13), %rdx
	subq	$16, %rdi
	shrq	$4, %rdi
	addq	$1, %rdi
	andl	$7, %edi
	je	.L52
	cmpq	$1, %rdi
	je	.L107
	cmpq	$2, %rdi
	je	.L108
	cmpq	$3, %rdi
	je	.L109
	cmpq	$4, %rdi
	je	.L110
	cmpq	$5, %rdi
	je	.L111
	cmpq	$6, %rdi
	jne	.L135
.L112:
	movdqu	(%rax), %xmm15
	addq	$16, %rax
	movdqa	%xmm15, %xmm0
	punpckldq	%xmm12, %xmm15
	punpckhdq	%xmm12, %xmm0
	paddq	%xmm0, %xmm15
	paddq	%xmm15, %xmm13
.L111:
	movdqu	(%rax), %xmm5
	addq	$16, %rax
	movdqa	%xmm5, %xmm1
	punpckldq	%xmm12, %xmm5
	punpckhdq	%xmm12, %xmm1
	paddq	%xmm1, %xmm5
	paddq	%xmm5, %xmm13
.L110:
	movdqu	(%rax), %xmm6
	addq	$16, %rax
	movdqa	%xmm6, %xmm2
	punpckldq	%xmm12, %xmm6
	punpckhdq	%xmm12, %xmm2
	paddq	%xmm2, %xmm6
	paddq	%xmm6, %xmm13
.L109:
	movdqu	(%rax), %xmm7
	addq	$16, %rax
	movdqa	%xmm7, %xmm3
	punpckldq	%xmm12, %xmm7
	punpckhdq	%xmm12, %xmm3
	paddq	%xmm3, %xmm7
	paddq	%xmm7, %xmm13
.L108:
	movdqu	(%rax), %xmm4
	addq	$16, %rax
	movdqa	%xmm4, %xmm8
	punpckldq	%xmm12, %xmm4
	punpckhdq	%xmm12, %xmm8
	paddq	%xmm8, %xmm4
	paddq	%xmm4, %xmm13
.L107:
	movdqu	(%rax), %xmm9
	addq	$16, %rax
	movdqa	%xmm9, %xmm10
	punpckldq	%xmm12, %xmm9
	punpckhdq	%xmm12, %xmm10
	paddq	%xmm10, %xmm9
	paddq	%xmm9, %xmm13
	cmpq	%rdx, %rax
	je	.L130
.L52:
	movdqu	(%rax), %xmm11
	movdqu	16(%rax), %xmm15
	subq	$-128, %rax
	movdqu	-96(%rax), %xmm5
	movdqu	-80(%rax), %xmm6
	movdqa	%xmm11, %xmm14
	movdqa	%xmm15, %xmm0
	punpckldq	%xmm12, %xmm11
	movdqu	-64(%rax), %xmm7
	punpckhdq	%xmm12, %xmm14
	movdqa	%xmm5, %xmm1
	punpckhdq	%xmm12, %xmm0
	movdqu	-48(%rax), %xmm4
	paddq	%xmm14, %xmm11
	punpckldq	%xmm12, %xmm15
	punpckhdq	%xmm12, %xmm1
	movdqu	-32(%rax), %xmm9
	paddq	%xmm11, %xmm13
	movdqa	%xmm6, %xmm2
	paddq	%xmm0, %xmm15
	punpckldq	%xmm12, %xmm5
	movdqa	%xmm7, %xmm3
	paddq	%xmm15, %xmm13
	paddq	%xmm1, %xmm5
	punpckhdq	%xmm12, %xmm2
	punpckldq	%xmm12, %xmm6
	movdqu	-16(%rax), %xmm1
	movdqa	%xmm4, %xmm8
	paddq	%xmm5, %xmm13
	paddq	%xmm2, %xmm6
	punpckhdq	%xmm12, %xmm3
	punpckldq	%xmm12, %xmm7
	movdqa	%xmm9, %xmm10
	paddq	%xmm6, %xmm13
	paddq	%xmm7, %xmm3
	punpckhdq	%xmm12, %xmm8
	punpckldq	%xmm12, %xmm4
	paddq	%xmm3, %xmm13
	punpckhdq	%xmm12, %xmm10
	paddq	%xmm8, %xmm4
	punpckldq	%xmm12, %xmm9
	movdqa	%xmm1, %xmm11
	paddq	%xmm4, %xmm13
	paddq	%xmm10, %xmm9
	punpckldq	%xmm12, %xmm1
	paddq	%xmm13, %xmm9
	punpckhdq	%xmm12, %xmm11
	movdqa	%xmm1, %xmm13
	paddq	%xmm11, %xmm13
	paddq	%xmm9, %xmm13
	cmpq	%rdx, %rax
	jne	.L52
.L130:
	movdqa	%xmm13, %xmm12
	movq	%rcx, %r11
	psrldq	$8, %xmm12
	andq	$-4, %r11
	paddq	%xmm12, %xmm13
	movq	%xmm13, %rbx
	testb	$3, %cl
	je	.L44
.L51:
	movl	0(%r13,%r11,4), %r10d
	addq	$1, %r11
	addq	%r10, %rbx
	cmpq	%rcx, %r11
	jnb	.L44
.L55:
	movl	0(%r13,%r11,4), %r9d
	addq	$1, %r11
	addq	%r9, %rbx
	cmpq	%rcx, %r11
	jnb	.L44
	movl	0(%r13,%r11,4), %ecx
	addq	%rcx, %rbx
.L44:
	movq	%rbp, %rdi
	call	free@PLT
	movq	%r12, %rdi
	call	free@PLT
	movq	%r13, %rdi
	call	free@PLT
.L41:
	movq	%rbx, %rax
	popq	%rbx
	.cfi_remember_state
	.cfi_def_cfa_offset 40
	popq	%rbp
	.cfi_def_cfa_offset 32
	popq	%r12
	.cfi_def_cfa_offset 24
	popq	%r13
	.cfi_def_cfa_offset 16
	popq	%r14
	.cfi_def_cfa_offset 8
	ret
.L135:
	.cfi_restore_state
	movdqu	0(%r13), %xmm13
	leaq	16(%r13), %rax
	movdqa	%xmm13, %xmm14
	punpckldq	%xmm12, %xmm13
	punpckhdq	%xmm12, %xmm14
	paddq	%xmm14, %xmm13
	jmp	.L112
.L126:
	xorl	%ebx, %ebx
	jmp	.L44
.L58:
	xorl	%ebx, %ebx
	jmp	.L46
.L134:
	movl	0(%r13), %ebx
	movl	$1, %r11d
	jmp	.L55
.L49:
	cmpq	$2, %r11
	ja	.L48
	xorl	%r11d, %r11d
	xorl	%ebx, %ebx
	jmp	.L51
.L42:
	movq	%rbp, %rdi
	orq	$-1, %rbx
	call	free@PLT
	movq	%r12, %rdi
	call	free@PLT
	movq	%r13, %rdi
	call	free@PLT
	jmp	.L41
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
	jne	.L147
	movq	16(%rbx), %rdi
	movq	%rsp, %rsi
	movl	$10, %edx
	call	strtoull@PLT
	movq	%rax, %rbp
	movq	(%rsp), %rax
	cmpq	%rax, 16(%rbx)
	je	.L139
	cmpb	$0, (%rax)
	jne	.L139
	testq	%rbp, %rbp
	je	.L139
	movq	8(%rbx), %r12
	leaq	.LC2(%rip), %rsi
	movq	%r12, %rdi
	call	strcmp@PLT
	testl	%eax, %eax
	je	.L148
	leaq	.LC3(%rip), %rsi
	movq	%r12, %rdi
	call	strcmp@PLT
	testl	%eax, %eax
	jne	.L144
	movq	%rbp, %rdi
	call	vector_kernel
	movq	%rax, %rdx
	cmpq	$-1, %rax
	je	.L149
.L143:
	leaq	.LC6(%rip), %rsi
	movl	$1, %edi
	xorl	%eax, %eax
	call	__printf_chk@PLT
	xorl	%eax, %eax
	jmp	.L136
.L139:
	movq	stderr(%rip), %rdi
	leaq	.LC1(%rip), %rdx
	movl	$1, %esi
	xorl	%eax, %eax
	call	__fprintf_chk@PLT
	movl	$2, %eax
.L136:
	movq	8(%rsp), %rcx
	xorq	%fs:40, %rcx
	jne	.L150
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
.L147:
	.cfi_restore_state
	movq	(%rsi), %rcx
	movq	stderr(%rip), %rdi
	leaq	.LC0(%rip), %rdx
	movl	$1, %esi
	call	__fprintf_chk@PLT
	movl	$2, %eax
	jmp	.L136
.L148:
	movq	%rbp, %rdi
	call	branch_kernel
	movq	%rax, %rdx
	jmp	.L143
.L144:
	movq	stderr(%rip), %rdi
	movq	%r12, %rcx
	movl	$1, %esi
	xorl	%eax, %eax
	leaq	.LC5(%rip), %rdx
	call	__fprintf_chk@PLT
	movl	$2, %eax
	jmp	.L136
.L149:
	movq	stderr(%rip), %rdi
	leaq	.LC4(%rip), %rdx
	movl	$1, %esi
	xorl	%eax, %eax
	call	__fprintf_chk@PLT
	movl	$3, %eax
	jmp	.L136
.L150:
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
