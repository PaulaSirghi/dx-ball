.386
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
window_title DB "DX BALL",0
area_width EQU 640
area_height EQU 480
area DD 0
init DD 0
conto dd 0
atins1 dd 0
atins2 dd 0
atins3 dd 0
atins4 dd 0
win dd 0

counter DD 0 ; numara evenimentele de tip timer

arg1 EQU 8     ;constante
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

symbol_width EQU 40
symbol_height EQU 10

include digits.inc
include letters.inc
include caractere.inc

sem dd 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
x_caramida dd 310,350,390,430,470,470,430,390,350,310, 270,230,190,150,150,190,230, 270,290,330,270,350,310,250,230,220,370,390,410 
y_caramida dd 70, 60, 50, 60, 70, 80 , 90 ,100,90, 80, 90, 100, 90, 80,70,  60, 50,  60,100,100,110,110, 90,120,130,140,120,130,140 
n dd $-y_caramida
bila_x dd 335
bila_y dd 410
y_min equ 10
y_max equ 420
x_min equ 50
x_max equ 620
counterOK dd 0

;34 453
stgX dd 290
stgY dd 450
drX dd 340
drY dd 450

mut dd 0
alta dd 0
ct dd 0
culoareD dd 0

button_x EQU 50
button_y EQU 10

stg dd 0
dr dd 0 

paletaX dd 320
paletaY dd 420

yRETINUT dd y_min 

p dd 0

button_size EQU 420
.code
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'a'
	jl make_digit
	cmp eax, 'n'
	jg make_digit
	mov alta,0
	mov culoareD,0
	cmp eax, 'b' 
	je cul
	cmp eax, 'd'
	je cul2
	cmp eax, 'e'
	je cul3
	cmp eax, 'f' 
	je cul3
	cmp eax, 'g' 
	je cul3
	cmp eax, 'h' 
	je cul3
	cmp eax, 'i' 
	je cul3
	cmp eax, 'j' 
	je cul2
	cmp eax, 'k' 
	je cul2
	cmp eax, 'l' 
	je cul2
	cmp eax, 'm' 
	je cul2
	cmp eax, 'n' 
	je cul2
	sub eax, 'a'
	lea esi, caractere
	jmp draw_text
	cul:
		inc ct
		mov ecx, ct
		shl ecx,1 
		jp al2
		mov alta,1
		jmp peste
		al2: mov alta,2
		peste:
		sub eax, 'a'
		jmp pestesf
	cul2:
		mov culoareD,1
		sub eax, 'a'
		jmp pestesf
	cul3:
		mov culoareD,5
		sub eax, 'a'
		jmp pestesf
	pestesf:
	lea esi, caractere
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space 
	sub eax, '0'
	lea esi, digits
	jmp draw_text

make_space:	
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters	

draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	cmp alta,1 
	je diferit
	cmp alta,2 
	je diferit2
	cmp culoareD,1
	je diferit3
	cmp culoareD,5 
	je diferit4
	mov dword ptr [edi], 0ffff00h;0ff0000h
	jmp simbol_pixel_next
	diferit:
	mov dword ptr [edi], 033ccffh
	jmp simbol_pixel_next
	diferit2:
	mov dword ptr [edi], 00066ffh
	jmp simbol_pixel_next
	diferit3:
	mov dword ptr [edi], 0ff0000h
	jmp simbol_pixel_next
	diferit4:
	mov dword ptr [edi], 000FF00h
	jmp simbol_pixel_next
	
simbol_pixel_alb:   ;negru
	mov dword ptr [edi],0
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm

line_horizontal macro x,y,len,color
local repetaH  ;il folosim in mai multe locuri
	mov eax,y ;eax=y
	mov ebx, area_width 
	mul ebx ;nu putem inmulti cu o constanta
	add eax,x ;eax=y*area_width+x
	shl eax,2   ;inmultim cu 4
	add eax,area 
	mov ecx,len 
	repetaH:
		mov dword ptr[eax],color
		add eax,4
	loop repetaH
endm

linie_vertical macro x,y,len,color
local repetaO
	mov eax,y
	mov ebx,area_width
	mul ebx
	add eax,x
	shl eax,2
	add eax,area
	mov ecx,len
	repetaO:
		mov dword ptr[eax],color
		add eax,area_width*4
	loop repetaO
endm

; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click)
; arg2 - x   -coordonate unde s-a dat click
; arg3 - y
draw proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1]
	cmp eax, 1   ;eveniment de click
	jz evt_click
	cmp eax, 2	;eveniment de timer
	jz evt_timer ; nu s-a efectuat click pe nimic
	;mai jos e codul care intializeaza fereastra cu pixeli albi
	mov eax, area_width   ;altfel initializam zona=>memmset se umple cu 255 (punem pixeli albi peste tot)
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 0
	push area
	call memset
	add esp, 12
	jmp afisare_litere
	
evt_click: ;se arunca mingea

	mov  eax,[ebp+arg2]  ;x
	cmp eax,stgX 
	jl sar1
	mov ebx,stgX
	add ebx,symbol_width
	cmp eax,ebx
	jg sar1 
	mov eax,[ebp+arg3] ;y
	cmp eax,stgY
	jl sar1 
	mov ebx,stgY
	add ebx,symbol_height
	cmp eax,ebx
	jg sar1 
	mov stg,1
	jmp actual
	
	sar1:
		mov  eax,[ebp+arg2]  ;x
		cmp eax,drX 
		jl sar2
		mov ebx,drX
		add ebx,symbol_width
		cmp eax,ebx
		jg sar2 
		mov eax,[ebp+arg3] ;y
		cmp eax,drY
		jl sar2 
		mov ebx,drY
		add ebx,symbol_height
		cmp eax,ebx
		jg sar2 
		mov dr,1
		jmp actual
	
	sar2:
	mov mut,1
     actual:
	jmp afisare_litere
