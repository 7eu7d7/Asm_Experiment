.386
.model flat,stdcall

include 实验4.inc

.data
	string db 'or example, This is a number 3692.',0	;要转换的字符串
	doout db '%c 的ASCII值为 %d',10,0
	
.code
start:	mov ebx,0
	mov eax,0
	.while ds:[string+ebx]!=0	;使用.while伪指令进行循环，从头到尾对每一位进行转换
		;取出一位输出其ascii数值
		mov al,ds:[string+ebx]
		invoke crt_printf,addr doout,eax,eax	;使用printf输出结果
		inc ebx
	.endw

end start