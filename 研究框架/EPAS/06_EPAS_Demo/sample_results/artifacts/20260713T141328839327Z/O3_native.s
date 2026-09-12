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
	xorl	%r9d, %r9d
	movl	$-2128831035, %r8d
	xorl	%r10d, %r10d
	movl	$-1206451487, %ebx
	movl	$1372618415, %r11d
	jmp	.L5
	.p2align 4,,10
.L10:
	mull	%r11d
	movl	%r8d, %eax
	subl	%edx, %eax
	shrl	%eax
	addl	%eax, %edx
	shrl	$6, %edx
	imull	$97, %edx, %edx
	movl	%r8d, %eax
	subl	%edx, %eax
	addq	%rax, %r10
	incq	%r9
	cmpq	%r9, %rcx
	je	.L8
.L5:
	leal	-1640531527(%r9), %eax
	xorl	%eax, %r8d
	imull	$16777619, %r8d, %r8d
	movl	%r8d, %eax
	andl	$7, %eax
	cmpl	$2, %eax
	movl	%r8d, %eax
	jbe	.L10
	mull	%ebx
	shrl	$6, %edx
	imull	$89, %edx, %edx
	movl	%r8d, %eax
	subl	%edx, %eax
	addq	%r9, %rax
	xorq	%rax, %r10
	incq	%r9
	cmpq	%r9, %rcx
	jne	.L5
.L8:
	movq	%r10, %rax
	popq	%rbx
	ret
.L6:
	xorl	%r10d, %r10d
	jmp	.L8
	.seh_endproc
	.p2align 4,,15
	.def	vector_kernel;	.scl	3;	.type	32;	.endef
	.seh_proc	vector_kernel
vector_kernel:
	pushq	%rbp
	.seh_pushreg	%rbp
	pushq	%rdi
	.seh_pushreg	%rdi
	pushq	%rsi
	.seh_pushreg	%rsi
	pushq	%rbx
	.seh_pushreg	%rbx
	subq	$40, %rsp
	.seh_stackalloc	40
	.seh_endprologue
	movq	%rcx, %rbp
	leaq	0(,%rcx,4), %rdi
	movq	%rdi, %rcx
	call	malloc
	movq	%rax, %rbx
	movq	%rdi, %rcx
	call	malloc
	movq	%rax, %rsi
	movq	%rdi, %rcx
	call	malloc
	movq	%rax, %rdi
	testq	%rbx, %rbx
	sete	%dl
	testq	%rsi, %rsi
	sete	%al
	orb	%al, %dl
	jne	.L12
	testq	%rdi, %rdi
	je	.L12
	xorl	%r8d, %r8d
	xorl	%ecx, %ecx
	movabsq	$-9086255505087856445, %r10
	movabsq	$-9123216960442729871, %r9
	testq	%rbp, %rbp
	jne	.L13
	jmp	.L14
	.p2align 4,,10
.L28:
	movq	%rdx, %rcx
.L13:
	movq	%rcx, %rax
	mulq	%r10
	shrq	$9, %rdx
	imulq	$1009, %rdx, %rdx
	movq	%rcx, %rax
	subq	%rdx, %rax
	movl	%eax, (%rbx,%rcx,4)
	movq	%r8, %rax
	mulq	%r9
	shrq	$9, %rdx
	imulq	$1013, %rdx, %rdx
	movq	%r8, %rax
	subq	%rdx, %rax
	movl	%eax, (%rsi,%rcx,4)
	leaq	1(%rcx), %rdx
	addq	$7, %r8
	cmpq	%rdx, %rbp
	jne	.L28
	cmpq	$6, %rcx
	jbe	.L29
	movq	%rdx, %r8
	shrq	$3, %r8
	salq	$5, %r8
	xorl	%eax, %eax
	.p2align 4,,10
.L17:
	vmovdqu	(%rbx,%rax), %ymm1
	vpslld	$1, %ymm1, %ymm0
	vpaddd	%ymm1, %ymm0, %ymm0
	vmovdqu	(%rsi,%rax), %ymm2
	vpslld	$2, %ymm2, %ymm1
	vpaddd	%ymm2, %ymm1, %ymm1
	vpaddd	%ymm1, %ymm0, %ymm0
	vmovdqu	%ymm0, (%rdi,%rax)
	addq	$32, %rax
	cmpq	%r8, %rax
	jne	.L17
	movq	%rdx, %rax
	andq	$-8, %rax
	cmpq	%rax, %rdx
	je	.L18
