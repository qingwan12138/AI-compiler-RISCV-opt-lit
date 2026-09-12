	.file	"bench.c"
	.text
	.p2align 4
	.type	branch_kernel, @function
branch_kernel:
.LFB29:
	.cfi_startproc
	movq	%rdi, %r8
	testq	%rdi, %rdi
	je	.L6
	movq	%rdi, %rdx
	xorl	%ecx, %ecx
	movl	$-2128831035, %eax
	xorl	%esi, %esi
	movl	$3088515809, %r9d
	andl	$3, %edx
	je	.L5
	cmpq	$1, %rdx
	je	.L23
	cmpq	$2, %rdx
	movl	$1, %r11d
	movl	$-1910984908, %edi
	movl	$86, %r10d
	cmovne	%r11, %rcx
	cmovne	%edi, %eax
	cmovne	%r10, %rsi
	leal	-1640531527(%rcx), %edx
	xorl	%edx, %eax
	imull	$16777619, %eax, %eax
	movl	%eax, %edi
	andl	$7, %edi
	cmpl	$2, %edi
	ja	.L11
	movl	%eax, %r10d
	movl	%eax, %edx
	movl	%eax, %edi
	imulq	$1372618415, %r10, %r11
	shrq	$32, %r11
	subl	%r11d, %edx
	shrl	%edx
	addl	%r11d, %edx
	shrl	$6, %edx
	imull	$97, %edx, %r10d
	subl	%r10d, %edi
	addq	%rdi, %rsi
.L30:
	addq	$1, %rcx
.L23:
	leal	-1640531527(%rcx), %r11d
	xorl	%r11d, %eax
	imull	$16777619, %eax, %eax
	movl	%eax, %edx
	andl	$7, %edx
	cmpl	$2, %edx
	jbe	.L31
	movl	%eax, %r10d
	movl	%eax, %edi
	imulq	%r9, %r10
	shrq	$38, %r10
	imull	$89, %r10d, %r11d
	subl	%r11d, %edi
	leaq	(%rdi,%rcx), %rdx
	xorq	%rdx, %rsi
.L32:
	addq	$1, %rcx
	cmpq	%rcx, %r8
	jne	.L5
.L1:
	movq	%rsi, %rax
	ret
	.p2align 4,,10
	.p2align 3
.L39:
	movl	%edx, %edi
	movl	%edx, %r11d
	imulq	$1372618415, %rdi, %r10
	movl	%edx, %edi
	shrq	$32, %r10
	subl	%r10d, %r11d
	shrl	%r11d
	addl	%r10d, %r11d
	shrl	$6, %r11d
	imull	$97, %r11d, %eax
	subl	%eax, %edi
	addq	%rdi, %rsi
.L4:
	leaq	1(%rcx), %r11
	leal	-1640531526(%rcx), %ecx
	xorl	%edx, %ecx
	imull	$16777619, %ecx, %eax
	movl	%eax, %edx
	andl	$7, %edx
	cmpl	$2, %edx
	ja	.L17
	movl	%eax, %r10d
	movl	%eax, %ecx
	imulq	$1372618415, %r10, %rdi
	movl	%eax, %r10d
	shrq	$32, %rdi
	subl	%edi, %ecx
	shrl	%ecx
	addl	%edi, %ecx
	shrl	$6, %ecx
	imull	$97, %ecx, %edx
	subl	%edx, %r10d
	addq	%r10, %rsi
.L33:
	leal	-1640531526(%r11), %ecx
	leaq	1(%r11), %rdi
	xorl	%eax, %ecx
	imull	$16777619, %ecx, %edx
	movl	%edx, %eax
	andl	$7, %eax
	cmpl	$2, %eax
	jbe	.L34
	movl	%edx, %r10d
	movl	%edx, %ecx
	imulq	%r9, %r10
	shrq	$38, %r10
	imull	$89, %r10d, %eax
	subl	%eax, %ecx
	addq	%rdi, %rcx
	xorq	%rsi, %rcx
.L35:
	leal	-1640531525(%r11), %esi
	leaq	2(%r11), %rdi
	xorl	%edx, %esi
	imull	$16777619, %esi, %eax
	movl	%eax, %edx
	andl	$7, %edx
	cmpl	$2, %edx
	jbe	.L36
	movl	%eax, %r10d
	movl	%eax, %esi
	imulq	%r9, %r10
	shrq	$38, %r10
	imull	$89, %r10d, %edx
	subl	%edx, %esi
	addq	%rdi, %rsi
	xorq	%rcx, %rsi