evt_timer:
	
	cmp win,1 
	je afisare_litere
	cmp p,1 
	je afisare_litere
	
	mov ebx,conto
	cmp ebx,n 
	jne departe
	make_text_macro 'g', area, 10,50  ;w
	make_text_macro 'h', area, 13,70  ;i
	make_text_macro 'i', area, 10,90  ;n
	make_text_macro 'a', area, bila_x,bila_y  ;stergem bila 
	jmp castig
	
	departe:
	
	inc counter
	;in jos y creste si in sus scade
	
	cmp mut,0
	je dif
		make_text_macro 'c', area, bila_x, bila_y 
	mov edx,10
	cmp bila_y, y_max
	je jos
	cmp bila_y,y_min
	je sus
	jmp nu
	jos:
		mov ecx,1  ;;am atins marginea de jos
		jmp nu
	sus:
	mov ecx,2  ;;am atins marginea de sus
	nu:
	cmp ecx,1
	je  scad
	
	cmp ecx,2
	je adun
	
	cmp init,0  ;;stare initiala, merge in sus
	je scad
	
	cmp init,1
	je adun
	
	cmp init,3 
	je diagonalaSTsus
	
	cmp init,4
	je diagonalaDRsus
	
	cmp init,5
	je diagonalaSTjos
	
	cmp init,6
	je diagonalaDRjos
	
	jmp scad ;;stare initiala
	
	scad:  ;;merg in sus
		cmp init,3
		je diagonalaSTsus
		cmp init,4
		je diagonalaDRsus
		cmp init,5
		je diagonalaSTjos
		cmp init,6
		je diagonalaDRjos
		sub bila_y,edx
		mov init,0
		jmp aici
		
	diagonalaSTjos:
		 
		 
		 mov ebx,bila_y
		add ebx,symbol_height
		cmp ebx,paletaY
		jl nuPlaca2
		mov ebx,bila_x
		add ebx,symbol_width
		sub ebx,30 ;scadem pixelii de 0
		cmp ebx,paletaX
		jl pierd2
		mov ebx,paletaX
		add ebx,symbol_width
		cmp ebx,bila_x
		jl pierd2
		mov ebx,bila_x
		add ebx,symbol_width
		sub ebx,30 ;scadem pixelii de 0
		mov ecx,paletaX
		add ecx,10    ;;daca loveste paleta intre paletax+10 si paletax+30, mingea merge in sus, daca nu o ia la 45 de grade
		cmp ebx,ecx 
		jl diagonalaSTsus
		add ecx,20
		cmp ebx,ecx 
		jg diagonalaDRsus
		mov init,0
		jmp scad 
		
		pierd2:
		mov p,1
		make_text_macro 'c', area, bila_x, bila_y 
		jmp scrie

		
		 nuPlaca2:
		 cmp atins1,1
		 jne vaContinua
		 mov atins1,0
		 jmp diagonalaSTsus
		 vaContinua:
		 mov ebx,bila_x
		 cmp ebx,x_min
		 jle diagonalaDRjos
		 sub bila_x,10
		 add bila_y,10 
		 make_text_macro 'c', area, bila_x, bila_y 
		 mov init,5
		 jmp aici
		
	diagonalaDRjos:
		

		
		mov ebx,bila_y
		add ebx,symbol_height
		cmp ebx,paletaY
		jl nuPlaca
		mov ebx,paletaX
		add ebx,symbol_width
		cmp ebx,bila_x
		jl pierd3
		
		mov ebx,bila_x
		add ebx,symbol_width
		sub ebx,30 ;scadem pixelii de 0
		cmp ebx,paletaX
		jl pierd3
		
		mov ecx,paletaX
		add ecx,10    ;;daca loveste paleta intre paletax+10 si paletax+30, mingea merge in sus, daca nu o ia la 45 de grade
		cmp ebx,ecx 
		jl diagonalaSTsus
		
		add ecx,20
		cmp ebx,ecx 
		jg diagonalaDRsus
		mov init,0
		jmp scad  
		
		pierd3: 
		mov p,1
		make_text_macro 'c', area, bila_x, bila_y 
		jmp scrie
		
		
		nuPlaca:
		cmp atins1,1
		jne vaContinua2
		mov atins1,0
		jmp diagonalaDRsus
		vaContinua2:
		mov ebx,bila_x
		cmp ebx,x_max
		jge diagonalaSTjos
		add bila_x,10
		add bila_y,10 
		make_text_macro 'c', area, bila_x, bila_y 
		mov init,6
		jmp aici
	
	diagonalaSTsus:
		;loveste paleta pe marginea stanga deci va merge la stanga cu un unghi de 45 de grade

		
		cmp atins1,1
		jne vaContinua3
		mov atins1,0
		jmp diagonalaDRsus
		
		vaContinua3:
		mov ebx,bila_x
		cmp ebx,x_min
		jle diagonalaDRsus
		mov ebx,bila_y
		cmp ebx,y_min
		jng diagonalaSTjos
		sub bila_x,10
		sub bila_y,10 
		make_text_macro 'c', area, bila_x, bila_y 
		mov init,3
		jmp aici
	diagonalaDRsus:
		cmp atins1,1
		mov atins1,0
		jne vaContinua4
		jmp diagonalaDRjos
		vaContinua4:
		mov ebx,bila_y
		cmp ebx,y_min
		jle diagonalaDRjos
		mov ebx,bila_x
		add ebx,symbol_width
		sub ebx,30                                                                                               
		cmp ebx,x_max
		jge diagonalaSTsus
		add bila_x,10
		sub bila_y,10
		make_text_macro 'c', area, bila_x, bila_y 
		mov init,4
		jmp aici
	nuDig:
		mov ebx,bila_y
		add ebx,symbol_height
		cmp ebx,paletaY
		je pierd
		jmp aici
	adun:   ;;merg in jos
		cmp init,3
		je diagonalaSTsus
		cmp init,4
		je diagonalaDRsus
		cmp init,5
		je diagonalaSTjos
		cmp init,6
		je diagonalaDRjos
		
		mov ebx,bila_y
		add ebx,symbol_height
		
		cmp ebx,paletaY
		jne continue2
		mov ebx,bila_x
		add ebx,symbol_width
		sub ebx,30 ;scadem pixelii de 0
		mov ecx,paletaX
		add ecx,10    ;;daca loveste paleta intre paletax+10 si paletax+30, mingea merge in sus, daca nu o ia la 45 de grade
		cmp ebx,ecx 
		jl diagonalaSTsus
		add ecx,20
		cmp ebx,ecx 
		jg diagonalaDRsus
		
		
		
		mov ebx,paletaX 
		add ebx,30 
		cmp ebx,bila_x  
		jl continue2
		jmp scad 
		
		

		
		continue2:
		mov ebx,bila_y
		add ebx,symbol_height
		cmp ebx,y_max
		je pierd
		add bila_y,edx
		mov init,1
		JMP aici
		
		pierd:
		mov p,1  ;;am pierdut
		
	aici:
	mov atins1,0
	mov esi,0
	repet:
	  cmp sem[esi],0
	  je dife
	  mov ebx,x_caramida[esi]
	 cmp bila_x,ebx	 		;;testam marginea stanga
	  jl dife
	  mov ebx,x_caramida[esi]
	  add ebx, symbol_width ;;testam si marginea dreapta
	  cmp bila_x,ebx
	  jg dife
	  
	  
	  
	  mov ebx,y_caramida[esi]
	  add ebx,symbol_height   ;yc-height>yb => nu o loveste
	  cmp bila_y,ebx
	  jg dife
	  mov ebx,bila_y   ;pastram yc initial si il comparam cu yb-height
	  add ebx,symbol_height
	  cmp y_caramida[esi],ebx  
	  jg dife 
	;nu s-a executat niciun jump deci a atins caramida
		mov atins1,1
		cmp sem[esi],0 
		je sarPeste
	   mov sem[esi],0
	   inc conto
	   mov ebx, conto
	   cmp ebx,n
	   jne sarPeste
	   make_text_macro 'g', area, 10,50  ;w
		make_text_macro 'h', area, 13,70  ;i
		make_text_macro 'i', area, 10,90  ;n
	    make_text_macro 'a', area, bila_x,bila_y  ;stergem bila 
		jmp castig
	   sarPeste:
	 make_text_macro 'c', area, x_caramida[esi], y_caramida[esi] 
	 
	 
	 
	 mov ebx,y_caramida[esi] ;vedem daca yc+height=yb => a lovit jos
	 add ebx,symbol_height
	 cmp bila_y,ebx
	 je joss 
	 
	 
	 
	 mov ebx,bila_y
	 add ebx,symbol_height
	 cmp y_caramida[esi],ebx
	 je suss
	 jmp dife
	 
	 
	 
	 joss:
	 mov edx,10
	 jmp adun
	 jmp dife
	 
	 suss:mov edx,10
		jmp scad
		jmp dife
	 
	 
	 
	 
	 dife:
	  inc esi
	  cmp esi,n
	jl repet
	
	dif: 
	cmp paletaX,x_min  
	je NUstg         ;nu iesim din extremitatea stanga
	cmp stg,1 
	jne NUstg
	cmp mut,1 
	je cont
	make_text_macro 'c', area, bila_x, bila_y
	sub bila_x,10
	cont:
	make_text_macro 'c', area, paletaX, paletaY
	sub paletaX,10
	
	mov stg,0
	NUstg:
	mov ebx,paletaX
	add ebx,symbol_width
	cmp ebx,x_max 
	je NUdr         ;nu iesim din extremitatea dreapta
	cmp dr,1 
	jne NUdr 
	cmp mut,1 
	je cont2
	make_text_macro 'c', area, bila_x, bila_y
	add bila_x,10
	cont2:
	make_text_macro 'c', area, paletaX, paletaY
	add paletaX,10
	mov dr,0
	
	NUdr:
	
	
	