.L16:
	imull	$3, (%rbx,%rax,4), %r8d
	imull	$5, (%rsi,%rax,4), %r9d
	addl	%r9d, %r8d
	movl	%r8d, (%rdi,%rax,4)
	leaq	1(%rax), %r8
	cmpq	%r8, %rdx
	jbe	.L19
	imull	$3, (%rbx,%r8,4), %r9d
	imull	$5, (%rsi,%r8,4), %r10d
	addl	%r10d, %r9d
	movl	%r9d, (%rdi,%r8,4)
	leaq	2(%rax), %r8
	cmpq	%r8, %rdx
	jbe	.L20
	imull	$3, (%rbx,%r8,4), %r9d
	imull	$5, (%rsi,%r8,4), %r10d
	addl	%r10d, %r9d
	movl	%r9d, (%rdi,%r8,4)
	leaq	3(%rax), %r8
	cmpq	%r8, %rdx
	jbe	.L20
	imull	$3, (%rbx,%r8,4), %r9d
	imull	$5, (%rsi,%r8,4), %r10d
	addl	%r10d, %r9d
	movl	%r9d, (%rdi,%r8,4)
	leaq	4(%rax), %r8
	cmpq	%r8, %rdx
	jbe	.L20
	imull	$3, (%rbx,%r8,4), %r9d
	imull	$5, (%rsi,%r8,4), %r10d
	addl	%r10d, %r9d
	movl	%r9d, (%rdi,%r8,4)
	leaq	5(%rax), %r8
	cmpq	%r8, %rdx
	jbe	.L20
	imull	$3, (%rbx,%r8,4), %r9d
	imull	$5, (%rsi,%r8,4), %r10d
	addl	%r10d, %r9d
	movl	%r9d, (%rdi,%r8,4)
	addq	$6, %rax
	cmpq	%rax, %rdx
	jbe	.L20
	imull	$3, (%rbx,%rax,4), %r8d
	imull	$5, (%rsi,%rax,4), %r9d
	addl	%r9d, %r8d
	movl	%r8d, (%rdi,%rax,4)
.L20:
	cmpq	$6, %rcx
	jbe	.L41
.L18:
	movq	%rdi, %rax
	movq	%rdx, %rcx
	shrq	$3, %rcx
	salq	$5, %rcx
	addq	%rdi, %rcx
	vpxor	%xmm2, %xmm2, %xmm2
	.p2align 4,,10
.L22:
	vmovdqu	(%rax), %ymm0
	vextracti128	$0x1, %ymm0, %xmm1
	vpmovzxdq	%xmm1, %ymm1
	vpmovzxdq	%xmm0, %ymm0
	vpaddq	%ymm0, %ymm1, %ymm0
	vpaddq	%ymm0, %ymm2, %ymm2
	addq	$32, %rax
	cmpq	%rcx, %rax
	jne	.L22
	vextracti128	$1, %ymm2, %xmm0
	vpaddq	%xmm2, %xmm0, %xmm2
	vpsrldq	$8, %xmm2, %xmm0
	vpaddq	%xmm0, %xmm2, %xmm2
	vmovq	%xmm2, %rbp
	movq	%rdx, %rax
	andq	$-8, %rax
	cmpq	%rax, %rdx
	je	.L39
.L21:
	movl	(%rdi,%rax,4), %ecx
	addq	%rcx, %rbp
	incq	%rax
	cmpq	%rdx, %rax
	jnb	.L39
.L25:
	movl	(%rdi,%rax,4), %ecx
	addq	%rcx, %rbp
	leaq	1(%rax), %rcx
	cmpq	%rdx, %rcx
	jnb	.L39
	movl	(%rdi,%rcx,4), %ecx
	addq	%rcx, %rbp
	leaq	2(%rax), %rcx
	cmpq	%rcx, %rdx
	jbe	.L39
	movl	(%rdi,%rcx,4), %ecx
	addq	%rcx, %rbp
	leaq	3(%rax), %rcx
	cmpq	%rcx, %rdx
	jbe	.L39
	movl	(%rdi,%rcx,4), %ecx
	addq	%rcx, %rbp
	leaq	4(%rax), %rcx
	cmpq	%rcx, %rdx
	jbe	.L39
	movl	(%rdi,%rcx,4), %ecx
	addq	%rcx, %rbp
	addq	$5, %rax
	cmpq	%rax, %rdx
	jbe	.L39
	movl	(%rdi,%rax,4), %eax
	addq	%rax, %rbp
	vzeroupper
