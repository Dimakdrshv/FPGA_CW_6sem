jmp $0039 // 0000 IRQ vector
ldl r30, $fc // 0001 SP low = 93fc
ldl r31, $93 // 0002 SP high
ldl r27, $87 // 0003 7seg high address
ldl r26, $c4 // 0004 7seg low address c4
stl x, $00 // 0005 enable all 7seg digits by default
ldl r27, $87 // 0006 7seg high address
ldl r26, $c3 // 0007 mirrored 7seg address for mode pair
stl x, $00 // 0008 mode pair = 00, default mode 0
ldl r27, $87 // 0009 7seg high address
ldl r26, $c2 // 000a mirrored 7seg address for operand A
stl x, $00 // 000b operand A pair = 00
ldl r27, $87 // 000c 7seg high address
ldl r26, $c1 // 000d mirrored 7seg address for operand B
stl x, $00 // 000e operand B pair = 00
ldl r27, $87 // 000f 7seg high address
ldl r26, $c0 // 0010 mirrored 7seg address for result/symbol
stl x, $00 // 0011 result/symbol pair = 00
ldl r27, $50 // 0012 RGB matrix high address
ldl r26, $f8 // 0013 RGB symbol register
stl x+, $0e // 0014 initial symbol E, X -> red PWM
stl x+, $20 // 0015 initial red = 20, X -> green PWM
stl x+, $20 // 0016 initial green = 20, X -> blue PWM
stl x, $20 // 0017 initial blue = 20
ldl r27, $90 // 0018 state RAM high address
ldl r26, $00 // 0019 state[0] mode
stl x+, $00 // 001a state[0] mode = 0
stl x+, $00 // 001b state[1] A = 0
stl x+, $00 // 001c state[2] B = 0
stl x+, $20 // 001d state[3] red = 20
stl x+, $20 // 001e state[4] green = 20
stl x+, $20 // 001f state[5] blue = 20
stl x, $00 // 0020 state[6] symbol sequence index = 0
ldl r26, $10 // 0021 sequence table base 9010
stl x+, $0e // 0022 sequence #1: E
stl x+, $01 // 0023 sequence #2: 1
stl x+, $0b // 0024 sequence #3: B
stl x+, $08 // 0025 sequence #4: 8
stl x+, $0a // 0026 sequence #5: A
stl x+, $0a // 0027 sequence #6: A
stl x+, $0b // 0028 sequence #7: B
stl x+, $0c // 0029 sequence #8: C
stl x+, $05 // 002a sequence #9: 5
stl x+, $04 // 002b sequence #10: 4
stl x+, $0f // 002c sequence #11: F
stl x+, $0e // 002d sequence #12: E
stl x+, $0a // 002e sequence #13: A
stl x+, $00 // 002f sequence #14: 0
stl x+, $0a // 0030 sequence #15: A
stl x+, $07 // 0031 sequence #16: 7
ldl r27, $81 // 0032 LED/mode register high address
ldl r26, $06 // 0033 LED/mode register low address
stl x, $00 // 0034 LEDs show default mode 0
ldl r27, $02 // 0035 IRQ monitor high address
ldl r26, $74 // 0036 IRQ mask register
stl x, $0f // 0037 enable BTN0..BTN3 interrupts after init
jmp $0038 // 0038 idle loop
ldl r27, $02 // 0039 IRQ monitor high address
ldl r26, $70 // 003a BTN0 flag
ld r0, x // 003b read BTN0 flag
sub r0, $01 // 003c Z=1 if BTN0 pending
jmps $000d, $1 // 003d handle BTN0
ldl r26, $71 // 003e BTN1 flag
ld r0, x // 003f read BTN1 flag
sub r0, $01 // 0040 Z=1 if BTN1 pending
jmps $007a, $1 // 0041 handle BTN1
ldl r26, $72 // 0042 BTN2 flag
ld r0, x // 0043 read BTN2 flag
sub r0, $01 // 0044 Z=1 if BTN2 pending
jmps $00a2, $1 // 0045 handle BTN2
ldl r26, $73 // 0046 BTN3 flag
ld r0, x // 0047 read BTN3 flag
sub r0, $01 // 0048 Z=1 if BTN3 pending
jmps $00ca, $1 // 0049 handle BTN3
jmp $0195 // 004a no pending flag: return through common IRQ exit
ldl r27, $02 // 004b BTN0: IRQ monitor high
ldl r26, $70 // 004c BTN0 flag
stl x, $00 // 004d clear BTN0 flag
ldl r27, $90 // 004e load mode: state base high
ldl r26, $00 // 004f load mode: state[0]
ld r0, x // 0050 r0 = current mode
inc r0 // 0051 mode++
mov r1, r0 // 0052 copy mode for wrap
sub r1, $06 // 0053 Z=1 if mode became 6
jmps $0001, $1 // 0054 wrap mode
jmp $0057 // 0055 store new mode
ldl r0, $00 // 0056 wrapped mode = 0
ldl r27, $90 // 0057 state RAM high
ldl r26, $00 // 0058 state[0] mode
st x, r0 // 0059 save current mode
ldl r27, $81 // 005a LED/mode register high
ldl r26, $06 // 005b LED/mode register low
st x, r0 // 005c LEDs show mode
ldl r27, $87 // 005d 7seg high address
ldl r26, $c3 // 005e mirrored 7seg address for mode
mov r5, r0 // 005f swap 7seg nibbles: copy value
lsr r5, $4 // 0060 swap 7seg nibbles: low nibble -> high digit
mov r6, r0 // 0061 swap 7seg nibbles: copy value again
rsr r6, $4 // 0062 swap 7seg nibbles: high nibble -> low digit
or r5, r6 // 0063 swap 7seg nibbles: AB becomes BA
st x, r5 // 0064 7seg first pair = mode (nibbles swapped for physical digit order)
mov r1, r0 // 0065 compare mode with 2
sub r1, $02 // 0066 Z=1 when mode is 2
jmps $001d, $1 // 0067 jump when matched
mov r1, r0 // 0068 compare mode with 4
sub r1, $04 // 0069 Z=1 when mode is 4
jmps $002c, $1 // 006a jump when matched
ldl r27, $87 // 006b 7seg high address
ldl r26, $c4 // 006c 7seg low address c4
stl x, $00 // 006d modes 0/1/3/5: show mode, A, B, result
ldl r27, $90 // 006e state RAM high
ldl r26, $01 // 006f state[1] A
ld r2, x // 0070 r2 = saved A
ldl r27, $87 // 0071 7seg high address
ldl r26, $c2 // 0072 mirrored 7seg address for A
mov r5, r2 // 0073 swap 7seg nibbles: copy value
lsr r5, $4 // 0074 swap 7seg nibbles: low nibble -> high digit
mov r6, r2 // 0075 swap 7seg nibbles: copy value again
rsr r6, $4 // 0076 swap 7seg nibbles: high nibble -> low digit
or r5, r6 // 0077 swap 7seg nibbles: AB becomes BA
st x, r5 // 0078 7seg A pair = saved A (nibbles swapped for physical digit order)
ldl r27, $90 // 0079 state RAM high
ldl r26, $02 // 007a state[2] B
ld r2, x // 007b r2 = saved B
ldl r27, $87 // 007c 7seg high address
ldl r26, $c1 // 007d mirrored 7seg address for B
mov r5, r2 // 007e swap 7seg nibbles: copy value
lsr r5, $4 // 007f swap 7seg nibbles: low nibble -> high digit
mov r6, r2 // 0080 swap 7seg nibbles: copy value again
rsr r6, $4 // 0081 swap 7seg nibbles: high nibble -> low digit
or r5, r6 // 0082 swap 7seg nibbles: AB becomes BA
st x, r5 // 0083 7seg B pair = saved B (nibbles swapped for physical digit order)
jmp $0195 // 0084 return after mode display update
ldl r27, $87 // 0085 7seg high address
ldl r26, $c4 // 0086 7seg low address c4
stl x, $3c // 0087 mode 2: hide A and B pairs
ldl r27, $90 // 0088 state RAM high
ldl r26, $06 // 0089 state[6] symbol index
ld r2, x // 008a r2 = current symbol index
ldl r26, $10 // 008b sequence table base
add r26, r2 // 008c X = sequence table + index
ld r3, x // 008d r3 = current symbol
ldl r27, $87 // 008e 7seg high address
ldl r26, $c0 // 008f mirrored 7seg address for symbol
mov r5, r3 // 0090 swap 7seg nibbles: copy value
lsr r5, $4 // 0091 swap 7seg nibbles: low nibble -> high digit
mov r6, r3 // 0092 swap 7seg nibbles: copy value again
rsr r6, $4 // 0093 swap 7seg nibbles: high nibble -> low digit
or r5, r6 // 0094 swap 7seg nibbles: AB becomes BA
st x, r5 // 0095 7seg symbol pair = current symbol (nibbles swapped for physical digit order)
jmp $0195 // 0096 return after mode 2 display update
ldl r27, $87 // 0097 7seg high address
ldl r26, $c4 // 0098 7seg low address c4
stl x, $00 // 0099 mode 4: show mode, R, G, B
ldl r27, $90 // 009a state RAM high
ldl r26, $03 // 009b state[3] red
ld r2, x // 009c r2 = red
ldl r27, $87 // 009d 7seg high address
ldl r26, $c2 // 009e mirrored 7seg address for R
mov r5, r2 // 009f swap 7seg nibbles: copy value
lsr r5, $4 // 00a0 swap 7seg nibbles: low nibble -> high digit
mov r6, r2 // 00a1 swap 7seg nibbles: copy value again
rsr r6, $4 // 00a2 swap 7seg nibbles: high nibble -> low digit
or r5, r6 // 00a3 swap 7seg nibbles: AB becomes BA
st x, r5 // 00a4 7seg R pair = red (nibbles swapped for physical digit order)
ldl r27, $90 // 00a5 state RAM high
ldl r26, $04 // 00a6 state[4] green
ld r2, x // 00a7 r2 = green
ldl r27, $87 // 00a8 7seg high address
ldl r26, $c1 // 00a9 mirrored 7seg address for G
mov r5, r2 // 00aa swap 7seg nibbles: copy value
lsr r5, $4 // 00ab swap 7seg nibbles: low nibble -> high digit
mov r6, r2 // 00ac swap 7seg nibbles: copy value again
rsr r6, $4 // 00ad swap 7seg nibbles: high nibble -> low digit
or r5, r6 // 00ae swap 7seg nibbles: AB becomes BA
st x, r5 // 00af 7seg G pair = green (nibbles swapped for physical digit order)
ldl r27, $90 // 00b0 state RAM high
ldl r26, $05 // 00b1 state[5] blue
ld r2, x // 00b2 r2 = blue
ldl r27, $87 // 00b3 7seg high address
ldl r26, $c0 // 00b4 mirrored 7seg address for B color
mov r5, r2 // 00b5 swap 7seg nibbles: copy value
lsr r5, $4 // 00b6 swap 7seg nibbles: low nibble -> high digit
mov r6, r2 // 00b7 swap 7seg nibbles: copy value again
rsr r6, $4 // 00b8 swap 7seg nibbles: high nibble -> low digit
or r5, r6 // 00b9 swap 7seg nibbles: AB becomes BA
st x, r5 // 00ba 7seg B pair = blue (nibbles swapped for physical digit order)
jmp $0195 // 00bb return after mode 4 display update
ldl r27, $02 // 00bc BTN1: IRQ monitor high
ldl r26, $71 // 00bd BTN1 flag
stl x, $00 // 00be clear BTN1 flag
ldl r27, $90 // 00bf load mode: state base high
ldl r26, $00 // 00c0 load mode: state[0]
ld r0, x // 00c1 r0 = current mode
mov r1, r0 // 00c2 compare mode with 2
sub r1, $02 // 00c3 Z=1 when mode is 2
jmps $00d0, $1 // 00c4 jump when matched
mov r1, r0 // 00c5 compare mode with 4
sub r1, $04 // 00c6 Z=1 when mode is 4
jmps $000f, $1 // 00c7 jump when matched
ldl r27, $18 // 00c8 operand A register high
ldl r26, $0c // 00c9 operand A register low
ld r2, x // 00ca r2 = input operand A
ldl r27, $90 // 00cb state RAM high
ldl r26, $01 // 00cc state[1] A
st x, r2 // 00cd save A
ldl r27, $87 // 00ce 7seg high address
ldl r26, $c2 // 00cf mirrored 7seg address for A
mov r5, r2 // 00d0 swap 7seg nibbles: copy value
lsr r5, $4 // 00d1 swap 7seg nibbles: low nibble -> high digit
mov r6, r2 // 00d2 swap 7seg nibbles: copy value again
rsr r6, $4 // 00d3 swap 7seg nibbles: high nibble -> low digit
or r5, r6 // 00d4 swap 7seg nibbles: AB becomes BA
st x, r5 // 00d5 7seg A pair = loaded A (nibbles swapped for physical digit order)
jmp $0195 // 00d6 return after loading A
ldl r27, $90 // 00d7 state RAM high
ldl r26, $03 // 00d8 state[3] red
ld r2, x // 00d9 r2 = red
add r2, $09 // 00da red += 9
st x, r2 // 00db save red
ldl r27, $50 // 00dc RGB matrix high
ldl r26, $f9 // 00dd red PWM register
st x, r2 // 00de apply red
ldl r27, $87 // 00df 7seg high address
ldl r26, $c2 // 00e0 mirrored 7seg address for R
mov r5, r2 // 00e1 swap 7seg nibbles: copy value
lsr r5, $4 // 00e2 swap 7seg nibbles: low nibble -> high digit
mov r6, r2 // 00e3 swap 7seg nibbles: copy value again
rsr r6, $4 // 00e4 swap 7seg nibbles: high nibble -> low digit
or r5, r6 // 00e5 swap 7seg nibbles: AB becomes BA
st x, r5 // 00e6 7seg R pair = red (nibbles swapped for physical digit order)
jmp $0195 // 00e7 return after red update
ldl r27, $02 // 00e8 BTN2: IRQ monitor high
ldl r26, $72 // 00e9 BTN2 flag
stl x, $00 // 00ea clear BTN2 flag
ldl r27, $90 // 00eb load mode: state base high
ldl r26, $00 // 00ec load mode: state[0]
ld r0, x // 00ed r0 = current mode
mov r1, r0 // 00ee compare mode with 2
sub r1, $02 // 00ef Z=1 when mode is 2
jmps $00a4, $1 // 00f0 jump when matched
mov r1, r0 // 00f1 compare mode with 4
sub r1, $04 // 00f2 Z=1 when mode is 4
jmps $000f, $1 // 00f3 jump when matched
ldl r27, $3e // 00f4 operand B register high
ldl r26, $61 // 00f5 operand B register low
ld r2, x // 00f6 r2 = input operand B
ldl r27, $90 // 00f7 state RAM high
ldl r26, $02 // 00f8 state[2] B
st x, r2 // 00f9 save B
ldl r27, $87 // 00fa 7seg high address
ldl r26, $c1 // 00fb mirrored 7seg address for B operand
mov r5, r2 // 00fc swap 7seg nibbles: copy value
lsr r5, $4 // 00fd swap 7seg nibbles: low nibble -> high digit
mov r6, r2 // 00fe swap 7seg nibbles: copy value again
rsr r6, $4 // 00ff swap 7seg nibbles: high nibble -> low digit
or r5, r6 // 0100 swap 7seg nibbles: AB becomes BA
st x, r5 // 0101 7seg B pair = loaded B (nibbles swapped for physical digit order)
jmp $0195 // 0102 return after loading B
ldl r27, $90 // 0103 state RAM high
ldl r26, $04 // 0104 state[4] green
ld r2, x // 0105 r2 = green
add r2, $09 // 0106 green += 9
st x, r2 // 0107 save green
ldl r27, $50 // 0108 RGB matrix high
ldl r26, $fa // 0109 green PWM register
st x, r2 // 010a apply green
ldl r27, $87 // 010b 7seg high address
ldl r26, $c1 // 010c mirrored 7seg address for G
mov r5, r2 // 010d swap 7seg nibbles: copy value
lsr r5, $4 // 010e swap 7seg nibbles: low nibble -> high digit
mov r6, r2 // 010f swap 7seg nibbles: copy value again
rsr r6, $4 // 0110 swap 7seg nibbles: high nibble -> low digit
or r5, r6 // 0111 swap 7seg nibbles: AB becomes BA
st x, r5 // 0112 7seg G pair = green (nibbles swapped for physical digit order)
jmp $0195 // 0113 return after green update
ldl r27, $02 // 0114 BTN3: IRQ monitor high
ldl r26, $73 // 0115 BTN3 flag
stl x, $00 // 0116 clear BTN3 flag
ldl r27, $90 // 0117 load mode: state base high
ldl r26, $00 // 0118 load mode: state[0]
ld r0, x // 0119 r0 = current mode
mov r1, r0 // 011a compare mode with 0
sub r1, $00 // 011b Z=1 when mode is 0
jmps $0010, $1 // 011c jump when matched
mov r1, r0 // 011d compare mode with 1
sub r1, $01 // 011e Z=1 when mode is 1
jmps $001c, $1 // 011f jump when matched
mov r1, r0 // 0120 compare mode with 2
sub r1, $02 // 0121 Z=1 when mode is 2
jmps $0028, $1 // 0122 jump when matched
mov r1, r0 // 0123 compare mode with 3
sub r1, $03 // 0124 Z=1 when mode is 3
jmps $0040, $1 // 0125 jump when matched
mov r1, r0 // 0126 compare mode with 4
sub r1, $04 // 0127 Z=1 when mode is 4
jmps $004c, $1 // 0128 jump when matched
mov r1, r0 // 0129 compare mode with 5
sub r1, $05 // 012a Z=1 when mode is 5
jmps $005a, $1 // 012b jump when matched
jmp $0195 // 012c unknown mode
ldl r27, $90 // 012d mode 0 SUB: state base high
ldl r26, $01 // 012e state[1] operand A
ld r3, x // 012f r3 = A
ldl r26, $02 // 0130 state[2] operand B
ld r4, x // 0131 r4 = B
sub r3, r4 // 0132 result = A - B
ldl r27, $87 // 0133 7seg high address
ldl r26, $c0 // 0134 mirrored 7seg address for result
mov r5, r3 // 0135 swap 7seg nibbles: copy value
lsr r5, $4 // 0136 swap 7seg nibbles: low nibble -> high digit
mov r6, r3 // 0137 swap 7seg nibbles: copy value again
rsr r6, $4 // 0138 swap 7seg nibbles: high nibble -> low digit
or r5, r6 // 0139 swap 7seg nibbles: AB becomes BA
st x, r5 // 013a 7seg result pair = operation result (nibbles swapped for physical digit order)
jmp $0195 // 013b return after SUB
ldl r27, $90 // 013c mode 1 ADD: state base high
ldl r26, $01 // 013d state[1] operand A
ld r3, x // 013e r3 = A
ldl r26, $02 // 013f state[2] operand B
ld r4, x // 0140 r4 = B
add r3, r4 // 0141 result = A + B
ldl r27, $87 // 0142 7seg high address
ldl r26, $c0 // 0143 mirrored 7seg address for result
mov r5, r3 // 0144 swap 7seg nibbles: copy value
lsr r5, $4 // 0145 swap 7seg nibbles: low nibble -> high digit
mov r6, r3 // 0146 swap 7seg nibbles: copy value again
rsr r6, $4 // 0147 swap 7seg nibbles: high nibble -> low digit
or r5, r6 // 0148 swap 7seg nibbles: AB becomes BA
st x, r5 // 0149 7seg result pair = operation result (nibbles swapped for physical digit order)
jmp $0195 // 014a return after ADD
ldl r27, $90 // 014b state RAM high
ldl r26, $06 // 014c state[6] symbol index
ld r2, x // 014d r2 = symbol index
inc r2 // 014e index++
mov r1, r2 // 014f copy index
sub r1, $10 // 0150 Z=1 if index == 16
jmps $0001, $1 // 0151 wrap sequence
jmp $0154 // 0152 store index
ldl r2, $00 // 0153 wrapped index = 0
ldl r27, $90 // 0154 state RAM high
ldl r26, $06 // 0155 state[6] symbol index
st x, r2 // 0156 save symbol index
ldl r26, $10 // 0157 sequence table base
add r26, r2 // 0158 X = sequence table + index
ld r3, x // 0159 r3 = sequence symbol
ldl r27, $50 // 015a RGB matrix high
ldl r26, $f8 // 015b symbol register
st x, r3 // 015c apply matrix symbol
ldl r27, $87 // 015d 7seg high address
ldl r26, $c0 // 015e mirrored 7seg address for symbol
mov r5, r3 // 015f swap 7seg nibbles: copy value
lsr r5, $4 // 0160 swap 7seg nibbles: low nibble -> high digit
mov r6, r3 // 0161 swap 7seg nibbles: copy value again
rsr r6, $4 // 0162 swap 7seg nibbles: high nibble -> low digit
or r5, r6 // 0163 swap 7seg nibbles: AB becomes BA
st x, r5 // 0164 7seg symbol pair = symbol (nibbles swapped for physical digit order)
jmp $0195 // 0165 return after symbol update
ldl r27, $90 // 0166 mode 3 OR: state base high
ldl r26, $01 // 0167 state[1] operand A
ld r3, x // 0168 r3 = A
ldl r26, $02 // 0169 state[2] operand B
ld r4, x // 016a r4 = B
or r3, r4 // 016b result = A OR B
ldl r27, $87 // 016c 7seg high address
ldl r26, $c0 // 016d mirrored 7seg address for result
mov r5, r3 // 016e swap 7seg nibbles: copy value
lsr r5, $4 // 016f swap 7seg nibbles: low nibble -> high digit
mov r6, r3 // 0170 swap 7seg nibbles: copy value again
rsr r6, $4 // 0171 swap 7seg nibbles: high nibble -> low digit
or r5, r6 // 0172 swap 7seg nibbles: AB becomes BA
st x, r5 // 0173 7seg result pair = operation result (nibbles swapped for physical digit order)
jmp $0195 // 0174 return after OR
ldl r27, $90 // 0175 state RAM high
ldl r26, $05 // 0176 state[5] blue
ld r2, x // 0177 r2 = blue
add r2, $09 // 0178 blue += 9
st x, r2 // 0179 save blue
ldl r27, $50 // 017a RGB matrix high
ldl r26, $fb // 017b blue PWM register
st x, r2 // 017c apply blue
ldl r27, $87 // 017d 7seg high address
ldl r26, $c0 // 017e mirrored 7seg address for B color
mov r5, r2 // 017f swap 7seg nibbles: copy value
lsr r5, $4 // 0180 swap 7seg nibbles: low nibble -> high digit
mov r6, r2 // 0181 swap 7seg nibbles: copy value again
rsr r6, $4 // 0182 swap 7seg nibbles: high nibble -> low digit
or r5, r6 // 0183 swap 7seg nibbles: AB becomes BA
st x, r5 // 0184 7seg B pair = blue (nibbles swapped for physical digit order)
jmp $0195 // 0185 return after blue update
ldl r27, $90 // 0186 mode 5 AND: state base high
ldl r26, $01 // 0187 state[1] operand A
ld r3, x // 0188 r3 = A
ldl r26, $02 // 0189 state[2] operand B
ld r4, x // 018a r4 = B
and r3, r4 // 018b result = A AND B
ldl r27, $87 // 018c 7seg high address
ldl r26, $c0 // 018d mirrored 7seg address for result
mov r5, r3 // 018e swap 7seg nibbles: copy value
lsr r5, $4 // 018f swap 7seg nibbles: low nibble -> high digit
mov r6, r3 // 0190 swap 7seg nibbles: copy value again
rsr r6, $4 // 0191 swap 7seg nibbles: high nibble -> low digit
or r5, r6 // 0192 swap 7seg nibbles: AB becomes BA
st x, r5 // 0193 7seg result pair = operation result (nibbles swapped for physical digit order)
jmp $0195 // 0194 return after AND
ldl r27, $93 // 0195 common IRQ exit: stack high address
ldl r26, $fc // 0196 stack return slot low byte
stl x+, $38 // 0197 force return PC low byte to idle loop 0038
stl x+, $00 // 0198 force return PC high byte to idle loop 0038
stl x, $00 // 0199 saved SREG flags for RETI pop
ldl r30, $ff // 019a SP low before RETI pops SREG, PCH, PCL
ldl r31, $93 // 019b SP high before RETI pops SREG, PCH, PCL
reti // 019c re-enable IRQ and return to idle loop
