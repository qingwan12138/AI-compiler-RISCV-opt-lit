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
	leaq	0(,%rcx,4), %rsi
	movq	%rcx, %r12
	movq	%rsi, %rcx
	call	malloc
	movq	%rsi, %rcx
	movq	%rax, %rdi
	call	malloc
	movq	%rsi, %rcx
	movq	%rax, %rbx
	call	malloc
	testq	%rdi, %rdi
	sete	%dl
	testq	%rbx, %rbx
	movq	%rax, %rbp
	sete	%al
	orb	%al, %dl
	jne	.L11
	testq	%rbp, %rbp
	je	.L11
	movabsq	$-9086255505087856445, %r10
	xorl	%r8d, %r8d
	xorl	%ecx, %ecx
	movabsq	$-9123216960442729871, %r9
	testq	%r12, %r12
	jne	.L12
	jmp	.L13
	.p2align 4,,10
.L18:
	movq	%rax, %rcx
.L12:
	movq	%rcx, %rax
	mulq	%r10
	movq	%rcx, %rax
	shrq	$9, %rdx
	imulq	$1009, %rdx, %rdx
	subq	%rdx, %rax
	movl	%eax, (%rdi,%rcx,4)
	movq	%r8, %rax
	mulq	%r9
	movq	%r8, %rax
	addq	$7, %r8
	shrq	$9, %rdx
	imulq	$1013, %rdx, %rdx
	subq	%rdx, %rax
	movl	%eax, (%rbx,%rcx,4)
	leaq	1(%rcx), %rax
	cmpq	%rax, %r12
	jne	.L18
	xorl	%eax, %eax
	jmp	.L15
	.p2align 4,,10
.L19:
	movq	%rdx, %rax
.L15:
	movl	(%rdi,%rax,4), %edx
	movl	(%rbx,%rax,4), %r8d
	leal	(%rdx,%rdx,2), %edx
	leal	(%r8,%r8,4), %r8d
	addl	%r8d, %edx
	cmpq	%rax, %rcx
	movl	%edx, 0(%rbp,%rax,4)
	leaq	1(%rax), %rdx
	jne	.L19
	movq	%rbp, %rdx
	addq	%rbp, %rsi
	xorl	%r12d, %r12d
	.p2align 4,,10
.L16:
	movl	(%rdx), %eax
	addq	$4, %rdx
	addq	%rax, %r12
	cmpq	%rdx, %rsi
	jne	.L16
.L13:
	movq	%rdi, %rcx
	call	free
	movq	%rbx, %rcx
	call	free
	movq	%rbp, %rcx
	call	free
.L10:
	movq	%r12, %rax
	addq	$32, %rsp
	popq	%rbx
	popq	%rsi
	popq	%rdi
	popq	%rbp
	popq	%r12
	ret
.L11:
	movq	%rdi, %rcx
	orq	$-1, %r12
	call	free
	movq	%rbx, %rcx
	call	free
	movq	%rbp, %rcx
	call	free
	jmp	.L10
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
	jne	.L31
	movq	16(%rbx), %rcx
	leaq	40(%rsp), %rdx
	movl	$10, %r8d
	call	strtoull
	movq	%rax, %rsi
	movq	40(%rsp), %rax
	cmpq	%rax, 16(%rbx)
	je	.L25
	cmpb	$0, (%rax)
	jne	.L25
	testq	%rsi, %rsi
	je	.L25
	movq	8(%rbx), %rbx
	leaq	.LC2(%rip), %rdx
	movq	%rbx, %rcx
	call	strcmp
	testl	%eax, %eax
	je	.L32
	leaq	.LC3(%rip), %rdx
	movq	%rbx, %rcx
	call	strcmp
	testl	%eax, %eax
	jne	.L30
	movq	%rsi, %rcx
	call	vector_kernel
	cmpq	$-1, %rax
	je	.L33
.L29:
	leaq	.LC6(%rip), %rcx
	movq	%rax, %rdx
	call	printf
	xorl	%eax, %eax
	jmp	.L22
.L25:
	movl	$2, %ecx
	call	*__imp___acrt_iob_func(%rip)
	movl	$52, %r8d
	movl	$1, %edx
	leaq	.LC1(%rip), %rcx
	movq	%rax, %r9
	call	fwrite
	movl	$2, %eax
.L22:
	addq	$56, %rsp
	popq	%rbx
	popq	%rsi
	ret
.L31:
	movq	(%rbx), %rbx
	movl	$2, %ecx
	call	*__imp___acrt_iob_func(%rip)
	leaq	.LC0(%rip), %rdx
	movq	%rax, %rcx
	movq	%rbx, %r8
	call	fprintf
	movl	$2, %eax
	jmp	.L22
.L32:
	movq	%rsi, %rcx
	call	branch_kernel
	jmp	.L29
.L30:
	movl	$2, %ecx
	call	*__imp___acrt_iob_func(%rip)
	leaq	.LC5(%rip), %rdx
	movq	%rbx, %r8
	movq	%rax, %rcx
	call	fprintf
	movl	$2, %eax
	jmp	.L22
.L33:
	movl	$2, %ecx
	call	*__imp___acrt_iob_func(%rip)
	movl	$18, %r8d
	movl	$1, %edx
	leaq	.LC4(%rip), %rcx
	movq	%rax, %r9
	call	fwrite
	movl	$3, %eax
	jmp	.L22
	.seh_endproc
	.ident	"GCC: (x86_64-posix-seh-rev0, Built by MinGW-W64 project) 8.1.0"
	.def	malloc;	.scl	2;	.type	32;	.endef
	.def	free;	.scl	2;	.type	32;	.endef
	.def	strtoull;	.scl	2;	.type	32;	.endef
	.def	strcmp;	.scl	2;	.type	32;	.endef
	.def	printf;	.scl	2;	.type	32;	.endef
	.def	fwrite;	.scl	2;	.type	32;	.endef
	.def	fprintf;	.scl	2;	.type	32;	.endef
