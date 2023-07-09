;����һ������ʾ�ַ���,�൱�ڸ߼����Եĺ���
OutPutString MACRO buffer
	push edx
	mov edx,OFFSET buffer
	call WriteString
	call Crlf
	pop edx
ENDM

;���Ժ�
testU MACRO 
	mov dh,40
	mov dl,20
	call Gotoxy
	mov eax,white+(black*16)
	call SetTextColor 
	call WaitMsg
endm

;������Ϊ(x,y)�ķ����óɱ���ɫΪ��ɫ(������ͷ)
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

;������Ϊ(x,y)�ķ����óɱ���ɫΪ��ɫ(����������)
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

;������Ϊ(x,y)�ķ����óɱ���ɫΪ��ɫ(����ʳ��)
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

;������Ϊ(x,y)�ķ����óɱ���ɫΪ��ɫ(����ǽ�߿�)
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

;������Ϊ(x,y)�ķ����óɱ���ɫΪ��ɫ(������δ�߹��ĵط�)
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

;���������������(���Ƹ߼����ԵĽṹ��)
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
;�����е������
PointNum=800
ALIGN DWORD
PointH SnakePoint PointNum DUP(<0,0>)
;��¼�����ĳ���
SnLen DWORD 0
;��¼������ļ�¼
FoodX DWORD 0
FoodY DWORD 0
;��¼��β�͵�����
TailX DWORD 0
TailY DWORD 0
;�߿�Ŀ���
FrWidth BYTE 0
;�߿�ĳ���
FrLen  BYTE 0
;�߿�ķ���
fr BYTE "#",0
;������ķ���
sn BYTE "S",0
;��Ϸ����
overed BYTE "Game Over!",0
;��ʳ��ķ���
fd BYTE "Q",0
SnFood DWORD 0
;��¼����
SnDir DWORD 0
;��ʱ��������ʱ����
temp DWORD 0
caption BYTE "Survey Completed",0
consoleInHandle DWORD ? ; ����̨��׼������
score BYTE "Socre:",0
;����̰���ߵ��˶��ٶ�
select BYTE "Please select the Difficulty",0
diffOne BYTE "1.easy",0
diffTwo BYTE "2.common",0
diffThree BYTE "3.hard",0
diffFour BYTE "4.very hard",0
FiveOut BYTE "5.quit",0
errPro BYTE "Input Error ,enter common mode",0
delayTimes DWORD 300
;������Ƿ�ײǽ����ײ������������
control DWORD 1
.code 

;��ģ�飬ͨ����������ģ��ʵ��̰������Ϸ
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

;��Ϸ��ʼ
Game PROC
	call Clrscr
	call paintFrame
	call InitSnack           
	call SnackFood
	;D�������ң�A��������S�������£�W��������
	;��ʼ����������
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

;���ƾ��α߿�
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

;��ʼ���ߵ�����
InitSnack PROC USES eax ecx edx
	mov FrWidth,20
	mov ecx,2 
	mov edi,TYPE SnakePoint
	imul edi,2
I:
	;����������
	SetSn 10,FrWidth
	mov (SnakePoint PTR PointH[edi]).X,10
	;testInt (SnakePoint PTR PointH[edi]).X
	;�޷���������չ
	movzx  eax,FrWidth
	mov (SnakePoint PTR PointH[edi]).Y,eax
	;testInt (SnakePoint PTR PointH[edi]).Y
	add FrWidth,1
	;������ĳ���+1          
	add SnLen,1
	sub edi,TYPE SnakePoint
Loop I
	;��¼��β
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
	;������ͷ
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

;��Ϸ����
GetInput PROC USES ecx edx eax edi esi
	mov    eax,delayTimes            ; ��Ϣ�����������ӳ�
    	call    Delay
	call ReadKey
	jz InputEnd
	mov esi,SnDir
	.if AL==0
		jmp InputEnd
	.endif
	cmp AL,64H  ;��
	jz CRIGHT
	cmp AL,61H  ;��
	jz CLEFT
	cmp AL,73H  ;��
	jz CDROW
	cmp AL,77H ;��
	jz CUP
InputEnd:
	;testU
	INVOKE FlushConsoleInputBuffer,consoleInHandle ;�������(ͨ���Ǽ���)���庯ʽ
	ret
CRIGHT:   ;ɶʱ����Ҫ���ķ����أ�
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

;����������������ͷ������
updateSn PROC USES eax ecx ebx
	;�޸���β
	mov eax,TailX
	mov ebx,TailY
	;testInt eax
	;testInt ebx
	SetRT al,bl
	;testU
	;������ͷ
	mov ecx,1
	mov edi,0
head:
	mov eax,(SnakePoint PTR PointH[edi]).X
	mov ebx,(SnakePoint PTR PointH[edi]).Y
	SetHP al,bl
	add edi,TYPE SnakePoint
Loop head
	;�����ߵ�����
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

;������Ƿ�Ե�ʳ������Ƿ�����ǽ�����Ƿ������ߵ�����
checkBody PROC USES eax edi ecx edx
	;�ж���ͷ�Ƿ������߿�(�������)
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
	;�ж���ͷ�Ƿ���������(������)
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
	
	;�ж���ͷ�Ƿ�����ʳ��
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
	;����
	mov al,07H
	call WriteChar 
	;������ʾʧ��
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

;���ռȶ��ķ������ƶ��ߵ�����
move PROC USES eax ecx edx edi
	;�ȶ�λ����β��λ��
	mov edi,SnLen
	;testInt SnLen
	imul edi,TYPE SnakePoint
	mov eax,(SnakePoint PTR PointH[edi]).X
	mov edx,(SnakePoint PTR PointH[edi]).Y
	mov TailX,eax
	mov TailY,edx
	;�Ƚ�ǰ��������������һλ
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
	;������ͷλ�õ��ƶ�
	;��
	cmp SnDir,77H
	jz U 
	;��
	cmp SnDir,73H
	jz D
	;��
	cmp SnDir,64H
	jz R
	;��
	cmp SnDir,61H
	jz LEF
outNew:	
	;��ʼ���»滭�ߵ�����
	;call addTemp
	;�����Ϸ�Ƿ����
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

;����̰����Ҫ�Ե�ʳ��
SnackFood PROC USES ecx edx eax ebx
Begin:
	;����0-38���������
	mov eax,37
	call RandomRange
	;����������λ��ǽ��λ���ϣ���������
	.if eax<2
		jmp Begin
	.endif
	mov ebx,eax
	;����������ڴ洢ʳ�������������
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
	;�������ʳ��ĵط���
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
	;��bl�У���al��
	SetFd al,bl
	ret
recoding:
	add temp,1
	jmp reC
recodingTwo:
	add temp,1
	jmp reCTwo
SnackFood endp

;д����Ӧ�ĵ÷�
DrawScore PROC USES edx eax
	;�������Ƶ�(0,41)
	mov dh,0
	mov dl,41
	call Gotoxy
	mov edx,OFFSET score
	mov eax,red+(black*16)
	call SetTextColor
	call WriteString
	;д�÷�
	mov eax,SnLen
	sub eax,2
	call WriteDec
	ret
DrawScore endp

END main