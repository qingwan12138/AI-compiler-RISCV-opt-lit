	.file	"bench.c"
	.text
	.p2align 4,,15
	.def	branch_kernel;	.scl	3;	.type	32;	.endef
	.seh_proc	branch_kernel
branch_kernel:
	pushq	%rbx
	.seh_pushreg	%rbx
	.seh_endprologue
	testq	%rcx, %rcx
	je	.L6
	movq	%rcx, %rax
	xorl	%r9d, %r9d
	xorl	%r11d, %r11d
	andl	$3, %eax
	movl	$-2128831035, %r8d
	movl	$-1206451487, %r10d
	je	.L5
	cmpq	$1, %rax
	je	.L23
	cmpq	$2, %rax
	movl	$1, %eax
	movl	$-1910984908, %edx
	cmovne	%rax, %r9
	movl	$86, %ebx
	cmovne	%edx, %r8d
	cmovne	%rbx, %r11
	leal	-1640531527(%r9), %edx
	xorl	%edx, %r8d
	imull	$16777619, %r8d, %r8d
	movl	%r8d, %ebx
	andl	$7, %ebx
	cmpl	$2, %ebx
	ja	.L11
	movl	%r8d, %edx
	movl	%r8d, %eax
	imulq	$1372618415, %rdx, %rdx
	shrq	$32, %rdx
	subl	%edx, %eax
	shrl	%eax
	addl	%edx, %eax
	shrl	$6, %eax
	imull	$97, %eax, %edx
	movl	%r8d, %eax
	subl	%edx, %eax
	addq	%rax, %r11
.L30:
	addq	$1, %r9
.L23:
	leal	-1640531527(%r9), %edx
	xorl	%edx, %r8d
	imull	$16777619, %r8d, %r8d
	movl	%r8d, %eax
	andl	$7, %eax
	cmpl	$2, %eax
	jbe	.L31
	movl	%r8d, %eax
	mull	%r10d
	movl	%r8d, %eax
	shrl	$6, %edx
	imull	$89, %edx, %ebx
	subl	%ebx, %eax
	addq	%r9, %rax
	xorq	%rax, %r11
.L32:
	addq	$1, %r9
	cmpq	%r9, %rcx
	jne	.L5
.L1:
	movq	%r11, %rax
	popq	%rbx
	ret
	.p2align 4,,10
.L39:
	movl	%r8d, %edx
	movl	%r8d, %eax
	imulq	$1372618415, %rdx, %rdx
	shrq	$32, %rdx
	subl	%edx, %eax
	shrl	%eax
	addl	%edx, %eax
	shrl	$6, %eax
	imull	$97, %eax, %edx
	movl	%r8d, %eax
	subl	%edx, %eax
	addq	%rax, %r11
.L4:
	addq	$1, %r9
	leal	-1640531527(%r9), %edx
	xorl	%edx, %r8d
	imull	$16777619, %r8d, %r8d
	movl	%r8d, %eax
	andl	$7, %eax
	cmpl	$2, %eax
	ja	.L17
	movl	%r8d, %edx
	imulq	$1372618415, %rdx, %rax
	movl	%r8d, %edx
	movq	%rax, %rbx
	movl	%r8d, %eax
	shrq	$32, %rbx
	subl	%ebx, %edx
	shrl	%edx
	addl	%ebx, %edx
	shrl	$6, %edx
	imull	$97, %edx, %ebx
	subl	%ebx, %eax
	addq	%rax, %r11
.L33:
	leaq	1(%r9), %rbx
	leal	-1640531527(%rbx), %edx
	xorl	%edx, %r8d
	imull	$16777619, %r8d, %r8d
	movl	%r8d, %eax
	andl	$7, %eax
	cmpl	$2, %eax
	jbe	.L34
	movl	%r8d, %eax
	mull	%r10d
	movl	%r8d, %eax
	shrl	$6, %edx
	imull	$89, %edx, %edx
	subl	%edx, %eax
	addq	%rax, %rbx
	xorq	%rbx, %r11