.L37:
	leaq	3(%r11), %rcx
	cmpq	%rcx, %r8
	je	.L1
.L5:
	leal	-1640531527(%rcx), %r11d
	xorl	%eax, %r11d
	imull	$16777619, %r11d, %edx
	movl	%edx, %eax
	andl	$7, %eax
	cmpl	$2, %eax
	jbe	.L39
	movl	%edx, %edi
	movl	%edx, %r11d
	imulq	%r9, %rdi
	shrq	$38, %rdi
	imull	$89, %edi, %r10d
	subl	%r10d, %r11d
	leaq	(%r11,%rcx), %rax
	xorq	%rax, %rsi
	jmp	.L4
	.p2align 4,,10
	.p2align 3
.L36:
	movl	%eax, %edi
	movl	%eax, %r10d
	imulq	$1372618415, %rdi, %rsi
	shrq	$32, %rsi
	subl	%esi, %r10d
	shrl	%r10d
	addl	%esi, %r10d
	movl	%eax, %esi
	shrl	$6, %r10d
	imull	$97, %r10d, %edx
	subl	%edx, %esi
	addq	%rcx, %rsi
	jmp	.L37
	.p2align 4,,10
	.p2align 3
.L34:
	movl	%edx, %edi
	movl	%edx, %r10d
	imulq	$1372618415, %rdi, %rcx
	shrq	$32, %rcx
	subl	%ecx, %r10d
	shrl	%r10d
	addl	%ecx, %r10d
	movl	%edx, %ecx
	shrl	$6, %r10d
	imull	$97, %r10d, %eax
	subl	%eax, %ecx
	addq	%rsi, %rcx
	jmp	.L35
	.p2align 4,,10
	.p2align 3
.L17:
	movl	%eax, %r10d
	movl	%eax, %ecx
	imulq	%r9, %r10
	shrq	$38, %r10
	imull	$89, %r10d, %edi
	subl	%edi, %ecx
	leaq	(%rcx,%r11), %rdx
	xorq	%rdx, %rsi
	jmp	.L33
.L31:
	movl	%eax, %r10d
	movl	%eax, %edi
	imulq	$1372618415, %r10, %r11
	movl	%eax, %r10d
	shrq	$32, %r11
	subl	%r11d, %edi
	shrl	%edi
	addl	%r11d, %edi
	shrl	$6, %edi
	imull	$97, %edi, %edx
	subl	%edx, %r10d
	addq	%r10, %rsi
	jmp	.L32
.L11:
	movl	%eax, %r10d
	movl	%eax, %edx
	imulq	%r9, %r10
	shrq	$38, %r10
	imull	$89, %r10d, %r11d
	subl	%r11d, %edx
	leaq	(%rdx,%rcx), %rdi
	xorq	%rdi, %rsi
	jmp	.L30
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
	movq	%rax, %rbx
	call	malloc@PLT
	movq	%r12, %rdi
	movq	%rax, %rbp
	call	malloc@PLT
	testq	%rbx, %rbx
	movq	%rax, %r12
	sete	%al
	testq	%rbp, %rbp
	sete	%dl
	orb	%dl, %al
	jne	.L41
	testq	%r12, %r12
	je	.L41
	xorl	%esi, %esi
	xorl	%r11d, %r11d
	testq	%r13, %r13
	je	.L135
	movabsq	$-9086255505087856445, %r9
	movq	%r13, %rdi
	movabsq	$-9123216960442729871, %r8
	andl	$3, %edi
	je	.L42
	cmpq	$1, %rdi
	je	.L108
	cmpq	$2, %rdi
	je	.L109
	xorl	%ecx, %ecx
	movl	$1, %r11d
	movl	$7, %esi
	movl	%ecx, (%rbx)
	movl	%ecx, 0(%rbp)
.L109:
	movq	%r11, %rax
	movq	%r11, %rdi
	mulq	%r9
	movq	%rsi, %rax
	shrq	$9, %rdx
	imulq	$1009, %rdx, %r10
	mulq	%r8
	subq	%r10, %rdi
	movq	%rsi, %r10
	addq	$7, %rsi
	shrq	$9, %rdx
	movl	%edi, (%rbx,%r11,4)
	imulq	$1013, %rdx, %rcx
	subq	%rcx, %r10
	movl	%r10d, 0(%rbp,%r11,4)
	addq	$1, %r11
