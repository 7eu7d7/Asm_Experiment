.model small
;运算量较大，在dosbox里面跑比较慢
.data
	num1 db 1,3000 dup(0)	;变量num1
	num2 db 10 dup(0)	;变量num2
	num_res db 3000 dup(0)	;保存结果的变量
	num_str db 3000 dup('$'),10,'$'	;最后输出结果用的字符串
	index1 dw 1	;数字1的长度
	index2 dw 0	;数字2的长度
	index_temp dw 0	;长度记录临时变量
	numa db 0,10,'$'
.code

intsplit proc ;num=ax,aim=bx
	;将数字以BCD码形式存储
	;数据入栈进行保护，函数结束再恢复
	push ax
	push bx
	push cx
	push dx
	push bp
	
	mov cx,10	;除数10放入cx
	mov bp,bx	;记录起始地址
next:	cmp ax,0	;若数字不为0则继续
	je ok
	mov dx,0	;dx:ax作为除数，所以dx置0
	div cx		;每次除10取出每一位
	mov ds:[bx],dl	;记录该位
	inc bx		;移到下一位
	jmp next
	
ok:	sub bx,bp	;计算该数的长度（十进制）
	mov ds:[index_temp],bx
	
	pop bp
	pop dx
	pop cx
	pop bx
	pop ax
	ret
	
intsplit endp

seekno0 proc ;index=index1,num=num_res
	;删除该数前面多余的0
	push ax
	push bx
	
	mov bx,ds:[index1]	;获取该数的地址
snext:	
	mov al,ds:[num_res+bx]	;取出该数当前位
	;若当前位为0则指针移向下一位（逻辑上删除该位）
	.if al==0
		dec bx
		jmp snext
	.else
		inc bx
		mov ds:[index1],bx	;记录该数真实长度
		
		pop bx
		pop ax
		ret
	.endif
	
seekno0 endp

bigmul proc
	;两个数相乘（num_res=num1*num2）
	push ax
	push bx
	push cx
	push dx
	push di
	
	;for(bx=0;bx<index1;bx++)  循环第一个乘数每一位
	mov bx,0
next1:	mov cx,ds:[index1]
	cmp cx,bx
	je bok2
	;for(di=0;di<index2;di++)  循环第二个乘数每一位
	mov di,0
	
next2:	mov cx,ds:[index2]
	cmp cx,di
	je bok1
	;类比手算乘法，对两个数每一位相乘再对应位求和
	;---------------------------------;
	;| res[bx+di]+=num1[bx]*num2[di] |;
	;---------------------------------;
	
	mov ax,0
	mov al,ds:[num1+bx]	;al=num1[bx]
	mov dl,ds:[num2+di]	;dl=num2[di]
	mul dl			;al=dl*al
	;res[bx+di]+=al
	mov dl,ds:[num_res+bx+di]
	add dl,al
	mov ds:[num_res+bx+di],dl
	inc di
	jmp next2
	
bok1:	inc bx
	jmp next1
	
bok2:	;for(bx=0;bx<index1+index2-1;bx++)  处理对应位求和大于9需要进位的情况
	mov bx,0
cnext:	mov cx,ds:[index1]
	add cx,ds:[index2]
	
	cmp cx,bx
	je bok
	mov ax,0
	mov al,ds:[num_res+bx]	;取出当前位进行判断
	.if al>=10
		;res[bx+1]+=res[bx]/10
		mov dl,ds:[num_res+bx+1]
		mov cl,10
		div cl
		add dl,al
		mov ds:[num_res+bx+1],dl
		;res[bx]=res[bx]%10
		mov ds:[num_res+bx],ah
	.endif
	inc bx
	jmp cnext
bok:	
	mov ds:[index1],bx
	call seekno0	;去掉前面无意义的0
	
loopcpy:cmp bx,-1
	je cpyok
	;将num_res中计算完的结果存入num1中，方便下次计算
	mov al,ds:[num_res+bx]
	mov ds:[num1+bx],al
	;num_res清零，不然影响下次计算
	mov al,0
	mov ds:[num_res+bx],al
	dec bx
	jmp loopcpy
cpyok:	

	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	
	ret
bigmul endp

bnum2str proc	;BCD码转字符串(ASCII)  num1->num_str
	push bx
	push ax
	push dx
	push di
	
	mov bx,ds:[index_temp];取出长度
	mov di,0
	;for(x:num1)
bloop1:	cmp bx,-1;判断是否转换完毕
	je bok
	;num_str[di]=num1[dx]+'0'
	mov al,ds:[num1+bx]	;取出num1当前位
	add al,'0'		;加0的ascii值实现转换
	
	mov ds:[num_str+di],al
	dec bx
	inc di
	
	jmp bloop1
bok:	
	pop di
	pop dx
	pop ax
	pop bx
	
	ret

bnum2str endp

start:	mov ax,@data	;将数据段地址赋给dx
	mov ds,ax
	mov ax,1	;从1开始乘
	mov cx,10	;除数为10
	
mulloop:
	cmp ax,1001	;从1乘到1000
	je mulok
	
	;将ax的值转换为BCD码存入num2
	lea bx,num2
	call intsplit
	
	;把num2长度放入index2
	mov bx,ds:[index_temp]
	mov ds:[index2],bx
	
	call bigmul	;开始乘法
	inc ax
	
	jmp mulloop
mulok:	;循环完毕
	mov dx,ds:[index1]
	mov ds:[index_temp],dx
	call bnum2str	;将结果的BCD码转成字符串
	lea dx,num_str
	;调用21h号中断的9号功能，输出字符串
	mov ah,09h
	int 21h
	
end start