.L35:
	leaq	2(%r9), %rbx
	leal	-1640531527(%rbx), %edx
	xorl	%edx, %r8d
	imull	$16777619, %r8d, %r8d
	movl	%r8d, %eax
	andl	$7, %eax
	cmpl	$2, %eax
	jbe	.L36
	movl	%r8d, %eax
	mull	%r10d
	movl	%r8d, %eax
	shrl	$6, %edx
	imull	$89, %edx, %edx
	subl	%edx, %eax
	addq	%rax, %rbx
	xorq	%rbx, %r11
.L37:
	addq	$3, %r9
	cmpq	%r9, %rcx
	je	.L1
.L5:
	leal	-1640531527(%r9), %edx
	xorl	%edx, %r8d
	imull	$16777619, %r8d, %r8d
	movl	%r8d, %eax
	andl	$7, %eax
	cmpl	$2, %eax
	jbe	.L39
	movl	%r8d, %eax
	mull	%r10d
	movl	%r8d, %eax
	shrl	$6, %edx
	imull	$89, %edx, %ebx
	subl	%ebx, %eax
	addq	%r9, %rax
	xorq	%rax, %r11
	jmp	.L4
	.p2align 4,,10
.L36:
	movl	%r8d, %ebx
	movl	%r8d, %edx
	imulq	$1372618415, %rbx, %rax
	movq	%rax, %rbx
	movl	%r8d, %eax
	shrq	$32, %rbx
	subl	%ebx, %edx
	shrl	%edx
	addl	%ebx, %edx
	shrl	$6, %edx
	imull	$97, %edx, %ebx
	subl	%ebx, %eax
	addq	%rax, %r11
	jmp	.L37
	.p2align 4,,10
.L34:
	movl	%r8d, %ebx
	movl	%r8d, %edx
	imulq	$1372618415, %rbx, %rax
	movq	%rax, %rbx
	movl	%r8d, %eax
	shrq	$32, %rbx
	subl	%ebx, %edx
	shrl	%edx
	addl	%ebx, %edx
	shrl	$6, %edx
	imull	$97, %edx, %ebx
	subl	%ebx, %eax
	addq	%rax, %r11
	jmp	.L35
	.p2align 4,,10
.L17:
	movl	%r8d, %eax
	mull	%r10d
	movl	%r8d, %eax
	shrl	$6, %edx
	imull	$89, %edx, %ebx
	subl	%ebx, %eax
	addq	%r9, %rax
	xorq	%rax, %r11
	jmp	.L33
.L31:
	movl	%r8d, %edx
	movl	%r8d, %eax
	imulq	$1372618415, %rdx, %rdx
	shrq	$32, %rdx
	subl	%edx, %eax
	shrl	%eax
	addl	%edx, %eax
	shrl	$6, %eax
	imull	$97, %eax, %edx
	movl	%r8d, %eax
	subl	%edx, %eax
	addq	%rax, %r11
	jmp	.L32
.L11:
	movl	%r8d, %eax
	mull	%r10d
	movl	%r8d, %eax
	shrl	$6, %edx
	imull	$89, %edx, %ebx
	subl	%ebx, %eax
	addq	%r9, %rax
	xorq	%rax, %r11
	jmp	.L30
.L6:
	xorl	%r11d, %r11d
	jmp	.L1
	.seh_endproc
	.p2align 4,,15
	.def	vector_kernel;	.scl	3;	.type	32;	.endef
	.seh_proc	vector_kernel
