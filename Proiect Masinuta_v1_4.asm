.386
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem msvcrt.lib, si declaram ce functii vrem sa importam
includelib msvcrt.lib 

extern printf: proc
extern scanf: proc
extern system: proc
extern exit: proc

; include \masm32\include\windows.inc
; include \masm32\include\kernel32.inc
; include \masm32\include\msvcrt.inc
; include \masm32\macros\macros.asm
	
; includelib masm32.lib
; extern  crt__getch: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data

window_title DB "Masinuta",0
area_width EQU 140
area_height EQU 300
area DD 0

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

symbol_width EQU 20
symbol_height EQU 20

autoplay_role DD 0
i DD 0
j DD 0
insert_ramas DD 0
nr_obstacole DB 0
poz_masinuta DD 0
obs_poz_nou DD 0
obs_poz_veche DB 0
aux DB 0
tasta DB 0
stalp DB "*", 0
masina DB "@", 0
spatiu DB " ", 0
linie_noua DB " ", 10, 0
sfarsit_joc DB 1
curatam_ecran DB "cls", 0
format DB "%d", 0
format2 DB "%c", 0
text_scor DB "Timp Supravietuit HUAHAHAHAH : %d", 10, 0
text_good DB "Welcome to the game NOOB", 10, 0
text_epic DB "YOU are good, are'n you", 10, 0 
text_legendary DB "LEGEND RANK ACHIEVED", 10, 0
text_auto_play_bot DB "YOU, good SIR, ARE USING AUTOPLAY", 10, 0
scor_actual DD 0
harta DB 105 DUP(0)
obstacol DB 105 DUP(0)

.code
initializare_harta proc		; subprogram de initializare a valorilor -->> 1 - spatiu ; 0 - obstacol ( margine de careu) ; 3 - locatie masinuta
	mov i, 0
	primul_loop:
		mov j, 0
		doilea_loop:		
			cmp i, 0		;pentru crearea zidurilor dreptunghiului
			je facem_0
			cmp i, 14
			je facem_0
			cmp j, 0
			je facem_0
			cmp j, 6
			je facem_0
			
			mov eax, i		; pentru crearea spatiului
			mov ecx, 7
			mul ecx
			add eax, j
			mov harta[eax], 1	
			mov obstacol[eax], 1		; nu vom avea nici un obiect la inceput asa ca punem 1
			jmp mergem
			facem_0:					
				mov eax, i
				mov ecx, 7
				mul ecx
				add eax, j
				mov harta[eax], 0
				mov obstacol[eax], 1	; -||- ^
			mergem:
				inc j
		cmp j, 7
		jb doilea_loop
		inc i
	cmp i, 15
	jb primul_loop
	mov poz_masinuta, 94
	mov harta[94], 3		; pozitia de start a masinutei
	ret
initializare_harta endp

desenam_imagine proc		; subprogram de desenare pe consola
	mov i, 0
	primul_loop:
		mov j, 0
		doilea_loop:
			mov eax, i		; ne deplasam prin matrice cu astea 4 linii 
			mov ecx, 7
			mul ecx
			add eax, j
			cmp harta[eax], 0
			je scriem_stalp
			cmp harta[eax], 1
			je scriem_spatiu
			
			push offset masina
			call printf
			add esp, 4
			jmp gata
			
			scriem_spatiu:
				mov eax, i
				mov ecx, 7
				mul ecx
				add eax, j
				cmp obstacol[eax], 0		; verificam daca nu exista un obiect de scris in loc de spatiu
				je scriem_stalp		
				
				push offset spatiu
				call printf
				add esp, 4
				jmp gata
			scriem_stalp:
				push offset stalp
				call printf
				add esp, 4
				jmp gata
			gata:
		inc j
		cmp j, 7
		jb doilea_loop
		
		push offset linie_noua
		call printf
		add esp, 4
		
		inc i
	cmp i, 15
	jb primul_loop
	
	mov eax, scor_actual
	
	push eax
	push offset text_scor
	call printf
	add esp, 8
	
	cmp scor_actual, 10
	jb gata_text
	cmp scor_actual, 70
	jb noob
	cmp scor_actual, 150
	jb epic
	cmp scor_actual, 220
	jb legend
	
	push offset text_auto_play_bot
	call printf
	add esp, 4
	jmp gata_text
	
	noob:
	push offset text_good
	call printf
	add esp, 4
	jmp gata_text
	
	epic:
	push offset text_epic
	call printf
	add esp, 4
	jmp gata_text
	
	legend:
	push offset text_legendary
	call printf
	add esp, 4
	jmp gata_text
	
	gata_text:
	ret
