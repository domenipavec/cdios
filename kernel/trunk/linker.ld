ENTRY(start)
OUTPUT_FORMAT(elf64-x86-64)
PHDRS
{
	header PT_PHDR FILEHDR PHDRS ;
	load PT_LOAD ;
}
SECTIONS
{
	.text :
	{
		FILL(0x00)
		
		. = ALIGN(0x1000);
		ro_start = .;

		*(.text)
		*(.rodata)

		*(.eh_frame)
		. += 4;

		start_ctors = .;
		*(.ctor*)
		end_ctors = .;
		start_dtors = .;
		*(.dtor*)
		end_dtors = .;
	
		ro_end = .;
	} :load
	.data : 
	{
		. = ALIGN(0x1000);
   		rw_start = .;

		*(.data)
		*(.bss)
		
		rw_end = .;
	} :load

}
MEMORY
{
	all(RWXAI) : org = 0x0100000, l = 1M
}