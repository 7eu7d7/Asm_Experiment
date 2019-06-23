.386
.model flat,stdcall

include 实验5.inc

.data
	hHeap dd ?    	;程序堆句柄
	pArray dd ?	;记录已退出的人（内存动态分配）
	
	N dd 0
	m dd 0
	i dd 0
	rest dd 0
	
	getint db '%d'
	pN db '请输入N:',0
	pm db '请输入m:',0
	pi db '请输入i:',0
	doout db '%d的二进制是:%s	十六进制是:%s',10,0
	exitout db '%d号退出',10,0
	restout db '剩下的是%d号',10,0
	err db '输入错误'
	
.code

allocate_array proc uses eax ;动态分配数组空间 	uses伪指令与先push在pop效果相同

    invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,N	;分配内存N个字节，用0初始化
   
    .if eax == NULL
       stc ;CF = 1
    .else
       mov  pArray,eax ;保存指针
       clc ;CF = 0
    .endif
    ret
allocate_array endp

indexloop proc
	;若超出范围进行重置
	.if ebx>=ds:[N]
		mov ebx,0
	.endif
	ret

indexloop endp

start:	;读N
	invoke crt_printf,addr pN
	invoke crt_scanf,addr getint,addr N
	
	.if ds:[N]<=0	;若输入不合法则报错
		invoke crt_printf,addr err
		jmp finish
	.endif
	
	mov ecx,ds:[N]
	
	;读m
	push ecx
	invoke crt_printf,addr pm
	invoke crt_scanf,addr getint,addr m
	pop ecx
	
	.if ds:[m]<=0	;若输入不合法则报错
		invoke crt_printf,addr err
		jmp finish
	.endif
	
	inc ds:[m]
	
	;读i
	push ecx
	invoke crt_printf,addr pi
	invoke crt_scanf,addr getint,addr i
	pop ecx
	.if ds:[i]>ecx || ds:[i]<=0	;若输入不合法则报错
		invoke crt_printf,addr err
		jmp finish
	.endif
	
	invoke allocate_array	;根据人数分配内存
	
	mov ecx,ds:[N]
	mov ebx,ds:[i]
	
	;dec ebx
	mov edi,ds:[pArray]	;取出内存地址的指针所值的地址
	
	;剩余人数大于1时一直循环
	.while ecx>1
		mov edx,1	;从1开始计数
		.while 1
			mov al,ds:[edi+ebx]
			.if al==0	;当前位置的人没有被淘汰
				inc edx	;计数
				.if edx==ds:[m]	;若计数达到m则淘汰当前人
					.break
				.endif
			.endif
			inc ebx
			call indexloop	;循环检测
		.endw
		;将当前位置置一，表示被淘汰
		mov al,1
		mov ds:[edi+ebx],al
		mov eax,ebx
		inc eax
		push ecx
		
		invoke crt_printf,addr exitout,eax	;输出当前被淘汰的序号
		pop ecx
		dec ecx
	.endw
	mov ebx,0
	mov al,0
loop1:	cmp byte ptr ds:[ebx+edi],al	;查找最后剩下的人
	je ok
	inc ebx
	jmp loop1
	
ok:	inc ebx
	invoke crt_printf,addr restout,ebx	;输出剩下的序号
	
finish:	
end start