desenam_imagine endp

pauza proc				; suspendam operatiile din cadrul jocului
	ret					; o scriem dupa ce imi dau seama cum citesc de la tastatura
pauza endp

logica_stanga proc		; deplasam masinuta la stanga cu o pozitie
	cmp poz_masinuta, 92
	jle gata_log_stanga
		mov eax, poz_masinuta 
		mov harta[eax], 1
		dec poz_masinuta
		mov eax, poz_masinuta
		mov harta[eax], 3
	gata_log_stanga:
	ret
logica_stanga endp

logica_dreapta proc		; deplasam masinuta la dreapta cu o pozitie
	cmp poz_masinuta, 96	
	jge gata_log_dreapta
		mov eax, poz_masinuta
		mov harta[eax], 1
		inc poz_masinuta
		mov eax, poz_masinuta
		mov harta[eax], 3
	gata_log_dreapta:
	ret
logica_dreapta endp

logica_key proc		; interpretam comenzile citie de la tastatura
	cmp tasta, 'a'		;A/a
	je mergem_stanga
	cmp tasta, 'd'		;D/d
	je mergem_dreapta
	cmp tasta, 'p'		;P/p
	je mergem_pauza
	cmp tasta, 01h		;Esc
	jne gata_log
	push 0
	call exit
	mergem_stanga:
		call logica_stanga
		jmp gata_log 
	mergem_dreapta:
		call logica_dreapta
		jmp gata_log
	mergem_pauza:
		call pauza
		jmp gata_log
	gata_log:
	ret
logica_key endp

autoplay_1 proc
	mov eax, poz_masinuta
	sub eax, 7
	cmp obstacol[eax], 1
	je stam_pe_loc
	
	sub eax, 1
	cmp obstacol[eax], 1
	jne incercam_dreapta
	
	call logica_stanga
	jmp stam_pe_loc
	
	incercam_dreapta:
	
	call logica_dreapta
	jmp stam_pe_loc
	
	stam_pe_loc:
	ret
autoplay_1 endp

autoplay_2 proc
	mov eax, poz_masinuta
	sub eax, 7
	cmp obstacol[eax], 1
	je stam_pe_loc
	
	add eax, 1
	cmp obstacol[eax], 1
	jne incercam_stanga
	
	call logica_dreapta
	jmp stam_pe_loc
	
	incercam_stanga:
	
	call logica_stanga
	jmp stam_pe_loc
	
	stam_pe_loc:
	ret
autoplay_2 endp

obstacol_nou proc					; ne pregatim sa inseram un nou obiect ( adica cream urmatoarea linie care va fi inserata )
	cmp insert_ramas, 0				; daca mai avem de inserat din obiectul precedent continuam sa facem asta
	je inseram_nou
									; daca nu inseram unul nou
	mov i, 0						; eliminam orice urma de la vechiul obiect inserat initializand linia cu " " ( spatii)
	loop_1:
		mov eax, i
		mov obstacol[eax], 1	
		inc i
	cmp i, 7
	jb loop_1	
	
	mov al, obs_poz_veche
	mov obstacol[eax], 0				; adaugam locatia varfului obiectului pe harta
	dec insert_ramas
	
	jmp gata
	inseram_nou:
		mov eax, obs_poz_nou		; formula pentru alegerea noii pozitii a obiectului ( puteam sa fac o functie de generare aleatoare dar a fost mai usor sa creez o formula random)
		mov ecx, 5
		div cl
		
		mov aux, al
		mov eax, 0
		mov al, aux
		inc eax
		
		mov ecx, 3
		mul ecx
		mov ecx, 7
		div cl
		
		cmp ah, 0
		je adun_1
		cmp ah, 6
		je scad_1
		jmp mere
		adun_1:
			inc ah
			jmp mere
		scad_1:
			dec ah
			jmp mere
		mere:
		mov obs_poz_veche, ah	; memoram pe ce pozitie dorim sa inseram urmatorul obiect
		mov insert_ramas, 4		; cat de lung dorim sa fie ( si partea asta poate sa varieaze pentru o dinamica mai mare a jocului, momentan ii constanta)
	gata:
	ret
