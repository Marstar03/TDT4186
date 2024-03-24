
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a6013103          	ld	sp,-1440(sp) # 80008a60 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000054:	a8070713          	addi	a4,a4,-1408 # 80008ad0 <timer_scratch>
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
    80000066:	1fe78793          	addi	a5,a5,510 # 80006260 <timervec>
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
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7fb9c8bf>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	efe78793          	addi	a5,a5,-258 # 80000faa <main>
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
    8000012e:	6ec080e7          	jalr	1772(ra) # 80002816 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
            break;
        uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	796080e7          	jalr	1942(ra) # 800008d0 <uartputc>
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
    8000018e:	a8650513          	addi	a0,a0,-1402 # 80010c10 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	b76080e7          	jalr	-1162(ra) # 80000d08 <acquire>
    while (n > 0)
    {
        // wait until interrupt handler has put some
        // input into cons.buffer.
        while (cons.r == cons.w)
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	a7648493          	addi	s1,s1,-1418 # 80010c10 <cons>
            if (killed(myproc()))
            {
                release(&cons.lock);
                return -1;
            }
            sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	b0690913          	addi	s2,s2,-1274 # 80010ca8 <cons+0x98>
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
    800001c4:	a38080e7          	jalr	-1480(ra) # 80001bf8 <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	498080e7          	jalr	1176(ra) # 80002660 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
            sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	1e2080e7          	jalr	482(ra) # 800023b8 <sleep>
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
    80000216:	5ae080e7          	jalr	1454(ra) # 800027c0 <either_copyout>
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
    8000022a:	9ea50513          	addi	a0,a0,-1558 # 80010c10 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	b8e080e7          	jalr	-1138(ra) # 80000dbc <release>

    return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
                release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	9d450513          	addi	a0,a0,-1580 # 80010c10 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	b78080e7          	jalr	-1160(ra) # 80000dbc <release>
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
    80000276:	a2f72b23          	sw	a5,-1482(a4) # 80010ca8 <cons+0x98>
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
    80000290:	572080e7          	jalr	1394(ra) # 800007fe <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
        uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	560080e7          	jalr	1376(ra) # 800007fe <uartputc_sync>
        uartputc_sync(' ');
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	554080e7          	jalr	1364(ra) # 800007fe <uartputc_sync>
        uartputc_sync('\b');
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	54a080e7          	jalr	1354(ra) # 800007fe <uartputc_sync>
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
    800002d0:	94450513          	addi	a0,a0,-1724 # 80010c10 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	a34080e7          	jalr	-1484(ra) # 80000d08 <acquire>

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
    800002f6:	57a080e7          	jalr	1402(ra) # 8000286c <procdump>
            }
        }
        break;
    }

    release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	91650513          	addi	a0,a0,-1770 # 80010c10 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	aba080e7          	jalr	-1350(ra) # 80000dbc <release>
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
    80000322:	8f270713          	addi	a4,a4,-1806 # 80010c10 <cons>
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
    8000034c:	8c878793          	addi	a5,a5,-1848 # 80010c10 <cons>
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
    8000037a:	9327a783          	lw	a5,-1742(a5) # 80010ca8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
        while (cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	88670713          	addi	a4,a4,-1914 # 80010c10 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
               cons.buf[(cons.e - 1) % INPUT_BUF_SIZE] != '\n')
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	87648493          	addi	s1,s1,-1930 # 80010c10 <cons>
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
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	83a70713          	addi	a4,a4,-1990 # 80010c10 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
            cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	8cf72223          	sw	a5,-1852(a4) # 80010cb0 <cons+0xa0>
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
    80000416:	7fe78793          	addi	a5,a5,2046 # 80010c10 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
                cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	86c7ab23          	sw	a2,-1930(a5) # 80010cac <cons+0x9c>
                wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	86a50513          	addi	a0,a0,-1942 # 80010ca8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	fd6080e7          	jalr	-42(ra) # 8000241c <wakeup>
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
    8000045c:	bc858593          	addi	a1,a1,-1080 # 80008020 <__func__.1+0x18>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	7b050513          	addi	a0,a0,1968 # 80010c10 <cons>
    80000468:	00001097          	auipc	ra,0x1
    8000046c:	810080e7          	jalr	-2032(ra) # 80000c78 <initlock>

    uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	33e080e7          	jalr	830(ra) # 800007ae <uartinit>

    // connect read and write system calls
    // to consoleread and consolewrite.
    devsw[CONSOLE].read = consoleread;
    80000478:	00461797          	auipc	a5,0x461
    8000047c:	93078793          	addi	a5,a5,-1744 # 80460da8 <devsw>
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

    if (sign && (sign = xx < 0))
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
    do
    {
        buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b9660613          	addi	a2,a2,-1130 # 80008050 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
    } while ((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

    if (sign)
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
        buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

    while (--i >= 0)
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
    while (--i >= 0)
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
    if (sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
        x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
    if (locking)
        release(&pr.lock);
}

void panic(char *s, ...)
{
    80000540:	711d                	addi	sp,sp,-96
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
    8000054c:	e40c                	sd	a1,8(s0)
    8000054e:	e810                	sd	a2,16(s0)
    80000550:	ec14                	sd	a3,24(s0)
    80000552:	f018                	sd	a4,32(s0)
    80000554:	f41c                	sd	a5,40(s0)
    80000556:	03043823          	sd	a6,48(s0)
    8000055a:	03143c23          	sd	a7,56(s0)
    pr.locking = 0;
    8000055e:	00010797          	auipc	a5,0x10
    80000562:	7607a923          	sw	zero,1906(a5) # 80010cd0 <pr+0x18>
    printf("panic: ");
    80000566:	00008517          	auipc	a0,0x8
    8000056a:	ac250513          	addi	a0,a0,-1342 # 80008028 <__func__.1+0x20>
    8000056e:	00000097          	auipc	ra,0x0
    80000572:	02e080e7          	jalr	46(ra) # 8000059c <printf>
    printf(s);
    80000576:	8526                	mv	a0,s1
    80000578:	00000097          	auipc	ra,0x0
    8000057c:	024080e7          	jalr	36(ra) # 8000059c <printf>
    printf("\n");
    80000580:	00008517          	auipc	a0,0x8
    80000584:	f1050513          	addi	a0,a0,-240 # 80008490 <states.0+0xa8>
    80000588:	00000097          	auipc	ra,0x0
    8000058c:	014080e7          	jalr	20(ra) # 8000059c <printf>
    panicked = 1; // freeze uart output from other CPUs
    80000590:	4785                	li	a5,1
    80000592:	00008717          	auipc	a4,0x8
    80000596:	4ef72723          	sw	a5,1262(a4) # 80008a80 <panicked>
    for (;;)
    8000059a:	a001                	j	8000059a <panic+0x5a>

000000008000059c <printf>:
{
    8000059c:	7131                	addi	sp,sp,-192
    8000059e:	fc86                	sd	ra,120(sp)
    800005a0:	f8a2                	sd	s0,112(sp)
    800005a2:	f4a6                	sd	s1,104(sp)
    800005a4:	f0ca                	sd	s2,96(sp)
    800005a6:	ecce                	sd	s3,88(sp)
    800005a8:	e8d2                	sd	s4,80(sp)
    800005aa:	e4d6                	sd	s5,72(sp)
    800005ac:	e0da                	sd	s6,64(sp)
    800005ae:	fc5e                	sd	s7,56(sp)
    800005b0:	f862                	sd	s8,48(sp)
    800005b2:	f466                	sd	s9,40(sp)
    800005b4:	f06a                	sd	s10,32(sp)
    800005b6:	ec6e                	sd	s11,24(sp)
    800005b8:	0100                	addi	s0,sp,128
    800005ba:	8a2a                	mv	s4,a0
    800005bc:	e40c                	sd	a1,8(s0)
    800005be:	e810                	sd	a2,16(s0)
    800005c0:	ec14                	sd	a3,24(s0)
    800005c2:	f018                	sd	a4,32(s0)
    800005c4:	f41c                	sd	a5,40(s0)
    800005c6:	03043823          	sd	a6,48(s0)
    800005ca:	03143c23          	sd	a7,56(s0)
    locking = pr.locking;
    800005ce:	00010d97          	auipc	s11,0x10
    800005d2:	702dad83          	lw	s11,1794(s11) # 80010cd0 <pr+0x18>
    if (locking)
    800005d6:	020d9b63          	bnez	s11,8000060c <printf+0x70>
    if (fmt == 0)
    800005da:	040a0263          	beqz	s4,8000061e <printf+0x82>
    va_start(ap, fmt);
    800005de:	00840793          	addi	a5,s0,8
    800005e2:	f8f43423          	sd	a5,-120(s0)
    for (i = 0; (c = fmt[i] & 0xff) != 0; i++)
    800005e6:	000a4503          	lbu	a0,0(s4)
    800005ea:	14050f63          	beqz	a0,80000748 <printf+0x1ac>
    800005ee:	4981                	li	s3,0
        if (c != '%')
    800005f0:	02500a93          	li	s5,37
        switch (c)
    800005f4:	07000b93          	li	s7,112
    consputc('x');
    800005f8:	4d41                	li	s10,16
        consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005fa:	00008b17          	auipc	s6,0x8
    800005fe:	a56b0b13          	addi	s6,s6,-1450 # 80008050 <digits>
        switch (c)
    80000602:	07300c93          	li	s9,115
    80000606:	06400c13          	li	s8,100
    8000060a:	a82d                	j	80000644 <printf+0xa8>
        acquire(&pr.lock);
    8000060c:	00010517          	auipc	a0,0x10
    80000610:	6ac50513          	addi	a0,a0,1708 # 80010cb8 <pr>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	6f4080e7          	jalr	1780(ra) # 80000d08 <acquire>
    8000061c:	bf7d                	j	800005da <printf+0x3e>
        panic("null fmt");
    8000061e:	00008517          	auipc	a0,0x8
    80000622:	a1a50513          	addi	a0,a0,-1510 # 80008038 <__func__.1+0x30>
    80000626:	00000097          	auipc	ra,0x0
    8000062a:	f1a080e7          	jalr	-230(ra) # 80000540 <panic>
            consputc(c);
    8000062e:	00000097          	auipc	ra,0x0
    80000632:	c4e080e7          	jalr	-946(ra) # 8000027c <consputc>
    for (i = 0; (c = fmt[i] & 0xff) != 0; i++)
    80000636:	2985                	addiw	s3,s3,1
    80000638:	013a07b3          	add	a5,s4,s3
    8000063c:	0007c503          	lbu	a0,0(a5)
    80000640:	10050463          	beqz	a0,80000748 <printf+0x1ac>
        if (c != '%')
    80000644:	ff5515e3          	bne	a0,s5,8000062e <printf+0x92>
        c = fmt[++i] & 0xff;
    80000648:	2985                	addiw	s3,s3,1
    8000064a:	013a07b3          	add	a5,s4,s3
    8000064e:	0007c783          	lbu	a5,0(a5)
    80000652:	0007849b          	sext.w	s1,a5
        if (c == 0)
    80000656:	cbed                	beqz	a5,80000748 <printf+0x1ac>
        switch (c)
    80000658:	05778a63          	beq	a5,s7,800006ac <printf+0x110>
    8000065c:	02fbf663          	bgeu	s7,a5,80000688 <printf+0xec>
    80000660:	09978863          	beq	a5,s9,800006f0 <printf+0x154>
    80000664:	07800713          	li	a4,120
    80000668:	0ce79563          	bne	a5,a4,80000732 <printf+0x196>
            printint(va_arg(ap, int), 16, 1);
    8000066c:	f8843783          	ld	a5,-120(s0)
    80000670:	00878713          	addi	a4,a5,8
    80000674:	f8e43423          	sd	a4,-120(s0)
    80000678:	4605                	li	a2,1
    8000067a:	85ea                	mv	a1,s10
    8000067c:	4388                	lw	a0,0(a5)
    8000067e:	00000097          	auipc	ra,0x0
    80000682:	e1e080e7          	jalr	-482(ra) # 8000049c <printint>
            break;
    80000686:	bf45                	j	80000636 <printf+0x9a>
        switch (c)
    80000688:	09578f63          	beq	a5,s5,80000726 <printf+0x18a>
    8000068c:	0b879363          	bne	a5,s8,80000732 <printf+0x196>
            printint(va_arg(ap, int), 10, 1);
    80000690:	f8843783          	ld	a5,-120(s0)
    80000694:	00878713          	addi	a4,a5,8
    80000698:	f8e43423          	sd	a4,-120(s0)
    8000069c:	4605                	li	a2,1
    8000069e:	45a9                	li	a1,10
    800006a0:	4388                	lw	a0,0(a5)
    800006a2:	00000097          	auipc	ra,0x0
    800006a6:	dfa080e7          	jalr	-518(ra) # 8000049c <printint>
            break;
    800006aa:	b771                	j	80000636 <printf+0x9a>
            printptr(va_arg(ap, uint64));
    800006ac:	f8843783          	ld	a5,-120(s0)
    800006b0:	00878713          	addi	a4,a5,8
    800006b4:	f8e43423          	sd	a4,-120(s0)
    800006b8:	0007b903          	ld	s2,0(a5)
    consputc('0');
    800006bc:	03000513          	li	a0,48
    800006c0:	00000097          	auipc	ra,0x0
    800006c4:	bbc080e7          	jalr	-1092(ra) # 8000027c <consputc>
    consputc('x');
    800006c8:	07800513          	li	a0,120
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
    800006d4:	84ea                	mv	s1,s10
        consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006d6:	03c95793          	srli	a5,s2,0x3c
    800006da:	97da                	add	a5,a5,s6
    800006dc:	0007c503          	lbu	a0,0(a5)
    800006e0:	00000097          	auipc	ra,0x0
    800006e4:	b9c080e7          	jalr	-1124(ra) # 8000027c <consputc>
    for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006e8:	0912                	slli	s2,s2,0x4
    800006ea:	34fd                	addiw	s1,s1,-1
    800006ec:	f4ed                	bnez	s1,800006d6 <printf+0x13a>
    800006ee:	b7a1                	j	80000636 <printf+0x9a>
            if ((s = va_arg(ap, char *)) == 0)
    800006f0:	f8843783          	ld	a5,-120(s0)
    800006f4:	00878713          	addi	a4,a5,8
    800006f8:	f8e43423          	sd	a4,-120(s0)
    800006fc:	6384                	ld	s1,0(a5)
    800006fe:	cc89                	beqz	s1,80000718 <printf+0x17c>
            for (; *s; s++)
    80000700:	0004c503          	lbu	a0,0(s1)
    80000704:	d90d                	beqz	a0,80000636 <printf+0x9a>
                consputc(*s);
    80000706:	00000097          	auipc	ra,0x0
    8000070a:	b76080e7          	jalr	-1162(ra) # 8000027c <consputc>
            for (; *s; s++)
    8000070e:	0485                	addi	s1,s1,1
    80000710:	0004c503          	lbu	a0,0(s1)
    80000714:	f96d                	bnez	a0,80000706 <printf+0x16a>
    80000716:	b705                	j	80000636 <printf+0x9a>
                s = "(null)";
    80000718:	00008497          	auipc	s1,0x8
    8000071c:	91848493          	addi	s1,s1,-1768 # 80008030 <__func__.1+0x28>
            for (; *s; s++)
    80000720:	02800513          	li	a0,40
    80000724:	b7cd                	j	80000706 <printf+0x16a>
            consputc('%');
    80000726:	8556                	mv	a0,s5
    80000728:	00000097          	auipc	ra,0x0
    8000072c:	b54080e7          	jalr	-1196(ra) # 8000027c <consputc>
            break;
    80000730:	b719                	j	80000636 <printf+0x9a>
            consputc('%');
    80000732:	8556                	mv	a0,s5
    80000734:	00000097          	auipc	ra,0x0
    80000738:	b48080e7          	jalr	-1208(ra) # 8000027c <consputc>
            consputc(c);
    8000073c:	8526                	mv	a0,s1
    8000073e:	00000097          	auipc	ra,0x0
    80000742:	b3e080e7          	jalr	-1218(ra) # 8000027c <consputc>
            break;
    80000746:	bdc5                	j	80000636 <printf+0x9a>
    if (locking)
    80000748:	020d9163          	bnez	s11,8000076a <printf+0x1ce>
}
    8000074c:	70e6                	ld	ra,120(sp)
    8000074e:	7446                	ld	s0,112(sp)
    80000750:	74a6                	ld	s1,104(sp)
    80000752:	7906                	ld	s2,96(sp)
    80000754:	69e6                	ld	s3,88(sp)
    80000756:	6a46                	ld	s4,80(sp)
    80000758:	6aa6                	ld	s5,72(sp)
    8000075a:	6b06                	ld	s6,64(sp)
    8000075c:	7be2                	ld	s7,56(sp)
    8000075e:	7c42                	ld	s8,48(sp)
    80000760:	7ca2                	ld	s9,40(sp)
    80000762:	7d02                	ld	s10,32(sp)
    80000764:	6de2                	ld	s11,24(sp)
    80000766:	6129                	addi	sp,sp,192
    80000768:	8082                	ret
        release(&pr.lock);
    8000076a:	00010517          	auipc	a0,0x10
    8000076e:	54e50513          	addi	a0,a0,1358 # 80010cb8 <pr>
    80000772:	00000097          	auipc	ra,0x0
    80000776:	64a080e7          	jalr	1610(ra) # 80000dbc <release>
}
    8000077a:	bfc9                	j	8000074c <printf+0x1b0>

000000008000077c <printfinit>:
        ;
}

void printfinit(void)
{
    8000077c:	1101                	addi	sp,sp,-32
    8000077e:	ec06                	sd	ra,24(sp)
    80000780:	e822                	sd	s0,16(sp)
    80000782:	e426                	sd	s1,8(sp)
    80000784:	1000                	addi	s0,sp,32
    initlock(&pr.lock, "pr");
    80000786:	00010497          	auipc	s1,0x10
    8000078a:	53248493          	addi	s1,s1,1330 # 80010cb8 <pr>
    8000078e:	00008597          	auipc	a1,0x8
    80000792:	8ba58593          	addi	a1,a1,-1862 # 80008048 <__func__.1+0x40>
    80000796:	8526                	mv	a0,s1
    80000798:	00000097          	auipc	ra,0x0
    8000079c:	4e0080e7          	jalr	1248(ra) # 80000c78 <initlock>
    pr.locking = 1;
    800007a0:	4785                	li	a5,1
    800007a2:	cc9c                	sw	a5,24(s1)
}
    800007a4:	60e2                	ld	ra,24(sp)
    800007a6:	6442                	ld	s0,16(sp)
    800007a8:	64a2                	ld	s1,8(sp)
    800007aa:	6105                	addi	sp,sp,32
    800007ac:	8082                	ret

00000000800007ae <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007ae:	1141                	addi	sp,sp,-16
    800007b0:	e406                	sd	ra,8(sp)
    800007b2:	e022                	sd	s0,0(sp)
    800007b4:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007b6:	100007b7          	lui	a5,0x10000
    800007ba:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007be:	f8000713          	li	a4,-128
    800007c2:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007c6:	470d                	li	a4,3
    800007c8:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007cc:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007d0:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007d4:	469d                	li	a3,7
    800007d6:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007da:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007de:	00008597          	auipc	a1,0x8
    800007e2:	88a58593          	addi	a1,a1,-1910 # 80008068 <digits+0x18>
    800007e6:	00010517          	auipc	a0,0x10
    800007ea:	4f250513          	addi	a0,a0,1266 # 80010cd8 <uart_tx_lock>
    800007ee:	00000097          	auipc	ra,0x0
    800007f2:	48a080e7          	jalr	1162(ra) # 80000c78 <initlock>
}
    800007f6:	60a2                	ld	ra,8(sp)
    800007f8:	6402                	ld	s0,0(sp)
    800007fa:	0141                	addi	sp,sp,16
    800007fc:	8082                	ret

00000000800007fe <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007fe:	1101                	addi	sp,sp,-32
    80000800:	ec06                	sd	ra,24(sp)
    80000802:	e822                	sd	s0,16(sp)
    80000804:	e426                	sd	s1,8(sp)
    80000806:	1000                	addi	s0,sp,32
    80000808:	84aa                	mv	s1,a0
  push_off();
    8000080a:	00000097          	auipc	ra,0x0
    8000080e:	4b2080e7          	jalr	1202(ra) # 80000cbc <push_off>

  if(panicked){
    80000812:	00008797          	auipc	a5,0x8
    80000816:	26e7a783          	lw	a5,622(a5) # 80008a80 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081a:	10000737          	lui	a4,0x10000
  if(panicked){
    8000081e:	c391                	beqz	a5,80000822 <uartputc_sync+0x24>
    for(;;)
    80000820:	a001                	j	80000820 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000822:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000826:	0207f793          	andi	a5,a5,32
    8000082a:	dfe5                	beqz	a5,80000822 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000082c:	0ff4f513          	zext.b	a0,s1
    80000830:	100007b7          	lui	a5,0x10000
    80000834:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000838:	00000097          	auipc	ra,0x0
    8000083c:	524080e7          	jalr	1316(ra) # 80000d5c <pop_off>
}
    80000840:	60e2                	ld	ra,24(sp)
    80000842:	6442                	ld	s0,16(sp)
    80000844:	64a2                	ld	s1,8(sp)
    80000846:	6105                	addi	sp,sp,32
    80000848:	8082                	ret

000000008000084a <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    8000084a:	00008797          	auipc	a5,0x8
    8000084e:	23e7b783          	ld	a5,574(a5) # 80008a88 <uart_tx_r>
    80000852:	00008717          	auipc	a4,0x8
    80000856:	23e73703          	ld	a4,574(a4) # 80008a90 <uart_tx_w>
    8000085a:	06f70a63          	beq	a4,a5,800008ce <uartstart+0x84>
{
    8000085e:	7139                	addi	sp,sp,-64
    80000860:	fc06                	sd	ra,56(sp)
    80000862:	f822                	sd	s0,48(sp)
    80000864:	f426                	sd	s1,40(sp)
    80000866:	f04a                	sd	s2,32(sp)
    80000868:	ec4e                	sd	s3,24(sp)
    8000086a:	e852                	sd	s4,16(sp)
    8000086c:	e456                	sd	s5,8(sp)
    8000086e:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000870:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000874:	00010a17          	auipc	s4,0x10
    80000878:	464a0a13          	addi	s4,s4,1124 # 80010cd8 <uart_tx_lock>
    uart_tx_r += 1;
    8000087c:	00008497          	auipc	s1,0x8
    80000880:	20c48493          	addi	s1,s1,524 # 80008a88 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000884:	00008997          	auipc	s3,0x8
    80000888:	20c98993          	addi	s3,s3,524 # 80008a90 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000088c:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000890:	02077713          	andi	a4,a4,32
    80000894:	c705                	beqz	a4,800008bc <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000896:	01f7f713          	andi	a4,a5,31
    8000089a:	9752                	add	a4,a4,s4
    8000089c:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    800008a0:	0785                	addi	a5,a5,1
    800008a2:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008a4:	8526                	mv	a0,s1
    800008a6:	00002097          	auipc	ra,0x2
    800008aa:	b76080e7          	jalr	-1162(ra) # 8000241c <wakeup>
    
    WriteReg(THR, c);
    800008ae:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008b2:	609c                	ld	a5,0(s1)
    800008b4:	0009b703          	ld	a4,0(s3)
    800008b8:	fcf71ae3          	bne	a4,a5,8000088c <uartstart+0x42>
  }
}
    800008bc:	70e2                	ld	ra,56(sp)
    800008be:	7442                	ld	s0,48(sp)
    800008c0:	74a2                	ld	s1,40(sp)
    800008c2:	7902                	ld	s2,32(sp)
    800008c4:	69e2                	ld	s3,24(sp)
    800008c6:	6a42                	ld	s4,16(sp)
    800008c8:	6aa2                	ld	s5,8(sp)
    800008ca:	6121                	addi	sp,sp,64
    800008cc:	8082                	ret
    800008ce:	8082                	ret

00000000800008d0 <uartputc>:
{
    800008d0:	7179                	addi	sp,sp,-48
    800008d2:	f406                	sd	ra,40(sp)
    800008d4:	f022                	sd	s0,32(sp)
    800008d6:	ec26                	sd	s1,24(sp)
    800008d8:	e84a                	sd	s2,16(sp)
    800008da:	e44e                	sd	s3,8(sp)
    800008dc:	e052                	sd	s4,0(sp)
    800008de:	1800                	addi	s0,sp,48
    800008e0:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008e2:	00010517          	auipc	a0,0x10
    800008e6:	3f650513          	addi	a0,a0,1014 # 80010cd8 <uart_tx_lock>
    800008ea:	00000097          	auipc	ra,0x0
    800008ee:	41e080e7          	jalr	1054(ra) # 80000d08 <acquire>
  if(panicked){
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	18e7a783          	lw	a5,398(a5) # 80008a80 <panicked>
    800008fa:	e7c9                	bnez	a5,80000984 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fc:	00008717          	auipc	a4,0x8
    80000900:	19473703          	ld	a4,404(a4) # 80008a90 <uart_tx_w>
    80000904:	00008797          	auipc	a5,0x8
    80000908:	1847b783          	ld	a5,388(a5) # 80008a88 <uart_tx_r>
    8000090c:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00010997          	auipc	s3,0x10
    80000914:	3c898993          	addi	s3,s3,968 # 80010cd8 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	17048493          	addi	s1,s1,368 # 80008a88 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	17090913          	addi	s2,s2,368 # 80008a90 <uart_tx_w>
    80000928:	00e79f63          	bne	a5,a4,80000946 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000092c:	85ce                	mv	a1,s3
    8000092e:	8526                	mv	a0,s1
    80000930:	00002097          	auipc	ra,0x2
    80000934:	a88080e7          	jalr	-1400(ra) # 800023b8 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000938:	00093703          	ld	a4,0(s2)
    8000093c:	609c                	ld	a5,0(s1)
    8000093e:	02078793          	addi	a5,a5,32
    80000942:	fee785e3          	beq	a5,a4,8000092c <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000946:	00010497          	auipc	s1,0x10
    8000094a:	39248493          	addi	s1,s1,914 # 80010cd8 <uart_tx_lock>
    8000094e:	01f77793          	andi	a5,a4,31
    80000952:	97a6                	add	a5,a5,s1
    80000954:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000958:	0705                	addi	a4,a4,1
    8000095a:	00008797          	auipc	a5,0x8
    8000095e:	12e7bb23          	sd	a4,310(a5) # 80008a90 <uart_tx_w>
  uartstart();
    80000962:	00000097          	auipc	ra,0x0
    80000966:	ee8080e7          	jalr	-280(ra) # 8000084a <uartstart>
  release(&uart_tx_lock);
    8000096a:	8526                	mv	a0,s1
    8000096c:	00000097          	auipc	ra,0x0
    80000970:	450080e7          	jalr	1104(ra) # 80000dbc <release>
}
    80000974:	70a2                	ld	ra,40(sp)
    80000976:	7402                	ld	s0,32(sp)
    80000978:	64e2                	ld	s1,24(sp)
    8000097a:	6942                	ld	s2,16(sp)
    8000097c:	69a2                	ld	s3,8(sp)
    8000097e:	6a02                	ld	s4,0(sp)
    80000980:	6145                	addi	sp,sp,48
    80000982:	8082                	ret
    for(;;)
    80000984:	a001                	j	80000984 <uartputc+0xb4>

0000000080000986 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000986:	1141                	addi	sp,sp,-16
    80000988:	e422                	sd	s0,8(sp)
    8000098a:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000098c:	100007b7          	lui	a5,0x10000
    80000990:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000994:	8b85                	andi	a5,a5,1
    80000996:	cb81                	beqz	a5,800009a6 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000998:	100007b7          	lui	a5,0x10000
    8000099c:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    800009a0:	6422                	ld	s0,8(sp)
    800009a2:	0141                	addi	sp,sp,16
    800009a4:	8082                	ret
    return -1;
    800009a6:	557d                	li	a0,-1
    800009a8:	bfe5                	j	800009a0 <uartgetc+0x1a>

00000000800009aa <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009aa:	1101                	addi	sp,sp,-32
    800009ac:	ec06                	sd	ra,24(sp)
    800009ae:	e822                	sd	s0,16(sp)
    800009b0:	e426                	sd	s1,8(sp)
    800009b2:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b4:	54fd                	li	s1,-1
    800009b6:	a029                	j	800009c0 <uartintr+0x16>
      break;
    consoleintr(c);
    800009b8:	00000097          	auipc	ra,0x0
    800009bc:	906080e7          	jalr	-1786(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	fc6080e7          	jalr	-58(ra) # 80000986 <uartgetc>
    if(c == -1)
    800009c8:	fe9518e3          	bne	a0,s1,800009b8 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009cc:	00010497          	auipc	s1,0x10
    800009d0:	30c48493          	addi	s1,s1,780 # 80010cd8 <uart_tx_lock>
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	332080e7          	jalr	818(ra) # 80000d08 <acquire>
  uartstart();
    800009de:	00000097          	auipc	ra,0x0
    800009e2:	e6c080e7          	jalr	-404(ra) # 8000084a <uartstart>
  release(&uart_tx_lock);
    800009e6:	8526                	mv	a0,s1
    800009e8:	00000097          	auipc	ra,0x0
    800009ec:	3d4080e7          	jalr	980(ra) # 80000dbc <release>
}
    800009f0:	60e2                	ld	ra,24(sp)
    800009f2:	6442                	ld	s0,16(sp)
    800009f4:	64a2                	ld	s1,8(sp)
    800009f6:	6105                	addi	sp,sp,32
    800009f8:	8082                	ret

00000000800009fa <increment_page_count>:

//struct page_struct page_array[PAGE_ARRAY_LENGTH]; // Endre 100 til antall pages vi må holde styr på om gangen

uint64 new_array[PAGE_ARRAY_LENGTH] = {0};

void increment_page_count(uint64 physical_address) {
    800009fa:	1141                	addi	sp,sp,-16
    800009fc:	e422                	sd	s0,8(sp)
    800009fe:	0800                	addi	s0,sp,16
    new_array[physical_address / PGSIZE] ++;
    80000a00:	8131                	srli	a0,a0,0xc
    80000a02:	050e                	slli	a0,a0,0x3
    80000a04:	00010797          	auipc	a5,0x10
    80000a08:	32c78793          	addi	a5,a5,812 # 80010d30 <new_array>
    80000a0c:	97aa                	add	a5,a5,a0
    80000a0e:	6398                	ld	a4,0(a5)
    80000a10:	0705                	addi	a4,a4,1
    80000a12:	e398                	sd	a4,0(a5)
    //printf("%d\n", FREE_PAGES);
}
    80000a14:	6422                	ld	s0,8(sp)
    80000a16:	0141                	addi	sp,sp,16
    80000a18:	8082                	ret

0000000080000a1a <decrement_page_count>:

void decrement_page_count(uint64 physical_address) {
    80000a1a:	1141                	addi	sp,sp,-16
    80000a1c:	e422                	sd	s0,8(sp)
    80000a1e:	0800                	addi	s0,sp,16
    new_array[physical_address / PGSIZE] ++;
    80000a20:	8131                	srli	a0,a0,0xc
    80000a22:	050e                	slli	a0,a0,0x3
    80000a24:	00010797          	auipc	a5,0x10
    80000a28:	30c78793          	addi	a5,a5,780 # 80010d30 <new_array>
    80000a2c:	97aa                	add	a5,a5,a0
    80000a2e:	6398                	ld	a4,0(a5)
    80000a30:	0705                	addi	a4,a4,1
    80000a32:	e398                	sd	a4,0(a5)
}
    80000a34:	6422                	ld	s0,8(sp)
    80000a36:	0141                	addi	sp,sp,16
    80000a38:	8082                	ret

0000000080000a3a <kfree>:

    // ---------------------
    /* if (new_array[(uint64)pa / PGSIZE] <= 0) {
        return;
    } */
    if (new_array[(uint64)pa / PGSIZE] > 0) {
    80000a3a:	00c55713          	srli	a4,a0,0xc
    80000a3e:	00371693          	slli	a3,a4,0x3
    80000a42:	00010797          	auipc	a5,0x10
    80000a46:	2ee78793          	addi	a5,a5,750 # 80010d30 <new_array>
    80000a4a:	97b6                	add	a5,a5,a3
    80000a4c:	639c                	ld	a5,0(a5)
    80000a4e:	ebc1                	bnez	a5,80000ade <kfree+0xa4>
{
    80000a50:	1101                	addi	sp,sp,-32
    80000a52:	ec06                	sd	ra,24(sp)
    80000a54:	e822                	sd	s0,16(sp)
    80000a56:	e426                	sd	s1,8(sp)
    80000a58:	e04a                	sd	s2,0(sp)
    80000a5a:	1000                	addi	s0,sp,32
    80000a5c:	84aa                	mv	s1,a0
    80000a5e:	862a                	mv	a2,a0
        new_array[(uint64)pa / PGSIZE] --;
        return;
    }
    // ---------------------

    if (MAX_PAGES != 0) // On kinit MAX_PAGES is not yet set
    80000a60:	00008797          	auipc	a5,0x8
    80000a64:	0407b783          	ld	a5,64(a5) # 80008aa0 <MAX_PAGES>
    80000a68:	c799                	beqz	a5,80000a76 <kfree+0x3c>
        assert(FREE_PAGES < MAX_PAGES);
    80000a6a:	00008717          	auipc	a4,0x8
    80000a6e:	02e73703          	ld	a4,46(a4) # 80008a98 <FREE_PAGES>
    80000a72:	06f77f63          	bgeu	a4,a5,80000af0 <kfree+0xb6>
    struct run *r;

    if (((uint64)pa % PGSIZE) != 0 || (char *)pa < end || (uint64)pa >= PHYSTOP)
    80000a76:	03449793          	slli	a5,s1,0x34
    80000a7a:	e7cd                	bnez	a5,80000b24 <kfree+0xea>
    80000a7c:	00461797          	auipc	a5,0x461
    80000a80:	4c478793          	addi	a5,a5,1220 # 80461f40 <end>
    80000a84:	0af4e063          	bltu	s1,a5,80000b24 <kfree+0xea>
    80000a88:	47c5                	li	a5,17
    80000a8a:	07ee                	slli	a5,a5,0x1b
    80000a8c:	08f67c63          	bgeu	a2,a5,80000b24 <kfree+0xea>
        panic("kfree");

    // Fill with junk to catch dangling refs.
    memset(pa, 1, PGSIZE);
    80000a90:	6605                	lui	a2,0x1
    80000a92:	4585                	li	a1,1
    80000a94:	8526                	mv	a0,s1
    80000a96:	00000097          	auipc	ra,0x0
    80000a9a:	36e080e7          	jalr	878(ra) # 80000e04 <memset>

    r = (struct run *)pa;

    acquire(&kmem.lock);
    80000a9e:	00010917          	auipc	s2,0x10
    80000aa2:	27290913          	addi	s2,s2,626 # 80010d10 <kmem>
    80000aa6:	854a                	mv	a0,s2
    80000aa8:	00000097          	auipc	ra,0x0
    80000aac:	260080e7          	jalr	608(ra) # 80000d08 <acquire>
    r->next = kmem.freelist;
    80000ab0:	01893783          	ld	a5,24(s2)
    80000ab4:	e09c                	sd	a5,0(s1)
    kmem.freelist = r;
    80000ab6:	00993c23          	sd	s1,24(s2)
    FREE_PAGES++;
    80000aba:	00008717          	auipc	a4,0x8
    80000abe:	fde70713          	addi	a4,a4,-34 # 80008a98 <FREE_PAGES>
    80000ac2:	631c                	ld	a5,0(a4)
    80000ac4:	0785                	addi	a5,a5,1
    80000ac6:	e31c                	sd	a5,0(a4)
    release(&kmem.lock);
    80000ac8:	854a                	mv	a0,s2
    80000aca:	00000097          	auipc	ra,0x0
    80000ace:	2f2080e7          	jalr	754(ra) # 80000dbc <release>
}
    80000ad2:	60e2                	ld	ra,24(sp)
    80000ad4:	6442                	ld	s0,16(sp)
    80000ad6:	64a2                	ld	s1,8(sp)
    80000ad8:	6902                	ld	s2,0(sp)
    80000ada:	6105                	addi	sp,sp,32
    80000adc:	8082                	ret
        new_array[(uint64)pa / PGSIZE] --;
    80000ade:	8736                	mv	a4,a3
    80000ae0:	00010697          	auipc	a3,0x10
    80000ae4:	25068693          	addi	a3,a3,592 # 80010d30 <new_array>
    80000ae8:	9736                	add	a4,a4,a3
    80000aea:	17fd                	addi	a5,a5,-1
    80000aec:	e31c                	sd	a5,0(a4)
        return;
    80000aee:	8082                	ret
        assert(FREE_PAGES < MAX_PAGES);
    80000af0:	09c00693          	li	a3,156
    80000af4:	00007617          	auipc	a2,0x7
    80000af8:	51460613          	addi	a2,a2,1300 # 80008008 <__func__.1>
    80000afc:	00007597          	auipc	a1,0x7
    80000b00:	57458593          	addi	a1,a1,1396 # 80008070 <digits+0x20>
    80000b04:	00007517          	auipc	a0,0x7
    80000b08:	57c50513          	addi	a0,a0,1404 # 80008080 <digits+0x30>
    80000b0c:	00000097          	auipc	ra,0x0
    80000b10:	a90080e7          	jalr	-1392(ra) # 8000059c <printf>
    80000b14:	00007517          	auipc	a0,0x7
    80000b18:	57c50513          	addi	a0,a0,1404 # 80008090 <digits+0x40>
    80000b1c:	00000097          	auipc	ra,0x0
    80000b20:	a24080e7          	jalr	-1500(ra) # 80000540 <panic>
        panic("kfree");
    80000b24:	00007517          	auipc	a0,0x7
    80000b28:	57c50513          	addi	a0,a0,1404 # 800080a0 <digits+0x50>
    80000b2c:	00000097          	auipc	ra,0x0
    80000b30:	a14080e7          	jalr	-1516(ra) # 80000540 <panic>

0000000080000b34 <freerange>:
{
    80000b34:	7179                	addi	sp,sp,-48
    80000b36:	f406                	sd	ra,40(sp)
    80000b38:	f022                	sd	s0,32(sp)
    80000b3a:	ec26                	sd	s1,24(sp)
    80000b3c:	e84a                	sd	s2,16(sp)
    80000b3e:	e44e                	sd	s3,8(sp)
    80000b40:	e052                	sd	s4,0(sp)
    80000b42:	1800                	addi	s0,sp,48
    p = (char *)PGROUNDUP((uint64)pa_start);
    80000b44:	6785                	lui	a5,0x1
    80000b46:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000b4a:	00e504b3          	add	s1,a0,a4
    80000b4e:	777d                	lui	a4,0xfffff
    80000b50:	8cf9                	and	s1,s1,a4
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000b52:	94be                	add	s1,s1,a5
    80000b54:	0095ee63          	bltu	a1,s1,80000b70 <freerange+0x3c>
    80000b58:	892e                	mv	s2,a1
        kfree(p);
    80000b5a:	7a7d                	lui	s4,0xfffff
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000b5c:	6985                	lui	s3,0x1
        kfree(p);
    80000b5e:	01448533          	add	a0,s1,s4
    80000b62:	00000097          	auipc	ra,0x0
    80000b66:	ed8080e7          	jalr	-296(ra) # 80000a3a <kfree>
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000b6a:	94ce                	add	s1,s1,s3
    80000b6c:	fe9979e3          	bgeu	s2,s1,80000b5e <freerange+0x2a>
}
    80000b70:	70a2                	ld	ra,40(sp)
    80000b72:	7402                	ld	s0,32(sp)
    80000b74:	64e2                	ld	s1,24(sp)
    80000b76:	6942                	ld	s2,16(sp)
    80000b78:	69a2                	ld	s3,8(sp)
    80000b7a:	6a02                	ld	s4,0(sp)
    80000b7c:	6145                	addi	sp,sp,48
    80000b7e:	8082                	ret

0000000080000b80 <kinit>:
{
    80000b80:	1141                	addi	sp,sp,-16
    80000b82:	e406                	sd	ra,8(sp)
    80000b84:	e022                	sd	s0,0(sp)
    80000b86:	0800                	addi	s0,sp,16
    initlock(&kmem.lock, "kmem");
    80000b88:	00007597          	auipc	a1,0x7
    80000b8c:	52058593          	addi	a1,a1,1312 # 800080a8 <digits+0x58>
    80000b90:	00010517          	auipc	a0,0x10
    80000b94:	18050513          	addi	a0,a0,384 # 80010d10 <kmem>
    80000b98:	00000097          	auipc	ra,0x0
    80000b9c:	0e0080e7          	jalr	224(ra) # 80000c78 <initlock>
    freerange(end, (void *)PHYSTOP);
    80000ba0:	45c5                	li	a1,17
    80000ba2:	05ee                	slli	a1,a1,0x1b
    80000ba4:	00461517          	auipc	a0,0x461
    80000ba8:	39c50513          	addi	a0,a0,924 # 80461f40 <end>
    80000bac:	00000097          	auipc	ra,0x0
    80000bb0:	f88080e7          	jalr	-120(ra) # 80000b34 <freerange>
    MAX_PAGES = FREE_PAGES;
    80000bb4:	00008797          	auipc	a5,0x8
    80000bb8:	ee47b783          	ld	a5,-284(a5) # 80008a98 <FREE_PAGES>
    80000bbc:	00008717          	auipc	a4,0x8
    80000bc0:	eef73223          	sd	a5,-284(a4) # 80008aa0 <MAX_PAGES>
}
    80000bc4:	60a2                	ld	ra,8(sp)
    80000bc6:	6402                	ld	s0,0(sp)
    80000bc8:	0141                	addi	sp,sp,16
    80000bca:	8082                	ret

0000000080000bcc <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000bcc:	1101                	addi	sp,sp,-32
    80000bce:	ec06                	sd	ra,24(sp)
    80000bd0:	e822                	sd	s0,16(sp)
    80000bd2:	e426                	sd	s1,8(sp)
    80000bd4:	1000                	addi	s0,sp,32
    assert(FREE_PAGES > 0);
    80000bd6:	00008797          	auipc	a5,0x8
    80000bda:	ec27b783          	ld	a5,-318(a5) # 80008a98 <FREE_PAGES>
    80000bde:	cbb1                	beqz	a5,80000c32 <kalloc+0x66>
    struct run *r;

    acquire(&kmem.lock);
    80000be0:	00010497          	auipc	s1,0x10
    80000be4:	13048493          	addi	s1,s1,304 # 80010d10 <kmem>
    80000be8:	8526                	mv	a0,s1
    80000bea:	00000097          	auipc	ra,0x0
    80000bee:	11e080e7          	jalr	286(ra) # 80000d08 <acquire>
    r = kmem.freelist;
    80000bf2:	6c84                	ld	s1,24(s1)
    if (r)
    80000bf4:	c8ad                	beqz	s1,80000c66 <kalloc+0x9a>
        kmem.freelist = r->next;
    80000bf6:	609c                	ld	a5,0(s1)
    80000bf8:	00010517          	auipc	a0,0x10
    80000bfc:	11850513          	addi	a0,a0,280 # 80010d10 <kmem>
    80000c00:	ed1c                	sd	a5,24(a0)
    release(&kmem.lock);
    80000c02:	00000097          	auipc	ra,0x0
    80000c06:	1ba080e7          	jalr	442(ra) # 80000dbc <release>

    if (r) {
        memset((char *)r, 5, PGSIZE); // fill with junk
    80000c0a:	6605                	lui	a2,0x1
    80000c0c:	4595                	li	a1,5
    80000c0e:	8526                	mv	a0,s1
    80000c10:	00000097          	auipc	ra,0x0
    80000c14:	1f4080e7          	jalr	500(ra) # 80000e04 <memset>
        } */
        // ---------------------
        //new_array[(uint64)r / PGSIZE] = 0;
        // ---------------------
    }
    FREE_PAGES--;
    80000c18:	00008717          	auipc	a4,0x8
    80000c1c:	e8070713          	addi	a4,a4,-384 # 80008a98 <FREE_PAGES>
    80000c20:	631c                	ld	a5,0(a4)
    80000c22:	17fd                	addi	a5,a5,-1
    80000c24:	e31c                	sd	a5,0(a4)
    return (void *)r;
}
    80000c26:	8526                	mv	a0,s1
    80000c28:	60e2                	ld	ra,24(sp)
    80000c2a:	6442                	ld	s0,16(sp)
    80000c2c:	64a2                	ld	s1,8(sp)
    80000c2e:	6105                	addi	sp,sp,32
    80000c30:	8082                	ret
    assert(FREE_PAGES > 0);
    80000c32:	0b400693          	li	a3,180
    80000c36:	00007617          	auipc	a2,0x7
    80000c3a:	3ca60613          	addi	a2,a2,970 # 80008000 <etext>
    80000c3e:	00007597          	auipc	a1,0x7
    80000c42:	43258593          	addi	a1,a1,1074 # 80008070 <digits+0x20>
    80000c46:	00007517          	auipc	a0,0x7
    80000c4a:	43a50513          	addi	a0,a0,1082 # 80008080 <digits+0x30>
    80000c4e:	00000097          	auipc	ra,0x0
    80000c52:	94e080e7          	jalr	-1714(ra) # 8000059c <printf>
    80000c56:	00007517          	auipc	a0,0x7
    80000c5a:	43a50513          	addi	a0,a0,1082 # 80008090 <digits+0x40>
    80000c5e:	00000097          	auipc	ra,0x0
    80000c62:	8e2080e7          	jalr	-1822(ra) # 80000540 <panic>
    release(&kmem.lock);
    80000c66:	00010517          	auipc	a0,0x10
    80000c6a:	0aa50513          	addi	a0,a0,170 # 80010d10 <kmem>
    80000c6e:	00000097          	auipc	ra,0x0
    80000c72:	14e080e7          	jalr	334(ra) # 80000dbc <release>
    if (r) {
    80000c76:	b74d                	j	80000c18 <kalloc+0x4c>

0000000080000c78 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000c78:	1141                	addi	sp,sp,-16
    80000c7a:	e422                	sd	s0,8(sp)
    80000c7c:	0800                	addi	s0,sp,16
  lk->name = name;
    80000c7e:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000c80:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000c84:	00053823          	sd	zero,16(a0)
}
    80000c88:	6422                	ld	s0,8(sp)
    80000c8a:	0141                	addi	sp,sp,16
    80000c8c:	8082                	ret

0000000080000c8e <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000c8e:	411c                	lw	a5,0(a0)
    80000c90:	e399                	bnez	a5,80000c96 <holding+0x8>
    80000c92:	4501                	li	a0,0
  return r;
}
    80000c94:	8082                	ret
{
    80000c96:	1101                	addi	sp,sp,-32
    80000c98:	ec06                	sd	ra,24(sp)
    80000c9a:	e822                	sd	s0,16(sp)
    80000c9c:	e426                	sd	s1,8(sp)
    80000c9e:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000ca0:	6904                	ld	s1,16(a0)
    80000ca2:	00001097          	auipc	ra,0x1
    80000ca6:	f3a080e7          	jalr	-198(ra) # 80001bdc <mycpu>
    80000caa:	40a48533          	sub	a0,s1,a0
    80000cae:	00153513          	seqz	a0,a0
}
    80000cb2:	60e2                	ld	ra,24(sp)
    80000cb4:	6442                	ld	s0,16(sp)
    80000cb6:	64a2                	ld	s1,8(sp)
    80000cb8:	6105                	addi	sp,sp,32
    80000cba:	8082                	ret

0000000080000cbc <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000cbc:	1101                	addi	sp,sp,-32
    80000cbe:	ec06                	sd	ra,24(sp)
    80000cc0:	e822                	sd	s0,16(sp)
    80000cc2:	e426                	sd	s1,8(sp)
    80000cc4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cc6:	100024f3          	csrr	s1,sstatus
    80000cca:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000cce:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cd0:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000cd4:	00001097          	auipc	ra,0x1
    80000cd8:	f08080e7          	jalr	-248(ra) # 80001bdc <mycpu>
    80000cdc:	5d3c                	lw	a5,120(a0)
    80000cde:	cf89                	beqz	a5,80000cf8 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000ce0:	00001097          	auipc	ra,0x1
    80000ce4:	efc080e7          	jalr	-260(ra) # 80001bdc <mycpu>
    80000ce8:	5d3c                	lw	a5,120(a0)
    80000cea:	2785                	addiw	a5,a5,1
    80000cec:	dd3c                	sw	a5,120(a0)
}
    80000cee:	60e2                	ld	ra,24(sp)
    80000cf0:	6442                	ld	s0,16(sp)
    80000cf2:	64a2                	ld	s1,8(sp)
    80000cf4:	6105                	addi	sp,sp,32
    80000cf6:	8082                	ret
    mycpu()->intena = old;
    80000cf8:	00001097          	auipc	ra,0x1
    80000cfc:	ee4080e7          	jalr	-284(ra) # 80001bdc <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000d00:	8085                	srli	s1,s1,0x1
    80000d02:	8885                	andi	s1,s1,1
    80000d04:	dd64                	sw	s1,124(a0)
    80000d06:	bfe9                	j	80000ce0 <push_off+0x24>

0000000080000d08 <acquire>:
{
    80000d08:	1101                	addi	sp,sp,-32
    80000d0a:	ec06                	sd	ra,24(sp)
    80000d0c:	e822                	sd	s0,16(sp)
    80000d0e:	e426                	sd	s1,8(sp)
    80000d10:	1000                	addi	s0,sp,32
    80000d12:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000d14:	00000097          	auipc	ra,0x0
    80000d18:	fa8080e7          	jalr	-88(ra) # 80000cbc <push_off>
  if(holding(lk))
    80000d1c:	8526                	mv	a0,s1
    80000d1e:	00000097          	auipc	ra,0x0
    80000d22:	f70080e7          	jalr	-144(ra) # 80000c8e <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d26:	4705                	li	a4,1
  if(holding(lk))
    80000d28:	e115                	bnez	a0,80000d4c <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d2a:	87ba                	mv	a5,a4
    80000d2c:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000d30:	2781                	sext.w	a5,a5
    80000d32:	ffe5                	bnez	a5,80000d2a <acquire+0x22>
  __sync_synchronize();
    80000d34:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000d38:	00001097          	auipc	ra,0x1
    80000d3c:	ea4080e7          	jalr	-348(ra) # 80001bdc <mycpu>
    80000d40:	e888                	sd	a0,16(s1)
}
    80000d42:	60e2                	ld	ra,24(sp)
    80000d44:	6442                	ld	s0,16(sp)
    80000d46:	64a2                	ld	s1,8(sp)
    80000d48:	6105                	addi	sp,sp,32
    80000d4a:	8082                	ret
    panic("acquire");
    80000d4c:	00007517          	auipc	a0,0x7
    80000d50:	36450513          	addi	a0,a0,868 # 800080b0 <digits+0x60>
    80000d54:	fffff097          	auipc	ra,0xfffff
    80000d58:	7ec080e7          	jalr	2028(ra) # 80000540 <panic>

0000000080000d5c <pop_off>:

void
pop_off(void)
{
    80000d5c:	1141                	addi	sp,sp,-16
    80000d5e:	e406                	sd	ra,8(sp)
    80000d60:	e022                	sd	s0,0(sp)
    80000d62:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000d64:	00001097          	auipc	ra,0x1
    80000d68:	e78080e7          	jalr	-392(ra) # 80001bdc <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d6c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000d70:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000d72:	e78d                	bnez	a5,80000d9c <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000d74:	5d3c                	lw	a5,120(a0)
    80000d76:	02f05b63          	blez	a5,80000dac <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000d7a:	37fd                	addiw	a5,a5,-1
    80000d7c:	0007871b          	sext.w	a4,a5
    80000d80:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000d82:	eb09                	bnez	a4,80000d94 <pop_off+0x38>
    80000d84:	5d7c                	lw	a5,124(a0)
    80000d86:	c799                	beqz	a5,80000d94 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d88:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000d8c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d90:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000d94:	60a2                	ld	ra,8(sp)
    80000d96:	6402                	ld	s0,0(sp)
    80000d98:	0141                	addi	sp,sp,16
    80000d9a:	8082                	ret
    panic("pop_off - interruptible");
    80000d9c:	00007517          	auipc	a0,0x7
    80000da0:	31c50513          	addi	a0,a0,796 # 800080b8 <digits+0x68>
    80000da4:	fffff097          	auipc	ra,0xfffff
    80000da8:	79c080e7          	jalr	1948(ra) # 80000540 <panic>
    panic("pop_off");
    80000dac:	00007517          	auipc	a0,0x7
    80000db0:	32450513          	addi	a0,a0,804 # 800080d0 <digits+0x80>
    80000db4:	fffff097          	auipc	ra,0xfffff
    80000db8:	78c080e7          	jalr	1932(ra) # 80000540 <panic>

0000000080000dbc <release>:
{
    80000dbc:	1101                	addi	sp,sp,-32
    80000dbe:	ec06                	sd	ra,24(sp)
    80000dc0:	e822                	sd	s0,16(sp)
    80000dc2:	e426                	sd	s1,8(sp)
    80000dc4:	1000                	addi	s0,sp,32
    80000dc6:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000dc8:	00000097          	auipc	ra,0x0
    80000dcc:	ec6080e7          	jalr	-314(ra) # 80000c8e <holding>
    80000dd0:	c115                	beqz	a0,80000df4 <release+0x38>
  lk->cpu = 0;
    80000dd2:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000dd6:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000dda:	0f50000f          	fence	iorw,ow
    80000dde:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000de2:	00000097          	auipc	ra,0x0
    80000de6:	f7a080e7          	jalr	-134(ra) # 80000d5c <pop_off>
}
    80000dea:	60e2                	ld	ra,24(sp)
    80000dec:	6442                	ld	s0,16(sp)
    80000dee:	64a2                	ld	s1,8(sp)
    80000df0:	6105                	addi	sp,sp,32
    80000df2:	8082                	ret
    panic("release");
    80000df4:	00007517          	auipc	a0,0x7
    80000df8:	2e450513          	addi	a0,a0,740 # 800080d8 <digits+0x88>
    80000dfc:	fffff097          	auipc	ra,0xfffff
    80000e00:	744080e7          	jalr	1860(ra) # 80000540 <panic>

0000000080000e04 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000e04:	1141                	addi	sp,sp,-16
    80000e06:	e422                	sd	s0,8(sp)
    80000e08:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000e0a:	ca19                	beqz	a2,80000e20 <memset+0x1c>
    80000e0c:	87aa                	mv	a5,a0
    80000e0e:	1602                	slli	a2,a2,0x20
    80000e10:	9201                	srli	a2,a2,0x20
    80000e12:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000e16:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000e1a:	0785                	addi	a5,a5,1
    80000e1c:	fee79de3          	bne	a5,a4,80000e16 <memset+0x12>
  }
  return dst;
}
    80000e20:	6422                	ld	s0,8(sp)
    80000e22:	0141                	addi	sp,sp,16
    80000e24:	8082                	ret

0000000080000e26 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000e26:	1141                	addi	sp,sp,-16
    80000e28:	e422                	sd	s0,8(sp)
    80000e2a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000e2c:	ca05                	beqz	a2,80000e5c <memcmp+0x36>
    80000e2e:	fff6069b          	addiw	a3,a2,-1
    80000e32:	1682                	slli	a3,a3,0x20
    80000e34:	9281                	srli	a3,a3,0x20
    80000e36:	0685                	addi	a3,a3,1
    80000e38:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000e3a:	00054783          	lbu	a5,0(a0)
    80000e3e:	0005c703          	lbu	a4,0(a1)
    80000e42:	00e79863          	bne	a5,a4,80000e52 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000e46:	0505                	addi	a0,a0,1
    80000e48:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000e4a:	fed518e3          	bne	a0,a3,80000e3a <memcmp+0x14>
  }

  return 0;
    80000e4e:	4501                	li	a0,0
    80000e50:	a019                	j	80000e56 <memcmp+0x30>
      return *s1 - *s2;
    80000e52:	40e7853b          	subw	a0,a5,a4
}
    80000e56:	6422                	ld	s0,8(sp)
    80000e58:	0141                	addi	sp,sp,16
    80000e5a:	8082                	ret
  return 0;
    80000e5c:	4501                	li	a0,0
    80000e5e:	bfe5                	j	80000e56 <memcmp+0x30>

0000000080000e60 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000e60:	1141                	addi	sp,sp,-16
    80000e62:	e422                	sd	s0,8(sp)
    80000e64:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000e66:	c205                	beqz	a2,80000e86 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000e68:	02a5e263          	bltu	a1,a0,80000e8c <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000e6c:	1602                	slli	a2,a2,0x20
    80000e6e:	9201                	srli	a2,a2,0x20
    80000e70:	00c587b3          	add	a5,a1,a2
{
    80000e74:	872a                	mv	a4,a0
      *d++ = *s++;
    80000e76:	0585                	addi	a1,a1,1
    80000e78:	0705                	addi	a4,a4,1
    80000e7a:	fff5c683          	lbu	a3,-1(a1)
    80000e7e:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000e82:	fef59ae3          	bne	a1,a5,80000e76 <memmove+0x16>

  return dst;
}
    80000e86:	6422                	ld	s0,8(sp)
    80000e88:	0141                	addi	sp,sp,16
    80000e8a:	8082                	ret
  if(s < d && s + n > d){
    80000e8c:	02061693          	slli	a3,a2,0x20
    80000e90:	9281                	srli	a3,a3,0x20
    80000e92:	00d58733          	add	a4,a1,a3
    80000e96:	fce57be3          	bgeu	a0,a4,80000e6c <memmove+0xc>
    d += n;
    80000e9a:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000e9c:	fff6079b          	addiw	a5,a2,-1
    80000ea0:	1782                	slli	a5,a5,0x20
    80000ea2:	9381                	srli	a5,a5,0x20
    80000ea4:	fff7c793          	not	a5,a5
    80000ea8:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000eaa:	177d                	addi	a4,a4,-1
    80000eac:	16fd                	addi	a3,a3,-1
    80000eae:	00074603          	lbu	a2,0(a4)
    80000eb2:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000eb6:	fee79ae3          	bne	a5,a4,80000eaa <memmove+0x4a>
    80000eba:	b7f1                	j	80000e86 <memmove+0x26>

0000000080000ebc <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000ebc:	1141                	addi	sp,sp,-16
    80000ebe:	e406                	sd	ra,8(sp)
    80000ec0:	e022                	sd	s0,0(sp)
    80000ec2:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000ec4:	00000097          	auipc	ra,0x0
    80000ec8:	f9c080e7          	jalr	-100(ra) # 80000e60 <memmove>
}
    80000ecc:	60a2                	ld	ra,8(sp)
    80000ece:	6402                	ld	s0,0(sp)
    80000ed0:	0141                	addi	sp,sp,16
    80000ed2:	8082                	ret

0000000080000ed4 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000ed4:	1141                	addi	sp,sp,-16
    80000ed6:	e422                	sd	s0,8(sp)
    80000ed8:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000eda:	ce11                	beqz	a2,80000ef6 <strncmp+0x22>
    80000edc:	00054783          	lbu	a5,0(a0)
    80000ee0:	cf89                	beqz	a5,80000efa <strncmp+0x26>
    80000ee2:	0005c703          	lbu	a4,0(a1)
    80000ee6:	00f71a63          	bne	a4,a5,80000efa <strncmp+0x26>
    n--, p++, q++;
    80000eea:	367d                	addiw	a2,a2,-1
    80000eec:	0505                	addi	a0,a0,1
    80000eee:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000ef0:	f675                	bnez	a2,80000edc <strncmp+0x8>
  if(n == 0)
    return 0;
    80000ef2:	4501                	li	a0,0
    80000ef4:	a809                	j	80000f06 <strncmp+0x32>
    80000ef6:	4501                	li	a0,0
    80000ef8:	a039                	j	80000f06 <strncmp+0x32>
  if(n == 0)
    80000efa:	ca09                	beqz	a2,80000f0c <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000efc:	00054503          	lbu	a0,0(a0)
    80000f00:	0005c783          	lbu	a5,0(a1)
    80000f04:	9d1d                	subw	a0,a0,a5
}
    80000f06:	6422                	ld	s0,8(sp)
    80000f08:	0141                	addi	sp,sp,16
    80000f0a:	8082                	ret
    return 0;
    80000f0c:	4501                	li	a0,0
    80000f0e:	bfe5                	j	80000f06 <strncmp+0x32>

0000000080000f10 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000f10:	1141                	addi	sp,sp,-16
    80000f12:	e422                	sd	s0,8(sp)
    80000f14:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000f16:	872a                	mv	a4,a0
    80000f18:	8832                	mv	a6,a2
    80000f1a:	367d                	addiw	a2,a2,-1
    80000f1c:	01005963          	blez	a6,80000f2e <strncpy+0x1e>
    80000f20:	0705                	addi	a4,a4,1
    80000f22:	0005c783          	lbu	a5,0(a1)
    80000f26:	fef70fa3          	sb	a5,-1(a4)
    80000f2a:	0585                	addi	a1,a1,1
    80000f2c:	f7f5                	bnez	a5,80000f18 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000f2e:	86ba                	mv	a3,a4
    80000f30:	00c05c63          	blez	a2,80000f48 <strncpy+0x38>
    *s++ = 0;
    80000f34:	0685                	addi	a3,a3,1
    80000f36:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000f3a:	40d707bb          	subw	a5,a4,a3
    80000f3e:	37fd                	addiw	a5,a5,-1
    80000f40:	010787bb          	addw	a5,a5,a6
    80000f44:	fef048e3          	bgtz	a5,80000f34 <strncpy+0x24>
  return os;
}
    80000f48:	6422                	ld	s0,8(sp)
    80000f4a:	0141                	addi	sp,sp,16
    80000f4c:	8082                	ret

0000000080000f4e <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000f4e:	1141                	addi	sp,sp,-16
    80000f50:	e422                	sd	s0,8(sp)
    80000f52:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000f54:	02c05363          	blez	a2,80000f7a <safestrcpy+0x2c>
    80000f58:	fff6069b          	addiw	a3,a2,-1
    80000f5c:	1682                	slli	a3,a3,0x20
    80000f5e:	9281                	srli	a3,a3,0x20
    80000f60:	96ae                	add	a3,a3,a1
    80000f62:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000f64:	00d58963          	beq	a1,a3,80000f76 <safestrcpy+0x28>
    80000f68:	0585                	addi	a1,a1,1
    80000f6a:	0785                	addi	a5,a5,1
    80000f6c:	fff5c703          	lbu	a4,-1(a1)
    80000f70:	fee78fa3          	sb	a4,-1(a5)
    80000f74:	fb65                	bnez	a4,80000f64 <safestrcpy+0x16>
    ;
  *s = 0;
    80000f76:	00078023          	sb	zero,0(a5)
  return os;
}
    80000f7a:	6422                	ld	s0,8(sp)
    80000f7c:	0141                	addi	sp,sp,16
    80000f7e:	8082                	ret

0000000080000f80 <strlen>:

int
strlen(const char *s)
{
    80000f80:	1141                	addi	sp,sp,-16
    80000f82:	e422                	sd	s0,8(sp)
    80000f84:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000f86:	00054783          	lbu	a5,0(a0)
    80000f8a:	cf91                	beqz	a5,80000fa6 <strlen+0x26>
    80000f8c:	0505                	addi	a0,a0,1
    80000f8e:	87aa                	mv	a5,a0
    80000f90:	4685                	li	a3,1
    80000f92:	9e89                	subw	a3,a3,a0
    80000f94:	00f6853b          	addw	a0,a3,a5
    80000f98:	0785                	addi	a5,a5,1
    80000f9a:	fff7c703          	lbu	a4,-1(a5)
    80000f9e:	fb7d                	bnez	a4,80000f94 <strlen+0x14>
    ;
  return n;
}
    80000fa0:	6422                	ld	s0,8(sp)
    80000fa2:	0141                	addi	sp,sp,16
    80000fa4:	8082                	ret
  for(n = 0; s[n]; n++)
    80000fa6:	4501                	li	a0,0
    80000fa8:	bfe5                	j	80000fa0 <strlen+0x20>

0000000080000faa <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000faa:	1141                	addi	sp,sp,-16
    80000fac:	e406                	sd	ra,8(sp)
    80000fae:	e022                	sd	s0,0(sp)
    80000fb0:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000fb2:	00001097          	auipc	ra,0x1
    80000fb6:	c1a080e7          	jalr	-998(ra) # 80001bcc <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000fba:	00008717          	auipc	a4,0x8
    80000fbe:	aee70713          	addi	a4,a4,-1298 # 80008aa8 <started>
  if(cpuid() == 0){
    80000fc2:	c139                	beqz	a0,80001008 <main+0x5e>
    while(started == 0)
    80000fc4:	431c                	lw	a5,0(a4)
    80000fc6:	2781                	sext.w	a5,a5
    80000fc8:	dff5                	beqz	a5,80000fc4 <main+0x1a>
      ;
    __sync_synchronize();
    80000fca:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000fce:	00001097          	auipc	ra,0x1
    80000fd2:	bfe080e7          	jalr	-1026(ra) # 80001bcc <cpuid>
    80000fd6:	85aa                	mv	a1,a0
    80000fd8:	00007517          	auipc	a0,0x7
    80000fdc:	12050513          	addi	a0,a0,288 # 800080f8 <digits+0xa8>
    80000fe0:	fffff097          	auipc	ra,0xfffff
    80000fe4:	5bc080e7          	jalr	1468(ra) # 8000059c <printf>
    kvminithart();    // turn on paging
    80000fe8:	00000097          	auipc	ra,0x0
    80000fec:	0d8080e7          	jalr	216(ra) # 800010c0 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ff0:	00002097          	auipc	ra,0x2
    80000ff4:	aa0080e7          	jalr	-1376(ra) # 80002a90 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ff8:	00005097          	auipc	ra,0x5
    80000ffc:	2a8080e7          	jalr	680(ra) # 800062a0 <plicinithart>
  }

  scheduler();        
    80001000:	00001097          	auipc	ra,0x1
    80001004:	296080e7          	jalr	662(ra) # 80002296 <scheduler>
    consoleinit();
    80001008:	fffff097          	auipc	ra,0xfffff
    8000100c:	448080e7          	jalr	1096(ra) # 80000450 <consoleinit>
    printfinit();
    80001010:	fffff097          	auipc	ra,0xfffff
    80001014:	76c080e7          	jalr	1900(ra) # 8000077c <printfinit>
    printf("\n");
    80001018:	00007517          	auipc	a0,0x7
    8000101c:	47850513          	addi	a0,a0,1144 # 80008490 <states.0+0xa8>
    80001020:	fffff097          	auipc	ra,0xfffff
    80001024:	57c080e7          	jalr	1404(ra) # 8000059c <printf>
    printf("xv6 kernel is booting\n");
    80001028:	00007517          	auipc	a0,0x7
    8000102c:	0b850513          	addi	a0,a0,184 # 800080e0 <digits+0x90>
    80001030:	fffff097          	auipc	ra,0xfffff
    80001034:	56c080e7          	jalr	1388(ra) # 8000059c <printf>
    printf("\n");
    80001038:	00007517          	auipc	a0,0x7
    8000103c:	45850513          	addi	a0,a0,1112 # 80008490 <states.0+0xa8>
    80001040:	fffff097          	auipc	ra,0xfffff
    80001044:	55c080e7          	jalr	1372(ra) # 8000059c <printf>
    kinit();         // physical page allocator
    80001048:	00000097          	auipc	ra,0x0
    8000104c:	b38080e7          	jalr	-1224(ra) # 80000b80 <kinit>
    kvminit();       // create kernel page table
    80001050:	00000097          	auipc	ra,0x0
    80001054:	326080e7          	jalr	806(ra) # 80001376 <kvminit>
    kvminithart();   // turn on paging
    80001058:	00000097          	auipc	ra,0x0
    8000105c:	068080e7          	jalr	104(ra) # 800010c0 <kvminithart>
    procinit();      // process table
    80001060:	00001097          	auipc	ra,0x1
    80001064:	a8a080e7          	jalr	-1398(ra) # 80001aea <procinit>
    trapinit();      // trap vectors
    80001068:	00002097          	auipc	ra,0x2
    8000106c:	a00080e7          	jalr	-1536(ra) # 80002a68 <trapinit>
    trapinithart();  // install kernel trap vector
    80001070:	00002097          	auipc	ra,0x2
    80001074:	a20080e7          	jalr	-1504(ra) # 80002a90 <trapinithart>
    plicinit();      // set up interrupt controller
    80001078:	00005097          	auipc	ra,0x5
    8000107c:	212080e7          	jalr	530(ra) # 8000628a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001080:	00005097          	auipc	ra,0x5
    80001084:	220080e7          	jalr	544(ra) # 800062a0 <plicinithart>
    binit();         // buffer cache
    80001088:	00002097          	auipc	ra,0x2
    8000108c:	3bc080e7          	jalr	956(ra) # 80003444 <binit>
    iinit();         // inode table
    80001090:	00003097          	auipc	ra,0x3
    80001094:	a5c080e7          	jalr	-1444(ra) # 80003aec <iinit>
    fileinit();      // file table
    80001098:	00004097          	auipc	ra,0x4
    8000109c:	a02080e7          	jalr	-1534(ra) # 80004a9a <fileinit>
    virtio_disk_init(); // emulated hard disk
    800010a0:	00005097          	auipc	ra,0x5
    800010a4:	308080e7          	jalr	776(ra) # 800063a8 <virtio_disk_init>
    userinit();      // first user process
    800010a8:	00001097          	auipc	ra,0x1
    800010ac:	e28080e7          	jalr	-472(ra) # 80001ed0 <userinit>
    __sync_synchronize();
    800010b0:	0ff0000f          	fence
    started = 1;
    800010b4:	4785                	li	a5,1
    800010b6:	00008717          	auipc	a4,0x8
    800010ba:	9ef72923          	sw	a5,-1550(a4) # 80008aa8 <started>
    800010be:	b789                	j	80001000 <main+0x56>

00000000800010c0 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    800010c0:	1141                	addi	sp,sp,-16
    800010c2:	e422                	sd	s0,8(sp)
    800010c4:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    800010c6:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    800010ca:	00008797          	auipc	a5,0x8
    800010ce:	9e67b783          	ld	a5,-1562(a5) # 80008ab0 <kernel_pagetable>
    800010d2:	83b1                	srli	a5,a5,0xc
    800010d4:	577d                	li	a4,-1
    800010d6:	177e                	slli	a4,a4,0x3f
    800010d8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    800010da:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    800010de:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    800010e2:	6422                	ld	s0,8(sp)
    800010e4:	0141                	addi	sp,sp,16
    800010e6:	8082                	ret

00000000800010e8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    800010e8:	7139                	addi	sp,sp,-64
    800010ea:	fc06                	sd	ra,56(sp)
    800010ec:	f822                	sd	s0,48(sp)
    800010ee:	f426                	sd	s1,40(sp)
    800010f0:	f04a                	sd	s2,32(sp)
    800010f2:	ec4e                	sd	s3,24(sp)
    800010f4:	e852                	sd	s4,16(sp)
    800010f6:	e456                	sd	s5,8(sp)
    800010f8:	e05a                	sd	s6,0(sp)
    800010fa:	0080                	addi	s0,sp,64
    800010fc:	84aa                	mv	s1,a0
    800010fe:	89ae                	mv	s3,a1
    80001100:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001102:	57fd                	li	a5,-1
    80001104:	83e9                	srli	a5,a5,0x1a
    80001106:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001108:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000110a:	04b7f263          	bgeu	a5,a1,8000114e <walk+0x66>
    panic("walk");
    8000110e:	00007517          	auipc	a0,0x7
    80001112:	00250513          	addi	a0,a0,2 # 80008110 <digits+0xc0>
    80001116:	fffff097          	auipc	ra,0xfffff
    8000111a:	42a080e7          	jalr	1066(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000111e:	060a8663          	beqz	s5,8000118a <walk+0xa2>
    80001122:	00000097          	auipc	ra,0x0
    80001126:	aaa080e7          	jalr	-1366(ra) # 80000bcc <kalloc>
    8000112a:	84aa                	mv	s1,a0
    8000112c:	c529                	beqz	a0,80001176 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000112e:	6605                	lui	a2,0x1
    80001130:	4581                	li	a1,0
    80001132:	00000097          	auipc	ra,0x0
    80001136:	cd2080e7          	jalr	-814(ra) # 80000e04 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000113a:	00c4d793          	srli	a5,s1,0xc
    8000113e:	07aa                	slli	a5,a5,0xa
    80001140:	0017e793          	ori	a5,a5,1
    80001144:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001148:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7fb9d0b7>
    8000114a:	036a0063          	beq	s4,s6,8000116a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000114e:	0149d933          	srl	s2,s3,s4
    80001152:	1ff97913          	andi	s2,s2,511
    80001156:	090e                	slli	s2,s2,0x3
    80001158:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000115a:	00093483          	ld	s1,0(s2)
    8000115e:	0014f793          	andi	a5,s1,1
    80001162:	dfd5                	beqz	a5,8000111e <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001164:	80a9                	srli	s1,s1,0xa
    80001166:	04b2                	slli	s1,s1,0xc
    80001168:	b7c5                	j	80001148 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000116a:	00c9d513          	srli	a0,s3,0xc
    8000116e:	1ff57513          	andi	a0,a0,511
    80001172:	050e                	slli	a0,a0,0x3
    80001174:	9526                	add	a0,a0,s1
}
    80001176:	70e2                	ld	ra,56(sp)
    80001178:	7442                	ld	s0,48(sp)
    8000117a:	74a2                	ld	s1,40(sp)
    8000117c:	7902                	ld	s2,32(sp)
    8000117e:	69e2                	ld	s3,24(sp)
    80001180:	6a42                	ld	s4,16(sp)
    80001182:	6aa2                	ld	s5,8(sp)
    80001184:	6b02                	ld	s6,0(sp)
    80001186:	6121                	addi	sp,sp,64
    80001188:	8082                	ret
        return 0;
    8000118a:	4501                	li	a0,0
    8000118c:	b7ed                	j	80001176 <walk+0x8e>

000000008000118e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000118e:	57fd                	li	a5,-1
    80001190:	83e9                	srli	a5,a5,0x1a
    80001192:	00b7f463          	bgeu	a5,a1,8000119a <walkaddr+0xc>
    return 0;
    80001196:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001198:	8082                	ret
{
    8000119a:	1141                	addi	sp,sp,-16
    8000119c:	e406                	sd	ra,8(sp)
    8000119e:	e022                	sd	s0,0(sp)
    800011a0:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800011a2:	4601                	li	a2,0
    800011a4:	00000097          	auipc	ra,0x0
    800011a8:	f44080e7          	jalr	-188(ra) # 800010e8 <walk>
  if(pte == 0)
    800011ac:	c105                	beqz	a0,800011cc <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800011ae:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800011b0:	0117f693          	andi	a3,a5,17
    800011b4:	4745                	li	a4,17
    return 0;
    800011b6:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800011b8:	00e68663          	beq	a3,a4,800011c4 <walkaddr+0x36>
}
    800011bc:	60a2                	ld	ra,8(sp)
    800011be:	6402                	ld	s0,0(sp)
    800011c0:	0141                	addi	sp,sp,16
    800011c2:	8082                	ret
  pa = PTE2PA(*pte);
    800011c4:	83a9                	srli	a5,a5,0xa
    800011c6:	00c79513          	slli	a0,a5,0xc
  return pa;
    800011ca:	bfcd                	j	800011bc <walkaddr+0x2e>
    return 0;
    800011cc:	4501                	li	a0,0
    800011ce:	b7fd                	j	800011bc <walkaddr+0x2e>

00000000800011d0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800011d0:	715d                	addi	sp,sp,-80
    800011d2:	e486                	sd	ra,72(sp)
    800011d4:	e0a2                	sd	s0,64(sp)
    800011d6:	fc26                	sd	s1,56(sp)
    800011d8:	f84a                	sd	s2,48(sp)
    800011da:	f44e                	sd	s3,40(sp)
    800011dc:	f052                	sd	s4,32(sp)
    800011de:	ec56                	sd	s5,24(sp)
    800011e0:	e85a                	sd	s6,16(sp)
    800011e2:	e45e                	sd	s7,8(sp)
    800011e4:	0880                	addi	s0,sp,80
  // printf("Mappages fysisk adresse mappages funksjon: %d\n", pa);
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800011e6:	c639                	beqz	a2,80001234 <mappages+0x64>
    800011e8:	8aaa                	mv	s5,a0
    800011ea:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800011ec:	777d                	lui	a4,0xfffff
    800011ee:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800011f2:	fff58993          	addi	s3,a1,-1
    800011f6:	99b2                	add	s3,s3,a2
    800011f8:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800011fc:	893e                	mv	s2,a5
    800011fe:	40f68a33          	sub	s4,a3,a5
      panic("mappages: remap");
    }
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001202:	6b85                	lui	s7,0x1
    80001204:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001208:	4605                	li	a2,1
    8000120a:	85ca                	mv	a1,s2
    8000120c:	8556                	mv	a0,s5
    8000120e:	00000097          	auipc	ra,0x0
    80001212:	eda080e7          	jalr	-294(ra) # 800010e8 <walk>
    80001216:	cd1d                	beqz	a0,80001254 <mappages+0x84>
    if(*pte & PTE_V) {
    80001218:	611c                	ld	a5,0(a0)
    8000121a:	8b85                	andi	a5,a5,1
    8000121c:	e785                	bnez	a5,80001244 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000121e:	80b1                	srli	s1,s1,0xc
    80001220:	04aa                	slli	s1,s1,0xa
    80001222:	0164e4b3          	or	s1,s1,s6
    80001226:	0014e493          	ori	s1,s1,1
    8000122a:	e104                	sd	s1,0(a0)
    if(a == last)
    8000122c:	05390063          	beq	s2,s3,8000126c <mappages+0x9c>
    a += PGSIZE;
    80001230:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001232:	bfc9                	j	80001204 <mappages+0x34>
    panic("mappages: size");
    80001234:	00007517          	auipc	a0,0x7
    80001238:	ee450513          	addi	a0,a0,-284 # 80008118 <digits+0xc8>
    8000123c:	fffff097          	auipc	ra,0xfffff
    80001240:	304080e7          	jalr	772(ra) # 80000540 <panic>
      panic("mappages: remap");
    80001244:	00007517          	auipc	a0,0x7
    80001248:	ee450513          	addi	a0,a0,-284 # 80008128 <digits+0xd8>
    8000124c:	fffff097          	auipc	ra,0xfffff
    80001250:	2f4080e7          	jalr	756(ra) # 80000540 <panic>
      return -1;
    80001254:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001256:	60a6                	ld	ra,72(sp)
    80001258:	6406                	ld	s0,64(sp)
    8000125a:	74e2                	ld	s1,56(sp)
    8000125c:	7942                	ld	s2,48(sp)
    8000125e:	79a2                	ld	s3,40(sp)
    80001260:	7a02                	ld	s4,32(sp)
    80001262:	6ae2                	ld	s5,24(sp)
    80001264:	6b42                	ld	s6,16(sp)
    80001266:	6ba2                	ld	s7,8(sp)
    80001268:	6161                	addi	sp,sp,80
    8000126a:	8082                	ret
  return 0;
    8000126c:	4501                	li	a0,0
    8000126e:	b7e5                	j	80001256 <mappages+0x86>

0000000080001270 <kvmmap>:
{
    80001270:	1141                	addi	sp,sp,-16
    80001272:	e406                	sd	ra,8(sp)
    80001274:	e022                	sd	s0,0(sp)
    80001276:	0800                	addi	s0,sp,16
    80001278:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000127a:	86b2                	mv	a3,a2
    8000127c:	863e                	mv	a2,a5
    8000127e:	00000097          	auipc	ra,0x0
    80001282:	f52080e7          	jalr	-174(ra) # 800011d0 <mappages>
    80001286:	e509                	bnez	a0,80001290 <kvmmap+0x20>
}
    80001288:	60a2                	ld	ra,8(sp)
    8000128a:	6402                	ld	s0,0(sp)
    8000128c:	0141                	addi	sp,sp,16
    8000128e:	8082                	ret
    panic("kvmmap");
    80001290:	00007517          	auipc	a0,0x7
    80001294:	ea850513          	addi	a0,a0,-344 # 80008138 <digits+0xe8>
    80001298:	fffff097          	auipc	ra,0xfffff
    8000129c:	2a8080e7          	jalr	680(ra) # 80000540 <panic>

00000000800012a0 <kvmmake>:
{
    800012a0:	1101                	addi	sp,sp,-32
    800012a2:	ec06                	sd	ra,24(sp)
    800012a4:	e822                	sd	s0,16(sp)
    800012a6:	e426                	sd	s1,8(sp)
    800012a8:	e04a                	sd	s2,0(sp)
    800012aa:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800012ac:	00000097          	auipc	ra,0x0
    800012b0:	920080e7          	jalr	-1760(ra) # 80000bcc <kalloc>
    800012b4:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800012b6:	6605                	lui	a2,0x1
    800012b8:	4581                	li	a1,0
    800012ba:	00000097          	auipc	ra,0x0
    800012be:	b4a080e7          	jalr	-1206(ra) # 80000e04 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800012c2:	4719                	li	a4,6
    800012c4:	6685                	lui	a3,0x1
    800012c6:	10000637          	lui	a2,0x10000
    800012ca:	100005b7          	lui	a1,0x10000
    800012ce:	8526                	mv	a0,s1
    800012d0:	00000097          	auipc	ra,0x0
    800012d4:	fa0080e7          	jalr	-96(ra) # 80001270 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800012d8:	4719                	li	a4,6
    800012da:	6685                	lui	a3,0x1
    800012dc:	10001637          	lui	a2,0x10001
    800012e0:	100015b7          	lui	a1,0x10001
    800012e4:	8526                	mv	a0,s1
    800012e6:	00000097          	auipc	ra,0x0
    800012ea:	f8a080e7          	jalr	-118(ra) # 80001270 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012ee:	4719                	li	a4,6
    800012f0:	004006b7          	lui	a3,0x400
    800012f4:	0c000637          	lui	a2,0xc000
    800012f8:	0c0005b7          	lui	a1,0xc000
    800012fc:	8526                	mv	a0,s1
    800012fe:	00000097          	auipc	ra,0x0
    80001302:	f72080e7          	jalr	-142(ra) # 80001270 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001306:	00007917          	auipc	s2,0x7
    8000130a:	cfa90913          	addi	s2,s2,-774 # 80008000 <etext>
    8000130e:	4729                	li	a4,10
    80001310:	80007697          	auipc	a3,0x80007
    80001314:	cf068693          	addi	a3,a3,-784 # 8000 <_entry-0x7fff8000>
    80001318:	4605                	li	a2,1
    8000131a:	067e                	slli	a2,a2,0x1f
    8000131c:	85b2                	mv	a1,a2
    8000131e:	8526                	mv	a0,s1
    80001320:	00000097          	auipc	ra,0x0
    80001324:	f50080e7          	jalr	-176(ra) # 80001270 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001328:	4719                	li	a4,6
    8000132a:	46c5                	li	a3,17
    8000132c:	06ee                	slli	a3,a3,0x1b
    8000132e:	412686b3          	sub	a3,a3,s2
    80001332:	864a                	mv	a2,s2
    80001334:	85ca                	mv	a1,s2
    80001336:	8526                	mv	a0,s1
    80001338:	00000097          	auipc	ra,0x0
    8000133c:	f38080e7          	jalr	-200(ra) # 80001270 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001340:	4729                	li	a4,10
    80001342:	6685                	lui	a3,0x1
    80001344:	00006617          	auipc	a2,0x6
    80001348:	cbc60613          	addi	a2,a2,-836 # 80007000 <_trampoline>
    8000134c:	040005b7          	lui	a1,0x4000
    80001350:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001352:	05b2                	slli	a1,a1,0xc
    80001354:	8526                	mv	a0,s1
    80001356:	00000097          	auipc	ra,0x0
    8000135a:	f1a080e7          	jalr	-230(ra) # 80001270 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000135e:	8526                	mv	a0,s1
    80001360:	00000097          	auipc	ra,0x0
    80001364:	6f4080e7          	jalr	1780(ra) # 80001a54 <proc_mapstacks>
}
    80001368:	8526                	mv	a0,s1
    8000136a:	60e2                	ld	ra,24(sp)
    8000136c:	6442                	ld	s0,16(sp)
    8000136e:	64a2                	ld	s1,8(sp)
    80001370:	6902                	ld	s2,0(sp)
    80001372:	6105                	addi	sp,sp,32
    80001374:	8082                	ret

0000000080001376 <kvminit>:
{
    80001376:	1141                	addi	sp,sp,-16
    80001378:	e406                	sd	ra,8(sp)
    8000137a:	e022                	sd	s0,0(sp)
    8000137c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000137e:	00000097          	auipc	ra,0x0
    80001382:	f22080e7          	jalr	-222(ra) # 800012a0 <kvmmake>
    80001386:	00007797          	auipc	a5,0x7
    8000138a:	72a7b523          	sd	a0,1834(a5) # 80008ab0 <kernel_pagetable>
}
    8000138e:	60a2                	ld	ra,8(sp)
    80001390:	6402                	ld	s0,0(sp)
    80001392:	0141                	addi	sp,sp,16
    80001394:	8082                	ret

0000000080001396 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001396:	715d                	addi	sp,sp,-80
    80001398:	e486                	sd	ra,72(sp)
    8000139a:	e0a2                	sd	s0,64(sp)
    8000139c:	fc26                	sd	s1,56(sp)
    8000139e:	f84a                	sd	s2,48(sp)
    800013a0:	f44e                	sd	s3,40(sp)
    800013a2:	f052                	sd	s4,32(sp)
    800013a4:	ec56                	sd	s5,24(sp)
    800013a6:	e85a                	sd	s6,16(sp)
    800013a8:	e45e                	sd	s7,8(sp)
    800013aa:	0880                	addi	s0,sp,80
  
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800013ac:	03459793          	slli	a5,a1,0x34
    800013b0:	e795                	bnez	a5,800013dc <uvmunmap+0x46>
    800013b2:	8a2a                	mv	s4,a0
    800013b4:	892e                	mv	s2,a1
    800013b6:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013b8:	0632                	slli	a2,a2,0xc
    800013ba:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800013be:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013c0:	6b05                	lui	s6,0x1
    800013c2:	0735e263          	bltu	a1,s3,80001426 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800013c6:	60a6                	ld	ra,72(sp)
    800013c8:	6406                	ld	s0,64(sp)
    800013ca:	74e2                	ld	s1,56(sp)
    800013cc:	7942                	ld	s2,48(sp)
    800013ce:	79a2                	ld	s3,40(sp)
    800013d0:	7a02                	ld	s4,32(sp)
    800013d2:	6ae2                	ld	s5,24(sp)
    800013d4:	6b42                	ld	s6,16(sp)
    800013d6:	6ba2                	ld	s7,8(sp)
    800013d8:	6161                	addi	sp,sp,80
    800013da:	8082                	ret
    panic("uvmunmap: not aligned");
    800013dc:	00007517          	auipc	a0,0x7
    800013e0:	d6450513          	addi	a0,a0,-668 # 80008140 <digits+0xf0>
    800013e4:	fffff097          	auipc	ra,0xfffff
    800013e8:	15c080e7          	jalr	348(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    800013ec:	00007517          	auipc	a0,0x7
    800013f0:	d6c50513          	addi	a0,a0,-660 # 80008158 <digits+0x108>
    800013f4:	fffff097          	auipc	ra,0xfffff
    800013f8:	14c080e7          	jalr	332(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    800013fc:	00007517          	auipc	a0,0x7
    80001400:	d6c50513          	addi	a0,a0,-660 # 80008168 <digits+0x118>
    80001404:	fffff097          	auipc	ra,0xfffff
    80001408:	13c080e7          	jalr	316(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    8000140c:	00007517          	auipc	a0,0x7
    80001410:	d7450513          	addi	a0,a0,-652 # 80008180 <digits+0x130>
    80001414:	fffff097          	auipc	ra,0xfffff
    80001418:	12c080e7          	jalr	300(ra) # 80000540 <panic>
    *pte = 0;
    8000141c:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001420:	995a                	add	s2,s2,s6
    80001422:	fb3972e3          	bgeu	s2,s3,800013c6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001426:	4601                	li	a2,0
    80001428:	85ca                	mv	a1,s2
    8000142a:	8552                	mv	a0,s4
    8000142c:	00000097          	auipc	ra,0x0
    80001430:	cbc080e7          	jalr	-836(ra) # 800010e8 <walk>
    80001434:	84aa                	mv	s1,a0
    80001436:	d95d                	beqz	a0,800013ec <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001438:	6108                	ld	a0,0(a0)
    8000143a:	00157793          	andi	a5,a0,1
    8000143e:	dfdd                	beqz	a5,800013fc <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001440:	3ff57793          	andi	a5,a0,1023
    80001444:	fd7784e3          	beq	a5,s7,8000140c <uvmunmap+0x76>
    if(do_free){
    80001448:	fc0a8ae3          	beqz	s5,8000141c <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000144c:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000144e:	0532                	slli	a0,a0,0xc
    80001450:	fffff097          	auipc	ra,0xfffff
    80001454:	5ea080e7          	jalr	1514(ra) # 80000a3a <kfree>
    80001458:	b7d1                	j	8000141c <uvmunmap+0x86>

000000008000145a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000145a:	1101                	addi	sp,sp,-32
    8000145c:	ec06                	sd	ra,24(sp)
    8000145e:	e822                	sd	s0,16(sp)
    80001460:	e426                	sd	s1,8(sp)
    80001462:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001464:	fffff097          	auipc	ra,0xfffff
    80001468:	768080e7          	jalr	1896(ra) # 80000bcc <kalloc>
    8000146c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000146e:	c519                	beqz	a0,8000147c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001470:	6605                	lui	a2,0x1
    80001472:	4581                	li	a1,0
    80001474:	00000097          	auipc	ra,0x0
    80001478:	990080e7          	jalr	-1648(ra) # 80000e04 <memset>
  return pagetable;
}
    8000147c:	8526                	mv	a0,s1
    8000147e:	60e2                	ld	ra,24(sp)
    80001480:	6442                	ld	s0,16(sp)
    80001482:	64a2                	ld	s1,8(sp)
    80001484:	6105                	addi	sp,sp,32
    80001486:	8082                	ret

0000000080001488 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001488:	7179                	addi	sp,sp,-48
    8000148a:	f406                	sd	ra,40(sp)
    8000148c:	f022                	sd	s0,32(sp)
    8000148e:	ec26                	sd	s1,24(sp)
    80001490:	e84a                	sd	s2,16(sp)
    80001492:	e44e                	sd	s3,8(sp)
    80001494:	e052                	sd	s4,0(sp)
    80001496:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001498:	6785                	lui	a5,0x1
    8000149a:	04f67863          	bgeu	a2,a5,800014ea <uvmfirst+0x62>
    8000149e:	8a2a                	mv	s4,a0
    800014a0:	89ae                	mv	s3,a1
    800014a2:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    800014a4:	fffff097          	auipc	ra,0xfffff
    800014a8:	728080e7          	jalr	1832(ra) # 80000bcc <kalloc>
    800014ac:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800014ae:	6605                	lui	a2,0x1
    800014b0:	4581                	li	a1,0
    800014b2:	00000097          	auipc	ra,0x0
    800014b6:	952080e7          	jalr	-1710(ra) # 80000e04 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800014ba:	4779                	li	a4,30
    800014bc:	86ca                	mv	a3,s2
    800014be:	6605                	lui	a2,0x1
    800014c0:	4581                	li	a1,0
    800014c2:	8552                	mv	a0,s4
    800014c4:	00000097          	auipc	ra,0x0
    800014c8:	d0c080e7          	jalr	-756(ra) # 800011d0 <mappages>
  memmove(mem, src, sz);
    800014cc:	8626                	mv	a2,s1
    800014ce:	85ce                	mv	a1,s3
    800014d0:	854a                	mv	a0,s2
    800014d2:	00000097          	auipc	ra,0x0
    800014d6:	98e080e7          	jalr	-1650(ra) # 80000e60 <memmove>
}
    800014da:	70a2                	ld	ra,40(sp)
    800014dc:	7402                	ld	s0,32(sp)
    800014de:	64e2                	ld	s1,24(sp)
    800014e0:	6942                	ld	s2,16(sp)
    800014e2:	69a2                	ld	s3,8(sp)
    800014e4:	6a02                	ld	s4,0(sp)
    800014e6:	6145                	addi	sp,sp,48
    800014e8:	8082                	ret
    panic("uvmfirst: more than a page");
    800014ea:	00007517          	auipc	a0,0x7
    800014ee:	cae50513          	addi	a0,a0,-850 # 80008198 <digits+0x148>
    800014f2:	fffff097          	auipc	ra,0xfffff
    800014f6:	04e080e7          	jalr	78(ra) # 80000540 <panic>

00000000800014fa <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800014fa:	1101                	addi	sp,sp,-32
    800014fc:	ec06                	sd	ra,24(sp)
    800014fe:	e822                	sd	s0,16(sp)
    80001500:	e426                	sd	s1,8(sp)
    80001502:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001504:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001506:	00b67d63          	bgeu	a2,a1,80001520 <uvmdealloc+0x26>
    8000150a:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000150c:	6785                	lui	a5,0x1
    8000150e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001510:	00f60733          	add	a4,a2,a5
    80001514:	76fd                	lui	a3,0xfffff
    80001516:	8f75                	and	a4,a4,a3
    80001518:	97ae                	add	a5,a5,a1
    8000151a:	8ff5                	and	a5,a5,a3
    8000151c:	00f76863          	bltu	a4,a5,8000152c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001520:	8526                	mv	a0,s1
    80001522:	60e2                	ld	ra,24(sp)
    80001524:	6442                	ld	s0,16(sp)
    80001526:	64a2                	ld	s1,8(sp)
    80001528:	6105                	addi	sp,sp,32
    8000152a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000152c:	8f99                	sub	a5,a5,a4
    8000152e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001530:	4685                	li	a3,1
    80001532:	0007861b          	sext.w	a2,a5
    80001536:	85ba                	mv	a1,a4
    80001538:	00000097          	auipc	ra,0x0
    8000153c:	e5e080e7          	jalr	-418(ra) # 80001396 <uvmunmap>
    80001540:	b7c5                	j	80001520 <uvmdealloc+0x26>

0000000080001542 <uvmalloc>:
  if(newsz < oldsz)
    80001542:	0ab66563          	bltu	a2,a1,800015ec <uvmalloc+0xaa>
{
    80001546:	7139                	addi	sp,sp,-64
    80001548:	fc06                	sd	ra,56(sp)
    8000154a:	f822                	sd	s0,48(sp)
    8000154c:	f426                	sd	s1,40(sp)
    8000154e:	f04a                	sd	s2,32(sp)
    80001550:	ec4e                	sd	s3,24(sp)
    80001552:	e852                	sd	s4,16(sp)
    80001554:	e456                	sd	s5,8(sp)
    80001556:	e05a                	sd	s6,0(sp)
    80001558:	0080                	addi	s0,sp,64
    8000155a:	8aaa                	mv	s5,a0
    8000155c:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000155e:	6785                	lui	a5,0x1
    80001560:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001562:	95be                	add	a1,a1,a5
    80001564:	77fd                	lui	a5,0xfffff
    80001566:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000156a:	08c9f363          	bgeu	s3,a2,800015f0 <uvmalloc+0xae>
    8000156e:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001570:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001574:	fffff097          	auipc	ra,0xfffff
    80001578:	658080e7          	jalr	1624(ra) # 80000bcc <kalloc>
    8000157c:	84aa                	mv	s1,a0
    if(mem == 0){
    8000157e:	c51d                	beqz	a0,800015ac <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    80001580:	6605                	lui	a2,0x1
    80001582:	4581                	li	a1,0
    80001584:	00000097          	auipc	ra,0x0
    80001588:	880080e7          	jalr	-1920(ra) # 80000e04 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000158c:	875a                	mv	a4,s6
    8000158e:	86a6                	mv	a3,s1
    80001590:	6605                	lui	a2,0x1
    80001592:	85ca                	mv	a1,s2
    80001594:	8556                	mv	a0,s5
    80001596:	00000097          	auipc	ra,0x0
    8000159a:	c3a080e7          	jalr	-966(ra) # 800011d0 <mappages>
    8000159e:	e90d                	bnez	a0,800015d0 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800015a0:	6785                	lui	a5,0x1
    800015a2:	993e                	add	s2,s2,a5
    800015a4:	fd4968e3          	bltu	s2,s4,80001574 <uvmalloc+0x32>
  return newsz;
    800015a8:	8552                	mv	a0,s4
    800015aa:	a809                	j	800015bc <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    800015ac:	864e                	mv	a2,s3
    800015ae:	85ca                	mv	a1,s2
    800015b0:	8556                	mv	a0,s5
    800015b2:	00000097          	auipc	ra,0x0
    800015b6:	f48080e7          	jalr	-184(ra) # 800014fa <uvmdealloc>
      return 0;
    800015ba:	4501                	li	a0,0
}
    800015bc:	70e2                	ld	ra,56(sp)
    800015be:	7442                	ld	s0,48(sp)
    800015c0:	74a2                	ld	s1,40(sp)
    800015c2:	7902                	ld	s2,32(sp)
    800015c4:	69e2                	ld	s3,24(sp)
    800015c6:	6a42                	ld	s4,16(sp)
    800015c8:	6aa2                	ld	s5,8(sp)
    800015ca:	6b02                	ld	s6,0(sp)
    800015cc:	6121                	addi	sp,sp,64
    800015ce:	8082                	ret
      kfree(mem);
    800015d0:	8526                	mv	a0,s1
    800015d2:	fffff097          	auipc	ra,0xfffff
    800015d6:	468080e7          	jalr	1128(ra) # 80000a3a <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800015da:	864e                	mv	a2,s3
    800015dc:	85ca                	mv	a1,s2
    800015de:	8556                	mv	a0,s5
    800015e0:	00000097          	auipc	ra,0x0
    800015e4:	f1a080e7          	jalr	-230(ra) # 800014fa <uvmdealloc>
      return 0;
    800015e8:	4501                	li	a0,0
    800015ea:	bfc9                	j	800015bc <uvmalloc+0x7a>
    return oldsz;
    800015ec:	852e                	mv	a0,a1
}
    800015ee:	8082                	ret
  return newsz;
    800015f0:	8532                	mv	a0,a2
    800015f2:	b7e9                	j	800015bc <uvmalloc+0x7a>

00000000800015f4 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800015f4:	7179                	addi	sp,sp,-48
    800015f6:	f406                	sd	ra,40(sp)
    800015f8:	f022                	sd	s0,32(sp)
    800015fa:	ec26                	sd	s1,24(sp)
    800015fc:	e84a                	sd	s2,16(sp)
    800015fe:	e44e                	sd	s3,8(sp)
    80001600:	e052                	sd	s4,0(sp)
    80001602:	1800                	addi	s0,sp,48
    80001604:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001606:	84aa                	mv	s1,a0
    80001608:	6905                	lui	s2,0x1
    8000160a:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000160c:	4985                	li	s3,1
    8000160e:	a829                	j	80001628 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001610:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    80001612:	00c79513          	slli	a0,a5,0xc
    80001616:	00000097          	auipc	ra,0x0
    8000161a:	fde080e7          	jalr	-34(ra) # 800015f4 <freewalk>
      pagetable[i] = 0;
    8000161e:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001622:	04a1                	addi	s1,s1,8
    80001624:	03248163          	beq	s1,s2,80001646 <freewalk+0x52>
    pte_t pte = pagetable[i];
    80001628:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000162a:	00f7f713          	andi	a4,a5,15
    8000162e:	ff3701e3          	beq	a4,s3,80001610 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001632:	8b85                	andi	a5,a5,1
    80001634:	d7fd                	beqz	a5,80001622 <freewalk+0x2e>
      panic("freewalk: leaf");
    80001636:	00007517          	auipc	a0,0x7
    8000163a:	b8250513          	addi	a0,a0,-1150 # 800081b8 <digits+0x168>
    8000163e:	fffff097          	auipc	ra,0xfffff
    80001642:	f02080e7          	jalr	-254(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    80001646:	8552                	mv	a0,s4
    80001648:	fffff097          	auipc	ra,0xfffff
    8000164c:	3f2080e7          	jalr	1010(ra) # 80000a3a <kfree>
}
    80001650:	70a2                	ld	ra,40(sp)
    80001652:	7402                	ld	s0,32(sp)
    80001654:	64e2                	ld	s1,24(sp)
    80001656:	6942                	ld	s2,16(sp)
    80001658:	69a2                	ld	s3,8(sp)
    8000165a:	6a02                	ld	s4,0(sp)
    8000165c:	6145                	addi	sp,sp,48
    8000165e:	8082                	ret

0000000080001660 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001660:	1101                	addi	sp,sp,-32
    80001662:	ec06                	sd	ra,24(sp)
    80001664:	e822                	sd	s0,16(sp)
    80001666:	e426                	sd	s1,8(sp)
    80001668:	1000                	addi	s0,sp,32
    8000166a:	84aa                	mv	s1,a0
  if(sz > 0)
    8000166c:	e999                	bnez	a1,80001682 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000166e:	8526                	mv	a0,s1
    80001670:	00000097          	auipc	ra,0x0
    80001674:	f84080e7          	jalr	-124(ra) # 800015f4 <freewalk>
}
    80001678:	60e2                	ld	ra,24(sp)
    8000167a:	6442                	ld	s0,16(sp)
    8000167c:	64a2                	ld	s1,8(sp)
    8000167e:	6105                	addi	sp,sp,32
    80001680:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001682:	6785                	lui	a5,0x1
    80001684:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001686:	95be                	add	a1,a1,a5
    80001688:	4685                	li	a3,1
    8000168a:	00c5d613          	srli	a2,a1,0xc
    8000168e:	4581                	li	a1,0
    80001690:	00000097          	auipc	ra,0x0
    80001694:	d06080e7          	jalr	-762(ra) # 80001396 <uvmunmap>
    80001698:	bfd9                	j	8000166e <uvmfree+0xe>

000000008000169a <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  //char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000169a:	c66d                	beqz	a2,80001784 <uvmcopy+0xea>
{
    8000169c:	7139                	addi	sp,sp,-64
    8000169e:	fc06                	sd	ra,56(sp)
    800016a0:	f822                	sd	s0,48(sp)
    800016a2:	f426                	sd	s1,40(sp)
    800016a4:	f04a                	sd	s2,32(sp)
    800016a6:	ec4e                	sd	s3,24(sp)
    800016a8:	e852                	sd	s4,16(sp)
    800016aa:	e456                	sd	s5,8(sp)
    800016ac:	e05a                	sd	s6,0(sp)
    800016ae:	0080                	addi	s0,sp,64
    800016b0:	8a2a                	mv	s4,a0
    800016b2:	8aae                	mv	s5,a1
    800016b4:	8b32                	mv	s6,a2
  for(i = 0; i < sz; i += PGSIZE){
    800016b6:	4901                	li	s2,0
    if((pte = walk(old, i, 0)) == 0)
    800016b8:	4601                	li	a2,0
    800016ba:	85ca                	mv	a1,s2
    800016bc:	8552                	mv	a0,s4
    800016be:	00000097          	auipc	ra,0x0
    800016c2:	a2a080e7          	jalr	-1494(ra) # 800010e8 <walk>
    800016c6:	c135                	beqz	a0,8000172a <uvmcopy+0x90>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800016c8:	6118                	ld	a4,0(a0)
    800016ca:	00177793          	andi	a5,a4,1
    800016ce:	c7b5                	beqz	a5,8000173a <uvmcopy+0xa0>
      panic("uvmcopy: page not present");

    pa = PTE2PA(*pte);
    800016d0:	00a75993          	srli	s3,a4,0xa
    800016d4:	09b2                	slli	s3,s3,0xc
    flags = PTE_FLAGS(*pte);
    // Added so that the pte write flag is disabled
    // This disables possibility to write to the page
    flags = flags & ~PTE_W;
    800016d6:	3fb77713          	andi	a4,a4,1019
    /* if((mem = kalloc()) == 0)
      goto err; */

    // memmove(mem, (char*)pa, PGSIZE);
    // printf("Mappages fysisk adresse uvmcopy: %d\n", pa);
    if(mappages(new, i, PGSIZE, pa, flags) != 0){
    800016da:	10076493          	ori	s1,a4,256
    800016de:	8726                	mv	a4,s1
    800016e0:	86ce                	mv	a3,s3
    800016e2:	6605                	lui	a2,0x1
    800016e4:	85ca                	mv	a1,s2
    800016e6:	8556                	mv	a0,s5
    800016e8:	00000097          	auipc	ra,0x0
    800016ec:	ae8080e7          	jalr	-1304(ra) # 800011d0 <mappages>
    800016f0:	ed29                	bnez	a0,8000174a <uvmcopy+0xb0>
      //kfree(mem);
      goto err;
    }

    increment_page_count(pa);
    800016f2:	854e                	mv	a0,s3
    800016f4:	fffff097          	auipc	ra,0xfffff
    800016f8:	306080e7          	jalr	774(ra) # 800009fa <increment_page_count>

    //Unmap and map old pagetable (didnt work)
    uvmunmap(old, i, 1, 0);
    800016fc:	4681                	li	a3,0
    800016fe:	4605                	li	a2,1
    80001700:	85ca                	mv	a1,s2
    80001702:	8552                	mv	a0,s4
    80001704:	00000097          	auipc	ra,0x0
    80001708:	c92080e7          	jalr	-878(ra) # 80001396 <uvmunmap>
    //mappages(old, i, PGSIZE, pa, flags);
    if(mappages(old, i, PGSIZE, pa, flags) != 0){
    8000170c:	8726                	mv	a4,s1
    8000170e:	86ce                	mv	a3,s3
    80001710:	6605                	lui	a2,0x1
    80001712:	85ca                	mv	a1,s2
    80001714:	8552                	mv	a0,s4
    80001716:	00000097          	auipc	ra,0x0
    8000171a:	aba080e7          	jalr	-1350(ra) # 800011d0 <mappages>
    8000171e:	e515                	bnez	a0,8000174a <uvmcopy+0xb0>
  for(i = 0; i < sz; i += PGSIZE){
    80001720:	6785                	lui	a5,0x1
    80001722:	993e                	add	s2,s2,a5
    80001724:	f9696ae3          	bltu	s2,s6,800016b8 <uvmcopy+0x1e>
    80001728:	a0a1                	j	80001770 <uvmcopy+0xd6>
      panic("uvmcopy: pte should exist");
    8000172a:	00007517          	auipc	a0,0x7
    8000172e:	a9e50513          	addi	a0,a0,-1378 # 800081c8 <digits+0x178>
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	e0e080e7          	jalr	-498(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    8000173a:	00007517          	auipc	a0,0x7
    8000173e:	aae50513          	addi	a0,a0,-1362 # 800081e8 <digits+0x198>
    80001742:	fffff097          	auipc	ra,0xfffff
    80001746:	dfe080e7          	jalr	-514(ra) # 80000540 <panic>

  }
  return 0;

 err:
  printf("%d", pa);
    8000174a:	85ce                	mv	a1,s3
    8000174c:	00007517          	auipc	a0,0x7
    80001750:	abc50513          	addi	a0,a0,-1348 # 80008208 <digits+0x1b8>
    80001754:	fffff097          	auipc	ra,0xfffff
    80001758:	e48080e7          	jalr	-440(ra) # 8000059c <printf>
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000175c:	4685                	li	a3,1
    8000175e:	00c95613          	srli	a2,s2,0xc
    80001762:	4581                	li	a1,0
    80001764:	8556                	mv	a0,s5
    80001766:	00000097          	auipc	ra,0x0
    8000176a:	c30080e7          	jalr	-976(ra) # 80001396 <uvmunmap>
  return -1;
    8000176e:	557d                	li	a0,-1
}
    80001770:	70e2                	ld	ra,56(sp)
    80001772:	7442                	ld	s0,48(sp)
    80001774:	74a2                	ld	s1,40(sp)
    80001776:	7902                	ld	s2,32(sp)
    80001778:	69e2                	ld	s3,24(sp)
    8000177a:	6a42                	ld	s4,16(sp)
    8000177c:	6aa2                	ld	s5,8(sp)
    8000177e:	6b02                	ld	s6,0(sp)
    80001780:	6121                	addi	sp,sp,64
    80001782:	8082                	ret
  return 0;
    80001784:	4501                	li	a0,0
}
    80001786:	8082                	ret

0000000080001788 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001788:	1141                	addi	sp,sp,-16
    8000178a:	e406                	sd	ra,8(sp)
    8000178c:	e022                	sd	s0,0(sp)
    8000178e:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001790:	4601                	li	a2,0
    80001792:	00000097          	auipc	ra,0x0
    80001796:	956080e7          	jalr	-1706(ra) # 800010e8 <walk>
  if(pte == 0)
    8000179a:	c901                	beqz	a0,800017aa <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000179c:	611c                	ld	a5,0(a0)
    8000179e:	9bbd                	andi	a5,a5,-17
    800017a0:	e11c                	sd	a5,0(a0)
}
    800017a2:	60a2                	ld	ra,8(sp)
    800017a4:	6402                	ld	s0,0(sp)
    800017a6:	0141                	addi	sp,sp,16
    800017a8:	8082                	ret
    panic("uvmclear");
    800017aa:	00007517          	auipc	a0,0x7
    800017ae:	a6650513          	addi	a0,a0,-1434 # 80008210 <digits+0x1c0>
    800017b2:	fffff097          	auipc	ra,0xfffff
    800017b6:	d8e080e7          	jalr	-626(ra) # 80000540 <panic>

00000000800017ba <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017ba:	c6bd                	beqz	a3,80001828 <copyout+0x6e>
{
    800017bc:	715d                	addi	sp,sp,-80
    800017be:	e486                	sd	ra,72(sp)
    800017c0:	e0a2                	sd	s0,64(sp)
    800017c2:	fc26                	sd	s1,56(sp)
    800017c4:	f84a                	sd	s2,48(sp)
    800017c6:	f44e                	sd	s3,40(sp)
    800017c8:	f052                	sd	s4,32(sp)
    800017ca:	ec56                	sd	s5,24(sp)
    800017cc:	e85a                	sd	s6,16(sp)
    800017ce:	e45e                	sd	s7,8(sp)
    800017d0:	e062                	sd	s8,0(sp)
    800017d2:	0880                	addi	s0,sp,80
    800017d4:	8b2a                	mv	s6,a0
    800017d6:	8c2e                	mv	s8,a1
    800017d8:	8a32                	mv	s4,a2
    800017da:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800017dc:	7bfd                	lui	s7,0xfffff


    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800017de:	6a85                	lui	s5,0x1
    800017e0:	a015                	j	80001804 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800017e2:	9562                	add	a0,a0,s8
    800017e4:	0004861b          	sext.w	a2,s1
    800017e8:	85d2                	mv	a1,s4
    800017ea:	41250533          	sub	a0,a0,s2
    800017ee:	fffff097          	auipc	ra,0xfffff
    800017f2:	672080e7          	jalr	1650(ra) # 80000e60 <memmove>

    len -= n;
    800017f6:	409989b3          	sub	s3,s3,s1
    src += n;
    800017fa:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800017fc:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001800:	02098263          	beqz	s3,80001824 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001804:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001808:	85ca                	mv	a1,s2
    8000180a:	855a                	mv	a0,s6
    8000180c:	00000097          	auipc	ra,0x0
    80001810:	982080e7          	jalr	-1662(ra) # 8000118e <walkaddr>
    if(pa0 == 0)
    80001814:	cd01                	beqz	a0,8000182c <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001816:	418904b3          	sub	s1,s2,s8
    8000181a:	94d6                	add	s1,s1,s5
    8000181c:	fc99f3e3          	bgeu	s3,s1,800017e2 <copyout+0x28>
    80001820:	84ce                	mv	s1,s3
    80001822:	b7c1                	j	800017e2 <copyout+0x28>
  }
  return 0;
    80001824:	4501                	li	a0,0
    80001826:	a021                	j	8000182e <copyout+0x74>
    80001828:	4501                	li	a0,0
}
    8000182a:	8082                	ret
      return -1;
    8000182c:	557d                	li	a0,-1
}
    8000182e:	60a6                	ld	ra,72(sp)
    80001830:	6406                	ld	s0,64(sp)
    80001832:	74e2                	ld	s1,56(sp)
    80001834:	7942                	ld	s2,48(sp)
    80001836:	79a2                	ld	s3,40(sp)
    80001838:	7a02                	ld	s4,32(sp)
    8000183a:	6ae2                	ld	s5,24(sp)
    8000183c:	6b42                	ld	s6,16(sp)
    8000183e:	6ba2                	ld	s7,8(sp)
    80001840:	6c02                	ld	s8,0(sp)
    80001842:	6161                	addi	sp,sp,80
    80001844:	8082                	ret

0000000080001846 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001846:	caa5                	beqz	a3,800018b6 <copyin+0x70>
{
    80001848:	715d                	addi	sp,sp,-80
    8000184a:	e486                	sd	ra,72(sp)
    8000184c:	e0a2                	sd	s0,64(sp)
    8000184e:	fc26                	sd	s1,56(sp)
    80001850:	f84a                	sd	s2,48(sp)
    80001852:	f44e                	sd	s3,40(sp)
    80001854:	f052                	sd	s4,32(sp)
    80001856:	ec56                	sd	s5,24(sp)
    80001858:	e85a                	sd	s6,16(sp)
    8000185a:	e45e                	sd	s7,8(sp)
    8000185c:	e062                	sd	s8,0(sp)
    8000185e:	0880                	addi	s0,sp,80
    80001860:	8b2a                	mv	s6,a0
    80001862:	8a2e                	mv	s4,a1
    80001864:	8c32                	mv	s8,a2
    80001866:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001868:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000186a:	6a85                	lui	s5,0x1
    8000186c:	a01d                	j	80001892 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000186e:	018505b3          	add	a1,a0,s8
    80001872:	0004861b          	sext.w	a2,s1
    80001876:	412585b3          	sub	a1,a1,s2
    8000187a:	8552                	mv	a0,s4
    8000187c:	fffff097          	auipc	ra,0xfffff
    80001880:	5e4080e7          	jalr	1508(ra) # 80000e60 <memmove>

    len -= n;
    80001884:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001888:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000188a:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000188e:	02098263          	beqz	s3,800018b2 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001892:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001896:	85ca                	mv	a1,s2
    80001898:	855a                	mv	a0,s6
    8000189a:	00000097          	auipc	ra,0x0
    8000189e:	8f4080e7          	jalr	-1804(ra) # 8000118e <walkaddr>
    if(pa0 == 0)
    800018a2:	cd01                	beqz	a0,800018ba <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    800018a4:	418904b3          	sub	s1,s2,s8
    800018a8:	94d6                	add	s1,s1,s5
    800018aa:	fc99f2e3          	bgeu	s3,s1,8000186e <copyin+0x28>
    800018ae:	84ce                	mv	s1,s3
    800018b0:	bf7d                	j	8000186e <copyin+0x28>
  }
  return 0;
    800018b2:	4501                	li	a0,0
    800018b4:	a021                	j	800018bc <copyin+0x76>
    800018b6:	4501                	li	a0,0
}
    800018b8:	8082                	ret
      return -1;
    800018ba:	557d                	li	a0,-1
}
    800018bc:	60a6                	ld	ra,72(sp)
    800018be:	6406                	ld	s0,64(sp)
    800018c0:	74e2                	ld	s1,56(sp)
    800018c2:	7942                	ld	s2,48(sp)
    800018c4:	79a2                	ld	s3,40(sp)
    800018c6:	7a02                	ld	s4,32(sp)
    800018c8:	6ae2                	ld	s5,24(sp)
    800018ca:	6b42                	ld	s6,16(sp)
    800018cc:	6ba2                	ld	s7,8(sp)
    800018ce:	6c02                	ld	s8,0(sp)
    800018d0:	6161                	addi	sp,sp,80
    800018d2:	8082                	ret

00000000800018d4 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800018d4:	c2dd                	beqz	a3,8000197a <copyinstr+0xa6>
{
    800018d6:	715d                	addi	sp,sp,-80
    800018d8:	e486                	sd	ra,72(sp)
    800018da:	e0a2                	sd	s0,64(sp)
    800018dc:	fc26                	sd	s1,56(sp)
    800018de:	f84a                	sd	s2,48(sp)
    800018e0:	f44e                	sd	s3,40(sp)
    800018e2:	f052                	sd	s4,32(sp)
    800018e4:	ec56                	sd	s5,24(sp)
    800018e6:	e85a                	sd	s6,16(sp)
    800018e8:	e45e                	sd	s7,8(sp)
    800018ea:	0880                	addi	s0,sp,80
    800018ec:	8a2a                	mv	s4,a0
    800018ee:	8b2e                	mv	s6,a1
    800018f0:	8bb2                	mv	s7,a2
    800018f2:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800018f4:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800018f6:	6985                	lui	s3,0x1
    800018f8:	a02d                	j	80001922 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800018fa:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800018fe:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001900:	37fd                	addiw	a5,a5,-1
    80001902:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001906:	60a6                	ld	ra,72(sp)
    80001908:	6406                	ld	s0,64(sp)
    8000190a:	74e2                	ld	s1,56(sp)
    8000190c:	7942                	ld	s2,48(sp)
    8000190e:	79a2                	ld	s3,40(sp)
    80001910:	7a02                	ld	s4,32(sp)
    80001912:	6ae2                	ld	s5,24(sp)
    80001914:	6b42                	ld	s6,16(sp)
    80001916:	6ba2                	ld	s7,8(sp)
    80001918:	6161                	addi	sp,sp,80
    8000191a:	8082                	ret
    srcva = va0 + PGSIZE;
    8000191c:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001920:	c8a9                	beqz	s1,80001972 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    80001922:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001926:	85ca                	mv	a1,s2
    80001928:	8552                	mv	a0,s4
    8000192a:	00000097          	auipc	ra,0x0
    8000192e:	864080e7          	jalr	-1948(ra) # 8000118e <walkaddr>
    if(pa0 == 0)
    80001932:	c131                	beqz	a0,80001976 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    80001934:	417906b3          	sub	a3,s2,s7
    80001938:	96ce                	add	a3,a3,s3
    8000193a:	00d4f363          	bgeu	s1,a3,80001940 <copyinstr+0x6c>
    8000193e:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001940:	955e                	add	a0,a0,s7
    80001942:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001946:	daf9                	beqz	a3,8000191c <copyinstr+0x48>
    80001948:	87da                	mv	a5,s6
      if(*p == '\0'){
    8000194a:	41650633          	sub	a2,a0,s6
    8000194e:	fff48593          	addi	a1,s1,-1
    80001952:	95da                	add	a1,a1,s6
    while(n > 0){
    80001954:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001956:	00f60733          	add	a4,a2,a5
    8000195a:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7fb9d0c0>
    8000195e:	df51                	beqz	a4,800018fa <copyinstr+0x26>
        *dst = *p;
    80001960:	00e78023          	sb	a4,0(a5)
      --max;
    80001964:	40f584b3          	sub	s1,a1,a5
      dst++;
    80001968:	0785                	addi	a5,a5,1
    while(n > 0){
    8000196a:	fed796e3          	bne	a5,a3,80001956 <copyinstr+0x82>
      dst++;
    8000196e:	8b3e                	mv	s6,a5
    80001970:	b775                	j	8000191c <copyinstr+0x48>
    80001972:	4781                	li	a5,0
    80001974:	b771                	j	80001900 <copyinstr+0x2c>
      return -1;
    80001976:	557d                	li	a0,-1
    80001978:	b779                	j	80001906 <copyinstr+0x32>
  int got_null = 0;
    8000197a:	4781                	li	a5,0
  if(got_null){
    8000197c:	37fd                	addiw	a5,a5,-1
    8000197e:	0007851b          	sext.w	a0,a5
}
    80001982:	8082                	ret

0000000080001984 <rr_scheduler>:
        (*sched_pointer)();
    }
}

void rr_scheduler(void)
{
    80001984:	715d                	addi	sp,sp,-80
    80001986:	e486                	sd	ra,72(sp)
    80001988:	e0a2                	sd	s0,64(sp)
    8000198a:	fc26                	sd	s1,56(sp)
    8000198c:	f84a                	sd	s2,48(sp)
    8000198e:	f44e                	sd	s3,40(sp)
    80001990:	f052                	sd	s4,32(sp)
    80001992:	ec56                	sd	s5,24(sp)
    80001994:	e85a                	sd	s6,16(sp)
    80001996:	e45e                	sd	s7,8(sp)
    80001998:	e062                	sd	s8,0(sp)
    8000199a:	0880                	addi	s0,sp,80
  asm volatile("mv %0, tp" : "=r" (x) );
    8000199c:	8792                	mv	a5,tp
    int id = r_tp();
    8000199e:	2781                	sext.w	a5,a5
    struct proc *p;
    struct cpu *c = mycpu();

    c->proc = 0;
    800019a0:	0044fa97          	auipc	s5,0x44f
    800019a4:	390a8a93          	addi	s5,s5,912 # 80450d30 <cpus>
    800019a8:	00779713          	slli	a4,a5,0x7
    800019ac:	00ea86b3          	add	a3,s5,a4
    800019b0:	0006b023          	sd	zero,0(a3) # fffffffffffff000 <end+0xffffffff7fb9d0c0>
                // Switch to chosen process.  It is the process's job
                // to release its lock and then reacquire it
                // before jumping back to us.
                p->state = RUNNING;
                c->proc = p;
                swtch(&c->context, &p->context);
    800019b4:	0721                	addi	a4,a4,8
    800019b6:	9aba                	add	s5,s5,a4
                c->proc = p;
    800019b8:	8936                	mv	s2,a3
                // check if we are still the right scheduler (or if schedset changed)
                if (sched_pointer != &rr_scheduler)
    800019ba:	00007c17          	auipc	s8,0x7
    800019be:	02ec0c13          	addi	s8,s8,46 # 800089e8 <sched_pointer>
    800019c2:	00000b97          	auipc	s7,0x0
    800019c6:	fc2b8b93          	addi	s7,s7,-62 # 80001984 <rr_scheduler>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800019ca:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800019ce:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800019d2:	10079073          	csrw	sstatus,a5
        for (p = proc; p < &proc[NPROC]; p++)
    800019d6:	0044f497          	auipc	s1,0x44f
    800019da:	78a48493          	addi	s1,s1,1930 # 80451160 <proc>
            if (p->state == RUNNABLE)
    800019de:	498d                	li	s3,3
                p->state = RUNNING;
    800019e0:	4b11                	li	s6,4
        for (p = proc; p < &proc[NPROC]; p++)
    800019e2:	00455a17          	auipc	s4,0x455
    800019e6:	17ea0a13          	addi	s4,s4,382 # 80456b60 <tickslock>
    800019ea:	a81d                	j	80001a20 <rr_scheduler+0x9c>
                {
                    release(&p->lock);
    800019ec:	8526                	mv	a0,s1
    800019ee:	fffff097          	auipc	ra,0xfffff
    800019f2:	3ce080e7          	jalr	974(ra) # 80000dbc <release>
                c->proc = 0;
            }
            release(&p->lock);
        }
    }
}
    800019f6:	60a6                	ld	ra,72(sp)
    800019f8:	6406                	ld	s0,64(sp)
    800019fa:	74e2                	ld	s1,56(sp)
    800019fc:	7942                	ld	s2,48(sp)
    800019fe:	79a2                	ld	s3,40(sp)
    80001a00:	7a02                	ld	s4,32(sp)
    80001a02:	6ae2                	ld	s5,24(sp)
    80001a04:	6b42                	ld	s6,16(sp)
    80001a06:	6ba2                	ld	s7,8(sp)
    80001a08:	6c02                	ld	s8,0(sp)
    80001a0a:	6161                	addi	sp,sp,80
    80001a0c:	8082                	ret
            release(&p->lock);
    80001a0e:	8526                	mv	a0,s1
    80001a10:	fffff097          	auipc	ra,0xfffff
    80001a14:	3ac080e7          	jalr	940(ra) # 80000dbc <release>
        for (p = proc; p < &proc[NPROC]; p++)
    80001a18:	16848493          	addi	s1,s1,360
    80001a1c:	fb4487e3          	beq	s1,s4,800019ca <rr_scheduler+0x46>
            acquire(&p->lock);
    80001a20:	8526                	mv	a0,s1
    80001a22:	fffff097          	auipc	ra,0xfffff
    80001a26:	2e6080e7          	jalr	742(ra) # 80000d08 <acquire>
            if (p->state == RUNNABLE)
    80001a2a:	4c9c                	lw	a5,24(s1)
    80001a2c:	ff3791e3          	bne	a5,s3,80001a0e <rr_scheduler+0x8a>
                p->state = RUNNING;
    80001a30:	0164ac23          	sw	s6,24(s1)
                c->proc = p;
    80001a34:	00993023          	sd	s1,0(s2) # 1000 <_entry-0x7ffff000>
                swtch(&c->context, &p->context);
    80001a38:	06048593          	addi	a1,s1,96
    80001a3c:	8556                	mv	a0,s5
    80001a3e:	00001097          	auipc	ra,0x1
    80001a42:	fc0080e7          	jalr	-64(ra) # 800029fe <swtch>
                if (sched_pointer != &rr_scheduler)
    80001a46:	000c3783          	ld	a5,0(s8)
    80001a4a:	fb7791e3          	bne	a5,s7,800019ec <rr_scheduler+0x68>
                c->proc = 0;
    80001a4e:	00093023          	sd	zero,0(s2)
    80001a52:	bf75                	j	80001a0e <rr_scheduler+0x8a>

0000000080001a54 <proc_mapstacks>:
{
    80001a54:	7139                	addi	sp,sp,-64
    80001a56:	fc06                	sd	ra,56(sp)
    80001a58:	f822                	sd	s0,48(sp)
    80001a5a:	f426                	sd	s1,40(sp)
    80001a5c:	f04a                	sd	s2,32(sp)
    80001a5e:	ec4e                	sd	s3,24(sp)
    80001a60:	e852                	sd	s4,16(sp)
    80001a62:	e456                	sd	s5,8(sp)
    80001a64:	e05a                	sd	s6,0(sp)
    80001a66:	0080                	addi	s0,sp,64
    80001a68:	89aa                	mv	s3,a0
    for (p = proc; p < &proc[NPROC]; p++)
    80001a6a:	0044f497          	auipc	s1,0x44f
    80001a6e:	6f648493          	addi	s1,s1,1782 # 80451160 <proc>
        uint64 va = KSTACK((int)(p - proc));
    80001a72:	8b26                	mv	s6,s1
    80001a74:	00006a97          	auipc	s5,0x6
    80001a78:	59ca8a93          	addi	s5,s5,1436 # 80008010 <__func__.1+0x8>
    80001a7c:	04000937          	lui	s2,0x4000
    80001a80:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001a82:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001a84:	00455a17          	auipc	s4,0x455
    80001a88:	0dca0a13          	addi	s4,s4,220 # 80456b60 <tickslock>
        char *pa = kalloc();
    80001a8c:	fffff097          	auipc	ra,0xfffff
    80001a90:	140080e7          	jalr	320(ra) # 80000bcc <kalloc>
    80001a94:	862a                	mv	a2,a0
        if (pa == 0)
    80001a96:	c131                	beqz	a0,80001ada <proc_mapstacks+0x86>
        uint64 va = KSTACK((int)(p - proc));
    80001a98:	416485b3          	sub	a1,s1,s6
    80001a9c:	858d                	srai	a1,a1,0x3
    80001a9e:	000ab783          	ld	a5,0(s5)
    80001aa2:	02f585b3          	mul	a1,a1,a5
    80001aa6:	2585                	addiw	a1,a1,1
    80001aa8:	00d5959b          	slliw	a1,a1,0xd
        kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001aac:	4719                	li	a4,6
    80001aae:	6685                	lui	a3,0x1
    80001ab0:	40b905b3          	sub	a1,s2,a1
    80001ab4:	854e                	mv	a0,s3
    80001ab6:	fffff097          	auipc	ra,0xfffff
    80001aba:	7ba080e7          	jalr	1978(ra) # 80001270 <kvmmap>
    for (p = proc; p < &proc[NPROC]; p++)
    80001abe:	16848493          	addi	s1,s1,360
    80001ac2:	fd4495e3          	bne	s1,s4,80001a8c <proc_mapstacks+0x38>
}
    80001ac6:	70e2                	ld	ra,56(sp)
    80001ac8:	7442                	ld	s0,48(sp)
    80001aca:	74a2                	ld	s1,40(sp)
    80001acc:	7902                	ld	s2,32(sp)
    80001ace:	69e2                	ld	s3,24(sp)
    80001ad0:	6a42                	ld	s4,16(sp)
    80001ad2:	6aa2                	ld	s5,8(sp)
    80001ad4:	6b02                	ld	s6,0(sp)
    80001ad6:	6121                	addi	sp,sp,64
    80001ad8:	8082                	ret
            panic("kalloc");
    80001ada:	00006517          	auipc	a0,0x6
    80001ade:	74650513          	addi	a0,a0,1862 # 80008220 <digits+0x1d0>
    80001ae2:	fffff097          	auipc	ra,0xfffff
    80001ae6:	a5e080e7          	jalr	-1442(ra) # 80000540 <panic>

0000000080001aea <procinit>:
{
    80001aea:	7139                	addi	sp,sp,-64
    80001aec:	fc06                	sd	ra,56(sp)
    80001aee:	f822                	sd	s0,48(sp)
    80001af0:	f426                	sd	s1,40(sp)
    80001af2:	f04a                	sd	s2,32(sp)
    80001af4:	ec4e                	sd	s3,24(sp)
    80001af6:	e852                	sd	s4,16(sp)
    80001af8:	e456                	sd	s5,8(sp)
    80001afa:	e05a                	sd	s6,0(sp)
    80001afc:	0080                	addi	s0,sp,64
    initlock(&pid_lock, "nextpid");
    80001afe:	00006597          	auipc	a1,0x6
    80001b02:	72a58593          	addi	a1,a1,1834 # 80008228 <digits+0x1d8>
    80001b06:	0044f517          	auipc	a0,0x44f
    80001b0a:	62a50513          	addi	a0,a0,1578 # 80451130 <pid_lock>
    80001b0e:	fffff097          	auipc	ra,0xfffff
    80001b12:	16a080e7          	jalr	362(ra) # 80000c78 <initlock>
    initlock(&wait_lock, "wait_lock");
    80001b16:	00006597          	auipc	a1,0x6
    80001b1a:	71a58593          	addi	a1,a1,1818 # 80008230 <digits+0x1e0>
    80001b1e:	0044f517          	auipc	a0,0x44f
    80001b22:	62a50513          	addi	a0,a0,1578 # 80451148 <wait_lock>
    80001b26:	fffff097          	auipc	ra,0xfffff
    80001b2a:	152080e7          	jalr	338(ra) # 80000c78 <initlock>
    for (p = proc; p < &proc[NPROC]; p++)
    80001b2e:	0044f497          	auipc	s1,0x44f
    80001b32:	63248493          	addi	s1,s1,1586 # 80451160 <proc>
        initlock(&p->lock, "proc");
    80001b36:	00006b17          	auipc	s6,0x6
    80001b3a:	70ab0b13          	addi	s6,s6,1802 # 80008240 <digits+0x1f0>
        p->kstack = KSTACK((int)(p - proc));
    80001b3e:	8aa6                	mv	s5,s1
    80001b40:	00006a17          	auipc	s4,0x6
    80001b44:	4d0a0a13          	addi	s4,s4,1232 # 80008010 <__func__.1+0x8>
    80001b48:	04000937          	lui	s2,0x4000
    80001b4c:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001b4e:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001b50:	00455997          	auipc	s3,0x455
    80001b54:	01098993          	addi	s3,s3,16 # 80456b60 <tickslock>
        initlock(&p->lock, "proc");
    80001b58:	85da                	mv	a1,s6
    80001b5a:	8526                	mv	a0,s1
    80001b5c:	fffff097          	auipc	ra,0xfffff
    80001b60:	11c080e7          	jalr	284(ra) # 80000c78 <initlock>
        p->state = UNUSED;
    80001b64:	0004ac23          	sw	zero,24(s1)
        p->kstack = KSTACK((int)(p - proc));
    80001b68:	415487b3          	sub	a5,s1,s5
    80001b6c:	878d                	srai	a5,a5,0x3
    80001b6e:	000a3703          	ld	a4,0(s4)
    80001b72:	02e787b3          	mul	a5,a5,a4
    80001b76:	2785                	addiw	a5,a5,1
    80001b78:	00d7979b          	slliw	a5,a5,0xd
    80001b7c:	40f907b3          	sub	a5,s2,a5
    80001b80:	e0bc                	sd	a5,64(s1)
    for (p = proc; p < &proc[NPROC]; p++)
    80001b82:	16848493          	addi	s1,s1,360
    80001b86:	fd3499e3          	bne	s1,s3,80001b58 <procinit+0x6e>
}
    80001b8a:	70e2                	ld	ra,56(sp)
    80001b8c:	7442                	ld	s0,48(sp)
    80001b8e:	74a2                	ld	s1,40(sp)
    80001b90:	7902                	ld	s2,32(sp)
    80001b92:	69e2                	ld	s3,24(sp)
    80001b94:	6a42                	ld	s4,16(sp)
    80001b96:	6aa2                	ld	s5,8(sp)
    80001b98:	6b02                	ld	s6,0(sp)
    80001b9a:	6121                	addi	sp,sp,64
    80001b9c:	8082                	ret

0000000080001b9e <copy_array>:
{
    80001b9e:	1141                	addi	sp,sp,-16
    80001ba0:	e422                	sd	s0,8(sp)
    80001ba2:	0800                	addi	s0,sp,16
    for (int i = 0; i < len; i++)
    80001ba4:	02c05163          	blez	a2,80001bc6 <copy_array+0x28>
    80001ba8:	87aa                	mv	a5,a0
    80001baa:	0505                	addi	a0,a0,1
    80001bac:	367d                	addiw	a2,a2,-1 # fff <_entry-0x7ffff001>
    80001bae:	1602                	slli	a2,a2,0x20
    80001bb0:	9201                	srli	a2,a2,0x20
    80001bb2:	00c506b3          	add	a3,a0,a2
        dst[i] = src[i];
    80001bb6:	0007c703          	lbu	a4,0(a5)
    80001bba:	00e58023          	sb	a4,0(a1)
    for (int i = 0; i < len; i++)
    80001bbe:	0785                	addi	a5,a5,1
    80001bc0:	0585                	addi	a1,a1,1
    80001bc2:	fed79ae3          	bne	a5,a3,80001bb6 <copy_array+0x18>
}
    80001bc6:	6422                	ld	s0,8(sp)
    80001bc8:	0141                	addi	sp,sp,16
    80001bca:	8082                	ret

0000000080001bcc <cpuid>:
{
    80001bcc:	1141                	addi	sp,sp,-16
    80001bce:	e422                	sd	s0,8(sp)
    80001bd0:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001bd2:	8512                	mv	a0,tp
}
    80001bd4:	2501                	sext.w	a0,a0
    80001bd6:	6422                	ld	s0,8(sp)
    80001bd8:	0141                	addi	sp,sp,16
    80001bda:	8082                	ret

0000000080001bdc <mycpu>:
{
    80001bdc:	1141                	addi	sp,sp,-16
    80001bde:	e422                	sd	s0,8(sp)
    80001be0:	0800                	addi	s0,sp,16
    80001be2:	8792                	mv	a5,tp
    struct cpu *c = &cpus[id];
    80001be4:	2781                	sext.w	a5,a5
    80001be6:	079e                	slli	a5,a5,0x7
}
    80001be8:	0044f517          	auipc	a0,0x44f
    80001bec:	14850513          	addi	a0,a0,328 # 80450d30 <cpus>
    80001bf0:	953e                	add	a0,a0,a5
    80001bf2:	6422                	ld	s0,8(sp)
    80001bf4:	0141                	addi	sp,sp,16
    80001bf6:	8082                	ret

0000000080001bf8 <myproc>:
{
    80001bf8:	1101                	addi	sp,sp,-32
    80001bfa:	ec06                	sd	ra,24(sp)
    80001bfc:	e822                	sd	s0,16(sp)
    80001bfe:	e426                	sd	s1,8(sp)
    80001c00:	1000                	addi	s0,sp,32
    push_off();
    80001c02:	fffff097          	auipc	ra,0xfffff
    80001c06:	0ba080e7          	jalr	186(ra) # 80000cbc <push_off>
    80001c0a:	8792                	mv	a5,tp
    struct proc *p = c->proc;
    80001c0c:	2781                	sext.w	a5,a5
    80001c0e:	079e                	slli	a5,a5,0x7
    80001c10:	0044f717          	auipc	a4,0x44f
    80001c14:	12070713          	addi	a4,a4,288 # 80450d30 <cpus>
    80001c18:	97ba                	add	a5,a5,a4
    80001c1a:	6384                	ld	s1,0(a5)
    pop_off();
    80001c1c:	fffff097          	auipc	ra,0xfffff
    80001c20:	140080e7          	jalr	320(ra) # 80000d5c <pop_off>
}
    80001c24:	8526                	mv	a0,s1
    80001c26:	60e2                	ld	ra,24(sp)
    80001c28:	6442                	ld	s0,16(sp)
    80001c2a:	64a2                	ld	s1,8(sp)
    80001c2c:	6105                	addi	sp,sp,32
    80001c2e:	8082                	ret

0000000080001c30 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001c30:	1141                	addi	sp,sp,-16
    80001c32:	e406                	sd	ra,8(sp)
    80001c34:	e022                	sd	s0,0(sp)
    80001c36:	0800                	addi	s0,sp,16
    static int first = 1;

    // Still holding p->lock from scheduler.
    release(&myproc()->lock);
    80001c38:	00000097          	auipc	ra,0x0
    80001c3c:	fc0080e7          	jalr	-64(ra) # 80001bf8 <myproc>
    80001c40:	fffff097          	auipc	ra,0xfffff
    80001c44:	17c080e7          	jalr	380(ra) # 80000dbc <release>

    if (first)
    80001c48:	00007797          	auipc	a5,0x7
    80001c4c:	d987a783          	lw	a5,-616(a5) # 800089e0 <first.1>
    80001c50:	eb89                	bnez	a5,80001c62 <forkret+0x32>
        // be run from main().
        first = 0;
        fsinit(ROOTDEV);
    }

    usertrapret();
    80001c52:	00001097          	auipc	ra,0x1
    80001c56:	e56080e7          	jalr	-426(ra) # 80002aa8 <usertrapret>
}
    80001c5a:	60a2                	ld	ra,8(sp)
    80001c5c:	6402                	ld	s0,0(sp)
    80001c5e:	0141                	addi	sp,sp,16
    80001c60:	8082                	ret
        first = 0;
    80001c62:	00007797          	auipc	a5,0x7
    80001c66:	d607af23          	sw	zero,-642(a5) # 800089e0 <first.1>
        fsinit(ROOTDEV);
    80001c6a:	4505                	li	a0,1
    80001c6c:	00002097          	auipc	ra,0x2
    80001c70:	e00080e7          	jalr	-512(ra) # 80003a6c <fsinit>
    80001c74:	bff9                	j	80001c52 <forkret+0x22>

0000000080001c76 <allocpid>:
{
    80001c76:	1101                	addi	sp,sp,-32
    80001c78:	ec06                	sd	ra,24(sp)
    80001c7a:	e822                	sd	s0,16(sp)
    80001c7c:	e426                	sd	s1,8(sp)
    80001c7e:	e04a                	sd	s2,0(sp)
    80001c80:	1000                	addi	s0,sp,32
    acquire(&pid_lock);
    80001c82:	0044f917          	auipc	s2,0x44f
    80001c86:	4ae90913          	addi	s2,s2,1198 # 80451130 <pid_lock>
    80001c8a:	854a                	mv	a0,s2
    80001c8c:	fffff097          	auipc	ra,0xfffff
    80001c90:	07c080e7          	jalr	124(ra) # 80000d08 <acquire>
    pid = nextpid;
    80001c94:	00007797          	auipc	a5,0x7
    80001c98:	d5c78793          	addi	a5,a5,-676 # 800089f0 <nextpid>
    80001c9c:	4384                	lw	s1,0(a5)
    nextpid = nextpid + 1;
    80001c9e:	0014871b          	addiw	a4,s1,1
    80001ca2:	c398                	sw	a4,0(a5)
    release(&pid_lock);
    80001ca4:	854a                	mv	a0,s2
    80001ca6:	fffff097          	auipc	ra,0xfffff
    80001caa:	116080e7          	jalr	278(ra) # 80000dbc <release>
}
    80001cae:	8526                	mv	a0,s1
    80001cb0:	60e2                	ld	ra,24(sp)
    80001cb2:	6442                	ld	s0,16(sp)
    80001cb4:	64a2                	ld	s1,8(sp)
    80001cb6:	6902                	ld	s2,0(sp)
    80001cb8:	6105                	addi	sp,sp,32
    80001cba:	8082                	ret

0000000080001cbc <proc_pagetable>:
{
    80001cbc:	1101                	addi	sp,sp,-32
    80001cbe:	ec06                	sd	ra,24(sp)
    80001cc0:	e822                	sd	s0,16(sp)
    80001cc2:	e426                	sd	s1,8(sp)
    80001cc4:	e04a                	sd	s2,0(sp)
    80001cc6:	1000                	addi	s0,sp,32
    80001cc8:	892a                	mv	s2,a0
    pagetable = uvmcreate();
    80001cca:	fffff097          	auipc	ra,0xfffff
    80001cce:	790080e7          	jalr	1936(ra) # 8000145a <uvmcreate>
    80001cd2:	84aa                	mv	s1,a0
    if (pagetable == 0)
    80001cd4:	c121                	beqz	a0,80001d14 <proc_pagetable+0x58>
    if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001cd6:	4729                	li	a4,10
    80001cd8:	00005697          	auipc	a3,0x5
    80001cdc:	32868693          	addi	a3,a3,808 # 80007000 <_trampoline>
    80001ce0:	6605                	lui	a2,0x1
    80001ce2:	040005b7          	lui	a1,0x4000
    80001ce6:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001ce8:	05b2                	slli	a1,a1,0xc
    80001cea:	fffff097          	auipc	ra,0xfffff
    80001cee:	4e6080e7          	jalr	1254(ra) # 800011d0 <mappages>
    80001cf2:	02054863          	bltz	a0,80001d22 <proc_pagetable+0x66>
    if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001cf6:	4719                	li	a4,6
    80001cf8:	05893683          	ld	a3,88(s2)
    80001cfc:	6605                	lui	a2,0x1
    80001cfe:	020005b7          	lui	a1,0x2000
    80001d02:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001d04:	05b6                	slli	a1,a1,0xd
    80001d06:	8526                	mv	a0,s1
    80001d08:	fffff097          	auipc	ra,0xfffff
    80001d0c:	4c8080e7          	jalr	1224(ra) # 800011d0 <mappages>
    80001d10:	02054163          	bltz	a0,80001d32 <proc_pagetable+0x76>
}
    80001d14:	8526                	mv	a0,s1
    80001d16:	60e2                	ld	ra,24(sp)
    80001d18:	6442                	ld	s0,16(sp)
    80001d1a:	64a2                	ld	s1,8(sp)
    80001d1c:	6902                	ld	s2,0(sp)
    80001d1e:	6105                	addi	sp,sp,32
    80001d20:	8082                	ret
        uvmfree(pagetable, 0);
    80001d22:	4581                	li	a1,0
    80001d24:	8526                	mv	a0,s1
    80001d26:	00000097          	auipc	ra,0x0
    80001d2a:	93a080e7          	jalr	-1734(ra) # 80001660 <uvmfree>
        return 0;
    80001d2e:	4481                	li	s1,0
    80001d30:	b7d5                	j	80001d14 <proc_pagetable+0x58>
        uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d32:	4681                	li	a3,0
    80001d34:	4605                	li	a2,1
    80001d36:	040005b7          	lui	a1,0x4000
    80001d3a:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001d3c:	05b2                	slli	a1,a1,0xc
    80001d3e:	8526                	mv	a0,s1
    80001d40:	fffff097          	auipc	ra,0xfffff
    80001d44:	656080e7          	jalr	1622(ra) # 80001396 <uvmunmap>
        uvmfree(pagetable, 0);
    80001d48:	4581                	li	a1,0
    80001d4a:	8526                	mv	a0,s1
    80001d4c:	00000097          	auipc	ra,0x0
    80001d50:	914080e7          	jalr	-1772(ra) # 80001660 <uvmfree>
        return 0;
    80001d54:	4481                	li	s1,0
    80001d56:	bf7d                	j	80001d14 <proc_pagetable+0x58>

0000000080001d58 <proc_freepagetable>:
{
    80001d58:	1101                	addi	sp,sp,-32
    80001d5a:	ec06                	sd	ra,24(sp)
    80001d5c:	e822                	sd	s0,16(sp)
    80001d5e:	e426                	sd	s1,8(sp)
    80001d60:	e04a                	sd	s2,0(sp)
    80001d62:	1000                	addi	s0,sp,32
    80001d64:	84aa                	mv	s1,a0
    80001d66:	892e                	mv	s2,a1
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d68:	4681                	li	a3,0
    80001d6a:	4605                	li	a2,1
    80001d6c:	040005b7          	lui	a1,0x4000
    80001d70:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001d72:	05b2                	slli	a1,a1,0xc
    80001d74:	fffff097          	auipc	ra,0xfffff
    80001d78:	622080e7          	jalr	1570(ra) # 80001396 <uvmunmap>
    uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001d7c:	4681                	li	a3,0
    80001d7e:	4605                	li	a2,1
    80001d80:	020005b7          	lui	a1,0x2000
    80001d84:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001d86:	05b6                	slli	a1,a1,0xd
    80001d88:	8526                	mv	a0,s1
    80001d8a:	fffff097          	auipc	ra,0xfffff
    80001d8e:	60c080e7          	jalr	1548(ra) # 80001396 <uvmunmap>
    uvmfree(pagetable, sz);
    80001d92:	85ca                	mv	a1,s2
    80001d94:	8526                	mv	a0,s1
    80001d96:	00000097          	auipc	ra,0x0
    80001d9a:	8ca080e7          	jalr	-1846(ra) # 80001660 <uvmfree>
}
    80001d9e:	60e2                	ld	ra,24(sp)
    80001da0:	6442                	ld	s0,16(sp)
    80001da2:	64a2                	ld	s1,8(sp)
    80001da4:	6902                	ld	s2,0(sp)
    80001da6:	6105                	addi	sp,sp,32
    80001da8:	8082                	ret

0000000080001daa <freeproc>:
{
    80001daa:	1101                	addi	sp,sp,-32
    80001dac:	ec06                	sd	ra,24(sp)
    80001dae:	e822                	sd	s0,16(sp)
    80001db0:	e426                	sd	s1,8(sp)
    80001db2:	1000                	addi	s0,sp,32
    80001db4:	84aa                	mv	s1,a0
    if (p->trapframe)
    80001db6:	6d28                	ld	a0,88(a0)
    80001db8:	c509                	beqz	a0,80001dc2 <freeproc+0x18>
        kfree((void *)p->trapframe);
    80001dba:	fffff097          	auipc	ra,0xfffff
    80001dbe:	c80080e7          	jalr	-896(ra) # 80000a3a <kfree>
    p->trapframe = 0;
    80001dc2:	0404bc23          	sd	zero,88(s1)
    if (p->pagetable)
    80001dc6:	68a8                	ld	a0,80(s1)
    80001dc8:	c511                	beqz	a0,80001dd4 <freeproc+0x2a>
        proc_freepagetable(p->pagetable, p->sz);
    80001dca:	64ac                	ld	a1,72(s1)
    80001dcc:	00000097          	auipc	ra,0x0
    80001dd0:	f8c080e7          	jalr	-116(ra) # 80001d58 <proc_freepagetable>
    p->pagetable = 0;
    80001dd4:	0404b823          	sd	zero,80(s1)
    p->sz = 0;
    80001dd8:	0404b423          	sd	zero,72(s1)
    p->pid = 0;
    80001ddc:	0204a823          	sw	zero,48(s1)
    p->parent = 0;
    80001de0:	0204bc23          	sd	zero,56(s1)
    p->name[0] = 0;
    80001de4:	14048c23          	sb	zero,344(s1)
    p->chan = 0;
    80001de8:	0204b023          	sd	zero,32(s1)
    p->killed = 0;
    80001dec:	0204a423          	sw	zero,40(s1)
    p->xstate = 0;
    80001df0:	0204a623          	sw	zero,44(s1)
    p->state = UNUSED;
    80001df4:	0004ac23          	sw	zero,24(s1)
}
    80001df8:	60e2                	ld	ra,24(sp)
    80001dfa:	6442                	ld	s0,16(sp)
    80001dfc:	64a2                	ld	s1,8(sp)
    80001dfe:	6105                	addi	sp,sp,32
    80001e00:	8082                	ret

0000000080001e02 <allocproc>:
{
    80001e02:	1101                	addi	sp,sp,-32
    80001e04:	ec06                	sd	ra,24(sp)
    80001e06:	e822                	sd	s0,16(sp)
    80001e08:	e426                	sd	s1,8(sp)
    80001e0a:	e04a                	sd	s2,0(sp)
    80001e0c:	1000                	addi	s0,sp,32
    for (p = proc; p < &proc[NPROC]; p++)
    80001e0e:	0044f497          	auipc	s1,0x44f
    80001e12:	35248493          	addi	s1,s1,850 # 80451160 <proc>
    80001e16:	00455917          	auipc	s2,0x455
    80001e1a:	d4a90913          	addi	s2,s2,-694 # 80456b60 <tickslock>
        acquire(&p->lock);
    80001e1e:	8526                	mv	a0,s1
    80001e20:	fffff097          	auipc	ra,0xfffff
    80001e24:	ee8080e7          	jalr	-280(ra) # 80000d08 <acquire>
        if (p->state == UNUSED)
    80001e28:	4c9c                	lw	a5,24(s1)
    80001e2a:	cf81                	beqz	a5,80001e42 <allocproc+0x40>
            release(&p->lock);
    80001e2c:	8526                	mv	a0,s1
    80001e2e:	fffff097          	auipc	ra,0xfffff
    80001e32:	f8e080e7          	jalr	-114(ra) # 80000dbc <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001e36:	16848493          	addi	s1,s1,360
    80001e3a:	ff2492e3          	bne	s1,s2,80001e1e <allocproc+0x1c>
    return 0;
    80001e3e:	4481                	li	s1,0
    80001e40:	a889                	j	80001e92 <allocproc+0x90>
    p->pid = allocpid();
    80001e42:	00000097          	auipc	ra,0x0
    80001e46:	e34080e7          	jalr	-460(ra) # 80001c76 <allocpid>
    80001e4a:	d888                	sw	a0,48(s1)
    p->state = USED;
    80001e4c:	4785                	li	a5,1
    80001e4e:	cc9c                	sw	a5,24(s1)
    if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001e50:	fffff097          	auipc	ra,0xfffff
    80001e54:	d7c080e7          	jalr	-644(ra) # 80000bcc <kalloc>
    80001e58:	892a                	mv	s2,a0
    80001e5a:	eca8                	sd	a0,88(s1)
    80001e5c:	c131                	beqz	a0,80001ea0 <allocproc+0x9e>
    p->pagetable = proc_pagetable(p);
    80001e5e:	8526                	mv	a0,s1
    80001e60:	00000097          	auipc	ra,0x0
    80001e64:	e5c080e7          	jalr	-420(ra) # 80001cbc <proc_pagetable>
    80001e68:	892a                	mv	s2,a0
    80001e6a:	e8a8                	sd	a0,80(s1)
    if (p->pagetable == 0)
    80001e6c:	c531                	beqz	a0,80001eb8 <allocproc+0xb6>
    memset(&p->context, 0, sizeof(p->context));
    80001e6e:	07000613          	li	a2,112
    80001e72:	4581                	li	a1,0
    80001e74:	06048513          	addi	a0,s1,96
    80001e78:	fffff097          	auipc	ra,0xfffff
    80001e7c:	f8c080e7          	jalr	-116(ra) # 80000e04 <memset>
    p->context.ra = (uint64)forkret;
    80001e80:	00000797          	auipc	a5,0x0
    80001e84:	db078793          	addi	a5,a5,-592 # 80001c30 <forkret>
    80001e88:	f0bc                	sd	a5,96(s1)
    p->context.sp = p->kstack + PGSIZE;
    80001e8a:	60bc                	ld	a5,64(s1)
    80001e8c:	6705                	lui	a4,0x1
    80001e8e:	97ba                	add	a5,a5,a4
    80001e90:	f4bc                	sd	a5,104(s1)
}
    80001e92:	8526                	mv	a0,s1
    80001e94:	60e2                	ld	ra,24(sp)
    80001e96:	6442                	ld	s0,16(sp)
    80001e98:	64a2                	ld	s1,8(sp)
    80001e9a:	6902                	ld	s2,0(sp)
    80001e9c:	6105                	addi	sp,sp,32
    80001e9e:	8082                	ret
        freeproc(p);
    80001ea0:	8526                	mv	a0,s1
    80001ea2:	00000097          	auipc	ra,0x0
    80001ea6:	f08080e7          	jalr	-248(ra) # 80001daa <freeproc>
        release(&p->lock);
    80001eaa:	8526                	mv	a0,s1
    80001eac:	fffff097          	auipc	ra,0xfffff
    80001eb0:	f10080e7          	jalr	-240(ra) # 80000dbc <release>
        return 0;
    80001eb4:	84ca                	mv	s1,s2
    80001eb6:	bff1                	j	80001e92 <allocproc+0x90>
        freeproc(p);
    80001eb8:	8526                	mv	a0,s1
    80001eba:	00000097          	auipc	ra,0x0
    80001ebe:	ef0080e7          	jalr	-272(ra) # 80001daa <freeproc>
        release(&p->lock);
    80001ec2:	8526                	mv	a0,s1
    80001ec4:	fffff097          	auipc	ra,0xfffff
    80001ec8:	ef8080e7          	jalr	-264(ra) # 80000dbc <release>
        return 0;
    80001ecc:	84ca                	mv	s1,s2
    80001ece:	b7d1                	j	80001e92 <allocproc+0x90>

0000000080001ed0 <userinit>:
{
    80001ed0:	1101                	addi	sp,sp,-32
    80001ed2:	ec06                	sd	ra,24(sp)
    80001ed4:	e822                	sd	s0,16(sp)
    80001ed6:	e426                	sd	s1,8(sp)
    80001ed8:	1000                	addi	s0,sp,32
    p = allocproc();
    80001eda:	00000097          	auipc	ra,0x0
    80001ede:	f28080e7          	jalr	-216(ra) # 80001e02 <allocproc>
    80001ee2:	84aa                	mv	s1,a0
    initproc = p;
    80001ee4:	00007797          	auipc	a5,0x7
    80001ee8:	bca7ba23          	sd	a0,-1068(a5) # 80008ab8 <initproc>
    uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001eec:	03400613          	li	a2,52
    80001ef0:	00007597          	auipc	a1,0x7
    80001ef4:	b1058593          	addi	a1,a1,-1264 # 80008a00 <initcode>
    80001ef8:	6928                	ld	a0,80(a0)
    80001efa:	fffff097          	auipc	ra,0xfffff
    80001efe:	58e080e7          	jalr	1422(ra) # 80001488 <uvmfirst>
    p->sz = PGSIZE;
    80001f02:	6785                	lui	a5,0x1
    80001f04:	e4bc                	sd	a5,72(s1)
    p->trapframe->epc = 0;     // user program counter
    80001f06:	6cb8                	ld	a4,88(s1)
    80001f08:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
    p->trapframe->sp = PGSIZE; // user stack pointer
    80001f0c:	6cb8                	ld	a4,88(s1)
    80001f0e:	fb1c                	sd	a5,48(a4)
    safestrcpy(p->name, "initcode", sizeof(p->name));
    80001f10:	4641                	li	a2,16
    80001f12:	00006597          	auipc	a1,0x6
    80001f16:	33658593          	addi	a1,a1,822 # 80008248 <digits+0x1f8>
    80001f1a:	15848513          	addi	a0,s1,344
    80001f1e:	fffff097          	auipc	ra,0xfffff
    80001f22:	030080e7          	jalr	48(ra) # 80000f4e <safestrcpy>
    p->cwd = namei("/");
    80001f26:	00006517          	auipc	a0,0x6
    80001f2a:	33250513          	addi	a0,a0,818 # 80008258 <digits+0x208>
    80001f2e:	00002097          	auipc	ra,0x2
    80001f32:	568080e7          	jalr	1384(ra) # 80004496 <namei>
    80001f36:	14a4b823          	sd	a0,336(s1)
    p->state = RUNNABLE;
    80001f3a:	478d                	li	a5,3
    80001f3c:	cc9c                	sw	a5,24(s1)
    release(&p->lock);
    80001f3e:	8526                	mv	a0,s1
    80001f40:	fffff097          	auipc	ra,0xfffff
    80001f44:	e7c080e7          	jalr	-388(ra) # 80000dbc <release>
}
    80001f48:	60e2                	ld	ra,24(sp)
    80001f4a:	6442                	ld	s0,16(sp)
    80001f4c:	64a2                	ld	s1,8(sp)
    80001f4e:	6105                	addi	sp,sp,32
    80001f50:	8082                	ret

0000000080001f52 <growproc>:
{
    80001f52:	1101                	addi	sp,sp,-32
    80001f54:	ec06                	sd	ra,24(sp)
    80001f56:	e822                	sd	s0,16(sp)
    80001f58:	e426                	sd	s1,8(sp)
    80001f5a:	e04a                	sd	s2,0(sp)
    80001f5c:	1000                	addi	s0,sp,32
    80001f5e:	892a                	mv	s2,a0
    struct proc *p = myproc();
    80001f60:	00000097          	auipc	ra,0x0
    80001f64:	c98080e7          	jalr	-872(ra) # 80001bf8 <myproc>
    80001f68:	84aa                	mv	s1,a0
    sz = p->sz;
    80001f6a:	652c                	ld	a1,72(a0)
    if (n > 0)
    80001f6c:	01204c63          	bgtz	s2,80001f84 <growproc+0x32>
    else if (n < 0)
    80001f70:	02094663          	bltz	s2,80001f9c <growproc+0x4a>
    p->sz = sz;
    80001f74:	e4ac                	sd	a1,72(s1)
    return 0;
    80001f76:	4501                	li	a0,0
}
    80001f78:	60e2                	ld	ra,24(sp)
    80001f7a:	6442                	ld	s0,16(sp)
    80001f7c:	64a2                	ld	s1,8(sp)
    80001f7e:	6902                	ld	s2,0(sp)
    80001f80:	6105                	addi	sp,sp,32
    80001f82:	8082                	ret
        if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001f84:	4691                	li	a3,4
    80001f86:	00b90633          	add	a2,s2,a1
    80001f8a:	6928                	ld	a0,80(a0)
    80001f8c:	fffff097          	auipc	ra,0xfffff
    80001f90:	5b6080e7          	jalr	1462(ra) # 80001542 <uvmalloc>
    80001f94:	85aa                	mv	a1,a0
    80001f96:	fd79                	bnez	a0,80001f74 <growproc+0x22>
            return -1;
    80001f98:	557d                	li	a0,-1
    80001f9a:	bff9                	j	80001f78 <growproc+0x26>
        sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001f9c:	00b90633          	add	a2,s2,a1
    80001fa0:	6928                	ld	a0,80(a0)
    80001fa2:	fffff097          	auipc	ra,0xfffff
    80001fa6:	558080e7          	jalr	1368(ra) # 800014fa <uvmdealloc>
    80001faa:	85aa                	mv	a1,a0
    80001fac:	b7e1                	j	80001f74 <growproc+0x22>

0000000080001fae <ps>:
{
    80001fae:	715d                	addi	sp,sp,-80
    80001fb0:	e486                	sd	ra,72(sp)
    80001fb2:	e0a2                	sd	s0,64(sp)
    80001fb4:	fc26                	sd	s1,56(sp)
    80001fb6:	f84a                	sd	s2,48(sp)
    80001fb8:	f44e                	sd	s3,40(sp)
    80001fba:	f052                	sd	s4,32(sp)
    80001fbc:	ec56                	sd	s5,24(sp)
    80001fbe:	e85a                	sd	s6,16(sp)
    80001fc0:	e45e                	sd	s7,8(sp)
    80001fc2:	e062                	sd	s8,0(sp)
    80001fc4:	0880                	addi	s0,sp,80
    80001fc6:	84aa                	mv	s1,a0
    80001fc8:	8bae                	mv	s7,a1
    void *result = (void *)myproc()->sz;
    80001fca:	00000097          	auipc	ra,0x0
    80001fce:	c2e080e7          	jalr	-978(ra) # 80001bf8 <myproc>
        return result;
    80001fd2:	4901                	li	s2,0
    if (count == 0)
    80001fd4:	0c0b8563          	beqz	s7,8000209e <ps+0xf0>
    void *result = (void *)myproc()->sz;
    80001fd8:	04853b03          	ld	s6,72(a0)
    if (growproc(count * sizeof(struct user_proc)) < 0)
    80001fdc:	003b951b          	slliw	a0,s7,0x3
    80001fe0:	0175053b          	addw	a0,a0,s7
    80001fe4:	0025151b          	slliw	a0,a0,0x2
    80001fe8:	00000097          	auipc	ra,0x0
    80001fec:	f6a080e7          	jalr	-150(ra) # 80001f52 <growproc>
    80001ff0:	12054f63          	bltz	a0,8000212e <ps+0x180>
    struct user_proc loc_result[count];
    80001ff4:	003b9a13          	slli	s4,s7,0x3
    80001ff8:	9a5e                	add	s4,s4,s7
    80001ffa:	0a0a                	slli	s4,s4,0x2
    80001ffc:	00fa0793          	addi	a5,s4,15
    80002000:	8391                	srli	a5,a5,0x4
    80002002:	0792                	slli	a5,a5,0x4
    80002004:	40f10133          	sub	sp,sp,a5
    80002008:	8a8a                	mv	s5,sp
    struct proc *p = proc + start;
    8000200a:	16800793          	li	a5,360
    8000200e:	02f484b3          	mul	s1,s1,a5
    80002012:	0044f797          	auipc	a5,0x44f
    80002016:	14e78793          	addi	a5,a5,334 # 80451160 <proc>
    8000201a:	94be                	add	s1,s1,a5
    if (p >= &proc[NPROC])
    8000201c:	00455797          	auipc	a5,0x455
    80002020:	b4478793          	addi	a5,a5,-1212 # 80456b60 <tickslock>
        return result;
    80002024:	4901                	li	s2,0
    if (p >= &proc[NPROC])
    80002026:	06f4fc63          	bgeu	s1,a5,8000209e <ps+0xf0>
    acquire(&wait_lock);
    8000202a:	0044f517          	auipc	a0,0x44f
    8000202e:	11e50513          	addi	a0,a0,286 # 80451148 <wait_lock>
    80002032:	fffff097          	auipc	ra,0xfffff
    80002036:	cd6080e7          	jalr	-810(ra) # 80000d08 <acquire>
        if (localCount == count)
    8000203a:	014a8913          	addi	s2,s5,20
    uint8 localCount = 0;
    8000203e:	4981                	li	s3,0
    for (; p < &proc[NPROC]; p++)
    80002040:	00455c17          	auipc	s8,0x455
    80002044:	b20c0c13          	addi	s8,s8,-1248 # 80456b60 <tickslock>
    80002048:	a851                	j	800020dc <ps+0x12e>
            loc_result[localCount].state = UNUSED;
    8000204a:	00399793          	slli	a5,s3,0x3
    8000204e:	97ce                	add	a5,a5,s3
    80002050:	078a                	slli	a5,a5,0x2
    80002052:	97d6                	add	a5,a5,s5
    80002054:	0007a023          	sw	zero,0(a5)
            release(&p->lock);
    80002058:	8526                	mv	a0,s1
    8000205a:	fffff097          	auipc	ra,0xfffff
    8000205e:	d62080e7          	jalr	-670(ra) # 80000dbc <release>
    release(&wait_lock);
    80002062:	0044f517          	auipc	a0,0x44f
    80002066:	0e650513          	addi	a0,a0,230 # 80451148 <wait_lock>
    8000206a:	fffff097          	auipc	ra,0xfffff
    8000206e:	d52080e7          	jalr	-686(ra) # 80000dbc <release>
    if (localCount < count)
    80002072:	0179f963          	bgeu	s3,s7,80002084 <ps+0xd6>
        loc_result[localCount].state = UNUSED; // if we reach the end of processes
    80002076:	00399793          	slli	a5,s3,0x3
    8000207a:	97ce                	add	a5,a5,s3
    8000207c:	078a                	slli	a5,a5,0x2
    8000207e:	97d6                	add	a5,a5,s5
    80002080:	0007a023          	sw	zero,0(a5)
    void *result = (void *)myproc()->sz;
    80002084:	895a                	mv	s2,s6
    copyout(myproc()->pagetable, (uint64)result, (void *)loc_result, count * sizeof(struct user_proc));
    80002086:	00000097          	auipc	ra,0x0
    8000208a:	b72080e7          	jalr	-1166(ra) # 80001bf8 <myproc>
    8000208e:	86d2                	mv	a3,s4
    80002090:	8656                	mv	a2,s5
    80002092:	85da                	mv	a1,s6
    80002094:	6928                	ld	a0,80(a0)
    80002096:	fffff097          	auipc	ra,0xfffff
    8000209a:	724080e7          	jalr	1828(ra) # 800017ba <copyout>
}
    8000209e:	854a                	mv	a0,s2
    800020a0:	fb040113          	addi	sp,s0,-80
    800020a4:	60a6                	ld	ra,72(sp)
    800020a6:	6406                	ld	s0,64(sp)
    800020a8:	74e2                	ld	s1,56(sp)
    800020aa:	7942                	ld	s2,48(sp)
    800020ac:	79a2                	ld	s3,40(sp)
    800020ae:	7a02                	ld	s4,32(sp)
    800020b0:	6ae2                	ld	s5,24(sp)
    800020b2:	6b42                	ld	s6,16(sp)
    800020b4:	6ba2                	ld	s7,8(sp)
    800020b6:	6c02                	ld	s8,0(sp)
    800020b8:	6161                	addi	sp,sp,80
    800020ba:	8082                	ret
        release(&p->lock);
    800020bc:	8526                	mv	a0,s1
    800020be:	fffff097          	auipc	ra,0xfffff
    800020c2:	cfe080e7          	jalr	-770(ra) # 80000dbc <release>
        localCount++;
    800020c6:	2985                	addiw	s3,s3,1
    800020c8:	0ff9f993          	zext.b	s3,s3
    for (; p < &proc[NPROC]; p++)
    800020cc:	16848493          	addi	s1,s1,360
    800020d0:	f984f9e3          	bgeu	s1,s8,80002062 <ps+0xb4>
        if (localCount == count)
    800020d4:	02490913          	addi	s2,s2,36
    800020d8:	053b8d63          	beq	s7,s3,80002132 <ps+0x184>
        acquire(&p->lock);
    800020dc:	8526                	mv	a0,s1
    800020de:	fffff097          	auipc	ra,0xfffff
    800020e2:	c2a080e7          	jalr	-982(ra) # 80000d08 <acquire>
        if (p->state == UNUSED)
    800020e6:	4c9c                	lw	a5,24(s1)
    800020e8:	d3ad                	beqz	a5,8000204a <ps+0x9c>
        loc_result[localCount].state = p->state;
    800020ea:	fef92623          	sw	a5,-20(s2)
        loc_result[localCount].killed = p->killed;
    800020ee:	549c                	lw	a5,40(s1)
    800020f0:	fef92823          	sw	a5,-16(s2)
        loc_result[localCount].xstate = p->xstate;
    800020f4:	54dc                	lw	a5,44(s1)
    800020f6:	fef92a23          	sw	a5,-12(s2)
        loc_result[localCount].pid = p->pid;
    800020fa:	589c                	lw	a5,48(s1)
    800020fc:	fef92c23          	sw	a5,-8(s2)
        copy_array(p->name, loc_result[localCount].name, 16);
    80002100:	4641                	li	a2,16
    80002102:	85ca                	mv	a1,s2
    80002104:	15848513          	addi	a0,s1,344
    80002108:	00000097          	auipc	ra,0x0
    8000210c:	a96080e7          	jalr	-1386(ra) # 80001b9e <copy_array>
        if (p->parent != 0) // init
    80002110:	7c88                	ld	a0,56(s1)
    80002112:	d54d                	beqz	a0,800020bc <ps+0x10e>
            acquire(&p->parent->lock);
    80002114:	fffff097          	auipc	ra,0xfffff
    80002118:	bf4080e7          	jalr	-1036(ra) # 80000d08 <acquire>
            loc_result[localCount].parent_id = p->parent->pid;
    8000211c:	7c88                	ld	a0,56(s1)
    8000211e:	591c                	lw	a5,48(a0)
    80002120:	fef92e23          	sw	a5,-4(s2)
            release(&p->parent->lock);
    80002124:	fffff097          	auipc	ra,0xfffff
    80002128:	c98080e7          	jalr	-872(ra) # 80000dbc <release>
    8000212c:	bf41                	j	800020bc <ps+0x10e>
        return result;
    8000212e:	4901                	li	s2,0
    80002130:	b7bd                	j	8000209e <ps+0xf0>
    release(&wait_lock);
    80002132:	0044f517          	auipc	a0,0x44f
    80002136:	01650513          	addi	a0,a0,22 # 80451148 <wait_lock>
    8000213a:	fffff097          	auipc	ra,0xfffff
    8000213e:	c82080e7          	jalr	-894(ra) # 80000dbc <release>
    if (localCount < count)
    80002142:	b789                	j	80002084 <ps+0xd6>

0000000080002144 <fork>:
{
    80002144:	7139                	addi	sp,sp,-64
    80002146:	fc06                	sd	ra,56(sp)
    80002148:	f822                	sd	s0,48(sp)
    8000214a:	f426                	sd	s1,40(sp)
    8000214c:	f04a                	sd	s2,32(sp)
    8000214e:	ec4e                	sd	s3,24(sp)
    80002150:	e852                	sd	s4,16(sp)
    80002152:	e456                	sd	s5,8(sp)
    80002154:	0080                	addi	s0,sp,64
    struct proc *p = myproc();
    80002156:	00000097          	auipc	ra,0x0
    8000215a:	aa2080e7          	jalr	-1374(ra) # 80001bf8 <myproc>
    8000215e:	8aaa                	mv	s5,a0
    if ((np = allocproc()) == 0)
    80002160:	00000097          	auipc	ra,0x0
    80002164:	ca2080e7          	jalr	-862(ra) # 80001e02 <allocproc>
    80002168:	12050563          	beqz	a0,80002292 <fork+0x14e>
    8000216c:	8a2a                	mv	s4,a0
    printf("Hallo\n");
    8000216e:	00006517          	auipc	a0,0x6
    80002172:	0f250513          	addi	a0,a0,242 # 80008260 <digits+0x210>
    80002176:	ffffe097          	auipc	ra,0xffffe
    8000217a:	426080e7          	jalr	1062(ra) # 8000059c <printf>
    if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    8000217e:	048ab603          	ld	a2,72(s5)
    80002182:	050a3583          	ld	a1,80(s4)
    80002186:	050ab503          	ld	a0,80(s5)
    8000218a:	fffff097          	auipc	ra,0xfffff
    8000218e:	510080e7          	jalr	1296(ra) # 8000169a <uvmcopy>
    80002192:	04054863          	bltz	a0,800021e2 <fork+0x9e>
    np->sz = p->sz;
    80002196:	048ab783          	ld	a5,72(s5)
    8000219a:	04fa3423          	sd	a5,72(s4)
    *(np->trapframe) = *(p->trapframe);
    8000219e:	058ab683          	ld	a3,88(s5)
    800021a2:	87b6                	mv	a5,a3
    800021a4:	058a3703          	ld	a4,88(s4)
    800021a8:	12068693          	addi	a3,a3,288
    800021ac:	0007b803          	ld	a6,0(a5)
    800021b0:	6788                	ld	a0,8(a5)
    800021b2:	6b8c                	ld	a1,16(a5)
    800021b4:	6f90                	ld	a2,24(a5)
    800021b6:	01073023          	sd	a6,0(a4)
    800021ba:	e708                	sd	a0,8(a4)
    800021bc:	eb0c                	sd	a1,16(a4)
    800021be:	ef10                	sd	a2,24(a4)
    800021c0:	02078793          	addi	a5,a5,32
    800021c4:	02070713          	addi	a4,a4,32
    800021c8:	fed792e3          	bne	a5,a3,800021ac <fork+0x68>
    np->trapframe->a0 = 0;
    800021cc:	058a3783          	ld	a5,88(s4)
    800021d0:	0607b823          	sd	zero,112(a5)
    for (i = 0; i < NOFILE; i++)
    800021d4:	0d0a8493          	addi	s1,s5,208
    800021d8:	0d0a0913          	addi	s2,s4,208
    800021dc:	150a8993          	addi	s3,s5,336
    800021e0:	a00d                	j	80002202 <fork+0xbe>
        freeproc(np);
    800021e2:	8552                	mv	a0,s4
    800021e4:	00000097          	auipc	ra,0x0
    800021e8:	bc6080e7          	jalr	-1082(ra) # 80001daa <freeproc>
        release(&np->lock);
    800021ec:	8552                	mv	a0,s4
    800021ee:	fffff097          	auipc	ra,0xfffff
    800021f2:	bce080e7          	jalr	-1074(ra) # 80000dbc <release>
        return -1;
    800021f6:	597d                	li	s2,-1
    800021f8:	a059                	j	8000227e <fork+0x13a>
    for (i = 0; i < NOFILE; i++)
    800021fa:	04a1                	addi	s1,s1,8
    800021fc:	0921                	addi	s2,s2,8
    800021fe:	01348b63          	beq	s1,s3,80002214 <fork+0xd0>
        if (p->ofile[i])
    80002202:	6088                	ld	a0,0(s1)
    80002204:	d97d                	beqz	a0,800021fa <fork+0xb6>
            np->ofile[i] = filedup(p->ofile[i]);
    80002206:	00003097          	auipc	ra,0x3
    8000220a:	926080e7          	jalr	-1754(ra) # 80004b2c <filedup>
    8000220e:	00a93023          	sd	a0,0(s2)
    80002212:	b7e5                	j	800021fa <fork+0xb6>
    np->cwd = idup(p->cwd);
    80002214:	150ab503          	ld	a0,336(s5)
    80002218:	00002097          	auipc	ra,0x2
    8000221c:	a94080e7          	jalr	-1388(ra) # 80003cac <idup>
    80002220:	14aa3823          	sd	a0,336(s4)
    safestrcpy(np->name, p->name, sizeof(p->name));
    80002224:	4641                	li	a2,16
    80002226:	158a8593          	addi	a1,s5,344
    8000222a:	158a0513          	addi	a0,s4,344
    8000222e:	fffff097          	auipc	ra,0xfffff
    80002232:	d20080e7          	jalr	-736(ra) # 80000f4e <safestrcpy>
    pid = np->pid;
    80002236:	030a2903          	lw	s2,48(s4)
    release(&np->lock);
    8000223a:	8552                	mv	a0,s4
    8000223c:	fffff097          	auipc	ra,0xfffff
    80002240:	b80080e7          	jalr	-1152(ra) # 80000dbc <release>
    acquire(&wait_lock);
    80002244:	0044f497          	auipc	s1,0x44f
    80002248:	f0448493          	addi	s1,s1,-252 # 80451148 <wait_lock>
    8000224c:	8526                	mv	a0,s1
    8000224e:	fffff097          	auipc	ra,0xfffff
    80002252:	aba080e7          	jalr	-1350(ra) # 80000d08 <acquire>
    np->parent = p;
    80002256:	035a3c23          	sd	s5,56(s4)
    release(&wait_lock);
    8000225a:	8526                	mv	a0,s1
    8000225c:	fffff097          	auipc	ra,0xfffff
    80002260:	b60080e7          	jalr	-1184(ra) # 80000dbc <release>
    acquire(&np->lock);
    80002264:	8552                	mv	a0,s4
    80002266:	fffff097          	auipc	ra,0xfffff
    8000226a:	aa2080e7          	jalr	-1374(ra) # 80000d08 <acquire>
    np->state = RUNNABLE;
    8000226e:	478d                	li	a5,3
    80002270:	00fa2c23          	sw	a5,24(s4)
    release(&np->lock);
    80002274:	8552                	mv	a0,s4
    80002276:	fffff097          	auipc	ra,0xfffff
    8000227a:	b46080e7          	jalr	-1210(ra) # 80000dbc <release>
}
    8000227e:	854a                	mv	a0,s2
    80002280:	70e2                	ld	ra,56(sp)
    80002282:	7442                	ld	s0,48(sp)
    80002284:	74a2                	ld	s1,40(sp)
    80002286:	7902                	ld	s2,32(sp)
    80002288:	69e2                	ld	s3,24(sp)
    8000228a:	6a42                	ld	s4,16(sp)
    8000228c:	6aa2                	ld	s5,8(sp)
    8000228e:	6121                	addi	sp,sp,64
    80002290:	8082                	ret
        return -1;
    80002292:	597d                	li	s2,-1
    80002294:	b7ed                	j	8000227e <fork+0x13a>

0000000080002296 <scheduler>:
{
    80002296:	1101                	addi	sp,sp,-32
    80002298:	ec06                	sd	ra,24(sp)
    8000229a:	e822                	sd	s0,16(sp)
    8000229c:	e426                	sd	s1,8(sp)
    8000229e:	1000                	addi	s0,sp,32
        (*sched_pointer)();
    800022a0:	00006497          	auipc	s1,0x6
    800022a4:	74848493          	addi	s1,s1,1864 # 800089e8 <sched_pointer>
    800022a8:	609c                	ld	a5,0(s1)
    800022aa:	9782                	jalr	a5
    while (1)
    800022ac:	bff5                	j	800022a8 <scheduler+0x12>

00000000800022ae <sched>:
{
    800022ae:	7179                	addi	sp,sp,-48
    800022b0:	f406                	sd	ra,40(sp)
    800022b2:	f022                	sd	s0,32(sp)
    800022b4:	ec26                	sd	s1,24(sp)
    800022b6:	e84a                	sd	s2,16(sp)
    800022b8:	e44e                	sd	s3,8(sp)
    800022ba:	1800                	addi	s0,sp,48
    struct proc *p = myproc();
    800022bc:	00000097          	auipc	ra,0x0
    800022c0:	93c080e7          	jalr	-1732(ra) # 80001bf8 <myproc>
    800022c4:	84aa                	mv	s1,a0
    if (!holding(&p->lock))
    800022c6:	fffff097          	auipc	ra,0xfffff
    800022ca:	9c8080e7          	jalr	-1592(ra) # 80000c8e <holding>
    800022ce:	c53d                	beqz	a0,8000233c <sched+0x8e>
    800022d0:	8792                	mv	a5,tp
    if (mycpu()->noff != 1)
    800022d2:	2781                	sext.w	a5,a5
    800022d4:	079e                	slli	a5,a5,0x7
    800022d6:	0044f717          	auipc	a4,0x44f
    800022da:	a5a70713          	addi	a4,a4,-1446 # 80450d30 <cpus>
    800022de:	97ba                	add	a5,a5,a4
    800022e0:	5fb8                	lw	a4,120(a5)
    800022e2:	4785                	li	a5,1
    800022e4:	06f71463          	bne	a4,a5,8000234c <sched+0x9e>
    if (p->state == RUNNING)
    800022e8:	4c98                	lw	a4,24(s1)
    800022ea:	4791                	li	a5,4
    800022ec:	06f70863          	beq	a4,a5,8000235c <sched+0xae>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022f0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800022f4:	8b89                	andi	a5,a5,2
    if (intr_get())
    800022f6:	ebbd                	bnez	a5,8000236c <sched+0xbe>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022f8:	8792                	mv	a5,tp
    intena = mycpu()->intena;
    800022fa:	0044f917          	auipc	s2,0x44f
    800022fe:	a3690913          	addi	s2,s2,-1482 # 80450d30 <cpus>
    80002302:	2781                	sext.w	a5,a5
    80002304:	079e                	slli	a5,a5,0x7
    80002306:	97ca                	add	a5,a5,s2
    80002308:	07c7a983          	lw	s3,124(a5)
    8000230c:	8592                	mv	a1,tp
    swtch(&p->context, &mycpu()->context);
    8000230e:	2581                	sext.w	a1,a1
    80002310:	059e                	slli	a1,a1,0x7
    80002312:	05a1                	addi	a1,a1,8
    80002314:	95ca                	add	a1,a1,s2
    80002316:	06048513          	addi	a0,s1,96
    8000231a:	00000097          	auipc	ra,0x0
    8000231e:	6e4080e7          	jalr	1764(ra) # 800029fe <swtch>
    80002322:	8792                	mv	a5,tp
    mycpu()->intena = intena;
    80002324:	2781                	sext.w	a5,a5
    80002326:	079e                	slli	a5,a5,0x7
    80002328:	993e                	add	s2,s2,a5
    8000232a:	07392e23          	sw	s3,124(s2)
}
    8000232e:	70a2                	ld	ra,40(sp)
    80002330:	7402                	ld	s0,32(sp)
    80002332:	64e2                	ld	s1,24(sp)
    80002334:	6942                	ld	s2,16(sp)
    80002336:	69a2                	ld	s3,8(sp)
    80002338:	6145                	addi	sp,sp,48
    8000233a:	8082                	ret
        panic("sched p->lock");
    8000233c:	00006517          	auipc	a0,0x6
    80002340:	f2c50513          	addi	a0,a0,-212 # 80008268 <digits+0x218>
    80002344:	ffffe097          	auipc	ra,0xffffe
    80002348:	1fc080e7          	jalr	508(ra) # 80000540 <panic>
        panic("sched locks");
    8000234c:	00006517          	auipc	a0,0x6
    80002350:	f2c50513          	addi	a0,a0,-212 # 80008278 <digits+0x228>
    80002354:	ffffe097          	auipc	ra,0xffffe
    80002358:	1ec080e7          	jalr	492(ra) # 80000540 <panic>
        panic("sched running");
    8000235c:	00006517          	auipc	a0,0x6
    80002360:	f2c50513          	addi	a0,a0,-212 # 80008288 <digits+0x238>
    80002364:	ffffe097          	auipc	ra,0xffffe
    80002368:	1dc080e7          	jalr	476(ra) # 80000540 <panic>
        panic("sched interruptible");
    8000236c:	00006517          	auipc	a0,0x6
    80002370:	f2c50513          	addi	a0,a0,-212 # 80008298 <digits+0x248>
    80002374:	ffffe097          	auipc	ra,0xffffe
    80002378:	1cc080e7          	jalr	460(ra) # 80000540 <panic>

000000008000237c <yield>:
{
    8000237c:	1101                	addi	sp,sp,-32
    8000237e:	ec06                	sd	ra,24(sp)
    80002380:	e822                	sd	s0,16(sp)
    80002382:	e426                	sd	s1,8(sp)
    80002384:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    80002386:	00000097          	auipc	ra,0x0
    8000238a:	872080e7          	jalr	-1934(ra) # 80001bf8 <myproc>
    8000238e:	84aa                	mv	s1,a0
    acquire(&p->lock);
    80002390:	fffff097          	auipc	ra,0xfffff
    80002394:	978080e7          	jalr	-1672(ra) # 80000d08 <acquire>
    p->state = RUNNABLE;
    80002398:	478d                	li	a5,3
    8000239a:	cc9c                	sw	a5,24(s1)
    sched();
    8000239c:	00000097          	auipc	ra,0x0
    800023a0:	f12080e7          	jalr	-238(ra) # 800022ae <sched>
    release(&p->lock);
    800023a4:	8526                	mv	a0,s1
    800023a6:	fffff097          	auipc	ra,0xfffff
    800023aa:	a16080e7          	jalr	-1514(ra) # 80000dbc <release>
}
    800023ae:	60e2                	ld	ra,24(sp)
    800023b0:	6442                	ld	s0,16(sp)
    800023b2:	64a2                	ld	s1,8(sp)
    800023b4:	6105                	addi	sp,sp,32
    800023b6:	8082                	ret

00000000800023b8 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800023b8:	7179                	addi	sp,sp,-48
    800023ba:	f406                	sd	ra,40(sp)
    800023bc:	f022                	sd	s0,32(sp)
    800023be:	ec26                	sd	s1,24(sp)
    800023c0:	e84a                	sd	s2,16(sp)
    800023c2:	e44e                	sd	s3,8(sp)
    800023c4:	1800                	addi	s0,sp,48
    800023c6:	89aa                	mv	s3,a0
    800023c8:	892e                	mv	s2,a1
    struct proc *p = myproc();
    800023ca:	00000097          	auipc	ra,0x0
    800023ce:	82e080e7          	jalr	-2002(ra) # 80001bf8 <myproc>
    800023d2:	84aa                	mv	s1,a0
    // Once we hold p->lock, we can be
    // guaranteed that we won't miss any wakeup
    // (wakeup locks p->lock),
    // so it's okay to release lk.

    acquire(&p->lock); // DOC: sleeplock1
    800023d4:	fffff097          	auipc	ra,0xfffff
    800023d8:	934080e7          	jalr	-1740(ra) # 80000d08 <acquire>
    release(lk);
    800023dc:	854a                	mv	a0,s2
    800023de:	fffff097          	auipc	ra,0xfffff
    800023e2:	9de080e7          	jalr	-1570(ra) # 80000dbc <release>

    // Go to sleep.
    p->chan = chan;
    800023e6:	0334b023          	sd	s3,32(s1)
    p->state = SLEEPING;
    800023ea:	4789                	li	a5,2
    800023ec:	cc9c                	sw	a5,24(s1)

    sched();
    800023ee:	00000097          	auipc	ra,0x0
    800023f2:	ec0080e7          	jalr	-320(ra) # 800022ae <sched>

    // Tidy up.
    p->chan = 0;
    800023f6:	0204b023          	sd	zero,32(s1)

    // Reacquire original lock.
    release(&p->lock);
    800023fa:	8526                	mv	a0,s1
    800023fc:	fffff097          	auipc	ra,0xfffff
    80002400:	9c0080e7          	jalr	-1600(ra) # 80000dbc <release>
    acquire(lk);
    80002404:	854a                	mv	a0,s2
    80002406:	fffff097          	auipc	ra,0xfffff
    8000240a:	902080e7          	jalr	-1790(ra) # 80000d08 <acquire>
}
    8000240e:	70a2                	ld	ra,40(sp)
    80002410:	7402                	ld	s0,32(sp)
    80002412:	64e2                	ld	s1,24(sp)
    80002414:	6942                	ld	s2,16(sp)
    80002416:	69a2                	ld	s3,8(sp)
    80002418:	6145                	addi	sp,sp,48
    8000241a:	8082                	ret

000000008000241c <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    8000241c:	7139                	addi	sp,sp,-64
    8000241e:	fc06                	sd	ra,56(sp)
    80002420:	f822                	sd	s0,48(sp)
    80002422:	f426                	sd	s1,40(sp)
    80002424:	f04a                	sd	s2,32(sp)
    80002426:	ec4e                	sd	s3,24(sp)
    80002428:	e852                	sd	s4,16(sp)
    8000242a:	e456                	sd	s5,8(sp)
    8000242c:	0080                	addi	s0,sp,64
    8000242e:	8a2a                	mv	s4,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    80002430:	0044f497          	auipc	s1,0x44f
    80002434:	d3048493          	addi	s1,s1,-720 # 80451160 <proc>
    {
        if (p != myproc())
        {
            acquire(&p->lock);
            if (p->state == SLEEPING && p->chan == chan)
    80002438:	4989                	li	s3,2
            {
                p->state = RUNNABLE;
    8000243a:	4a8d                	li	s5,3
    for (p = proc; p < &proc[NPROC]; p++)
    8000243c:	00454917          	auipc	s2,0x454
    80002440:	72490913          	addi	s2,s2,1828 # 80456b60 <tickslock>
    80002444:	a811                	j	80002458 <wakeup+0x3c>
            }
            release(&p->lock);
    80002446:	8526                	mv	a0,s1
    80002448:	fffff097          	auipc	ra,0xfffff
    8000244c:	974080e7          	jalr	-1676(ra) # 80000dbc <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002450:	16848493          	addi	s1,s1,360
    80002454:	03248663          	beq	s1,s2,80002480 <wakeup+0x64>
        if (p != myproc())
    80002458:	fffff097          	auipc	ra,0xfffff
    8000245c:	7a0080e7          	jalr	1952(ra) # 80001bf8 <myproc>
    80002460:	fea488e3          	beq	s1,a0,80002450 <wakeup+0x34>
            acquire(&p->lock);
    80002464:	8526                	mv	a0,s1
    80002466:	fffff097          	auipc	ra,0xfffff
    8000246a:	8a2080e7          	jalr	-1886(ra) # 80000d08 <acquire>
            if (p->state == SLEEPING && p->chan == chan)
    8000246e:	4c9c                	lw	a5,24(s1)
    80002470:	fd379be3          	bne	a5,s3,80002446 <wakeup+0x2a>
    80002474:	709c                	ld	a5,32(s1)
    80002476:	fd4798e3          	bne	a5,s4,80002446 <wakeup+0x2a>
                p->state = RUNNABLE;
    8000247a:	0154ac23          	sw	s5,24(s1)
    8000247e:	b7e1                	j	80002446 <wakeup+0x2a>
        }
    }
}
    80002480:	70e2                	ld	ra,56(sp)
    80002482:	7442                	ld	s0,48(sp)
    80002484:	74a2                	ld	s1,40(sp)
    80002486:	7902                	ld	s2,32(sp)
    80002488:	69e2                	ld	s3,24(sp)
    8000248a:	6a42                	ld	s4,16(sp)
    8000248c:	6aa2                	ld	s5,8(sp)
    8000248e:	6121                	addi	sp,sp,64
    80002490:	8082                	ret

0000000080002492 <reparent>:
{
    80002492:	7179                	addi	sp,sp,-48
    80002494:	f406                	sd	ra,40(sp)
    80002496:	f022                	sd	s0,32(sp)
    80002498:	ec26                	sd	s1,24(sp)
    8000249a:	e84a                	sd	s2,16(sp)
    8000249c:	e44e                	sd	s3,8(sp)
    8000249e:	e052                	sd	s4,0(sp)
    800024a0:	1800                	addi	s0,sp,48
    800024a2:	892a                	mv	s2,a0
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800024a4:	0044f497          	auipc	s1,0x44f
    800024a8:	cbc48493          	addi	s1,s1,-836 # 80451160 <proc>
            pp->parent = initproc;
    800024ac:	00006a17          	auipc	s4,0x6
    800024b0:	60ca0a13          	addi	s4,s4,1548 # 80008ab8 <initproc>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800024b4:	00454997          	auipc	s3,0x454
    800024b8:	6ac98993          	addi	s3,s3,1708 # 80456b60 <tickslock>
    800024bc:	a029                	j	800024c6 <reparent+0x34>
    800024be:	16848493          	addi	s1,s1,360
    800024c2:	01348d63          	beq	s1,s3,800024dc <reparent+0x4a>
        if (pp->parent == p)
    800024c6:	7c9c                	ld	a5,56(s1)
    800024c8:	ff279be3          	bne	a5,s2,800024be <reparent+0x2c>
            pp->parent = initproc;
    800024cc:	000a3503          	ld	a0,0(s4)
    800024d0:	fc88                	sd	a0,56(s1)
            wakeup(initproc);
    800024d2:	00000097          	auipc	ra,0x0
    800024d6:	f4a080e7          	jalr	-182(ra) # 8000241c <wakeup>
    800024da:	b7d5                	j	800024be <reparent+0x2c>
}
    800024dc:	70a2                	ld	ra,40(sp)
    800024de:	7402                	ld	s0,32(sp)
    800024e0:	64e2                	ld	s1,24(sp)
    800024e2:	6942                	ld	s2,16(sp)
    800024e4:	69a2                	ld	s3,8(sp)
    800024e6:	6a02                	ld	s4,0(sp)
    800024e8:	6145                	addi	sp,sp,48
    800024ea:	8082                	ret

00000000800024ec <exit>:
{
    800024ec:	7179                	addi	sp,sp,-48
    800024ee:	f406                	sd	ra,40(sp)
    800024f0:	f022                	sd	s0,32(sp)
    800024f2:	ec26                	sd	s1,24(sp)
    800024f4:	e84a                	sd	s2,16(sp)
    800024f6:	e44e                	sd	s3,8(sp)
    800024f8:	e052                	sd	s4,0(sp)
    800024fa:	1800                	addi	s0,sp,48
    800024fc:	8a2a                	mv	s4,a0
    struct proc *p = myproc();
    800024fe:	fffff097          	auipc	ra,0xfffff
    80002502:	6fa080e7          	jalr	1786(ra) # 80001bf8 <myproc>
    80002506:	89aa                	mv	s3,a0
    if (p == initproc)
    80002508:	00006797          	auipc	a5,0x6
    8000250c:	5b07b783          	ld	a5,1456(a5) # 80008ab8 <initproc>
    80002510:	0d050493          	addi	s1,a0,208
    80002514:	15050913          	addi	s2,a0,336
    80002518:	02a79363          	bne	a5,a0,8000253e <exit+0x52>
        panic("init exiting");
    8000251c:	00006517          	auipc	a0,0x6
    80002520:	d9450513          	addi	a0,a0,-620 # 800082b0 <digits+0x260>
    80002524:	ffffe097          	auipc	ra,0xffffe
    80002528:	01c080e7          	jalr	28(ra) # 80000540 <panic>
            fileclose(f);
    8000252c:	00002097          	auipc	ra,0x2
    80002530:	652080e7          	jalr	1618(ra) # 80004b7e <fileclose>
            p->ofile[fd] = 0;
    80002534:	0004b023          	sd	zero,0(s1)
    for (int fd = 0; fd < NOFILE; fd++)
    80002538:	04a1                	addi	s1,s1,8
    8000253a:	01248563          	beq	s1,s2,80002544 <exit+0x58>
        if (p->ofile[fd])
    8000253e:	6088                	ld	a0,0(s1)
    80002540:	f575                	bnez	a0,8000252c <exit+0x40>
    80002542:	bfdd                	j	80002538 <exit+0x4c>
    begin_op();
    80002544:	00002097          	auipc	ra,0x2
    80002548:	172080e7          	jalr	370(ra) # 800046b6 <begin_op>
    iput(p->cwd);
    8000254c:	1509b503          	ld	a0,336(s3)
    80002550:	00002097          	auipc	ra,0x2
    80002554:	954080e7          	jalr	-1708(ra) # 80003ea4 <iput>
    end_op();
    80002558:	00002097          	auipc	ra,0x2
    8000255c:	1dc080e7          	jalr	476(ra) # 80004734 <end_op>
    p->cwd = 0;
    80002560:	1409b823          	sd	zero,336(s3)
    acquire(&wait_lock);
    80002564:	0044f497          	auipc	s1,0x44f
    80002568:	be448493          	addi	s1,s1,-1052 # 80451148 <wait_lock>
    8000256c:	8526                	mv	a0,s1
    8000256e:	ffffe097          	auipc	ra,0xffffe
    80002572:	79a080e7          	jalr	1946(ra) # 80000d08 <acquire>
    reparent(p);
    80002576:	854e                	mv	a0,s3
    80002578:	00000097          	auipc	ra,0x0
    8000257c:	f1a080e7          	jalr	-230(ra) # 80002492 <reparent>
    wakeup(p->parent);
    80002580:	0389b503          	ld	a0,56(s3)
    80002584:	00000097          	auipc	ra,0x0
    80002588:	e98080e7          	jalr	-360(ra) # 8000241c <wakeup>
    acquire(&p->lock);
    8000258c:	854e                	mv	a0,s3
    8000258e:	ffffe097          	auipc	ra,0xffffe
    80002592:	77a080e7          	jalr	1914(ra) # 80000d08 <acquire>
    p->xstate = status;
    80002596:	0349a623          	sw	s4,44(s3)
    p->state = ZOMBIE;
    8000259a:	4795                	li	a5,5
    8000259c:	00f9ac23          	sw	a5,24(s3)
    release(&wait_lock);
    800025a0:	8526                	mv	a0,s1
    800025a2:	fffff097          	auipc	ra,0xfffff
    800025a6:	81a080e7          	jalr	-2022(ra) # 80000dbc <release>
    sched();
    800025aa:	00000097          	auipc	ra,0x0
    800025ae:	d04080e7          	jalr	-764(ra) # 800022ae <sched>
    panic("zombie exit");
    800025b2:	00006517          	auipc	a0,0x6
    800025b6:	d0e50513          	addi	a0,a0,-754 # 800082c0 <digits+0x270>
    800025ba:	ffffe097          	auipc	ra,0xffffe
    800025be:	f86080e7          	jalr	-122(ra) # 80000540 <panic>

00000000800025c2 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800025c2:	7179                	addi	sp,sp,-48
    800025c4:	f406                	sd	ra,40(sp)
    800025c6:	f022                	sd	s0,32(sp)
    800025c8:	ec26                	sd	s1,24(sp)
    800025ca:	e84a                	sd	s2,16(sp)
    800025cc:	e44e                	sd	s3,8(sp)
    800025ce:	1800                	addi	s0,sp,48
    800025d0:	892a                	mv	s2,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    800025d2:	0044f497          	auipc	s1,0x44f
    800025d6:	b8e48493          	addi	s1,s1,-1138 # 80451160 <proc>
    800025da:	00454997          	auipc	s3,0x454
    800025de:	58698993          	addi	s3,s3,1414 # 80456b60 <tickslock>
    {
        acquire(&p->lock);
    800025e2:	8526                	mv	a0,s1
    800025e4:	ffffe097          	auipc	ra,0xffffe
    800025e8:	724080e7          	jalr	1828(ra) # 80000d08 <acquire>
        if (p->pid == pid)
    800025ec:	589c                	lw	a5,48(s1)
    800025ee:	01278d63          	beq	a5,s2,80002608 <kill+0x46>
                p->state = RUNNABLE;
            }
            release(&p->lock);
            return 0;
        }
        release(&p->lock);
    800025f2:	8526                	mv	a0,s1
    800025f4:	ffffe097          	auipc	ra,0xffffe
    800025f8:	7c8080e7          	jalr	1992(ra) # 80000dbc <release>
    for (p = proc; p < &proc[NPROC]; p++)
    800025fc:	16848493          	addi	s1,s1,360
    80002600:	ff3491e3          	bne	s1,s3,800025e2 <kill+0x20>
    }
    return -1;
    80002604:	557d                	li	a0,-1
    80002606:	a829                	j	80002620 <kill+0x5e>
            p->killed = 1;
    80002608:	4785                	li	a5,1
    8000260a:	d49c                	sw	a5,40(s1)
            if (p->state == SLEEPING)
    8000260c:	4c98                	lw	a4,24(s1)
    8000260e:	4789                	li	a5,2
    80002610:	00f70f63          	beq	a4,a5,8000262e <kill+0x6c>
            release(&p->lock);
    80002614:	8526                	mv	a0,s1
    80002616:	ffffe097          	auipc	ra,0xffffe
    8000261a:	7a6080e7          	jalr	1958(ra) # 80000dbc <release>
            return 0;
    8000261e:	4501                	li	a0,0
}
    80002620:	70a2                	ld	ra,40(sp)
    80002622:	7402                	ld	s0,32(sp)
    80002624:	64e2                	ld	s1,24(sp)
    80002626:	6942                	ld	s2,16(sp)
    80002628:	69a2                	ld	s3,8(sp)
    8000262a:	6145                	addi	sp,sp,48
    8000262c:	8082                	ret
                p->state = RUNNABLE;
    8000262e:	478d                	li	a5,3
    80002630:	cc9c                	sw	a5,24(s1)
    80002632:	b7cd                	j	80002614 <kill+0x52>

0000000080002634 <setkilled>:

void setkilled(struct proc *p)
{
    80002634:	1101                	addi	sp,sp,-32
    80002636:	ec06                	sd	ra,24(sp)
    80002638:	e822                	sd	s0,16(sp)
    8000263a:	e426                	sd	s1,8(sp)
    8000263c:	1000                	addi	s0,sp,32
    8000263e:	84aa                	mv	s1,a0
    acquire(&p->lock);
    80002640:	ffffe097          	auipc	ra,0xffffe
    80002644:	6c8080e7          	jalr	1736(ra) # 80000d08 <acquire>
    p->killed = 1;
    80002648:	4785                	li	a5,1
    8000264a:	d49c                	sw	a5,40(s1)
    release(&p->lock);
    8000264c:	8526                	mv	a0,s1
    8000264e:	ffffe097          	auipc	ra,0xffffe
    80002652:	76e080e7          	jalr	1902(ra) # 80000dbc <release>
}
    80002656:	60e2                	ld	ra,24(sp)
    80002658:	6442                	ld	s0,16(sp)
    8000265a:	64a2                	ld	s1,8(sp)
    8000265c:	6105                	addi	sp,sp,32
    8000265e:	8082                	ret

0000000080002660 <killed>:

int killed(struct proc *p)
{
    80002660:	1101                	addi	sp,sp,-32
    80002662:	ec06                	sd	ra,24(sp)
    80002664:	e822                	sd	s0,16(sp)
    80002666:	e426                	sd	s1,8(sp)
    80002668:	e04a                	sd	s2,0(sp)
    8000266a:	1000                	addi	s0,sp,32
    8000266c:	84aa                	mv	s1,a0
    int k;

    acquire(&p->lock);
    8000266e:	ffffe097          	auipc	ra,0xffffe
    80002672:	69a080e7          	jalr	1690(ra) # 80000d08 <acquire>
    k = p->killed;
    80002676:	0284a903          	lw	s2,40(s1)
    release(&p->lock);
    8000267a:	8526                	mv	a0,s1
    8000267c:	ffffe097          	auipc	ra,0xffffe
    80002680:	740080e7          	jalr	1856(ra) # 80000dbc <release>
    return k;
}
    80002684:	854a                	mv	a0,s2
    80002686:	60e2                	ld	ra,24(sp)
    80002688:	6442                	ld	s0,16(sp)
    8000268a:	64a2                	ld	s1,8(sp)
    8000268c:	6902                	ld	s2,0(sp)
    8000268e:	6105                	addi	sp,sp,32
    80002690:	8082                	ret

0000000080002692 <wait>:
{
    80002692:	715d                	addi	sp,sp,-80
    80002694:	e486                	sd	ra,72(sp)
    80002696:	e0a2                	sd	s0,64(sp)
    80002698:	fc26                	sd	s1,56(sp)
    8000269a:	f84a                	sd	s2,48(sp)
    8000269c:	f44e                	sd	s3,40(sp)
    8000269e:	f052                	sd	s4,32(sp)
    800026a0:	ec56                	sd	s5,24(sp)
    800026a2:	e85a                	sd	s6,16(sp)
    800026a4:	e45e                	sd	s7,8(sp)
    800026a6:	e062                	sd	s8,0(sp)
    800026a8:	0880                	addi	s0,sp,80
    800026aa:	8b2a                	mv	s6,a0
    struct proc *p = myproc();
    800026ac:	fffff097          	auipc	ra,0xfffff
    800026b0:	54c080e7          	jalr	1356(ra) # 80001bf8 <myproc>
    800026b4:	892a                	mv	s2,a0
    acquire(&wait_lock);
    800026b6:	0044f517          	auipc	a0,0x44f
    800026ba:	a9250513          	addi	a0,a0,-1390 # 80451148 <wait_lock>
    800026be:	ffffe097          	auipc	ra,0xffffe
    800026c2:	64a080e7          	jalr	1610(ra) # 80000d08 <acquire>
        havekids = 0;
    800026c6:	4b81                	li	s7,0
                if (pp->state == ZOMBIE)
    800026c8:	4a15                	li	s4,5
                havekids = 1;
    800026ca:	4a85                	li	s5,1
        for (pp = proc; pp < &proc[NPROC]; pp++)
    800026cc:	00454997          	auipc	s3,0x454
    800026d0:	49498993          	addi	s3,s3,1172 # 80456b60 <tickslock>
        sleep(p, &wait_lock); // DOC: wait-sleep
    800026d4:	0044fc17          	auipc	s8,0x44f
    800026d8:	a74c0c13          	addi	s8,s8,-1420 # 80451148 <wait_lock>
        havekids = 0;
    800026dc:	875e                	mv	a4,s7
        for (pp = proc; pp < &proc[NPROC]; pp++)
    800026de:	0044f497          	auipc	s1,0x44f
    800026e2:	a8248493          	addi	s1,s1,-1406 # 80451160 <proc>
    800026e6:	a0bd                	j	80002754 <wait+0xc2>
                    pid = pp->pid;
    800026e8:	0304a983          	lw	s3,48(s1)
                    if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800026ec:	000b0e63          	beqz	s6,80002708 <wait+0x76>
    800026f0:	4691                	li	a3,4
    800026f2:	02c48613          	addi	a2,s1,44
    800026f6:	85da                	mv	a1,s6
    800026f8:	05093503          	ld	a0,80(s2)
    800026fc:	fffff097          	auipc	ra,0xfffff
    80002700:	0be080e7          	jalr	190(ra) # 800017ba <copyout>
    80002704:	02054563          	bltz	a0,8000272e <wait+0x9c>
                    freeproc(pp);
    80002708:	8526                	mv	a0,s1
    8000270a:	fffff097          	auipc	ra,0xfffff
    8000270e:	6a0080e7          	jalr	1696(ra) # 80001daa <freeproc>
                    release(&pp->lock);
    80002712:	8526                	mv	a0,s1
    80002714:	ffffe097          	auipc	ra,0xffffe
    80002718:	6a8080e7          	jalr	1704(ra) # 80000dbc <release>
                    release(&wait_lock);
    8000271c:	0044f517          	auipc	a0,0x44f
    80002720:	a2c50513          	addi	a0,a0,-1492 # 80451148 <wait_lock>
    80002724:	ffffe097          	auipc	ra,0xffffe
    80002728:	698080e7          	jalr	1688(ra) # 80000dbc <release>
                    return pid;
    8000272c:	a0b5                	j	80002798 <wait+0x106>
                        release(&pp->lock);
    8000272e:	8526                	mv	a0,s1
    80002730:	ffffe097          	auipc	ra,0xffffe
    80002734:	68c080e7          	jalr	1676(ra) # 80000dbc <release>
                        release(&wait_lock);
    80002738:	0044f517          	auipc	a0,0x44f
    8000273c:	a1050513          	addi	a0,a0,-1520 # 80451148 <wait_lock>
    80002740:	ffffe097          	auipc	ra,0xffffe
    80002744:	67c080e7          	jalr	1660(ra) # 80000dbc <release>
                        return -1;
    80002748:	59fd                	li	s3,-1
    8000274a:	a0b9                	j	80002798 <wait+0x106>
        for (pp = proc; pp < &proc[NPROC]; pp++)
    8000274c:	16848493          	addi	s1,s1,360
    80002750:	03348463          	beq	s1,s3,80002778 <wait+0xe6>
            if (pp->parent == p)
    80002754:	7c9c                	ld	a5,56(s1)
    80002756:	ff279be3          	bne	a5,s2,8000274c <wait+0xba>
                acquire(&pp->lock);
    8000275a:	8526                	mv	a0,s1
    8000275c:	ffffe097          	auipc	ra,0xffffe
    80002760:	5ac080e7          	jalr	1452(ra) # 80000d08 <acquire>
                if (pp->state == ZOMBIE)
    80002764:	4c9c                	lw	a5,24(s1)
    80002766:	f94781e3          	beq	a5,s4,800026e8 <wait+0x56>
                release(&pp->lock);
    8000276a:	8526                	mv	a0,s1
    8000276c:	ffffe097          	auipc	ra,0xffffe
    80002770:	650080e7          	jalr	1616(ra) # 80000dbc <release>
                havekids = 1;
    80002774:	8756                	mv	a4,s5
    80002776:	bfd9                	j	8000274c <wait+0xba>
        if (!havekids || killed(p))
    80002778:	c719                	beqz	a4,80002786 <wait+0xf4>
    8000277a:	854a                	mv	a0,s2
    8000277c:	00000097          	auipc	ra,0x0
    80002780:	ee4080e7          	jalr	-284(ra) # 80002660 <killed>
    80002784:	c51d                	beqz	a0,800027b2 <wait+0x120>
            release(&wait_lock);
    80002786:	0044f517          	auipc	a0,0x44f
    8000278a:	9c250513          	addi	a0,a0,-1598 # 80451148 <wait_lock>
    8000278e:	ffffe097          	auipc	ra,0xffffe
    80002792:	62e080e7          	jalr	1582(ra) # 80000dbc <release>
            return -1;
    80002796:	59fd                	li	s3,-1
}
    80002798:	854e                	mv	a0,s3
    8000279a:	60a6                	ld	ra,72(sp)
    8000279c:	6406                	ld	s0,64(sp)
    8000279e:	74e2                	ld	s1,56(sp)
    800027a0:	7942                	ld	s2,48(sp)
    800027a2:	79a2                	ld	s3,40(sp)
    800027a4:	7a02                	ld	s4,32(sp)
    800027a6:	6ae2                	ld	s5,24(sp)
    800027a8:	6b42                	ld	s6,16(sp)
    800027aa:	6ba2                	ld	s7,8(sp)
    800027ac:	6c02                	ld	s8,0(sp)
    800027ae:	6161                	addi	sp,sp,80
    800027b0:	8082                	ret
        sleep(p, &wait_lock); // DOC: wait-sleep
    800027b2:	85e2                	mv	a1,s8
    800027b4:	854a                	mv	a0,s2
    800027b6:	00000097          	auipc	ra,0x0
    800027ba:	c02080e7          	jalr	-1022(ra) # 800023b8 <sleep>
        havekids = 0;
    800027be:	bf39                	j	800026dc <wait+0x4a>

00000000800027c0 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800027c0:	7179                	addi	sp,sp,-48
    800027c2:	f406                	sd	ra,40(sp)
    800027c4:	f022                	sd	s0,32(sp)
    800027c6:	ec26                	sd	s1,24(sp)
    800027c8:	e84a                	sd	s2,16(sp)
    800027ca:	e44e                	sd	s3,8(sp)
    800027cc:	e052                	sd	s4,0(sp)
    800027ce:	1800                	addi	s0,sp,48
    800027d0:	84aa                	mv	s1,a0
    800027d2:	892e                	mv	s2,a1
    800027d4:	89b2                	mv	s3,a2
    800027d6:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    800027d8:	fffff097          	auipc	ra,0xfffff
    800027dc:	420080e7          	jalr	1056(ra) # 80001bf8 <myproc>
    if (user_dst)
    800027e0:	c08d                	beqz	s1,80002802 <either_copyout+0x42>
    {
        return copyout(p->pagetable, dst, src, len);
    800027e2:	86d2                	mv	a3,s4
    800027e4:	864e                	mv	a2,s3
    800027e6:	85ca                	mv	a1,s2
    800027e8:	6928                	ld	a0,80(a0)
    800027ea:	fffff097          	auipc	ra,0xfffff
    800027ee:	fd0080e7          	jalr	-48(ra) # 800017ba <copyout>
    else
    {
        memmove((char *)dst, src, len);
        return 0;
    }
}
    800027f2:	70a2                	ld	ra,40(sp)
    800027f4:	7402                	ld	s0,32(sp)
    800027f6:	64e2                	ld	s1,24(sp)
    800027f8:	6942                	ld	s2,16(sp)
    800027fa:	69a2                	ld	s3,8(sp)
    800027fc:	6a02                	ld	s4,0(sp)
    800027fe:	6145                	addi	sp,sp,48
    80002800:	8082                	ret
        memmove((char *)dst, src, len);
    80002802:	000a061b          	sext.w	a2,s4
    80002806:	85ce                	mv	a1,s3
    80002808:	854a                	mv	a0,s2
    8000280a:	ffffe097          	auipc	ra,0xffffe
    8000280e:	656080e7          	jalr	1622(ra) # 80000e60 <memmove>
        return 0;
    80002812:	8526                	mv	a0,s1
    80002814:	bff9                	j	800027f2 <either_copyout+0x32>

0000000080002816 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002816:	7179                	addi	sp,sp,-48
    80002818:	f406                	sd	ra,40(sp)
    8000281a:	f022                	sd	s0,32(sp)
    8000281c:	ec26                	sd	s1,24(sp)
    8000281e:	e84a                	sd	s2,16(sp)
    80002820:	e44e                	sd	s3,8(sp)
    80002822:	e052                	sd	s4,0(sp)
    80002824:	1800                	addi	s0,sp,48
    80002826:	892a                	mv	s2,a0
    80002828:	84ae                	mv	s1,a1
    8000282a:	89b2                	mv	s3,a2
    8000282c:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    8000282e:	fffff097          	auipc	ra,0xfffff
    80002832:	3ca080e7          	jalr	970(ra) # 80001bf8 <myproc>
    if (user_src)
    80002836:	c08d                	beqz	s1,80002858 <either_copyin+0x42>
    {
        return copyin(p->pagetable, dst, src, len);
    80002838:	86d2                	mv	a3,s4
    8000283a:	864e                	mv	a2,s3
    8000283c:	85ca                	mv	a1,s2
    8000283e:	6928                	ld	a0,80(a0)
    80002840:	fffff097          	auipc	ra,0xfffff
    80002844:	006080e7          	jalr	6(ra) # 80001846 <copyin>
    else
    {
        memmove(dst, (char *)src, len);
        return 0;
    }
}
    80002848:	70a2                	ld	ra,40(sp)
    8000284a:	7402                	ld	s0,32(sp)
    8000284c:	64e2                	ld	s1,24(sp)
    8000284e:	6942                	ld	s2,16(sp)
    80002850:	69a2                	ld	s3,8(sp)
    80002852:	6a02                	ld	s4,0(sp)
    80002854:	6145                	addi	sp,sp,48
    80002856:	8082                	ret
        memmove(dst, (char *)src, len);
    80002858:	000a061b          	sext.w	a2,s4
    8000285c:	85ce                	mv	a1,s3
    8000285e:	854a                	mv	a0,s2
    80002860:	ffffe097          	auipc	ra,0xffffe
    80002864:	600080e7          	jalr	1536(ra) # 80000e60 <memmove>
        return 0;
    80002868:	8526                	mv	a0,s1
    8000286a:	bff9                	j	80002848 <either_copyin+0x32>

000000008000286c <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    8000286c:	715d                	addi	sp,sp,-80
    8000286e:	e486                	sd	ra,72(sp)
    80002870:	e0a2                	sd	s0,64(sp)
    80002872:	fc26                	sd	s1,56(sp)
    80002874:	f84a                	sd	s2,48(sp)
    80002876:	f44e                	sd	s3,40(sp)
    80002878:	f052                	sd	s4,32(sp)
    8000287a:	ec56                	sd	s5,24(sp)
    8000287c:	e85a                	sd	s6,16(sp)
    8000287e:	e45e                	sd	s7,8(sp)
    80002880:	0880                	addi	s0,sp,80
        [RUNNING] "run   ",
        [ZOMBIE] "zombie"};
    struct proc *p;
    char *state;

    printf("\n");
    80002882:	00006517          	auipc	a0,0x6
    80002886:	c0e50513          	addi	a0,a0,-1010 # 80008490 <states.0+0xa8>
    8000288a:	ffffe097          	auipc	ra,0xffffe
    8000288e:	d12080e7          	jalr	-750(ra) # 8000059c <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    80002892:	0044f497          	auipc	s1,0x44f
    80002896:	a2648493          	addi	s1,s1,-1498 # 804512b8 <proc+0x158>
    8000289a:	00454917          	auipc	s2,0x454
    8000289e:	41e90913          	addi	s2,s2,1054 # 80456cb8 <bcache+0x140>
    {
        if (p->state == UNUSED)
            continue;
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028a2:	4b15                	li	s6,5
            state = states[p->state];
        else
            state = "???";
    800028a4:	00006997          	auipc	s3,0x6
    800028a8:	a2c98993          	addi	s3,s3,-1492 # 800082d0 <digits+0x280>
        printf("%d <%s %s", p->pid, state, p->name);
    800028ac:	00006a97          	auipc	s5,0x6
    800028b0:	a2ca8a93          	addi	s5,s5,-1492 # 800082d8 <digits+0x288>
        printf("\n");
    800028b4:	00006a17          	auipc	s4,0x6
    800028b8:	bdca0a13          	addi	s4,s4,-1060 # 80008490 <states.0+0xa8>
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028bc:	00006b97          	auipc	s7,0x6
    800028c0:	b2cb8b93          	addi	s7,s7,-1236 # 800083e8 <states.0>
    800028c4:	a00d                	j	800028e6 <procdump+0x7a>
        printf("%d <%s %s", p->pid, state, p->name);
    800028c6:	ed86a583          	lw	a1,-296(a3)
    800028ca:	8556                	mv	a0,s5
    800028cc:	ffffe097          	auipc	ra,0xffffe
    800028d0:	cd0080e7          	jalr	-816(ra) # 8000059c <printf>
        printf("\n");
    800028d4:	8552                	mv	a0,s4
    800028d6:	ffffe097          	auipc	ra,0xffffe
    800028da:	cc6080e7          	jalr	-826(ra) # 8000059c <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    800028de:	16848493          	addi	s1,s1,360
    800028e2:	03248263          	beq	s1,s2,80002906 <procdump+0x9a>
        if (p->state == UNUSED)
    800028e6:	86a6                	mv	a3,s1
    800028e8:	ec04a783          	lw	a5,-320(s1)
    800028ec:	dbed                	beqz	a5,800028de <procdump+0x72>
            state = "???";
    800028ee:	864e                	mv	a2,s3
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028f0:	fcfb6be3          	bltu	s6,a5,800028c6 <procdump+0x5a>
    800028f4:	02079713          	slli	a4,a5,0x20
    800028f8:	01d75793          	srli	a5,a4,0x1d
    800028fc:	97de                	add	a5,a5,s7
    800028fe:	6390                	ld	a2,0(a5)
    80002900:	f279                	bnez	a2,800028c6 <procdump+0x5a>
            state = "???";
    80002902:	864e                	mv	a2,s3
    80002904:	b7c9                	j	800028c6 <procdump+0x5a>
    }
}
    80002906:	60a6                	ld	ra,72(sp)
    80002908:	6406                	ld	s0,64(sp)
    8000290a:	74e2                	ld	s1,56(sp)
    8000290c:	7942                	ld	s2,48(sp)
    8000290e:	79a2                	ld	s3,40(sp)
    80002910:	7a02                	ld	s4,32(sp)
    80002912:	6ae2                	ld	s5,24(sp)
    80002914:	6b42                	ld	s6,16(sp)
    80002916:	6ba2                	ld	s7,8(sp)
    80002918:	6161                	addi	sp,sp,80
    8000291a:	8082                	ret

000000008000291c <schedls>:

void schedls()
{
    8000291c:	1141                	addi	sp,sp,-16
    8000291e:	e406                	sd	ra,8(sp)
    80002920:	e022                	sd	s0,0(sp)
    80002922:	0800                	addi	s0,sp,16
    printf("[ ]\tScheduler Name\tScheduler ID\n");
    80002924:	00006517          	auipc	a0,0x6
    80002928:	9c450513          	addi	a0,a0,-1596 # 800082e8 <digits+0x298>
    8000292c:	ffffe097          	auipc	ra,0xffffe
    80002930:	c70080e7          	jalr	-912(ra) # 8000059c <printf>
    printf("====================================\n");
    80002934:	00006517          	auipc	a0,0x6
    80002938:	9dc50513          	addi	a0,a0,-1572 # 80008310 <digits+0x2c0>
    8000293c:	ffffe097          	auipc	ra,0xffffe
    80002940:	c60080e7          	jalr	-928(ra) # 8000059c <printf>
    for (int i = 0; i < SCHEDC; i++)
    {
        if (available_schedulers[i].impl == sched_pointer)
    80002944:	00006717          	auipc	a4,0x6
    80002948:	10473703          	ld	a4,260(a4) # 80008a48 <available_schedulers+0x10>
    8000294c:	00006797          	auipc	a5,0x6
    80002950:	09c7b783          	ld	a5,156(a5) # 800089e8 <sched_pointer>
    80002954:	04f70663          	beq	a4,a5,800029a0 <schedls+0x84>
        {
            printf("[*]\t");
        }
        else
        {
            printf("   \t");
    80002958:	00006517          	auipc	a0,0x6
    8000295c:	9e850513          	addi	a0,a0,-1560 # 80008340 <digits+0x2f0>
    80002960:	ffffe097          	auipc	ra,0xffffe
    80002964:	c3c080e7          	jalr	-964(ra) # 8000059c <printf>
        }
        printf("%s\t%d\n", available_schedulers[i].name, available_schedulers[i].id);
    80002968:	00006617          	auipc	a2,0x6
    8000296c:	0e862603          	lw	a2,232(a2) # 80008a50 <available_schedulers+0x18>
    80002970:	00006597          	auipc	a1,0x6
    80002974:	0c858593          	addi	a1,a1,200 # 80008a38 <available_schedulers>
    80002978:	00006517          	auipc	a0,0x6
    8000297c:	9d050513          	addi	a0,a0,-1584 # 80008348 <digits+0x2f8>
    80002980:	ffffe097          	auipc	ra,0xffffe
    80002984:	c1c080e7          	jalr	-996(ra) # 8000059c <printf>
    }
    printf("\n*: current scheduler\n\n");
    80002988:	00006517          	auipc	a0,0x6
    8000298c:	9c850513          	addi	a0,a0,-1592 # 80008350 <digits+0x300>
    80002990:	ffffe097          	auipc	ra,0xffffe
    80002994:	c0c080e7          	jalr	-1012(ra) # 8000059c <printf>
}
    80002998:	60a2                	ld	ra,8(sp)
    8000299a:	6402                	ld	s0,0(sp)
    8000299c:	0141                	addi	sp,sp,16
    8000299e:	8082                	ret
            printf("[*]\t");
    800029a0:	00006517          	auipc	a0,0x6
    800029a4:	99850513          	addi	a0,a0,-1640 # 80008338 <digits+0x2e8>
    800029a8:	ffffe097          	auipc	ra,0xffffe
    800029ac:	bf4080e7          	jalr	-1036(ra) # 8000059c <printf>
    800029b0:	bf65                	j	80002968 <schedls+0x4c>

00000000800029b2 <schedset>:

void schedset(int id)
{
    800029b2:	1141                	addi	sp,sp,-16
    800029b4:	e406                	sd	ra,8(sp)
    800029b6:	e022                	sd	s0,0(sp)
    800029b8:	0800                	addi	s0,sp,16
    if (id < 0 || SCHEDC <= id)
    800029ba:	e90d                	bnez	a0,800029ec <schedset+0x3a>
    {
        printf("Scheduler unchanged: ID out of range\n");
        return;
    }
    sched_pointer = available_schedulers[id].impl;
    800029bc:	00006797          	auipc	a5,0x6
    800029c0:	08c7b783          	ld	a5,140(a5) # 80008a48 <available_schedulers+0x10>
    800029c4:	00006717          	auipc	a4,0x6
    800029c8:	02f73223          	sd	a5,36(a4) # 800089e8 <sched_pointer>
    printf("Scheduler successfully changed to %s\n", available_schedulers[id].name);
    800029cc:	00006597          	auipc	a1,0x6
    800029d0:	06c58593          	addi	a1,a1,108 # 80008a38 <available_schedulers>
    800029d4:	00006517          	auipc	a0,0x6
    800029d8:	9bc50513          	addi	a0,a0,-1604 # 80008390 <digits+0x340>
    800029dc:	ffffe097          	auipc	ra,0xffffe
    800029e0:	bc0080e7          	jalr	-1088(ra) # 8000059c <printf>
    800029e4:	60a2                	ld	ra,8(sp)
    800029e6:	6402                	ld	s0,0(sp)
    800029e8:	0141                	addi	sp,sp,16
    800029ea:	8082                	ret
        printf("Scheduler unchanged: ID out of range\n");
    800029ec:	00006517          	auipc	a0,0x6
    800029f0:	97c50513          	addi	a0,a0,-1668 # 80008368 <digits+0x318>
    800029f4:	ffffe097          	auipc	ra,0xffffe
    800029f8:	ba8080e7          	jalr	-1112(ra) # 8000059c <printf>
        return;
    800029fc:	b7e5                	j	800029e4 <schedset+0x32>

00000000800029fe <swtch>:
    800029fe:	00153023          	sd	ra,0(a0)
    80002a02:	00253423          	sd	sp,8(a0)
    80002a06:	e900                	sd	s0,16(a0)
    80002a08:	ed04                	sd	s1,24(a0)
    80002a0a:	03253023          	sd	s2,32(a0)
    80002a0e:	03353423          	sd	s3,40(a0)
    80002a12:	03453823          	sd	s4,48(a0)
    80002a16:	03553c23          	sd	s5,56(a0)
    80002a1a:	05653023          	sd	s6,64(a0)
    80002a1e:	05753423          	sd	s7,72(a0)
    80002a22:	05853823          	sd	s8,80(a0)
    80002a26:	05953c23          	sd	s9,88(a0)
    80002a2a:	07a53023          	sd	s10,96(a0)
    80002a2e:	07b53423          	sd	s11,104(a0)
    80002a32:	0005b083          	ld	ra,0(a1)
    80002a36:	0085b103          	ld	sp,8(a1)
    80002a3a:	6980                	ld	s0,16(a1)
    80002a3c:	6d84                	ld	s1,24(a1)
    80002a3e:	0205b903          	ld	s2,32(a1)
    80002a42:	0285b983          	ld	s3,40(a1)
    80002a46:	0305ba03          	ld	s4,48(a1)
    80002a4a:	0385ba83          	ld	s5,56(a1)
    80002a4e:	0405bb03          	ld	s6,64(a1)
    80002a52:	0485bb83          	ld	s7,72(a1)
    80002a56:	0505bc03          	ld	s8,80(a1)
    80002a5a:	0585bc83          	ld	s9,88(a1)
    80002a5e:	0605bd03          	ld	s10,96(a1)
    80002a62:	0685bd83          	ld	s11,104(a1)
    80002a66:	8082                	ret

0000000080002a68 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002a68:	1141                	addi	sp,sp,-16
    80002a6a:	e406                	sd	ra,8(sp)
    80002a6c:	e022                	sd	s0,0(sp)
    80002a6e:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002a70:	00006597          	auipc	a1,0x6
    80002a74:	9a858593          	addi	a1,a1,-1624 # 80008418 <states.0+0x30>
    80002a78:	00454517          	auipc	a0,0x454
    80002a7c:	0e850513          	addi	a0,a0,232 # 80456b60 <tickslock>
    80002a80:	ffffe097          	auipc	ra,0xffffe
    80002a84:	1f8080e7          	jalr	504(ra) # 80000c78 <initlock>
}
    80002a88:	60a2                	ld	ra,8(sp)
    80002a8a:	6402                	ld	s0,0(sp)
    80002a8c:	0141                	addi	sp,sp,16
    80002a8e:	8082                	ret

0000000080002a90 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002a90:	1141                	addi	sp,sp,-16
    80002a92:	e422                	sd	s0,8(sp)
    80002a94:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a96:	00003797          	auipc	a5,0x3
    80002a9a:	73a78793          	addi	a5,a5,1850 # 800061d0 <kernelvec>
    80002a9e:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002aa2:	6422                	ld	s0,8(sp)
    80002aa4:	0141                	addi	sp,sp,16
    80002aa6:	8082                	ret

0000000080002aa8 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002aa8:	1141                	addi	sp,sp,-16
    80002aaa:	e406                	sd	ra,8(sp)
    80002aac:	e022                	sd	s0,0(sp)
    80002aae:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002ab0:	fffff097          	auipc	ra,0xfffff
    80002ab4:	148080e7          	jalr	328(ra) # 80001bf8 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ab8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002abc:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002abe:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002ac2:	00004697          	auipc	a3,0x4
    80002ac6:	53e68693          	addi	a3,a3,1342 # 80007000 <_trampoline>
    80002aca:	00004717          	auipc	a4,0x4
    80002ace:	53670713          	addi	a4,a4,1334 # 80007000 <_trampoline>
    80002ad2:	8f15                	sub	a4,a4,a3
    80002ad4:	040007b7          	lui	a5,0x4000
    80002ad8:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002ada:	07b2                	slli	a5,a5,0xc
    80002adc:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ade:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002ae2:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002ae4:	18002673          	csrr	a2,satp
    80002ae8:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002aea:	6d30                	ld	a2,88(a0)
    80002aec:	6138                	ld	a4,64(a0)
    80002aee:	6585                	lui	a1,0x1
    80002af0:	972e                	add	a4,a4,a1
    80002af2:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002af4:	6d38                	ld	a4,88(a0)
    80002af6:	00000617          	auipc	a2,0x0
    80002afa:	13060613          	addi	a2,a2,304 # 80002c26 <usertrap>
    80002afe:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002b00:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002b02:	8612                	mv	a2,tp
    80002b04:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b06:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002b0a:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002b0e:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b12:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002b16:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b18:	6f18                	ld	a4,24(a4)
    80002b1a:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002b1e:	6928                	ld	a0,80(a0)
    80002b20:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002b22:	00004717          	auipc	a4,0x4
    80002b26:	57a70713          	addi	a4,a4,1402 # 8000709c <userret>
    80002b2a:	8f15                	sub	a4,a4,a3
    80002b2c:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002b2e:	577d                	li	a4,-1
    80002b30:	177e                	slli	a4,a4,0x3f
    80002b32:	8d59                	or	a0,a0,a4
    80002b34:	9782                	jalr	a5
}
    80002b36:	60a2                	ld	ra,8(sp)
    80002b38:	6402                	ld	s0,0(sp)
    80002b3a:	0141                	addi	sp,sp,16
    80002b3c:	8082                	ret

0000000080002b3e <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002b3e:	1101                	addi	sp,sp,-32
    80002b40:	ec06                	sd	ra,24(sp)
    80002b42:	e822                	sd	s0,16(sp)
    80002b44:	e426                	sd	s1,8(sp)
    80002b46:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002b48:	00454497          	auipc	s1,0x454
    80002b4c:	01848493          	addi	s1,s1,24 # 80456b60 <tickslock>
    80002b50:	8526                	mv	a0,s1
    80002b52:	ffffe097          	auipc	ra,0xffffe
    80002b56:	1b6080e7          	jalr	438(ra) # 80000d08 <acquire>
  ticks++;
    80002b5a:	00006517          	auipc	a0,0x6
    80002b5e:	f6650513          	addi	a0,a0,-154 # 80008ac0 <ticks>
    80002b62:	411c                	lw	a5,0(a0)
    80002b64:	2785                	addiw	a5,a5,1
    80002b66:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002b68:	00000097          	auipc	ra,0x0
    80002b6c:	8b4080e7          	jalr	-1868(ra) # 8000241c <wakeup>
  release(&tickslock);
    80002b70:	8526                	mv	a0,s1
    80002b72:	ffffe097          	auipc	ra,0xffffe
    80002b76:	24a080e7          	jalr	586(ra) # 80000dbc <release>
}
    80002b7a:	60e2                	ld	ra,24(sp)
    80002b7c:	6442                	ld	s0,16(sp)
    80002b7e:	64a2                	ld	s1,8(sp)
    80002b80:	6105                	addi	sp,sp,32
    80002b82:	8082                	ret

0000000080002b84 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002b84:	1101                	addi	sp,sp,-32
    80002b86:	ec06                	sd	ra,24(sp)
    80002b88:	e822                	sd	s0,16(sp)
    80002b8a:	e426                	sd	s1,8(sp)
    80002b8c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b8e:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002b92:	00074d63          	bltz	a4,80002bac <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002b96:	57fd                	li	a5,-1
    80002b98:	17fe                	slli	a5,a5,0x3f
    80002b9a:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002b9c:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002b9e:	06f70363          	beq	a4,a5,80002c04 <devintr+0x80>
  }
}
    80002ba2:	60e2                	ld	ra,24(sp)
    80002ba4:	6442                	ld	s0,16(sp)
    80002ba6:	64a2                	ld	s1,8(sp)
    80002ba8:	6105                	addi	sp,sp,32
    80002baa:	8082                	ret
     (scause & 0xff) == 9){
    80002bac:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    80002bb0:	46a5                	li	a3,9
    80002bb2:	fed792e3          	bne	a5,a3,80002b96 <devintr+0x12>
    int irq = plic_claim();
    80002bb6:	00003097          	auipc	ra,0x3
    80002bba:	722080e7          	jalr	1826(ra) # 800062d8 <plic_claim>
    80002bbe:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002bc0:	47a9                	li	a5,10
    80002bc2:	02f50763          	beq	a0,a5,80002bf0 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002bc6:	4785                	li	a5,1
    80002bc8:	02f50963          	beq	a0,a5,80002bfa <devintr+0x76>
    return 1;
    80002bcc:	4505                	li	a0,1
    } else if(irq){
    80002bce:	d8f1                	beqz	s1,80002ba2 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002bd0:	85a6                	mv	a1,s1
    80002bd2:	00006517          	auipc	a0,0x6
    80002bd6:	84e50513          	addi	a0,a0,-1970 # 80008420 <states.0+0x38>
    80002bda:	ffffe097          	auipc	ra,0xffffe
    80002bde:	9c2080e7          	jalr	-1598(ra) # 8000059c <printf>
      plic_complete(irq);
    80002be2:	8526                	mv	a0,s1
    80002be4:	00003097          	auipc	ra,0x3
    80002be8:	718080e7          	jalr	1816(ra) # 800062fc <plic_complete>
    return 1;
    80002bec:	4505                	li	a0,1
    80002bee:	bf55                	j	80002ba2 <devintr+0x1e>
      uartintr();
    80002bf0:	ffffe097          	auipc	ra,0xffffe
    80002bf4:	dba080e7          	jalr	-582(ra) # 800009aa <uartintr>
    80002bf8:	b7ed                	j	80002be2 <devintr+0x5e>
      virtio_disk_intr();
    80002bfa:	00004097          	auipc	ra,0x4
    80002bfe:	bca080e7          	jalr	-1078(ra) # 800067c4 <virtio_disk_intr>
    80002c02:	b7c5                	j	80002be2 <devintr+0x5e>
    if(cpuid() == 0){
    80002c04:	fffff097          	auipc	ra,0xfffff
    80002c08:	fc8080e7          	jalr	-56(ra) # 80001bcc <cpuid>
    80002c0c:	c901                	beqz	a0,80002c1c <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002c0e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002c12:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002c14:	14479073          	csrw	sip,a5
    return 2;
    80002c18:	4509                	li	a0,2
    80002c1a:	b761                	j	80002ba2 <devintr+0x1e>
      clockintr();
    80002c1c:	00000097          	auipc	ra,0x0
    80002c20:	f22080e7          	jalr	-222(ra) # 80002b3e <clockintr>
    80002c24:	b7ed                	j	80002c0e <devintr+0x8a>

0000000080002c26 <usertrap>:
{
    80002c26:	7139                	addi	sp,sp,-64
    80002c28:	fc06                	sd	ra,56(sp)
    80002c2a:	f822                	sd	s0,48(sp)
    80002c2c:	f426                	sd	s1,40(sp)
    80002c2e:	f04a                	sd	s2,32(sp)
    80002c30:	ec4e                	sd	s3,24(sp)
    80002c32:	e852                	sd	s4,16(sp)
    80002c34:	e456                	sd	s5,8(sp)
    80002c36:	e05a                	sd	s6,0(sp)
    80002c38:	0080                	addi	s0,sp,64
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c3a:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002c3e:	1007f793          	andi	a5,a5,256
    80002c42:	efb1                	bnez	a5,80002c9e <usertrap+0x78>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c44:	00003797          	auipc	a5,0x3
    80002c48:	58c78793          	addi	a5,a5,1420 # 800061d0 <kernelvec>
    80002c4c:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002c50:	fffff097          	auipc	ra,0xfffff
    80002c54:	fa8080e7          	jalr	-88(ra) # 80001bf8 <myproc>
    80002c58:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002c5a:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c5c:	14102773          	csrr	a4,sepc
    80002c60:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c62:	14202773          	csrr	a4,scause
  if (r_scause() == 15) {
    80002c66:	47bd                	li	a5,15
    80002c68:	04f70363          	beq	a4,a5,80002cae <usertrap+0x88>
    80002c6c:	14202773          	csrr	a4,scause
  } else if(r_scause() == 8){
    80002c70:	47a1                	li	a5,8
    80002c72:	10f70463          	beq	a4,a5,80002d7a <usertrap+0x154>
    80002c76:	14202773          	csrr	a4,scause
  } else if(r_scause() == 13){
    80002c7a:	47b5                	li	a5,13
    80002c7c:	12f70963          	beq	a4,a5,80002dae <usertrap+0x188>
  } else if((which_dev = devintr()) != 0){
    80002c80:	00000097          	auipc	ra,0x0
    80002c84:	f04080e7          	jalr	-252(ra) # 80002b84 <devintr>
    80002c88:	892a                	mv	s2,a0
    80002c8a:	18050a63          	beqz	a0,80002e1e <usertrap+0x1f8>
  if(killed(p))
    80002c8e:	8526                	mv	a0,s1
    80002c90:	00000097          	auipc	ra,0x0
    80002c94:	9d0080e7          	jalr	-1584(ra) # 80002660 <killed>
    80002c98:	1c050663          	beqz	a0,80002e64 <usertrap+0x23e>
    80002c9c:	aa7d                	j	80002e5a <usertrap+0x234>
    panic("usertrap: not from user mode");
    80002c9e:	00005517          	auipc	a0,0x5
    80002ca2:	7a250513          	addi	a0,a0,1954 # 80008440 <states.0+0x58>
    80002ca6:	ffffe097          	auipc	ra,0xffffe
    80002caa:	89a080e7          	jalr	-1894(ra) # 80000540 <panic>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002cae:	143029f3          	csrr	s3,stval
    pte_t *pte = walk(p->pagetable, virtual_address, 0);
    80002cb2:	4601                	li	a2,0
    80002cb4:	85ce                	mv	a1,s3
    80002cb6:	6928                	ld	a0,80(a0)
    80002cb8:	ffffe097          	auipc	ra,0xffffe
    80002cbc:	430080e7          	jalr	1072(ra) # 800010e8 <walk>
    if (pte && (*pte & PTE_C)) {
    80002cc0:	c509                	beqz	a0,80002cca <usertrap+0xa4>
    80002cc2:	611c                	ld	a5,0(a0)
    80002cc4:	1007f713          	andi	a4,a5,256
    80002cc8:	e70d                	bnez	a4,80002cf2 <usertrap+0xcc>
      printf("Segmentation fault (pid=%d)\n", p->pid);
    80002cca:	588c                	lw	a1,48(s1)
    80002ccc:	00005517          	auipc	a0,0x5
    80002cd0:	79450513          	addi	a0,a0,1940 # 80008460 <states.0+0x78>
    80002cd4:	ffffe097          	auipc	ra,0xffffe
    80002cd8:	8c8080e7          	jalr	-1848(ra) # 8000059c <printf>
      setkilled(p);
    80002cdc:	8526                	mv	a0,s1
    80002cde:	00000097          	auipc	ra,0x0
    80002ce2:	956080e7          	jalr	-1706(ra) # 80002634 <setkilled>
      exit(-1); // Kanskje bytt ut med return -1
    80002ce6:	557d                	li	a0,-1
    80002ce8:	00000097          	auipc	ra,0x0
    80002cec:	804080e7          	jalr	-2044(ra) # 800024ec <exit>
    80002cf0:	a219                	j	80002df6 <usertrap+0x1d0>
      pagetable_t pt = p->pagetable;
    80002cf2:	0504bb03          	ld	s6,80(s1)
      uint64 physical_address = PTE2PA(*pte);
    80002cf6:	00a7da93          	srli	s5,a5,0xa
    80002cfa:	0ab2                	slli	s5,s5,0xc
      flags = flags & ~PTE_C;
    80002cfc:	2ff7f793          	andi	a5,a5,767
      flags = flags | PTE_W;
    80002d00:	0047e913          	ori	s2,a5,4
      if((mem = kalloc()) == 0) {
    80002d04:	ffffe097          	auipc	ra,0xffffe
    80002d08:	ec8080e7          	jalr	-312(ra) # 80000bcc <kalloc>
    80002d0c:	8a2a                	mv	s4,a0
    80002d0e:	c921                	beqz	a0,80002d5e <usertrap+0x138>
      memmove(mem, (char*)physical_address, PGSIZE);
    80002d10:	6605                	lui	a2,0x1
    80002d12:	85d6                	mv	a1,s5
    80002d14:	8552                	mv	a0,s4
    80002d16:	ffffe097          	auipc	ra,0xffffe
    80002d1a:	14a080e7          	jalr	330(ra) # 80000e60 <memmove>
      uvmunmap(pt, PGROUNDDOWN(virtual_address), 1, 1); // Burde jeg ha round up eller round down?
    80002d1e:	77fd                	lui	a5,0xfffff
    80002d20:	00f9f9b3          	and	s3,s3,a5
    80002d24:	4685                	li	a3,1
    80002d26:	4605                	li	a2,1
    80002d28:	85ce                	mv	a1,s3
    80002d2a:	855a                	mv	a0,s6
    80002d2c:	ffffe097          	auipc	ra,0xffffe
    80002d30:	66a080e7          	jalr	1642(ra) # 80001396 <uvmunmap>
      if(mappages(pt, PGROUNDDOWN(virtual_address), PGSIZE, (uint64)mem, flags) != 0){
    80002d34:	874a                	mv	a4,s2
    80002d36:	86d2                	mv	a3,s4
    80002d38:	6605                	lui	a2,0x1
    80002d3a:	85ce                	mv	a1,s3
    80002d3c:	855a                	mv	a0,s6
    80002d3e:	ffffe097          	auipc	ra,0xffffe
    80002d42:	492080e7          	jalr	1170(ra) # 800011d0 <mappages>
    80002d46:	c945                	beqz	a0,80002df6 <usertrap+0x1d0>
        kfree(mem);
    80002d48:	8552                	mv	a0,s4
    80002d4a:	ffffe097          	auipc	ra,0xffffe
    80002d4e:	cf0080e7          	jalr	-784(ra) # 80000a3a <kfree>
        exit(-1); // Kanskje bytt ut med return -1
    80002d52:	557d                	li	a0,-1
    80002d54:	fffff097          	auipc	ra,0xfffff
    80002d58:	798080e7          	jalr	1944(ra) # 800024ec <exit>
    80002d5c:	a869                	j	80002df6 <usertrap+0x1d0>
        uvmunmap(pt, 0, 1, 1);
    80002d5e:	4685                	li	a3,1
    80002d60:	4605                	li	a2,1
    80002d62:	4581                	li	a1,0
    80002d64:	855a                	mv	a0,s6
    80002d66:	ffffe097          	auipc	ra,0xffffe
    80002d6a:	630080e7          	jalr	1584(ra) # 80001396 <uvmunmap>
        exit(-1); // Kanskje bytt ut med return -1
    80002d6e:	557d                	li	a0,-1
    80002d70:	fffff097          	auipc	ra,0xfffff
    80002d74:	77c080e7          	jalr	1916(ra) # 800024ec <exit>
    80002d78:	bf61                	j	80002d10 <usertrap+0xea>
    if(killed(p))
    80002d7a:	00000097          	auipc	ra,0x0
    80002d7e:	8e6080e7          	jalr	-1818(ra) # 80002660 <killed>
    80002d82:	e105                	bnez	a0,80002da2 <usertrap+0x17c>
    p->trapframe->epc += 4;
    80002d84:	6cb8                	ld	a4,88(s1)
    80002d86:	6f1c                	ld	a5,24(a4)
    80002d88:	0791                	addi	a5,a5,4 # fffffffffffff004 <end+0xffffffff7fb9d0c4>
    80002d8a:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d8c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002d90:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d94:	10079073          	csrw	sstatus,a5
    syscall();
    80002d98:	00000097          	auipc	ra,0x0
    80002d9c:	336080e7          	jalr	822(ra) # 800030ce <syscall>
    80002da0:	a899                	j	80002df6 <usertrap+0x1d0>
      exit(-1);
    80002da2:	557d                	li	a0,-1
    80002da4:	fffff097          	auipc	ra,0xfffff
    80002da8:	748080e7          	jalr	1864(ra) # 800024ec <exit>
    80002dac:	bfe1                	j	80002d84 <usertrap+0x15e>
    printf("Feil. feil 13!!!\n");
    80002dae:	00005517          	auipc	a0,0x5
    80002db2:	6d250513          	addi	a0,a0,1746 # 80008480 <states.0+0x98>
    80002db6:	ffffd097          	auipc	ra,0xffffd
    80002dba:	7e6080e7          	jalr	2022(ra) # 8000059c <printf>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002dbe:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002dc2:	5890                	lw	a2,48(s1)
    80002dc4:	00005517          	auipc	a0,0x5
    80002dc8:	6d450513          	addi	a0,a0,1748 # 80008498 <states.0+0xb0>
    80002dcc:	ffffd097          	auipc	ra,0xffffd
    80002dd0:	7d0080e7          	jalr	2000(ra) # 8000059c <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002dd4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002dd8:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ddc:	00005517          	auipc	a0,0x5
    80002de0:	6ec50513          	addi	a0,a0,1772 # 800084c8 <states.0+0xe0>
    80002de4:	ffffd097          	auipc	ra,0xffffd
    80002de8:	7b8080e7          	jalr	1976(ra) # 8000059c <printf>
    setkilled(p);
    80002dec:	8526                	mv	a0,s1
    80002dee:	00000097          	auipc	ra,0x0
    80002df2:	846080e7          	jalr	-1978(ra) # 80002634 <setkilled>
  if(killed(p))
    80002df6:	8526                	mv	a0,s1
    80002df8:	00000097          	auipc	ra,0x0
    80002dfc:	868080e7          	jalr	-1944(ra) # 80002660 <killed>
    80002e00:	ed21                	bnez	a0,80002e58 <usertrap+0x232>
  usertrapret();
    80002e02:	00000097          	auipc	ra,0x0
    80002e06:	ca6080e7          	jalr	-858(ra) # 80002aa8 <usertrapret>
}
    80002e0a:	70e2                	ld	ra,56(sp)
    80002e0c:	7442                	ld	s0,48(sp)
    80002e0e:	74a2                	ld	s1,40(sp)
    80002e10:	7902                	ld	s2,32(sp)
    80002e12:	69e2                	ld	s3,24(sp)
    80002e14:	6a42                	ld	s4,16(sp)
    80002e16:	6aa2                	ld	s5,8(sp)
    80002e18:	6b02                	ld	s6,0(sp)
    80002e1a:	6121                	addi	sp,sp,64
    80002e1c:	8082                	ret
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e1e:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002e22:	5890                	lw	a2,48(s1)
    80002e24:	00005517          	auipc	a0,0x5
    80002e28:	67450513          	addi	a0,a0,1652 # 80008498 <states.0+0xb0>
    80002e2c:	ffffd097          	auipc	ra,0xffffd
    80002e30:	770080e7          	jalr	1904(ra) # 8000059c <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e34:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e38:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e3c:	00005517          	auipc	a0,0x5
    80002e40:	68c50513          	addi	a0,a0,1676 # 800084c8 <states.0+0xe0>
    80002e44:	ffffd097          	auipc	ra,0xffffd
    80002e48:	758080e7          	jalr	1880(ra) # 8000059c <printf>
    setkilled(p);
    80002e4c:	8526                	mv	a0,s1
    80002e4e:	fffff097          	auipc	ra,0xfffff
    80002e52:	7e6080e7          	jalr	2022(ra) # 80002634 <setkilled>
    80002e56:	b745                	j	80002df6 <usertrap+0x1d0>
  if(killed(p))
    80002e58:	4901                	li	s2,0
    exit(-1);
    80002e5a:	557d                	li	a0,-1
    80002e5c:	fffff097          	auipc	ra,0xfffff
    80002e60:	690080e7          	jalr	1680(ra) # 800024ec <exit>
  if(which_dev == 2)
    80002e64:	4789                	li	a5,2
    80002e66:	f8f91ee3          	bne	s2,a5,80002e02 <usertrap+0x1dc>
    yield();
    80002e6a:	fffff097          	auipc	ra,0xfffff
    80002e6e:	512080e7          	jalr	1298(ra) # 8000237c <yield>
    80002e72:	bf41                	j	80002e02 <usertrap+0x1dc>

0000000080002e74 <kerneltrap>:
{
    80002e74:	7179                	addi	sp,sp,-48
    80002e76:	f406                	sd	ra,40(sp)
    80002e78:	f022                	sd	s0,32(sp)
    80002e7a:	ec26                	sd	s1,24(sp)
    80002e7c:	e84a                	sd	s2,16(sp)
    80002e7e:	e44e                	sd	s3,8(sp)
    80002e80:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e82:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e86:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e8a:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002e8e:	1004f793          	andi	a5,s1,256
    80002e92:	cb85                	beqz	a5,80002ec2 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e94:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002e98:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002e9a:	ef85                	bnez	a5,80002ed2 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002e9c:	00000097          	auipc	ra,0x0
    80002ea0:	ce8080e7          	jalr	-792(ra) # 80002b84 <devintr>
    80002ea4:	cd1d                	beqz	a0,80002ee2 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ea6:	4789                	li	a5,2
    80002ea8:	08f50263          	beq	a0,a5,80002f2c <kerneltrap+0xb8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002eac:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002eb0:	10049073          	csrw	sstatus,s1
}
    80002eb4:	70a2                	ld	ra,40(sp)
    80002eb6:	7402                	ld	s0,32(sp)
    80002eb8:	64e2                	ld	s1,24(sp)
    80002eba:	6942                	ld	s2,16(sp)
    80002ebc:	69a2                	ld	s3,8(sp)
    80002ebe:	6145                	addi	sp,sp,48
    80002ec0:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002ec2:	00005517          	auipc	a0,0x5
    80002ec6:	62650513          	addi	a0,a0,1574 # 800084e8 <states.0+0x100>
    80002eca:	ffffd097          	auipc	ra,0xffffd
    80002ece:	676080e7          	jalr	1654(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002ed2:	00005517          	auipc	a0,0x5
    80002ed6:	63e50513          	addi	a0,a0,1598 # 80008510 <states.0+0x128>
    80002eda:	ffffd097          	auipc	ra,0xffffd
    80002ede:	666080e7          	jalr	1638(ra) # 80000540 <panic>
    printf("Failed badly...\n");
    80002ee2:	00005517          	auipc	a0,0x5
    80002ee6:	64e50513          	addi	a0,a0,1614 # 80008530 <states.0+0x148>
    80002eea:	ffffd097          	auipc	ra,0xffffd
    80002eee:	6b2080e7          	jalr	1714(ra) # 8000059c <printf>
    printf("scause %p\n", scause);
    80002ef2:	85ce                	mv	a1,s3
    80002ef4:	00005517          	auipc	a0,0x5
    80002ef8:	65450513          	addi	a0,a0,1620 # 80008548 <states.0+0x160>
    80002efc:	ffffd097          	auipc	ra,0xffffd
    80002f00:	6a0080e7          	jalr	1696(ra) # 8000059c <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f04:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f08:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f0c:	00005517          	auipc	a0,0x5
    80002f10:	64c50513          	addi	a0,a0,1612 # 80008558 <states.0+0x170>
    80002f14:	ffffd097          	auipc	ra,0xffffd
    80002f18:	688080e7          	jalr	1672(ra) # 8000059c <printf>
    panic("kerneltrap");
    80002f1c:	00005517          	auipc	a0,0x5
    80002f20:	65450513          	addi	a0,a0,1620 # 80008570 <states.0+0x188>
    80002f24:	ffffd097          	auipc	ra,0xffffd
    80002f28:	61c080e7          	jalr	1564(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002f2c:	fffff097          	auipc	ra,0xfffff
    80002f30:	ccc080e7          	jalr	-820(ra) # 80001bf8 <myproc>
    80002f34:	dd25                	beqz	a0,80002eac <kerneltrap+0x38>
    80002f36:	fffff097          	auipc	ra,0xfffff
    80002f3a:	cc2080e7          	jalr	-830(ra) # 80001bf8 <myproc>
    80002f3e:	4d18                	lw	a4,24(a0)
    80002f40:	4791                	li	a5,4
    80002f42:	f6f715e3          	bne	a4,a5,80002eac <kerneltrap+0x38>
    yield();
    80002f46:	fffff097          	auipc	ra,0xfffff
    80002f4a:	436080e7          	jalr	1078(ra) # 8000237c <yield>
    80002f4e:	bfb9                	j	80002eac <kerneltrap+0x38>

0000000080002f50 <argraw>:
    return strlen(buf);
}

static uint64
argraw(int n)
{
    80002f50:	1101                	addi	sp,sp,-32
    80002f52:	ec06                	sd	ra,24(sp)
    80002f54:	e822                	sd	s0,16(sp)
    80002f56:	e426                	sd	s1,8(sp)
    80002f58:	1000                	addi	s0,sp,32
    80002f5a:	84aa                	mv	s1,a0
    struct proc *p = myproc();
    80002f5c:	fffff097          	auipc	ra,0xfffff
    80002f60:	c9c080e7          	jalr	-868(ra) # 80001bf8 <myproc>
    switch (n)
    80002f64:	4795                	li	a5,5
    80002f66:	0497e163          	bltu	a5,s1,80002fa8 <argraw+0x58>
    80002f6a:	048a                	slli	s1,s1,0x2
    80002f6c:	00005717          	auipc	a4,0x5
    80002f70:	63c70713          	addi	a4,a4,1596 # 800085a8 <states.0+0x1c0>
    80002f74:	94ba                	add	s1,s1,a4
    80002f76:	409c                	lw	a5,0(s1)
    80002f78:	97ba                	add	a5,a5,a4
    80002f7a:	8782                	jr	a5
    {
    case 0:
        return p->trapframe->a0;
    80002f7c:	6d3c                	ld	a5,88(a0)
    80002f7e:	7ba8                	ld	a0,112(a5)
    case 5:
        return p->trapframe->a5;
    }
    panic("argraw");
    return -1;
}
    80002f80:	60e2                	ld	ra,24(sp)
    80002f82:	6442                	ld	s0,16(sp)
    80002f84:	64a2                	ld	s1,8(sp)
    80002f86:	6105                	addi	sp,sp,32
    80002f88:	8082                	ret
        return p->trapframe->a1;
    80002f8a:	6d3c                	ld	a5,88(a0)
    80002f8c:	7fa8                	ld	a0,120(a5)
    80002f8e:	bfcd                	j	80002f80 <argraw+0x30>
        return p->trapframe->a2;
    80002f90:	6d3c                	ld	a5,88(a0)
    80002f92:	63c8                	ld	a0,128(a5)
    80002f94:	b7f5                	j	80002f80 <argraw+0x30>
        return p->trapframe->a3;
    80002f96:	6d3c                	ld	a5,88(a0)
    80002f98:	67c8                	ld	a0,136(a5)
    80002f9a:	b7dd                	j	80002f80 <argraw+0x30>
        return p->trapframe->a4;
    80002f9c:	6d3c                	ld	a5,88(a0)
    80002f9e:	6bc8                	ld	a0,144(a5)
    80002fa0:	b7c5                	j	80002f80 <argraw+0x30>
        return p->trapframe->a5;
    80002fa2:	6d3c                	ld	a5,88(a0)
    80002fa4:	6fc8                	ld	a0,152(a5)
    80002fa6:	bfe9                	j	80002f80 <argraw+0x30>
    panic("argraw");
    80002fa8:	00005517          	auipc	a0,0x5
    80002fac:	5d850513          	addi	a0,a0,1496 # 80008580 <states.0+0x198>
    80002fb0:	ffffd097          	auipc	ra,0xffffd
    80002fb4:	590080e7          	jalr	1424(ra) # 80000540 <panic>

0000000080002fb8 <fetchaddr>:
{
    80002fb8:	1101                	addi	sp,sp,-32
    80002fba:	ec06                	sd	ra,24(sp)
    80002fbc:	e822                	sd	s0,16(sp)
    80002fbe:	e426                	sd	s1,8(sp)
    80002fc0:	e04a                	sd	s2,0(sp)
    80002fc2:	1000                	addi	s0,sp,32
    80002fc4:	84aa                	mv	s1,a0
    80002fc6:	892e                	mv	s2,a1
    struct proc *p = myproc();
    80002fc8:	fffff097          	auipc	ra,0xfffff
    80002fcc:	c30080e7          	jalr	-976(ra) # 80001bf8 <myproc>
    if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002fd0:	653c                	ld	a5,72(a0)
    80002fd2:	02f4f863          	bgeu	s1,a5,80003002 <fetchaddr+0x4a>
    80002fd6:	00848713          	addi	a4,s1,8
    80002fda:	02e7e663          	bltu	a5,a4,80003006 <fetchaddr+0x4e>
    if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002fde:	46a1                	li	a3,8
    80002fe0:	8626                	mv	a2,s1
    80002fe2:	85ca                	mv	a1,s2
    80002fe4:	6928                	ld	a0,80(a0)
    80002fe6:	fffff097          	auipc	ra,0xfffff
    80002fea:	860080e7          	jalr	-1952(ra) # 80001846 <copyin>
    80002fee:	00a03533          	snez	a0,a0
    80002ff2:	40a00533          	neg	a0,a0
}
    80002ff6:	60e2                	ld	ra,24(sp)
    80002ff8:	6442                	ld	s0,16(sp)
    80002ffa:	64a2                	ld	s1,8(sp)
    80002ffc:	6902                	ld	s2,0(sp)
    80002ffe:	6105                	addi	sp,sp,32
    80003000:	8082                	ret
        return -1;
    80003002:	557d                	li	a0,-1
    80003004:	bfcd                	j	80002ff6 <fetchaddr+0x3e>
    80003006:	557d                	li	a0,-1
    80003008:	b7fd                	j	80002ff6 <fetchaddr+0x3e>

000000008000300a <fetchstr>:
{
    8000300a:	7179                	addi	sp,sp,-48
    8000300c:	f406                	sd	ra,40(sp)
    8000300e:	f022                	sd	s0,32(sp)
    80003010:	ec26                	sd	s1,24(sp)
    80003012:	e84a                	sd	s2,16(sp)
    80003014:	e44e                	sd	s3,8(sp)
    80003016:	1800                	addi	s0,sp,48
    80003018:	892a                	mv	s2,a0
    8000301a:	84ae                	mv	s1,a1
    8000301c:	89b2                	mv	s3,a2
    struct proc *p = myproc();
    8000301e:	fffff097          	auipc	ra,0xfffff
    80003022:	bda080e7          	jalr	-1062(ra) # 80001bf8 <myproc>
    if (copyinstr(p->pagetable, buf, addr, max) < 0)
    80003026:	86ce                	mv	a3,s3
    80003028:	864a                	mv	a2,s2
    8000302a:	85a6                	mv	a1,s1
    8000302c:	6928                	ld	a0,80(a0)
    8000302e:	fffff097          	auipc	ra,0xfffff
    80003032:	8a6080e7          	jalr	-1882(ra) # 800018d4 <copyinstr>
    80003036:	00054e63          	bltz	a0,80003052 <fetchstr+0x48>
    return strlen(buf);
    8000303a:	8526                	mv	a0,s1
    8000303c:	ffffe097          	auipc	ra,0xffffe
    80003040:	f44080e7          	jalr	-188(ra) # 80000f80 <strlen>
}
    80003044:	70a2                	ld	ra,40(sp)
    80003046:	7402                	ld	s0,32(sp)
    80003048:	64e2                	ld	s1,24(sp)
    8000304a:	6942                	ld	s2,16(sp)
    8000304c:	69a2                	ld	s3,8(sp)
    8000304e:	6145                	addi	sp,sp,48
    80003050:	8082                	ret
        return -1;
    80003052:	557d                	li	a0,-1
    80003054:	bfc5                	j	80003044 <fetchstr+0x3a>

0000000080003056 <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    80003056:	1101                	addi	sp,sp,-32
    80003058:	ec06                	sd	ra,24(sp)
    8000305a:	e822                	sd	s0,16(sp)
    8000305c:	e426                	sd	s1,8(sp)
    8000305e:	1000                	addi	s0,sp,32
    80003060:	84ae                	mv	s1,a1
    *ip = argraw(n);
    80003062:	00000097          	auipc	ra,0x0
    80003066:	eee080e7          	jalr	-274(ra) # 80002f50 <argraw>
    8000306a:	c088                	sw	a0,0(s1)
}
    8000306c:	60e2                	ld	ra,24(sp)
    8000306e:	6442                	ld	s0,16(sp)
    80003070:	64a2                	ld	s1,8(sp)
    80003072:	6105                	addi	sp,sp,32
    80003074:	8082                	ret

0000000080003076 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    80003076:	1101                	addi	sp,sp,-32
    80003078:	ec06                	sd	ra,24(sp)
    8000307a:	e822                	sd	s0,16(sp)
    8000307c:	e426                	sd	s1,8(sp)
    8000307e:	1000                	addi	s0,sp,32
    80003080:	84ae                	mv	s1,a1
    *ip = argraw(n);
    80003082:	00000097          	auipc	ra,0x0
    80003086:	ece080e7          	jalr	-306(ra) # 80002f50 <argraw>
    8000308a:	e088                	sd	a0,0(s1)
}
    8000308c:	60e2                	ld	ra,24(sp)
    8000308e:	6442                	ld	s0,16(sp)
    80003090:	64a2                	ld	s1,8(sp)
    80003092:	6105                	addi	sp,sp,32
    80003094:	8082                	ret

0000000080003096 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80003096:	7179                	addi	sp,sp,-48
    80003098:	f406                	sd	ra,40(sp)
    8000309a:	f022                	sd	s0,32(sp)
    8000309c:	ec26                	sd	s1,24(sp)
    8000309e:	e84a                	sd	s2,16(sp)
    800030a0:	1800                	addi	s0,sp,48
    800030a2:	84ae                	mv	s1,a1
    800030a4:	8932                	mv	s2,a2
    uint64 addr;
    argaddr(n, &addr);
    800030a6:	fd840593          	addi	a1,s0,-40
    800030aa:	00000097          	auipc	ra,0x0
    800030ae:	fcc080e7          	jalr	-52(ra) # 80003076 <argaddr>
    return fetchstr(addr, buf, max);
    800030b2:	864a                	mv	a2,s2
    800030b4:	85a6                	mv	a1,s1
    800030b6:	fd843503          	ld	a0,-40(s0)
    800030ba:	00000097          	auipc	ra,0x0
    800030be:	f50080e7          	jalr	-176(ra) # 8000300a <fetchstr>
}
    800030c2:	70a2                	ld	ra,40(sp)
    800030c4:	7402                	ld	s0,32(sp)
    800030c6:	64e2                	ld	s1,24(sp)
    800030c8:	6942                	ld	s2,16(sp)
    800030ca:	6145                	addi	sp,sp,48
    800030cc:	8082                	ret

00000000800030ce <syscall>:
    [SYS_pfreepages] sys_pfreepages,
    [SYS_va2pa] sys_va2pa,
};

void syscall(void)
{
    800030ce:	1101                	addi	sp,sp,-32
    800030d0:	ec06                	sd	ra,24(sp)
    800030d2:	e822                	sd	s0,16(sp)
    800030d4:	e426                	sd	s1,8(sp)
    800030d6:	e04a                	sd	s2,0(sp)
    800030d8:	1000                	addi	s0,sp,32
    int num;
    struct proc *p = myproc();
    800030da:	fffff097          	auipc	ra,0xfffff
    800030de:	b1e080e7          	jalr	-1250(ra) # 80001bf8 <myproc>
    800030e2:	84aa                	mv	s1,a0

    num = p->trapframe->a7;
    800030e4:	05853903          	ld	s2,88(a0)
    800030e8:	0a893783          	ld	a5,168(s2)
    800030ec:	0007869b          	sext.w	a3,a5
    if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    800030f0:	37fd                	addiw	a5,a5,-1
    800030f2:	4765                	li	a4,25
    800030f4:	00f76f63          	bltu	a4,a5,80003112 <syscall+0x44>
    800030f8:	00369713          	slli	a4,a3,0x3
    800030fc:	00005797          	auipc	a5,0x5
    80003100:	4c478793          	addi	a5,a5,1220 # 800085c0 <syscalls>
    80003104:	97ba                	add	a5,a5,a4
    80003106:	639c                	ld	a5,0(a5)
    80003108:	c789                	beqz	a5,80003112 <syscall+0x44>
    {
        // Use num to lookup the system call function for num, call it,
        // and store its return value in p->trapframe->a0
        p->trapframe->a0 = syscalls[num]();
    8000310a:	9782                	jalr	a5
    8000310c:	06a93823          	sd	a0,112(s2)
    80003110:	a839                	j	8000312e <syscall+0x60>
    }
    else
    {
        printf("%d %s: unknown sys call %d\n",
    80003112:	15848613          	addi	a2,s1,344
    80003116:	588c                	lw	a1,48(s1)
    80003118:	00005517          	auipc	a0,0x5
    8000311c:	47050513          	addi	a0,a0,1136 # 80008588 <states.0+0x1a0>
    80003120:	ffffd097          	auipc	ra,0xffffd
    80003124:	47c080e7          	jalr	1148(ra) # 8000059c <printf>
               p->pid, p->name, num);
        p->trapframe->a0 = -1;
    80003128:	6cbc                	ld	a5,88(s1)
    8000312a:	577d                	li	a4,-1
    8000312c:	fbb8                	sd	a4,112(a5)
    }
}
    8000312e:	60e2                	ld	ra,24(sp)
    80003130:	6442                	ld	s0,16(sp)
    80003132:	64a2                	ld	s1,8(sp)
    80003134:	6902                	ld	s2,0(sp)
    80003136:	6105                	addi	sp,sp,32
    80003138:	8082                	ret

000000008000313a <sys_exit>:

extern uint64 FREE_PAGES; // kalloc.c keeps track of those

uint64
sys_exit(void)
{
    8000313a:	1101                	addi	sp,sp,-32
    8000313c:	ec06                	sd	ra,24(sp)
    8000313e:	e822                	sd	s0,16(sp)
    80003140:	1000                	addi	s0,sp,32
    int n;
    argint(0, &n);
    80003142:	fec40593          	addi	a1,s0,-20
    80003146:	4501                	li	a0,0
    80003148:	00000097          	auipc	ra,0x0
    8000314c:	f0e080e7          	jalr	-242(ra) # 80003056 <argint>
    exit(n);
    80003150:	fec42503          	lw	a0,-20(s0)
    80003154:	fffff097          	auipc	ra,0xfffff
    80003158:	398080e7          	jalr	920(ra) # 800024ec <exit>
    return 0; // not reached
}
    8000315c:	4501                	li	a0,0
    8000315e:	60e2                	ld	ra,24(sp)
    80003160:	6442                	ld	s0,16(sp)
    80003162:	6105                	addi	sp,sp,32
    80003164:	8082                	ret

0000000080003166 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003166:	1141                	addi	sp,sp,-16
    80003168:	e406                	sd	ra,8(sp)
    8000316a:	e022                	sd	s0,0(sp)
    8000316c:	0800                	addi	s0,sp,16
    return myproc()->pid;
    8000316e:	fffff097          	auipc	ra,0xfffff
    80003172:	a8a080e7          	jalr	-1398(ra) # 80001bf8 <myproc>
}
    80003176:	5908                	lw	a0,48(a0)
    80003178:	60a2                	ld	ra,8(sp)
    8000317a:	6402                	ld	s0,0(sp)
    8000317c:	0141                	addi	sp,sp,16
    8000317e:	8082                	ret

0000000080003180 <sys_fork>:

uint64
sys_fork(void)
{
    80003180:	1141                	addi	sp,sp,-16
    80003182:	e406                	sd	ra,8(sp)
    80003184:	e022                	sd	s0,0(sp)
    80003186:	0800                	addi	s0,sp,16
    return fork();
    80003188:	fffff097          	auipc	ra,0xfffff
    8000318c:	fbc080e7          	jalr	-68(ra) # 80002144 <fork>
}
    80003190:	60a2                	ld	ra,8(sp)
    80003192:	6402                	ld	s0,0(sp)
    80003194:	0141                	addi	sp,sp,16
    80003196:	8082                	ret

0000000080003198 <sys_wait>:

uint64
sys_wait(void)
{
    80003198:	1101                	addi	sp,sp,-32
    8000319a:	ec06                	sd	ra,24(sp)
    8000319c:	e822                	sd	s0,16(sp)
    8000319e:	1000                	addi	s0,sp,32
    uint64 p;
    argaddr(0, &p);
    800031a0:	fe840593          	addi	a1,s0,-24
    800031a4:	4501                	li	a0,0
    800031a6:	00000097          	auipc	ra,0x0
    800031aa:	ed0080e7          	jalr	-304(ra) # 80003076 <argaddr>
    return wait(p);
    800031ae:	fe843503          	ld	a0,-24(s0)
    800031b2:	fffff097          	auipc	ra,0xfffff
    800031b6:	4e0080e7          	jalr	1248(ra) # 80002692 <wait>
}
    800031ba:	60e2                	ld	ra,24(sp)
    800031bc:	6442                	ld	s0,16(sp)
    800031be:	6105                	addi	sp,sp,32
    800031c0:	8082                	ret

00000000800031c2 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800031c2:	7179                	addi	sp,sp,-48
    800031c4:	f406                	sd	ra,40(sp)
    800031c6:	f022                	sd	s0,32(sp)
    800031c8:	ec26                	sd	s1,24(sp)
    800031ca:	1800                	addi	s0,sp,48
    uint64 addr;
    int n;

    argint(0, &n);
    800031cc:	fdc40593          	addi	a1,s0,-36
    800031d0:	4501                	li	a0,0
    800031d2:	00000097          	auipc	ra,0x0
    800031d6:	e84080e7          	jalr	-380(ra) # 80003056 <argint>
    addr = myproc()->sz;
    800031da:	fffff097          	auipc	ra,0xfffff
    800031de:	a1e080e7          	jalr	-1506(ra) # 80001bf8 <myproc>
    800031e2:	6524                	ld	s1,72(a0)
    if (growproc(n) < 0)
    800031e4:	fdc42503          	lw	a0,-36(s0)
    800031e8:	fffff097          	auipc	ra,0xfffff
    800031ec:	d6a080e7          	jalr	-662(ra) # 80001f52 <growproc>
    800031f0:	00054863          	bltz	a0,80003200 <sys_sbrk+0x3e>
        return -1;
    return addr;
}
    800031f4:	8526                	mv	a0,s1
    800031f6:	70a2                	ld	ra,40(sp)
    800031f8:	7402                	ld	s0,32(sp)
    800031fa:	64e2                	ld	s1,24(sp)
    800031fc:	6145                	addi	sp,sp,48
    800031fe:	8082                	ret
        return -1;
    80003200:	54fd                	li	s1,-1
    80003202:	bfcd                	j	800031f4 <sys_sbrk+0x32>

0000000080003204 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003204:	7139                	addi	sp,sp,-64
    80003206:	fc06                	sd	ra,56(sp)
    80003208:	f822                	sd	s0,48(sp)
    8000320a:	f426                	sd	s1,40(sp)
    8000320c:	f04a                	sd	s2,32(sp)
    8000320e:	ec4e                	sd	s3,24(sp)
    80003210:	0080                	addi	s0,sp,64
    int n;
    uint ticks0;

    argint(0, &n);
    80003212:	fcc40593          	addi	a1,s0,-52
    80003216:	4501                	li	a0,0
    80003218:	00000097          	auipc	ra,0x0
    8000321c:	e3e080e7          	jalr	-450(ra) # 80003056 <argint>
    acquire(&tickslock);
    80003220:	00454517          	auipc	a0,0x454
    80003224:	94050513          	addi	a0,a0,-1728 # 80456b60 <tickslock>
    80003228:	ffffe097          	auipc	ra,0xffffe
    8000322c:	ae0080e7          	jalr	-1312(ra) # 80000d08 <acquire>
    ticks0 = ticks;
    80003230:	00006917          	auipc	s2,0x6
    80003234:	89092903          	lw	s2,-1904(s2) # 80008ac0 <ticks>
    while (ticks - ticks0 < n)
    80003238:	fcc42783          	lw	a5,-52(s0)
    8000323c:	cf9d                	beqz	a5,8000327a <sys_sleep+0x76>
        if (killed(myproc()))
        {
            release(&tickslock);
            return -1;
        }
        sleep(&ticks, &tickslock);
    8000323e:	00454997          	auipc	s3,0x454
    80003242:	92298993          	addi	s3,s3,-1758 # 80456b60 <tickslock>
    80003246:	00006497          	auipc	s1,0x6
    8000324a:	87a48493          	addi	s1,s1,-1926 # 80008ac0 <ticks>
        if (killed(myproc()))
    8000324e:	fffff097          	auipc	ra,0xfffff
    80003252:	9aa080e7          	jalr	-1622(ra) # 80001bf8 <myproc>
    80003256:	fffff097          	auipc	ra,0xfffff
    8000325a:	40a080e7          	jalr	1034(ra) # 80002660 <killed>
    8000325e:	ed15                	bnez	a0,8000329a <sys_sleep+0x96>
        sleep(&ticks, &tickslock);
    80003260:	85ce                	mv	a1,s3
    80003262:	8526                	mv	a0,s1
    80003264:	fffff097          	auipc	ra,0xfffff
    80003268:	154080e7          	jalr	340(ra) # 800023b8 <sleep>
    while (ticks - ticks0 < n)
    8000326c:	409c                	lw	a5,0(s1)
    8000326e:	412787bb          	subw	a5,a5,s2
    80003272:	fcc42703          	lw	a4,-52(s0)
    80003276:	fce7ece3          	bltu	a5,a4,8000324e <sys_sleep+0x4a>
    }
    release(&tickslock);
    8000327a:	00454517          	auipc	a0,0x454
    8000327e:	8e650513          	addi	a0,a0,-1818 # 80456b60 <tickslock>
    80003282:	ffffe097          	auipc	ra,0xffffe
    80003286:	b3a080e7          	jalr	-1222(ra) # 80000dbc <release>
    return 0;
    8000328a:	4501                	li	a0,0
}
    8000328c:	70e2                	ld	ra,56(sp)
    8000328e:	7442                	ld	s0,48(sp)
    80003290:	74a2                	ld	s1,40(sp)
    80003292:	7902                	ld	s2,32(sp)
    80003294:	69e2                	ld	s3,24(sp)
    80003296:	6121                	addi	sp,sp,64
    80003298:	8082                	ret
            release(&tickslock);
    8000329a:	00454517          	auipc	a0,0x454
    8000329e:	8c650513          	addi	a0,a0,-1850 # 80456b60 <tickslock>
    800032a2:	ffffe097          	auipc	ra,0xffffe
    800032a6:	b1a080e7          	jalr	-1254(ra) # 80000dbc <release>
            return -1;
    800032aa:	557d                	li	a0,-1
    800032ac:	b7c5                	j	8000328c <sys_sleep+0x88>

00000000800032ae <sys_kill>:

uint64
sys_kill(void)
{
    800032ae:	1101                	addi	sp,sp,-32
    800032b0:	ec06                	sd	ra,24(sp)
    800032b2:	e822                	sd	s0,16(sp)
    800032b4:	1000                	addi	s0,sp,32
    int pid;

    argint(0, &pid);
    800032b6:	fec40593          	addi	a1,s0,-20
    800032ba:	4501                	li	a0,0
    800032bc:	00000097          	auipc	ra,0x0
    800032c0:	d9a080e7          	jalr	-614(ra) # 80003056 <argint>
    return kill(pid);
    800032c4:	fec42503          	lw	a0,-20(s0)
    800032c8:	fffff097          	auipc	ra,0xfffff
    800032cc:	2fa080e7          	jalr	762(ra) # 800025c2 <kill>
}
    800032d0:	60e2                	ld	ra,24(sp)
    800032d2:	6442                	ld	s0,16(sp)
    800032d4:	6105                	addi	sp,sp,32
    800032d6:	8082                	ret

00000000800032d8 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800032d8:	1101                	addi	sp,sp,-32
    800032da:	ec06                	sd	ra,24(sp)
    800032dc:	e822                	sd	s0,16(sp)
    800032de:	e426                	sd	s1,8(sp)
    800032e0:	1000                	addi	s0,sp,32
    uint xticks;

    acquire(&tickslock);
    800032e2:	00454517          	auipc	a0,0x454
    800032e6:	87e50513          	addi	a0,a0,-1922 # 80456b60 <tickslock>
    800032ea:	ffffe097          	auipc	ra,0xffffe
    800032ee:	a1e080e7          	jalr	-1506(ra) # 80000d08 <acquire>
    xticks = ticks;
    800032f2:	00005497          	auipc	s1,0x5
    800032f6:	7ce4a483          	lw	s1,1998(s1) # 80008ac0 <ticks>
    release(&tickslock);
    800032fa:	00454517          	auipc	a0,0x454
    800032fe:	86650513          	addi	a0,a0,-1946 # 80456b60 <tickslock>
    80003302:	ffffe097          	auipc	ra,0xffffe
    80003306:	aba080e7          	jalr	-1350(ra) # 80000dbc <release>
    return xticks;
}
    8000330a:	02049513          	slli	a0,s1,0x20
    8000330e:	9101                	srli	a0,a0,0x20
    80003310:	60e2                	ld	ra,24(sp)
    80003312:	6442                	ld	s0,16(sp)
    80003314:	64a2                	ld	s1,8(sp)
    80003316:	6105                	addi	sp,sp,32
    80003318:	8082                	ret

000000008000331a <sys_ps>:

void *
sys_ps(void)
{
    8000331a:	1101                	addi	sp,sp,-32
    8000331c:	ec06                	sd	ra,24(sp)
    8000331e:	e822                	sd	s0,16(sp)
    80003320:	1000                	addi	s0,sp,32
    int start = 0, count = 0;
    80003322:	fe042623          	sw	zero,-20(s0)
    80003326:	fe042423          	sw	zero,-24(s0)
    argint(0, &start);
    8000332a:	fec40593          	addi	a1,s0,-20
    8000332e:	4501                	li	a0,0
    80003330:	00000097          	auipc	ra,0x0
    80003334:	d26080e7          	jalr	-730(ra) # 80003056 <argint>
    argint(1, &count);
    80003338:	fe840593          	addi	a1,s0,-24
    8000333c:	4505                	li	a0,1
    8000333e:	00000097          	auipc	ra,0x0
    80003342:	d18080e7          	jalr	-744(ra) # 80003056 <argint>
    return ps((uint8)start, (uint8)count);
    80003346:	fe844583          	lbu	a1,-24(s0)
    8000334a:	fec44503          	lbu	a0,-20(s0)
    8000334e:	fffff097          	auipc	ra,0xfffff
    80003352:	c60080e7          	jalr	-928(ra) # 80001fae <ps>
}
    80003356:	60e2                	ld	ra,24(sp)
    80003358:	6442                	ld	s0,16(sp)
    8000335a:	6105                	addi	sp,sp,32
    8000335c:	8082                	ret

000000008000335e <sys_schedls>:

uint64 sys_schedls(void)
{
    8000335e:	1141                	addi	sp,sp,-16
    80003360:	e406                	sd	ra,8(sp)
    80003362:	e022                	sd	s0,0(sp)
    80003364:	0800                	addi	s0,sp,16
    schedls();
    80003366:	fffff097          	auipc	ra,0xfffff
    8000336a:	5b6080e7          	jalr	1462(ra) # 8000291c <schedls>
    return 0;
}
    8000336e:	4501                	li	a0,0
    80003370:	60a2                	ld	ra,8(sp)
    80003372:	6402                	ld	s0,0(sp)
    80003374:	0141                	addi	sp,sp,16
    80003376:	8082                	ret

0000000080003378 <sys_schedset>:

uint64 sys_schedset(void)
{
    80003378:	1101                	addi	sp,sp,-32
    8000337a:	ec06                	sd	ra,24(sp)
    8000337c:	e822                	sd	s0,16(sp)
    8000337e:	1000                	addi	s0,sp,32
    int id = 0;
    80003380:	fe042623          	sw	zero,-20(s0)
    argint(0, &id);
    80003384:	fec40593          	addi	a1,s0,-20
    80003388:	4501                	li	a0,0
    8000338a:	00000097          	auipc	ra,0x0
    8000338e:	ccc080e7          	jalr	-820(ra) # 80003056 <argint>
    schedset(id - 1);
    80003392:	fec42503          	lw	a0,-20(s0)
    80003396:	357d                	addiw	a0,a0,-1
    80003398:	fffff097          	auipc	ra,0xfffff
    8000339c:	61a080e7          	jalr	1562(ra) # 800029b2 <schedset>
    return 0;
}
    800033a0:	4501                	li	a0,0
    800033a2:	60e2                	ld	ra,24(sp)
    800033a4:	6442                	ld	s0,16(sp)
    800033a6:	6105                	addi	sp,sp,32
    800033a8:	8082                	ret

00000000800033aa <sys_va2pa>:

extern struct proc proc[];

uint64 sys_va2pa(void)
{
    800033aa:	1101                	addi	sp,sp,-32
    800033ac:	ec06                	sd	ra,24(sp)
    800033ae:	e822                	sd	s0,16(sp)
    800033b0:	1000                	addi	s0,sp,32
    uint64 virtual_address;
    int process_id;

    argaddr(0, &virtual_address);
    800033b2:	fe840593          	addi	a1,s0,-24
    800033b6:	4501                	li	a0,0
    800033b8:	00000097          	auipc	ra,0x0
    800033bc:	cbe080e7          	jalr	-834(ra) # 80003076 <argaddr>
    argint(1, &process_id);
    800033c0:	fe440593          	addi	a1,s0,-28
    800033c4:	4505                	li	a0,1
    800033c6:	00000097          	auipc	ra,0x0
    800033ca:	c90080e7          	jalr	-880(ra) # 80003056 <argint>
    
    pagetable_t pagetable;

    if (process_id <= 0) {
    800033ce:	fe442683          	lw	a3,-28(s0)
        pagetable = myproc()->pagetable;
    }
    else {
        struct proc *p;
        int found = 0;
        for (p = proc; p < &proc[NPROC]; p++) {
    800033d2:	0044e797          	auipc	a5,0x44e
    800033d6:	d8e78793          	addi	a5,a5,-626 # 80451160 <proc>
    800033da:	00453617          	auipc	a2,0x453
    800033de:	78660613          	addi	a2,a2,1926 # 80456b60 <tickslock>
    if (process_id <= 0) {
    800033e2:	00d05b63          	blez	a3,800033f8 <sys_va2pa+0x4e>
            if (p->pid == process_id) {
    800033e6:	5b98                	lw	a4,48(a5)
    800033e8:	00d70e63          	beq	a4,a3,80003404 <sys_va2pa+0x5a>
        for (p = proc; p < &proc[NPROC]; p++) {
    800033ec:	16878793          	addi	a5,a5,360
    800033f0:	fec79be3          	bne	a5,a2,800033e6 <sys_va2pa+0x3c>
                break;
            }
        }
        // If found is 0, then the user has provided a non-existing pid
        if (found == 0) {
            return 0;
    800033f4:	4501                	li	a0,0
    800033f6:	a831                	j	80003412 <sys_va2pa+0x68>
        pagetable = myproc()->pagetable;
    800033f8:	fffff097          	auipc	ra,0xfffff
    800033fc:	800080e7          	jalr	-2048(ra) # 80001bf8 <myproc>
    80003400:	6928                	ld	a0,80(a0)
    80003402:	a011                	j	80003406 <sys_va2pa+0x5c>
                pagetable = p->pagetable;
    80003404:	6ba8                	ld	a0,80(a5)
        }
    }
    uint64 physical_address = walkaddr(pagetable, virtual_address);
    80003406:	fe843583          	ld	a1,-24(s0)
    8000340a:	ffffe097          	auipc	ra,0xffffe
    8000340e:	d84080e7          	jalr	-636(ra) # 8000118e <walkaddr>
    return physical_address;
}
    80003412:	60e2                	ld	ra,24(sp)
    80003414:	6442                	ld	s0,16(sp)
    80003416:	6105                	addi	sp,sp,32
    80003418:	8082                	ret

000000008000341a <sys_pfreepages>:

uint64 sys_pfreepages(void)
{
    8000341a:	1141                	addi	sp,sp,-16
    8000341c:	e406                	sd	ra,8(sp)
    8000341e:	e022                	sd	s0,0(sp)
    80003420:	0800                	addi	s0,sp,16
    printf("%d\n", FREE_PAGES);
    80003422:	00005597          	auipc	a1,0x5
    80003426:	6765b583          	ld	a1,1654(a1) # 80008a98 <FREE_PAGES>
    8000342a:	00005517          	auipc	a0,0x5
    8000342e:	17650513          	addi	a0,a0,374 # 800085a0 <states.0+0x1b8>
    80003432:	ffffd097          	auipc	ra,0xffffd
    80003436:	16a080e7          	jalr	362(ra) # 8000059c <printf>
    return 0;
    8000343a:	4501                	li	a0,0
    8000343c:	60a2                	ld	ra,8(sp)
    8000343e:	6402                	ld	s0,0(sp)
    80003440:	0141                	addi	sp,sp,16
    80003442:	8082                	ret

0000000080003444 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003444:	7179                	addi	sp,sp,-48
    80003446:	f406                	sd	ra,40(sp)
    80003448:	f022                	sd	s0,32(sp)
    8000344a:	ec26                	sd	s1,24(sp)
    8000344c:	e84a                	sd	s2,16(sp)
    8000344e:	e44e                	sd	s3,8(sp)
    80003450:	e052                	sd	s4,0(sp)
    80003452:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003454:	00005597          	auipc	a1,0x5
    80003458:	24458593          	addi	a1,a1,580 # 80008698 <syscalls+0xd8>
    8000345c:	00453517          	auipc	a0,0x453
    80003460:	71c50513          	addi	a0,a0,1820 # 80456b78 <bcache>
    80003464:	ffffe097          	auipc	ra,0xffffe
    80003468:	814080e7          	jalr	-2028(ra) # 80000c78 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000346c:	0045b797          	auipc	a5,0x45b
    80003470:	70c78793          	addi	a5,a5,1804 # 8045eb78 <bcache+0x8000>
    80003474:	0045c717          	auipc	a4,0x45c
    80003478:	96c70713          	addi	a4,a4,-1684 # 8045ede0 <bcache+0x8268>
    8000347c:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003480:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003484:	00453497          	auipc	s1,0x453
    80003488:	70c48493          	addi	s1,s1,1804 # 80456b90 <bcache+0x18>
    b->next = bcache.head.next;
    8000348c:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000348e:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003490:	00005a17          	auipc	s4,0x5
    80003494:	210a0a13          	addi	s4,s4,528 # 800086a0 <syscalls+0xe0>
    b->next = bcache.head.next;
    80003498:	2b893783          	ld	a5,696(s2)
    8000349c:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000349e:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800034a2:	85d2                	mv	a1,s4
    800034a4:	01048513          	addi	a0,s1,16
    800034a8:	00001097          	auipc	ra,0x1
    800034ac:	4c8080e7          	jalr	1224(ra) # 80004970 <initsleeplock>
    bcache.head.next->prev = b;
    800034b0:	2b893783          	ld	a5,696(s2)
    800034b4:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800034b6:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800034ba:	45848493          	addi	s1,s1,1112
    800034be:	fd349de3          	bne	s1,s3,80003498 <binit+0x54>
  }
}
    800034c2:	70a2                	ld	ra,40(sp)
    800034c4:	7402                	ld	s0,32(sp)
    800034c6:	64e2                	ld	s1,24(sp)
    800034c8:	6942                	ld	s2,16(sp)
    800034ca:	69a2                	ld	s3,8(sp)
    800034cc:	6a02                	ld	s4,0(sp)
    800034ce:	6145                	addi	sp,sp,48
    800034d0:	8082                	ret

00000000800034d2 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800034d2:	7179                	addi	sp,sp,-48
    800034d4:	f406                	sd	ra,40(sp)
    800034d6:	f022                	sd	s0,32(sp)
    800034d8:	ec26                	sd	s1,24(sp)
    800034da:	e84a                	sd	s2,16(sp)
    800034dc:	e44e                	sd	s3,8(sp)
    800034de:	1800                	addi	s0,sp,48
    800034e0:	892a                	mv	s2,a0
    800034e2:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800034e4:	00453517          	auipc	a0,0x453
    800034e8:	69450513          	addi	a0,a0,1684 # 80456b78 <bcache>
    800034ec:	ffffe097          	auipc	ra,0xffffe
    800034f0:	81c080e7          	jalr	-2020(ra) # 80000d08 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800034f4:	0045c497          	auipc	s1,0x45c
    800034f8:	93c4b483          	ld	s1,-1732(s1) # 8045ee30 <bcache+0x82b8>
    800034fc:	0045c797          	auipc	a5,0x45c
    80003500:	8e478793          	addi	a5,a5,-1820 # 8045ede0 <bcache+0x8268>
    80003504:	02f48f63          	beq	s1,a5,80003542 <bread+0x70>
    80003508:	873e                	mv	a4,a5
    8000350a:	a021                	j	80003512 <bread+0x40>
    8000350c:	68a4                	ld	s1,80(s1)
    8000350e:	02e48a63          	beq	s1,a4,80003542 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003512:	449c                	lw	a5,8(s1)
    80003514:	ff279ce3          	bne	a5,s2,8000350c <bread+0x3a>
    80003518:	44dc                	lw	a5,12(s1)
    8000351a:	ff3799e3          	bne	a5,s3,8000350c <bread+0x3a>
      b->refcnt++;
    8000351e:	40bc                	lw	a5,64(s1)
    80003520:	2785                	addiw	a5,a5,1
    80003522:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003524:	00453517          	auipc	a0,0x453
    80003528:	65450513          	addi	a0,a0,1620 # 80456b78 <bcache>
    8000352c:	ffffe097          	auipc	ra,0xffffe
    80003530:	890080e7          	jalr	-1904(ra) # 80000dbc <release>
      acquiresleep(&b->lock);
    80003534:	01048513          	addi	a0,s1,16
    80003538:	00001097          	auipc	ra,0x1
    8000353c:	472080e7          	jalr	1138(ra) # 800049aa <acquiresleep>
      return b;
    80003540:	a8b9                	j	8000359e <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003542:	0045c497          	auipc	s1,0x45c
    80003546:	8e64b483          	ld	s1,-1818(s1) # 8045ee28 <bcache+0x82b0>
    8000354a:	0045c797          	auipc	a5,0x45c
    8000354e:	89678793          	addi	a5,a5,-1898 # 8045ede0 <bcache+0x8268>
    80003552:	00f48863          	beq	s1,a5,80003562 <bread+0x90>
    80003556:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003558:	40bc                	lw	a5,64(s1)
    8000355a:	cf81                	beqz	a5,80003572 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000355c:	64a4                	ld	s1,72(s1)
    8000355e:	fee49de3          	bne	s1,a4,80003558 <bread+0x86>
  panic("bget: no buffers");
    80003562:	00005517          	auipc	a0,0x5
    80003566:	14650513          	addi	a0,a0,326 # 800086a8 <syscalls+0xe8>
    8000356a:	ffffd097          	auipc	ra,0xffffd
    8000356e:	fd6080e7          	jalr	-42(ra) # 80000540 <panic>
      b->dev = dev;
    80003572:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003576:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000357a:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000357e:	4785                	li	a5,1
    80003580:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003582:	00453517          	auipc	a0,0x453
    80003586:	5f650513          	addi	a0,a0,1526 # 80456b78 <bcache>
    8000358a:	ffffe097          	auipc	ra,0xffffe
    8000358e:	832080e7          	jalr	-1998(ra) # 80000dbc <release>
      acquiresleep(&b->lock);
    80003592:	01048513          	addi	a0,s1,16
    80003596:	00001097          	auipc	ra,0x1
    8000359a:	414080e7          	jalr	1044(ra) # 800049aa <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000359e:	409c                	lw	a5,0(s1)
    800035a0:	cb89                	beqz	a5,800035b2 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800035a2:	8526                	mv	a0,s1
    800035a4:	70a2                	ld	ra,40(sp)
    800035a6:	7402                	ld	s0,32(sp)
    800035a8:	64e2                	ld	s1,24(sp)
    800035aa:	6942                	ld	s2,16(sp)
    800035ac:	69a2                	ld	s3,8(sp)
    800035ae:	6145                	addi	sp,sp,48
    800035b0:	8082                	ret
    virtio_disk_rw(b, 0);
    800035b2:	4581                	li	a1,0
    800035b4:	8526                	mv	a0,s1
    800035b6:	00003097          	auipc	ra,0x3
    800035ba:	fdc080e7          	jalr	-36(ra) # 80006592 <virtio_disk_rw>
    b->valid = 1;
    800035be:	4785                	li	a5,1
    800035c0:	c09c                	sw	a5,0(s1)
  return b;
    800035c2:	b7c5                	j	800035a2 <bread+0xd0>

00000000800035c4 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800035c4:	1101                	addi	sp,sp,-32
    800035c6:	ec06                	sd	ra,24(sp)
    800035c8:	e822                	sd	s0,16(sp)
    800035ca:	e426                	sd	s1,8(sp)
    800035cc:	1000                	addi	s0,sp,32
    800035ce:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800035d0:	0541                	addi	a0,a0,16
    800035d2:	00001097          	auipc	ra,0x1
    800035d6:	472080e7          	jalr	1138(ra) # 80004a44 <holdingsleep>
    800035da:	cd01                	beqz	a0,800035f2 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800035dc:	4585                	li	a1,1
    800035de:	8526                	mv	a0,s1
    800035e0:	00003097          	auipc	ra,0x3
    800035e4:	fb2080e7          	jalr	-78(ra) # 80006592 <virtio_disk_rw>
}
    800035e8:	60e2                	ld	ra,24(sp)
    800035ea:	6442                	ld	s0,16(sp)
    800035ec:	64a2                	ld	s1,8(sp)
    800035ee:	6105                	addi	sp,sp,32
    800035f0:	8082                	ret
    panic("bwrite");
    800035f2:	00005517          	auipc	a0,0x5
    800035f6:	0ce50513          	addi	a0,a0,206 # 800086c0 <syscalls+0x100>
    800035fa:	ffffd097          	auipc	ra,0xffffd
    800035fe:	f46080e7          	jalr	-186(ra) # 80000540 <panic>

0000000080003602 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003602:	1101                	addi	sp,sp,-32
    80003604:	ec06                	sd	ra,24(sp)
    80003606:	e822                	sd	s0,16(sp)
    80003608:	e426                	sd	s1,8(sp)
    8000360a:	e04a                	sd	s2,0(sp)
    8000360c:	1000                	addi	s0,sp,32
    8000360e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003610:	01050913          	addi	s2,a0,16
    80003614:	854a                	mv	a0,s2
    80003616:	00001097          	auipc	ra,0x1
    8000361a:	42e080e7          	jalr	1070(ra) # 80004a44 <holdingsleep>
    8000361e:	c92d                	beqz	a0,80003690 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003620:	854a                	mv	a0,s2
    80003622:	00001097          	auipc	ra,0x1
    80003626:	3de080e7          	jalr	990(ra) # 80004a00 <releasesleep>

  acquire(&bcache.lock);
    8000362a:	00453517          	auipc	a0,0x453
    8000362e:	54e50513          	addi	a0,a0,1358 # 80456b78 <bcache>
    80003632:	ffffd097          	auipc	ra,0xffffd
    80003636:	6d6080e7          	jalr	1750(ra) # 80000d08 <acquire>
  b->refcnt--;
    8000363a:	40bc                	lw	a5,64(s1)
    8000363c:	37fd                	addiw	a5,a5,-1
    8000363e:	0007871b          	sext.w	a4,a5
    80003642:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003644:	eb05                	bnez	a4,80003674 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003646:	68bc                	ld	a5,80(s1)
    80003648:	64b8                	ld	a4,72(s1)
    8000364a:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000364c:	64bc                	ld	a5,72(s1)
    8000364e:	68b8                	ld	a4,80(s1)
    80003650:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003652:	0045b797          	auipc	a5,0x45b
    80003656:	52678793          	addi	a5,a5,1318 # 8045eb78 <bcache+0x8000>
    8000365a:	2b87b703          	ld	a4,696(a5)
    8000365e:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003660:	0045b717          	auipc	a4,0x45b
    80003664:	78070713          	addi	a4,a4,1920 # 8045ede0 <bcache+0x8268>
    80003668:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000366a:	2b87b703          	ld	a4,696(a5)
    8000366e:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003670:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003674:	00453517          	auipc	a0,0x453
    80003678:	50450513          	addi	a0,a0,1284 # 80456b78 <bcache>
    8000367c:	ffffd097          	auipc	ra,0xffffd
    80003680:	740080e7          	jalr	1856(ra) # 80000dbc <release>
}
    80003684:	60e2                	ld	ra,24(sp)
    80003686:	6442                	ld	s0,16(sp)
    80003688:	64a2                	ld	s1,8(sp)
    8000368a:	6902                	ld	s2,0(sp)
    8000368c:	6105                	addi	sp,sp,32
    8000368e:	8082                	ret
    panic("brelse");
    80003690:	00005517          	auipc	a0,0x5
    80003694:	03850513          	addi	a0,a0,56 # 800086c8 <syscalls+0x108>
    80003698:	ffffd097          	auipc	ra,0xffffd
    8000369c:	ea8080e7          	jalr	-344(ra) # 80000540 <panic>

00000000800036a0 <bpin>:

void
bpin(struct buf *b) {
    800036a0:	1101                	addi	sp,sp,-32
    800036a2:	ec06                	sd	ra,24(sp)
    800036a4:	e822                	sd	s0,16(sp)
    800036a6:	e426                	sd	s1,8(sp)
    800036a8:	1000                	addi	s0,sp,32
    800036aa:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800036ac:	00453517          	auipc	a0,0x453
    800036b0:	4cc50513          	addi	a0,a0,1228 # 80456b78 <bcache>
    800036b4:	ffffd097          	auipc	ra,0xffffd
    800036b8:	654080e7          	jalr	1620(ra) # 80000d08 <acquire>
  b->refcnt++;
    800036bc:	40bc                	lw	a5,64(s1)
    800036be:	2785                	addiw	a5,a5,1
    800036c0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800036c2:	00453517          	auipc	a0,0x453
    800036c6:	4b650513          	addi	a0,a0,1206 # 80456b78 <bcache>
    800036ca:	ffffd097          	auipc	ra,0xffffd
    800036ce:	6f2080e7          	jalr	1778(ra) # 80000dbc <release>
}
    800036d2:	60e2                	ld	ra,24(sp)
    800036d4:	6442                	ld	s0,16(sp)
    800036d6:	64a2                	ld	s1,8(sp)
    800036d8:	6105                	addi	sp,sp,32
    800036da:	8082                	ret

00000000800036dc <bunpin>:

void
bunpin(struct buf *b) {
    800036dc:	1101                	addi	sp,sp,-32
    800036de:	ec06                	sd	ra,24(sp)
    800036e0:	e822                	sd	s0,16(sp)
    800036e2:	e426                	sd	s1,8(sp)
    800036e4:	1000                	addi	s0,sp,32
    800036e6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800036e8:	00453517          	auipc	a0,0x453
    800036ec:	49050513          	addi	a0,a0,1168 # 80456b78 <bcache>
    800036f0:	ffffd097          	auipc	ra,0xffffd
    800036f4:	618080e7          	jalr	1560(ra) # 80000d08 <acquire>
  b->refcnt--;
    800036f8:	40bc                	lw	a5,64(s1)
    800036fa:	37fd                	addiw	a5,a5,-1
    800036fc:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800036fe:	00453517          	auipc	a0,0x453
    80003702:	47a50513          	addi	a0,a0,1146 # 80456b78 <bcache>
    80003706:	ffffd097          	auipc	ra,0xffffd
    8000370a:	6b6080e7          	jalr	1718(ra) # 80000dbc <release>
}
    8000370e:	60e2                	ld	ra,24(sp)
    80003710:	6442                	ld	s0,16(sp)
    80003712:	64a2                	ld	s1,8(sp)
    80003714:	6105                	addi	sp,sp,32
    80003716:	8082                	ret

0000000080003718 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003718:	1101                	addi	sp,sp,-32
    8000371a:	ec06                	sd	ra,24(sp)
    8000371c:	e822                	sd	s0,16(sp)
    8000371e:	e426                	sd	s1,8(sp)
    80003720:	e04a                	sd	s2,0(sp)
    80003722:	1000                	addi	s0,sp,32
    80003724:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003726:	00d5d59b          	srliw	a1,a1,0xd
    8000372a:	0045c797          	auipc	a5,0x45c
    8000372e:	b2a7a783          	lw	a5,-1238(a5) # 8045f254 <sb+0x1c>
    80003732:	9dbd                	addw	a1,a1,a5
    80003734:	00000097          	auipc	ra,0x0
    80003738:	d9e080e7          	jalr	-610(ra) # 800034d2 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000373c:	0074f713          	andi	a4,s1,7
    80003740:	4785                	li	a5,1
    80003742:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003746:	14ce                	slli	s1,s1,0x33
    80003748:	90d9                	srli	s1,s1,0x36
    8000374a:	00950733          	add	a4,a0,s1
    8000374e:	05874703          	lbu	a4,88(a4)
    80003752:	00e7f6b3          	and	a3,a5,a4
    80003756:	c69d                	beqz	a3,80003784 <bfree+0x6c>
    80003758:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000375a:	94aa                	add	s1,s1,a0
    8000375c:	fff7c793          	not	a5,a5
    80003760:	8f7d                	and	a4,a4,a5
    80003762:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003766:	00001097          	auipc	ra,0x1
    8000376a:	126080e7          	jalr	294(ra) # 8000488c <log_write>
  brelse(bp);
    8000376e:	854a                	mv	a0,s2
    80003770:	00000097          	auipc	ra,0x0
    80003774:	e92080e7          	jalr	-366(ra) # 80003602 <brelse>
}
    80003778:	60e2                	ld	ra,24(sp)
    8000377a:	6442                	ld	s0,16(sp)
    8000377c:	64a2                	ld	s1,8(sp)
    8000377e:	6902                	ld	s2,0(sp)
    80003780:	6105                	addi	sp,sp,32
    80003782:	8082                	ret
    panic("freeing free block");
    80003784:	00005517          	auipc	a0,0x5
    80003788:	f4c50513          	addi	a0,a0,-180 # 800086d0 <syscalls+0x110>
    8000378c:	ffffd097          	auipc	ra,0xffffd
    80003790:	db4080e7          	jalr	-588(ra) # 80000540 <panic>

0000000080003794 <balloc>:
{
    80003794:	711d                	addi	sp,sp,-96
    80003796:	ec86                	sd	ra,88(sp)
    80003798:	e8a2                	sd	s0,80(sp)
    8000379a:	e4a6                	sd	s1,72(sp)
    8000379c:	e0ca                	sd	s2,64(sp)
    8000379e:	fc4e                	sd	s3,56(sp)
    800037a0:	f852                	sd	s4,48(sp)
    800037a2:	f456                	sd	s5,40(sp)
    800037a4:	f05a                	sd	s6,32(sp)
    800037a6:	ec5e                	sd	s7,24(sp)
    800037a8:	e862                	sd	s8,16(sp)
    800037aa:	e466                	sd	s9,8(sp)
    800037ac:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800037ae:	0045c797          	auipc	a5,0x45c
    800037b2:	a8e7a783          	lw	a5,-1394(a5) # 8045f23c <sb+0x4>
    800037b6:	cff5                	beqz	a5,800038b2 <balloc+0x11e>
    800037b8:	8baa                	mv	s7,a0
    800037ba:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800037bc:	0045cb17          	auipc	s6,0x45c
    800037c0:	a7cb0b13          	addi	s6,s6,-1412 # 8045f238 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037c4:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800037c6:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037c8:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800037ca:	6c89                	lui	s9,0x2
    800037cc:	a061                	j	80003854 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    800037ce:	97ca                	add	a5,a5,s2
    800037d0:	8e55                	or	a2,a2,a3
    800037d2:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800037d6:	854a                	mv	a0,s2
    800037d8:	00001097          	auipc	ra,0x1
    800037dc:	0b4080e7          	jalr	180(ra) # 8000488c <log_write>
        brelse(bp);
    800037e0:	854a                	mv	a0,s2
    800037e2:	00000097          	auipc	ra,0x0
    800037e6:	e20080e7          	jalr	-480(ra) # 80003602 <brelse>
  bp = bread(dev, bno);
    800037ea:	85a6                	mv	a1,s1
    800037ec:	855e                	mv	a0,s7
    800037ee:	00000097          	auipc	ra,0x0
    800037f2:	ce4080e7          	jalr	-796(ra) # 800034d2 <bread>
    800037f6:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800037f8:	40000613          	li	a2,1024
    800037fc:	4581                	li	a1,0
    800037fe:	05850513          	addi	a0,a0,88
    80003802:	ffffd097          	auipc	ra,0xffffd
    80003806:	602080e7          	jalr	1538(ra) # 80000e04 <memset>
  log_write(bp);
    8000380a:	854a                	mv	a0,s2
    8000380c:	00001097          	auipc	ra,0x1
    80003810:	080080e7          	jalr	128(ra) # 8000488c <log_write>
  brelse(bp);
    80003814:	854a                	mv	a0,s2
    80003816:	00000097          	auipc	ra,0x0
    8000381a:	dec080e7          	jalr	-532(ra) # 80003602 <brelse>
}
    8000381e:	8526                	mv	a0,s1
    80003820:	60e6                	ld	ra,88(sp)
    80003822:	6446                	ld	s0,80(sp)
    80003824:	64a6                	ld	s1,72(sp)
    80003826:	6906                	ld	s2,64(sp)
    80003828:	79e2                	ld	s3,56(sp)
    8000382a:	7a42                	ld	s4,48(sp)
    8000382c:	7aa2                	ld	s5,40(sp)
    8000382e:	7b02                	ld	s6,32(sp)
    80003830:	6be2                	ld	s7,24(sp)
    80003832:	6c42                	ld	s8,16(sp)
    80003834:	6ca2                	ld	s9,8(sp)
    80003836:	6125                	addi	sp,sp,96
    80003838:	8082                	ret
    brelse(bp);
    8000383a:	854a                	mv	a0,s2
    8000383c:	00000097          	auipc	ra,0x0
    80003840:	dc6080e7          	jalr	-570(ra) # 80003602 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003844:	015c87bb          	addw	a5,s9,s5
    80003848:	00078a9b          	sext.w	s5,a5
    8000384c:	004b2703          	lw	a4,4(s6)
    80003850:	06eaf163          	bgeu	s5,a4,800038b2 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003854:	41fad79b          	sraiw	a5,s5,0x1f
    80003858:	0137d79b          	srliw	a5,a5,0x13
    8000385c:	015787bb          	addw	a5,a5,s5
    80003860:	40d7d79b          	sraiw	a5,a5,0xd
    80003864:	01cb2583          	lw	a1,28(s6)
    80003868:	9dbd                	addw	a1,a1,a5
    8000386a:	855e                	mv	a0,s7
    8000386c:	00000097          	auipc	ra,0x0
    80003870:	c66080e7          	jalr	-922(ra) # 800034d2 <bread>
    80003874:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003876:	004b2503          	lw	a0,4(s6)
    8000387a:	000a849b          	sext.w	s1,s5
    8000387e:	8762                	mv	a4,s8
    80003880:	faa4fde3          	bgeu	s1,a0,8000383a <balloc+0xa6>
      m = 1 << (bi % 8);
    80003884:	00777693          	andi	a3,a4,7
    80003888:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000388c:	41f7579b          	sraiw	a5,a4,0x1f
    80003890:	01d7d79b          	srliw	a5,a5,0x1d
    80003894:	9fb9                	addw	a5,a5,a4
    80003896:	4037d79b          	sraiw	a5,a5,0x3
    8000389a:	00f90633          	add	a2,s2,a5
    8000389e:	05864603          	lbu	a2,88(a2)
    800038a2:	00c6f5b3          	and	a1,a3,a2
    800038a6:	d585                	beqz	a1,800037ce <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038a8:	2705                	addiw	a4,a4,1
    800038aa:	2485                	addiw	s1,s1,1
    800038ac:	fd471ae3          	bne	a4,s4,80003880 <balloc+0xec>
    800038b0:	b769                	j	8000383a <balloc+0xa6>
  printf("balloc: out of blocks\n");
    800038b2:	00005517          	auipc	a0,0x5
    800038b6:	e3650513          	addi	a0,a0,-458 # 800086e8 <syscalls+0x128>
    800038ba:	ffffd097          	auipc	ra,0xffffd
    800038be:	ce2080e7          	jalr	-798(ra) # 8000059c <printf>
  return 0;
    800038c2:	4481                	li	s1,0
    800038c4:	bfa9                	j	8000381e <balloc+0x8a>

00000000800038c6 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800038c6:	7179                	addi	sp,sp,-48
    800038c8:	f406                	sd	ra,40(sp)
    800038ca:	f022                	sd	s0,32(sp)
    800038cc:	ec26                	sd	s1,24(sp)
    800038ce:	e84a                	sd	s2,16(sp)
    800038d0:	e44e                	sd	s3,8(sp)
    800038d2:	e052                	sd	s4,0(sp)
    800038d4:	1800                	addi	s0,sp,48
    800038d6:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800038d8:	47ad                	li	a5,11
    800038da:	02b7e863          	bltu	a5,a1,8000390a <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    800038de:	02059793          	slli	a5,a1,0x20
    800038e2:	01e7d593          	srli	a1,a5,0x1e
    800038e6:	00b504b3          	add	s1,a0,a1
    800038ea:	0504a903          	lw	s2,80(s1)
    800038ee:	06091e63          	bnez	s2,8000396a <bmap+0xa4>
      addr = balloc(ip->dev);
    800038f2:	4108                	lw	a0,0(a0)
    800038f4:	00000097          	auipc	ra,0x0
    800038f8:	ea0080e7          	jalr	-352(ra) # 80003794 <balloc>
    800038fc:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003900:	06090563          	beqz	s2,8000396a <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80003904:	0524a823          	sw	s2,80(s1)
    80003908:	a08d                	j	8000396a <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    8000390a:	ff45849b          	addiw	s1,a1,-12
    8000390e:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003912:	0ff00793          	li	a5,255
    80003916:	08e7e563          	bltu	a5,a4,800039a0 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    8000391a:	08052903          	lw	s2,128(a0)
    8000391e:	00091d63          	bnez	s2,80003938 <bmap+0x72>
      addr = balloc(ip->dev);
    80003922:	4108                	lw	a0,0(a0)
    80003924:	00000097          	auipc	ra,0x0
    80003928:	e70080e7          	jalr	-400(ra) # 80003794 <balloc>
    8000392c:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003930:	02090d63          	beqz	s2,8000396a <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003934:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003938:	85ca                	mv	a1,s2
    8000393a:	0009a503          	lw	a0,0(s3)
    8000393e:	00000097          	auipc	ra,0x0
    80003942:	b94080e7          	jalr	-1132(ra) # 800034d2 <bread>
    80003946:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003948:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000394c:	02049713          	slli	a4,s1,0x20
    80003950:	01e75593          	srli	a1,a4,0x1e
    80003954:	00b784b3          	add	s1,a5,a1
    80003958:	0004a903          	lw	s2,0(s1)
    8000395c:	02090063          	beqz	s2,8000397c <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003960:	8552                	mv	a0,s4
    80003962:	00000097          	auipc	ra,0x0
    80003966:	ca0080e7          	jalr	-864(ra) # 80003602 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000396a:	854a                	mv	a0,s2
    8000396c:	70a2                	ld	ra,40(sp)
    8000396e:	7402                	ld	s0,32(sp)
    80003970:	64e2                	ld	s1,24(sp)
    80003972:	6942                	ld	s2,16(sp)
    80003974:	69a2                	ld	s3,8(sp)
    80003976:	6a02                	ld	s4,0(sp)
    80003978:	6145                	addi	sp,sp,48
    8000397a:	8082                	ret
      addr = balloc(ip->dev);
    8000397c:	0009a503          	lw	a0,0(s3)
    80003980:	00000097          	auipc	ra,0x0
    80003984:	e14080e7          	jalr	-492(ra) # 80003794 <balloc>
    80003988:	0005091b          	sext.w	s2,a0
      if(addr){
    8000398c:	fc090ae3          	beqz	s2,80003960 <bmap+0x9a>
        a[bn] = addr;
    80003990:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003994:	8552                	mv	a0,s4
    80003996:	00001097          	auipc	ra,0x1
    8000399a:	ef6080e7          	jalr	-266(ra) # 8000488c <log_write>
    8000399e:	b7c9                	j	80003960 <bmap+0x9a>
  panic("bmap: out of range");
    800039a0:	00005517          	auipc	a0,0x5
    800039a4:	d6050513          	addi	a0,a0,-672 # 80008700 <syscalls+0x140>
    800039a8:	ffffd097          	auipc	ra,0xffffd
    800039ac:	b98080e7          	jalr	-1128(ra) # 80000540 <panic>

00000000800039b0 <iget>:
{
    800039b0:	7179                	addi	sp,sp,-48
    800039b2:	f406                	sd	ra,40(sp)
    800039b4:	f022                	sd	s0,32(sp)
    800039b6:	ec26                	sd	s1,24(sp)
    800039b8:	e84a                	sd	s2,16(sp)
    800039ba:	e44e                	sd	s3,8(sp)
    800039bc:	e052                	sd	s4,0(sp)
    800039be:	1800                	addi	s0,sp,48
    800039c0:	89aa                	mv	s3,a0
    800039c2:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800039c4:	0045c517          	auipc	a0,0x45c
    800039c8:	89450513          	addi	a0,a0,-1900 # 8045f258 <itable>
    800039cc:	ffffd097          	auipc	ra,0xffffd
    800039d0:	33c080e7          	jalr	828(ra) # 80000d08 <acquire>
  empty = 0;
    800039d4:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800039d6:	0045c497          	auipc	s1,0x45c
    800039da:	89a48493          	addi	s1,s1,-1894 # 8045f270 <itable+0x18>
    800039de:	0045d697          	auipc	a3,0x45d
    800039e2:	32268693          	addi	a3,a3,802 # 80460d00 <log>
    800039e6:	a039                	j	800039f4 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800039e8:	02090b63          	beqz	s2,80003a1e <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800039ec:	08848493          	addi	s1,s1,136
    800039f0:	02d48a63          	beq	s1,a3,80003a24 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800039f4:	449c                	lw	a5,8(s1)
    800039f6:	fef059e3          	blez	a5,800039e8 <iget+0x38>
    800039fa:	4098                	lw	a4,0(s1)
    800039fc:	ff3716e3          	bne	a4,s3,800039e8 <iget+0x38>
    80003a00:	40d8                	lw	a4,4(s1)
    80003a02:	ff4713e3          	bne	a4,s4,800039e8 <iget+0x38>
      ip->ref++;
    80003a06:	2785                	addiw	a5,a5,1
    80003a08:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003a0a:	0045c517          	auipc	a0,0x45c
    80003a0e:	84e50513          	addi	a0,a0,-1970 # 8045f258 <itable>
    80003a12:	ffffd097          	auipc	ra,0xffffd
    80003a16:	3aa080e7          	jalr	938(ra) # 80000dbc <release>
      return ip;
    80003a1a:	8926                	mv	s2,s1
    80003a1c:	a03d                	j	80003a4a <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a1e:	f7f9                	bnez	a5,800039ec <iget+0x3c>
    80003a20:	8926                	mv	s2,s1
    80003a22:	b7e9                	j	800039ec <iget+0x3c>
  if(empty == 0)
    80003a24:	02090c63          	beqz	s2,80003a5c <iget+0xac>
  ip->dev = dev;
    80003a28:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003a2c:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003a30:	4785                	li	a5,1
    80003a32:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003a36:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003a3a:	0045c517          	auipc	a0,0x45c
    80003a3e:	81e50513          	addi	a0,a0,-2018 # 8045f258 <itable>
    80003a42:	ffffd097          	auipc	ra,0xffffd
    80003a46:	37a080e7          	jalr	890(ra) # 80000dbc <release>
}
    80003a4a:	854a                	mv	a0,s2
    80003a4c:	70a2                	ld	ra,40(sp)
    80003a4e:	7402                	ld	s0,32(sp)
    80003a50:	64e2                	ld	s1,24(sp)
    80003a52:	6942                	ld	s2,16(sp)
    80003a54:	69a2                	ld	s3,8(sp)
    80003a56:	6a02                	ld	s4,0(sp)
    80003a58:	6145                	addi	sp,sp,48
    80003a5a:	8082                	ret
    panic("iget: no inodes");
    80003a5c:	00005517          	auipc	a0,0x5
    80003a60:	cbc50513          	addi	a0,a0,-836 # 80008718 <syscalls+0x158>
    80003a64:	ffffd097          	auipc	ra,0xffffd
    80003a68:	adc080e7          	jalr	-1316(ra) # 80000540 <panic>

0000000080003a6c <fsinit>:
fsinit(int dev) {
    80003a6c:	7179                	addi	sp,sp,-48
    80003a6e:	f406                	sd	ra,40(sp)
    80003a70:	f022                	sd	s0,32(sp)
    80003a72:	ec26                	sd	s1,24(sp)
    80003a74:	e84a                	sd	s2,16(sp)
    80003a76:	e44e                	sd	s3,8(sp)
    80003a78:	1800                	addi	s0,sp,48
    80003a7a:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003a7c:	4585                	li	a1,1
    80003a7e:	00000097          	auipc	ra,0x0
    80003a82:	a54080e7          	jalr	-1452(ra) # 800034d2 <bread>
    80003a86:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003a88:	0045b997          	auipc	s3,0x45b
    80003a8c:	7b098993          	addi	s3,s3,1968 # 8045f238 <sb>
    80003a90:	02000613          	li	a2,32
    80003a94:	05850593          	addi	a1,a0,88
    80003a98:	854e                	mv	a0,s3
    80003a9a:	ffffd097          	auipc	ra,0xffffd
    80003a9e:	3c6080e7          	jalr	966(ra) # 80000e60 <memmove>
  brelse(bp);
    80003aa2:	8526                	mv	a0,s1
    80003aa4:	00000097          	auipc	ra,0x0
    80003aa8:	b5e080e7          	jalr	-1186(ra) # 80003602 <brelse>
  if(sb.magic != FSMAGIC)
    80003aac:	0009a703          	lw	a4,0(s3)
    80003ab0:	102037b7          	lui	a5,0x10203
    80003ab4:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003ab8:	02f71263          	bne	a4,a5,80003adc <fsinit+0x70>
  initlog(dev, &sb);
    80003abc:	0045b597          	auipc	a1,0x45b
    80003ac0:	77c58593          	addi	a1,a1,1916 # 8045f238 <sb>
    80003ac4:	854a                	mv	a0,s2
    80003ac6:	00001097          	auipc	ra,0x1
    80003aca:	b4a080e7          	jalr	-1206(ra) # 80004610 <initlog>
}
    80003ace:	70a2                	ld	ra,40(sp)
    80003ad0:	7402                	ld	s0,32(sp)
    80003ad2:	64e2                	ld	s1,24(sp)
    80003ad4:	6942                	ld	s2,16(sp)
    80003ad6:	69a2                	ld	s3,8(sp)
    80003ad8:	6145                	addi	sp,sp,48
    80003ada:	8082                	ret
    panic("invalid file system");
    80003adc:	00005517          	auipc	a0,0x5
    80003ae0:	c4c50513          	addi	a0,a0,-948 # 80008728 <syscalls+0x168>
    80003ae4:	ffffd097          	auipc	ra,0xffffd
    80003ae8:	a5c080e7          	jalr	-1444(ra) # 80000540 <panic>

0000000080003aec <iinit>:
{
    80003aec:	7179                	addi	sp,sp,-48
    80003aee:	f406                	sd	ra,40(sp)
    80003af0:	f022                	sd	s0,32(sp)
    80003af2:	ec26                	sd	s1,24(sp)
    80003af4:	e84a                	sd	s2,16(sp)
    80003af6:	e44e                	sd	s3,8(sp)
    80003af8:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003afa:	00005597          	auipc	a1,0x5
    80003afe:	c4658593          	addi	a1,a1,-954 # 80008740 <syscalls+0x180>
    80003b02:	0045b517          	auipc	a0,0x45b
    80003b06:	75650513          	addi	a0,a0,1878 # 8045f258 <itable>
    80003b0a:	ffffd097          	auipc	ra,0xffffd
    80003b0e:	16e080e7          	jalr	366(ra) # 80000c78 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003b12:	0045b497          	auipc	s1,0x45b
    80003b16:	76e48493          	addi	s1,s1,1902 # 8045f280 <itable+0x28>
    80003b1a:	0045d997          	auipc	s3,0x45d
    80003b1e:	1f698993          	addi	s3,s3,502 # 80460d10 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003b22:	00005917          	auipc	s2,0x5
    80003b26:	c2690913          	addi	s2,s2,-986 # 80008748 <syscalls+0x188>
    80003b2a:	85ca                	mv	a1,s2
    80003b2c:	8526                	mv	a0,s1
    80003b2e:	00001097          	auipc	ra,0x1
    80003b32:	e42080e7          	jalr	-446(ra) # 80004970 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003b36:	08848493          	addi	s1,s1,136
    80003b3a:	ff3498e3          	bne	s1,s3,80003b2a <iinit+0x3e>
}
    80003b3e:	70a2                	ld	ra,40(sp)
    80003b40:	7402                	ld	s0,32(sp)
    80003b42:	64e2                	ld	s1,24(sp)
    80003b44:	6942                	ld	s2,16(sp)
    80003b46:	69a2                	ld	s3,8(sp)
    80003b48:	6145                	addi	sp,sp,48
    80003b4a:	8082                	ret

0000000080003b4c <ialloc>:
{
    80003b4c:	715d                	addi	sp,sp,-80
    80003b4e:	e486                	sd	ra,72(sp)
    80003b50:	e0a2                	sd	s0,64(sp)
    80003b52:	fc26                	sd	s1,56(sp)
    80003b54:	f84a                	sd	s2,48(sp)
    80003b56:	f44e                	sd	s3,40(sp)
    80003b58:	f052                	sd	s4,32(sp)
    80003b5a:	ec56                	sd	s5,24(sp)
    80003b5c:	e85a                	sd	s6,16(sp)
    80003b5e:	e45e                	sd	s7,8(sp)
    80003b60:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b62:	0045b717          	auipc	a4,0x45b
    80003b66:	6e272703          	lw	a4,1762(a4) # 8045f244 <sb+0xc>
    80003b6a:	4785                	li	a5,1
    80003b6c:	04e7fa63          	bgeu	a5,a4,80003bc0 <ialloc+0x74>
    80003b70:	8aaa                	mv	s5,a0
    80003b72:	8bae                	mv	s7,a1
    80003b74:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003b76:	0045ba17          	auipc	s4,0x45b
    80003b7a:	6c2a0a13          	addi	s4,s4,1730 # 8045f238 <sb>
    80003b7e:	00048b1b          	sext.w	s6,s1
    80003b82:	0044d593          	srli	a1,s1,0x4
    80003b86:	018a2783          	lw	a5,24(s4)
    80003b8a:	9dbd                	addw	a1,a1,a5
    80003b8c:	8556                	mv	a0,s5
    80003b8e:	00000097          	auipc	ra,0x0
    80003b92:	944080e7          	jalr	-1724(ra) # 800034d2 <bread>
    80003b96:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003b98:	05850993          	addi	s3,a0,88
    80003b9c:	00f4f793          	andi	a5,s1,15
    80003ba0:	079a                	slli	a5,a5,0x6
    80003ba2:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003ba4:	00099783          	lh	a5,0(s3)
    80003ba8:	c3a1                	beqz	a5,80003be8 <ialloc+0x9c>
    brelse(bp);
    80003baa:	00000097          	auipc	ra,0x0
    80003bae:	a58080e7          	jalr	-1448(ra) # 80003602 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003bb2:	0485                	addi	s1,s1,1
    80003bb4:	00ca2703          	lw	a4,12(s4)
    80003bb8:	0004879b          	sext.w	a5,s1
    80003bbc:	fce7e1e3          	bltu	a5,a4,80003b7e <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003bc0:	00005517          	auipc	a0,0x5
    80003bc4:	b9050513          	addi	a0,a0,-1136 # 80008750 <syscalls+0x190>
    80003bc8:	ffffd097          	auipc	ra,0xffffd
    80003bcc:	9d4080e7          	jalr	-1580(ra) # 8000059c <printf>
  return 0;
    80003bd0:	4501                	li	a0,0
}
    80003bd2:	60a6                	ld	ra,72(sp)
    80003bd4:	6406                	ld	s0,64(sp)
    80003bd6:	74e2                	ld	s1,56(sp)
    80003bd8:	7942                	ld	s2,48(sp)
    80003bda:	79a2                	ld	s3,40(sp)
    80003bdc:	7a02                	ld	s4,32(sp)
    80003bde:	6ae2                	ld	s5,24(sp)
    80003be0:	6b42                	ld	s6,16(sp)
    80003be2:	6ba2                	ld	s7,8(sp)
    80003be4:	6161                	addi	sp,sp,80
    80003be6:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003be8:	04000613          	li	a2,64
    80003bec:	4581                	li	a1,0
    80003bee:	854e                	mv	a0,s3
    80003bf0:	ffffd097          	auipc	ra,0xffffd
    80003bf4:	214080e7          	jalr	532(ra) # 80000e04 <memset>
      dip->type = type;
    80003bf8:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003bfc:	854a                	mv	a0,s2
    80003bfe:	00001097          	auipc	ra,0x1
    80003c02:	c8e080e7          	jalr	-882(ra) # 8000488c <log_write>
      brelse(bp);
    80003c06:	854a                	mv	a0,s2
    80003c08:	00000097          	auipc	ra,0x0
    80003c0c:	9fa080e7          	jalr	-1542(ra) # 80003602 <brelse>
      return iget(dev, inum);
    80003c10:	85da                	mv	a1,s6
    80003c12:	8556                	mv	a0,s5
    80003c14:	00000097          	auipc	ra,0x0
    80003c18:	d9c080e7          	jalr	-612(ra) # 800039b0 <iget>
    80003c1c:	bf5d                	j	80003bd2 <ialloc+0x86>

0000000080003c1e <iupdate>:
{
    80003c1e:	1101                	addi	sp,sp,-32
    80003c20:	ec06                	sd	ra,24(sp)
    80003c22:	e822                	sd	s0,16(sp)
    80003c24:	e426                	sd	s1,8(sp)
    80003c26:	e04a                	sd	s2,0(sp)
    80003c28:	1000                	addi	s0,sp,32
    80003c2a:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c2c:	415c                	lw	a5,4(a0)
    80003c2e:	0047d79b          	srliw	a5,a5,0x4
    80003c32:	0045b597          	auipc	a1,0x45b
    80003c36:	61e5a583          	lw	a1,1566(a1) # 8045f250 <sb+0x18>
    80003c3a:	9dbd                	addw	a1,a1,a5
    80003c3c:	4108                	lw	a0,0(a0)
    80003c3e:	00000097          	auipc	ra,0x0
    80003c42:	894080e7          	jalr	-1900(ra) # 800034d2 <bread>
    80003c46:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c48:	05850793          	addi	a5,a0,88
    80003c4c:	40d8                	lw	a4,4(s1)
    80003c4e:	8b3d                	andi	a4,a4,15
    80003c50:	071a                	slli	a4,a4,0x6
    80003c52:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003c54:	04449703          	lh	a4,68(s1)
    80003c58:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003c5c:	04649703          	lh	a4,70(s1)
    80003c60:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003c64:	04849703          	lh	a4,72(s1)
    80003c68:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003c6c:	04a49703          	lh	a4,74(s1)
    80003c70:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003c74:	44f8                	lw	a4,76(s1)
    80003c76:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003c78:	03400613          	li	a2,52
    80003c7c:	05048593          	addi	a1,s1,80
    80003c80:	00c78513          	addi	a0,a5,12
    80003c84:	ffffd097          	auipc	ra,0xffffd
    80003c88:	1dc080e7          	jalr	476(ra) # 80000e60 <memmove>
  log_write(bp);
    80003c8c:	854a                	mv	a0,s2
    80003c8e:	00001097          	auipc	ra,0x1
    80003c92:	bfe080e7          	jalr	-1026(ra) # 8000488c <log_write>
  brelse(bp);
    80003c96:	854a                	mv	a0,s2
    80003c98:	00000097          	auipc	ra,0x0
    80003c9c:	96a080e7          	jalr	-1686(ra) # 80003602 <brelse>
}
    80003ca0:	60e2                	ld	ra,24(sp)
    80003ca2:	6442                	ld	s0,16(sp)
    80003ca4:	64a2                	ld	s1,8(sp)
    80003ca6:	6902                	ld	s2,0(sp)
    80003ca8:	6105                	addi	sp,sp,32
    80003caa:	8082                	ret

0000000080003cac <idup>:
{
    80003cac:	1101                	addi	sp,sp,-32
    80003cae:	ec06                	sd	ra,24(sp)
    80003cb0:	e822                	sd	s0,16(sp)
    80003cb2:	e426                	sd	s1,8(sp)
    80003cb4:	1000                	addi	s0,sp,32
    80003cb6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003cb8:	0045b517          	auipc	a0,0x45b
    80003cbc:	5a050513          	addi	a0,a0,1440 # 8045f258 <itable>
    80003cc0:	ffffd097          	auipc	ra,0xffffd
    80003cc4:	048080e7          	jalr	72(ra) # 80000d08 <acquire>
  ip->ref++;
    80003cc8:	449c                	lw	a5,8(s1)
    80003cca:	2785                	addiw	a5,a5,1
    80003ccc:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003cce:	0045b517          	auipc	a0,0x45b
    80003cd2:	58a50513          	addi	a0,a0,1418 # 8045f258 <itable>
    80003cd6:	ffffd097          	auipc	ra,0xffffd
    80003cda:	0e6080e7          	jalr	230(ra) # 80000dbc <release>
}
    80003cde:	8526                	mv	a0,s1
    80003ce0:	60e2                	ld	ra,24(sp)
    80003ce2:	6442                	ld	s0,16(sp)
    80003ce4:	64a2                	ld	s1,8(sp)
    80003ce6:	6105                	addi	sp,sp,32
    80003ce8:	8082                	ret

0000000080003cea <ilock>:
{
    80003cea:	1101                	addi	sp,sp,-32
    80003cec:	ec06                	sd	ra,24(sp)
    80003cee:	e822                	sd	s0,16(sp)
    80003cf0:	e426                	sd	s1,8(sp)
    80003cf2:	e04a                	sd	s2,0(sp)
    80003cf4:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003cf6:	c115                	beqz	a0,80003d1a <ilock+0x30>
    80003cf8:	84aa                	mv	s1,a0
    80003cfa:	451c                	lw	a5,8(a0)
    80003cfc:	00f05f63          	blez	a5,80003d1a <ilock+0x30>
  acquiresleep(&ip->lock);
    80003d00:	0541                	addi	a0,a0,16
    80003d02:	00001097          	auipc	ra,0x1
    80003d06:	ca8080e7          	jalr	-856(ra) # 800049aa <acquiresleep>
  if(ip->valid == 0){
    80003d0a:	40bc                	lw	a5,64(s1)
    80003d0c:	cf99                	beqz	a5,80003d2a <ilock+0x40>
}
    80003d0e:	60e2                	ld	ra,24(sp)
    80003d10:	6442                	ld	s0,16(sp)
    80003d12:	64a2                	ld	s1,8(sp)
    80003d14:	6902                	ld	s2,0(sp)
    80003d16:	6105                	addi	sp,sp,32
    80003d18:	8082                	ret
    panic("ilock");
    80003d1a:	00005517          	auipc	a0,0x5
    80003d1e:	a4e50513          	addi	a0,a0,-1458 # 80008768 <syscalls+0x1a8>
    80003d22:	ffffd097          	auipc	ra,0xffffd
    80003d26:	81e080e7          	jalr	-2018(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d2a:	40dc                	lw	a5,4(s1)
    80003d2c:	0047d79b          	srliw	a5,a5,0x4
    80003d30:	0045b597          	auipc	a1,0x45b
    80003d34:	5205a583          	lw	a1,1312(a1) # 8045f250 <sb+0x18>
    80003d38:	9dbd                	addw	a1,a1,a5
    80003d3a:	4088                	lw	a0,0(s1)
    80003d3c:	fffff097          	auipc	ra,0xfffff
    80003d40:	796080e7          	jalr	1942(ra) # 800034d2 <bread>
    80003d44:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d46:	05850593          	addi	a1,a0,88
    80003d4a:	40dc                	lw	a5,4(s1)
    80003d4c:	8bbd                	andi	a5,a5,15
    80003d4e:	079a                	slli	a5,a5,0x6
    80003d50:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003d52:	00059783          	lh	a5,0(a1)
    80003d56:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003d5a:	00259783          	lh	a5,2(a1)
    80003d5e:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003d62:	00459783          	lh	a5,4(a1)
    80003d66:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003d6a:	00659783          	lh	a5,6(a1)
    80003d6e:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003d72:	459c                	lw	a5,8(a1)
    80003d74:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003d76:	03400613          	li	a2,52
    80003d7a:	05b1                	addi	a1,a1,12
    80003d7c:	05048513          	addi	a0,s1,80
    80003d80:	ffffd097          	auipc	ra,0xffffd
    80003d84:	0e0080e7          	jalr	224(ra) # 80000e60 <memmove>
    brelse(bp);
    80003d88:	854a                	mv	a0,s2
    80003d8a:	00000097          	auipc	ra,0x0
    80003d8e:	878080e7          	jalr	-1928(ra) # 80003602 <brelse>
    ip->valid = 1;
    80003d92:	4785                	li	a5,1
    80003d94:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003d96:	04449783          	lh	a5,68(s1)
    80003d9a:	fbb5                	bnez	a5,80003d0e <ilock+0x24>
      panic("ilock: no type");
    80003d9c:	00005517          	auipc	a0,0x5
    80003da0:	9d450513          	addi	a0,a0,-1580 # 80008770 <syscalls+0x1b0>
    80003da4:	ffffc097          	auipc	ra,0xffffc
    80003da8:	79c080e7          	jalr	1948(ra) # 80000540 <panic>

0000000080003dac <iunlock>:
{
    80003dac:	1101                	addi	sp,sp,-32
    80003dae:	ec06                	sd	ra,24(sp)
    80003db0:	e822                	sd	s0,16(sp)
    80003db2:	e426                	sd	s1,8(sp)
    80003db4:	e04a                	sd	s2,0(sp)
    80003db6:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003db8:	c905                	beqz	a0,80003de8 <iunlock+0x3c>
    80003dba:	84aa                	mv	s1,a0
    80003dbc:	01050913          	addi	s2,a0,16
    80003dc0:	854a                	mv	a0,s2
    80003dc2:	00001097          	auipc	ra,0x1
    80003dc6:	c82080e7          	jalr	-894(ra) # 80004a44 <holdingsleep>
    80003dca:	cd19                	beqz	a0,80003de8 <iunlock+0x3c>
    80003dcc:	449c                	lw	a5,8(s1)
    80003dce:	00f05d63          	blez	a5,80003de8 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003dd2:	854a                	mv	a0,s2
    80003dd4:	00001097          	auipc	ra,0x1
    80003dd8:	c2c080e7          	jalr	-980(ra) # 80004a00 <releasesleep>
}
    80003ddc:	60e2                	ld	ra,24(sp)
    80003dde:	6442                	ld	s0,16(sp)
    80003de0:	64a2                	ld	s1,8(sp)
    80003de2:	6902                	ld	s2,0(sp)
    80003de4:	6105                	addi	sp,sp,32
    80003de6:	8082                	ret
    panic("iunlock");
    80003de8:	00005517          	auipc	a0,0x5
    80003dec:	99850513          	addi	a0,a0,-1640 # 80008780 <syscalls+0x1c0>
    80003df0:	ffffc097          	auipc	ra,0xffffc
    80003df4:	750080e7          	jalr	1872(ra) # 80000540 <panic>

0000000080003df8 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003df8:	7179                	addi	sp,sp,-48
    80003dfa:	f406                	sd	ra,40(sp)
    80003dfc:	f022                	sd	s0,32(sp)
    80003dfe:	ec26                	sd	s1,24(sp)
    80003e00:	e84a                	sd	s2,16(sp)
    80003e02:	e44e                	sd	s3,8(sp)
    80003e04:	e052                	sd	s4,0(sp)
    80003e06:	1800                	addi	s0,sp,48
    80003e08:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003e0a:	05050493          	addi	s1,a0,80
    80003e0e:	08050913          	addi	s2,a0,128
    80003e12:	a021                	j	80003e1a <itrunc+0x22>
    80003e14:	0491                	addi	s1,s1,4
    80003e16:	01248d63          	beq	s1,s2,80003e30 <itrunc+0x38>
    if(ip->addrs[i]){
    80003e1a:	408c                	lw	a1,0(s1)
    80003e1c:	dde5                	beqz	a1,80003e14 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003e1e:	0009a503          	lw	a0,0(s3)
    80003e22:	00000097          	auipc	ra,0x0
    80003e26:	8f6080e7          	jalr	-1802(ra) # 80003718 <bfree>
      ip->addrs[i] = 0;
    80003e2a:	0004a023          	sw	zero,0(s1)
    80003e2e:	b7dd                	j	80003e14 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003e30:	0809a583          	lw	a1,128(s3)
    80003e34:	e185                	bnez	a1,80003e54 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003e36:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003e3a:	854e                	mv	a0,s3
    80003e3c:	00000097          	auipc	ra,0x0
    80003e40:	de2080e7          	jalr	-542(ra) # 80003c1e <iupdate>
}
    80003e44:	70a2                	ld	ra,40(sp)
    80003e46:	7402                	ld	s0,32(sp)
    80003e48:	64e2                	ld	s1,24(sp)
    80003e4a:	6942                	ld	s2,16(sp)
    80003e4c:	69a2                	ld	s3,8(sp)
    80003e4e:	6a02                	ld	s4,0(sp)
    80003e50:	6145                	addi	sp,sp,48
    80003e52:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003e54:	0009a503          	lw	a0,0(s3)
    80003e58:	fffff097          	auipc	ra,0xfffff
    80003e5c:	67a080e7          	jalr	1658(ra) # 800034d2 <bread>
    80003e60:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003e62:	05850493          	addi	s1,a0,88
    80003e66:	45850913          	addi	s2,a0,1112
    80003e6a:	a021                	j	80003e72 <itrunc+0x7a>
    80003e6c:	0491                	addi	s1,s1,4
    80003e6e:	01248b63          	beq	s1,s2,80003e84 <itrunc+0x8c>
      if(a[j])
    80003e72:	408c                	lw	a1,0(s1)
    80003e74:	dde5                	beqz	a1,80003e6c <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003e76:	0009a503          	lw	a0,0(s3)
    80003e7a:	00000097          	auipc	ra,0x0
    80003e7e:	89e080e7          	jalr	-1890(ra) # 80003718 <bfree>
    80003e82:	b7ed                	j	80003e6c <itrunc+0x74>
    brelse(bp);
    80003e84:	8552                	mv	a0,s4
    80003e86:	fffff097          	auipc	ra,0xfffff
    80003e8a:	77c080e7          	jalr	1916(ra) # 80003602 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003e8e:	0809a583          	lw	a1,128(s3)
    80003e92:	0009a503          	lw	a0,0(s3)
    80003e96:	00000097          	auipc	ra,0x0
    80003e9a:	882080e7          	jalr	-1918(ra) # 80003718 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003e9e:	0809a023          	sw	zero,128(s3)
    80003ea2:	bf51                	j	80003e36 <itrunc+0x3e>

0000000080003ea4 <iput>:
{
    80003ea4:	1101                	addi	sp,sp,-32
    80003ea6:	ec06                	sd	ra,24(sp)
    80003ea8:	e822                	sd	s0,16(sp)
    80003eaa:	e426                	sd	s1,8(sp)
    80003eac:	e04a                	sd	s2,0(sp)
    80003eae:	1000                	addi	s0,sp,32
    80003eb0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003eb2:	0045b517          	auipc	a0,0x45b
    80003eb6:	3a650513          	addi	a0,a0,934 # 8045f258 <itable>
    80003eba:	ffffd097          	auipc	ra,0xffffd
    80003ebe:	e4e080e7          	jalr	-434(ra) # 80000d08 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ec2:	4498                	lw	a4,8(s1)
    80003ec4:	4785                	li	a5,1
    80003ec6:	02f70363          	beq	a4,a5,80003eec <iput+0x48>
  ip->ref--;
    80003eca:	449c                	lw	a5,8(s1)
    80003ecc:	37fd                	addiw	a5,a5,-1
    80003ece:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ed0:	0045b517          	auipc	a0,0x45b
    80003ed4:	38850513          	addi	a0,a0,904 # 8045f258 <itable>
    80003ed8:	ffffd097          	auipc	ra,0xffffd
    80003edc:	ee4080e7          	jalr	-284(ra) # 80000dbc <release>
}
    80003ee0:	60e2                	ld	ra,24(sp)
    80003ee2:	6442                	ld	s0,16(sp)
    80003ee4:	64a2                	ld	s1,8(sp)
    80003ee6:	6902                	ld	s2,0(sp)
    80003ee8:	6105                	addi	sp,sp,32
    80003eea:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003eec:	40bc                	lw	a5,64(s1)
    80003eee:	dff1                	beqz	a5,80003eca <iput+0x26>
    80003ef0:	04a49783          	lh	a5,74(s1)
    80003ef4:	fbf9                	bnez	a5,80003eca <iput+0x26>
    acquiresleep(&ip->lock);
    80003ef6:	01048913          	addi	s2,s1,16
    80003efa:	854a                	mv	a0,s2
    80003efc:	00001097          	auipc	ra,0x1
    80003f00:	aae080e7          	jalr	-1362(ra) # 800049aa <acquiresleep>
    release(&itable.lock);
    80003f04:	0045b517          	auipc	a0,0x45b
    80003f08:	35450513          	addi	a0,a0,852 # 8045f258 <itable>
    80003f0c:	ffffd097          	auipc	ra,0xffffd
    80003f10:	eb0080e7          	jalr	-336(ra) # 80000dbc <release>
    itrunc(ip);
    80003f14:	8526                	mv	a0,s1
    80003f16:	00000097          	auipc	ra,0x0
    80003f1a:	ee2080e7          	jalr	-286(ra) # 80003df8 <itrunc>
    ip->type = 0;
    80003f1e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003f22:	8526                	mv	a0,s1
    80003f24:	00000097          	auipc	ra,0x0
    80003f28:	cfa080e7          	jalr	-774(ra) # 80003c1e <iupdate>
    ip->valid = 0;
    80003f2c:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003f30:	854a                	mv	a0,s2
    80003f32:	00001097          	auipc	ra,0x1
    80003f36:	ace080e7          	jalr	-1330(ra) # 80004a00 <releasesleep>
    acquire(&itable.lock);
    80003f3a:	0045b517          	auipc	a0,0x45b
    80003f3e:	31e50513          	addi	a0,a0,798 # 8045f258 <itable>
    80003f42:	ffffd097          	auipc	ra,0xffffd
    80003f46:	dc6080e7          	jalr	-570(ra) # 80000d08 <acquire>
    80003f4a:	b741                	j	80003eca <iput+0x26>

0000000080003f4c <iunlockput>:
{
    80003f4c:	1101                	addi	sp,sp,-32
    80003f4e:	ec06                	sd	ra,24(sp)
    80003f50:	e822                	sd	s0,16(sp)
    80003f52:	e426                	sd	s1,8(sp)
    80003f54:	1000                	addi	s0,sp,32
    80003f56:	84aa                	mv	s1,a0
  iunlock(ip);
    80003f58:	00000097          	auipc	ra,0x0
    80003f5c:	e54080e7          	jalr	-428(ra) # 80003dac <iunlock>
  iput(ip);
    80003f60:	8526                	mv	a0,s1
    80003f62:	00000097          	auipc	ra,0x0
    80003f66:	f42080e7          	jalr	-190(ra) # 80003ea4 <iput>
}
    80003f6a:	60e2                	ld	ra,24(sp)
    80003f6c:	6442                	ld	s0,16(sp)
    80003f6e:	64a2                	ld	s1,8(sp)
    80003f70:	6105                	addi	sp,sp,32
    80003f72:	8082                	ret

0000000080003f74 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003f74:	1141                	addi	sp,sp,-16
    80003f76:	e422                	sd	s0,8(sp)
    80003f78:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003f7a:	411c                	lw	a5,0(a0)
    80003f7c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003f7e:	415c                	lw	a5,4(a0)
    80003f80:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003f82:	04451783          	lh	a5,68(a0)
    80003f86:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003f8a:	04a51783          	lh	a5,74(a0)
    80003f8e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003f92:	04c56783          	lwu	a5,76(a0)
    80003f96:	e99c                	sd	a5,16(a1)
}
    80003f98:	6422                	ld	s0,8(sp)
    80003f9a:	0141                	addi	sp,sp,16
    80003f9c:	8082                	ret

0000000080003f9e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f9e:	457c                	lw	a5,76(a0)
    80003fa0:	0ed7e963          	bltu	a5,a3,80004092 <readi+0xf4>
{
    80003fa4:	7159                	addi	sp,sp,-112
    80003fa6:	f486                	sd	ra,104(sp)
    80003fa8:	f0a2                	sd	s0,96(sp)
    80003faa:	eca6                	sd	s1,88(sp)
    80003fac:	e8ca                	sd	s2,80(sp)
    80003fae:	e4ce                	sd	s3,72(sp)
    80003fb0:	e0d2                	sd	s4,64(sp)
    80003fb2:	fc56                	sd	s5,56(sp)
    80003fb4:	f85a                	sd	s6,48(sp)
    80003fb6:	f45e                	sd	s7,40(sp)
    80003fb8:	f062                	sd	s8,32(sp)
    80003fba:	ec66                	sd	s9,24(sp)
    80003fbc:	e86a                	sd	s10,16(sp)
    80003fbe:	e46e                	sd	s11,8(sp)
    80003fc0:	1880                	addi	s0,sp,112
    80003fc2:	8b2a                	mv	s6,a0
    80003fc4:	8bae                	mv	s7,a1
    80003fc6:	8a32                	mv	s4,a2
    80003fc8:	84b6                	mv	s1,a3
    80003fca:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003fcc:	9f35                	addw	a4,a4,a3
    return 0;
    80003fce:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003fd0:	0ad76063          	bltu	a4,a3,80004070 <readi+0xd2>
  if(off + n > ip->size)
    80003fd4:	00e7f463          	bgeu	a5,a4,80003fdc <readi+0x3e>
    n = ip->size - off;
    80003fd8:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003fdc:	0a0a8963          	beqz	s5,8000408e <readi+0xf0>
    80003fe0:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fe2:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003fe6:	5c7d                	li	s8,-1
    80003fe8:	a82d                	j	80004022 <readi+0x84>
    80003fea:	020d1d93          	slli	s11,s10,0x20
    80003fee:	020ddd93          	srli	s11,s11,0x20
    80003ff2:	05890613          	addi	a2,s2,88
    80003ff6:	86ee                	mv	a3,s11
    80003ff8:	963a                	add	a2,a2,a4
    80003ffa:	85d2                	mv	a1,s4
    80003ffc:	855e                	mv	a0,s7
    80003ffe:	ffffe097          	auipc	ra,0xffffe
    80004002:	7c2080e7          	jalr	1986(ra) # 800027c0 <either_copyout>
    80004006:	05850d63          	beq	a0,s8,80004060 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000400a:	854a                	mv	a0,s2
    8000400c:	fffff097          	auipc	ra,0xfffff
    80004010:	5f6080e7          	jalr	1526(ra) # 80003602 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004014:	013d09bb          	addw	s3,s10,s3
    80004018:	009d04bb          	addw	s1,s10,s1
    8000401c:	9a6e                	add	s4,s4,s11
    8000401e:	0559f763          	bgeu	s3,s5,8000406c <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80004022:	00a4d59b          	srliw	a1,s1,0xa
    80004026:	855a                	mv	a0,s6
    80004028:	00000097          	auipc	ra,0x0
    8000402c:	89e080e7          	jalr	-1890(ra) # 800038c6 <bmap>
    80004030:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004034:	cd85                	beqz	a1,8000406c <readi+0xce>
    bp = bread(ip->dev, addr);
    80004036:	000b2503          	lw	a0,0(s6)
    8000403a:	fffff097          	auipc	ra,0xfffff
    8000403e:	498080e7          	jalr	1176(ra) # 800034d2 <bread>
    80004042:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004044:	3ff4f713          	andi	a4,s1,1023
    80004048:	40ec87bb          	subw	a5,s9,a4
    8000404c:	413a86bb          	subw	a3,s5,s3
    80004050:	8d3e                	mv	s10,a5
    80004052:	2781                	sext.w	a5,a5
    80004054:	0006861b          	sext.w	a2,a3
    80004058:	f8f679e3          	bgeu	a2,a5,80003fea <readi+0x4c>
    8000405c:	8d36                	mv	s10,a3
    8000405e:	b771                	j	80003fea <readi+0x4c>
      brelse(bp);
    80004060:	854a                	mv	a0,s2
    80004062:	fffff097          	auipc	ra,0xfffff
    80004066:	5a0080e7          	jalr	1440(ra) # 80003602 <brelse>
      tot = -1;
    8000406a:	59fd                	li	s3,-1
  }
  return tot;
    8000406c:	0009851b          	sext.w	a0,s3
}
    80004070:	70a6                	ld	ra,104(sp)
    80004072:	7406                	ld	s0,96(sp)
    80004074:	64e6                	ld	s1,88(sp)
    80004076:	6946                	ld	s2,80(sp)
    80004078:	69a6                	ld	s3,72(sp)
    8000407a:	6a06                	ld	s4,64(sp)
    8000407c:	7ae2                	ld	s5,56(sp)
    8000407e:	7b42                	ld	s6,48(sp)
    80004080:	7ba2                	ld	s7,40(sp)
    80004082:	7c02                	ld	s8,32(sp)
    80004084:	6ce2                	ld	s9,24(sp)
    80004086:	6d42                	ld	s10,16(sp)
    80004088:	6da2                	ld	s11,8(sp)
    8000408a:	6165                	addi	sp,sp,112
    8000408c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000408e:	89d6                	mv	s3,s5
    80004090:	bff1                	j	8000406c <readi+0xce>
    return 0;
    80004092:	4501                	li	a0,0
}
    80004094:	8082                	ret

0000000080004096 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004096:	457c                	lw	a5,76(a0)
    80004098:	10d7e863          	bltu	a5,a3,800041a8 <writei+0x112>
{
    8000409c:	7159                	addi	sp,sp,-112
    8000409e:	f486                	sd	ra,104(sp)
    800040a0:	f0a2                	sd	s0,96(sp)
    800040a2:	eca6                	sd	s1,88(sp)
    800040a4:	e8ca                	sd	s2,80(sp)
    800040a6:	e4ce                	sd	s3,72(sp)
    800040a8:	e0d2                	sd	s4,64(sp)
    800040aa:	fc56                	sd	s5,56(sp)
    800040ac:	f85a                	sd	s6,48(sp)
    800040ae:	f45e                	sd	s7,40(sp)
    800040b0:	f062                	sd	s8,32(sp)
    800040b2:	ec66                	sd	s9,24(sp)
    800040b4:	e86a                	sd	s10,16(sp)
    800040b6:	e46e                	sd	s11,8(sp)
    800040b8:	1880                	addi	s0,sp,112
    800040ba:	8aaa                	mv	s5,a0
    800040bc:	8bae                	mv	s7,a1
    800040be:	8a32                	mv	s4,a2
    800040c0:	8936                	mv	s2,a3
    800040c2:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800040c4:	00e687bb          	addw	a5,a3,a4
    800040c8:	0ed7e263          	bltu	a5,a3,800041ac <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800040cc:	00043737          	lui	a4,0x43
    800040d0:	0ef76063          	bltu	a4,a5,800041b0 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040d4:	0c0b0863          	beqz	s6,800041a4 <writei+0x10e>
    800040d8:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800040da:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800040de:	5c7d                	li	s8,-1
    800040e0:	a091                	j	80004124 <writei+0x8e>
    800040e2:	020d1d93          	slli	s11,s10,0x20
    800040e6:	020ddd93          	srli	s11,s11,0x20
    800040ea:	05848513          	addi	a0,s1,88
    800040ee:	86ee                	mv	a3,s11
    800040f0:	8652                	mv	a2,s4
    800040f2:	85de                	mv	a1,s7
    800040f4:	953a                	add	a0,a0,a4
    800040f6:	ffffe097          	auipc	ra,0xffffe
    800040fa:	720080e7          	jalr	1824(ra) # 80002816 <either_copyin>
    800040fe:	07850263          	beq	a0,s8,80004162 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004102:	8526                	mv	a0,s1
    80004104:	00000097          	auipc	ra,0x0
    80004108:	788080e7          	jalr	1928(ra) # 8000488c <log_write>
    brelse(bp);
    8000410c:	8526                	mv	a0,s1
    8000410e:	fffff097          	auipc	ra,0xfffff
    80004112:	4f4080e7          	jalr	1268(ra) # 80003602 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004116:	013d09bb          	addw	s3,s10,s3
    8000411a:	012d093b          	addw	s2,s10,s2
    8000411e:	9a6e                	add	s4,s4,s11
    80004120:	0569f663          	bgeu	s3,s6,8000416c <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80004124:	00a9559b          	srliw	a1,s2,0xa
    80004128:	8556                	mv	a0,s5
    8000412a:	fffff097          	auipc	ra,0xfffff
    8000412e:	79c080e7          	jalr	1948(ra) # 800038c6 <bmap>
    80004132:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004136:	c99d                	beqz	a1,8000416c <writei+0xd6>
    bp = bread(ip->dev, addr);
    80004138:	000aa503          	lw	a0,0(s5)
    8000413c:	fffff097          	auipc	ra,0xfffff
    80004140:	396080e7          	jalr	918(ra) # 800034d2 <bread>
    80004144:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004146:	3ff97713          	andi	a4,s2,1023
    8000414a:	40ec87bb          	subw	a5,s9,a4
    8000414e:	413b06bb          	subw	a3,s6,s3
    80004152:	8d3e                	mv	s10,a5
    80004154:	2781                	sext.w	a5,a5
    80004156:	0006861b          	sext.w	a2,a3
    8000415a:	f8f674e3          	bgeu	a2,a5,800040e2 <writei+0x4c>
    8000415e:	8d36                	mv	s10,a3
    80004160:	b749                	j	800040e2 <writei+0x4c>
      brelse(bp);
    80004162:	8526                	mv	a0,s1
    80004164:	fffff097          	auipc	ra,0xfffff
    80004168:	49e080e7          	jalr	1182(ra) # 80003602 <brelse>
  }

  if(off > ip->size)
    8000416c:	04caa783          	lw	a5,76(s5)
    80004170:	0127f463          	bgeu	a5,s2,80004178 <writei+0xe2>
    ip->size = off;
    80004174:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004178:	8556                	mv	a0,s5
    8000417a:	00000097          	auipc	ra,0x0
    8000417e:	aa4080e7          	jalr	-1372(ra) # 80003c1e <iupdate>

  return tot;
    80004182:	0009851b          	sext.w	a0,s3
}
    80004186:	70a6                	ld	ra,104(sp)
    80004188:	7406                	ld	s0,96(sp)
    8000418a:	64e6                	ld	s1,88(sp)
    8000418c:	6946                	ld	s2,80(sp)
    8000418e:	69a6                	ld	s3,72(sp)
    80004190:	6a06                	ld	s4,64(sp)
    80004192:	7ae2                	ld	s5,56(sp)
    80004194:	7b42                	ld	s6,48(sp)
    80004196:	7ba2                	ld	s7,40(sp)
    80004198:	7c02                	ld	s8,32(sp)
    8000419a:	6ce2                	ld	s9,24(sp)
    8000419c:	6d42                	ld	s10,16(sp)
    8000419e:	6da2                	ld	s11,8(sp)
    800041a0:	6165                	addi	sp,sp,112
    800041a2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041a4:	89da                	mv	s3,s6
    800041a6:	bfc9                	j	80004178 <writei+0xe2>
    return -1;
    800041a8:	557d                	li	a0,-1
}
    800041aa:	8082                	ret
    return -1;
    800041ac:	557d                	li	a0,-1
    800041ae:	bfe1                	j	80004186 <writei+0xf0>
    return -1;
    800041b0:	557d                	li	a0,-1
    800041b2:	bfd1                	j	80004186 <writei+0xf0>

00000000800041b4 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800041b4:	1141                	addi	sp,sp,-16
    800041b6:	e406                	sd	ra,8(sp)
    800041b8:	e022                	sd	s0,0(sp)
    800041ba:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800041bc:	4639                	li	a2,14
    800041be:	ffffd097          	auipc	ra,0xffffd
    800041c2:	d16080e7          	jalr	-746(ra) # 80000ed4 <strncmp>
}
    800041c6:	60a2                	ld	ra,8(sp)
    800041c8:	6402                	ld	s0,0(sp)
    800041ca:	0141                	addi	sp,sp,16
    800041cc:	8082                	ret

00000000800041ce <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800041ce:	7139                	addi	sp,sp,-64
    800041d0:	fc06                	sd	ra,56(sp)
    800041d2:	f822                	sd	s0,48(sp)
    800041d4:	f426                	sd	s1,40(sp)
    800041d6:	f04a                	sd	s2,32(sp)
    800041d8:	ec4e                	sd	s3,24(sp)
    800041da:	e852                	sd	s4,16(sp)
    800041dc:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800041de:	04451703          	lh	a4,68(a0)
    800041e2:	4785                	li	a5,1
    800041e4:	00f71a63          	bne	a4,a5,800041f8 <dirlookup+0x2a>
    800041e8:	892a                	mv	s2,a0
    800041ea:	89ae                	mv	s3,a1
    800041ec:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800041ee:	457c                	lw	a5,76(a0)
    800041f0:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800041f2:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041f4:	e79d                	bnez	a5,80004222 <dirlookup+0x54>
    800041f6:	a8a5                	j	8000426e <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800041f8:	00004517          	auipc	a0,0x4
    800041fc:	59050513          	addi	a0,a0,1424 # 80008788 <syscalls+0x1c8>
    80004200:	ffffc097          	auipc	ra,0xffffc
    80004204:	340080e7          	jalr	832(ra) # 80000540 <panic>
      panic("dirlookup read");
    80004208:	00004517          	auipc	a0,0x4
    8000420c:	59850513          	addi	a0,a0,1432 # 800087a0 <syscalls+0x1e0>
    80004210:	ffffc097          	auipc	ra,0xffffc
    80004214:	330080e7          	jalr	816(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004218:	24c1                	addiw	s1,s1,16
    8000421a:	04c92783          	lw	a5,76(s2)
    8000421e:	04f4f763          	bgeu	s1,a5,8000426c <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004222:	4741                	li	a4,16
    80004224:	86a6                	mv	a3,s1
    80004226:	fc040613          	addi	a2,s0,-64
    8000422a:	4581                	li	a1,0
    8000422c:	854a                	mv	a0,s2
    8000422e:	00000097          	auipc	ra,0x0
    80004232:	d70080e7          	jalr	-656(ra) # 80003f9e <readi>
    80004236:	47c1                	li	a5,16
    80004238:	fcf518e3          	bne	a0,a5,80004208 <dirlookup+0x3a>
    if(de.inum == 0)
    8000423c:	fc045783          	lhu	a5,-64(s0)
    80004240:	dfe1                	beqz	a5,80004218 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004242:	fc240593          	addi	a1,s0,-62
    80004246:	854e                	mv	a0,s3
    80004248:	00000097          	auipc	ra,0x0
    8000424c:	f6c080e7          	jalr	-148(ra) # 800041b4 <namecmp>
    80004250:	f561                	bnez	a0,80004218 <dirlookup+0x4a>
      if(poff)
    80004252:	000a0463          	beqz	s4,8000425a <dirlookup+0x8c>
        *poff = off;
    80004256:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000425a:	fc045583          	lhu	a1,-64(s0)
    8000425e:	00092503          	lw	a0,0(s2)
    80004262:	fffff097          	auipc	ra,0xfffff
    80004266:	74e080e7          	jalr	1870(ra) # 800039b0 <iget>
    8000426a:	a011                	j	8000426e <dirlookup+0xa0>
  return 0;
    8000426c:	4501                	li	a0,0
}
    8000426e:	70e2                	ld	ra,56(sp)
    80004270:	7442                	ld	s0,48(sp)
    80004272:	74a2                	ld	s1,40(sp)
    80004274:	7902                	ld	s2,32(sp)
    80004276:	69e2                	ld	s3,24(sp)
    80004278:	6a42                	ld	s4,16(sp)
    8000427a:	6121                	addi	sp,sp,64
    8000427c:	8082                	ret

000000008000427e <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000427e:	711d                	addi	sp,sp,-96
    80004280:	ec86                	sd	ra,88(sp)
    80004282:	e8a2                	sd	s0,80(sp)
    80004284:	e4a6                	sd	s1,72(sp)
    80004286:	e0ca                	sd	s2,64(sp)
    80004288:	fc4e                	sd	s3,56(sp)
    8000428a:	f852                	sd	s4,48(sp)
    8000428c:	f456                	sd	s5,40(sp)
    8000428e:	f05a                	sd	s6,32(sp)
    80004290:	ec5e                	sd	s7,24(sp)
    80004292:	e862                	sd	s8,16(sp)
    80004294:	e466                	sd	s9,8(sp)
    80004296:	e06a                	sd	s10,0(sp)
    80004298:	1080                	addi	s0,sp,96
    8000429a:	84aa                	mv	s1,a0
    8000429c:	8b2e                	mv	s6,a1
    8000429e:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800042a0:	00054703          	lbu	a4,0(a0)
    800042a4:	02f00793          	li	a5,47
    800042a8:	02f70363          	beq	a4,a5,800042ce <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800042ac:	ffffe097          	auipc	ra,0xffffe
    800042b0:	94c080e7          	jalr	-1716(ra) # 80001bf8 <myproc>
    800042b4:	15053503          	ld	a0,336(a0)
    800042b8:	00000097          	auipc	ra,0x0
    800042bc:	9f4080e7          	jalr	-1548(ra) # 80003cac <idup>
    800042c0:	8a2a                	mv	s4,a0
  while(*path == '/')
    800042c2:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    800042c6:	4cb5                	li	s9,13
  len = path - s;
    800042c8:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800042ca:	4c05                	li	s8,1
    800042cc:	a87d                	j	8000438a <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    800042ce:	4585                	li	a1,1
    800042d0:	4505                	li	a0,1
    800042d2:	fffff097          	auipc	ra,0xfffff
    800042d6:	6de080e7          	jalr	1758(ra) # 800039b0 <iget>
    800042da:	8a2a                	mv	s4,a0
    800042dc:	b7dd                	j	800042c2 <namex+0x44>
      iunlockput(ip);
    800042de:	8552                	mv	a0,s4
    800042e0:	00000097          	auipc	ra,0x0
    800042e4:	c6c080e7          	jalr	-916(ra) # 80003f4c <iunlockput>
      return 0;
    800042e8:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800042ea:	8552                	mv	a0,s4
    800042ec:	60e6                	ld	ra,88(sp)
    800042ee:	6446                	ld	s0,80(sp)
    800042f0:	64a6                	ld	s1,72(sp)
    800042f2:	6906                	ld	s2,64(sp)
    800042f4:	79e2                	ld	s3,56(sp)
    800042f6:	7a42                	ld	s4,48(sp)
    800042f8:	7aa2                	ld	s5,40(sp)
    800042fa:	7b02                	ld	s6,32(sp)
    800042fc:	6be2                	ld	s7,24(sp)
    800042fe:	6c42                	ld	s8,16(sp)
    80004300:	6ca2                	ld	s9,8(sp)
    80004302:	6d02                	ld	s10,0(sp)
    80004304:	6125                	addi	sp,sp,96
    80004306:	8082                	ret
      iunlock(ip);
    80004308:	8552                	mv	a0,s4
    8000430a:	00000097          	auipc	ra,0x0
    8000430e:	aa2080e7          	jalr	-1374(ra) # 80003dac <iunlock>
      return ip;
    80004312:	bfe1                	j	800042ea <namex+0x6c>
      iunlockput(ip);
    80004314:	8552                	mv	a0,s4
    80004316:	00000097          	auipc	ra,0x0
    8000431a:	c36080e7          	jalr	-970(ra) # 80003f4c <iunlockput>
      return 0;
    8000431e:	8a4e                	mv	s4,s3
    80004320:	b7e9                	j	800042ea <namex+0x6c>
  len = path - s;
    80004322:	40998633          	sub	a2,s3,s1
    80004326:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    8000432a:	09acd863          	bge	s9,s10,800043ba <namex+0x13c>
    memmove(name, s, DIRSIZ);
    8000432e:	4639                	li	a2,14
    80004330:	85a6                	mv	a1,s1
    80004332:	8556                	mv	a0,s5
    80004334:	ffffd097          	auipc	ra,0xffffd
    80004338:	b2c080e7          	jalr	-1236(ra) # 80000e60 <memmove>
    8000433c:	84ce                	mv	s1,s3
  while(*path == '/')
    8000433e:	0004c783          	lbu	a5,0(s1)
    80004342:	01279763          	bne	a5,s2,80004350 <namex+0xd2>
    path++;
    80004346:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004348:	0004c783          	lbu	a5,0(s1)
    8000434c:	ff278de3          	beq	a5,s2,80004346 <namex+0xc8>
    ilock(ip);
    80004350:	8552                	mv	a0,s4
    80004352:	00000097          	auipc	ra,0x0
    80004356:	998080e7          	jalr	-1640(ra) # 80003cea <ilock>
    if(ip->type != T_DIR){
    8000435a:	044a1783          	lh	a5,68(s4)
    8000435e:	f98790e3          	bne	a5,s8,800042de <namex+0x60>
    if(nameiparent && *path == '\0'){
    80004362:	000b0563          	beqz	s6,8000436c <namex+0xee>
    80004366:	0004c783          	lbu	a5,0(s1)
    8000436a:	dfd9                	beqz	a5,80004308 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000436c:	865e                	mv	a2,s7
    8000436e:	85d6                	mv	a1,s5
    80004370:	8552                	mv	a0,s4
    80004372:	00000097          	auipc	ra,0x0
    80004376:	e5c080e7          	jalr	-420(ra) # 800041ce <dirlookup>
    8000437a:	89aa                	mv	s3,a0
    8000437c:	dd41                	beqz	a0,80004314 <namex+0x96>
    iunlockput(ip);
    8000437e:	8552                	mv	a0,s4
    80004380:	00000097          	auipc	ra,0x0
    80004384:	bcc080e7          	jalr	-1076(ra) # 80003f4c <iunlockput>
    ip = next;
    80004388:	8a4e                	mv	s4,s3
  while(*path == '/')
    8000438a:	0004c783          	lbu	a5,0(s1)
    8000438e:	01279763          	bne	a5,s2,8000439c <namex+0x11e>
    path++;
    80004392:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004394:	0004c783          	lbu	a5,0(s1)
    80004398:	ff278de3          	beq	a5,s2,80004392 <namex+0x114>
  if(*path == 0)
    8000439c:	cb9d                	beqz	a5,800043d2 <namex+0x154>
  while(*path != '/' && *path != 0)
    8000439e:	0004c783          	lbu	a5,0(s1)
    800043a2:	89a6                	mv	s3,s1
  len = path - s;
    800043a4:	8d5e                	mv	s10,s7
    800043a6:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800043a8:	01278963          	beq	a5,s2,800043ba <namex+0x13c>
    800043ac:	dbbd                	beqz	a5,80004322 <namex+0xa4>
    path++;
    800043ae:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    800043b0:	0009c783          	lbu	a5,0(s3)
    800043b4:	ff279ce3          	bne	a5,s2,800043ac <namex+0x12e>
    800043b8:	b7ad                	j	80004322 <namex+0xa4>
    memmove(name, s, len);
    800043ba:	2601                	sext.w	a2,a2
    800043bc:	85a6                	mv	a1,s1
    800043be:	8556                	mv	a0,s5
    800043c0:	ffffd097          	auipc	ra,0xffffd
    800043c4:	aa0080e7          	jalr	-1376(ra) # 80000e60 <memmove>
    name[len] = 0;
    800043c8:	9d56                	add	s10,s10,s5
    800043ca:	000d0023          	sb	zero,0(s10)
    800043ce:	84ce                	mv	s1,s3
    800043d0:	b7bd                	j	8000433e <namex+0xc0>
  if(nameiparent){
    800043d2:	f00b0ce3          	beqz	s6,800042ea <namex+0x6c>
    iput(ip);
    800043d6:	8552                	mv	a0,s4
    800043d8:	00000097          	auipc	ra,0x0
    800043dc:	acc080e7          	jalr	-1332(ra) # 80003ea4 <iput>
    return 0;
    800043e0:	4a01                	li	s4,0
    800043e2:	b721                	j	800042ea <namex+0x6c>

00000000800043e4 <dirlink>:
{
    800043e4:	7139                	addi	sp,sp,-64
    800043e6:	fc06                	sd	ra,56(sp)
    800043e8:	f822                	sd	s0,48(sp)
    800043ea:	f426                	sd	s1,40(sp)
    800043ec:	f04a                	sd	s2,32(sp)
    800043ee:	ec4e                	sd	s3,24(sp)
    800043f0:	e852                	sd	s4,16(sp)
    800043f2:	0080                	addi	s0,sp,64
    800043f4:	892a                	mv	s2,a0
    800043f6:	8a2e                	mv	s4,a1
    800043f8:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800043fa:	4601                	li	a2,0
    800043fc:	00000097          	auipc	ra,0x0
    80004400:	dd2080e7          	jalr	-558(ra) # 800041ce <dirlookup>
    80004404:	e93d                	bnez	a0,8000447a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004406:	04c92483          	lw	s1,76(s2)
    8000440a:	c49d                	beqz	s1,80004438 <dirlink+0x54>
    8000440c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000440e:	4741                	li	a4,16
    80004410:	86a6                	mv	a3,s1
    80004412:	fc040613          	addi	a2,s0,-64
    80004416:	4581                	li	a1,0
    80004418:	854a                	mv	a0,s2
    8000441a:	00000097          	auipc	ra,0x0
    8000441e:	b84080e7          	jalr	-1148(ra) # 80003f9e <readi>
    80004422:	47c1                	li	a5,16
    80004424:	06f51163          	bne	a0,a5,80004486 <dirlink+0xa2>
    if(de.inum == 0)
    80004428:	fc045783          	lhu	a5,-64(s0)
    8000442c:	c791                	beqz	a5,80004438 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000442e:	24c1                	addiw	s1,s1,16
    80004430:	04c92783          	lw	a5,76(s2)
    80004434:	fcf4ede3          	bltu	s1,a5,8000440e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004438:	4639                	li	a2,14
    8000443a:	85d2                	mv	a1,s4
    8000443c:	fc240513          	addi	a0,s0,-62
    80004440:	ffffd097          	auipc	ra,0xffffd
    80004444:	ad0080e7          	jalr	-1328(ra) # 80000f10 <strncpy>
  de.inum = inum;
    80004448:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000444c:	4741                	li	a4,16
    8000444e:	86a6                	mv	a3,s1
    80004450:	fc040613          	addi	a2,s0,-64
    80004454:	4581                	li	a1,0
    80004456:	854a                	mv	a0,s2
    80004458:	00000097          	auipc	ra,0x0
    8000445c:	c3e080e7          	jalr	-962(ra) # 80004096 <writei>
    80004460:	1541                	addi	a0,a0,-16
    80004462:	00a03533          	snez	a0,a0
    80004466:	40a00533          	neg	a0,a0
}
    8000446a:	70e2                	ld	ra,56(sp)
    8000446c:	7442                	ld	s0,48(sp)
    8000446e:	74a2                	ld	s1,40(sp)
    80004470:	7902                	ld	s2,32(sp)
    80004472:	69e2                	ld	s3,24(sp)
    80004474:	6a42                	ld	s4,16(sp)
    80004476:	6121                	addi	sp,sp,64
    80004478:	8082                	ret
    iput(ip);
    8000447a:	00000097          	auipc	ra,0x0
    8000447e:	a2a080e7          	jalr	-1494(ra) # 80003ea4 <iput>
    return -1;
    80004482:	557d                	li	a0,-1
    80004484:	b7dd                	j	8000446a <dirlink+0x86>
      panic("dirlink read");
    80004486:	00004517          	auipc	a0,0x4
    8000448a:	32a50513          	addi	a0,a0,810 # 800087b0 <syscalls+0x1f0>
    8000448e:	ffffc097          	auipc	ra,0xffffc
    80004492:	0b2080e7          	jalr	178(ra) # 80000540 <panic>

0000000080004496 <namei>:

struct inode*
namei(char *path)
{
    80004496:	1101                	addi	sp,sp,-32
    80004498:	ec06                	sd	ra,24(sp)
    8000449a:	e822                	sd	s0,16(sp)
    8000449c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000449e:	fe040613          	addi	a2,s0,-32
    800044a2:	4581                	li	a1,0
    800044a4:	00000097          	auipc	ra,0x0
    800044a8:	dda080e7          	jalr	-550(ra) # 8000427e <namex>
}
    800044ac:	60e2                	ld	ra,24(sp)
    800044ae:	6442                	ld	s0,16(sp)
    800044b0:	6105                	addi	sp,sp,32
    800044b2:	8082                	ret

00000000800044b4 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800044b4:	1141                	addi	sp,sp,-16
    800044b6:	e406                	sd	ra,8(sp)
    800044b8:	e022                	sd	s0,0(sp)
    800044ba:	0800                	addi	s0,sp,16
    800044bc:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800044be:	4585                	li	a1,1
    800044c0:	00000097          	auipc	ra,0x0
    800044c4:	dbe080e7          	jalr	-578(ra) # 8000427e <namex>
}
    800044c8:	60a2                	ld	ra,8(sp)
    800044ca:	6402                	ld	s0,0(sp)
    800044cc:	0141                	addi	sp,sp,16
    800044ce:	8082                	ret

00000000800044d0 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800044d0:	1101                	addi	sp,sp,-32
    800044d2:	ec06                	sd	ra,24(sp)
    800044d4:	e822                	sd	s0,16(sp)
    800044d6:	e426                	sd	s1,8(sp)
    800044d8:	e04a                	sd	s2,0(sp)
    800044da:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800044dc:	0045d917          	auipc	s2,0x45d
    800044e0:	82490913          	addi	s2,s2,-2012 # 80460d00 <log>
    800044e4:	01892583          	lw	a1,24(s2)
    800044e8:	02892503          	lw	a0,40(s2)
    800044ec:	fffff097          	auipc	ra,0xfffff
    800044f0:	fe6080e7          	jalr	-26(ra) # 800034d2 <bread>
    800044f4:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800044f6:	02c92683          	lw	a3,44(s2)
    800044fa:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800044fc:	02d05863          	blez	a3,8000452c <write_head+0x5c>
    80004500:	0045d797          	auipc	a5,0x45d
    80004504:	83078793          	addi	a5,a5,-2000 # 80460d30 <log+0x30>
    80004508:	05c50713          	addi	a4,a0,92
    8000450c:	36fd                	addiw	a3,a3,-1
    8000450e:	02069613          	slli	a2,a3,0x20
    80004512:	01e65693          	srli	a3,a2,0x1e
    80004516:	0045d617          	auipc	a2,0x45d
    8000451a:	81e60613          	addi	a2,a2,-2018 # 80460d34 <log+0x34>
    8000451e:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004520:	4390                	lw	a2,0(a5)
    80004522:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004524:	0791                	addi	a5,a5,4
    80004526:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80004528:	fed79ce3          	bne	a5,a3,80004520 <write_head+0x50>
  }
  bwrite(buf);
    8000452c:	8526                	mv	a0,s1
    8000452e:	fffff097          	auipc	ra,0xfffff
    80004532:	096080e7          	jalr	150(ra) # 800035c4 <bwrite>
  brelse(buf);
    80004536:	8526                	mv	a0,s1
    80004538:	fffff097          	auipc	ra,0xfffff
    8000453c:	0ca080e7          	jalr	202(ra) # 80003602 <brelse>
}
    80004540:	60e2                	ld	ra,24(sp)
    80004542:	6442                	ld	s0,16(sp)
    80004544:	64a2                	ld	s1,8(sp)
    80004546:	6902                	ld	s2,0(sp)
    80004548:	6105                	addi	sp,sp,32
    8000454a:	8082                	ret

000000008000454c <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000454c:	0045c797          	auipc	a5,0x45c
    80004550:	7e07a783          	lw	a5,2016(a5) # 80460d2c <log+0x2c>
    80004554:	0af05d63          	blez	a5,8000460e <install_trans+0xc2>
{
    80004558:	7139                	addi	sp,sp,-64
    8000455a:	fc06                	sd	ra,56(sp)
    8000455c:	f822                	sd	s0,48(sp)
    8000455e:	f426                	sd	s1,40(sp)
    80004560:	f04a                	sd	s2,32(sp)
    80004562:	ec4e                	sd	s3,24(sp)
    80004564:	e852                	sd	s4,16(sp)
    80004566:	e456                	sd	s5,8(sp)
    80004568:	e05a                	sd	s6,0(sp)
    8000456a:	0080                	addi	s0,sp,64
    8000456c:	8b2a                	mv	s6,a0
    8000456e:	0045ca97          	auipc	s5,0x45c
    80004572:	7c2a8a93          	addi	s5,s5,1986 # 80460d30 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004576:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004578:	0045c997          	auipc	s3,0x45c
    8000457c:	78898993          	addi	s3,s3,1928 # 80460d00 <log>
    80004580:	a00d                	j	800045a2 <install_trans+0x56>
    brelse(lbuf);
    80004582:	854a                	mv	a0,s2
    80004584:	fffff097          	auipc	ra,0xfffff
    80004588:	07e080e7          	jalr	126(ra) # 80003602 <brelse>
    brelse(dbuf);
    8000458c:	8526                	mv	a0,s1
    8000458e:	fffff097          	auipc	ra,0xfffff
    80004592:	074080e7          	jalr	116(ra) # 80003602 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004596:	2a05                	addiw	s4,s4,1
    80004598:	0a91                	addi	s5,s5,4
    8000459a:	02c9a783          	lw	a5,44(s3)
    8000459e:	04fa5e63          	bge	s4,a5,800045fa <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800045a2:	0189a583          	lw	a1,24(s3)
    800045a6:	014585bb          	addw	a1,a1,s4
    800045aa:	2585                	addiw	a1,a1,1
    800045ac:	0289a503          	lw	a0,40(s3)
    800045b0:	fffff097          	auipc	ra,0xfffff
    800045b4:	f22080e7          	jalr	-222(ra) # 800034d2 <bread>
    800045b8:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800045ba:	000aa583          	lw	a1,0(s5)
    800045be:	0289a503          	lw	a0,40(s3)
    800045c2:	fffff097          	auipc	ra,0xfffff
    800045c6:	f10080e7          	jalr	-240(ra) # 800034d2 <bread>
    800045ca:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800045cc:	40000613          	li	a2,1024
    800045d0:	05890593          	addi	a1,s2,88
    800045d4:	05850513          	addi	a0,a0,88
    800045d8:	ffffd097          	auipc	ra,0xffffd
    800045dc:	888080e7          	jalr	-1912(ra) # 80000e60 <memmove>
    bwrite(dbuf);  // write dst to disk
    800045e0:	8526                	mv	a0,s1
    800045e2:	fffff097          	auipc	ra,0xfffff
    800045e6:	fe2080e7          	jalr	-30(ra) # 800035c4 <bwrite>
    if(recovering == 0)
    800045ea:	f80b1ce3          	bnez	s6,80004582 <install_trans+0x36>
      bunpin(dbuf);
    800045ee:	8526                	mv	a0,s1
    800045f0:	fffff097          	auipc	ra,0xfffff
    800045f4:	0ec080e7          	jalr	236(ra) # 800036dc <bunpin>
    800045f8:	b769                	j	80004582 <install_trans+0x36>
}
    800045fa:	70e2                	ld	ra,56(sp)
    800045fc:	7442                	ld	s0,48(sp)
    800045fe:	74a2                	ld	s1,40(sp)
    80004600:	7902                	ld	s2,32(sp)
    80004602:	69e2                	ld	s3,24(sp)
    80004604:	6a42                	ld	s4,16(sp)
    80004606:	6aa2                	ld	s5,8(sp)
    80004608:	6b02                	ld	s6,0(sp)
    8000460a:	6121                	addi	sp,sp,64
    8000460c:	8082                	ret
    8000460e:	8082                	ret

0000000080004610 <initlog>:
{
    80004610:	7179                	addi	sp,sp,-48
    80004612:	f406                	sd	ra,40(sp)
    80004614:	f022                	sd	s0,32(sp)
    80004616:	ec26                	sd	s1,24(sp)
    80004618:	e84a                	sd	s2,16(sp)
    8000461a:	e44e                	sd	s3,8(sp)
    8000461c:	1800                	addi	s0,sp,48
    8000461e:	892a                	mv	s2,a0
    80004620:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004622:	0045c497          	auipc	s1,0x45c
    80004626:	6de48493          	addi	s1,s1,1758 # 80460d00 <log>
    8000462a:	00004597          	auipc	a1,0x4
    8000462e:	19658593          	addi	a1,a1,406 # 800087c0 <syscalls+0x200>
    80004632:	8526                	mv	a0,s1
    80004634:	ffffc097          	auipc	ra,0xffffc
    80004638:	644080e7          	jalr	1604(ra) # 80000c78 <initlock>
  log.start = sb->logstart;
    8000463c:	0149a583          	lw	a1,20(s3)
    80004640:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004642:	0109a783          	lw	a5,16(s3)
    80004646:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004648:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000464c:	854a                	mv	a0,s2
    8000464e:	fffff097          	auipc	ra,0xfffff
    80004652:	e84080e7          	jalr	-380(ra) # 800034d2 <bread>
  log.lh.n = lh->n;
    80004656:	4d34                	lw	a3,88(a0)
    80004658:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000465a:	02d05663          	blez	a3,80004686 <initlog+0x76>
    8000465e:	05c50793          	addi	a5,a0,92
    80004662:	0045c717          	auipc	a4,0x45c
    80004666:	6ce70713          	addi	a4,a4,1742 # 80460d30 <log+0x30>
    8000466a:	36fd                	addiw	a3,a3,-1
    8000466c:	02069613          	slli	a2,a3,0x20
    80004670:	01e65693          	srli	a3,a2,0x1e
    80004674:	06050613          	addi	a2,a0,96
    80004678:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    8000467a:	4390                	lw	a2,0(a5)
    8000467c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000467e:	0791                	addi	a5,a5,4
    80004680:	0711                	addi	a4,a4,4
    80004682:	fed79ce3          	bne	a5,a3,8000467a <initlog+0x6a>
  brelse(buf);
    80004686:	fffff097          	auipc	ra,0xfffff
    8000468a:	f7c080e7          	jalr	-132(ra) # 80003602 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000468e:	4505                	li	a0,1
    80004690:	00000097          	auipc	ra,0x0
    80004694:	ebc080e7          	jalr	-324(ra) # 8000454c <install_trans>
  log.lh.n = 0;
    80004698:	0045c797          	auipc	a5,0x45c
    8000469c:	6807aa23          	sw	zero,1684(a5) # 80460d2c <log+0x2c>
  write_head(); // clear the log
    800046a0:	00000097          	auipc	ra,0x0
    800046a4:	e30080e7          	jalr	-464(ra) # 800044d0 <write_head>
}
    800046a8:	70a2                	ld	ra,40(sp)
    800046aa:	7402                	ld	s0,32(sp)
    800046ac:	64e2                	ld	s1,24(sp)
    800046ae:	6942                	ld	s2,16(sp)
    800046b0:	69a2                	ld	s3,8(sp)
    800046b2:	6145                	addi	sp,sp,48
    800046b4:	8082                	ret

00000000800046b6 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800046b6:	1101                	addi	sp,sp,-32
    800046b8:	ec06                	sd	ra,24(sp)
    800046ba:	e822                	sd	s0,16(sp)
    800046bc:	e426                	sd	s1,8(sp)
    800046be:	e04a                	sd	s2,0(sp)
    800046c0:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800046c2:	0045c517          	auipc	a0,0x45c
    800046c6:	63e50513          	addi	a0,a0,1598 # 80460d00 <log>
    800046ca:	ffffc097          	auipc	ra,0xffffc
    800046ce:	63e080e7          	jalr	1598(ra) # 80000d08 <acquire>
  while(1){
    if(log.committing){
    800046d2:	0045c497          	auipc	s1,0x45c
    800046d6:	62e48493          	addi	s1,s1,1582 # 80460d00 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800046da:	4979                	li	s2,30
    800046dc:	a039                	j	800046ea <begin_op+0x34>
      sleep(&log, &log.lock);
    800046de:	85a6                	mv	a1,s1
    800046e0:	8526                	mv	a0,s1
    800046e2:	ffffe097          	auipc	ra,0xffffe
    800046e6:	cd6080e7          	jalr	-810(ra) # 800023b8 <sleep>
    if(log.committing){
    800046ea:	50dc                	lw	a5,36(s1)
    800046ec:	fbed                	bnez	a5,800046de <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800046ee:	5098                	lw	a4,32(s1)
    800046f0:	2705                	addiw	a4,a4,1
    800046f2:	0007069b          	sext.w	a3,a4
    800046f6:	0027179b          	slliw	a5,a4,0x2
    800046fa:	9fb9                	addw	a5,a5,a4
    800046fc:	0017979b          	slliw	a5,a5,0x1
    80004700:	54d8                	lw	a4,44(s1)
    80004702:	9fb9                	addw	a5,a5,a4
    80004704:	00f95963          	bge	s2,a5,80004716 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004708:	85a6                	mv	a1,s1
    8000470a:	8526                	mv	a0,s1
    8000470c:	ffffe097          	auipc	ra,0xffffe
    80004710:	cac080e7          	jalr	-852(ra) # 800023b8 <sleep>
    80004714:	bfd9                	j	800046ea <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004716:	0045c517          	auipc	a0,0x45c
    8000471a:	5ea50513          	addi	a0,a0,1514 # 80460d00 <log>
    8000471e:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004720:	ffffc097          	auipc	ra,0xffffc
    80004724:	69c080e7          	jalr	1692(ra) # 80000dbc <release>
      break;
    }
  }
}
    80004728:	60e2                	ld	ra,24(sp)
    8000472a:	6442                	ld	s0,16(sp)
    8000472c:	64a2                	ld	s1,8(sp)
    8000472e:	6902                	ld	s2,0(sp)
    80004730:	6105                	addi	sp,sp,32
    80004732:	8082                	ret

0000000080004734 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004734:	7139                	addi	sp,sp,-64
    80004736:	fc06                	sd	ra,56(sp)
    80004738:	f822                	sd	s0,48(sp)
    8000473a:	f426                	sd	s1,40(sp)
    8000473c:	f04a                	sd	s2,32(sp)
    8000473e:	ec4e                	sd	s3,24(sp)
    80004740:	e852                	sd	s4,16(sp)
    80004742:	e456                	sd	s5,8(sp)
    80004744:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004746:	0045c497          	auipc	s1,0x45c
    8000474a:	5ba48493          	addi	s1,s1,1466 # 80460d00 <log>
    8000474e:	8526                	mv	a0,s1
    80004750:	ffffc097          	auipc	ra,0xffffc
    80004754:	5b8080e7          	jalr	1464(ra) # 80000d08 <acquire>
  log.outstanding -= 1;
    80004758:	509c                	lw	a5,32(s1)
    8000475a:	37fd                	addiw	a5,a5,-1
    8000475c:	0007891b          	sext.w	s2,a5
    80004760:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004762:	50dc                	lw	a5,36(s1)
    80004764:	e7b9                	bnez	a5,800047b2 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004766:	04091e63          	bnez	s2,800047c2 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000476a:	0045c497          	auipc	s1,0x45c
    8000476e:	59648493          	addi	s1,s1,1430 # 80460d00 <log>
    80004772:	4785                	li	a5,1
    80004774:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004776:	8526                	mv	a0,s1
    80004778:	ffffc097          	auipc	ra,0xffffc
    8000477c:	644080e7          	jalr	1604(ra) # 80000dbc <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004780:	54dc                	lw	a5,44(s1)
    80004782:	06f04763          	bgtz	a5,800047f0 <end_op+0xbc>
    acquire(&log.lock);
    80004786:	0045c497          	auipc	s1,0x45c
    8000478a:	57a48493          	addi	s1,s1,1402 # 80460d00 <log>
    8000478e:	8526                	mv	a0,s1
    80004790:	ffffc097          	auipc	ra,0xffffc
    80004794:	578080e7          	jalr	1400(ra) # 80000d08 <acquire>
    log.committing = 0;
    80004798:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000479c:	8526                	mv	a0,s1
    8000479e:	ffffe097          	auipc	ra,0xffffe
    800047a2:	c7e080e7          	jalr	-898(ra) # 8000241c <wakeup>
    release(&log.lock);
    800047a6:	8526                	mv	a0,s1
    800047a8:	ffffc097          	auipc	ra,0xffffc
    800047ac:	614080e7          	jalr	1556(ra) # 80000dbc <release>
}
    800047b0:	a03d                	j	800047de <end_op+0xaa>
    panic("log.committing");
    800047b2:	00004517          	auipc	a0,0x4
    800047b6:	01650513          	addi	a0,a0,22 # 800087c8 <syscalls+0x208>
    800047ba:	ffffc097          	auipc	ra,0xffffc
    800047be:	d86080e7          	jalr	-634(ra) # 80000540 <panic>
    wakeup(&log);
    800047c2:	0045c497          	auipc	s1,0x45c
    800047c6:	53e48493          	addi	s1,s1,1342 # 80460d00 <log>
    800047ca:	8526                	mv	a0,s1
    800047cc:	ffffe097          	auipc	ra,0xffffe
    800047d0:	c50080e7          	jalr	-944(ra) # 8000241c <wakeup>
  release(&log.lock);
    800047d4:	8526                	mv	a0,s1
    800047d6:	ffffc097          	auipc	ra,0xffffc
    800047da:	5e6080e7          	jalr	1510(ra) # 80000dbc <release>
}
    800047de:	70e2                	ld	ra,56(sp)
    800047e0:	7442                	ld	s0,48(sp)
    800047e2:	74a2                	ld	s1,40(sp)
    800047e4:	7902                	ld	s2,32(sp)
    800047e6:	69e2                	ld	s3,24(sp)
    800047e8:	6a42                	ld	s4,16(sp)
    800047ea:	6aa2                	ld	s5,8(sp)
    800047ec:	6121                	addi	sp,sp,64
    800047ee:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800047f0:	0045ca97          	auipc	s5,0x45c
    800047f4:	540a8a93          	addi	s5,s5,1344 # 80460d30 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800047f8:	0045ca17          	auipc	s4,0x45c
    800047fc:	508a0a13          	addi	s4,s4,1288 # 80460d00 <log>
    80004800:	018a2583          	lw	a1,24(s4)
    80004804:	012585bb          	addw	a1,a1,s2
    80004808:	2585                	addiw	a1,a1,1
    8000480a:	028a2503          	lw	a0,40(s4)
    8000480e:	fffff097          	auipc	ra,0xfffff
    80004812:	cc4080e7          	jalr	-828(ra) # 800034d2 <bread>
    80004816:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004818:	000aa583          	lw	a1,0(s5)
    8000481c:	028a2503          	lw	a0,40(s4)
    80004820:	fffff097          	auipc	ra,0xfffff
    80004824:	cb2080e7          	jalr	-846(ra) # 800034d2 <bread>
    80004828:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000482a:	40000613          	li	a2,1024
    8000482e:	05850593          	addi	a1,a0,88
    80004832:	05848513          	addi	a0,s1,88
    80004836:	ffffc097          	auipc	ra,0xffffc
    8000483a:	62a080e7          	jalr	1578(ra) # 80000e60 <memmove>
    bwrite(to);  // write the log
    8000483e:	8526                	mv	a0,s1
    80004840:	fffff097          	auipc	ra,0xfffff
    80004844:	d84080e7          	jalr	-636(ra) # 800035c4 <bwrite>
    brelse(from);
    80004848:	854e                	mv	a0,s3
    8000484a:	fffff097          	auipc	ra,0xfffff
    8000484e:	db8080e7          	jalr	-584(ra) # 80003602 <brelse>
    brelse(to);
    80004852:	8526                	mv	a0,s1
    80004854:	fffff097          	auipc	ra,0xfffff
    80004858:	dae080e7          	jalr	-594(ra) # 80003602 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000485c:	2905                	addiw	s2,s2,1
    8000485e:	0a91                	addi	s5,s5,4
    80004860:	02ca2783          	lw	a5,44(s4)
    80004864:	f8f94ee3          	blt	s2,a5,80004800 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004868:	00000097          	auipc	ra,0x0
    8000486c:	c68080e7          	jalr	-920(ra) # 800044d0 <write_head>
    install_trans(0); // Now install writes to home locations
    80004870:	4501                	li	a0,0
    80004872:	00000097          	auipc	ra,0x0
    80004876:	cda080e7          	jalr	-806(ra) # 8000454c <install_trans>
    log.lh.n = 0;
    8000487a:	0045c797          	auipc	a5,0x45c
    8000487e:	4a07a923          	sw	zero,1202(a5) # 80460d2c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004882:	00000097          	auipc	ra,0x0
    80004886:	c4e080e7          	jalr	-946(ra) # 800044d0 <write_head>
    8000488a:	bdf5                	j	80004786 <end_op+0x52>

000000008000488c <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000488c:	1101                	addi	sp,sp,-32
    8000488e:	ec06                	sd	ra,24(sp)
    80004890:	e822                	sd	s0,16(sp)
    80004892:	e426                	sd	s1,8(sp)
    80004894:	e04a                	sd	s2,0(sp)
    80004896:	1000                	addi	s0,sp,32
    80004898:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000489a:	0045c917          	auipc	s2,0x45c
    8000489e:	46690913          	addi	s2,s2,1126 # 80460d00 <log>
    800048a2:	854a                	mv	a0,s2
    800048a4:	ffffc097          	auipc	ra,0xffffc
    800048a8:	464080e7          	jalr	1124(ra) # 80000d08 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800048ac:	02c92603          	lw	a2,44(s2)
    800048b0:	47f5                	li	a5,29
    800048b2:	06c7c563          	blt	a5,a2,8000491c <log_write+0x90>
    800048b6:	0045c797          	auipc	a5,0x45c
    800048ba:	4667a783          	lw	a5,1126(a5) # 80460d1c <log+0x1c>
    800048be:	37fd                	addiw	a5,a5,-1
    800048c0:	04f65e63          	bge	a2,a5,8000491c <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800048c4:	0045c797          	auipc	a5,0x45c
    800048c8:	45c7a783          	lw	a5,1116(a5) # 80460d20 <log+0x20>
    800048cc:	06f05063          	blez	a5,8000492c <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800048d0:	4781                	li	a5,0
    800048d2:	06c05563          	blez	a2,8000493c <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800048d6:	44cc                	lw	a1,12(s1)
    800048d8:	0045c717          	auipc	a4,0x45c
    800048dc:	45870713          	addi	a4,a4,1112 # 80460d30 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800048e0:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800048e2:	4314                	lw	a3,0(a4)
    800048e4:	04b68c63          	beq	a3,a1,8000493c <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800048e8:	2785                	addiw	a5,a5,1
    800048ea:	0711                	addi	a4,a4,4
    800048ec:	fef61be3          	bne	a2,a5,800048e2 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800048f0:	0621                	addi	a2,a2,8
    800048f2:	060a                	slli	a2,a2,0x2
    800048f4:	0045c797          	auipc	a5,0x45c
    800048f8:	40c78793          	addi	a5,a5,1036 # 80460d00 <log>
    800048fc:	97b2                	add	a5,a5,a2
    800048fe:	44d8                	lw	a4,12(s1)
    80004900:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004902:	8526                	mv	a0,s1
    80004904:	fffff097          	auipc	ra,0xfffff
    80004908:	d9c080e7          	jalr	-612(ra) # 800036a0 <bpin>
    log.lh.n++;
    8000490c:	0045c717          	auipc	a4,0x45c
    80004910:	3f470713          	addi	a4,a4,1012 # 80460d00 <log>
    80004914:	575c                	lw	a5,44(a4)
    80004916:	2785                	addiw	a5,a5,1
    80004918:	d75c                	sw	a5,44(a4)
    8000491a:	a82d                	j	80004954 <log_write+0xc8>
    panic("too big a transaction");
    8000491c:	00004517          	auipc	a0,0x4
    80004920:	ebc50513          	addi	a0,a0,-324 # 800087d8 <syscalls+0x218>
    80004924:	ffffc097          	auipc	ra,0xffffc
    80004928:	c1c080e7          	jalr	-996(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    8000492c:	00004517          	auipc	a0,0x4
    80004930:	ec450513          	addi	a0,a0,-316 # 800087f0 <syscalls+0x230>
    80004934:	ffffc097          	auipc	ra,0xffffc
    80004938:	c0c080e7          	jalr	-1012(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    8000493c:	00878693          	addi	a3,a5,8
    80004940:	068a                	slli	a3,a3,0x2
    80004942:	0045c717          	auipc	a4,0x45c
    80004946:	3be70713          	addi	a4,a4,958 # 80460d00 <log>
    8000494a:	9736                	add	a4,a4,a3
    8000494c:	44d4                	lw	a3,12(s1)
    8000494e:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004950:	faf609e3          	beq	a2,a5,80004902 <log_write+0x76>
  }
  release(&log.lock);
    80004954:	0045c517          	auipc	a0,0x45c
    80004958:	3ac50513          	addi	a0,a0,940 # 80460d00 <log>
    8000495c:	ffffc097          	auipc	ra,0xffffc
    80004960:	460080e7          	jalr	1120(ra) # 80000dbc <release>
}
    80004964:	60e2                	ld	ra,24(sp)
    80004966:	6442                	ld	s0,16(sp)
    80004968:	64a2                	ld	s1,8(sp)
    8000496a:	6902                	ld	s2,0(sp)
    8000496c:	6105                	addi	sp,sp,32
    8000496e:	8082                	ret

0000000080004970 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004970:	1101                	addi	sp,sp,-32
    80004972:	ec06                	sd	ra,24(sp)
    80004974:	e822                	sd	s0,16(sp)
    80004976:	e426                	sd	s1,8(sp)
    80004978:	e04a                	sd	s2,0(sp)
    8000497a:	1000                	addi	s0,sp,32
    8000497c:	84aa                	mv	s1,a0
    8000497e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004980:	00004597          	auipc	a1,0x4
    80004984:	e9058593          	addi	a1,a1,-368 # 80008810 <syscalls+0x250>
    80004988:	0521                	addi	a0,a0,8
    8000498a:	ffffc097          	auipc	ra,0xffffc
    8000498e:	2ee080e7          	jalr	750(ra) # 80000c78 <initlock>
  lk->name = name;
    80004992:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004996:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000499a:	0204a423          	sw	zero,40(s1)
}
    8000499e:	60e2                	ld	ra,24(sp)
    800049a0:	6442                	ld	s0,16(sp)
    800049a2:	64a2                	ld	s1,8(sp)
    800049a4:	6902                	ld	s2,0(sp)
    800049a6:	6105                	addi	sp,sp,32
    800049a8:	8082                	ret

00000000800049aa <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800049aa:	1101                	addi	sp,sp,-32
    800049ac:	ec06                	sd	ra,24(sp)
    800049ae:	e822                	sd	s0,16(sp)
    800049b0:	e426                	sd	s1,8(sp)
    800049b2:	e04a                	sd	s2,0(sp)
    800049b4:	1000                	addi	s0,sp,32
    800049b6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800049b8:	00850913          	addi	s2,a0,8
    800049bc:	854a                	mv	a0,s2
    800049be:	ffffc097          	auipc	ra,0xffffc
    800049c2:	34a080e7          	jalr	842(ra) # 80000d08 <acquire>
  while (lk->locked) {
    800049c6:	409c                	lw	a5,0(s1)
    800049c8:	cb89                	beqz	a5,800049da <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800049ca:	85ca                	mv	a1,s2
    800049cc:	8526                	mv	a0,s1
    800049ce:	ffffe097          	auipc	ra,0xffffe
    800049d2:	9ea080e7          	jalr	-1558(ra) # 800023b8 <sleep>
  while (lk->locked) {
    800049d6:	409c                	lw	a5,0(s1)
    800049d8:	fbed                	bnez	a5,800049ca <acquiresleep+0x20>
  }
  lk->locked = 1;
    800049da:	4785                	li	a5,1
    800049dc:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800049de:	ffffd097          	auipc	ra,0xffffd
    800049e2:	21a080e7          	jalr	538(ra) # 80001bf8 <myproc>
    800049e6:	591c                	lw	a5,48(a0)
    800049e8:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800049ea:	854a                	mv	a0,s2
    800049ec:	ffffc097          	auipc	ra,0xffffc
    800049f0:	3d0080e7          	jalr	976(ra) # 80000dbc <release>
}
    800049f4:	60e2                	ld	ra,24(sp)
    800049f6:	6442                	ld	s0,16(sp)
    800049f8:	64a2                	ld	s1,8(sp)
    800049fa:	6902                	ld	s2,0(sp)
    800049fc:	6105                	addi	sp,sp,32
    800049fe:	8082                	ret

0000000080004a00 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004a00:	1101                	addi	sp,sp,-32
    80004a02:	ec06                	sd	ra,24(sp)
    80004a04:	e822                	sd	s0,16(sp)
    80004a06:	e426                	sd	s1,8(sp)
    80004a08:	e04a                	sd	s2,0(sp)
    80004a0a:	1000                	addi	s0,sp,32
    80004a0c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004a0e:	00850913          	addi	s2,a0,8
    80004a12:	854a                	mv	a0,s2
    80004a14:	ffffc097          	auipc	ra,0xffffc
    80004a18:	2f4080e7          	jalr	756(ra) # 80000d08 <acquire>
  lk->locked = 0;
    80004a1c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a20:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004a24:	8526                	mv	a0,s1
    80004a26:	ffffe097          	auipc	ra,0xffffe
    80004a2a:	9f6080e7          	jalr	-1546(ra) # 8000241c <wakeup>
  release(&lk->lk);
    80004a2e:	854a                	mv	a0,s2
    80004a30:	ffffc097          	auipc	ra,0xffffc
    80004a34:	38c080e7          	jalr	908(ra) # 80000dbc <release>
}
    80004a38:	60e2                	ld	ra,24(sp)
    80004a3a:	6442                	ld	s0,16(sp)
    80004a3c:	64a2                	ld	s1,8(sp)
    80004a3e:	6902                	ld	s2,0(sp)
    80004a40:	6105                	addi	sp,sp,32
    80004a42:	8082                	ret

0000000080004a44 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004a44:	7179                	addi	sp,sp,-48
    80004a46:	f406                	sd	ra,40(sp)
    80004a48:	f022                	sd	s0,32(sp)
    80004a4a:	ec26                	sd	s1,24(sp)
    80004a4c:	e84a                	sd	s2,16(sp)
    80004a4e:	e44e                	sd	s3,8(sp)
    80004a50:	1800                	addi	s0,sp,48
    80004a52:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004a54:	00850913          	addi	s2,a0,8
    80004a58:	854a                	mv	a0,s2
    80004a5a:	ffffc097          	auipc	ra,0xffffc
    80004a5e:	2ae080e7          	jalr	686(ra) # 80000d08 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a62:	409c                	lw	a5,0(s1)
    80004a64:	ef99                	bnez	a5,80004a82 <holdingsleep+0x3e>
    80004a66:	4481                	li	s1,0
  release(&lk->lk);
    80004a68:	854a                	mv	a0,s2
    80004a6a:	ffffc097          	auipc	ra,0xffffc
    80004a6e:	352080e7          	jalr	850(ra) # 80000dbc <release>
  return r;
}
    80004a72:	8526                	mv	a0,s1
    80004a74:	70a2                	ld	ra,40(sp)
    80004a76:	7402                	ld	s0,32(sp)
    80004a78:	64e2                	ld	s1,24(sp)
    80004a7a:	6942                	ld	s2,16(sp)
    80004a7c:	69a2                	ld	s3,8(sp)
    80004a7e:	6145                	addi	sp,sp,48
    80004a80:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a82:	0284a983          	lw	s3,40(s1)
    80004a86:	ffffd097          	auipc	ra,0xffffd
    80004a8a:	172080e7          	jalr	370(ra) # 80001bf8 <myproc>
    80004a8e:	5904                	lw	s1,48(a0)
    80004a90:	413484b3          	sub	s1,s1,s3
    80004a94:	0014b493          	seqz	s1,s1
    80004a98:	bfc1                	j	80004a68 <holdingsleep+0x24>

0000000080004a9a <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004a9a:	1141                	addi	sp,sp,-16
    80004a9c:	e406                	sd	ra,8(sp)
    80004a9e:	e022                	sd	s0,0(sp)
    80004aa0:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004aa2:	00004597          	auipc	a1,0x4
    80004aa6:	d7e58593          	addi	a1,a1,-642 # 80008820 <syscalls+0x260>
    80004aaa:	0045c517          	auipc	a0,0x45c
    80004aae:	39e50513          	addi	a0,a0,926 # 80460e48 <ftable>
    80004ab2:	ffffc097          	auipc	ra,0xffffc
    80004ab6:	1c6080e7          	jalr	454(ra) # 80000c78 <initlock>
}
    80004aba:	60a2                	ld	ra,8(sp)
    80004abc:	6402                	ld	s0,0(sp)
    80004abe:	0141                	addi	sp,sp,16
    80004ac0:	8082                	ret

0000000080004ac2 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004ac2:	1101                	addi	sp,sp,-32
    80004ac4:	ec06                	sd	ra,24(sp)
    80004ac6:	e822                	sd	s0,16(sp)
    80004ac8:	e426                	sd	s1,8(sp)
    80004aca:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004acc:	0045c517          	auipc	a0,0x45c
    80004ad0:	37c50513          	addi	a0,a0,892 # 80460e48 <ftable>
    80004ad4:	ffffc097          	auipc	ra,0xffffc
    80004ad8:	234080e7          	jalr	564(ra) # 80000d08 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004adc:	0045c497          	auipc	s1,0x45c
    80004ae0:	38448493          	addi	s1,s1,900 # 80460e60 <ftable+0x18>
    80004ae4:	0045d717          	auipc	a4,0x45d
    80004ae8:	31c70713          	addi	a4,a4,796 # 80461e00 <disk>
    if(f->ref == 0){
    80004aec:	40dc                	lw	a5,4(s1)
    80004aee:	cf99                	beqz	a5,80004b0c <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004af0:	02848493          	addi	s1,s1,40
    80004af4:	fee49ce3          	bne	s1,a4,80004aec <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004af8:	0045c517          	auipc	a0,0x45c
    80004afc:	35050513          	addi	a0,a0,848 # 80460e48 <ftable>
    80004b00:	ffffc097          	auipc	ra,0xffffc
    80004b04:	2bc080e7          	jalr	700(ra) # 80000dbc <release>
  return 0;
    80004b08:	4481                	li	s1,0
    80004b0a:	a819                	j	80004b20 <filealloc+0x5e>
      f->ref = 1;
    80004b0c:	4785                	li	a5,1
    80004b0e:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004b10:	0045c517          	auipc	a0,0x45c
    80004b14:	33850513          	addi	a0,a0,824 # 80460e48 <ftable>
    80004b18:	ffffc097          	auipc	ra,0xffffc
    80004b1c:	2a4080e7          	jalr	676(ra) # 80000dbc <release>
}
    80004b20:	8526                	mv	a0,s1
    80004b22:	60e2                	ld	ra,24(sp)
    80004b24:	6442                	ld	s0,16(sp)
    80004b26:	64a2                	ld	s1,8(sp)
    80004b28:	6105                	addi	sp,sp,32
    80004b2a:	8082                	ret

0000000080004b2c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004b2c:	1101                	addi	sp,sp,-32
    80004b2e:	ec06                	sd	ra,24(sp)
    80004b30:	e822                	sd	s0,16(sp)
    80004b32:	e426                	sd	s1,8(sp)
    80004b34:	1000                	addi	s0,sp,32
    80004b36:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004b38:	0045c517          	auipc	a0,0x45c
    80004b3c:	31050513          	addi	a0,a0,784 # 80460e48 <ftable>
    80004b40:	ffffc097          	auipc	ra,0xffffc
    80004b44:	1c8080e7          	jalr	456(ra) # 80000d08 <acquire>
  if(f->ref < 1)
    80004b48:	40dc                	lw	a5,4(s1)
    80004b4a:	02f05263          	blez	a5,80004b6e <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004b4e:	2785                	addiw	a5,a5,1
    80004b50:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004b52:	0045c517          	auipc	a0,0x45c
    80004b56:	2f650513          	addi	a0,a0,758 # 80460e48 <ftable>
    80004b5a:	ffffc097          	auipc	ra,0xffffc
    80004b5e:	262080e7          	jalr	610(ra) # 80000dbc <release>
  return f;
}
    80004b62:	8526                	mv	a0,s1
    80004b64:	60e2                	ld	ra,24(sp)
    80004b66:	6442                	ld	s0,16(sp)
    80004b68:	64a2                	ld	s1,8(sp)
    80004b6a:	6105                	addi	sp,sp,32
    80004b6c:	8082                	ret
    panic("filedup");
    80004b6e:	00004517          	auipc	a0,0x4
    80004b72:	cba50513          	addi	a0,a0,-838 # 80008828 <syscalls+0x268>
    80004b76:	ffffc097          	auipc	ra,0xffffc
    80004b7a:	9ca080e7          	jalr	-1590(ra) # 80000540 <panic>

0000000080004b7e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004b7e:	7139                	addi	sp,sp,-64
    80004b80:	fc06                	sd	ra,56(sp)
    80004b82:	f822                	sd	s0,48(sp)
    80004b84:	f426                	sd	s1,40(sp)
    80004b86:	f04a                	sd	s2,32(sp)
    80004b88:	ec4e                	sd	s3,24(sp)
    80004b8a:	e852                	sd	s4,16(sp)
    80004b8c:	e456                	sd	s5,8(sp)
    80004b8e:	0080                	addi	s0,sp,64
    80004b90:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004b92:	0045c517          	auipc	a0,0x45c
    80004b96:	2b650513          	addi	a0,a0,694 # 80460e48 <ftable>
    80004b9a:	ffffc097          	auipc	ra,0xffffc
    80004b9e:	16e080e7          	jalr	366(ra) # 80000d08 <acquire>
  if(f->ref < 1)
    80004ba2:	40dc                	lw	a5,4(s1)
    80004ba4:	06f05163          	blez	a5,80004c06 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004ba8:	37fd                	addiw	a5,a5,-1
    80004baa:	0007871b          	sext.w	a4,a5
    80004bae:	c0dc                	sw	a5,4(s1)
    80004bb0:	06e04363          	bgtz	a4,80004c16 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004bb4:	0004a903          	lw	s2,0(s1)
    80004bb8:	0094ca83          	lbu	s5,9(s1)
    80004bbc:	0104ba03          	ld	s4,16(s1)
    80004bc0:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004bc4:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004bc8:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004bcc:	0045c517          	auipc	a0,0x45c
    80004bd0:	27c50513          	addi	a0,a0,636 # 80460e48 <ftable>
    80004bd4:	ffffc097          	auipc	ra,0xffffc
    80004bd8:	1e8080e7          	jalr	488(ra) # 80000dbc <release>

  if(ff.type == FD_PIPE){
    80004bdc:	4785                	li	a5,1
    80004bde:	04f90d63          	beq	s2,a5,80004c38 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004be2:	3979                	addiw	s2,s2,-2
    80004be4:	4785                	li	a5,1
    80004be6:	0527e063          	bltu	a5,s2,80004c26 <fileclose+0xa8>
    begin_op();
    80004bea:	00000097          	auipc	ra,0x0
    80004bee:	acc080e7          	jalr	-1332(ra) # 800046b6 <begin_op>
    iput(ff.ip);
    80004bf2:	854e                	mv	a0,s3
    80004bf4:	fffff097          	auipc	ra,0xfffff
    80004bf8:	2b0080e7          	jalr	688(ra) # 80003ea4 <iput>
    end_op();
    80004bfc:	00000097          	auipc	ra,0x0
    80004c00:	b38080e7          	jalr	-1224(ra) # 80004734 <end_op>
    80004c04:	a00d                	j	80004c26 <fileclose+0xa8>
    panic("fileclose");
    80004c06:	00004517          	auipc	a0,0x4
    80004c0a:	c2a50513          	addi	a0,a0,-982 # 80008830 <syscalls+0x270>
    80004c0e:	ffffc097          	auipc	ra,0xffffc
    80004c12:	932080e7          	jalr	-1742(ra) # 80000540 <panic>
    release(&ftable.lock);
    80004c16:	0045c517          	auipc	a0,0x45c
    80004c1a:	23250513          	addi	a0,a0,562 # 80460e48 <ftable>
    80004c1e:	ffffc097          	auipc	ra,0xffffc
    80004c22:	19e080e7          	jalr	414(ra) # 80000dbc <release>
  }
}
    80004c26:	70e2                	ld	ra,56(sp)
    80004c28:	7442                	ld	s0,48(sp)
    80004c2a:	74a2                	ld	s1,40(sp)
    80004c2c:	7902                	ld	s2,32(sp)
    80004c2e:	69e2                	ld	s3,24(sp)
    80004c30:	6a42                	ld	s4,16(sp)
    80004c32:	6aa2                	ld	s5,8(sp)
    80004c34:	6121                	addi	sp,sp,64
    80004c36:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004c38:	85d6                	mv	a1,s5
    80004c3a:	8552                	mv	a0,s4
    80004c3c:	00000097          	auipc	ra,0x0
    80004c40:	34c080e7          	jalr	844(ra) # 80004f88 <pipeclose>
    80004c44:	b7cd                	j	80004c26 <fileclose+0xa8>

0000000080004c46 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004c46:	715d                	addi	sp,sp,-80
    80004c48:	e486                	sd	ra,72(sp)
    80004c4a:	e0a2                	sd	s0,64(sp)
    80004c4c:	fc26                	sd	s1,56(sp)
    80004c4e:	f84a                	sd	s2,48(sp)
    80004c50:	f44e                	sd	s3,40(sp)
    80004c52:	0880                	addi	s0,sp,80
    80004c54:	84aa                	mv	s1,a0
    80004c56:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004c58:	ffffd097          	auipc	ra,0xffffd
    80004c5c:	fa0080e7          	jalr	-96(ra) # 80001bf8 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004c60:	409c                	lw	a5,0(s1)
    80004c62:	37f9                	addiw	a5,a5,-2
    80004c64:	4705                	li	a4,1
    80004c66:	04f76763          	bltu	a4,a5,80004cb4 <filestat+0x6e>
    80004c6a:	892a                	mv	s2,a0
    ilock(f->ip);
    80004c6c:	6c88                	ld	a0,24(s1)
    80004c6e:	fffff097          	auipc	ra,0xfffff
    80004c72:	07c080e7          	jalr	124(ra) # 80003cea <ilock>
    stati(f->ip, &st);
    80004c76:	fb840593          	addi	a1,s0,-72
    80004c7a:	6c88                	ld	a0,24(s1)
    80004c7c:	fffff097          	auipc	ra,0xfffff
    80004c80:	2f8080e7          	jalr	760(ra) # 80003f74 <stati>
    iunlock(f->ip);
    80004c84:	6c88                	ld	a0,24(s1)
    80004c86:	fffff097          	auipc	ra,0xfffff
    80004c8a:	126080e7          	jalr	294(ra) # 80003dac <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004c8e:	46e1                	li	a3,24
    80004c90:	fb840613          	addi	a2,s0,-72
    80004c94:	85ce                	mv	a1,s3
    80004c96:	05093503          	ld	a0,80(s2)
    80004c9a:	ffffd097          	auipc	ra,0xffffd
    80004c9e:	b20080e7          	jalr	-1248(ra) # 800017ba <copyout>
    80004ca2:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004ca6:	60a6                	ld	ra,72(sp)
    80004ca8:	6406                	ld	s0,64(sp)
    80004caa:	74e2                	ld	s1,56(sp)
    80004cac:	7942                	ld	s2,48(sp)
    80004cae:	79a2                	ld	s3,40(sp)
    80004cb0:	6161                	addi	sp,sp,80
    80004cb2:	8082                	ret
  return -1;
    80004cb4:	557d                	li	a0,-1
    80004cb6:	bfc5                	j	80004ca6 <filestat+0x60>

0000000080004cb8 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004cb8:	7179                	addi	sp,sp,-48
    80004cba:	f406                	sd	ra,40(sp)
    80004cbc:	f022                	sd	s0,32(sp)
    80004cbe:	ec26                	sd	s1,24(sp)
    80004cc0:	e84a                	sd	s2,16(sp)
    80004cc2:	e44e                	sd	s3,8(sp)
    80004cc4:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004cc6:	00854783          	lbu	a5,8(a0)
    80004cca:	c3d5                	beqz	a5,80004d6e <fileread+0xb6>
    80004ccc:	84aa                	mv	s1,a0
    80004cce:	89ae                	mv	s3,a1
    80004cd0:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004cd2:	411c                	lw	a5,0(a0)
    80004cd4:	4705                	li	a4,1
    80004cd6:	04e78963          	beq	a5,a4,80004d28 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004cda:	470d                	li	a4,3
    80004cdc:	04e78d63          	beq	a5,a4,80004d36 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004ce0:	4709                	li	a4,2
    80004ce2:	06e79e63          	bne	a5,a4,80004d5e <fileread+0xa6>
    ilock(f->ip);
    80004ce6:	6d08                	ld	a0,24(a0)
    80004ce8:	fffff097          	auipc	ra,0xfffff
    80004cec:	002080e7          	jalr	2(ra) # 80003cea <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004cf0:	874a                	mv	a4,s2
    80004cf2:	5094                	lw	a3,32(s1)
    80004cf4:	864e                	mv	a2,s3
    80004cf6:	4585                	li	a1,1
    80004cf8:	6c88                	ld	a0,24(s1)
    80004cfa:	fffff097          	auipc	ra,0xfffff
    80004cfe:	2a4080e7          	jalr	676(ra) # 80003f9e <readi>
    80004d02:	892a                	mv	s2,a0
    80004d04:	00a05563          	blez	a0,80004d0e <fileread+0x56>
      f->off += r;
    80004d08:	509c                	lw	a5,32(s1)
    80004d0a:	9fa9                	addw	a5,a5,a0
    80004d0c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004d0e:	6c88                	ld	a0,24(s1)
    80004d10:	fffff097          	auipc	ra,0xfffff
    80004d14:	09c080e7          	jalr	156(ra) # 80003dac <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004d18:	854a                	mv	a0,s2
    80004d1a:	70a2                	ld	ra,40(sp)
    80004d1c:	7402                	ld	s0,32(sp)
    80004d1e:	64e2                	ld	s1,24(sp)
    80004d20:	6942                	ld	s2,16(sp)
    80004d22:	69a2                	ld	s3,8(sp)
    80004d24:	6145                	addi	sp,sp,48
    80004d26:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004d28:	6908                	ld	a0,16(a0)
    80004d2a:	00000097          	auipc	ra,0x0
    80004d2e:	3c6080e7          	jalr	966(ra) # 800050f0 <piperead>
    80004d32:	892a                	mv	s2,a0
    80004d34:	b7d5                	j	80004d18 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004d36:	02451783          	lh	a5,36(a0)
    80004d3a:	03079693          	slli	a3,a5,0x30
    80004d3e:	92c1                	srli	a3,a3,0x30
    80004d40:	4725                	li	a4,9
    80004d42:	02d76863          	bltu	a4,a3,80004d72 <fileread+0xba>
    80004d46:	0792                	slli	a5,a5,0x4
    80004d48:	0045c717          	auipc	a4,0x45c
    80004d4c:	06070713          	addi	a4,a4,96 # 80460da8 <devsw>
    80004d50:	97ba                	add	a5,a5,a4
    80004d52:	639c                	ld	a5,0(a5)
    80004d54:	c38d                	beqz	a5,80004d76 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004d56:	4505                	li	a0,1
    80004d58:	9782                	jalr	a5
    80004d5a:	892a                	mv	s2,a0
    80004d5c:	bf75                	j	80004d18 <fileread+0x60>
    panic("fileread");
    80004d5e:	00004517          	auipc	a0,0x4
    80004d62:	ae250513          	addi	a0,a0,-1310 # 80008840 <syscalls+0x280>
    80004d66:	ffffb097          	auipc	ra,0xffffb
    80004d6a:	7da080e7          	jalr	2010(ra) # 80000540 <panic>
    return -1;
    80004d6e:	597d                	li	s2,-1
    80004d70:	b765                	j	80004d18 <fileread+0x60>
      return -1;
    80004d72:	597d                	li	s2,-1
    80004d74:	b755                	j	80004d18 <fileread+0x60>
    80004d76:	597d                	li	s2,-1
    80004d78:	b745                	j	80004d18 <fileread+0x60>

0000000080004d7a <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004d7a:	715d                	addi	sp,sp,-80
    80004d7c:	e486                	sd	ra,72(sp)
    80004d7e:	e0a2                	sd	s0,64(sp)
    80004d80:	fc26                	sd	s1,56(sp)
    80004d82:	f84a                	sd	s2,48(sp)
    80004d84:	f44e                	sd	s3,40(sp)
    80004d86:	f052                	sd	s4,32(sp)
    80004d88:	ec56                	sd	s5,24(sp)
    80004d8a:	e85a                	sd	s6,16(sp)
    80004d8c:	e45e                	sd	s7,8(sp)
    80004d8e:	e062                	sd	s8,0(sp)
    80004d90:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004d92:	00954783          	lbu	a5,9(a0)
    80004d96:	10078663          	beqz	a5,80004ea2 <filewrite+0x128>
    80004d9a:	892a                	mv	s2,a0
    80004d9c:	8b2e                	mv	s6,a1
    80004d9e:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004da0:	411c                	lw	a5,0(a0)
    80004da2:	4705                	li	a4,1
    80004da4:	02e78263          	beq	a5,a4,80004dc8 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004da8:	470d                	li	a4,3
    80004daa:	02e78663          	beq	a5,a4,80004dd6 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004dae:	4709                	li	a4,2
    80004db0:	0ee79163          	bne	a5,a4,80004e92 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004db4:	0ac05d63          	blez	a2,80004e6e <filewrite+0xf4>
    int i = 0;
    80004db8:	4981                	li	s3,0
    80004dba:	6b85                	lui	s7,0x1
    80004dbc:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004dc0:	6c05                	lui	s8,0x1
    80004dc2:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004dc6:	a861                	j	80004e5e <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004dc8:	6908                	ld	a0,16(a0)
    80004dca:	00000097          	auipc	ra,0x0
    80004dce:	22e080e7          	jalr	558(ra) # 80004ff8 <pipewrite>
    80004dd2:	8a2a                	mv	s4,a0
    80004dd4:	a045                	j	80004e74 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004dd6:	02451783          	lh	a5,36(a0)
    80004dda:	03079693          	slli	a3,a5,0x30
    80004dde:	92c1                	srli	a3,a3,0x30
    80004de0:	4725                	li	a4,9
    80004de2:	0cd76263          	bltu	a4,a3,80004ea6 <filewrite+0x12c>
    80004de6:	0792                	slli	a5,a5,0x4
    80004de8:	0045c717          	auipc	a4,0x45c
    80004dec:	fc070713          	addi	a4,a4,-64 # 80460da8 <devsw>
    80004df0:	97ba                	add	a5,a5,a4
    80004df2:	679c                	ld	a5,8(a5)
    80004df4:	cbdd                	beqz	a5,80004eaa <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004df6:	4505                	li	a0,1
    80004df8:	9782                	jalr	a5
    80004dfa:	8a2a                	mv	s4,a0
    80004dfc:	a8a5                	j	80004e74 <filewrite+0xfa>
    80004dfe:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004e02:	00000097          	auipc	ra,0x0
    80004e06:	8b4080e7          	jalr	-1868(ra) # 800046b6 <begin_op>
      ilock(f->ip);
    80004e0a:	01893503          	ld	a0,24(s2)
    80004e0e:	fffff097          	auipc	ra,0xfffff
    80004e12:	edc080e7          	jalr	-292(ra) # 80003cea <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004e16:	8756                	mv	a4,s5
    80004e18:	02092683          	lw	a3,32(s2)
    80004e1c:	01698633          	add	a2,s3,s6
    80004e20:	4585                	li	a1,1
    80004e22:	01893503          	ld	a0,24(s2)
    80004e26:	fffff097          	auipc	ra,0xfffff
    80004e2a:	270080e7          	jalr	624(ra) # 80004096 <writei>
    80004e2e:	84aa                	mv	s1,a0
    80004e30:	00a05763          	blez	a0,80004e3e <filewrite+0xc4>
        f->off += r;
    80004e34:	02092783          	lw	a5,32(s2)
    80004e38:	9fa9                	addw	a5,a5,a0
    80004e3a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004e3e:	01893503          	ld	a0,24(s2)
    80004e42:	fffff097          	auipc	ra,0xfffff
    80004e46:	f6a080e7          	jalr	-150(ra) # 80003dac <iunlock>
      end_op();
    80004e4a:	00000097          	auipc	ra,0x0
    80004e4e:	8ea080e7          	jalr	-1814(ra) # 80004734 <end_op>

      if(r != n1){
    80004e52:	009a9f63          	bne	s5,s1,80004e70 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004e56:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004e5a:	0149db63          	bge	s3,s4,80004e70 <filewrite+0xf6>
      int n1 = n - i;
    80004e5e:	413a04bb          	subw	s1,s4,s3
    80004e62:	0004879b          	sext.w	a5,s1
    80004e66:	f8fbdce3          	bge	s7,a5,80004dfe <filewrite+0x84>
    80004e6a:	84e2                	mv	s1,s8
    80004e6c:	bf49                	j	80004dfe <filewrite+0x84>
    int i = 0;
    80004e6e:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004e70:	013a1f63          	bne	s4,s3,80004e8e <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004e74:	8552                	mv	a0,s4
    80004e76:	60a6                	ld	ra,72(sp)
    80004e78:	6406                	ld	s0,64(sp)
    80004e7a:	74e2                	ld	s1,56(sp)
    80004e7c:	7942                	ld	s2,48(sp)
    80004e7e:	79a2                	ld	s3,40(sp)
    80004e80:	7a02                	ld	s4,32(sp)
    80004e82:	6ae2                	ld	s5,24(sp)
    80004e84:	6b42                	ld	s6,16(sp)
    80004e86:	6ba2                	ld	s7,8(sp)
    80004e88:	6c02                	ld	s8,0(sp)
    80004e8a:	6161                	addi	sp,sp,80
    80004e8c:	8082                	ret
    ret = (i == n ? n : -1);
    80004e8e:	5a7d                	li	s4,-1
    80004e90:	b7d5                	j	80004e74 <filewrite+0xfa>
    panic("filewrite");
    80004e92:	00004517          	auipc	a0,0x4
    80004e96:	9be50513          	addi	a0,a0,-1602 # 80008850 <syscalls+0x290>
    80004e9a:	ffffb097          	auipc	ra,0xffffb
    80004e9e:	6a6080e7          	jalr	1702(ra) # 80000540 <panic>
    return -1;
    80004ea2:	5a7d                	li	s4,-1
    80004ea4:	bfc1                	j	80004e74 <filewrite+0xfa>
      return -1;
    80004ea6:	5a7d                	li	s4,-1
    80004ea8:	b7f1                	j	80004e74 <filewrite+0xfa>
    80004eaa:	5a7d                	li	s4,-1
    80004eac:	b7e1                	j	80004e74 <filewrite+0xfa>

0000000080004eae <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004eae:	7179                	addi	sp,sp,-48
    80004eb0:	f406                	sd	ra,40(sp)
    80004eb2:	f022                	sd	s0,32(sp)
    80004eb4:	ec26                	sd	s1,24(sp)
    80004eb6:	e84a                	sd	s2,16(sp)
    80004eb8:	e44e                	sd	s3,8(sp)
    80004eba:	e052                	sd	s4,0(sp)
    80004ebc:	1800                	addi	s0,sp,48
    80004ebe:	84aa                	mv	s1,a0
    80004ec0:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004ec2:	0005b023          	sd	zero,0(a1)
    80004ec6:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004eca:	00000097          	auipc	ra,0x0
    80004ece:	bf8080e7          	jalr	-1032(ra) # 80004ac2 <filealloc>
    80004ed2:	e088                	sd	a0,0(s1)
    80004ed4:	c551                	beqz	a0,80004f60 <pipealloc+0xb2>
    80004ed6:	00000097          	auipc	ra,0x0
    80004eda:	bec080e7          	jalr	-1044(ra) # 80004ac2 <filealloc>
    80004ede:	00aa3023          	sd	a0,0(s4)
    80004ee2:	c92d                	beqz	a0,80004f54 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004ee4:	ffffc097          	auipc	ra,0xffffc
    80004ee8:	ce8080e7          	jalr	-792(ra) # 80000bcc <kalloc>
    80004eec:	892a                	mv	s2,a0
    80004eee:	c125                	beqz	a0,80004f4e <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004ef0:	4985                	li	s3,1
    80004ef2:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004ef6:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004efa:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004efe:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004f02:	00004597          	auipc	a1,0x4
    80004f06:	95e58593          	addi	a1,a1,-1698 # 80008860 <syscalls+0x2a0>
    80004f0a:	ffffc097          	auipc	ra,0xffffc
    80004f0e:	d6e080e7          	jalr	-658(ra) # 80000c78 <initlock>
  (*f0)->type = FD_PIPE;
    80004f12:	609c                	ld	a5,0(s1)
    80004f14:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004f18:	609c                	ld	a5,0(s1)
    80004f1a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004f1e:	609c                	ld	a5,0(s1)
    80004f20:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004f24:	609c                	ld	a5,0(s1)
    80004f26:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004f2a:	000a3783          	ld	a5,0(s4)
    80004f2e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004f32:	000a3783          	ld	a5,0(s4)
    80004f36:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004f3a:	000a3783          	ld	a5,0(s4)
    80004f3e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004f42:	000a3783          	ld	a5,0(s4)
    80004f46:	0127b823          	sd	s2,16(a5)
  return 0;
    80004f4a:	4501                	li	a0,0
    80004f4c:	a025                	j	80004f74 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004f4e:	6088                	ld	a0,0(s1)
    80004f50:	e501                	bnez	a0,80004f58 <pipealloc+0xaa>
    80004f52:	a039                	j	80004f60 <pipealloc+0xb2>
    80004f54:	6088                	ld	a0,0(s1)
    80004f56:	c51d                	beqz	a0,80004f84 <pipealloc+0xd6>
    fileclose(*f0);
    80004f58:	00000097          	auipc	ra,0x0
    80004f5c:	c26080e7          	jalr	-986(ra) # 80004b7e <fileclose>
  if(*f1)
    80004f60:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004f64:	557d                	li	a0,-1
  if(*f1)
    80004f66:	c799                	beqz	a5,80004f74 <pipealloc+0xc6>
    fileclose(*f1);
    80004f68:	853e                	mv	a0,a5
    80004f6a:	00000097          	auipc	ra,0x0
    80004f6e:	c14080e7          	jalr	-1004(ra) # 80004b7e <fileclose>
  return -1;
    80004f72:	557d                	li	a0,-1
}
    80004f74:	70a2                	ld	ra,40(sp)
    80004f76:	7402                	ld	s0,32(sp)
    80004f78:	64e2                	ld	s1,24(sp)
    80004f7a:	6942                	ld	s2,16(sp)
    80004f7c:	69a2                	ld	s3,8(sp)
    80004f7e:	6a02                	ld	s4,0(sp)
    80004f80:	6145                	addi	sp,sp,48
    80004f82:	8082                	ret
  return -1;
    80004f84:	557d                	li	a0,-1
    80004f86:	b7fd                	j	80004f74 <pipealloc+0xc6>

0000000080004f88 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004f88:	1101                	addi	sp,sp,-32
    80004f8a:	ec06                	sd	ra,24(sp)
    80004f8c:	e822                	sd	s0,16(sp)
    80004f8e:	e426                	sd	s1,8(sp)
    80004f90:	e04a                	sd	s2,0(sp)
    80004f92:	1000                	addi	s0,sp,32
    80004f94:	84aa                	mv	s1,a0
    80004f96:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004f98:	ffffc097          	auipc	ra,0xffffc
    80004f9c:	d70080e7          	jalr	-656(ra) # 80000d08 <acquire>
  if(writable){
    80004fa0:	02090d63          	beqz	s2,80004fda <pipeclose+0x52>
    pi->writeopen = 0;
    80004fa4:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004fa8:	21848513          	addi	a0,s1,536
    80004fac:	ffffd097          	auipc	ra,0xffffd
    80004fb0:	470080e7          	jalr	1136(ra) # 8000241c <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004fb4:	2204b783          	ld	a5,544(s1)
    80004fb8:	eb95                	bnez	a5,80004fec <pipeclose+0x64>
    release(&pi->lock);
    80004fba:	8526                	mv	a0,s1
    80004fbc:	ffffc097          	auipc	ra,0xffffc
    80004fc0:	e00080e7          	jalr	-512(ra) # 80000dbc <release>
    kfree((char*)pi);
    80004fc4:	8526                	mv	a0,s1
    80004fc6:	ffffc097          	auipc	ra,0xffffc
    80004fca:	a74080e7          	jalr	-1420(ra) # 80000a3a <kfree>
  } else
    release(&pi->lock);
}
    80004fce:	60e2                	ld	ra,24(sp)
    80004fd0:	6442                	ld	s0,16(sp)
    80004fd2:	64a2                	ld	s1,8(sp)
    80004fd4:	6902                	ld	s2,0(sp)
    80004fd6:	6105                	addi	sp,sp,32
    80004fd8:	8082                	ret
    pi->readopen = 0;
    80004fda:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004fde:	21c48513          	addi	a0,s1,540
    80004fe2:	ffffd097          	auipc	ra,0xffffd
    80004fe6:	43a080e7          	jalr	1082(ra) # 8000241c <wakeup>
    80004fea:	b7e9                	j	80004fb4 <pipeclose+0x2c>
    release(&pi->lock);
    80004fec:	8526                	mv	a0,s1
    80004fee:	ffffc097          	auipc	ra,0xffffc
    80004ff2:	dce080e7          	jalr	-562(ra) # 80000dbc <release>
}
    80004ff6:	bfe1                	j	80004fce <pipeclose+0x46>

0000000080004ff8 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004ff8:	711d                	addi	sp,sp,-96
    80004ffa:	ec86                	sd	ra,88(sp)
    80004ffc:	e8a2                	sd	s0,80(sp)
    80004ffe:	e4a6                	sd	s1,72(sp)
    80005000:	e0ca                	sd	s2,64(sp)
    80005002:	fc4e                	sd	s3,56(sp)
    80005004:	f852                	sd	s4,48(sp)
    80005006:	f456                	sd	s5,40(sp)
    80005008:	f05a                	sd	s6,32(sp)
    8000500a:	ec5e                	sd	s7,24(sp)
    8000500c:	e862                	sd	s8,16(sp)
    8000500e:	1080                	addi	s0,sp,96
    80005010:	84aa                	mv	s1,a0
    80005012:	8aae                	mv	s5,a1
    80005014:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005016:	ffffd097          	auipc	ra,0xffffd
    8000501a:	be2080e7          	jalr	-1054(ra) # 80001bf8 <myproc>
    8000501e:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005020:	8526                	mv	a0,s1
    80005022:	ffffc097          	auipc	ra,0xffffc
    80005026:	ce6080e7          	jalr	-794(ra) # 80000d08 <acquire>
  while(i < n){
    8000502a:	0b405663          	blez	s4,800050d6 <pipewrite+0xde>
  int i = 0;
    8000502e:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005030:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005032:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005036:	21c48b93          	addi	s7,s1,540
    8000503a:	a089                	j	8000507c <pipewrite+0x84>
      release(&pi->lock);
    8000503c:	8526                	mv	a0,s1
    8000503e:	ffffc097          	auipc	ra,0xffffc
    80005042:	d7e080e7          	jalr	-642(ra) # 80000dbc <release>
      return -1;
    80005046:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005048:	854a                	mv	a0,s2
    8000504a:	60e6                	ld	ra,88(sp)
    8000504c:	6446                	ld	s0,80(sp)
    8000504e:	64a6                	ld	s1,72(sp)
    80005050:	6906                	ld	s2,64(sp)
    80005052:	79e2                	ld	s3,56(sp)
    80005054:	7a42                	ld	s4,48(sp)
    80005056:	7aa2                	ld	s5,40(sp)
    80005058:	7b02                	ld	s6,32(sp)
    8000505a:	6be2                	ld	s7,24(sp)
    8000505c:	6c42                	ld	s8,16(sp)
    8000505e:	6125                	addi	sp,sp,96
    80005060:	8082                	ret
      wakeup(&pi->nread);
    80005062:	8562                	mv	a0,s8
    80005064:	ffffd097          	auipc	ra,0xffffd
    80005068:	3b8080e7          	jalr	952(ra) # 8000241c <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000506c:	85a6                	mv	a1,s1
    8000506e:	855e                	mv	a0,s7
    80005070:	ffffd097          	auipc	ra,0xffffd
    80005074:	348080e7          	jalr	840(ra) # 800023b8 <sleep>
  while(i < n){
    80005078:	07495063          	bge	s2,s4,800050d8 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    8000507c:	2204a783          	lw	a5,544(s1)
    80005080:	dfd5                	beqz	a5,8000503c <pipewrite+0x44>
    80005082:	854e                	mv	a0,s3
    80005084:	ffffd097          	auipc	ra,0xffffd
    80005088:	5dc080e7          	jalr	1500(ra) # 80002660 <killed>
    8000508c:	f945                	bnez	a0,8000503c <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    8000508e:	2184a783          	lw	a5,536(s1)
    80005092:	21c4a703          	lw	a4,540(s1)
    80005096:	2007879b          	addiw	a5,a5,512
    8000509a:	fcf704e3          	beq	a4,a5,80005062 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000509e:	4685                	li	a3,1
    800050a0:	01590633          	add	a2,s2,s5
    800050a4:	faf40593          	addi	a1,s0,-81
    800050a8:	0509b503          	ld	a0,80(s3)
    800050ac:	ffffc097          	auipc	ra,0xffffc
    800050b0:	79a080e7          	jalr	1946(ra) # 80001846 <copyin>
    800050b4:	03650263          	beq	a0,s6,800050d8 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800050b8:	21c4a783          	lw	a5,540(s1)
    800050bc:	0017871b          	addiw	a4,a5,1
    800050c0:	20e4ae23          	sw	a4,540(s1)
    800050c4:	1ff7f793          	andi	a5,a5,511
    800050c8:	97a6                	add	a5,a5,s1
    800050ca:	faf44703          	lbu	a4,-81(s0)
    800050ce:	00e78c23          	sb	a4,24(a5)
      i++;
    800050d2:	2905                	addiw	s2,s2,1
    800050d4:	b755                	j	80005078 <pipewrite+0x80>
  int i = 0;
    800050d6:	4901                	li	s2,0
  wakeup(&pi->nread);
    800050d8:	21848513          	addi	a0,s1,536
    800050dc:	ffffd097          	auipc	ra,0xffffd
    800050e0:	340080e7          	jalr	832(ra) # 8000241c <wakeup>
  release(&pi->lock);
    800050e4:	8526                	mv	a0,s1
    800050e6:	ffffc097          	auipc	ra,0xffffc
    800050ea:	cd6080e7          	jalr	-810(ra) # 80000dbc <release>
  return i;
    800050ee:	bfa9                	j	80005048 <pipewrite+0x50>

00000000800050f0 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800050f0:	715d                	addi	sp,sp,-80
    800050f2:	e486                	sd	ra,72(sp)
    800050f4:	e0a2                	sd	s0,64(sp)
    800050f6:	fc26                	sd	s1,56(sp)
    800050f8:	f84a                	sd	s2,48(sp)
    800050fa:	f44e                	sd	s3,40(sp)
    800050fc:	f052                	sd	s4,32(sp)
    800050fe:	ec56                	sd	s5,24(sp)
    80005100:	e85a                	sd	s6,16(sp)
    80005102:	0880                	addi	s0,sp,80
    80005104:	84aa                	mv	s1,a0
    80005106:	892e                	mv	s2,a1
    80005108:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000510a:	ffffd097          	auipc	ra,0xffffd
    8000510e:	aee080e7          	jalr	-1298(ra) # 80001bf8 <myproc>
    80005112:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005114:	8526                	mv	a0,s1
    80005116:	ffffc097          	auipc	ra,0xffffc
    8000511a:	bf2080e7          	jalr	-1038(ra) # 80000d08 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000511e:	2184a703          	lw	a4,536(s1)
    80005122:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005126:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000512a:	02f71763          	bne	a4,a5,80005158 <piperead+0x68>
    8000512e:	2244a783          	lw	a5,548(s1)
    80005132:	c39d                	beqz	a5,80005158 <piperead+0x68>
    if(killed(pr)){
    80005134:	8552                	mv	a0,s4
    80005136:	ffffd097          	auipc	ra,0xffffd
    8000513a:	52a080e7          	jalr	1322(ra) # 80002660 <killed>
    8000513e:	e949                	bnez	a0,800051d0 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005140:	85a6                	mv	a1,s1
    80005142:	854e                	mv	a0,s3
    80005144:	ffffd097          	auipc	ra,0xffffd
    80005148:	274080e7          	jalr	628(ra) # 800023b8 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000514c:	2184a703          	lw	a4,536(s1)
    80005150:	21c4a783          	lw	a5,540(s1)
    80005154:	fcf70de3          	beq	a4,a5,8000512e <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005158:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000515a:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000515c:	05505463          	blez	s5,800051a4 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80005160:	2184a783          	lw	a5,536(s1)
    80005164:	21c4a703          	lw	a4,540(s1)
    80005168:	02f70e63          	beq	a4,a5,800051a4 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000516c:	0017871b          	addiw	a4,a5,1
    80005170:	20e4ac23          	sw	a4,536(s1)
    80005174:	1ff7f793          	andi	a5,a5,511
    80005178:	97a6                	add	a5,a5,s1
    8000517a:	0187c783          	lbu	a5,24(a5)
    8000517e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005182:	4685                	li	a3,1
    80005184:	fbf40613          	addi	a2,s0,-65
    80005188:	85ca                	mv	a1,s2
    8000518a:	050a3503          	ld	a0,80(s4)
    8000518e:	ffffc097          	auipc	ra,0xffffc
    80005192:	62c080e7          	jalr	1580(ra) # 800017ba <copyout>
    80005196:	01650763          	beq	a0,s6,800051a4 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000519a:	2985                	addiw	s3,s3,1
    8000519c:	0905                	addi	s2,s2,1
    8000519e:	fd3a91e3          	bne	s5,s3,80005160 <piperead+0x70>
    800051a2:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800051a4:	21c48513          	addi	a0,s1,540
    800051a8:	ffffd097          	auipc	ra,0xffffd
    800051ac:	274080e7          	jalr	628(ra) # 8000241c <wakeup>
  release(&pi->lock);
    800051b0:	8526                	mv	a0,s1
    800051b2:	ffffc097          	auipc	ra,0xffffc
    800051b6:	c0a080e7          	jalr	-1014(ra) # 80000dbc <release>
  return i;
}
    800051ba:	854e                	mv	a0,s3
    800051bc:	60a6                	ld	ra,72(sp)
    800051be:	6406                	ld	s0,64(sp)
    800051c0:	74e2                	ld	s1,56(sp)
    800051c2:	7942                	ld	s2,48(sp)
    800051c4:	79a2                	ld	s3,40(sp)
    800051c6:	7a02                	ld	s4,32(sp)
    800051c8:	6ae2                	ld	s5,24(sp)
    800051ca:	6b42                	ld	s6,16(sp)
    800051cc:	6161                	addi	sp,sp,80
    800051ce:	8082                	ret
      release(&pi->lock);
    800051d0:	8526                	mv	a0,s1
    800051d2:	ffffc097          	auipc	ra,0xffffc
    800051d6:	bea080e7          	jalr	-1046(ra) # 80000dbc <release>
      return -1;
    800051da:	59fd                	li	s3,-1
    800051dc:	bff9                	j	800051ba <piperead+0xca>

00000000800051de <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    800051de:	1141                	addi	sp,sp,-16
    800051e0:	e422                	sd	s0,8(sp)
    800051e2:	0800                	addi	s0,sp,16
    800051e4:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    800051e6:	8905                	andi	a0,a0,1
    800051e8:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    800051ea:	8b89                	andi	a5,a5,2
    800051ec:	c399                	beqz	a5,800051f2 <flags2perm+0x14>
      perm |= PTE_W;
    800051ee:	00456513          	ori	a0,a0,4
    return perm;
}
    800051f2:	6422                	ld	s0,8(sp)
    800051f4:	0141                	addi	sp,sp,16
    800051f6:	8082                	ret

00000000800051f8 <exec>:

int
exec(char *path, char **argv)
{
    800051f8:	de010113          	addi	sp,sp,-544
    800051fc:	20113c23          	sd	ra,536(sp)
    80005200:	20813823          	sd	s0,528(sp)
    80005204:	20913423          	sd	s1,520(sp)
    80005208:	21213023          	sd	s2,512(sp)
    8000520c:	ffce                	sd	s3,504(sp)
    8000520e:	fbd2                	sd	s4,496(sp)
    80005210:	f7d6                	sd	s5,488(sp)
    80005212:	f3da                	sd	s6,480(sp)
    80005214:	efde                	sd	s7,472(sp)
    80005216:	ebe2                	sd	s8,464(sp)
    80005218:	e7e6                	sd	s9,456(sp)
    8000521a:	e3ea                	sd	s10,448(sp)
    8000521c:	ff6e                	sd	s11,440(sp)
    8000521e:	1400                	addi	s0,sp,544
    80005220:	892a                	mv	s2,a0
    80005222:	dea43423          	sd	a0,-536(s0)
    80005226:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000522a:	ffffd097          	auipc	ra,0xffffd
    8000522e:	9ce080e7          	jalr	-1586(ra) # 80001bf8 <myproc>
    80005232:	84aa                	mv	s1,a0

  begin_op();
    80005234:	fffff097          	auipc	ra,0xfffff
    80005238:	482080e7          	jalr	1154(ra) # 800046b6 <begin_op>

  if((ip = namei(path)) == 0){
    8000523c:	854a                	mv	a0,s2
    8000523e:	fffff097          	auipc	ra,0xfffff
    80005242:	258080e7          	jalr	600(ra) # 80004496 <namei>
    80005246:	c93d                	beqz	a0,800052bc <exec+0xc4>
    80005248:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000524a:	fffff097          	auipc	ra,0xfffff
    8000524e:	aa0080e7          	jalr	-1376(ra) # 80003cea <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005252:	04000713          	li	a4,64
    80005256:	4681                	li	a3,0
    80005258:	e5040613          	addi	a2,s0,-432
    8000525c:	4581                	li	a1,0
    8000525e:	8556                	mv	a0,s5
    80005260:	fffff097          	auipc	ra,0xfffff
    80005264:	d3e080e7          	jalr	-706(ra) # 80003f9e <readi>
    80005268:	04000793          	li	a5,64
    8000526c:	00f51a63          	bne	a0,a5,80005280 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80005270:	e5042703          	lw	a4,-432(s0)
    80005274:	464c47b7          	lui	a5,0x464c4
    80005278:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000527c:	04f70663          	beq	a4,a5,800052c8 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005280:	8556                	mv	a0,s5
    80005282:	fffff097          	auipc	ra,0xfffff
    80005286:	cca080e7          	jalr	-822(ra) # 80003f4c <iunlockput>
    end_op();
    8000528a:	fffff097          	auipc	ra,0xfffff
    8000528e:	4aa080e7          	jalr	1194(ra) # 80004734 <end_op>
  }
  return -1;
    80005292:	557d                	li	a0,-1
}
    80005294:	21813083          	ld	ra,536(sp)
    80005298:	21013403          	ld	s0,528(sp)
    8000529c:	20813483          	ld	s1,520(sp)
    800052a0:	20013903          	ld	s2,512(sp)
    800052a4:	79fe                	ld	s3,504(sp)
    800052a6:	7a5e                	ld	s4,496(sp)
    800052a8:	7abe                	ld	s5,488(sp)
    800052aa:	7b1e                	ld	s6,480(sp)
    800052ac:	6bfe                	ld	s7,472(sp)
    800052ae:	6c5e                	ld	s8,464(sp)
    800052b0:	6cbe                	ld	s9,456(sp)
    800052b2:	6d1e                	ld	s10,448(sp)
    800052b4:	7dfa                	ld	s11,440(sp)
    800052b6:	22010113          	addi	sp,sp,544
    800052ba:	8082                	ret
    end_op();
    800052bc:	fffff097          	auipc	ra,0xfffff
    800052c0:	478080e7          	jalr	1144(ra) # 80004734 <end_op>
    return -1;
    800052c4:	557d                	li	a0,-1
    800052c6:	b7f9                	j	80005294 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    800052c8:	8526                	mv	a0,s1
    800052ca:	ffffd097          	auipc	ra,0xffffd
    800052ce:	9f2080e7          	jalr	-1550(ra) # 80001cbc <proc_pagetable>
    800052d2:	8b2a                	mv	s6,a0
    800052d4:	d555                	beqz	a0,80005280 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800052d6:	e7042783          	lw	a5,-400(s0)
    800052da:	e8845703          	lhu	a4,-376(s0)
    800052de:	c735                	beqz	a4,8000534a <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800052e0:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800052e2:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    800052e6:	6a05                	lui	s4,0x1
    800052e8:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    800052ec:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    800052f0:	6d85                	lui	s11,0x1
    800052f2:	7d7d                	lui	s10,0xfffff
    800052f4:	ac3d                	j	80005532 <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800052f6:	00003517          	auipc	a0,0x3
    800052fa:	57250513          	addi	a0,a0,1394 # 80008868 <syscalls+0x2a8>
    800052fe:	ffffb097          	auipc	ra,0xffffb
    80005302:	242080e7          	jalr	578(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005306:	874a                	mv	a4,s2
    80005308:	009c86bb          	addw	a3,s9,s1
    8000530c:	4581                	li	a1,0
    8000530e:	8556                	mv	a0,s5
    80005310:	fffff097          	auipc	ra,0xfffff
    80005314:	c8e080e7          	jalr	-882(ra) # 80003f9e <readi>
    80005318:	2501                	sext.w	a0,a0
    8000531a:	1aa91963          	bne	s2,a0,800054cc <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    8000531e:	009d84bb          	addw	s1,s11,s1
    80005322:	013d09bb          	addw	s3,s10,s3
    80005326:	1f74f663          	bgeu	s1,s7,80005512 <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    8000532a:	02049593          	slli	a1,s1,0x20
    8000532e:	9181                	srli	a1,a1,0x20
    80005330:	95e2                	add	a1,a1,s8
    80005332:	855a                	mv	a0,s6
    80005334:	ffffc097          	auipc	ra,0xffffc
    80005338:	e5a080e7          	jalr	-422(ra) # 8000118e <walkaddr>
    8000533c:	862a                	mv	a2,a0
    if(pa == 0)
    8000533e:	dd45                	beqz	a0,800052f6 <exec+0xfe>
      n = PGSIZE;
    80005340:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005342:	fd49f2e3          	bgeu	s3,s4,80005306 <exec+0x10e>
      n = sz - i;
    80005346:	894e                	mv	s2,s3
    80005348:	bf7d                	j	80005306 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000534a:	4901                	li	s2,0
  iunlockput(ip);
    8000534c:	8556                	mv	a0,s5
    8000534e:	fffff097          	auipc	ra,0xfffff
    80005352:	bfe080e7          	jalr	-1026(ra) # 80003f4c <iunlockput>
  end_op();
    80005356:	fffff097          	auipc	ra,0xfffff
    8000535a:	3de080e7          	jalr	990(ra) # 80004734 <end_op>
  p = myproc();
    8000535e:	ffffd097          	auipc	ra,0xffffd
    80005362:	89a080e7          	jalr	-1894(ra) # 80001bf8 <myproc>
    80005366:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005368:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    8000536c:	6785                	lui	a5,0x1
    8000536e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80005370:	97ca                	add	a5,a5,s2
    80005372:	777d                	lui	a4,0xfffff
    80005374:	8ff9                	and	a5,a5,a4
    80005376:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000537a:	4691                	li	a3,4
    8000537c:	6609                	lui	a2,0x2
    8000537e:	963e                	add	a2,a2,a5
    80005380:	85be                	mv	a1,a5
    80005382:	855a                	mv	a0,s6
    80005384:	ffffc097          	auipc	ra,0xffffc
    80005388:	1be080e7          	jalr	446(ra) # 80001542 <uvmalloc>
    8000538c:	8c2a                	mv	s8,a0
  ip = 0;
    8000538e:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005390:	12050e63          	beqz	a0,800054cc <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005394:	75f9                	lui	a1,0xffffe
    80005396:	95aa                	add	a1,a1,a0
    80005398:	855a                	mv	a0,s6
    8000539a:	ffffc097          	auipc	ra,0xffffc
    8000539e:	3ee080e7          	jalr	1006(ra) # 80001788 <uvmclear>
  stackbase = sp - PGSIZE;
    800053a2:	7afd                	lui	s5,0xfffff
    800053a4:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800053a6:	df043783          	ld	a5,-528(s0)
    800053aa:	6388                	ld	a0,0(a5)
    800053ac:	c925                	beqz	a0,8000541c <exec+0x224>
    800053ae:	e9040993          	addi	s3,s0,-368
    800053b2:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800053b6:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800053b8:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800053ba:	ffffc097          	auipc	ra,0xffffc
    800053be:	bc6080e7          	jalr	-1082(ra) # 80000f80 <strlen>
    800053c2:	0015079b          	addiw	a5,a0,1
    800053c6:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800053ca:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    800053ce:	13596663          	bltu	s2,s5,800054fa <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800053d2:	df043d83          	ld	s11,-528(s0)
    800053d6:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800053da:	8552                	mv	a0,s4
    800053dc:	ffffc097          	auipc	ra,0xffffc
    800053e0:	ba4080e7          	jalr	-1116(ra) # 80000f80 <strlen>
    800053e4:	0015069b          	addiw	a3,a0,1
    800053e8:	8652                	mv	a2,s4
    800053ea:	85ca                	mv	a1,s2
    800053ec:	855a                	mv	a0,s6
    800053ee:	ffffc097          	auipc	ra,0xffffc
    800053f2:	3cc080e7          	jalr	972(ra) # 800017ba <copyout>
    800053f6:	10054663          	bltz	a0,80005502 <exec+0x30a>
    ustack[argc] = sp;
    800053fa:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800053fe:	0485                	addi	s1,s1,1
    80005400:	008d8793          	addi	a5,s11,8
    80005404:	def43823          	sd	a5,-528(s0)
    80005408:	008db503          	ld	a0,8(s11)
    8000540c:	c911                	beqz	a0,80005420 <exec+0x228>
    if(argc >= MAXARG)
    8000540e:	09a1                	addi	s3,s3,8
    80005410:	fb3c95e3          	bne	s9,s3,800053ba <exec+0x1c2>
  sz = sz1;
    80005414:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005418:	4a81                	li	s5,0
    8000541a:	a84d                	j	800054cc <exec+0x2d4>
  sp = sz;
    8000541c:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000541e:	4481                	li	s1,0
  ustack[argc] = 0;
    80005420:	00349793          	slli	a5,s1,0x3
    80005424:	f9078793          	addi	a5,a5,-112
    80005428:	97a2                	add	a5,a5,s0
    8000542a:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    8000542e:	00148693          	addi	a3,s1,1
    80005432:	068e                	slli	a3,a3,0x3
    80005434:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005438:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000543c:	01597663          	bgeu	s2,s5,80005448 <exec+0x250>
  sz = sz1;
    80005440:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005444:	4a81                	li	s5,0
    80005446:	a059                	j	800054cc <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005448:	e9040613          	addi	a2,s0,-368
    8000544c:	85ca                	mv	a1,s2
    8000544e:	855a                	mv	a0,s6
    80005450:	ffffc097          	auipc	ra,0xffffc
    80005454:	36a080e7          	jalr	874(ra) # 800017ba <copyout>
    80005458:	0a054963          	bltz	a0,8000550a <exec+0x312>
  p->trapframe->a1 = sp;
    8000545c:	058bb783          	ld	a5,88(s7)
    80005460:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005464:	de843783          	ld	a5,-536(s0)
    80005468:	0007c703          	lbu	a4,0(a5)
    8000546c:	cf11                	beqz	a4,80005488 <exec+0x290>
    8000546e:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005470:	02f00693          	li	a3,47
    80005474:	a039                	j	80005482 <exec+0x28a>
      last = s+1;
    80005476:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    8000547a:	0785                	addi	a5,a5,1
    8000547c:	fff7c703          	lbu	a4,-1(a5)
    80005480:	c701                	beqz	a4,80005488 <exec+0x290>
    if(*s == '/')
    80005482:	fed71ce3          	bne	a4,a3,8000547a <exec+0x282>
    80005486:	bfc5                	j	80005476 <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    80005488:	4641                	li	a2,16
    8000548a:	de843583          	ld	a1,-536(s0)
    8000548e:	158b8513          	addi	a0,s7,344
    80005492:	ffffc097          	auipc	ra,0xffffc
    80005496:	abc080e7          	jalr	-1348(ra) # 80000f4e <safestrcpy>
  oldpagetable = p->pagetable;
    8000549a:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    8000549e:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    800054a2:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800054a6:	058bb783          	ld	a5,88(s7)
    800054aa:	e6843703          	ld	a4,-408(s0)
    800054ae:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800054b0:	058bb783          	ld	a5,88(s7)
    800054b4:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800054b8:	85ea                	mv	a1,s10
    800054ba:	ffffd097          	auipc	ra,0xffffd
    800054be:	89e080e7          	jalr	-1890(ra) # 80001d58 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800054c2:	0004851b          	sext.w	a0,s1
    800054c6:	b3f9                	j	80005294 <exec+0x9c>
    800054c8:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    800054cc:	df843583          	ld	a1,-520(s0)
    800054d0:	855a                	mv	a0,s6
    800054d2:	ffffd097          	auipc	ra,0xffffd
    800054d6:	886080e7          	jalr	-1914(ra) # 80001d58 <proc_freepagetable>
  if(ip){
    800054da:	da0a93e3          	bnez	s5,80005280 <exec+0x88>
  return -1;
    800054de:	557d                	li	a0,-1
    800054e0:	bb55                	j	80005294 <exec+0x9c>
    800054e2:	df243c23          	sd	s2,-520(s0)
    800054e6:	b7dd                	j	800054cc <exec+0x2d4>
    800054e8:	df243c23          	sd	s2,-520(s0)
    800054ec:	b7c5                	j	800054cc <exec+0x2d4>
    800054ee:	df243c23          	sd	s2,-520(s0)
    800054f2:	bfe9                	j	800054cc <exec+0x2d4>
    800054f4:	df243c23          	sd	s2,-520(s0)
    800054f8:	bfd1                	j	800054cc <exec+0x2d4>
  sz = sz1;
    800054fa:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800054fe:	4a81                	li	s5,0
    80005500:	b7f1                	j	800054cc <exec+0x2d4>
  sz = sz1;
    80005502:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005506:	4a81                	li	s5,0
    80005508:	b7d1                	j	800054cc <exec+0x2d4>
  sz = sz1;
    8000550a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000550e:	4a81                	li	s5,0
    80005510:	bf75                	j	800054cc <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005512:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005516:	e0843783          	ld	a5,-504(s0)
    8000551a:	0017869b          	addiw	a3,a5,1
    8000551e:	e0d43423          	sd	a3,-504(s0)
    80005522:	e0043783          	ld	a5,-512(s0)
    80005526:	0387879b          	addiw	a5,a5,56
    8000552a:	e8845703          	lhu	a4,-376(s0)
    8000552e:	e0e6dfe3          	bge	a3,a4,8000534c <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005532:	2781                	sext.w	a5,a5
    80005534:	e0f43023          	sd	a5,-512(s0)
    80005538:	03800713          	li	a4,56
    8000553c:	86be                	mv	a3,a5
    8000553e:	e1840613          	addi	a2,s0,-488
    80005542:	4581                	li	a1,0
    80005544:	8556                	mv	a0,s5
    80005546:	fffff097          	auipc	ra,0xfffff
    8000554a:	a58080e7          	jalr	-1448(ra) # 80003f9e <readi>
    8000554e:	03800793          	li	a5,56
    80005552:	f6f51be3          	bne	a0,a5,800054c8 <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    80005556:	e1842783          	lw	a5,-488(s0)
    8000555a:	4705                	li	a4,1
    8000555c:	fae79de3          	bne	a5,a4,80005516 <exec+0x31e>
    if(ph.memsz < ph.filesz)
    80005560:	e4043483          	ld	s1,-448(s0)
    80005564:	e3843783          	ld	a5,-456(s0)
    80005568:	f6f4ede3          	bltu	s1,a5,800054e2 <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000556c:	e2843783          	ld	a5,-472(s0)
    80005570:	94be                	add	s1,s1,a5
    80005572:	f6f4ebe3          	bltu	s1,a5,800054e8 <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    80005576:	de043703          	ld	a4,-544(s0)
    8000557a:	8ff9                	and	a5,a5,a4
    8000557c:	fbad                	bnez	a5,800054ee <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000557e:	e1c42503          	lw	a0,-484(s0)
    80005582:	00000097          	auipc	ra,0x0
    80005586:	c5c080e7          	jalr	-932(ra) # 800051de <flags2perm>
    8000558a:	86aa                	mv	a3,a0
    8000558c:	8626                	mv	a2,s1
    8000558e:	85ca                	mv	a1,s2
    80005590:	855a                	mv	a0,s6
    80005592:	ffffc097          	auipc	ra,0xffffc
    80005596:	fb0080e7          	jalr	-80(ra) # 80001542 <uvmalloc>
    8000559a:	dea43c23          	sd	a0,-520(s0)
    8000559e:	d939                	beqz	a0,800054f4 <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800055a0:	e2843c03          	ld	s8,-472(s0)
    800055a4:	e2042c83          	lw	s9,-480(s0)
    800055a8:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800055ac:	f60b83e3          	beqz	s7,80005512 <exec+0x31a>
    800055b0:	89de                	mv	s3,s7
    800055b2:	4481                	li	s1,0
    800055b4:	bb9d                	j	8000532a <exec+0x132>

00000000800055b6 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800055b6:	7179                	addi	sp,sp,-48
    800055b8:	f406                	sd	ra,40(sp)
    800055ba:	f022                	sd	s0,32(sp)
    800055bc:	ec26                	sd	s1,24(sp)
    800055be:	e84a                	sd	s2,16(sp)
    800055c0:	1800                	addi	s0,sp,48
    800055c2:	892e                	mv	s2,a1
    800055c4:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800055c6:	fdc40593          	addi	a1,s0,-36
    800055ca:	ffffe097          	auipc	ra,0xffffe
    800055ce:	a8c080e7          	jalr	-1396(ra) # 80003056 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800055d2:	fdc42703          	lw	a4,-36(s0)
    800055d6:	47bd                	li	a5,15
    800055d8:	02e7eb63          	bltu	a5,a4,8000560e <argfd+0x58>
    800055dc:	ffffc097          	auipc	ra,0xffffc
    800055e0:	61c080e7          	jalr	1564(ra) # 80001bf8 <myproc>
    800055e4:	fdc42703          	lw	a4,-36(s0)
    800055e8:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7fb9d0da>
    800055ec:	078e                	slli	a5,a5,0x3
    800055ee:	953e                	add	a0,a0,a5
    800055f0:	611c                	ld	a5,0(a0)
    800055f2:	c385                	beqz	a5,80005612 <argfd+0x5c>
    return -1;
  if(pfd)
    800055f4:	00090463          	beqz	s2,800055fc <argfd+0x46>
    *pfd = fd;
    800055f8:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800055fc:	4501                	li	a0,0
  if(pf)
    800055fe:	c091                	beqz	s1,80005602 <argfd+0x4c>
    *pf = f;
    80005600:	e09c                	sd	a5,0(s1)
}
    80005602:	70a2                	ld	ra,40(sp)
    80005604:	7402                	ld	s0,32(sp)
    80005606:	64e2                	ld	s1,24(sp)
    80005608:	6942                	ld	s2,16(sp)
    8000560a:	6145                	addi	sp,sp,48
    8000560c:	8082                	ret
    return -1;
    8000560e:	557d                	li	a0,-1
    80005610:	bfcd                	j	80005602 <argfd+0x4c>
    80005612:	557d                	li	a0,-1
    80005614:	b7fd                	j	80005602 <argfd+0x4c>

0000000080005616 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005616:	1101                	addi	sp,sp,-32
    80005618:	ec06                	sd	ra,24(sp)
    8000561a:	e822                	sd	s0,16(sp)
    8000561c:	e426                	sd	s1,8(sp)
    8000561e:	1000                	addi	s0,sp,32
    80005620:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005622:	ffffc097          	auipc	ra,0xffffc
    80005626:	5d6080e7          	jalr	1494(ra) # 80001bf8 <myproc>
    8000562a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000562c:	0d050793          	addi	a5,a0,208
    80005630:	4501                	li	a0,0
    80005632:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005634:	6398                	ld	a4,0(a5)
    80005636:	cb19                	beqz	a4,8000564c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005638:	2505                	addiw	a0,a0,1
    8000563a:	07a1                	addi	a5,a5,8
    8000563c:	fed51ce3          	bne	a0,a3,80005634 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005640:	557d                	li	a0,-1
}
    80005642:	60e2                	ld	ra,24(sp)
    80005644:	6442                	ld	s0,16(sp)
    80005646:	64a2                	ld	s1,8(sp)
    80005648:	6105                	addi	sp,sp,32
    8000564a:	8082                	ret
      p->ofile[fd] = f;
    8000564c:	01a50793          	addi	a5,a0,26
    80005650:	078e                	slli	a5,a5,0x3
    80005652:	963e                	add	a2,a2,a5
    80005654:	e204                	sd	s1,0(a2)
      return fd;
    80005656:	b7f5                	j	80005642 <fdalloc+0x2c>

0000000080005658 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005658:	715d                	addi	sp,sp,-80
    8000565a:	e486                	sd	ra,72(sp)
    8000565c:	e0a2                	sd	s0,64(sp)
    8000565e:	fc26                	sd	s1,56(sp)
    80005660:	f84a                	sd	s2,48(sp)
    80005662:	f44e                	sd	s3,40(sp)
    80005664:	f052                	sd	s4,32(sp)
    80005666:	ec56                	sd	s5,24(sp)
    80005668:	e85a                	sd	s6,16(sp)
    8000566a:	0880                	addi	s0,sp,80
    8000566c:	8b2e                	mv	s6,a1
    8000566e:	89b2                	mv	s3,a2
    80005670:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005672:	fb040593          	addi	a1,s0,-80
    80005676:	fffff097          	auipc	ra,0xfffff
    8000567a:	e3e080e7          	jalr	-450(ra) # 800044b4 <nameiparent>
    8000567e:	84aa                	mv	s1,a0
    80005680:	14050f63          	beqz	a0,800057de <create+0x186>
    return 0;

  ilock(dp);
    80005684:	ffffe097          	auipc	ra,0xffffe
    80005688:	666080e7          	jalr	1638(ra) # 80003cea <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000568c:	4601                	li	a2,0
    8000568e:	fb040593          	addi	a1,s0,-80
    80005692:	8526                	mv	a0,s1
    80005694:	fffff097          	auipc	ra,0xfffff
    80005698:	b3a080e7          	jalr	-1222(ra) # 800041ce <dirlookup>
    8000569c:	8aaa                	mv	s5,a0
    8000569e:	c931                	beqz	a0,800056f2 <create+0x9a>
    iunlockput(dp);
    800056a0:	8526                	mv	a0,s1
    800056a2:	fffff097          	auipc	ra,0xfffff
    800056a6:	8aa080e7          	jalr	-1878(ra) # 80003f4c <iunlockput>
    ilock(ip);
    800056aa:	8556                	mv	a0,s5
    800056ac:	ffffe097          	auipc	ra,0xffffe
    800056b0:	63e080e7          	jalr	1598(ra) # 80003cea <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800056b4:	000b059b          	sext.w	a1,s6
    800056b8:	4789                	li	a5,2
    800056ba:	02f59563          	bne	a1,a5,800056e4 <create+0x8c>
    800056be:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7fb9d104>
    800056c2:	37f9                	addiw	a5,a5,-2
    800056c4:	17c2                	slli	a5,a5,0x30
    800056c6:	93c1                	srli	a5,a5,0x30
    800056c8:	4705                	li	a4,1
    800056ca:	00f76d63          	bltu	a4,a5,800056e4 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800056ce:	8556                	mv	a0,s5
    800056d0:	60a6                	ld	ra,72(sp)
    800056d2:	6406                	ld	s0,64(sp)
    800056d4:	74e2                	ld	s1,56(sp)
    800056d6:	7942                	ld	s2,48(sp)
    800056d8:	79a2                	ld	s3,40(sp)
    800056da:	7a02                	ld	s4,32(sp)
    800056dc:	6ae2                	ld	s5,24(sp)
    800056de:	6b42                	ld	s6,16(sp)
    800056e0:	6161                	addi	sp,sp,80
    800056e2:	8082                	ret
    iunlockput(ip);
    800056e4:	8556                	mv	a0,s5
    800056e6:	fffff097          	auipc	ra,0xfffff
    800056ea:	866080e7          	jalr	-1946(ra) # 80003f4c <iunlockput>
    return 0;
    800056ee:	4a81                	li	s5,0
    800056f0:	bff9                	j	800056ce <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800056f2:	85da                	mv	a1,s6
    800056f4:	4088                	lw	a0,0(s1)
    800056f6:	ffffe097          	auipc	ra,0xffffe
    800056fa:	456080e7          	jalr	1110(ra) # 80003b4c <ialloc>
    800056fe:	8a2a                	mv	s4,a0
    80005700:	c539                	beqz	a0,8000574e <create+0xf6>
  ilock(ip);
    80005702:	ffffe097          	auipc	ra,0xffffe
    80005706:	5e8080e7          	jalr	1512(ra) # 80003cea <ilock>
  ip->major = major;
    8000570a:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    8000570e:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005712:	4905                	li	s2,1
    80005714:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005718:	8552                	mv	a0,s4
    8000571a:	ffffe097          	auipc	ra,0xffffe
    8000571e:	504080e7          	jalr	1284(ra) # 80003c1e <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005722:	000b059b          	sext.w	a1,s6
    80005726:	03258b63          	beq	a1,s2,8000575c <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    8000572a:	004a2603          	lw	a2,4(s4)
    8000572e:	fb040593          	addi	a1,s0,-80
    80005732:	8526                	mv	a0,s1
    80005734:	fffff097          	auipc	ra,0xfffff
    80005738:	cb0080e7          	jalr	-848(ra) # 800043e4 <dirlink>
    8000573c:	06054f63          	bltz	a0,800057ba <create+0x162>
  iunlockput(dp);
    80005740:	8526                	mv	a0,s1
    80005742:	fffff097          	auipc	ra,0xfffff
    80005746:	80a080e7          	jalr	-2038(ra) # 80003f4c <iunlockput>
  return ip;
    8000574a:	8ad2                	mv	s5,s4
    8000574c:	b749                	j	800056ce <create+0x76>
    iunlockput(dp);
    8000574e:	8526                	mv	a0,s1
    80005750:	ffffe097          	auipc	ra,0xffffe
    80005754:	7fc080e7          	jalr	2044(ra) # 80003f4c <iunlockput>
    return 0;
    80005758:	8ad2                	mv	s5,s4
    8000575a:	bf95                	j	800056ce <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000575c:	004a2603          	lw	a2,4(s4)
    80005760:	00003597          	auipc	a1,0x3
    80005764:	12858593          	addi	a1,a1,296 # 80008888 <syscalls+0x2c8>
    80005768:	8552                	mv	a0,s4
    8000576a:	fffff097          	auipc	ra,0xfffff
    8000576e:	c7a080e7          	jalr	-902(ra) # 800043e4 <dirlink>
    80005772:	04054463          	bltz	a0,800057ba <create+0x162>
    80005776:	40d0                	lw	a2,4(s1)
    80005778:	00003597          	auipc	a1,0x3
    8000577c:	11858593          	addi	a1,a1,280 # 80008890 <syscalls+0x2d0>
    80005780:	8552                	mv	a0,s4
    80005782:	fffff097          	auipc	ra,0xfffff
    80005786:	c62080e7          	jalr	-926(ra) # 800043e4 <dirlink>
    8000578a:	02054863          	bltz	a0,800057ba <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    8000578e:	004a2603          	lw	a2,4(s4)
    80005792:	fb040593          	addi	a1,s0,-80
    80005796:	8526                	mv	a0,s1
    80005798:	fffff097          	auipc	ra,0xfffff
    8000579c:	c4c080e7          	jalr	-948(ra) # 800043e4 <dirlink>
    800057a0:	00054d63          	bltz	a0,800057ba <create+0x162>
    dp->nlink++;  // for ".."
    800057a4:	04a4d783          	lhu	a5,74(s1)
    800057a8:	2785                	addiw	a5,a5,1
    800057aa:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800057ae:	8526                	mv	a0,s1
    800057b0:	ffffe097          	auipc	ra,0xffffe
    800057b4:	46e080e7          	jalr	1134(ra) # 80003c1e <iupdate>
    800057b8:	b761                	j	80005740 <create+0xe8>
  ip->nlink = 0;
    800057ba:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800057be:	8552                	mv	a0,s4
    800057c0:	ffffe097          	auipc	ra,0xffffe
    800057c4:	45e080e7          	jalr	1118(ra) # 80003c1e <iupdate>
  iunlockput(ip);
    800057c8:	8552                	mv	a0,s4
    800057ca:	ffffe097          	auipc	ra,0xffffe
    800057ce:	782080e7          	jalr	1922(ra) # 80003f4c <iunlockput>
  iunlockput(dp);
    800057d2:	8526                	mv	a0,s1
    800057d4:	ffffe097          	auipc	ra,0xffffe
    800057d8:	778080e7          	jalr	1912(ra) # 80003f4c <iunlockput>
  return 0;
    800057dc:	bdcd                	j	800056ce <create+0x76>
    return 0;
    800057de:	8aaa                	mv	s5,a0
    800057e0:	b5fd                	j	800056ce <create+0x76>

00000000800057e2 <sys_dup>:
{
    800057e2:	7179                	addi	sp,sp,-48
    800057e4:	f406                	sd	ra,40(sp)
    800057e6:	f022                	sd	s0,32(sp)
    800057e8:	ec26                	sd	s1,24(sp)
    800057ea:	e84a                	sd	s2,16(sp)
    800057ec:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800057ee:	fd840613          	addi	a2,s0,-40
    800057f2:	4581                	li	a1,0
    800057f4:	4501                	li	a0,0
    800057f6:	00000097          	auipc	ra,0x0
    800057fa:	dc0080e7          	jalr	-576(ra) # 800055b6 <argfd>
    return -1;
    800057fe:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005800:	02054363          	bltz	a0,80005826 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005804:	fd843903          	ld	s2,-40(s0)
    80005808:	854a                	mv	a0,s2
    8000580a:	00000097          	auipc	ra,0x0
    8000580e:	e0c080e7          	jalr	-500(ra) # 80005616 <fdalloc>
    80005812:	84aa                	mv	s1,a0
    return -1;
    80005814:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005816:	00054863          	bltz	a0,80005826 <sys_dup+0x44>
  filedup(f);
    8000581a:	854a                	mv	a0,s2
    8000581c:	fffff097          	auipc	ra,0xfffff
    80005820:	310080e7          	jalr	784(ra) # 80004b2c <filedup>
  return fd;
    80005824:	87a6                	mv	a5,s1
}
    80005826:	853e                	mv	a0,a5
    80005828:	70a2                	ld	ra,40(sp)
    8000582a:	7402                	ld	s0,32(sp)
    8000582c:	64e2                	ld	s1,24(sp)
    8000582e:	6942                	ld	s2,16(sp)
    80005830:	6145                	addi	sp,sp,48
    80005832:	8082                	ret

0000000080005834 <sys_read>:
{
    80005834:	7179                	addi	sp,sp,-48
    80005836:	f406                	sd	ra,40(sp)
    80005838:	f022                	sd	s0,32(sp)
    8000583a:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000583c:	fd840593          	addi	a1,s0,-40
    80005840:	4505                	li	a0,1
    80005842:	ffffe097          	auipc	ra,0xffffe
    80005846:	834080e7          	jalr	-1996(ra) # 80003076 <argaddr>
  argint(2, &n);
    8000584a:	fe440593          	addi	a1,s0,-28
    8000584e:	4509                	li	a0,2
    80005850:	ffffe097          	auipc	ra,0xffffe
    80005854:	806080e7          	jalr	-2042(ra) # 80003056 <argint>
  if(argfd(0, 0, &f) < 0)
    80005858:	fe840613          	addi	a2,s0,-24
    8000585c:	4581                	li	a1,0
    8000585e:	4501                	li	a0,0
    80005860:	00000097          	auipc	ra,0x0
    80005864:	d56080e7          	jalr	-682(ra) # 800055b6 <argfd>
    80005868:	87aa                	mv	a5,a0
    return -1;
    8000586a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000586c:	0007cc63          	bltz	a5,80005884 <sys_read+0x50>
  return fileread(f, p, n);
    80005870:	fe442603          	lw	a2,-28(s0)
    80005874:	fd843583          	ld	a1,-40(s0)
    80005878:	fe843503          	ld	a0,-24(s0)
    8000587c:	fffff097          	auipc	ra,0xfffff
    80005880:	43c080e7          	jalr	1084(ra) # 80004cb8 <fileread>
}
    80005884:	70a2                	ld	ra,40(sp)
    80005886:	7402                	ld	s0,32(sp)
    80005888:	6145                	addi	sp,sp,48
    8000588a:	8082                	ret

000000008000588c <sys_write>:
{
    8000588c:	7179                	addi	sp,sp,-48
    8000588e:	f406                	sd	ra,40(sp)
    80005890:	f022                	sd	s0,32(sp)
    80005892:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005894:	fd840593          	addi	a1,s0,-40
    80005898:	4505                	li	a0,1
    8000589a:	ffffd097          	auipc	ra,0xffffd
    8000589e:	7dc080e7          	jalr	2012(ra) # 80003076 <argaddr>
  argint(2, &n);
    800058a2:	fe440593          	addi	a1,s0,-28
    800058a6:	4509                	li	a0,2
    800058a8:	ffffd097          	auipc	ra,0xffffd
    800058ac:	7ae080e7          	jalr	1966(ra) # 80003056 <argint>
  if(argfd(0, 0, &f) < 0)
    800058b0:	fe840613          	addi	a2,s0,-24
    800058b4:	4581                	li	a1,0
    800058b6:	4501                	li	a0,0
    800058b8:	00000097          	auipc	ra,0x0
    800058bc:	cfe080e7          	jalr	-770(ra) # 800055b6 <argfd>
    800058c0:	87aa                	mv	a5,a0
    return -1;
    800058c2:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800058c4:	0007cc63          	bltz	a5,800058dc <sys_write+0x50>
  return filewrite(f, p, n);
    800058c8:	fe442603          	lw	a2,-28(s0)
    800058cc:	fd843583          	ld	a1,-40(s0)
    800058d0:	fe843503          	ld	a0,-24(s0)
    800058d4:	fffff097          	auipc	ra,0xfffff
    800058d8:	4a6080e7          	jalr	1190(ra) # 80004d7a <filewrite>
}
    800058dc:	70a2                	ld	ra,40(sp)
    800058de:	7402                	ld	s0,32(sp)
    800058e0:	6145                	addi	sp,sp,48
    800058e2:	8082                	ret

00000000800058e4 <sys_close>:
{
    800058e4:	1101                	addi	sp,sp,-32
    800058e6:	ec06                	sd	ra,24(sp)
    800058e8:	e822                	sd	s0,16(sp)
    800058ea:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800058ec:	fe040613          	addi	a2,s0,-32
    800058f0:	fec40593          	addi	a1,s0,-20
    800058f4:	4501                	li	a0,0
    800058f6:	00000097          	auipc	ra,0x0
    800058fa:	cc0080e7          	jalr	-832(ra) # 800055b6 <argfd>
    return -1;
    800058fe:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005900:	02054463          	bltz	a0,80005928 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005904:	ffffc097          	auipc	ra,0xffffc
    80005908:	2f4080e7          	jalr	756(ra) # 80001bf8 <myproc>
    8000590c:	fec42783          	lw	a5,-20(s0)
    80005910:	07e9                	addi	a5,a5,26
    80005912:	078e                	slli	a5,a5,0x3
    80005914:	953e                	add	a0,a0,a5
    80005916:	00053023          	sd	zero,0(a0)
  fileclose(f);
    8000591a:	fe043503          	ld	a0,-32(s0)
    8000591e:	fffff097          	auipc	ra,0xfffff
    80005922:	260080e7          	jalr	608(ra) # 80004b7e <fileclose>
  return 0;
    80005926:	4781                	li	a5,0
}
    80005928:	853e                	mv	a0,a5
    8000592a:	60e2                	ld	ra,24(sp)
    8000592c:	6442                	ld	s0,16(sp)
    8000592e:	6105                	addi	sp,sp,32
    80005930:	8082                	ret

0000000080005932 <sys_fstat>:
{
    80005932:	1101                	addi	sp,sp,-32
    80005934:	ec06                	sd	ra,24(sp)
    80005936:	e822                	sd	s0,16(sp)
    80005938:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    8000593a:	fe040593          	addi	a1,s0,-32
    8000593e:	4505                	li	a0,1
    80005940:	ffffd097          	auipc	ra,0xffffd
    80005944:	736080e7          	jalr	1846(ra) # 80003076 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005948:	fe840613          	addi	a2,s0,-24
    8000594c:	4581                	li	a1,0
    8000594e:	4501                	li	a0,0
    80005950:	00000097          	auipc	ra,0x0
    80005954:	c66080e7          	jalr	-922(ra) # 800055b6 <argfd>
    80005958:	87aa                	mv	a5,a0
    return -1;
    8000595a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000595c:	0007ca63          	bltz	a5,80005970 <sys_fstat+0x3e>
  return filestat(f, st);
    80005960:	fe043583          	ld	a1,-32(s0)
    80005964:	fe843503          	ld	a0,-24(s0)
    80005968:	fffff097          	auipc	ra,0xfffff
    8000596c:	2de080e7          	jalr	734(ra) # 80004c46 <filestat>
}
    80005970:	60e2                	ld	ra,24(sp)
    80005972:	6442                	ld	s0,16(sp)
    80005974:	6105                	addi	sp,sp,32
    80005976:	8082                	ret

0000000080005978 <sys_link>:
{
    80005978:	7169                	addi	sp,sp,-304
    8000597a:	f606                	sd	ra,296(sp)
    8000597c:	f222                	sd	s0,288(sp)
    8000597e:	ee26                	sd	s1,280(sp)
    80005980:	ea4a                	sd	s2,272(sp)
    80005982:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005984:	08000613          	li	a2,128
    80005988:	ed040593          	addi	a1,s0,-304
    8000598c:	4501                	li	a0,0
    8000598e:	ffffd097          	auipc	ra,0xffffd
    80005992:	708080e7          	jalr	1800(ra) # 80003096 <argstr>
    return -1;
    80005996:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005998:	10054e63          	bltz	a0,80005ab4 <sys_link+0x13c>
    8000599c:	08000613          	li	a2,128
    800059a0:	f5040593          	addi	a1,s0,-176
    800059a4:	4505                	li	a0,1
    800059a6:	ffffd097          	auipc	ra,0xffffd
    800059aa:	6f0080e7          	jalr	1776(ra) # 80003096 <argstr>
    return -1;
    800059ae:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800059b0:	10054263          	bltz	a0,80005ab4 <sys_link+0x13c>
  begin_op();
    800059b4:	fffff097          	auipc	ra,0xfffff
    800059b8:	d02080e7          	jalr	-766(ra) # 800046b6 <begin_op>
  if((ip = namei(old)) == 0){
    800059bc:	ed040513          	addi	a0,s0,-304
    800059c0:	fffff097          	auipc	ra,0xfffff
    800059c4:	ad6080e7          	jalr	-1322(ra) # 80004496 <namei>
    800059c8:	84aa                	mv	s1,a0
    800059ca:	c551                	beqz	a0,80005a56 <sys_link+0xde>
  ilock(ip);
    800059cc:	ffffe097          	auipc	ra,0xffffe
    800059d0:	31e080e7          	jalr	798(ra) # 80003cea <ilock>
  if(ip->type == T_DIR){
    800059d4:	04449703          	lh	a4,68(s1)
    800059d8:	4785                	li	a5,1
    800059da:	08f70463          	beq	a4,a5,80005a62 <sys_link+0xea>
  ip->nlink++;
    800059de:	04a4d783          	lhu	a5,74(s1)
    800059e2:	2785                	addiw	a5,a5,1
    800059e4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800059e8:	8526                	mv	a0,s1
    800059ea:	ffffe097          	auipc	ra,0xffffe
    800059ee:	234080e7          	jalr	564(ra) # 80003c1e <iupdate>
  iunlock(ip);
    800059f2:	8526                	mv	a0,s1
    800059f4:	ffffe097          	auipc	ra,0xffffe
    800059f8:	3b8080e7          	jalr	952(ra) # 80003dac <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800059fc:	fd040593          	addi	a1,s0,-48
    80005a00:	f5040513          	addi	a0,s0,-176
    80005a04:	fffff097          	auipc	ra,0xfffff
    80005a08:	ab0080e7          	jalr	-1360(ra) # 800044b4 <nameiparent>
    80005a0c:	892a                	mv	s2,a0
    80005a0e:	c935                	beqz	a0,80005a82 <sys_link+0x10a>
  ilock(dp);
    80005a10:	ffffe097          	auipc	ra,0xffffe
    80005a14:	2da080e7          	jalr	730(ra) # 80003cea <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005a18:	00092703          	lw	a4,0(s2)
    80005a1c:	409c                	lw	a5,0(s1)
    80005a1e:	04f71d63          	bne	a4,a5,80005a78 <sys_link+0x100>
    80005a22:	40d0                	lw	a2,4(s1)
    80005a24:	fd040593          	addi	a1,s0,-48
    80005a28:	854a                	mv	a0,s2
    80005a2a:	fffff097          	auipc	ra,0xfffff
    80005a2e:	9ba080e7          	jalr	-1606(ra) # 800043e4 <dirlink>
    80005a32:	04054363          	bltz	a0,80005a78 <sys_link+0x100>
  iunlockput(dp);
    80005a36:	854a                	mv	a0,s2
    80005a38:	ffffe097          	auipc	ra,0xffffe
    80005a3c:	514080e7          	jalr	1300(ra) # 80003f4c <iunlockput>
  iput(ip);
    80005a40:	8526                	mv	a0,s1
    80005a42:	ffffe097          	auipc	ra,0xffffe
    80005a46:	462080e7          	jalr	1122(ra) # 80003ea4 <iput>
  end_op();
    80005a4a:	fffff097          	auipc	ra,0xfffff
    80005a4e:	cea080e7          	jalr	-790(ra) # 80004734 <end_op>
  return 0;
    80005a52:	4781                	li	a5,0
    80005a54:	a085                	j	80005ab4 <sys_link+0x13c>
    end_op();
    80005a56:	fffff097          	auipc	ra,0xfffff
    80005a5a:	cde080e7          	jalr	-802(ra) # 80004734 <end_op>
    return -1;
    80005a5e:	57fd                	li	a5,-1
    80005a60:	a891                	j	80005ab4 <sys_link+0x13c>
    iunlockput(ip);
    80005a62:	8526                	mv	a0,s1
    80005a64:	ffffe097          	auipc	ra,0xffffe
    80005a68:	4e8080e7          	jalr	1256(ra) # 80003f4c <iunlockput>
    end_op();
    80005a6c:	fffff097          	auipc	ra,0xfffff
    80005a70:	cc8080e7          	jalr	-824(ra) # 80004734 <end_op>
    return -1;
    80005a74:	57fd                	li	a5,-1
    80005a76:	a83d                	j	80005ab4 <sys_link+0x13c>
    iunlockput(dp);
    80005a78:	854a                	mv	a0,s2
    80005a7a:	ffffe097          	auipc	ra,0xffffe
    80005a7e:	4d2080e7          	jalr	1234(ra) # 80003f4c <iunlockput>
  ilock(ip);
    80005a82:	8526                	mv	a0,s1
    80005a84:	ffffe097          	auipc	ra,0xffffe
    80005a88:	266080e7          	jalr	614(ra) # 80003cea <ilock>
  ip->nlink--;
    80005a8c:	04a4d783          	lhu	a5,74(s1)
    80005a90:	37fd                	addiw	a5,a5,-1
    80005a92:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a96:	8526                	mv	a0,s1
    80005a98:	ffffe097          	auipc	ra,0xffffe
    80005a9c:	186080e7          	jalr	390(ra) # 80003c1e <iupdate>
  iunlockput(ip);
    80005aa0:	8526                	mv	a0,s1
    80005aa2:	ffffe097          	auipc	ra,0xffffe
    80005aa6:	4aa080e7          	jalr	1194(ra) # 80003f4c <iunlockput>
  end_op();
    80005aaa:	fffff097          	auipc	ra,0xfffff
    80005aae:	c8a080e7          	jalr	-886(ra) # 80004734 <end_op>
  return -1;
    80005ab2:	57fd                	li	a5,-1
}
    80005ab4:	853e                	mv	a0,a5
    80005ab6:	70b2                	ld	ra,296(sp)
    80005ab8:	7412                	ld	s0,288(sp)
    80005aba:	64f2                	ld	s1,280(sp)
    80005abc:	6952                	ld	s2,272(sp)
    80005abe:	6155                	addi	sp,sp,304
    80005ac0:	8082                	ret

0000000080005ac2 <sys_unlink>:
{
    80005ac2:	7151                	addi	sp,sp,-240
    80005ac4:	f586                	sd	ra,232(sp)
    80005ac6:	f1a2                	sd	s0,224(sp)
    80005ac8:	eda6                	sd	s1,216(sp)
    80005aca:	e9ca                	sd	s2,208(sp)
    80005acc:	e5ce                	sd	s3,200(sp)
    80005ace:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005ad0:	08000613          	li	a2,128
    80005ad4:	f3040593          	addi	a1,s0,-208
    80005ad8:	4501                	li	a0,0
    80005ada:	ffffd097          	auipc	ra,0xffffd
    80005ade:	5bc080e7          	jalr	1468(ra) # 80003096 <argstr>
    80005ae2:	18054163          	bltz	a0,80005c64 <sys_unlink+0x1a2>
  begin_op();
    80005ae6:	fffff097          	auipc	ra,0xfffff
    80005aea:	bd0080e7          	jalr	-1072(ra) # 800046b6 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005aee:	fb040593          	addi	a1,s0,-80
    80005af2:	f3040513          	addi	a0,s0,-208
    80005af6:	fffff097          	auipc	ra,0xfffff
    80005afa:	9be080e7          	jalr	-1602(ra) # 800044b4 <nameiparent>
    80005afe:	84aa                	mv	s1,a0
    80005b00:	c979                	beqz	a0,80005bd6 <sys_unlink+0x114>
  ilock(dp);
    80005b02:	ffffe097          	auipc	ra,0xffffe
    80005b06:	1e8080e7          	jalr	488(ra) # 80003cea <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005b0a:	00003597          	auipc	a1,0x3
    80005b0e:	d7e58593          	addi	a1,a1,-642 # 80008888 <syscalls+0x2c8>
    80005b12:	fb040513          	addi	a0,s0,-80
    80005b16:	ffffe097          	auipc	ra,0xffffe
    80005b1a:	69e080e7          	jalr	1694(ra) # 800041b4 <namecmp>
    80005b1e:	14050a63          	beqz	a0,80005c72 <sys_unlink+0x1b0>
    80005b22:	00003597          	auipc	a1,0x3
    80005b26:	d6e58593          	addi	a1,a1,-658 # 80008890 <syscalls+0x2d0>
    80005b2a:	fb040513          	addi	a0,s0,-80
    80005b2e:	ffffe097          	auipc	ra,0xffffe
    80005b32:	686080e7          	jalr	1670(ra) # 800041b4 <namecmp>
    80005b36:	12050e63          	beqz	a0,80005c72 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005b3a:	f2c40613          	addi	a2,s0,-212
    80005b3e:	fb040593          	addi	a1,s0,-80
    80005b42:	8526                	mv	a0,s1
    80005b44:	ffffe097          	auipc	ra,0xffffe
    80005b48:	68a080e7          	jalr	1674(ra) # 800041ce <dirlookup>
    80005b4c:	892a                	mv	s2,a0
    80005b4e:	12050263          	beqz	a0,80005c72 <sys_unlink+0x1b0>
  ilock(ip);
    80005b52:	ffffe097          	auipc	ra,0xffffe
    80005b56:	198080e7          	jalr	408(ra) # 80003cea <ilock>
  if(ip->nlink < 1)
    80005b5a:	04a91783          	lh	a5,74(s2)
    80005b5e:	08f05263          	blez	a5,80005be2 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005b62:	04491703          	lh	a4,68(s2)
    80005b66:	4785                	li	a5,1
    80005b68:	08f70563          	beq	a4,a5,80005bf2 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005b6c:	4641                	li	a2,16
    80005b6e:	4581                	li	a1,0
    80005b70:	fc040513          	addi	a0,s0,-64
    80005b74:	ffffb097          	auipc	ra,0xffffb
    80005b78:	290080e7          	jalr	656(ra) # 80000e04 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b7c:	4741                	li	a4,16
    80005b7e:	f2c42683          	lw	a3,-212(s0)
    80005b82:	fc040613          	addi	a2,s0,-64
    80005b86:	4581                	li	a1,0
    80005b88:	8526                	mv	a0,s1
    80005b8a:	ffffe097          	auipc	ra,0xffffe
    80005b8e:	50c080e7          	jalr	1292(ra) # 80004096 <writei>
    80005b92:	47c1                	li	a5,16
    80005b94:	0af51563          	bne	a0,a5,80005c3e <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005b98:	04491703          	lh	a4,68(s2)
    80005b9c:	4785                	li	a5,1
    80005b9e:	0af70863          	beq	a4,a5,80005c4e <sys_unlink+0x18c>
  iunlockput(dp);
    80005ba2:	8526                	mv	a0,s1
    80005ba4:	ffffe097          	auipc	ra,0xffffe
    80005ba8:	3a8080e7          	jalr	936(ra) # 80003f4c <iunlockput>
  ip->nlink--;
    80005bac:	04a95783          	lhu	a5,74(s2)
    80005bb0:	37fd                	addiw	a5,a5,-1
    80005bb2:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005bb6:	854a                	mv	a0,s2
    80005bb8:	ffffe097          	auipc	ra,0xffffe
    80005bbc:	066080e7          	jalr	102(ra) # 80003c1e <iupdate>
  iunlockput(ip);
    80005bc0:	854a                	mv	a0,s2
    80005bc2:	ffffe097          	auipc	ra,0xffffe
    80005bc6:	38a080e7          	jalr	906(ra) # 80003f4c <iunlockput>
  end_op();
    80005bca:	fffff097          	auipc	ra,0xfffff
    80005bce:	b6a080e7          	jalr	-1174(ra) # 80004734 <end_op>
  return 0;
    80005bd2:	4501                	li	a0,0
    80005bd4:	a84d                	j	80005c86 <sys_unlink+0x1c4>
    end_op();
    80005bd6:	fffff097          	auipc	ra,0xfffff
    80005bda:	b5e080e7          	jalr	-1186(ra) # 80004734 <end_op>
    return -1;
    80005bde:	557d                	li	a0,-1
    80005be0:	a05d                	j	80005c86 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005be2:	00003517          	auipc	a0,0x3
    80005be6:	cb650513          	addi	a0,a0,-842 # 80008898 <syscalls+0x2d8>
    80005bea:	ffffb097          	auipc	ra,0xffffb
    80005bee:	956080e7          	jalr	-1706(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005bf2:	04c92703          	lw	a4,76(s2)
    80005bf6:	02000793          	li	a5,32
    80005bfa:	f6e7f9e3          	bgeu	a5,a4,80005b6c <sys_unlink+0xaa>
    80005bfe:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c02:	4741                	li	a4,16
    80005c04:	86ce                	mv	a3,s3
    80005c06:	f1840613          	addi	a2,s0,-232
    80005c0a:	4581                	li	a1,0
    80005c0c:	854a                	mv	a0,s2
    80005c0e:	ffffe097          	auipc	ra,0xffffe
    80005c12:	390080e7          	jalr	912(ra) # 80003f9e <readi>
    80005c16:	47c1                	li	a5,16
    80005c18:	00f51b63          	bne	a0,a5,80005c2e <sys_unlink+0x16c>
    if(de.inum != 0)
    80005c1c:	f1845783          	lhu	a5,-232(s0)
    80005c20:	e7a1                	bnez	a5,80005c68 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005c22:	29c1                	addiw	s3,s3,16
    80005c24:	04c92783          	lw	a5,76(s2)
    80005c28:	fcf9ede3          	bltu	s3,a5,80005c02 <sys_unlink+0x140>
    80005c2c:	b781                	j	80005b6c <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005c2e:	00003517          	auipc	a0,0x3
    80005c32:	c8250513          	addi	a0,a0,-894 # 800088b0 <syscalls+0x2f0>
    80005c36:	ffffb097          	auipc	ra,0xffffb
    80005c3a:	90a080e7          	jalr	-1782(ra) # 80000540 <panic>
    panic("unlink: writei");
    80005c3e:	00003517          	auipc	a0,0x3
    80005c42:	c8a50513          	addi	a0,a0,-886 # 800088c8 <syscalls+0x308>
    80005c46:	ffffb097          	auipc	ra,0xffffb
    80005c4a:	8fa080e7          	jalr	-1798(ra) # 80000540 <panic>
    dp->nlink--;
    80005c4e:	04a4d783          	lhu	a5,74(s1)
    80005c52:	37fd                	addiw	a5,a5,-1
    80005c54:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005c58:	8526                	mv	a0,s1
    80005c5a:	ffffe097          	auipc	ra,0xffffe
    80005c5e:	fc4080e7          	jalr	-60(ra) # 80003c1e <iupdate>
    80005c62:	b781                	j	80005ba2 <sys_unlink+0xe0>
    return -1;
    80005c64:	557d                	li	a0,-1
    80005c66:	a005                	j	80005c86 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005c68:	854a                	mv	a0,s2
    80005c6a:	ffffe097          	auipc	ra,0xffffe
    80005c6e:	2e2080e7          	jalr	738(ra) # 80003f4c <iunlockput>
  iunlockput(dp);
    80005c72:	8526                	mv	a0,s1
    80005c74:	ffffe097          	auipc	ra,0xffffe
    80005c78:	2d8080e7          	jalr	728(ra) # 80003f4c <iunlockput>
  end_op();
    80005c7c:	fffff097          	auipc	ra,0xfffff
    80005c80:	ab8080e7          	jalr	-1352(ra) # 80004734 <end_op>
  return -1;
    80005c84:	557d                	li	a0,-1
}
    80005c86:	70ae                	ld	ra,232(sp)
    80005c88:	740e                	ld	s0,224(sp)
    80005c8a:	64ee                	ld	s1,216(sp)
    80005c8c:	694e                	ld	s2,208(sp)
    80005c8e:	69ae                	ld	s3,200(sp)
    80005c90:	616d                	addi	sp,sp,240
    80005c92:	8082                	ret

0000000080005c94 <sys_open>:

uint64
sys_open(void)
{
    80005c94:	7131                	addi	sp,sp,-192
    80005c96:	fd06                	sd	ra,184(sp)
    80005c98:	f922                	sd	s0,176(sp)
    80005c9a:	f526                	sd	s1,168(sp)
    80005c9c:	f14a                	sd	s2,160(sp)
    80005c9e:	ed4e                	sd	s3,152(sp)
    80005ca0:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005ca2:	f4c40593          	addi	a1,s0,-180
    80005ca6:	4505                	li	a0,1
    80005ca8:	ffffd097          	auipc	ra,0xffffd
    80005cac:	3ae080e7          	jalr	942(ra) # 80003056 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005cb0:	08000613          	li	a2,128
    80005cb4:	f5040593          	addi	a1,s0,-176
    80005cb8:	4501                	li	a0,0
    80005cba:	ffffd097          	auipc	ra,0xffffd
    80005cbe:	3dc080e7          	jalr	988(ra) # 80003096 <argstr>
    80005cc2:	87aa                	mv	a5,a0
    return -1;
    80005cc4:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005cc6:	0a07c963          	bltz	a5,80005d78 <sys_open+0xe4>

  begin_op();
    80005cca:	fffff097          	auipc	ra,0xfffff
    80005cce:	9ec080e7          	jalr	-1556(ra) # 800046b6 <begin_op>

  if(omode & O_CREATE){
    80005cd2:	f4c42783          	lw	a5,-180(s0)
    80005cd6:	2007f793          	andi	a5,a5,512
    80005cda:	cfc5                	beqz	a5,80005d92 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005cdc:	4681                	li	a3,0
    80005cde:	4601                	li	a2,0
    80005ce0:	4589                	li	a1,2
    80005ce2:	f5040513          	addi	a0,s0,-176
    80005ce6:	00000097          	auipc	ra,0x0
    80005cea:	972080e7          	jalr	-1678(ra) # 80005658 <create>
    80005cee:	84aa                	mv	s1,a0
    if(ip == 0){
    80005cf0:	c959                	beqz	a0,80005d86 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005cf2:	04449703          	lh	a4,68(s1)
    80005cf6:	478d                	li	a5,3
    80005cf8:	00f71763          	bne	a4,a5,80005d06 <sys_open+0x72>
    80005cfc:	0464d703          	lhu	a4,70(s1)
    80005d00:	47a5                	li	a5,9
    80005d02:	0ce7ed63          	bltu	a5,a4,80005ddc <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005d06:	fffff097          	auipc	ra,0xfffff
    80005d0a:	dbc080e7          	jalr	-580(ra) # 80004ac2 <filealloc>
    80005d0e:	89aa                	mv	s3,a0
    80005d10:	10050363          	beqz	a0,80005e16 <sys_open+0x182>
    80005d14:	00000097          	auipc	ra,0x0
    80005d18:	902080e7          	jalr	-1790(ra) # 80005616 <fdalloc>
    80005d1c:	892a                	mv	s2,a0
    80005d1e:	0e054763          	bltz	a0,80005e0c <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005d22:	04449703          	lh	a4,68(s1)
    80005d26:	478d                	li	a5,3
    80005d28:	0cf70563          	beq	a4,a5,80005df2 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005d2c:	4789                	li	a5,2
    80005d2e:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005d32:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005d36:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005d3a:	f4c42783          	lw	a5,-180(s0)
    80005d3e:	0017c713          	xori	a4,a5,1
    80005d42:	8b05                	andi	a4,a4,1
    80005d44:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005d48:	0037f713          	andi	a4,a5,3
    80005d4c:	00e03733          	snez	a4,a4
    80005d50:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005d54:	4007f793          	andi	a5,a5,1024
    80005d58:	c791                	beqz	a5,80005d64 <sys_open+0xd0>
    80005d5a:	04449703          	lh	a4,68(s1)
    80005d5e:	4789                	li	a5,2
    80005d60:	0af70063          	beq	a4,a5,80005e00 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005d64:	8526                	mv	a0,s1
    80005d66:	ffffe097          	auipc	ra,0xffffe
    80005d6a:	046080e7          	jalr	70(ra) # 80003dac <iunlock>
  end_op();
    80005d6e:	fffff097          	auipc	ra,0xfffff
    80005d72:	9c6080e7          	jalr	-1594(ra) # 80004734 <end_op>

  return fd;
    80005d76:	854a                	mv	a0,s2
}
    80005d78:	70ea                	ld	ra,184(sp)
    80005d7a:	744a                	ld	s0,176(sp)
    80005d7c:	74aa                	ld	s1,168(sp)
    80005d7e:	790a                	ld	s2,160(sp)
    80005d80:	69ea                	ld	s3,152(sp)
    80005d82:	6129                	addi	sp,sp,192
    80005d84:	8082                	ret
      end_op();
    80005d86:	fffff097          	auipc	ra,0xfffff
    80005d8a:	9ae080e7          	jalr	-1618(ra) # 80004734 <end_op>
      return -1;
    80005d8e:	557d                	li	a0,-1
    80005d90:	b7e5                	j	80005d78 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005d92:	f5040513          	addi	a0,s0,-176
    80005d96:	ffffe097          	auipc	ra,0xffffe
    80005d9a:	700080e7          	jalr	1792(ra) # 80004496 <namei>
    80005d9e:	84aa                	mv	s1,a0
    80005da0:	c905                	beqz	a0,80005dd0 <sys_open+0x13c>
    ilock(ip);
    80005da2:	ffffe097          	auipc	ra,0xffffe
    80005da6:	f48080e7          	jalr	-184(ra) # 80003cea <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005daa:	04449703          	lh	a4,68(s1)
    80005dae:	4785                	li	a5,1
    80005db0:	f4f711e3          	bne	a4,a5,80005cf2 <sys_open+0x5e>
    80005db4:	f4c42783          	lw	a5,-180(s0)
    80005db8:	d7b9                	beqz	a5,80005d06 <sys_open+0x72>
      iunlockput(ip);
    80005dba:	8526                	mv	a0,s1
    80005dbc:	ffffe097          	auipc	ra,0xffffe
    80005dc0:	190080e7          	jalr	400(ra) # 80003f4c <iunlockput>
      end_op();
    80005dc4:	fffff097          	auipc	ra,0xfffff
    80005dc8:	970080e7          	jalr	-1680(ra) # 80004734 <end_op>
      return -1;
    80005dcc:	557d                	li	a0,-1
    80005dce:	b76d                	j	80005d78 <sys_open+0xe4>
      end_op();
    80005dd0:	fffff097          	auipc	ra,0xfffff
    80005dd4:	964080e7          	jalr	-1692(ra) # 80004734 <end_op>
      return -1;
    80005dd8:	557d                	li	a0,-1
    80005dda:	bf79                	j	80005d78 <sys_open+0xe4>
    iunlockput(ip);
    80005ddc:	8526                	mv	a0,s1
    80005dde:	ffffe097          	auipc	ra,0xffffe
    80005de2:	16e080e7          	jalr	366(ra) # 80003f4c <iunlockput>
    end_op();
    80005de6:	fffff097          	auipc	ra,0xfffff
    80005dea:	94e080e7          	jalr	-1714(ra) # 80004734 <end_op>
    return -1;
    80005dee:	557d                	li	a0,-1
    80005df0:	b761                	j	80005d78 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005df2:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005df6:	04649783          	lh	a5,70(s1)
    80005dfa:	02f99223          	sh	a5,36(s3)
    80005dfe:	bf25                	j	80005d36 <sys_open+0xa2>
    itrunc(ip);
    80005e00:	8526                	mv	a0,s1
    80005e02:	ffffe097          	auipc	ra,0xffffe
    80005e06:	ff6080e7          	jalr	-10(ra) # 80003df8 <itrunc>
    80005e0a:	bfa9                	j	80005d64 <sys_open+0xd0>
      fileclose(f);
    80005e0c:	854e                	mv	a0,s3
    80005e0e:	fffff097          	auipc	ra,0xfffff
    80005e12:	d70080e7          	jalr	-656(ra) # 80004b7e <fileclose>
    iunlockput(ip);
    80005e16:	8526                	mv	a0,s1
    80005e18:	ffffe097          	auipc	ra,0xffffe
    80005e1c:	134080e7          	jalr	308(ra) # 80003f4c <iunlockput>
    end_op();
    80005e20:	fffff097          	auipc	ra,0xfffff
    80005e24:	914080e7          	jalr	-1772(ra) # 80004734 <end_op>
    return -1;
    80005e28:	557d                	li	a0,-1
    80005e2a:	b7b9                	j	80005d78 <sys_open+0xe4>

0000000080005e2c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005e2c:	7175                	addi	sp,sp,-144
    80005e2e:	e506                	sd	ra,136(sp)
    80005e30:	e122                	sd	s0,128(sp)
    80005e32:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005e34:	fffff097          	auipc	ra,0xfffff
    80005e38:	882080e7          	jalr	-1918(ra) # 800046b6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005e3c:	08000613          	li	a2,128
    80005e40:	f7040593          	addi	a1,s0,-144
    80005e44:	4501                	li	a0,0
    80005e46:	ffffd097          	auipc	ra,0xffffd
    80005e4a:	250080e7          	jalr	592(ra) # 80003096 <argstr>
    80005e4e:	02054963          	bltz	a0,80005e80 <sys_mkdir+0x54>
    80005e52:	4681                	li	a3,0
    80005e54:	4601                	li	a2,0
    80005e56:	4585                	li	a1,1
    80005e58:	f7040513          	addi	a0,s0,-144
    80005e5c:	fffff097          	auipc	ra,0xfffff
    80005e60:	7fc080e7          	jalr	2044(ra) # 80005658 <create>
    80005e64:	cd11                	beqz	a0,80005e80 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e66:	ffffe097          	auipc	ra,0xffffe
    80005e6a:	0e6080e7          	jalr	230(ra) # 80003f4c <iunlockput>
  end_op();
    80005e6e:	fffff097          	auipc	ra,0xfffff
    80005e72:	8c6080e7          	jalr	-1850(ra) # 80004734 <end_op>
  return 0;
    80005e76:	4501                	li	a0,0
}
    80005e78:	60aa                	ld	ra,136(sp)
    80005e7a:	640a                	ld	s0,128(sp)
    80005e7c:	6149                	addi	sp,sp,144
    80005e7e:	8082                	ret
    end_op();
    80005e80:	fffff097          	auipc	ra,0xfffff
    80005e84:	8b4080e7          	jalr	-1868(ra) # 80004734 <end_op>
    return -1;
    80005e88:	557d                	li	a0,-1
    80005e8a:	b7fd                	j	80005e78 <sys_mkdir+0x4c>

0000000080005e8c <sys_mknod>:

uint64
sys_mknod(void)
{
    80005e8c:	7135                	addi	sp,sp,-160
    80005e8e:	ed06                	sd	ra,152(sp)
    80005e90:	e922                	sd	s0,144(sp)
    80005e92:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005e94:	fffff097          	auipc	ra,0xfffff
    80005e98:	822080e7          	jalr	-2014(ra) # 800046b6 <begin_op>
  argint(1, &major);
    80005e9c:	f6c40593          	addi	a1,s0,-148
    80005ea0:	4505                	li	a0,1
    80005ea2:	ffffd097          	auipc	ra,0xffffd
    80005ea6:	1b4080e7          	jalr	436(ra) # 80003056 <argint>
  argint(2, &minor);
    80005eaa:	f6840593          	addi	a1,s0,-152
    80005eae:	4509                	li	a0,2
    80005eb0:	ffffd097          	auipc	ra,0xffffd
    80005eb4:	1a6080e7          	jalr	422(ra) # 80003056 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005eb8:	08000613          	li	a2,128
    80005ebc:	f7040593          	addi	a1,s0,-144
    80005ec0:	4501                	li	a0,0
    80005ec2:	ffffd097          	auipc	ra,0xffffd
    80005ec6:	1d4080e7          	jalr	468(ra) # 80003096 <argstr>
    80005eca:	02054b63          	bltz	a0,80005f00 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005ece:	f6841683          	lh	a3,-152(s0)
    80005ed2:	f6c41603          	lh	a2,-148(s0)
    80005ed6:	458d                	li	a1,3
    80005ed8:	f7040513          	addi	a0,s0,-144
    80005edc:	fffff097          	auipc	ra,0xfffff
    80005ee0:	77c080e7          	jalr	1916(ra) # 80005658 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ee4:	cd11                	beqz	a0,80005f00 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ee6:	ffffe097          	auipc	ra,0xffffe
    80005eea:	066080e7          	jalr	102(ra) # 80003f4c <iunlockput>
  end_op();
    80005eee:	fffff097          	auipc	ra,0xfffff
    80005ef2:	846080e7          	jalr	-1978(ra) # 80004734 <end_op>
  return 0;
    80005ef6:	4501                	li	a0,0
}
    80005ef8:	60ea                	ld	ra,152(sp)
    80005efa:	644a                	ld	s0,144(sp)
    80005efc:	610d                	addi	sp,sp,160
    80005efe:	8082                	ret
    end_op();
    80005f00:	fffff097          	auipc	ra,0xfffff
    80005f04:	834080e7          	jalr	-1996(ra) # 80004734 <end_op>
    return -1;
    80005f08:	557d                	li	a0,-1
    80005f0a:	b7fd                	j	80005ef8 <sys_mknod+0x6c>

0000000080005f0c <sys_chdir>:

uint64
sys_chdir(void)
{
    80005f0c:	7135                	addi	sp,sp,-160
    80005f0e:	ed06                	sd	ra,152(sp)
    80005f10:	e922                	sd	s0,144(sp)
    80005f12:	e526                	sd	s1,136(sp)
    80005f14:	e14a                	sd	s2,128(sp)
    80005f16:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005f18:	ffffc097          	auipc	ra,0xffffc
    80005f1c:	ce0080e7          	jalr	-800(ra) # 80001bf8 <myproc>
    80005f20:	892a                	mv	s2,a0
  
  begin_op();
    80005f22:	ffffe097          	auipc	ra,0xffffe
    80005f26:	794080e7          	jalr	1940(ra) # 800046b6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005f2a:	08000613          	li	a2,128
    80005f2e:	f6040593          	addi	a1,s0,-160
    80005f32:	4501                	li	a0,0
    80005f34:	ffffd097          	auipc	ra,0xffffd
    80005f38:	162080e7          	jalr	354(ra) # 80003096 <argstr>
    80005f3c:	04054b63          	bltz	a0,80005f92 <sys_chdir+0x86>
    80005f40:	f6040513          	addi	a0,s0,-160
    80005f44:	ffffe097          	auipc	ra,0xffffe
    80005f48:	552080e7          	jalr	1362(ra) # 80004496 <namei>
    80005f4c:	84aa                	mv	s1,a0
    80005f4e:	c131                	beqz	a0,80005f92 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005f50:	ffffe097          	auipc	ra,0xffffe
    80005f54:	d9a080e7          	jalr	-614(ra) # 80003cea <ilock>
  if(ip->type != T_DIR){
    80005f58:	04449703          	lh	a4,68(s1)
    80005f5c:	4785                	li	a5,1
    80005f5e:	04f71063          	bne	a4,a5,80005f9e <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005f62:	8526                	mv	a0,s1
    80005f64:	ffffe097          	auipc	ra,0xffffe
    80005f68:	e48080e7          	jalr	-440(ra) # 80003dac <iunlock>
  iput(p->cwd);
    80005f6c:	15093503          	ld	a0,336(s2)
    80005f70:	ffffe097          	auipc	ra,0xffffe
    80005f74:	f34080e7          	jalr	-204(ra) # 80003ea4 <iput>
  end_op();
    80005f78:	ffffe097          	auipc	ra,0xffffe
    80005f7c:	7bc080e7          	jalr	1980(ra) # 80004734 <end_op>
  p->cwd = ip;
    80005f80:	14993823          	sd	s1,336(s2)
  return 0;
    80005f84:	4501                	li	a0,0
}
    80005f86:	60ea                	ld	ra,152(sp)
    80005f88:	644a                	ld	s0,144(sp)
    80005f8a:	64aa                	ld	s1,136(sp)
    80005f8c:	690a                	ld	s2,128(sp)
    80005f8e:	610d                	addi	sp,sp,160
    80005f90:	8082                	ret
    end_op();
    80005f92:	ffffe097          	auipc	ra,0xffffe
    80005f96:	7a2080e7          	jalr	1954(ra) # 80004734 <end_op>
    return -1;
    80005f9a:	557d                	li	a0,-1
    80005f9c:	b7ed                	j	80005f86 <sys_chdir+0x7a>
    iunlockput(ip);
    80005f9e:	8526                	mv	a0,s1
    80005fa0:	ffffe097          	auipc	ra,0xffffe
    80005fa4:	fac080e7          	jalr	-84(ra) # 80003f4c <iunlockput>
    end_op();
    80005fa8:	ffffe097          	auipc	ra,0xffffe
    80005fac:	78c080e7          	jalr	1932(ra) # 80004734 <end_op>
    return -1;
    80005fb0:	557d                	li	a0,-1
    80005fb2:	bfd1                	j	80005f86 <sys_chdir+0x7a>

0000000080005fb4 <sys_exec>:

uint64
sys_exec(void)
{
    80005fb4:	7145                	addi	sp,sp,-464
    80005fb6:	e786                	sd	ra,456(sp)
    80005fb8:	e3a2                	sd	s0,448(sp)
    80005fba:	ff26                	sd	s1,440(sp)
    80005fbc:	fb4a                	sd	s2,432(sp)
    80005fbe:	f74e                	sd	s3,424(sp)
    80005fc0:	f352                	sd	s4,416(sp)
    80005fc2:	ef56                	sd	s5,408(sp)
    80005fc4:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005fc6:	e3840593          	addi	a1,s0,-456
    80005fca:	4505                	li	a0,1
    80005fcc:	ffffd097          	auipc	ra,0xffffd
    80005fd0:	0aa080e7          	jalr	170(ra) # 80003076 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005fd4:	08000613          	li	a2,128
    80005fd8:	f4040593          	addi	a1,s0,-192
    80005fdc:	4501                	li	a0,0
    80005fde:	ffffd097          	auipc	ra,0xffffd
    80005fe2:	0b8080e7          	jalr	184(ra) # 80003096 <argstr>
    80005fe6:	87aa                	mv	a5,a0
    return -1;
    80005fe8:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005fea:	0c07c363          	bltz	a5,800060b0 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005fee:	10000613          	li	a2,256
    80005ff2:	4581                	li	a1,0
    80005ff4:	e4040513          	addi	a0,s0,-448
    80005ff8:	ffffb097          	auipc	ra,0xffffb
    80005ffc:	e0c080e7          	jalr	-500(ra) # 80000e04 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006000:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006004:	89a6                	mv	s3,s1
    80006006:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006008:	02000a13          	li	s4,32
    8000600c:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006010:	00391513          	slli	a0,s2,0x3
    80006014:	e3040593          	addi	a1,s0,-464
    80006018:	e3843783          	ld	a5,-456(s0)
    8000601c:	953e                	add	a0,a0,a5
    8000601e:	ffffd097          	auipc	ra,0xffffd
    80006022:	f9a080e7          	jalr	-102(ra) # 80002fb8 <fetchaddr>
    80006026:	02054a63          	bltz	a0,8000605a <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    8000602a:	e3043783          	ld	a5,-464(s0)
    8000602e:	c3b9                	beqz	a5,80006074 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006030:	ffffb097          	auipc	ra,0xffffb
    80006034:	b9c080e7          	jalr	-1124(ra) # 80000bcc <kalloc>
    80006038:	85aa                	mv	a1,a0
    8000603a:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000603e:	cd11                	beqz	a0,8000605a <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006040:	6605                	lui	a2,0x1
    80006042:	e3043503          	ld	a0,-464(s0)
    80006046:	ffffd097          	auipc	ra,0xffffd
    8000604a:	fc4080e7          	jalr	-60(ra) # 8000300a <fetchstr>
    8000604e:	00054663          	bltz	a0,8000605a <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80006052:	0905                	addi	s2,s2,1
    80006054:	09a1                	addi	s3,s3,8
    80006056:	fb491be3          	bne	s2,s4,8000600c <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000605a:	f4040913          	addi	s2,s0,-192
    8000605e:	6088                	ld	a0,0(s1)
    80006060:	c539                	beqz	a0,800060ae <sys_exec+0xfa>
    kfree(argv[i]);
    80006062:	ffffb097          	auipc	ra,0xffffb
    80006066:	9d8080e7          	jalr	-1576(ra) # 80000a3a <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000606a:	04a1                	addi	s1,s1,8
    8000606c:	ff2499e3          	bne	s1,s2,8000605e <sys_exec+0xaa>
  return -1;
    80006070:	557d                	li	a0,-1
    80006072:	a83d                	j	800060b0 <sys_exec+0xfc>
      argv[i] = 0;
    80006074:	0a8e                	slli	s5,s5,0x3
    80006076:	fc0a8793          	addi	a5,s5,-64
    8000607a:	00878ab3          	add	s5,a5,s0
    8000607e:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006082:	e4040593          	addi	a1,s0,-448
    80006086:	f4040513          	addi	a0,s0,-192
    8000608a:	fffff097          	auipc	ra,0xfffff
    8000608e:	16e080e7          	jalr	366(ra) # 800051f8 <exec>
    80006092:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006094:	f4040993          	addi	s3,s0,-192
    80006098:	6088                	ld	a0,0(s1)
    8000609a:	c901                	beqz	a0,800060aa <sys_exec+0xf6>
    kfree(argv[i]);
    8000609c:	ffffb097          	auipc	ra,0xffffb
    800060a0:	99e080e7          	jalr	-1634(ra) # 80000a3a <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060a4:	04a1                	addi	s1,s1,8
    800060a6:	ff3499e3          	bne	s1,s3,80006098 <sys_exec+0xe4>
  return ret;
    800060aa:	854a                	mv	a0,s2
    800060ac:	a011                	j	800060b0 <sys_exec+0xfc>
  return -1;
    800060ae:	557d                	li	a0,-1
}
    800060b0:	60be                	ld	ra,456(sp)
    800060b2:	641e                	ld	s0,448(sp)
    800060b4:	74fa                	ld	s1,440(sp)
    800060b6:	795a                	ld	s2,432(sp)
    800060b8:	79ba                	ld	s3,424(sp)
    800060ba:	7a1a                	ld	s4,416(sp)
    800060bc:	6afa                	ld	s5,408(sp)
    800060be:	6179                	addi	sp,sp,464
    800060c0:	8082                	ret

00000000800060c2 <sys_pipe>:

uint64
sys_pipe(void)
{
    800060c2:	7139                	addi	sp,sp,-64
    800060c4:	fc06                	sd	ra,56(sp)
    800060c6:	f822                	sd	s0,48(sp)
    800060c8:	f426                	sd	s1,40(sp)
    800060ca:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800060cc:	ffffc097          	auipc	ra,0xffffc
    800060d0:	b2c080e7          	jalr	-1236(ra) # 80001bf8 <myproc>
    800060d4:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    800060d6:	fd840593          	addi	a1,s0,-40
    800060da:	4501                	li	a0,0
    800060dc:	ffffd097          	auipc	ra,0xffffd
    800060e0:	f9a080e7          	jalr	-102(ra) # 80003076 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    800060e4:	fc840593          	addi	a1,s0,-56
    800060e8:	fd040513          	addi	a0,s0,-48
    800060ec:	fffff097          	auipc	ra,0xfffff
    800060f0:	dc2080e7          	jalr	-574(ra) # 80004eae <pipealloc>
    return -1;
    800060f4:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800060f6:	0c054463          	bltz	a0,800061be <sys_pipe+0xfc>
  fd0 = -1;
    800060fa:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800060fe:	fd043503          	ld	a0,-48(s0)
    80006102:	fffff097          	auipc	ra,0xfffff
    80006106:	514080e7          	jalr	1300(ra) # 80005616 <fdalloc>
    8000610a:	fca42223          	sw	a0,-60(s0)
    8000610e:	08054b63          	bltz	a0,800061a4 <sys_pipe+0xe2>
    80006112:	fc843503          	ld	a0,-56(s0)
    80006116:	fffff097          	auipc	ra,0xfffff
    8000611a:	500080e7          	jalr	1280(ra) # 80005616 <fdalloc>
    8000611e:	fca42023          	sw	a0,-64(s0)
    80006122:	06054863          	bltz	a0,80006192 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006126:	4691                	li	a3,4
    80006128:	fc440613          	addi	a2,s0,-60
    8000612c:	fd843583          	ld	a1,-40(s0)
    80006130:	68a8                	ld	a0,80(s1)
    80006132:	ffffb097          	auipc	ra,0xffffb
    80006136:	688080e7          	jalr	1672(ra) # 800017ba <copyout>
    8000613a:	02054063          	bltz	a0,8000615a <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000613e:	4691                	li	a3,4
    80006140:	fc040613          	addi	a2,s0,-64
    80006144:	fd843583          	ld	a1,-40(s0)
    80006148:	0591                	addi	a1,a1,4
    8000614a:	68a8                	ld	a0,80(s1)
    8000614c:	ffffb097          	auipc	ra,0xffffb
    80006150:	66e080e7          	jalr	1646(ra) # 800017ba <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006154:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006156:	06055463          	bgez	a0,800061be <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    8000615a:	fc442783          	lw	a5,-60(s0)
    8000615e:	07e9                	addi	a5,a5,26
    80006160:	078e                	slli	a5,a5,0x3
    80006162:	97a6                	add	a5,a5,s1
    80006164:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006168:	fc042783          	lw	a5,-64(s0)
    8000616c:	07e9                	addi	a5,a5,26
    8000616e:	078e                	slli	a5,a5,0x3
    80006170:	94be                	add	s1,s1,a5
    80006172:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006176:	fd043503          	ld	a0,-48(s0)
    8000617a:	fffff097          	auipc	ra,0xfffff
    8000617e:	a04080e7          	jalr	-1532(ra) # 80004b7e <fileclose>
    fileclose(wf);
    80006182:	fc843503          	ld	a0,-56(s0)
    80006186:	fffff097          	auipc	ra,0xfffff
    8000618a:	9f8080e7          	jalr	-1544(ra) # 80004b7e <fileclose>
    return -1;
    8000618e:	57fd                	li	a5,-1
    80006190:	a03d                	j	800061be <sys_pipe+0xfc>
    if(fd0 >= 0)
    80006192:	fc442783          	lw	a5,-60(s0)
    80006196:	0007c763          	bltz	a5,800061a4 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    8000619a:	07e9                	addi	a5,a5,26
    8000619c:	078e                	slli	a5,a5,0x3
    8000619e:	97a6                	add	a5,a5,s1
    800061a0:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    800061a4:	fd043503          	ld	a0,-48(s0)
    800061a8:	fffff097          	auipc	ra,0xfffff
    800061ac:	9d6080e7          	jalr	-1578(ra) # 80004b7e <fileclose>
    fileclose(wf);
    800061b0:	fc843503          	ld	a0,-56(s0)
    800061b4:	fffff097          	auipc	ra,0xfffff
    800061b8:	9ca080e7          	jalr	-1590(ra) # 80004b7e <fileclose>
    return -1;
    800061bc:	57fd                	li	a5,-1
}
    800061be:	853e                	mv	a0,a5
    800061c0:	70e2                	ld	ra,56(sp)
    800061c2:	7442                	ld	s0,48(sp)
    800061c4:	74a2                	ld	s1,40(sp)
    800061c6:	6121                	addi	sp,sp,64
    800061c8:	8082                	ret
    800061ca:	0000                	unimp
    800061cc:	0000                	unimp
	...

00000000800061d0 <kernelvec>:
    800061d0:	7111                	addi	sp,sp,-256
    800061d2:	e006                	sd	ra,0(sp)
    800061d4:	e40a                	sd	sp,8(sp)
    800061d6:	e80e                	sd	gp,16(sp)
    800061d8:	ec12                	sd	tp,24(sp)
    800061da:	f016                	sd	t0,32(sp)
    800061dc:	f41a                	sd	t1,40(sp)
    800061de:	f81e                	sd	t2,48(sp)
    800061e0:	fc22                	sd	s0,56(sp)
    800061e2:	e0a6                	sd	s1,64(sp)
    800061e4:	e4aa                	sd	a0,72(sp)
    800061e6:	e8ae                	sd	a1,80(sp)
    800061e8:	ecb2                	sd	a2,88(sp)
    800061ea:	f0b6                	sd	a3,96(sp)
    800061ec:	f4ba                	sd	a4,104(sp)
    800061ee:	f8be                	sd	a5,112(sp)
    800061f0:	fcc2                	sd	a6,120(sp)
    800061f2:	e146                	sd	a7,128(sp)
    800061f4:	e54a                	sd	s2,136(sp)
    800061f6:	e94e                	sd	s3,144(sp)
    800061f8:	ed52                	sd	s4,152(sp)
    800061fa:	f156                	sd	s5,160(sp)
    800061fc:	f55a                	sd	s6,168(sp)
    800061fe:	f95e                	sd	s7,176(sp)
    80006200:	fd62                	sd	s8,184(sp)
    80006202:	e1e6                	sd	s9,192(sp)
    80006204:	e5ea                	sd	s10,200(sp)
    80006206:	e9ee                	sd	s11,208(sp)
    80006208:	edf2                	sd	t3,216(sp)
    8000620a:	f1f6                	sd	t4,224(sp)
    8000620c:	f5fa                	sd	t5,232(sp)
    8000620e:	f9fe                	sd	t6,240(sp)
    80006210:	c65fc0ef          	jal	ra,80002e74 <kerneltrap>
    80006214:	6082                	ld	ra,0(sp)
    80006216:	6122                	ld	sp,8(sp)
    80006218:	61c2                	ld	gp,16(sp)
    8000621a:	7282                	ld	t0,32(sp)
    8000621c:	7322                	ld	t1,40(sp)
    8000621e:	73c2                	ld	t2,48(sp)
    80006220:	7462                	ld	s0,56(sp)
    80006222:	6486                	ld	s1,64(sp)
    80006224:	6526                	ld	a0,72(sp)
    80006226:	65c6                	ld	a1,80(sp)
    80006228:	6666                	ld	a2,88(sp)
    8000622a:	7686                	ld	a3,96(sp)
    8000622c:	7726                	ld	a4,104(sp)
    8000622e:	77c6                	ld	a5,112(sp)
    80006230:	7866                	ld	a6,120(sp)
    80006232:	688a                	ld	a7,128(sp)
    80006234:	692a                	ld	s2,136(sp)
    80006236:	69ca                	ld	s3,144(sp)
    80006238:	6a6a                	ld	s4,152(sp)
    8000623a:	7a8a                	ld	s5,160(sp)
    8000623c:	7b2a                	ld	s6,168(sp)
    8000623e:	7bca                	ld	s7,176(sp)
    80006240:	7c6a                	ld	s8,184(sp)
    80006242:	6c8e                	ld	s9,192(sp)
    80006244:	6d2e                	ld	s10,200(sp)
    80006246:	6dce                	ld	s11,208(sp)
    80006248:	6e6e                	ld	t3,216(sp)
    8000624a:	7e8e                	ld	t4,224(sp)
    8000624c:	7f2e                	ld	t5,232(sp)
    8000624e:	7fce                	ld	t6,240(sp)
    80006250:	6111                	addi	sp,sp,256
    80006252:	10200073          	sret
    80006256:	00000013          	nop
    8000625a:	00000013          	nop
    8000625e:	0001                	nop

0000000080006260 <timervec>:
    80006260:	34051573          	csrrw	a0,mscratch,a0
    80006264:	e10c                	sd	a1,0(a0)
    80006266:	e510                	sd	a2,8(a0)
    80006268:	e914                	sd	a3,16(a0)
    8000626a:	6d0c                	ld	a1,24(a0)
    8000626c:	7110                	ld	a2,32(a0)
    8000626e:	6194                	ld	a3,0(a1)
    80006270:	96b2                	add	a3,a3,a2
    80006272:	e194                	sd	a3,0(a1)
    80006274:	4589                	li	a1,2
    80006276:	14459073          	csrw	sip,a1
    8000627a:	6914                	ld	a3,16(a0)
    8000627c:	6510                	ld	a2,8(a0)
    8000627e:	610c                	ld	a1,0(a0)
    80006280:	34051573          	csrrw	a0,mscratch,a0
    80006284:	30200073          	mret
	...

000000008000628a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000628a:	1141                	addi	sp,sp,-16
    8000628c:	e422                	sd	s0,8(sp)
    8000628e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006290:	0c0007b7          	lui	a5,0xc000
    80006294:	4705                	li	a4,1
    80006296:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006298:	c3d8                	sw	a4,4(a5)
}
    8000629a:	6422                	ld	s0,8(sp)
    8000629c:	0141                	addi	sp,sp,16
    8000629e:	8082                	ret

00000000800062a0 <plicinithart>:

void
plicinithart(void)
{
    800062a0:	1141                	addi	sp,sp,-16
    800062a2:	e406                	sd	ra,8(sp)
    800062a4:	e022                	sd	s0,0(sp)
    800062a6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800062a8:	ffffc097          	auipc	ra,0xffffc
    800062ac:	924080e7          	jalr	-1756(ra) # 80001bcc <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800062b0:	0085171b          	slliw	a4,a0,0x8
    800062b4:	0c0027b7          	lui	a5,0xc002
    800062b8:	97ba                	add	a5,a5,a4
    800062ba:	40200713          	li	a4,1026
    800062be:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800062c2:	00d5151b          	slliw	a0,a0,0xd
    800062c6:	0c2017b7          	lui	a5,0xc201
    800062ca:	97aa                	add	a5,a5,a0
    800062cc:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    800062d0:	60a2                	ld	ra,8(sp)
    800062d2:	6402                	ld	s0,0(sp)
    800062d4:	0141                	addi	sp,sp,16
    800062d6:	8082                	ret

00000000800062d8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800062d8:	1141                	addi	sp,sp,-16
    800062da:	e406                	sd	ra,8(sp)
    800062dc:	e022                	sd	s0,0(sp)
    800062de:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800062e0:	ffffc097          	auipc	ra,0xffffc
    800062e4:	8ec080e7          	jalr	-1812(ra) # 80001bcc <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800062e8:	00d5151b          	slliw	a0,a0,0xd
    800062ec:	0c2017b7          	lui	a5,0xc201
    800062f0:	97aa                	add	a5,a5,a0
  return irq;
}
    800062f2:	43c8                	lw	a0,4(a5)
    800062f4:	60a2                	ld	ra,8(sp)
    800062f6:	6402                	ld	s0,0(sp)
    800062f8:	0141                	addi	sp,sp,16
    800062fa:	8082                	ret

00000000800062fc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800062fc:	1101                	addi	sp,sp,-32
    800062fe:	ec06                	sd	ra,24(sp)
    80006300:	e822                	sd	s0,16(sp)
    80006302:	e426                	sd	s1,8(sp)
    80006304:	1000                	addi	s0,sp,32
    80006306:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006308:	ffffc097          	auipc	ra,0xffffc
    8000630c:	8c4080e7          	jalr	-1852(ra) # 80001bcc <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006310:	00d5151b          	slliw	a0,a0,0xd
    80006314:	0c2017b7          	lui	a5,0xc201
    80006318:	97aa                	add	a5,a5,a0
    8000631a:	c3c4                	sw	s1,4(a5)
}
    8000631c:	60e2                	ld	ra,24(sp)
    8000631e:	6442                	ld	s0,16(sp)
    80006320:	64a2                	ld	s1,8(sp)
    80006322:	6105                	addi	sp,sp,32
    80006324:	8082                	ret

0000000080006326 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006326:	1141                	addi	sp,sp,-16
    80006328:	e406                	sd	ra,8(sp)
    8000632a:	e022                	sd	s0,0(sp)
    8000632c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000632e:	479d                	li	a5,7
    80006330:	04a7cc63          	blt	a5,a0,80006388 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006334:	0045c797          	auipc	a5,0x45c
    80006338:	acc78793          	addi	a5,a5,-1332 # 80461e00 <disk>
    8000633c:	97aa                	add	a5,a5,a0
    8000633e:	0187c783          	lbu	a5,24(a5)
    80006342:	ebb9                	bnez	a5,80006398 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006344:	00451693          	slli	a3,a0,0x4
    80006348:	0045c797          	auipc	a5,0x45c
    8000634c:	ab878793          	addi	a5,a5,-1352 # 80461e00 <disk>
    80006350:	6398                	ld	a4,0(a5)
    80006352:	9736                	add	a4,a4,a3
    80006354:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80006358:	6398                	ld	a4,0(a5)
    8000635a:	9736                	add	a4,a4,a3
    8000635c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006360:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006364:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006368:	97aa                	add	a5,a5,a0
    8000636a:	4705                	li	a4,1
    8000636c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80006370:	0045c517          	auipc	a0,0x45c
    80006374:	aa850513          	addi	a0,a0,-1368 # 80461e18 <disk+0x18>
    80006378:	ffffc097          	auipc	ra,0xffffc
    8000637c:	0a4080e7          	jalr	164(ra) # 8000241c <wakeup>
}
    80006380:	60a2                	ld	ra,8(sp)
    80006382:	6402                	ld	s0,0(sp)
    80006384:	0141                	addi	sp,sp,16
    80006386:	8082                	ret
    panic("free_desc 1");
    80006388:	00002517          	auipc	a0,0x2
    8000638c:	55050513          	addi	a0,a0,1360 # 800088d8 <syscalls+0x318>
    80006390:	ffffa097          	auipc	ra,0xffffa
    80006394:	1b0080e7          	jalr	432(ra) # 80000540 <panic>
    panic("free_desc 2");
    80006398:	00002517          	auipc	a0,0x2
    8000639c:	55050513          	addi	a0,a0,1360 # 800088e8 <syscalls+0x328>
    800063a0:	ffffa097          	auipc	ra,0xffffa
    800063a4:	1a0080e7          	jalr	416(ra) # 80000540 <panic>

00000000800063a8 <virtio_disk_init>:
{
    800063a8:	1101                	addi	sp,sp,-32
    800063aa:	ec06                	sd	ra,24(sp)
    800063ac:	e822                	sd	s0,16(sp)
    800063ae:	e426                	sd	s1,8(sp)
    800063b0:	e04a                	sd	s2,0(sp)
    800063b2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800063b4:	00002597          	auipc	a1,0x2
    800063b8:	54458593          	addi	a1,a1,1348 # 800088f8 <syscalls+0x338>
    800063bc:	0045c517          	auipc	a0,0x45c
    800063c0:	b6c50513          	addi	a0,a0,-1172 # 80461f28 <disk+0x128>
    800063c4:	ffffb097          	auipc	ra,0xffffb
    800063c8:	8b4080e7          	jalr	-1868(ra) # 80000c78 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800063cc:	100017b7          	lui	a5,0x10001
    800063d0:	4398                	lw	a4,0(a5)
    800063d2:	2701                	sext.w	a4,a4
    800063d4:	747277b7          	lui	a5,0x74727
    800063d8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800063dc:	14f71b63          	bne	a4,a5,80006532 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800063e0:	100017b7          	lui	a5,0x10001
    800063e4:	43dc                	lw	a5,4(a5)
    800063e6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800063e8:	4709                	li	a4,2
    800063ea:	14e79463          	bne	a5,a4,80006532 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800063ee:	100017b7          	lui	a5,0x10001
    800063f2:	479c                	lw	a5,8(a5)
    800063f4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800063f6:	12e79e63          	bne	a5,a4,80006532 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800063fa:	100017b7          	lui	a5,0x10001
    800063fe:	47d8                	lw	a4,12(a5)
    80006400:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006402:	554d47b7          	lui	a5,0x554d4
    80006406:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000640a:	12f71463          	bne	a4,a5,80006532 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000640e:	100017b7          	lui	a5,0x10001
    80006412:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006416:	4705                	li	a4,1
    80006418:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000641a:	470d                	li	a4,3
    8000641c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000641e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006420:	c7ffe6b7          	lui	a3,0xc7ffe
    80006424:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47b9c81f>
    80006428:	8f75                	and	a4,a4,a3
    8000642a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000642c:	472d                	li	a4,11
    8000642e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006430:	5bbc                	lw	a5,112(a5)
    80006432:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006436:	8ba1                	andi	a5,a5,8
    80006438:	10078563          	beqz	a5,80006542 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000643c:	100017b7          	lui	a5,0x10001
    80006440:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006444:	43fc                	lw	a5,68(a5)
    80006446:	2781                	sext.w	a5,a5
    80006448:	10079563          	bnez	a5,80006552 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000644c:	100017b7          	lui	a5,0x10001
    80006450:	5bdc                	lw	a5,52(a5)
    80006452:	2781                	sext.w	a5,a5
  if(max == 0)
    80006454:	10078763          	beqz	a5,80006562 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006458:	471d                	li	a4,7
    8000645a:	10f77c63          	bgeu	a4,a5,80006572 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    8000645e:	ffffa097          	auipc	ra,0xffffa
    80006462:	76e080e7          	jalr	1902(ra) # 80000bcc <kalloc>
    80006466:	0045c497          	auipc	s1,0x45c
    8000646a:	99a48493          	addi	s1,s1,-1638 # 80461e00 <disk>
    8000646e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006470:	ffffa097          	auipc	ra,0xffffa
    80006474:	75c080e7          	jalr	1884(ra) # 80000bcc <kalloc>
    80006478:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000647a:	ffffa097          	auipc	ra,0xffffa
    8000647e:	752080e7          	jalr	1874(ra) # 80000bcc <kalloc>
    80006482:	87aa                	mv	a5,a0
    80006484:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006486:	6088                	ld	a0,0(s1)
    80006488:	cd6d                	beqz	a0,80006582 <virtio_disk_init+0x1da>
    8000648a:	0045c717          	auipc	a4,0x45c
    8000648e:	97e73703          	ld	a4,-1666(a4) # 80461e08 <disk+0x8>
    80006492:	cb65                	beqz	a4,80006582 <virtio_disk_init+0x1da>
    80006494:	c7fd                	beqz	a5,80006582 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80006496:	6605                	lui	a2,0x1
    80006498:	4581                	li	a1,0
    8000649a:	ffffb097          	auipc	ra,0xffffb
    8000649e:	96a080e7          	jalr	-1686(ra) # 80000e04 <memset>
  memset(disk.avail, 0, PGSIZE);
    800064a2:	0045c497          	auipc	s1,0x45c
    800064a6:	95e48493          	addi	s1,s1,-1698 # 80461e00 <disk>
    800064aa:	6605                	lui	a2,0x1
    800064ac:	4581                	li	a1,0
    800064ae:	6488                	ld	a0,8(s1)
    800064b0:	ffffb097          	auipc	ra,0xffffb
    800064b4:	954080e7          	jalr	-1708(ra) # 80000e04 <memset>
  memset(disk.used, 0, PGSIZE);
    800064b8:	6605                	lui	a2,0x1
    800064ba:	4581                	li	a1,0
    800064bc:	6888                	ld	a0,16(s1)
    800064be:	ffffb097          	auipc	ra,0xffffb
    800064c2:	946080e7          	jalr	-1722(ra) # 80000e04 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800064c6:	100017b7          	lui	a5,0x10001
    800064ca:	4721                	li	a4,8
    800064cc:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800064ce:	4098                	lw	a4,0(s1)
    800064d0:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800064d4:	40d8                	lw	a4,4(s1)
    800064d6:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800064da:	6498                	ld	a4,8(s1)
    800064dc:	0007069b          	sext.w	a3,a4
    800064e0:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800064e4:	9701                	srai	a4,a4,0x20
    800064e6:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800064ea:	6898                	ld	a4,16(s1)
    800064ec:	0007069b          	sext.w	a3,a4
    800064f0:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800064f4:	9701                	srai	a4,a4,0x20
    800064f6:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800064fa:	4705                	li	a4,1
    800064fc:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    800064fe:	00e48c23          	sb	a4,24(s1)
    80006502:	00e48ca3          	sb	a4,25(s1)
    80006506:	00e48d23          	sb	a4,26(s1)
    8000650a:	00e48da3          	sb	a4,27(s1)
    8000650e:	00e48e23          	sb	a4,28(s1)
    80006512:	00e48ea3          	sb	a4,29(s1)
    80006516:	00e48f23          	sb	a4,30(s1)
    8000651a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000651e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006522:	0727a823          	sw	s2,112(a5)
}
    80006526:	60e2                	ld	ra,24(sp)
    80006528:	6442                	ld	s0,16(sp)
    8000652a:	64a2                	ld	s1,8(sp)
    8000652c:	6902                	ld	s2,0(sp)
    8000652e:	6105                	addi	sp,sp,32
    80006530:	8082                	ret
    panic("could not find virtio disk");
    80006532:	00002517          	auipc	a0,0x2
    80006536:	3d650513          	addi	a0,a0,982 # 80008908 <syscalls+0x348>
    8000653a:	ffffa097          	auipc	ra,0xffffa
    8000653e:	006080e7          	jalr	6(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006542:	00002517          	auipc	a0,0x2
    80006546:	3e650513          	addi	a0,a0,998 # 80008928 <syscalls+0x368>
    8000654a:	ffffa097          	auipc	ra,0xffffa
    8000654e:	ff6080e7          	jalr	-10(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80006552:	00002517          	auipc	a0,0x2
    80006556:	3f650513          	addi	a0,a0,1014 # 80008948 <syscalls+0x388>
    8000655a:	ffffa097          	auipc	ra,0xffffa
    8000655e:	fe6080e7          	jalr	-26(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006562:	00002517          	auipc	a0,0x2
    80006566:	40650513          	addi	a0,a0,1030 # 80008968 <syscalls+0x3a8>
    8000656a:	ffffa097          	auipc	ra,0xffffa
    8000656e:	fd6080e7          	jalr	-42(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80006572:	00002517          	auipc	a0,0x2
    80006576:	41650513          	addi	a0,a0,1046 # 80008988 <syscalls+0x3c8>
    8000657a:	ffffa097          	auipc	ra,0xffffa
    8000657e:	fc6080e7          	jalr	-58(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80006582:	00002517          	auipc	a0,0x2
    80006586:	42650513          	addi	a0,a0,1062 # 800089a8 <syscalls+0x3e8>
    8000658a:	ffffa097          	auipc	ra,0xffffa
    8000658e:	fb6080e7          	jalr	-74(ra) # 80000540 <panic>

0000000080006592 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006592:	7119                	addi	sp,sp,-128
    80006594:	fc86                	sd	ra,120(sp)
    80006596:	f8a2                	sd	s0,112(sp)
    80006598:	f4a6                	sd	s1,104(sp)
    8000659a:	f0ca                	sd	s2,96(sp)
    8000659c:	ecce                	sd	s3,88(sp)
    8000659e:	e8d2                	sd	s4,80(sp)
    800065a0:	e4d6                	sd	s5,72(sp)
    800065a2:	e0da                	sd	s6,64(sp)
    800065a4:	fc5e                	sd	s7,56(sp)
    800065a6:	f862                	sd	s8,48(sp)
    800065a8:	f466                	sd	s9,40(sp)
    800065aa:	f06a                	sd	s10,32(sp)
    800065ac:	ec6e                	sd	s11,24(sp)
    800065ae:	0100                	addi	s0,sp,128
    800065b0:	8aaa                	mv	s5,a0
    800065b2:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800065b4:	00c52d03          	lw	s10,12(a0)
    800065b8:	001d1d1b          	slliw	s10,s10,0x1
    800065bc:	1d02                	slli	s10,s10,0x20
    800065be:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800065c2:	0045c517          	auipc	a0,0x45c
    800065c6:	96650513          	addi	a0,a0,-1690 # 80461f28 <disk+0x128>
    800065ca:	ffffa097          	auipc	ra,0xffffa
    800065ce:	73e080e7          	jalr	1854(ra) # 80000d08 <acquire>
  for(int i = 0; i < 3; i++){
    800065d2:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800065d4:	44a1                	li	s1,8
      disk.free[i] = 0;
    800065d6:	0045cb97          	auipc	s7,0x45c
    800065da:	82ab8b93          	addi	s7,s7,-2006 # 80461e00 <disk>
  for(int i = 0; i < 3; i++){
    800065de:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800065e0:	0045cc97          	auipc	s9,0x45c
    800065e4:	948c8c93          	addi	s9,s9,-1720 # 80461f28 <disk+0x128>
    800065e8:	a08d                	j	8000664a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800065ea:	00fb8733          	add	a4,s7,a5
    800065ee:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800065f2:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800065f4:	0207c563          	bltz	a5,8000661e <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800065f8:	2905                	addiw	s2,s2,1
    800065fa:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    800065fc:	05690c63          	beq	s2,s6,80006654 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006600:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006602:	0045b717          	auipc	a4,0x45b
    80006606:	7fe70713          	addi	a4,a4,2046 # 80461e00 <disk>
    8000660a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000660c:	01874683          	lbu	a3,24(a4)
    80006610:	fee9                	bnez	a3,800065ea <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006612:	2785                	addiw	a5,a5,1
    80006614:	0705                	addi	a4,a4,1
    80006616:	fe979be3          	bne	a5,s1,8000660c <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000661a:	57fd                	li	a5,-1
    8000661c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000661e:	01205d63          	blez	s2,80006638 <virtio_disk_rw+0xa6>
    80006622:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006624:	000a2503          	lw	a0,0(s4)
    80006628:	00000097          	auipc	ra,0x0
    8000662c:	cfe080e7          	jalr	-770(ra) # 80006326 <free_desc>
      for(int j = 0; j < i; j++)
    80006630:	2d85                	addiw	s11,s11,1
    80006632:	0a11                	addi	s4,s4,4
    80006634:	ff2d98e3          	bne	s11,s2,80006624 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006638:	85e6                	mv	a1,s9
    8000663a:	0045b517          	auipc	a0,0x45b
    8000663e:	7de50513          	addi	a0,a0,2014 # 80461e18 <disk+0x18>
    80006642:	ffffc097          	auipc	ra,0xffffc
    80006646:	d76080e7          	jalr	-650(ra) # 800023b8 <sleep>
  for(int i = 0; i < 3; i++){
    8000664a:	f8040a13          	addi	s4,s0,-128
{
    8000664e:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006650:	894e                	mv	s2,s3
    80006652:	b77d                	j	80006600 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006654:	f8042503          	lw	a0,-128(s0)
    80006658:	00a50713          	addi	a4,a0,10
    8000665c:	0712                	slli	a4,a4,0x4

  if(write)
    8000665e:	0045b797          	auipc	a5,0x45b
    80006662:	7a278793          	addi	a5,a5,1954 # 80461e00 <disk>
    80006666:	00e786b3          	add	a3,a5,a4
    8000666a:	01803633          	snez	a2,s8
    8000666e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006670:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006674:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006678:	f6070613          	addi	a2,a4,-160
    8000667c:	6394                	ld	a3,0(a5)
    8000667e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006680:	00870593          	addi	a1,a4,8
    80006684:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006686:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006688:	0007b803          	ld	a6,0(a5)
    8000668c:	9642                	add	a2,a2,a6
    8000668e:	46c1                	li	a3,16
    80006690:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006692:	4585                	li	a1,1
    80006694:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006698:	f8442683          	lw	a3,-124(s0)
    8000669c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800066a0:	0692                	slli	a3,a3,0x4
    800066a2:	9836                	add	a6,a6,a3
    800066a4:	058a8613          	addi	a2,s5,88
    800066a8:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    800066ac:	0007b803          	ld	a6,0(a5)
    800066b0:	96c2                	add	a3,a3,a6
    800066b2:	40000613          	li	a2,1024
    800066b6:	c690                	sw	a2,8(a3)
  if(write)
    800066b8:	001c3613          	seqz	a2,s8
    800066bc:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800066c0:	00166613          	ori	a2,a2,1
    800066c4:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800066c8:	f8842603          	lw	a2,-120(s0)
    800066cc:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800066d0:	00250693          	addi	a3,a0,2
    800066d4:	0692                	slli	a3,a3,0x4
    800066d6:	96be                	add	a3,a3,a5
    800066d8:	58fd                	li	a7,-1
    800066da:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800066de:	0612                	slli	a2,a2,0x4
    800066e0:	9832                	add	a6,a6,a2
    800066e2:	f9070713          	addi	a4,a4,-112
    800066e6:	973e                	add	a4,a4,a5
    800066e8:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    800066ec:	6398                	ld	a4,0(a5)
    800066ee:	9732                	add	a4,a4,a2
    800066f0:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800066f2:	4609                	li	a2,2
    800066f4:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    800066f8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800066fc:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006700:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006704:	6794                	ld	a3,8(a5)
    80006706:	0026d703          	lhu	a4,2(a3)
    8000670a:	8b1d                	andi	a4,a4,7
    8000670c:	0706                	slli	a4,a4,0x1
    8000670e:	96ba                	add	a3,a3,a4
    80006710:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006714:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006718:	6798                	ld	a4,8(a5)
    8000671a:	00275783          	lhu	a5,2(a4)
    8000671e:	2785                	addiw	a5,a5,1
    80006720:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006724:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006728:	100017b7          	lui	a5,0x10001
    8000672c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006730:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    80006734:	0045b917          	auipc	s2,0x45b
    80006738:	7f490913          	addi	s2,s2,2036 # 80461f28 <disk+0x128>
  while(b->disk == 1) {
    8000673c:	4485                	li	s1,1
    8000673e:	00b79c63          	bne	a5,a1,80006756 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006742:	85ca                	mv	a1,s2
    80006744:	8556                	mv	a0,s5
    80006746:	ffffc097          	auipc	ra,0xffffc
    8000674a:	c72080e7          	jalr	-910(ra) # 800023b8 <sleep>
  while(b->disk == 1) {
    8000674e:	004aa783          	lw	a5,4(s5)
    80006752:	fe9788e3          	beq	a5,s1,80006742 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006756:	f8042903          	lw	s2,-128(s0)
    8000675a:	00290713          	addi	a4,s2,2
    8000675e:	0712                	slli	a4,a4,0x4
    80006760:	0045b797          	auipc	a5,0x45b
    80006764:	6a078793          	addi	a5,a5,1696 # 80461e00 <disk>
    80006768:	97ba                	add	a5,a5,a4
    8000676a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000676e:	0045b997          	auipc	s3,0x45b
    80006772:	69298993          	addi	s3,s3,1682 # 80461e00 <disk>
    80006776:	00491713          	slli	a4,s2,0x4
    8000677a:	0009b783          	ld	a5,0(s3)
    8000677e:	97ba                	add	a5,a5,a4
    80006780:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006784:	854a                	mv	a0,s2
    80006786:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000678a:	00000097          	auipc	ra,0x0
    8000678e:	b9c080e7          	jalr	-1124(ra) # 80006326 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006792:	8885                	andi	s1,s1,1
    80006794:	f0ed                	bnez	s1,80006776 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006796:	0045b517          	auipc	a0,0x45b
    8000679a:	79250513          	addi	a0,a0,1938 # 80461f28 <disk+0x128>
    8000679e:	ffffa097          	auipc	ra,0xffffa
    800067a2:	61e080e7          	jalr	1566(ra) # 80000dbc <release>
}
    800067a6:	70e6                	ld	ra,120(sp)
    800067a8:	7446                	ld	s0,112(sp)
    800067aa:	74a6                	ld	s1,104(sp)
    800067ac:	7906                	ld	s2,96(sp)
    800067ae:	69e6                	ld	s3,88(sp)
    800067b0:	6a46                	ld	s4,80(sp)
    800067b2:	6aa6                	ld	s5,72(sp)
    800067b4:	6b06                	ld	s6,64(sp)
    800067b6:	7be2                	ld	s7,56(sp)
    800067b8:	7c42                	ld	s8,48(sp)
    800067ba:	7ca2                	ld	s9,40(sp)
    800067bc:	7d02                	ld	s10,32(sp)
    800067be:	6de2                	ld	s11,24(sp)
    800067c0:	6109                	addi	sp,sp,128
    800067c2:	8082                	ret

00000000800067c4 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800067c4:	1101                	addi	sp,sp,-32
    800067c6:	ec06                	sd	ra,24(sp)
    800067c8:	e822                	sd	s0,16(sp)
    800067ca:	e426                	sd	s1,8(sp)
    800067cc:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800067ce:	0045b497          	auipc	s1,0x45b
    800067d2:	63248493          	addi	s1,s1,1586 # 80461e00 <disk>
    800067d6:	0045b517          	auipc	a0,0x45b
    800067da:	75250513          	addi	a0,a0,1874 # 80461f28 <disk+0x128>
    800067de:	ffffa097          	auipc	ra,0xffffa
    800067e2:	52a080e7          	jalr	1322(ra) # 80000d08 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800067e6:	10001737          	lui	a4,0x10001
    800067ea:	533c                	lw	a5,96(a4)
    800067ec:	8b8d                	andi	a5,a5,3
    800067ee:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800067f0:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800067f4:	689c                	ld	a5,16(s1)
    800067f6:	0204d703          	lhu	a4,32(s1)
    800067fa:	0027d783          	lhu	a5,2(a5)
    800067fe:	04f70863          	beq	a4,a5,8000684e <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006802:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006806:	6898                	ld	a4,16(s1)
    80006808:	0204d783          	lhu	a5,32(s1)
    8000680c:	8b9d                	andi	a5,a5,7
    8000680e:	078e                	slli	a5,a5,0x3
    80006810:	97ba                	add	a5,a5,a4
    80006812:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006814:	00278713          	addi	a4,a5,2
    80006818:	0712                	slli	a4,a4,0x4
    8000681a:	9726                	add	a4,a4,s1
    8000681c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006820:	e721                	bnez	a4,80006868 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006822:	0789                	addi	a5,a5,2
    80006824:	0792                	slli	a5,a5,0x4
    80006826:	97a6                	add	a5,a5,s1
    80006828:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000682a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000682e:	ffffc097          	auipc	ra,0xffffc
    80006832:	bee080e7          	jalr	-1042(ra) # 8000241c <wakeup>

    disk.used_idx += 1;
    80006836:	0204d783          	lhu	a5,32(s1)
    8000683a:	2785                	addiw	a5,a5,1
    8000683c:	17c2                	slli	a5,a5,0x30
    8000683e:	93c1                	srli	a5,a5,0x30
    80006840:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006844:	6898                	ld	a4,16(s1)
    80006846:	00275703          	lhu	a4,2(a4)
    8000684a:	faf71ce3          	bne	a4,a5,80006802 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000684e:	0045b517          	auipc	a0,0x45b
    80006852:	6da50513          	addi	a0,a0,1754 # 80461f28 <disk+0x128>
    80006856:	ffffa097          	auipc	ra,0xffffa
    8000685a:	566080e7          	jalr	1382(ra) # 80000dbc <release>
}
    8000685e:	60e2                	ld	ra,24(sp)
    80006860:	6442                	ld	s0,16(sp)
    80006862:	64a2                	ld	s1,8(sp)
    80006864:	6105                	addi	sp,sp,32
    80006866:	8082                	ret
      panic("virtio_disk_intr status");
    80006868:	00002517          	auipc	a0,0x2
    8000686c:	15850513          	addi	a0,a0,344 # 800089c0 <syscalls+0x400>
    80006870:	ffffa097          	auipc	ra,0xffffa
    80006874:	cd0080e7          	jalr	-816(ra) # 80000540 <panic>
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