vector_kernel:
	pushq	%r12
	.seh_pushreg	%r12
	pushq	%rbp
	.seh_pushreg	%rbp
	pushq	%rdi
	.seh_pushreg	%rdi
	pushq	%rsi
	.seh_pushreg	%rsi
	pushq	%rbx
	.seh_pushreg	%rbx
	subq	$32, %rsp
	.seh_stackalloc	32
	.seh_endprologue
	leaq	0(,%rcx,4), %rdi
	movq	%rcx, %rbp
	movq	%rdi, %rcx
	call	malloc
	movq	%rdi, %rcx
	movq	%rax, %rsi
	call	malloc
	movq	%rdi, %rcx
	movq	%rax, %rbx
	call	malloc
	testq	%rsi, %rsi
	sete	%dl
	testq	%rbx, %rbx
	movq	%rax, %rdi
	sete	%al
	orb	%al, %dl
	jne	.L41
	testq	%rdi, %rdi
	je	.L41
	xorl	%r9d, %r9d
	xorl	%ecx, %ecx
	testq	%rbp, %rbp
	je	.L124
	leaq	-1(%rbp), %r8
	movabsq	$-9086255505087856445, %r11
	movabsq	$-9123216960442729871, %r10
	andl	$3, %r8d
	je	.L42
	cmpq	$1, %r8
	movl	$0, (%rsi)
	movl	$1, %ecx
	movl	$7, %r9d
	movl	$0, (%rbx)
	je	.L42
	cmpq	$2, %r8
	je	.L110
	movl	$1, (%rsi,%rcx,4)
	movl	$14, %r9d
	movl	$7, (%rbx,%rcx,4)
	movl	$2, %ecx
.L110:
	movq	%rcx, %rax
	movq	%rcx, %r8
	mulq	%r11
	movq	%r9, %rax
	shrq	$9, %rdx
	imulq	$1009, %rdx, %r12
	mulq	%r10
	subq	%r12, %r8
	shrq	$9, %rdx
	movl	%r8d, (%rsi,%rcx,4)
	movq	%r9, %r8
	addq	$7, %r9
	imulq	$1013, %rdx, %r12
	subq	%r12, %r8
	movl	%r8d, (%rbx,%rcx,4)
	addq	$1, %rcx
	jmp	.L42
	.p2align 4,,10
.L57:
	movq	%r8, %rax
	mulq	%r11
	movq	%r8, %rax
	shrq	$9, %rdx
	imulq	$1009, %rdx, %rdx
	subq	%rdx, %rax
	movl	%eax, (%rsi,%r8,4)
	movq	%r12, %rax
	mulq	%r10
	shrq	$9, %rdx
	imulq	$1013, %rdx, %rax
	subq	%rax, %r12
	movl	%r12d, (%rbx,%r8,4)
	leaq	2(%rcx), %r8
	leaq	14(%r9), %r12
	movq	%r8, %rax
	mulq	%r11
	movq	%r8, %rax
	shrq	$9, %rdx
	imulq	$1009, %rdx, %rdx
	subq	%rdx, %rax
	movl	%eax, (%rsi,%r8,4)
	movq	%r12, %rax
	mulq	%r10
	shrq	$9, %rdx
	imulq	$1013, %rdx, %rax
	subq	%rax, %r12
	movl	%r12d, (%rbx,%r8,4)
	leaq	3(%rcx), %r8
	addq	$4, %rcx
	leaq	21(%r9), %r12
	movq	%r8, %rax
	addq	$28, %r9
	mulq	%r11
	movq	%r8, %rax
	shrq	$9, %rdx
	imulq	$1009, %rdx, %rdx
	subq	%rdx, %rax
	movl	%eax, (%rsi,%r8,4)
	movq	%r12, %rax
	mulq	%r10
	shrq	$9, %rdx
	imulq	$1013, %rdx, %rax
	subq	%rax, %r12
	movl	%r12d, (%rbx,%r8,4)
.L42:
	movq	%rcx, %rax
	movq	%rcx, %r8
	mulq	%r11
	movq	%r9, %rax
	shrq	$9, %rdx
	imulq	$1009, %rdx, %r12
	mulq	%r10
	subq	%r12, %r8
	shrq	$9, %rdx
	movl	%r8d, (%rsi,%rcx,4)
	movq	%r9, %r8
	imulq	$1013, %rdx, %r12
	subq	%r12, %r8
	movl	%r8d, (%rbx,%rcx,4)
	leaq	1(%rcx), %r8
	leaq	7(%r9), %r12
	cmpq	%r8, %rbp
	jne	.L57
	cmpq	$2, %rcx
	jbe	.L58
	movq	%r8, %r10
	xorl	%r9d, %r9d
	shrq	$2, %r10
	salq	$4, %r10
	leaq	-16(%r10), %r11
	shrq	$4, %r11
	addq	$1, %r11
	andl	$3, %r11d
	je	.L46
	cmpq	$1, %r11
	je	.L102
	cmpq	$2, %r11
	jne	.L130
