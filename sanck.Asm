;定义一个宏显示字符串,相当于高级语言的函数
OutPutString MACRO buffer
	push edx
	mov edx,OFFSET buffer
	call WriteString
	call Crlf
	pop edx
ENDM

;测试宏
testU MACRO 
	mov dh,40
	mov dl,20
	call Gotoxy
	mov eax,white+(black*16)
	call SetTextColor 
	call WaitMsg
endm

;把坐标为(x,y)的方格置成背景色为绿色(代表蛇头)
SetBC MACRO x,y
	push EDX
	mov dh,x
	mov dl,y
	call Gotoxy
	mov edx,OFFSET fr
	mov eax,green+(green*16)
	call SetTextColor
	call WriteString
	pop EDX
ENDM

;把坐标为(x,y)的方格置成背景色为灰色(代表蛇身体)
SetSn MACRO x,y
	push EDX
	mov dh,x
	mov dl,y
	call Gotoxy
	mov edx,OFFSET sn
	mov eax,gray+(gray*16)
	call SetTextColor
	call WriteString
	pop EDX
ENDM

;把坐标为(x,y)的方格置成背景色为黄色(代表食物)
SetFd MACRO x,y
	push EDX
	mov dh,x
	mov dl,y
	call Gotoxy
	mov edx,OFFSET fd
	mov eax,yellow+(yellow*16)
	call SetTextColor
	call WriteString
	pop EDX
ENDM

;把坐标为(x,y)的方格置成背景色为红色(代表墙边框)
SetHP MACRO x,y
	push EDX
	mov dh,x
	mov dl,y
	call Gotoxy
	mov edx,OFFSET sn
	mov eax,red+(red*16)
	call SetTextColor
	call WriteString
	pop EDX
ENDM

;把坐标为(x,y)的方格置成背景色为黑色(代表蛇未走过的地方)
SetRT MACRO x,y
	push EDX
	mov dh,x
	mov dl,y
	call Gotoxy
	mov edx,OFFSET sn
	mov eax,black+(black*16)
	call SetTextColor
	call WriteString
	pop EDX
endm

;定义蛇身体的坐标(类似高级语言的结构体)
SnakePoint STRUCT
	X DWORD 0
	Y DWORD 0
SnakePoint  ends

Include Irvine32.inc
Includelib Irvine32.lib 
Includelib kernel32.lib 
Includelib user32.lib
INCLUDE Macros.inc

.data
;方框当中的坐标点
PointNum=800
ALIGN DWORD
PointH SnakePoint PointNum DUP(<0,0>)
;记录蛇身的长度
SnLen DWORD 0
;记录蛇身体的记录
FoodX DWORD 0
FoodY DWORD 0
;记录蛇尾巴的坐标
TailX DWORD 0
TailY DWORD 0
;边框的宽度
FrWidth BYTE 0
;边框的长度
FrLen  BYTE 0
;边框的符号
fr BYTE "#",0
;蛇身体的符号
sn BYTE "S",0
;游戏结束
overed BYTE "Game Over!",0
;蛇食物的符号
fd BYTE "Q",0
SnFood DWORD 0
;记录方向
SnDir DWORD 0
;临时变量，随时可用
temp DWORD 0
caption BYTE "Survey Completed",0
consoleInHandle DWORD ? ; 控制台标准输入句柄
score BYTE "Socre:",0
;控制贪吃蛇的运动速度
select BYTE "Please select the Difficulty",0
diffOne BYTE "1.easy",0
diffTwo BYTE "2.common",0
diffThree BYTE "3.hard",0
diffFour BYTE "4.very hard",0
FiveOut BYTE "5.quit",0
errPro BYTE "Input Error ,enter common mode",0
delayTimes DWORD 300
;监控蛇是否撞墙或者撞到自身而死亡
control DWORD 1
.code 

