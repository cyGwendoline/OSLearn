void mem_init(long start_mem,long end_mem) {
	int i;
	for(i=0;i<PAGING_PAGES;i++)
		mem_map[i]=USED;
	i=MAP_NR(start_mem);
	end_mem -= start_mem;
	end_mem >>= 12;
	while(end_mem -- > 0)
		mem_map[i++]=0;
}