.L103:
	movdqu	(%rsi,%r9), %xmm4
	movdqu	(%rbx,%r9), %xmm0
	movdqa	%xmm4, %xmm5
	movdqa	%xmm0, %xmm1
	pslld	$1, %xmm5
	pslld	$2, %xmm1
	paddd	%xmm4, %xmm5
	paddd	%xmm0, %xmm1
	paddd	%xmm1, %xmm5
	movups	%xmm5, (%rdi,%r9)
	addq	$16, %r9
.L102:
	movdqu	(%rsi,%r9), %xmm2
	movdqu	(%rbx,%r9), %xmm4
	movdqa	%xmm2, %xmm3
	movdqa	%xmm4, %xmm5
	pslld	$1, %xmm3
	pslld	$2, %xmm5
	paddd	%xmm2, %xmm3
	paddd	%xmm4, %xmm5
	paddd	%xmm5, %xmm3
	movups	%xmm3, (%rdi,%r9)
	addq	$16, %r9
	cmpq	%r10, %r9
	je	.L129
.L46:
	movdqu	(%rsi,%r9), %xmm1
	movdqu	(%rbx,%r9), %xmm2
	movdqa	%xmm1, %xmm0
	movdqu	16(%rsi,%r9), %xmm4
	movdqa	%xmm2, %xmm3
	pslld	$1, %xmm0
	pslld	$2, %xmm3
	paddd	%xmm1, %xmm0
	movdqa	%xmm4, %xmm5
	paddd	%xmm2, %xmm3
	pslld	$1, %xmm5
	movdqu	32(%rsi,%r9), %xmm2
	paddd	%xmm3, %xmm0
	paddd	%xmm4, %xmm5
	movdqu	32(%rbx,%r9), %xmm4
	movups	%xmm0, (%rdi,%r9)
	movdqu	16(%rbx,%r9), %xmm0
	movdqa	%xmm2, %xmm3
	pslld	$1, %xmm3
	movdqa	%xmm0, %xmm1
	paddd	%xmm2, %xmm3
	movdqu	48(%rbx,%r9), %xmm2
	pslld	$2, %xmm1
	paddd	%xmm0, %xmm1
	paddd	%xmm1, %xmm5
	movdqu	48(%rsi,%r9), %xmm1
	movups	%xmm5, 16(%rdi,%r9)
	movdqa	%xmm4, %xmm5
	pslld	$2, %xmm5
	movdqa	%xmm1, %xmm0
	paddd	%xmm4, %xmm5
	pslld	$1, %xmm0
	paddd	%xmm5, %xmm3
	paddd	%xmm1, %xmm0
	movups	%xmm3, 32(%rdi,%r9)
	movdqa	%xmm2, %xmm3
	pslld	$2, %xmm3
	paddd	%xmm2, %xmm3
	paddd	%xmm3, %xmm0
	movups	%xmm0, 48(%rdi,%r9)
	addq	$64, %r9
	cmpq	%r10, %r9
	jne	.L46
.L129:
	movq	%r8, %rbp
	andq	$-4, %rbp
	cmpq	%rbp, %r8
	je	.L47
.L45:
	imull	$3, (%rsi,%rbp,4), %eax
	leaq	1(%rbp), %r12
	imull	$5, (%rbx,%rbp,4), %edx
	addl	%edx, %eax
	cmpq	%r12, %r8
	movl	%eax, (%rdi,%rbp,4)
	jbe	.L48
	imull	$3, (%rsi,%r12,4), %r11d
	addq	$2, %rbp
	imull	$5, (%rbx,%r12,4), %r10d
	addl	%r10d, %r11d
	cmpq	%rbp, %r8
	movl	%r11d, (%rdi,%r12,4)
	jbe	.L49
	imull	$3, (%rsi,%rbp,4), %eax
	imull	$5, (%rbx,%rbp,4), %r9d
	addl	%r9d, %eax
	movl	%eax, (%rdi,%rbp,4)
