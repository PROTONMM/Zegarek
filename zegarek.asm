[bits 16]
[org 0x7c00]
start:
%define petla_ile   16*8
%define vram_bufor  0x0800
%define vram_vga    0xb800
%define stos        0x07f0
;NOTES:
;B800:0000 - początek VRAM - tryb tekstowy
;8000:0000 - początek bufora
;AX - indeks pod który wielokrotnie kopiujemy wzorek do bufora
;BX - iterator, wielkokrotne kopiowane wzorka do bufora
;CX - iterator, kopiowanie do bufora i bufora do VRAM, instrukcje movsb stosb
;DX - DL kod koloru przy wrzucaniu wzorka do bufora
;VGA
;3D4h - Addres register
;3D5h - Data register
;0Ah  - Cursor Start register
;00100000 - cursor disable
;SEGMENT
;CS - Code Segment
;DS - Data Segment
;ES,FS,GS - Extra Segment
;SS - Stack Segment             -
;INDEX
;DI - Destination Index (ES:DI)
;SI - Source Index      (DS:SI)
;BP - Base Pointer      (SS:BP) -
;SP - Stack Pointer     (SS:SP) -
;IP - Index Pointer     (CS:IP) -
;###################################
;ustawienie stosu
;###################################
mov ax, stos
mov sp, ax
;###################################
;schowanie kursora
;###################################
mov al, 0x0A        ;Cursor Start register
mov dx, 0x3D4       ;Addres register
out dx, al
mov al, 0b00100000  ;Cursor disable
mov dx, 0x3D5       ;Data register
out dx, al
;###################################
;rejestracja obsługi przerwania w IVT
;###################################
;blokowanie cli nic nie daje, przewanie z timera jest NMI
cli
xor ax, ax
mov es, ax
mov bx, ax
mov word [es:bx+8*4+2], ax  ;segment
mov ax, IRQ0_handler
mov word [es:bx+8*4], ax    ;adres
;konfiguracja 8259 PIC  --  nie jest potrzebna, domyślna konfiguracja jest OK
; ICW 1
;mov al, 0x11
;out 0x20, al
;out 0xA0, al
; ICW 2
;mov al, 0x20
;out 0x21, al
;mov al, 0x28
;out 0xA1, al
; ICW 3
;mov al, 0x04
;out 0x21, al
;mov al, 0x02
;out 0xA1, al
; ICW 4
;mov al, 0x01
;out 0x21, al
;out 0xA1, al
;mov al, 0xfe   ;maskowanie przerwań, 1-blokuje, 0-aktywuje
;out 0x21, al   ;0xFE - odblokowane tylko INT 0
                ;0x01 - blokuje przerwanie z timera (IRQ 0)
;out 0xA1, al
sti
; zrobione
;###################################
;skok do głównego programu
;###################################
jmp word 0:code
;###################################
;IRQ0 Handler
;###################################
;Przerwanie jest wykonywane 18.2 razy na sekundę,
;zwiększa ono rejestr [rej_krok] o 1 przy każdym wywołanu,
;po przekroczeniu w rejestrze wartości 78, rejest jest zerowany.
IRQ0_handler:   
push ax
push di
push ds
xor di, di
mov ds, di
mov ax, [rej_krok]
inc ax
cmp ax,78
jle IRQ0_dalej
xor ax, ax
IRQ0_dalej:
mov [rej_krok], ax
mov al, 0x20            ;kasowanie przerwania w 8259
out 0x20, al
pop ds
pop di
pop ax
iret
;###################################
;Główna pętla
code:
;###################################
xor di, di      ;DI = 0000
mov ds, di      ;DS = 0000
;###################################
;ustawienie bufora: vram_bufor
mov ax, vram_bufor
mov es, ax      ;ES = vram_bufor
;###################################
;rysowanie kolorowego wzorka
;###################################
mov ax, [rej_krok]
mov [rej_przesuniecie], ax  ;kopiuje [rej_krok] do [rej_przesuniecie]
mov bx, petla_ile           ;ile razy ma być powtórzony wzorek,
petla_wzorka:
;wypisanie wzorka
mov ax, petla_ile
sub ax, bx
mov ax, [rej_przesuniecie]
shl ax, 1
mov di, ax ;DI - indeks pod który piszemy
;wybór koloru wzorka
mov dx, bx
and dx, 0b0000000000000011  ;maskowanie koloru
mov [rej_dx], dx
add dx, mapa_koloru
mov si, dx
mov dx, [si]    ;skopiowanie do DX kodu koloru
mov si, wzorek
mov cx, wzorek_dl
xor ax, ax
pisz_wzorek:
movsb
mov al, dl  ;kolor do AL
stosb
loop pisz_wzorek
;obliczanie przesunięcia wzorka
mov ax, [rej_przesuniecie]  ;wczytanie przesunęcia z pamięci
add ax, wzorek_dl
mov dx,[rej_dx]
cmp dl, 3
jne dalej_0
add ax, 39
dalej_0:
mov [rej_przesuniecie], ax  ;zapamiętanie przesunięcia w pamięci
dec bx
jnz petla_wzorka
;###################################
;skopiowanie tekstu do bufora
;###################################
mov di, (80*12+40-10)*2
mov si, text
mov cx, text_dl
;push bx
mov bx, [rej_krok]
shr bx, 1           
shl bx, 4           ;kolor tła
or bx, 0x0e         ;dodanie koloru czczionki do koloru tła
write:
movsb               ;mov byte DS:SI ->  ES:DI
mov al, bl          ;KOD KOLORU
stosb               ;store AL at address ES:DI
loop write
;pop bx
;###############################################
;odczyt godziny (tryb BCD) i zapisanie do bufora
;###############################################
clc
xor ax, ax
xor bx, bx
xor cx, cx
xor dx, dx
mov ah, 0x2
int 1ah
 
