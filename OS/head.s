disk:Image	;Image 镜像
	dd bs=8192 if=Image of=/dev/PS0		;if=input file , /dev/PS0是软驱A
Image:	boot/bootsect boot/setup tools/system tools/build
	tools/build	boot/bootsect boot/setup tools/system >Image
tools/system:	boot/head.o init/main.o $(DRIVERS)
	$(LD) boot/head.o init/main.o $(DRIVERS)...-o tools/system

;idt_48: word 0 word 0,0
;_idt: .fill 256,8,0
startup_32:	
	mov1 $0x10, %eax	mov %ax, %ds	mov %ax, %es
	mov %as, %fs	mov %as, %gs	;指向gdt的0x10项（数据段）
	lss _stack, %esp	;设置栈（系统栈）
	call setup_idt
	call setup_gdt
	;struct{long *a,short b;}stack_start={&user_stack[PAGE_SIZE>>2],0x10};
	xorl %eax, %eax
1:	incl %eax
	mov1 %eax,0x000000	cmp1 %eax, 0x100000
	je 1b	;0地址处和1M地址处相同（A20没开启），就死循环
	jmp after_page_tables ;页表
setup_idt:
	les ignore_int, %edx
	mov1 $0x00080000, %eax	movw %dx, %ax
	lea _idx, %edi	mov %eax, (%edi)
	
after_page_tables:
	push1 $0	push1 $0	push1 $L6	
	push1 $_main	jmp set_paging
L6:
	jmp L6
set_paging:		;设置页表
	ret			;从栈中弹出一个地址