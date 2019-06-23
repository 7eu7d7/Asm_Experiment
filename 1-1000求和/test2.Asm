.model small

.data
	num db '0000','$$'	;整数转换完的字符串
	index dw 0		;转换后最低位的位置
.code

int2str proc ;参数ax，整数转字符串，结果存入num中
	;将所有用到的寄存器压入栈，最后在取出来
	push bx
	push cx
	push dx
	mov cx,10	;权为10
	lea bx,num+3
	
	;若ax大于0，每次除10，取出每一位
next:	cmp ax,0
	je ok
	mov dx,0
	div cx
	add dl,'0'	;数字+0的ascii码，转成字符
	mov ds:[bx],dl
	dec bx
	jmp next
	
ok:	inc bx
	mov ds:[index],bx
	pop dx
	pop cx
	pop bx
	ret
	
int2str endp

start:	mov cx,1	;cx为当前加数，从1-1000
	mov dx,0
	mov ax,@data	;数据段地址放入ds中
	mov ds,ax
	mov ax,0
loop1:	cmp cx,1001	;if(cx>1000)goto finish;
	je finish
	
	;求和，低位存入ax,高位存入dx
	add ax,cx
	adc dx,0
	;寄存器不够用了，先push进去，临时做其他用途
	push ax
	push dx
	
	;将dx:ax分离，将16进制高低位分离变成10进制高低位，高位存入ax,低位dx
	mov bx,10000
	div bx
	;输出ax高4位(10进制)
	push ax
	push dx
	
	mov dx,0
	call int2str
	
	;添加结束符
	mov dl,'$'
	mov ds:[num+4],dl
	mov dx,ds:[index]
	mov ah,09h
	int 21h
	
	pop dx
	pop ax
	;输出dx低4位(10进制)
	push ax
	push dx
	
	;先清零
	mov al,'0'
	mov ds:[num],al
	mov ds:[num+1],al
	mov ds:[num+2],al
	mov ds:[num+3],al
	
	.if ds:[index]>=offset num+3
		mov bx,1	;没有超过四位，标记1
	.else
		xor bx,bx	;超过四位，标记0
	.endif
	
	mov ax,dx
	call int2str
	
	mov dl,10
	mov ds:[num+4],dl	;低四位输出后换行
	.if bx==0
		mov dx,offset num	;超过四位则保留前面的0
	.else
		mov dx,ds:[index]	;四位以内则去掉前面的0
	.endif
	mov ah,09h
	int 21h
	inc cx
	
	pop dx
	pop ax
	
	pop dx
	pop ax
	jmp loop1
	
finish:	
end start