.L49:
	cmpq	$2, %rcx
	jbe	.L131
.L47:
	movq	%r8, %rdx
	movq	%rdi, %r11
	pxor	%xmm1, %xmm1
	pxor	%xmm5, %xmm5
	shrq	$2, %rdx
	salq	$4, %rdx
	leaq	(%rdx,%rdi), %r12
	subq	$16, %rdx
	shrq	$4, %rdx
	addq	$1, %rdx
	andl	$7, %edx
	je	.L51
	cmpq	$1, %rdx
	je	.L104
	cmpq	$2, %rdx
	je	.L105
	cmpq	$3, %rdx
	je	.L106
	cmpq	$4, %rdx
	je	.L107
	cmpq	$5, %rdx
	je	.L108
	cmpq	$6, %rdx
	je	.L109
	movdqu	(%rdi), %xmm1
	leaq	16(%rdi), %r11
	movdqa	%xmm1, %xmm4
	punpckldq	%xmm5, %xmm1
	punpckhdq	%xmm5, %xmm4
	paddq	%xmm4, %xmm1
.L109:
	movdqu	(%r11), %xmm0
	addq	$16, %r11
	movdqa	%xmm0, %xmm2
	punpckldq	%xmm5, %xmm0
	punpckhdq	%xmm5, %xmm2
	paddq	%xmm2, %xmm0
	paddq	%xmm0, %xmm1
.L108:
	movdqu	(%r11), %xmm4
	addq	$16, %r11
	movdqa	%xmm4, %xmm3
	punpckldq	%xmm5, %xmm4
	punpckhdq	%xmm5, %xmm3
	paddq	%xmm3, %xmm4
	paddq	%xmm4, %xmm1
.L107:
	movdqu	(%r11), %xmm0
	addq	$16, %r11
	movdqa	%xmm0, %xmm2
	punpckldq	%xmm5, %xmm0
	punpckhdq	%xmm5, %xmm2
	paddq	%xmm2, %xmm0
	paddq	%xmm0, %xmm1
.L106:
	movdqu	(%r11), %xmm4
	addq	$16, %r11
	movdqa	%xmm4, %xmm3
	punpckldq	%xmm5, %xmm4
	punpckhdq	%xmm5, %xmm3
	paddq	%xmm3, %xmm4
	paddq	%xmm4, %xmm1
.L105:
	movdqu	(%r11), %xmm0
	addq	$16, %r11
	movdqa	%xmm0, %xmm2
	punpckldq	%xmm5, %xmm0
	punpckhdq	%xmm5, %xmm2
	paddq	%xmm2, %xmm0
	paddq	%xmm0, %xmm1
.L104:
	movdqu	(%r11), %xmm4
	addq	$16, %r11
	cmpq	%r12, %r11
	movdqa	%xmm4, %xmm3
	punpckldq	%xmm5, %xmm4
	punpckhdq	%xmm5, %xmm3
	paddq	%xmm3, %xmm4
	paddq	%xmm4, %xmm1
	je	.L128
