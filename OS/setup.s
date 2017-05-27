;SYSSEG=0x1000
start:
	mov ax, #INITSEG	mov ds, ax	mov ah, #0x03
	xor bh, bh	int 0x10 ;取光标位置dx	mov [0], dx		;取出光标位置（包括其他硬件参数）到0x90000处
	mov ah, #0x88	int 0x15	mov [2], ax 			;扩展内存大小
	cli			;不允许中断
	mov ax, #0x0000		cld
do_move:
	mov es, ax 	add ax, #0x1000
	cmp ax, #0x9000		jz end_move
	mov ds, ax	sub di, di
	sub si, si
	mov cx, #0x8000
	rep		;将system模块移动到0地址
	movsw
	jmp do_move
	
end_move:
	mov ax, #SETUPSEG	mov ds, ax
	lidt idt_48		lgdt gdt 48		;设置保护模式下的中断和寻址
	;用GDT将cs:ip变成物理地址
	;gdt:全局描述表，保护模式下的地址翻译：根据cs查表+ip
	;进入保护模式(32位)的命令：
idt_48:
	.word 0		.word 0, 0		;保护模式中断函数表
gdt_48:
	.word 0x800		.word 512+gdt,0x9
gdt:
	.word 0,0,0,0
	.word 0x07ff, 0x0000, 0x9a00, 0x00c0
	.word 0x07ff, 0x0000, 0x9200, 0x00c0
;两个gdt表项，都是0x0000,一个只读(代码)，一个读写(数据)
	
call empty_8042		mov al, #0xD1		out #0x64, al
;8042是键盘控制器，其输出端口p2用来控制a20地址线，D1表示写数据到8042的P2端口
call empty_8042		mov al, #0xDF		out #0x60, al
;选通a20地址线
call empty_8042		
;初始化8259（中断控制），cr0:是一个寄存器
mov ax, #0x0001		mov cr0, ax
jmpi 0, 8
;PE=1启动保护模式，PG=1启动分页
;jmpi 0, 8 ip=8用来查gdt
;从15位机进入32位

empty_8042:
	.word 0x00eb, 0x00eb
	in al, #0x64
	test al, #2
	jnz empty_8042
	ret