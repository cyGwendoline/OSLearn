;BOOTSEG=0x07c0, INITSEG=0x9000, SETUPSEG=0x9020
.global begtext,begdata,begbss,endtext,enddata,endbss
.text ;文本段(.text等是伪操作符，告诉编译器产生文本段，.text用于标识文本段的开始位置)
begtext:
.data ;数据段
begdata:
.bss ;未初始化数据段(此处的.text,.data,.bss表明这3个段重叠，不分段)
begbss:
entry start ;关键字entry告诉链接器“程序入口”
start:
	mov ax, #BOOTSEG		mov ds, ax
	mov ax, #INITSEG		mov es, ax
	mov cx, #256
	sub si, si				sub di,di ;将0x07c0:0x0000处的256个字移动到0x9000:0x0000处
	rep		move
	jmpi	go, INITSEG	；go:IP,INITSEG:CS (cs<<4+ip)
	
;cs=INITSEG,ip=go
go:	mov as, cs ;cs=0x9000	
	mov ds, ax	mov es,ax	mov ss,ax	mov sp,#0xff00	;	为call做准备
load_setup:	;载入setup模块
	mov dx,#0x0000	mov cs,#0x0002	mov bx,#0x0200
	mov ax,#0x0200+SETUPLEN	int 0x13	;BIOS中断
	;0x13是BIOS读磁盘扇区的中断；ah=0x12-读磁盘，al=扇区数量（SETUPLEN=4）,ch=柱面号，cl=开始扇区，dh=磁头号，dl=驱动器号，ex:bx=内存地址
	jnc ok_load_setup
	mov	dx,#0x0000
	mov ax,#0x0000	;复位
	int 0x13
	j	load_setup	;重读
	
ok_load_setup:	;载入setup模块
	mov dl, #0x00	mov ax, #0x0800	;ah=8获得磁盘参数
	int 0x13		mov ch, #0x00	mov sectors, cx 
	mov ah, #0x03	xor bh,bh		int 0x10 ;读光标
	mov cx, #24		mov bx,#0x0007	;7是显示属性
	mov bp, #msg1	mov ax,#1301	int 0x10	;显示字符
	mov ax, #SYSSEG	;SYSSEG=0x1000
	mov es, ax
	call read_it	;读入system模块
	jmpi	0,SETUPSEG	;转入0x9020:0x0000执行setup.s
	
read_it:
	mov ax, es	cmp ax, #ENDSEG		jb ok1_read		;ENDSEG=SYSSEG+SYSSIZE SYSSIZE=0x8000,可根据Image大小设定
	ret
ok1_read:
	mov ax, sectors
	sub ax,sread	;sread是当前磁道已读扇区数，ax未读扇区数
	call read_track	;读磁道
	
	
	
;bootsect.s中的数据
sectors:	.word 0
msg1:	.byte 13,10
		.ascii "Loading system..."
		.byte 13,10,13,10
.org 510
	.word 0xAA55	;扇区的最后两个字节