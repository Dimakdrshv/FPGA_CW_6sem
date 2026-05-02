JMP $0030 // Адрес прерывания
LDL R0, $00 // Регистр режима
LDL R1, $00 // Адрес символа, выводимого на матричный индикатор в памяти
LDL R2, $FF // R
LDL R3, $FF // G
LDL R4, $FF // B
LDL R26, $F8
LDL R27, $50
STL X+, $00 // Вывод первого элемента последовательности матричного индикатора
STL X+, $FF // R = 255
STL X+, $FF // G = 255
STL X+, $FF // B = 255
LDL R26, $C0
LDL R27, $87
ST X+, R0 // Режим
STL X+, $FF // SEG5_4: R
STL X+, $FF // SEG3_2: G
STL X+, $FF // SEG1_0: B
STL X+, $00 // BLANK = 0
STL X+, $00 // DP_IN = 0
LDL R26, $06
LDL R27, $81
STL X+, $00 // LED7_0: 0
STL X+, $00 // LEDF_8: 0
LDL R26, $74
LDL R27, $02
STL X, $0F // Разрешение прерываний
LDL R30, $08 // Запись младшего байта указателя стека SP
LDL R31, $91 // Запись старшего байта указателя стека SP
LDL R26, $00
LDL R27, $90
STL X+, $0E // N1: E
STL X+, $0B // N2: B
STL X+, $07 // N3: 7
STL X+, $00 // N4: 0
STL X+, $06 // N5: 6
STL X+, $01 // N6: 1
STL X+, $08 // N7: 8
STL X+, $04 // N8: 4
STL X+, $09 // N9: 9
STL X+, $02 // N10: 2
STL X+, $0C // N11: C
STL X+, $0D // N12: D
STL X+, $0F // N13: F
STL X+, $05 // N14: 5
STL X+, $03 // N15: 3
STL X+, $0A // N16: A
JMP $002F // Бесконечный цикл
LDL R26, $70 // Загрузка адреса обработчика прерывания X[7:0]
LDL R27, $02 // Загрузка адреса обработчика прерывания X
LD R16, X // Проверка первого прерывания
SUB R16, $01
JMPC $0002, $1
STL X, $00
JMP $004A
INC R26
LD R16, X // Проверка второго прерывания
SUB R16, $01
JMPC $0002, $1
STL X, $00
JMP $0086
INC R26
LD R16, X // Проверка третьего прерывания
SUB R16, $01
JMPC $0002, $1
STL X, $00
JMP $009C
INC R26
LD R16, X // Проверка четвертого прерывания
SUB R16, $01
JMPC $0002, $1
STL X, $00
JMP $00B2
RETI
INC R0 // Первый обработчик
MOV R8, R0
SUB R8, $06
JMPC $0001, $1
LDL R0, $00
MOV R8, R0
SUB R8, $02
JMPC $000B, $1
LDL R26, $C0
LDL R27, $87
ST X, R0 // Режим смены кадра
MOV R28, R1
LDL R29, $90
LD R8, Y // Загрузка символа из памяти
LDL R26, $C3
LDL R27, $87
ST X+, R8 // Запись символа
STL X, $3C // BLANK = 0
JMP $0085
MOV R8, R0
SUB R8, $04
JMPC $0008, $1
LDL R26, $C0
LDL R27, $87
ST X+, R0 // Режим настройки матричного индикатора
ST X+, R2 // SEG5_4: R
ST X+, R3 // SEG3_2: G
ST X+, R4 // SEG1_0: B
STL X+, $00 // BLANK = 0
JMP $0085
LDL R26, $C0
LDL R27, $87
ST X+, R0 // Режим выполнения операции
LDL R28, $0C
LDL R29, $18
LD R8, Y // Загрузка операнда A
ST X+, R8
LDL R28, $61
LDL R29, $3E
LD R9, Y // Загрузка операнда B
ST X+, R9
MOV R10, R0 // Проверка режима
SUB R10, $00
JMPC $0001, $1
SUB R8, R9
MOV R10, R0 // Проверка режима
SUB R10, $01
JMPC $0001, $1
ADD R8, R9
MOV R10, R0 // Проверка режима
SUB R10, $03
JMPC $0001, $1
OR R8, R9
MOV R10, R0 // Проверка режима
SUB R10, $05
JMPC $0001, $1
AND R8, R9
ST X+, R8
STL X+, $00 // BLANK = 0
RETI
MOV R8, R0
SUB R8, $04 // Настройка матричного индикатора
JMPC $0008, $1
ADD R2, $09
LDL R26, $F9
LDL R27, $50
ST X, R2
LDL R26, $C1
LDL R27, $87
ST X, R2
JMP $009B
MOV R8, R0
SUB R8, $02 // Смена символа: нет действия
JMPC $0001, $1
JMP $009B
LDL R26, $0C
LDL R27, $18
LD R8, X // Загрузка операнда A
LDL R26, $C1
LDL R27, $87
ST X, R8
RETI
MOV R8, R0 // Третье прерывание
SUB R8, $04 // Настройка матричного индикатора
JMPC $0008, $1
ADD R3, $09
LDL R26, $FA
LDL R27, $50
ST X, R3
LDL R26, $C2
LDL R27, $87
ST X, R3
JMP $00B1
MOV R8, R0
SUB R8, $02 // Смена символа: нет действия
JMPC $0001, $1
JMP $00B1
LDL R26, $61
LDL R27, $3E
LD R8, X // Загрузка операнда B
LDL R26, $C2
LDL R27, $87
ST X, R8
RETI
MOV R8, R0 // Четвертое прерывание
SUB R8, $04 // Настройка матричного индикатора
JMPC $0008, $1
ADD R4, $09
LDL R26, $FB
LDL R27, $50
ST X, R4
LDL R26, $C3
LDL R27, $87
ST X, R4
JMP $00E8
MOV R8, R0
SUB R8, $02 // Смена символа
JMPC $000F, $1
INC R1
MOV R8, R1
SUB R8, $10
JMPC $0001, $1
LDL R1, $00
MOV R26, R1
LDL R27, $90
LD R8, X
LDL R26, $C3
LDL R27, $87
ST X, R8
LDL R26, $F8
LDL R27, $50
ST X, R8
JMP $00E8
LDL R26, $0C
LDL R27, $18
LD R8, X
LDL R26, $61
LDL R27, $3E
LD R9, X
LDL R26, $C3
LDL R27, $87
MOV R10, R0 // Проверка режима
SUB R10, $00
JMPC $0001, $1
SUB R8, R9
MOV R10, R0 // Проверка режима
SUB R10, $01
JMPC $0001, $1
ADD R8, R9
MOV R10, R0 // Проверка режима
SUB R10, $03
JMPC $0001, $1
OR R8, R9
MOV R10, R0 // Проверка режима
SUB R10, $05
JMPC $0001, $1
AND R8, R9
ST X, R8
RETI