	.file	"bench.c"
	.text
	.p2align 4,,15
	.def	branch_kernel;	.scl	3;	.type	32;	.endef
	.seh_proc	branch_kernel
branch_kernel:
	.seh_endprologue
	testq	%rcx, %rcx
	je	.L6
	xorl	%r9d, %r9d
	movl	$-2128831035, %r8d
	xorl	%r10d, %r10d
	movl	$-1206451487, %r11d
	jmp	.L5
	.p2align 4,,10
.L9:
	movl	%r8d, %eax
	addq	$1, %r9
	imulq	$1372618415, %rax, %rax
	shrq	$32, %rax
	movq	%rax, %rdx
	movl	%r8d, %eax
	subl	%edx, %eax
	shrl	%eax
	addl	%edx, %eax
	movl	%r8d, %edx
	shrl	$6, %eax
	imull	$97, %eax, %eax
	subl	%eax, %edx
	addq	%rdx, %r10
	cmpq	%r9, %rcx
	je	.L1
.L5:
	leal	-1640531527(%r9), %eax
	xorl	%eax, %r8d
	imull	$16777619, %r8d, %r8d
	movl	%r8d, %eax
	andl	$7, %eax
	cmpl	$2, %eax
	jbe	.L9
	movl	%r8d, %eax
	mull	%r11d
	movl	%r8d, %eax
	shrl	$6, %edx
	imull	$89, %edx, %edx
	subl	%edx, %eax
	addq	%r9, %rax
	addq	$1, %r9
	xorq	%rax, %r10
	cmpq	%r9, %rcx
	jne	.L5
.L1:
	movq	%r10, %rax
	ret
.L6:
	xorl	%r10d, %r10d
	jmp	.L1
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
	leaq	0(,%rcx,4), %rdi
	movq	%rcx, %rbp
	movq	%rdi, %rcx
	call	malloc
	movq	%rdi, %rcx
	movq	%rax, %rbx
	call	malloc
	movq	%rdi, %rcx
	movq	%rax, %rsi
	call	malloc
	testq	%rbx, %rbx
	sete	%dl
	testq	%rsi, %rsi
	movq	%rax, %rdi
	sete	%al
	orb	%al, %dl
	jne	.L11
	testq	%rdi, %rdi
	je	.L11
	movabsq	$-9086255505087856445, %r10
	xorl	%r8d, %r8d
	xorl	%ecx, %ecx
	movabsq	$-9123216960442729871, %r9
	testq	%rbp, %rbp
	jne	.L12
	jmp	.L13
	.p2align 4,,10
.L27:
	movq	%rdx, %rcx
.L12:
	movq	%rcx, %rax
	mulq	%r10
	movq	%rcx, %rax
	shrq	$9, %rdx
	imulq	$1009, %rdx, %rdx
	subq	%rdx, %rax
	movl	%eax, (%rbx,%rcx,4)
	movq	%r8, %rax
	mulq	%r9
	movq	%r8, %rax
	addq	$7, %r8
	shrq	$9, %rdx
	imulq	$1013, %rdx, %rdx
	subq	%rdx, %rax
	leaq	1(%rcx), %rdx
	movl	%eax, (%rsi,%rcx,4)
	cmpq	%rdx, %rbp
	jne	.L27
	cmpq	$2, %rcx
	jbe	.L28
	movq	%rdx, %r8
	xorl	%eax, %eax
	shrq	$2, %r8
	salq	$4, %r8
	.p2align 4,,10
.L16:
	movdqu	(%rbx,%rax), %xmm1
	movdqu	(%rsi,%rax), %xmm2
	movdqa	%xmm1, %xmm0
	pslld	$1, %xmm0
	paddd	%xmm1, %xmm0
	movdqa	%xmm2, %xmm1
	pslld	$2, %xmm1
	paddd	%xmm2, %xmm1
	paddd	%xmm1, %xmm0
	movups	%xmm0, (%rdi,%rax)
	addq	$16, %rax
	cmpq	%r8, %rax
	jne	.L16
	movq	%rdx, %rax
	andq	$-4, %rax
	cmpq	%rax, %rdx
	je	.L17
.L15:
	imull	$3, (%rbx,%rax,4), %r8d
	imull	$5, (%rsi,%rax,4), %r9d
	addl	%r9d, %r8d
	movl	%r8d, (%rdi,%rax,4)
	leaq	1(%rax), %r8
	cmpq	%r8, %rdx
	jbe	.L18
	imull	$3, (%rbx,%r8,4), %r9d
	addq	$2, %rax
	imull	$5, (%rsi,%r8,4), %r10d
	addl	%r10d, %r9d
	cmpq	%rax, %rdx
	movl	%r9d, (%rdi,%r8,4)
	jbe	.L19
	imull	$3, (%rbx,%rax,4), %r8d
	imull	$5, (%rsi,%rax,4), %r9d
	addl	%r9d, %r8d
	movl	%r8d, (%rdi,%rax,4)
.L19:
	cmpq	$2, %rcx
	jbe	.L33