;主模块，通过调用其他模块实现贪吃蛇游戏
main PROC
GameBegin:
	call Clrscr
	mov eax,white+(black*16)
	call SetTextColor
	mov control,1
	mov SnLen,0
	mov FrWidth,0
	mov FrLen,0
	OutPutString select
	OutPutString diffOne
	OutPutString diffTwo
	OutPutString diffThree
	OutPutString diffFour
	OutPutString FiveOut
	call ReadDec
	.if eax==1
		mov delayTimes,400
	.elseif eax==2
		mov delayTimes,300
	.elseif eax==3
		mov delayTimes,200
	.elseif eax==4
		mov delayTimes,100
	.elseif eax==5
		jmp mainend
	.else
		OutPutString 	errPro	
	.endif
	call Game
	.if control==0
		jmp GameBegin
	.endif
mainend:
	ret
main endp

;游戏开始
Game PROC
	call Clrscr
	call paintFrame
	call InitSnack           
	call SnackFood
	;D代表向右，A代表向左，S代表向下，W代表向上
	;初始化方向向右
	mov SnDir,64H
.while(1)
	push ecx
	mov ecx,3
	call GetInput
	call move
	.if control==0
		jmp GameEd
	.endif
	pop ecx
.ENDW
GameEd:
	ret

Game endp

;绘制矩形边框
paintFrame PROC USES ecx edx
	mov ecx,40
L1:
	SetBC 0,FrWidth
	SetBC 19,FrWidth
	add FrWidth,1
Loop L1
	mov ecx,20
L2:
	SetBC FrLen,0
	SetBC FrLen,39
	add FrLen,1
Loop L2
	mov FrLen,0
	mov ecx,20
L3:
	SetBC FrLen,1
	SetBC FrLen,40
	add FrLen,1
Loop L3
	ret
paintFrame endp

;初始化蛇的身体
InitSnack PROC USES eax ecx edx
	mov FrWidth,20
	mov ecx,2 
	mov edi,TYPE SnakePoint
	imul edi,2
I:
	;绘制蛇身体
	SetSn 10,FrWidth
	mov (SnakePoint PTR PointH[edi]).X,10
	;testInt (SnakePoint PTR PointH[edi]).X
	;无符号整数扩展
	movzx  eax,FrWidth
	mov (SnakePoint PTR PointH[edi]).Y,eax
	;testInt (SnakePoint PTR PointH[edi]).Y
	add FrWidth,1
	;蛇身体的长度+1          
	add SnLen,1
	sub edi,TYPE SnakePoint
Loop I
	;记录蛇尾
	mov edi,TYPE SnakePoint
	mov eax,(SnakePoint PTR PointH[edi]).X
	mov TailX,eax
	;testInt TailX
	mov eax,(SnakePoint PTR PointH[edi]).Y
	mov TailY,eax
	;testInt TailY
	mov edi,0
	mov ecx,1
I2:
	;绘制蛇头
	SetHP 10,FrWidth
	mov (SnakePoint PTR PointH[edi]).X,10
	;testInt (SnakePoint PTR PointH[edi]).X
	movzx  eax,FrWidth
	mov (SnakePoint PTR PointH[edi]).Y,eax
	;testInt (SnakePoint PTR PointH[edi]).Y
Loop I2
	call DrawScore
	ret
InitSnack endp

;游戏输入
GetInput PROC USES ecx edx eax edi esi
	mov    eax,delayTimes            ; 消息处理带来的延迟
    	call    Delay
	call ReadKey
	jz InputEnd
	mov esi,SnDir
	.if AL==0
		jmp InputEnd
	.endif
	cmp AL,64H  ;右
	jz CRIGHT
	cmp AL,61H  ;左
	jz CLEFT
	cmp AL,73H  ;下
	jz CDROW
	cmp AL,77H ;上
	jz CUP
InputEnd:
	;testU
	INVOKE FlushConsoleInputBuffer,consoleInHandle ;清除输入(通常是键盘)缓冲函式
	ret
CRIGHT:   ;啥时候需要更改方向呢？
		cmp esi,73H
		jz Change
		cmp esi,77H
		jz Change
		JMP InputEnd
