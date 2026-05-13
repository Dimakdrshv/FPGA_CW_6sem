jmp $002f // 0000 IRQ vector: enter interrupt dispatcher
ldl r30, $fc // 0001 reset: SP low = 93fc, inside RAM 9000..93ff
ldl r31, $93 // 0002 reset: SP high
ldl r27, $87 // 0003 XH=87 for 7-seg controller base 87c0
ldl r26, $c4 // 0004 XL=c4, blank mask register
stl x, $fc // 0005 show only two low 7-seg digits
ldl r26, $c3 // 0006 XL=c3, low display byte
stl x, $00 // 0007 clear 7-seg value
ldl r27, $50 // 0008 XH=50 for RGB matrix base 50f8
ldl r26, $f8 // 0009 XL=f8, symbol register
stl x+, $0e // 000a init matrix symbol = first sequence value E, X -> 50f9
stl x+, $20 // 000b init red brightness = 20, X -> 50fa
stl x+, $20 // 000c init green brightness = 20, X -> 50fb
stl x, $20 // 000d init blue brightness = 20
ldl r27, $90 // 000e XH=90 for software state RAM base 9000
ldl r26, $00 // 000f XL=00, current mode cell
stl x+, $00 // 0010 state[0] mode = 0, X -> operand A copy
stl x+, $00 // 0011 state[1] operand A = 0, X -> operand B copy
stl x+, $00 // 0012 state[2] operand B = 0, X -> red value
stl x+, $20 // 0013 state[3] red = 20, X -> green value
stl x+, $20 // 0014 state[4] green = 20, X -> blue value
stl x+, $20 // 0015 state[5] blue = 20, X -> sequence index
stl x, $00 // 0016 state[6] sequence index = 0
ldl r26, $10 // 0017 XL=10, sequence table base 9010
stl x+, $0e // 0018 sequence #1: E
stl x+, $01 // 0019 sequence #2: 1
stl x+, $0b // 001a sequence #3: B
stl x+, $08 // 001b sequence #4: 8
stl x+, $0a // 001c sequence #5: A
stl x+, $0a // 001d sequence #6: A
stl x+, $0b // 001e sequence #7: B
stl x+, $0c // 001f sequence #8: C
stl x+, $05 // 0020 sequence #9: 5
stl x+, $04 // 0021 sequence #10: 4
stl x+, $0f // 0022 sequence #11: F
stl x+, $0e // 0023 sequence #12: E
stl x+, $0a // 0024 sequence #13: A
stl x+, $00 // 0025 sequence #14: 0
stl x+, $0a // 0026 sequence #15: A
stl x+, $07 // 0027 sequence #16: 7
ldl r27, $81 // 0028 XH=81 for LED/mode register 8106
ldl r26, $06 // 0029 XL=06
stl x, $00 // 002a show initial mode 0 on LEDs
ldl r27, $02 // 002b XH=02 for IRQ monitor base 0270
ldl r26, $74 // 002c XL=74, IRQ mask register 0274
stl x, $0f // 002d enable BTN0..BTN3 interrupts after init
jmp $002e // 002e main idle loop; IRQ does all useful work
ldl r27, $02 // 002f IRQ: XH=02, scan IRQ monitor flags
ldl r26, $70 // 0030 XL=70, BTN0 flag
ld r0, x // 0031 read BTN0 flag
sub r0, $01 // 0032 Z=1 when BTN0 flag is set
jmps $000d, $1 // 0033 if BTN0 set, jump to mode switch handler
ldl r26, $71 // 0034 XL=71, BTN1 flag
ld r0, x // 0035 read BTN1 flag
sub r0, $01 // 0036 Z=1 when BTN1 flag is set
jmps $001f, $1 // 0037 if BTN1 set, jump to BTN1 handler
ldl r26, $72 // 0038 XL=72, BTN2 flag
ld r0, x // 0039 read BTN2 flag
sub r0, $01 // 003a Z=1 when BTN2 flag is set
jmps $003a, $1 // 003b if BTN2 set, jump to BTN2 handler
ldl r26, $73 // 003c XL=73, BTN3 flag
ld r0, x // 003d read BTN3 flag
sub r0, $01 // 003e Z=1 when BTN3 flag is set
jmps $0055, $1 // 003f if BTN3 set, jump to BTN3 handler
reti // 0040 no pending enabled flag, return from IRQ
ldl r27, $02 // 0041 BTN0: XH=02, clear BTN0 IRQ flag
ldl r26, $70 // 0042 XL=70
stl x, $00 // 0043 clear BTN0 flag in IRQ monitor
ldl r27, $90 // 0044 XH=90, load current mode
ldl r26, $00 // 0045 XL=00, state[0]
ld r1, x // 0046 r1 = mode
inc r1 // 0047 mode++
mov r2, r1 // 0048 copy mode for wrap check
sub r2, $06 // 0049 Z=1 when mode became 6
jmps $0001, $1 // 004a wrap 6 back to 0
jmp $004d // 004b otherwise store incremented mode
ldl r1, $00 // 004c wrapped mode = 0
ldl r27, $90 // 004d XH=90
ldl r26, $00 // 004e XL=00, state[0]
st x, r1 // 004f save current mode
ldl r27, $81 // 0050 XH=81 for LED/mode register
ldl r26, $06 // 0051 XL=06
st x, r1 // 0052 show mode on LEDs
ldl r27, $87 // 0053 XH=87 for 7-seg controller
ldl r26, $c3 // 0054 XL=c3
st x, r1 // 0055 show mode on 7-seg
reti // 0056 return after BTN0
ldl r27, $02 // 0057 BTN1: XH=02, clear BTN1 IRQ flag
ldl r26, $71 // 0058 XL=71
stl x, $00 // 0059 clear BTN1 flag in IRQ monitor
ldl r27, $90 // 005a XH=90, read current mode
ldl r26, $00 // 005b XL=00
ld r0, x // 005c r0 = mode
mov r1, r0 // 005d copy mode
sub r1, $02 // 005e mode 2: no action for BTN1
jmps $0092, $1 // 005f if mode 2, just return
mov r1, r0 // 0060 copy mode again
sub r1, $04 // 0061 mode 4: red brightness action
jmps $000a, $1 // 0062 if mode 4, jump to red +9
ldl r27, $18 // 0063 other modes: XH=18 for operand A at 180c
ldl r26, $0c // 0064 XL=0c
ld r2, x // 0065 r2 = operand A input
ldl r27, $90 // 0066 XH=90, save operand A copy
ldl r26, $01 // 0067 XL=01, state[1]
st x, r2 // 0068 state[1] = A
ldl r27, $87 // 0069 XH=87 for 7-seg controller
ldl r26, $c3 // 006a XL=c3
st x, r2 // 006b show A on 7-seg
reti // 006c return after loading A
ldl r27, $90 // 006d BTN1 mode 4: XH=90, red state
ldl r26, $03 // 006e XL=03, state[3]
ld r2, x // 006f r2 = red
add r2, $09 // 0070 red += 9
st x, r2 // 0071 save red
ldl r27, $50 // 0072 XH=50 for RGB matrix
ldl r26, $f9 // 0073 XL=f9, red PWM register
st x, r2 // 0074 apply red brightness
reti // 0075 return after red update
ldl r27, $02 // 0076 BTN2: XH=02, clear BTN2 IRQ flag
ldl r26, $72 // 0077 XL=72
stl x, $00 // 0078 clear BTN2 flag in IRQ monitor
ldl r27, $90 // 0079 XH=90, read current mode
ldl r26, $00 // 007a XL=00
ld r0, x // 007b r0 = mode
mov r1, r0 // 007c copy mode
sub r1, $02 // 007d mode 2: no action for BTN2
jmps $0073, $1 // 007e if mode 2, just return
mov r1, r0 // 007f copy mode again
sub r1, $04 // 0080 mode 4: green brightness action
jmps $000a, $1 // 0081 if mode 4, jump to green +9
ldl r27, $3e // 0082 other modes: XH=3e for operand B at 3e61
ldl r26, $61 // 0083 XL=61
ld r2, x // 0084 r2 = operand B input
ldl r27, $90 // 0085 XH=90, save operand B copy
ldl r26, $02 // 0086 XL=02, state[2]
st x, r2 // 0087 state[2] = B
ldl r27, $87 // 0088 XH=87 for 7-seg controller
ldl r26, $c3 // 0089 XL=c3
st x, r2 // 008a show B on 7-seg
reti // 008b return after loading B
ldl r27, $90 // 008c BTN2 mode 4: XH=90, green state
ldl r26, $04 // 008d XL=04, state[4]
ld r2, x // 008e r2 = green
add r2, $09 // 008f green += 9
st x, r2 // 0090 save green
ldl r27, $50 // 0091 XH=50 for RGB matrix
ldl r26, $fa // 0092 XL=fa, green PWM register
st x, r2 // 0093 apply green brightness
reti // 0094 return after green update
ldl r27, $02 // 0095 BTN3: XH=02, clear BTN3 IRQ flag
ldl r26, $73 // 0096 XL=73
stl x, $00 // 0097 clear BTN3 flag in IRQ monitor
ldl r27, $90 // 0098 XH=90, read current mode
ldl r26, $00 // 0099 XL=00
ld r0, x // 009a r0 = mode
mov r1, r0 // 009b compare mode with 0
sub r1, $00 // 009c mode 0: A - B
jmps $0010, $1 // 009d jump to SUB operation
mov r1, r0 // 009e compare mode with 1
sub r1, $01 // 009f mode 1: A + B
jmps $0017, $1 // 00a0 jump to selected action
mov r1, r0 // 00a1 compare mode with 2
sub r1, $02 // 00a2 mode 2: next symbol from sequence table
jmps $001e, $1 // 00a3 jump to selected action
mov r1, r0 // 00a4 compare mode with 3
sub r1, $03 // 00a5 mode 3: A OR B
jmps $002e, $1 // 00a6 jump to selected action
mov r1, r0 // 00a7 compare mode with 4
sub r1, $04 // 00a8 mode 4: blue brightness action
jmps $0035, $1 // 00a9 jump to selected action
mov r1, r0 // 00aa compare mode with 5
sub r1, $05 // 00ab mode 5: A AND B
jmps $003b, $1 // 00ac jump to selected action
jmp $00f2 // 00ad unknown mode: return safely
ldl r27, $90 // 00ae mode 0 SUB: XH=90, load A copy
ldl r26, $01 // 00af XL=01, state[1]
ld r3, x // 00b0 r3 = A
ldl r26, $02 // 00b1 XL=02, state[2]
ld r4, x // 00b2 r4 = B
sub r3, r4 // 00b3 r3 = A - B
ldl r27, $87 // 00b4 XH=87 for 7-seg controller
ldl r26, $c3 // 00b5 XL=c3
st x, r3 // 00b6 show result
reti // 00b7 return after SUB
ldl r27, $90 // 00b8 mode 1 ADD: XH=90, load A copy
ldl r26, $01 // 00b9 XL=01, state[1]
ld r3, x // 00ba r3 = A
ldl r26, $02 // 00bb XL=02, state[2]
ld r4, x // 00bc r4 = B
add r3, r4 // 00bd r3 = A + B
ldl r27, $87 // 00be XH=87 for 7-seg controller
ldl r26, $c3 // 00bf XL=c3
st x, r3 // 00c0 show result
reti // 00c1 return after ADD
ldl r27, $90 // 00c2 mode 2 symbol: XH=90, load sequence index
ldl r26, $06 // 00c3 XL=06, state[6]
ld r2, x // 00c4 r2 = current sequence index 0..15
inc r2 // 00c5 index++
mov r1, r2 // 00c6 copy index
sub r1, $10 // 00c7 Z=1 when index became 16
jmps $0001, $1 // 00c8 wrap index 16 back to 0
jmp $00cb // 00c9 otherwise store index
ldl r2, $00 // 00ca wrapped sequence index = 0
ldl r27, $90 // 00cb XH=90
ldl r26, $06 // 00cc XL=06, state[6]
st x, r2 // 00cd save sequence index
ldl r26, $10 // 00ce XL=10, sequence table base
add r26, r2 // 00cf X = 9010 + sequence index
ld r3, x // 00d0 r3 = selected sequence symbol
ldl r27, $50 // 00d1 XH=50 for RGB matrix
ldl r26, $f8 // 00d2 XL=f8, symbol register
st x, r3 // 00d3 apply matrix symbol
reti // 00d4 return after symbol update
ldl r27, $90 // 00d5 mode 3 OR: XH=90, load A copy
ldl r26, $01 // 00d6 XL=01, state[1]
ld r3, x // 00d7 r3 = A
ldl r26, $02 // 00d8 XL=02, state[2]
ld r4, x // 00d9 r4 = B
or r3, r4 // 00da r3 = A OR B
ldl r27, $87 // 00db XH=87 for 7-seg controller
ldl r26, $c3 // 00dc XL=c3
st x, r3 // 00dd show result
reti // 00de return after OR
ldl r27, $90 // 00df mode 4 blue: XH=90, blue state
ldl r26, $05 // 00e0 XL=05, state[5]
ld r2, x // 00e1 r2 = blue
add r2, $09 // 00e2 blue += 9
st x, r2 // 00e3 save blue
ldl r27, $50 // 00e4 XH=50 for RGB matrix
ldl r26, $fb // 00e5 XL=fb, blue PWM register
st x, r2 // 00e6 apply blue brightness
reti // 00e7 return after blue update
ldl r27, $90 // 00e8 mode 5 AND: XH=90, load A copy
ldl r26, $01 // 00e9 XL=01, state[1]
ld r3, x // 00ea r3 = A
ldl r26, $02 // 00eb XL=02, state[2]
ld r4, x // 00ec r4 = B
and r3, r4 // 00ed r3 = A AND B
ldl r27, $87 // 00ee XH=87 for 7-seg controller
ldl r26, $c3 // 00ef XL=c3
st x, r3 // 00f0 show result
reti // 00f1 return after AND
reti // 00f2 safe return target