.L51:
	movdqu	(%r11), %xmm0
	subq	$-128, %r11
	movdqu	-112(%r11), %xmm4
	movdqa	%xmm0, %xmm2
	punpckldq	%xmm5, %xmm0
	punpckhdq	%xmm5, %xmm2
	paddq	%xmm2, %xmm0
	movdqa	%xmm4, %xmm3
	punpckldq	%xmm5, %xmm4
	paddq	%xmm0, %xmm1
	movdqu	-96(%r11), %xmm0
	punpckhdq	%xmm5, %xmm3
	paddq	%xmm3, %xmm4
	paddq	%xmm4, %xmm1
	movdqu	-80(%r11), %xmm4
	movdqa	%xmm0, %xmm2
	punpckldq	%xmm5, %xmm0
	punpckhdq	%xmm5, %xmm2
	paddq	%xmm2, %xmm0
	movdqa	%xmm4, %xmm3
	punpckldq	%xmm5, %xmm4
	paddq	%xmm0, %xmm1
	movdqu	-64(%r11), %xmm0
	punpckhdq	%xmm5, %xmm3
	paddq	%xmm3, %xmm4
	paddq	%xmm4, %xmm1
	movdqu	-48(%r11), %xmm4
	movdqa	%xmm0, %xmm2
	punpckldq	%xmm5, %xmm0
	punpckhdq	%xmm5, %xmm2
	paddq	%xmm0, %xmm2
	movdqu	-32(%r11), %xmm0
	movdqa	%xmm4, %xmm3
	paddq	%xmm2, %xmm1
	punpckhdq	%xmm5, %xmm3
	punpckldq	%xmm5, %xmm4
	paddq	%xmm3, %xmm4
	movdqa	%xmm0, %xmm2
	paddq	%xmm4, %xmm1
	punpckldq	%xmm5, %xmm0
	punpckhdq	%xmm5, %xmm2
	paddq	%xmm2, %xmm0
	paddq	%xmm1, %xmm0
	movdqu	-16(%r11), %xmm1
	cmpq	%r12, %r11
	movdqa	%xmm1, %xmm4
	punpckldq	%xmm5, %xmm1
	punpckhdq	%xmm5, %xmm4
	paddq	%xmm4, %xmm1
	paddq	%xmm0, %xmm1
	jne	.L51
.L128:
	movdqa	%xmm1, %xmm5
	movq	%r8, %rcx
	psrldq	$8, %xmm5
	andq	$-4, %rcx
	paddq	%xmm5, %xmm1
	cmpq	%rcx, %r8
	movq	%xmm1, %rbp
	je	.L43
.L50:
	movl	(%rdi,%rcx,4), %r10d
	addq	$1, %rcx
	addq	%r10, %rbp
	cmpq	%r8, %rcx
	jnb	.L43
.L54:
	movl	(%rdi,%rcx,4), %eax
	addq	$1, %rcx
	addq	%rax, %rbp
	cmpq	%r8, %rcx
	jnb	.L43
	movl	(%rdi,%rcx,4), %r9d
	addq	%r9, %rbp
.L43:
	movq	%rsi, %rcx
	call	free
	movq	%rbx, %rcx
	call	free
	movq	%rdi, %rcx
	call	free
.L40:
	movq	%rbp, %rax
	addq	$32, %rsp
	popq	%rbx
	popq	%rsi
	popq	%rdi
	popq	%rbp
	popq	%r12
	ret
.L41:
	movq	%rsi, %rcx
	orq	$-1, %rbp
	call	free
	movq	%rbx, %rcx
	call	free
	movq	%rdi, %rcx
	call	free
	jmp	.L40
.L130:
	movdqu	(%rsi), %xmm1
	movl	$16, %r9d
	movdqu	(%rbx), %xmm2
	movdqa	%xmm1, %xmm0
	movdqa	%xmm2, %xmm3
	pslld	$1, %xmm0
	pslld	$2, %xmm3
	paddd	%xmm1, %xmm0
	paddd	%xmm2, %xmm3
	paddd	%xmm3, %xmm0
	movups	%xmm0, (%rdi)
	jmp	.L103
.L131:
	movl	(%rdi), %ebp
	movl	$1, %ecx
	jmp	.L54
.L48:
	cmpq	$2, %rcx
	ja	.L47
	xorl	%ecx, %ecx
	xorl	%ebp, %ebp
	jmp	.L50
.L124:
	xorl	%ebp, %ebp
	jmp	.L43
.L58:
	xorl	%ebp, %ebp
	jmp	.L45
	.seh_endproc
	.def	__main;	.scl	2;	.type	32;	.endef
	.section .rdata,"dr"
	.align 8