.L17:
	movq	%rdx, %rcx
	movq	%rdi, %rax
	pxor	%xmm1, %xmm1
	pxor	%xmm2, %xmm2
	shrq	$2, %rcx
	salq	$4, %rcx
	addq	%rdi, %rcx
	.p2align 4,,10
.L21:
	movdqu	(%rax), %xmm0
	addq	$16, %rax
	cmpq	%rcx, %rax
	movdqa	%xmm0, %xmm3
	punpckldq	%xmm2, %xmm0
	punpckhdq	%xmm2, %xmm3
	paddq	%xmm3, %xmm0
	paddq	%xmm0, %xmm1
	jne	.L21
	movdqa	%xmm1, %xmm0
	movq	%rdx, %rax
	psrldq	$8, %xmm0
	andq	$-4, %rax
	paddq	%xmm0, %xmm1
	cmpq	%rax, %rdx
	movq	%xmm1, %rbp
	je	.L13
.L20:
	movl	(%rdi,%rax,4), %ecx
	addq	$1, %rax
	addq	%rcx, %rbp
	cmpq	%rdx, %rax
	jnb	.L13
.L24:
	movl	(%rdi,%rax,4), %ecx
	addq	$1, %rax
	addq	%rcx, %rbp
	cmpq	%rdx, %rax
	jnb	.L13
	movl	(%rdi,%rax,4), %eax
	addq	%rax, %rbp
.L13:
	movq	%rbx, %rcx
	call	free
	movq	%rsi, %rcx
	call	free
	movq	%rdi, %rcx
	call	free
.L10:
	movq	%rbp, %rax
	addq	$40, %rsp
	popq	%rbx
	popq	%rsi
	popq	%rdi
	popq	%rbp
	ret
.L11:
	movq	%rbx, %rcx
	orq	$-1, %rbp
	call	free
	movq	%rsi, %rcx
	call	free
	movq	%rdi, %rcx
	call	free
	jmp	.L10
.L33:
	movl	(%rdi), %ebp
	movl	$1, %eax
	jmp	.L24
.L18:
	cmpq	$2, %rcx
	ja	.L17
	xorl	%eax, %eax
	xorl	%ebp, %ebp
	jmp	.L20
.L28:
	xorl	%eax, %eax
	jmp	.L15
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
	jne	.L43
	movq	16(%rbx), %rcx
	leaq	40(%rsp), %rdx
	movl	$10, %r8d
	call	strtoull
	movq	%rax, %rsi
	movq	40(%rsp), %rax
	cmpq	%rax, 16(%rbx)
	je	.L37
	cmpb	$0, (%rax)
	jne	.L37
	testq	%rsi, %rsi
	je	.L37
	movq	8(%rbx), %rbx
	leaq	.LC2(%rip), %rdx
	movq	%rbx, %rcx
	call	strcmp
	testl	%eax, %eax
	je	.L44
	leaq	.LC3(%rip), %rdx
	movq	%rbx, %rcx
	call	strcmp
	testl	%eax, %eax
	jne	.L42
	movq	%rsi, %rcx
	call	vector_kernel
	cmpq	$-1, %rax
	je	.L45
.L41:
	leaq	.LC6(%rip), %rcx
	movq	%rax, %rdx
	call	printf
	xorl	%eax, %eax
	jmp	.L34
.L37:
	movl	$2, %ecx
	call	*__imp___acrt_iob_func(%rip)
	movl	$52, %r8d
	movl	$1, %edx
	leaq	.LC1(%rip), %rcx
	movq	%rax, %r9
	call	fwrite
	movl	$2, %eax
.L34:
	addq	$56, %rsp
	popq	%rbx
	popq	%rsi
	ret
.L43:
	movq	(%rbx), %rbx
	movl	$2, %ecx
	call	*__imp___acrt_iob_func(%rip)
	leaq	.LC0(%rip), %rdx
	movq	%rax, %rcx
	movq	%rbx, %r8
	call	fprintf
	movl	$2, %eax
	jmp	.L34
.L44:
	movq	%rsi, %rcx
	call	branch_kernel
	jmp	.L41
.L42:
	movl	$2, %ecx
	call	*__imp___acrt_iob_func(%rip)
	leaq	.LC5(%rip), %rdx
	movq	%rbx, %r8
	movq	%rax, %rcx
	call	fprintf
	movl	$2, %eax
	jmp	.L34
.L45:
	movl	$2, %ecx
	call	*__imp___acrt_iob_func(%rip)
	movl	$18, %r8d
	movl	$1, %edx
	leaq	.LC4(%rip), %rcx
	movq	%rax, %r9
	call	fwrite
	movl	$3, %eax
	jmp	.L34
	.seh_endproc
	.ident	"GCC: (x86_64-posix-seh-rev0, Built by MinGW-W64 project) 8.1.0"
	.def	malloc;	.scl	2;	.type	32;	.endef
	.def	free;	.scl	2;	.type	32;	.endef
	.def	strtoull;	.scl	2;	.type	32;	.endef
	.def	strcmp;	.scl	2;	.type	32;	.endef
	.def	printf;	.scl	2;	.type	32;	.endef
	.def	fwrite;	.scl	2;	.type	32;	.endef
	.def	fprintf;	.scl	2;	.type	32;	.endef
