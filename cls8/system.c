int fork_syscall()
{
    int ret = -1;
    __asm__ volatile ("int $0x82": "=a" (ret): );
    
    return ret;
}