.LC0:
	.ascii "usage: %s <branch|vector> <positive-size>\12\0"
	.align 8
.LC1:
	.ascii "size must be a positive integer within size_t range\12\0"
.LC2:
	.ascii "branch\0"
.LC3:
	.ascii "vector\0"
.LC4:
	.ascii "allocation failed\12\0"
.LC5:
	.ascii "unknown kernel: %s\12\0"
.LC6:
	.ascii "%I64u\12\0"
	.section	.text.startup,"x"
	.p2align 4,,15
	.globl	main
	.def	main;	.scl	2;	.type	32;	.endef
	.seh_proc	main
main:
	pushq	%rsi
	.seh_pushreg	%rsi
	pushq	%rbx
	.seh_pushreg	%rbx
	subq	$56, %rsp
	.seh_stackalloc	56
	.seh_endprologue
	movl	%ecx, %esi
	movq	%rdx, %rbx
	call	__main
	cmpl	$3, %esi
	movq	$0, 40(%rsp)
	jne	.L141
	movq	16(%rbx), %rcx
	leaq	40(%rsp), %rdx
	movl	$10, %r8d
	call	strtoull
	movq	%rax, %rsi
	movq	40(%rsp), %rax
	cmpq	%rax, 16(%rbx)
	je	.L135
	cmpb	$0, (%rax)
	jne	.L135
	testq	%rsi, %rsi
	je	.L135
	movq	8(%rbx), %rbx
	leaq	.LC2(%rip), %rdx
	movq	%rbx, %rcx
	call	strcmp
	testl	%eax, %eax
	je	.L142
	leaq	.LC3(%rip), %rdx
	movq	%rbx, %rcx
	call	strcmp
	testl	%eax, %eax
	jne	.L140
	movq	%rsi, %rcx
	call	vector_kernel
	cmpq	$-1, %rax
	je	.L143
.L139:
	leaq	.LC6(%rip), %rcx
	movq	%rax, %rdx
	call	printf
	xorl	%eax, %eax
	jmp	.L132
.L135:
	movl	$2, %ecx
	call	*__imp___acrt_iob_func(%rip)
	movl	$52, %r8d
	movl	$1, %edx
	leaq	.LC1(%rip), %rcx
	movq	%rax, %r9
	call	fwrite
	movl	$2, %eax
.L132:
	addq	$56, %rsp
	popq	%rbx
	popq	%rsi
	ret
.L141:
	movq	(%rbx), %rsi
	movl	$2, %ecx
	call	*__imp___acrt_iob_func(%rip)
	leaq	.LC0(%rip), %rdx
	movq	%rax, %rcx
	movq	%rsi, %r8
	call	fprintf
	movl	$2, %eax
	jmp	.L132
.L142:
	movq	%rsi, %rcx
	call	branch_kernel
	jmp	.L139
.L140:
	movl	$2, %ecx
	call	*__imp___acrt_iob_func(%rip)
	leaq	.LC5(%rip), %rdx
	movq	%rbx, %r8
	movq	%rax, %rcx
	call	fprintf
	movl	$2, %eax
	jmp	.L132
.L143:
	movl	$2, %ecx
	call	*__imp___acrt_iob_func(%rip)
	movl	$18, %r8d
	movl	$1, %edx
	leaq	.LC4(%rip), %rcx
	movq	%rax, %r9
	call	fwrite
	movl	$3, %eax
	jmp	.L132
	.seh_endproc
	.ident	"GCC: (x86_64-posix-seh-rev0, Built by MinGW-W64 project) 8.1.0"
	.def	malloc;	.scl	2;	.type	32;	.endef
	.def	free;	.scl	2;	.type	32;	.endef
	.def	strtoull;	.scl	2;	.type	32;	.endef
	.def	strcmp;	.scl	2;	.type	32;	.endef
	.def	printf;	.scl	2;	.type	32;	.endef
	.def	fwrite;	.scl	2;	.type	32;	.endef
	.def	fprintf;	.scl	2;	.type	32;	.endef