obstacol_nou endp

obstacol_logic proc			; mapam obiectele existente pe harta si actualizam urmatoarea lor pozitie
	mov i, 14
	primul_loop:
		mov j, 0
		doilea_loop:		; aici mutam toate obiectele existente cu o linie mai jos
			dec i
			mov eax, i
			mov ecx, 7
			mul ecx
			add eax, j
			mov bl, obstacol[eax]
			inc i
			
			mov eax, i
			mov ecx, 7
			mul ecx
			add eax, j
			
			mov obstacol[eax], bl
			
			inc j
		cmp j, 7
		jb doilea_loop
		dec i
	cmp i, 0
	ja primul_loop
	ret
obstacol_logic endp

verificare_corect proc		; subprogram de verificare a posibilelor locuri de endgame
	mov eax, poz_masinuta
	cmp obstacol[eax], 1
	je gata
	mov sfarsit_joc, 0
	jmp final
	gata:
	mov sfarsit_joc, 1
	final:
	ret						; ca la pauza
verificare_corect endp

start:
	call initializare_harta
	call desenam_imagine
	
	jocul_continua:
		push offset curatam_ecran
		call system
		add esp, 4
		
		call desenam_imagine
		
		call obstacol_logic
		call obstacol_nou
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;		
		; partea asta se ocupa cu citirea si interpretarea comenzilor de la tastatura
			;mov ah, 01h
			;int 16h 				; nu merge asa
			;jmp mai_departe
			;mov ah, 00h
			;int 16h
			;mov tasta, al
			;mov eax, 01h
			;int 21h
			;jz mai_departe
			;in al, 21	;Obtain scancode form Keyboart I/O Port
			;mov cl,al	;Store the scancode in CL for now
		;;	mov tasta, cl
		
		;;;;;;;;;;;;;;;;;;;;; citim de la tastatura
		push offset tasta
		push offset format2
		call scanf
		call logica_key
		push offset curatam_ecran
		call system
		add esp, 4
		;;;;;;;;;;;;;;;;;
		
		;;	in al,61h	
			;mov ah,al	
	;;		;or al,80h	
	;		o;ut 61h,al	
	;;		mov al,ah	
	;;		out 61h,al	
	;			mov al,cl	
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
			;nu_apasat_tasta:
			
			;cmp sfarsit_joc, 1
			;jne game_over
			
			;push offset sfarsit_joc
			;call verificare_corect
			;add esp, 4
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		; mov ebx, [ebp+arg1]
		; cmp ebx, 'A'
		; je stanga
		
		; cmp ebx, 'D'
		; je dreapta
		
		; jmp mai_departe1
		
		; stanga:
		; call logica_stanga
		; jmp mai_departe1
		; dreapta:
		; call logica_dreapta
		
		; mai_departe1:
		; cmp autoplay_role, 0
		; je autoplay1_1
		
		; mov autoplay_role, 0
		; call autoplay_2
		; jmp continuare
		
		; autoplay1_1:
		; mov autoplay_role, 1
		; call autoplay_1
		
		;mov ah, 07
		;int 21h
		; call crt__getch
		continuare:
		
		inc obs_poz_nou
		cmp obs_poz_nou, 100		; corectam mici erori in inserarea obiectelor
		jne mai_departe				; aia a fost la inceput --- acum nu mai trebuie dar nu strica la nimic *_*
		mov obs_poz_nou, 5
		
		mai_departe:
		call desenam_imagine
		call verificare_corect
		
		inc scor_actual
	
	cmp sfarsit_joc, 1
	je jocul_continua
	push 0
	call exit
end start
