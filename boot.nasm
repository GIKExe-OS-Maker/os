[BITS 16]
[ORG 0x7C00]

start:
	cli                     ; Отключить прерывания
	cld                     ; Очистить флаг направления

	; Загрузить сегменты
	xor ax, ax
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov fs, ax
	mov gs, ax

	; Настройка GDT
	lgdt [gdt_descriptor]

	; Включение A20 линии
	call enable_a20

	; Включение PAE (Physical Address Extension)
	mov ecx, 0xC0000080
	rdmsr
	or eax, 1 << 8
	wrmsr

	; Включение длинного режима
	mov ecx, 0xC0000080
	rdmsr
	or eax, 1
	wrmsr

	; Включение страниц
	mov cr4, cr4 | 0x20   ; PAE
	mov cr3, pml4_table   ; Загрузка PML4 таблицы
	mov cr0, cr0 | 0x80000000 ; Включение страниц

	; Переход в длинный режим
	jmp 08h:long_mode

[BITS 64]
long_mode:
	; Теперь мы в 64-битном режиме
	mov ax, 10h
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov fs, ax
	mov gs, ax

_start:
	mov rax, 0xB8000         ; Адрес видеопамяти
	mov rdi, rax             ; Копируем адрес в rdi для использования с movsb

	; Заполним буфер цветными символами
	mov rcx, string_len      ; Длина строки
	mov rsi, string          ; Адрес строки

fill_screen:
	lodsb                   ; Загрузить следующий символ в AL
	mov ah, 0x1F            ; Установить атрибут цвета (белый на синем фоне)
	stosw                   ; Записать символ и атрибут в видеопамять
	loop fill_screen        ; Повторить для всех символов

	; Заполнить оставшуюся часть экрана пробелами
	mov al, ' '             ; Пробел
	mov ah, 0x1F            ; Атрибут цвета (белый на синем фоне)
	mov rcx, 80*25 - string_len ; Количество оставшихся символов
fill_spaces:
	stosw                   ; Записать пробел и атрибут в видеопамять
	loop fill_spaces        ; Повторить для всех оставшихся символов

	; Остановить процессор
halt:
	hlt
	jmp halt

string db 'Hello, World!', 0
string_len equ $ - string

enable_a20:
	in al, 0x64
	test al, 2
	jnz enable_a20
	mov al, 0xD1
	out 0x64, al
	in al, 0x60
	or al, 2
	out 0x60, al
	ret

gdt_start:
gdt_null:
	dq 0x0000000000000000
gdt_code:
	dq 0x00A09A000000FFFF
gdt_data:
	dq 0x00A092000000FFFF
gdt_end:

gdt_descriptor:
	dw gdt_end - gdt_start - 1
	dd gdt_start

align 4096
pml4_table:
	dq pdp_table | 0x03
align 4096
pdp_table:
	dq pd_table | 0x03
align 4096
pd_table:
	times 512 dq 0x0000000000000000

times 510 - ($ - $$) db 0
dw 0xAA55
