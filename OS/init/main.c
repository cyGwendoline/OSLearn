/* main()初始化xx_init：内存，中断，设备，时钟，cpu等 */
void main(void) {
	mem_init();
	trap_init();
	blk_dev_init();
	chr_dev_init();
	tty_init();
	time_init();
	sched_init();
	buffer_init();
	hd_init();
	floppy_int();
	sti();
	mov_to_user_mode();
	if(!fork()){init();}
}