.L108:
	movq	%r11, %rax
	movq	%r11, %rcx
	mulq	%r9
	movq	%rsi, %rax
	shrq	$9, %rdx
	imulq	$1009, %rdx, %rdi
	mulq	%r8
	subq	%rdi, %rcx
	movq	%rsi, %rdi
	addq	$7, %rsi
	shrq	$9, %rdx
	movl	%ecx, (%rbx,%r11,4)
	movq	%r11, %rcx
	imulq	$1013, %rdx, %r10
	subq	%r10, %rdi
	movl	%edi, 0(%rbp,%r11,4)
	addq	$1, %r11
	cmpq	%r11, %r13
	je	.L141
.L42:
	movq	%r11, %rax
	movq	%r11, %rdi
	mulq	%r9
	movq	%rsi, %rax
	shrq	$9, %rdx
	imulq	$1009, %rdx, %r10
	mulq	%r8
	subq	%r10, %rdi
	movq	%rsi, %r10
	movl	%edi, (%rbx,%r11,4)
	leaq	1(%r11), %rdi
	shrq	$9, %rdx
	movq	%rdi, %rax
	imulq	$1013, %rdx, %rcx
	mulq	%r9
	movq	%rdi, %rax
	subq	%rcx, %r10
	leaq	7(%rsi), %rcx
	shrq	$9, %rdx
	movl	%r10d, 0(%rbp,%r11,4)
	imulq	$1009, %rdx, %r10
	subq	%r10, %rax
	movl	%eax, (%rbx,%rdi,4)
	movq	%rcx, %rax
	mulq	%r8
	shrq	$9, %rdx
	imulq	$1013, %rdx, %r10
	subq	%r10, %rcx
	movl	%ecx, 0(%rbp,%rdi,4)
	leaq	2(%r11), %rdi
	leaq	14(%rsi), %rcx
	movq	%rdi, %rax
	mulq	%r9
	movq	%rdi, %rax
	shrq	$9, %rdx
	imulq	$1009, %rdx, %r10
	subq	%r10, %rax
	movl	%eax, (%rbx,%rdi,4)
	movq	%rcx, %rax
	mulq	%r8
	shrq	$9, %rdx
	imulq	$1013, %rdx, %r10
	subq	%r10, %rcx
	movl	%ecx, 0(%rbp,%rdi,4)
	leaq	3(%r11), %rcx
	leaq	21(%rsi), %rdi
	movq	%rcx, %rax
	mulq	%r9
	movq	%rcx, %rax
	shrq	$9, %rdx
	imulq	$1009, %rdx, %r10
	subq	%r10, %rax
	movl	%eax, (%rbx,%rcx,4)
	movq	%rdi, %rax
	mulq	%r8
	shrq	$9, %rdx
	imulq	$1013, %rdx, %r10
	subq	%r10, %rdi
	addq	$4, %r11
	addq	$28, %rsi
	movl	%edi, 0(%rbp,%rcx,4)
	cmpq	%r11, %r13
	jne	.L42
.L141:
	cmpq	$2, %rcx
	jbe	.L55
	movq	%r11, %r9
	xorl	%esi, %esi
	shrq	$2, %r9
	salq	$4, %r9
	leaq	-16(%r9), %r8
	shrq	$4, %r8
	addq	$1, %r8
	andl	$3, %r8d
	je	.L46
	cmpq	$1, %r8
	je	.L110
	cmpq	$2, %r8
	je	.L111
	movdqu	(%rbx), %xmm0
	movdqu	0(%rbp), %xmm1
	movl	$16, %esi
	movdqu	(%rbx), %xmm5
	movdqu	0(%rbp), %xmm6
	pslld	$1, %xmm0
	pslld	$2, %xmm1
	paddd	%xmm5, %xmm0
	paddd	%xmm6, %xmm1
	paddd	%xmm1, %xmm0
	movups	%xmm0, (%r12)
.L111:
	movdqu	(%rbx,%rsi), %xmm2
	movdqu	0(%rbp,%rsi), %xmm3
	movdqu	(%rbx,%rsi), %xmm7
	movdqu	0(%rbp,%rsi), %xmm4
	pslld	$1, %xmm2
	pslld	$2, %xmm3
	paddd	%xmm7, %xmm2
	paddd	%xmm4, %xmm3
	paddd	%xmm3, %xmm2
	movups	%xmm2, (%r12,%rsi)
	addq	$16, %rsi