CLEFT:
		cmp esi,73H
		jz Change
		cmp esi,77H
		jz Change
		JMP InputEnd
CDROW:
		cmp esi,61H
		jz Change
		cmp esi,64H
		jz Change
		JMP InputEnd
CUP:
		cmp esi,61H
		jz Change
		cmp esi,64H
		jz Change
		JMP InputEnd
Change:
	movzx edi,al 
	mov SnDir,edi
	jmp InputEnd
GetInput endp

;按照坐标来绘制蛇头和蛇身
updateSn PROC USES eax ecx ebx
	;修改蛇尾
	mov eax,TailX
	mov ebx,TailY
	;testInt eax
	;testInt ebx
	SetRT al,bl
	;testU
	;绘制蛇头
	mov ecx,1
	mov edi,0
head:
	mov eax,(SnakePoint PTR PointH[edi]).X
	mov ebx,(SnakePoint PTR PointH[edi]).Y
	SetHP al,bl
	add edi,TYPE SnakePoint
Loop head
	;绘制蛇的身体
	mov ecx,SnLen
	;mov edi,TYPE SnakePoint
body:
	mov eax,(SnakePoint PTR PointH[edi]).X
	mov ebx,(SnakePoint PTR PointH[edi]).Y
	SetSn al,bl
	add edi,TYPE SnakePoint
Loop body
	ret
updateSn endp

;检查蛇是否吃到食物或者是否碰到墙或者是否碰到蛇的身体
checkBody PROC USES eax edi ecx edx
	;判断蛇头是否碰到边框(测试完毕)
	mov edi,0
	mov eax,(SnakePoint PTR PointH[edi]).X
	mov edx,(SnakePoint PTR PointH[edi]).Y
	.if eax<=0
		jmp GameOver
	.elseif eax>18
		jmp GameOver
	.elseif edx<=1
		jmp GameOver
	.elseif edx>38
		jmp GameOver
	.endif
	;判断蛇头是否碰到蛇身(待测试)
	mov eax,(SnakePoint PTR PointH[0]).X
	mov edx,(SnakePoint PTR PointH[0]).Y
	mov ecx,SnLen
	mov edi,0
	SBody:
		add edi,TYPE SnakePoint
		mov temp,0
		cmp (SnakePoint PTR PointH[edi]).X,eax
		jz SBo
		Sbod:
			cmp (SnakePoint PTR PointH[edi]).Y,edx
			jz SBe
		Sboe:		
			.if temp==2
				jmp GameOver
			.endif
	Loop SBody
	
	;判断蛇头是否碰到食物
	mov edi,0
	mov temp,0
	mov eax,(SnakePoint PTR PointH[0]).X
	cmp FoodY,eax
	jz ta
	reTa:
		mov eax,(SnakePoint PTR PointH[0]).Y
		cmp FoodX,eax
		jz te
	reTe:	
		.if temp==2
			jmp addBody
		.endif
finish:	
	ret
ta:
	add temp,1
	jmp reTa	
te:
	add temp,1
	jmp reTe
SBo:
	add temp,1
	jmp Sbod	
SBe:
	add temp,1
	jmp Sboe
GameOver:
	;响铃
	mov al,07H
	call WriteChar 
	;弹窗提示失败
	mov ebx,OFFSET caption 
	mov edx,OFFSET overed
	call MsgBox
	mov control,0
	mov eax,white+(black*16)
	call SetTextColor
	;exit
	jmp finish
addBody:
	mov ecx,SnLen
	mov edi,SnLen
	imul edi,TYPE SnakePoint
	add edi,TYPE SnakePoint
	mov eax,TailX
	mov (SnakePoint PTR PointH[edi]).X,eax
	mov eax,TailY
	mov (SnakePoint PTR PointH[edi]).Y,eax
	mov ecx,(SnakePoint PTR PointH[edi]).X
	SetSn cl,al
	add SnLen,1
	call DrawScore 
	call SnackFood
	jmp finish
checkBody endp

