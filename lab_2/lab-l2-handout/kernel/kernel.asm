
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	9d013103          	ld	sp,-1584(sp) # 800089d0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	9e070713          	addi	a4,a4,-1568 # 80008a30 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	0fe78793          	addi	a5,a5,254 # 80006160 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc71f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dcc78793          	addi	a5,a5,-564 # 80000e78 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:

//
// user write()s to the console go here.
//
int consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
    int i;

    for (i = 0; i < n; i++)
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    {
        char c;
        if (either_copyin(&c, user_src, src + i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	74e080e7          	jalr	1870(ra) # 80002878 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
            break;
        uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	784080e7          	jalr	1924(ra) # 800008be <uartputc>
    for (i = 0; i < n; i++)
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
    }

    return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
    for (i = 0; i < n; i++)
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// copy (up to) a whole input line to dst.
// user_dist indicates whether dst is a user
// or kernel address.
//
int consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
    uint target;
    int c;
    char cbuf;

    target = n;
    80000186:	00060b1b          	sext.w	s6,a2
    acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	9e650513          	addi	a0,a0,-1562 # 80010b70 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
    while (n > 0)
    {
        // wait until interrupt handler has put some
        // input into cons.buffer.
        while (cons.r == cons.w)
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	9d648493          	addi	s1,s1,-1578 # 80010b70 <cons>
            if (killed(myproc()))
            {
                release(&cons.lock);
                return -1;
            }
            sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	a6690913          	addi	s2,s2,-1434 # 80010c08 <cons+0x98>
        }

        c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

        if (c == C('D'))
    800001aa:	4b91                	li	s7,4
            break;
        }

        // copy the input byte to the user-space buffer.
        cbuf = c;
        if (either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
            break;

        dst++;
        --n;

        if (c == '\n')
    800001ae:	4ca9                	li	s9,10
    while (n > 0)
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
        while (cons.r == cons.w)
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
            if (killed(myproc()))
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	a8a080e7          	jalr	-1398(ra) # 80001c4a <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	4fa080e7          	jalr	1274(ra) # 800026c2 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
            sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	244080e7          	jalr	580(ra) # 8000241a <sleep>
        while (cons.r == cons.w)
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
        c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
        if (c == C('D'))
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
        cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
        if (either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	610080e7          	jalr	1552(ra) # 80002822 <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
        dst++;
    8000021e:	0a05                	addi	s4,s4,1
        --n;
    80000220:	39fd                	addiw	s3,s3,-1
        if (c == '\n')
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
            // a whole line has arrived, return to
            // the user-level read().
            break;
        }
    }
    release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	94a50513          	addi	a0,a0,-1718 # 80010b70 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

    return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
                release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	93450513          	addi	a0,a0,-1740 # 80010b70 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
                return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
            if (n < target)
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
                cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	98f72b23          	sw	a5,-1642(a4) # 80010c08 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
    if (c == BACKSPACE)
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
        uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	560080e7          	jalr	1376(ra) # 800007ec <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
        uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54e080e7          	jalr	1358(ra) # 800007ec <uartputc_sync>
        uartputc_sync(' ');
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	542080e7          	jalr	1346(ra) # 800007ec <uartputc_sync>
        uartputc_sync('\b');
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	538080e7          	jalr	1336(ra) # 800007ec <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// uartintr() calls this for input character.
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
    acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	8a450513          	addi	a0,a0,-1884 # 80010b70 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

    switch (c)
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
    {
    case C('P'): // Print process list.
        procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	5dc080e7          	jalr	1500(ra) # 800028ce <procdump>
            }
        }
        break;
    }

    release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	87650513          	addi	a0,a0,-1930 # 80010b70 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
    switch (c)
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
        if (c != 0 && cons.e - cons.r < INPUT_BUF_SIZE)
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	85270713          	addi	a4,a4,-1966 # 80010b70 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
            c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
            consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
            cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	82878793          	addi	a5,a5,-2008 # 80010b70 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
            if (c == '\n' || c == C('D') || cons.e - cons.r == INPUT_BUF_SIZE)
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	8927a783          	lw	a5,-1902(a5) # 80010c08 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
        while (cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	7e670713          	addi	a4,a4,2022 # 80010b70 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
               cons.buf[(cons.e - 1) % INPUT_BUF_SIZE] != '\n')
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	7d648493          	addi	s1,s1,2006 # 80010b70 <cons>
        while (cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
               cons.buf[(cons.e - 1) % INPUT_BUF_SIZE] != '\n')
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
        while (cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
            cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
            consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
        while (cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
        if (cons.e != cons.w)
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	79a70713          	addi	a4,a4,1946 # 80010b70 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
            cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	82f72223          	sw	a5,-2012(a4) # 80010c10 <cons+0xa0>
            consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
        if (c != 0 && cons.e - cons.r < INPUT_BUF_SIZE)
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
            consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
            cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	75e78793          	addi	a5,a5,1886 # 80010b70 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
                cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	7cc7ab23          	sw	a2,2006(a5) # 80010c0c <cons+0x9c>
                wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	7ca50513          	addi	a0,a0,1994 # 80010c08 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	038080e7          	jalr	56(ra) # 8000247e <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
    initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	71050513          	addi	a0,a0,1808 # 80010b70 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

    uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

    // connect read and write system calls
    // to consoleread and consolewrite.
    devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	ad078793          	addi	a5,a5,-1328 # 80020f48 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
    devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7670713          	addi	a4,a4,-906 # 80000100 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
    buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00010797          	auipc	a5,0x10
    80000550:	6e07a223          	sw	zero,1764(a5) # 80010c30 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	b5a50513          	addi	a0,a0,-1190 # 800080c8 <digits+0x88>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00008717          	auipc	a4,0x8
    80000584:	46f72823          	sw	a5,1136(a4) # 800089f0 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	8a2a                	mv	s4,a0
    800005aa:	e40c                	sd	a1,8(s0)
    800005ac:	e810                	sd	a2,16(s0)
    800005ae:	ec14                	sd	a3,24(s0)
    800005b0:	f018                	sd	a4,32(s0)
    800005b2:	f41c                	sd	a5,40(s0)
    800005b4:	03043823          	sd	a6,48(s0)
    800005b8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005bc:	00010d97          	auipc	s11,0x10
    800005c0:	674dad83          	lw	s11,1652(s11) # 80010c30 <pr+0x18>
  if(locking)
    800005c4:	020d9b63          	bnez	s11,800005fa <printf+0x70>
  if (fmt == 0)
    800005c8:	040a0263          	beqz	s4,8000060c <printf+0x82>
  va_start(ap, fmt);
    800005cc:	00840793          	addi	a5,s0,8
    800005d0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d4:	000a4503          	lbu	a0,0(s4)
    800005d8:	14050f63          	beqz	a0,80000736 <printf+0x1ac>
    800005dc:	4981                	li	s3,0
    if(c != '%'){
    800005de:	02500a93          	li	s5,37
    switch(c){
    800005e2:	07000b93          	li	s7,112
  consputc('x');
    800005e6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e8:	00008b17          	auipc	s6,0x8
    800005ec:	a58b0b13          	addi	s6,s6,-1448 # 80008040 <digits>
    switch(c){
    800005f0:	07300c93          	li	s9,115
    800005f4:	06400c13          	li	s8,100
    800005f8:	a82d                	j	80000632 <printf+0xa8>
    acquire(&pr.lock);
    800005fa:	00010517          	auipc	a0,0x10
    800005fe:	61e50513          	addi	a0,a0,1566 # 80010c18 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	5d4080e7          	jalr	1492(ra) # 80000bd6 <acquire>
    8000060a:	bf7d                	j	800005c8 <printf+0x3e>
    panic("null fmt");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a1c50513          	addi	a0,a0,-1508 # 80008028 <etext+0x28>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	f2c080e7          	jalr	-212(ra) # 80000540 <panic>
      consputc(c);
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	c60080e7          	jalr	-928(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000624:	2985                	addiw	s3,s3,1
    80000626:	013a07b3          	add	a5,s4,s3
    8000062a:	0007c503          	lbu	a0,0(a5)
    8000062e:	10050463          	beqz	a0,80000736 <printf+0x1ac>
    if(c != '%'){
    80000632:	ff5515e3          	bne	a0,s5,8000061c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000636:	2985                	addiw	s3,s3,1
    80000638:	013a07b3          	add	a5,s4,s3
    8000063c:	0007c783          	lbu	a5,0(a5)
    80000640:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000644:	cbed                	beqz	a5,80000736 <printf+0x1ac>
    switch(c){
    80000646:	05778a63          	beq	a5,s7,8000069a <printf+0x110>
    8000064a:	02fbf663          	bgeu	s7,a5,80000676 <printf+0xec>
    8000064e:	09978863          	beq	a5,s9,800006de <printf+0x154>
    80000652:	07800713          	li	a4,120
    80000656:	0ce79563          	bne	a5,a4,80000720 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065a:	f8843783          	ld	a5,-120(s0)
    8000065e:	00878713          	addi	a4,a5,8
    80000662:	f8e43423          	sd	a4,-120(s0)
    80000666:	4605                	li	a2,1
    80000668:	85ea                	mv	a1,s10
    8000066a:	4388                	lw	a0,0(a5)
    8000066c:	00000097          	auipc	ra,0x0
    80000670:	e30080e7          	jalr	-464(ra) # 8000049c <printint>
      break;
    80000674:	bf45                	j	80000624 <printf+0x9a>
    switch(c){
    80000676:	09578f63          	beq	a5,s5,80000714 <printf+0x18a>
    8000067a:	0b879363          	bne	a5,s8,80000720 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067e:	f8843783          	ld	a5,-120(s0)
    80000682:	00878713          	addi	a4,a5,8
    80000686:	f8e43423          	sd	a4,-120(s0)
    8000068a:	4605                	li	a2,1
    8000068c:	45a9                	li	a1,10
    8000068e:	4388                	lw	a0,0(a5)
    80000690:	00000097          	auipc	ra,0x0
    80000694:	e0c080e7          	jalr	-500(ra) # 8000049c <printint>
      break;
    80000698:	b771                	j	80000624 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069a:	f8843783          	ld	a5,-120(s0)
    8000069e:	00878713          	addi	a4,a5,8
    800006a2:	f8e43423          	sd	a4,-120(s0)
    800006a6:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006aa:	03000513          	li	a0,48
    800006ae:	00000097          	auipc	ra,0x0
    800006b2:	bce080e7          	jalr	-1074(ra) # 8000027c <consputc>
  consputc('x');
    800006b6:	07800513          	li	a0,120
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bc2080e7          	jalr	-1086(ra) # 8000027c <consputc>
    800006c2:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c4:	03c95793          	srli	a5,s2,0x3c
    800006c8:	97da                	add	a5,a5,s6
    800006ca:	0007c503          	lbu	a0,0(a5)
    800006ce:	00000097          	auipc	ra,0x0
    800006d2:	bae080e7          	jalr	-1106(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d6:	0912                	slli	s2,s2,0x4
    800006d8:	34fd                	addiw	s1,s1,-1
    800006da:	f4ed                	bnez	s1,800006c4 <printf+0x13a>
    800006dc:	b7a1                	j	80000624 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	6384                	ld	s1,0(a5)
    800006ec:	cc89                	beqz	s1,80000706 <printf+0x17c>
      for(; *s; s++)
    800006ee:	0004c503          	lbu	a0,0(s1)
    800006f2:	d90d                	beqz	a0,80000624 <printf+0x9a>
        consputc(*s);
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b88080e7          	jalr	-1144(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fc:	0485                	addi	s1,s1,1
    800006fe:	0004c503          	lbu	a0,0(s1)
    80000702:	f96d                	bnez	a0,800006f4 <printf+0x16a>
    80000704:	b705                	j	80000624 <printf+0x9a>
        s = "(null)";
    80000706:	00008497          	auipc	s1,0x8
    8000070a:	91a48493          	addi	s1,s1,-1766 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070e:	02800513          	li	a0,40
    80000712:	b7cd                	j	800006f4 <printf+0x16a>
      consputc('%');
    80000714:	8556                	mv	a0,s5
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b66080e7          	jalr	-1178(ra) # 8000027c <consputc>
      break;
    8000071e:	b719                	j	80000624 <printf+0x9a>
      consputc('%');
    80000720:	8556                	mv	a0,s5
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b5a080e7          	jalr	-1190(ra) # 8000027c <consputc>
      consputc(c);
    8000072a:	8526                	mv	a0,s1
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b50080e7          	jalr	-1200(ra) # 8000027c <consputc>
      break;
    80000734:	bdc5                	j	80000624 <printf+0x9a>
  if(locking)
    80000736:	020d9163          	bnez	s11,80000758 <printf+0x1ce>
}
    8000073a:	70e6                	ld	ra,120(sp)
    8000073c:	7446                	ld	s0,112(sp)
    8000073e:	74a6                	ld	s1,104(sp)
    80000740:	7906                	ld	s2,96(sp)
    80000742:	69e6                	ld	s3,88(sp)
    80000744:	6a46                	ld	s4,80(sp)
    80000746:	6aa6                	ld	s5,72(sp)
    80000748:	6b06                	ld	s6,64(sp)
    8000074a:	7be2                	ld	s7,56(sp)
    8000074c:	7c42                	ld	s8,48(sp)
    8000074e:	7ca2                	ld	s9,40(sp)
    80000750:	7d02                	ld	s10,32(sp)
    80000752:	6de2                	ld	s11,24(sp)
    80000754:	6129                	addi	sp,sp,192
    80000756:	8082                	ret
    release(&pr.lock);
    80000758:	00010517          	auipc	a0,0x10
    8000075c:	4c050513          	addi	a0,a0,1216 # 80010c18 <pr>
    80000760:	00000097          	auipc	ra,0x0
    80000764:	52a080e7          	jalr	1322(ra) # 80000c8a <release>
}
    80000768:	bfc9                	j	8000073a <printf+0x1b0>

000000008000076a <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076a:	1101                	addi	sp,sp,-32
    8000076c:	ec06                	sd	ra,24(sp)
    8000076e:	e822                	sd	s0,16(sp)
    80000770:	e426                	sd	s1,8(sp)
    80000772:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000774:	00010497          	auipc	s1,0x10
    80000778:	4a448493          	addi	s1,s1,1188 # 80010c18 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80008038 <etext+0x38>
    80000784:	8526                	mv	a0,s1
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	3c0080e7          	jalr	960(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078e:	4785                	li	a5,1
    80000790:	cc9c                	sw	a5,24(s1)
}
    80000792:	60e2                	ld	ra,24(sp)
    80000794:	6442                	ld	s0,16(sp)
    80000796:	64a2                	ld	s1,8(sp)
    80000798:	6105                	addi	sp,sp,32
    8000079a:	8082                	ret

000000008000079c <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079c:	1141                	addi	sp,sp,-16
    8000079e:	e406                	sd	ra,8(sp)
    800007a0:	e022                	sd	s0,0(sp)
    800007a2:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a4:	100007b7          	lui	a5,0x10000
    800007a8:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ac:	f8000713          	li	a4,-128
    800007b0:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b4:	470d                	li	a4,3
    800007b6:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007ba:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007be:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c2:	469d                	li	a3,7
    800007c4:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c8:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007cc:	00008597          	auipc	a1,0x8
    800007d0:	88c58593          	addi	a1,a1,-1908 # 80008058 <digits+0x18>
    800007d4:	00010517          	auipc	a0,0x10
    800007d8:	46450513          	addi	a0,a0,1124 # 80010c38 <uart_tx_lock>
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	36a080e7          	jalr	874(ra) # 80000b46 <initlock>
}
    800007e4:	60a2                	ld	ra,8(sp)
    800007e6:	6402                	ld	s0,0(sp)
    800007e8:	0141                	addi	sp,sp,16
    800007ea:	8082                	ret

00000000800007ec <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ec:	1101                	addi	sp,sp,-32
    800007ee:	ec06                	sd	ra,24(sp)
    800007f0:	e822                	sd	s0,16(sp)
    800007f2:	e426                	sd	s1,8(sp)
    800007f4:	1000                	addi	s0,sp,32
    800007f6:	84aa                	mv	s1,a0
  push_off();
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	392080e7          	jalr	914(ra) # 80000b8a <push_off>

  if(panicked){
    80000800:	00008797          	auipc	a5,0x8
    80000804:	1f07a783          	lw	a5,496(a5) # 800089f0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080c:	c391                	beqz	a5,80000810 <uartputc_sync+0x24>
    for(;;)
    8000080e:	a001                	j	8000080e <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000810:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000814:	0207f793          	andi	a5,a5,32
    80000818:	dfe5                	beqz	a5,80000810 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081a:	0ff4f513          	zext.b	a0,s1
    8000081e:	100007b7          	lui	a5,0x10000
    80000822:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000826:	00000097          	auipc	ra,0x0
    8000082a:	404080e7          	jalr	1028(ra) # 80000c2a <pop_off>
}
    8000082e:	60e2                	ld	ra,24(sp)
    80000830:	6442                	ld	s0,16(sp)
    80000832:	64a2                	ld	s1,8(sp)
    80000834:	6105                	addi	sp,sp,32
    80000836:	8082                	ret

0000000080000838 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000838:	00008797          	auipc	a5,0x8
    8000083c:	1c07b783          	ld	a5,448(a5) # 800089f8 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	1c073703          	ld	a4,448(a4) # 80008a00 <uart_tx_w>
    80000848:	06f70a63          	beq	a4,a5,800008bc <uartstart+0x84>
{
    8000084c:	7139                	addi	sp,sp,-64
    8000084e:	fc06                	sd	ra,56(sp)
    80000850:	f822                	sd	s0,48(sp)
    80000852:	f426                	sd	s1,40(sp)
    80000854:	f04a                	sd	s2,32(sp)
    80000856:	ec4e                	sd	s3,24(sp)
    80000858:	e852                	sd	s4,16(sp)
    8000085a:	e456                	sd	s5,8(sp)
    8000085c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000862:	00010a17          	auipc	s4,0x10
    80000866:	3d6a0a13          	addi	s4,s4,982 # 80010c38 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	18e48493          	addi	s1,s1,398 # 800089f8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	18e98993          	addi	s3,s3,398 # 80008a00 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087a:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087e:	02077713          	andi	a4,a4,32
    80000882:	c705                	beqz	a4,800008aa <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000884:	01f7f713          	andi	a4,a5,31
    80000888:	9752                	add	a4,a4,s4
    8000088a:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088e:	0785                	addi	a5,a5,1
    80000890:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000892:	8526                	mv	a0,s1
    80000894:	00002097          	auipc	ra,0x2
    80000898:	bea080e7          	jalr	-1046(ra) # 8000247e <wakeup>
    
    WriteReg(THR, c);
    8000089c:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008a0:	609c                	ld	a5,0(s1)
    800008a2:	0009b703          	ld	a4,0(s3)
    800008a6:	fcf71ae3          	bne	a4,a5,8000087a <uartstart+0x42>
  }
}
    800008aa:	70e2                	ld	ra,56(sp)
    800008ac:	7442                	ld	s0,48(sp)
    800008ae:	74a2                	ld	s1,40(sp)
    800008b0:	7902                	ld	s2,32(sp)
    800008b2:	69e2                	ld	s3,24(sp)
    800008b4:	6a42                	ld	s4,16(sp)
    800008b6:	6aa2                	ld	s5,8(sp)
    800008b8:	6121                	addi	sp,sp,64
    800008ba:	8082                	ret
    800008bc:	8082                	ret

00000000800008be <uartputc>:
{
    800008be:	7179                	addi	sp,sp,-48
    800008c0:	f406                	sd	ra,40(sp)
    800008c2:	f022                	sd	s0,32(sp)
    800008c4:	ec26                	sd	s1,24(sp)
    800008c6:	e84a                	sd	s2,16(sp)
    800008c8:	e44e                	sd	s3,8(sp)
    800008ca:	e052                	sd	s4,0(sp)
    800008cc:	1800                	addi	s0,sp,48
    800008ce:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008d0:	00010517          	auipc	a0,0x10
    800008d4:	36850513          	addi	a0,a0,872 # 80010c38 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	2fe080e7          	jalr	766(ra) # 80000bd6 <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	1107a783          	lw	a5,272(a5) # 800089f0 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	11673703          	ld	a4,278(a4) # 80008a00 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	1067b783          	ld	a5,262(a5) # 800089f8 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	33a98993          	addi	s3,s3,826 # 80010c38 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	0f248493          	addi	s1,s1,242 # 800089f8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	0f290913          	addi	s2,s2,242 # 80008a00 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00002097          	auipc	ra,0x2
    80000922:	afc080e7          	jalr	-1284(ra) # 8000241a <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	30448493          	addi	s1,s1,772 # 80010c38 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	0ae7bc23          	sd	a4,184(a5) # 80008a00 <uart_tx_w>
  uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee8080e7          	jalr	-280(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	330080e7          	jalr	816(ra) # 80000c8a <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret
    for(;;)
    80000972:	a001                	j	80000972 <uartputc+0xb4>

0000000080000974 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000974:	1141                	addi	sp,sp,-16
    80000976:	e422                	sd	s0,8(sp)
    80000978:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000097a:	100007b7          	lui	a5,0x10000
    8000097e:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000982:	8b85                	andi	a5,a5,1
    80000984:	cb81                	beqz	a5,80000994 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098e:	6422                	ld	s0,8(sp)
    80000990:	0141                	addi	sp,sp,16
    80000992:	8082                	ret
    return -1;
    80000994:	557d                	li	a0,-1
    80000996:	bfe5                	j	8000098e <uartgetc+0x1a>

0000000080000998 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000998:	1101                	addi	sp,sp,-32
    8000099a:	ec06                	sd	ra,24(sp)
    8000099c:	e822                	sd	s0,16(sp)
    8000099e:	e426                	sd	s1,8(sp)
    800009a0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a2:	54fd                	li	s1,-1
    800009a4:	a029                	j	800009ae <uartintr+0x16>
      break;
    consoleintr(c);
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	918080e7          	jalr	-1768(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009ae:	00000097          	auipc	ra,0x0
    800009b2:	fc6080e7          	jalr	-58(ra) # 80000974 <uartgetc>
    if(c == -1)
    800009b6:	fe9518e3          	bne	a0,s1,800009a6 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ba:	00010497          	auipc	s1,0x10
    800009be:	27e48493          	addi	s1,s1,638 # 80010c38 <uart_tx_lock>
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	212080e7          	jalr	530(ra) # 80000bd6 <acquire>
  uartstart();
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	e6c080e7          	jalr	-404(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	2b4080e7          	jalr	692(ra) # 80000c8a <release>
}
    800009de:	60e2                	ld	ra,24(sp)
    800009e0:	6442                	ld	s0,16(sp)
    800009e2:	64a2                	ld	s1,8(sp)
    800009e4:	6105                	addi	sp,sp,32
    800009e6:	8082                	ret

00000000800009e8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e8:	1101                	addi	sp,sp,-32
    800009ea:	ec06                	sd	ra,24(sp)
    800009ec:	e822                	sd	s0,16(sp)
    800009ee:	e426                	sd	s1,8(sp)
    800009f0:	e04a                	sd	s2,0(sp)
    800009f2:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f4:	03451793          	slli	a5,a0,0x34
    800009f8:	ebb9                	bnez	a5,80000a4e <kfree+0x66>
    800009fa:	84aa                	mv	s1,a0
    800009fc:	00021797          	auipc	a5,0x21
    80000a00:	6e478793          	addi	a5,a5,1764 # 800220e0 <end>
    80000a04:	04f56563          	bltu	a0,a5,80000a4e <kfree+0x66>
    80000a08:	47c5                	li	a5,17
    80000a0a:	07ee                	slli	a5,a5,0x1b
    80000a0c:	04f57163          	bgeu	a0,a5,80000a4e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a10:	6605                	lui	a2,0x1
    80000a12:	4585                	li	a1,1
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	2be080e7          	jalr	702(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1c:	00010917          	auipc	s2,0x10
    80000a20:	25490913          	addi	s2,s2,596 # 80010c70 <kmem>
    80000a24:	854a                	mv	a0,s2
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	1b0080e7          	jalr	432(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a2e:	01893783          	ld	a5,24(s2)
    80000a32:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a34:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a38:	854a                	mv	a0,s2
    80000a3a:	00000097          	auipc	ra,0x0
    80000a3e:	250080e7          	jalr	592(ra) # 80000c8a <release>
}
    80000a42:	60e2                	ld	ra,24(sp)
    80000a44:	6442                	ld	s0,16(sp)
    80000a46:	64a2                	ld	s1,8(sp)
    80000a48:	6902                	ld	s2,0(sp)
    80000a4a:	6105                	addi	sp,sp,32
    80000a4c:	8082                	ret
    panic("kfree");
    80000a4e:	00007517          	auipc	a0,0x7
    80000a52:	61250513          	addi	a0,a0,1554 # 80008060 <digits+0x20>
    80000a56:	00000097          	auipc	ra,0x0
    80000a5a:	aea080e7          	jalr	-1302(ra) # 80000540 <panic>

0000000080000a5e <freerange>:
{
    80000a5e:	7179                	addi	sp,sp,-48
    80000a60:	f406                	sd	ra,40(sp)
    80000a62:	f022                	sd	s0,32(sp)
    80000a64:	ec26                	sd	s1,24(sp)
    80000a66:	e84a                	sd	s2,16(sp)
    80000a68:	e44e                	sd	s3,8(sp)
    80000a6a:	e052                	sd	s4,0(sp)
    80000a6c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6e:	6785                	lui	a5,0x1
    80000a70:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a74:	00e504b3          	add	s1,a0,a4
    80000a78:	777d                	lui	a4,0xfffff
    80000a7a:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3c>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5c080e7          	jalr	-164(ra) # 800009e8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x2a>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	1b650513          	addi	a0,a0,438 # 80010c70 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00021517          	auipc	a0,0x21
    80000ad2:	61250513          	addi	a0,a0,1554 # 800220e0 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f88080e7          	jalr	-120(ra) # 80000a5e <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	18048493          	addi	s1,s1,384 # 80010c70 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	16850513          	addi	a0,a0,360 # 80010c70 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	13c50513          	addi	a0,a0,316 # 80010c70 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	0b8080e7          	jalr	184(ra) # 80001c28 <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	086080e7          	jalr	134(ra) # 80001c28 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	07a080e7          	jalr	122(ra) # 80001c28 <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	062080e7          	jalr	98(ra) # 80001c28 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	022080e7          	jalr	34(ra) # 80001c28 <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91e080e7          	jalr	-1762(ra) # 80000540 <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	ff6080e7          	jalr	-10(ra) # 80001c28 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8ce080e7          	jalr	-1842(ra) # 80000540 <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8be080e7          	jalr	-1858(ra) # 80000540 <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	876080e7          	jalr	-1930(ra) # 80000540 <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdcf21>
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	40d707bb          	subw	a5,a4,a3
    80000e0c:	37fd                	addiw	a5,a5,-1
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	d98080e7          	jalr	-616(ra) # 80001c18 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	b8070713          	addi	a4,a4,-1152 # 80008a08 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	d7c080e7          	jalr	-644(ra) # 80001c18 <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6dc080e7          	jalr	1756(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	c98080e7          	jalr	-872(ra) # 80002b56 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	2da080e7          	jalr	730(ra) # 800061a0 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	412080e7          	jalr	1042(ra) # 800022e0 <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88c080e7          	jalr	-1908(ra) # 8000076a <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	1e250513          	addi	a0,a0,482 # 800080c8 <digits+0x88>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69c080e7          	jalr	1692(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68c080e7          	jalr	1676(ra) # 8000058a <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	1c250513          	addi	a0,a0,450 # 800080c8 <digits+0x88>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67c080e7          	jalr	1660(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	326080e7          	jalr	806(ra) # 80001244 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	068080e7          	jalr	104(ra) # 80000f8e <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	c08080e7          	jalr	-1016(ra) # 80001b36 <procinit>
    trapinit();      // trap vectors
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	bf8080e7          	jalr	-1032(ra) # 80002b2e <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	c18080e7          	jalr	-1000(ra) # 80002b56 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	244080e7          	jalr	580(ra) # 8000618a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	252080e7          	jalr	594(ra) # 800061a0 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	3f0080e7          	jalr	1008(ra) # 80003346 <binit>
    iinit();         // inode table
    80000f5e:	00003097          	auipc	ra,0x3
    80000f62:	a90080e7          	jalr	-1392(ra) # 800039ee <iinit>
    fileinit();      // file table
    80000f66:	00004097          	auipc	ra,0x4
    80000f6a:	a36080e7          	jalr	-1482(ra) # 8000499c <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	33a080e7          	jalr	826(ra) # 800062a8 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	fb6080e7          	jalr	-74(ra) # 80001f2c <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	a8f72223          	sw	a5,-1404(a4) # 80008a08 <started>
    80000f8c:	b789                	j	80000ece <main+0x56>

0000000080000f8e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f8e:	1141                	addi	sp,sp,-16
    80000f90:	e422                	sd	s0,8(sp)
    80000f92:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f94:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f98:	00008797          	auipc	a5,0x8
    80000f9c:	a787b783          	ld	a5,-1416(a5) # 80008a10 <kernel_pagetable>
    80000fa0:	83b1                	srli	a5,a5,0xc
    80000fa2:	577d                	li	a4,-1
    80000fa4:	177e                	slli	a4,a4,0x3f
    80000fa6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fac:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb0:	6422                	ld	s0,8(sp)
    80000fb2:	0141                	addi	sp,sp,16
    80000fb4:	8082                	ret

0000000080000fb6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb6:	7139                	addi	sp,sp,-64
    80000fb8:	fc06                	sd	ra,56(sp)
    80000fba:	f822                	sd	s0,48(sp)
    80000fbc:	f426                	sd	s1,40(sp)
    80000fbe:	f04a                	sd	s2,32(sp)
    80000fc0:	ec4e                	sd	s3,24(sp)
    80000fc2:	e852                	sd	s4,16(sp)
    80000fc4:	e456                	sd	s5,8(sp)
    80000fc6:	e05a                	sd	s6,0(sp)
    80000fc8:	0080                	addi	s0,sp,64
    80000fca:	84aa                	mv	s1,a0
    80000fcc:	89ae                	mv	s3,a1
    80000fce:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd0:	57fd                	li	a5,-1
    80000fd2:	83e9                	srli	a5,a5,0x1a
    80000fd4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd8:	04b7f263          	bgeu	a5,a1,8000101c <walk+0x66>
    panic("walk");
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	0f450513          	addi	a0,a0,244 # 800080d0 <digits+0x90>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	55c080e7          	jalr	1372(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fec:	060a8663          	beqz	s5,80001058 <walk+0xa2>
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	af6080e7          	jalr	-1290(ra) # 80000ae6 <kalloc>
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	c529                	beqz	a0,80001044 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ffc:	6605                	lui	a2,0x1
    80000ffe:	4581                	li	a1,0
    80001000:	00000097          	auipc	ra,0x0
    80001004:	cd2080e7          	jalr	-814(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001008:	00c4d793          	srli	a5,s1,0xc
    8000100c:	07aa                	slli	a5,a5,0xa
    8000100e:	0017e793          	ori	a5,a5,1
    80001012:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001016:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdcf17>
    80001018:	036a0063          	beq	s4,s6,80001038 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000101c:	0149d933          	srl	s2,s3,s4
    80001020:	1ff97913          	andi	s2,s2,511
    80001024:	090e                	slli	s2,s2,0x3
    80001026:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001028:	00093483          	ld	s1,0(s2)
    8000102c:	0014f793          	andi	a5,s1,1
    80001030:	dfd5                	beqz	a5,80000fec <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001032:	80a9                	srli	s1,s1,0xa
    80001034:	04b2                	slli	s1,s1,0xc
    80001036:	b7c5                	j	80001016 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001038:	00c9d513          	srli	a0,s3,0xc
    8000103c:	1ff57513          	andi	a0,a0,511
    80001040:	050e                	slli	a0,a0,0x3
    80001042:	9526                	add	a0,a0,s1
}
    80001044:	70e2                	ld	ra,56(sp)
    80001046:	7442                	ld	s0,48(sp)
    80001048:	74a2                	ld	s1,40(sp)
    8000104a:	7902                	ld	s2,32(sp)
    8000104c:	69e2                	ld	s3,24(sp)
    8000104e:	6a42                	ld	s4,16(sp)
    80001050:	6aa2                	ld	s5,8(sp)
    80001052:	6b02                	ld	s6,0(sp)
    80001054:	6121                	addi	sp,sp,64
    80001056:	8082                	ret
        return 0;
    80001058:	4501                	li	a0,0
    8000105a:	b7ed                	j	80001044 <walk+0x8e>

000000008000105c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	00b7f463          	bgeu	a5,a1,80001068 <walkaddr+0xc>
    return 0;
    80001064:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001066:	8082                	ret
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001070:	4601                	li	a2,0
    80001072:	00000097          	auipc	ra,0x0
    80001076:	f44080e7          	jalr	-188(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000107a:	c105                	beqz	a0,8000109a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000107c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000107e:	0117f693          	andi	a3,a5,17
    80001082:	4745                	li	a4,17
    return 0;
    80001084:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001086:	00e68663          	beq	a3,a4,80001092 <walkaddr+0x36>
}
    8000108a:	60a2                	ld	ra,8(sp)
    8000108c:	6402                	ld	s0,0(sp)
    8000108e:	0141                	addi	sp,sp,16
    80001090:	8082                	ret
  pa = PTE2PA(*pte);
    80001092:	83a9                	srli	a5,a5,0xa
    80001094:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001098:	bfcd                	j	8000108a <walkaddr+0x2e>
    return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7fd                	j	8000108a <walkaddr+0x2e>

000000008000109e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000109e:	715d                	addi	sp,sp,-80
    800010a0:	e486                	sd	ra,72(sp)
    800010a2:	e0a2                	sd	s0,64(sp)
    800010a4:	fc26                	sd	s1,56(sp)
    800010a6:	f84a                	sd	s2,48(sp)
    800010a8:	f44e                	sd	s3,40(sp)
    800010aa:	f052                	sd	s4,32(sp)
    800010ac:	ec56                	sd	s5,24(sp)
    800010ae:	e85a                	sd	s6,16(sp)
    800010b0:	e45e                	sd	s7,8(sp)
    800010b2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010b4:	c639                	beqz	a2,80001102 <mappages+0x64>
    800010b6:	8aaa                	mv	s5,a0
    800010b8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010ba:	777d                	lui	a4,0xfffff
    800010bc:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010c0:	fff58993          	addi	s3,a1,-1
    800010c4:	99b2                	add	s3,s3,a2
    800010c6:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010ca:	893e                	mv	s2,a5
    800010cc:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d0:	6b85                	lui	s7,0x1
    800010d2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d6:	4605                	li	a2,1
    800010d8:	85ca                	mv	a1,s2
    800010da:	8556                	mv	a0,s5
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	eda080e7          	jalr	-294(ra) # 80000fb6 <walk>
    800010e4:	cd1d                	beqz	a0,80001122 <mappages+0x84>
    if(*pte & PTE_V)
    800010e6:	611c                	ld	a5,0(a0)
    800010e8:	8b85                	andi	a5,a5,1
    800010ea:	e785                	bnez	a5,80001112 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010ec:	80b1                	srli	s1,s1,0xc
    800010ee:	04aa                	slli	s1,s1,0xa
    800010f0:	0164e4b3          	or	s1,s1,s6
    800010f4:	0014e493          	ori	s1,s1,1
    800010f8:	e104                	sd	s1,0(a0)
    if(a == last)
    800010fa:	05390063          	beq	s2,s3,8000113a <mappages+0x9c>
    a += PGSIZE;
    800010fe:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001100:	bfc9                	j	800010d2 <mappages+0x34>
    panic("mappages: size");
    80001102:	00007517          	auipc	a0,0x7
    80001106:	fd650513          	addi	a0,a0,-42 # 800080d8 <digits+0x98>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	436080e7          	jalr	1078(ra) # 80000540 <panic>
      panic("mappages: remap");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fd650513          	addi	a0,a0,-42 # 800080e8 <digits+0xa8>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	426080e7          	jalr	1062(ra) # 80000540 <panic>
      return -1;
    80001122:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001124:	60a6                	ld	ra,72(sp)
    80001126:	6406                	ld	s0,64(sp)
    80001128:	74e2                	ld	s1,56(sp)
    8000112a:	7942                	ld	s2,48(sp)
    8000112c:	79a2                	ld	s3,40(sp)
    8000112e:	7a02                	ld	s4,32(sp)
    80001130:	6ae2                	ld	s5,24(sp)
    80001132:	6b42                	ld	s6,16(sp)
    80001134:	6ba2                	ld	s7,8(sp)
    80001136:	6161                	addi	sp,sp,80
    80001138:	8082                	ret
  return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7e5                	j	80001124 <mappages+0x86>

000000008000113e <kvmmap>:
{
    8000113e:	1141                	addi	sp,sp,-16
    80001140:	e406                	sd	ra,8(sp)
    80001142:	e022                	sd	s0,0(sp)
    80001144:	0800                	addi	s0,sp,16
    80001146:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001148:	86b2                	mv	a3,a2
    8000114a:	863e                	mv	a2,a5
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	f52080e7          	jalr	-174(ra) # 8000109e <mappages>
    80001154:	e509                	bnez	a0,8000115e <kvmmap+0x20>
}
    80001156:	60a2                	ld	ra,8(sp)
    80001158:	6402                	ld	s0,0(sp)
    8000115a:	0141                	addi	sp,sp,16
    8000115c:	8082                	ret
    panic("kvmmap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f9a50513          	addi	a0,a0,-102 # 800080f8 <digits+0xb8>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3da080e7          	jalr	986(ra) # 80000540 <panic>

000000008000116e <kvmmake>:
{
    8000116e:	1101                	addi	sp,sp,-32
    80001170:	ec06                	sd	ra,24(sp)
    80001172:	e822                	sd	s0,16(sp)
    80001174:	e426                	sd	s1,8(sp)
    80001176:	e04a                	sd	s2,0(sp)
    80001178:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	96c080e7          	jalr	-1684(ra) # 80000ae6 <kalloc>
    80001182:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001184:	6605                	lui	a2,0x1
    80001186:	4581                	li	a1,0
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	b4a080e7          	jalr	-1206(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10000637          	lui	a2,0x10000
    80001198:	100005b7          	lui	a1,0x10000
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	fa0080e7          	jalr	-96(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	6685                	lui	a3,0x1
    800011aa:	10001637          	lui	a2,0x10001
    800011ae:	100015b7          	lui	a1,0x10001
    800011b2:	8526                	mv	a0,s1
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f8a080e7          	jalr	-118(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011bc:	4719                	li	a4,6
    800011be:	004006b7          	lui	a3,0x400
    800011c2:	0c000637          	lui	a2,0xc000
    800011c6:	0c0005b7          	lui	a1,0xc000
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f72080e7          	jalr	-142(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011d4:	00007917          	auipc	s2,0x7
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80008000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80007697          	auipc	a3,0x80007
    800011e2:	e2268693          	addi	a3,a3,-478 # 8000 <_entry-0x7fff8000>
    800011e6:	4605                	li	a2,1
    800011e8:	067e                	slli	a2,a2,0x1f
    800011ea:	85b2                	mv	a1,a2
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f50080e7          	jalr	-176(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	46c5                	li	a3,17
    800011fa:	06ee                	slli	a3,a3,0x1b
    800011fc:	412686b3          	sub	a3,a3,s2
    80001200:	864a                	mv	a2,s2
    80001202:	85ca                	mv	a1,s2
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f38080e7          	jalr	-200(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000120e:	4729                	li	a4,10
    80001210:	6685                	lui	a3,0x1
    80001212:	00006617          	auipc	a2,0x6
    80001216:	dee60613          	addi	a2,a2,-530 # 80007000 <_trampoline>
    8000121a:	040005b7          	lui	a1,0x4000
    8000121e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001220:	05b2                	slli	a1,a1,0xc
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f1a080e7          	jalr	-230(ra) # 8000113e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000122c:	8526                	mv	a0,s1
    8000122e:	00001097          	auipc	ra,0x1
    80001232:	872080e7          	jalr	-1934(ra) # 80001aa0 <proc_mapstacks>
}
    80001236:	8526                	mv	a0,s1
    80001238:	60e2                	ld	ra,24(sp)
    8000123a:	6442                	ld	s0,16(sp)
    8000123c:	64a2                	ld	s1,8(sp)
    8000123e:	6902                	ld	s2,0(sp)
    80001240:	6105                	addi	sp,sp,32
    80001242:	8082                	ret

0000000080001244 <kvminit>:
{
    80001244:	1141                	addi	sp,sp,-16
    80001246:	e406                	sd	ra,8(sp)
    80001248:	e022                	sd	s0,0(sp)
    8000124a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f22080e7          	jalr	-222(ra) # 8000116e <kvmmake>
    80001254:	00007797          	auipc	a5,0x7
    80001258:	7aa7be23          	sd	a0,1980(a5) # 80008a10 <kernel_pagetable>
}
    8000125c:	60a2                	ld	ra,8(sp)
    8000125e:	6402                	ld	s0,0(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001264:	715d                	addi	sp,sp,-80
    80001266:	e486                	sd	ra,72(sp)
    80001268:	e0a2                	sd	s0,64(sp)
    8000126a:	fc26                	sd	s1,56(sp)
    8000126c:	f84a                	sd	s2,48(sp)
    8000126e:	f44e                	sd	s3,40(sp)
    80001270:	f052                	sd	s4,32(sp)
    80001272:	ec56                	sd	s5,24(sp)
    80001274:	e85a                	sd	s6,16(sp)
    80001276:	e45e                	sd	s7,8(sp)
    80001278:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000127a:	03459793          	slli	a5,a1,0x34
    8000127e:	e795                	bnez	a5,800012aa <uvmunmap+0x46>
    80001280:	8a2a                	mv	s4,a0
    80001282:	892e                	mv	s2,a1
    80001284:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001286:	0632                	slli	a2,a2,0xc
    80001288:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000128c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	6b05                	lui	s6,0x1
    80001290:	0735e263          	bltu	a1,s3,800012f4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001294:	60a6                	ld	ra,72(sp)
    80001296:	6406                	ld	s0,64(sp)
    80001298:	74e2                	ld	s1,56(sp)
    8000129a:	7942                	ld	s2,48(sp)
    8000129c:	79a2                	ld	s3,40(sp)
    8000129e:	7a02                	ld	s4,32(sp)
    800012a0:	6ae2                	ld	s5,24(sp)
    800012a2:	6b42                	ld	s6,16(sp)
    800012a4:	6ba2                	ld	s7,8(sp)
    800012a6:	6161                	addi	sp,sp,80
    800012a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012aa:	00007517          	auipc	a0,0x7
    800012ae:	e5650513          	addi	a0,a0,-426 # 80008100 <digits+0xc0>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28e080e7          	jalr	654(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e5e50513          	addi	a0,a0,-418 # 80008118 <digits+0xd8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27e080e7          	jalr	638(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e5e50513          	addi	a0,a0,-418 # 80008128 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26e080e7          	jalr	622(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e6650513          	addi	a0,a0,-410 # 80008140 <digits+0x100>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25e080e7          	jalr	606(ra) # 80000540 <panic>
    *pte = 0;
    800012ea:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ee:	995a                	add	s2,s2,s6
    800012f0:	fb3972e3          	bgeu	s2,s3,80001294 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f4:	4601                	li	a2,0
    800012f6:	85ca                	mv	a1,s2
    800012f8:	8552                	mv	a0,s4
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	cbc080e7          	jalr	-836(ra) # 80000fb6 <walk>
    80001302:	84aa                	mv	s1,a0
    80001304:	d95d                	beqz	a0,800012ba <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001306:	6108                	ld	a0,0(a0)
    80001308:	00157793          	andi	a5,a0,1
    8000130c:	dfdd                	beqz	a5,800012ca <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130e:	3ff57793          	andi	a5,a0,1023
    80001312:	fd7784e3          	beq	a5,s7,800012da <uvmunmap+0x76>
    if(do_free){
    80001316:	fc0a8ae3          	beqz	s5,800012ea <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000131a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000131c:	0532                	slli	a0,a0,0xc
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	6ca080e7          	jalr	1738(ra) # 800009e8 <kfree>
    80001326:	b7d1                	j	800012ea <uvmunmap+0x86>

0000000080001328 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001328:	1101                	addi	sp,sp,-32
    8000132a:	ec06                	sd	ra,24(sp)
    8000132c:	e822                	sd	s0,16(sp)
    8000132e:	e426                	sd	s1,8(sp)
    80001330:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	7b4080e7          	jalr	1972(ra) # 80000ae6 <kalloc>
    8000133a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000133c:	c519                	beqz	a0,8000134a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000133e:	6605                	lui	a2,0x1
    80001340:	4581                	li	a1,0
    80001342:	00000097          	auipc	ra,0x0
    80001346:	990080e7          	jalr	-1648(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000134a:	8526                	mv	a0,s1
    8000134c:	60e2                	ld	ra,24(sp)
    8000134e:	6442                	ld	s0,16(sp)
    80001350:	64a2                	ld	s1,8(sp)
    80001352:	6105                	addi	sp,sp,32
    80001354:	8082                	ret

0000000080001356 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001356:	7179                	addi	sp,sp,-48
    80001358:	f406                	sd	ra,40(sp)
    8000135a:	f022                	sd	s0,32(sp)
    8000135c:	ec26                	sd	s1,24(sp)
    8000135e:	e84a                	sd	s2,16(sp)
    80001360:	e44e                	sd	s3,8(sp)
    80001362:	e052                	sd	s4,0(sp)
    80001364:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001366:	6785                	lui	a5,0x1
    80001368:	04f67863          	bgeu	a2,a5,800013b8 <uvmfirst+0x62>
    8000136c:	8a2a                	mv	s4,a0
    8000136e:	89ae                	mv	s3,a1
    80001370:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	774080e7          	jalr	1908(ra) # 80000ae6 <kalloc>
    8000137a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000137c:	6605                	lui	a2,0x1
    8000137e:	4581                	li	a1,0
    80001380:	00000097          	auipc	ra,0x0
    80001384:	952080e7          	jalr	-1710(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001388:	4779                	li	a4,30
    8000138a:	86ca                	mv	a3,s2
    8000138c:	6605                	lui	a2,0x1
    8000138e:	4581                	li	a1,0
    80001390:	8552                	mv	a0,s4
    80001392:	00000097          	auipc	ra,0x0
    80001396:	d0c080e7          	jalr	-756(ra) # 8000109e <mappages>
  memmove(mem, src, sz);
    8000139a:	8626                	mv	a2,s1
    8000139c:	85ce                	mv	a1,s3
    8000139e:	854a                	mv	a0,s2
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	98e080e7          	jalr	-1650(ra) # 80000d2e <memmove>
}
    800013a8:	70a2                	ld	ra,40(sp)
    800013aa:	7402                	ld	s0,32(sp)
    800013ac:	64e2                	ld	s1,24(sp)
    800013ae:	6942                	ld	s2,16(sp)
    800013b0:	69a2                	ld	s3,8(sp)
    800013b2:	6a02                	ld	s4,0(sp)
    800013b4:	6145                	addi	sp,sp,48
    800013b6:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	da050513          	addi	a0,a0,-608 # 80008158 <digits+0x118>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	180080e7          	jalr	384(ra) # 80000540 <panic>

00000000800013c8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c8:	1101                	addi	sp,sp,-32
    800013ca:	ec06                	sd	ra,24(sp)
    800013cc:	e822                	sd	s0,16(sp)
    800013ce:	e426                	sd	s1,8(sp)
    800013d0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013d2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013d4:	00b67d63          	bgeu	a2,a1,800013ee <uvmdealloc+0x26>
    800013d8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013da:	6785                	lui	a5,0x1
    800013dc:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013de:	00f60733          	add	a4,a2,a5
    800013e2:	76fd                	lui	a3,0xfffff
    800013e4:	8f75                	and	a4,a4,a3
    800013e6:	97ae                	add	a5,a5,a1
    800013e8:	8ff5                	and	a5,a5,a3
    800013ea:	00f76863          	bltu	a4,a5,800013fa <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013ee:	8526                	mv	a0,s1
    800013f0:	60e2                	ld	ra,24(sp)
    800013f2:	6442                	ld	s0,16(sp)
    800013f4:	64a2                	ld	s1,8(sp)
    800013f6:	6105                	addi	sp,sp,32
    800013f8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013fa:	8f99                	sub	a5,a5,a4
    800013fc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013fe:	4685                	li	a3,1
    80001400:	0007861b          	sext.w	a2,a5
    80001404:	85ba                	mv	a1,a4
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	e5e080e7          	jalr	-418(ra) # 80001264 <uvmunmap>
    8000140e:	b7c5                	j	800013ee <uvmdealloc+0x26>

0000000080001410 <uvmalloc>:
  if(newsz < oldsz)
    80001410:	0ab66563          	bltu	a2,a1,800014ba <uvmalloc+0xaa>
{
    80001414:	7139                	addi	sp,sp,-64
    80001416:	fc06                	sd	ra,56(sp)
    80001418:	f822                	sd	s0,48(sp)
    8000141a:	f426                	sd	s1,40(sp)
    8000141c:	f04a                	sd	s2,32(sp)
    8000141e:	ec4e                	sd	s3,24(sp)
    80001420:	e852                	sd	s4,16(sp)
    80001422:	e456                	sd	s5,8(sp)
    80001424:	e05a                	sd	s6,0(sp)
    80001426:	0080                	addi	s0,sp,64
    80001428:	8aaa                	mv	s5,a0
    8000142a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000142c:	6785                	lui	a5,0x1
    8000142e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001430:	95be                	add	a1,a1,a5
    80001432:	77fd                	lui	a5,0xfffff
    80001434:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001438:	08c9f363          	bgeu	s3,a2,800014be <uvmalloc+0xae>
    8000143c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000143e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	6a4080e7          	jalr	1700(ra) # 80000ae6 <kalloc>
    8000144a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000144c:	c51d                	beqz	a0,8000147a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000144e:	6605                	lui	a2,0x1
    80001450:	4581                	li	a1,0
    80001452:	00000097          	auipc	ra,0x0
    80001456:	880080e7          	jalr	-1920(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	875a                	mv	a4,s6
    8000145c:	86a6                	mv	a3,s1
    8000145e:	6605                	lui	a2,0x1
    80001460:	85ca                	mv	a1,s2
    80001462:	8556                	mv	a0,s5
    80001464:	00000097          	auipc	ra,0x0
    80001468:	c3a080e7          	jalr	-966(ra) # 8000109e <mappages>
    8000146c:	e90d                	bnez	a0,8000149e <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146e:	6785                	lui	a5,0x1
    80001470:	993e                	add	s2,s2,a5
    80001472:	fd4968e3          	bltu	s2,s4,80001442 <uvmalloc+0x32>
  return newsz;
    80001476:	8552                	mv	a0,s4
    80001478:	a809                	j	8000148a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000147a:	864e                	mv	a2,s3
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	f48080e7          	jalr	-184(ra) # 800013c8 <uvmdealloc>
      return 0;
    80001488:	4501                	li	a0,0
}
    8000148a:	70e2                	ld	ra,56(sp)
    8000148c:	7442                	ld	s0,48(sp)
    8000148e:	74a2                	ld	s1,40(sp)
    80001490:	7902                	ld	s2,32(sp)
    80001492:	69e2                	ld	s3,24(sp)
    80001494:	6a42                	ld	s4,16(sp)
    80001496:	6aa2                	ld	s5,8(sp)
    80001498:	6b02                	ld	s6,0(sp)
    8000149a:	6121                	addi	sp,sp,64
    8000149c:	8082                	ret
      kfree(mem);
    8000149e:	8526                	mv	a0,s1
    800014a0:	fffff097          	auipc	ra,0xfffff
    800014a4:	548080e7          	jalr	1352(ra) # 800009e8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a8:	864e                	mv	a2,s3
    800014aa:	85ca                	mv	a1,s2
    800014ac:	8556                	mv	a0,s5
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	f1a080e7          	jalr	-230(ra) # 800013c8 <uvmdealloc>
      return 0;
    800014b6:	4501                	li	a0,0
    800014b8:	bfc9                	j	8000148a <uvmalloc+0x7a>
    return oldsz;
    800014ba:	852e                	mv	a0,a1
}
    800014bc:	8082                	ret
  return newsz;
    800014be:	8532                	mv	a0,a2
    800014c0:	b7e9                	j	8000148a <uvmalloc+0x7a>

00000000800014c2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014c2:	7179                	addi	sp,sp,-48
    800014c4:	f406                	sd	ra,40(sp)
    800014c6:	f022                	sd	s0,32(sp)
    800014c8:	ec26                	sd	s1,24(sp)
    800014ca:	e84a                	sd	s2,16(sp)
    800014cc:	e44e                	sd	s3,8(sp)
    800014ce:	e052                	sd	s4,0(sp)
    800014d0:	1800                	addi	s0,sp,48
    800014d2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014d4:	84aa                	mv	s1,a0
    800014d6:	6905                	lui	s2,0x1
    800014d8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014da:	4985                	li	s3,1
    800014dc:	a829                	j	800014f6 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014de:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014e0:	00c79513          	slli	a0,a5,0xc
    800014e4:	00000097          	auipc	ra,0x0
    800014e8:	fde080e7          	jalr	-34(ra) # 800014c2 <freewalk>
      pagetable[i] = 0;
    800014ec:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f0:	04a1                	addi	s1,s1,8
    800014f2:	03248163          	beq	s1,s2,80001514 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014f6:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f8:	00f7f713          	andi	a4,a5,15
    800014fc:	ff3701e3          	beq	a4,s3,800014de <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001500:	8b85                	andi	a5,a5,1
    80001502:	d7fd                	beqz	a5,800014f0 <freewalk+0x2e>
      panic("freewalk: leaf");
    80001504:	00007517          	auipc	a0,0x7
    80001508:	c7450513          	addi	a0,a0,-908 # 80008178 <digits+0x138>
    8000150c:	fffff097          	auipc	ra,0xfffff
    80001510:	034080e7          	jalr	52(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    80001514:	8552                	mv	a0,s4
    80001516:	fffff097          	auipc	ra,0xfffff
    8000151a:	4d2080e7          	jalr	1234(ra) # 800009e8 <kfree>
}
    8000151e:	70a2                	ld	ra,40(sp)
    80001520:	7402                	ld	s0,32(sp)
    80001522:	64e2                	ld	s1,24(sp)
    80001524:	6942                	ld	s2,16(sp)
    80001526:	69a2                	ld	s3,8(sp)
    80001528:	6a02                	ld	s4,0(sp)
    8000152a:	6145                	addi	sp,sp,48
    8000152c:	8082                	ret

000000008000152e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000152e:	1101                	addi	sp,sp,-32
    80001530:	ec06                	sd	ra,24(sp)
    80001532:	e822                	sd	s0,16(sp)
    80001534:	e426                	sd	s1,8(sp)
    80001536:	1000                	addi	s0,sp,32
    80001538:	84aa                	mv	s1,a0
  if(sz > 0)
    8000153a:	e999                	bnez	a1,80001550 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000153c:	8526                	mv	a0,s1
    8000153e:	00000097          	auipc	ra,0x0
    80001542:	f84080e7          	jalr	-124(ra) # 800014c2 <freewalk>
}
    80001546:	60e2                	ld	ra,24(sp)
    80001548:	6442                	ld	s0,16(sp)
    8000154a:	64a2                	ld	s1,8(sp)
    8000154c:	6105                	addi	sp,sp,32
    8000154e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001550:	6785                	lui	a5,0x1
    80001552:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001554:	95be                	add	a1,a1,a5
    80001556:	4685                	li	a3,1
    80001558:	00c5d613          	srli	a2,a1,0xc
    8000155c:	4581                	li	a1,0
    8000155e:	00000097          	auipc	ra,0x0
    80001562:	d06080e7          	jalr	-762(ra) # 80001264 <uvmunmap>
    80001566:	bfd9                	j	8000153c <uvmfree+0xe>

0000000080001568 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001568:	c679                	beqz	a2,80001636 <uvmcopy+0xce>
{
    8000156a:	715d                	addi	sp,sp,-80
    8000156c:	e486                	sd	ra,72(sp)
    8000156e:	e0a2                	sd	s0,64(sp)
    80001570:	fc26                	sd	s1,56(sp)
    80001572:	f84a                	sd	s2,48(sp)
    80001574:	f44e                	sd	s3,40(sp)
    80001576:	f052                	sd	s4,32(sp)
    80001578:	ec56                	sd	s5,24(sp)
    8000157a:	e85a                	sd	s6,16(sp)
    8000157c:	e45e                	sd	s7,8(sp)
    8000157e:	0880                	addi	s0,sp,80
    80001580:	8b2a                	mv	s6,a0
    80001582:	8aae                	mv	s5,a1
    80001584:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001586:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001588:	4601                	li	a2,0
    8000158a:	85ce                	mv	a1,s3
    8000158c:	855a                	mv	a0,s6
    8000158e:	00000097          	auipc	ra,0x0
    80001592:	a28080e7          	jalr	-1496(ra) # 80000fb6 <walk>
    80001596:	c531                	beqz	a0,800015e2 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001598:	6118                	ld	a4,0(a0)
    8000159a:	00177793          	andi	a5,a4,1
    8000159e:	cbb1                	beqz	a5,800015f2 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a0:	00a75593          	srli	a1,a4,0xa
    800015a4:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a8:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015ac:	fffff097          	auipc	ra,0xfffff
    800015b0:	53a080e7          	jalr	1338(ra) # 80000ae6 <kalloc>
    800015b4:	892a                	mv	s2,a0
    800015b6:	c939                	beqz	a0,8000160c <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b8:	6605                	lui	a2,0x1
    800015ba:	85de                	mv	a1,s7
    800015bc:	fffff097          	auipc	ra,0xfffff
    800015c0:	772080e7          	jalr	1906(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c4:	8726                	mv	a4,s1
    800015c6:	86ca                	mv	a3,s2
    800015c8:	6605                	lui	a2,0x1
    800015ca:	85ce                	mv	a1,s3
    800015cc:	8556                	mv	a0,s5
    800015ce:	00000097          	auipc	ra,0x0
    800015d2:	ad0080e7          	jalr	-1328(ra) # 8000109e <mappages>
    800015d6:	e515                	bnez	a0,80001602 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d8:	6785                	lui	a5,0x1
    800015da:	99be                	add	s3,s3,a5
    800015dc:	fb49e6e3          	bltu	s3,s4,80001588 <uvmcopy+0x20>
    800015e0:	a081                	j	80001620 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e2:	00007517          	auipc	a0,0x7
    800015e6:	ba650513          	addi	a0,a0,-1114 # 80008188 <digits+0x148>
    800015ea:	fffff097          	auipc	ra,0xfffff
    800015ee:	f56080e7          	jalr	-170(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    800015f2:	00007517          	auipc	a0,0x7
    800015f6:	bb650513          	addi	a0,a0,-1098 # 800081a8 <digits+0x168>
    800015fa:	fffff097          	auipc	ra,0xfffff
    800015fe:	f46080e7          	jalr	-186(ra) # 80000540 <panic>
      kfree(mem);
    80001602:	854a                	mv	a0,s2
    80001604:	fffff097          	auipc	ra,0xfffff
    80001608:	3e4080e7          	jalr	996(ra) # 800009e8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000160c:	4685                	li	a3,1
    8000160e:	00c9d613          	srli	a2,s3,0xc
    80001612:	4581                	li	a1,0
    80001614:	8556                	mv	a0,s5
    80001616:	00000097          	auipc	ra,0x0
    8000161a:	c4e080e7          	jalr	-946(ra) # 80001264 <uvmunmap>
  return -1;
    8000161e:	557d                	li	a0,-1
}
    80001620:	60a6                	ld	ra,72(sp)
    80001622:	6406                	ld	s0,64(sp)
    80001624:	74e2                	ld	s1,56(sp)
    80001626:	7942                	ld	s2,48(sp)
    80001628:	79a2                	ld	s3,40(sp)
    8000162a:	7a02                	ld	s4,32(sp)
    8000162c:	6ae2                	ld	s5,24(sp)
    8000162e:	6b42                	ld	s6,16(sp)
    80001630:	6ba2                	ld	s7,8(sp)
    80001632:	6161                	addi	sp,sp,80
    80001634:	8082                	ret
  return 0;
    80001636:	4501                	li	a0,0
}
    80001638:	8082                	ret

000000008000163a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000163a:	1141                	addi	sp,sp,-16
    8000163c:	e406                	sd	ra,8(sp)
    8000163e:	e022                	sd	s0,0(sp)
    80001640:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001642:	4601                	li	a2,0
    80001644:	00000097          	auipc	ra,0x0
    80001648:	972080e7          	jalr	-1678(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000164c:	c901                	beqz	a0,8000165c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000164e:	611c                	ld	a5,0(a0)
    80001650:	9bbd                	andi	a5,a5,-17
    80001652:	e11c                	sd	a5,0(a0)
}
    80001654:	60a2                	ld	ra,8(sp)
    80001656:	6402                	ld	s0,0(sp)
    80001658:	0141                	addi	sp,sp,16
    8000165a:	8082                	ret
    panic("uvmclear");
    8000165c:	00007517          	auipc	a0,0x7
    80001660:	b6c50513          	addi	a0,a0,-1172 # 800081c8 <digits+0x188>
    80001664:	fffff097          	auipc	ra,0xfffff
    80001668:	edc080e7          	jalr	-292(ra) # 80000540 <panic>

000000008000166c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000166c:	c6bd                	beqz	a3,800016da <copyout+0x6e>
{
    8000166e:	715d                	addi	sp,sp,-80
    80001670:	e486                	sd	ra,72(sp)
    80001672:	e0a2                	sd	s0,64(sp)
    80001674:	fc26                	sd	s1,56(sp)
    80001676:	f84a                	sd	s2,48(sp)
    80001678:	f44e                	sd	s3,40(sp)
    8000167a:	f052                	sd	s4,32(sp)
    8000167c:	ec56                	sd	s5,24(sp)
    8000167e:	e85a                	sd	s6,16(sp)
    80001680:	e45e                	sd	s7,8(sp)
    80001682:	e062                	sd	s8,0(sp)
    80001684:	0880                	addi	s0,sp,80
    80001686:	8b2a                	mv	s6,a0
    80001688:	8c2e                	mv	s8,a1
    8000168a:	8a32                	mv	s4,a2
    8000168c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000168e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001690:	6a85                	lui	s5,0x1
    80001692:	a015                	j	800016b6 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001694:	9562                	add	a0,a0,s8
    80001696:	0004861b          	sext.w	a2,s1
    8000169a:	85d2                	mv	a1,s4
    8000169c:	41250533          	sub	a0,a0,s2
    800016a0:	fffff097          	auipc	ra,0xfffff
    800016a4:	68e080e7          	jalr	1678(ra) # 80000d2e <memmove>

    len -= n;
    800016a8:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ac:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016ae:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b2:	02098263          	beqz	s3,800016d6 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b6:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016ba:	85ca                	mv	a1,s2
    800016bc:	855a                	mv	a0,s6
    800016be:	00000097          	auipc	ra,0x0
    800016c2:	99e080e7          	jalr	-1634(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800016c6:	cd01                	beqz	a0,800016de <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c8:	418904b3          	sub	s1,s2,s8
    800016cc:	94d6                	add	s1,s1,s5
    800016ce:	fc99f3e3          	bgeu	s3,s1,80001694 <copyout+0x28>
    800016d2:	84ce                	mv	s1,s3
    800016d4:	b7c1                	j	80001694 <copyout+0x28>
  }
  return 0;
    800016d6:	4501                	li	a0,0
    800016d8:	a021                	j	800016e0 <copyout+0x74>
    800016da:	4501                	li	a0,0
}
    800016dc:	8082                	ret
      return -1;
    800016de:	557d                	li	a0,-1
}
    800016e0:	60a6                	ld	ra,72(sp)
    800016e2:	6406                	ld	s0,64(sp)
    800016e4:	74e2                	ld	s1,56(sp)
    800016e6:	7942                	ld	s2,48(sp)
    800016e8:	79a2                	ld	s3,40(sp)
    800016ea:	7a02                	ld	s4,32(sp)
    800016ec:	6ae2                	ld	s5,24(sp)
    800016ee:	6b42                	ld	s6,16(sp)
    800016f0:	6ba2                	ld	s7,8(sp)
    800016f2:	6c02                	ld	s8,0(sp)
    800016f4:	6161                	addi	sp,sp,80
    800016f6:	8082                	ret

00000000800016f8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f8:	caa5                	beqz	a3,80001768 <copyin+0x70>
{
    800016fa:	715d                	addi	sp,sp,-80
    800016fc:	e486                	sd	ra,72(sp)
    800016fe:	e0a2                	sd	s0,64(sp)
    80001700:	fc26                	sd	s1,56(sp)
    80001702:	f84a                	sd	s2,48(sp)
    80001704:	f44e                	sd	s3,40(sp)
    80001706:	f052                	sd	s4,32(sp)
    80001708:	ec56                	sd	s5,24(sp)
    8000170a:	e85a                	sd	s6,16(sp)
    8000170c:	e45e                	sd	s7,8(sp)
    8000170e:	e062                	sd	s8,0(sp)
    80001710:	0880                	addi	s0,sp,80
    80001712:	8b2a                	mv	s6,a0
    80001714:	8a2e                	mv	s4,a1
    80001716:	8c32                	mv	s8,a2
    80001718:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000171a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000171c:	6a85                	lui	s5,0x1
    8000171e:	a01d                	j	80001744 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001720:	018505b3          	add	a1,a0,s8
    80001724:	0004861b          	sext.w	a2,s1
    80001728:	412585b3          	sub	a1,a1,s2
    8000172c:	8552                	mv	a0,s4
    8000172e:	fffff097          	auipc	ra,0xfffff
    80001732:	600080e7          	jalr	1536(ra) # 80000d2e <memmove>

    len -= n;
    80001736:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173a:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000173c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001740:	02098263          	beqz	s3,80001764 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001744:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001748:	85ca                	mv	a1,s2
    8000174a:	855a                	mv	a0,s6
    8000174c:	00000097          	auipc	ra,0x0
    80001750:	910080e7          	jalr	-1776(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    80001754:	cd01                	beqz	a0,8000176c <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001756:	418904b3          	sub	s1,s2,s8
    8000175a:	94d6                	add	s1,s1,s5
    8000175c:	fc99f2e3          	bgeu	s3,s1,80001720 <copyin+0x28>
    80001760:	84ce                	mv	s1,s3
    80001762:	bf7d                	j	80001720 <copyin+0x28>
  }
  return 0;
    80001764:	4501                	li	a0,0
    80001766:	a021                	j	8000176e <copyin+0x76>
    80001768:	4501                	li	a0,0
}
    8000176a:	8082                	ret
      return -1;
    8000176c:	557d                	li	a0,-1
}
    8000176e:	60a6                	ld	ra,72(sp)
    80001770:	6406                	ld	s0,64(sp)
    80001772:	74e2                	ld	s1,56(sp)
    80001774:	7942                	ld	s2,48(sp)
    80001776:	79a2                	ld	s3,40(sp)
    80001778:	7a02                	ld	s4,32(sp)
    8000177a:	6ae2                	ld	s5,24(sp)
    8000177c:	6b42                	ld	s6,16(sp)
    8000177e:	6ba2                	ld	s7,8(sp)
    80001780:	6c02                	ld	s8,0(sp)
    80001782:	6161                	addi	sp,sp,80
    80001784:	8082                	ret

0000000080001786 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001786:	c2dd                	beqz	a3,8000182c <copyinstr+0xa6>
{
    80001788:	715d                	addi	sp,sp,-80
    8000178a:	e486                	sd	ra,72(sp)
    8000178c:	e0a2                	sd	s0,64(sp)
    8000178e:	fc26                	sd	s1,56(sp)
    80001790:	f84a                	sd	s2,48(sp)
    80001792:	f44e                	sd	s3,40(sp)
    80001794:	f052                	sd	s4,32(sp)
    80001796:	ec56                	sd	s5,24(sp)
    80001798:	e85a                	sd	s6,16(sp)
    8000179a:	e45e                	sd	s7,8(sp)
    8000179c:	0880                	addi	s0,sp,80
    8000179e:	8a2a                	mv	s4,a0
    800017a0:	8b2e                	mv	s6,a1
    800017a2:	8bb2                	mv	s7,a2
    800017a4:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a6:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a8:	6985                	lui	s3,0x1
    800017aa:	a02d                	j	800017d4 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017ac:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b0:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b2:	37fd                	addiw	a5,a5,-1
    800017b4:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b8:	60a6                	ld	ra,72(sp)
    800017ba:	6406                	ld	s0,64(sp)
    800017bc:	74e2                	ld	s1,56(sp)
    800017be:	7942                	ld	s2,48(sp)
    800017c0:	79a2                	ld	s3,40(sp)
    800017c2:	7a02                	ld	s4,32(sp)
    800017c4:	6ae2                	ld	s5,24(sp)
    800017c6:	6b42                	ld	s6,16(sp)
    800017c8:	6ba2                	ld	s7,8(sp)
    800017ca:	6161                	addi	sp,sp,80
    800017cc:	8082                	ret
    srcva = va0 + PGSIZE;
    800017ce:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d2:	c8a9                	beqz	s1,80001824 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017d4:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d8:	85ca                	mv	a1,s2
    800017da:	8552                	mv	a0,s4
    800017dc:	00000097          	auipc	ra,0x0
    800017e0:	880080e7          	jalr	-1920(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800017e4:	c131                	beqz	a0,80001828 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017e6:	417906b3          	sub	a3,s2,s7
    800017ea:	96ce                	add	a3,a3,s3
    800017ec:	00d4f363          	bgeu	s1,a3,800017f2 <copyinstr+0x6c>
    800017f0:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f2:	955e                	add	a0,a0,s7
    800017f4:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f8:	daf9                	beqz	a3,800017ce <copyinstr+0x48>
    800017fa:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017fc:	41650633          	sub	a2,a0,s6
    80001800:	fff48593          	addi	a1,s1,-1
    80001804:	95da                	add	a1,a1,s6
    while(n > 0){
    80001806:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001808:	00f60733          	add	a4,a2,a5
    8000180c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdcf20>
    80001810:	df51                	beqz	a4,800017ac <copyinstr+0x26>
        *dst = *p;
    80001812:	00e78023          	sb	a4,0(a5)
      --max;
    80001816:	40f584b3          	sub	s1,a1,a5
      dst++;
    8000181a:	0785                	addi	a5,a5,1
    while(n > 0){
    8000181c:	fed796e3          	bne	a5,a3,80001808 <copyinstr+0x82>
      dst++;
    80001820:	8b3e                	mv	s6,a5
    80001822:	b775                	j	800017ce <copyinstr+0x48>
    80001824:	4781                	li	a5,0
    80001826:	b771                	j	800017b2 <copyinstr+0x2c>
      return -1;
    80001828:	557d                	li	a0,-1
    8000182a:	b779                	j	800017b8 <copyinstr+0x32>
  int got_null = 0;
    8000182c:	4781                	li	a5,0
  if(got_null){
    8000182e:	37fd                	addiw	a5,a5,-1
    80001830:	0007851b          	sext.w	a0,a5
}
    80001834:	8082                	ret

0000000080001836 <rr_scheduler>:
        (*sched_pointer)();
    }
}

void rr_scheduler(void)
{
    80001836:	7139                	addi	sp,sp,-64
    80001838:	fc06                	sd	ra,56(sp)
    8000183a:	f822                	sd	s0,48(sp)
    8000183c:	f426                	sd	s1,40(sp)
    8000183e:	f04a                	sd	s2,32(sp)
    80001840:	ec4e                	sd	s3,24(sp)
    80001842:	e852                	sd	s4,16(sp)
    80001844:	e456                	sd	s5,8(sp)
    80001846:	e05a                	sd	s6,0(sp)
    80001848:	0080                	addi	s0,sp,64
  asm volatile("mv %0, tp" : "=r" (x) );
    8000184a:	8712                	mv	a4,tp
    int id = r_tp();
    8000184c:	2701                	sext.w	a4,a4
    struct proc *p;
    struct cpu *c = mycpu();

    c->proc = 0;
    8000184e:	0000fa97          	auipc	s5,0xf
    80001852:	442a8a93          	addi	s5,s5,1090 # 80010c90 <cpus>
    80001856:	00471793          	slli	a5,a4,0x4
    8000185a:	00e786b3          	add	a3,a5,a4
    8000185e:	068e                	slli	a3,a3,0x3
    80001860:	96d6                	add	a3,a3,s5
    80001862:	0006b023          	sd	zero,0(a3) # fffffffffffff000 <end+0xffffffff7ffdcf20>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001866:	100026f3          	csrr	a3,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000186a:	0026e693          	ori	a3,a3,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000186e:	10069073          	csrw	sstatus,a3
            // Switch to chosen process.  It is the process's job
            // to release its lock and then reacquire it
            // before jumping back to us.
            p->state = RUNNING;
            c->proc = p;
            swtch(&c->context, &p->context);
    80001872:	97ba                	add	a5,a5,a4
    80001874:	078e                	slli	a5,a5,0x3
    80001876:	07a1                	addi	a5,a5,8
    80001878:	9abe                	add	s5,s5,a5
    for (p = proc; p < &proc[NPROC]; p++)
    8000187a:	00010497          	auipc	s1,0x10
    8000187e:	88648493          	addi	s1,s1,-1914 # 80011100 <proc>
        if (p->state == RUNNABLE)
    80001882:	498d                	li	s3,3
            p->state = RUNNING;
    80001884:	4b11                	li	s6,4
            c->proc = p;
    80001886:	00471793          	slli	a5,a4,0x4
    8000188a:	97ba                	add	a5,a5,a4
    8000188c:	078e                	slli	a5,a5,0x3
    8000188e:	0000fa17          	auipc	s4,0xf
    80001892:	402a0a13          	addi	s4,s4,1026 # 80010c90 <cpus>
    80001896:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80001898:	00015917          	auipc	s2,0x15
    8000189c:	46890913          	addi	s2,s2,1128 # 80016d00 <tickslock>
    800018a0:	a811                	j	800018b4 <rr_scheduler+0x7e>

            // Process is done running for now.
            // It should have changed its p->state before coming back.
            c->proc = 0;
        }
        release(&p->lock);
    800018a2:	8526                	mv	a0,s1
    800018a4:	fffff097          	auipc	ra,0xfffff
    800018a8:	3e6080e7          	jalr	998(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    800018ac:	17048493          	addi	s1,s1,368
    800018b0:	03248863          	beq	s1,s2,800018e0 <rr_scheduler+0xaa>
        acquire(&p->lock);
    800018b4:	8526                	mv	a0,s1
    800018b6:	fffff097          	auipc	ra,0xfffff
    800018ba:	320080e7          	jalr	800(ra) # 80000bd6 <acquire>
        if (p->state == RUNNABLE)
    800018be:	4c9c                	lw	a5,24(s1)
    800018c0:	ff3791e3          	bne	a5,s3,800018a2 <rr_scheduler+0x6c>
            p->state = RUNNING;
    800018c4:	0164ac23          	sw	s6,24(s1)
            c->proc = p;
    800018c8:	009a3023          	sd	s1,0(s4)
            swtch(&c->context, &p->context);
    800018cc:	06848593          	addi	a1,s1,104
    800018d0:	8556                	mv	a0,s5
    800018d2:	00001097          	auipc	ra,0x1
    800018d6:	1f2080e7          	jalr	498(ra) # 80002ac4 <swtch>
            c->proc = 0;
    800018da:	000a3023          	sd	zero,0(s4)
    800018de:	b7d1                	j	800018a2 <rr_scheduler+0x6c>
    }
    // In case a setsched happened, we will switch to the new scheduler after one
    // Round Robin round has completed.
}
    800018e0:	70e2                	ld	ra,56(sp)
    800018e2:	7442                	ld	s0,48(sp)
    800018e4:	74a2                	ld	s1,40(sp)
    800018e6:	7902                	ld	s2,32(sp)
    800018e8:	69e2                	ld	s3,24(sp)
    800018ea:	6a42                	ld	s4,16(sp)
    800018ec:	6aa2                	ld	s5,8(sp)
    800018ee:	6b02                	ld	s6,0(sp)
    800018f0:	6121                	addi	sp,sp,64
    800018f2:	8082                	ret

00000000800018f4 <mlfq_scheduler>:

void mlfq_scheduler(void)
{
    800018f4:	711d                	addi	sp,sp,-96
    800018f6:	ec86                	sd	ra,88(sp)
    800018f8:	e8a2                	sd	s0,80(sp)
    800018fa:	e4a6                	sd	s1,72(sp)
    800018fc:	e0ca                	sd	s2,64(sp)
    800018fe:	fc4e                	sd	s3,56(sp)
    80001900:	f852                	sd	s4,48(sp)
    80001902:	f456                	sd	s5,40(sp)
    80001904:	f05a                	sd	s6,32(sp)
    80001906:	ec5e                	sd	s7,24(sp)
    80001908:	e862                	sd	s8,16(sp)
    8000190a:	e466                	sd	s9,8(sp)
    8000190c:	e06a                	sd	s10,0(sp)
    8000190e:	1080                	addi	s0,sp,96
  asm volatile("mv %0, tp" : "=r" (x) );
    80001910:	8c92                	mv	s9,tp
    int id = r_tp();
    80001912:	2c81                	sext.w	s9,s9
    struct proc *p;
    struct cpu *c = mycpu();
    int period = 1000;

    c->proc = 0;
    80001914:	004c9793          	slli	a5,s9,0x4
    80001918:	97e6                	add	a5,a5,s9
    8000191a:	078e                	slli	a5,a5,0x3
    8000191c:	0000f717          	auipc	a4,0xf
    80001920:	37470713          	addi	a4,a4,884 # 80010c90 <cpus>
    80001924:	97ba                	add	a5,a5,a4
    80001926:	0007b023          	sd	zero,0(a5)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000192a:	10002773          	csrr	a4,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000192e:	00276713          	ori	a4,a4,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001932:	10071073          	csrw	sstatus,a4
    // Avoid deadlock by ensuring that devices can interrupt.
    intr_on();

    if (c->time >= period) {
    80001936:	0807a703          	lw	a4,128(a5)
    8000193a:	3e700793          	li	a5,999
    8000193e:	02e7db63          	bge	a5,a4,80001974 <mlfq_scheduler+0x80>
        c->time = 0;
    80001942:	004c9793          	slli	a5,s9,0x4
    80001946:	97e6                	add	a5,a5,s9
    80001948:	078e                	slli	a5,a5,0x3
    8000194a:	0000f717          	auipc	a4,0xf
    8000194e:	34670713          	addi	a4,a4,838 # 80010c90 <cpus>
    80001952:	97ba                	add	a5,a5,a4
    80001954:	0807a023          	sw	zero,128(a5)
        for (p = proc; p < &proc[NPROC]; p++)
    80001958:	0000f797          	auipc	a5,0xf
    8000195c:	7a878793          	addi	a5,a5,1960 # 80011100 <proc>
    80001960:	00015717          	auipc	a4,0x15
    80001964:	3a070713          	addi	a4,a4,928 # 80016d00 <tickslock>
        {
            p->priority = 0;
    80001968:	0207aa23          	sw	zero,52(a5)
        for (p = proc; p < &proc[NPROC]; p++)
    8000196c:	17078793          	addi	a5,a5,368
    80001970:	fee79ce3          	bne	a5,a4,80001968 <mlfq_scheduler+0x74>
                // Switch to chosen process.  It is the process's job
                // to release its lock and then reacquire it
                // before jumping back to us.
                p->state = RUNNING;
                c->proc = p;
                swtch(&c->context, &p->context);
    80001974:	004c9c13          	slli	s8,s9,0x4
    80001978:	9c66                	add	s8,s8,s9
    8000197a:	0c0e                	slli	s8,s8,0x3
    8000197c:	0000f797          	auipc	a5,0xf
    80001980:	31c78793          	addi	a5,a5,796 # 80010c98 <cpus+0x8>
    80001984:	9c3e                	add	s8,s8,a5
            c->time++;
    80001986:	004c9793          	slli	a5,s9,0x4
    8000198a:	97e6                	add	a5,a5,s9
    8000198c:	078e                	slli	a5,a5,0x3
    8000198e:	0000f917          	auipc	s2,0xf
    80001992:	30290913          	addi	s2,s2,770 # 80010c90 <cpus>
    80001996:	993e                	add	s2,s2,a5
                find_high = 1;
    80001998:	4b05                	li	s6,1
        for (p = proc; p < &proc[NPROC]; p++)
    8000199a:	00015a17          	auipc	s4,0x15
    8000199e:	366a0a13          	addi	s4,s4,870 # 80016d00 <tickslock>
    800019a2:	a891                	j	800019f6 <mlfq_scheduler+0x102>

                // Process is done running for now.
                // It should have changed its p->state before coming back.
                c->proc = 0;
            }
            release(&p->lock);
    800019a4:	8526                	mv	a0,s1
    800019a6:	fffff097          	auipc	ra,0xfffff
    800019aa:	2e4080e7          	jalr	740(ra) # 80000c8a <release>
        for (p = proc; p < &proc[NPROC]; p++)
    800019ae:	17048493          	addi	s1,s1,368
    800019b2:	05448063          	beq	s1,s4,800019f2 <mlfq_scheduler+0xfe>
            c->time++;
    800019b6:	08092783          	lw	a5,128(s2)
    800019ba:	2785                	addiw	a5,a5,1
    800019bc:	08f92023          	sw	a5,128(s2)
            acquire(&p->lock);
    800019c0:	8526                	mv	a0,s1
    800019c2:	fffff097          	auipc	ra,0xfffff
    800019c6:	214080e7          	jalr	532(ra) # 80000bd6 <acquire>
            if (p->state == RUNNABLE && p->priority == 0)
    800019ca:	4c9c                	lw	a5,24(s1)
    800019cc:	fd379ce3          	bne	a5,s3,800019a4 <mlfq_scheduler+0xb0>
    800019d0:	58dc                	lw	a5,52(s1)
    800019d2:	fbe9                	bnez	a5,800019a4 <mlfq_scheduler+0xb0>
                p->state = RUNNING;
    800019d4:	0174ac23          	sw	s7,24(s1)
                c->proc = p;
    800019d8:	00993023          	sd	s1,0(s2)
                swtch(&c->context, &p->context);
    800019dc:	06848593          	addi	a1,s1,104
    800019e0:	8562                	mv	a0,s8
    800019e2:	00001097          	auipc	ra,0x1
    800019e6:	0e2080e7          	jalr	226(ra) # 80002ac4 <swtch>
                c->proc = 0;
    800019ea:	00093023          	sd	zero,0(s2)
                find_high = 1;
    800019ee:	8ada                	mv	s5,s6
    800019f0:	bf55                	j	800019a4 <mlfq_scheduler+0xb0>
    while (find_high == 1)
    800019f2:	016a9a63          	bne	s5,s6,80001a06 <mlfq_scheduler+0x112>
        find_high = 0;
    800019f6:	4a81                	li	s5,0
        for (p = proc; p < &proc[NPROC]; p++)
    800019f8:	0000f497          	auipc	s1,0xf
    800019fc:	70848493          	addi	s1,s1,1800 # 80011100 <proc>
            if (p->state == RUNNABLE && p->priority == 0)
    80001a00:	498d                	li	s3,3
                p->state = RUNNING;
    80001a02:	4b91                	li	s7,4
    80001a04:	bf4d                	j	800019b6 <mlfq_scheduler+0xc2>
        }
    }
    
    for (p = proc; p < &proc[NPROC]; p++)
    80001a06:	0000f497          	auipc	s1,0xf
    80001a0a:	6fa48493          	addi	s1,s1,1786 # 80011100 <proc>
    {
        c->time++;
    80001a0e:	004c9793          	slli	a5,s9,0x4
    80001a12:	97e6                	add	a5,a5,s9
    80001a14:	078e                	slli	a5,a5,0x3
    80001a16:	0000f917          	auipc	s2,0xf
    80001a1a:	27a90913          	addi	s2,s2,634 # 80010c90 <cpus>
    80001a1e:	993e                	add	s2,s2,a5
        if (p->priority == 0) {
            release(&p->lock);
            break;
        }

        if (p->state == RUNNABLE)
    80001a20:	4a8d                	li	s5,3
        {
            // Switch to chosen process.  It is the process's job
            // to release its lock and then reacquire it
            // before jumping back to us.
            p->state = RUNNING;
    80001a22:	4b11                	li	s6,4
    for (p = proc; p < &proc[NPROC]; p++)
    80001a24:	00015a17          	auipc	s4,0x15
    80001a28:	2dca0a13          	addi	s4,s4,732 # 80016d00 <tickslock>
    80001a2c:	a82d                	j	80001a66 <mlfq_scheduler+0x172>
            release(&p->lock);
    80001a2e:	8526                	mv	a0,s1
    80001a30:	fffff097          	auipc	ra,0xfffff
    80001a34:	25a080e7          	jalr	602(ra) # 80000c8a <release>
        }
        release(&p->lock);
    }
    // In case a setsched happened, we will switch to the new scheduler after one
    // Round Robin round has completed.
}
    80001a38:	60e6                	ld	ra,88(sp)
    80001a3a:	6446                	ld	s0,80(sp)
    80001a3c:	64a6                	ld	s1,72(sp)
    80001a3e:	6906                	ld	s2,64(sp)
    80001a40:	79e2                	ld	s3,56(sp)
    80001a42:	7a42                	ld	s4,48(sp)
    80001a44:	7aa2                	ld	s5,40(sp)
    80001a46:	7b02                	ld	s6,32(sp)
    80001a48:	6be2                	ld	s7,24(sp)
    80001a4a:	6c42                	ld	s8,16(sp)
    80001a4c:	6ca2                	ld	s9,8(sp)
    80001a4e:	6d02                	ld	s10,0(sp)
    80001a50:	6125                	addi	sp,sp,96
    80001a52:	8082                	ret
        release(&p->lock);
    80001a54:	8526                	mv	a0,s1
    80001a56:	fffff097          	auipc	ra,0xfffff
    80001a5a:	234080e7          	jalr	564(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001a5e:	17048493          	addi	s1,s1,368
    80001a62:	fd448be3          	beq	s1,s4,80001a38 <mlfq_scheduler+0x144>
        c->time++;
    80001a66:	08092783          	lw	a5,128(s2)
    80001a6a:	2785                	addiw	a5,a5,1
    80001a6c:	08f92023          	sw	a5,128(s2)
        acquire(&p->lock);
    80001a70:	8526                	mv	a0,s1
    80001a72:	fffff097          	auipc	ra,0xfffff
    80001a76:	164080e7          	jalr	356(ra) # 80000bd6 <acquire>
        if (p->priority == 0) {
    80001a7a:	58dc                	lw	a5,52(s1)
    80001a7c:	dbcd                	beqz	a5,80001a2e <mlfq_scheduler+0x13a>
        if (p->state == RUNNABLE)
    80001a7e:	4c9c                	lw	a5,24(s1)
    80001a80:	fd579ae3          	bne	a5,s5,80001a54 <mlfq_scheduler+0x160>
            p->state = RUNNING;
    80001a84:	0164ac23          	sw	s6,24(s1)
            c->proc = p;
    80001a88:	00993023          	sd	s1,0(s2)
            swtch(&c->context, &p->context);
    80001a8c:	06848593          	addi	a1,s1,104
    80001a90:	8562                	mv	a0,s8
    80001a92:	00001097          	auipc	ra,0x1
    80001a96:	032080e7          	jalr	50(ra) # 80002ac4 <swtch>
            c->proc = 0;
    80001a9a:	00093023          	sd	zero,0(s2)
    80001a9e:	bf5d                	j	80001a54 <mlfq_scheduler+0x160>

0000000080001aa0 <proc_mapstacks>:
{
    80001aa0:	7139                	addi	sp,sp,-64
    80001aa2:	fc06                	sd	ra,56(sp)
    80001aa4:	f822                	sd	s0,48(sp)
    80001aa6:	f426                	sd	s1,40(sp)
    80001aa8:	f04a                	sd	s2,32(sp)
    80001aaa:	ec4e                	sd	s3,24(sp)
    80001aac:	e852                	sd	s4,16(sp)
    80001aae:	e456                	sd	s5,8(sp)
    80001ab0:	e05a                	sd	s6,0(sp)
    80001ab2:	0080                	addi	s0,sp,64
    80001ab4:	89aa                	mv	s3,a0
    for (p = proc; p < &proc[NPROC]; p++)
    80001ab6:	0000f497          	auipc	s1,0xf
    80001aba:	64a48493          	addi	s1,s1,1610 # 80011100 <proc>
        uint64 va = KSTACK((int)(p - proc));
    80001abe:	8b26                	mv	s6,s1
    80001ac0:	00006a97          	auipc	s5,0x6
    80001ac4:	540a8a93          	addi	s5,s5,1344 # 80008000 <etext>
    80001ac8:	04000937          	lui	s2,0x4000
    80001acc:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001ace:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001ad0:	00015a17          	auipc	s4,0x15
    80001ad4:	230a0a13          	addi	s4,s4,560 # 80016d00 <tickslock>
        char *pa = kalloc();
    80001ad8:	fffff097          	auipc	ra,0xfffff
    80001adc:	00e080e7          	jalr	14(ra) # 80000ae6 <kalloc>
    80001ae0:	862a                	mv	a2,a0
        if (pa == 0)
    80001ae2:	c131                	beqz	a0,80001b26 <proc_mapstacks+0x86>
        uint64 va = KSTACK((int)(p - proc));
    80001ae4:	416485b3          	sub	a1,s1,s6
    80001ae8:	8591                	srai	a1,a1,0x4
    80001aea:	000ab783          	ld	a5,0(s5)
    80001aee:	02f585b3          	mul	a1,a1,a5
    80001af2:	2585                	addiw	a1,a1,1
    80001af4:	00d5959b          	slliw	a1,a1,0xd
        kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001af8:	4719                	li	a4,6
    80001afa:	6685                	lui	a3,0x1
    80001afc:	40b905b3          	sub	a1,s2,a1
    80001b00:	854e                	mv	a0,s3
    80001b02:	fffff097          	auipc	ra,0xfffff
    80001b06:	63c080e7          	jalr	1596(ra) # 8000113e <kvmmap>
    for (p = proc; p < &proc[NPROC]; p++)
    80001b0a:	17048493          	addi	s1,s1,368
    80001b0e:	fd4495e3          	bne	s1,s4,80001ad8 <proc_mapstacks+0x38>
}
    80001b12:	70e2                	ld	ra,56(sp)
    80001b14:	7442                	ld	s0,48(sp)
    80001b16:	74a2                	ld	s1,40(sp)
    80001b18:	7902                	ld	s2,32(sp)
    80001b1a:	69e2                	ld	s3,24(sp)
    80001b1c:	6a42                	ld	s4,16(sp)
    80001b1e:	6aa2                	ld	s5,8(sp)
    80001b20:	6b02                	ld	s6,0(sp)
    80001b22:	6121                	addi	sp,sp,64
    80001b24:	8082                	ret
            panic("kalloc");
    80001b26:	00006517          	auipc	a0,0x6
    80001b2a:	6b250513          	addi	a0,a0,1714 # 800081d8 <digits+0x198>
    80001b2e:	fffff097          	auipc	ra,0xfffff
    80001b32:	a12080e7          	jalr	-1518(ra) # 80000540 <panic>

0000000080001b36 <procinit>:
{
    80001b36:	7139                	addi	sp,sp,-64
    80001b38:	fc06                	sd	ra,56(sp)
    80001b3a:	f822                	sd	s0,48(sp)
    80001b3c:	f426                	sd	s1,40(sp)
    80001b3e:	f04a                	sd	s2,32(sp)
    80001b40:	ec4e                	sd	s3,24(sp)
    80001b42:	e852                	sd	s4,16(sp)
    80001b44:	e456                	sd	s5,8(sp)
    80001b46:	e05a                	sd	s6,0(sp)
    80001b48:	0080                	addi	s0,sp,64
    initlock(&pid_lock, "nextpid");
    80001b4a:	00006597          	auipc	a1,0x6
    80001b4e:	69658593          	addi	a1,a1,1686 # 800081e0 <digits+0x1a0>
    80001b52:	0000f517          	auipc	a0,0xf
    80001b56:	57e50513          	addi	a0,a0,1406 # 800110d0 <pid_lock>
    80001b5a:	fffff097          	auipc	ra,0xfffff
    80001b5e:	fec080e7          	jalr	-20(ra) # 80000b46 <initlock>
    initlock(&wait_lock, "wait_lock");
    80001b62:	00006597          	auipc	a1,0x6
    80001b66:	68658593          	addi	a1,a1,1670 # 800081e8 <digits+0x1a8>
    80001b6a:	0000f517          	auipc	a0,0xf
    80001b6e:	57e50513          	addi	a0,a0,1406 # 800110e8 <wait_lock>
    80001b72:	fffff097          	auipc	ra,0xfffff
    80001b76:	fd4080e7          	jalr	-44(ra) # 80000b46 <initlock>
    for (p = proc; p < &proc[NPROC]; p++)
    80001b7a:	0000f497          	auipc	s1,0xf
    80001b7e:	58648493          	addi	s1,s1,1414 # 80011100 <proc>
        initlock(&p->lock, "proc");
    80001b82:	00006b17          	auipc	s6,0x6
    80001b86:	676b0b13          	addi	s6,s6,1654 # 800081f8 <digits+0x1b8>
        p->kstack = KSTACK((int)(p - proc));
    80001b8a:	8aa6                	mv	s5,s1
    80001b8c:	00006a17          	auipc	s4,0x6
    80001b90:	474a0a13          	addi	s4,s4,1140 # 80008000 <etext>
    80001b94:	04000937          	lui	s2,0x4000
    80001b98:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001b9a:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001b9c:	00015997          	auipc	s3,0x15
    80001ba0:	16498993          	addi	s3,s3,356 # 80016d00 <tickslock>
        initlock(&p->lock, "proc");
    80001ba4:	85da                	mv	a1,s6
    80001ba6:	8526                	mv	a0,s1
    80001ba8:	fffff097          	auipc	ra,0xfffff
    80001bac:	f9e080e7          	jalr	-98(ra) # 80000b46 <initlock>
        p->state = UNUSED;
    80001bb0:	0004ac23          	sw	zero,24(s1)
        p->kstack = KSTACK((int)(p - proc));
    80001bb4:	415487b3          	sub	a5,s1,s5
    80001bb8:	8791                	srai	a5,a5,0x4
    80001bba:	000a3703          	ld	a4,0(s4)
    80001bbe:	02e787b3          	mul	a5,a5,a4
    80001bc2:	2785                	addiw	a5,a5,1
    80001bc4:	00d7979b          	slliw	a5,a5,0xd
    80001bc8:	40f907b3          	sub	a5,s2,a5
    80001bcc:	e4bc                	sd	a5,72(s1)
    for (p = proc; p < &proc[NPROC]; p++)
    80001bce:	17048493          	addi	s1,s1,368
    80001bd2:	fd3499e3          	bne	s1,s3,80001ba4 <procinit+0x6e>
}
    80001bd6:	70e2                	ld	ra,56(sp)
    80001bd8:	7442                	ld	s0,48(sp)
    80001bda:	74a2                	ld	s1,40(sp)
    80001bdc:	7902                	ld	s2,32(sp)
    80001bde:	69e2                	ld	s3,24(sp)
    80001be0:	6a42                	ld	s4,16(sp)
    80001be2:	6aa2                	ld	s5,8(sp)
    80001be4:	6b02                	ld	s6,0(sp)
    80001be6:	6121                	addi	sp,sp,64
    80001be8:	8082                	ret

0000000080001bea <copy_array>:
{
    80001bea:	1141                	addi	sp,sp,-16
    80001bec:	e422                	sd	s0,8(sp)
    80001bee:	0800                	addi	s0,sp,16
    for (int i = 0; i < len; i++)
    80001bf0:	02c05163          	blez	a2,80001c12 <copy_array+0x28>
    80001bf4:	87aa                	mv	a5,a0
    80001bf6:	0505                	addi	a0,a0,1
    80001bf8:	367d                	addiw	a2,a2,-1 # fff <_entry-0x7ffff001>
    80001bfa:	1602                	slli	a2,a2,0x20
    80001bfc:	9201                	srli	a2,a2,0x20
    80001bfe:	00c506b3          	add	a3,a0,a2
        dst[i] = src[i];
    80001c02:	0007c703          	lbu	a4,0(a5)
    80001c06:	00e58023          	sb	a4,0(a1)
    for (int i = 0; i < len; i++)
    80001c0a:	0785                	addi	a5,a5,1
    80001c0c:	0585                	addi	a1,a1,1
    80001c0e:	fed79ae3          	bne	a5,a3,80001c02 <copy_array+0x18>
}
    80001c12:	6422                	ld	s0,8(sp)
    80001c14:	0141                	addi	sp,sp,16
    80001c16:	8082                	ret

0000000080001c18 <cpuid>:
{
    80001c18:	1141                	addi	sp,sp,-16
    80001c1a:	e422                	sd	s0,8(sp)
    80001c1c:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001c1e:	8512                	mv	a0,tp
}
    80001c20:	2501                	sext.w	a0,a0
    80001c22:	6422                	ld	s0,8(sp)
    80001c24:	0141                	addi	sp,sp,16
    80001c26:	8082                	ret

0000000080001c28 <mycpu>:
{
    80001c28:	1141                	addi	sp,sp,-16
    80001c2a:	e422                	sd	s0,8(sp)
    80001c2c:	0800                	addi	s0,sp,16
    80001c2e:	8712                	mv	a4,tp
    struct cpu *c = &cpus[id];
    80001c30:	2701                	sext.w	a4,a4
    80001c32:	00471793          	slli	a5,a4,0x4
    80001c36:	97ba                	add	a5,a5,a4
    80001c38:	078e                	slli	a5,a5,0x3
}
    80001c3a:	0000f517          	auipc	a0,0xf
    80001c3e:	05650513          	addi	a0,a0,86 # 80010c90 <cpus>
    80001c42:	953e                	add	a0,a0,a5
    80001c44:	6422                	ld	s0,8(sp)
    80001c46:	0141                	addi	sp,sp,16
    80001c48:	8082                	ret

0000000080001c4a <myproc>:
{
    80001c4a:	1101                	addi	sp,sp,-32
    80001c4c:	ec06                	sd	ra,24(sp)
    80001c4e:	e822                	sd	s0,16(sp)
    80001c50:	e426                	sd	s1,8(sp)
    80001c52:	1000                	addi	s0,sp,32
    push_off();
    80001c54:	fffff097          	auipc	ra,0xfffff
    80001c58:	f36080e7          	jalr	-202(ra) # 80000b8a <push_off>
    80001c5c:	8712                	mv	a4,tp
    struct proc *p = c->proc;
    80001c5e:	2701                	sext.w	a4,a4
    80001c60:	00471793          	slli	a5,a4,0x4
    80001c64:	97ba                	add	a5,a5,a4
    80001c66:	078e                	slli	a5,a5,0x3
    80001c68:	0000f717          	auipc	a4,0xf
    80001c6c:	02870713          	addi	a4,a4,40 # 80010c90 <cpus>
    80001c70:	97ba                	add	a5,a5,a4
    80001c72:	6384                	ld	s1,0(a5)
    pop_off();
    80001c74:	fffff097          	auipc	ra,0xfffff
    80001c78:	fb6080e7          	jalr	-74(ra) # 80000c2a <pop_off>
}
    80001c7c:	8526                	mv	a0,s1
    80001c7e:	60e2                	ld	ra,24(sp)
    80001c80:	6442                	ld	s0,16(sp)
    80001c82:	64a2                	ld	s1,8(sp)
    80001c84:	6105                	addi	sp,sp,32
    80001c86:	8082                	ret

0000000080001c88 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001c88:	1141                	addi	sp,sp,-16
    80001c8a:	e406                	sd	ra,8(sp)
    80001c8c:	e022                	sd	s0,0(sp)
    80001c8e:	0800                	addi	s0,sp,16
    static int first = 1;

    // Still holding p->lock from scheduler.
    release(&myproc()->lock);
    80001c90:	00000097          	auipc	ra,0x0
    80001c94:	fba080e7          	jalr	-70(ra) # 80001c4a <myproc>
    80001c98:	fffff097          	auipc	ra,0xfffff
    80001c9c:	ff2080e7          	jalr	-14(ra) # 80000c8a <release>

    if (first)
    80001ca0:	00007797          	auipc	a5,0x7
    80001ca4:	c907a783          	lw	a5,-880(a5) # 80008930 <first.1>
    80001ca8:	eb89                	bnez	a5,80001cba <forkret+0x32>
        // be run from main().
        first = 0;
        fsinit(ROOTDEV);
    }

    usertrapret();
    80001caa:	00001097          	auipc	ra,0x1
    80001cae:	ec4080e7          	jalr	-316(ra) # 80002b6e <usertrapret>
}
    80001cb2:	60a2                	ld	ra,8(sp)
    80001cb4:	6402                	ld	s0,0(sp)
    80001cb6:	0141                	addi	sp,sp,16
    80001cb8:	8082                	ret
        first = 0;
    80001cba:	00007797          	auipc	a5,0x7
    80001cbe:	c607ab23          	sw	zero,-906(a5) # 80008930 <first.1>
        fsinit(ROOTDEV);
    80001cc2:	4505                	li	a0,1
    80001cc4:	00002097          	auipc	ra,0x2
    80001cc8:	caa080e7          	jalr	-854(ra) # 8000396e <fsinit>
    80001ccc:	bff9                	j	80001caa <forkret+0x22>

0000000080001cce <allocpid>:
{
    80001cce:	1101                	addi	sp,sp,-32
    80001cd0:	ec06                	sd	ra,24(sp)
    80001cd2:	e822                	sd	s0,16(sp)
    80001cd4:	e426                	sd	s1,8(sp)
    80001cd6:	e04a                	sd	s2,0(sp)
    80001cd8:	1000                	addi	s0,sp,32
    acquire(&pid_lock);
    80001cda:	0000f917          	auipc	s2,0xf
    80001cde:	3f690913          	addi	s2,s2,1014 # 800110d0 <pid_lock>
    80001ce2:	854a                	mv	a0,s2
    80001ce4:	fffff097          	auipc	ra,0xfffff
    80001ce8:	ef2080e7          	jalr	-270(ra) # 80000bd6 <acquire>
    pid = nextpid;
    80001cec:	00007797          	auipc	a5,0x7
    80001cf0:	c5478793          	addi	a5,a5,-940 # 80008940 <nextpid>
    80001cf4:	4384                	lw	s1,0(a5)
    nextpid = nextpid + 1;
    80001cf6:	0014871b          	addiw	a4,s1,1
    80001cfa:	c398                	sw	a4,0(a5)
    release(&pid_lock);
    80001cfc:	854a                	mv	a0,s2
    80001cfe:	fffff097          	auipc	ra,0xfffff
    80001d02:	f8c080e7          	jalr	-116(ra) # 80000c8a <release>
}
    80001d06:	8526                	mv	a0,s1
    80001d08:	60e2                	ld	ra,24(sp)
    80001d0a:	6442                	ld	s0,16(sp)
    80001d0c:	64a2                	ld	s1,8(sp)
    80001d0e:	6902                	ld	s2,0(sp)
    80001d10:	6105                	addi	sp,sp,32
    80001d12:	8082                	ret

0000000080001d14 <proc_pagetable>:
{
    80001d14:	1101                	addi	sp,sp,-32
    80001d16:	ec06                	sd	ra,24(sp)
    80001d18:	e822                	sd	s0,16(sp)
    80001d1a:	e426                	sd	s1,8(sp)
    80001d1c:	e04a                	sd	s2,0(sp)
    80001d1e:	1000                	addi	s0,sp,32
    80001d20:	892a                	mv	s2,a0
    pagetable = uvmcreate();
    80001d22:	fffff097          	auipc	ra,0xfffff
    80001d26:	606080e7          	jalr	1542(ra) # 80001328 <uvmcreate>
    80001d2a:	84aa                	mv	s1,a0
    if (pagetable == 0)
    80001d2c:	c121                	beqz	a0,80001d6c <proc_pagetable+0x58>
    if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001d2e:	4729                	li	a4,10
    80001d30:	00005697          	auipc	a3,0x5
    80001d34:	2d068693          	addi	a3,a3,720 # 80007000 <_trampoline>
    80001d38:	6605                	lui	a2,0x1
    80001d3a:	040005b7          	lui	a1,0x4000
    80001d3e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001d40:	05b2                	slli	a1,a1,0xc
    80001d42:	fffff097          	auipc	ra,0xfffff
    80001d46:	35c080e7          	jalr	860(ra) # 8000109e <mappages>
    80001d4a:	02054863          	bltz	a0,80001d7a <proc_pagetable+0x66>
    if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001d4e:	4719                	li	a4,6
    80001d50:	06093683          	ld	a3,96(s2)
    80001d54:	6605                	lui	a2,0x1
    80001d56:	020005b7          	lui	a1,0x2000
    80001d5a:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001d5c:	05b6                	slli	a1,a1,0xd
    80001d5e:	8526                	mv	a0,s1
    80001d60:	fffff097          	auipc	ra,0xfffff
    80001d64:	33e080e7          	jalr	830(ra) # 8000109e <mappages>
    80001d68:	02054163          	bltz	a0,80001d8a <proc_pagetable+0x76>
}
    80001d6c:	8526                	mv	a0,s1
    80001d6e:	60e2                	ld	ra,24(sp)
    80001d70:	6442                	ld	s0,16(sp)
    80001d72:	64a2                	ld	s1,8(sp)
    80001d74:	6902                	ld	s2,0(sp)
    80001d76:	6105                	addi	sp,sp,32
    80001d78:	8082                	ret
        uvmfree(pagetable, 0);
    80001d7a:	4581                	li	a1,0
    80001d7c:	8526                	mv	a0,s1
    80001d7e:	fffff097          	auipc	ra,0xfffff
    80001d82:	7b0080e7          	jalr	1968(ra) # 8000152e <uvmfree>
        return 0;
    80001d86:	4481                	li	s1,0
    80001d88:	b7d5                	j	80001d6c <proc_pagetable+0x58>
        uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d8a:	4681                	li	a3,0
    80001d8c:	4605                	li	a2,1
    80001d8e:	040005b7          	lui	a1,0x4000
    80001d92:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001d94:	05b2                	slli	a1,a1,0xc
    80001d96:	8526                	mv	a0,s1
    80001d98:	fffff097          	auipc	ra,0xfffff
    80001d9c:	4cc080e7          	jalr	1228(ra) # 80001264 <uvmunmap>
        uvmfree(pagetable, 0);
    80001da0:	4581                	li	a1,0
    80001da2:	8526                	mv	a0,s1
    80001da4:	fffff097          	auipc	ra,0xfffff
    80001da8:	78a080e7          	jalr	1930(ra) # 8000152e <uvmfree>
        return 0;
    80001dac:	4481                	li	s1,0
    80001dae:	bf7d                	j	80001d6c <proc_pagetable+0x58>

0000000080001db0 <proc_freepagetable>:
{
    80001db0:	1101                	addi	sp,sp,-32
    80001db2:	ec06                	sd	ra,24(sp)
    80001db4:	e822                	sd	s0,16(sp)
    80001db6:	e426                	sd	s1,8(sp)
    80001db8:	e04a                	sd	s2,0(sp)
    80001dba:	1000                	addi	s0,sp,32
    80001dbc:	84aa                	mv	s1,a0
    80001dbe:	892e                	mv	s2,a1
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001dc0:	4681                	li	a3,0
    80001dc2:	4605                	li	a2,1
    80001dc4:	040005b7          	lui	a1,0x4000
    80001dc8:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001dca:	05b2                	slli	a1,a1,0xc
    80001dcc:	fffff097          	auipc	ra,0xfffff
    80001dd0:	498080e7          	jalr	1176(ra) # 80001264 <uvmunmap>
    uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001dd4:	4681                	li	a3,0
    80001dd6:	4605                	li	a2,1
    80001dd8:	020005b7          	lui	a1,0x2000
    80001ddc:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001dde:	05b6                	slli	a1,a1,0xd
    80001de0:	8526                	mv	a0,s1
    80001de2:	fffff097          	auipc	ra,0xfffff
    80001de6:	482080e7          	jalr	1154(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, sz);
    80001dea:	85ca                	mv	a1,s2
    80001dec:	8526                	mv	a0,s1
    80001dee:	fffff097          	auipc	ra,0xfffff
    80001df2:	740080e7          	jalr	1856(ra) # 8000152e <uvmfree>
}
    80001df6:	60e2                	ld	ra,24(sp)
    80001df8:	6442                	ld	s0,16(sp)
    80001dfa:	64a2                	ld	s1,8(sp)
    80001dfc:	6902                	ld	s2,0(sp)
    80001dfe:	6105                	addi	sp,sp,32
    80001e00:	8082                	ret

0000000080001e02 <freeproc>:
{
    80001e02:	1101                	addi	sp,sp,-32
    80001e04:	ec06                	sd	ra,24(sp)
    80001e06:	e822                	sd	s0,16(sp)
    80001e08:	e426                	sd	s1,8(sp)
    80001e0a:	1000                	addi	s0,sp,32
    80001e0c:	84aa                	mv	s1,a0
    if (p->trapframe)
    80001e0e:	7128                	ld	a0,96(a0)
    80001e10:	c509                	beqz	a0,80001e1a <freeproc+0x18>
        kfree((void *)p->trapframe);
    80001e12:	fffff097          	auipc	ra,0xfffff
    80001e16:	bd6080e7          	jalr	-1066(ra) # 800009e8 <kfree>
    p->trapframe = 0;
    80001e1a:	0604b023          	sd	zero,96(s1)
    if (p->pagetable)
    80001e1e:	6ca8                	ld	a0,88(s1)
    80001e20:	c511                	beqz	a0,80001e2c <freeproc+0x2a>
        proc_freepagetable(p->pagetable, p->sz);
    80001e22:	68ac                	ld	a1,80(s1)
    80001e24:	00000097          	auipc	ra,0x0
    80001e28:	f8c080e7          	jalr	-116(ra) # 80001db0 <proc_freepagetable>
    p->pagetable = 0;
    80001e2c:	0404bc23          	sd	zero,88(s1)
    p->sz = 0;
    80001e30:	0404b823          	sd	zero,80(s1)
    p->pid = 0;
    80001e34:	0204a823          	sw	zero,48(s1)
    p->parent = 0;
    80001e38:	0404b023          	sd	zero,64(s1)
    p->name[0] = 0;
    80001e3c:	16048023          	sb	zero,352(s1)
    p->chan = 0;
    80001e40:	0204b023          	sd	zero,32(s1)
    p->killed = 0;
    80001e44:	0204a423          	sw	zero,40(s1)
    p->xstate = 0;
    80001e48:	0204a623          	sw	zero,44(s1)
    p->state = UNUSED;
    80001e4c:	0004ac23          	sw	zero,24(s1)
}
    80001e50:	60e2                	ld	ra,24(sp)
    80001e52:	6442                	ld	s0,16(sp)
    80001e54:	64a2                	ld	s1,8(sp)
    80001e56:	6105                	addi	sp,sp,32
    80001e58:	8082                	ret

0000000080001e5a <allocproc>:
{
    80001e5a:	1101                	addi	sp,sp,-32
    80001e5c:	ec06                	sd	ra,24(sp)
    80001e5e:	e822                	sd	s0,16(sp)
    80001e60:	e426                	sd	s1,8(sp)
    80001e62:	e04a                	sd	s2,0(sp)
    80001e64:	1000                	addi	s0,sp,32
    for (p = proc; p < &proc[NPROC]; p++)
    80001e66:	0000f497          	auipc	s1,0xf
    80001e6a:	29a48493          	addi	s1,s1,666 # 80011100 <proc>
    80001e6e:	00015917          	auipc	s2,0x15
    80001e72:	e9290913          	addi	s2,s2,-366 # 80016d00 <tickslock>
        acquire(&p->lock);
    80001e76:	8526                	mv	a0,s1
    80001e78:	fffff097          	auipc	ra,0xfffff
    80001e7c:	d5e080e7          	jalr	-674(ra) # 80000bd6 <acquire>
        if (p->state == UNUSED)
    80001e80:	4c9c                	lw	a5,24(s1)
    80001e82:	cf81                	beqz	a5,80001e9a <allocproc+0x40>
            release(&p->lock);
    80001e84:	8526                	mv	a0,s1
    80001e86:	fffff097          	auipc	ra,0xfffff
    80001e8a:	e04080e7          	jalr	-508(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001e8e:	17048493          	addi	s1,s1,368
    80001e92:	ff2492e3          	bne	s1,s2,80001e76 <allocproc+0x1c>
    return 0;
    80001e96:	4481                	li	s1,0
    80001e98:	a899                	j	80001eee <allocproc+0x94>
    p->pid = allocpid();
    80001e9a:	00000097          	auipc	ra,0x0
    80001e9e:	e34080e7          	jalr	-460(ra) # 80001cce <allocpid>
    80001ea2:	d888                	sw	a0,48(s1)
    p->state = USED;
    80001ea4:	4785                	li	a5,1
    80001ea6:	cc9c                	sw	a5,24(s1)
    if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001ea8:	fffff097          	auipc	ra,0xfffff
    80001eac:	c3e080e7          	jalr	-962(ra) # 80000ae6 <kalloc>
    80001eb0:	892a                	mv	s2,a0
    80001eb2:	f0a8                	sd	a0,96(s1)
    80001eb4:	c521                	beqz	a0,80001efc <allocproc+0xa2>
    p->pagetable = proc_pagetable(p);
    80001eb6:	8526                	mv	a0,s1
    80001eb8:	00000097          	auipc	ra,0x0
    80001ebc:	e5c080e7          	jalr	-420(ra) # 80001d14 <proc_pagetable>
    80001ec0:	892a                	mv	s2,a0
    80001ec2:	eca8                	sd	a0,88(s1)
    if (p->pagetable == 0)
    80001ec4:	c921                	beqz	a0,80001f14 <allocproc+0xba>
    memset(&p->context, 0, sizeof(p->context));
    80001ec6:	07000613          	li	a2,112
    80001eca:	4581                	li	a1,0
    80001ecc:	06848513          	addi	a0,s1,104
    80001ed0:	fffff097          	auipc	ra,0xfffff
    80001ed4:	e02080e7          	jalr	-510(ra) # 80000cd2 <memset>
    p->context.ra = (uint64)forkret;
    80001ed8:	00000797          	auipc	a5,0x0
    80001edc:	db078793          	addi	a5,a5,-592 # 80001c88 <forkret>
    80001ee0:	f4bc                	sd	a5,104(s1)
    p->context.sp = p->kstack + PGSIZE;
    80001ee2:	64bc                	ld	a5,72(s1)
    80001ee4:	6705                	lui	a4,0x1
    80001ee6:	97ba                	add	a5,a5,a4
    80001ee8:	f8bc                	sd	a5,112(s1)
    p->priority = 0;
    80001eea:	0204aa23          	sw	zero,52(s1)
}
    80001eee:	8526                	mv	a0,s1
    80001ef0:	60e2                	ld	ra,24(sp)
    80001ef2:	6442                	ld	s0,16(sp)
    80001ef4:	64a2                	ld	s1,8(sp)
    80001ef6:	6902                	ld	s2,0(sp)
    80001ef8:	6105                	addi	sp,sp,32
    80001efa:	8082                	ret
        freeproc(p);
    80001efc:	8526                	mv	a0,s1
    80001efe:	00000097          	auipc	ra,0x0
    80001f02:	f04080e7          	jalr	-252(ra) # 80001e02 <freeproc>
        release(&p->lock);
    80001f06:	8526                	mv	a0,s1
    80001f08:	fffff097          	auipc	ra,0xfffff
    80001f0c:	d82080e7          	jalr	-638(ra) # 80000c8a <release>
        return 0;
    80001f10:	84ca                	mv	s1,s2
    80001f12:	bff1                	j	80001eee <allocproc+0x94>
        freeproc(p);
    80001f14:	8526                	mv	a0,s1
    80001f16:	00000097          	auipc	ra,0x0
    80001f1a:	eec080e7          	jalr	-276(ra) # 80001e02 <freeproc>
        release(&p->lock);
    80001f1e:	8526                	mv	a0,s1
    80001f20:	fffff097          	auipc	ra,0xfffff
    80001f24:	d6a080e7          	jalr	-662(ra) # 80000c8a <release>
        return 0;
    80001f28:	84ca                	mv	s1,s2
    80001f2a:	b7d1                	j	80001eee <allocproc+0x94>

0000000080001f2c <userinit>:
{
    80001f2c:	1101                	addi	sp,sp,-32
    80001f2e:	ec06                	sd	ra,24(sp)
    80001f30:	e822                	sd	s0,16(sp)
    80001f32:	e426                	sd	s1,8(sp)
    80001f34:	1000                	addi	s0,sp,32
    p = allocproc();
    80001f36:	00000097          	auipc	ra,0x0
    80001f3a:	f24080e7          	jalr	-220(ra) # 80001e5a <allocproc>
    80001f3e:	84aa                	mv	s1,a0
    initproc = p;
    80001f40:	00007797          	auipc	a5,0x7
    80001f44:	aca7bc23          	sd	a0,-1320(a5) # 80008a18 <initproc>
    uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001f48:	03400613          	li	a2,52
    80001f4c:	00007597          	auipc	a1,0x7
    80001f50:	a0458593          	addi	a1,a1,-1532 # 80008950 <initcode>
    80001f54:	6d28                	ld	a0,88(a0)
    80001f56:	fffff097          	auipc	ra,0xfffff
    80001f5a:	400080e7          	jalr	1024(ra) # 80001356 <uvmfirst>
    p->sz = PGSIZE;
    80001f5e:	6785                	lui	a5,0x1
    80001f60:	e8bc                	sd	a5,80(s1)
    p->trapframe->epc = 0;     // user program counter
    80001f62:	70b8                	ld	a4,96(s1)
    80001f64:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
    p->trapframe->sp = PGSIZE; // user stack pointer
    80001f68:	70b8                	ld	a4,96(s1)
    80001f6a:	fb1c                	sd	a5,48(a4)
    safestrcpy(p->name, "initcode", sizeof(p->name));
    80001f6c:	4641                	li	a2,16
    80001f6e:	00006597          	auipc	a1,0x6
    80001f72:	29258593          	addi	a1,a1,658 # 80008200 <digits+0x1c0>
    80001f76:	16048513          	addi	a0,s1,352
    80001f7a:	fffff097          	auipc	ra,0xfffff
    80001f7e:	ea2080e7          	jalr	-350(ra) # 80000e1c <safestrcpy>
    p->cwd = namei("/");
    80001f82:	00006517          	auipc	a0,0x6
    80001f86:	28e50513          	addi	a0,a0,654 # 80008210 <digits+0x1d0>
    80001f8a:	00002097          	auipc	ra,0x2
    80001f8e:	40e080e7          	jalr	1038(ra) # 80004398 <namei>
    80001f92:	14a4bc23          	sd	a0,344(s1)
    p->state = RUNNABLE;
    80001f96:	478d                	li	a5,3
    80001f98:	cc9c                	sw	a5,24(s1)
    release(&p->lock);
    80001f9a:	8526                	mv	a0,s1
    80001f9c:	fffff097          	auipc	ra,0xfffff
    80001fa0:	cee080e7          	jalr	-786(ra) # 80000c8a <release>
}
    80001fa4:	60e2                	ld	ra,24(sp)
    80001fa6:	6442                	ld	s0,16(sp)
    80001fa8:	64a2                	ld	s1,8(sp)
    80001faa:	6105                	addi	sp,sp,32
    80001fac:	8082                	ret

0000000080001fae <growproc>:
{
    80001fae:	1101                	addi	sp,sp,-32
    80001fb0:	ec06                	sd	ra,24(sp)
    80001fb2:	e822                	sd	s0,16(sp)
    80001fb4:	e426                	sd	s1,8(sp)
    80001fb6:	e04a                	sd	s2,0(sp)
    80001fb8:	1000                	addi	s0,sp,32
    80001fba:	892a                	mv	s2,a0
    struct proc *p = myproc();
    80001fbc:	00000097          	auipc	ra,0x0
    80001fc0:	c8e080e7          	jalr	-882(ra) # 80001c4a <myproc>
    80001fc4:	84aa                	mv	s1,a0
    sz = p->sz;
    80001fc6:	692c                	ld	a1,80(a0)
    if (n > 0)
    80001fc8:	01204c63          	bgtz	s2,80001fe0 <growproc+0x32>
    else if (n < 0)
    80001fcc:	02094663          	bltz	s2,80001ff8 <growproc+0x4a>
    p->sz = sz;
    80001fd0:	e8ac                	sd	a1,80(s1)
    return 0;
    80001fd2:	4501                	li	a0,0
}
    80001fd4:	60e2                	ld	ra,24(sp)
    80001fd6:	6442                	ld	s0,16(sp)
    80001fd8:	64a2                	ld	s1,8(sp)
    80001fda:	6902                	ld	s2,0(sp)
    80001fdc:	6105                	addi	sp,sp,32
    80001fde:	8082                	ret
        if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001fe0:	4691                	li	a3,4
    80001fe2:	00b90633          	add	a2,s2,a1
    80001fe6:	6d28                	ld	a0,88(a0)
    80001fe8:	fffff097          	auipc	ra,0xfffff
    80001fec:	428080e7          	jalr	1064(ra) # 80001410 <uvmalloc>
    80001ff0:	85aa                	mv	a1,a0
    80001ff2:	fd79                	bnez	a0,80001fd0 <growproc+0x22>
            return -1;
    80001ff4:	557d                	li	a0,-1
    80001ff6:	bff9                	j	80001fd4 <growproc+0x26>
        sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001ff8:	00b90633          	add	a2,s2,a1
    80001ffc:	6d28                	ld	a0,88(a0)
    80001ffe:	fffff097          	auipc	ra,0xfffff
    80002002:	3ca080e7          	jalr	970(ra) # 800013c8 <uvmdealloc>
    80002006:	85aa                	mv	a1,a0
    80002008:	b7e1                	j	80001fd0 <growproc+0x22>

000000008000200a <ps>:
{
    8000200a:	715d                	addi	sp,sp,-80
    8000200c:	e486                	sd	ra,72(sp)
    8000200e:	e0a2                	sd	s0,64(sp)
    80002010:	fc26                	sd	s1,56(sp)
    80002012:	f84a                	sd	s2,48(sp)
    80002014:	f44e                	sd	s3,40(sp)
    80002016:	f052                	sd	s4,32(sp)
    80002018:	ec56                	sd	s5,24(sp)
    8000201a:	e85a                	sd	s6,16(sp)
    8000201c:	e45e                	sd	s7,8(sp)
    8000201e:	e062                	sd	s8,0(sp)
    80002020:	0880                	addi	s0,sp,80
    80002022:	84aa                	mv	s1,a0
    80002024:	8bae                	mv	s7,a1
    void *result = (void *)myproc()->sz;
    80002026:	00000097          	auipc	ra,0x0
    8000202a:	c24080e7          	jalr	-988(ra) # 80001c4a <myproc>
        return result;
    8000202e:	4901                	li	s2,0
    if (count == 0)
    80002030:	0c0b8563          	beqz	s7,800020fa <ps+0xf0>
    void *result = (void *)myproc()->sz;
    80002034:	05053b03          	ld	s6,80(a0)
    if (growproc(count * sizeof(struct user_proc)) < 0)
    80002038:	003b951b          	slliw	a0,s7,0x3
    8000203c:	0175053b          	addw	a0,a0,s7
    80002040:	0025151b          	slliw	a0,a0,0x2
    80002044:	00000097          	auipc	ra,0x0
    80002048:	f6a080e7          	jalr	-150(ra) # 80001fae <growproc>
    8000204c:	12054f63          	bltz	a0,8000218a <ps+0x180>
    struct user_proc loc_result[count];
    80002050:	003b9a13          	slli	s4,s7,0x3
    80002054:	9a5e                	add	s4,s4,s7
    80002056:	0a0a                	slli	s4,s4,0x2
    80002058:	00fa0793          	addi	a5,s4,15
    8000205c:	8391                	srli	a5,a5,0x4
    8000205e:	0792                	slli	a5,a5,0x4
    80002060:	40f10133          	sub	sp,sp,a5
    80002064:	8a8a                	mv	s5,sp
    struct proc *p = proc + start;
    80002066:	17000793          	li	a5,368
    8000206a:	02f484b3          	mul	s1,s1,a5
    8000206e:	0000f797          	auipc	a5,0xf
    80002072:	09278793          	addi	a5,a5,146 # 80011100 <proc>
    80002076:	94be                	add	s1,s1,a5
    if (p >= &proc[NPROC])
    80002078:	00015797          	auipc	a5,0x15
    8000207c:	c8878793          	addi	a5,a5,-888 # 80016d00 <tickslock>
        return result;
    80002080:	4901                	li	s2,0
    if (p >= &proc[NPROC])
    80002082:	06f4fc63          	bgeu	s1,a5,800020fa <ps+0xf0>
    acquire(&wait_lock);
    80002086:	0000f517          	auipc	a0,0xf
    8000208a:	06250513          	addi	a0,a0,98 # 800110e8 <wait_lock>
    8000208e:	fffff097          	auipc	ra,0xfffff
    80002092:	b48080e7          	jalr	-1208(ra) # 80000bd6 <acquire>
        if (localCount == count)
    80002096:	014a8913          	addi	s2,s5,20
    uint8 localCount = 0;
    8000209a:	4981                	li	s3,0
    for (; p < &proc[NPROC]; p++)
    8000209c:	00015c17          	auipc	s8,0x15
    800020a0:	c64c0c13          	addi	s8,s8,-924 # 80016d00 <tickslock>
    800020a4:	a851                	j	80002138 <ps+0x12e>
            loc_result[localCount].state = UNUSED;
    800020a6:	00399793          	slli	a5,s3,0x3
    800020aa:	97ce                	add	a5,a5,s3
    800020ac:	078a                	slli	a5,a5,0x2
    800020ae:	97d6                	add	a5,a5,s5
    800020b0:	0007a023          	sw	zero,0(a5)
            release(&p->lock);
    800020b4:	8526                	mv	a0,s1
    800020b6:	fffff097          	auipc	ra,0xfffff
    800020ba:	bd4080e7          	jalr	-1068(ra) # 80000c8a <release>
    release(&wait_lock);
    800020be:	0000f517          	auipc	a0,0xf
    800020c2:	02a50513          	addi	a0,a0,42 # 800110e8 <wait_lock>
    800020c6:	fffff097          	auipc	ra,0xfffff
    800020ca:	bc4080e7          	jalr	-1084(ra) # 80000c8a <release>
    if (localCount < count)
    800020ce:	0179f963          	bgeu	s3,s7,800020e0 <ps+0xd6>
        loc_result[localCount].state = UNUSED; // if we reach the end of processes
    800020d2:	00399793          	slli	a5,s3,0x3
    800020d6:	97ce                	add	a5,a5,s3
    800020d8:	078a                	slli	a5,a5,0x2
    800020da:	97d6                	add	a5,a5,s5
    800020dc:	0007a023          	sw	zero,0(a5)
    void *result = (void *)myproc()->sz;
    800020e0:	895a                	mv	s2,s6
    copyout(myproc()->pagetable, (uint64)result, (void *)loc_result, count * sizeof(struct user_proc));
    800020e2:	00000097          	auipc	ra,0x0
    800020e6:	b68080e7          	jalr	-1176(ra) # 80001c4a <myproc>
    800020ea:	86d2                	mv	a3,s4
    800020ec:	8656                	mv	a2,s5
    800020ee:	85da                	mv	a1,s6
    800020f0:	6d28                	ld	a0,88(a0)
    800020f2:	fffff097          	auipc	ra,0xfffff
    800020f6:	57a080e7          	jalr	1402(ra) # 8000166c <copyout>
}
    800020fa:	854a                	mv	a0,s2
    800020fc:	fb040113          	addi	sp,s0,-80
    80002100:	60a6                	ld	ra,72(sp)
    80002102:	6406                	ld	s0,64(sp)
    80002104:	74e2                	ld	s1,56(sp)
    80002106:	7942                	ld	s2,48(sp)
    80002108:	79a2                	ld	s3,40(sp)
    8000210a:	7a02                	ld	s4,32(sp)
    8000210c:	6ae2                	ld	s5,24(sp)
    8000210e:	6b42                	ld	s6,16(sp)
    80002110:	6ba2                	ld	s7,8(sp)
    80002112:	6c02                	ld	s8,0(sp)
    80002114:	6161                	addi	sp,sp,80
    80002116:	8082                	ret
        release(&p->lock);
    80002118:	8526                	mv	a0,s1
    8000211a:	fffff097          	auipc	ra,0xfffff
    8000211e:	b70080e7          	jalr	-1168(ra) # 80000c8a <release>
        localCount++;
    80002122:	2985                	addiw	s3,s3,1
    80002124:	0ff9f993          	zext.b	s3,s3
    for (; p < &proc[NPROC]; p++)
    80002128:	17048493          	addi	s1,s1,368
    8000212c:	f984f9e3          	bgeu	s1,s8,800020be <ps+0xb4>
        if (localCount == count)
    80002130:	02490913          	addi	s2,s2,36
    80002134:	053b8d63          	beq	s7,s3,8000218e <ps+0x184>
        acquire(&p->lock);
    80002138:	8526                	mv	a0,s1
    8000213a:	fffff097          	auipc	ra,0xfffff
    8000213e:	a9c080e7          	jalr	-1380(ra) # 80000bd6 <acquire>
        if (p->state == UNUSED)
    80002142:	4c9c                	lw	a5,24(s1)
    80002144:	d3ad                	beqz	a5,800020a6 <ps+0x9c>
        loc_result[localCount].state = p->state;
    80002146:	fef92623          	sw	a5,-20(s2)
        loc_result[localCount].killed = p->killed;
    8000214a:	549c                	lw	a5,40(s1)
    8000214c:	fef92823          	sw	a5,-16(s2)
        loc_result[localCount].xstate = p->xstate;
    80002150:	54dc                	lw	a5,44(s1)
    80002152:	fef92a23          	sw	a5,-12(s2)
        loc_result[localCount].pid = p->pid;
    80002156:	589c                	lw	a5,48(s1)
    80002158:	fef92c23          	sw	a5,-8(s2)
        copy_array(p->name, loc_result[localCount].name, 16);
    8000215c:	4641                	li	a2,16
    8000215e:	85ca                	mv	a1,s2
    80002160:	16048513          	addi	a0,s1,352
    80002164:	00000097          	auipc	ra,0x0
    80002168:	a86080e7          	jalr	-1402(ra) # 80001bea <copy_array>
        if (p->parent != 0) // init
    8000216c:	60a8                	ld	a0,64(s1)
    8000216e:	d54d                	beqz	a0,80002118 <ps+0x10e>
            acquire(&p->parent->lock);
    80002170:	fffff097          	auipc	ra,0xfffff
    80002174:	a66080e7          	jalr	-1434(ra) # 80000bd6 <acquire>
            loc_result[localCount].parent_id = p->parent->pid;
    80002178:	60a8                	ld	a0,64(s1)
    8000217a:	591c                	lw	a5,48(a0)
    8000217c:	fef92e23          	sw	a5,-4(s2)
            release(&p->parent->lock);
    80002180:	fffff097          	auipc	ra,0xfffff
    80002184:	b0a080e7          	jalr	-1270(ra) # 80000c8a <release>
    80002188:	bf41                	j	80002118 <ps+0x10e>
        return result;
    8000218a:	4901                	li	s2,0
    8000218c:	b7bd                	j	800020fa <ps+0xf0>
    release(&wait_lock);
    8000218e:	0000f517          	auipc	a0,0xf
    80002192:	f5a50513          	addi	a0,a0,-166 # 800110e8 <wait_lock>
    80002196:	fffff097          	auipc	ra,0xfffff
    8000219a:	af4080e7          	jalr	-1292(ra) # 80000c8a <release>
    if (localCount < count)
    8000219e:	b789                	j	800020e0 <ps+0xd6>

00000000800021a0 <fork>:
{
    800021a0:	7139                	addi	sp,sp,-64
    800021a2:	fc06                	sd	ra,56(sp)
    800021a4:	f822                	sd	s0,48(sp)
    800021a6:	f426                	sd	s1,40(sp)
    800021a8:	f04a                	sd	s2,32(sp)
    800021aa:	ec4e                	sd	s3,24(sp)
    800021ac:	e852                	sd	s4,16(sp)
    800021ae:	e456                	sd	s5,8(sp)
    800021b0:	0080                	addi	s0,sp,64
    struct proc *p = myproc();
    800021b2:	00000097          	auipc	ra,0x0
    800021b6:	a98080e7          	jalr	-1384(ra) # 80001c4a <myproc>
    800021ba:	8aaa                	mv	s5,a0
    if ((np = allocproc()) == 0)
    800021bc:	00000097          	auipc	ra,0x0
    800021c0:	c9e080e7          	jalr	-866(ra) # 80001e5a <allocproc>
    800021c4:	10050c63          	beqz	a0,800022dc <fork+0x13c>
    800021c8:	8a2a                	mv	s4,a0
    if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    800021ca:	050ab603          	ld	a2,80(s5)
    800021ce:	6d2c                	ld	a1,88(a0)
    800021d0:	058ab503          	ld	a0,88(s5)
    800021d4:	fffff097          	auipc	ra,0xfffff
    800021d8:	394080e7          	jalr	916(ra) # 80001568 <uvmcopy>
    800021dc:	04054863          	bltz	a0,8000222c <fork+0x8c>
    np->sz = p->sz;
    800021e0:	050ab783          	ld	a5,80(s5)
    800021e4:	04fa3823          	sd	a5,80(s4)
    *(np->trapframe) = *(p->trapframe);
    800021e8:	060ab683          	ld	a3,96(s5)
    800021ec:	87b6                	mv	a5,a3
    800021ee:	060a3703          	ld	a4,96(s4)
    800021f2:	12068693          	addi	a3,a3,288
    800021f6:	0007b803          	ld	a6,0(a5)
    800021fa:	6788                	ld	a0,8(a5)
    800021fc:	6b8c                	ld	a1,16(a5)
    800021fe:	6f90                	ld	a2,24(a5)
    80002200:	01073023          	sd	a6,0(a4)
    80002204:	e708                	sd	a0,8(a4)
    80002206:	eb0c                	sd	a1,16(a4)
    80002208:	ef10                	sd	a2,24(a4)
    8000220a:	02078793          	addi	a5,a5,32
    8000220e:	02070713          	addi	a4,a4,32
    80002212:	fed792e3          	bne	a5,a3,800021f6 <fork+0x56>
    np->trapframe->a0 = 0;
    80002216:	060a3783          	ld	a5,96(s4)
    8000221a:	0607b823          	sd	zero,112(a5)
    for (i = 0; i < NOFILE; i++)
    8000221e:	0d8a8493          	addi	s1,s5,216
    80002222:	0d8a0913          	addi	s2,s4,216
    80002226:	158a8993          	addi	s3,s5,344
    8000222a:	a00d                	j	8000224c <fork+0xac>
        freeproc(np);
    8000222c:	8552                	mv	a0,s4
    8000222e:	00000097          	auipc	ra,0x0
    80002232:	bd4080e7          	jalr	-1068(ra) # 80001e02 <freeproc>
        release(&np->lock);
    80002236:	8552                	mv	a0,s4
    80002238:	fffff097          	auipc	ra,0xfffff
    8000223c:	a52080e7          	jalr	-1454(ra) # 80000c8a <release>
        return -1;
    80002240:	597d                	li	s2,-1
    80002242:	a059                	j	800022c8 <fork+0x128>
    for (i = 0; i < NOFILE; i++)
    80002244:	04a1                	addi	s1,s1,8
    80002246:	0921                	addi	s2,s2,8
    80002248:	01348b63          	beq	s1,s3,8000225e <fork+0xbe>
        if (p->ofile[i])
    8000224c:	6088                	ld	a0,0(s1)
    8000224e:	d97d                	beqz	a0,80002244 <fork+0xa4>
            np->ofile[i] = filedup(p->ofile[i]);
    80002250:	00002097          	auipc	ra,0x2
    80002254:	7de080e7          	jalr	2014(ra) # 80004a2e <filedup>
    80002258:	00a93023          	sd	a0,0(s2)
    8000225c:	b7e5                	j	80002244 <fork+0xa4>
    np->cwd = idup(p->cwd);
    8000225e:	158ab503          	ld	a0,344(s5)
    80002262:	00002097          	auipc	ra,0x2
    80002266:	94c080e7          	jalr	-1716(ra) # 80003bae <idup>
    8000226a:	14aa3c23          	sd	a0,344(s4)
    safestrcpy(np->name, p->name, sizeof(p->name));
    8000226e:	4641                	li	a2,16
    80002270:	160a8593          	addi	a1,s5,352
    80002274:	160a0513          	addi	a0,s4,352
    80002278:	fffff097          	auipc	ra,0xfffff
    8000227c:	ba4080e7          	jalr	-1116(ra) # 80000e1c <safestrcpy>
    pid = np->pid;
    80002280:	030a2903          	lw	s2,48(s4)
    release(&np->lock);
    80002284:	8552                	mv	a0,s4
    80002286:	fffff097          	auipc	ra,0xfffff
    8000228a:	a04080e7          	jalr	-1532(ra) # 80000c8a <release>
    acquire(&wait_lock);
    8000228e:	0000f497          	auipc	s1,0xf
    80002292:	e5a48493          	addi	s1,s1,-422 # 800110e8 <wait_lock>
    80002296:	8526                	mv	a0,s1
    80002298:	fffff097          	auipc	ra,0xfffff
    8000229c:	93e080e7          	jalr	-1730(ra) # 80000bd6 <acquire>
    np->parent = p;
    800022a0:	055a3023          	sd	s5,64(s4)
    release(&wait_lock);
    800022a4:	8526                	mv	a0,s1
    800022a6:	fffff097          	auipc	ra,0xfffff
    800022aa:	9e4080e7          	jalr	-1564(ra) # 80000c8a <release>
    acquire(&np->lock);
    800022ae:	8552                	mv	a0,s4
    800022b0:	fffff097          	auipc	ra,0xfffff
    800022b4:	926080e7          	jalr	-1754(ra) # 80000bd6 <acquire>
    np->state = RUNNABLE;
    800022b8:	478d                	li	a5,3
    800022ba:	00fa2c23          	sw	a5,24(s4)
    release(&np->lock);
    800022be:	8552                	mv	a0,s4
    800022c0:	fffff097          	auipc	ra,0xfffff
    800022c4:	9ca080e7          	jalr	-1590(ra) # 80000c8a <release>
}
    800022c8:	854a                	mv	a0,s2
    800022ca:	70e2                	ld	ra,56(sp)
    800022cc:	7442                	ld	s0,48(sp)
    800022ce:	74a2                	ld	s1,40(sp)
    800022d0:	7902                	ld	s2,32(sp)
    800022d2:	69e2                	ld	s3,24(sp)
    800022d4:	6a42                	ld	s4,16(sp)
    800022d6:	6aa2                	ld	s5,8(sp)
    800022d8:	6121                	addi	sp,sp,64
    800022da:	8082                	ret
        return -1;
    800022dc:	597d                	li	s2,-1
    800022de:	b7ed                	j	800022c8 <fork+0x128>

00000000800022e0 <scheduler>:
{
    800022e0:	1101                	addi	sp,sp,-32
    800022e2:	ec06                	sd	ra,24(sp)
    800022e4:	e822                	sd	s0,16(sp)
    800022e6:	e426                	sd	s1,8(sp)
    800022e8:	1000                	addi	s0,sp,32
        (*sched_pointer)();
    800022ea:	00006497          	auipc	s1,0x6
    800022ee:	64e48493          	addi	s1,s1,1614 # 80008938 <sched_pointer>
    800022f2:	609c                	ld	a5,0(s1)
    800022f4:	9782                	jalr	a5
    while (1)
    800022f6:	bff5                	j	800022f2 <scheduler+0x12>

00000000800022f8 <sched>:
{
    800022f8:	7179                	addi	sp,sp,-48
    800022fa:	f406                	sd	ra,40(sp)
    800022fc:	f022                	sd	s0,32(sp)
    800022fe:	ec26                	sd	s1,24(sp)
    80002300:	e84a                	sd	s2,16(sp)
    80002302:	e44e                	sd	s3,8(sp)
    80002304:	1800                	addi	s0,sp,48
    struct proc *p = myproc();
    80002306:	00000097          	auipc	ra,0x0
    8000230a:	944080e7          	jalr	-1724(ra) # 80001c4a <myproc>
    8000230e:	84aa                	mv	s1,a0
    if (!holding(&p->lock))
    80002310:	fffff097          	auipc	ra,0xfffff
    80002314:	84c080e7          	jalr	-1972(ra) # 80000b5c <holding>
    80002318:	c159                	beqz	a0,8000239e <sched+0xa6>
    8000231a:	8712                	mv	a4,tp
    if (mycpu()->noff != 1)
    8000231c:	2701                	sext.w	a4,a4
    8000231e:	00471793          	slli	a5,a4,0x4
    80002322:	97ba                	add	a5,a5,a4
    80002324:	078e                	slli	a5,a5,0x3
    80002326:	0000f717          	auipc	a4,0xf
    8000232a:	96a70713          	addi	a4,a4,-1686 # 80010c90 <cpus>
    8000232e:	97ba                	add	a5,a5,a4
    80002330:	5fb8                	lw	a4,120(a5)
    80002332:	4785                	li	a5,1
    80002334:	06f71d63          	bne	a4,a5,800023ae <sched+0xb6>
    if (p->state == RUNNING)
    80002338:	4c98                	lw	a4,24(s1)
    8000233a:	4791                	li	a5,4
    8000233c:	08f70163          	beq	a4,a5,800023be <sched+0xc6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002340:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002344:	8b89                	andi	a5,a5,2
    if (intr_get())
    80002346:	e7c1                	bnez	a5,800023ce <sched+0xd6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002348:	8712                	mv	a4,tp
    intena = mycpu()->intena;
    8000234a:	0000f917          	auipc	s2,0xf
    8000234e:	94690913          	addi	s2,s2,-1722 # 80010c90 <cpus>
    80002352:	2701                	sext.w	a4,a4
    80002354:	00471793          	slli	a5,a4,0x4
    80002358:	97ba                	add	a5,a5,a4
    8000235a:	078e                	slli	a5,a5,0x3
    8000235c:	97ca                	add	a5,a5,s2
    8000235e:	07c7a983          	lw	s3,124(a5)
    80002362:	8792                	mv	a5,tp
    swtch(&p->context, &mycpu()->context);
    80002364:	2781                	sext.w	a5,a5
    80002366:	00479593          	slli	a1,a5,0x4
    8000236a:	95be                	add	a1,a1,a5
    8000236c:	058e                	slli	a1,a1,0x3
    8000236e:	05a1                	addi	a1,a1,8
    80002370:	95ca                	add	a1,a1,s2
    80002372:	06848513          	addi	a0,s1,104
    80002376:	00000097          	auipc	ra,0x0
    8000237a:	74e080e7          	jalr	1870(ra) # 80002ac4 <swtch>
    8000237e:	8712                	mv	a4,tp
    mycpu()->intena = intena;
    80002380:	2701                	sext.w	a4,a4
    80002382:	00471793          	slli	a5,a4,0x4
    80002386:	97ba                	add	a5,a5,a4
    80002388:	078e                	slli	a5,a5,0x3
    8000238a:	993e                	add	s2,s2,a5
    8000238c:	07392e23          	sw	s3,124(s2)
}
    80002390:	70a2                	ld	ra,40(sp)
    80002392:	7402                	ld	s0,32(sp)
    80002394:	64e2                	ld	s1,24(sp)
    80002396:	6942                	ld	s2,16(sp)
    80002398:	69a2                	ld	s3,8(sp)
    8000239a:	6145                	addi	sp,sp,48
    8000239c:	8082                	ret
        panic("sched p->lock");
    8000239e:	00006517          	auipc	a0,0x6
    800023a2:	e7a50513          	addi	a0,a0,-390 # 80008218 <digits+0x1d8>
    800023a6:	ffffe097          	auipc	ra,0xffffe
    800023aa:	19a080e7          	jalr	410(ra) # 80000540 <panic>
        panic("sched locks");
    800023ae:	00006517          	auipc	a0,0x6
    800023b2:	e7a50513          	addi	a0,a0,-390 # 80008228 <digits+0x1e8>
    800023b6:	ffffe097          	auipc	ra,0xffffe
    800023ba:	18a080e7          	jalr	394(ra) # 80000540 <panic>
        panic("sched running");
    800023be:	00006517          	auipc	a0,0x6
    800023c2:	e7a50513          	addi	a0,a0,-390 # 80008238 <digits+0x1f8>
    800023c6:	ffffe097          	auipc	ra,0xffffe
    800023ca:	17a080e7          	jalr	378(ra) # 80000540 <panic>
        panic("sched interruptible");
    800023ce:	00006517          	auipc	a0,0x6
    800023d2:	e7a50513          	addi	a0,a0,-390 # 80008248 <digits+0x208>
    800023d6:	ffffe097          	auipc	ra,0xffffe
    800023da:	16a080e7          	jalr	362(ra) # 80000540 <panic>

00000000800023de <yield>:
{
    800023de:	1101                	addi	sp,sp,-32
    800023e0:	ec06                	sd	ra,24(sp)
    800023e2:	e822                	sd	s0,16(sp)
    800023e4:	e426                	sd	s1,8(sp)
    800023e6:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    800023e8:	00000097          	auipc	ra,0x0
    800023ec:	862080e7          	jalr	-1950(ra) # 80001c4a <myproc>
    800023f0:	84aa                	mv	s1,a0
    acquire(&p->lock);
    800023f2:	ffffe097          	auipc	ra,0xffffe
    800023f6:	7e4080e7          	jalr	2020(ra) # 80000bd6 <acquire>
    p->state = RUNNABLE;
    800023fa:	478d                	li	a5,3
    800023fc:	cc9c                	sw	a5,24(s1)
    sched();
    800023fe:	00000097          	auipc	ra,0x0
    80002402:	efa080e7          	jalr	-262(ra) # 800022f8 <sched>
    release(&p->lock);
    80002406:	8526                	mv	a0,s1
    80002408:	fffff097          	auipc	ra,0xfffff
    8000240c:	882080e7          	jalr	-1918(ra) # 80000c8a <release>
}
    80002410:	60e2                	ld	ra,24(sp)
    80002412:	6442                	ld	s0,16(sp)
    80002414:	64a2                	ld	s1,8(sp)
    80002416:	6105                	addi	sp,sp,32
    80002418:	8082                	ret

000000008000241a <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    8000241a:	7179                	addi	sp,sp,-48
    8000241c:	f406                	sd	ra,40(sp)
    8000241e:	f022                	sd	s0,32(sp)
    80002420:	ec26                	sd	s1,24(sp)
    80002422:	e84a                	sd	s2,16(sp)
    80002424:	e44e                	sd	s3,8(sp)
    80002426:	1800                	addi	s0,sp,48
    80002428:	89aa                	mv	s3,a0
    8000242a:	892e                	mv	s2,a1
    struct proc *p = myproc();
    8000242c:	00000097          	auipc	ra,0x0
    80002430:	81e080e7          	jalr	-2018(ra) # 80001c4a <myproc>
    80002434:	84aa                	mv	s1,a0
    // Once we hold p->lock, we can be
    // guaranteed that we won't miss any wakeup
    // (wakeup locks p->lock),
    // so it's okay to release lk.

    acquire(&p->lock); // DOC: sleeplock1
    80002436:	ffffe097          	auipc	ra,0xffffe
    8000243a:	7a0080e7          	jalr	1952(ra) # 80000bd6 <acquire>
    release(lk);
    8000243e:	854a                	mv	a0,s2
    80002440:	fffff097          	auipc	ra,0xfffff
    80002444:	84a080e7          	jalr	-1974(ra) # 80000c8a <release>

    // Go to sleep.
    p->chan = chan;
    80002448:	0334b023          	sd	s3,32(s1)
    p->state = SLEEPING;
    8000244c:	4789                	li	a5,2
    8000244e:	cc9c                	sw	a5,24(s1)

    sched();
    80002450:	00000097          	auipc	ra,0x0
    80002454:	ea8080e7          	jalr	-344(ra) # 800022f8 <sched>

    // Tidy up.
    p->chan = 0;
    80002458:	0204b023          	sd	zero,32(s1)

    // Reacquire original lock.
    release(&p->lock);
    8000245c:	8526                	mv	a0,s1
    8000245e:	fffff097          	auipc	ra,0xfffff
    80002462:	82c080e7          	jalr	-2004(ra) # 80000c8a <release>
    acquire(lk);
    80002466:	854a                	mv	a0,s2
    80002468:	ffffe097          	auipc	ra,0xffffe
    8000246c:	76e080e7          	jalr	1902(ra) # 80000bd6 <acquire>
}
    80002470:	70a2                	ld	ra,40(sp)
    80002472:	7402                	ld	s0,32(sp)
    80002474:	64e2                	ld	s1,24(sp)
    80002476:	6942                	ld	s2,16(sp)
    80002478:	69a2                	ld	s3,8(sp)
    8000247a:	6145                	addi	sp,sp,48
    8000247c:	8082                	ret

000000008000247e <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    8000247e:	7139                	addi	sp,sp,-64
    80002480:	fc06                	sd	ra,56(sp)
    80002482:	f822                	sd	s0,48(sp)
    80002484:	f426                	sd	s1,40(sp)
    80002486:	f04a                	sd	s2,32(sp)
    80002488:	ec4e                	sd	s3,24(sp)
    8000248a:	e852                	sd	s4,16(sp)
    8000248c:	e456                	sd	s5,8(sp)
    8000248e:	0080                	addi	s0,sp,64
    80002490:	8a2a                	mv	s4,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    80002492:	0000f497          	auipc	s1,0xf
    80002496:	c6e48493          	addi	s1,s1,-914 # 80011100 <proc>
    {
        if (p != myproc())
        {
            acquire(&p->lock);
            if (p->state == SLEEPING && p->chan == chan)
    8000249a:	4989                	li	s3,2
            {
                p->state = RUNNABLE;
    8000249c:	4a8d                	li	s5,3
    for (p = proc; p < &proc[NPROC]; p++)
    8000249e:	00015917          	auipc	s2,0x15
    800024a2:	86290913          	addi	s2,s2,-1950 # 80016d00 <tickslock>
    800024a6:	a811                	j	800024ba <wakeup+0x3c>
            }
            release(&p->lock);
    800024a8:	8526                	mv	a0,s1
    800024aa:	ffffe097          	auipc	ra,0xffffe
    800024ae:	7e0080e7          	jalr	2016(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    800024b2:	17048493          	addi	s1,s1,368
    800024b6:	03248663          	beq	s1,s2,800024e2 <wakeup+0x64>
        if (p != myproc())
    800024ba:	fffff097          	auipc	ra,0xfffff
    800024be:	790080e7          	jalr	1936(ra) # 80001c4a <myproc>
    800024c2:	fea488e3          	beq	s1,a0,800024b2 <wakeup+0x34>
            acquire(&p->lock);
    800024c6:	8526                	mv	a0,s1
    800024c8:	ffffe097          	auipc	ra,0xffffe
    800024cc:	70e080e7          	jalr	1806(ra) # 80000bd6 <acquire>
            if (p->state == SLEEPING && p->chan == chan)
    800024d0:	4c9c                	lw	a5,24(s1)
    800024d2:	fd379be3          	bne	a5,s3,800024a8 <wakeup+0x2a>
    800024d6:	709c                	ld	a5,32(s1)
    800024d8:	fd4798e3          	bne	a5,s4,800024a8 <wakeup+0x2a>
                p->state = RUNNABLE;
    800024dc:	0154ac23          	sw	s5,24(s1)
    800024e0:	b7e1                	j	800024a8 <wakeup+0x2a>
        }
    }
}
    800024e2:	70e2                	ld	ra,56(sp)
    800024e4:	7442                	ld	s0,48(sp)
    800024e6:	74a2                	ld	s1,40(sp)
    800024e8:	7902                	ld	s2,32(sp)
    800024ea:	69e2                	ld	s3,24(sp)
    800024ec:	6a42                	ld	s4,16(sp)
    800024ee:	6aa2                	ld	s5,8(sp)
    800024f0:	6121                	addi	sp,sp,64
    800024f2:	8082                	ret

00000000800024f4 <reparent>:
{
    800024f4:	7179                	addi	sp,sp,-48
    800024f6:	f406                	sd	ra,40(sp)
    800024f8:	f022                	sd	s0,32(sp)
    800024fa:	ec26                	sd	s1,24(sp)
    800024fc:	e84a                	sd	s2,16(sp)
    800024fe:	e44e                	sd	s3,8(sp)
    80002500:	e052                	sd	s4,0(sp)
    80002502:	1800                	addi	s0,sp,48
    80002504:	892a                	mv	s2,a0
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002506:	0000f497          	auipc	s1,0xf
    8000250a:	bfa48493          	addi	s1,s1,-1030 # 80011100 <proc>
            pp->parent = initproc;
    8000250e:	00006a17          	auipc	s4,0x6
    80002512:	50aa0a13          	addi	s4,s4,1290 # 80008a18 <initproc>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002516:	00014997          	auipc	s3,0x14
    8000251a:	7ea98993          	addi	s3,s3,2026 # 80016d00 <tickslock>
    8000251e:	a029                	j	80002528 <reparent+0x34>
    80002520:	17048493          	addi	s1,s1,368
    80002524:	01348d63          	beq	s1,s3,8000253e <reparent+0x4a>
        if (pp->parent == p)
    80002528:	60bc                	ld	a5,64(s1)
    8000252a:	ff279be3          	bne	a5,s2,80002520 <reparent+0x2c>
            pp->parent = initproc;
    8000252e:	000a3503          	ld	a0,0(s4)
    80002532:	e0a8                	sd	a0,64(s1)
            wakeup(initproc);
    80002534:	00000097          	auipc	ra,0x0
    80002538:	f4a080e7          	jalr	-182(ra) # 8000247e <wakeup>
    8000253c:	b7d5                	j	80002520 <reparent+0x2c>
}
    8000253e:	70a2                	ld	ra,40(sp)
    80002540:	7402                	ld	s0,32(sp)
    80002542:	64e2                	ld	s1,24(sp)
    80002544:	6942                	ld	s2,16(sp)
    80002546:	69a2                	ld	s3,8(sp)
    80002548:	6a02                	ld	s4,0(sp)
    8000254a:	6145                	addi	sp,sp,48
    8000254c:	8082                	ret

000000008000254e <exit>:
{
    8000254e:	7179                	addi	sp,sp,-48
    80002550:	f406                	sd	ra,40(sp)
    80002552:	f022                	sd	s0,32(sp)
    80002554:	ec26                	sd	s1,24(sp)
    80002556:	e84a                	sd	s2,16(sp)
    80002558:	e44e                	sd	s3,8(sp)
    8000255a:	e052                	sd	s4,0(sp)
    8000255c:	1800                	addi	s0,sp,48
    8000255e:	8a2a                	mv	s4,a0
    struct proc *p = myproc();
    80002560:	fffff097          	auipc	ra,0xfffff
    80002564:	6ea080e7          	jalr	1770(ra) # 80001c4a <myproc>
    80002568:	89aa                	mv	s3,a0
    if (p == initproc)
    8000256a:	00006797          	auipc	a5,0x6
    8000256e:	4ae7b783          	ld	a5,1198(a5) # 80008a18 <initproc>
    80002572:	0d850493          	addi	s1,a0,216
    80002576:	15850913          	addi	s2,a0,344
    8000257a:	02a79363          	bne	a5,a0,800025a0 <exit+0x52>
        panic("init exiting");
    8000257e:	00006517          	auipc	a0,0x6
    80002582:	ce250513          	addi	a0,a0,-798 # 80008260 <digits+0x220>
    80002586:	ffffe097          	auipc	ra,0xffffe
    8000258a:	fba080e7          	jalr	-70(ra) # 80000540 <panic>
            fileclose(f);
    8000258e:	00002097          	auipc	ra,0x2
    80002592:	4f2080e7          	jalr	1266(ra) # 80004a80 <fileclose>
            p->ofile[fd] = 0;
    80002596:	0004b023          	sd	zero,0(s1)
    for (int fd = 0; fd < NOFILE; fd++)
    8000259a:	04a1                	addi	s1,s1,8
    8000259c:	01248563          	beq	s1,s2,800025a6 <exit+0x58>
        if (p->ofile[fd])
    800025a0:	6088                	ld	a0,0(s1)
    800025a2:	f575                	bnez	a0,8000258e <exit+0x40>
    800025a4:	bfdd                	j	8000259a <exit+0x4c>
    begin_op();
    800025a6:	00002097          	auipc	ra,0x2
    800025aa:	012080e7          	jalr	18(ra) # 800045b8 <begin_op>
    iput(p->cwd);
    800025ae:	1589b503          	ld	a0,344(s3)
    800025b2:	00001097          	auipc	ra,0x1
    800025b6:	7f4080e7          	jalr	2036(ra) # 80003da6 <iput>
    end_op();
    800025ba:	00002097          	auipc	ra,0x2
    800025be:	07c080e7          	jalr	124(ra) # 80004636 <end_op>
    p->cwd = 0;
    800025c2:	1409bc23          	sd	zero,344(s3)
    acquire(&wait_lock);
    800025c6:	0000f497          	auipc	s1,0xf
    800025ca:	b2248493          	addi	s1,s1,-1246 # 800110e8 <wait_lock>
    800025ce:	8526                	mv	a0,s1
    800025d0:	ffffe097          	auipc	ra,0xffffe
    800025d4:	606080e7          	jalr	1542(ra) # 80000bd6 <acquire>
    reparent(p);
    800025d8:	854e                	mv	a0,s3
    800025da:	00000097          	auipc	ra,0x0
    800025de:	f1a080e7          	jalr	-230(ra) # 800024f4 <reparent>
    wakeup(p->parent);
    800025e2:	0409b503          	ld	a0,64(s3)
    800025e6:	00000097          	auipc	ra,0x0
    800025ea:	e98080e7          	jalr	-360(ra) # 8000247e <wakeup>
    acquire(&p->lock);
    800025ee:	854e                	mv	a0,s3
    800025f0:	ffffe097          	auipc	ra,0xffffe
    800025f4:	5e6080e7          	jalr	1510(ra) # 80000bd6 <acquire>
    p->xstate = status;
    800025f8:	0349a623          	sw	s4,44(s3)
    p->state = ZOMBIE;
    800025fc:	4795                	li	a5,5
    800025fe:	00f9ac23          	sw	a5,24(s3)
    release(&wait_lock);
    80002602:	8526                	mv	a0,s1
    80002604:	ffffe097          	auipc	ra,0xffffe
    80002608:	686080e7          	jalr	1670(ra) # 80000c8a <release>
    sched();
    8000260c:	00000097          	auipc	ra,0x0
    80002610:	cec080e7          	jalr	-788(ra) # 800022f8 <sched>
    panic("zombie exit");
    80002614:	00006517          	auipc	a0,0x6
    80002618:	c5c50513          	addi	a0,a0,-932 # 80008270 <digits+0x230>
    8000261c:	ffffe097          	auipc	ra,0xffffe
    80002620:	f24080e7          	jalr	-220(ra) # 80000540 <panic>

0000000080002624 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002624:	7179                	addi	sp,sp,-48
    80002626:	f406                	sd	ra,40(sp)
    80002628:	f022                	sd	s0,32(sp)
    8000262a:	ec26                	sd	s1,24(sp)
    8000262c:	e84a                	sd	s2,16(sp)
    8000262e:	e44e                	sd	s3,8(sp)
    80002630:	1800                	addi	s0,sp,48
    80002632:	892a                	mv	s2,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    80002634:	0000f497          	auipc	s1,0xf
    80002638:	acc48493          	addi	s1,s1,-1332 # 80011100 <proc>
    8000263c:	00014997          	auipc	s3,0x14
    80002640:	6c498993          	addi	s3,s3,1732 # 80016d00 <tickslock>
    {
        acquire(&p->lock);
    80002644:	8526                	mv	a0,s1
    80002646:	ffffe097          	auipc	ra,0xffffe
    8000264a:	590080e7          	jalr	1424(ra) # 80000bd6 <acquire>
        if (p->pid == pid)
    8000264e:	589c                	lw	a5,48(s1)
    80002650:	01278d63          	beq	a5,s2,8000266a <kill+0x46>
                p->state = RUNNABLE;
            }
            release(&p->lock);
            return 0;
        }
        release(&p->lock);
    80002654:	8526                	mv	a0,s1
    80002656:	ffffe097          	auipc	ra,0xffffe
    8000265a:	634080e7          	jalr	1588(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000265e:	17048493          	addi	s1,s1,368
    80002662:	ff3491e3          	bne	s1,s3,80002644 <kill+0x20>
    }
    return -1;
    80002666:	557d                	li	a0,-1
    80002668:	a829                	j	80002682 <kill+0x5e>
            p->killed = 1;
    8000266a:	4785                	li	a5,1
    8000266c:	d49c                	sw	a5,40(s1)
            if (p->state == SLEEPING)
    8000266e:	4c98                	lw	a4,24(s1)
    80002670:	4789                	li	a5,2
    80002672:	00f70f63          	beq	a4,a5,80002690 <kill+0x6c>
            release(&p->lock);
    80002676:	8526                	mv	a0,s1
    80002678:	ffffe097          	auipc	ra,0xffffe
    8000267c:	612080e7          	jalr	1554(ra) # 80000c8a <release>
            return 0;
    80002680:	4501                	li	a0,0
}
    80002682:	70a2                	ld	ra,40(sp)
    80002684:	7402                	ld	s0,32(sp)
    80002686:	64e2                	ld	s1,24(sp)
    80002688:	6942                	ld	s2,16(sp)
    8000268a:	69a2                	ld	s3,8(sp)
    8000268c:	6145                	addi	sp,sp,48
    8000268e:	8082                	ret
                p->state = RUNNABLE;
    80002690:	478d                	li	a5,3
    80002692:	cc9c                	sw	a5,24(s1)
    80002694:	b7cd                	j	80002676 <kill+0x52>

0000000080002696 <setkilled>:

void setkilled(struct proc *p)
{
    80002696:	1101                	addi	sp,sp,-32
    80002698:	ec06                	sd	ra,24(sp)
    8000269a:	e822                	sd	s0,16(sp)
    8000269c:	e426                	sd	s1,8(sp)
    8000269e:	1000                	addi	s0,sp,32
    800026a0:	84aa                	mv	s1,a0
    acquire(&p->lock);
    800026a2:	ffffe097          	auipc	ra,0xffffe
    800026a6:	534080e7          	jalr	1332(ra) # 80000bd6 <acquire>
    p->killed = 1;
    800026aa:	4785                	li	a5,1
    800026ac:	d49c                	sw	a5,40(s1)
    release(&p->lock);
    800026ae:	8526                	mv	a0,s1
    800026b0:	ffffe097          	auipc	ra,0xffffe
    800026b4:	5da080e7          	jalr	1498(ra) # 80000c8a <release>
}
    800026b8:	60e2                	ld	ra,24(sp)
    800026ba:	6442                	ld	s0,16(sp)
    800026bc:	64a2                	ld	s1,8(sp)
    800026be:	6105                	addi	sp,sp,32
    800026c0:	8082                	ret

00000000800026c2 <killed>:

int killed(struct proc *p)
{
    800026c2:	1101                	addi	sp,sp,-32
    800026c4:	ec06                	sd	ra,24(sp)
    800026c6:	e822                	sd	s0,16(sp)
    800026c8:	e426                	sd	s1,8(sp)
    800026ca:	e04a                	sd	s2,0(sp)
    800026cc:	1000                	addi	s0,sp,32
    800026ce:	84aa                	mv	s1,a0
    int k;

    acquire(&p->lock);
    800026d0:	ffffe097          	auipc	ra,0xffffe
    800026d4:	506080e7          	jalr	1286(ra) # 80000bd6 <acquire>
    k = p->killed;
    800026d8:	0284a903          	lw	s2,40(s1)
    release(&p->lock);
    800026dc:	8526                	mv	a0,s1
    800026de:	ffffe097          	auipc	ra,0xffffe
    800026e2:	5ac080e7          	jalr	1452(ra) # 80000c8a <release>
    return k;
}
    800026e6:	854a                	mv	a0,s2
    800026e8:	60e2                	ld	ra,24(sp)
    800026ea:	6442                	ld	s0,16(sp)
    800026ec:	64a2                	ld	s1,8(sp)
    800026ee:	6902                	ld	s2,0(sp)
    800026f0:	6105                	addi	sp,sp,32
    800026f2:	8082                	ret

00000000800026f4 <wait>:
{
    800026f4:	715d                	addi	sp,sp,-80
    800026f6:	e486                	sd	ra,72(sp)
    800026f8:	e0a2                	sd	s0,64(sp)
    800026fa:	fc26                	sd	s1,56(sp)
    800026fc:	f84a                	sd	s2,48(sp)
    800026fe:	f44e                	sd	s3,40(sp)
    80002700:	f052                	sd	s4,32(sp)
    80002702:	ec56                	sd	s5,24(sp)
    80002704:	e85a                	sd	s6,16(sp)
    80002706:	e45e                	sd	s7,8(sp)
    80002708:	e062                	sd	s8,0(sp)
    8000270a:	0880                	addi	s0,sp,80
    8000270c:	8b2a                	mv	s6,a0
    struct proc *p = myproc();
    8000270e:	fffff097          	auipc	ra,0xfffff
    80002712:	53c080e7          	jalr	1340(ra) # 80001c4a <myproc>
    80002716:	892a                	mv	s2,a0
    acquire(&wait_lock);
    80002718:	0000f517          	auipc	a0,0xf
    8000271c:	9d050513          	addi	a0,a0,-1584 # 800110e8 <wait_lock>
    80002720:	ffffe097          	auipc	ra,0xffffe
    80002724:	4b6080e7          	jalr	1206(ra) # 80000bd6 <acquire>
        havekids = 0;
    80002728:	4b81                	li	s7,0
                if (pp->state == ZOMBIE)
    8000272a:	4a15                	li	s4,5
                havekids = 1;
    8000272c:	4a85                	li	s5,1
        for (pp = proc; pp < &proc[NPROC]; pp++)
    8000272e:	00014997          	auipc	s3,0x14
    80002732:	5d298993          	addi	s3,s3,1490 # 80016d00 <tickslock>
        sleep(p, &wait_lock); // DOC: wait-sleep
    80002736:	0000fc17          	auipc	s8,0xf
    8000273a:	9b2c0c13          	addi	s8,s8,-1614 # 800110e8 <wait_lock>
        havekids = 0;
    8000273e:	875e                	mv	a4,s7
        for (pp = proc; pp < &proc[NPROC]; pp++)
    80002740:	0000f497          	auipc	s1,0xf
    80002744:	9c048493          	addi	s1,s1,-1600 # 80011100 <proc>
    80002748:	a0bd                	j	800027b6 <wait+0xc2>
                    pid = pp->pid;
    8000274a:	0304a983          	lw	s3,48(s1)
                    if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    8000274e:	000b0e63          	beqz	s6,8000276a <wait+0x76>
    80002752:	4691                	li	a3,4
    80002754:	02c48613          	addi	a2,s1,44
    80002758:	85da                	mv	a1,s6
    8000275a:	05893503          	ld	a0,88(s2)
    8000275e:	fffff097          	auipc	ra,0xfffff
    80002762:	f0e080e7          	jalr	-242(ra) # 8000166c <copyout>
    80002766:	02054563          	bltz	a0,80002790 <wait+0x9c>
                    freeproc(pp);
    8000276a:	8526                	mv	a0,s1
    8000276c:	fffff097          	auipc	ra,0xfffff
    80002770:	696080e7          	jalr	1686(ra) # 80001e02 <freeproc>
                    release(&pp->lock);
    80002774:	8526                	mv	a0,s1
    80002776:	ffffe097          	auipc	ra,0xffffe
    8000277a:	514080e7          	jalr	1300(ra) # 80000c8a <release>
                    release(&wait_lock);
    8000277e:	0000f517          	auipc	a0,0xf
    80002782:	96a50513          	addi	a0,a0,-1686 # 800110e8 <wait_lock>
    80002786:	ffffe097          	auipc	ra,0xffffe
    8000278a:	504080e7          	jalr	1284(ra) # 80000c8a <release>
                    return pid;
    8000278e:	a0b5                	j	800027fa <wait+0x106>
                        release(&pp->lock);
    80002790:	8526                	mv	a0,s1
    80002792:	ffffe097          	auipc	ra,0xffffe
    80002796:	4f8080e7          	jalr	1272(ra) # 80000c8a <release>
                        release(&wait_lock);
    8000279a:	0000f517          	auipc	a0,0xf
    8000279e:	94e50513          	addi	a0,a0,-1714 # 800110e8 <wait_lock>
    800027a2:	ffffe097          	auipc	ra,0xffffe
    800027a6:	4e8080e7          	jalr	1256(ra) # 80000c8a <release>
                        return -1;
    800027aa:	59fd                	li	s3,-1
    800027ac:	a0b9                	j	800027fa <wait+0x106>
        for (pp = proc; pp < &proc[NPROC]; pp++)
    800027ae:	17048493          	addi	s1,s1,368
    800027b2:	03348463          	beq	s1,s3,800027da <wait+0xe6>
            if (pp->parent == p)
    800027b6:	60bc                	ld	a5,64(s1)
    800027b8:	ff279be3          	bne	a5,s2,800027ae <wait+0xba>
                acquire(&pp->lock);
    800027bc:	8526                	mv	a0,s1
    800027be:	ffffe097          	auipc	ra,0xffffe
    800027c2:	418080e7          	jalr	1048(ra) # 80000bd6 <acquire>
                if (pp->state == ZOMBIE)
    800027c6:	4c9c                	lw	a5,24(s1)
    800027c8:	f94781e3          	beq	a5,s4,8000274a <wait+0x56>
                release(&pp->lock);
    800027cc:	8526                	mv	a0,s1
    800027ce:	ffffe097          	auipc	ra,0xffffe
    800027d2:	4bc080e7          	jalr	1212(ra) # 80000c8a <release>
                havekids = 1;
    800027d6:	8756                	mv	a4,s5
    800027d8:	bfd9                	j	800027ae <wait+0xba>
        if (!havekids || killed(p))
    800027da:	c719                	beqz	a4,800027e8 <wait+0xf4>
    800027dc:	854a                	mv	a0,s2
    800027de:	00000097          	auipc	ra,0x0
    800027e2:	ee4080e7          	jalr	-284(ra) # 800026c2 <killed>
    800027e6:	c51d                	beqz	a0,80002814 <wait+0x120>
            release(&wait_lock);
    800027e8:	0000f517          	auipc	a0,0xf
    800027ec:	90050513          	addi	a0,a0,-1792 # 800110e8 <wait_lock>
    800027f0:	ffffe097          	auipc	ra,0xffffe
    800027f4:	49a080e7          	jalr	1178(ra) # 80000c8a <release>
            return -1;
    800027f8:	59fd                	li	s3,-1
}
    800027fa:	854e                	mv	a0,s3
    800027fc:	60a6                	ld	ra,72(sp)
    800027fe:	6406                	ld	s0,64(sp)
    80002800:	74e2                	ld	s1,56(sp)
    80002802:	7942                	ld	s2,48(sp)
    80002804:	79a2                	ld	s3,40(sp)
    80002806:	7a02                	ld	s4,32(sp)
    80002808:	6ae2                	ld	s5,24(sp)
    8000280a:	6b42                	ld	s6,16(sp)
    8000280c:	6ba2                	ld	s7,8(sp)
    8000280e:	6c02                	ld	s8,0(sp)
    80002810:	6161                	addi	sp,sp,80
    80002812:	8082                	ret
        sleep(p, &wait_lock); // DOC: wait-sleep
    80002814:	85e2                	mv	a1,s8
    80002816:	854a                	mv	a0,s2
    80002818:	00000097          	auipc	ra,0x0
    8000281c:	c02080e7          	jalr	-1022(ra) # 8000241a <sleep>
        havekids = 0;
    80002820:	bf39                	j	8000273e <wait+0x4a>

0000000080002822 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002822:	7179                	addi	sp,sp,-48
    80002824:	f406                	sd	ra,40(sp)
    80002826:	f022                	sd	s0,32(sp)
    80002828:	ec26                	sd	s1,24(sp)
    8000282a:	e84a                	sd	s2,16(sp)
    8000282c:	e44e                	sd	s3,8(sp)
    8000282e:	e052                	sd	s4,0(sp)
    80002830:	1800                	addi	s0,sp,48
    80002832:	84aa                	mv	s1,a0
    80002834:	892e                	mv	s2,a1
    80002836:	89b2                	mv	s3,a2
    80002838:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    8000283a:	fffff097          	auipc	ra,0xfffff
    8000283e:	410080e7          	jalr	1040(ra) # 80001c4a <myproc>
    if (user_dst)
    80002842:	c08d                	beqz	s1,80002864 <either_copyout+0x42>
    {
        return copyout(p->pagetable, dst, src, len);
    80002844:	86d2                	mv	a3,s4
    80002846:	864e                	mv	a2,s3
    80002848:	85ca                	mv	a1,s2
    8000284a:	6d28                	ld	a0,88(a0)
    8000284c:	fffff097          	auipc	ra,0xfffff
    80002850:	e20080e7          	jalr	-480(ra) # 8000166c <copyout>
    else
    {
        memmove((char *)dst, src, len);
        return 0;
    }
}
    80002854:	70a2                	ld	ra,40(sp)
    80002856:	7402                	ld	s0,32(sp)
    80002858:	64e2                	ld	s1,24(sp)
    8000285a:	6942                	ld	s2,16(sp)
    8000285c:	69a2                	ld	s3,8(sp)
    8000285e:	6a02                	ld	s4,0(sp)
    80002860:	6145                	addi	sp,sp,48
    80002862:	8082                	ret
        memmove((char *)dst, src, len);
    80002864:	000a061b          	sext.w	a2,s4
    80002868:	85ce                	mv	a1,s3
    8000286a:	854a                	mv	a0,s2
    8000286c:	ffffe097          	auipc	ra,0xffffe
    80002870:	4c2080e7          	jalr	1218(ra) # 80000d2e <memmove>
        return 0;
    80002874:	8526                	mv	a0,s1
    80002876:	bff9                	j	80002854 <either_copyout+0x32>

0000000080002878 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002878:	7179                	addi	sp,sp,-48
    8000287a:	f406                	sd	ra,40(sp)
    8000287c:	f022                	sd	s0,32(sp)
    8000287e:	ec26                	sd	s1,24(sp)
    80002880:	e84a                	sd	s2,16(sp)
    80002882:	e44e                	sd	s3,8(sp)
    80002884:	e052                	sd	s4,0(sp)
    80002886:	1800                	addi	s0,sp,48
    80002888:	892a                	mv	s2,a0
    8000288a:	84ae                	mv	s1,a1
    8000288c:	89b2                	mv	s3,a2
    8000288e:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    80002890:	fffff097          	auipc	ra,0xfffff
    80002894:	3ba080e7          	jalr	954(ra) # 80001c4a <myproc>
    if (user_src)
    80002898:	c08d                	beqz	s1,800028ba <either_copyin+0x42>
    {
        return copyin(p->pagetable, dst, src, len);
    8000289a:	86d2                	mv	a3,s4
    8000289c:	864e                	mv	a2,s3
    8000289e:	85ca                	mv	a1,s2
    800028a0:	6d28                	ld	a0,88(a0)
    800028a2:	fffff097          	auipc	ra,0xfffff
    800028a6:	e56080e7          	jalr	-426(ra) # 800016f8 <copyin>
    else
    {
        memmove(dst, (char *)src, len);
        return 0;
    }
}
    800028aa:	70a2                	ld	ra,40(sp)
    800028ac:	7402                	ld	s0,32(sp)
    800028ae:	64e2                	ld	s1,24(sp)
    800028b0:	6942                	ld	s2,16(sp)
    800028b2:	69a2                	ld	s3,8(sp)
    800028b4:	6a02                	ld	s4,0(sp)
    800028b6:	6145                	addi	sp,sp,48
    800028b8:	8082                	ret
        memmove(dst, (char *)src, len);
    800028ba:	000a061b          	sext.w	a2,s4
    800028be:	85ce                	mv	a1,s3
    800028c0:	854a                	mv	a0,s2
    800028c2:	ffffe097          	auipc	ra,0xffffe
    800028c6:	46c080e7          	jalr	1132(ra) # 80000d2e <memmove>
        return 0;
    800028ca:	8526                	mv	a0,s1
    800028cc:	bff9                	j	800028aa <either_copyin+0x32>

00000000800028ce <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    800028ce:	715d                	addi	sp,sp,-80
    800028d0:	e486                	sd	ra,72(sp)
    800028d2:	e0a2                	sd	s0,64(sp)
    800028d4:	fc26                	sd	s1,56(sp)
    800028d6:	f84a                	sd	s2,48(sp)
    800028d8:	f44e                	sd	s3,40(sp)
    800028da:	f052                	sd	s4,32(sp)
    800028dc:	ec56                	sd	s5,24(sp)
    800028de:	e85a                	sd	s6,16(sp)
    800028e0:	e45e                	sd	s7,8(sp)
    800028e2:	0880                	addi	s0,sp,80
        [RUNNING] "run   ",
        [ZOMBIE] "zombie"};
    struct proc *p;
    char *state;

    printf("\n");
    800028e4:	00005517          	auipc	a0,0x5
    800028e8:	7e450513          	addi	a0,a0,2020 # 800080c8 <digits+0x88>
    800028ec:	ffffe097          	auipc	ra,0xffffe
    800028f0:	c9e080e7          	jalr	-866(ra) # 8000058a <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    800028f4:	0000f497          	auipc	s1,0xf
    800028f8:	96c48493          	addi	s1,s1,-1684 # 80011260 <proc+0x160>
    800028fc:	00014917          	auipc	s2,0x14
    80002900:	56490913          	addi	s2,s2,1380 # 80016e60 <bcache+0x148>
    {
        if (p->state == UNUSED)
            continue;
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002904:	4b15                	li	s6,5
            state = states[p->state];
        else
            state = "???";
    80002906:	00006997          	auipc	s3,0x6
    8000290a:	97a98993          	addi	s3,s3,-1670 # 80008280 <digits+0x240>
        printf("%d <%s %s", p->pid, state, p->name);
    8000290e:	00006a97          	auipc	s5,0x6
    80002912:	97aa8a93          	addi	s5,s5,-1670 # 80008288 <digits+0x248>
        printf("\n");
    80002916:	00005a17          	auipc	s4,0x5
    8000291a:	7b2a0a13          	addi	s4,s4,1970 # 800080c8 <digits+0x88>
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000291e:	00006b97          	auipc	s7,0x6
    80002922:	a7ab8b93          	addi	s7,s7,-1414 # 80008398 <states.0>
    80002926:	a00d                	j	80002948 <procdump+0x7a>
        printf("%d <%s %s", p->pid, state, p->name);
    80002928:	ed06a583          	lw	a1,-304(a3)
    8000292c:	8556                	mv	a0,s5
    8000292e:	ffffe097          	auipc	ra,0xffffe
    80002932:	c5c080e7          	jalr	-932(ra) # 8000058a <printf>
        printf("\n");
    80002936:	8552                	mv	a0,s4
    80002938:	ffffe097          	auipc	ra,0xffffe
    8000293c:	c52080e7          	jalr	-942(ra) # 8000058a <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    80002940:	17048493          	addi	s1,s1,368
    80002944:	03248263          	beq	s1,s2,80002968 <procdump+0x9a>
        if (p->state == UNUSED)
    80002948:	86a6                	mv	a3,s1
    8000294a:	eb84a783          	lw	a5,-328(s1)
    8000294e:	dbed                	beqz	a5,80002940 <procdump+0x72>
            state = "???";
    80002950:	864e                	mv	a2,s3
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002952:	fcfb6be3          	bltu	s6,a5,80002928 <procdump+0x5a>
    80002956:	02079713          	slli	a4,a5,0x20
    8000295a:	01d75793          	srli	a5,a4,0x1d
    8000295e:	97de                	add	a5,a5,s7
    80002960:	6390                	ld	a2,0(a5)
    80002962:	f279                	bnez	a2,80002928 <procdump+0x5a>
            state = "???";
    80002964:	864e                	mv	a2,s3
    80002966:	b7c9                	j	80002928 <procdump+0x5a>
    }
}
    80002968:	60a6                	ld	ra,72(sp)
    8000296a:	6406                	ld	s0,64(sp)
    8000296c:	74e2                	ld	s1,56(sp)
    8000296e:	7942                	ld	s2,48(sp)
    80002970:	79a2                	ld	s3,40(sp)
    80002972:	7a02                	ld	s4,32(sp)
    80002974:	6ae2                	ld	s5,24(sp)
    80002976:	6b42                	ld	s6,16(sp)
    80002978:	6ba2                	ld	s7,8(sp)
    8000297a:	6161                	addi	sp,sp,80
    8000297c:	8082                	ret

000000008000297e <schedls>:

void schedls()
{
    8000297e:	1101                	addi	sp,sp,-32
    80002980:	ec06                	sd	ra,24(sp)
    80002982:	e822                	sd	s0,16(sp)
    80002984:	e426                	sd	s1,8(sp)
    80002986:	1000                	addi	s0,sp,32
    printf("[ ]\tScheduler Name\tScheduler ID\n");
    80002988:	00006517          	auipc	a0,0x6
    8000298c:	91050513          	addi	a0,a0,-1776 # 80008298 <digits+0x258>
    80002990:	ffffe097          	auipc	ra,0xffffe
    80002994:	bfa080e7          	jalr	-1030(ra) # 8000058a <printf>
    printf("====================================\n");
    80002998:	00006517          	auipc	a0,0x6
    8000299c:	92850513          	addi	a0,a0,-1752 # 800082c0 <digits+0x280>
    800029a0:	ffffe097          	auipc	ra,0xffffe
    800029a4:	bea080e7          	jalr	-1046(ra) # 8000058a <printf>
    for (int i = 0; i < SCHEDC; i++)
    {
        if (available_schedulers[i].impl == sched_pointer)
    800029a8:	00006717          	auipc	a4,0x6
    800029ac:	ff073703          	ld	a4,-16(a4) # 80008998 <available_schedulers+0x10>
    800029b0:	00006797          	auipc	a5,0x6
    800029b4:	f887b783          	ld	a5,-120(a5) # 80008938 <sched_pointer>
    800029b8:	08f70763          	beq	a4,a5,80002a46 <schedls+0xc8>
        {
            printf("[*]\t");
        }
        else
        {
            printf("   \t");
    800029bc:	00006517          	auipc	a0,0x6
    800029c0:	92c50513          	addi	a0,a0,-1748 # 800082e8 <digits+0x2a8>
    800029c4:	ffffe097          	auipc	ra,0xffffe
    800029c8:	bc6080e7          	jalr	-1082(ra) # 8000058a <printf>
        }
        printf("%s\t%d\n", available_schedulers[i].name, available_schedulers[i].id);
    800029cc:	00006497          	auipc	s1,0x6
    800029d0:	f8448493          	addi	s1,s1,-124 # 80008950 <initcode>
    800029d4:	48b0                	lw	a2,80(s1)
    800029d6:	00006597          	auipc	a1,0x6
    800029da:	fb258593          	addi	a1,a1,-78 # 80008988 <available_schedulers>
    800029de:	00006517          	auipc	a0,0x6
    800029e2:	91a50513          	addi	a0,a0,-1766 # 800082f8 <digits+0x2b8>
    800029e6:	ffffe097          	auipc	ra,0xffffe
    800029ea:	ba4080e7          	jalr	-1116(ra) # 8000058a <printf>
        if (available_schedulers[i].impl == sched_pointer)
    800029ee:	74b8                	ld	a4,104(s1)
    800029f0:	00006797          	auipc	a5,0x6
    800029f4:	f487b783          	ld	a5,-184(a5) # 80008938 <sched_pointer>
    800029f8:	06f70063          	beq	a4,a5,80002a58 <schedls+0xda>
            printf("   \t");
    800029fc:	00006517          	auipc	a0,0x6
    80002a00:	8ec50513          	addi	a0,a0,-1812 # 800082e8 <digits+0x2a8>
    80002a04:	ffffe097          	auipc	ra,0xffffe
    80002a08:	b86080e7          	jalr	-1146(ra) # 8000058a <printf>
        printf("%s\t%d\n", available_schedulers[i].name, available_schedulers[i].id);
    80002a0c:	00006617          	auipc	a2,0x6
    80002a10:	fb462603          	lw	a2,-76(a2) # 800089c0 <available_schedulers+0x38>
    80002a14:	00006597          	auipc	a1,0x6
    80002a18:	f9458593          	addi	a1,a1,-108 # 800089a8 <available_schedulers+0x20>
    80002a1c:	00006517          	auipc	a0,0x6
    80002a20:	8dc50513          	addi	a0,a0,-1828 # 800082f8 <digits+0x2b8>
    80002a24:	ffffe097          	auipc	ra,0xffffe
    80002a28:	b66080e7          	jalr	-1178(ra) # 8000058a <printf>
    }
    printf("\n*: current scheduler\n\n");
    80002a2c:	00006517          	auipc	a0,0x6
    80002a30:	8d450513          	addi	a0,a0,-1836 # 80008300 <digits+0x2c0>
    80002a34:	ffffe097          	auipc	ra,0xffffe
    80002a38:	b56080e7          	jalr	-1194(ra) # 8000058a <printf>
}
    80002a3c:	60e2                	ld	ra,24(sp)
    80002a3e:	6442                	ld	s0,16(sp)
    80002a40:	64a2                	ld	s1,8(sp)
    80002a42:	6105                	addi	sp,sp,32
    80002a44:	8082                	ret
            printf("[*]\t");
    80002a46:	00006517          	auipc	a0,0x6
    80002a4a:	8aa50513          	addi	a0,a0,-1878 # 800082f0 <digits+0x2b0>
    80002a4e:	ffffe097          	auipc	ra,0xffffe
    80002a52:	b3c080e7          	jalr	-1220(ra) # 8000058a <printf>
    80002a56:	bf9d                	j	800029cc <schedls+0x4e>
    80002a58:	00006517          	auipc	a0,0x6
    80002a5c:	89850513          	addi	a0,a0,-1896 # 800082f0 <digits+0x2b0>
    80002a60:	ffffe097          	auipc	ra,0xffffe
    80002a64:	b2a080e7          	jalr	-1238(ra) # 8000058a <printf>
    80002a68:	b755                	j	80002a0c <schedls+0x8e>

0000000080002a6a <schedset>:

void schedset(int id)
{
    80002a6a:	1141                	addi	sp,sp,-16
    80002a6c:	e406                	sd	ra,8(sp)
    80002a6e:	e022                	sd	s0,0(sp)
    80002a70:	0800                	addi	s0,sp,16
    if (id < 0 || SCHEDC <= id)
    80002a72:	4705                	li	a4,1
    80002a74:	02a76f63          	bltu	a4,a0,80002ab2 <schedset+0x48>
    {
        printf("Scheduler unchanged: ID out of range\n");
        return;
    }
    sched_pointer = available_schedulers[id].impl;
    80002a78:	00551793          	slli	a5,a0,0x5
    80002a7c:	00006717          	auipc	a4,0x6
    80002a80:	ed470713          	addi	a4,a4,-300 # 80008950 <initcode>
    80002a84:	973e                	add	a4,a4,a5
    80002a86:	6738                	ld	a4,72(a4)
    80002a88:	00006697          	auipc	a3,0x6
    80002a8c:	eae6b823          	sd	a4,-336(a3) # 80008938 <sched_pointer>
    printf("Scheduler successfully changed to %s\n", available_schedulers[id].name);
    80002a90:	00006597          	auipc	a1,0x6
    80002a94:	ef858593          	addi	a1,a1,-264 # 80008988 <available_schedulers>
    80002a98:	95be                	add	a1,a1,a5
    80002a9a:	00006517          	auipc	a0,0x6
    80002a9e:	8a650513          	addi	a0,a0,-1882 # 80008340 <digits+0x300>
    80002aa2:	ffffe097          	auipc	ra,0xffffe
    80002aa6:	ae8080e7          	jalr	-1304(ra) # 8000058a <printf>
    80002aaa:	60a2                	ld	ra,8(sp)
    80002aac:	6402                	ld	s0,0(sp)
    80002aae:	0141                	addi	sp,sp,16
    80002ab0:	8082                	ret
        printf("Scheduler unchanged: ID out of range\n");
    80002ab2:	00006517          	auipc	a0,0x6
    80002ab6:	86650513          	addi	a0,a0,-1946 # 80008318 <digits+0x2d8>
    80002aba:	ffffe097          	auipc	ra,0xffffe
    80002abe:	ad0080e7          	jalr	-1328(ra) # 8000058a <printf>
        return;
    80002ac2:	b7e5                	j	80002aaa <schedset+0x40>

0000000080002ac4 <swtch>:
    80002ac4:	00153023          	sd	ra,0(a0)
    80002ac8:	00253423          	sd	sp,8(a0)
    80002acc:	e900                	sd	s0,16(a0)
    80002ace:	ed04                	sd	s1,24(a0)
    80002ad0:	03253023          	sd	s2,32(a0)
    80002ad4:	03353423          	sd	s3,40(a0)
    80002ad8:	03453823          	sd	s4,48(a0)
    80002adc:	03553c23          	sd	s5,56(a0)
    80002ae0:	05653023          	sd	s6,64(a0)
    80002ae4:	05753423          	sd	s7,72(a0)
    80002ae8:	05853823          	sd	s8,80(a0)
    80002aec:	05953c23          	sd	s9,88(a0)
    80002af0:	07a53023          	sd	s10,96(a0)
    80002af4:	07b53423          	sd	s11,104(a0)
    80002af8:	0005b083          	ld	ra,0(a1)
    80002afc:	0085b103          	ld	sp,8(a1)
    80002b00:	6980                	ld	s0,16(a1)
    80002b02:	6d84                	ld	s1,24(a1)
    80002b04:	0205b903          	ld	s2,32(a1)
    80002b08:	0285b983          	ld	s3,40(a1)
    80002b0c:	0305ba03          	ld	s4,48(a1)
    80002b10:	0385ba83          	ld	s5,56(a1)
    80002b14:	0405bb03          	ld	s6,64(a1)
    80002b18:	0485bb83          	ld	s7,72(a1)
    80002b1c:	0505bc03          	ld	s8,80(a1)
    80002b20:	0585bc83          	ld	s9,88(a1)
    80002b24:	0605bd03          	ld	s10,96(a1)
    80002b28:	0685bd83          	ld	s11,104(a1)
    80002b2c:	8082                	ret

0000000080002b2e <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002b2e:	1141                	addi	sp,sp,-16
    80002b30:	e406                	sd	ra,8(sp)
    80002b32:	e022                	sd	s0,0(sp)
    80002b34:	0800                	addi	s0,sp,16
    initlock(&tickslock, "time");
    80002b36:	00006597          	auipc	a1,0x6
    80002b3a:	89258593          	addi	a1,a1,-1902 # 800083c8 <states.0+0x30>
    80002b3e:	00014517          	auipc	a0,0x14
    80002b42:	1c250513          	addi	a0,a0,450 # 80016d00 <tickslock>
    80002b46:	ffffe097          	auipc	ra,0xffffe
    80002b4a:	000080e7          	jalr	ra # 80000b46 <initlock>
}
    80002b4e:	60a2                	ld	ra,8(sp)
    80002b50:	6402                	ld	s0,0(sp)
    80002b52:	0141                	addi	sp,sp,16
    80002b54:	8082                	ret

0000000080002b56 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002b56:	1141                	addi	sp,sp,-16
    80002b58:	e422                	sd	s0,8(sp)
    80002b5a:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b5c:	00003797          	auipc	a5,0x3
    80002b60:	57478793          	addi	a5,a5,1396 # 800060d0 <kernelvec>
    80002b64:	10579073          	csrw	stvec,a5
    w_stvec((uint64)kernelvec);
}
    80002b68:	6422                	ld	s0,8(sp)
    80002b6a:	0141                	addi	sp,sp,16
    80002b6c:	8082                	ret

0000000080002b6e <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002b6e:	1141                	addi	sp,sp,-16
    80002b70:	e406                	sd	ra,8(sp)
    80002b72:	e022                	sd	s0,0(sp)
    80002b74:	0800                	addi	s0,sp,16
    struct proc *p = myproc();
    80002b76:	fffff097          	auipc	ra,0xfffff
    80002b7a:	0d4080e7          	jalr	212(ra) # 80001c4a <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b7e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002b82:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b84:	10079073          	csrw	sstatus,a5
    // kerneltrap() to usertrap(), so turn off interrupts until
    // we're back in user space, where usertrap() is correct.
    intr_off();

    // send syscalls, interrupts, and exceptions to uservec in trampoline.S
    uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002b88:	00004697          	auipc	a3,0x4
    80002b8c:	47868693          	addi	a3,a3,1144 # 80007000 <_trampoline>
    80002b90:	00004717          	auipc	a4,0x4
    80002b94:	47070713          	addi	a4,a4,1136 # 80007000 <_trampoline>
    80002b98:	8f15                	sub	a4,a4,a3
    80002b9a:	040007b7          	lui	a5,0x4000
    80002b9e:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002ba0:	07b2                	slli	a5,a5,0xc
    80002ba2:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ba4:	10571073          	csrw	stvec,a4
    w_stvec(trampoline_uservec);

    // set up trapframe values that uservec will need when
    // the process next traps into the kernel.
    p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002ba8:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002baa:	18002673          	csrr	a2,satp
    80002bae:	e310                	sd	a2,0(a4)
    p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002bb0:	7130                	ld	a2,96(a0)
    80002bb2:	6538                	ld	a4,72(a0)
    80002bb4:	6585                	lui	a1,0x1
    80002bb6:	972e                	add	a4,a4,a1
    80002bb8:	e618                	sd	a4,8(a2)
    p->trapframe->kernel_trap = (uint64)usertrap;
    80002bba:	7138                	ld	a4,96(a0)
    80002bbc:	00000617          	auipc	a2,0x0
    80002bc0:	13060613          	addi	a2,a2,304 # 80002cec <usertrap>
    80002bc4:	eb10                	sd	a2,16(a4)
    p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002bc6:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002bc8:	8612                	mv	a2,tp
    80002bca:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bcc:	10002773          	csrr	a4,sstatus
    // set up the registers that trampoline.S's sret will use
    // to get to user space.

    // set S Previous Privilege mode to User.
    unsigned long x = r_sstatus();
    x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002bd0:	eff77713          	andi	a4,a4,-257
    x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002bd4:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bd8:	10071073          	csrw	sstatus,a4
    w_sstatus(x);

    // set S Exception Program Counter to the saved user pc.
    w_sepc(p->trapframe->epc);
    80002bdc:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002bde:	6f18                	ld	a4,24(a4)
    80002be0:	14171073          	csrw	sepc,a4

    // tell trampoline.S the user page table to switch to.
    uint64 satp = MAKE_SATP(p->pagetable);
    80002be4:	6d28                	ld	a0,88(a0)
    80002be6:	8131                	srli	a0,a0,0xc

    // jump to userret in trampoline.S at the top of memory, which
    // switches to the user page table, restores user registers,
    // and switches to user mode with sret.
    uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002be8:	00004717          	auipc	a4,0x4
    80002bec:	4b470713          	addi	a4,a4,1204 # 8000709c <userret>
    80002bf0:	8f15                	sub	a4,a4,a3
    80002bf2:	97ba                	add	a5,a5,a4
    ((void (*)(uint64))trampoline_userret)(satp);
    80002bf4:	577d                	li	a4,-1
    80002bf6:	177e                	slli	a4,a4,0x3f
    80002bf8:	8d59                	or	a0,a0,a4
    80002bfa:	9782                	jalr	a5
}
    80002bfc:	60a2                	ld	ra,8(sp)
    80002bfe:	6402                	ld	s0,0(sp)
    80002c00:	0141                	addi	sp,sp,16
    80002c02:	8082                	ret

0000000080002c04 <clockintr>:
    w_sepc(sepc);
    w_sstatus(sstatus);
}

void clockintr()
{
    80002c04:	1101                	addi	sp,sp,-32
    80002c06:	ec06                	sd	ra,24(sp)
    80002c08:	e822                	sd	s0,16(sp)
    80002c0a:	e426                	sd	s1,8(sp)
    80002c0c:	1000                	addi	s0,sp,32
    acquire(&tickslock);
    80002c0e:	00014497          	auipc	s1,0x14
    80002c12:	0f248493          	addi	s1,s1,242 # 80016d00 <tickslock>
    80002c16:	8526                	mv	a0,s1
    80002c18:	ffffe097          	auipc	ra,0xffffe
    80002c1c:	fbe080e7          	jalr	-66(ra) # 80000bd6 <acquire>
    ticks++;
    80002c20:	00006517          	auipc	a0,0x6
    80002c24:	e0050513          	addi	a0,a0,-512 # 80008a20 <ticks>
    80002c28:	411c                	lw	a5,0(a0)
    80002c2a:	2785                	addiw	a5,a5,1
    80002c2c:	c11c                	sw	a5,0(a0)
    wakeup(&ticks);
    80002c2e:	00000097          	auipc	ra,0x0
    80002c32:	850080e7          	jalr	-1968(ra) # 8000247e <wakeup>
    release(&tickslock);
    80002c36:	8526                	mv	a0,s1
    80002c38:	ffffe097          	auipc	ra,0xffffe
    80002c3c:	052080e7          	jalr	82(ra) # 80000c8a <release>
}
    80002c40:	60e2                	ld	ra,24(sp)
    80002c42:	6442                	ld	s0,16(sp)
    80002c44:	64a2                	ld	s1,8(sp)
    80002c46:	6105                	addi	sp,sp,32
    80002c48:	8082                	ret

0000000080002c4a <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002c4a:	1101                	addi	sp,sp,-32
    80002c4c:	ec06                	sd	ra,24(sp)
    80002c4e:	e822                	sd	s0,16(sp)
    80002c50:	e426                	sd	s1,8(sp)
    80002c52:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c54:	14202773          	csrr	a4,scause
    uint64 scause = r_scause();

    if ((scause & 0x8000000000000000L) &&
    80002c58:	00074d63          	bltz	a4,80002c72 <devintr+0x28>
        if (irq)
            plic_complete(irq);

        return 1;
    }
    else if (scause == 0x8000000000000001L)
    80002c5c:	57fd                	li	a5,-1
    80002c5e:	17fe                	slli	a5,a5,0x3f
    80002c60:	0785                	addi	a5,a5,1

        return 2;
    }
    else
    {
        return 0;
    80002c62:	4501                	li	a0,0
    else if (scause == 0x8000000000000001L)
    80002c64:	06f70363          	beq	a4,a5,80002cca <devintr+0x80>
    }
}
    80002c68:	60e2                	ld	ra,24(sp)
    80002c6a:	6442                	ld	s0,16(sp)
    80002c6c:	64a2                	ld	s1,8(sp)
    80002c6e:	6105                	addi	sp,sp,32
    80002c70:	8082                	ret
        (scause & 0xff) == 9)
    80002c72:	0ff77793          	zext.b	a5,a4
    if ((scause & 0x8000000000000000L) &&
    80002c76:	46a5                	li	a3,9
    80002c78:	fed792e3          	bne	a5,a3,80002c5c <devintr+0x12>
        int irq = plic_claim();
    80002c7c:	00003097          	auipc	ra,0x3
    80002c80:	55c080e7          	jalr	1372(ra) # 800061d8 <plic_claim>
    80002c84:	84aa                	mv	s1,a0
        if (irq == UART0_IRQ)
    80002c86:	47a9                	li	a5,10
    80002c88:	02f50763          	beq	a0,a5,80002cb6 <devintr+0x6c>
        else if (irq == VIRTIO0_IRQ)
    80002c8c:	4785                	li	a5,1
    80002c8e:	02f50963          	beq	a0,a5,80002cc0 <devintr+0x76>
        return 1;
    80002c92:	4505                	li	a0,1
        else if (irq)
    80002c94:	d8f1                	beqz	s1,80002c68 <devintr+0x1e>
            printf("unexpected interrupt irq=%d\n", irq);
    80002c96:	85a6                	mv	a1,s1
    80002c98:	00005517          	auipc	a0,0x5
    80002c9c:	73850513          	addi	a0,a0,1848 # 800083d0 <states.0+0x38>
    80002ca0:	ffffe097          	auipc	ra,0xffffe
    80002ca4:	8ea080e7          	jalr	-1814(ra) # 8000058a <printf>
            plic_complete(irq);
    80002ca8:	8526                	mv	a0,s1
    80002caa:	00003097          	auipc	ra,0x3
    80002cae:	552080e7          	jalr	1362(ra) # 800061fc <plic_complete>
        return 1;
    80002cb2:	4505                	li	a0,1
    80002cb4:	bf55                	j	80002c68 <devintr+0x1e>
            uartintr();
    80002cb6:	ffffe097          	auipc	ra,0xffffe
    80002cba:	ce2080e7          	jalr	-798(ra) # 80000998 <uartintr>
    80002cbe:	b7ed                	j	80002ca8 <devintr+0x5e>
            virtio_disk_intr();
    80002cc0:	00004097          	auipc	ra,0x4
    80002cc4:	a04080e7          	jalr	-1532(ra) # 800066c4 <virtio_disk_intr>
    80002cc8:	b7c5                	j	80002ca8 <devintr+0x5e>
        if (cpuid() == 0)
    80002cca:	fffff097          	auipc	ra,0xfffff
    80002cce:	f4e080e7          	jalr	-178(ra) # 80001c18 <cpuid>
    80002cd2:	c901                	beqz	a0,80002ce2 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002cd4:	144027f3          	csrr	a5,sip
        w_sip(r_sip() & ~2);
    80002cd8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002cda:	14479073          	csrw	sip,a5
        return 2;
    80002cde:	4509                	li	a0,2
    80002ce0:	b761                	j	80002c68 <devintr+0x1e>
            clockintr();
    80002ce2:	00000097          	auipc	ra,0x0
    80002ce6:	f22080e7          	jalr	-222(ra) # 80002c04 <clockintr>
    80002cea:	b7ed                	j	80002cd4 <devintr+0x8a>

0000000080002cec <usertrap>:
{
    80002cec:	1101                	addi	sp,sp,-32
    80002cee:	ec06                	sd	ra,24(sp)
    80002cf0:	e822                	sd	s0,16(sp)
    80002cf2:	e426                	sd	s1,8(sp)
    80002cf4:	e04a                	sd	s2,0(sp)
    80002cf6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cf8:	100027f3          	csrr	a5,sstatus
    if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002cfc:	1007f793          	andi	a5,a5,256
    80002d00:	e3b1                	bnez	a5,80002d44 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d02:	00003797          	auipc	a5,0x3
    80002d06:	3ce78793          	addi	a5,a5,974 # 800060d0 <kernelvec>
    80002d0a:	10579073          	csrw	stvec,a5
    struct proc *p = myproc();
    80002d0e:	fffff097          	auipc	ra,0xfffff
    80002d12:	f3c080e7          	jalr	-196(ra) # 80001c4a <myproc>
    80002d16:	84aa                	mv	s1,a0
    p->trapframe->epc = r_sepc();
    80002d18:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d1a:	14102773          	csrr	a4,sepc
    80002d1e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d20:	14202773          	csrr	a4,scause
    if (r_scause() == 8)
    80002d24:	47a1                	li	a5,8
    80002d26:	02f70763          	beq	a4,a5,80002d54 <usertrap+0x68>
    else if ((which_dev = devintr()) != 0)
    80002d2a:	00000097          	auipc	ra,0x0
    80002d2e:	f20080e7          	jalr	-224(ra) # 80002c4a <devintr>
    80002d32:	892a                	mv	s2,a0
    80002d34:	c151                	beqz	a0,80002db8 <usertrap+0xcc>
    if (killed(p))
    80002d36:	8526                	mv	a0,s1
    80002d38:	00000097          	auipc	ra,0x0
    80002d3c:	98a080e7          	jalr	-1654(ra) # 800026c2 <killed>
    80002d40:	c929                	beqz	a0,80002d92 <usertrap+0xa6>
    80002d42:	a099                	j	80002d88 <usertrap+0x9c>
        panic("usertrap: not from user mode");
    80002d44:	00005517          	auipc	a0,0x5
    80002d48:	6ac50513          	addi	a0,a0,1708 # 800083f0 <states.0+0x58>
    80002d4c:	ffffd097          	auipc	ra,0xffffd
    80002d50:	7f4080e7          	jalr	2036(ra) # 80000540 <panic>
        if (killed(p))
    80002d54:	00000097          	auipc	ra,0x0
    80002d58:	96e080e7          	jalr	-1682(ra) # 800026c2 <killed>
    80002d5c:	e921                	bnez	a0,80002dac <usertrap+0xc0>
        p->trapframe->epc += 4;
    80002d5e:	70b8                	ld	a4,96(s1)
    80002d60:	6f1c                	ld	a5,24(a4)
    80002d62:	0791                	addi	a5,a5,4
    80002d64:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d66:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002d6a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d6e:	10079073          	csrw	sstatus,a5
        syscall();
    80002d72:	00000097          	auipc	ra,0x0
    80002d76:	2dc080e7          	jalr	732(ra) # 8000304e <syscall>
    if (killed(p))
    80002d7a:	8526                	mv	a0,s1
    80002d7c:	00000097          	auipc	ra,0x0
    80002d80:	946080e7          	jalr	-1722(ra) # 800026c2 <killed>
    80002d84:	c911                	beqz	a0,80002d98 <usertrap+0xac>
    80002d86:	4901                	li	s2,0
        exit(-1);
    80002d88:	557d                	li	a0,-1
    80002d8a:	fffff097          	auipc	ra,0xfffff
    80002d8e:	7c4080e7          	jalr	1988(ra) # 8000254e <exit>
    if (which_dev == 2) {
    80002d92:	4789                	li	a5,2
    80002d94:	04f90f63          	beq	s2,a5,80002df2 <usertrap+0x106>
    usertrapret();
    80002d98:	00000097          	auipc	ra,0x0
    80002d9c:	dd6080e7          	jalr	-554(ra) # 80002b6e <usertrapret>
}
    80002da0:	60e2                	ld	ra,24(sp)
    80002da2:	6442                	ld	s0,16(sp)
    80002da4:	64a2                	ld	s1,8(sp)
    80002da6:	6902                	ld	s2,0(sp)
    80002da8:	6105                	addi	sp,sp,32
    80002daa:	8082                	ret
            exit(-1);
    80002dac:	557d                	li	a0,-1
    80002dae:	fffff097          	auipc	ra,0xfffff
    80002db2:	7a0080e7          	jalr	1952(ra) # 8000254e <exit>
    80002db6:	b765                	j	80002d5e <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002db8:	142025f3          	csrr	a1,scause
        printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002dbc:	5890                	lw	a2,48(s1)
    80002dbe:	00005517          	auipc	a0,0x5
    80002dc2:	65250513          	addi	a0,a0,1618 # 80008410 <states.0+0x78>
    80002dc6:	ffffd097          	auipc	ra,0xffffd
    80002dca:	7c4080e7          	jalr	1988(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002dce:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002dd2:	14302673          	csrr	a2,stval
        printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002dd6:	00005517          	auipc	a0,0x5
    80002dda:	66a50513          	addi	a0,a0,1642 # 80008440 <states.0+0xa8>
    80002dde:	ffffd097          	auipc	ra,0xffffd
    80002de2:	7ac080e7          	jalr	1964(ra) # 8000058a <printf>
        setkilled(p);
    80002de6:	8526                	mv	a0,s1
    80002de8:	00000097          	auipc	ra,0x0
    80002dec:	8ae080e7          	jalr	-1874(ra) # 80002696 <setkilled>
    80002df0:	b769                	j	80002d7a <usertrap+0x8e>
        p->priority = 1;
    80002df2:	4785                	li	a5,1
    80002df4:	d8dc                	sw	a5,52(s1)
        yield(YIELD_TIMER);
    80002df6:	4505                	li	a0,1
    80002df8:	fffff097          	auipc	ra,0xfffff
    80002dfc:	5e6080e7          	jalr	1510(ra) # 800023de <yield>
    80002e00:	bf61                	j	80002d98 <usertrap+0xac>

0000000080002e02 <kerneltrap>:
{
    80002e02:	7179                	addi	sp,sp,-48
    80002e04:	f406                	sd	ra,40(sp)
    80002e06:	f022                	sd	s0,32(sp)
    80002e08:	ec26                	sd	s1,24(sp)
    80002e0a:	e84a                	sd	s2,16(sp)
    80002e0c:	e44e                	sd	s3,8(sp)
    80002e0e:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e10:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e14:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e18:	142029f3          	csrr	s3,scause
    if ((sstatus & SSTATUS_SPP) == 0)
    80002e1c:	1004f793          	andi	a5,s1,256
    80002e20:	cb85                	beqz	a5,80002e50 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e22:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002e26:	8b89                	andi	a5,a5,2
    if (intr_get() != 0)
    80002e28:	ef85                	bnez	a5,80002e60 <kerneltrap+0x5e>
    if ((which_dev = devintr()) == 0)
    80002e2a:	00000097          	auipc	ra,0x0
    80002e2e:	e20080e7          	jalr	-480(ra) # 80002c4a <devintr>
    80002e32:	cd1d                	beqz	a0,80002e70 <kerneltrap+0x6e>
    if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e34:	4789                	li	a5,2
    80002e36:	06f50a63          	beq	a0,a5,80002eaa <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002e3a:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e3e:	10049073          	csrw	sstatus,s1
}
    80002e42:	70a2                	ld	ra,40(sp)
    80002e44:	7402                	ld	s0,32(sp)
    80002e46:	64e2                	ld	s1,24(sp)
    80002e48:	6942                	ld	s2,16(sp)
    80002e4a:	69a2                	ld	s3,8(sp)
    80002e4c:	6145                	addi	sp,sp,48
    80002e4e:	8082                	ret
        panic("kerneltrap: not from supervisor mode");
    80002e50:	00005517          	auipc	a0,0x5
    80002e54:	61050513          	addi	a0,a0,1552 # 80008460 <states.0+0xc8>
    80002e58:	ffffd097          	auipc	ra,0xffffd
    80002e5c:	6e8080e7          	jalr	1768(ra) # 80000540 <panic>
        panic("kerneltrap: interrupts enabled");
    80002e60:	00005517          	auipc	a0,0x5
    80002e64:	62850513          	addi	a0,a0,1576 # 80008488 <states.0+0xf0>
    80002e68:	ffffd097          	auipc	ra,0xffffd
    80002e6c:	6d8080e7          	jalr	1752(ra) # 80000540 <panic>
        printf("scause %p\n", scause);
    80002e70:	85ce                	mv	a1,s3
    80002e72:	00005517          	auipc	a0,0x5
    80002e76:	63650513          	addi	a0,a0,1590 # 800084a8 <states.0+0x110>
    80002e7a:	ffffd097          	auipc	ra,0xffffd
    80002e7e:	710080e7          	jalr	1808(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e82:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e86:	14302673          	csrr	a2,stval
        printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e8a:	00005517          	auipc	a0,0x5
    80002e8e:	62e50513          	addi	a0,a0,1582 # 800084b8 <states.0+0x120>
    80002e92:	ffffd097          	auipc	ra,0xffffd
    80002e96:	6f8080e7          	jalr	1784(ra) # 8000058a <printf>
        panic("kerneltrap");
    80002e9a:	00005517          	auipc	a0,0x5
    80002e9e:	63650513          	addi	a0,a0,1590 # 800084d0 <states.0+0x138>
    80002ea2:	ffffd097          	auipc	ra,0xffffd
    80002ea6:	69e080e7          	jalr	1694(ra) # 80000540 <panic>
    if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002eaa:	fffff097          	auipc	ra,0xfffff
    80002eae:	da0080e7          	jalr	-608(ra) # 80001c4a <myproc>
    80002eb2:	d541                	beqz	a0,80002e3a <kerneltrap+0x38>
    80002eb4:	fffff097          	auipc	ra,0xfffff
    80002eb8:	d96080e7          	jalr	-618(ra) # 80001c4a <myproc>
    80002ebc:	4d18                	lw	a4,24(a0)
    80002ebe:	4791                	li	a5,4
    80002ec0:	f6f71de3          	bne	a4,a5,80002e3a <kerneltrap+0x38>
        yield(YIELD_OTHER);
    80002ec4:	4509                	li	a0,2
    80002ec6:	fffff097          	auipc	ra,0xfffff
    80002eca:	518080e7          	jalr	1304(ra) # 800023de <yield>
    80002ece:	b7b5                	j	80002e3a <kerneltrap+0x38>

0000000080002ed0 <argraw>:
    return strlen(buf);
}

static uint64
argraw(int n)
{
    80002ed0:	1101                	addi	sp,sp,-32
    80002ed2:	ec06                	sd	ra,24(sp)
    80002ed4:	e822                	sd	s0,16(sp)
    80002ed6:	e426                	sd	s1,8(sp)
    80002ed8:	1000                	addi	s0,sp,32
    80002eda:	84aa                	mv	s1,a0
    struct proc *p = myproc();
    80002edc:	fffff097          	auipc	ra,0xfffff
    80002ee0:	d6e080e7          	jalr	-658(ra) # 80001c4a <myproc>
    switch (n)
    80002ee4:	4795                	li	a5,5
    80002ee6:	0497e163          	bltu	a5,s1,80002f28 <argraw+0x58>
    80002eea:	048a                	slli	s1,s1,0x2
    80002eec:	00005717          	auipc	a4,0x5
    80002ef0:	61c70713          	addi	a4,a4,1564 # 80008508 <states.0+0x170>
    80002ef4:	94ba                	add	s1,s1,a4
    80002ef6:	409c                	lw	a5,0(s1)
    80002ef8:	97ba                	add	a5,a5,a4
    80002efa:	8782                	jr	a5
    {
    case 0:
        return p->trapframe->a0;
    80002efc:	713c                	ld	a5,96(a0)
    80002efe:	7ba8                	ld	a0,112(a5)
    case 5:
        return p->trapframe->a5;
    }
    panic("argraw");
    return -1;
}
    80002f00:	60e2                	ld	ra,24(sp)
    80002f02:	6442                	ld	s0,16(sp)
    80002f04:	64a2                	ld	s1,8(sp)
    80002f06:	6105                	addi	sp,sp,32
    80002f08:	8082                	ret
        return p->trapframe->a1;
    80002f0a:	713c                	ld	a5,96(a0)
    80002f0c:	7fa8                	ld	a0,120(a5)
    80002f0e:	bfcd                	j	80002f00 <argraw+0x30>
        return p->trapframe->a2;
    80002f10:	713c                	ld	a5,96(a0)
    80002f12:	63c8                	ld	a0,128(a5)
    80002f14:	b7f5                	j	80002f00 <argraw+0x30>
        return p->trapframe->a3;
    80002f16:	713c                	ld	a5,96(a0)
    80002f18:	67c8                	ld	a0,136(a5)
    80002f1a:	b7dd                	j	80002f00 <argraw+0x30>
        return p->trapframe->a4;
    80002f1c:	713c                	ld	a5,96(a0)
    80002f1e:	6bc8                	ld	a0,144(a5)
    80002f20:	b7c5                	j	80002f00 <argraw+0x30>
        return p->trapframe->a5;
    80002f22:	713c                	ld	a5,96(a0)
    80002f24:	6fc8                	ld	a0,152(a5)
    80002f26:	bfe9                	j	80002f00 <argraw+0x30>
    panic("argraw");
    80002f28:	00005517          	auipc	a0,0x5
    80002f2c:	5b850513          	addi	a0,a0,1464 # 800084e0 <states.0+0x148>
    80002f30:	ffffd097          	auipc	ra,0xffffd
    80002f34:	610080e7          	jalr	1552(ra) # 80000540 <panic>

0000000080002f38 <fetchaddr>:
{
    80002f38:	1101                	addi	sp,sp,-32
    80002f3a:	ec06                	sd	ra,24(sp)
    80002f3c:	e822                	sd	s0,16(sp)
    80002f3e:	e426                	sd	s1,8(sp)
    80002f40:	e04a                	sd	s2,0(sp)
    80002f42:	1000                	addi	s0,sp,32
    80002f44:	84aa                	mv	s1,a0
    80002f46:	892e                	mv	s2,a1
    struct proc *p = myproc();
    80002f48:	fffff097          	auipc	ra,0xfffff
    80002f4c:	d02080e7          	jalr	-766(ra) # 80001c4a <myproc>
    if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002f50:	693c                	ld	a5,80(a0)
    80002f52:	02f4f863          	bgeu	s1,a5,80002f82 <fetchaddr+0x4a>
    80002f56:	00848713          	addi	a4,s1,8
    80002f5a:	02e7e663          	bltu	a5,a4,80002f86 <fetchaddr+0x4e>
    if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002f5e:	46a1                	li	a3,8
    80002f60:	8626                	mv	a2,s1
    80002f62:	85ca                	mv	a1,s2
    80002f64:	6d28                	ld	a0,88(a0)
    80002f66:	ffffe097          	auipc	ra,0xffffe
    80002f6a:	792080e7          	jalr	1938(ra) # 800016f8 <copyin>
    80002f6e:	00a03533          	snez	a0,a0
    80002f72:	40a00533          	neg	a0,a0
}
    80002f76:	60e2                	ld	ra,24(sp)
    80002f78:	6442                	ld	s0,16(sp)
    80002f7a:	64a2                	ld	s1,8(sp)
    80002f7c:	6902                	ld	s2,0(sp)
    80002f7e:	6105                	addi	sp,sp,32
    80002f80:	8082                	ret
        return -1;
    80002f82:	557d                	li	a0,-1
    80002f84:	bfcd                	j	80002f76 <fetchaddr+0x3e>
    80002f86:	557d                	li	a0,-1
    80002f88:	b7fd                	j	80002f76 <fetchaddr+0x3e>

0000000080002f8a <fetchstr>:
{
    80002f8a:	7179                	addi	sp,sp,-48
    80002f8c:	f406                	sd	ra,40(sp)
    80002f8e:	f022                	sd	s0,32(sp)
    80002f90:	ec26                	sd	s1,24(sp)
    80002f92:	e84a                	sd	s2,16(sp)
    80002f94:	e44e                	sd	s3,8(sp)
    80002f96:	1800                	addi	s0,sp,48
    80002f98:	892a                	mv	s2,a0
    80002f9a:	84ae                	mv	s1,a1
    80002f9c:	89b2                	mv	s3,a2
    struct proc *p = myproc();
    80002f9e:	fffff097          	auipc	ra,0xfffff
    80002fa2:	cac080e7          	jalr	-852(ra) # 80001c4a <myproc>
    if (copyinstr(p->pagetable, buf, addr, max) < 0)
    80002fa6:	86ce                	mv	a3,s3
    80002fa8:	864a                	mv	a2,s2
    80002faa:	85a6                	mv	a1,s1
    80002fac:	6d28                	ld	a0,88(a0)
    80002fae:	ffffe097          	auipc	ra,0xffffe
    80002fb2:	7d8080e7          	jalr	2008(ra) # 80001786 <copyinstr>
    80002fb6:	00054e63          	bltz	a0,80002fd2 <fetchstr+0x48>
    return strlen(buf);
    80002fba:	8526                	mv	a0,s1
    80002fbc:	ffffe097          	auipc	ra,0xffffe
    80002fc0:	e92080e7          	jalr	-366(ra) # 80000e4e <strlen>
}
    80002fc4:	70a2                	ld	ra,40(sp)
    80002fc6:	7402                	ld	s0,32(sp)
    80002fc8:	64e2                	ld	s1,24(sp)
    80002fca:	6942                	ld	s2,16(sp)
    80002fcc:	69a2                	ld	s3,8(sp)
    80002fce:	6145                	addi	sp,sp,48
    80002fd0:	8082                	ret
        return -1;
    80002fd2:	557d                	li	a0,-1
    80002fd4:	bfc5                	j	80002fc4 <fetchstr+0x3a>

0000000080002fd6 <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    80002fd6:	1101                	addi	sp,sp,-32
    80002fd8:	ec06                	sd	ra,24(sp)
    80002fda:	e822                	sd	s0,16(sp)
    80002fdc:	e426                	sd	s1,8(sp)
    80002fde:	1000                	addi	s0,sp,32
    80002fe0:	84ae                	mv	s1,a1
    *ip = argraw(n);
    80002fe2:	00000097          	auipc	ra,0x0
    80002fe6:	eee080e7          	jalr	-274(ra) # 80002ed0 <argraw>
    80002fea:	c088                	sw	a0,0(s1)
}
    80002fec:	60e2                	ld	ra,24(sp)
    80002fee:	6442                	ld	s0,16(sp)
    80002ff0:	64a2                	ld	s1,8(sp)
    80002ff2:	6105                	addi	sp,sp,32
    80002ff4:	8082                	ret

0000000080002ff6 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    80002ff6:	1101                	addi	sp,sp,-32
    80002ff8:	ec06                	sd	ra,24(sp)
    80002ffa:	e822                	sd	s0,16(sp)
    80002ffc:	e426                	sd	s1,8(sp)
    80002ffe:	1000                	addi	s0,sp,32
    80003000:	84ae                	mv	s1,a1
    *ip = argraw(n);
    80003002:	00000097          	auipc	ra,0x0
    80003006:	ece080e7          	jalr	-306(ra) # 80002ed0 <argraw>
    8000300a:	e088                	sd	a0,0(s1)
}
    8000300c:	60e2                	ld	ra,24(sp)
    8000300e:	6442                	ld	s0,16(sp)
    80003010:	64a2                	ld	s1,8(sp)
    80003012:	6105                	addi	sp,sp,32
    80003014:	8082                	ret

0000000080003016 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80003016:	7179                	addi	sp,sp,-48
    80003018:	f406                	sd	ra,40(sp)
    8000301a:	f022                	sd	s0,32(sp)
    8000301c:	ec26                	sd	s1,24(sp)
    8000301e:	e84a                	sd	s2,16(sp)
    80003020:	1800                	addi	s0,sp,48
    80003022:	84ae                	mv	s1,a1
    80003024:	8932                	mv	s2,a2
    uint64 addr;
    argaddr(n, &addr);
    80003026:	fd840593          	addi	a1,s0,-40
    8000302a:	00000097          	auipc	ra,0x0
    8000302e:	fcc080e7          	jalr	-52(ra) # 80002ff6 <argaddr>
    return fetchstr(addr, buf, max);
    80003032:	864a                	mv	a2,s2
    80003034:	85a6                	mv	a1,s1
    80003036:	fd843503          	ld	a0,-40(s0)
    8000303a:	00000097          	auipc	ra,0x0
    8000303e:	f50080e7          	jalr	-176(ra) # 80002f8a <fetchstr>
}
    80003042:	70a2                	ld	ra,40(sp)
    80003044:	7402                	ld	s0,32(sp)
    80003046:	64e2                	ld	s1,24(sp)
    80003048:	6942                	ld	s2,16(sp)
    8000304a:	6145                	addi	sp,sp,48
    8000304c:	8082                	ret

000000008000304e <syscall>:
    [SYS_schedset] sys_schedset,
    [SYS_yield] sys_yield,
};

void syscall(void)
{
    8000304e:	1101                	addi	sp,sp,-32
    80003050:	ec06                	sd	ra,24(sp)
    80003052:	e822                	sd	s0,16(sp)
    80003054:	e426                	sd	s1,8(sp)
    80003056:	e04a                	sd	s2,0(sp)
    80003058:	1000                	addi	s0,sp,32
    int num;
    struct proc *p = myproc();
    8000305a:	fffff097          	auipc	ra,0xfffff
    8000305e:	bf0080e7          	jalr	-1040(ra) # 80001c4a <myproc>
    80003062:	84aa                	mv	s1,a0

    num = p->trapframe->a7;
    80003064:	06053903          	ld	s2,96(a0)
    80003068:	0a893783          	ld	a5,168(s2)
    8000306c:	0007869b          	sext.w	a3,a5
    if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80003070:	37fd                	addiw	a5,a5,-1
    80003072:	4761                	li	a4,24
    80003074:	00f76f63          	bltu	a4,a5,80003092 <syscall+0x44>
    80003078:	00369713          	slli	a4,a3,0x3
    8000307c:	00005797          	auipc	a5,0x5
    80003080:	4a478793          	addi	a5,a5,1188 # 80008520 <syscalls>
    80003084:	97ba                	add	a5,a5,a4
    80003086:	639c                	ld	a5,0(a5)
    80003088:	c789                	beqz	a5,80003092 <syscall+0x44>
    {
        // Use num to lookup the system call function for num, call it,
        // and store its return value in p->trapframe->a0
        p->trapframe->a0 = syscalls[num]();
    8000308a:	9782                	jalr	a5
    8000308c:	06a93823          	sd	a0,112(s2)
    80003090:	a839                	j	800030ae <syscall+0x60>
    }
    else
    {
        printf("%d %s: unknown sys call %d\n",
    80003092:	16048613          	addi	a2,s1,352
    80003096:	588c                	lw	a1,48(s1)
    80003098:	00005517          	auipc	a0,0x5
    8000309c:	45050513          	addi	a0,a0,1104 # 800084e8 <states.0+0x150>
    800030a0:	ffffd097          	auipc	ra,0xffffd
    800030a4:	4ea080e7          	jalr	1258(ra) # 8000058a <printf>
               p->pid, p->name, num);
        p->trapframe->a0 = -1;
    800030a8:	70bc                	ld	a5,96(s1)
    800030aa:	577d                	li	a4,-1
    800030ac:	fbb8                	sd	a4,112(a5)
    }
}
    800030ae:	60e2                	ld	ra,24(sp)
    800030b0:	6442                	ld	s0,16(sp)
    800030b2:	64a2                	ld	s1,8(sp)
    800030b4:	6902                	ld	s2,0(sp)
    800030b6:	6105                	addi	sp,sp,32
    800030b8:	8082                	ret

00000000800030ba <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800030ba:	1101                	addi	sp,sp,-32
    800030bc:	ec06                	sd	ra,24(sp)
    800030be:	e822                	sd	s0,16(sp)
    800030c0:	1000                	addi	s0,sp,32
    int n;
    argint(0, &n);
    800030c2:	fec40593          	addi	a1,s0,-20
    800030c6:	4501                	li	a0,0
    800030c8:	00000097          	auipc	ra,0x0
    800030cc:	f0e080e7          	jalr	-242(ra) # 80002fd6 <argint>
    exit(n);
    800030d0:	fec42503          	lw	a0,-20(s0)
    800030d4:	fffff097          	auipc	ra,0xfffff
    800030d8:	47a080e7          	jalr	1146(ra) # 8000254e <exit>
    return 0; // not reached
}
    800030dc:	4501                	li	a0,0
    800030de:	60e2                	ld	ra,24(sp)
    800030e0:	6442                	ld	s0,16(sp)
    800030e2:	6105                	addi	sp,sp,32
    800030e4:	8082                	ret

00000000800030e6 <sys_getpid>:

uint64
sys_getpid(void)
{
    800030e6:	1141                	addi	sp,sp,-16
    800030e8:	e406                	sd	ra,8(sp)
    800030ea:	e022                	sd	s0,0(sp)
    800030ec:	0800                	addi	s0,sp,16
    return myproc()->pid;
    800030ee:	fffff097          	auipc	ra,0xfffff
    800030f2:	b5c080e7          	jalr	-1188(ra) # 80001c4a <myproc>
}
    800030f6:	5908                	lw	a0,48(a0)
    800030f8:	60a2                	ld	ra,8(sp)
    800030fa:	6402                	ld	s0,0(sp)
    800030fc:	0141                	addi	sp,sp,16
    800030fe:	8082                	ret

0000000080003100 <sys_fork>:

uint64
sys_fork(void)
{
    80003100:	1141                	addi	sp,sp,-16
    80003102:	e406                	sd	ra,8(sp)
    80003104:	e022                	sd	s0,0(sp)
    80003106:	0800                	addi	s0,sp,16
    return fork();
    80003108:	fffff097          	auipc	ra,0xfffff
    8000310c:	098080e7          	jalr	152(ra) # 800021a0 <fork>
}
    80003110:	60a2                	ld	ra,8(sp)
    80003112:	6402                	ld	s0,0(sp)
    80003114:	0141                	addi	sp,sp,16
    80003116:	8082                	ret

0000000080003118 <sys_wait>:

uint64
sys_wait(void)
{
    80003118:	1101                	addi	sp,sp,-32
    8000311a:	ec06                	sd	ra,24(sp)
    8000311c:	e822                	sd	s0,16(sp)
    8000311e:	1000                	addi	s0,sp,32
    uint64 p;
    argaddr(0, &p);
    80003120:	fe840593          	addi	a1,s0,-24
    80003124:	4501                	li	a0,0
    80003126:	00000097          	auipc	ra,0x0
    8000312a:	ed0080e7          	jalr	-304(ra) # 80002ff6 <argaddr>
    return wait(p);
    8000312e:	fe843503          	ld	a0,-24(s0)
    80003132:	fffff097          	auipc	ra,0xfffff
    80003136:	5c2080e7          	jalr	1474(ra) # 800026f4 <wait>
}
    8000313a:	60e2                	ld	ra,24(sp)
    8000313c:	6442                	ld	s0,16(sp)
    8000313e:	6105                	addi	sp,sp,32
    80003140:	8082                	ret

0000000080003142 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003142:	7179                	addi	sp,sp,-48
    80003144:	f406                	sd	ra,40(sp)
    80003146:	f022                	sd	s0,32(sp)
    80003148:	ec26                	sd	s1,24(sp)
    8000314a:	1800                	addi	s0,sp,48
    uint64 addr;
    int n;

    argint(0, &n);
    8000314c:	fdc40593          	addi	a1,s0,-36
    80003150:	4501                	li	a0,0
    80003152:	00000097          	auipc	ra,0x0
    80003156:	e84080e7          	jalr	-380(ra) # 80002fd6 <argint>
    addr = myproc()->sz;
    8000315a:	fffff097          	auipc	ra,0xfffff
    8000315e:	af0080e7          	jalr	-1296(ra) # 80001c4a <myproc>
    80003162:	6924                	ld	s1,80(a0)
    if (growproc(n) < 0)
    80003164:	fdc42503          	lw	a0,-36(s0)
    80003168:	fffff097          	auipc	ra,0xfffff
    8000316c:	e46080e7          	jalr	-442(ra) # 80001fae <growproc>
    80003170:	00054863          	bltz	a0,80003180 <sys_sbrk+0x3e>
        return -1;
    return addr;
}
    80003174:	8526                	mv	a0,s1
    80003176:	70a2                	ld	ra,40(sp)
    80003178:	7402                	ld	s0,32(sp)
    8000317a:	64e2                	ld	s1,24(sp)
    8000317c:	6145                	addi	sp,sp,48
    8000317e:	8082                	ret
        return -1;
    80003180:	54fd                	li	s1,-1
    80003182:	bfcd                	j	80003174 <sys_sbrk+0x32>

0000000080003184 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003184:	7139                	addi	sp,sp,-64
    80003186:	fc06                	sd	ra,56(sp)
    80003188:	f822                	sd	s0,48(sp)
    8000318a:	f426                	sd	s1,40(sp)
    8000318c:	f04a                	sd	s2,32(sp)
    8000318e:	ec4e                	sd	s3,24(sp)
    80003190:	0080                	addi	s0,sp,64
    int n;
    uint ticks0;

    argint(0, &n);
    80003192:	fcc40593          	addi	a1,s0,-52
    80003196:	4501                	li	a0,0
    80003198:	00000097          	auipc	ra,0x0
    8000319c:	e3e080e7          	jalr	-450(ra) # 80002fd6 <argint>
    acquire(&tickslock);
    800031a0:	00014517          	auipc	a0,0x14
    800031a4:	b6050513          	addi	a0,a0,-1184 # 80016d00 <tickslock>
    800031a8:	ffffe097          	auipc	ra,0xffffe
    800031ac:	a2e080e7          	jalr	-1490(ra) # 80000bd6 <acquire>
    ticks0 = ticks;
    800031b0:	00006917          	auipc	s2,0x6
    800031b4:	87092903          	lw	s2,-1936(s2) # 80008a20 <ticks>
    while (ticks - ticks0 < n)
    800031b8:	fcc42783          	lw	a5,-52(s0)
    800031bc:	cf9d                	beqz	a5,800031fa <sys_sleep+0x76>
        if (killed(myproc()))
        {
            release(&tickslock);
            return -1;
        }
        sleep(&ticks, &tickslock);
    800031be:	00014997          	auipc	s3,0x14
    800031c2:	b4298993          	addi	s3,s3,-1214 # 80016d00 <tickslock>
    800031c6:	00006497          	auipc	s1,0x6
    800031ca:	85a48493          	addi	s1,s1,-1958 # 80008a20 <ticks>
        if (killed(myproc()))
    800031ce:	fffff097          	auipc	ra,0xfffff
    800031d2:	a7c080e7          	jalr	-1412(ra) # 80001c4a <myproc>
    800031d6:	fffff097          	auipc	ra,0xfffff
    800031da:	4ec080e7          	jalr	1260(ra) # 800026c2 <killed>
    800031de:	ed15                	bnez	a0,8000321a <sys_sleep+0x96>
        sleep(&ticks, &tickslock);
    800031e0:	85ce                	mv	a1,s3
    800031e2:	8526                	mv	a0,s1
    800031e4:	fffff097          	auipc	ra,0xfffff
    800031e8:	236080e7          	jalr	566(ra) # 8000241a <sleep>
    while (ticks - ticks0 < n)
    800031ec:	409c                	lw	a5,0(s1)
    800031ee:	412787bb          	subw	a5,a5,s2
    800031f2:	fcc42703          	lw	a4,-52(s0)
    800031f6:	fce7ece3          	bltu	a5,a4,800031ce <sys_sleep+0x4a>
    }
    release(&tickslock);
    800031fa:	00014517          	auipc	a0,0x14
    800031fe:	b0650513          	addi	a0,a0,-1274 # 80016d00 <tickslock>
    80003202:	ffffe097          	auipc	ra,0xffffe
    80003206:	a88080e7          	jalr	-1400(ra) # 80000c8a <release>
    return 0;
    8000320a:	4501                	li	a0,0
}
    8000320c:	70e2                	ld	ra,56(sp)
    8000320e:	7442                	ld	s0,48(sp)
    80003210:	74a2                	ld	s1,40(sp)
    80003212:	7902                	ld	s2,32(sp)
    80003214:	69e2                	ld	s3,24(sp)
    80003216:	6121                	addi	sp,sp,64
    80003218:	8082                	ret
            release(&tickslock);
    8000321a:	00014517          	auipc	a0,0x14
    8000321e:	ae650513          	addi	a0,a0,-1306 # 80016d00 <tickslock>
    80003222:	ffffe097          	auipc	ra,0xffffe
    80003226:	a68080e7          	jalr	-1432(ra) # 80000c8a <release>
            return -1;
    8000322a:	557d                	li	a0,-1
    8000322c:	b7c5                	j	8000320c <sys_sleep+0x88>

000000008000322e <sys_kill>:

uint64
sys_kill(void)
{
    8000322e:	1101                	addi	sp,sp,-32
    80003230:	ec06                	sd	ra,24(sp)
    80003232:	e822                	sd	s0,16(sp)
    80003234:	1000                	addi	s0,sp,32
    int pid;

    argint(0, &pid);
    80003236:	fec40593          	addi	a1,s0,-20
    8000323a:	4501                	li	a0,0
    8000323c:	00000097          	auipc	ra,0x0
    80003240:	d9a080e7          	jalr	-614(ra) # 80002fd6 <argint>
    return kill(pid);
    80003244:	fec42503          	lw	a0,-20(s0)
    80003248:	fffff097          	auipc	ra,0xfffff
    8000324c:	3dc080e7          	jalr	988(ra) # 80002624 <kill>
}
    80003250:	60e2                	ld	ra,24(sp)
    80003252:	6442                	ld	s0,16(sp)
    80003254:	6105                	addi	sp,sp,32
    80003256:	8082                	ret

0000000080003258 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003258:	1101                	addi	sp,sp,-32
    8000325a:	ec06                	sd	ra,24(sp)
    8000325c:	e822                	sd	s0,16(sp)
    8000325e:	e426                	sd	s1,8(sp)
    80003260:	1000                	addi	s0,sp,32
    uint xticks;

    acquire(&tickslock);
    80003262:	00014517          	auipc	a0,0x14
    80003266:	a9e50513          	addi	a0,a0,-1378 # 80016d00 <tickslock>
    8000326a:	ffffe097          	auipc	ra,0xffffe
    8000326e:	96c080e7          	jalr	-1684(ra) # 80000bd6 <acquire>
    xticks = ticks;
    80003272:	00005497          	auipc	s1,0x5
    80003276:	7ae4a483          	lw	s1,1966(s1) # 80008a20 <ticks>
    release(&tickslock);
    8000327a:	00014517          	auipc	a0,0x14
    8000327e:	a8650513          	addi	a0,a0,-1402 # 80016d00 <tickslock>
    80003282:	ffffe097          	auipc	ra,0xffffe
    80003286:	a08080e7          	jalr	-1528(ra) # 80000c8a <release>
    return xticks;
}
    8000328a:	02049513          	slli	a0,s1,0x20
    8000328e:	9101                	srli	a0,a0,0x20
    80003290:	60e2                	ld	ra,24(sp)
    80003292:	6442                	ld	s0,16(sp)
    80003294:	64a2                	ld	s1,8(sp)
    80003296:	6105                	addi	sp,sp,32
    80003298:	8082                	ret

000000008000329a <sys_ps>:

void *
sys_ps(void)
{
    8000329a:	1101                	addi	sp,sp,-32
    8000329c:	ec06                	sd	ra,24(sp)
    8000329e:	e822                	sd	s0,16(sp)
    800032a0:	1000                	addi	s0,sp,32
    int start = 0, count = 0;
    800032a2:	fe042623          	sw	zero,-20(s0)
    800032a6:	fe042423          	sw	zero,-24(s0)
    argint(0, &start);
    800032aa:	fec40593          	addi	a1,s0,-20
    800032ae:	4501                	li	a0,0
    800032b0:	00000097          	auipc	ra,0x0
    800032b4:	d26080e7          	jalr	-730(ra) # 80002fd6 <argint>
    argint(1, &count);
    800032b8:	fe840593          	addi	a1,s0,-24
    800032bc:	4505                	li	a0,1
    800032be:	00000097          	auipc	ra,0x0
    800032c2:	d18080e7          	jalr	-744(ra) # 80002fd6 <argint>
    return ps((uint8)start, (uint8)count);
    800032c6:	fe844583          	lbu	a1,-24(s0)
    800032ca:	fec44503          	lbu	a0,-20(s0)
    800032ce:	fffff097          	auipc	ra,0xfffff
    800032d2:	d3c080e7          	jalr	-708(ra) # 8000200a <ps>
}
    800032d6:	60e2                	ld	ra,24(sp)
    800032d8:	6442                	ld	s0,16(sp)
    800032da:	6105                	addi	sp,sp,32
    800032dc:	8082                	ret

00000000800032de <sys_schedls>:

uint64 sys_schedls(void)
{
    800032de:	1141                	addi	sp,sp,-16
    800032e0:	e406                	sd	ra,8(sp)
    800032e2:	e022                	sd	s0,0(sp)
    800032e4:	0800                	addi	s0,sp,16
    schedls();
    800032e6:	fffff097          	auipc	ra,0xfffff
    800032ea:	698080e7          	jalr	1688(ra) # 8000297e <schedls>
    return 0;
}
    800032ee:	4501                	li	a0,0
    800032f0:	60a2                	ld	ra,8(sp)
    800032f2:	6402                	ld	s0,0(sp)
    800032f4:	0141                	addi	sp,sp,16
    800032f6:	8082                	ret

00000000800032f8 <sys_schedset>:

uint64 sys_schedset(void)
{
    800032f8:	1101                	addi	sp,sp,-32
    800032fa:	ec06                	sd	ra,24(sp)
    800032fc:	e822                	sd	s0,16(sp)
    800032fe:	1000                	addi	s0,sp,32
    int id = 0;
    80003300:	fe042623          	sw	zero,-20(s0)
    argint(0, &id);
    80003304:	fec40593          	addi	a1,s0,-20
    80003308:	4501                	li	a0,0
    8000330a:	00000097          	auipc	ra,0x0
    8000330e:	ccc080e7          	jalr	-820(ra) # 80002fd6 <argint>
    schedset(id - 1);
    80003312:	fec42503          	lw	a0,-20(s0)
    80003316:	357d                	addiw	a0,a0,-1
    80003318:	fffff097          	auipc	ra,0xfffff
    8000331c:	752080e7          	jalr	1874(ra) # 80002a6a <schedset>
    return 0;
}
    80003320:	4501                	li	a0,0
    80003322:	60e2                	ld	ra,24(sp)
    80003324:	6442                	ld	s0,16(sp)
    80003326:	6105                	addi	sp,sp,32
    80003328:	8082                	ret

000000008000332a <sys_yield>:

uint64 sys_yield(void)
{
    8000332a:	1141                	addi	sp,sp,-16
    8000332c:	e406                	sd	ra,8(sp)
    8000332e:	e022                	sd	s0,0(sp)
    80003330:	0800                	addi	s0,sp,16
    yield(YIELD_OTHER);
    80003332:	4509                	li	a0,2
    80003334:	fffff097          	auipc	ra,0xfffff
    80003338:	0aa080e7          	jalr	170(ra) # 800023de <yield>
    return 0;
    8000333c:	4501                	li	a0,0
    8000333e:	60a2                	ld	ra,8(sp)
    80003340:	6402                	ld	s0,0(sp)
    80003342:	0141                	addi	sp,sp,16
    80003344:	8082                	ret

0000000080003346 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003346:	7179                	addi	sp,sp,-48
    80003348:	f406                	sd	ra,40(sp)
    8000334a:	f022                	sd	s0,32(sp)
    8000334c:	ec26                	sd	s1,24(sp)
    8000334e:	e84a                	sd	s2,16(sp)
    80003350:	e44e                	sd	s3,8(sp)
    80003352:	e052                	sd	s4,0(sp)
    80003354:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003356:	00005597          	auipc	a1,0x5
    8000335a:	29a58593          	addi	a1,a1,666 # 800085f0 <syscalls+0xd0>
    8000335e:	00014517          	auipc	a0,0x14
    80003362:	9ba50513          	addi	a0,a0,-1606 # 80016d18 <bcache>
    80003366:	ffffd097          	auipc	ra,0xffffd
    8000336a:	7e0080e7          	jalr	2016(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000336e:	0001c797          	auipc	a5,0x1c
    80003372:	9aa78793          	addi	a5,a5,-1622 # 8001ed18 <bcache+0x8000>
    80003376:	0001c717          	auipc	a4,0x1c
    8000337a:	c0a70713          	addi	a4,a4,-1014 # 8001ef80 <bcache+0x8268>
    8000337e:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003382:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003386:	00014497          	auipc	s1,0x14
    8000338a:	9aa48493          	addi	s1,s1,-1622 # 80016d30 <bcache+0x18>
    b->next = bcache.head.next;
    8000338e:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003390:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003392:	00005a17          	auipc	s4,0x5
    80003396:	266a0a13          	addi	s4,s4,614 # 800085f8 <syscalls+0xd8>
    b->next = bcache.head.next;
    8000339a:	2b893783          	ld	a5,696(s2)
    8000339e:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800033a0:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800033a4:	85d2                	mv	a1,s4
    800033a6:	01048513          	addi	a0,s1,16
    800033aa:	00001097          	auipc	ra,0x1
    800033ae:	4c8080e7          	jalr	1224(ra) # 80004872 <initsleeplock>
    bcache.head.next->prev = b;
    800033b2:	2b893783          	ld	a5,696(s2)
    800033b6:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800033b8:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800033bc:	45848493          	addi	s1,s1,1112
    800033c0:	fd349de3          	bne	s1,s3,8000339a <binit+0x54>
  }
}
    800033c4:	70a2                	ld	ra,40(sp)
    800033c6:	7402                	ld	s0,32(sp)
    800033c8:	64e2                	ld	s1,24(sp)
    800033ca:	6942                	ld	s2,16(sp)
    800033cc:	69a2                	ld	s3,8(sp)
    800033ce:	6a02                	ld	s4,0(sp)
    800033d0:	6145                	addi	sp,sp,48
    800033d2:	8082                	ret

00000000800033d4 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800033d4:	7179                	addi	sp,sp,-48
    800033d6:	f406                	sd	ra,40(sp)
    800033d8:	f022                	sd	s0,32(sp)
    800033da:	ec26                	sd	s1,24(sp)
    800033dc:	e84a                	sd	s2,16(sp)
    800033de:	e44e                	sd	s3,8(sp)
    800033e0:	1800                	addi	s0,sp,48
    800033e2:	892a                	mv	s2,a0
    800033e4:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800033e6:	00014517          	auipc	a0,0x14
    800033ea:	93250513          	addi	a0,a0,-1742 # 80016d18 <bcache>
    800033ee:	ffffd097          	auipc	ra,0xffffd
    800033f2:	7e8080e7          	jalr	2024(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800033f6:	0001c497          	auipc	s1,0x1c
    800033fa:	bda4b483          	ld	s1,-1062(s1) # 8001efd0 <bcache+0x82b8>
    800033fe:	0001c797          	auipc	a5,0x1c
    80003402:	b8278793          	addi	a5,a5,-1150 # 8001ef80 <bcache+0x8268>
    80003406:	02f48f63          	beq	s1,a5,80003444 <bread+0x70>
    8000340a:	873e                	mv	a4,a5
    8000340c:	a021                	j	80003414 <bread+0x40>
    8000340e:	68a4                	ld	s1,80(s1)
    80003410:	02e48a63          	beq	s1,a4,80003444 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003414:	449c                	lw	a5,8(s1)
    80003416:	ff279ce3          	bne	a5,s2,8000340e <bread+0x3a>
    8000341a:	44dc                	lw	a5,12(s1)
    8000341c:	ff3799e3          	bne	a5,s3,8000340e <bread+0x3a>
      b->refcnt++;
    80003420:	40bc                	lw	a5,64(s1)
    80003422:	2785                	addiw	a5,a5,1
    80003424:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003426:	00014517          	auipc	a0,0x14
    8000342a:	8f250513          	addi	a0,a0,-1806 # 80016d18 <bcache>
    8000342e:	ffffe097          	auipc	ra,0xffffe
    80003432:	85c080e7          	jalr	-1956(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003436:	01048513          	addi	a0,s1,16
    8000343a:	00001097          	auipc	ra,0x1
    8000343e:	472080e7          	jalr	1138(ra) # 800048ac <acquiresleep>
      return b;
    80003442:	a8b9                	j	800034a0 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003444:	0001c497          	auipc	s1,0x1c
    80003448:	b844b483          	ld	s1,-1148(s1) # 8001efc8 <bcache+0x82b0>
    8000344c:	0001c797          	auipc	a5,0x1c
    80003450:	b3478793          	addi	a5,a5,-1228 # 8001ef80 <bcache+0x8268>
    80003454:	00f48863          	beq	s1,a5,80003464 <bread+0x90>
    80003458:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000345a:	40bc                	lw	a5,64(s1)
    8000345c:	cf81                	beqz	a5,80003474 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000345e:	64a4                	ld	s1,72(s1)
    80003460:	fee49de3          	bne	s1,a4,8000345a <bread+0x86>
  panic("bget: no buffers");
    80003464:	00005517          	auipc	a0,0x5
    80003468:	19c50513          	addi	a0,a0,412 # 80008600 <syscalls+0xe0>
    8000346c:	ffffd097          	auipc	ra,0xffffd
    80003470:	0d4080e7          	jalr	212(ra) # 80000540 <panic>
      b->dev = dev;
    80003474:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003478:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000347c:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003480:	4785                	li	a5,1
    80003482:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003484:	00014517          	auipc	a0,0x14
    80003488:	89450513          	addi	a0,a0,-1900 # 80016d18 <bcache>
    8000348c:	ffffd097          	auipc	ra,0xffffd
    80003490:	7fe080e7          	jalr	2046(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003494:	01048513          	addi	a0,s1,16
    80003498:	00001097          	auipc	ra,0x1
    8000349c:	414080e7          	jalr	1044(ra) # 800048ac <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800034a0:	409c                	lw	a5,0(s1)
    800034a2:	cb89                	beqz	a5,800034b4 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800034a4:	8526                	mv	a0,s1
    800034a6:	70a2                	ld	ra,40(sp)
    800034a8:	7402                	ld	s0,32(sp)
    800034aa:	64e2                	ld	s1,24(sp)
    800034ac:	6942                	ld	s2,16(sp)
    800034ae:	69a2                	ld	s3,8(sp)
    800034b0:	6145                	addi	sp,sp,48
    800034b2:	8082                	ret
    virtio_disk_rw(b, 0);
    800034b4:	4581                	li	a1,0
    800034b6:	8526                	mv	a0,s1
    800034b8:	00003097          	auipc	ra,0x3
    800034bc:	fda080e7          	jalr	-38(ra) # 80006492 <virtio_disk_rw>
    b->valid = 1;
    800034c0:	4785                	li	a5,1
    800034c2:	c09c                	sw	a5,0(s1)
  return b;
    800034c4:	b7c5                	j	800034a4 <bread+0xd0>

00000000800034c6 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800034c6:	1101                	addi	sp,sp,-32
    800034c8:	ec06                	sd	ra,24(sp)
    800034ca:	e822                	sd	s0,16(sp)
    800034cc:	e426                	sd	s1,8(sp)
    800034ce:	1000                	addi	s0,sp,32
    800034d0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800034d2:	0541                	addi	a0,a0,16
    800034d4:	00001097          	auipc	ra,0x1
    800034d8:	472080e7          	jalr	1138(ra) # 80004946 <holdingsleep>
    800034dc:	cd01                	beqz	a0,800034f4 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800034de:	4585                	li	a1,1
    800034e0:	8526                	mv	a0,s1
    800034e2:	00003097          	auipc	ra,0x3
    800034e6:	fb0080e7          	jalr	-80(ra) # 80006492 <virtio_disk_rw>
}
    800034ea:	60e2                	ld	ra,24(sp)
    800034ec:	6442                	ld	s0,16(sp)
    800034ee:	64a2                	ld	s1,8(sp)
    800034f0:	6105                	addi	sp,sp,32
    800034f2:	8082                	ret
    panic("bwrite");
    800034f4:	00005517          	auipc	a0,0x5
    800034f8:	12450513          	addi	a0,a0,292 # 80008618 <syscalls+0xf8>
    800034fc:	ffffd097          	auipc	ra,0xffffd
    80003500:	044080e7          	jalr	68(ra) # 80000540 <panic>

0000000080003504 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003504:	1101                	addi	sp,sp,-32
    80003506:	ec06                	sd	ra,24(sp)
    80003508:	e822                	sd	s0,16(sp)
    8000350a:	e426                	sd	s1,8(sp)
    8000350c:	e04a                	sd	s2,0(sp)
    8000350e:	1000                	addi	s0,sp,32
    80003510:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003512:	01050913          	addi	s2,a0,16
    80003516:	854a                	mv	a0,s2
    80003518:	00001097          	auipc	ra,0x1
    8000351c:	42e080e7          	jalr	1070(ra) # 80004946 <holdingsleep>
    80003520:	c92d                	beqz	a0,80003592 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003522:	854a                	mv	a0,s2
    80003524:	00001097          	auipc	ra,0x1
    80003528:	3de080e7          	jalr	990(ra) # 80004902 <releasesleep>

  acquire(&bcache.lock);
    8000352c:	00013517          	auipc	a0,0x13
    80003530:	7ec50513          	addi	a0,a0,2028 # 80016d18 <bcache>
    80003534:	ffffd097          	auipc	ra,0xffffd
    80003538:	6a2080e7          	jalr	1698(ra) # 80000bd6 <acquire>
  b->refcnt--;
    8000353c:	40bc                	lw	a5,64(s1)
    8000353e:	37fd                	addiw	a5,a5,-1
    80003540:	0007871b          	sext.w	a4,a5
    80003544:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003546:	eb05                	bnez	a4,80003576 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003548:	68bc                	ld	a5,80(s1)
    8000354a:	64b8                	ld	a4,72(s1)
    8000354c:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000354e:	64bc                	ld	a5,72(s1)
    80003550:	68b8                	ld	a4,80(s1)
    80003552:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003554:	0001b797          	auipc	a5,0x1b
    80003558:	7c478793          	addi	a5,a5,1988 # 8001ed18 <bcache+0x8000>
    8000355c:	2b87b703          	ld	a4,696(a5)
    80003560:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003562:	0001c717          	auipc	a4,0x1c
    80003566:	a1e70713          	addi	a4,a4,-1506 # 8001ef80 <bcache+0x8268>
    8000356a:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000356c:	2b87b703          	ld	a4,696(a5)
    80003570:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003572:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003576:	00013517          	auipc	a0,0x13
    8000357a:	7a250513          	addi	a0,a0,1954 # 80016d18 <bcache>
    8000357e:	ffffd097          	auipc	ra,0xffffd
    80003582:	70c080e7          	jalr	1804(ra) # 80000c8a <release>
}
    80003586:	60e2                	ld	ra,24(sp)
    80003588:	6442                	ld	s0,16(sp)
    8000358a:	64a2                	ld	s1,8(sp)
    8000358c:	6902                	ld	s2,0(sp)
    8000358e:	6105                	addi	sp,sp,32
    80003590:	8082                	ret
    panic("brelse");
    80003592:	00005517          	auipc	a0,0x5
    80003596:	08e50513          	addi	a0,a0,142 # 80008620 <syscalls+0x100>
    8000359a:	ffffd097          	auipc	ra,0xffffd
    8000359e:	fa6080e7          	jalr	-90(ra) # 80000540 <panic>

00000000800035a2 <bpin>:

void
bpin(struct buf *b) {
    800035a2:	1101                	addi	sp,sp,-32
    800035a4:	ec06                	sd	ra,24(sp)
    800035a6:	e822                	sd	s0,16(sp)
    800035a8:	e426                	sd	s1,8(sp)
    800035aa:	1000                	addi	s0,sp,32
    800035ac:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800035ae:	00013517          	auipc	a0,0x13
    800035b2:	76a50513          	addi	a0,a0,1898 # 80016d18 <bcache>
    800035b6:	ffffd097          	auipc	ra,0xffffd
    800035ba:	620080e7          	jalr	1568(ra) # 80000bd6 <acquire>
  b->refcnt++;
    800035be:	40bc                	lw	a5,64(s1)
    800035c0:	2785                	addiw	a5,a5,1
    800035c2:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800035c4:	00013517          	auipc	a0,0x13
    800035c8:	75450513          	addi	a0,a0,1876 # 80016d18 <bcache>
    800035cc:	ffffd097          	auipc	ra,0xffffd
    800035d0:	6be080e7          	jalr	1726(ra) # 80000c8a <release>
}
    800035d4:	60e2                	ld	ra,24(sp)
    800035d6:	6442                	ld	s0,16(sp)
    800035d8:	64a2                	ld	s1,8(sp)
    800035da:	6105                	addi	sp,sp,32
    800035dc:	8082                	ret

00000000800035de <bunpin>:

void
bunpin(struct buf *b) {
    800035de:	1101                	addi	sp,sp,-32
    800035e0:	ec06                	sd	ra,24(sp)
    800035e2:	e822                	sd	s0,16(sp)
    800035e4:	e426                	sd	s1,8(sp)
    800035e6:	1000                	addi	s0,sp,32
    800035e8:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800035ea:	00013517          	auipc	a0,0x13
    800035ee:	72e50513          	addi	a0,a0,1838 # 80016d18 <bcache>
    800035f2:	ffffd097          	auipc	ra,0xffffd
    800035f6:	5e4080e7          	jalr	1508(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800035fa:	40bc                	lw	a5,64(s1)
    800035fc:	37fd                	addiw	a5,a5,-1
    800035fe:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003600:	00013517          	auipc	a0,0x13
    80003604:	71850513          	addi	a0,a0,1816 # 80016d18 <bcache>
    80003608:	ffffd097          	auipc	ra,0xffffd
    8000360c:	682080e7          	jalr	1666(ra) # 80000c8a <release>
}
    80003610:	60e2                	ld	ra,24(sp)
    80003612:	6442                	ld	s0,16(sp)
    80003614:	64a2                	ld	s1,8(sp)
    80003616:	6105                	addi	sp,sp,32
    80003618:	8082                	ret

000000008000361a <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000361a:	1101                	addi	sp,sp,-32
    8000361c:	ec06                	sd	ra,24(sp)
    8000361e:	e822                	sd	s0,16(sp)
    80003620:	e426                	sd	s1,8(sp)
    80003622:	e04a                	sd	s2,0(sp)
    80003624:	1000                	addi	s0,sp,32
    80003626:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003628:	00d5d59b          	srliw	a1,a1,0xd
    8000362c:	0001c797          	auipc	a5,0x1c
    80003630:	dc87a783          	lw	a5,-568(a5) # 8001f3f4 <sb+0x1c>
    80003634:	9dbd                	addw	a1,a1,a5
    80003636:	00000097          	auipc	ra,0x0
    8000363a:	d9e080e7          	jalr	-610(ra) # 800033d4 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000363e:	0074f713          	andi	a4,s1,7
    80003642:	4785                	li	a5,1
    80003644:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003648:	14ce                	slli	s1,s1,0x33
    8000364a:	90d9                	srli	s1,s1,0x36
    8000364c:	00950733          	add	a4,a0,s1
    80003650:	05874703          	lbu	a4,88(a4)
    80003654:	00e7f6b3          	and	a3,a5,a4
    80003658:	c69d                	beqz	a3,80003686 <bfree+0x6c>
    8000365a:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000365c:	94aa                	add	s1,s1,a0
    8000365e:	fff7c793          	not	a5,a5
    80003662:	8f7d                	and	a4,a4,a5
    80003664:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003668:	00001097          	auipc	ra,0x1
    8000366c:	126080e7          	jalr	294(ra) # 8000478e <log_write>
  brelse(bp);
    80003670:	854a                	mv	a0,s2
    80003672:	00000097          	auipc	ra,0x0
    80003676:	e92080e7          	jalr	-366(ra) # 80003504 <brelse>
}
    8000367a:	60e2                	ld	ra,24(sp)
    8000367c:	6442                	ld	s0,16(sp)
    8000367e:	64a2                	ld	s1,8(sp)
    80003680:	6902                	ld	s2,0(sp)
    80003682:	6105                	addi	sp,sp,32
    80003684:	8082                	ret
    panic("freeing free block");
    80003686:	00005517          	auipc	a0,0x5
    8000368a:	fa250513          	addi	a0,a0,-94 # 80008628 <syscalls+0x108>
    8000368e:	ffffd097          	auipc	ra,0xffffd
    80003692:	eb2080e7          	jalr	-334(ra) # 80000540 <panic>

0000000080003696 <balloc>:
{
    80003696:	711d                	addi	sp,sp,-96
    80003698:	ec86                	sd	ra,88(sp)
    8000369a:	e8a2                	sd	s0,80(sp)
    8000369c:	e4a6                	sd	s1,72(sp)
    8000369e:	e0ca                	sd	s2,64(sp)
    800036a0:	fc4e                	sd	s3,56(sp)
    800036a2:	f852                	sd	s4,48(sp)
    800036a4:	f456                	sd	s5,40(sp)
    800036a6:	f05a                	sd	s6,32(sp)
    800036a8:	ec5e                	sd	s7,24(sp)
    800036aa:	e862                	sd	s8,16(sp)
    800036ac:	e466                	sd	s9,8(sp)
    800036ae:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800036b0:	0001c797          	auipc	a5,0x1c
    800036b4:	d2c7a783          	lw	a5,-724(a5) # 8001f3dc <sb+0x4>
    800036b8:	cff5                	beqz	a5,800037b4 <balloc+0x11e>
    800036ba:	8baa                	mv	s7,a0
    800036bc:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800036be:	0001cb17          	auipc	s6,0x1c
    800036c2:	d1ab0b13          	addi	s6,s6,-742 # 8001f3d8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036c6:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800036c8:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036ca:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800036cc:	6c89                	lui	s9,0x2
    800036ce:	a061                	j	80003756 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    800036d0:	97ca                	add	a5,a5,s2
    800036d2:	8e55                	or	a2,a2,a3
    800036d4:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800036d8:	854a                	mv	a0,s2
    800036da:	00001097          	auipc	ra,0x1
    800036de:	0b4080e7          	jalr	180(ra) # 8000478e <log_write>
        brelse(bp);
    800036e2:	854a                	mv	a0,s2
    800036e4:	00000097          	auipc	ra,0x0
    800036e8:	e20080e7          	jalr	-480(ra) # 80003504 <brelse>
  bp = bread(dev, bno);
    800036ec:	85a6                	mv	a1,s1
    800036ee:	855e                	mv	a0,s7
    800036f0:	00000097          	auipc	ra,0x0
    800036f4:	ce4080e7          	jalr	-796(ra) # 800033d4 <bread>
    800036f8:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800036fa:	40000613          	li	a2,1024
    800036fe:	4581                	li	a1,0
    80003700:	05850513          	addi	a0,a0,88
    80003704:	ffffd097          	auipc	ra,0xffffd
    80003708:	5ce080e7          	jalr	1486(ra) # 80000cd2 <memset>
  log_write(bp);
    8000370c:	854a                	mv	a0,s2
    8000370e:	00001097          	auipc	ra,0x1
    80003712:	080080e7          	jalr	128(ra) # 8000478e <log_write>
  brelse(bp);
    80003716:	854a                	mv	a0,s2
    80003718:	00000097          	auipc	ra,0x0
    8000371c:	dec080e7          	jalr	-532(ra) # 80003504 <brelse>
}
    80003720:	8526                	mv	a0,s1
    80003722:	60e6                	ld	ra,88(sp)
    80003724:	6446                	ld	s0,80(sp)
    80003726:	64a6                	ld	s1,72(sp)
    80003728:	6906                	ld	s2,64(sp)
    8000372a:	79e2                	ld	s3,56(sp)
    8000372c:	7a42                	ld	s4,48(sp)
    8000372e:	7aa2                	ld	s5,40(sp)
    80003730:	7b02                	ld	s6,32(sp)
    80003732:	6be2                	ld	s7,24(sp)
    80003734:	6c42                	ld	s8,16(sp)
    80003736:	6ca2                	ld	s9,8(sp)
    80003738:	6125                	addi	sp,sp,96
    8000373a:	8082                	ret
    brelse(bp);
    8000373c:	854a                	mv	a0,s2
    8000373e:	00000097          	auipc	ra,0x0
    80003742:	dc6080e7          	jalr	-570(ra) # 80003504 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003746:	015c87bb          	addw	a5,s9,s5
    8000374a:	00078a9b          	sext.w	s5,a5
    8000374e:	004b2703          	lw	a4,4(s6)
    80003752:	06eaf163          	bgeu	s5,a4,800037b4 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003756:	41fad79b          	sraiw	a5,s5,0x1f
    8000375a:	0137d79b          	srliw	a5,a5,0x13
    8000375e:	015787bb          	addw	a5,a5,s5
    80003762:	40d7d79b          	sraiw	a5,a5,0xd
    80003766:	01cb2583          	lw	a1,28(s6)
    8000376a:	9dbd                	addw	a1,a1,a5
    8000376c:	855e                	mv	a0,s7
    8000376e:	00000097          	auipc	ra,0x0
    80003772:	c66080e7          	jalr	-922(ra) # 800033d4 <bread>
    80003776:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003778:	004b2503          	lw	a0,4(s6)
    8000377c:	000a849b          	sext.w	s1,s5
    80003780:	8762                	mv	a4,s8
    80003782:	faa4fde3          	bgeu	s1,a0,8000373c <balloc+0xa6>
      m = 1 << (bi % 8);
    80003786:	00777693          	andi	a3,a4,7
    8000378a:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000378e:	41f7579b          	sraiw	a5,a4,0x1f
    80003792:	01d7d79b          	srliw	a5,a5,0x1d
    80003796:	9fb9                	addw	a5,a5,a4
    80003798:	4037d79b          	sraiw	a5,a5,0x3
    8000379c:	00f90633          	add	a2,s2,a5
    800037a0:	05864603          	lbu	a2,88(a2)
    800037a4:	00c6f5b3          	and	a1,a3,a2
    800037a8:	d585                	beqz	a1,800036d0 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037aa:	2705                	addiw	a4,a4,1
    800037ac:	2485                	addiw	s1,s1,1
    800037ae:	fd471ae3          	bne	a4,s4,80003782 <balloc+0xec>
    800037b2:	b769                	j	8000373c <balloc+0xa6>
  printf("balloc: out of blocks\n");
    800037b4:	00005517          	auipc	a0,0x5
    800037b8:	e8c50513          	addi	a0,a0,-372 # 80008640 <syscalls+0x120>
    800037bc:	ffffd097          	auipc	ra,0xffffd
    800037c0:	dce080e7          	jalr	-562(ra) # 8000058a <printf>
  return 0;
    800037c4:	4481                	li	s1,0
    800037c6:	bfa9                	j	80003720 <balloc+0x8a>

00000000800037c8 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800037c8:	7179                	addi	sp,sp,-48
    800037ca:	f406                	sd	ra,40(sp)
    800037cc:	f022                	sd	s0,32(sp)
    800037ce:	ec26                	sd	s1,24(sp)
    800037d0:	e84a                	sd	s2,16(sp)
    800037d2:	e44e                	sd	s3,8(sp)
    800037d4:	e052                	sd	s4,0(sp)
    800037d6:	1800                	addi	s0,sp,48
    800037d8:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800037da:	47ad                	li	a5,11
    800037dc:	02b7e863          	bltu	a5,a1,8000380c <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    800037e0:	02059793          	slli	a5,a1,0x20
    800037e4:	01e7d593          	srli	a1,a5,0x1e
    800037e8:	00b504b3          	add	s1,a0,a1
    800037ec:	0504a903          	lw	s2,80(s1)
    800037f0:	06091e63          	bnez	s2,8000386c <bmap+0xa4>
      addr = balloc(ip->dev);
    800037f4:	4108                	lw	a0,0(a0)
    800037f6:	00000097          	auipc	ra,0x0
    800037fa:	ea0080e7          	jalr	-352(ra) # 80003696 <balloc>
    800037fe:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003802:	06090563          	beqz	s2,8000386c <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80003806:	0524a823          	sw	s2,80(s1)
    8000380a:	a08d                	j	8000386c <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    8000380c:	ff45849b          	addiw	s1,a1,-12
    80003810:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003814:	0ff00793          	li	a5,255
    80003818:	08e7e563          	bltu	a5,a4,800038a2 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    8000381c:	08052903          	lw	s2,128(a0)
    80003820:	00091d63          	bnez	s2,8000383a <bmap+0x72>
      addr = balloc(ip->dev);
    80003824:	4108                	lw	a0,0(a0)
    80003826:	00000097          	auipc	ra,0x0
    8000382a:	e70080e7          	jalr	-400(ra) # 80003696 <balloc>
    8000382e:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003832:	02090d63          	beqz	s2,8000386c <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003836:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000383a:	85ca                	mv	a1,s2
    8000383c:	0009a503          	lw	a0,0(s3)
    80003840:	00000097          	auipc	ra,0x0
    80003844:	b94080e7          	jalr	-1132(ra) # 800033d4 <bread>
    80003848:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000384a:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000384e:	02049713          	slli	a4,s1,0x20
    80003852:	01e75593          	srli	a1,a4,0x1e
    80003856:	00b784b3          	add	s1,a5,a1
    8000385a:	0004a903          	lw	s2,0(s1)
    8000385e:	02090063          	beqz	s2,8000387e <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003862:	8552                	mv	a0,s4
    80003864:	00000097          	auipc	ra,0x0
    80003868:	ca0080e7          	jalr	-864(ra) # 80003504 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000386c:	854a                	mv	a0,s2
    8000386e:	70a2                	ld	ra,40(sp)
    80003870:	7402                	ld	s0,32(sp)
    80003872:	64e2                	ld	s1,24(sp)
    80003874:	6942                	ld	s2,16(sp)
    80003876:	69a2                	ld	s3,8(sp)
    80003878:	6a02                	ld	s4,0(sp)
    8000387a:	6145                	addi	sp,sp,48
    8000387c:	8082                	ret
      addr = balloc(ip->dev);
    8000387e:	0009a503          	lw	a0,0(s3)
    80003882:	00000097          	auipc	ra,0x0
    80003886:	e14080e7          	jalr	-492(ra) # 80003696 <balloc>
    8000388a:	0005091b          	sext.w	s2,a0
      if(addr){
    8000388e:	fc090ae3          	beqz	s2,80003862 <bmap+0x9a>
        a[bn] = addr;
    80003892:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003896:	8552                	mv	a0,s4
    80003898:	00001097          	auipc	ra,0x1
    8000389c:	ef6080e7          	jalr	-266(ra) # 8000478e <log_write>
    800038a0:	b7c9                	j	80003862 <bmap+0x9a>
  panic("bmap: out of range");
    800038a2:	00005517          	auipc	a0,0x5
    800038a6:	db650513          	addi	a0,a0,-586 # 80008658 <syscalls+0x138>
    800038aa:	ffffd097          	auipc	ra,0xffffd
    800038ae:	c96080e7          	jalr	-874(ra) # 80000540 <panic>

00000000800038b2 <iget>:
{
    800038b2:	7179                	addi	sp,sp,-48
    800038b4:	f406                	sd	ra,40(sp)
    800038b6:	f022                	sd	s0,32(sp)
    800038b8:	ec26                	sd	s1,24(sp)
    800038ba:	e84a                	sd	s2,16(sp)
    800038bc:	e44e                	sd	s3,8(sp)
    800038be:	e052                	sd	s4,0(sp)
    800038c0:	1800                	addi	s0,sp,48
    800038c2:	89aa                	mv	s3,a0
    800038c4:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800038c6:	0001c517          	auipc	a0,0x1c
    800038ca:	b3250513          	addi	a0,a0,-1230 # 8001f3f8 <itable>
    800038ce:	ffffd097          	auipc	ra,0xffffd
    800038d2:	308080e7          	jalr	776(ra) # 80000bd6 <acquire>
  empty = 0;
    800038d6:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800038d8:	0001c497          	auipc	s1,0x1c
    800038dc:	b3848493          	addi	s1,s1,-1224 # 8001f410 <itable+0x18>
    800038e0:	0001d697          	auipc	a3,0x1d
    800038e4:	5c068693          	addi	a3,a3,1472 # 80020ea0 <log>
    800038e8:	a039                	j	800038f6 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800038ea:	02090b63          	beqz	s2,80003920 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800038ee:	08848493          	addi	s1,s1,136
    800038f2:	02d48a63          	beq	s1,a3,80003926 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800038f6:	449c                	lw	a5,8(s1)
    800038f8:	fef059e3          	blez	a5,800038ea <iget+0x38>
    800038fc:	4098                	lw	a4,0(s1)
    800038fe:	ff3716e3          	bne	a4,s3,800038ea <iget+0x38>
    80003902:	40d8                	lw	a4,4(s1)
    80003904:	ff4713e3          	bne	a4,s4,800038ea <iget+0x38>
      ip->ref++;
    80003908:	2785                	addiw	a5,a5,1
    8000390a:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000390c:	0001c517          	auipc	a0,0x1c
    80003910:	aec50513          	addi	a0,a0,-1300 # 8001f3f8 <itable>
    80003914:	ffffd097          	auipc	ra,0xffffd
    80003918:	376080e7          	jalr	886(ra) # 80000c8a <release>
      return ip;
    8000391c:	8926                	mv	s2,s1
    8000391e:	a03d                	j	8000394c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003920:	f7f9                	bnez	a5,800038ee <iget+0x3c>
    80003922:	8926                	mv	s2,s1
    80003924:	b7e9                	j	800038ee <iget+0x3c>
  if(empty == 0)
    80003926:	02090c63          	beqz	s2,8000395e <iget+0xac>
  ip->dev = dev;
    8000392a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000392e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003932:	4785                	li	a5,1
    80003934:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003938:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000393c:	0001c517          	auipc	a0,0x1c
    80003940:	abc50513          	addi	a0,a0,-1348 # 8001f3f8 <itable>
    80003944:	ffffd097          	auipc	ra,0xffffd
    80003948:	346080e7          	jalr	838(ra) # 80000c8a <release>
}
    8000394c:	854a                	mv	a0,s2
    8000394e:	70a2                	ld	ra,40(sp)
    80003950:	7402                	ld	s0,32(sp)
    80003952:	64e2                	ld	s1,24(sp)
    80003954:	6942                	ld	s2,16(sp)
    80003956:	69a2                	ld	s3,8(sp)
    80003958:	6a02                	ld	s4,0(sp)
    8000395a:	6145                	addi	sp,sp,48
    8000395c:	8082                	ret
    panic("iget: no inodes");
    8000395e:	00005517          	auipc	a0,0x5
    80003962:	d1250513          	addi	a0,a0,-750 # 80008670 <syscalls+0x150>
    80003966:	ffffd097          	auipc	ra,0xffffd
    8000396a:	bda080e7          	jalr	-1062(ra) # 80000540 <panic>

000000008000396e <fsinit>:
fsinit(int dev) {
    8000396e:	7179                	addi	sp,sp,-48
    80003970:	f406                	sd	ra,40(sp)
    80003972:	f022                	sd	s0,32(sp)
    80003974:	ec26                	sd	s1,24(sp)
    80003976:	e84a                	sd	s2,16(sp)
    80003978:	e44e                	sd	s3,8(sp)
    8000397a:	1800                	addi	s0,sp,48
    8000397c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000397e:	4585                	li	a1,1
    80003980:	00000097          	auipc	ra,0x0
    80003984:	a54080e7          	jalr	-1452(ra) # 800033d4 <bread>
    80003988:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000398a:	0001c997          	auipc	s3,0x1c
    8000398e:	a4e98993          	addi	s3,s3,-1458 # 8001f3d8 <sb>
    80003992:	02000613          	li	a2,32
    80003996:	05850593          	addi	a1,a0,88
    8000399a:	854e                	mv	a0,s3
    8000399c:	ffffd097          	auipc	ra,0xffffd
    800039a0:	392080e7          	jalr	914(ra) # 80000d2e <memmove>
  brelse(bp);
    800039a4:	8526                	mv	a0,s1
    800039a6:	00000097          	auipc	ra,0x0
    800039aa:	b5e080e7          	jalr	-1186(ra) # 80003504 <brelse>
  if(sb.magic != FSMAGIC)
    800039ae:	0009a703          	lw	a4,0(s3)
    800039b2:	102037b7          	lui	a5,0x10203
    800039b6:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800039ba:	02f71263          	bne	a4,a5,800039de <fsinit+0x70>
  initlog(dev, &sb);
    800039be:	0001c597          	auipc	a1,0x1c
    800039c2:	a1a58593          	addi	a1,a1,-1510 # 8001f3d8 <sb>
    800039c6:	854a                	mv	a0,s2
    800039c8:	00001097          	auipc	ra,0x1
    800039cc:	b4a080e7          	jalr	-1206(ra) # 80004512 <initlog>
}
    800039d0:	70a2                	ld	ra,40(sp)
    800039d2:	7402                	ld	s0,32(sp)
    800039d4:	64e2                	ld	s1,24(sp)
    800039d6:	6942                	ld	s2,16(sp)
    800039d8:	69a2                	ld	s3,8(sp)
    800039da:	6145                	addi	sp,sp,48
    800039dc:	8082                	ret
    panic("invalid file system");
    800039de:	00005517          	auipc	a0,0x5
    800039e2:	ca250513          	addi	a0,a0,-862 # 80008680 <syscalls+0x160>
    800039e6:	ffffd097          	auipc	ra,0xffffd
    800039ea:	b5a080e7          	jalr	-1190(ra) # 80000540 <panic>

00000000800039ee <iinit>:
{
    800039ee:	7179                	addi	sp,sp,-48
    800039f0:	f406                	sd	ra,40(sp)
    800039f2:	f022                	sd	s0,32(sp)
    800039f4:	ec26                	sd	s1,24(sp)
    800039f6:	e84a                	sd	s2,16(sp)
    800039f8:	e44e                	sd	s3,8(sp)
    800039fa:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800039fc:	00005597          	auipc	a1,0x5
    80003a00:	c9c58593          	addi	a1,a1,-868 # 80008698 <syscalls+0x178>
    80003a04:	0001c517          	auipc	a0,0x1c
    80003a08:	9f450513          	addi	a0,a0,-1548 # 8001f3f8 <itable>
    80003a0c:	ffffd097          	auipc	ra,0xffffd
    80003a10:	13a080e7          	jalr	314(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003a14:	0001c497          	auipc	s1,0x1c
    80003a18:	a0c48493          	addi	s1,s1,-1524 # 8001f420 <itable+0x28>
    80003a1c:	0001d997          	auipc	s3,0x1d
    80003a20:	49498993          	addi	s3,s3,1172 # 80020eb0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003a24:	00005917          	auipc	s2,0x5
    80003a28:	c7c90913          	addi	s2,s2,-900 # 800086a0 <syscalls+0x180>
    80003a2c:	85ca                	mv	a1,s2
    80003a2e:	8526                	mv	a0,s1
    80003a30:	00001097          	auipc	ra,0x1
    80003a34:	e42080e7          	jalr	-446(ra) # 80004872 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003a38:	08848493          	addi	s1,s1,136
    80003a3c:	ff3498e3          	bne	s1,s3,80003a2c <iinit+0x3e>
}
    80003a40:	70a2                	ld	ra,40(sp)
    80003a42:	7402                	ld	s0,32(sp)
    80003a44:	64e2                	ld	s1,24(sp)
    80003a46:	6942                	ld	s2,16(sp)
    80003a48:	69a2                	ld	s3,8(sp)
    80003a4a:	6145                	addi	sp,sp,48
    80003a4c:	8082                	ret

0000000080003a4e <ialloc>:
{
    80003a4e:	715d                	addi	sp,sp,-80
    80003a50:	e486                	sd	ra,72(sp)
    80003a52:	e0a2                	sd	s0,64(sp)
    80003a54:	fc26                	sd	s1,56(sp)
    80003a56:	f84a                	sd	s2,48(sp)
    80003a58:	f44e                	sd	s3,40(sp)
    80003a5a:	f052                	sd	s4,32(sp)
    80003a5c:	ec56                	sd	s5,24(sp)
    80003a5e:	e85a                	sd	s6,16(sp)
    80003a60:	e45e                	sd	s7,8(sp)
    80003a62:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a64:	0001c717          	auipc	a4,0x1c
    80003a68:	98072703          	lw	a4,-1664(a4) # 8001f3e4 <sb+0xc>
    80003a6c:	4785                	li	a5,1
    80003a6e:	04e7fa63          	bgeu	a5,a4,80003ac2 <ialloc+0x74>
    80003a72:	8aaa                	mv	s5,a0
    80003a74:	8bae                	mv	s7,a1
    80003a76:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003a78:	0001ca17          	auipc	s4,0x1c
    80003a7c:	960a0a13          	addi	s4,s4,-1696 # 8001f3d8 <sb>
    80003a80:	00048b1b          	sext.w	s6,s1
    80003a84:	0044d593          	srli	a1,s1,0x4
    80003a88:	018a2783          	lw	a5,24(s4)
    80003a8c:	9dbd                	addw	a1,a1,a5
    80003a8e:	8556                	mv	a0,s5
    80003a90:	00000097          	auipc	ra,0x0
    80003a94:	944080e7          	jalr	-1724(ra) # 800033d4 <bread>
    80003a98:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003a9a:	05850993          	addi	s3,a0,88
    80003a9e:	00f4f793          	andi	a5,s1,15
    80003aa2:	079a                	slli	a5,a5,0x6
    80003aa4:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003aa6:	00099783          	lh	a5,0(s3)
    80003aaa:	c3a1                	beqz	a5,80003aea <ialloc+0x9c>
    brelse(bp);
    80003aac:	00000097          	auipc	ra,0x0
    80003ab0:	a58080e7          	jalr	-1448(ra) # 80003504 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003ab4:	0485                	addi	s1,s1,1
    80003ab6:	00ca2703          	lw	a4,12(s4)
    80003aba:	0004879b          	sext.w	a5,s1
    80003abe:	fce7e1e3          	bltu	a5,a4,80003a80 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003ac2:	00005517          	auipc	a0,0x5
    80003ac6:	be650513          	addi	a0,a0,-1050 # 800086a8 <syscalls+0x188>
    80003aca:	ffffd097          	auipc	ra,0xffffd
    80003ace:	ac0080e7          	jalr	-1344(ra) # 8000058a <printf>
  return 0;
    80003ad2:	4501                	li	a0,0
}
    80003ad4:	60a6                	ld	ra,72(sp)
    80003ad6:	6406                	ld	s0,64(sp)
    80003ad8:	74e2                	ld	s1,56(sp)
    80003ada:	7942                	ld	s2,48(sp)
    80003adc:	79a2                	ld	s3,40(sp)
    80003ade:	7a02                	ld	s4,32(sp)
    80003ae0:	6ae2                	ld	s5,24(sp)
    80003ae2:	6b42                	ld	s6,16(sp)
    80003ae4:	6ba2                	ld	s7,8(sp)
    80003ae6:	6161                	addi	sp,sp,80
    80003ae8:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003aea:	04000613          	li	a2,64
    80003aee:	4581                	li	a1,0
    80003af0:	854e                	mv	a0,s3
    80003af2:	ffffd097          	auipc	ra,0xffffd
    80003af6:	1e0080e7          	jalr	480(ra) # 80000cd2 <memset>
      dip->type = type;
    80003afa:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003afe:	854a                	mv	a0,s2
    80003b00:	00001097          	auipc	ra,0x1
    80003b04:	c8e080e7          	jalr	-882(ra) # 8000478e <log_write>
      brelse(bp);
    80003b08:	854a                	mv	a0,s2
    80003b0a:	00000097          	auipc	ra,0x0
    80003b0e:	9fa080e7          	jalr	-1542(ra) # 80003504 <brelse>
      return iget(dev, inum);
    80003b12:	85da                	mv	a1,s6
    80003b14:	8556                	mv	a0,s5
    80003b16:	00000097          	auipc	ra,0x0
    80003b1a:	d9c080e7          	jalr	-612(ra) # 800038b2 <iget>
    80003b1e:	bf5d                	j	80003ad4 <ialloc+0x86>

0000000080003b20 <iupdate>:
{
    80003b20:	1101                	addi	sp,sp,-32
    80003b22:	ec06                	sd	ra,24(sp)
    80003b24:	e822                	sd	s0,16(sp)
    80003b26:	e426                	sd	s1,8(sp)
    80003b28:	e04a                	sd	s2,0(sp)
    80003b2a:	1000                	addi	s0,sp,32
    80003b2c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b2e:	415c                	lw	a5,4(a0)
    80003b30:	0047d79b          	srliw	a5,a5,0x4
    80003b34:	0001c597          	auipc	a1,0x1c
    80003b38:	8bc5a583          	lw	a1,-1860(a1) # 8001f3f0 <sb+0x18>
    80003b3c:	9dbd                	addw	a1,a1,a5
    80003b3e:	4108                	lw	a0,0(a0)
    80003b40:	00000097          	auipc	ra,0x0
    80003b44:	894080e7          	jalr	-1900(ra) # 800033d4 <bread>
    80003b48:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b4a:	05850793          	addi	a5,a0,88
    80003b4e:	40d8                	lw	a4,4(s1)
    80003b50:	8b3d                	andi	a4,a4,15
    80003b52:	071a                	slli	a4,a4,0x6
    80003b54:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003b56:	04449703          	lh	a4,68(s1)
    80003b5a:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003b5e:	04649703          	lh	a4,70(s1)
    80003b62:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003b66:	04849703          	lh	a4,72(s1)
    80003b6a:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003b6e:	04a49703          	lh	a4,74(s1)
    80003b72:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003b76:	44f8                	lw	a4,76(s1)
    80003b78:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003b7a:	03400613          	li	a2,52
    80003b7e:	05048593          	addi	a1,s1,80
    80003b82:	00c78513          	addi	a0,a5,12
    80003b86:	ffffd097          	auipc	ra,0xffffd
    80003b8a:	1a8080e7          	jalr	424(ra) # 80000d2e <memmove>
  log_write(bp);
    80003b8e:	854a                	mv	a0,s2
    80003b90:	00001097          	auipc	ra,0x1
    80003b94:	bfe080e7          	jalr	-1026(ra) # 8000478e <log_write>
  brelse(bp);
    80003b98:	854a                	mv	a0,s2
    80003b9a:	00000097          	auipc	ra,0x0
    80003b9e:	96a080e7          	jalr	-1686(ra) # 80003504 <brelse>
}
    80003ba2:	60e2                	ld	ra,24(sp)
    80003ba4:	6442                	ld	s0,16(sp)
    80003ba6:	64a2                	ld	s1,8(sp)
    80003ba8:	6902                	ld	s2,0(sp)
    80003baa:	6105                	addi	sp,sp,32
    80003bac:	8082                	ret

0000000080003bae <idup>:
{
    80003bae:	1101                	addi	sp,sp,-32
    80003bb0:	ec06                	sd	ra,24(sp)
    80003bb2:	e822                	sd	s0,16(sp)
    80003bb4:	e426                	sd	s1,8(sp)
    80003bb6:	1000                	addi	s0,sp,32
    80003bb8:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003bba:	0001c517          	auipc	a0,0x1c
    80003bbe:	83e50513          	addi	a0,a0,-1986 # 8001f3f8 <itable>
    80003bc2:	ffffd097          	auipc	ra,0xffffd
    80003bc6:	014080e7          	jalr	20(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003bca:	449c                	lw	a5,8(s1)
    80003bcc:	2785                	addiw	a5,a5,1
    80003bce:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003bd0:	0001c517          	auipc	a0,0x1c
    80003bd4:	82850513          	addi	a0,a0,-2008 # 8001f3f8 <itable>
    80003bd8:	ffffd097          	auipc	ra,0xffffd
    80003bdc:	0b2080e7          	jalr	178(ra) # 80000c8a <release>
}
    80003be0:	8526                	mv	a0,s1
    80003be2:	60e2                	ld	ra,24(sp)
    80003be4:	6442                	ld	s0,16(sp)
    80003be6:	64a2                	ld	s1,8(sp)
    80003be8:	6105                	addi	sp,sp,32
    80003bea:	8082                	ret

0000000080003bec <ilock>:
{
    80003bec:	1101                	addi	sp,sp,-32
    80003bee:	ec06                	sd	ra,24(sp)
    80003bf0:	e822                	sd	s0,16(sp)
    80003bf2:	e426                	sd	s1,8(sp)
    80003bf4:	e04a                	sd	s2,0(sp)
    80003bf6:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003bf8:	c115                	beqz	a0,80003c1c <ilock+0x30>
    80003bfa:	84aa                	mv	s1,a0
    80003bfc:	451c                	lw	a5,8(a0)
    80003bfe:	00f05f63          	blez	a5,80003c1c <ilock+0x30>
  acquiresleep(&ip->lock);
    80003c02:	0541                	addi	a0,a0,16
    80003c04:	00001097          	auipc	ra,0x1
    80003c08:	ca8080e7          	jalr	-856(ra) # 800048ac <acquiresleep>
  if(ip->valid == 0){
    80003c0c:	40bc                	lw	a5,64(s1)
    80003c0e:	cf99                	beqz	a5,80003c2c <ilock+0x40>
}
    80003c10:	60e2                	ld	ra,24(sp)
    80003c12:	6442                	ld	s0,16(sp)
    80003c14:	64a2                	ld	s1,8(sp)
    80003c16:	6902                	ld	s2,0(sp)
    80003c18:	6105                	addi	sp,sp,32
    80003c1a:	8082                	ret
    panic("ilock");
    80003c1c:	00005517          	auipc	a0,0x5
    80003c20:	aa450513          	addi	a0,a0,-1372 # 800086c0 <syscalls+0x1a0>
    80003c24:	ffffd097          	auipc	ra,0xffffd
    80003c28:	91c080e7          	jalr	-1764(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c2c:	40dc                	lw	a5,4(s1)
    80003c2e:	0047d79b          	srliw	a5,a5,0x4
    80003c32:	0001b597          	auipc	a1,0x1b
    80003c36:	7be5a583          	lw	a1,1982(a1) # 8001f3f0 <sb+0x18>
    80003c3a:	9dbd                	addw	a1,a1,a5
    80003c3c:	4088                	lw	a0,0(s1)
    80003c3e:	fffff097          	auipc	ra,0xfffff
    80003c42:	796080e7          	jalr	1942(ra) # 800033d4 <bread>
    80003c46:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c48:	05850593          	addi	a1,a0,88
    80003c4c:	40dc                	lw	a5,4(s1)
    80003c4e:	8bbd                	andi	a5,a5,15
    80003c50:	079a                	slli	a5,a5,0x6
    80003c52:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003c54:	00059783          	lh	a5,0(a1)
    80003c58:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003c5c:	00259783          	lh	a5,2(a1)
    80003c60:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003c64:	00459783          	lh	a5,4(a1)
    80003c68:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003c6c:	00659783          	lh	a5,6(a1)
    80003c70:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003c74:	459c                	lw	a5,8(a1)
    80003c76:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003c78:	03400613          	li	a2,52
    80003c7c:	05b1                	addi	a1,a1,12
    80003c7e:	05048513          	addi	a0,s1,80
    80003c82:	ffffd097          	auipc	ra,0xffffd
    80003c86:	0ac080e7          	jalr	172(ra) # 80000d2e <memmove>
    brelse(bp);
    80003c8a:	854a                	mv	a0,s2
    80003c8c:	00000097          	auipc	ra,0x0
    80003c90:	878080e7          	jalr	-1928(ra) # 80003504 <brelse>
    ip->valid = 1;
    80003c94:	4785                	li	a5,1
    80003c96:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003c98:	04449783          	lh	a5,68(s1)
    80003c9c:	fbb5                	bnez	a5,80003c10 <ilock+0x24>
      panic("ilock: no type");
    80003c9e:	00005517          	auipc	a0,0x5
    80003ca2:	a2a50513          	addi	a0,a0,-1494 # 800086c8 <syscalls+0x1a8>
    80003ca6:	ffffd097          	auipc	ra,0xffffd
    80003caa:	89a080e7          	jalr	-1894(ra) # 80000540 <panic>

0000000080003cae <iunlock>:
{
    80003cae:	1101                	addi	sp,sp,-32
    80003cb0:	ec06                	sd	ra,24(sp)
    80003cb2:	e822                	sd	s0,16(sp)
    80003cb4:	e426                	sd	s1,8(sp)
    80003cb6:	e04a                	sd	s2,0(sp)
    80003cb8:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003cba:	c905                	beqz	a0,80003cea <iunlock+0x3c>
    80003cbc:	84aa                	mv	s1,a0
    80003cbe:	01050913          	addi	s2,a0,16
    80003cc2:	854a                	mv	a0,s2
    80003cc4:	00001097          	auipc	ra,0x1
    80003cc8:	c82080e7          	jalr	-894(ra) # 80004946 <holdingsleep>
    80003ccc:	cd19                	beqz	a0,80003cea <iunlock+0x3c>
    80003cce:	449c                	lw	a5,8(s1)
    80003cd0:	00f05d63          	blez	a5,80003cea <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003cd4:	854a                	mv	a0,s2
    80003cd6:	00001097          	auipc	ra,0x1
    80003cda:	c2c080e7          	jalr	-980(ra) # 80004902 <releasesleep>
}
    80003cde:	60e2                	ld	ra,24(sp)
    80003ce0:	6442                	ld	s0,16(sp)
    80003ce2:	64a2                	ld	s1,8(sp)
    80003ce4:	6902                	ld	s2,0(sp)
    80003ce6:	6105                	addi	sp,sp,32
    80003ce8:	8082                	ret
    panic("iunlock");
    80003cea:	00005517          	auipc	a0,0x5
    80003cee:	9ee50513          	addi	a0,a0,-1554 # 800086d8 <syscalls+0x1b8>
    80003cf2:	ffffd097          	auipc	ra,0xffffd
    80003cf6:	84e080e7          	jalr	-1970(ra) # 80000540 <panic>

0000000080003cfa <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003cfa:	7179                	addi	sp,sp,-48
    80003cfc:	f406                	sd	ra,40(sp)
    80003cfe:	f022                	sd	s0,32(sp)
    80003d00:	ec26                	sd	s1,24(sp)
    80003d02:	e84a                	sd	s2,16(sp)
    80003d04:	e44e                	sd	s3,8(sp)
    80003d06:	e052                	sd	s4,0(sp)
    80003d08:	1800                	addi	s0,sp,48
    80003d0a:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003d0c:	05050493          	addi	s1,a0,80
    80003d10:	08050913          	addi	s2,a0,128
    80003d14:	a021                	j	80003d1c <itrunc+0x22>
    80003d16:	0491                	addi	s1,s1,4
    80003d18:	01248d63          	beq	s1,s2,80003d32 <itrunc+0x38>
    if(ip->addrs[i]){
    80003d1c:	408c                	lw	a1,0(s1)
    80003d1e:	dde5                	beqz	a1,80003d16 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003d20:	0009a503          	lw	a0,0(s3)
    80003d24:	00000097          	auipc	ra,0x0
    80003d28:	8f6080e7          	jalr	-1802(ra) # 8000361a <bfree>
      ip->addrs[i] = 0;
    80003d2c:	0004a023          	sw	zero,0(s1)
    80003d30:	b7dd                	j	80003d16 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003d32:	0809a583          	lw	a1,128(s3)
    80003d36:	e185                	bnez	a1,80003d56 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003d38:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003d3c:	854e                	mv	a0,s3
    80003d3e:	00000097          	auipc	ra,0x0
    80003d42:	de2080e7          	jalr	-542(ra) # 80003b20 <iupdate>
}
    80003d46:	70a2                	ld	ra,40(sp)
    80003d48:	7402                	ld	s0,32(sp)
    80003d4a:	64e2                	ld	s1,24(sp)
    80003d4c:	6942                	ld	s2,16(sp)
    80003d4e:	69a2                	ld	s3,8(sp)
    80003d50:	6a02                	ld	s4,0(sp)
    80003d52:	6145                	addi	sp,sp,48
    80003d54:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003d56:	0009a503          	lw	a0,0(s3)
    80003d5a:	fffff097          	auipc	ra,0xfffff
    80003d5e:	67a080e7          	jalr	1658(ra) # 800033d4 <bread>
    80003d62:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003d64:	05850493          	addi	s1,a0,88
    80003d68:	45850913          	addi	s2,a0,1112
    80003d6c:	a021                	j	80003d74 <itrunc+0x7a>
    80003d6e:	0491                	addi	s1,s1,4
    80003d70:	01248b63          	beq	s1,s2,80003d86 <itrunc+0x8c>
      if(a[j])
    80003d74:	408c                	lw	a1,0(s1)
    80003d76:	dde5                	beqz	a1,80003d6e <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003d78:	0009a503          	lw	a0,0(s3)
    80003d7c:	00000097          	auipc	ra,0x0
    80003d80:	89e080e7          	jalr	-1890(ra) # 8000361a <bfree>
    80003d84:	b7ed                	j	80003d6e <itrunc+0x74>
    brelse(bp);
    80003d86:	8552                	mv	a0,s4
    80003d88:	fffff097          	auipc	ra,0xfffff
    80003d8c:	77c080e7          	jalr	1916(ra) # 80003504 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003d90:	0809a583          	lw	a1,128(s3)
    80003d94:	0009a503          	lw	a0,0(s3)
    80003d98:	00000097          	auipc	ra,0x0
    80003d9c:	882080e7          	jalr	-1918(ra) # 8000361a <bfree>
    ip->addrs[NDIRECT] = 0;
    80003da0:	0809a023          	sw	zero,128(s3)
    80003da4:	bf51                	j	80003d38 <itrunc+0x3e>

0000000080003da6 <iput>:
{
    80003da6:	1101                	addi	sp,sp,-32
    80003da8:	ec06                	sd	ra,24(sp)
    80003daa:	e822                	sd	s0,16(sp)
    80003dac:	e426                	sd	s1,8(sp)
    80003dae:	e04a                	sd	s2,0(sp)
    80003db0:	1000                	addi	s0,sp,32
    80003db2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003db4:	0001b517          	auipc	a0,0x1b
    80003db8:	64450513          	addi	a0,a0,1604 # 8001f3f8 <itable>
    80003dbc:	ffffd097          	auipc	ra,0xffffd
    80003dc0:	e1a080e7          	jalr	-486(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003dc4:	4498                	lw	a4,8(s1)
    80003dc6:	4785                	li	a5,1
    80003dc8:	02f70363          	beq	a4,a5,80003dee <iput+0x48>
  ip->ref--;
    80003dcc:	449c                	lw	a5,8(s1)
    80003dce:	37fd                	addiw	a5,a5,-1
    80003dd0:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003dd2:	0001b517          	auipc	a0,0x1b
    80003dd6:	62650513          	addi	a0,a0,1574 # 8001f3f8 <itable>
    80003dda:	ffffd097          	auipc	ra,0xffffd
    80003dde:	eb0080e7          	jalr	-336(ra) # 80000c8a <release>
}
    80003de2:	60e2                	ld	ra,24(sp)
    80003de4:	6442                	ld	s0,16(sp)
    80003de6:	64a2                	ld	s1,8(sp)
    80003de8:	6902                	ld	s2,0(sp)
    80003dea:	6105                	addi	sp,sp,32
    80003dec:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003dee:	40bc                	lw	a5,64(s1)
    80003df0:	dff1                	beqz	a5,80003dcc <iput+0x26>
    80003df2:	04a49783          	lh	a5,74(s1)
    80003df6:	fbf9                	bnez	a5,80003dcc <iput+0x26>
    acquiresleep(&ip->lock);
    80003df8:	01048913          	addi	s2,s1,16
    80003dfc:	854a                	mv	a0,s2
    80003dfe:	00001097          	auipc	ra,0x1
    80003e02:	aae080e7          	jalr	-1362(ra) # 800048ac <acquiresleep>
    release(&itable.lock);
    80003e06:	0001b517          	auipc	a0,0x1b
    80003e0a:	5f250513          	addi	a0,a0,1522 # 8001f3f8 <itable>
    80003e0e:	ffffd097          	auipc	ra,0xffffd
    80003e12:	e7c080e7          	jalr	-388(ra) # 80000c8a <release>
    itrunc(ip);
    80003e16:	8526                	mv	a0,s1
    80003e18:	00000097          	auipc	ra,0x0
    80003e1c:	ee2080e7          	jalr	-286(ra) # 80003cfa <itrunc>
    ip->type = 0;
    80003e20:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003e24:	8526                	mv	a0,s1
    80003e26:	00000097          	auipc	ra,0x0
    80003e2a:	cfa080e7          	jalr	-774(ra) # 80003b20 <iupdate>
    ip->valid = 0;
    80003e2e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003e32:	854a                	mv	a0,s2
    80003e34:	00001097          	auipc	ra,0x1
    80003e38:	ace080e7          	jalr	-1330(ra) # 80004902 <releasesleep>
    acquire(&itable.lock);
    80003e3c:	0001b517          	auipc	a0,0x1b
    80003e40:	5bc50513          	addi	a0,a0,1468 # 8001f3f8 <itable>
    80003e44:	ffffd097          	auipc	ra,0xffffd
    80003e48:	d92080e7          	jalr	-622(ra) # 80000bd6 <acquire>
    80003e4c:	b741                	j	80003dcc <iput+0x26>

0000000080003e4e <iunlockput>:
{
    80003e4e:	1101                	addi	sp,sp,-32
    80003e50:	ec06                	sd	ra,24(sp)
    80003e52:	e822                	sd	s0,16(sp)
    80003e54:	e426                	sd	s1,8(sp)
    80003e56:	1000                	addi	s0,sp,32
    80003e58:	84aa                	mv	s1,a0
  iunlock(ip);
    80003e5a:	00000097          	auipc	ra,0x0
    80003e5e:	e54080e7          	jalr	-428(ra) # 80003cae <iunlock>
  iput(ip);
    80003e62:	8526                	mv	a0,s1
    80003e64:	00000097          	auipc	ra,0x0
    80003e68:	f42080e7          	jalr	-190(ra) # 80003da6 <iput>
}
    80003e6c:	60e2                	ld	ra,24(sp)
    80003e6e:	6442                	ld	s0,16(sp)
    80003e70:	64a2                	ld	s1,8(sp)
    80003e72:	6105                	addi	sp,sp,32
    80003e74:	8082                	ret

0000000080003e76 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003e76:	1141                	addi	sp,sp,-16
    80003e78:	e422                	sd	s0,8(sp)
    80003e7a:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003e7c:	411c                	lw	a5,0(a0)
    80003e7e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003e80:	415c                	lw	a5,4(a0)
    80003e82:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003e84:	04451783          	lh	a5,68(a0)
    80003e88:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003e8c:	04a51783          	lh	a5,74(a0)
    80003e90:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003e94:	04c56783          	lwu	a5,76(a0)
    80003e98:	e99c                	sd	a5,16(a1)
}
    80003e9a:	6422                	ld	s0,8(sp)
    80003e9c:	0141                	addi	sp,sp,16
    80003e9e:	8082                	ret

0000000080003ea0 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ea0:	457c                	lw	a5,76(a0)
    80003ea2:	0ed7e963          	bltu	a5,a3,80003f94 <readi+0xf4>
{
    80003ea6:	7159                	addi	sp,sp,-112
    80003ea8:	f486                	sd	ra,104(sp)
    80003eaa:	f0a2                	sd	s0,96(sp)
    80003eac:	eca6                	sd	s1,88(sp)
    80003eae:	e8ca                	sd	s2,80(sp)
    80003eb0:	e4ce                	sd	s3,72(sp)
    80003eb2:	e0d2                	sd	s4,64(sp)
    80003eb4:	fc56                	sd	s5,56(sp)
    80003eb6:	f85a                	sd	s6,48(sp)
    80003eb8:	f45e                	sd	s7,40(sp)
    80003eba:	f062                	sd	s8,32(sp)
    80003ebc:	ec66                	sd	s9,24(sp)
    80003ebe:	e86a                	sd	s10,16(sp)
    80003ec0:	e46e                	sd	s11,8(sp)
    80003ec2:	1880                	addi	s0,sp,112
    80003ec4:	8b2a                	mv	s6,a0
    80003ec6:	8bae                	mv	s7,a1
    80003ec8:	8a32                	mv	s4,a2
    80003eca:	84b6                	mv	s1,a3
    80003ecc:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003ece:	9f35                	addw	a4,a4,a3
    return 0;
    80003ed0:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003ed2:	0ad76063          	bltu	a4,a3,80003f72 <readi+0xd2>
  if(off + n > ip->size)
    80003ed6:	00e7f463          	bgeu	a5,a4,80003ede <readi+0x3e>
    n = ip->size - off;
    80003eda:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ede:	0a0a8963          	beqz	s5,80003f90 <readi+0xf0>
    80003ee2:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ee4:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003ee8:	5c7d                	li	s8,-1
    80003eea:	a82d                	j	80003f24 <readi+0x84>
    80003eec:	020d1d93          	slli	s11,s10,0x20
    80003ef0:	020ddd93          	srli	s11,s11,0x20
    80003ef4:	05890613          	addi	a2,s2,88
    80003ef8:	86ee                	mv	a3,s11
    80003efa:	963a                	add	a2,a2,a4
    80003efc:	85d2                	mv	a1,s4
    80003efe:	855e                	mv	a0,s7
    80003f00:	fffff097          	auipc	ra,0xfffff
    80003f04:	922080e7          	jalr	-1758(ra) # 80002822 <either_copyout>
    80003f08:	05850d63          	beq	a0,s8,80003f62 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003f0c:	854a                	mv	a0,s2
    80003f0e:	fffff097          	auipc	ra,0xfffff
    80003f12:	5f6080e7          	jalr	1526(ra) # 80003504 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f16:	013d09bb          	addw	s3,s10,s3
    80003f1a:	009d04bb          	addw	s1,s10,s1
    80003f1e:	9a6e                	add	s4,s4,s11
    80003f20:	0559f763          	bgeu	s3,s5,80003f6e <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003f24:	00a4d59b          	srliw	a1,s1,0xa
    80003f28:	855a                	mv	a0,s6
    80003f2a:	00000097          	auipc	ra,0x0
    80003f2e:	89e080e7          	jalr	-1890(ra) # 800037c8 <bmap>
    80003f32:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003f36:	cd85                	beqz	a1,80003f6e <readi+0xce>
    bp = bread(ip->dev, addr);
    80003f38:	000b2503          	lw	a0,0(s6)
    80003f3c:	fffff097          	auipc	ra,0xfffff
    80003f40:	498080e7          	jalr	1176(ra) # 800033d4 <bread>
    80003f44:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f46:	3ff4f713          	andi	a4,s1,1023
    80003f4a:	40ec87bb          	subw	a5,s9,a4
    80003f4e:	413a86bb          	subw	a3,s5,s3
    80003f52:	8d3e                	mv	s10,a5
    80003f54:	2781                	sext.w	a5,a5
    80003f56:	0006861b          	sext.w	a2,a3
    80003f5a:	f8f679e3          	bgeu	a2,a5,80003eec <readi+0x4c>
    80003f5e:	8d36                	mv	s10,a3
    80003f60:	b771                	j	80003eec <readi+0x4c>
      brelse(bp);
    80003f62:	854a                	mv	a0,s2
    80003f64:	fffff097          	auipc	ra,0xfffff
    80003f68:	5a0080e7          	jalr	1440(ra) # 80003504 <brelse>
      tot = -1;
    80003f6c:	59fd                	li	s3,-1
  }
  return tot;
    80003f6e:	0009851b          	sext.w	a0,s3
}
    80003f72:	70a6                	ld	ra,104(sp)
    80003f74:	7406                	ld	s0,96(sp)
    80003f76:	64e6                	ld	s1,88(sp)
    80003f78:	6946                	ld	s2,80(sp)
    80003f7a:	69a6                	ld	s3,72(sp)
    80003f7c:	6a06                	ld	s4,64(sp)
    80003f7e:	7ae2                	ld	s5,56(sp)
    80003f80:	7b42                	ld	s6,48(sp)
    80003f82:	7ba2                	ld	s7,40(sp)
    80003f84:	7c02                	ld	s8,32(sp)
    80003f86:	6ce2                	ld	s9,24(sp)
    80003f88:	6d42                	ld	s10,16(sp)
    80003f8a:	6da2                	ld	s11,8(sp)
    80003f8c:	6165                	addi	sp,sp,112
    80003f8e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f90:	89d6                	mv	s3,s5
    80003f92:	bff1                	j	80003f6e <readi+0xce>
    return 0;
    80003f94:	4501                	li	a0,0
}
    80003f96:	8082                	ret

0000000080003f98 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f98:	457c                	lw	a5,76(a0)
    80003f9a:	10d7e863          	bltu	a5,a3,800040aa <writei+0x112>
{
    80003f9e:	7159                	addi	sp,sp,-112
    80003fa0:	f486                	sd	ra,104(sp)
    80003fa2:	f0a2                	sd	s0,96(sp)
    80003fa4:	eca6                	sd	s1,88(sp)
    80003fa6:	e8ca                	sd	s2,80(sp)
    80003fa8:	e4ce                	sd	s3,72(sp)
    80003faa:	e0d2                	sd	s4,64(sp)
    80003fac:	fc56                	sd	s5,56(sp)
    80003fae:	f85a                	sd	s6,48(sp)
    80003fb0:	f45e                	sd	s7,40(sp)
    80003fb2:	f062                	sd	s8,32(sp)
    80003fb4:	ec66                	sd	s9,24(sp)
    80003fb6:	e86a                	sd	s10,16(sp)
    80003fb8:	e46e                	sd	s11,8(sp)
    80003fba:	1880                	addi	s0,sp,112
    80003fbc:	8aaa                	mv	s5,a0
    80003fbe:	8bae                	mv	s7,a1
    80003fc0:	8a32                	mv	s4,a2
    80003fc2:	8936                	mv	s2,a3
    80003fc4:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003fc6:	00e687bb          	addw	a5,a3,a4
    80003fca:	0ed7e263          	bltu	a5,a3,800040ae <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003fce:	00043737          	lui	a4,0x43
    80003fd2:	0ef76063          	bltu	a4,a5,800040b2 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003fd6:	0c0b0863          	beqz	s6,800040a6 <writei+0x10e>
    80003fda:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fdc:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003fe0:	5c7d                	li	s8,-1
    80003fe2:	a091                	j	80004026 <writei+0x8e>
    80003fe4:	020d1d93          	slli	s11,s10,0x20
    80003fe8:	020ddd93          	srli	s11,s11,0x20
    80003fec:	05848513          	addi	a0,s1,88
    80003ff0:	86ee                	mv	a3,s11
    80003ff2:	8652                	mv	a2,s4
    80003ff4:	85de                	mv	a1,s7
    80003ff6:	953a                	add	a0,a0,a4
    80003ff8:	fffff097          	auipc	ra,0xfffff
    80003ffc:	880080e7          	jalr	-1920(ra) # 80002878 <either_copyin>
    80004000:	07850263          	beq	a0,s8,80004064 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004004:	8526                	mv	a0,s1
    80004006:	00000097          	auipc	ra,0x0
    8000400a:	788080e7          	jalr	1928(ra) # 8000478e <log_write>
    brelse(bp);
    8000400e:	8526                	mv	a0,s1
    80004010:	fffff097          	auipc	ra,0xfffff
    80004014:	4f4080e7          	jalr	1268(ra) # 80003504 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004018:	013d09bb          	addw	s3,s10,s3
    8000401c:	012d093b          	addw	s2,s10,s2
    80004020:	9a6e                	add	s4,s4,s11
    80004022:	0569f663          	bgeu	s3,s6,8000406e <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80004026:	00a9559b          	srliw	a1,s2,0xa
    8000402a:	8556                	mv	a0,s5
    8000402c:	fffff097          	auipc	ra,0xfffff
    80004030:	79c080e7          	jalr	1948(ra) # 800037c8 <bmap>
    80004034:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004038:	c99d                	beqz	a1,8000406e <writei+0xd6>
    bp = bread(ip->dev, addr);
    8000403a:	000aa503          	lw	a0,0(s5)
    8000403e:	fffff097          	auipc	ra,0xfffff
    80004042:	396080e7          	jalr	918(ra) # 800033d4 <bread>
    80004046:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004048:	3ff97713          	andi	a4,s2,1023
    8000404c:	40ec87bb          	subw	a5,s9,a4
    80004050:	413b06bb          	subw	a3,s6,s3
    80004054:	8d3e                	mv	s10,a5
    80004056:	2781                	sext.w	a5,a5
    80004058:	0006861b          	sext.w	a2,a3
    8000405c:	f8f674e3          	bgeu	a2,a5,80003fe4 <writei+0x4c>
    80004060:	8d36                	mv	s10,a3
    80004062:	b749                	j	80003fe4 <writei+0x4c>
      brelse(bp);
    80004064:	8526                	mv	a0,s1
    80004066:	fffff097          	auipc	ra,0xfffff
    8000406a:	49e080e7          	jalr	1182(ra) # 80003504 <brelse>
  }

  if(off > ip->size)
    8000406e:	04caa783          	lw	a5,76(s5)
    80004072:	0127f463          	bgeu	a5,s2,8000407a <writei+0xe2>
    ip->size = off;
    80004076:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000407a:	8556                	mv	a0,s5
    8000407c:	00000097          	auipc	ra,0x0
    80004080:	aa4080e7          	jalr	-1372(ra) # 80003b20 <iupdate>

  return tot;
    80004084:	0009851b          	sext.w	a0,s3
}
    80004088:	70a6                	ld	ra,104(sp)
    8000408a:	7406                	ld	s0,96(sp)
    8000408c:	64e6                	ld	s1,88(sp)
    8000408e:	6946                	ld	s2,80(sp)
    80004090:	69a6                	ld	s3,72(sp)
    80004092:	6a06                	ld	s4,64(sp)
    80004094:	7ae2                	ld	s5,56(sp)
    80004096:	7b42                	ld	s6,48(sp)
    80004098:	7ba2                	ld	s7,40(sp)
    8000409a:	7c02                	ld	s8,32(sp)
    8000409c:	6ce2                	ld	s9,24(sp)
    8000409e:	6d42                	ld	s10,16(sp)
    800040a0:	6da2                	ld	s11,8(sp)
    800040a2:	6165                	addi	sp,sp,112
    800040a4:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040a6:	89da                	mv	s3,s6
    800040a8:	bfc9                	j	8000407a <writei+0xe2>
    return -1;
    800040aa:	557d                	li	a0,-1
}
    800040ac:	8082                	ret
    return -1;
    800040ae:	557d                	li	a0,-1
    800040b0:	bfe1                	j	80004088 <writei+0xf0>
    return -1;
    800040b2:	557d                	li	a0,-1
    800040b4:	bfd1                	j	80004088 <writei+0xf0>

00000000800040b6 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800040b6:	1141                	addi	sp,sp,-16
    800040b8:	e406                	sd	ra,8(sp)
    800040ba:	e022                	sd	s0,0(sp)
    800040bc:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800040be:	4639                	li	a2,14
    800040c0:	ffffd097          	auipc	ra,0xffffd
    800040c4:	ce2080e7          	jalr	-798(ra) # 80000da2 <strncmp>
}
    800040c8:	60a2                	ld	ra,8(sp)
    800040ca:	6402                	ld	s0,0(sp)
    800040cc:	0141                	addi	sp,sp,16
    800040ce:	8082                	ret

00000000800040d0 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800040d0:	7139                	addi	sp,sp,-64
    800040d2:	fc06                	sd	ra,56(sp)
    800040d4:	f822                	sd	s0,48(sp)
    800040d6:	f426                	sd	s1,40(sp)
    800040d8:	f04a                	sd	s2,32(sp)
    800040da:	ec4e                	sd	s3,24(sp)
    800040dc:	e852                	sd	s4,16(sp)
    800040de:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800040e0:	04451703          	lh	a4,68(a0)
    800040e4:	4785                	li	a5,1
    800040e6:	00f71a63          	bne	a4,a5,800040fa <dirlookup+0x2a>
    800040ea:	892a                	mv	s2,a0
    800040ec:	89ae                	mv	s3,a1
    800040ee:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800040f0:	457c                	lw	a5,76(a0)
    800040f2:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800040f4:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040f6:	e79d                	bnez	a5,80004124 <dirlookup+0x54>
    800040f8:	a8a5                	j	80004170 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800040fa:	00004517          	auipc	a0,0x4
    800040fe:	5e650513          	addi	a0,a0,1510 # 800086e0 <syscalls+0x1c0>
    80004102:	ffffc097          	auipc	ra,0xffffc
    80004106:	43e080e7          	jalr	1086(ra) # 80000540 <panic>
      panic("dirlookup read");
    8000410a:	00004517          	auipc	a0,0x4
    8000410e:	5ee50513          	addi	a0,a0,1518 # 800086f8 <syscalls+0x1d8>
    80004112:	ffffc097          	auipc	ra,0xffffc
    80004116:	42e080e7          	jalr	1070(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000411a:	24c1                	addiw	s1,s1,16
    8000411c:	04c92783          	lw	a5,76(s2)
    80004120:	04f4f763          	bgeu	s1,a5,8000416e <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004124:	4741                	li	a4,16
    80004126:	86a6                	mv	a3,s1
    80004128:	fc040613          	addi	a2,s0,-64
    8000412c:	4581                	li	a1,0
    8000412e:	854a                	mv	a0,s2
    80004130:	00000097          	auipc	ra,0x0
    80004134:	d70080e7          	jalr	-656(ra) # 80003ea0 <readi>
    80004138:	47c1                	li	a5,16
    8000413a:	fcf518e3          	bne	a0,a5,8000410a <dirlookup+0x3a>
    if(de.inum == 0)
    8000413e:	fc045783          	lhu	a5,-64(s0)
    80004142:	dfe1                	beqz	a5,8000411a <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004144:	fc240593          	addi	a1,s0,-62
    80004148:	854e                	mv	a0,s3
    8000414a:	00000097          	auipc	ra,0x0
    8000414e:	f6c080e7          	jalr	-148(ra) # 800040b6 <namecmp>
    80004152:	f561                	bnez	a0,8000411a <dirlookup+0x4a>
      if(poff)
    80004154:	000a0463          	beqz	s4,8000415c <dirlookup+0x8c>
        *poff = off;
    80004158:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000415c:	fc045583          	lhu	a1,-64(s0)
    80004160:	00092503          	lw	a0,0(s2)
    80004164:	fffff097          	auipc	ra,0xfffff
    80004168:	74e080e7          	jalr	1870(ra) # 800038b2 <iget>
    8000416c:	a011                	j	80004170 <dirlookup+0xa0>
  return 0;
    8000416e:	4501                	li	a0,0
}
    80004170:	70e2                	ld	ra,56(sp)
    80004172:	7442                	ld	s0,48(sp)
    80004174:	74a2                	ld	s1,40(sp)
    80004176:	7902                	ld	s2,32(sp)
    80004178:	69e2                	ld	s3,24(sp)
    8000417a:	6a42                	ld	s4,16(sp)
    8000417c:	6121                	addi	sp,sp,64
    8000417e:	8082                	ret

0000000080004180 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004180:	711d                	addi	sp,sp,-96
    80004182:	ec86                	sd	ra,88(sp)
    80004184:	e8a2                	sd	s0,80(sp)
    80004186:	e4a6                	sd	s1,72(sp)
    80004188:	e0ca                	sd	s2,64(sp)
    8000418a:	fc4e                	sd	s3,56(sp)
    8000418c:	f852                	sd	s4,48(sp)
    8000418e:	f456                	sd	s5,40(sp)
    80004190:	f05a                	sd	s6,32(sp)
    80004192:	ec5e                	sd	s7,24(sp)
    80004194:	e862                	sd	s8,16(sp)
    80004196:	e466                	sd	s9,8(sp)
    80004198:	e06a                	sd	s10,0(sp)
    8000419a:	1080                	addi	s0,sp,96
    8000419c:	84aa                	mv	s1,a0
    8000419e:	8b2e                	mv	s6,a1
    800041a0:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800041a2:	00054703          	lbu	a4,0(a0)
    800041a6:	02f00793          	li	a5,47
    800041aa:	02f70363          	beq	a4,a5,800041d0 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800041ae:	ffffe097          	auipc	ra,0xffffe
    800041b2:	a9c080e7          	jalr	-1380(ra) # 80001c4a <myproc>
    800041b6:	15853503          	ld	a0,344(a0)
    800041ba:	00000097          	auipc	ra,0x0
    800041be:	9f4080e7          	jalr	-1548(ra) # 80003bae <idup>
    800041c2:	8a2a                	mv	s4,a0
  while(*path == '/')
    800041c4:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    800041c8:	4cb5                	li	s9,13
  len = path - s;
    800041ca:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800041cc:	4c05                	li	s8,1
    800041ce:	a87d                	j	8000428c <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    800041d0:	4585                	li	a1,1
    800041d2:	4505                	li	a0,1
    800041d4:	fffff097          	auipc	ra,0xfffff
    800041d8:	6de080e7          	jalr	1758(ra) # 800038b2 <iget>
    800041dc:	8a2a                	mv	s4,a0
    800041de:	b7dd                	j	800041c4 <namex+0x44>
      iunlockput(ip);
    800041e0:	8552                	mv	a0,s4
    800041e2:	00000097          	auipc	ra,0x0
    800041e6:	c6c080e7          	jalr	-916(ra) # 80003e4e <iunlockput>
      return 0;
    800041ea:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800041ec:	8552                	mv	a0,s4
    800041ee:	60e6                	ld	ra,88(sp)
    800041f0:	6446                	ld	s0,80(sp)
    800041f2:	64a6                	ld	s1,72(sp)
    800041f4:	6906                	ld	s2,64(sp)
    800041f6:	79e2                	ld	s3,56(sp)
    800041f8:	7a42                	ld	s4,48(sp)
    800041fa:	7aa2                	ld	s5,40(sp)
    800041fc:	7b02                	ld	s6,32(sp)
    800041fe:	6be2                	ld	s7,24(sp)
    80004200:	6c42                	ld	s8,16(sp)
    80004202:	6ca2                	ld	s9,8(sp)
    80004204:	6d02                	ld	s10,0(sp)
    80004206:	6125                	addi	sp,sp,96
    80004208:	8082                	ret
      iunlock(ip);
    8000420a:	8552                	mv	a0,s4
    8000420c:	00000097          	auipc	ra,0x0
    80004210:	aa2080e7          	jalr	-1374(ra) # 80003cae <iunlock>
      return ip;
    80004214:	bfe1                	j	800041ec <namex+0x6c>
      iunlockput(ip);
    80004216:	8552                	mv	a0,s4
    80004218:	00000097          	auipc	ra,0x0
    8000421c:	c36080e7          	jalr	-970(ra) # 80003e4e <iunlockput>
      return 0;
    80004220:	8a4e                	mv	s4,s3
    80004222:	b7e9                	j	800041ec <namex+0x6c>
  len = path - s;
    80004224:	40998633          	sub	a2,s3,s1
    80004228:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    8000422c:	09acd863          	bge	s9,s10,800042bc <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80004230:	4639                	li	a2,14
    80004232:	85a6                	mv	a1,s1
    80004234:	8556                	mv	a0,s5
    80004236:	ffffd097          	auipc	ra,0xffffd
    8000423a:	af8080e7          	jalr	-1288(ra) # 80000d2e <memmove>
    8000423e:	84ce                	mv	s1,s3
  while(*path == '/')
    80004240:	0004c783          	lbu	a5,0(s1)
    80004244:	01279763          	bne	a5,s2,80004252 <namex+0xd2>
    path++;
    80004248:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000424a:	0004c783          	lbu	a5,0(s1)
    8000424e:	ff278de3          	beq	a5,s2,80004248 <namex+0xc8>
    ilock(ip);
    80004252:	8552                	mv	a0,s4
    80004254:	00000097          	auipc	ra,0x0
    80004258:	998080e7          	jalr	-1640(ra) # 80003bec <ilock>
    if(ip->type != T_DIR){
    8000425c:	044a1783          	lh	a5,68(s4)
    80004260:	f98790e3          	bne	a5,s8,800041e0 <namex+0x60>
    if(nameiparent && *path == '\0'){
    80004264:	000b0563          	beqz	s6,8000426e <namex+0xee>
    80004268:	0004c783          	lbu	a5,0(s1)
    8000426c:	dfd9                	beqz	a5,8000420a <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000426e:	865e                	mv	a2,s7
    80004270:	85d6                	mv	a1,s5
    80004272:	8552                	mv	a0,s4
    80004274:	00000097          	auipc	ra,0x0
    80004278:	e5c080e7          	jalr	-420(ra) # 800040d0 <dirlookup>
    8000427c:	89aa                	mv	s3,a0
    8000427e:	dd41                	beqz	a0,80004216 <namex+0x96>
    iunlockput(ip);
    80004280:	8552                	mv	a0,s4
    80004282:	00000097          	auipc	ra,0x0
    80004286:	bcc080e7          	jalr	-1076(ra) # 80003e4e <iunlockput>
    ip = next;
    8000428a:	8a4e                	mv	s4,s3
  while(*path == '/')
    8000428c:	0004c783          	lbu	a5,0(s1)
    80004290:	01279763          	bne	a5,s2,8000429e <namex+0x11e>
    path++;
    80004294:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004296:	0004c783          	lbu	a5,0(s1)
    8000429a:	ff278de3          	beq	a5,s2,80004294 <namex+0x114>
  if(*path == 0)
    8000429e:	cb9d                	beqz	a5,800042d4 <namex+0x154>
  while(*path != '/' && *path != 0)
    800042a0:	0004c783          	lbu	a5,0(s1)
    800042a4:	89a6                	mv	s3,s1
  len = path - s;
    800042a6:	8d5e                	mv	s10,s7
    800042a8:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800042aa:	01278963          	beq	a5,s2,800042bc <namex+0x13c>
    800042ae:	dbbd                	beqz	a5,80004224 <namex+0xa4>
    path++;
    800042b0:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    800042b2:	0009c783          	lbu	a5,0(s3)
    800042b6:	ff279ce3          	bne	a5,s2,800042ae <namex+0x12e>
    800042ba:	b7ad                	j	80004224 <namex+0xa4>
    memmove(name, s, len);
    800042bc:	2601                	sext.w	a2,a2
    800042be:	85a6                	mv	a1,s1
    800042c0:	8556                	mv	a0,s5
    800042c2:	ffffd097          	auipc	ra,0xffffd
    800042c6:	a6c080e7          	jalr	-1428(ra) # 80000d2e <memmove>
    name[len] = 0;
    800042ca:	9d56                	add	s10,s10,s5
    800042cc:	000d0023          	sb	zero,0(s10)
    800042d0:	84ce                	mv	s1,s3
    800042d2:	b7bd                	j	80004240 <namex+0xc0>
  if(nameiparent){
    800042d4:	f00b0ce3          	beqz	s6,800041ec <namex+0x6c>
    iput(ip);
    800042d8:	8552                	mv	a0,s4
    800042da:	00000097          	auipc	ra,0x0
    800042de:	acc080e7          	jalr	-1332(ra) # 80003da6 <iput>
    return 0;
    800042e2:	4a01                	li	s4,0
    800042e4:	b721                	j	800041ec <namex+0x6c>

00000000800042e6 <dirlink>:
{
    800042e6:	7139                	addi	sp,sp,-64
    800042e8:	fc06                	sd	ra,56(sp)
    800042ea:	f822                	sd	s0,48(sp)
    800042ec:	f426                	sd	s1,40(sp)
    800042ee:	f04a                	sd	s2,32(sp)
    800042f0:	ec4e                	sd	s3,24(sp)
    800042f2:	e852                	sd	s4,16(sp)
    800042f4:	0080                	addi	s0,sp,64
    800042f6:	892a                	mv	s2,a0
    800042f8:	8a2e                	mv	s4,a1
    800042fa:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800042fc:	4601                	li	a2,0
    800042fe:	00000097          	auipc	ra,0x0
    80004302:	dd2080e7          	jalr	-558(ra) # 800040d0 <dirlookup>
    80004306:	e93d                	bnez	a0,8000437c <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004308:	04c92483          	lw	s1,76(s2)
    8000430c:	c49d                	beqz	s1,8000433a <dirlink+0x54>
    8000430e:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004310:	4741                	li	a4,16
    80004312:	86a6                	mv	a3,s1
    80004314:	fc040613          	addi	a2,s0,-64
    80004318:	4581                	li	a1,0
    8000431a:	854a                	mv	a0,s2
    8000431c:	00000097          	auipc	ra,0x0
    80004320:	b84080e7          	jalr	-1148(ra) # 80003ea0 <readi>
    80004324:	47c1                	li	a5,16
    80004326:	06f51163          	bne	a0,a5,80004388 <dirlink+0xa2>
    if(de.inum == 0)
    8000432a:	fc045783          	lhu	a5,-64(s0)
    8000432e:	c791                	beqz	a5,8000433a <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004330:	24c1                	addiw	s1,s1,16
    80004332:	04c92783          	lw	a5,76(s2)
    80004336:	fcf4ede3          	bltu	s1,a5,80004310 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000433a:	4639                	li	a2,14
    8000433c:	85d2                	mv	a1,s4
    8000433e:	fc240513          	addi	a0,s0,-62
    80004342:	ffffd097          	auipc	ra,0xffffd
    80004346:	a9c080e7          	jalr	-1380(ra) # 80000dde <strncpy>
  de.inum = inum;
    8000434a:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000434e:	4741                	li	a4,16
    80004350:	86a6                	mv	a3,s1
    80004352:	fc040613          	addi	a2,s0,-64
    80004356:	4581                	li	a1,0
    80004358:	854a                	mv	a0,s2
    8000435a:	00000097          	auipc	ra,0x0
    8000435e:	c3e080e7          	jalr	-962(ra) # 80003f98 <writei>
    80004362:	1541                	addi	a0,a0,-16
    80004364:	00a03533          	snez	a0,a0
    80004368:	40a00533          	neg	a0,a0
}
    8000436c:	70e2                	ld	ra,56(sp)
    8000436e:	7442                	ld	s0,48(sp)
    80004370:	74a2                	ld	s1,40(sp)
    80004372:	7902                	ld	s2,32(sp)
    80004374:	69e2                	ld	s3,24(sp)
    80004376:	6a42                	ld	s4,16(sp)
    80004378:	6121                	addi	sp,sp,64
    8000437a:	8082                	ret
    iput(ip);
    8000437c:	00000097          	auipc	ra,0x0
    80004380:	a2a080e7          	jalr	-1494(ra) # 80003da6 <iput>
    return -1;
    80004384:	557d                	li	a0,-1
    80004386:	b7dd                	j	8000436c <dirlink+0x86>
      panic("dirlink read");
    80004388:	00004517          	auipc	a0,0x4
    8000438c:	38050513          	addi	a0,a0,896 # 80008708 <syscalls+0x1e8>
    80004390:	ffffc097          	auipc	ra,0xffffc
    80004394:	1b0080e7          	jalr	432(ra) # 80000540 <panic>

0000000080004398 <namei>:

struct inode*
namei(char *path)
{
    80004398:	1101                	addi	sp,sp,-32
    8000439a:	ec06                	sd	ra,24(sp)
    8000439c:	e822                	sd	s0,16(sp)
    8000439e:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800043a0:	fe040613          	addi	a2,s0,-32
    800043a4:	4581                	li	a1,0
    800043a6:	00000097          	auipc	ra,0x0
    800043aa:	dda080e7          	jalr	-550(ra) # 80004180 <namex>
}
    800043ae:	60e2                	ld	ra,24(sp)
    800043b0:	6442                	ld	s0,16(sp)
    800043b2:	6105                	addi	sp,sp,32
    800043b4:	8082                	ret

00000000800043b6 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800043b6:	1141                	addi	sp,sp,-16
    800043b8:	e406                	sd	ra,8(sp)
    800043ba:	e022                	sd	s0,0(sp)
    800043bc:	0800                	addi	s0,sp,16
    800043be:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800043c0:	4585                	li	a1,1
    800043c2:	00000097          	auipc	ra,0x0
    800043c6:	dbe080e7          	jalr	-578(ra) # 80004180 <namex>
}
    800043ca:	60a2                	ld	ra,8(sp)
    800043cc:	6402                	ld	s0,0(sp)
    800043ce:	0141                	addi	sp,sp,16
    800043d0:	8082                	ret

00000000800043d2 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800043d2:	1101                	addi	sp,sp,-32
    800043d4:	ec06                	sd	ra,24(sp)
    800043d6:	e822                	sd	s0,16(sp)
    800043d8:	e426                	sd	s1,8(sp)
    800043da:	e04a                	sd	s2,0(sp)
    800043dc:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800043de:	0001d917          	auipc	s2,0x1d
    800043e2:	ac290913          	addi	s2,s2,-1342 # 80020ea0 <log>
    800043e6:	01892583          	lw	a1,24(s2)
    800043ea:	02892503          	lw	a0,40(s2)
    800043ee:	fffff097          	auipc	ra,0xfffff
    800043f2:	fe6080e7          	jalr	-26(ra) # 800033d4 <bread>
    800043f6:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800043f8:	02c92683          	lw	a3,44(s2)
    800043fc:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800043fe:	02d05863          	blez	a3,8000442e <write_head+0x5c>
    80004402:	0001d797          	auipc	a5,0x1d
    80004406:	ace78793          	addi	a5,a5,-1330 # 80020ed0 <log+0x30>
    8000440a:	05c50713          	addi	a4,a0,92
    8000440e:	36fd                	addiw	a3,a3,-1
    80004410:	02069613          	slli	a2,a3,0x20
    80004414:	01e65693          	srli	a3,a2,0x1e
    80004418:	0001d617          	auipc	a2,0x1d
    8000441c:	abc60613          	addi	a2,a2,-1348 # 80020ed4 <log+0x34>
    80004420:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004422:	4390                	lw	a2,0(a5)
    80004424:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004426:	0791                	addi	a5,a5,4
    80004428:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    8000442a:	fed79ce3          	bne	a5,a3,80004422 <write_head+0x50>
  }
  bwrite(buf);
    8000442e:	8526                	mv	a0,s1
    80004430:	fffff097          	auipc	ra,0xfffff
    80004434:	096080e7          	jalr	150(ra) # 800034c6 <bwrite>
  brelse(buf);
    80004438:	8526                	mv	a0,s1
    8000443a:	fffff097          	auipc	ra,0xfffff
    8000443e:	0ca080e7          	jalr	202(ra) # 80003504 <brelse>
}
    80004442:	60e2                	ld	ra,24(sp)
    80004444:	6442                	ld	s0,16(sp)
    80004446:	64a2                	ld	s1,8(sp)
    80004448:	6902                	ld	s2,0(sp)
    8000444a:	6105                	addi	sp,sp,32
    8000444c:	8082                	ret

000000008000444e <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000444e:	0001d797          	auipc	a5,0x1d
    80004452:	a7e7a783          	lw	a5,-1410(a5) # 80020ecc <log+0x2c>
    80004456:	0af05d63          	blez	a5,80004510 <install_trans+0xc2>
{
    8000445a:	7139                	addi	sp,sp,-64
    8000445c:	fc06                	sd	ra,56(sp)
    8000445e:	f822                	sd	s0,48(sp)
    80004460:	f426                	sd	s1,40(sp)
    80004462:	f04a                	sd	s2,32(sp)
    80004464:	ec4e                	sd	s3,24(sp)
    80004466:	e852                	sd	s4,16(sp)
    80004468:	e456                	sd	s5,8(sp)
    8000446a:	e05a                	sd	s6,0(sp)
    8000446c:	0080                	addi	s0,sp,64
    8000446e:	8b2a                	mv	s6,a0
    80004470:	0001da97          	auipc	s5,0x1d
    80004474:	a60a8a93          	addi	s5,s5,-1440 # 80020ed0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004478:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000447a:	0001d997          	auipc	s3,0x1d
    8000447e:	a2698993          	addi	s3,s3,-1498 # 80020ea0 <log>
    80004482:	a00d                	j	800044a4 <install_trans+0x56>
    brelse(lbuf);
    80004484:	854a                	mv	a0,s2
    80004486:	fffff097          	auipc	ra,0xfffff
    8000448a:	07e080e7          	jalr	126(ra) # 80003504 <brelse>
    brelse(dbuf);
    8000448e:	8526                	mv	a0,s1
    80004490:	fffff097          	auipc	ra,0xfffff
    80004494:	074080e7          	jalr	116(ra) # 80003504 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004498:	2a05                	addiw	s4,s4,1
    8000449a:	0a91                	addi	s5,s5,4
    8000449c:	02c9a783          	lw	a5,44(s3)
    800044a0:	04fa5e63          	bge	s4,a5,800044fc <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800044a4:	0189a583          	lw	a1,24(s3)
    800044a8:	014585bb          	addw	a1,a1,s4
    800044ac:	2585                	addiw	a1,a1,1
    800044ae:	0289a503          	lw	a0,40(s3)
    800044b2:	fffff097          	auipc	ra,0xfffff
    800044b6:	f22080e7          	jalr	-222(ra) # 800033d4 <bread>
    800044ba:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800044bc:	000aa583          	lw	a1,0(s5)
    800044c0:	0289a503          	lw	a0,40(s3)
    800044c4:	fffff097          	auipc	ra,0xfffff
    800044c8:	f10080e7          	jalr	-240(ra) # 800033d4 <bread>
    800044cc:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800044ce:	40000613          	li	a2,1024
    800044d2:	05890593          	addi	a1,s2,88
    800044d6:	05850513          	addi	a0,a0,88
    800044da:	ffffd097          	auipc	ra,0xffffd
    800044de:	854080e7          	jalr	-1964(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    800044e2:	8526                	mv	a0,s1
    800044e4:	fffff097          	auipc	ra,0xfffff
    800044e8:	fe2080e7          	jalr	-30(ra) # 800034c6 <bwrite>
    if(recovering == 0)
    800044ec:	f80b1ce3          	bnez	s6,80004484 <install_trans+0x36>
      bunpin(dbuf);
    800044f0:	8526                	mv	a0,s1
    800044f2:	fffff097          	auipc	ra,0xfffff
    800044f6:	0ec080e7          	jalr	236(ra) # 800035de <bunpin>
    800044fa:	b769                	j	80004484 <install_trans+0x36>
}
    800044fc:	70e2                	ld	ra,56(sp)
    800044fe:	7442                	ld	s0,48(sp)
    80004500:	74a2                	ld	s1,40(sp)
    80004502:	7902                	ld	s2,32(sp)
    80004504:	69e2                	ld	s3,24(sp)
    80004506:	6a42                	ld	s4,16(sp)
    80004508:	6aa2                	ld	s5,8(sp)
    8000450a:	6b02                	ld	s6,0(sp)
    8000450c:	6121                	addi	sp,sp,64
    8000450e:	8082                	ret
    80004510:	8082                	ret

0000000080004512 <initlog>:
{
    80004512:	7179                	addi	sp,sp,-48
    80004514:	f406                	sd	ra,40(sp)
    80004516:	f022                	sd	s0,32(sp)
    80004518:	ec26                	sd	s1,24(sp)
    8000451a:	e84a                	sd	s2,16(sp)
    8000451c:	e44e                	sd	s3,8(sp)
    8000451e:	1800                	addi	s0,sp,48
    80004520:	892a                	mv	s2,a0
    80004522:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004524:	0001d497          	auipc	s1,0x1d
    80004528:	97c48493          	addi	s1,s1,-1668 # 80020ea0 <log>
    8000452c:	00004597          	auipc	a1,0x4
    80004530:	1ec58593          	addi	a1,a1,492 # 80008718 <syscalls+0x1f8>
    80004534:	8526                	mv	a0,s1
    80004536:	ffffc097          	auipc	ra,0xffffc
    8000453a:	610080e7          	jalr	1552(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    8000453e:	0149a583          	lw	a1,20(s3)
    80004542:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004544:	0109a783          	lw	a5,16(s3)
    80004548:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000454a:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000454e:	854a                	mv	a0,s2
    80004550:	fffff097          	auipc	ra,0xfffff
    80004554:	e84080e7          	jalr	-380(ra) # 800033d4 <bread>
  log.lh.n = lh->n;
    80004558:	4d34                	lw	a3,88(a0)
    8000455a:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000455c:	02d05663          	blez	a3,80004588 <initlog+0x76>
    80004560:	05c50793          	addi	a5,a0,92
    80004564:	0001d717          	auipc	a4,0x1d
    80004568:	96c70713          	addi	a4,a4,-1684 # 80020ed0 <log+0x30>
    8000456c:	36fd                	addiw	a3,a3,-1
    8000456e:	02069613          	slli	a2,a3,0x20
    80004572:	01e65693          	srli	a3,a2,0x1e
    80004576:	06050613          	addi	a2,a0,96
    8000457a:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    8000457c:	4390                	lw	a2,0(a5)
    8000457e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004580:	0791                	addi	a5,a5,4
    80004582:	0711                	addi	a4,a4,4
    80004584:	fed79ce3          	bne	a5,a3,8000457c <initlog+0x6a>
  brelse(buf);
    80004588:	fffff097          	auipc	ra,0xfffff
    8000458c:	f7c080e7          	jalr	-132(ra) # 80003504 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004590:	4505                	li	a0,1
    80004592:	00000097          	auipc	ra,0x0
    80004596:	ebc080e7          	jalr	-324(ra) # 8000444e <install_trans>
  log.lh.n = 0;
    8000459a:	0001d797          	auipc	a5,0x1d
    8000459e:	9207a923          	sw	zero,-1742(a5) # 80020ecc <log+0x2c>
  write_head(); // clear the log
    800045a2:	00000097          	auipc	ra,0x0
    800045a6:	e30080e7          	jalr	-464(ra) # 800043d2 <write_head>
}
    800045aa:	70a2                	ld	ra,40(sp)
    800045ac:	7402                	ld	s0,32(sp)
    800045ae:	64e2                	ld	s1,24(sp)
    800045b0:	6942                	ld	s2,16(sp)
    800045b2:	69a2                	ld	s3,8(sp)
    800045b4:	6145                	addi	sp,sp,48
    800045b6:	8082                	ret

00000000800045b8 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800045b8:	1101                	addi	sp,sp,-32
    800045ba:	ec06                	sd	ra,24(sp)
    800045bc:	e822                	sd	s0,16(sp)
    800045be:	e426                	sd	s1,8(sp)
    800045c0:	e04a                	sd	s2,0(sp)
    800045c2:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800045c4:	0001d517          	auipc	a0,0x1d
    800045c8:	8dc50513          	addi	a0,a0,-1828 # 80020ea0 <log>
    800045cc:	ffffc097          	auipc	ra,0xffffc
    800045d0:	60a080e7          	jalr	1546(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    800045d4:	0001d497          	auipc	s1,0x1d
    800045d8:	8cc48493          	addi	s1,s1,-1844 # 80020ea0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800045dc:	4979                	li	s2,30
    800045de:	a039                	j	800045ec <begin_op+0x34>
      sleep(&log, &log.lock);
    800045e0:	85a6                	mv	a1,s1
    800045e2:	8526                	mv	a0,s1
    800045e4:	ffffe097          	auipc	ra,0xffffe
    800045e8:	e36080e7          	jalr	-458(ra) # 8000241a <sleep>
    if(log.committing){
    800045ec:	50dc                	lw	a5,36(s1)
    800045ee:	fbed                	bnez	a5,800045e0 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800045f0:	5098                	lw	a4,32(s1)
    800045f2:	2705                	addiw	a4,a4,1
    800045f4:	0007069b          	sext.w	a3,a4
    800045f8:	0027179b          	slliw	a5,a4,0x2
    800045fc:	9fb9                	addw	a5,a5,a4
    800045fe:	0017979b          	slliw	a5,a5,0x1
    80004602:	54d8                	lw	a4,44(s1)
    80004604:	9fb9                	addw	a5,a5,a4
    80004606:	00f95963          	bge	s2,a5,80004618 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000460a:	85a6                	mv	a1,s1
    8000460c:	8526                	mv	a0,s1
    8000460e:	ffffe097          	auipc	ra,0xffffe
    80004612:	e0c080e7          	jalr	-500(ra) # 8000241a <sleep>
    80004616:	bfd9                	j	800045ec <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004618:	0001d517          	auipc	a0,0x1d
    8000461c:	88850513          	addi	a0,a0,-1912 # 80020ea0 <log>
    80004620:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004622:	ffffc097          	auipc	ra,0xffffc
    80004626:	668080e7          	jalr	1640(ra) # 80000c8a <release>
      break;
    }
  }
}
    8000462a:	60e2                	ld	ra,24(sp)
    8000462c:	6442                	ld	s0,16(sp)
    8000462e:	64a2                	ld	s1,8(sp)
    80004630:	6902                	ld	s2,0(sp)
    80004632:	6105                	addi	sp,sp,32
    80004634:	8082                	ret

0000000080004636 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004636:	7139                	addi	sp,sp,-64
    80004638:	fc06                	sd	ra,56(sp)
    8000463a:	f822                	sd	s0,48(sp)
    8000463c:	f426                	sd	s1,40(sp)
    8000463e:	f04a                	sd	s2,32(sp)
    80004640:	ec4e                	sd	s3,24(sp)
    80004642:	e852                	sd	s4,16(sp)
    80004644:	e456                	sd	s5,8(sp)
    80004646:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004648:	0001d497          	auipc	s1,0x1d
    8000464c:	85848493          	addi	s1,s1,-1960 # 80020ea0 <log>
    80004650:	8526                	mv	a0,s1
    80004652:	ffffc097          	auipc	ra,0xffffc
    80004656:	584080e7          	jalr	1412(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    8000465a:	509c                	lw	a5,32(s1)
    8000465c:	37fd                	addiw	a5,a5,-1
    8000465e:	0007891b          	sext.w	s2,a5
    80004662:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004664:	50dc                	lw	a5,36(s1)
    80004666:	e7b9                	bnez	a5,800046b4 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004668:	04091e63          	bnez	s2,800046c4 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000466c:	0001d497          	auipc	s1,0x1d
    80004670:	83448493          	addi	s1,s1,-1996 # 80020ea0 <log>
    80004674:	4785                	li	a5,1
    80004676:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004678:	8526                	mv	a0,s1
    8000467a:	ffffc097          	auipc	ra,0xffffc
    8000467e:	610080e7          	jalr	1552(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004682:	54dc                	lw	a5,44(s1)
    80004684:	06f04763          	bgtz	a5,800046f2 <end_op+0xbc>
    acquire(&log.lock);
    80004688:	0001d497          	auipc	s1,0x1d
    8000468c:	81848493          	addi	s1,s1,-2024 # 80020ea0 <log>
    80004690:	8526                	mv	a0,s1
    80004692:	ffffc097          	auipc	ra,0xffffc
    80004696:	544080e7          	jalr	1348(ra) # 80000bd6 <acquire>
    log.committing = 0;
    8000469a:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000469e:	8526                	mv	a0,s1
    800046a0:	ffffe097          	auipc	ra,0xffffe
    800046a4:	dde080e7          	jalr	-546(ra) # 8000247e <wakeup>
    release(&log.lock);
    800046a8:	8526                	mv	a0,s1
    800046aa:	ffffc097          	auipc	ra,0xffffc
    800046ae:	5e0080e7          	jalr	1504(ra) # 80000c8a <release>
}
    800046b2:	a03d                	j	800046e0 <end_op+0xaa>
    panic("log.committing");
    800046b4:	00004517          	auipc	a0,0x4
    800046b8:	06c50513          	addi	a0,a0,108 # 80008720 <syscalls+0x200>
    800046bc:	ffffc097          	auipc	ra,0xffffc
    800046c0:	e84080e7          	jalr	-380(ra) # 80000540 <panic>
    wakeup(&log);
    800046c4:	0001c497          	auipc	s1,0x1c
    800046c8:	7dc48493          	addi	s1,s1,2012 # 80020ea0 <log>
    800046cc:	8526                	mv	a0,s1
    800046ce:	ffffe097          	auipc	ra,0xffffe
    800046d2:	db0080e7          	jalr	-592(ra) # 8000247e <wakeup>
  release(&log.lock);
    800046d6:	8526                	mv	a0,s1
    800046d8:	ffffc097          	auipc	ra,0xffffc
    800046dc:	5b2080e7          	jalr	1458(ra) # 80000c8a <release>
}
    800046e0:	70e2                	ld	ra,56(sp)
    800046e2:	7442                	ld	s0,48(sp)
    800046e4:	74a2                	ld	s1,40(sp)
    800046e6:	7902                	ld	s2,32(sp)
    800046e8:	69e2                	ld	s3,24(sp)
    800046ea:	6a42                	ld	s4,16(sp)
    800046ec:	6aa2                	ld	s5,8(sp)
    800046ee:	6121                	addi	sp,sp,64
    800046f0:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800046f2:	0001ca97          	auipc	s5,0x1c
    800046f6:	7dea8a93          	addi	s5,s5,2014 # 80020ed0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800046fa:	0001ca17          	auipc	s4,0x1c
    800046fe:	7a6a0a13          	addi	s4,s4,1958 # 80020ea0 <log>
    80004702:	018a2583          	lw	a1,24(s4)
    80004706:	012585bb          	addw	a1,a1,s2
    8000470a:	2585                	addiw	a1,a1,1
    8000470c:	028a2503          	lw	a0,40(s4)
    80004710:	fffff097          	auipc	ra,0xfffff
    80004714:	cc4080e7          	jalr	-828(ra) # 800033d4 <bread>
    80004718:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000471a:	000aa583          	lw	a1,0(s5)
    8000471e:	028a2503          	lw	a0,40(s4)
    80004722:	fffff097          	auipc	ra,0xfffff
    80004726:	cb2080e7          	jalr	-846(ra) # 800033d4 <bread>
    8000472a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000472c:	40000613          	li	a2,1024
    80004730:	05850593          	addi	a1,a0,88
    80004734:	05848513          	addi	a0,s1,88
    80004738:	ffffc097          	auipc	ra,0xffffc
    8000473c:	5f6080e7          	jalr	1526(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    80004740:	8526                	mv	a0,s1
    80004742:	fffff097          	auipc	ra,0xfffff
    80004746:	d84080e7          	jalr	-636(ra) # 800034c6 <bwrite>
    brelse(from);
    8000474a:	854e                	mv	a0,s3
    8000474c:	fffff097          	auipc	ra,0xfffff
    80004750:	db8080e7          	jalr	-584(ra) # 80003504 <brelse>
    brelse(to);
    80004754:	8526                	mv	a0,s1
    80004756:	fffff097          	auipc	ra,0xfffff
    8000475a:	dae080e7          	jalr	-594(ra) # 80003504 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000475e:	2905                	addiw	s2,s2,1
    80004760:	0a91                	addi	s5,s5,4
    80004762:	02ca2783          	lw	a5,44(s4)
    80004766:	f8f94ee3          	blt	s2,a5,80004702 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000476a:	00000097          	auipc	ra,0x0
    8000476e:	c68080e7          	jalr	-920(ra) # 800043d2 <write_head>
    install_trans(0); // Now install writes to home locations
    80004772:	4501                	li	a0,0
    80004774:	00000097          	auipc	ra,0x0
    80004778:	cda080e7          	jalr	-806(ra) # 8000444e <install_trans>
    log.lh.n = 0;
    8000477c:	0001c797          	auipc	a5,0x1c
    80004780:	7407a823          	sw	zero,1872(a5) # 80020ecc <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004784:	00000097          	auipc	ra,0x0
    80004788:	c4e080e7          	jalr	-946(ra) # 800043d2 <write_head>
    8000478c:	bdf5                	j	80004688 <end_op+0x52>

000000008000478e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000478e:	1101                	addi	sp,sp,-32
    80004790:	ec06                	sd	ra,24(sp)
    80004792:	e822                	sd	s0,16(sp)
    80004794:	e426                	sd	s1,8(sp)
    80004796:	e04a                	sd	s2,0(sp)
    80004798:	1000                	addi	s0,sp,32
    8000479a:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000479c:	0001c917          	auipc	s2,0x1c
    800047a0:	70490913          	addi	s2,s2,1796 # 80020ea0 <log>
    800047a4:	854a                	mv	a0,s2
    800047a6:	ffffc097          	auipc	ra,0xffffc
    800047aa:	430080e7          	jalr	1072(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800047ae:	02c92603          	lw	a2,44(s2)
    800047b2:	47f5                	li	a5,29
    800047b4:	06c7c563          	blt	a5,a2,8000481e <log_write+0x90>
    800047b8:	0001c797          	auipc	a5,0x1c
    800047bc:	7047a783          	lw	a5,1796(a5) # 80020ebc <log+0x1c>
    800047c0:	37fd                	addiw	a5,a5,-1
    800047c2:	04f65e63          	bge	a2,a5,8000481e <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800047c6:	0001c797          	auipc	a5,0x1c
    800047ca:	6fa7a783          	lw	a5,1786(a5) # 80020ec0 <log+0x20>
    800047ce:	06f05063          	blez	a5,8000482e <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800047d2:	4781                	li	a5,0
    800047d4:	06c05563          	blez	a2,8000483e <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800047d8:	44cc                	lw	a1,12(s1)
    800047da:	0001c717          	auipc	a4,0x1c
    800047de:	6f670713          	addi	a4,a4,1782 # 80020ed0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800047e2:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800047e4:	4314                	lw	a3,0(a4)
    800047e6:	04b68c63          	beq	a3,a1,8000483e <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800047ea:	2785                	addiw	a5,a5,1
    800047ec:	0711                	addi	a4,a4,4
    800047ee:	fef61be3          	bne	a2,a5,800047e4 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800047f2:	0621                	addi	a2,a2,8
    800047f4:	060a                	slli	a2,a2,0x2
    800047f6:	0001c797          	auipc	a5,0x1c
    800047fa:	6aa78793          	addi	a5,a5,1706 # 80020ea0 <log>
    800047fe:	97b2                	add	a5,a5,a2
    80004800:	44d8                	lw	a4,12(s1)
    80004802:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004804:	8526                	mv	a0,s1
    80004806:	fffff097          	auipc	ra,0xfffff
    8000480a:	d9c080e7          	jalr	-612(ra) # 800035a2 <bpin>
    log.lh.n++;
    8000480e:	0001c717          	auipc	a4,0x1c
    80004812:	69270713          	addi	a4,a4,1682 # 80020ea0 <log>
    80004816:	575c                	lw	a5,44(a4)
    80004818:	2785                	addiw	a5,a5,1
    8000481a:	d75c                	sw	a5,44(a4)
    8000481c:	a82d                	j	80004856 <log_write+0xc8>
    panic("too big a transaction");
    8000481e:	00004517          	auipc	a0,0x4
    80004822:	f1250513          	addi	a0,a0,-238 # 80008730 <syscalls+0x210>
    80004826:	ffffc097          	auipc	ra,0xffffc
    8000482a:	d1a080e7          	jalr	-742(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    8000482e:	00004517          	auipc	a0,0x4
    80004832:	f1a50513          	addi	a0,a0,-230 # 80008748 <syscalls+0x228>
    80004836:	ffffc097          	auipc	ra,0xffffc
    8000483a:	d0a080e7          	jalr	-758(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    8000483e:	00878693          	addi	a3,a5,8
    80004842:	068a                	slli	a3,a3,0x2
    80004844:	0001c717          	auipc	a4,0x1c
    80004848:	65c70713          	addi	a4,a4,1628 # 80020ea0 <log>
    8000484c:	9736                	add	a4,a4,a3
    8000484e:	44d4                	lw	a3,12(s1)
    80004850:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004852:	faf609e3          	beq	a2,a5,80004804 <log_write+0x76>
  }
  release(&log.lock);
    80004856:	0001c517          	auipc	a0,0x1c
    8000485a:	64a50513          	addi	a0,a0,1610 # 80020ea0 <log>
    8000485e:	ffffc097          	auipc	ra,0xffffc
    80004862:	42c080e7          	jalr	1068(ra) # 80000c8a <release>
}
    80004866:	60e2                	ld	ra,24(sp)
    80004868:	6442                	ld	s0,16(sp)
    8000486a:	64a2                	ld	s1,8(sp)
    8000486c:	6902                	ld	s2,0(sp)
    8000486e:	6105                	addi	sp,sp,32
    80004870:	8082                	ret

0000000080004872 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004872:	1101                	addi	sp,sp,-32
    80004874:	ec06                	sd	ra,24(sp)
    80004876:	e822                	sd	s0,16(sp)
    80004878:	e426                	sd	s1,8(sp)
    8000487a:	e04a                	sd	s2,0(sp)
    8000487c:	1000                	addi	s0,sp,32
    8000487e:	84aa                	mv	s1,a0
    80004880:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004882:	00004597          	auipc	a1,0x4
    80004886:	ee658593          	addi	a1,a1,-282 # 80008768 <syscalls+0x248>
    8000488a:	0521                	addi	a0,a0,8
    8000488c:	ffffc097          	auipc	ra,0xffffc
    80004890:	2ba080e7          	jalr	698(ra) # 80000b46 <initlock>
  lk->name = name;
    80004894:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004898:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000489c:	0204a423          	sw	zero,40(s1)
}
    800048a0:	60e2                	ld	ra,24(sp)
    800048a2:	6442                	ld	s0,16(sp)
    800048a4:	64a2                	ld	s1,8(sp)
    800048a6:	6902                	ld	s2,0(sp)
    800048a8:	6105                	addi	sp,sp,32
    800048aa:	8082                	ret

00000000800048ac <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800048ac:	1101                	addi	sp,sp,-32
    800048ae:	ec06                	sd	ra,24(sp)
    800048b0:	e822                	sd	s0,16(sp)
    800048b2:	e426                	sd	s1,8(sp)
    800048b4:	e04a                	sd	s2,0(sp)
    800048b6:	1000                	addi	s0,sp,32
    800048b8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800048ba:	00850913          	addi	s2,a0,8
    800048be:	854a                	mv	a0,s2
    800048c0:	ffffc097          	auipc	ra,0xffffc
    800048c4:	316080e7          	jalr	790(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    800048c8:	409c                	lw	a5,0(s1)
    800048ca:	cb89                	beqz	a5,800048dc <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800048cc:	85ca                	mv	a1,s2
    800048ce:	8526                	mv	a0,s1
    800048d0:	ffffe097          	auipc	ra,0xffffe
    800048d4:	b4a080e7          	jalr	-1206(ra) # 8000241a <sleep>
  while (lk->locked) {
    800048d8:	409c                	lw	a5,0(s1)
    800048da:	fbed                	bnez	a5,800048cc <acquiresleep+0x20>
  }
  lk->locked = 1;
    800048dc:	4785                	li	a5,1
    800048de:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800048e0:	ffffd097          	auipc	ra,0xffffd
    800048e4:	36a080e7          	jalr	874(ra) # 80001c4a <myproc>
    800048e8:	591c                	lw	a5,48(a0)
    800048ea:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800048ec:	854a                	mv	a0,s2
    800048ee:	ffffc097          	auipc	ra,0xffffc
    800048f2:	39c080e7          	jalr	924(ra) # 80000c8a <release>
}
    800048f6:	60e2                	ld	ra,24(sp)
    800048f8:	6442                	ld	s0,16(sp)
    800048fa:	64a2                	ld	s1,8(sp)
    800048fc:	6902                	ld	s2,0(sp)
    800048fe:	6105                	addi	sp,sp,32
    80004900:	8082                	ret

0000000080004902 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004902:	1101                	addi	sp,sp,-32
    80004904:	ec06                	sd	ra,24(sp)
    80004906:	e822                	sd	s0,16(sp)
    80004908:	e426                	sd	s1,8(sp)
    8000490a:	e04a                	sd	s2,0(sp)
    8000490c:	1000                	addi	s0,sp,32
    8000490e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004910:	00850913          	addi	s2,a0,8
    80004914:	854a                	mv	a0,s2
    80004916:	ffffc097          	auipc	ra,0xffffc
    8000491a:	2c0080e7          	jalr	704(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    8000491e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004922:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004926:	8526                	mv	a0,s1
    80004928:	ffffe097          	auipc	ra,0xffffe
    8000492c:	b56080e7          	jalr	-1194(ra) # 8000247e <wakeup>
  release(&lk->lk);
    80004930:	854a                	mv	a0,s2
    80004932:	ffffc097          	auipc	ra,0xffffc
    80004936:	358080e7          	jalr	856(ra) # 80000c8a <release>
}
    8000493a:	60e2                	ld	ra,24(sp)
    8000493c:	6442                	ld	s0,16(sp)
    8000493e:	64a2                	ld	s1,8(sp)
    80004940:	6902                	ld	s2,0(sp)
    80004942:	6105                	addi	sp,sp,32
    80004944:	8082                	ret

0000000080004946 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004946:	7179                	addi	sp,sp,-48
    80004948:	f406                	sd	ra,40(sp)
    8000494a:	f022                	sd	s0,32(sp)
    8000494c:	ec26                	sd	s1,24(sp)
    8000494e:	e84a                	sd	s2,16(sp)
    80004950:	e44e                	sd	s3,8(sp)
    80004952:	1800                	addi	s0,sp,48
    80004954:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004956:	00850913          	addi	s2,a0,8
    8000495a:	854a                	mv	a0,s2
    8000495c:	ffffc097          	auipc	ra,0xffffc
    80004960:	27a080e7          	jalr	634(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004964:	409c                	lw	a5,0(s1)
    80004966:	ef99                	bnez	a5,80004984 <holdingsleep+0x3e>
    80004968:	4481                	li	s1,0
  release(&lk->lk);
    8000496a:	854a                	mv	a0,s2
    8000496c:	ffffc097          	auipc	ra,0xffffc
    80004970:	31e080e7          	jalr	798(ra) # 80000c8a <release>
  return r;
}
    80004974:	8526                	mv	a0,s1
    80004976:	70a2                	ld	ra,40(sp)
    80004978:	7402                	ld	s0,32(sp)
    8000497a:	64e2                	ld	s1,24(sp)
    8000497c:	6942                	ld	s2,16(sp)
    8000497e:	69a2                	ld	s3,8(sp)
    80004980:	6145                	addi	sp,sp,48
    80004982:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004984:	0284a983          	lw	s3,40(s1)
    80004988:	ffffd097          	auipc	ra,0xffffd
    8000498c:	2c2080e7          	jalr	706(ra) # 80001c4a <myproc>
    80004990:	5904                	lw	s1,48(a0)
    80004992:	413484b3          	sub	s1,s1,s3
    80004996:	0014b493          	seqz	s1,s1
    8000499a:	bfc1                	j	8000496a <holdingsleep+0x24>

000000008000499c <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000499c:	1141                	addi	sp,sp,-16
    8000499e:	e406                	sd	ra,8(sp)
    800049a0:	e022                	sd	s0,0(sp)
    800049a2:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800049a4:	00004597          	auipc	a1,0x4
    800049a8:	dd458593          	addi	a1,a1,-556 # 80008778 <syscalls+0x258>
    800049ac:	0001c517          	auipc	a0,0x1c
    800049b0:	63c50513          	addi	a0,a0,1596 # 80020fe8 <ftable>
    800049b4:	ffffc097          	auipc	ra,0xffffc
    800049b8:	192080e7          	jalr	402(ra) # 80000b46 <initlock>
}
    800049bc:	60a2                	ld	ra,8(sp)
    800049be:	6402                	ld	s0,0(sp)
    800049c0:	0141                	addi	sp,sp,16
    800049c2:	8082                	ret

00000000800049c4 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800049c4:	1101                	addi	sp,sp,-32
    800049c6:	ec06                	sd	ra,24(sp)
    800049c8:	e822                	sd	s0,16(sp)
    800049ca:	e426                	sd	s1,8(sp)
    800049cc:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800049ce:	0001c517          	auipc	a0,0x1c
    800049d2:	61a50513          	addi	a0,a0,1562 # 80020fe8 <ftable>
    800049d6:	ffffc097          	auipc	ra,0xffffc
    800049da:	200080e7          	jalr	512(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800049de:	0001c497          	auipc	s1,0x1c
    800049e2:	62248493          	addi	s1,s1,1570 # 80021000 <ftable+0x18>
    800049e6:	0001d717          	auipc	a4,0x1d
    800049ea:	5ba70713          	addi	a4,a4,1466 # 80021fa0 <disk>
    if(f->ref == 0){
    800049ee:	40dc                	lw	a5,4(s1)
    800049f0:	cf99                	beqz	a5,80004a0e <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800049f2:	02848493          	addi	s1,s1,40
    800049f6:	fee49ce3          	bne	s1,a4,800049ee <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800049fa:	0001c517          	auipc	a0,0x1c
    800049fe:	5ee50513          	addi	a0,a0,1518 # 80020fe8 <ftable>
    80004a02:	ffffc097          	auipc	ra,0xffffc
    80004a06:	288080e7          	jalr	648(ra) # 80000c8a <release>
  return 0;
    80004a0a:	4481                	li	s1,0
    80004a0c:	a819                	j	80004a22 <filealloc+0x5e>
      f->ref = 1;
    80004a0e:	4785                	li	a5,1
    80004a10:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004a12:	0001c517          	auipc	a0,0x1c
    80004a16:	5d650513          	addi	a0,a0,1494 # 80020fe8 <ftable>
    80004a1a:	ffffc097          	auipc	ra,0xffffc
    80004a1e:	270080e7          	jalr	624(ra) # 80000c8a <release>
}
    80004a22:	8526                	mv	a0,s1
    80004a24:	60e2                	ld	ra,24(sp)
    80004a26:	6442                	ld	s0,16(sp)
    80004a28:	64a2                	ld	s1,8(sp)
    80004a2a:	6105                	addi	sp,sp,32
    80004a2c:	8082                	ret

0000000080004a2e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004a2e:	1101                	addi	sp,sp,-32
    80004a30:	ec06                	sd	ra,24(sp)
    80004a32:	e822                	sd	s0,16(sp)
    80004a34:	e426                	sd	s1,8(sp)
    80004a36:	1000                	addi	s0,sp,32
    80004a38:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004a3a:	0001c517          	auipc	a0,0x1c
    80004a3e:	5ae50513          	addi	a0,a0,1454 # 80020fe8 <ftable>
    80004a42:	ffffc097          	auipc	ra,0xffffc
    80004a46:	194080e7          	jalr	404(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004a4a:	40dc                	lw	a5,4(s1)
    80004a4c:	02f05263          	blez	a5,80004a70 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004a50:	2785                	addiw	a5,a5,1
    80004a52:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004a54:	0001c517          	auipc	a0,0x1c
    80004a58:	59450513          	addi	a0,a0,1428 # 80020fe8 <ftable>
    80004a5c:	ffffc097          	auipc	ra,0xffffc
    80004a60:	22e080e7          	jalr	558(ra) # 80000c8a <release>
  return f;
}
    80004a64:	8526                	mv	a0,s1
    80004a66:	60e2                	ld	ra,24(sp)
    80004a68:	6442                	ld	s0,16(sp)
    80004a6a:	64a2                	ld	s1,8(sp)
    80004a6c:	6105                	addi	sp,sp,32
    80004a6e:	8082                	ret
    panic("filedup");
    80004a70:	00004517          	auipc	a0,0x4
    80004a74:	d1050513          	addi	a0,a0,-752 # 80008780 <syscalls+0x260>
    80004a78:	ffffc097          	auipc	ra,0xffffc
    80004a7c:	ac8080e7          	jalr	-1336(ra) # 80000540 <panic>

0000000080004a80 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004a80:	7139                	addi	sp,sp,-64
    80004a82:	fc06                	sd	ra,56(sp)
    80004a84:	f822                	sd	s0,48(sp)
    80004a86:	f426                	sd	s1,40(sp)
    80004a88:	f04a                	sd	s2,32(sp)
    80004a8a:	ec4e                	sd	s3,24(sp)
    80004a8c:	e852                	sd	s4,16(sp)
    80004a8e:	e456                	sd	s5,8(sp)
    80004a90:	0080                	addi	s0,sp,64
    80004a92:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004a94:	0001c517          	auipc	a0,0x1c
    80004a98:	55450513          	addi	a0,a0,1364 # 80020fe8 <ftable>
    80004a9c:	ffffc097          	auipc	ra,0xffffc
    80004aa0:	13a080e7          	jalr	314(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004aa4:	40dc                	lw	a5,4(s1)
    80004aa6:	06f05163          	blez	a5,80004b08 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004aaa:	37fd                	addiw	a5,a5,-1
    80004aac:	0007871b          	sext.w	a4,a5
    80004ab0:	c0dc                	sw	a5,4(s1)
    80004ab2:	06e04363          	bgtz	a4,80004b18 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004ab6:	0004a903          	lw	s2,0(s1)
    80004aba:	0094ca83          	lbu	s5,9(s1)
    80004abe:	0104ba03          	ld	s4,16(s1)
    80004ac2:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004ac6:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004aca:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004ace:	0001c517          	auipc	a0,0x1c
    80004ad2:	51a50513          	addi	a0,a0,1306 # 80020fe8 <ftable>
    80004ad6:	ffffc097          	auipc	ra,0xffffc
    80004ada:	1b4080e7          	jalr	436(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    80004ade:	4785                	li	a5,1
    80004ae0:	04f90d63          	beq	s2,a5,80004b3a <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004ae4:	3979                	addiw	s2,s2,-2
    80004ae6:	4785                	li	a5,1
    80004ae8:	0527e063          	bltu	a5,s2,80004b28 <fileclose+0xa8>
    begin_op();
    80004aec:	00000097          	auipc	ra,0x0
    80004af0:	acc080e7          	jalr	-1332(ra) # 800045b8 <begin_op>
    iput(ff.ip);
    80004af4:	854e                	mv	a0,s3
    80004af6:	fffff097          	auipc	ra,0xfffff
    80004afa:	2b0080e7          	jalr	688(ra) # 80003da6 <iput>
    end_op();
    80004afe:	00000097          	auipc	ra,0x0
    80004b02:	b38080e7          	jalr	-1224(ra) # 80004636 <end_op>
    80004b06:	a00d                	j	80004b28 <fileclose+0xa8>
    panic("fileclose");
    80004b08:	00004517          	auipc	a0,0x4
    80004b0c:	c8050513          	addi	a0,a0,-896 # 80008788 <syscalls+0x268>
    80004b10:	ffffc097          	auipc	ra,0xffffc
    80004b14:	a30080e7          	jalr	-1488(ra) # 80000540 <panic>
    release(&ftable.lock);
    80004b18:	0001c517          	auipc	a0,0x1c
    80004b1c:	4d050513          	addi	a0,a0,1232 # 80020fe8 <ftable>
    80004b20:	ffffc097          	auipc	ra,0xffffc
    80004b24:	16a080e7          	jalr	362(ra) # 80000c8a <release>
  }
}
    80004b28:	70e2                	ld	ra,56(sp)
    80004b2a:	7442                	ld	s0,48(sp)
    80004b2c:	74a2                	ld	s1,40(sp)
    80004b2e:	7902                	ld	s2,32(sp)
    80004b30:	69e2                	ld	s3,24(sp)
    80004b32:	6a42                	ld	s4,16(sp)
    80004b34:	6aa2                	ld	s5,8(sp)
    80004b36:	6121                	addi	sp,sp,64
    80004b38:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004b3a:	85d6                	mv	a1,s5
    80004b3c:	8552                	mv	a0,s4
    80004b3e:	00000097          	auipc	ra,0x0
    80004b42:	34c080e7          	jalr	844(ra) # 80004e8a <pipeclose>
    80004b46:	b7cd                	j	80004b28 <fileclose+0xa8>

0000000080004b48 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004b48:	715d                	addi	sp,sp,-80
    80004b4a:	e486                	sd	ra,72(sp)
    80004b4c:	e0a2                	sd	s0,64(sp)
    80004b4e:	fc26                	sd	s1,56(sp)
    80004b50:	f84a                	sd	s2,48(sp)
    80004b52:	f44e                	sd	s3,40(sp)
    80004b54:	0880                	addi	s0,sp,80
    80004b56:	84aa                	mv	s1,a0
    80004b58:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004b5a:	ffffd097          	auipc	ra,0xffffd
    80004b5e:	0f0080e7          	jalr	240(ra) # 80001c4a <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004b62:	409c                	lw	a5,0(s1)
    80004b64:	37f9                	addiw	a5,a5,-2
    80004b66:	4705                	li	a4,1
    80004b68:	04f76763          	bltu	a4,a5,80004bb6 <filestat+0x6e>
    80004b6c:	892a                	mv	s2,a0
    ilock(f->ip);
    80004b6e:	6c88                	ld	a0,24(s1)
    80004b70:	fffff097          	auipc	ra,0xfffff
    80004b74:	07c080e7          	jalr	124(ra) # 80003bec <ilock>
    stati(f->ip, &st);
    80004b78:	fb840593          	addi	a1,s0,-72
    80004b7c:	6c88                	ld	a0,24(s1)
    80004b7e:	fffff097          	auipc	ra,0xfffff
    80004b82:	2f8080e7          	jalr	760(ra) # 80003e76 <stati>
    iunlock(f->ip);
    80004b86:	6c88                	ld	a0,24(s1)
    80004b88:	fffff097          	auipc	ra,0xfffff
    80004b8c:	126080e7          	jalr	294(ra) # 80003cae <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004b90:	46e1                	li	a3,24
    80004b92:	fb840613          	addi	a2,s0,-72
    80004b96:	85ce                	mv	a1,s3
    80004b98:	05893503          	ld	a0,88(s2)
    80004b9c:	ffffd097          	auipc	ra,0xffffd
    80004ba0:	ad0080e7          	jalr	-1328(ra) # 8000166c <copyout>
    80004ba4:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004ba8:	60a6                	ld	ra,72(sp)
    80004baa:	6406                	ld	s0,64(sp)
    80004bac:	74e2                	ld	s1,56(sp)
    80004bae:	7942                	ld	s2,48(sp)
    80004bb0:	79a2                	ld	s3,40(sp)
    80004bb2:	6161                	addi	sp,sp,80
    80004bb4:	8082                	ret
  return -1;
    80004bb6:	557d                	li	a0,-1
    80004bb8:	bfc5                	j	80004ba8 <filestat+0x60>

0000000080004bba <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004bba:	7179                	addi	sp,sp,-48
    80004bbc:	f406                	sd	ra,40(sp)
    80004bbe:	f022                	sd	s0,32(sp)
    80004bc0:	ec26                	sd	s1,24(sp)
    80004bc2:	e84a                	sd	s2,16(sp)
    80004bc4:	e44e                	sd	s3,8(sp)
    80004bc6:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004bc8:	00854783          	lbu	a5,8(a0)
    80004bcc:	c3d5                	beqz	a5,80004c70 <fileread+0xb6>
    80004bce:	84aa                	mv	s1,a0
    80004bd0:	89ae                	mv	s3,a1
    80004bd2:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004bd4:	411c                	lw	a5,0(a0)
    80004bd6:	4705                	li	a4,1
    80004bd8:	04e78963          	beq	a5,a4,80004c2a <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004bdc:	470d                	li	a4,3
    80004bde:	04e78d63          	beq	a5,a4,80004c38 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004be2:	4709                	li	a4,2
    80004be4:	06e79e63          	bne	a5,a4,80004c60 <fileread+0xa6>
    ilock(f->ip);
    80004be8:	6d08                	ld	a0,24(a0)
    80004bea:	fffff097          	auipc	ra,0xfffff
    80004bee:	002080e7          	jalr	2(ra) # 80003bec <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004bf2:	874a                	mv	a4,s2
    80004bf4:	5094                	lw	a3,32(s1)
    80004bf6:	864e                	mv	a2,s3
    80004bf8:	4585                	li	a1,1
    80004bfa:	6c88                	ld	a0,24(s1)
    80004bfc:	fffff097          	auipc	ra,0xfffff
    80004c00:	2a4080e7          	jalr	676(ra) # 80003ea0 <readi>
    80004c04:	892a                	mv	s2,a0
    80004c06:	00a05563          	blez	a0,80004c10 <fileread+0x56>
      f->off += r;
    80004c0a:	509c                	lw	a5,32(s1)
    80004c0c:	9fa9                	addw	a5,a5,a0
    80004c0e:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004c10:	6c88                	ld	a0,24(s1)
    80004c12:	fffff097          	auipc	ra,0xfffff
    80004c16:	09c080e7          	jalr	156(ra) # 80003cae <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004c1a:	854a                	mv	a0,s2
    80004c1c:	70a2                	ld	ra,40(sp)
    80004c1e:	7402                	ld	s0,32(sp)
    80004c20:	64e2                	ld	s1,24(sp)
    80004c22:	6942                	ld	s2,16(sp)
    80004c24:	69a2                	ld	s3,8(sp)
    80004c26:	6145                	addi	sp,sp,48
    80004c28:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004c2a:	6908                	ld	a0,16(a0)
    80004c2c:	00000097          	auipc	ra,0x0
    80004c30:	3c6080e7          	jalr	966(ra) # 80004ff2 <piperead>
    80004c34:	892a                	mv	s2,a0
    80004c36:	b7d5                	j	80004c1a <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004c38:	02451783          	lh	a5,36(a0)
    80004c3c:	03079693          	slli	a3,a5,0x30
    80004c40:	92c1                	srli	a3,a3,0x30
    80004c42:	4725                	li	a4,9
    80004c44:	02d76863          	bltu	a4,a3,80004c74 <fileread+0xba>
    80004c48:	0792                	slli	a5,a5,0x4
    80004c4a:	0001c717          	auipc	a4,0x1c
    80004c4e:	2fe70713          	addi	a4,a4,766 # 80020f48 <devsw>
    80004c52:	97ba                	add	a5,a5,a4
    80004c54:	639c                	ld	a5,0(a5)
    80004c56:	c38d                	beqz	a5,80004c78 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004c58:	4505                	li	a0,1
    80004c5a:	9782                	jalr	a5
    80004c5c:	892a                	mv	s2,a0
    80004c5e:	bf75                	j	80004c1a <fileread+0x60>
    panic("fileread");
    80004c60:	00004517          	auipc	a0,0x4
    80004c64:	b3850513          	addi	a0,a0,-1224 # 80008798 <syscalls+0x278>
    80004c68:	ffffc097          	auipc	ra,0xffffc
    80004c6c:	8d8080e7          	jalr	-1832(ra) # 80000540 <panic>
    return -1;
    80004c70:	597d                	li	s2,-1
    80004c72:	b765                	j	80004c1a <fileread+0x60>
      return -1;
    80004c74:	597d                	li	s2,-1
    80004c76:	b755                	j	80004c1a <fileread+0x60>
    80004c78:	597d                	li	s2,-1
    80004c7a:	b745                	j	80004c1a <fileread+0x60>

0000000080004c7c <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004c7c:	715d                	addi	sp,sp,-80
    80004c7e:	e486                	sd	ra,72(sp)
    80004c80:	e0a2                	sd	s0,64(sp)
    80004c82:	fc26                	sd	s1,56(sp)
    80004c84:	f84a                	sd	s2,48(sp)
    80004c86:	f44e                	sd	s3,40(sp)
    80004c88:	f052                	sd	s4,32(sp)
    80004c8a:	ec56                	sd	s5,24(sp)
    80004c8c:	e85a                	sd	s6,16(sp)
    80004c8e:	e45e                	sd	s7,8(sp)
    80004c90:	e062                	sd	s8,0(sp)
    80004c92:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004c94:	00954783          	lbu	a5,9(a0)
    80004c98:	10078663          	beqz	a5,80004da4 <filewrite+0x128>
    80004c9c:	892a                	mv	s2,a0
    80004c9e:	8b2e                	mv	s6,a1
    80004ca0:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ca2:	411c                	lw	a5,0(a0)
    80004ca4:	4705                	li	a4,1
    80004ca6:	02e78263          	beq	a5,a4,80004cca <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004caa:	470d                	li	a4,3
    80004cac:	02e78663          	beq	a5,a4,80004cd8 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004cb0:	4709                	li	a4,2
    80004cb2:	0ee79163          	bne	a5,a4,80004d94 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004cb6:	0ac05d63          	blez	a2,80004d70 <filewrite+0xf4>
    int i = 0;
    80004cba:	4981                	li	s3,0
    80004cbc:	6b85                	lui	s7,0x1
    80004cbe:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004cc2:	6c05                	lui	s8,0x1
    80004cc4:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004cc8:	a861                	j	80004d60 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004cca:	6908                	ld	a0,16(a0)
    80004ccc:	00000097          	auipc	ra,0x0
    80004cd0:	22e080e7          	jalr	558(ra) # 80004efa <pipewrite>
    80004cd4:	8a2a                	mv	s4,a0
    80004cd6:	a045                	j	80004d76 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004cd8:	02451783          	lh	a5,36(a0)
    80004cdc:	03079693          	slli	a3,a5,0x30
    80004ce0:	92c1                	srli	a3,a3,0x30
    80004ce2:	4725                	li	a4,9
    80004ce4:	0cd76263          	bltu	a4,a3,80004da8 <filewrite+0x12c>
    80004ce8:	0792                	slli	a5,a5,0x4
    80004cea:	0001c717          	auipc	a4,0x1c
    80004cee:	25e70713          	addi	a4,a4,606 # 80020f48 <devsw>
    80004cf2:	97ba                	add	a5,a5,a4
    80004cf4:	679c                	ld	a5,8(a5)
    80004cf6:	cbdd                	beqz	a5,80004dac <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004cf8:	4505                	li	a0,1
    80004cfa:	9782                	jalr	a5
    80004cfc:	8a2a                	mv	s4,a0
    80004cfe:	a8a5                	j	80004d76 <filewrite+0xfa>
    80004d00:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004d04:	00000097          	auipc	ra,0x0
    80004d08:	8b4080e7          	jalr	-1868(ra) # 800045b8 <begin_op>
      ilock(f->ip);
    80004d0c:	01893503          	ld	a0,24(s2)
    80004d10:	fffff097          	auipc	ra,0xfffff
    80004d14:	edc080e7          	jalr	-292(ra) # 80003bec <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004d18:	8756                	mv	a4,s5
    80004d1a:	02092683          	lw	a3,32(s2)
    80004d1e:	01698633          	add	a2,s3,s6
    80004d22:	4585                	li	a1,1
    80004d24:	01893503          	ld	a0,24(s2)
    80004d28:	fffff097          	auipc	ra,0xfffff
    80004d2c:	270080e7          	jalr	624(ra) # 80003f98 <writei>
    80004d30:	84aa                	mv	s1,a0
    80004d32:	00a05763          	blez	a0,80004d40 <filewrite+0xc4>
        f->off += r;
    80004d36:	02092783          	lw	a5,32(s2)
    80004d3a:	9fa9                	addw	a5,a5,a0
    80004d3c:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004d40:	01893503          	ld	a0,24(s2)
    80004d44:	fffff097          	auipc	ra,0xfffff
    80004d48:	f6a080e7          	jalr	-150(ra) # 80003cae <iunlock>
      end_op();
    80004d4c:	00000097          	auipc	ra,0x0
    80004d50:	8ea080e7          	jalr	-1814(ra) # 80004636 <end_op>

      if(r != n1){
    80004d54:	009a9f63          	bne	s5,s1,80004d72 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004d58:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004d5c:	0149db63          	bge	s3,s4,80004d72 <filewrite+0xf6>
      int n1 = n - i;
    80004d60:	413a04bb          	subw	s1,s4,s3
    80004d64:	0004879b          	sext.w	a5,s1
    80004d68:	f8fbdce3          	bge	s7,a5,80004d00 <filewrite+0x84>
    80004d6c:	84e2                	mv	s1,s8
    80004d6e:	bf49                	j	80004d00 <filewrite+0x84>
    int i = 0;
    80004d70:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004d72:	013a1f63          	bne	s4,s3,80004d90 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004d76:	8552                	mv	a0,s4
    80004d78:	60a6                	ld	ra,72(sp)
    80004d7a:	6406                	ld	s0,64(sp)
    80004d7c:	74e2                	ld	s1,56(sp)
    80004d7e:	7942                	ld	s2,48(sp)
    80004d80:	79a2                	ld	s3,40(sp)
    80004d82:	7a02                	ld	s4,32(sp)
    80004d84:	6ae2                	ld	s5,24(sp)
    80004d86:	6b42                	ld	s6,16(sp)
    80004d88:	6ba2                	ld	s7,8(sp)
    80004d8a:	6c02                	ld	s8,0(sp)
    80004d8c:	6161                	addi	sp,sp,80
    80004d8e:	8082                	ret
    ret = (i == n ? n : -1);
    80004d90:	5a7d                	li	s4,-1
    80004d92:	b7d5                	j	80004d76 <filewrite+0xfa>
    panic("filewrite");
    80004d94:	00004517          	auipc	a0,0x4
    80004d98:	a1450513          	addi	a0,a0,-1516 # 800087a8 <syscalls+0x288>
    80004d9c:	ffffb097          	auipc	ra,0xffffb
    80004da0:	7a4080e7          	jalr	1956(ra) # 80000540 <panic>
    return -1;
    80004da4:	5a7d                	li	s4,-1
    80004da6:	bfc1                	j	80004d76 <filewrite+0xfa>
      return -1;
    80004da8:	5a7d                	li	s4,-1
    80004daa:	b7f1                	j	80004d76 <filewrite+0xfa>
    80004dac:	5a7d                	li	s4,-1
    80004dae:	b7e1                	j	80004d76 <filewrite+0xfa>

0000000080004db0 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004db0:	7179                	addi	sp,sp,-48
    80004db2:	f406                	sd	ra,40(sp)
    80004db4:	f022                	sd	s0,32(sp)
    80004db6:	ec26                	sd	s1,24(sp)
    80004db8:	e84a                	sd	s2,16(sp)
    80004dba:	e44e                	sd	s3,8(sp)
    80004dbc:	e052                	sd	s4,0(sp)
    80004dbe:	1800                	addi	s0,sp,48
    80004dc0:	84aa                	mv	s1,a0
    80004dc2:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004dc4:	0005b023          	sd	zero,0(a1)
    80004dc8:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004dcc:	00000097          	auipc	ra,0x0
    80004dd0:	bf8080e7          	jalr	-1032(ra) # 800049c4 <filealloc>
    80004dd4:	e088                	sd	a0,0(s1)
    80004dd6:	c551                	beqz	a0,80004e62 <pipealloc+0xb2>
    80004dd8:	00000097          	auipc	ra,0x0
    80004ddc:	bec080e7          	jalr	-1044(ra) # 800049c4 <filealloc>
    80004de0:	00aa3023          	sd	a0,0(s4)
    80004de4:	c92d                	beqz	a0,80004e56 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004de6:	ffffc097          	auipc	ra,0xffffc
    80004dea:	d00080e7          	jalr	-768(ra) # 80000ae6 <kalloc>
    80004dee:	892a                	mv	s2,a0
    80004df0:	c125                	beqz	a0,80004e50 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004df2:	4985                	li	s3,1
    80004df4:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004df8:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004dfc:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004e00:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004e04:	00004597          	auipc	a1,0x4
    80004e08:	9b458593          	addi	a1,a1,-1612 # 800087b8 <syscalls+0x298>
    80004e0c:	ffffc097          	auipc	ra,0xffffc
    80004e10:	d3a080e7          	jalr	-710(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004e14:	609c                	ld	a5,0(s1)
    80004e16:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004e1a:	609c                	ld	a5,0(s1)
    80004e1c:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004e20:	609c                	ld	a5,0(s1)
    80004e22:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004e26:	609c                	ld	a5,0(s1)
    80004e28:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004e2c:	000a3783          	ld	a5,0(s4)
    80004e30:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004e34:	000a3783          	ld	a5,0(s4)
    80004e38:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004e3c:	000a3783          	ld	a5,0(s4)
    80004e40:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004e44:	000a3783          	ld	a5,0(s4)
    80004e48:	0127b823          	sd	s2,16(a5)
  return 0;
    80004e4c:	4501                	li	a0,0
    80004e4e:	a025                	j	80004e76 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004e50:	6088                	ld	a0,0(s1)
    80004e52:	e501                	bnez	a0,80004e5a <pipealloc+0xaa>
    80004e54:	a039                	j	80004e62 <pipealloc+0xb2>
    80004e56:	6088                	ld	a0,0(s1)
    80004e58:	c51d                	beqz	a0,80004e86 <pipealloc+0xd6>
    fileclose(*f0);
    80004e5a:	00000097          	auipc	ra,0x0
    80004e5e:	c26080e7          	jalr	-986(ra) # 80004a80 <fileclose>
  if(*f1)
    80004e62:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004e66:	557d                	li	a0,-1
  if(*f1)
    80004e68:	c799                	beqz	a5,80004e76 <pipealloc+0xc6>
    fileclose(*f1);
    80004e6a:	853e                	mv	a0,a5
    80004e6c:	00000097          	auipc	ra,0x0
    80004e70:	c14080e7          	jalr	-1004(ra) # 80004a80 <fileclose>
  return -1;
    80004e74:	557d                	li	a0,-1
}
    80004e76:	70a2                	ld	ra,40(sp)
    80004e78:	7402                	ld	s0,32(sp)
    80004e7a:	64e2                	ld	s1,24(sp)
    80004e7c:	6942                	ld	s2,16(sp)
    80004e7e:	69a2                	ld	s3,8(sp)
    80004e80:	6a02                	ld	s4,0(sp)
    80004e82:	6145                	addi	sp,sp,48
    80004e84:	8082                	ret
  return -1;
    80004e86:	557d                	li	a0,-1
    80004e88:	b7fd                	j	80004e76 <pipealloc+0xc6>

0000000080004e8a <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004e8a:	1101                	addi	sp,sp,-32
    80004e8c:	ec06                	sd	ra,24(sp)
    80004e8e:	e822                	sd	s0,16(sp)
    80004e90:	e426                	sd	s1,8(sp)
    80004e92:	e04a                	sd	s2,0(sp)
    80004e94:	1000                	addi	s0,sp,32
    80004e96:	84aa                	mv	s1,a0
    80004e98:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004e9a:	ffffc097          	auipc	ra,0xffffc
    80004e9e:	d3c080e7          	jalr	-708(ra) # 80000bd6 <acquire>
  if(writable){
    80004ea2:	02090d63          	beqz	s2,80004edc <pipeclose+0x52>
    pi->writeopen = 0;
    80004ea6:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004eaa:	21848513          	addi	a0,s1,536
    80004eae:	ffffd097          	auipc	ra,0xffffd
    80004eb2:	5d0080e7          	jalr	1488(ra) # 8000247e <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004eb6:	2204b783          	ld	a5,544(s1)
    80004eba:	eb95                	bnez	a5,80004eee <pipeclose+0x64>
    release(&pi->lock);
    80004ebc:	8526                	mv	a0,s1
    80004ebe:	ffffc097          	auipc	ra,0xffffc
    80004ec2:	dcc080e7          	jalr	-564(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004ec6:	8526                	mv	a0,s1
    80004ec8:	ffffc097          	auipc	ra,0xffffc
    80004ecc:	b20080e7          	jalr	-1248(ra) # 800009e8 <kfree>
  } else
    release(&pi->lock);
}
    80004ed0:	60e2                	ld	ra,24(sp)
    80004ed2:	6442                	ld	s0,16(sp)
    80004ed4:	64a2                	ld	s1,8(sp)
    80004ed6:	6902                	ld	s2,0(sp)
    80004ed8:	6105                	addi	sp,sp,32
    80004eda:	8082                	ret
    pi->readopen = 0;
    80004edc:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004ee0:	21c48513          	addi	a0,s1,540
    80004ee4:	ffffd097          	auipc	ra,0xffffd
    80004ee8:	59a080e7          	jalr	1434(ra) # 8000247e <wakeup>
    80004eec:	b7e9                	j	80004eb6 <pipeclose+0x2c>
    release(&pi->lock);
    80004eee:	8526                	mv	a0,s1
    80004ef0:	ffffc097          	auipc	ra,0xffffc
    80004ef4:	d9a080e7          	jalr	-614(ra) # 80000c8a <release>
}
    80004ef8:	bfe1                	j	80004ed0 <pipeclose+0x46>

0000000080004efa <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004efa:	711d                	addi	sp,sp,-96
    80004efc:	ec86                	sd	ra,88(sp)
    80004efe:	e8a2                	sd	s0,80(sp)
    80004f00:	e4a6                	sd	s1,72(sp)
    80004f02:	e0ca                	sd	s2,64(sp)
    80004f04:	fc4e                	sd	s3,56(sp)
    80004f06:	f852                	sd	s4,48(sp)
    80004f08:	f456                	sd	s5,40(sp)
    80004f0a:	f05a                	sd	s6,32(sp)
    80004f0c:	ec5e                	sd	s7,24(sp)
    80004f0e:	e862                	sd	s8,16(sp)
    80004f10:	1080                	addi	s0,sp,96
    80004f12:	84aa                	mv	s1,a0
    80004f14:	8aae                	mv	s5,a1
    80004f16:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004f18:	ffffd097          	auipc	ra,0xffffd
    80004f1c:	d32080e7          	jalr	-718(ra) # 80001c4a <myproc>
    80004f20:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004f22:	8526                	mv	a0,s1
    80004f24:	ffffc097          	auipc	ra,0xffffc
    80004f28:	cb2080e7          	jalr	-846(ra) # 80000bd6 <acquire>
  while(i < n){
    80004f2c:	0b405663          	blez	s4,80004fd8 <pipewrite+0xde>
  int i = 0;
    80004f30:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f32:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004f34:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004f38:	21c48b93          	addi	s7,s1,540
    80004f3c:	a089                	j	80004f7e <pipewrite+0x84>
      release(&pi->lock);
    80004f3e:	8526                	mv	a0,s1
    80004f40:	ffffc097          	auipc	ra,0xffffc
    80004f44:	d4a080e7          	jalr	-694(ra) # 80000c8a <release>
      return -1;
    80004f48:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004f4a:	854a                	mv	a0,s2
    80004f4c:	60e6                	ld	ra,88(sp)
    80004f4e:	6446                	ld	s0,80(sp)
    80004f50:	64a6                	ld	s1,72(sp)
    80004f52:	6906                	ld	s2,64(sp)
    80004f54:	79e2                	ld	s3,56(sp)
    80004f56:	7a42                	ld	s4,48(sp)
    80004f58:	7aa2                	ld	s5,40(sp)
    80004f5a:	7b02                	ld	s6,32(sp)
    80004f5c:	6be2                	ld	s7,24(sp)
    80004f5e:	6c42                	ld	s8,16(sp)
    80004f60:	6125                	addi	sp,sp,96
    80004f62:	8082                	ret
      wakeup(&pi->nread);
    80004f64:	8562                	mv	a0,s8
    80004f66:	ffffd097          	auipc	ra,0xffffd
    80004f6a:	518080e7          	jalr	1304(ra) # 8000247e <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004f6e:	85a6                	mv	a1,s1
    80004f70:	855e                	mv	a0,s7
    80004f72:	ffffd097          	auipc	ra,0xffffd
    80004f76:	4a8080e7          	jalr	1192(ra) # 8000241a <sleep>
  while(i < n){
    80004f7a:	07495063          	bge	s2,s4,80004fda <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004f7e:	2204a783          	lw	a5,544(s1)
    80004f82:	dfd5                	beqz	a5,80004f3e <pipewrite+0x44>
    80004f84:	854e                	mv	a0,s3
    80004f86:	ffffd097          	auipc	ra,0xffffd
    80004f8a:	73c080e7          	jalr	1852(ra) # 800026c2 <killed>
    80004f8e:	f945                	bnez	a0,80004f3e <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004f90:	2184a783          	lw	a5,536(s1)
    80004f94:	21c4a703          	lw	a4,540(s1)
    80004f98:	2007879b          	addiw	a5,a5,512
    80004f9c:	fcf704e3          	beq	a4,a5,80004f64 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004fa0:	4685                	li	a3,1
    80004fa2:	01590633          	add	a2,s2,s5
    80004fa6:	faf40593          	addi	a1,s0,-81
    80004faa:	0589b503          	ld	a0,88(s3)
    80004fae:	ffffc097          	auipc	ra,0xffffc
    80004fb2:	74a080e7          	jalr	1866(ra) # 800016f8 <copyin>
    80004fb6:	03650263          	beq	a0,s6,80004fda <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004fba:	21c4a783          	lw	a5,540(s1)
    80004fbe:	0017871b          	addiw	a4,a5,1
    80004fc2:	20e4ae23          	sw	a4,540(s1)
    80004fc6:	1ff7f793          	andi	a5,a5,511
    80004fca:	97a6                	add	a5,a5,s1
    80004fcc:	faf44703          	lbu	a4,-81(s0)
    80004fd0:	00e78c23          	sb	a4,24(a5)
      i++;
    80004fd4:	2905                	addiw	s2,s2,1
    80004fd6:	b755                	j	80004f7a <pipewrite+0x80>
  int i = 0;
    80004fd8:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004fda:	21848513          	addi	a0,s1,536
    80004fde:	ffffd097          	auipc	ra,0xffffd
    80004fe2:	4a0080e7          	jalr	1184(ra) # 8000247e <wakeup>
  release(&pi->lock);
    80004fe6:	8526                	mv	a0,s1
    80004fe8:	ffffc097          	auipc	ra,0xffffc
    80004fec:	ca2080e7          	jalr	-862(ra) # 80000c8a <release>
  return i;
    80004ff0:	bfa9                	j	80004f4a <pipewrite+0x50>

0000000080004ff2 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004ff2:	715d                	addi	sp,sp,-80
    80004ff4:	e486                	sd	ra,72(sp)
    80004ff6:	e0a2                	sd	s0,64(sp)
    80004ff8:	fc26                	sd	s1,56(sp)
    80004ffa:	f84a                	sd	s2,48(sp)
    80004ffc:	f44e                	sd	s3,40(sp)
    80004ffe:	f052                	sd	s4,32(sp)
    80005000:	ec56                	sd	s5,24(sp)
    80005002:	e85a                	sd	s6,16(sp)
    80005004:	0880                	addi	s0,sp,80
    80005006:	84aa                	mv	s1,a0
    80005008:	892e                	mv	s2,a1
    8000500a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000500c:	ffffd097          	auipc	ra,0xffffd
    80005010:	c3e080e7          	jalr	-962(ra) # 80001c4a <myproc>
    80005014:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005016:	8526                	mv	a0,s1
    80005018:	ffffc097          	auipc	ra,0xffffc
    8000501c:	bbe080e7          	jalr	-1090(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005020:	2184a703          	lw	a4,536(s1)
    80005024:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005028:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000502c:	02f71763          	bne	a4,a5,8000505a <piperead+0x68>
    80005030:	2244a783          	lw	a5,548(s1)
    80005034:	c39d                	beqz	a5,8000505a <piperead+0x68>
    if(killed(pr)){
    80005036:	8552                	mv	a0,s4
    80005038:	ffffd097          	auipc	ra,0xffffd
    8000503c:	68a080e7          	jalr	1674(ra) # 800026c2 <killed>
    80005040:	e949                	bnez	a0,800050d2 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005042:	85a6                	mv	a1,s1
    80005044:	854e                	mv	a0,s3
    80005046:	ffffd097          	auipc	ra,0xffffd
    8000504a:	3d4080e7          	jalr	980(ra) # 8000241a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000504e:	2184a703          	lw	a4,536(s1)
    80005052:	21c4a783          	lw	a5,540(s1)
    80005056:	fcf70de3          	beq	a4,a5,80005030 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000505a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000505c:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000505e:	05505463          	blez	s5,800050a6 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80005062:	2184a783          	lw	a5,536(s1)
    80005066:	21c4a703          	lw	a4,540(s1)
    8000506a:	02f70e63          	beq	a4,a5,800050a6 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000506e:	0017871b          	addiw	a4,a5,1
    80005072:	20e4ac23          	sw	a4,536(s1)
    80005076:	1ff7f793          	andi	a5,a5,511
    8000507a:	97a6                	add	a5,a5,s1
    8000507c:	0187c783          	lbu	a5,24(a5)
    80005080:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005084:	4685                	li	a3,1
    80005086:	fbf40613          	addi	a2,s0,-65
    8000508a:	85ca                	mv	a1,s2
    8000508c:	058a3503          	ld	a0,88(s4)
    80005090:	ffffc097          	auipc	ra,0xffffc
    80005094:	5dc080e7          	jalr	1500(ra) # 8000166c <copyout>
    80005098:	01650763          	beq	a0,s6,800050a6 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000509c:	2985                	addiw	s3,s3,1
    8000509e:	0905                	addi	s2,s2,1
    800050a0:	fd3a91e3          	bne	s5,s3,80005062 <piperead+0x70>
    800050a4:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800050a6:	21c48513          	addi	a0,s1,540
    800050aa:	ffffd097          	auipc	ra,0xffffd
    800050ae:	3d4080e7          	jalr	980(ra) # 8000247e <wakeup>
  release(&pi->lock);
    800050b2:	8526                	mv	a0,s1
    800050b4:	ffffc097          	auipc	ra,0xffffc
    800050b8:	bd6080e7          	jalr	-1066(ra) # 80000c8a <release>
  return i;
}
    800050bc:	854e                	mv	a0,s3
    800050be:	60a6                	ld	ra,72(sp)
    800050c0:	6406                	ld	s0,64(sp)
    800050c2:	74e2                	ld	s1,56(sp)
    800050c4:	7942                	ld	s2,48(sp)
    800050c6:	79a2                	ld	s3,40(sp)
    800050c8:	7a02                	ld	s4,32(sp)
    800050ca:	6ae2                	ld	s5,24(sp)
    800050cc:	6b42                	ld	s6,16(sp)
    800050ce:	6161                	addi	sp,sp,80
    800050d0:	8082                	ret
      release(&pi->lock);
    800050d2:	8526                	mv	a0,s1
    800050d4:	ffffc097          	auipc	ra,0xffffc
    800050d8:	bb6080e7          	jalr	-1098(ra) # 80000c8a <release>
      return -1;
    800050dc:	59fd                	li	s3,-1
    800050de:	bff9                	j	800050bc <piperead+0xca>

00000000800050e0 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    800050e0:	1141                	addi	sp,sp,-16
    800050e2:	e422                	sd	s0,8(sp)
    800050e4:	0800                	addi	s0,sp,16
    800050e6:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    800050e8:	8905                	andi	a0,a0,1
    800050ea:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    800050ec:	8b89                	andi	a5,a5,2
    800050ee:	c399                	beqz	a5,800050f4 <flags2perm+0x14>
      perm |= PTE_W;
    800050f0:	00456513          	ori	a0,a0,4
    return perm;
}
    800050f4:	6422                	ld	s0,8(sp)
    800050f6:	0141                	addi	sp,sp,16
    800050f8:	8082                	ret

00000000800050fa <exec>:

int
exec(char *path, char **argv)
{
    800050fa:	de010113          	addi	sp,sp,-544
    800050fe:	20113c23          	sd	ra,536(sp)
    80005102:	20813823          	sd	s0,528(sp)
    80005106:	20913423          	sd	s1,520(sp)
    8000510a:	21213023          	sd	s2,512(sp)
    8000510e:	ffce                	sd	s3,504(sp)
    80005110:	fbd2                	sd	s4,496(sp)
    80005112:	f7d6                	sd	s5,488(sp)
    80005114:	f3da                	sd	s6,480(sp)
    80005116:	efde                	sd	s7,472(sp)
    80005118:	ebe2                	sd	s8,464(sp)
    8000511a:	e7e6                	sd	s9,456(sp)
    8000511c:	e3ea                	sd	s10,448(sp)
    8000511e:	ff6e                	sd	s11,440(sp)
    80005120:	1400                	addi	s0,sp,544
    80005122:	892a                	mv	s2,a0
    80005124:	dea43423          	sd	a0,-536(s0)
    80005128:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000512c:	ffffd097          	auipc	ra,0xffffd
    80005130:	b1e080e7          	jalr	-1250(ra) # 80001c4a <myproc>
    80005134:	84aa                	mv	s1,a0

  begin_op();
    80005136:	fffff097          	auipc	ra,0xfffff
    8000513a:	482080e7          	jalr	1154(ra) # 800045b8 <begin_op>

  if((ip = namei(path)) == 0){
    8000513e:	854a                	mv	a0,s2
    80005140:	fffff097          	auipc	ra,0xfffff
    80005144:	258080e7          	jalr	600(ra) # 80004398 <namei>
    80005148:	c93d                	beqz	a0,800051be <exec+0xc4>
    8000514a:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000514c:	fffff097          	auipc	ra,0xfffff
    80005150:	aa0080e7          	jalr	-1376(ra) # 80003bec <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005154:	04000713          	li	a4,64
    80005158:	4681                	li	a3,0
    8000515a:	e5040613          	addi	a2,s0,-432
    8000515e:	4581                	li	a1,0
    80005160:	8556                	mv	a0,s5
    80005162:	fffff097          	auipc	ra,0xfffff
    80005166:	d3e080e7          	jalr	-706(ra) # 80003ea0 <readi>
    8000516a:	04000793          	li	a5,64
    8000516e:	00f51a63          	bne	a0,a5,80005182 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80005172:	e5042703          	lw	a4,-432(s0)
    80005176:	464c47b7          	lui	a5,0x464c4
    8000517a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000517e:	04f70663          	beq	a4,a5,800051ca <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005182:	8556                	mv	a0,s5
    80005184:	fffff097          	auipc	ra,0xfffff
    80005188:	cca080e7          	jalr	-822(ra) # 80003e4e <iunlockput>
    end_op();
    8000518c:	fffff097          	auipc	ra,0xfffff
    80005190:	4aa080e7          	jalr	1194(ra) # 80004636 <end_op>
  }
  return -1;
    80005194:	557d                	li	a0,-1
}
    80005196:	21813083          	ld	ra,536(sp)
    8000519a:	21013403          	ld	s0,528(sp)
    8000519e:	20813483          	ld	s1,520(sp)
    800051a2:	20013903          	ld	s2,512(sp)
    800051a6:	79fe                	ld	s3,504(sp)
    800051a8:	7a5e                	ld	s4,496(sp)
    800051aa:	7abe                	ld	s5,488(sp)
    800051ac:	7b1e                	ld	s6,480(sp)
    800051ae:	6bfe                	ld	s7,472(sp)
    800051b0:	6c5e                	ld	s8,464(sp)
    800051b2:	6cbe                	ld	s9,456(sp)
    800051b4:	6d1e                	ld	s10,448(sp)
    800051b6:	7dfa                	ld	s11,440(sp)
    800051b8:	22010113          	addi	sp,sp,544
    800051bc:	8082                	ret
    end_op();
    800051be:	fffff097          	auipc	ra,0xfffff
    800051c2:	478080e7          	jalr	1144(ra) # 80004636 <end_op>
    return -1;
    800051c6:	557d                	li	a0,-1
    800051c8:	b7f9                	j	80005196 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    800051ca:	8526                	mv	a0,s1
    800051cc:	ffffd097          	auipc	ra,0xffffd
    800051d0:	b48080e7          	jalr	-1208(ra) # 80001d14 <proc_pagetable>
    800051d4:	8b2a                	mv	s6,a0
    800051d6:	d555                	beqz	a0,80005182 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051d8:	e7042783          	lw	a5,-400(s0)
    800051dc:	e8845703          	lhu	a4,-376(s0)
    800051e0:	c735                	beqz	a4,8000524c <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800051e2:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051e4:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    800051e8:	6a05                	lui	s4,0x1
    800051ea:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    800051ee:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    800051f2:	6d85                	lui	s11,0x1
    800051f4:	7d7d                	lui	s10,0xfffff
    800051f6:	ac3d                	j	80005434 <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800051f8:	00003517          	auipc	a0,0x3
    800051fc:	5c850513          	addi	a0,a0,1480 # 800087c0 <syscalls+0x2a0>
    80005200:	ffffb097          	auipc	ra,0xffffb
    80005204:	340080e7          	jalr	832(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005208:	874a                	mv	a4,s2
    8000520a:	009c86bb          	addw	a3,s9,s1
    8000520e:	4581                	li	a1,0
    80005210:	8556                	mv	a0,s5
    80005212:	fffff097          	auipc	ra,0xfffff
    80005216:	c8e080e7          	jalr	-882(ra) # 80003ea0 <readi>
    8000521a:	2501                	sext.w	a0,a0
    8000521c:	1aa91963          	bne	s2,a0,800053ce <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    80005220:	009d84bb          	addw	s1,s11,s1
    80005224:	013d09bb          	addw	s3,s10,s3
    80005228:	1f74f663          	bgeu	s1,s7,80005414 <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    8000522c:	02049593          	slli	a1,s1,0x20
    80005230:	9181                	srli	a1,a1,0x20
    80005232:	95e2                	add	a1,a1,s8
    80005234:	855a                	mv	a0,s6
    80005236:	ffffc097          	auipc	ra,0xffffc
    8000523a:	e26080e7          	jalr	-474(ra) # 8000105c <walkaddr>
    8000523e:	862a                	mv	a2,a0
    if(pa == 0)
    80005240:	dd45                	beqz	a0,800051f8 <exec+0xfe>
      n = PGSIZE;
    80005242:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005244:	fd49f2e3          	bgeu	s3,s4,80005208 <exec+0x10e>
      n = sz - i;
    80005248:	894e                	mv	s2,s3
    8000524a:	bf7d                	j	80005208 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000524c:	4901                	li	s2,0
  iunlockput(ip);
    8000524e:	8556                	mv	a0,s5
    80005250:	fffff097          	auipc	ra,0xfffff
    80005254:	bfe080e7          	jalr	-1026(ra) # 80003e4e <iunlockput>
  end_op();
    80005258:	fffff097          	auipc	ra,0xfffff
    8000525c:	3de080e7          	jalr	990(ra) # 80004636 <end_op>
  p = myproc();
    80005260:	ffffd097          	auipc	ra,0xffffd
    80005264:	9ea080e7          	jalr	-1558(ra) # 80001c4a <myproc>
    80005268:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    8000526a:	05053d03          	ld	s10,80(a0)
  sz = PGROUNDUP(sz);
    8000526e:	6785                	lui	a5,0x1
    80005270:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80005272:	97ca                	add	a5,a5,s2
    80005274:	777d                	lui	a4,0xfffff
    80005276:	8ff9                	and	a5,a5,a4
    80005278:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000527c:	4691                	li	a3,4
    8000527e:	6609                	lui	a2,0x2
    80005280:	963e                	add	a2,a2,a5
    80005282:	85be                	mv	a1,a5
    80005284:	855a                	mv	a0,s6
    80005286:	ffffc097          	auipc	ra,0xffffc
    8000528a:	18a080e7          	jalr	394(ra) # 80001410 <uvmalloc>
    8000528e:	8c2a                	mv	s8,a0
  ip = 0;
    80005290:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005292:	12050e63          	beqz	a0,800053ce <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005296:	75f9                	lui	a1,0xffffe
    80005298:	95aa                	add	a1,a1,a0
    8000529a:	855a                	mv	a0,s6
    8000529c:	ffffc097          	auipc	ra,0xffffc
    800052a0:	39e080e7          	jalr	926(ra) # 8000163a <uvmclear>
  stackbase = sp - PGSIZE;
    800052a4:	7afd                	lui	s5,0xfffff
    800052a6:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800052a8:	df043783          	ld	a5,-528(s0)
    800052ac:	6388                	ld	a0,0(a5)
    800052ae:	c925                	beqz	a0,8000531e <exec+0x224>
    800052b0:	e9040993          	addi	s3,s0,-368
    800052b4:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800052b8:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800052ba:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800052bc:	ffffc097          	auipc	ra,0xffffc
    800052c0:	b92080e7          	jalr	-1134(ra) # 80000e4e <strlen>
    800052c4:	0015079b          	addiw	a5,a0,1
    800052c8:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800052cc:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    800052d0:	13596663          	bltu	s2,s5,800053fc <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800052d4:	df043d83          	ld	s11,-528(s0)
    800052d8:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800052dc:	8552                	mv	a0,s4
    800052de:	ffffc097          	auipc	ra,0xffffc
    800052e2:	b70080e7          	jalr	-1168(ra) # 80000e4e <strlen>
    800052e6:	0015069b          	addiw	a3,a0,1
    800052ea:	8652                	mv	a2,s4
    800052ec:	85ca                	mv	a1,s2
    800052ee:	855a                	mv	a0,s6
    800052f0:	ffffc097          	auipc	ra,0xffffc
    800052f4:	37c080e7          	jalr	892(ra) # 8000166c <copyout>
    800052f8:	10054663          	bltz	a0,80005404 <exec+0x30a>
    ustack[argc] = sp;
    800052fc:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005300:	0485                	addi	s1,s1,1
    80005302:	008d8793          	addi	a5,s11,8
    80005306:	def43823          	sd	a5,-528(s0)
    8000530a:	008db503          	ld	a0,8(s11)
    8000530e:	c911                	beqz	a0,80005322 <exec+0x228>
    if(argc >= MAXARG)
    80005310:	09a1                	addi	s3,s3,8
    80005312:	fb3c95e3          	bne	s9,s3,800052bc <exec+0x1c2>
  sz = sz1;
    80005316:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000531a:	4a81                	li	s5,0
    8000531c:	a84d                	j	800053ce <exec+0x2d4>
  sp = sz;
    8000531e:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005320:	4481                	li	s1,0
  ustack[argc] = 0;
    80005322:	00349793          	slli	a5,s1,0x3
    80005326:	f9078793          	addi	a5,a5,-112
    8000532a:	97a2                	add	a5,a5,s0
    8000532c:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005330:	00148693          	addi	a3,s1,1
    80005334:	068e                	slli	a3,a3,0x3
    80005336:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000533a:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000533e:	01597663          	bgeu	s2,s5,8000534a <exec+0x250>
  sz = sz1;
    80005342:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005346:	4a81                	li	s5,0
    80005348:	a059                	j	800053ce <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000534a:	e9040613          	addi	a2,s0,-368
    8000534e:	85ca                	mv	a1,s2
    80005350:	855a                	mv	a0,s6
    80005352:	ffffc097          	auipc	ra,0xffffc
    80005356:	31a080e7          	jalr	794(ra) # 8000166c <copyout>
    8000535a:	0a054963          	bltz	a0,8000540c <exec+0x312>
  p->trapframe->a1 = sp;
    8000535e:	060bb783          	ld	a5,96(s7)
    80005362:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005366:	de843783          	ld	a5,-536(s0)
    8000536a:	0007c703          	lbu	a4,0(a5)
    8000536e:	cf11                	beqz	a4,8000538a <exec+0x290>
    80005370:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005372:	02f00693          	li	a3,47
    80005376:	a039                	j	80005384 <exec+0x28a>
      last = s+1;
    80005378:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    8000537c:	0785                	addi	a5,a5,1
    8000537e:	fff7c703          	lbu	a4,-1(a5)
    80005382:	c701                	beqz	a4,8000538a <exec+0x290>
    if(*s == '/')
    80005384:	fed71ce3          	bne	a4,a3,8000537c <exec+0x282>
    80005388:	bfc5                	j	80005378 <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    8000538a:	4641                	li	a2,16
    8000538c:	de843583          	ld	a1,-536(s0)
    80005390:	160b8513          	addi	a0,s7,352
    80005394:	ffffc097          	auipc	ra,0xffffc
    80005398:	a88080e7          	jalr	-1400(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    8000539c:	058bb503          	ld	a0,88(s7)
  p->pagetable = pagetable;
    800053a0:	056bbc23          	sd	s6,88(s7)
  p->sz = sz;
    800053a4:	058bb823          	sd	s8,80(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800053a8:	060bb783          	ld	a5,96(s7)
    800053ac:	e6843703          	ld	a4,-408(s0)
    800053b0:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800053b2:	060bb783          	ld	a5,96(s7)
    800053b6:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800053ba:	85ea                	mv	a1,s10
    800053bc:	ffffd097          	auipc	ra,0xffffd
    800053c0:	9f4080e7          	jalr	-1548(ra) # 80001db0 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800053c4:	0004851b          	sext.w	a0,s1
    800053c8:	b3f9                	j	80005196 <exec+0x9c>
    800053ca:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    800053ce:	df843583          	ld	a1,-520(s0)
    800053d2:	855a                	mv	a0,s6
    800053d4:	ffffd097          	auipc	ra,0xffffd
    800053d8:	9dc080e7          	jalr	-1572(ra) # 80001db0 <proc_freepagetable>
  if(ip){
    800053dc:	da0a93e3          	bnez	s5,80005182 <exec+0x88>
  return -1;
    800053e0:	557d                	li	a0,-1
    800053e2:	bb55                	j	80005196 <exec+0x9c>
    800053e4:	df243c23          	sd	s2,-520(s0)
    800053e8:	b7dd                	j	800053ce <exec+0x2d4>
    800053ea:	df243c23          	sd	s2,-520(s0)
    800053ee:	b7c5                	j	800053ce <exec+0x2d4>
    800053f0:	df243c23          	sd	s2,-520(s0)
    800053f4:	bfe9                	j	800053ce <exec+0x2d4>
    800053f6:	df243c23          	sd	s2,-520(s0)
    800053fa:	bfd1                	j	800053ce <exec+0x2d4>
  sz = sz1;
    800053fc:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005400:	4a81                	li	s5,0
    80005402:	b7f1                	j	800053ce <exec+0x2d4>
  sz = sz1;
    80005404:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005408:	4a81                	li	s5,0
    8000540a:	b7d1                	j	800053ce <exec+0x2d4>
  sz = sz1;
    8000540c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005410:	4a81                	li	s5,0
    80005412:	bf75                	j	800053ce <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005414:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005418:	e0843783          	ld	a5,-504(s0)
    8000541c:	0017869b          	addiw	a3,a5,1
    80005420:	e0d43423          	sd	a3,-504(s0)
    80005424:	e0043783          	ld	a5,-512(s0)
    80005428:	0387879b          	addiw	a5,a5,56
    8000542c:	e8845703          	lhu	a4,-376(s0)
    80005430:	e0e6dfe3          	bge	a3,a4,8000524e <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005434:	2781                	sext.w	a5,a5
    80005436:	e0f43023          	sd	a5,-512(s0)
    8000543a:	03800713          	li	a4,56
    8000543e:	86be                	mv	a3,a5
    80005440:	e1840613          	addi	a2,s0,-488
    80005444:	4581                	li	a1,0
    80005446:	8556                	mv	a0,s5
    80005448:	fffff097          	auipc	ra,0xfffff
    8000544c:	a58080e7          	jalr	-1448(ra) # 80003ea0 <readi>
    80005450:	03800793          	li	a5,56
    80005454:	f6f51be3          	bne	a0,a5,800053ca <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    80005458:	e1842783          	lw	a5,-488(s0)
    8000545c:	4705                	li	a4,1
    8000545e:	fae79de3          	bne	a5,a4,80005418 <exec+0x31e>
    if(ph.memsz < ph.filesz)
    80005462:	e4043483          	ld	s1,-448(s0)
    80005466:	e3843783          	ld	a5,-456(s0)
    8000546a:	f6f4ede3          	bltu	s1,a5,800053e4 <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000546e:	e2843783          	ld	a5,-472(s0)
    80005472:	94be                	add	s1,s1,a5
    80005474:	f6f4ebe3          	bltu	s1,a5,800053ea <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    80005478:	de043703          	ld	a4,-544(s0)
    8000547c:	8ff9                	and	a5,a5,a4
    8000547e:	fbad                	bnez	a5,800053f0 <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005480:	e1c42503          	lw	a0,-484(s0)
    80005484:	00000097          	auipc	ra,0x0
    80005488:	c5c080e7          	jalr	-932(ra) # 800050e0 <flags2perm>
    8000548c:	86aa                	mv	a3,a0
    8000548e:	8626                	mv	a2,s1
    80005490:	85ca                	mv	a1,s2
    80005492:	855a                	mv	a0,s6
    80005494:	ffffc097          	auipc	ra,0xffffc
    80005498:	f7c080e7          	jalr	-132(ra) # 80001410 <uvmalloc>
    8000549c:	dea43c23          	sd	a0,-520(s0)
    800054a0:	d939                	beqz	a0,800053f6 <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800054a2:	e2843c03          	ld	s8,-472(s0)
    800054a6:	e2042c83          	lw	s9,-480(s0)
    800054aa:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800054ae:	f60b83e3          	beqz	s7,80005414 <exec+0x31a>
    800054b2:	89de                	mv	s3,s7
    800054b4:	4481                	li	s1,0
    800054b6:	bb9d                	j	8000522c <exec+0x132>

00000000800054b8 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800054b8:	7179                	addi	sp,sp,-48
    800054ba:	f406                	sd	ra,40(sp)
    800054bc:	f022                	sd	s0,32(sp)
    800054be:	ec26                	sd	s1,24(sp)
    800054c0:	e84a                	sd	s2,16(sp)
    800054c2:	1800                	addi	s0,sp,48
    800054c4:	892e                	mv	s2,a1
    800054c6:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800054c8:	fdc40593          	addi	a1,s0,-36
    800054cc:	ffffe097          	auipc	ra,0xffffe
    800054d0:	b0a080e7          	jalr	-1270(ra) # 80002fd6 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800054d4:	fdc42703          	lw	a4,-36(s0)
    800054d8:	47bd                	li	a5,15
    800054da:	02e7eb63          	bltu	a5,a4,80005510 <argfd+0x58>
    800054de:	ffffc097          	auipc	ra,0xffffc
    800054e2:	76c080e7          	jalr	1900(ra) # 80001c4a <myproc>
    800054e6:	fdc42703          	lw	a4,-36(s0)
    800054ea:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffdcf3a>
    800054ee:	078e                	slli	a5,a5,0x3
    800054f0:	953e                	add	a0,a0,a5
    800054f2:	651c                	ld	a5,8(a0)
    800054f4:	c385                	beqz	a5,80005514 <argfd+0x5c>
    return -1;
  if(pfd)
    800054f6:	00090463          	beqz	s2,800054fe <argfd+0x46>
    *pfd = fd;
    800054fa:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800054fe:	4501                	li	a0,0
  if(pf)
    80005500:	c091                	beqz	s1,80005504 <argfd+0x4c>
    *pf = f;
    80005502:	e09c                	sd	a5,0(s1)
}
    80005504:	70a2                	ld	ra,40(sp)
    80005506:	7402                	ld	s0,32(sp)
    80005508:	64e2                	ld	s1,24(sp)
    8000550a:	6942                	ld	s2,16(sp)
    8000550c:	6145                	addi	sp,sp,48
    8000550e:	8082                	ret
    return -1;
    80005510:	557d                	li	a0,-1
    80005512:	bfcd                	j	80005504 <argfd+0x4c>
    80005514:	557d                	li	a0,-1
    80005516:	b7fd                	j	80005504 <argfd+0x4c>

0000000080005518 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005518:	1101                	addi	sp,sp,-32
    8000551a:	ec06                	sd	ra,24(sp)
    8000551c:	e822                	sd	s0,16(sp)
    8000551e:	e426                	sd	s1,8(sp)
    80005520:	1000                	addi	s0,sp,32
    80005522:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005524:	ffffc097          	auipc	ra,0xffffc
    80005528:	726080e7          	jalr	1830(ra) # 80001c4a <myproc>
    8000552c:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000552e:	0d850793          	addi	a5,a0,216
    80005532:	4501                	li	a0,0
    80005534:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005536:	6398                	ld	a4,0(a5)
    80005538:	cb19                	beqz	a4,8000554e <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000553a:	2505                	addiw	a0,a0,1
    8000553c:	07a1                	addi	a5,a5,8
    8000553e:	fed51ce3          	bne	a0,a3,80005536 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005542:	557d                	li	a0,-1
}
    80005544:	60e2                	ld	ra,24(sp)
    80005546:	6442                	ld	s0,16(sp)
    80005548:	64a2                	ld	s1,8(sp)
    8000554a:	6105                	addi	sp,sp,32
    8000554c:	8082                	ret
      p->ofile[fd] = f;
    8000554e:	01a50793          	addi	a5,a0,26
    80005552:	078e                	slli	a5,a5,0x3
    80005554:	963e                	add	a2,a2,a5
    80005556:	e604                	sd	s1,8(a2)
      return fd;
    80005558:	b7f5                	j	80005544 <fdalloc+0x2c>

000000008000555a <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000555a:	715d                	addi	sp,sp,-80
    8000555c:	e486                	sd	ra,72(sp)
    8000555e:	e0a2                	sd	s0,64(sp)
    80005560:	fc26                	sd	s1,56(sp)
    80005562:	f84a                	sd	s2,48(sp)
    80005564:	f44e                	sd	s3,40(sp)
    80005566:	f052                	sd	s4,32(sp)
    80005568:	ec56                	sd	s5,24(sp)
    8000556a:	e85a                	sd	s6,16(sp)
    8000556c:	0880                	addi	s0,sp,80
    8000556e:	8b2e                	mv	s6,a1
    80005570:	89b2                	mv	s3,a2
    80005572:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005574:	fb040593          	addi	a1,s0,-80
    80005578:	fffff097          	auipc	ra,0xfffff
    8000557c:	e3e080e7          	jalr	-450(ra) # 800043b6 <nameiparent>
    80005580:	84aa                	mv	s1,a0
    80005582:	14050f63          	beqz	a0,800056e0 <create+0x186>
    return 0;

  ilock(dp);
    80005586:	ffffe097          	auipc	ra,0xffffe
    8000558a:	666080e7          	jalr	1638(ra) # 80003bec <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000558e:	4601                	li	a2,0
    80005590:	fb040593          	addi	a1,s0,-80
    80005594:	8526                	mv	a0,s1
    80005596:	fffff097          	auipc	ra,0xfffff
    8000559a:	b3a080e7          	jalr	-1222(ra) # 800040d0 <dirlookup>
    8000559e:	8aaa                	mv	s5,a0
    800055a0:	c931                	beqz	a0,800055f4 <create+0x9a>
    iunlockput(dp);
    800055a2:	8526                	mv	a0,s1
    800055a4:	fffff097          	auipc	ra,0xfffff
    800055a8:	8aa080e7          	jalr	-1878(ra) # 80003e4e <iunlockput>
    ilock(ip);
    800055ac:	8556                	mv	a0,s5
    800055ae:	ffffe097          	auipc	ra,0xffffe
    800055b2:	63e080e7          	jalr	1598(ra) # 80003bec <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800055b6:	000b059b          	sext.w	a1,s6
    800055ba:	4789                	li	a5,2
    800055bc:	02f59563          	bne	a1,a5,800055e6 <create+0x8c>
    800055c0:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdcf64>
    800055c4:	37f9                	addiw	a5,a5,-2
    800055c6:	17c2                	slli	a5,a5,0x30
    800055c8:	93c1                	srli	a5,a5,0x30
    800055ca:	4705                	li	a4,1
    800055cc:	00f76d63          	bltu	a4,a5,800055e6 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800055d0:	8556                	mv	a0,s5
    800055d2:	60a6                	ld	ra,72(sp)
    800055d4:	6406                	ld	s0,64(sp)
    800055d6:	74e2                	ld	s1,56(sp)
    800055d8:	7942                	ld	s2,48(sp)
    800055da:	79a2                	ld	s3,40(sp)
    800055dc:	7a02                	ld	s4,32(sp)
    800055de:	6ae2                	ld	s5,24(sp)
    800055e0:	6b42                	ld	s6,16(sp)
    800055e2:	6161                	addi	sp,sp,80
    800055e4:	8082                	ret
    iunlockput(ip);
    800055e6:	8556                	mv	a0,s5
    800055e8:	fffff097          	auipc	ra,0xfffff
    800055ec:	866080e7          	jalr	-1946(ra) # 80003e4e <iunlockput>
    return 0;
    800055f0:	4a81                	li	s5,0
    800055f2:	bff9                	j	800055d0 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800055f4:	85da                	mv	a1,s6
    800055f6:	4088                	lw	a0,0(s1)
    800055f8:	ffffe097          	auipc	ra,0xffffe
    800055fc:	456080e7          	jalr	1110(ra) # 80003a4e <ialloc>
    80005600:	8a2a                	mv	s4,a0
    80005602:	c539                	beqz	a0,80005650 <create+0xf6>
  ilock(ip);
    80005604:	ffffe097          	auipc	ra,0xffffe
    80005608:	5e8080e7          	jalr	1512(ra) # 80003bec <ilock>
  ip->major = major;
    8000560c:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005610:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005614:	4905                	li	s2,1
    80005616:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    8000561a:	8552                	mv	a0,s4
    8000561c:	ffffe097          	auipc	ra,0xffffe
    80005620:	504080e7          	jalr	1284(ra) # 80003b20 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005624:	000b059b          	sext.w	a1,s6
    80005628:	03258b63          	beq	a1,s2,8000565e <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    8000562c:	004a2603          	lw	a2,4(s4)
    80005630:	fb040593          	addi	a1,s0,-80
    80005634:	8526                	mv	a0,s1
    80005636:	fffff097          	auipc	ra,0xfffff
    8000563a:	cb0080e7          	jalr	-848(ra) # 800042e6 <dirlink>
    8000563e:	06054f63          	bltz	a0,800056bc <create+0x162>
  iunlockput(dp);
    80005642:	8526                	mv	a0,s1
    80005644:	fffff097          	auipc	ra,0xfffff
    80005648:	80a080e7          	jalr	-2038(ra) # 80003e4e <iunlockput>
  return ip;
    8000564c:	8ad2                	mv	s5,s4
    8000564e:	b749                	j	800055d0 <create+0x76>
    iunlockput(dp);
    80005650:	8526                	mv	a0,s1
    80005652:	ffffe097          	auipc	ra,0xffffe
    80005656:	7fc080e7          	jalr	2044(ra) # 80003e4e <iunlockput>
    return 0;
    8000565a:	8ad2                	mv	s5,s4
    8000565c:	bf95                	j	800055d0 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000565e:	004a2603          	lw	a2,4(s4)
    80005662:	00003597          	auipc	a1,0x3
    80005666:	17e58593          	addi	a1,a1,382 # 800087e0 <syscalls+0x2c0>
    8000566a:	8552                	mv	a0,s4
    8000566c:	fffff097          	auipc	ra,0xfffff
    80005670:	c7a080e7          	jalr	-902(ra) # 800042e6 <dirlink>
    80005674:	04054463          	bltz	a0,800056bc <create+0x162>
    80005678:	40d0                	lw	a2,4(s1)
    8000567a:	00003597          	auipc	a1,0x3
    8000567e:	16e58593          	addi	a1,a1,366 # 800087e8 <syscalls+0x2c8>
    80005682:	8552                	mv	a0,s4
    80005684:	fffff097          	auipc	ra,0xfffff
    80005688:	c62080e7          	jalr	-926(ra) # 800042e6 <dirlink>
    8000568c:	02054863          	bltz	a0,800056bc <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005690:	004a2603          	lw	a2,4(s4)
    80005694:	fb040593          	addi	a1,s0,-80
    80005698:	8526                	mv	a0,s1
    8000569a:	fffff097          	auipc	ra,0xfffff
    8000569e:	c4c080e7          	jalr	-948(ra) # 800042e6 <dirlink>
    800056a2:	00054d63          	bltz	a0,800056bc <create+0x162>
    dp->nlink++;  // for ".."
    800056a6:	04a4d783          	lhu	a5,74(s1)
    800056aa:	2785                	addiw	a5,a5,1
    800056ac:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056b0:	8526                	mv	a0,s1
    800056b2:	ffffe097          	auipc	ra,0xffffe
    800056b6:	46e080e7          	jalr	1134(ra) # 80003b20 <iupdate>
    800056ba:	b761                	j	80005642 <create+0xe8>
  ip->nlink = 0;
    800056bc:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800056c0:	8552                	mv	a0,s4
    800056c2:	ffffe097          	auipc	ra,0xffffe
    800056c6:	45e080e7          	jalr	1118(ra) # 80003b20 <iupdate>
  iunlockput(ip);
    800056ca:	8552                	mv	a0,s4
    800056cc:	ffffe097          	auipc	ra,0xffffe
    800056d0:	782080e7          	jalr	1922(ra) # 80003e4e <iunlockput>
  iunlockput(dp);
    800056d4:	8526                	mv	a0,s1
    800056d6:	ffffe097          	auipc	ra,0xffffe
    800056da:	778080e7          	jalr	1912(ra) # 80003e4e <iunlockput>
  return 0;
    800056de:	bdcd                	j	800055d0 <create+0x76>
    return 0;
    800056e0:	8aaa                	mv	s5,a0
    800056e2:	b5fd                	j	800055d0 <create+0x76>

00000000800056e4 <sys_dup>:
{
    800056e4:	7179                	addi	sp,sp,-48
    800056e6:	f406                	sd	ra,40(sp)
    800056e8:	f022                	sd	s0,32(sp)
    800056ea:	ec26                	sd	s1,24(sp)
    800056ec:	e84a                	sd	s2,16(sp)
    800056ee:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800056f0:	fd840613          	addi	a2,s0,-40
    800056f4:	4581                	li	a1,0
    800056f6:	4501                	li	a0,0
    800056f8:	00000097          	auipc	ra,0x0
    800056fc:	dc0080e7          	jalr	-576(ra) # 800054b8 <argfd>
    return -1;
    80005700:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005702:	02054363          	bltz	a0,80005728 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005706:	fd843903          	ld	s2,-40(s0)
    8000570a:	854a                	mv	a0,s2
    8000570c:	00000097          	auipc	ra,0x0
    80005710:	e0c080e7          	jalr	-500(ra) # 80005518 <fdalloc>
    80005714:	84aa                	mv	s1,a0
    return -1;
    80005716:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005718:	00054863          	bltz	a0,80005728 <sys_dup+0x44>
  filedup(f);
    8000571c:	854a                	mv	a0,s2
    8000571e:	fffff097          	auipc	ra,0xfffff
    80005722:	310080e7          	jalr	784(ra) # 80004a2e <filedup>
  return fd;
    80005726:	87a6                	mv	a5,s1
}
    80005728:	853e                	mv	a0,a5
    8000572a:	70a2                	ld	ra,40(sp)
    8000572c:	7402                	ld	s0,32(sp)
    8000572e:	64e2                	ld	s1,24(sp)
    80005730:	6942                	ld	s2,16(sp)
    80005732:	6145                	addi	sp,sp,48
    80005734:	8082                	ret

0000000080005736 <sys_read>:
{
    80005736:	7179                	addi	sp,sp,-48
    80005738:	f406                	sd	ra,40(sp)
    8000573a:	f022                	sd	s0,32(sp)
    8000573c:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000573e:	fd840593          	addi	a1,s0,-40
    80005742:	4505                	li	a0,1
    80005744:	ffffe097          	auipc	ra,0xffffe
    80005748:	8b2080e7          	jalr	-1870(ra) # 80002ff6 <argaddr>
  argint(2, &n);
    8000574c:	fe440593          	addi	a1,s0,-28
    80005750:	4509                	li	a0,2
    80005752:	ffffe097          	auipc	ra,0xffffe
    80005756:	884080e7          	jalr	-1916(ra) # 80002fd6 <argint>
  if(argfd(0, 0, &f) < 0)
    8000575a:	fe840613          	addi	a2,s0,-24
    8000575e:	4581                	li	a1,0
    80005760:	4501                	li	a0,0
    80005762:	00000097          	auipc	ra,0x0
    80005766:	d56080e7          	jalr	-682(ra) # 800054b8 <argfd>
    8000576a:	87aa                	mv	a5,a0
    return -1;
    8000576c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000576e:	0007cc63          	bltz	a5,80005786 <sys_read+0x50>
  return fileread(f, p, n);
    80005772:	fe442603          	lw	a2,-28(s0)
    80005776:	fd843583          	ld	a1,-40(s0)
    8000577a:	fe843503          	ld	a0,-24(s0)
    8000577e:	fffff097          	auipc	ra,0xfffff
    80005782:	43c080e7          	jalr	1084(ra) # 80004bba <fileread>
}
    80005786:	70a2                	ld	ra,40(sp)
    80005788:	7402                	ld	s0,32(sp)
    8000578a:	6145                	addi	sp,sp,48
    8000578c:	8082                	ret

000000008000578e <sys_write>:
{
    8000578e:	7179                	addi	sp,sp,-48
    80005790:	f406                	sd	ra,40(sp)
    80005792:	f022                	sd	s0,32(sp)
    80005794:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005796:	fd840593          	addi	a1,s0,-40
    8000579a:	4505                	li	a0,1
    8000579c:	ffffe097          	auipc	ra,0xffffe
    800057a0:	85a080e7          	jalr	-1958(ra) # 80002ff6 <argaddr>
  argint(2, &n);
    800057a4:	fe440593          	addi	a1,s0,-28
    800057a8:	4509                	li	a0,2
    800057aa:	ffffe097          	auipc	ra,0xffffe
    800057ae:	82c080e7          	jalr	-2004(ra) # 80002fd6 <argint>
  if(argfd(0, 0, &f) < 0)
    800057b2:	fe840613          	addi	a2,s0,-24
    800057b6:	4581                	li	a1,0
    800057b8:	4501                	li	a0,0
    800057ba:	00000097          	auipc	ra,0x0
    800057be:	cfe080e7          	jalr	-770(ra) # 800054b8 <argfd>
    800057c2:	87aa                	mv	a5,a0
    return -1;
    800057c4:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800057c6:	0007cc63          	bltz	a5,800057de <sys_write+0x50>
  return filewrite(f, p, n);
    800057ca:	fe442603          	lw	a2,-28(s0)
    800057ce:	fd843583          	ld	a1,-40(s0)
    800057d2:	fe843503          	ld	a0,-24(s0)
    800057d6:	fffff097          	auipc	ra,0xfffff
    800057da:	4a6080e7          	jalr	1190(ra) # 80004c7c <filewrite>
}
    800057de:	70a2                	ld	ra,40(sp)
    800057e0:	7402                	ld	s0,32(sp)
    800057e2:	6145                	addi	sp,sp,48
    800057e4:	8082                	ret

00000000800057e6 <sys_close>:
{
    800057e6:	1101                	addi	sp,sp,-32
    800057e8:	ec06                	sd	ra,24(sp)
    800057ea:	e822                	sd	s0,16(sp)
    800057ec:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800057ee:	fe040613          	addi	a2,s0,-32
    800057f2:	fec40593          	addi	a1,s0,-20
    800057f6:	4501                	li	a0,0
    800057f8:	00000097          	auipc	ra,0x0
    800057fc:	cc0080e7          	jalr	-832(ra) # 800054b8 <argfd>
    return -1;
    80005800:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005802:	02054463          	bltz	a0,8000582a <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005806:	ffffc097          	auipc	ra,0xffffc
    8000580a:	444080e7          	jalr	1092(ra) # 80001c4a <myproc>
    8000580e:	fec42783          	lw	a5,-20(s0)
    80005812:	07e9                	addi	a5,a5,26
    80005814:	078e                	slli	a5,a5,0x3
    80005816:	953e                	add	a0,a0,a5
    80005818:	00053423          	sd	zero,8(a0)
  fileclose(f);
    8000581c:	fe043503          	ld	a0,-32(s0)
    80005820:	fffff097          	auipc	ra,0xfffff
    80005824:	260080e7          	jalr	608(ra) # 80004a80 <fileclose>
  return 0;
    80005828:	4781                	li	a5,0
}
    8000582a:	853e                	mv	a0,a5
    8000582c:	60e2                	ld	ra,24(sp)
    8000582e:	6442                	ld	s0,16(sp)
    80005830:	6105                	addi	sp,sp,32
    80005832:	8082                	ret

0000000080005834 <sys_fstat>:
{
    80005834:	1101                	addi	sp,sp,-32
    80005836:	ec06                	sd	ra,24(sp)
    80005838:	e822                	sd	s0,16(sp)
    8000583a:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    8000583c:	fe040593          	addi	a1,s0,-32
    80005840:	4505                	li	a0,1
    80005842:	ffffd097          	auipc	ra,0xffffd
    80005846:	7b4080e7          	jalr	1972(ra) # 80002ff6 <argaddr>
  if(argfd(0, 0, &f) < 0)
    8000584a:	fe840613          	addi	a2,s0,-24
    8000584e:	4581                	li	a1,0
    80005850:	4501                	li	a0,0
    80005852:	00000097          	auipc	ra,0x0
    80005856:	c66080e7          	jalr	-922(ra) # 800054b8 <argfd>
    8000585a:	87aa                	mv	a5,a0
    return -1;
    8000585c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000585e:	0007ca63          	bltz	a5,80005872 <sys_fstat+0x3e>
  return filestat(f, st);
    80005862:	fe043583          	ld	a1,-32(s0)
    80005866:	fe843503          	ld	a0,-24(s0)
    8000586a:	fffff097          	auipc	ra,0xfffff
    8000586e:	2de080e7          	jalr	734(ra) # 80004b48 <filestat>
}
    80005872:	60e2                	ld	ra,24(sp)
    80005874:	6442                	ld	s0,16(sp)
    80005876:	6105                	addi	sp,sp,32
    80005878:	8082                	ret

000000008000587a <sys_link>:
{
    8000587a:	7169                	addi	sp,sp,-304
    8000587c:	f606                	sd	ra,296(sp)
    8000587e:	f222                	sd	s0,288(sp)
    80005880:	ee26                	sd	s1,280(sp)
    80005882:	ea4a                	sd	s2,272(sp)
    80005884:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005886:	08000613          	li	a2,128
    8000588a:	ed040593          	addi	a1,s0,-304
    8000588e:	4501                	li	a0,0
    80005890:	ffffd097          	auipc	ra,0xffffd
    80005894:	786080e7          	jalr	1926(ra) # 80003016 <argstr>
    return -1;
    80005898:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000589a:	10054e63          	bltz	a0,800059b6 <sys_link+0x13c>
    8000589e:	08000613          	li	a2,128
    800058a2:	f5040593          	addi	a1,s0,-176
    800058a6:	4505                	li	a0,1
    800058a8:	ffffd097          	auipc	ra,0xffffd
    800058ac:	76e080e7          	jalr	1902(ra) # 80003016 <argstr>
    return -1;
    800058b0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058b2:	10054263          	bltz	a0,800059b6 <sys_link+0x13c>
  begin_op();
    800058b6:	fffff097          	auipc	ra,0xfffff
    800058ba:	d02080e7          	jalr	-766(ra) # 800045b8 <begin_op>
  if((ip = namei(old)) == 0){
    800058be:	ed040513          	addi	a0,s0,-304
    800058c2:	fffff097          	auipc	ra,0xfffff
    800058c6:	ad6080e7          	jalr	-1322(ra) # 80004398 <namei>
    800058ca:	84aa                	mv	s1,a0
    800058cc:	c551                	beqz	a0,80005958 <sys_link+0xde>
  ilock(ip);
    800058ce:	ffffe097          	auipc	ra,0xffffe
    800058d2:	31e080e7          	jalr	798(ra) # 80003bec <ilock>
  if(ip->type == T_DIR){
    800058d6:	04449703          	lh	a4,68(s1)
    800058da:	4785                	li	a5,1
    800058dc:	08f70463          	beq	a4,a5,80005964 <sys_link+0xea>
  ip->nlink++;
    800058e0:	04a4d783          	lhu	a5,74(s1)
    800058e4:	2785                	addiw	a5,a5,1
    800058e6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800058ea:	8526                	mv	a0,s1
    800058ec:	ffffe097          	auipc	ra,0xffffe
    800058f0:	234080e7          	jalr	564(ra) # 80003b20 <iupdate>
  iunlock(ip);
    800058f4:	8526                	mv	a0,s1
    800058f6:	ffffe097          	auipc	ra,0xffffe
    800058fa:	3b8080e7          	jalr	952(ra) # 80003cae <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800058fe:	fd040593          	addi	a1,s0,-48
    80005902:	f5040513          	addi	a0,s0,-176
    80005906:	fffff097          	auipc	ra,0xfffff
    8000590a:	ab0080e7          	jalr	-1360(ra) # 800043b6 <nameiparent>
    8000590e:	892a                	mv	s2,a0
    80005910:	c935                	beqz	a0,80005984 <sys_link+0x10a>
  ilock(dp);
    80005912:	ffffe097          	auipc	ra,0xffffe
    80005916:	2da080e7          	jalr	730(ra) # 80003bec <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000591a:	00092703          	lw	a4,0(s2)
    8000591e:	409c                	lw	a5,0(s1)
    80005920:	04f71d63          	bne	a4,a5,8000597a <sys_link+0x100>
    80005924:	40d0                	lw	a2,4(s1)
    80005926:	fd040593          	addi	a1,s0,-48
    8000592a:	854a                	mv	a0,s2
    8000592c:	fffff097          	auipc	ra,0xfffff
    80005930:	9ba080e7          	jalr	-1606(ra) # 800042e6 <dirlink>
    80005934:	04054363          	bltz	a0,8000597a <sys_link+0x100>
  iunlockput(dp);
    80005938:	854a                	mv	a0,s2
    8000593a:	ffffe097          	auipc	ra,0xffffe
    8000593e:	514080e7          	jalr	1300(ra) # 80003e4e <iunlockput>
  iput(ip);
    80005942:	8526                	mv	a0,s1
    80005944:	ffffe097          	auipc	ra,0xffffe
    80005948:	462080e7          	jalr	1122(ra) # 80003da6 <iput>
  end_op();
    8000594c:	fffff097          	auipc	ra,0xfffff
    80005950:	cea080e7          	jalr	-790(ra) # 80004636 <end_op>
  return 0;
    80005954:	4781                	li	a5,0
    80005956:	a085                	j	800059b6 <sys_link+0x13c>
    end_op();
    80005958:	fffff097          	auipc	ra,0xfffff
    8000595c:	cde080e7          	jalr	-802(ra) # 80004636 <end_op>
    return -1;
    80005960:	57fd                	li	a5,-1
    80005962:	a891                	j	800059b6 <sys_link+0x13c>
    iunlockput(ip);
    80005964:	8526                	mv	a0,s1
    80005966:	ffffe097          	auipc	ra,0xffffe
    8000596a:	4e8080e7          	jalr	1256(ra) # 80003e4e <iunlockput>
    end_op();
    8000596e:	fffff097          	auipc	ra,0xfffff
    80005972:	cc8080e7          	jalr	-824(ra) # 80004636 <end_op>
    return -1;
    80005976:	57fd                	li	a5,-1
    80005978:	a83d                	j	800059b6 <sys_link+0x13c>
    iunlockput(dp);
    8000597a:	854a                	mv	a0,s2
    8000597c:	ffffe097          	auipc	ra,0xffffe
    80005980:	4d2080e7          	jalr	1234(ra) # 80003e4e <iunlockput>
  ilock(ip);
    80005984:	8526                	mv	a0,s1
    80005986:	ffffe097          	auipc	ra,0xffffe
    8000598a:	266080e7          	jalr	614(ra) # 80003bec <ilock>
  ip->nlink--;
    8000598e:	04a4d783          	lhu	a5,74(s1)
    80005992:	37fd                	addiw	a5,a5,-1
    80005994:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005998:	8526                	mv	a0,s1
    8000599a:	ffffe097          	auipc	ra,0xffffe
    8000599e:	186080e7          	jalr	390(ra) # 80003b20 <iupdate>
  iunlockput(ip);
    800059a2:	8526                	mv	a0,s1
    800059a4:	ffffe097          	auipc	ra,0xffffe
    800059a8:	4aa080e7          	jalr	1194(ra) # 80003e4e <iunlockput>
  end_op();
    800059ac:	fffff097          	auipc	ra,0xfffff
    800059b0:	c8a080e7          	jalr	-886(ra) # 80004636 <end_op>
  return -1;
    800059b4:	57fd                	li	a5,-1
}
    800059b6:	853e                	mv	a0,a5
    800059b8:	70b2                	ld	ra,296(sp)
    800059ba:	7412                	ld	s0,288(sp)
    800059bc:	64f2                	ld	s1,280(sp)
    800059be:	6952                	ld	s2,272(sp)
    800059c0:	6155                	addi	sp,sp,304
    800059c2:	8082                	ret

00000000800059c4 <sys_unlink>:
{
    800059c4:	7151                	addi	sp,sp,-240
    800059c6:	f586                	sd	ra,232(sp)
    800059c8:	f1a2                	sd	s0,224(sp)
    800059ca:	eda6                	sd	s1,216(sp)
    800059cc:	e9ca                	sd	s2,208(sp)
    800059ce:	e5ce                	sd	s3,200(sp)
    800059d0:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800059d2:	08000613          	li	a2,128
    800059d6:	f3040593          	addi	a1,s0,-208
    800059da:	4501                	li	a0,0
    800059dc:	ffffd097          	auipc	ra,0xffffd
    800059e0:	63a080e7          	jalr	1594(ra) # 80003016 <argstr>
    800059e4:	18054163          	bltz	a0,80005b66 <sys_unlink+0x1a2>
  begin_op();
    800059e8:	fffff097          	auipc	ra,0xfffff
    800059ec:	bd0080e7          	jalr	-1072(ra) # 800045b8 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800059f0:	fb040593          	addi	a1,s0,-80
    800059f4:	f3040513          	addi	a0,s0,-208
    800059f8:	fffff097          	auipc	ra,0xfffff
    800059fc:	9be080e7          	jalr	-1602(ra) # 800043b6 <nameiparent>
    80005a00:	84aa                	mv	s1,a0
    80005a02:	c979                	beqz	a0,80005ad8 <sys_unlink+0x114>
  ilock(dp);
    80005a04:	ffffe097          	auipc	ra,0xffffe
    80005a08:	1e8080e7          	jalr	488(ra) # 80003bec <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005a0c:	00003597          	auipc	a1,0x3
    80005a10:	dd458593          	addi	a1,a1,-556 # 800087e0 <syscalls+0x2c0>
    80005a14:	fb040513          	addi	a0,s0,-80
    80005a18:	ffffe097          	auipc	ra,0xffffe
    80005a1c:	69e080e7          	jalr	1694(ra) # 800040b6 <namecmp>
    80005a20:	14050a63          	beqz	a0,80005b74 <sys_unlink+0x1b0>
    80005a24:	00003597          	auipc	a1,0x3
    80005a28:	dc458593          	addi	a1,a1,-572 # 800087e8 <syscalls+0x2c8>
    80005a2c:	fb040513          	addi	a0,s0,-80
    80005a30:	ffffe097          	auipc	ra,0xffffe
    80005a34:	686080e7          	jalr	1670(ra) # 800040b6 <namecmp>
    80005a38:	12050e63          	beqz	a0,80005b74 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005a3c:	f2c40613          	addi	a2,s0,-212
    80005a40:	fb040593          	addi	a1,s0,-80
    80005a44:	8526                	mv	a0,s1
    80005a46:	ffffe097          	auipc	ra,0xffffe
    80005a4a:	68a080e7          	jalr	1674(ra) # 800040d0 <dirlookup>
    80005a4e:	892a                	mv	s2,a0
    80005a50:	12050263          	beqz	a0,80005b74 <sys_unlink+0x1b0>
  ilock(ip);
    80005a54:	ffffe097          	auipc	ra,0xffffe
    80005a58:	198080e7          	jalr	408(ra) # 80003bec <ilock>
  if(ip->nlink < 1)
    80005a5c:	04a91783          	lh	a5,74(s2)
    80005a60:	08f05263          	blez	a5,80005ae4 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005a64:	04491703          	lh	a4,68(s2)
    80005a68:	4785                	li	a5,1
    80005a6a:	08f70563          	beq	a4,a5,80005af4 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005a6e:	4641                	li	a2,16
    80005a70:	4581                	li	a1,0
    80005a72:	fc040513          	addi	a0,s0,-64
    80005a76:	ffffb097          	auipc	ra,0xffffb
    80005a7a:	25c080e7          	jalr	604(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a7e:	4741                	li	a4,16
    80005a80:	f2c42683          	lw	a3,-212(s0)
    80005a84:	fc040613          	addi	a2,s0,-64
    80005a88:	4581                	li	a1,0
    80005a8a:	8526                	mv	a0,s1
    80005a8c:	ffffe097          	auipc	ra,0xffffe
    80005a90:	50c080e7          	jalr	1292(ra) # 80003f98 <writei>
    80005a94:	47c1                	li	a5,16
    80005a96:	0af51563          	bne	a0,a5,80005b40 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005a9a:	04491703          	lh	a4,68(s2)
    80005a9e:	4785                	li	a5,1
    80005aa0:	0af70863          	beq	a4,a5,80005b50 <sys_unlink+0x18c>
  iunlockput(dp);
    80005aa4:	8526                	mv	a0,s1
    80005aa6:	ffffe097          	auipc	ra,0xffffe
    80005aaa:	3a8080e7          	jalr	936(ra) # 80003e4e <iunlockput>
  ip->nlink--;
    80005aae:	04a95783          	lhu	a5,74(s2)
    80005ab2:	37fd                	addiw	a5,a5,-1
    80005ab4:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005ab8:	854a                	mv	a0,s2
    80005aba:	ffffe097          	auipc	ra,0xffffe
    80005abe:	066080e7          	jalr	102(ra) # 80003b20 <iupdate>
  iunlockput(ip);
    80005ac2:	854a                	mv	a0,s2
    80005ac4:	ffffe097          	auipc	ra,0xffffe
    80005ac8:	38a080e7          	jalr	906(ra) # 80003e4e <iunlockput>
  end_op();
    80005acc:	fffff097          	auipc	ra,0xfffff
    80005ad0:	b6a080e7          	jalr	-1174(ra) # 80004636 <end_op>
  return 0;
    80005ad4:	4501                	li	a0,0
    80005ad6:	a84d                	j	80005b88 <sys_unlink+0x1c4>
    end_op();
    80005ad8:	fffff097          	auipc	ra,0xfffff
    80005adc:	b5e080e7          	jalr	-1186(ra) # 80004636 <end_op>
    return -1;
    80005ae0:	557d                	li	a0,-1
    80005ae2:	a05d                	j	80005b88 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005ae4:	00003517          	auipc	a0,0x3
    80005ae8:	d0c50513          	addi	a0,a0,-756 # 800087f0 <syscalls+0x2d0>
    80005aec:	ffffb097          	auipc	ra,0xffffb
    80005af0:	a54080e7          	jalr	-1452(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005af4:	04c92703          	lw	a4,76(s2)
    80005af8:	02000793          	li	a5,32
    80005afc:	f6e7f9e3          	bgeu	a5,a4,80005a6e <sys_unlink+0xaa>
    80005b00:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b04:	4741                	li	a4,16
    80005b06:	86ce                	mv	a3,s3
    80005b08:	f1840613          	addi	a2,s0,-232
    80005b0c:	4581                	li	a1,0
    80005b0e:	854a                	mv	a0,s2
    80005b10:	ffffe097          	auipc	ra,0xffffe
    80005b14:	390080e7          	jalr	912(ra) # 80003ea0 <readi>
    80005b18:	47c1                	li	a5,16
    80005b1a:	00f51b63          	bne	a0,a5,80005b30 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005b1e:	f1845783          	lhu	a5,-232(s0)
    80005b22:	e7a1                	bnez	a5,80005b6a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b24:	29c1                	addiw	s3,s3,16
    80005b26:	04c92783          	lw	a5,76(s2)
    80005b2a:	fcf9ede3          	bltu	s3,a5,80005b04 <sys_unlink+0x140>
    80005b2e:	b781                	j	80005a6e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005b30:	00003517          	auipc	a0,0x3
    80005b34:	cd850513          	addi	a0,a0,-808 # 80008808 <syscalls+0x2e8>
    80005b38:	ffffb097          	auipc	ra,0xffffb
    80005b3c:	a08080e7          	jalr	-1528(ra) # 80000540 <panic>
    panic("unlink: writei");
    80005b40:	00003517          	auipc	a0,0x3
    80005b44:	ce050513          	addi	a0,a0,-800 # 80008820 <syscalls+0x300>
    80005b48:	ffffb097          	auipc	ra,0xffffb
    80005b4c:	9f8080e7          	jalr	-1544(ra) # 80000540 <panic>
    dp->nlink--;
    80005b50:	04a4d783          	lhu	a5,74(s1)
    80005b54:	37fd                	addiw	a5,a5,-1
    80005b56:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005b5a:	8526                	mv	a0,s1
    80005b5c:	ffffe097          	auipc	ra,0xffffe
    80005b60:	fc4080e7          	jalr	-60(ra) # 80003b20 <iupdate>
    80005b64:	b781                	j	80005aa4 <sys_unlink+0xe0>
    return -1;
    80005b66:	557d                	li	a0,-1
    80005b68:	a005                	j	80005b88 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005b6a:	854a                	mv	a0,s2
    80005b6c:	ffffe097          	auipc	ra,0xffffe
    80005b70:	2e2080e7          	jalr	738(ra) # 80003e4e <iunlockput>
  iunlockput(dp);
    80005b74:	8526                	mv	a0,s1
    80005b76:	ffffe097          	auipc	ra,0xffffe
    80005b7a:	2d8080e7          	jalr	728(ra) # 80003e4e <iunlockput>
  end_op();
    80005b7e:	fffff097          	auipc	ra,0xfffff
    80005b82:	ab8080e7          	jalr	-1352(ra) # 80004636 <end_op>
  return -1;
    80005b86:	557d                	li	a0,-1
}
    80005b88:	70ae                	ld	ra,232(sp)
    80005b8a:	740e                	ld	s0,224(sp)
    80005b8c:	64ee                	ld	s1,216(sp)
    80005b8e:	694e                	ld	s2,208(sp)
    80005b90:	69ae                	ld	s3,200(sp)
    80005b92:	616d                	addi	sp,sp,240
    80005b94:	8082                	ret

0000000080005b96 <sys_open>:

uint64
sys_open(void)
{
    80005b96:	7131                	addi	sp,sp,-192
    80005b98:	fd06                	sd	ra,184(sp)
    80005b9a:	f922                	sd	s0,176(sp)
    80005b9c:	f526                	sd	s1,168(sp)
    80005b9e:	f14a                	sd	s2,160(sp)
    80005ba0:	ed4e                	sd	s3,152(sp)
    80005ba2:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005ba4:	f4c40593          	addi	a1,s0,-180
    80005ba8:	4505                	li	a0,1
    80005baa:	ffffd097          	auipc	ra,0xffffd
    80005bae:	42c080e7          	jalr	1068(ra) # 80002fd6 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005bb2:	08000613          	li	a2,128
    80005bb6:	f5040593          	addi	a1,s0,-176
    80005bba:	4501                	li	a0,0
    80005bbc:	ffffd097          	auipc	ra,0xffffd
    80005bc0:	45a080e7          	jalr	1114(ra) # 80003016 <argstr>
    80005bc4:	87aa                	mv	a5,a0
    return -1;
    80005bc6:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005bc8:	0a07c963          	bltz	a5,80005c7a <sys_open+0xe4>

  begin_op();
    80005bcc:	fffff097          	auipc	ra,0xfffff
    80005bd0:	9ec080e7          	jalr	-1556(ra) # 800045b8 <begin_op>

  if(omode & O_CREATE){
    80005bd4:	f4c42783          	lw	a5,-180(s0)
    80005bd8:	2007f793          	andi	a5,a5,512
    80005bdc:	cfc5                	beqz	a5,80005c94 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005bde:	4681                	li	a3,0
    80005be0:	4601                	li	a2,0
    80005be2:	4589                	li	a1,2
    80005be4:	f5040513          	addi	a0,s0,-176
    80005be8:	00000097          	auipc	ra,0x0
    80005bec:	972080e7          	jalr	-1678(ra) # 8000555a <create>
    80005bf0:	84aa                	mv	s1,a0
    if(ip == 0){
    80005bf2:	c959                	beqz	a0,80005c88 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005bf4:	04449703          	lh	a4,68(s1)
    80005bf8:	478d                	li	a5,3
    80005bfa:	00f71763          	bne	a4,a5,80005c08 <sys_open+0x72>
    80005bfe:	0464d703          	lhu	a4,70(s1)
    80005c02:	47a5                	li	a5,9
    80005c04:	0ce7ed63          	bltu	a5,a4,80005cde <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005c08:	fffff097          	auipc	ra,0xfffff
    80005c0c:	dbc080e7          	jalr	-580(ra) # 800049c4 <filealloc>
    80005c10:	89aa                	mv	s3,a0
    80005c12:	10050363          	beqz	a0,80005d18 <sys_open+0x182>
    80005c16:	00000097          	auipc	ra,0x0
    80005c1a:	902080e7          	jalr	-1790(ra) # 80005518 <fdalloc>
    80005c1e:	892a                	mv	s2,a0
    80005c20:	0e054763          	bltz	a0,80005d0e <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005c24:	04449703          	lh	a4,68(s1)
    80005c28:	478d                	li	a5,3
    80005c2a:	0cf70563          	beq	a4,a5,80005cf4 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005c2e:	4789                	li	a5,2
    80005c30:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005c34:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005c38:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005c3c:	f4c42783          	lw	a5,-180(s0)
    80005c40:	0017c713          	xori	a4,a5,1
    80005c44:	8b05                	andi	a4,a4,1
    80005c46:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005c4a:	0037f713          	andi	a4,a5,3
    80005c4e:	00e03733          	snez	a4,a4
    80005c52:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005c56:	4007f793          	andi	a5,a5,1024
    80005c5a:	c791                	beqz	a5,80005c66 <sys_open+0xd0>
    80005c5c:	04449703          	lh	a4,68(s1)
    80005c60:	4789                	li	a5,2
    80005c62:	0af70063          	beq	a4,a5,80005d02 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005c66:	8526                	mv	a0,s1
    80005c68:	ffffe097          	auipc	ra,0xffffe
    80005c6c:	046080e7          	jalr	70(ra) # 80003cae <iunlock>
  end_op();
    80005c70:	fffff097          	auipc	ra,0xfffff
    80005c74:	9c6080e7          	jalr	-1594(ra) # 80004636 <end_op>

  return fd;
    80005c78:	854a                	mv	a0,s2
}
    80005c7a:	70ea                	ld	ra,184(sp)
    80005c7c:	744a                	ld	s0,176(sp)
    80005c7e:	74aa                	ld	s1,168(sp)
    80005c80:	790a                	ld	s2,160(sp)
    80005c82:	69ea                	ld	s3,152(sp)
    80005c84:	6129                	addi	sp,sp,192
    80005c86:	8082                	ret
      end_op();
    80005c88:	fffff097          	auipc	ra,0xfffff
    80005c8c:	9ae080e7          	jalr	-1618(ra) # 80004636 <end_op>
      return -1;
    80005c90:	557d                	li	a0,-1
    80005c92:	b7e5                	j	80005c7a <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005c94:	f5040513          	addi	a0,s0,-176
    80005c98:	ffffe097          	auipc	ra,0xffffe
    80005c9c:	700080e7          	jalr	1792(ra) # 80004398 <namei>
    80005ca0:	84aa                	mv	s1,a0
    80005ca2:	c905                	beqz	a0,80005cd2 <sys_open+0x13c>
    ilock(ip);
    80005ca4:	ffffe097          	auipc	ra,0xffffe
    80005ca8:	f48080e7          	jalr	-184(ra) # 80003bec <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005cac:	04449703          	lh	a4,68(s1)
    80005cb0:	4785                	li	a5,1
    80005cb2:	f4f711e3          	bne	a4,a5,80005bf4 <sys_open+0x5e>
    80005cb6:	f4c42783          	lw	a5,-180(s0)
    80005cba:	d7b9                	beqz	a5,80005c08 <sys_open+0x72>
      iunlockput(ip);
    80005cbc:	8526                	mv	a0,s1
    80005cbe:	ffffe097          	auipc	ra,0xffffe
    80005cc2:	190080e7          	jalr	400(ra) # 80003e4e <iunlockput>
      end_op();
    80005cc6:	fffff097          	auipc	ra,0xfffff
    80005cca:	970080e7          	jalr	-1680(ra) # 80004636 <end_op>
      return -1;
    80005cce:	557d                	li	a0,-1
    80005cd0:	b76d                	j	80005c7a <sys_open+0xe4>
      end_op();
    80005cd2:	fffff097          	auipc	ra,0xfffff
    80005cd6:	964080e7          	jalr	-1692(ra) # 80004636 <end_op>
      return -1;
    80005cda:	557d                	li	a0,-1
    80005cdc:	bf79                	j	80005c7a <sys_open+0xe4>
    iunlockput(ip);
    80005cde:	8526                	mv	a0,s1
    80005ce0:	ffffe097          	auipc	ra,0xffffe
    80005ce4:	16e080e7          	jalr	366(ra) # 80003e4e <iunlockput>
    end_op();
    80005ce8:	fffff097          	auipc	ra,0xfffff
    80005cec:	94e080e7          	jalr	-1714(ra) # 80004636 <end_op>
    return -1;
    80005cf0:	557d                	li	a0,-1
    80005cf2:	b761                	j	80005c7a <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005cf4:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005cf8:	04649783          	lh	a5,70(s1)
    80005cfc:	02f99223          	sh	a5,36(s3)
    80005d00:	bf25                	j	80005c38 <sys_open+0xa2>
    itrunc(ip);
    80005d02:	8526                	mv	a0,s1
    80005d04:	ffffe097          	auipc	ra,0xffffe
    80005d08:	ff6080e7          	jalr	-10(ra) # 80003cfa <itrunc>
    80005d0c:	bfa9                	j	80005c66 <sys_open+0xd0>
      fileclose(f);
    80005d0e:	854e                	mv	a0,s3
    80005d10:	fffff097          	auipc	ra,0xfffff
    80005d14:	d70080e7          	jalr	-656(ra) # 80004a80 <fileclose>
    iunlockput(ip);
    80005d18:	8526                	mv	a0,s1
    80005d1a:	ffffe097          	auipc	ra,0xffffe
    80005d1e:	134080e7          	jalr	308(ra) # 80003e4e <iunlockput>
    end_op();
    80005d22:	fffff097          	auipc	ra,0xfffff
    80005d26:	914080e7          	jalr	-1772(ra) # 80004636 <end_op>
    return -1;
    80005d2a:	557d                	li	a0,-1
    80005d2c:	b7b9                	j	80005c7a <sys_open+0xe4>

0000000080005d2e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005d2e:	7175                	addi	sp,sp,-144
    80005d30:	e506                	sd	ra,136(sp)
    80005d32:	e122                	sd	s0,128(sp)
    80005d34:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005d36:	fffff097          	auipc	ra,0xfffff
    80005d3a:	882080e7          	jalr	-1918(ra) # 800045b8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005d3e:	08000613          	li	a2,128
    80005d42:	f7040593          	addi	a1,s0,-144
    80005d46:	4501                	li	a0,0
    80005d48:	ffffd097          	auipc	ra,0xffffd
    80005d4c:	2ce080e7          	jalr	718(ra) # 80003016 <argstr>
    80005d50:	02054963          	bltz	a0,80005d82 <sys_mkdir+0x54>
    80005d54:	4681                	li	a3,0
    80005d56:	4601                	li	a2,0
    80005d58:	4585                	li	a1,1
    80005d5a:	f7040513          	addi	a0,s0,-144
    80005d5e:	fffff097          	auipc	ra,0xfffff
    80005d62:	7fc080e7          	jalr	2044(ra) # 8000555a <create>
    80005d66:	cd11                	beqz	a0,80005d82 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d68:	ffffe097          	auipc	ra,0xffffe
    80005d6c:	0e6080e7          	jalr	230(ra) # 80003e4e <iunlockput>
  end_op();
    80005d70:	fffff097          	auipc	ra,0xfffff
    80005d74:	8c6080e7          	jalr	-1850(ra) # 80004636 <end_op>
  return 0;
    80005d78:	4501                	li	a0,0
}
    80005d7a:	60aa                	ld	ra,136(sp)
    80005d7c:	640a                	ld	s0,128(sp)
    80005d7e:	6149                	addi	sp,sp,144
    80005d80:	8082                	ret
    end_op();
    80005d82:	fffff097          	auipc	ra,0xfffff
    80005d86:	8b4080e7          	jalr	-1868(ra) # 80004636 <end_op>
    return -1;
    80005d8a:	557d                	li	a0,-1
    80005d8c:	b7fd                	j	80005d7a <sys_mkdir+0x4c>

0000000080005d8e <sys_mknod>:

uint64
sys_mknod(void)
{
    80005d8e:	7135                	addi	sp,sp,-160
    80005d90:	ed06                	sd	ra,152(sp)
    80005d92:	e922                	sd	s0,144(sp)
    80005d94:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005d96:	fffff097          	auipc	ra,0xfffff
    80005d9a:	822080e7          	jalr	-2014(ra) # 800045b8 <begin_op>
  argint(1, &major);
    80005d9e:	f6c40593          	addi	a1,s0,-148
    80005da2:	4505                	li	a0,1
    80005da4:	ffffd097          	auipc	ra,0xffffd
    80005da8:	232080e7          	jalr	562(ra) # 80002fd6 <argint>
  argint(2, &minor);
    80005dac:	f6840593          	addi	a1,s0,-152
    80005db0:	4509                	li	a0,2
    80005db2:	ffffd097          	auipc	ra,0xffffd
    80005db6:	224080e7          	jalr	548(ra) # 80002fd6 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005dba:	08000613          	li	a2,128
    80005dbe:	f7040593          	addi	a1,s0,-144
    80005dc2:	4501                	li	a0,0
    80005dc4:	ffffd097          	auipc	ra,0xffffd
    80005dc8:	252080e7          	jalr	594(ra) # 80003016 <argstr>
    80005dcc:	02054b63          	bltz	a0,80005e02 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005dd0:	f6841683          	lh	a3,-152(s0)
    80005dd4:	f6c41603          	lh	a2,-148(s0)
    80005dd8:	458d                	li	a1,3
    80005dda:	f7040513          	addi	a0,s0,-144
    80005dde:	fffff097          	auipc	ra,0xfffff
    80005de2:	77c080e7          	jalr	1916(ra) # 8000555a <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005de6:	cd11                	beqz	a0,80005e02 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005de8:	ffffe097          	auipc	ra,0xffffe
    80005dec:	066080e7          	jalr	102(ra) # 80003e4e <iunlockput>
  end_op();
    80005df0:	fffff097          	auipc	ra,0xfffff
    80005df4:	846080e7          	jalr	-1978(ra) # 80004636 <end_op>
  return 0;
    80005df8:	4501                	li	a0,0
}
    80005dfa:	60ea                	ld	ra,152(sp)
    80005dfc:	644a                	ld	s0,144(sp)
    80005dfe:	610d                	addi	sp,sp,160
    80005e00:	8082                	ret
    end_op();
    80005e02:	fffff097          	auipc	ra,0xfffff
    80005e06:	834080e7          	jalr	-1996(ra) # 80004636 <end_op>
    return -1;
    80005e0a:	557d                	li	a0,-1
    80005e0c:	b7fd                	j	80005dfa <sys_mknod+0x6c>

0000000080005e0e <sys_chdir>:

uint64
sys_chdir(void)
{
    80005e0e:	7135                	addi	sp,sp,-160
    80005e10:	ed06                	sd	ra,152(sp)
    80005e12:	e922                	sd	s0,144(sp)
    80005e14:	e526                	sd	s1,136(sp)
    80005e16:	e14a                	sd	s2,128(sp)
    80005e18:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005e1a:	ffffc097          	auipc	ra,0xffffc
    80005e1e:	e30080e7          	jalr	-464(ra) # 80001c4a <myproc>
    80005e22:	892a                	mv	s2,a0
  
  begin_op();
    80005e24:	ffffe097          	auipc	ra,0xffffe
    80005e28:	794080e7          	jalr	1940(ra) # 800045b8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005e2c:	08000613          	li	a2,128
    80005e30:	f6040593          	addi	a1,s0,-160
    80005e34:	4501                	li	a0,0
    80005e36:	ffffd097          	auipc	ra,0xffffd
    80005e3a:	1e0080e7          	jalr	480(ra) # 80003016 <argstr>
    80005e3e:	04054b63          	bltz	a0,80005e94 <sys_chdir+0x86>
    80005e42:	f6040513          	addi	a0,s0,-160
    80005e46:	ffffe097          	auipc	ra,0xffffe
    80005e4a:	552080e7          	jalr	1362(ra) # 80004398 <namei>
    80005e4e:	84aa                	mv	s1,a0
    80005e50:	c131                	beqz	a0,80005e94 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005e52:	ffffe097          	auipc	ra,0xffffe
    80005e56:	d9a080e7          	jalr	-614(ra) # 80003bec <ilock>
  if(ip->type != T_DIR){
    80005e5a:	04449703          	lh	a4,68(s1)
    80005e5e:	4785                	li	a5,1
    80005e60:	04f71063          	bne	a4,a5,80005ea0 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005e64:	8526                	mv	a0,s1
    80005e66:	ffffe097          	auipc	ra,0xffffe
    80005e6a:	e48080e7          	jalr	-440(ra) # 80003cae <iunlock>
  iput(p->cwd);
    80005e6e:	15893503          	ld	a0,344(s2)
    80005e72:	ffffe097          	auipc	ra,0xffffe
    80005e76:	f34080e7          	jalr	-204(ra) # 80003da6 <iput>
  end_op();
    80005e7a:	ffffe097          	auipc	ra,0xffffe
    80005e7e:	7bc080e7          	jalr	1980(ra) # 80004636 <end_op>
  p->cwd = ip;
    80005e82:	14993c23          	sd	s1,344(s2)
  return 0;
    80005e86:	4501                	li	a0,0
}
    80005e88:	60ea                	ld	ra,152(sp)
    80005e8a:	644a                	ld	s0,144(sp)
    80005e8c:	64aa                	ld	s1,136(sp)
    80005e8e:	690a                	ld	s2,128(sp)
    80005e90:	610d                	addi	sp,sp,160
    80005e92:	8082                	ret
    end_op();
    80005e94:	ffffe097          	auipc	ra,0xffffe
    80005e98:	7a2080e7          	jalr	1954(ra) # 80004636 <end_op>
    return -1;
    80005e9c:	557d                	li	a0,-1
    80005e9e:	b7ed                	j	80005e88 <sys_chdir+0x7a>
    iunlockput(ip);
    80005ea0:	8526                	mv	a0,s1
    80005ea2:	ffffe097          	auipc	ra,0xffffe
    80005ea6:	fac080e7          	jalr	-84(ra) # 80003e4e <iunlockput>
    end_op();
    80005eaa:	ffffe097          	auipc	ra,0xffffe
    80005eae:	78c080e7          	jalr	1932(ra) # 80004636 <end_op>
    return -1;
    80005eb2:	557d                	li	a0,-1
    80005eb4:	bfd1                	j	80005e88 <sys_chdir+0x7a>

0000000080005eb6 <sys_exec>:

uint64
sys_exec(void)
{
    80005eb6:	7145                	addi	sp,sp,-464
    80005eb8:	e786                	sd	ra,456(sp)
    80005eba:	e3a2                	sd	s0,448(sp)
    80005ebc:	ff26                	sd	s1,440(sp)
    80005ebe:	fb4a                	sd	s2,432(sp)
    80005ec0:	f74e                	sd	s3,424(sp)
    80005ec2:	f352                	sd	s4,416(sp)
    80005ec4:	ef56                	sd	s5,408(sp)
    80005ec6:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005ec8:	e3840593          	addi	a1,s0,-456
    80005ecc:	4505                	li	a0,1
    80005ece:	ffffd097          	auipc	ra,0xffffd
    80005ed2:	128080e7          	jalr	296(ra) # 80002ff6 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005ed6:	08000613          	li	a2,128
    80005eda:	f4040593          	addi	a1,s0,-192
    80005ede:	4501                	li	a0,0
    80005ee0:	ffffd097          	auipc	ra,0xffffd
    80005ee4:	136080e7          	jalr	310(ra) # 80003016 <argstr>
    80005ee8:	87aa                	mv	a5,a0
    return -1;
    80005eea:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005eec:	0c07c363          	bltz	a5,80005fb2 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005ef0:	10000613          	li	a2,256
    80005ef4:	4581                	li	a1,0
    80005ef6:	e4040513          	addi	a0,s0,-448
    80005efa:	ffffb097          	auipc	ra,0xffffb
    80005efe:	dd8080e7          	jalr	-552(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005f02:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005f06:	89a6                	mv	s3,s1
    80005f08:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005f0a:	02000a13          	li	s4,32
    80005f0e:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005f12:	00391513          	slli	a0,s2,0x3
    80005f16:	e3040593          	addi	a1,s0,-464
    80005f1a:	e3843783          	ld	a5,-456(s0)
    80005f1e:	953e                	add	a0,a0,a5
    80005f20:	ffffd097          	auipc	ra,0xffffd
    80005f24:	018080e7          	jalr	24(ra) # 80002f38 <fetchaddr>
    80005f28:	02054a63          	bltz	a0,80005f5c <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005f2c:	e3043783          	ld	a5,-464(s0)
    80005f30:	c3b9                	beqz	a5,80005f76 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005f32:	ffffb097          	auipc	ra,0xffffb
    80005f36:	bb4080e7          	jalr	-1100(ra) # 80000ae6 <kalloc>
    80005f3a:	85aa                	mv	a1,a0
    80005f3c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005f40:	cd11                	beqz	a0,80005f5c <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005f42:	6605                	lui	a2,0x1
    80005f44:	e3043503          	ld	a0,-464(s0)
    80005f48:	ffffd097          	auipc	ra,0xffffd
    80005f4c:	042080e7          	jalr	66(ra) # 80002f8a <fetchstr>
    80005f50:	00054663          	bltz	a0,80005f5c <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005f54:	0905                	addi	s2,s2,1
    80005f56:	09a1                	addi	s3,s3,8
    80005f58:	fb491be3          	bne	s2,s4,80005f0e <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f5c:	f4040913          	addi	s2,s0,-192
    80005f60:	6088                	ld	a0,0(s1)
    80005f62:	c539                	beqz	a0,80005fb0 <sys_exec+0xfa>
    kfree(argv[i]);
    80005f64:	ffffb097          	auipc	ra,0xffffb
    80005f68:	a84080e7          	jalr	-1404(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f6c:	04a1                	addi	s1,s1,8
    80005f6e:	ff2499e3          	bne	s1,s2,80005f60 <sys_exec+0xaa>
  return -1;
    80005f72:	557d                	li	a0,-1
    80005f74:	a83d                	j	80005fb2 <sys_exec+0xfc>
      argv[i] = 0;
    80005f76:	0a8e                	slli	s5,s5,0x3
    80005f78:	fc0a8793          	addi	a5,s5,-64
    80005f7c:	00878ab3          	add	s5,a5,s0
    80005f80:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005f84:	e4040593          	addi	a1,s0,-448
    80005f88:	f4040513          	addi	a0,s0,-192
    80005f8c:	fffff097          	auipc	ra,0xfffff
    80005f90:	16e080e7          	jalr	366(ra) # 800050fa <exec>
    80005f94:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f96:	f4040993          	addi	s3,s0,-192
    80005f9a:	6088                	ld	a0,0(s1)
    80005f9c:	c901                	beqz	a0,80005fac <sys_exec+0xf6>
    kfree(argv[i]);
    80005f9e:	ffffb097          	auipc	ra,0xffffb
    80005fa2:	a4a080e7          	jalr	-1462(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fa6:	04a1                	addi	s1,s1,8
    80005fa8:	ff3499e3          	bne	s1,s3,80005f9a <sys_exec+0xe4>
  return ret;
    80005fac:	854a                	mv	a0,s2
    80005fae:	a011                	j	80005fb2 <sys_exec+0xfc>
  return -1;
    80005fb0:	557d                	li	a0,-1
}
    80005fb2:	60be                	ld	ra,456(sp)
    80005fb4:	641e                	ld	s0,448(sp)
    80005fb6:	74fa                	ld	s1,440(sp)
    80005fb8:	795a                	ld	s2,432(sp)
    80005fba:	79ba                	ld	s3,424(sp)
    80005fbc:	7a1a                	ld	s4,416(sp)
    80005fbe:	6afa                	ld	s5,408(sp)
    80005fc0:	6179                	addi	sp,sp,464
    80005fc2:	8082                	ret

0000000080005fc4 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005fc4:	7139                	addi	sp,sp,-64
    80005fc6:	fc06                	sd	ra,56(sp)
    80005fc8:	f822                	sd	s0,48(sp)
    80005fca:	f426                	sd	s1,40(sp)
    80005fcc:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005fce:	ffffc097          	auipc	ra,0xffffc
    80005fd2:	c7c080e7          	jalr	-900(ra) # 80001c4a <myproc>
    80005fd6:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005fd8:	fd840593          	addi	a1,s0,-40
    80005fdc:	4501                	li	a0,0
    80005fde:	ffffd097          	auipc	ra,0xffffd
    80005fe2:	018080e7          	jalr	24(ra) # 80002ff6 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005fe6:	fc840593          	addi	a1,s0,-56
    80005fea:	fd040513          	addi	a0,s0,-48
    80005fee:	fffff097          	auipc	ra,0xfffff
    80005ff2:	dc2080e7          	jalr	-574(ra) # 80004db0 <pipealloc>
    return -1;
    80005ff6:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005ff8:	0c054463          	bltz	a0,800060c0 <sys_pipe+0xfc>
  fd0 = -1;
    80005ffc:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006000:	fd043503          	ld	a0,-48(s0)
    80006004:	fffff097          	auipc	ra,0xfffff
    80006008:	514080e7          	jalr	1300(ra) # 80005518 <fdalloc>
    8000600c:	fca42223          	sw	a0,-60(s0)
    80006010:	08054b63          	bltz	a0,800060a6 <sys_pipe+0xe2>
    80006014:	fc843503          	ld	a0,-56(s0)
    80006018:	fffff097          	auipc	ra,0xfffff
    8000601c:	500080e7          	jalr	1280(ra) # 80005518 <fdalloc>
    80006020:	fca42023          	sw	a0,-64(s0)
    80006024:	06054863          	bltz	a0,80006094 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006028:	4691                	li	a3,4
    8000602a:	fc440613          	addi	a2,s0,-60
    8000602e:	fd843583          	ld	a1,-40(s0)
    80006032:	6ca8                	ld	a0,88(s1)
    80006034:	ffffb097          	auipc	ra,0xffffb
    80006038:	638080e7          	jalr	1592(ra) # 8000166c <copyout>
    8000603c:	02054063          	bltz	a0,8000605c <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006040:	4691                	li	a3,4
    80006042:	fc040613          	addi	a2,s0,-64
    80006046:	fd843583          	ld	a1,-40(s0)
    8000604a:	0591                	addi	a1,a1,4
    8000604c:	6ca8                	ld	a0,88(s1)
    8000604e:	ffffb097          	auipc	ra,0xffffb
    80006052:	61e080e7          	jalr	1566(ra) # 8000166c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006056:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006058:	06055463          	bgez	a0,800060c0 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    8000605c:	fc442783          	lw	a5,-60(s0)
    80006060:	07e9                	addi	a5,a5,26
    80006062:	078e                	slli	a5,a5,0x3
    80006064:	97a6                	add	a5,a5,s1
    80006066:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    8000606a:	fc042783          	lw	a5,-64(s0)
    8000606e:	07e9                	addi	a5,a5,26
    80006070:	078e                	slli	a5,a5,0x3
    80006072:	94be                	add	s1,s1,a5
    80006074:	0004b423          	sd	zero,8(s1)
    fileclose(rf);
    80006078:	fd043503          	ld	a0,-48(s0)
    8000607c:	fffff097          	auipc	ra,0xfffff
    80006080:	a04080e7          	jalr	-1532(ra) # 80004a80 <fileclose>
    fileclose(wf);
    80006084:	fc843503          	ld	a0,-56(s0)
    80006088:	fffff097          	auipc	ra,0xfffff
    8000608c:	9f8080e7          	jalr	-1544(ra) # 80004a80 <fileclose>
    return -1;
    80006090:	57fd                	li	a5,-1
    80006092:	a03d                	j	800060c0 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80006094:	fc442783          	lw	a5,-60(s0)
    80006098:	0007c763          	bltz	a5,800060a6 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    8000609c:	07e9                	addi	a5,a5,26
    8000609e:	078e                	slli	a5,a5,0x3
    800060a0:	97a6                	add	a5,a5,s1
    800060a2:	0007b423          	sd	zero,8(a5)
    fileclose(rf);
    800060a6:	fd043503          	ld	a0,-48(s0)
    800060aa:	fffff097          	auipc	ra,0xfffff
    800060ae:	9d6080e7          	jalr	-1578(ra) # 80004a80 <fileclose>
    fileclose(wf);
    800060b2:	fc843503          	ld	a0,-56(s0)
    800060b6:	fffff097          	auipc	ra,0xfffff
    800060ba:	9ca080e7          	jalr	-1590(ra) # 80004a80 <fileclose>
    return -1;
    800060be:	57fd                	li	a5,-1
}
    800060c0:	853e                	mv	a0,a5
    800060c2:	70e2                	ld	ra,56(sp)
    800060c4:	7442                	ld	s0,48(sp)
    800060c6:	74a2                	ld	s1,40(sp)
    800060c8:	6121                	addi	sp,sp,64
    800060ca:	8082                	ret
    800060cc:	0000                	unimp
	...

00000000800060d0 <kernelvec>:
    800060d0:	7111                	addi	sp,sp,-256
    800060d2:	e006                	sd	ra,0(sp)
    800060d4:	e40a                	sd	sp,8(sp)
    800060d6:	e80e                	sd	gp,16(sp)
    800060d8:	ec12                	sd	tp,24(sp)
    800060da:	f016                	sd	t0,32(sp)
    800060dc:	f41a                	sd	t1,40(sp)
    800060de:	f81e                	sd	t2,48(sp)
    800060e0:	fc22                	sd	s0,56(sp)
    800060e2:	e0a6                	sd	s1,64(sp)
    800060e4:	e4aa                	sd	a0,72(sp)
    800060e6:	e8ae                	sd	a1,80(sp)
    800060e8:	ecb2                	sd	a2,88(sp)
    800060ea:	f0b6                	sd	a3,96(sp)
    800060ec:	f4ba                	sd	a4,104(sp)
    800060ee:	f8be                	sd	a5,112(sp)
    800060f0:	fcc2                	sd	a6,120(sp)
    800060f2:	e146                	sd	a7,128(sp)
    800060f4:	e54a                	sd	s2,136(sp)
    800060f6:	e94e                	sd	s3,144(sp)
    800060f8:	ed52                	sd	s4,152(sp)
    800060fa:	f156                	sd	s5,160(sp)
    800060fc:	f55a                	sd	s6,168(sp)
    800060fe:	f95e                	sd	s7,176(sp)
    80006100:	fd62                	sd	s8,184(sp)
    80006102:	e1e6                	sd	s9,192(sp)
    80006104:	e5ea                	sd	s10,200(sp)
    80006106:	e9ee                	sd	s11,208(sp)
    80006108:	edf2                	sd	t3,216(sp)
    8000610a:	f1f6                	sd	t4,224(sp)
    8000610c:	f5fa                	sd	t5,232(sp)
    8000610e:	f9fe                	sd	t6,240(sp)
    80006110:	cf3fc0ef          	jal	ra,80002e02 <kerneltrap>
    80006114:	6082                	ld	ra,0(sp)
    80006116:	6122                	ld	sp,8(sp)
    80006118:	61c2                	ld	gp,16(sp)
    8000611a:	7282                	ld	t0,32(sp)
    8000611c:	7322                	ld	t1,40(sp)
    8000611e:	73c2                	ld	t2,48(sp)
    80006120:	7462                	ld	s0,56(sp)
    80006122:	6486                	ld	s1,64(sp)
    80006124:	6526                	ld	a0,72(sp)
    80006126:	65c6                	ld	a1,80(sp)
    80006128:	6666                	ld	a2,88(sp)
    8000612a:	7686                	ld	a3,96(sp)
    8000612c:	7726                	ld	a4,104(sp)
    8000612e:	77c6                	ld	a5,112(sp)
    80006130:	7866                	ld	a6,120(sp)
    80006132:	688a                	ld	a7,128(sp)
    80006134:	692a                	ld	s2,136(sp)
    80006136:	69ca                	ld	s3,144(sp)
    80006138:	6a6a                	ld	s4,152(sp)
    8000613a:	7a8a                	ld	s5,160(sp)
    8000613c:	7b2a                	ld	s6,168(sp)
    8000613e:	7bca                	ld	s7,176(sp)
    80006140:	7c6a                	ld	s8,184(sp)
    80006142:	6c8e                	ld	s9,192(sp)
    80006144:	6d2e                	ld	s10,200(sp)
    80006146:	6dce                	ld	s11,208(sp)
    80006148:	6e6e                	ld	t3,216(sp)
    8000614a:	7e8e                	ld	t4,224(sp)
    8000614c:	7f2e                	ld	t5,232(sp)
    8000614e:	7fce                	ld	t6,240(sp)
    80006150:	6111                	addi	sp,sp,256
    80006152:	10200073          	sret
    80006156:	00000013          	nop
    8000615a:	00000013          	nop
    8000615e:	0001                	nop

0000000080006160 <timervec>:
    80006160:	34051573          	csrrw	a0,mscratch,a0
    80006164:	e10c                	sd	a1,0(a0)
    80006166:	e510                	sd	a2,8(a0)
    80006168:	e914                	sd	a3,16(a0)
    8000616a:	6d0c                	ld	a1,24(a0)
    8000616c:	7110                	ld	a2,32(a0)
    8000616e:	6194                	ld	a3,0(a1)
    80006170:	96b2                	add	a3,a3,a2
    80006172:	e194                	sd	a3,0(a1)
    80006174:	4589                	li	a1,2
    80006176:	14459073          	csrw	sip,a1
    8000617a:	6914                	ld	a3,16(a0)
    8000617c:	6510                	ld	a2,8(a0)
    8000617e:	610c                	ld	a1,0(a0)
    80006180:	34051573          	csrrw	a0,mscratch,a0
    80006184:	30200073          	mret
	...

000000008000618a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000618a:	1141                	addi	sp,sp,-16
    8000618c:	e422                	sd	s0,8(sp)
    8000618e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006190:	0c0007b7          	lui	a5,0xc000
    80006194:	4705                	li	a4,1
    80006196:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006198:	c3d8                	sw	a4,4(a5)
}
    8000619a:	6422                	ld	s0,8(sp)
    8000619c:	0141                	addi	sp,sp,16
    8000619e:	8082                	ret

00000000800061a0 <plicinithart>:

void
plicinithart(void)
{
    800061a0:	1141                	addi	sp,sp,-16
    800061a2:	e406                	sd	ra,8(sp)
    800061a4:	e022                	sd	s0,0(sp)
    800061a6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800061a8:	ffffc097          	auipc	ra,0xffffc
    800061ac:	a70080e7          	jalr	-1424(ra) # 80001c18 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800061b0:	0085171b          	slliw	a4,a0,0x8
    800061b4:	0c0027b7          	lui	a5,0xc002
    800061b8:	97ba                	add	a5,a5,a4
    800061ba:	40200713          	li	a4,1026
    800061be:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800061c2:	00d5151b          	slliw	a0,a0,0xd
    800061c6:	0c2017b7          	lui	a5,0xc201
    800061ca:	97aa                	add	a5,a5,a0
    800061cc:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    800061d0:	60a2                	ld	ra,8(sp)
    800061d2:	6402                	ld	s0,0(sp)
    800061d4:	0141                	addi	sp,sp,16
    800061d6:	8082                	ret

00000000800061d8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800061d8:	1141                	addi	sp,sp,-16
    800061da:	e406                	sd	ra,8(sp)
    800061dc:	e022                	sd	s0,0(sp)
    800061de:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800061e0:	ffffc097          	auipc	ra,0xffffc
    800061e4:	a38080e7          	jalr	-1480(ra) # 80001c18 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800061e8:	00d5151b          	slliw	a0,a0,0xd
    800061ec:	0c2017b7          	lui	a5,0xc201
    800061f0:	97aa                	add	a5,a5,a0
  return irq;
}
    800061f2:	43c8                	lw	a0,4(a5)
    800061f4:	60a2                	ld	ra,8(sp)
    800061f6:	6402                	ld	s0,0(sp)
    800061f8:	0141                	addi	sp,sp,16
    800061fa:	8082                	ret

00000000800061fc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800061fc:	1101                	addi	sp,sp,-32
    800061fe:	ec06                	sd	ra,24(sp)
    80006200:	e822                	sd	s0,16(sp)
    80006202:	e426                	sd	s1,8(sp)
    80006204:	1000                	addi	s0,sp,32
    80006206:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006208:	ffffc097          	auipc	ra,0xffffc
    8000620c:	a10080e7          	jalr	-1520(ra) # 80001c18 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006210:	00d5151b          	slliw	a0,a0,0xd
    80006214:	0c2017b7          	lui	a5,0xc201
    80006218:	97aa                	add	a5,a5,a0
    8000621a:	c3c4                	sw	s1,4(a5)
}
    8000621c:	60e2                	ld	ra,24(sp)
    8000621e:	6442                	ld	s0,16(sp)
    80006220:	64a2                	ld	s1,8(sp)
    80006222:	6105                	addi	sp,sp,32
    80006224:	8082                	ret

0000000080006226 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006226:	1141                	addi	sp,sp,-16
    80006228:	e406                	sd	ra,8(sp)
    8000622a:	e022                	sd	s0,0(sp)
    8000622c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000622e:	479d                	li	a5,7
    80006230:	04a7cc63          	blt	a5,a0,80006288 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006234:	0001c797          	auipc	a5,0x1c
    80006238:	d6c78793          	addi	a5,a5,-660 # 80021fa0 <disk>
    8000623c:	97aa                	add	a5,a5,a0
    8000623e:	0187c783          	lbu	a5,24(a5)
    80006242:	ebb9                	bnez	a5,80006298 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006244:	00451693          	slli	a3,a0,0x4
    80006248:	0001c797          	auipc	a5,0x1c
    8000624c:	d5878793          	addi	a5,a5,-680 # 80021fa0 <disk>
    80006250:	6398                	ld	a4,0(a5)
    80006252:	9736                	add	a4,a4,a3
    80006254:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80006258:	6398                	ld	a4,0(a5)
    8000625a:	9736                	add	a4,a4,a3
    8000625c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006260:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006264:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006268:	97aa                	add	a5,a5,a0
    8000626a:	4705                	li	a4,1
    8000626c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80006270:	0001c517          	auipc	a0,0x1c
    80006274:	d4850513          	addi	a0,a0,-696 # 80021fb8 <disk+0x18>
    80006278:	ffffc097          	auipc	ra,0xffffc
    8000627c:	206080e7          	jalr	518(ra) # 8000247e <wakeup>
}
    80006280:	60a2                	ld	ra,8(sp)
    80006282:	6402                	ld	s0,0(sp)
    80006284:	0141                	addi	sp,sp,16
    80006286:	8082                	ret
    panic("free_desc 1");
    80006288:	00002517          	auipc	a0,0x2
    8000628c:	5a850513          	addi	a0,a0,1448 # 80008830 <syscalls+0x310>
    80006290:	ffffa097          	auipc	ra,0xffffa
    80006294:	2b0080e7          	jalr	688(ra) # 80000540 <panic>
    panic("free_desc 2");
    80006298:	00002517          	auipc	a0,0x2
    8000629c:	5a850513          	addi	a0,a0,1448 # 80008840 <syscalls+0x320>
    800062a0:	ffffa097          	auipc	ra,0xffffa
    800062a4:	2a0080e7          	jalr	672(ra) # 80000540 <panic>

00000000800062a8 <virtio_disk_init>:
{
    800062a8:	1101                	addi	sp,sp,-32
    800062aa:	ec06                	sd	ra,24(sp)
    800062ac:	e822                	sd	s0,16(sp)
    800062ae:	e426                	sd	s1,8(sp)
    800062b0:	e04a                	sd	s2,0(sp)
    800062b2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800062b4:	00002597          	auipc	a1,0x2
    800062b8:	59c58593          	addi	a1,a1,1436 # 80008850 <syscalls+0x330>
    800062bc:	0001c517          	auipc	a0,0x1c
    800062c0:	e0c50513          	addi	a0,a0,-500 # 800220c8 <disk+0x128>
    800062c4:	ffffb097          	auipc	ra,0xffffb
    800062c8:	882080e7          	jalr	-1918(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800062cc:	100017b7          	lui	a5,0x10001
    800062d0:	4398                	lw	a4,0(a5)
    800062d2:	2701                	sext.w	a4,a4
    800062d4:	747277b7          	lui	a5,0x74727
    800062d8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800062dc:	14f71b63          	bne	a4,a5,80006432 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800062e0:	100017b7          	lui	a5,0x10001
    800062e4:	43dc                	lw	a5,4(a5)
    800062e6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800062e8:	4709                	li	a4,2
    800062ea:	14e79463          	bne	a5,a4,80006432 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800062ee:	100017b7          	lui	a5,0x10001
    800062f2:	479c                	lw	a5,8(a5)
    800062f4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800062f6:	12e79e63          	bne	a5,a4,80006432 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800062fa:	100017b7          	lui	a5,0x10001
    800062fe:	47d8                	lw	a4,12(a5)
    80006300:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006302:	554d47b7          	lui	a5,0x554d4
    80006306:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000630a:	12f71463          	bne	a4,a5,80006432 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000630e:	100017b7          	lui	a5,0x10001
    80006312:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006316:	4705                	li	a4,1
    80006318:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000631a:	470d                	li	a4,3
    8000631c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000631e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006320:	c7ffe6b7          	lui	a3,0xc7ffe
    80006324:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc67f>
    80006328:	8f75                	and	a4,a4,a3
    8000632a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000632c:	472d                	li	a4,11
    8000632e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006330:	5bbc                	lw	a5,112(a5)
    80006332:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006336:	8ba1                	andi	a5,a5,8
    80006338:	10078563          	beqz	a5,80006442 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000633c:	100017b7          	lui	a5,0x10001
    80006340:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006344:	43fc                	lw	a5,68(a5)
    80006346:	2781                	sext.w	a5,a5
    80006348:	10079563          	bnez	a5,80006452 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000634c:	100017b7          	lui	a5,0x10001
    80006350:	5bdc                	lw	a5,52(a5)
    80006352:	2781                	sext.w	a5,a5
  if(max == 0)
    80006354:	10078763          	beqz	a5,80006462 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006358:	471d                	li	a4,7
    8000635a:	10f77c63          	bgeu	a4,a5,80006472 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    8000635e:	ffffa097          	auipc	ra,0xffffa
    80006362:	788080e7          	jalr	1928(ra) # 80000ae6 <kalloc>
    80006366:	0001c497          	auipc	s1,0x1c
    8000636a:	c3a48493          	addi	s1,s1,-966 # 80021fa0 <disk>
    8000636e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006370:	ffffa097          	auipc	ra,0xffffa
    80006374:	776080e7          	jalr	1910(ra) # 80000ae6 <kalloc>
    80006378:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000637a:	ffffa097          	auipc	ra,0xffffa
    8000637e:	76c080e7          	jalr	1900(ra) # 80000ae6 <kalloc>
    80006382:	87aa                	mv	a5,a0
    80006384:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006386:	6088                	ld	a0,0(s1)
    80006388:	cd6d                	beqz	a0,80006482 <virtio_disk_init+0x1da>
    8000638a:	0001c717          	auipc	a4,0x1c
    8000638e:	c1e73703          	ld	a4,-994(a4) # 80021fa8 <disk+0x8>
    80006392:	cb65                	beqz	a4,80006482 <virtio_disk_init+0x1da>
    80006394:	c7fd                	beqz	a5,80006482 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80006396:	6605                	lui	a2,0x1
    80006398:	4581                	li	a1,0
    8000639a:	ffffb097          	auipc	ra,0xffffb
    8000639e:	938080e7          	jalr	-1736(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    800063a2:	0001c497          	auipc	s1,0x1c
    800063a6:	bfe48493          	addi	s1,s1,-1026 # 80021fa0 <disk>
    800063aa:	6605                	lui	a2,0x1
    800063ac:	4581                	li	a1,0
    800063ae:	6488                	ld	a0,8(s1)
    800063b0:	ffffb097          	auipc	ra,0xffffb
    800063b4:	922080e7          	jalr	-1758(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    800063b8:	6605                	lui	a2,0x1
    800063ba:	4581                	li	a1,0
    800063bc:	6888                	ld	a0,16(s1)
    800063be:	ffffb097          	auipc	ra,0xffffb
    800063c2:	914080e7          	jalr	-1772(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800063c6:	100017b7          	lui	a5,0x10001
    800063ca:	4721                	li	a4,8
    800063cc:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800063ce:	4098                	lw	a4,0(s1)
    800063d0:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800063d4:	40d8                	lw	a4,4(s1)
    800063d6:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800063da:	6498                	ld	a4,8(s1)
    800063dc:	0007069b          	sext.w	a3,a4
    800063e0:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800063e4:	9701                	srai	a4,a4,0x20
    800063e6:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800063ea:	6898                	ld	a4,16(s1)
    800063ec:	0007069b          	sext.w	a3,a4
    800063f0:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800063f4:	9701                	srai	a4,a4,0x20
    800063f6:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800063fa:	4705                	li	a4,1
    800063fc:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    800063fe:	00e48c23          	sb	a4,24(s1)
    80006402:	00e48ca3          	sb	a4,25(s1)
    80006406:	00e48d23          	sb	a4,26(s1)
    8000640a:	00e48da3          	sb	a4,27(s1)
    8000640e:	00e48e23          	sb	a4,28(s1)
    80006412:	00e48ea3          	sb	a4,29(s1)
    80006416:	00e48f23          	sb	a4,30(s1)
    8000641a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000641e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006422:	0727a823          	sw	s2,112(a5)
}
    80006426:	60e2                	ld	ra,24(sp)
    80006428:	6442                	ld	s0,16(sp)
    8000642a:	64a2                	ld	s1,8(sp)
    8000642c:	6902                	ld	s2,0(sp)
    8000642e:	6105                	addi	sp,sp,32
    80006430:	8082                	ret
    panic("could not find virtio disk");
    80006432:	00002517          	auipc	a0,0x2
    80006436:	42e50513          	addi	a0,a0,1070 # 80008860 <syscalls+0x340>
    8000643a:	ffffa097          	auipc	ra,0xffffa
    8000643e:	106080e7          	jalr	262(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006442:	00002517          	auipc	a0,0x2
    80006446:	43e50513          	addi	a0,a0,1086 # 80008880 <syscalls+0x360>
    8000644a:	ffffa097          	auipc	ra,0xffffa
    8000644e:	0f6080e7          	jalr	246(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80006452:	00002517          	auipc	a0,0x2
    80006456:	44e50513          	addi	a0,a0,1102 # 800088a0 <syscalls+0x380>
    8000645a:	ffffa097          	auipc	ra,0xffffa
    8000645e:	0e6080e7          	jalr	230(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006462:	00002517          	auipc	a0,0x2
    80006466:	45e50513          	addi	a0,a0,1118 # 800088c0 <syscalls+0x3a0>
    8000646a:	ffffa097          	auipc	ra,0xffffa
    8000646e:	0d6080e7          	jalr	214(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80006472:	00002517          	auipc	a0,0x2
    80006476:	46e50513          	addi	a0,a0,1134 # 800088e0 <syscalls+0x3c0>
    8000647a:	ffffa097          	auipc	ra,0xffffa
    8000647e:	0c6080e7          	jalr	198(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80006482:	00002517          	auipc	a0,0x2
    80006486:	47e50513          	addi	a0,a0,1150 # 80008900 <syscalls+0x3e0>
    8000648a:	ffffa097          	auipc	ra,0xffffa
    8000648e:	0b6080e7          	jalr	182(ra) # 80000540 <panic>

0000000080006492 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006492:	7119                	addi	sp,sp,-128
    80006494:	fc86                	sd	ra,120(sp)
    80006496:	f8a2                	sd	s0,112(sp)
    80006498:	f4a6                	sd	s1,104(sp)
    8000649a:	f0ca                	sd	s2,96(sp)
    8000649c:	ecce                	sd	s3,88(sp)
    8000649e:	e8d2                	sd	s4,80(sp)
    800064a0:	e4d6                	sd	s5,72(sp)
    800064a2:	e0da                	sd	s6,64(sp)
    800064a4:	fc5e                	sd	s7,56(sp)
    800064a6:	f862                	sd	s8,48(sp)
    800064a8:	f466                	sd	s9,40(sp)
    800064aa:	f06a                	sd	s10,32(sp)
    800064ac:	ec6e                	sd	s11,24(sp)
    800064ae:	0100                	addi	s0,sp,128
    800064b0:	8aaa                	mv	s5,a0
    800064b2:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800064b4:	00c52d03          	lw	s10,12(a0)
    800064b8:	001d1d1b          	slliw	s10,s10,0x1
    800064bc:	1d02                	slli	s10,s10,0x20
    800064be:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800064c2:	0001c517          	auipc	a0,0x1c
    800064c6:	c0650513          	addi	a0,a0,-1018 # 800220c8 <disk+0x128>
    800064ca:	ffffa097          	auipc	ra,0xffffa
    800064ce:	70c080e7          	jalr	1804(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    800064d2:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800064d4:	44a1                	li	s1,8
      disk.free[i] = 0;
    800064d6:	0001cb97          	auipc	s7,0x1c
    800064da:	acab8b93          	addi	s7,s7,-1334 # 80021fa0 <disk>
  for(int i = 0; i < 3; i++){
    800064de:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800064e0:	0001cc97          	auipc	s9,0x1c
    800064e4:	be8c8c93          	addi	s9,s9,-1048 # 800220c8 <disk+0x128>
    800064e8:	a08d                	j	8000654a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800064ea:	00fb8733          	add	a4,s7,a5
    800064ee:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800064f2:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800064f4:	0207c563          	bltz	a5,8000651e <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800064f8:	2905                	addiw	s2,s2,1
    800064fa:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    800064fc:	05690c63          	beq	s2,s6,80006554 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006500:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006502:	0001c717          	auipc	a4,0x1c
    80006506:	a9e70713          	addi	a4,a4,-1378 # 80021fa0 <disk>
    8000650a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000650c:	01874683          	lbu	a3,24(a4)
    80006510:	fee9                	bnez	a3,800064ea <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006512:	2785                	addiw	a5,a5,1
    80006514:	0705                	addi	a4,a4,1
    80006516:	fe979be3          	bne	a5,s1,8000650c <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000651a:	57fd                	li	a5,-1
    8000651c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000651e:	01205d63          	blez	s2,80006538 <virtio_disk_rw+0xa6>
    80006522:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006524:	000a2503          	lw	a0,0(s4)
    80006528:	00000097          	auipc	ra,0x0
    8000652c:	cfe080e7          	jalr	-770(ra) # 80006226 <free_desc>
      for(int j = 0; j < i; j++)
    80006530:	2d85                	addiw	s11,s11,1
    80006532:	0a11                	addi	s4,s4,4
    80006534:	ff2d98e3          	bne	s11,s2,80006524 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006538:	85e6                	mv	a1,s9
    8000653a:	0001c517          	auipc	a0,0x1c
    8000653e:	a7e50513          	addi	a0,a0,-1410 # 80021fb8 <disk+0x18>
    80006542:	ffffc097          	auipc	ra,0xffffc
    80006546:	ed8080e7          	jalr	-296(ra) # 8000241a <sleep>
  for(int i = 0; i < 3; i++){
    8000654a:	f8040a13          	addi	s4,s0,-128
{
    8000654e:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006550:	894e                	mv	s2,s3
    80006552:	b77d                	j	80006500 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006554:	f8042503          	lw	a0,-128(s0)
    80006558:	00a50713          	addi	a4,a0,10
    8000655c:	0712                	slli	a4,a4,0x4

  if(write)
    8000655e:	0001c797          	auipc	a5,0x1c
    80006562:	a4278793          	addi	a5,a5,-1470 # 80021fa0 <disk>
    80006566:	00e786b3          	add	a3,a5,a4
    8000656a:	01803633          	snez	a2,s8
    8000656e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006570:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006574:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006578:	f6070613          	addi	a2,a4,-160
    8000657c:	6394                	ld	a3,0(a5)
    8000657e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006580:	00870593          	addi	a1,a4,8
    80006584:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006586:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006588:	0007b803          	ld	a6,0(a5)
    8000658c:	9642                	add	a2,a2,a6
    8000658e:	46c1                	li	a3,16
    80006590:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006592:	4585                	li	a1,1
    80006594:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006598:	f8442683          	lw	a3,-124(s0)
    8000659c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800065a0:	0692                	slli	a3,a3,0x4
    800065a2:	9836                	add	a6,a6,a3
    800065a4:	058a8613          	addi	a2,s5,88
    800065a8:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    800065ac:	0007b803          	ld	a6,0(a5)
    800065b0:	96c2                	add	a3,a3,a6
    800065b2:	40000613          	li	a2,1024
    800065b6:	c690                	sw	a2,8(a3)
  if(write)
    800065b8:	001c3613          	seqz	a2,s8
    800065bc:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800065c0:	00166613          	ori	a2,a2,1
    800065c4:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800065c8:	f8842603          	lw	a2,-120(s0)
    800065cc:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800065d0:	00250693          	addi	a3,a0,2
    800065d4:	0692                	slli	a3,a3,0x4
    800065d6:	96be                	add	a3,a3,a5
    800065d8:	58fd                	li	a7,-1
    800065da:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800065de:	0612                	slli	a2,a2,0x4
    800065e0:	9832                	add	a6,a6,a2
    800065e2:	f9070713          	addi	a4,a4,-112
    800065e6:	973e                	add	a4,a4,a5
    800065e8:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    800065ec:	6398                	ld	a4,0(a5)
    800065ee:	9732                	add	a4,a4,a2
    800065f0:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800065f2:	4609                	li	a2,2
    800065f4:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    800065f8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800065fc:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006600:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006604:	6794                	ld	a3,8(a5)
    80006606:	0026d703          	lhu	a4,2(a3)
    8000660a:	8b1d                	andi	a4,a4,7
    8000660c:	0706                	slli	a4,a4,0x1
    8000660e:	96ba                	add	a3,a3,a4
    80006610:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006614:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006618:	6798                	ld	a4,8(a5)
    8000661a:	00275783          	lhu	a5,2(a4)
    8000661e:	2785                	addiw	a5,a5,1
    80006620:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006624:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006628:	100017b7          	lui	a5,0x10001
    8000662c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006630:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    80006634:	0001c917          	auipc	s2,0x1c
    80006638:	a9490913          	addi	s2,s2,-1388 # 800220c8 <disk+0x128>
  while(b->disk == 1) {
    8000663c:	4485                	li	s1,1
    8000663e:	00b79c63          	bne	a5,a1,80006656 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006642:	85ca                	mv	a1,s2
    80006644:	8556                	mv	a0,s5
    80006646:	ffffc097          	auipc	ra,0xffffc
    8000664a:	dd4080e7          	jalr	-556(ra) # 8000241a <sleep>
  while(b->disk == 1) {
    8000664e:	004aa783          	lw	a5,4(s5)
    80006652:	fe9788e3          	beq	a5,s1,80006642 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006656:	f8042903          	lw	s2,-128(s0)
    8000665a:	00290713          	addi	a4,s2,2
    8000665e:	0712                	slli	a4,a4,0x4
    80006660:	0001c797          	auipc	a5,0x1c
    80006664:	94078793          	addi	a5,a5,-1728 # 80021fa0 <disk>
    80006668:	97ba                	add	a5,a5,a4
    8000666a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000666e:	0001c997          	auipc	s3,0x1c
    80006672:	93298993          	addi	s3,s3,-1742 # 80021fa0 <disk>
    80006676:	00491713          	slli	a4,s2,0x4
    8000667a:	0009b783          	ld	a5,0(s3)
    8000667e:	97ba                	add	a5,a5,a4
    80006680:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006684:	854a                	mv	a0,s2
    80006686:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000668a:	00000097          	auipc	ra,0x0
    8000668e:	b9c080e7          	jalr	-1124(ra) # 80006226 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006692:	8885                	andi	s1,s1,1
    80006694:	f0ed                	bnez	s1,80006676 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006696:	0001c517          	auipc	a0,0x1c
    8000669a:	a3250513          	addi	a0,a0,-1486 # 800220c8 <disk+0x128>
    8000669e:	ffffa097          	auipc	ra,0xffffa
    800066a2:	5ec080e7          	jalr	1516(ra) # 80000c8a <release>
}
    800066a6:	70e6                	ld	ra,120(sp)
    800066a8:	7446                	ld	s0,112(sp)
    800066aa:	74a6                	ld	s1,104(sp)
    800066ac:	7906                	ld	s2,96(sp)
    800066ae:	69e6                	ld	s3,88(sp)
    800066b0:	6a46                	ld	s4,80(sp)
    800066b2:	6aa6                	ld	s5,72(sp)
    800066b4:	6b06                	ld	s6,64(sp)
    800066b6:	7be2                	ld	s7,56(sp)
    800066b8:	7c42                	ld	s8,48(sp)
    800066ba:	7ca2                	ld	s9,40(sp)
    800066bc:	7d02                	ld	s10,32(sp)
    800066be:	6de2                	ld	s11,24(sp)
    800066c0:	6109                	addi	sp,sp,128
    800066c2:	8082                	ret

00000000800066c4 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800066c4:	1101                	addi	sp,sp,-32
    800066c6:	ec06                	sd	ra,24(sp)
    800066c8:	e822                	sd	s0,16(sp)
    800066ca:	e426                	sd	s1,8(sp)
    800066cc:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800066ce:	0001c497          	auipc	s1,0x1c
    800066d2:	8d248493          	addi	s1,s1,-1838 # 80021fa0 <disk>
    800066d6:	0001c517          	auipc	a0,0x1c
    800066da:	9f250513          	addi	a0,a0,-1550 # 800220c8 <disk+0x128>
    800066de:	ffffa097          	auipc	ra,0xffffa
    800066e2:	4f8080e7          	jalr	1272(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800066e6:	10001737          	lui	a4,0x10001
    800066ea:	533c                	lw	a5,96(a4)
    800066ec:	8b8d                	andi	a5,a5,3
    800066ee:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800066f0:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800066f4:	689c                	ld	a5,16(s1)
    800066f6:	0204d703          	lhu	a4,32(s1)
    800066fa:	0027d783          	lhu	a5,2(a5)
    800066fe:	04f70863          	beq	a4,a5,8000674e <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006702:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006706:	6898                	ld	a4,16(s1)
    80006708:	0204d783          	lhu	a5,32(s1)
    8000670c:	8b9d                	andi	a5,a5,7
    8000670e:	078e                	slli	a5,a5,0x3
    80006710:	97ba                	add	a5,a5,a4
    80006712:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006714:	00278713          	addi	a4,a5,2
    80006718:	0712                	slli	a4,a4,0x4
    8000671a:	9726                	add	a4,a4,s1
    8000671c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006720:	e721                	bnez	a4,80006768 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006722:	0789                	addi	a5,a5,2
    80006724:	0792                	slli	a5,a5,0x4
    80006726:	97a6                	add	a5,a5,s1
    80006728:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000672a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000672e:	ffffc097          	auipc	ra,0xffffc
    80006732:	d50080e7          	jalr	-688(ra) # 8000247e <wakeup>

    disk.used_idx += 1;
    80006736:	0204d783          	lhu	a5,32(s1)
    8000673a:	2785                	addiw	a5,a5,1
    8000673c:	17c2                	slli	a5,a5,0x30
    8000673e:	93c1                	srli	a5,a5,0x30
    80006740:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006744:	6898                	ld	a4,16(s1)
    80006746:	00275703          	lhu	a4,2(a4)
    8000674a:	faf71ce3          	bne	a4,a5,80006702 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000674e:	0001c517          	auipc	a0,0x1c
    80006752:	97a50513          	addi	a0,a0,-1670 # 800220c8 <disk+0x128>
    80006756:	ffffa097          	auipc	ra,0xffffa
    8000675a:	534080e7          	jalr	1332(ra) # 80000c8a <release>
}
    8000675e:	60e2                	ld	ra,24(sp)
    80006760:	6442                	ld	s0,16(sp)
    80006762:	64a2                	ld	s1,8(sp)
    80006764:	6105                	addi	sp,sp,32
    80006766:	8082                	ret
      panic("virtio_disk_intr status");
    80006768:	00002517          	auipc	a0,0x2
    8000676c:	1b050513          	addi	a0,a0,432 # 80008918 <syscalls+0x3f8>
    80006770:	ffffa097          	auipc	ra,0xffffa
    80006774:	dd0080e7          	jalr	-560(ra) # 80000540 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
