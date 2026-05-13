jmp $0039 // 0000 IRQ vector
ldl r30, $fc // 0001 SP low = 93fc
ldl r31, $93 // 0002 SP high
ldl r27, $87 // 0003 7seg high address
ldl r26, $c4 // 0004 7seg low address c4
stl x, $00 // 0005 enable all 7seg digits by default
ldl r27, $87 // 0006 7seg high address
ldl r26, $c0 // 0007 7seg low address c0
stl x, $00 // 0008 mode pair = 00, default mode 0
ldl r27, $87 // 0009 7seg high address
ldl r26, $c1 // 000a 7seg low address c1
stl x, $00 // 000b operand A pair = 00
ldl r27, $87 // 000c 7seg high address
ldl r26, $c2 // 000d 7seg low address c2
stl x, $00 // 000e operand B pair = 00
ldl r27, $87 // 000f 7seg high address
ldl r26, $c3 // 0010 7seg low address c3
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
jmps $0057, $1 // 0041 handle BTN1
ldl r26, $72 // 0042 BTN2 flag
ld r0, x // 0043 read BTN2 flag
sub r0, $01 // 0044 Z=1 if BTN2 pending
jmps $0075, $1 // 0045 handle BTN2
ldl r26, $73 // 0046 BTN3 flag
ld r0, x // 0047 read BTN3 flag
sub r0, $01 // 0048 Z=1 if BTN3 pending
jmps $0093, $1 // 0049 handle BTN3
jmp $0140 // 004a no pending flag: return through common IRQ exit
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
ldl r26, $c0 // 005e 7seg low address c0
st x, r0 // 005f 7seg first pair = mode
mov r1, r0 // 0060 compare mode with 2
sub r1, $02 // 0061 Z=1 when mode is 2
jmps $0013, $1 // 0062 jump when matched
mov r1, r0 // 0063 compare mode with 4
sub r1, $04 // 0064 Z=1 when mode is 4
jmps $001d, $1 // 0065 jump when matched
ldl r27, $87 // 0066 7seg high address
ldl r26, $c4 // 0067 7seg low address c4
stl x, $00 // 0068 modes 0/1/3/5: show mode, A, B, result
ldl r27, $90 // 0069 state RAM high
ldl r26, $01 // 006a state[1] A
ld r2, x // 006b r2 = saved A
ldl r27, $87 // 006c 7seg high address
ldl r26, $c1 // 006d 7seg low address c1
st x, r2 // 006e 7seg A pair = saved A
ldl r27, $90 // 006f state RAM high
ldl r26, $02 // 0070 state[2] B
ld r2, x // 0071 r2 = saved B
ldl r27, $87 // 0072 7seg high address
ldl r26, $c2 // 0073 7seg low address c2
st x, r2 // 0074 7seg B pair = saved B
jmp $0140 // 0075 return after mode display update
ldl r27, $87 // 0076 7seg high address
ldl r26, $c4 // 0077 7seg low address c4
stl x, $3c // 0078 mode 2: hide A and B pairs
ldl r27, $90 // 0079 state RAM high
ldl r26, $06 // 007a state[6] symbol index
ld r2, x // 007b r2 = current symbol index
ldl r26, $10 // 007c sequence table base
add r26, r2 // 007d X = sequence table + index
ld r3, x // 007e r3 = current symbol
ldl r27, $87 // 007f 7seg high address
ldl r26, $c3 // 0080 7seg low address c3
st x, r3 // 0081 7seg symbol pair = current symbol
jmp $0140 // 0082 return after mode 2 display update
ldl r27, $87 // 0083 7seg high address
ldl r26, $c4 // 0084 7seg low address c4
stl x, $00 // 0085 mode 4: show mode, R, G, B
ldl r27, $90 // 0086 state RAM high
ldl r26, $03 // 0087 state[3] red
ld r2, x // 0088 r2 = red
ldl r27, $87 // 0089 7seg high address
ldl r26, $c1 // 008a 7seg low address c1
st x, r2 // 008b 7seg R pair = red
ldl r27, $90 // 008c state RAM high
ldl r26, $04 // 008d state[4] green
ld r2, x // 008e r2 = green
ldl r27, $87 // 008f 7seg high address
ldl r26, $c2 // 0090 7seg low address c2
st x, r2 // 0091 7seg G pair = green
ldl r27, $90 // 0092 state RAM high
ldl r26, $05 // 0093 state[5] blue
ld r2, x // 0094 r2 = blue
ldl r27, $87 // 0095 7seg high address
ldl r26, $c3 // 0096 7seg low address c3
st x, r2 // 0097 7seg B pair = blue
jmp $0140 // 0098 return after mode 4 display update
ldl r27, $02 // 0099 BTN1: IRQ monitor high
ldl r26, $71 // 009a BTN1 flag
stl x, $00 // 009b clear BTN1 flag
ldl r27, $90 // 009c load mode: state base high
ldl r26, $00 // 009d load mode: state[0]
ld r0, x // 009e r0 = current mode
mov r1, r0 // 009f compare mode with 2
sub r1, $02 // 00a0 Z=1 when mode is 2
jmps $009e, $1 // 00a1 jump when matched
mov r1, r0 // 00a2 compare mode with 4
sub r1, $04 // 00a3 Z=1 when mode is 4
jmps $000a, $1 // 00a4 jump when matched
ldl r27, $18 // 00a5 operand A register high
ldl r26, $0c // 00a6 operand A register low
ld r2, x // 00a7 r2 = input operand A
ldl r27, $90 // 00a8 state RAM high
ldl r26, $01 // 00a9 state[1] A
st x, r2 // 00aa save A
ldl r27, $87 // 00ab 7seg high address
ldl r26, $c1 // 00ac 7seg low address c1
st x, r2 // 00ad 7seg A pair = loaded A
jmp $0140 // 00ae return after loading A
ldl r27, $90 // 00af state RAM high
ldl r26, $03 // 00b0 state[3] red
ld r2, x // 00b1 r2 = red
add r2, $09 // 00b2 red += 9
st x, r2 // 00b3 save red
ldl r27, $50 // 00b4 RGB matrix high
ldl r26, $f9 // 00b5 red PWM register
st x, r2 // 00b6 apply red
ldl r27, $87 // 00b7 7seg high address
ldl r26, $c1 // 00b8 7seg low address c1
st x, r2 // 00b9 7seg R pair = red
jmp $0140 // 00ba return after red update
ldl r27, $02 // 00bb BTN2: IRQ monitor high
ldl r26, $72 // 00bc BTN2 flag
stl x, $00 // 00bd clear BTN2 flag
ldl r27, $90 // 00be load mode: state base high
ldl r26, $00 // 00bf load mode: state[0]
ld r0, x // 00c0 r0 = current mode
mov r1, r0 // 00c1 compare mode with 2
sub r1, $02 // 00c2 Z=1 when mode is 2
jmps $007c, $1 // 00c3 jump when matched
mov r1, r0 // 00c4 compare mode with 4
sub r1, $04 // 00c5 Z=1 when mode is 4
jmps $000a, $1 // 00c6 jump when matched
ldl r27, $3e // 00c7 operand B register high
ldl r26, $61 // 00c8 operand B register low
ld r2, x // 00c9 r2 = input operand B
ldl r27, $90 // 00ca state RAM high
ldl r26, $02 // 00cb state[2] B
st x, r2 // 00cc save B
ldl r27, $87 // 00cd 7seg high address
ldl r26, $c2 // 00ce 7seg low address c2
st x, r2 // 00cf 7seg B pair = loaded B
jmp $0140 // 00d0 return after loading B
ldl r27, $90 // 00d1 state RAM high
ldl r26, $04 // 00d2 state[4] green
ld r2, x // 00d3 r2 = green
add r2, $09 // 00d4 green += 9
st x, r2 // 00d5 save green
ldl r27, $50 // 00d6 RGB matrix high
ldl r26, $fa // 00d7 green PWM register
st x, r2 // 00d8 apply green
ldl r27, $87 // 00d9 7seg high address
ldl r26, $c2 // 00da 7seg low address c2
st x, r2 // 00db 7seg G pair = green
jmp $0140 // 00dc return after green update
ldl r27, $02 // 00dd BTN3: IRQ monitor high
ldl r26, $73 // 00de BTN3 flag
stl x, $00 // 00df clear BTN3 flag
ldl r27, $90 // 00e0 load mode: state base high
ldl r26, $00 // 00e1 load mode: state[0]
ld r0, x // 00e2 r0 = current mode
mov r1, r0 // 00e3 compare mode with 0
sub r1, $00 // 00e4 Z=1 when mode is 0
jmps $0010, $1 // 00e5 jump when matched
mov r1, r0 // 00e6 compare mode with 1
sub r1, $01 // 00e7 Z=1 when mode is 1
jmps $0017, $1 // 00e8 jump when matched
mov r1, r0 // 00e9 compare mode with 2
sub r1, $02 // 00ea Z=1 when mode is 2
jmps $001e, $1 // 00eb jump when matched
mov r1, r0 // 00ec compare mode with 3
sub r1, $03 // 00ed Z=1 when mode is 3
jmps $0031, $1 // 00ee jump when matched
mov r1, r0 // 00ef compare mode with 4
sub r1, $04 // 00f0 Z=1 when mode is 4
jmps $0038, $1 // 00f1 jump when matched
mov r1, r0 // 00f2 compare mode with 5
sub r1, $05 // 00f3 Z=1 when mode is 5
jmps $0041, $1 // 00f4 jump when matched
jmp $0140 // 00f5 unknown mode
ldl r27, $90 // 00f6 mode 0 SUB: state base high
ldl r26, $01 // 00f7 state[1] operand A
ld r3, x // 00f8 r3 = A
ldl r26, $02 // 00f9 state[2] operand B
ld r4, x // 00fa r4 = B
sub r3, r4 // 00fb result = A - B
ldl r27, $87 // 00fc 7seg high address
ldl r26, $c3 // 00fd 7seg low address c3
st x, r3 // 00fe 7seg result pair = operation result
jmp $0140 // 00ff return after SUB
ldl r27, $90 // 0100 mode 1 ADD: state base high
ldl r26, $01 // 0101 state[1] operand A
ld r3, x // 0102 r3 = A
ldl r26, $02 // 0103 state[2] operand B
ld r4, x // 0104 r4 = B
add r3, r4 // 0105 result = A + B
ldl r27, $87 // 0106 7seg high address
ldl r26, $c3 // 0107 7seg low address c3
st x, r3 // 0108 7seg result pair = operation result
jmp $0140 // 0109 return after ADD
ldl r27, $90 // 010a state RAM high
ldl r26, $06 // 010b state[6] symbol index
ld r2, x // 010c r2 = symbol index
inc r2 // 010d index++
mov r1, r2 // 010e copy index
sub r1, $10 // 010f Z=1 if index == 16
jmps $0001, $1 // 0110 wrap sequence
jmp $0113 // 0111 store index
ldl r2, $00 // 0112 wrapped index = 0
ldl r27, $90 // 0113 state RAM high
ldl r26, $06 // 0114 state[6] symbol index
st x, r2 // 0115 save symbol index
ldl r26, $10 // 0116 sequence table base
add r26, r2 // 0117 X = sequence table + index
ld r3, x // 0118 r3 = sequence symbol
ldl r27, $50 // 0119 RGB matrix high
ldl r26, $f8 // 011a symbol register
st x, r3 // 011b apply matrix symbol
ldl r27, $87 // 011c 7seg high address
ldl r26, $c3 // 011d 7seg low address c3
st x, r3 // 011e 7seg symbol pair = symbol
jmp $0140 // 011f return after symbol update
ldl r27, $90 // 0120 mode 3 OR: state base high
ldl r26, $01 // 0121 state[1] operand A
ld r3, x // 0122 r3 = A
ldl r26, $02 // 0123 state[2] operand B
ld r4, x // 0124 r4 = B
or r3, r4 // 0125 result = A OR B
ldl r27, $87 // 0126 7seg high address
ldl r26, $c3 // 0127 7seg low address c3
st x, r3 // 0128 7seg result pair = operation result
jmp $0140 // 0129 return after OR
ldl r27, $90 // 012a state RAM high
ldl r26, $05 // 012b state[5] blue
ld r2, x // 012c r2 = blue
add r2, $09 // 012d blue += 9
st x, r2 // 012e save blue
ldl r27, $50 // 012f RGB matrix high
ldl r26, $fb // 0130 blue PWM register
st x, r2 // 0131 apply blue
ldl r27, $87 // 0132 7seg high address
ldl r26, $c3 // 0133 7seg low address c3
st x, r2 // 0134 7seg B pair = blue
jmp $0140 // 0135 return after blue update
ldl r27, $90 // 0136 mode 5 AND: state base high
ldl r26, $01 // 0137 state[1] operand A
ld r3, x // 0138 r3 = A
ldl r26, $02 // 0139 state[2] operand B
ld r4, x // 013a r4 = B
and r3, r4 // 013b result = A AND B
ldl r27, $87 // 013c 7seg high address
ldl r26, $c3 // 013d 7seg low address c3
st x, r3 // 013e 7seg result pair = operation result
jmp $0140 // 013f return after AND
ldl r27, $93 // 0140 common IRQ exit: stack high address
ldl r26, $fc // 0141 stack return slot low byte
stl x+, $38 // 0142 force return PC low byte to idle loop 0038
stl x+, $00 // 0143 force return PC high byte to idle loop 0038
stl x, $00 // 0144 saved SREG flags for RETI pop
ldl r30, $ff // 0145 SP low before RETI pops SREG, PCH, PCL
ldl r31, $93 // 0146 SP high before RETI pops SREG, PCH, PCL
reti // 0147 re-enable IRQ and return to idle loop
