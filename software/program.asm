jmp $001e // 0000 IRQ vector: enter interrupt dispatcher
ldl r30, $fc // 0001 reset: SP low = 93fc, inside RAM 9000..93ff
ldl r31, $93 // 0002 reset: SP high
ldl r27, $02 // 0003 XH=02 for IRQ monitor base 0270
ldl r26, $74 // 0004 XL=74, IRQ mask register 0274
stl x, $0f // 0005 enable BTN0..BTN3 interrupts
ldl r27, $87 // 0006 XH=87 for 7-seg controller base 87c0
ldl r26, $c4 // 0007 XL=c4, blank mask register
stl x, $fc // 0008 show only two low 7-seg digits
ldl r26, $c3 // 0009 XL=c3, low display byte
stl x, $00 // 000a clear 7-seg value
ldl r27, $50 // 000b XH=50 for RGB matrix base 50f8
ldl r26, $f8 // 000c XL=f8, symbol register
stl x+, $00 // 000d init matrix symbol = 0, X -> 50f9
stl x+, $20 // 000e init red brightness = 20, X -> 50fa
stl x+, $20 // 000f init green brightness = 20, X -> 50fb
stl x, $20 // 0010 init blue brightness = 20
ldl r27, $90 // 0011 XH=90 for software state RAM base 9000
ldl r26, $00 // 0012 XL=00, current mode cell
stl x+, $00 // 0013 state[0] mode = 0, X -> operand A copy
stl x+, $00 // 0014 state[1] operand A = 0, X -> operand B copy
stl x+, $00 // 0015 state[2] operand B = 0, X -> red value
stl x+, $20 // 0016 state[3] red = 20, X -> green value
stl x+, $20 // 0017 state[4] green = 20, X -> blue value
stl x+, $20 // 0018 state[5] blue = 20, X -> symbol value
stl x, $00 // 0019 state[6] symbol = 0
ldl r27, $81 // 001a XH=81 for LED/mode register 8106
ldl r26, $06 // 001b XL=06
stl x, $00 // 001c show initial mode 0 on LEDs
jmp $001d // 001d main idle loop; IRQ does all useful work
ldl r27, $02 // 001e IRQ: XH=02, scan IRQ monitor flags
ldl r26, $70 // 001f XL=70, BTN0 flag
ld r0, x // 0020 read BTN0 flag
sub r0, $01 // 0021 Z=1 when BTN0 flag is set
jmps $000d, $1 // 0022 if BTN0 set, jump to mode switch handler
ldl r26, $71 // 0023 XL=71, BTN1 flag
ld r0, x // 0024 read BTN1 flag
sub r0, $01 // 0025 Z=1 when BTN1 flag is set
jmps $001f, $1 // 0026 if BTN1 set, jump to BTN1 handler
ldl r26, $72 // 0027 XL=72, BTN2 flag
ld r0, x // 0028 read BTN2 flag
sub r0, $01 // 0029 Z=1 when BTN2 flag is set
jmps $003a, $1 // 002a if BTN2 set, jump to BTN2 handler
ldl r26, $73 // 002b XL=73, BTN3 flag
ld r0, x // 002c read BTN3 flag
sub r0, $01 // 002d Z=1 when BTN3 flag is set
jmps $0055, $1 // 002e if BTN3 set, jump to BTN3 handler
reti // 002f no pending enabled flag, return from IRQ
ldl r27, $02 // 0030 BTN0: XH=02, clear BTN0 IRQ flag
ldl r26, $70 // 0031 XL=70
stl x, $00 // 0032 clear BTN0 flag in IRQ monitor
ldl r27, $90 // 0033 XH=90, load current mode
ldl r26, $00 // 0034 XL=00, state[0]
ld r1, x // 0035 r1 = mode
inc r1 // 0036 mode++
mov r2, r1 // 0037 copy mode for wrap check
sub r2, $06 // 0038 Z=1 when mode became 6
jmps $0001, $1 // 0039 wrap 6 back to 0
jmp $003c // 003a otherwise store incremented mode
ldl r1, $00 // 003b wrapped mode = 0
ldl r27, $90 // 003c XH=90
ldl r26, $00 // 003d XL=00, state[0]
st x, r1 // 003e save current mode
ldl r27, $81 // 003f XH=81 for LED/mode register
ldl r26, $06 // 0040 XL=06
st x, r1 // 0041 show mode on LEDs
ldl r27, $87 // 0042 XH=87 for 7-seg controller
ldl r26, $c3 // 0043 XL=c3
st x, r1 // 0044 show mode on 7-seg
reti // 0045 return after BTN0
ldl r27, $02 // 0046 BTN1: XH=02, clear BTN1 IRQ flag
ldl r26, $71 // 0047 XL=71
stl x, $00 // 0048 clear BTN1 flag in IRQ monitor
ldl r27, $90 // 0049 XH=90, read current mode
ldl r26, $00 // 004a XL=00
ld r0, x // 004b r0 = mode
mov r1, r0 // 004c copy mode
sub r1, $02 // 004d mode 2: no action for BTN1
jmps $008f, $1 // 004e if mode 2, just return
mov r1, r0 // 004f copy mode again
sub r1, $04 // 0050 mode 4: red brightness action
jmps $000a, $1 // 0051 if mode 4, jump to red +9
ldl r27, $18 // 0052 other modes: XH=18 for operand A at 180c
ldl r26, $0c // 0053 XL=0c
ld r2, x // 0054 r2 = operand A input
ldl r27, $90 // 0055 XH=90, save operand A copy
ldl r26, $01 // 0056 XL=01, state[1]
st x, r2 // 0057 state[1] = A
ldl r27, $87 // 0058 XH=87 for 7-seg controller
ldl r26, $c3 // 0059 XL=c3
st x, r2 // 005a show A on 7-seg
reti // 005b return after loading A
ldl r27, $90 // 005c BTN1 mode 4: XH=90, red state
ldl r26, $03 // 005d XL=03, state[3]
ld r2, x // 005e r2 = red
add r2, $09 // 005f red += 9
st x, r2 // 0060 save red
ldl r27, $50 // 0061 XH=50 for RGB matrix
ldl r26, $f9 // 0062 XL=f9, red PWM register
st x, r2 // 0063 apply red brightness
reti // 0064 return after red update
ldl r27, $02 // 0065 BTN2: XH=02, clear BTN2 IRQ flag
ldl r26, $72 // 0066 XL=72
stl x, $00 // 0067 clear BTN2 flag in IRQ monitor
ldl r27, $90 // 0068 XH=90, read current mode
ldl r26, $00 // 0069 XL=00
ld r0, x // 006a r0 = mode
mov r1, r0 // 006b copy mode
sub r1, $02 // 006c mode 2: no action for BTN2
jmps $0070, $1 // 006d if mode 2, just return
mov r1, r0 // 006e copy mode again
sub r1, $04 // 006f mode 4: green brightness action
jmps $000a, $1 // 0070 if mode 4, jump to green +9
ldl r27, $3e // 0071 other modes: XH=3e for operand B at 3e61
ldl r26, $61 // 0072 XL=61
ld r2, x // 0073 r2 = operand B input
ldl r27, $90 // 0074 XH=90, save operand B copy
ldl r26, $02 // 0075 XL=02, state[2]
st x, r2 // 0076 state[2] = B
ldl r27, $87 // 0077 XH=87 for 7-seg controller
ldl r26, $c3 // 0078 XL=c3
st x, r2 // 0079 show B on 7-seg
reti // 007a return after loading B
ldl r27, $90 // 007b BTN2 mode 4: XH=90, green state
ldl r26, $04 // 007c XL=04, state[4]
ld r2, x // 007d r2 = green
add r2, $09 // 007e green += 9
st x, r2 // 007f save green
ldl r27, $50 // 0080 XH=50 for RGB matrix
ldl r26, $fa // 0081 XL=fa, green PWM register
st x, r2 // 0082 apply green brightness
reti // 0083 return after green update
ldl r27, $02 // 0084 BTN3: XH=02, clear BTN3 IRQ flag
ldl r26, $73 // 0085 XL=73
stl x, $00 // 0086 clear BTN3 flag in IRQ monitor
ldl r27, $90 // 0087 XH=90, read current mode
ldl r26, $00 // 0088 XL=00
ld r0, x // 0089 r0 = mode
mov r1, r0 // 008a compare mode with 0
sub r1, $00 // 008b mode 0: A - B
jmps $0010, $1 // 008c jump to SUB operation
mov r1, r0 // 008d compare mode with 1
sub r1, $01 // 008e mode 1: A + B
jmps $0017, $1 // 008f jump to ADD operation
mov r1, r0 // 0090 compare mode with 2
sub r1, $02 // 0091 mode 2: change matrix symbol
jmps $001e, $1 // 0092 jump to symbol update
mov r1, r0 // 0093 compare mode with 3
sub r1, $03 // 0094 mode 3: A OR B
jmps $002b, $1 // 0095 jump to OR operation
mov r1, r0 // 0096 compare mode with 4
sub r1, $04 // 0097 mode 4: blue brightness action
jmps $0032, $1 // 0098 jump to blue +9
mov r1, r0 // 0099 compare mode with 5
sub r1, $05 // 009a mode 5: A AND B
jmps $0038, $1 // 009b jump to AND operation
jmp $00de // 009c unknown mode: return safely
ldl r27, $90 // 009d mode 0 SUB: XH=90, load A copy
ldl r26, $01 // 009e XL=01, state[1]
ld r3, x // 009f r3 = A
ldl r26, $02 // 00a0 XL=02, state[2]
ld r4, x // 00a1 r4 = B
sub r3, r4 // 00a2 r3 = A - B
ldl r27, $87 // 00a3 XH=87 for 7-seg controller
ldl r26, $c3 // 00a4 XL=c3
st x, r3 // 00a5 show result
reti // 00a6 return after SUB
ldl r27, $90 // 00a7 mode 1 ADD: XH=90, load A copy
ldl r26, $01 // 00a8 XL=01, state[1]
ld r3, x // 00a9 r3 = A
ldl r26, $02 // 00aa XL=02, state[2]
ld r4, x // 00ab r4 = B
add r3, r4 // 00ac r3 = A + B
ldl r27, $87 // 00ad XH=87 for 7-seg controller
ldl r26, $c3 // 00ae XL=c3
st x, r3 // 00af show result
reti // 00b0 return after ADD
ldl r27, $90 // 00b1 mode 2 symbol: XH=90, load symbol state
ldl r26, $06 // 00b2 XL=06, state[6]
ld r2, x // 00b3 r2 = current symbol 0..15
inc r2 // 00b4 symbol++
mov r1, r2 // 00b5 copy symbol
sub r1, $10 // 00b6 Z=1 when symbol became 16
jmps $0001, $1 // 00b7 wrap symbol 16 back to 0
jmp $00ba // 00b8 otherwise store symbol
ldl r2, $00 // 00b9 wrapped symbol = 0
ldl r27, $90 // 00ba XH=90
ldl r26, $06 // 00bb XL=06, state[6]
st x, r2 // 00bc save symbol
ldl r27, $50 // 00bd XH=50 for RGB matrix
ldl r26, $f8 // 00be XL=f8, symbol register
st x, r2 // 00bf apply matrix symbol
reti // 00c0 return after symbol update
ldl r27, $90 // 00c1 mode 3 OR: XH=90, load A copy
ldl r26, $01 // 00c2 XL=01, state[1]
ld r3, x // 00c3 r3 = A
ldl r26, $02 // 00c4 XL=02, state[2]
ld r4, x // 00c5 r4 = B
or r3, r4 // 00c6 r3 = A OR B
ldl r27, $87 // 00c7 XH=87 for 7-seg controller
ldl r26, $c3 // 00c8 XL=c3
st x, r3 // 00c9 show result
reti // 00ca return after OR
ldl r27, $90 // 00cb mode 4 blue: XH=90, blue state
ldl r26, $05 // 00cc XL=05, state[5]
ld r2, x // 00cd r2 = blue
add r2, $09 // 00ce blue += 9
st x, r2 // 00cf save blue
ldl r27, $50 // 00d0 XH=50 for RGB matrix
ldl r26, $fb // 00d1 XL=fb, blue PWM register
st x, r2 // 00d2 apply blue brightness
reti // 00d3 return after blue update
ldl r27, $90 // 00d4 mode 5 AND: XH=90, load A copy
ldl r26, $01 // 00d5 XL=01, state[1]
ld r3, x // 00d6 r3 = A
ldl r26, $02 // 00d7 XL=02, state[2]
ld r4, x // 00d8 r4 = B
and r3, r4 // 00d9 r3 = A AND B
ldl r27, $87 // 00da XH=87 for 7-seg controller
ldl r26, $c3 // 00db XL=c3
st x, r3 // 00dc show result
reti // 00dd return after AND
reti // 00de safe return target