;按照既定的方向来移动蛇的身体
move PROC USES eax ecx edx edi
	;先定位到蛇尾的位置
	mov edi,SnLen
	;testInt SnLen
	imul edi,TYPE SnakePoint
	mov eax,(SnakePoint PTR PointH[edi]).X
	mov edx,(SnakePoint PTR PointH[edi]).Y
	mov TailX,eax
	mov TailY,edx
	;先将前方的数据往后移一位
	mov ecx,SnLen
	mov edi,SnLen
	imul edi,TYPE SnakePoint
A:
	sub edi,TYPE SnakePoint
	mov eax,(SnakePoint PTR PointH[edi]).X
	add edi,TYPE SnakePoint
	mov (SnakePoint PTR PointH[edi]).X,eax
	;testInt (SnakePoint PTR PointH[edi]).X
	sub edi,TYPE SnakePoint
	mov eax,(SnakePoint PTR PointH[edi]).Y
	add edi,TYPE SnakePoint
	mov (SnakePoint PTR PointH[edi]).Y,eax
	
	sub edi,TYPE SnakePoint
Loop A
	;testInt (SnakePoint PTR PointH[16]).Y
	;处理蛇头位置的移动
	;下
	cmp SnDir,77H
	jz U 
	;上
	cmp SnDir,73H
	jz D
	;右
	cmp SnDir,64H
	jz R
	;左
	cmp SnDir,61H
	jz LEF
outNew:	
	;开始重新绘画蛇的身体
	;call addTemp
	;检查游戏是否结束
	call checkBody
	.if control==0
		jmp moveEnd
	.endif
	call updateSn
moveEnd:	
	ret 	
U:	
	mov eax,(SnakePoint PTR PointH[0]).X
	sub eax,1
	mov (SnakePoint PTR PointH[0]).X,eax
	jmp outNew
D:	
	mov eax,(SnakePoint PTR PointH[0]).X
	add eax,1
	mov (SnakePoint PTR PointH[0]).X,eax
	jmp outNew
R:	
	mov eax,(SnakePoint PTR PointH[0]).Y
	add eax,1
	mov (SnakePoint PTR PointH[0]).Y,eax
	jmp outNew
LEF:
	mov eax,(SnakePoint PTR PointH[0]).Y
	sub eax,1
	mov (SnakePoint PTR PointH[0]).Y,eax
	jmp outNew
move endp

;产生贪吃蛇要吃的食物
SnackFood PROC USES ecx edx eax ebx
Begin:
	;产生0-38的随机整数
	mov eax,37
	call RandomRange
	;产生的整数位于墙的位置上，重新生成
	.if eax<2
		jmp Begin
	.endif
	mov ebx,eax
	;将随机数放于存储食物坐标的坐标上
	mov FoodX,eax
	;testInt FoodX
New:
	mov eax,17
	call RandomRange
	.if eax<=2
		jmp New
	.endif
	mov FoodY,eax
	mov ecx,SnLen
	add ecx,1
	;检查生成食物的地方和
	mov edi,0
S:
		mov ebx,FoodX
		mov temp,0
		cmp ebx,(SnakePoint PTR PointH[edi]).Y
		jz recoding
	reC:
		mov eax,FoodY
		cmp eax,(SnakePoint PTR PointH[edi]).X
		jz recodingTwo
	reCTwo:
		.if temp==2
			JMP Begin
		.endif
	add edi,TYPE SnakePoint
Loop S
success:
	;第bl行，第al列
	SetFd al,bl
	ret
recoding:
	add temp,1
	jmp reC
recodingTwo:
	add temp,1
	jmp reCTwo
SnackFood endp

;写出相应的得分
DrawScore PROC USES edx eax
	;将坐标移到(0,41)
	mov dh,0
	mov dl,41
	call Gotoxy
	mov edx,OFFSET score
	mov eax,red+(black*16)
	call SetTextColor
	call WriteString
	;写得分
	mov eax,SnLen
	sub eax,2
	call WriteDec
	ret
DrawScore endp

END main
