[BITS 16]

%macro wGDT 4 ; limit, base, access, flags
	; 2 байта ограничение
	dw %1 & 0xFFFF

	; 3 байта база
	dw %2 & 0xFFFF
	db (%2 >> 16) & 0xFF

	; байт доступ
	db %3

	; 4 бита ограничение и 4 бита флаги
	db ((%4 & 0xF) << 4) + ((%1 >> 16) & 0xF)

	; байт база
	db (%2 >> 24)
%endmacro

%macro wIDT 2
	dw (%2 - $$ + 0x7C00) & 0xFFFF
	dw %1
	db 0, 10001110b
	dw (%2 - $$ + 0x7C00) >> 16
%endmacro


; переход в защищённый режим (32 бита)
mov ax, cs
mov ds, ax
mov es, ax
mov ss, ax

; mov sp, protected_entry ; вершина стека
mov sp, 0x7C00 ; вершина стека
mov bp, sp
	
; Включаем линию A20
in al, 0x92
or al, 2
out 0x92, al

; Выключаем ВСЕ прерывания
cli
in al, 0x70
or al, 0x80
out 0x70, al ; Disable non-maskable interrupts
	
; Загружаем Таблицы Дескрепторов
lgdt [GDTR]

mov eax, cr0
or  al, 1
mov cr0, eax


CODE_SELECTOR equ 0x08
 
jmp CODE_SELECTOR:protected_entry


; https://wiki.osdev.org/Global_Descriptor_Table
GDT:
	; пустой
	dq 0

	; код (селектор = 0x08)
	wGDT 0xFFFFF, 0, 10011010b, 1100b

	; данные (селектор = 0x10)
	wGDT 0xFFFFF, 0, 10010010b, 1100b

	; видеобуфер (селектор = 0x18)
	wGDT 0xFFFF, 0xB8000, 10010010b, 0100b

GDTR:
	dw $ - GDT - 1
	dd GDT


[BITS 32]
; ===================================== PM =====================================

protected_entry:
	mov ax, 16
	mov ds, ax
	mov ss, ax

	mov ax, 24
	mov es, ax

.main:
	jmp .main


times 510 + $$ - $ db 0
dw 0xAA55