.L14:
	movq	%rbx, %rcx
	call	free
	movq	%rsi, %rcx
	call	free
	movq	%rdi, %rcx
	call	free
.L40:
	movq	%rbp, %rax
	addq	$40, %rsp
	popq	%rbx
	popq	%rsi
	popq	%rdi
	popq	%rbp
	ret
.L39:
	vzeroupper
	jmp	.L14
.L12:
	movq	%rbx, %rcx
	call	free
	movq	%rsi, %rcx
	call	free
	movq	%rdi, %rcx
	call	free
	orq	$-1, %rbp
	jmp	.L40
.L41:
	movl	(%rdi), %ebp
	movl	$1, %eax
	jmp	.L25
.L29:
	xorl	%eax, %eax
	jmp	.L16
.L19:
	cmpq	$6, %rcx
	ja	.L18
	xorl	%eax, %eax
	xorl	%ebp, %ebp
	jmp	.L21
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
	movq	$0, 40(%rsp)
	cmpl	$3, %esi
	jne	.L52
	leaq	40(%rsp), %rdx
	movq	16(%rbx), %rcx
	movl	$10, %r8d
	call	strtoull
	movq	%rax, %rsi
	movq	40(%rsp), %rax
	cmpq	%rax, 16(%rbx)
	je	.L45
	cmpb	$0, (%rax)
	jne	.L45
	testq	%rsi, %rsi
	je	.L45
	movq	8(%rbx), %rbx
	leaq	.LC2(%rip), %rdx
	movq	%rbx, %rcx
	call	strcmp
	testl	%eax, %eax
	je	.L53
	leaq	.LC3(%rip), %rdx
	movq	%rbx, %rcx
	call	strcmp
	testl	%eax, %eax
	jne	.L50
	movq	%rsi, %rcx
	call	vector_kernel
	cmpq	$-1, %rax
	je	.L54
.L49:
	movq	%rax, %rdx
	leaq	.LC6(%rip), %rcx
	call	printf
	xorl	%eax, %eax
	jmp	.L51
.L45:
	movl	$2, %ecx
	call	*__imp___acrt_iob_func(%rip)
	movq	%rax, %r9
	movl	$52, %r8d
	movl	$1, %edx
	leaq	.LC1(%rip), %rcx
	call	fwrite
	movl	$2, %eax
.L51:
	addq	$56, %rsp
	popq	%rbx
	popq	%rsi
	ret
.L52:
	movq	(%rbx), %rbx
	movl	$2, %ecx
	call	*__imp___acrt_iob_func(%rip)
	movq	%rbx, %r8
	leaq	.LC0(%rip), %rdx
	movq	%rax, %rcx
	call	fprintf
	movl	$2, %eax
	jmp	.L51
.L53:
	movq	%rsi, %rcx
	call	branch_kernel
	jmp	.L49
.L50:
	movl	$2, %ecx
	call	*__imp___acrt_iob_func(%rip)
	movq	%rbx, %r8
	leaq	.LC5(%rip), %rdx
	movq	%rax, %rcx
	call	fprintf
	movl	$2, %eax
	jmp	.L51
.L54:
	movl	$2, %ecx
	call	*__imp___acrt_iob_func(%rip)
	movq	%rax, %r9
	movl	$18, %r8d
	movl	$1, %edx
	leaq	.LC4(%rip), %rcx
	call	fwrite
	movl	$3, %eax
	jmp	.L51
	.seh_endproc
	.ident	"GCC: (x86_64-posix-seh-rev0, Built by MinGW-W64 project) 8.1.0"
	.def	malloc;	.scl	2;	.type	32;	.endef
	.def	free;	.scl	2;	.type	32;	.endef
	.def	strtoull;	.scl	2;	.type	32;	.endef
	.def	strcmp;	.scl	2;	.type	32;	.endef
	.def	printf;	.scl	2;	.type	32;	.endef
	.def	fwrite;	.scl	2;	.type	32;	.endef
	.def	fprintf;	.scl	2;	.type	32;	.endef