.L110:
	movdqu	(%rbx,%rsi), %xmm8
	movdqu	0(%rbp,%rsi), %xmm10
	movdqu	(%rbx,%rsi), %xmm9
	movdqu	0(%rbp,%rsi), %xmm11
	pslld	$1, %xmm8
	pslld	$2, %xmm10
	paddd	%xmm9, %xmm8
	paddd	%xmm11, %xmm10
	paddd	%xmm10, %xmm8
	movups	%xmm8, (%r12,%rsi)
	addq	$16, %rsi
	cmpq	%r9, %rsi
	je	.L140
.L46:
	movdqu	(%rbx,%rsi), %xmm12
	movdqu	0(%rbp,%rsi), %xmm14
	movdqu	16(%rbx,%rsi), %xmm0
	movdqu	16(%rbp,%rsi), %xmm1
	movdqu	32(%rbx,%rsi), %xmm2
	movdqu	32(%rbp,%rsi), %xmm3
	pslld	$1, %xmm12
	pslld	$2, %xmm14
	movdqu	48(%rbx,%rsi), %xmm8
	movdqu	48(%rbp,%rsi), %xmm10
	pslld	$1, %xmm0
	pslld	$2, %xmm1
	movdqu	(%rbx,%rsi), %xmm13
	movdqu	0(%rbp,%rsi), %xmm15
	pslld	$1, %xmm2
	pslld	$2, %xmm3
	movdqu	16(%rbx,%rsi), %xmm5
	movdqu	16(%rbp,%rsi), %xmm6
	pslld	$1, %xmm8
	pslld	$2, %xmm10
	movdqu	32(%rbx,%rsi), %xmm7
	movdqu	32(%rbp,%rsi), %xmm4
	paddd	%xmm13, %xmm12
	paddd	%xmm15, %xmm14
	movdqu	48(%rbx,%rsi), %xmm9
	movdqu	48(%rbp,%rsi), %xmm11
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
	movups	%xmm12, (%r12,%rsi)
	movups	%xmm0, 16(%r12,%rsi)
	movups	%xmm2, 32(%r12,%rsi)
	movups	%xmm8, 48(%r12,%rsi)
	addq	$64, %rsi
	cmpq	%r9, %rsi
	jne	.L46
.L140:
	testb	$3, %r11b
	je	.L47
	movq	%r11, %r13
	andq	$-4, %r13
.L45:
	movq	%r11, %rdi
	subq	%r13, %rdi
	cmpq	$1, %rdi
	je	.L48
	movq	(%rbx,%r13,4), %xmm12
	movq	0(%rbp,%r13,4), %xmm13
	movdqa	%xmm12, %xmm14
	movdqa	%xmm13, %xmm15
	pslld	$1, %xmm14
	pslld	$2, %xmm15
	paddd	%xmm12, %xmm14
	paddd	%xmm13, %xmm15
	paddd	%xmm15, %xmm14
	movq	%xmm14, (%r12,%r13,4)
	testb	$1, %dil
	je	.L49
	andq	$-2, %rdi
	addq	%rdi, %r13
.L48:
	movl	(%rbx,%r13,4), %eax
	movl	0(%rbp,%r13,4), %r10d
	leal	(%rax,%rax,2), %edx
	leal	(%r10,%r10,4), %r9d
	addl	%r9d, %edx
	movl	%edx, (%r12,%r13,4)
.L49:
	cmpq	$2, %rcx
	jbe	.L56
.L47:
	movq	%r11, %r8
	pxor	%xmm5, %xmm5
	pxor	%xmm0, %xmm0
	movq	%r12, %rdi
	shrq	$2, %r8
	salq	$4, %r8
	leaq	(%r8,%r12), %rsi
	subq	$16, %r8
	shrq	$4, %r8
	addq	$1, %r8
	andl	$7, %r8d
	je	.L51
	cmpq	$1, %r8
	je	.L112
	cmpq	$2, %r8
	je	.L113
	cmpq	$3, %r8
	je	.L114
	cmpq	$4, %r8
	je	.L115
	cmpq	$5, %r8
	je	.L116
	cmpq	$6, %r8
	jne	.L143