;przetwarzanie godziny
;godzina
xor ax, ax
mov al, ch
shr al, 4
add al, "0"
mov [data], al
 
mov al, ch
and al, 0b00001111
add al, "0"
mov [data+1], al
 
mov al,":"
mov [data+2], al
 
;minuta
mov al, cl
shr al, 4
add al, "0"
mov [data+3], al
 
mov al, cl
and al, 0b00001111
add al, "0"
mov [data+4], al
 
mov al,":"
mov [data+5], al
 
;sekunda
mov al, dh
shr al, 4
add al, "0"
mov [data+6], al
 
mov al, dh
and al, 0b00001111
add al, "0"
mov [data+7], al
 
mov al, " "
mov [data+8], al
mov [data+9], al
 
;wypisanie godziny
mov di, (80*13+40-4)*2
mov si, data
mov cx, data_dl-2
write2:
movsb
mov al, 4
stosb
loop write2
 
;#########################################
;odczyt daty i zapisanie do bufora
;#########################################
clc
xor ax, ax
xor bx, bx
xor cx, cx
xor dx, dx
mov ah, 0x4
int 1ah
 
;przetwarzanie daty
;century
xor ax, ax
mov al, ch
shr al, 4
add al, "0"
mov [data], al
 
mov al, ch
and al, 0b00001111
add al, "0"
mov [data+1], al
 
;rok
mov al, cl
shr al, 4
add al, "0"
mov [data+2], al
 
mov al, cl
and al, 0b00001111
add al, "0"
mov [data+3], al
 
mov al,"-"
mov [data+4], al
 
;miesiac
mov al, dh
shr al, 4
add al, "0"
mov [data+5], al
 
mov al, dh
and al, 0b00001111
add al, "0"
mov [data+6], al
 
mov al,"-"
mov [data+7], al
 
;dzien
mov al, dl
shr al, 4
add al, "0"
mov [data+8], al
 
mov al, dl
and al, 0b00001111
add al, "0"
mov [data+9], al
 
;wypisanie daty
mov di, (80*14+40-5)*2
mov si, data
mov cx, data_dl
write3:
movsb
mov al, 6
stosb
loop write3
 
;czekanie na klawisz
;xor ax, ax
;int 16h
;#########################################
; kopiowanie bufora do VRAM
;#########################################
;UWAGA zmiana segmentów ES i DS
mov ax, vram_vga
mov es, ax 
mov ax, vram_bufor
mov ds, ax
;mov cx, 80*25*2
mov cx, 80*25
mov si, 80*2      ;zamaskowanie górnej lini.
xor di, di
;rep movsb
rep movsw
jmp code
 
; stop
jmp $
 
;#########################################
;#########################################
;#########################################
;text  db "<HTTP://SPECCY.PL>"
text db " HTTP://MICROGEEK.EU "
text_dl equ $ - text
wzorek db 0,176,177,219,219,219,219,177,176,0
wzorek_dl equ $ - wzorek
mapa_koloru db 0x2,0xE,0x4,0x1
;TODO: to można umieścić poza pamiecią programu
rej_dx dw 0
rej_kolor dw 0
rej_przesuniecie dw 0
rej_krok dw 0
data times 10 db " "
data_dl equ $ - data
;#########################################
;uzupełnienie do 1,44MB
;#########################################
times (510-($-start)) db 0
db 0x55, 0xAA
times ((1440*1024)-($-start)) db 0
;#########################################
;kompilacja:
;nasm zegar.asm -o zegar.img
;#########################################