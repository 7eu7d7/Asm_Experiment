.386
.model flat,stdcall;使用flat模型，使用stdcall模式方便调用win32 api

include 实验1.inc

;声明数据段
.data
	nums dd 369,10000,4095,32767,8000			;要转换的数字
	numa dd 0						;int numa
	res2 db 32 dup(0),0					;2进制转换的结果
	res16 db 4 dup('0'),0					;16进制转换的结果
	doout db '%d的二进制是:%s	十六进制是:%s',10,0	;输出用字符串
	
;代码段
.code
start:	mov ebp,0
	;每次循环清空
	;用降幂法实现10进制转2进制
foreach:mov ds:[res16],'0'
	mov ds:[res16+1],'0'
	mov ds:[res16+2],'0'
	mov ds:[res16+3],'0'
	
	mov ecx,ds:[nums+ebp]	;取下一个数
	
	;找到第一个小于该数的二进制的权
	mov eax,10000H
geth:	shr eax,1
	cmp ecx,eax
	jae getok
	jb geth
	
getok:	lea ebx,res2	;把res2的地址存入ebx中
	;若ecx小于当前的权，则这一位为0，不减小ecx，否则这一位为1，ecx减去当前的权
loop1:	.if ecx<eax
		mov dl,'0'
		mov ds:[ebx],dl
	.else
		sub ecx,eax
		mov dl,'1'
		mov ds:[ebx],dl
	.endif
	shr eax,1	;权减小一级
	cmp eax,0	;若eax为0，说明转换完毕
	jbe next
	inc ebx		;储存指针移向下一位
	jmp loop1
	
	;用除法实现10进制转16进制
next:	mov cl,0
	mov ds:[ebx+1],cl ;将字符串结束标志存入结果后一位
	
	mov ecx,16		;权为16，存入ecx中
	mov eax,ds:[nums+ebp]	;取下一个数
	lea ebx,res16+3		;由于除法结果是逆序的，所以倒着存
loop2:	mov edx,0
	div ecx		;eax=edx:eax/ecx   edx=edx:eax%ecx
	;大于9的为A-F与0-9的数转换为ascii码公式不同
	.if dl>9
		add dl,55
	.else
		add dl,'0'
	.endif
	mov ds:[ebx],dl
	cmp eax,0	;eax为0说明转换完毕
	je ok
	dec ebx		;指针左移
	jmp loop2
	
ok:	
	mov ecx,ds:[nums+ebp]
	invoke crt_printf,addr doout,ecx,addr res2,addr res16	;输出结果
	add ebp,4
	cmp ebp,20	;判断是否所有数字都转换完毕
	je finish
	jmp foreach
finish:	nop
end start