.L117:
	movdqu	(%rdi), %xmm6
	addq	$16, %rdi
	movdqa	%xmm6, %xmm2
	punpckldq	%xmm0, %xmm6
	punpckhdq	%xmm0, %xmm2
	paddq	%xmm2, %xmm6
	paddq	%xmm6, %xmm5
.L116:
	movdqu	(%rdi), %xmm7
	addq	$16, %rdi
	movdqa	%xmm7, %xmm3
	punpckldq	%xmm0, %xmm7
	punpckhdq	%xmm0, %xmm3
	paddq	%xmm3, %xmm7
	paddq	%xmm7, %xmm5
.L115:
	movdqu	(%rdi), %xmm4
	addq	$16, %rdi
	movdqa	%xmm4, %xmm8
	punpckldq	%xmm0, %xmm4
	punpckhdq	%xmm0, %xmm8
	paddq	%xmm8, %xmm4
	paddq	%xmm4, %xmm5
.L114:
	movdqu	(%rdi), %xmm9
	addq	$16, %rdi
	movdqa	%xmm9, %xmm10
	punpckldq	%xmm0, %xmm9
	punpckhdq	%xmm0, %xmm10
	paddq	%xmm10, %xmm9
	paddq	%xmm9, %xmm5
.L113:
	movdqu	(%rdi), %xmm11
	addq	$16, %rdi
	movdqa	%xmm11, %xmm12
	punpckldq	%xmm0, %xmm11
	punpckhdq	%xmm0, %xmm12
	paddq	%xmm12, %xmm11
	paddq	%xmm11, %xmm5
.L112:
	movdqu	(%rdi), %xmm13
	addq	$16, %rdi
	movdqa	%xmm13, %xmm14
	punpckldq	%xmm0, %xmm13
	punpckhdq	%xmm0, %xmm14
	paddq	%xmm14, %xmm13
	paddq	%xmm13, %xmm5
	cmpq	%rsi, %rdi
	je	.L139
.L51:
	movdqu	(%rdi), %xmm15
	movdqu	32(%rdi), %xmm2
	subq	$-128, %rdi
	movdqu	-80(%rdi), %xmm4
	movdqu	-64(%rdi), %xmm8
	movdqa	%xmm15, %xmm1
	punpckldq	%xmm0, %xmm15
	movdqa	%xmm2, %xmm7
	movdqu	-48(%rdi), %xmm10
	punpckhdq	%xmm0, %xmm1
	movdqa	%xmm4, %xmm3
	punpckhdq	%xmm0, %xmm7
	movdqu	-32(%rdi), %xmm12
	paddq	%xmm1, %xmm15
	punpckldq	%xmm0, %xmm2
	movdqa	%xmm8, %xmm9
	movdqu	-16(%rdi), %xmm1
	paddq	%xmm5, %xmm15
	movdqu	-112(%rdi), %xmm5
	paddq	%xmm7, %xmm2
	punpckhdq	%xmm0, %xmm3
	punpckldq	%xmm0, %xmm4
	movdqa	%xmm10, %xmm11
	punpckhdq	%xmm0, %xmm9
	movdqa	%xmm5, %xmm6
	punpckldq	%xmm0, %xmm5
	paddq	%xmm3, %xmm4
	punpckhdq	%xmm0, %xmm6
	punpckldq	%xmm0, %xmm8
	movdqa	%xmm12, %xmm13
	paddq	%xmm6, %xmm5
	paddq	%xmm9, %xmm8
	punpckhdq	%xmm0, %xmm11
	paddq	%xmm5, %xmm15
	punpckldq	%xmm0, %xmm10
	movdqa	%xmm1, %xmm14
	paddq	%xmm2, %xmm15
	paddq	%xmm11, %xmm10
	punpckhdq	%xmm0, %xmm13
	paddq	%xmm4, %xmm15
	punpckldq	%xmm0, %xmm12
	punpckldq	%xmm0, %xmm1
	paddq	%xmm8, %xmm15
	paddq	%xmm13, %xmm12
	punpckhdq	%xmm0, %xmm14
	paddq	%xmm10, %xmm15
	movdqa	%xmm1, %xmm5
	paddq	%xmm12, %xmm15
	paddq	%xmm14, %xmm5
	paddq	%xmm15, %xmm5
	cmpq	%rsi, %rdi
	jne	.L51
