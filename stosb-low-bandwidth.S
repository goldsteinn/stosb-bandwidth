// abf-off

/*

Usage:

Compiler:
$> gcc -s -static -nostartfiles -nodefaultlibs -nostdlib -Wl,--build-id=none stosb-low-bandwidth.S -o stosb-low-bandwidth


Runs gather relevant memory bandwidth counters (multiplexing but we
don't need super precision here).

$> perf stat  --all-user -e cycles,cpu/event=0x24,umask=0x27,name=l2_rqsts_all_demand_miss/,cpu/event=0x24,umask=0xe7,name=l2_rqsts_all_demand_references/,cpu/event=0x24,umask=0xe2,name=l2_rqsts_all_rfo/,cpu/event=0x24,umask=0xc2,name=l2_rqsts_rfo_hit/,cpu/event=0x24,umask=0x22,name=l2_rqsts_rfo_miss/,cpu/event=0xb0,umask=0x08,name=offcore_requests_all_data_rd/,cpu/event=0xb0,umask=0x80,name=offcore_requests_all_requests/,cpu/event=0xb0,umask=0x01,name=offcore_requests_demand_data_rd/,cpu/event=0xb0,umask=0x04,name=offcore_requests_demand_rfo/,cpu/event=0x60,umask=0x08,name=offcore_requests_outstanding_all_data_rd/,cpu/event=0x60,umask=0x01,name=offcore_requests_outstanding_demand_data_rd/,cpu/event=0x60,umask=0x04,name=offcore_requests_outstanding_demand_rfo/  ./stosb-low-bandwidth


Config:

Set 'TODO' to either 'VEC_COPY' or 'REP_STOSB_COPY'.

If using 'VEC_COPY' set 'vec_mov' to 'vmovu' (cacheable) or 'vmovnt'
(non-cacheable).

If using 'VEC_COPY' set 'VEC_SIZE' to '16', '32', or '64'.


*/

// abf-on


#define VEC_COPY	0
#define REP_STOSB_COPY	1


#define VEC_SIZE	32
#if VEC_SIZE == 16
# define VEC	xmm0
# define vmovu	vmovdqu
# define vmovnt	vmovntdq
#elif VEC_SIZE == 32
# define VEC	ymm0
# define vmovu	vmovdqu
# define vmovnt	vmovntdq
#else
# define VEC	zmm0
# define vmovu	vmovdqu64
# define vmovnt	vmovntdq
#endif

#define buf_sz	(4096	*	4096)
#define copy_len	(4096	*	1024)

#ifndef TODO
# define TODO	REP_STOSB_COPY
#endif

#ifndef vec_mov
# define vec_mov	vmovnt
#endif

	.global	_start
	.text
_start:

	movl	$10000, %esp
	vpxor	%xmm0, %xmm0, %xmm0
	xorl	%eax, %eax

	leaq	(buf_start)(%rip), %rdx
	movl	$(copy_len), %esi

	movq	%rdx, %rdi
	movl	%esi, %ecx

	.p2align 6
loop:
#if TODO == VEC_COPY
copy_loop:
	vec_mov	%VEC, (%rdi)
	vec_mov	%VEC, VEC_SIZE(%rdi)
	vec_mov	%VEC, (VEC_SIZE * 2)(%rdi)
	vec_mov	%VEC, (VEC_SIZE * 3)(%rdi)
	subq	$-(VEC_SIZE * 4), %rdi
	addl	$-(VEC_SIZE * 4), %ecx
	jnz	copy_loop
#else
	rep	stosb
#endif

	movq	%rdx, %rdi
	movl	%esi, %ecx

	decl	%esp
	jnz	loop

	movl	$60, %eax
	xorl	%edi, %edi
	syscall

	.section .data
	.balign	4096
buf_start:	.space buf_sz
buf_end:
