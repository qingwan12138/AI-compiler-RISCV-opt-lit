	.file	"bench.c"
	.text
	.def	branch_kernel;	.scl	3;	.type	32;	.endef
	.seh_proc	branch_kernel
branch_kernel:
	pushq	%rbx
	.seh_pushreg	%rbx
	.seh_endprologue
	xorl	%r10d, %r10d
	movl	$-2128831035, %r8d
	xorl	%r9d, %r9d
	movl	$89, %r11d
	movl	$97, %ebx
.L2:
	cmpq	%rcx, %r10
	je	.L7
	leal	-1640531527(%r10), %eax
	movl	$0, %edx
	xorl	%eax, %r8d
	imull	$16777619, %r8d, %r8d
	movl	%r8d, %eax
	andl	$7, %eax
	cmpl	$2, %eax
	movl	%r8d, %eax
	ja	.L3
	divl	%ebx
	movl	%edx, %edx
	addq	%rdx, %r9
	jmp	.L4
.L3:
	divl	%r11d
	movl	%edx, %edx
	addq	%r10, %rdx
	xorq	%rdx, %r9
.L4:
	incq	%r10
	jmp	.L2
.L7:
	movq	%r9, %rax
	popq	%rbx
	ret
	.seh_endproc
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
	leaq	0(,%rcx,4), %rbx
	movq	%rcx, %r12
	movq	%rbx, %rcx
	call	malloc
	movq	%rbx, %rcx
	movq	%rax, %rdi
	call	malloc
	movq	%rbx, %rcx
	movq	%rax, %rsi
	call	malloc
	testq	%rdi, %rdi
	sete	%dl
	testq	%rsi, %rsi
	movq	%rax, %rbx
	sete	%al
	orb	%al, %dl
	jne	.L18
	xorl	%ecx, %ecx
	testq	%rbx, %rbx
	je	.L18
	movl	$1009, %r8d
	movl	$1013, %r9d
	jmp	.L9
.L18:
	movq	%rdi, %rcx
	orq	$-1, %rbp
	call	free
	movq	%rsi, %rcx
	call	free
	movq	%rbx, %rcx
	call	free
	jmp	.L8
.L9:
	cmpq	%r12, %rcx
	je	.L20
	movq	%rcx, %rax
	xorl	%edx, %edx
	divq	%r8
	imulq	$7, %rcx, %rax
	movl	%edx, (%rdi,%rcx,4)
	xorl	%edx, %edx
	divq	%r9
	movl	%edx, (%rsi,%rcx,4)
	incq	%rcx
	jmp	.L9
.L20:
	xorl	%eax, %eax
.L13:
	cmpq	%r12, %rax
	je	.L21
	imull	$3, (%rdi,%rax,4), %edx
	imull	$5, (%rsi,%rax,4), %ecx
	addl	%ecx, %edx
	movl	%edx, (%rbx,%rax,4)
	incq	%rax
	jmp	.L13
.L21:
	xorl	%eax, %eax
	xorl	%ebp, %ebp
.L15:
	cmpq	%r12, %rax
	je	.L22
	movl	(%rbx,%rax,4), %edx
	incq	%rax
	addq	%rdx, %rbp
	jmp	.L15
.L22:
	movq	%rdi, %rcx
	call	free
	movq	%rsi, %rcx
	call	free
	movq	%rbx, %rcx
	call	free
.L8:
	movq	%rbp, %rax
	addq	$32, %rsp
	popq	%rbx
	popq	%rsi
	popq	%rdi
	popq	%rbp
	popq	%r12
	ret
	.seh_endproc
	.def	__main;	.scl	2;	.type	32;	.endef
	.section .rdata,"dr"
.LC0:
	.ascii "usage: %s <branch|vector> <positive-size>\12\0"
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
	.globl	main
	.def	main;	.scl	2;	.type	32;	.endef
	.seh_proc	main
main:
	pushq	%rdi
	.seh_pushreg	%rdi
	pushq	%rsi
	.seh_pushreg	%rsi
	pushq	%rbx
	.seh_pushreg	%rbx
	subq	$64, %rsp
	.seh_stackalloc	64
	.seh_endprologue
	movl	%ecx, %ebx
	movq	%rdx, %rsi
	call	__main
	cmpl	$3, %ebx
	movq	$0, 56(%rsp)
	je	.L24
	movq	(%rsi), %r8
	movl	$2, %ecx
	movq	%r8, 40(%rsp)
	call	*__imp___acrt_iob_func(%rip)
	movq	40(%rsp), %r8
	leaq	.LC0(%rip), %rdx
	jmp	.L33
.L24:
	movq	16(%rsi), %rcx
	leaq	56(%rsp), %rdx
	movl	$10, %r8d
	call	strtoull
	movq	%rax, %rdi
	movq	56(%rsp), %rax
	cmpq	%rax, 16(%rsi)
	je	.L26
	cmpb	$0, (%rax)
	jne	.L26
	testq	%rdi, %rdi
	jne	.L27
.L26:
	movl	$2, %ecx
	call	*__imp___acrt_iob_func(%rip)
	leaq	.LC1(%rip), %rcx
	movq	%rax, %rdx
	call	fputs
.L32:
	movl	$2, %ebx
	jmp	.L25
.L27:
	movq	8(%rsi), %rsi
	leaq	.LC2(%rip), %rdx
	movq	%rsi, %rcx
	call	strcmp
	testl	%eax, %eax
	jne	.L29
	movq	%rdi, %rcx
	call	branch_kernel
	jmp	.L30
.L29:
	leaq	.LC3(%rip), %rdx
	movq	%rsi, %rcx
	call	strcmp
	testl	%eax, %eax
	jne	.L31
	movq	%rdi, %rcx
	call	vector_kernel
	cmpq	$-1, %rax
	jne	.L30
	movl	$2, %ecx
	call	*__imp___acrt_iob_func(%rip)
	leaq	.LC4(%rip), %rcx
	movq	%rax, %rdx
	call	fputs
	jmp	.L25
.L31:
	movl	$2, %ecx
	call	*__imp___acrt_iob_func(%rip)
	leaq	.LC5(%rip), %rdx
	movq	%rsi, %r8
.L33:
	movq	%rax, %rcx
	call	fprintf
	jmp	.L32
.L30:
	leaq	.LC6(%rip), %rcx
	movq	%rax, %rdx
	xorl	%ebx, %ebx
	call	printf
.L25:
	movl	%ebx, %eax
	addq	$64, %rsp
	popq	%rbx
	popq	%rsi
	popq	%rdi
	ret
	.seh_endproc
	.ident	"GCC: (x86_64-posix-seh-rev0, Built by MinGW-W64 project) 8.1.0"
	.def	malloc;	.scl	2;	.type	32;	.endef
	.def	free;	.scl	2;	.type	32;	.endef
	.def	strtoull;	.scl	2;	.type	32;	.endef
	.def	fputs;	.scl	2;	.type	32;	.endef
	.def	strcmp;	.scl	2;	.type	32;	.endef
	.def	fprintf;	.scl	2;	.type	32;	.endef
	.def	printf;	.scl	2;	.type	32;	.endef