.L139:
	movdqa	%xmm5, %xmm0
	psrldq	$8, %xmm0
	paddq	%xmm5, %xmm0
	movq	%xmm0, %r13
	testb	$3, %r11b
	je	.L43
	movq	%r11, %rcx
	andq	$-4, %rcx
.L50:
	movl	(%r12,%rcx,4), %edx
	leaq	1(%rcx), %r10
	leaq	0(,%rcx,4), %rax
	addq	%rdx, %r13
	cmpq	%r11, %r10
	jnb	.L43
	movl	4(%r12,%rax), %r9d
	addq	$2, %rcx
	addq	%r9, %r13
	cmpq	%r11, %rcx
	jnb	.L43
	movl	8(%r12,%rax), %r11d
	addq	%r11, %r13
.L43:
	movq	%rbx, %rdi
	call	free@PLT
	movq	%rbp, %rdi
	call	free@PLT
	movq	%r12, %rdi
	call	free@PLT
.L40:
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
.L143:
	.cfi_restore_state
	movdqu	(%r12), %xmm5
	leaq	16(%r12), %rdi
	movdqa	%xmm5, %xmm1
	punpckldq	%xmm0, %xmm5
	punpckhdq	%xmm0, %xmm1
	paddq	%xmm1, %xmm5
	jmp	.L117
.L135:
	xorl	%r13d, %r13d
	jmp	.L43
.L56:
	xorl	%ecx, %ecx
	xorl	%r13d, %r13d
	jmp	.L50
.L55:
	xorl	%r13d, %r13d
	jmp	.L45
.L41:
	movq	%rbx, %rdi
	orq	$-1, %r13
	call	free@PLT
	movq	%rbp, %rdi
	call	free@PLT
	movq	%r12, %rdi
	call	free@PLT
	jmp	.L40
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
	jne	.L156
	movq	16(%rbx), %rdi
	movq	%rsp, %rsi
	movl	$10, %edx
	call	strtoull@PLT
	movq	%rax, %rbp
	movq	(%rsp), %rax
	cmpq	%rax, 16(%rbx)
	je	.L147
	cmpb	$0, (%rax)
	jne	.L147
	testq	%rbp, %rbp
	je	.L147
	movq	8(%rbx), %rbx
	leaq	.LC2(%rip), %rsi
	movq	%rbx, %rdi
	call	strcmp@PLT
	testl	%eax, %eax
	je	.L157
	leaq	.LC3(%rip), %rsi
	movq	%rbx, %rdi
	call	strcmp@PLT
	testl	%eax, %eax
	jne	.L153
	movq	%rbp, %rdi
	call	vector_kernel
	movq	%rax, %rdx
	cmpq	$-1, %rax
	je	.L158
.L152:
	leaq	.LC6(%rip), %rsi
	movl	$2, %edi
	xorl	%eax, %eax
	call	__printf_chk@PLT
	xorl	%eax, %eax
	jmp	.L144
.L147:
	movq	stderr(%rip), %rdi
	leaq	.LC1(%rip), %rdx
	movl	$2, %esi
	xorl	%eax, %eax
	call	__fprintf_chk@PLT
.L146:
	movl	$2, %eax
.L144:
	movq	8(%rsp), %rdx
	subq	%fs:40, %rdx
	jne	.L159
	addq	$24, %rsp
	.cfi_remember_state
	.cfi_def_cfa_offset 24
	popq	%rbx
	.cfi_def_cfa_offset 16
	popq	%rbp
	.cfi_def_cfa_offset 8
	ret
.L156:
	.cfi_restore_state
	movq	(%rsi), %rcx
	movq	stderr(%rip), %rdi
	leaq	.LC0(%rip), %rdx
	movl	$2, %esi
	call	__fprintf_chk@PLT
	jmp	.L146
.L157:
	movq	%rbp, %rdi
	call	branch_kernel
	movq	%rax, %rdx
	jmp	.L152
.L153:
	movq	stderr(%rip), %rdi
	movq	%rbx, %rcx
	movl	$2, %esi
	xorl	%eax, %eax
	leaq	.LC5(%rip), %rdx
	call	__fprintf_chk@PLT
	jmp	.L146
.L158:
	movq	stderr(%rip), %rdi
	leaq	.LC4(%rip), %rdx
	movl	$2, %esi
	xorl	%eax, %eax
	call	__fprintf_chk@PLT
	movl	$3, %eax
	jmp	.L144
.L159:
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