afisare_litere:
	;scriem un mesaj
	cmp p,1 
	je scrie
	cmp win,1 
	je castig 
	
	mov esi,0
	mov ebx,n
	mov eax,1
	parcurg:
		cmp sem[esi],eax 
		je nuAmCastigat
		inc esi
		cmp esi,n
		jne parcurg
	jmp castig
		
	nuAmCastigat:	
	
	
	make_text_macro 'a', area, bila_x, bila_y ;;pentru minge 
	
	mov esi,0
	repeta:
	cmp sem[esi],1
	jne lovit
	make_text_macro 'b', area, x_caramida[esi],y_caramida[esi]

	lovit:
	inc esi
	cmp esi,n
	jl repeta
	 
	 make_text_macro 'd', area, paletaX,paletaY;
	 make_text_macro 'e', area, stgX,stgY;
	 make_text_macro 'f', area, drX,drY;
	 
	 line_horizontal button_x,button_y,button_size+button_size/3+11,0ffffffh  
	 line_horizontal button_x,button_y+button_size,button_size+button_size/3+11,0ffffffh 
	 linie_vertical button_x,button_y,button_size,0ffffffh
	 linie_vertical 620,button_y,button_size,0ffffffh
	 jmp final_draw
	 
	 scrie:
	 	make_text_macro 'j', area, 10,110  ;l
		make_text_macro 'k', area, 10,130 ;o
		make_text_macro 'l', area, 10,150 ;s
		make_text_macro 'm', area, 10,170  ;e
		make_text_macro 'n', area, 10,190  ;r

	jmp final_draw
	castig:
		make_text_macro 'g', area, 8,110  ;w
		make_text_macro 'h', area, 10,130  ;i
		make_text_macro 'i', area, 8,150  ;n
		mov win,1
	    make_text_macro 'c', area, bila_x,bila_y  ;stergem bila 

	 
final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	;alocam memorie pentru zona de desenat
	mov eax, area_width			;malloc
	mov ebx, area_height
	mul ebx
	shl eax, 2   ;inmultim cu 4 pentru ca fiecare pixel din zona de desenat ocupa un dword=4 bytes
	push eax
	call malloc
	add esp, 4
	mov area, eax
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw  ;procedura principala in programul nostru; se apeleaza la fiecare eveniment
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	;terminarea programului
	
	push 0
	call exit
end start
