
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a0013103          	ld	sp,-1536(sp) # 80008a00 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000054:	a2070713          	addi	a4,a4,-1504 # 80008a70 <timer_scratch>
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
    80000066:	01e78793          	addi	a5,a5,30 # 80006080 <timervec>
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
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc91f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	e9478793          	addi	a5,a5,-364 # 80000f40 <main>
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
    8000012e:	654080e7          	jalr	1620(ra) # 8000277e <either_copyin>
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
    8000018e:	a2650513          	addi	a0,a0,-1498 # 80010bb0 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	b0c080e7          	jalr	-1268(ra) # 80000c9e <acquire>
    while (n > 0)
    {
        // wait until interrupt handler has put some
        // input into cons.buffer.
        while (cons.r == cons.w)
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	a1648493          	addi	s1,s1,-1514 # 80010bb0 <cons>
            if (killed(myproc()))
            {
                release(&cons.lock);
                return -1;
            }
            sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	aa690913          	addi	s2,s2,-1370 # 80010c48 <cons+0x98>
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
    800001c4:	9b2080e7          	jalr	-1614(ra) # 80001b72 <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	400080e7          	jalr	1024(ra) # 800025c8 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
            sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	14a080e7          	jalr	330(ra) # 80002320 <sleep>
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
    80000216:	516080e7          	jalr	1302(ra) # 80002728 <either_copyout>
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
    8000022a:	98a50513          	addi	a0,a0,-1654 # 80010bb0 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	b24080e7          	jalr	-1244(ra) # 80000d52 <release>

    return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
                release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	97450513          	addi	a0,a0,-1676 # 80010bb0 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	b0e080e7          	jalr	-1266(ra) # 80000d52 <release>
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
    80000276:	9cf72b23          	sw	a5,-1578(a4) # 80010c48 <cons+0x98>
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
    800002d0:	8e450513          	addi	a0,a0,-1820 # 80010bb0 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	9ca080e7          	jalr	-1590(ra) # 80000c9e <acquire>

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
    800002f6:	4e2080e7          	jalr	1250(ra) # 800027d4 <procdump>
            }
        }
        break;
    }

    release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	8b650513          	addi	a0,a0,-1866 # 80010bb0 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	a50080e7          	jalr	-1456(ra) # 80000d52 <release>
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
    80000322:	89270713          	addi	a4,a4,-1902 # 80010bb0 <cons>
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
    8000034c:	86878793          	addi	a5,a5,-1944 # 80010bb0 <cons>
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
    8000037a:	8d27a783          	lw	a5,-1838(a5) # 80010c48 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
        while (cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	82670713          	addi	a4,a4,-2010 # 80010bb0 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
               cons.buf[(cons.e - 1) % INPUT_BUF_SIZE] != '\n')
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	81648493          	addi	s1,s1,-2026 # 80010bb0 <cons>
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
    800003da:	7da70713          	addi	a4,a4,2010 # 80010bb0 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
            cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	86f72223          	sw	a5,-1948(a4) # 80010c50 <cons+0xa0>
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
    80000416:	79e78793          	addi	a5,a5,1950 # 80010bb0 <cons>
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
    8000043a:	80c7ab23          	sw	a2,-2026(a5) # 80010c4c <cons+0x9c>
                wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	80a50513          	addi	a0,a0,-2038 # 80010c48 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	f3e080e7          	jalr	-194(ra) # 80002384 <wakeup>
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
    80000464:	75050513          	addi	a0,a0,1872 # 80010bb0 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	7a6080e7          	jalr	1958(ra) # 80000c0e <initlock>

    uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	33e080e7          	jalr	830(ra) # 800007ae <uartinit>

    // connect read and write system calls
    // to consoleread and consolewrite.
    devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	8d078793          	addi	a5,a5,-1840 # 80020d48 <devsw>
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
    80000562:	7007a923          	sw	zero,1810(a5) # 80010c70 <pr+0x18>
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
    80000584:	b0850513          	addi	a0,a0,-1272 # 80008088 <digits+0x38>
    80000588:	00000097          	auipc	ra,0x0
    8000058c:	014080e7          	jalr	20(ra) # 8000059c <printf>
    panicked = 1; // freeze uart output from other CPUs
    80000590:	4785                	li	a5,1
    80000592:	00008717          	auipc	a4,0x8
    80000596:	48f72723          	sw	a5,1166(a4) # 80008a20 <panicked>
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
    800005d2:	6a2dad83          	lw	s11,1698(s11) # 80010c70 <pr+0x18>
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
    80000610:	64c50513          	addi	a0,a0,1612 # 80010c58 <pr>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	68a080e7          	jalr	1674(ra) # 80000c9e <acquire>
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
    8000076e:	4ee50513          	addi	a0,a0,1262 # 80010c58 <pr>
    80000772:	00000097          	auipc	ra,0x0
    80000776:	5e0080e7          	jalr	1504(ra) # 80000d52 <release>
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
    8000078a:	4d248493          	addi	s1,s1,1234 # 80010c58 <pr>
    8000078e:	00008597          	auipc	a1,0x8
    80000792:	8ba58593          	addi	a1,a1,-1862 # 80008048 <__func__.1+0x40>
    80000796:	8526                	mv	a0,s1
    80000798:	00000097          	auipc	ra,0x0
    8000079c:	476080e7          	jalr	1142(ra) # 80000c0e <initlock>
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
    800007ea:	49250513          	addi	a0,a0,1170 # 80010c78 <uart_tx_lock>
    800007ee:	00000097          	auipc	ra,0x0
    800007f2:	420080e7          	jalr	1056(ra) # 80000c0e <initlock>
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
    8000080e:	448080e7          	jalr	1096(ra) # 80000c52 <push_off>

  if(panicked){
    80000812:	00008797          	auipc	a5,0x8
    80000816:	20e7a783          	lw	a5,526(a5) # 80008a20 <panicked>
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
    8000083c:	4ba080e7          	jalr	1210(ra) # 80000cf2 <pop_off>
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
    8000084e:	1de7b783          	ld	a5,478(a5) # 80008a28 <uart_tx_r>
    80000852:	00008717          	auipc	a4,0x8
    80000856:	1de73703          	ld	a4,478(a4) # 80008a30 <uart_tx_w>
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
    80000878:	404a0a13          	addi	s4,s4,1028 # 80010c78 <uart_tx_lock>
    uart_tx_r += 1;
    8000087c:	00008497          	auipc	s1,0x8
    80000880:	1ac48493          	addi	s1,s1,428 # 80008a28 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000884:	00008997          	auipc	s3,0x8
    80000888:	1ac98993          	addi	s3,s3,428 # 80008a30 <uart_tx_w>
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
    800008aa:	ade080e7          	jalr	-1314(ra) # 80002384 <wakeup>
    
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
    800008e6:	39650513          	addi	a0,a0,918 # 80010c78 <uart_tx_lock>
    800008ea:	00000097          	auipc	ra,0x0
    800008ee:	3b4080e7          	jalr	948(ra) # 80000c9e <acquire>
  if(panicked){
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	12e7a783          	lw	a5,302(a5) # 80008a20 <panicked>
    800008fa:	e7c9                	bnez	a5,80000984 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fc:	00008717          	auipc	a4,0x8
    80000900:	13473703          	ld	a4,308(a4) # 80008a30 <uart_tx_w>
    80000904:	00008797          	auipc	a5,0x8
    80000908:	1247b783          	ld	a5,292(a5) # 80008a28 <uart_tx_r>
    8000090c:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00010997          	auipc	s3,0x10
    80000914:	36898993          	addi	s3,s3,872 # 80010c78 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	11048493          	addi	s1,s1,272 # 80008a28 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	11090913          	addi	s2,s2,272 # 80008a30 <uart_tx_w>
    80000928:	00e79f63          	bne	a5,a4,80000946 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000092c:	85ce                	mv	a1,s3
    8000092e:	8526                	mv	a0,s1
    80000930:	00002097          	auipc	ra,0x2
    80000934:	9f0080e7          	jalr	-1552(ra) # 80002320 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000938:	00093703          	ld	a4,0(s2)
    8000093c:	609c                	ld	a5,0(s1)
    8000093e:	02078793          	addi	a5,a5,32
    80000942:	fee785e3          	beq	a5,a4,8000092c <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000946:	00010497          	auipc	s1,0x10
    8000094a:	33248493          	addi	s1,s1,818 # 80010c78 <uart_tx_lock>
    8000094e:	01f77793          	andi	a5,a4,31
    80000952:	97a6                	add	a5,a5,s1
    80000954:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000958:	0705                	addi	a4,a4,1
    8000095a:	00008797          	auipc	a5,0x8
    8000095e:	0ce7bb23          	sd	a4,214(a5) # 80008a30 <uart_tx_w>
  uartstart();
    80000962:	00000097          	auipc	ra,0x0
    80000966:	ee8080e7          	jalr	-280(ra) # 8000084a <uartstart>
  release(&uart_tx_lock);
    8000096a:	8526                	mv	a0,s1
    8000096c:	00000097          	auipc	ra,0x0
    80000970:	3e6080e7          	jalr	998(ra) # 80000d52 <release>
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
    800009d0:	2ac48493          	addi	s1,s1,684 # 80010c78 <uart_tx_lock>
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	2c8080e7          	jalr	712(ra) # 80000c9e <acquire>
  uartstart();
    800009de:	00000097          	auipc	ra,0x0
    800009e2:	e6c080e7          	jalr	-404(ra) # 8000084a <uartstart>
  release(&uart_tx_lock);
    800009e6:	8526                	mv	a0,s1
    800009e8:	00000097          	auipc	ra,0x0
    800009ec:	36a080e7          	jalr	874(ra) # 80000d52 <release>
}
    800009f0:	60e2                	ld	ra,24(sp)
    800009f2:	6442                	ld	s0,16(sp)
    800009f4:	64a2                	ld	s1,8(sp)
    800009f6:	6105                	addi	sp,sp,32
    800009f8:	8082                	ret

00000000800009fa <kfree>:
// Free the page of physical memory pointed at by pa,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void kfree(void *pa)
{
    800009fa:	1101                	addi	sp,sp,-32
    800009fc:	ec06                	sd	ra,24(sp)
    800009fe:	e822                	sd	s0,16(sp)
    80000a00:	e426                	sd	s1,8(sp)
    80000a02:	e04a                	sd	s2,0(sp)
    80000a04:	1000                	addi	s0,sp,32
    80000a06:	84aa                	mv	s1,a0
    if (MAX_PAGES != 0) // On kinit MAX_PAGES is not yet set
    80000a08:	00008797          	auipc	a5,0x8
    80000a0c:	0387b783          	ld	a5,56(a5) # 80008a40 <MAX_PAGES>
    80000a10:	c799                	beqz	a5,80000a1e <kfree+0x24>
        assert(FREE_PAGES < MAX_PAGES);
    80000a12:	00008717          	auipc	a4,0x8
    80000a16:	02673703          	ld	a4,38(a4) # 80008a38 <FREE_PAGES>
    80000a1a:	06f77663          	bgeu	a4,a5,80000a86 <kfree+0x8c>
    struct run *r;

    if (((uint64)pa % PGSIZE) != 0 || (char *)pa < end || (uint64)pa >= PHYSTOP)
    80000a1e:	03449793          	slli	a5,s1,0x34
    80000a22:	efc1                	bnez	a5,80000aba <kfree+0xc0>
    80000a24:	00021797          	auipc	a5,0x21
    80000a28:	4bc78793          	addi	a5,a5,1212 # 80021ee0 <end>
    80000a2c:	08f4e763          	bltu	s1,a5,80000aba <kfree+0xc0>
    80000a30:	47c5                	li	a5,17
    80000a32:	07ee                	slli	a5,a5,0x1b
    80000a34:	08f4f363          	bgeu	s1,a5,80000aba <kfree+0xc0>
        panic("kfree");

    // Fill with junk to catch dangling refs.
    memset(pa, 1, PGSIZE);
    80000a38:	6605                	lui	a2,0x1
    80000a3a:	4585                	li	a1,1
    80000a3c:	8526                	mv	a0,s1
    80000a3e:	00000097          	auipc	ra,0x0
    80000a42:	35c080e7          	jalr	860(ra) # 80000d9a <memset>

    r = (struct run *)pa;

    acquire(&kmem.lock);
    80000a46:	00010917          	auipc	s2,0x10
    80000a4a:	26a90913          	addi	s2,s2,618 # 80010cb0 <kmem>
    80000a4e:	854a                	mv	a0,s2
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	24e080e7          	jalr	590(ra) # 80000c9e <acquire>
    r->next = kmem.freelist;
    80000a58:	01893783          	ld	a5,24(s2)
    80000a5c:	e09c                	sd	a5,0(s1)
    kmem.freelist = r;
    80000a5e:	00993c23          	sd	s1,24(s2)
    FREE_PAGES++;
    80000a62:	00008717          	auipc	a4,0x8
    80000a66:	fd670713          	addi	a4,a4,-42 # 80008a38 <FREE_PAGES>
    80000a6a:	631c                	ld	a5,0(a4)
    80000a6c:	0785                	addi	a5,a5,1
    80000a6e:	e31c                	sd	a5,0(a4)
    release(&kmem.lock);
    80000a70:	854a                	mv	a0,s2
    80000a72:	00000097          	auipc	ra,0x0
    80000a76:	2e0080e7          	jalr	736(ra) # 80000d52 <release>
}
    80000a7a:	60e2                	ld	ra,24(sp)
    80000a7c:	6442                	ld	s0,16(sp)
    80000a7e:	64a2                	ld	s1,8(sp)
    80000a80:	6902                	ld	s2,0(sp)
    80000a82:	6105                	addi	sp,sp,32
    80000a84:	8082                	ret
        assert(FREE_PAGES < MAX_PAGES);
    80000a86:	03700693          	li	a3,55
    80000a8a:	00007617          	auipc	a2,0x7
    80000a8e:	57e60613          	addi	a2,a2,1406 # 80008008 <__func__.1>
    80000a92:	00007597          	auipc	a1,0x7
    80000a96:	5de58593          	addi	a1,a1,1502 # 80008070 <digits+0x20>
    80000a9a:	00007517          	auipc	a0,0x7
    80000a9e:	5e650513          	addi	a0,a0,1510 # 80008080 <digits+0x30>
    80000aa2:	00000097          	auipc	ra,0x0
    80000aa6:	afa080e7          	jalr	-1286(ra) # 8000059c <printf>
    80000aaa:	00007517          	auipc	a0,0x7
    80000aae:	5e650513          	addi	a0,a0,1510 # 80008090 <digits+0x40>
    80000ab2:	00000097          	auipc	ra,0x0
    80000ab6:	a8e080e7          	jalr	-1394(ra) # 80000540 <panic>
        panic("kfree");
    80000aba:	00007517          	auipc	a0,0x7
    80000abe:	5e650513          	addi	a0,a0,1510 # 800080a0 <digits+0x50>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	a7e080e7          	jalr	-1410(ra) # 80000540 <panic>

0000000080000aca <freerange>:
{
    80000aca:	7179                	addi	sp,sp,-48
    80000acc:	f406                	sd	ra,40(sp)
    80000ace:	f022                	sd	s0,32(sp)
    80000ad0:	ec26                	sd	s1,24(sp)
    80000ad2:	e84a                	sd	s2,16(sp)
    80000ad4:	e44e                	sd	s3,8(sp)
    80000ad6:	e052                	sd	s4,0(sp)
    80000ad8:	1800                	addi	s0,sp,48
    p = (char *)PGROUNDUP((uint64)pa_start);
    80000ada:	6785                	lui	a5,0x1
    80000adc:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000ae0:	00e504b3          	add	s1,a0,a4
    80000ae4:	777d                	lui	a4,0xfffff
    80000ae6:	8cf9                	and	s1,s1,a4
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000ae8:	94be                	add	s1,s1,a5
    80000aea:	0095ee63          	bltu	a1,s1,80000b06 <freerange+0x3c>
    80000aee:	892e                	mv	s2,a1
        kfree(p);
    80000af0:	7a7d                	lui	s4,0xfffff
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000af2:	6985                	lui	s3,0x1
        kfree(p);
    80000af4:	01448533          	add	a0,s1,s4
    80000af8:	00000097          	auipc	ra,0x0
    80000afc:	f02080e7          	jalr	-254(ra) # 800009fa <kfree>
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000b00:	94ce                	add	s1,s1,s3
    80000b02:	fe9979e3          	bgeu	s2,s1,80000af4 <freerange+0x2a>
}
    80000b06:	70a2                	ld	ra,40(sp)
    80000b08:	7402                	ld	s0,32(sp)
    80000b0a:	64e2                	ld	s1,24(sp)
    80000b0c:	6942                	ld	s2,16(sp)
    80000b0e:	69a2                	ld	s3,8(sp)
    80000b10:	6a02                	ld	s4,0(sp)
    80000b12:	6145                	addi	sp,sp,48
    80000b14:	8082                	ret

0000000080000b16 <kinit>:
{
    80000b16:	1141                	addi	sp,sp,-16
    80000b18:	e406                	sd	ra,8(sp)
    80000b1a:	e022                	sd	s0,0(sp)
    80000b1c:	0800                	addi	s0,sp,16
    initlock(&kmem.lock, "kmem");
    80000b1e:	00007597          	auipc	a1,0x7
    80000b22:	58a58593          	addi	a1,a1,1418 # 800080a8 <digits+0x58>
    80000b26:	00010517          	auipc	a0,0x10
    80000b2a:	18a50513          	addi	a0,a0,394 # 80010cb0 <kmem>
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	0e0080e7          	jalr	224(ra) # 80000c0e <initlock>
    freerange(end, (void *)PHYSTOP);
    80000b36:	45c5                	li	a1,17
    80000b38:	05ee                	slli	a1,a1,0x1b
    80000b3a:	00021517          	auipc	a0,0x21
    80000b3e:	3a650513          	addi	a0,a0,934 # 80021ee0 <end>
    80000b42:	00000097          	auipc	ra,0x0
    80000b46:	f88080e7          	jalr	-120(ra) # 80000aca <freerange>
    MAX_PAGES = FREE_PAGES;
    80000b4a:	00008797          	auipc	a5,0x8
    80000b4e:	eee7b783          	ld	a5,-274(a5) # 80008a38 <FREE_PAGES>
    80000b52:	00008717          	auipc	a4,0x8
    80000b56:	eef73723          	sd	a5,-274(a4) # 80008a40 <MAX_PAGES>
}
    80000b5a:	60a2                	ld	ra,8(sp)
    80000b5c:	6402                	ld	s0,0(sp)
    80000b5e:	0141                	addi	sp,sp,16
    80000b60:	8082                	ret

0000000080000b62 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b62:	1101                	addi	sp,sp,-32
    80000b64:	ec06                	sd	ra,24(sp)
    80000b66:	e822                	sd	s0,16(sp)
    80000b68:	e426                	sd	s1,8(sp)
    80000b6a:	1000                	addi	s0,sp,32
    assert(FREE_PAGES > 0);
    80000b6c:	00008797          	auipc	a5,0x8
    80000b70:	ecc7b783          	ld	a5,-308(a5) # 80008a38 <FREE_PAGES>
    80000b74:	cbb1                	beqz	a5,80000bc8 <kalloc+0x66>
    struct run *r;

    acquire(&kmem.lock);
    80000b76:	00010497          	auipc	s1,0x10
    80000b7a:	13a48493          	addi	s1,s1,314 # 80010cb0 <kmem>
    80000b7e:	8526                	mv	a0,s1
    80000b80:	00000097          	auipc	ra,0x0
    80000b84:	11e080e7          	jalr	286(ra) # 80000c9e <acquire>
    r = kmem.freelist;
    80000b88:	6c84                	ld	s1,24(s1)
    if (r)
    80000b8a:	c8ad                	beqz	s1,80000bfc <kalloc+0x9a>
        kmem.freelist = r->next;
    80000b8c:	609c                	ld	a5,0(s1)
    80000b8e:	00010517          	auipc	a0,0x10
    80000b92:	12250513          	addi	a0,a0,290 # 80010cb0 <kmem>
    80000b96:	ed1c                	sd	a5,24(a0)
    release(&kmem.lock);
    80000b98:	00000097          	auipc	ra,0x0
    80000b9c:	1ba080e7          	jalr	442(ra) # 80000d52 <release>

    if (r)
        memset((char *)r, 5, PGSIZE); // fill with junk
    80000ba0:	6605                	lui	a2,0x1
    80000ba2:	4595                	li	a1,5
    80000ba4:	8526                	mv	a0,s1
    80000ba6:	00000097          	auipc	ra,0x0
    80000baa:	1f4080e7          	jalr	500(ra) # 80000d9a <memset>
    FREE_PAGES--;
    80000bae:	00008717          	auipc	a4,0x8
    80000bb2:	e8a70713          	addi	a4,a4,-374 # 80008a38 <FREE_PAGES>
    80000bb6:	631c                	ld	a5,0(a4)
    80000bb8:	17fd                	addi	a5,a5,-1
    80000bba:	e31c                	sd	a5,0(a4)
    return (void *)r;
}
    80000bbc:	8526                	mv	a0,s1
    80000bbe:	60e2                	ld	ra,24(sp)
    80000bc0:	6442                	ld	s0,16(sp)
    80000bc2:	64a2                	ld	s1,8(sp)
    80000bc4:	6105                	addi	sp,sp,32
    80000bc6:	8082                	ret
    assert(FREE_PAGES > 0);
    80000bc8:	04f00693          	li	a3,79
    80000bcc:	00007617          	auipc	a2,0x7
    80000bd0:	43460613          	addi	a2,a2,1076 # 80008000 <etext>
    80000bd4:	00007597          	auipc	a1,0x7
    80000bd8:	49c58593          	addi	a1,a1,1180 # 80008070 <digits+0x20>
    80000bdc:	00007517          	auipc	a0,0x7
    80000be0:	4a450513          	addi	a0,a0,1188 # 80008080 <digits+0x30>
    80000be4:	00000097          	auipc	ra,0x0
    80000be8:	9b8080e7          	jalr	-1608(ra) # 8000059c <printf>
    80000bec:	00007517          	auipc	a0,0x7
    80000bf0:	4a450513          	addi	a0,a0,1188 # 80008090 <digits+0x40>
    80000bf4:	00000097          	auipc	ra,0x0
    80000bf8:	94c080e7          	jalr	-1716(ra) # 80000540 <panic>
    release(&kmem.lock);
    80000bfc:	00010517          	auipc	a0,0x10
    80000c00:	0b450513          	addi	a0,a0,180 # 80010cb0 <kmem>
    80000c04:	00000097          	auipc	ra,0x0
    80000c08:	14e080e7          	jalr	334(ra) # 80000d52 <release>
    if (r)
    80000c0c:	b74d                	j	80000bae <kalloc+0x4c>

0000000080000c0e <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000c0e:	1141                	addi	sp,sp,-16
    80000c10:	e422                	sd	s0,8(sp)
    80000c12:	0800                	addi	s0,sp,16
  lk->name = name;
    80000c14:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000c16:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000c1a:	00053823          	sd	zero,16(a0)
}
    80000c1e:	6422                	ld	s0,8(sp)
    80000c20:	0141                	addi	sp,sp,16
    80000c22:	8082                	ret

0000000080000c24 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000c24:	411c                	lw	a5,0(a0)
    80000c26:	e399                	bnez	a5,80000c2c <holding+0x8>
    80000c28:	4501                	li	a0,0
  return r;
}
    80000c2a:	8082                	ret
{
    80000c2c:	1101                	addi	sp,sp,-32
    80000c2e:	ec06                	sd	ra,24(sp)
    80000c30:	e822                	sd	s0,16(sp)
    80000c32:	e426                	sd	s1,8(sp)
    80000c34:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000c36:	6904                	ld	s1,16(a0)
    80000c38:	00001097          	auipc	ra,0x1
    80000c3c:	f1e080e7          	jalr	-226(ra) # 80001b56 <mycpu>
    80000c40:	40a48533          	sub	a0,s1,a0
    80000c44:	00153513          	seqz	a0,a0
}
    80000c48:	60e2                	ld	ra,24(sp)
    80000c4a:	6442                	ld	s0,16(sp)
    80000c4c:	64a2                	ld	s1,8(sp)
    80000c4e:	6105                	addi	sp,sp,32
    80000c50:	8082                	ret

0000000080000c52 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c52:	1101                	addi	sp,sp,-32
    80000c54:	ec06                	sd	ra,24(sp)
    80000c56:	e822                	sd	s0,16(sp)
    80000c58:	e426                	sd	s1,8(sp)
    80000c5a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c5c:	100024f3          	csrr	s1,sstatus
    80000c60:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c64:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c66:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c6a:	00001097          	auipc	ra,0x1
    80000c6e:	eec080e7          	jalr	-276(ra) # 80001b56 <mycpu>
    80000c72:	5d3c                	lw	a5,120(a0)
    80000c74:	cf89                	beqz	a5,80000c8e <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c76:	00001097          	auipc	ra,0x1
    80000c7a:	ee0080e7          	jalr	-288(ra) # 80001b56 <mycpu>
    80000c7e:	5d3c                	lw	a5,120(a0)
    80000c80:	2785                	addiw	a5,a5,1
    80000c82:	dd3c                	sw	a5,120(a0)
}
    80000c84:	60e2                	ld	ra,24(sp)
    80000c86:	6442                	ld	s0,16(sp)
    80000c88:	64a2                	ld	s1,8(sp)
    80000c8a:	6105                	addi	sp,sp,32
    80000c8c:	8082                	ret
    mycpu()->intena = old;
    80000c8e:	00001097          	auipc	ra,0x1
    80000c92:	ec8080e7          	jalr	-312(ra) # 80001b56 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c96:	8085                	srli	s1,s1,0x1
    80000c98:	8885                	andi	s1,s1,1
    80000c9a:	dd64                	sw	s1,124(a0)
    80000c9c:	bfe9                	j	80000c76 <push_off+0x24>

0000000080000c9e <acquire>:
{
    80000c9e:	1101                	addi	sp,sp,-32
    80000ca0:	ec06                	sd	ra,24(sp)
    80000ca2:	e822                	sd	s0,16(sp)
    80000ca4:	e426                	sd	s1,8(sp)
    80000ca6:	1000                	addi	s0,sp,32
    80000ca8:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000caa:	00000097          	auipc	ra,0x0
    80000cae:	fa8080e7          	jalr	-88(ra) # 80000c52 <push_off>
  if(holding(lk))
    80000cb2:	8526                	mv	a0,s1
    80000cb4:	00000097          	auipc	ra,0x0
    80000cb8:	f70080e7          	jalr	-144(ra) # 80000c24 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000cbc:	4705                	li	a4,1
  if(holding(lk))
    80000cbe:	e115                	bnez	a0,80000ce2 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000cc0:	87ba                	mv	a5,a4
    80000cc2:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000cc6:	2781                	sext.w	a5,a5
    80000cc8:	ffe5                	bnez	a5,80000cc0 <acquire+0x22>
  __sync_synchronize();
    80000cca:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000cce:	00001097          	auipc	ra,0x1
    80000cd2:	e88080e7          	jalr	-376(ra) # 80001b56 <mycpu>
    80000cd6:	e888                	sd	a0,16(s1)
}
    80000cd8:	60e2                	ld	ra,24(sp)
    80000cda:	6442                	ld	s0,16(sp)
    80000cdc:	64a2                	ld	s1,8(sp)
    80000cde:	6105                	addi	sp,sp,32
    80000ce0:	8082                	ret
    panic("acquire");
    80000ce2:	00007517          	auipc	a0,0x7
    80000ce6:	3ce50513          	addi	a0,a0,974 # 800080b0 <digits+0x60>
    80000cea:	00000097          	auipc	ra,0x0
    80000cee:	856080e7          	jalr	-1962(ra) # 80000540 <panic>

0000000080000cf2 <pop_off>:

void
pop_off(void)
{
    80000cf2:	1141                	addi	sp,sp,-16
    80000cf4:	e406                	sd	ra,8(sp)
    80000cf6:	e022                	sd	s0,0(sp)
    80000cf8:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000cfa:	00001097          	auipc	ra,0x1
    80000cfe:	e5c080e7          	jalr	-420(ra) # 80001b56 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d02:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000d06:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000d08:	e78d                	bnez	a5,80000d32 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000d0a:	5d3c                	lw	a5,120(a0)
    80000d0c:	02f05b63          	blez	a5,80000d42 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000d10:	37fd                	addiw	a5,a5,-1
    80000d12:	0007871b          	sext.w	a4,a5
    80000d16:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000d18:	eb09                	bnez	a4,80000d2a <pop_off+0x38>
    80000d1a:	5d7c                	lw	a5,124(a0)
    80000d1c:	c799                	beqz	a5,80000d2a <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d1e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000d22:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d26:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000d2a:	60a2                	ld	ra,8(sp)
    80000d2c:	6402                	ld	s0,0(sp)
    80000d2e:	0141                	addi	sp,sp,16
    80000d30:	8082                	ret
    panic("pop_off - interruptible");
    80000d32:	00007517          	auipc	a0,0x7
    80000d36:	38650513          	addi	a0,a0,902 # 800080b8 <digits+0x68>
    80000d3a:	00000097          	auipc	ra,0x0
    80000d3e:	806080e7          	jalr	-2042(ra) # 80000540 <panic>
    panic("pop_off");
    80000d42:	00007517          	auipc	a0,0x7
    80000d46:	38e50513          	addi	a0,a0,910 # 800080d0 <digits+0x80>
    80000d4a:	fffff097          	auipc	ra,0xfffff
    80000d4e:	7f6080e7          	jalr	2038(ra) # 80000540 <panic>

0000000080000d52 <release>:
{
    80000d52:	1101                	addi	sp,sp,-32
    80000d54:	ec06                	sd	ra,24(sp)
    80000d56:	e822                	sd	s0,16(sp)
    80000d58:	e426                	sd	s1,8(sp)
    80000d5a:	1000                	addi	s0,sp,32
    80000d5c:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d5e:	00000097          	auipc	ra,0x0
    80000d62:	ec6080e7          	jalr	-314(ra) # 80000c24 <holding>
    80000d66:	c115                	beqz	a0,80000d8a <release+0x38>
  lk->cpu = 0;
    80000d68:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d6c:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d70:	0f50000f          	fence	iorw,ow
    80000d74:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d78:	00000097          	auipc	ra,0x0
    80000d7c:	f7a080e7          	jalr	-134(ra) # 80000cf2 <pop_off>
}
    80000d80:	60e2                	ld	ra,24(sp)
    80000d82:	6442                	ld	s0,16(sp)
    80000d84:	64a2                	ld	s1,8(sp)
    80000d86:	6105                	addi	sp,sp,32
    80000d88:	8082                	ret
    panic("release");
    80000d8a:	00007517          	auipc	a0,0x7
    80000d8e:	34e50513          	addi	a0,a0,846 # 800080d8 <digits+0x88>
    80000d92:	fffff097          	auipc	ra,0xfffff
    80000d96:	7ae080e7          	jalr	1966(ra) # 80000540 <panic>

0000000080000d9a <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d9a:	1141                	addi	sp,sp,-16
    80000d9c:	e422                	sd	s0,8(sp)
    80000d9e:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000da0:	ca19                	beqz	a2,80000db6 <memset+0x1c>
    80000da2:	87aa                	mv	a5,a0
    80000da4:	1602                	slli	a2,a2,0x20
    80000da6:	9201                	srli	a2,a2,0x20
    80000da8:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000dac:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000db0:	0785                	addi	a5,a5,1
    80000db2:	fee79de3          	bne	a5,a4,80000dac <memset+0x12>
  }
  return dst;
}
    80000db6:	6422                	ld	s0,8(sp)
    80000db8:	0141                	addi	sp,sp,16
    80000dba:	8082                	ret

0000000080000dbc <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000dbc:	1141                	addi	sp,sp,-16
    80000dbe:	e422                	sd	s0,8(sp)
    80000dc0:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000dc2:	ca05                	beqz	a2,80000df2 <memcmp+0x36>
    80000dc4:	fff6069b          	addiw	a3,a2,-1
    80000dc8:	1682                	slli	a3,a3,0x20
    80000dca:	9281                	srli	a3,a3,0x20
    80000dcc:	0685                	addi	a3,a3,1
    80000dce:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000dd0:	00054783          	lbu	a5,0(a0)
    80000dd4:	0005c703          	lbu	a4,0(a1)
    80000dd8:	00e79863          	bne	a5,a4,80000de8 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000ddc:	0505                	addi	a0,a0,1
    80000dde:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000de0:	fed518e3          	bne	a0,a3,80000dd0 <memcmp+0x14>
  }

  return 0;
    80000de4:	4501                	li	a0,0
    80000de6:	a019                	j	80000dec <memcmp+0x30>
      return *s1 - *s2;
    80000de8:	40e7853b          	subw	a0,a5,a4
}
    80000dec:	6422                	ld	s0,8(sp)
    80000dee:	0141                	addi	sp,sp,16
    80000df0:	8082                	ret
  return 0;
    80000df2:	4501                	li	a0,0
    80000df4:	bfe5                	j	80000dec <memcmp+0x30>

0000000080000df6 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000df6:	1141                	addi	sp,sp,-16
    80000df8:	e422                	sd	s0,8(sp)
    80000dfa:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000dfc:	c205                	beqz	a2,80000e1c <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000dfe:	02a5e263          	bltu	a1,a0,80000e22 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000e02:	1602                	slli	a2,a2,0x20
    80000e04:	9201                	srli	a2,a2,0x20
    80000e06:	00c587b3          	add	a5,a1,a2
{
    80000e0a:	872a                	mv	a4,a0
      *d++ = *s++;
    80000e0c:	0585                	addi	a1,a1,1
    80000e0e:	0705                	addi	a4,a4,1
    80000e10:	fff5c683          	lbu	a3,-1(a1)
    80000e14:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000e18:	fef59ae3          	bne	a1,a5,80000e0c <memmove+0x16>

  return dst;
}
    80000e1c:	6422                	ld	s0,8(sp)
    80000e1e:	0141                	addi	sp,sp,16
    80000e20:	8082                	ret
  if(s < d && s + n > d){
    80000e22:	02061693          	slli	a3,a2,0x20
    80000e26:	9281                	srli	a3,a3,0x20
    80000e28:	00d58733          	add	a4,a1,a3
    80000e2c:	fce57be3          	bgeu	a0,a4,80000e02 <memmove+0xc>
    d += n;
    80000e30:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000e32:	fff6079b          	addiw	a5,a2,-1
    80000e36:	1782                	slli	a5,a5,0x20
    80000e38:	9381                	srli	a5,a5,0x20
    80000e3a:	fff7c793          	not	a5,a5
    80000e3e:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000e40:	177d                	addi	a4,a4,-1
    80000e42:	16fd                	addi	a3,a3,-1
    80000e44:	00074603          	lbu	a2,0(a4)
    80000e48:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000e4c:	fee79ae3          	bne	a5,a4,80000e40 <memmove+0x4a>
    80000e50:	b7f1                	j	80000e1c <memmove+0x26>

0000000080000e52 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000e52:	1141                	addi	sp,sp,-16
    80000e54:	e406                	sd	ra,8(sp)
    80000e56:	e022                	sd	s0,0(sp)
    80000e58:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000e5a:	00000097          	auipc	ra,0x0
    80000e5e:	f9c080e7          	jalr	-100(ra) # 80000df6 <memmove>
}
    80000e62:	60a2                	ld	ra,8(sp)
    80000e64:	6402                	ld	s0,0(sp)
    80000e66:	0141                	addi	sp,sp,16
    80000e68:	8082                	ret

0000000080000e6a <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e6a:	1141                	addi	sp,sp,-16
    80000e6c:	e422                	sd	s0,8(sp)
    80000e6e:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e70:	ce11                	beqz	a2,80000e8c <strncmp+0x22>
    80000e72:	00054783          	lbu	a5,0(a0)
    80000e76:	cf89                	beqz	a5,80000e90 <strncmp+0x26>
    80000e78:	0005c703          	lbu	a4,0(a1)
    80000e7c:	00f71a63          	bne	a4,a5,80000e90 <strncmp+0x26>
    n--, p++, q++;
    80000e80:	367d                	addiw	a2,a2,-1
    80000e82:	0505                	addi	a0,a0,1
    80000e84:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e86:	f675                	bnez	a2,80000e72 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e88:	4501                	li	a0,0
    80000e8a:	a809                	j	80000e9c <strncmp+0x32>
    80000e8c:	4501                	li	a0,0
    80000e8e:	a039                	j	80000e9c <strncmp+0x32>
  if(n == 0)
    80000e90:	ca09                	beqz	a2,80000ea2 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e92:	00054503          	lbu	a0,0(a0)
    80000e96:	0005c783          	lbu	a5,0(a1)
    80000e9a:	9d1d                	subw	a0,a0,a5
}
    80000e9c:	6422                	ld	s0,8(sp)
    80000e9e:	0141                	addi	sp,sp,16
    80000ea0:	8082                	ret
    return 0;
    80000ea2:	4501                	li	a0,0
    80000ea4:	bfe5                	j	80000e9c <strncmp+0x32>

0000000080000ea6 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000ea6:	1141                	addi	sp,sp,-16
    80000ea8:	e422                	sd	s0,8(sp)
    80000eaa:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000eac:	872a                	mv	a4,a0
    80000eae:	8832                	mv	a6,a2
    80000eb0:	367d                	addiw	a2,a2,-1
    80000eb2:	01005963          	blez	a6,80000ec4 <strncpy+0x1e>
    80000eb6:	0705                	addi	a4,a4,1
    80000eb8:	0005c783          	lbu	a5,0(a1)
    80000ebc:	fef70fa3          	sb	a5,-1(a4)
    80000ec0:	0585                	addi	a1,a1,1
    80000ec2:	f7f5                	bnez	a5,80000eae <strncpy+0x8>
    ;
  while(n-- > 0)
    80000ec4:	86ba                	mv	a3,a4
    80000ec6:	00c05c63          	blez	a2,80000ede <strncpy+0x38>
    *s++ = 0;
    80000eca:	0685                	addi	a3,a3,1
    80000ecc:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000ed0:	40d707bb          	subw	a5,a4,a3
    80000ed4:	37fd                	addiw	a5,a5,-1
    80000ed6:	010787bb          	addw	a5,a5,a6
    80000eda:	fef048e3          	bgtz	a5,80000eca <strncpy+0x24>
  return os;
}
    80000ede:	6422                	ld	s0,8(sp)
    80000ee0:	0141                	addi	sp,sp,16
    80000ee2:	8082                	ret

0000000080000ee4 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000ee4:	1141                	addi	sp,sp,-16
    80000ee6:	e422                	sd	s0,8(sp)
    80000ee8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000eea:	02c05363          	blez	a2,80000f10 <safestrcpy+0x2c>
    80000eee:	fff6069b          	addiw	a3,a2,-1
    80000ef2:	1682                	slli	a3,a3,0x20
    80000ef4:	9281                	srli	a3,a3,0x20
    80000ef6:	96ae                	add	a3,a3,a1
    80000ef8:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000efa:	00d58963          	beq	a1,a3,80000f0c <safestrcpy+0x28>
    80000efe:	0585                	addi	a1,a1,1
    80000f00:	0785                	addi	a5,a5,1
    80000f02:	fff5c703          	lbu	a4,-1(a1)
    80000f06:	fee78fa3          	sb	a4,-1(a5)
    80000f0a:	fb65                	bnez	a4,80000efa <safestrcpy+0x16>
    ;
  *s = 0;
    80000f0c:	00078023          	sb	zero,0(a5)
  return os;
}
    80000f10:	6422                	ld	s0,8(sp)
    80000f12:	0141                	addi	sp,sp,16
    80000f14:	8082                	ret

0000000080000f16 <strlen>:

int
strlen(const char *s)
{
    80000f16:	1141                	addi	sp,sp,-16
    80000f18:	e422                	sd	s0,8(sp)
    80000f1a:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000f1c:	00054783          	lbu	a5,0(a0)
    80000f20:	cf91                	beqz	a5,80000f3c <strlen+0x26>
    80000f22:	0505                	addi	a0,a0,1
    80000f24:	87aa                	mv	a5,a0
    80000f26:	4685                	li	a3,1
    80000f28:	9e89                	subw	a3,a3,a0
    80000f2a:	00f6853b          	addw	a0,a3,a5
    80000f2e:	0785                	addi	a5,a5,1
    80000f30:	fff7c703          	lbu	a4,-1(a5)
    80000f34:	fb7d                	bnez	a4,80000f2a <strlen+0x14>
    ;
  return n;
}
    80000f36:	6422                	ld	s0,8(sp)
    80000f38:	0141                	addi	sp,sp,16
    80000f3a:	8082                	ret
  for(n = 0; s[n]; n++)
    80000f3c:	4501                	li	a0,0
    80000f3e:	bfe5                	j	80000f36 <strlen+0x20>

0000000080000f40 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000f40:	1141                	addi	sp,sp,-16
    80000f42:	e406                	sd	ra,8(sp)
    80000f44:	e022                	sd	s0,0(sp)
    80000f46:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000f48:	00001097          	auipc	ra,0x1
    80000f4c:	bfe080e7          	jalr	-1026(ra) # 80001b46 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f50:	00008717          	auipc	a4,0x8
    80000f54:	af870713          	addi	a4,a4,-1288 # 80008a48 <started>
  if(cpuid() == 0){
    80000f58:	c139                	beqz	a0,80000f9e <main+0x5e>
    while(started == 0)
    80000f5a:	431c                	lw	a5,0(a4)
    80000f5c:	2781                	sext.w	a5,a5
    80000f5e:	dff5                	beqz	a5,80000f5a <main+0x1a>
      ;
    __sync_synchronize();
    80000f60:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f64:	00001097          	auipc	ra,0x1
    80000f68:	be2080e7          	jalr	-1054(ra) # 80001b46 <cpuid>
    80000f6c:	85aa                	mv	a1,a0
    80000f6e:	00007517          	auipc	a0,0x7
    80000f72:	18a50513          	addi	a0,a0,394 # 800080f8 <digits+0xa8>
    80000f76:	fffff097          	auipc	ra,0xfffff
    80000f7a:	626080e7          	jalr	1574(ra) # 8000059c <printf>
    kvminithart();    // turn on paging
    80000f7e:	00000097          	auipc	ra,0x0
    80000f82:	0d8080e7          	jalr	216(ra) # 80001056 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f86:	00002097          	auipc	ra,0x2
    80000f8a:	a72080e7          	jalr	-1422(ra) # 800029f8 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f8e:	00005097          	auipc	ra,0x5
    80000f92:	132080e7          	jalr	306(ra) # 800060c0 <plicinithart>
  }

  scheduler();        
    80000f96:	00001097          	auipc	ra,0x1
    80000f9a:	268080e7          	jalr	616(ra) # 800021fe <scheduler>
    consoleinit();
    80000f9e:	fffff097          	auipc	ra,0xfffff
    80000fa2:	4b2080e7          	jalr	1202(ra) # 80000450 <consoleinit>
    printfinit();
    80000fa6:	fffff097          	auipc	ra,0xfffff
    80000faa:	7d6080e7          	jalr	2006(ra) # 8000077c <printfinit>
    printf("\n");
    80000fae:	00007517          	auipc	a0,0x7
    80000fb2:	0da50513          	addi	a0,a0,218 # 80008088 <digits+0x38>
    80000fb6:	fffff097          	auipc	ra,0xfffff
    80000fba:	5e6080e7          	jalr	1510(ra) # 8000059c <printf>
    printf("xv6 kernel is booting\n");
    80000fbe:	00007517          	auipc	a0,0x7
    80000fc2:	12250513          	addi	a0,a0,290 # 800080e0 <digits+0x90>
    80000fc6:	fffff097          	auipc	ra,0xfffff
    80000fca:	5d6080e7          	jalr	1494(ra) # 8000059c <printf>
    printf("\n");
    80000fce:	00007517          	auipc	a0,0x7
    80000fd2:	0ba50513          	addi	a0,a0,186 # 80008088 <digits+0x38>
    80000fd6:	fffff097          	auipc	ra,0xfffff
    80000fda:	5c6080e7          	jalr	1478(ra) # 8000059c <printf>
    kinit();         // physical page allocator
    80000fde:	00000097          	auipc	ra,0x0
    80000fe2:	b38080e7          	jalr	-1224(ra) # 80000b16 <kinit>
    kvminit();       // create kernel page table
    80000fe6:	00000097          	auipc	ra,0x0
    80000fea:	326080e7          	jalr	806(ra) # 8000130c <kvminit>
    kvminithart();   // turn on paging
    80000fee:	00000097          	auipc	ra,0x0
    80000ff2:	068080e7          	jalr	104(ra) # 80001056 <kvminithart>
    procinit();      // process table
    80000ff6:	00001097          	auipc	ra,0x1
    80000ffa:	a6e080e7          	jalr	-1426(ra) # 80001a64 <procinit>
    trapinit();      // trap vectors
    80000ffe:	00002097          	auipc	ra,0x2
    80001002:	9d2080e7          	jalr	-1582(ra) # 800029d0 <trapinit>
    trapinithart();  // install kernel trap vector
    80001006:	00002097          	auipc	ra,0x2
    8000100a:	9f2080e7          	jalr	-1550(ra) # 800029f8 <trapinithart>
    plicinit();      // set up interrupt controller
    8000100e:	00005097          	auipc	ra,0x5
    80001012:	09c080e7          	jalr	156(ra) # 800060aa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001016:	00005097          	auipc	ra,0x5
    8000101a:	0aa080e7          	jalr	170(ra) # 800060c0 <plicinithart>
    binit();         // buffer cache
    8000101e:	00002097          	auipc	ra,0x2
    80001022:	240080e7          	jalr	576(ra) # 8000325e <binit>
    iinit();         // inode table
    80001026:	00003097          	auipc	ra,0x3
    8000102a:	8e0080e7          	jalr	-1824(ra) # 80003906 <iinit>
    fileinit();      // file table
    8000102e:	00004097          	auipc	ra,0x4
    80001032:	886080e7          	jalr	-1914(ra) # 800048b4 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80001036:	00005097          	auipc	ra,0x5
    8000103a:	192080e7          	jalr	402(ra) # 800061c8 <virtio_disk_init>
    userinit();      // first user process
    8000103e:	00001097          	auipc	ra,0x1
    80001042:	e0c080e7          	jalr	-500(ra) # 80001e4a <userinit>
    __sync_synchronize();
    80001046:	0ff0000f          	fence
    started = 1;
    8000104a:	4785                	li	a5,1
    8000104c:	00008717          	auipc	a4,0x8
    80001050:	9ef72e23          	sw	a5,-1540(a4) # 80008a48 <started>
    80001054:	b789                	j	80000f96 <main+0x56>

0000000080001056 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80001056:	1141                	addi	sp,sp,-16
    80001058:	e422                	sd	s0,8(sp)
    8000105a:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    8000105c:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80001060:	00008797          	auipc	a5,0x8
    80001064:	9f07b783          	ld	a5,-1552(a5) # 80008a50 <kernel_pagetable>
    80001068:	83b1                	srli	a5,a5,0xc
    8000106a:	577d                	li	a4,-1
    8000106c:	177e                	slli	a4,a4,0x3f
    8000106e:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001070:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80001074:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80001078:	6422                	ld	s0,8(sp)
    8000107a:	0141                	addi	sp,sp,16
    8000107c:	8082                	ret

000000008000107e <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    8000107e:	7139                	addi	sp,sp,-64
    80001080:	fc06                	sd	ra,56(sp)
    80001082:	f822                	sd	s0,48(sp)
    80001084:	f426                	sd	s1,40(sp)
    80001086:	f04a                	sd	s2,32(sp)
    80001088:	ec4e                	sd	s3,24(sp)
    8000108a:	e852                	sd	s4,16(sp)
    8000108c:	e456                	sd	s5,8(sp)
    8000108e:	e05a                	sd	s6,0(sp)
    80001090:	0080                	addi	s0,sp,64
    80001092:	84aa                	mv	s1,a0
    80001094:	89ae                	mv	s3,a1
    80001096:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001098:	57fd                	li	a5,-1
    8000109a:	83e9                	srli	a5,a5,0x1a
    8000109c:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000109e:	4b31                	li	s6,12
  if(va >= MAXVA)
    800010a0:	04b7f263          	bgeu	a5,a1,800010e4 <walk+0x66>
    panic("walk");
    800010a4:	00007517          	auipc	a0,0x7
    800010a8:	06c50513          	addi	a0,a0,108 # 80008110 <digits+0xc0>
    800010ac:	fffff097          	auipc	ra,0xfffff
    800010b0:	494080e7          	jalr	1172(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    800010b4:	060a8663          	beqz	s5,80001120 <walk+0xa2>
    800010b8:	00000097          	auipc	ra,0x0
    800010bc:	aaa080e7          	jalr	-1366(ra) # 80000b62 <kalloc>
    800010c0:	84aa                	mv	s1,a0
    800010c2:	c529                	beqz	a0,8000110c <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800010c4:	6605                	lui	a2,0x1
    800010c6:	4581                	li	a1,0
    800010c8:	00000097          	auipc	ra,0x0
    800010cc:	cd2080e7          	jalr	-814(ra) # 80000d9a <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800010d0:	00c4d793          	srli	a5,s1,0xc
    800010d4:	07aa                	slli	a5,a5,0xa
    800010d6:	0017e793          	ori	a5,a5,1
    800010da:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800010de:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdd117>
    800010e0:	036a0063          	beq	s4,s6,80001100 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800010e4:	0149d933          	srl	s2,s3,s4
    800010e8:	1ff97913          	andi	s2,s2,511
    800010ec:	090e                	slli	s2,s2,0x3
    800010ee:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010f0:	00093483          	ld	s1,0(s2)
    800010f4:	0014f793          	andi	a5,s1,1
    800010f8:	dfd5                	beqz	a5,800010b4 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010fa:	80a9                	srli	s1,s1,0xa
    800010fc:	04b2                	slli	s1,s1,0xc
    800010fe:	b7c5                	j	800010de <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001100:	00c9d513          	srli	a0,s3,0xc
    80001104:	1ff57513          	andi	a0,a0,511
    80001108:	050e                	slli	a0,a0,0x3
    8000110a:	9526                	add	a0,a0,s1
}
    8000110c:	70e2                	ld	ra,56(sp)
    8000110e:	7442                	ld	s0,48(sp)
    80001110:	74a2                	ld	s1,40(sp)
    80001112:	7902                	ld	s2,32(sp)
    80001114:	69e2                	ld	s3,24(sp)
    80001116:	6a42                	ld	s4,16(sp)
    80001118:	6aa2                	ld	s5,8(sp)
    8000111a:	6b02                	ld	s6,0(sp)
    8000111c:	6121                	addi	sp,sp,64
    8000111e:	8082                	ret
        return 0;
    80001120:	4501                	li	a0,0
    80001122:	b7ed                	j	8000110c <walk+0x8e>

0000000080001124 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001124:	57fd                	li	a5,-1
    80001126:	83e9                	srli	a5,a5,0x1a
    80001128:	00b7f463          	bgeu	a5,a1,80001130 <walkaddr+0xc>
    return 0;
    8000112c:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000112e:	8082                	ret
{
    80001130:	1141                	addi	sp,sp,-16
    80001132:	e406                	sd	ra,8(sp)
    80001134:	e022                	sd	s0,0(sp)
    80001136:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001138:	4601                	li	a2,0
    8000113a:	00000097          	auipc	ra,0x0
    8000113e:	f44080e7          	jalr	-188(ra) # 8000107e <walk>
  if(pte == 0)
    80001142:	c105                	beqz	a0,80001162 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001144:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001146:	0117f693          	andi	a3,a5,17
    8000114a:	4745                	li	a4,17
    return 0;
    8000114c:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000114e:	00e68663          	beq	a3,a4,8000115a <walkaddr+0x36>
}
    80001152:	60a2                	ld	ra,8(sp)
    80001154:	6402                	ld	s0,0(sp)
    80001156:	0141                	addi	sp,sp,16
    80001158:	8082                	ret
  pa = PTE2PA(*pte);
    8000115a:	83a9                	srli	a5,a5,0xa
    8000115c:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001160:	bfcd                	j	80001152 <walkaddr+0x2e>
    return 0;
    80001162:	4501                	li	a0,0
    80001164:	b7fd                	j	80001152 <walkaddr+0x2e>

0000000080001166 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001166:	715d                	addi	sp,sp,-80
    80001168:	e486                	sd	ra,72(sp)
    8000116a:	e0a2                	sd	s0,64(sp)
    8000116c:	fc26                	sd	s1,56(sp)
    8000116e:	f84a                	sd	s2,48(sp)
    80001170:	f44e                	sd	s3,40(sp)
    80001172:	f052                	sd	s4,32(sp)
    80001174:	ec56                	sd	s5,24(sp)
    80001176:	e85a                	sd	s6,16(sp)
    80001178:	e45e                	sd	s7,8(sp)
    8000117a:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    8000117c:	c639                	beqz	a2,800011ca <mappages+0x64>
    8000117e:	8aaa                	mv	s5,a0
    80001180:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    80001182:	777d                	lui	a4,0xfffff
    80001184:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001188:	fff58993          	addi	s3,a1,-1
    8000118c:	99b2                	add	s3,s3,a2
    8000118e:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001192:	893e                	mv	s2,a5
    80001194:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001198:	6b85                	lui	s7,0x1
    8000119a:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000119e:	4605                	li	a2,1
    800011a0:	85ca                	mv	a1,s2
    800011a2:	8556                	mv	a0,s5
    800011a4:	00000097          	auipc	ra,0x0
    800011a8:	eda080e7          	jalr	-294(ra) # 8000107e <walk>
    800011ac:	cd1d                	beqz	a0,800011ea <mappages+0x84>
    if(*pte & PTE_V)
    800011ae:	611c                	ld	a5,0(a0)
    800011b0:	8b85                	andi	a5,a5,1
    800011b2:	e785                	bnez	a5,800011da <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800011b4:	80b1                	srli	s1,s1,0xc
    800011b6:	04aa                	slli	s1,s1,0xa
    800011b8:	0164e4b3          	or	s1,s1,s6
    800011bc:	0014e493          	ori	s1,s1,1
    800011c0:	e104                	sd	s1,0(a0)
    if(a == last)
    800011c2:	05390063          	beq	s2,s3,80001202 <mappages+0x9c>
    a += PGSIZE;
    800011c6:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800011c8:	bfc9                	j	8000119a <mappages+0x34>
    panic("mappages: size");
    800011ca:	00007517          	auipc	a0,0x7
    800011ce:	f4e50513          	addi	a0,a0,-178 # 80008118 <digits+0xc8>
    800011d2:	fffff097          	auipc	ra,0xfffff
    800011d6:	36e080e7          	jalr	878(ra) # 80000540 <panic>
      panic("mappages: remap");
    800011da:	00007517          	auipc	a0,0x7
    800011de:	f4e50513          	addi	a0,a0,-178 # 80008128 <digits+0xd8>
    800011e2:	fffff097          	auipc	ra,0xfffff
    800011e6:	35e080e7          	jalr	862(ra) # 80000540 <panic>
      return -1;
    800011ea:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800011ec:	60a6                	ld	ra,72(sp)
    800011ee:	6406                	ld	s0,64(sp)
    800011f0:	74e2                	ld	s1,56(sp)
    800011f2:	7942                	ld	s2,48(sp)
    800011f4:	79a2                	ld	s3,40(sp)
    800011f6:	7a02                	ld	s4,32(sp)
    800011f8:	6ae2                	ld	s5,24(sp)
    800011fa:	6b42                	ld	s6,16(sp)
    800011fc:	6ba2                	ld	s7,8(sp)
    800011fe:	6161                	addi	sp,sp,80
    80001200:	8082                	ret
  return 0;
    80001202:	4501                	li	a0,0
    80001204:	b7e5                	j	800011ec <mappages+0x86>

0000000080001206 <kvmmap>:
{
    80001206:	1141                	addi	sp,sp,-16
    80001208:	e406                	sd	ra,8(sp)
    8000120a:	e022                	sd	s0,0(sp)
    8000120c:	0800                	addi	s0,sp,16
    8000120e:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001210:	86b2                	mv	a3,a2
    80001212:	863e                	mv	a2,a5
    80001214:	00000097          	auipc	ra,0x0
    80001218:	f52080e7          	jalr	-174(ra) # 80001166 <mappages>
    8000121c:	e509                	bnez	a0,80001226 <kvmmap+0x20>
}
    8000121e:	60a2                	ld	ra,8(sp)
    80001220:	6402                	ld	s0,0(sp)
    80001222:	0141                	addi	sp,sp,16
    80001224:	8082                	ret
    panic("kvmmap");
    80001226:	00007517          	auipc	a0,0x7
    8000122a:	f1250513          	addi	a0,a0,-238 # 80008138 <digits+0xe8>
    8000122e:	fffff097          	auipc	ra,0xfffff
    80001232:	312080e7          	jalr	786(ra) # 80000540 <panic>

0000000080001236 <kvmmake>:
{
    80001236:	1101                	addi	sp,sp,-32
    80001238:	ec06                	sd	ra,24(sp)
    8000123a:	e822                	sd	s0,16(sp)
    8000123c:	e426                	sd	s1,8(sp)
    8000123e:	e04a                	sd	s2,0(sp)
    80001240:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001242:	00000097          	auipc	ra,0x0
    80001246:	920080e7          	jalr	-1760(ra) # 80000b62 <kalloc>
    8000124a:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000124c:	6605                	lui	a2,0x1
    8000124e:	4581                	li	a1,0
    80001250:	00000097          	auipc	ra,0x0
    80001254:	b4a080e7          	jalr	-1206(ra) # 80000d9a <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001258:	4719                	li	a4,6
    8000125a:	6685                	lui	a3,0x1
    8000125c:	10000637          	lui	a2,0x10000
    80001260:	100005b7          	lui	a1,0x10000
    80001264:	8526                	mv	a0,s1
    80001266:	00000097          	auipc	ra,0x0
    8000126a:	fa0080e7          	jalr	-96(ra) # 80001206 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000126e:	4719                	li	a4,6
    80001270:	6685                	lui	a3,0x1
    80001272:	10001637          	lui	a2,0x10001
    80001276:	100015b7          	lui	a1,0x10001
    8000127a:	8526                	mv	a0,s1
    8000127c:	00000097          	auipc	ra,0x0
    80001280:	f8a080e7          	jalr	-118(ra) # 80001206 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001284:	4719                	li	a4,6
    80001286:	004006b7          	lui	a3,0x400
    8000128a:	0c000637          	lui	a2,0xc000
    8000128e:	0c0005b7          	lui	a1,0xc000
    80001292:	8526                	mv	a0,s1
    80001294:	00000097          	auipc	ra,0x0
    80001298:	f72080e7          	jalr	-142(ra) # 80001206 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000129c:	00007917          	auipc	s2,0x7
    800012a0:	d6490913          	addi	s2,s2,-668 # 80008000 <etext>
    800012a4:	4729                	li	a4,10
    800012a6:	80007697          	auipc	a3,0x80007
    800012aa:	d5a68693          	addi	a3,a3,-678 # 8000 <_entry-0x7fff8000>
    800012ae:	4605                	li	a2,1
    800012b0:	067e                	slli	a2,a2,0x1f
    800012b2:	85b2                	mv	a1,a2
    800012b4:	8526                	mv	a0,s1
    800012b6:	00000097          	auipc	ra,0x0
    800012ba:	f50080e7          	jalr	-176(ra) # 80001206 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800012be:	4719                	li	a4,6
    800012c0:	46c5                	li	a3,17
    800012c2:	06ee                	slli	a3,a3,0x1b
    800012c4:	412686b3          	sub	a3,a3,s2
    800012c8:	864a                	mv	a2,s2
    800012ca:	85ca                	mv	a1,s2
    800012cc:	8526                	mv	a0,s1
    800012ce:	00000097          	auipc	ra,0x0
    800012d2:	f38080e7          	jalr	-200(ra) # 80001206 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800012d6:	4729                	li	a4,10
    800012d8:	6685                	lui	a3,0x1
    800012da:	00006617          	auipc	a2,0x6
    800012de:	d2660613          	addi	a2,a2,-730 # 80007000 <_trampoline>
    800012e2:	040005b7          	lui	a1,0x4000
    800012e6:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    800012e8:	05b2                	slli	a1,a1,0xc
    800012ea:	8526                	mv	a0,s1
    800012ec:	00000097          	auipc	ra,0x0
    800012f0:	f1a080e7          	jalr	-230(ra) # 80001206 <kvmmap>
  proc_mapstacks(kpgtbl);
    800012f4:	8526                	mv	a0,s1
    800012f6:	00000097          	auipc	ra,0x0
    800012fa:	6d8080e7          	jalr	1752(ra) # 800019ce <proc_mapstacks>
}
    800012fe:	8526                	mv	a0,s1
    80001300:	60e2                	ld	ra,24(sp)
    80001302:	6442                	ld	s0,16(sp)
    80001304:	64a2                	ld	s1,8(sp)
    80001306:	6902                	ld	s2,0(sp)
    80001308:	6105                	addi	sp,sp,32
    8000130a:	8082                	ret

000000008000130c <kvminit>:
{
    8000130c:	1141                	addi	sp,sp,-16
    8000130e:	e406                	sd	ra,8(sp)
    80001310:	e022                	sd	s0,0(sp)
    80001312:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001314:	00000097          	auipc	ra,0x0
    80001318:	f22080e7          	jalr	-222(ra) # 80001236 <kvmmake>
    8000131c:	00007797          	auipc	a5,0x7
    80001320:	72a7ba23          	sd	a0,1844(a5) # 80008a50 <kernel_pagetable>
}
    80001324:	60a2                	ld	ra,8(sp)
    80001326:	6402                	ld	s0,0(sp)
    80001328:	0141                	addi	sp,sp,16
    8000132a:	8082                	ret

000000008000132c <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000132c:	715d                	addi	sp,sp,-80
    8000132e:	e486                	sd	ra,72(sp)
    80001330:	e0a2                	sd	s0,64(sp)
    80001332:	fc26                	sd	s1,56(sp)
    80001334:	f84a                	sd	s2,48(sp)
    80001336:	f44e                	sd	s3,40(sp)
    80001338:	f052                	sd	s4,32(sp)
    8000133a:	ec56                	sd	s5,24(sp)
    8000133c:	e85a                	sd	s6,16(sp)
    8000133e:	e45e                	sd	s7,8(sp)
    80001340:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001342:	03459793          	slli	a5,a1,0x34
    80001346:	e795                	bnez	a5,80001372 <uvmunmap+0x46>
    80001348:	8a2a                	mv	s4,a0
    8000134a:	892e                	mv	s2,a1
    8000134c:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000134e:	0632                	slli	a2,a2,0xc
    80001350:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001354:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001356:	6b05                	lui	s6,0x1
    80001358:	0735e263          	bltu	a1,s3,800013bc <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000135c:	60a6                	ld	ra,72(sp)
    8000135e:	6406                	ld	s0,64(sp)
    80001360:	74e2                	ld	s1,56(sp)
    80001362:	7942                	ld	s2,48(sp)
    80001364:	79a2                	ld	s3,40(sp)
    80001366:	7a02                	ld	s4,32(sp)
    80001368:	6ae2                	ld	s5,24(sp)
    8000136a:	6b42                	ld	s6,16(sp)
    8000136c:	6ba2                	ld	s7,8(sp)
    8000136e:	6161                	addi	sp,sp,80
    80001370:	8082                	ret
    panic("uvmunmap: not aligned");
    80001372:	00007517          	auipc	a0,0x7
    80001376:	dce50513          	addi	a0,a0,-562 # 80008140 <digits+0xf0>
    8000137a:	fffff097          	auipc	ra,0xfffff
    8000137e:	1c6080e7          	jalr	454(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    80001382:	00007517          	auipc	a0,0x7
    80001386:	dd650513          	addi	a0,a0,-554 # 80008158 <digits+0x108>
    8000138a:	fffff097          	auipc	ra,0xfffff
    8000138e:	1b6080e7          	jalr	438(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    80001392:	00007517          	auipc	a0,0x7
    80001396:	dd650513          	addi	a0,a0,-554 # 80008168 <digits+0x118>
    8000139a:	fffff097          	auipc	ra,0xfffff
    8000139e:	1a6080e7          	jalr	422(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    800013a2:	00007517          	auipc	a0,0x7
    800013a6:	dde50513          	addi	a0,a0,-546 # 80008180 <digits+0x130>
    800013aa:	fffff097          	auipc	ra,0xfffff
    800013ae:	196080e7          	jalr	406(ra) # 80000540 <panic>
    *pte = 0;
    800013b2:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013b6:	995a                	add	s2,s2,s6
    800013b8:	fb3972e3          	bgeu	s2,s3,8000135c <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800013bc:	4601                	li	a2,0
    800013be:	85ca                	mv	a1,s2
    800013c0:	8552                	mv	a0,s4
    800013c2:	00000097          	auipc	ra,0x0
    800013c6:	cbc080e7          	jalr	-836(ra) # 8000107e <walk>
    800013ca:	84aa                	mv	s1,a0
    800013cc:	d95d                	beqz	a0,80001382 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800013ce:	6108                	ld	a0,0(a0)
    800013d0:	00157793          	andi	a5,a0,1
    800013d4:	dfdd                	beqz	a5,80001392 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800013d6:	3ff57793          	andi	a5,a0,1023
    800013da:	fd7784e3          	beq	a5,s7,800013a2 <uvmunmap+0x76>
    if(do_free){
    800013de:	fc0a8ae3          	beqz	s5,800013b2 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    800013e2:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800013e4:	0532                	slli	a0,a0,0xc
    800013e6:	fffff097          	auipc	ra,0xfffff
    800013ea:	614080e7          	jalr	1556(ra) # 800009fa <kfree>
    800013ee:	b7d1                	j	800013b2 <uvmunmap+0x86>

00000000800013f0 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013f0:	1101                	addi	sp,sp,-32
    800013f2:	ec06                	sd	ra,24(sp)
    800013f4:	e822                	sd	s0,16(sp)
    800013f6:	e426                	sd	s1,8(sp)
    800013f8:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013fa:	fffff097          	auipc	ra,0xfffff
    800013fe:	768080e7          	jalr	1896(ra) # 80000b62 <kalloc>
    80001402:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001404:	c519                	beqz	a0,80001412 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001406:	6605                	lui	a2,0x1
    80001408:	4581                	li	a1,0
    8000140a:	00000097          	auipc	ra,0x0
    8000140e:	990080e7          	jalr	-1648(ra) # 80000d9a <memset>
  return pagetable;
}
    80001412:	8526                	mv	a0,s1
    80001414:	60e2                	ld	ra,24(sp)
    80001416:	6442                	ld	s0,16(sp)
    80001418:	64a2                	ld	s1,8(sp)
    8000141a:	6105                	addi	sp,sp,32
    8000141c:	8082                	ret

000000008000141e <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    8000141e:	7179                	addi	sp,sp,-48
    80001420:	f406                	sd	ra,40(sp)
    80001422:	f022                	sd	s0,32(sp)
    80001424:	ec26                	sd	s1,24(sp)
    80001426:	e84a                	sd	s2,16(sp)
    80001428:	e44e                	sd	s3,8(sp)
    8000142a:	e052                	sd	s4,0(sp)
    8000142c:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000142e:	6785                	lui	a5,0x1
    80001430:	04f67863          	bgeu	a2,a5,80001480 <uvmfirst+0x62>
    80001434:	8a2a                	mv	s4,a0
    80001436:	89ae                	mv	s3,a1
    80001438:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    8000143a:	fffff097          	auipc	ra,0xfffff
    8000143e:	728080e7          	jalr	1832(ra) # 80000b62 <kalloc>
    80001442:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001444:	6605                	lui	a2,0x1
    80001446:	4581                	li	a1,0
    80001448:	00000097          	auipc	ra,0x0
    8000144c:	952080e7          	jalr	-1710(ra) # 80000d9a <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001450:	4779                	li	a4,30
    80001452:	86ca                	mv	a3,s2
    80001454:	6605                	lui	a2,0x1
    80001456:	4581                	li	a1,0
    80001458:	8552                	mv	a0,s4
    8000145a:	00000097          	auipc	ra,0x0
    8000145e:	d0c080e7          	jalr	-756(ra) # 80001166 <mappages>
  memmove(mem, src, sz);
    80001462:	8626                	mv	a2,s1
    80001464:	85ce                	mv	a1,s3
    80001466:	854a                	mv	a0,s2
    80001468:	00000097          	auipc	ra,0x0
    8000146c:	98e080e7          	jalr	-1650(ra) # 80000df6 <memmove>
}
    80001470:	70a2                	ld	ra,40(sp)
    80001472:	7402                	ld	s0,32(sp)
    80001474:	64e2                	ld	s1,24(sp)
    80001476:	6942                	ld	s2,16(sp)
    80001478:	69a2                	ld	s3,8(sp)
    8000147a:	6a02                	ld	s4,0(sp)
    8000147c:	6145                	addi	sp,sp,48
    8000147e:	8082                	ret
    panic("uvmfirst: more than a page");
    80001480:	00007517          	auipc	a0,0x7
    80001484:	d1850513          	addi	a0,a0,-744 # 80008198 <digits+0x148>
    80001488:	fffff097          	auipc	ra,0xfffff
    8000148c:	0b8080e7          	jalr	184(ra) # 80000540 <panic>

0000000080001490 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001490:	1101                	addi	sp,sp,-32
    80001492:	ec06                	sd	ra,24(sp)
    80001494:	e822                	sd	s0,16(sp)
    80001496:	e426                	sd	s1,8(sp)
    80001498:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000149a:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000149c:	00b67d63          	bgeu	a2,a1,800014b6 <uvmdealloc+0x26>
    800014a0:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800014a2:	6785                	lui	a5,0x1
    800014a4:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800014a6:	00f60733          	add	a4,a2,a5
    800014aa:	76fd                	lui	a3,0xfffff
    800014ac:	8f75                	and	a4,a4,a3
    800014ae:	97ae                	add	a5,a5,a1
    800014b0:	8ff5                	and	a5,a5,a3
    800014b2:	00f76863          	bltu	a4,a5,800014c2 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014b6:	8526                	mv	a0,s1
    800014b8:	60e2                	ld	ra,24(sp)
    800014ba:	6442                	ld	s0,16(sp)
    800014bc:	64a2                	ld	s1,8(sp)
    800014be:	6105                	addi	sp,sp,32
    800014c0:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800014c2:	8f99                	sub	a5,a5,a4
    800014c4:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800014c6:	4685                	li	a3,1
    800014c8:	0007861b          	sext.w	a2,a5
    800014cc:	85ba                	mv	a1,a4
    800014ce:	00000097          	auipc	ra,0x0
    800014d2:	e5e080e7          	jalr	-418(ra) # 8000132c <uvmunmap>
    800014d6:	b7c5                	j	800014b6 <uvmdealloc+0x26>

00000000800014d8 <uvmalloc>:
  if(newsz < oldsz)
    800014d8:	0ab66563          	bltu	a2,a1,80001582 <uvmalloc+0xaa>
{
    800014dc:	7139                	addi	sp,sp,-64
    800014de:	fc06                	sd	ra,56(sp)
    800014e0:	f822                	sd	s0,48(sp)
    800014e2:	f426                	sd	s1,40(sp)
    800014e4:	f04a                	sd	s2,32(sp)
    800014e6:	ec4e                	sd	s3,24(sp)
    800014e8:	e852                	sd	s4,16(sp)
    800014ea:	e456                	sd	s5,8(sp)
    800014ec:	e05a                	sd	s6,0(sp)
    800014ee:	0080                	addi	s0,sp,64
    800014f0:	8aaa                	mv	s5,a0
    800014f2:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800014f4:	6785                	lui	a5,0x1
    800014f6:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800014f8:	95be                	add	a1,a1,a5
    800014fa:	77fd                	lui	a5,0xfffff
    800014fc:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001500:	08c9f363          	bgeu	s3,a2,80001586 <uvmalloc+0xae>
    80001504:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001506:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    8000150a:	fffff097          	auipc	ra,0xfffff
    8000150e:	658080e7          	jalr	1624(ra) # 80000b62 <kalloc>
    80001512:	84aa                	mv	s1,a0
    if(mem == 0){
    80001514:	c51d                	beqz	a0,80001542 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    80001516:	6605                	lui	a2,0x1
    80001518:	4581                	li	a1,0
    8000151a:	00000097          	auipc	ra,0x0
    8000151e:	880080e7          	jalr	-1920(ra) # 80000d9a <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001522:	875a                	mv	a4,s6
    80001524:	86a6                	mv	a3,s1
    80001526:	6605                	lui	a2,0x1
    80001528:	85ca                	mv	a1,s2
    8000152a:	8556                	mv	a0,s5
    8000152c:	00000097          	auipc	ra,0x0
    80001530:	c3a080e7          	jalr	-966(ra) # 80001166 <mappages>
    80001534:	e90d                	bnez	a0,80001566 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001536:	6785                	lui	a5,0x1
    80001538:	993e                	add	s2,s2,a5
    8000153a:	fd4968e3          	bltu	s2,s4,8000150a <uvmalloc+0x32>
  return newsz;
    8000153e:	8552                	mv	a0,s4
    80001540:	a809                	j	80001552 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001542:	864e                	mv	a2,s3
    80001544:	85ca                	mv	a1,s2
    80001546:	8556                	mv	a0,s5
    80001548:	00000097          	auipc	ra,0x0
    8000154c:	f48080e7          	jalr	-184(ra) # 80001490 <uvmdealloc>
      return 0;
    80001550:	4501                	li	a0,0
}
    80001552:	70e2                	ld	ra,56(sp)
    80001554:	7442                	ld	s0,48(sp)
    80001556:	74a2                	ld	s1,40(sp)
    80001558:	7902                	ld	s2,32(sp)
    8000155a:	69e2                	ld	s3,24(sp)
    8000155c:	6a42                	ld	s4,16(sp)
    8000155e:	6aa2                	ld	s5,8(sp)
    80001560:	6b02                	ld	s6,0(sp)
    80001562:	6121                	addi	sp,sp,64
    80001564:	8082                	ret
      kfree(mem);
    80001566:	8526                	mv	a0,s1
    80001568:	fffff097          	auipc	ra,0xfffff
    8000156c:	492080e7          	jalr	1170(ra) # 800009fa <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001570:	864e                	mv	a2,s3
    80001572:	85ca                	mv	a1,s2
    80001574:	8556                	mv	a0,s5
    80001576:	00000097          	auipc	ra,0x0
    8000157a:	f1a080e7          	jalr	-230(ra) # 80001490 <uvmdealloc>
      return 0;
    8000157e:	4501                	li	a0,0
    80001580:	bfc9                	j	80001552 <uvmalloc+0x7a>
    return oldsz;
    80001582:	852e                	mv	a0,a1
}
    80001584:	8082                	ret
  return newsz;
    80001586:	8532                	mv	a0,a2
    80001588:	b7e9                	j	80001552 <uvmalloc+0x7a>

000000008000158a <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000158a:	7179                	addi	sp,sp,-48
    8000158c:	f406                	sd	ra,40(sp)
    8000158e:	f022                	sd	s0,32(sp)
    80001590:	ec26                	sd	s1,24(sp)
    80001592:	e84a                	sd	s2,16(sp)
    80001594:	e44e                	sd	s3,8(sp)
    80001596:	e052                	sd	s4,0(sp)
    80001598:	1800                	addi	s0,sp,48
    8000159a:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000159c:	84aa                	mv	s1,a0
    8000159e:	6905                	lui	s2,0x1
    800015a0:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015a2:	4985                	li	s3,1
    800015a4:	a829                	j	800015be <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800015a6:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800015a8:	00c79513          	slli	a0,a5,0xc
    800015ac:	00000097          	auipc	ra,0x0
    800015b0:	fde080e7          	jalr	-34(ra) # 8000158a <freewalk>
      pagetable[i] = 0;
    800015b4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800015b8:	04a1                	addi	s1,s1,8
    800015ba:	03248163          	beq	s1,s2,800015dc <freewalk+0x52>
    pte_t pte = pagetable[i];
    800015be:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015c0:	00f7f713          	andi	a4,a5,15
    800015c4:	ff3701e3          	beq	a4,s3,800015a6 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800015c8:	8b85                	andi	a5,a5,1
    800015ca:	d7fd                	beqz	a5,800015b8 <freewalk+0x2e>
      panic("freewalk: leaf");
    800015cc:	00007517          	auipc	a0,0x7
    800015d0:	bec50513          	addi	a0,a0,-1044 # 800081b8 <digits+0x168>
    800015d4:	fffff097          	auipc	ra,0xfffff
    800015d8:	f6c080e7          	jalr	-148(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    800015dc:	8552                	mv	a0,s4
    800015de:	fffff097          	auipc	ra,0xfffff
    800015e2:	41c080e7          	jalr	1052(ra) # 800009fa <kfree>
}
    800015e6:	70a2                	ld	ra,40(sp)
    800015e8:	7402                	ld	s0,32(sp)
    800015ea:	64e2                	ld	s1,24(sp)
    800015ec:	6942                	ld	s2,16(sp)
    800015ee:	69a2                	ld	s3,8(sp)
    800015f0:	6a02                	ld	s4,0(sp)
    800015f2:	6145                	addi	sp,sp,48
    800015f4:	8082                	ret

00000000800015f6 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800015f6:	1101                	addi	sp,sp,-32
    800015f8:	ec06                	sd	ra,24(sp)
    800015fa:	e822                	sd	s0,16(sp)
    800015fc:	e426                	sd	s1,8(sp)
    800015fe:	1000                	addi	s0,sp,32
    80001600:	84aa                	mv	s1,a0
  if(sz > 0)
    80001602:	e999                	bnez	a1,80001618 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001604:	8526                	mv	a0,s1
    80001606:	00000097          	auipc	ra,0x0
    8000160a:	f84080e7          	jalr	-124(ra) # 8000158a <freewalk>
}
    8000160e:	60e2                	ld	ra,24(sp)
    80001610:	6442                	ld	s0,16(sp)
    80001612:	64a2                	ld	s1,8(sp)
    80001614:	6105                	addi	sp,sp,32
    80001616:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001618:	6785                	lui	a5,0x1
    8000161a:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000161c:	95be                	add	a1,a1,a5
    8000161e:	4685                	li	a3,1
    80001620:	00c5d613          	srli	a2,a1,0xc
    80001624:	4581                	li	a1,0
    80001626:	00000097          	auipc	ra,0x0
    8000162a:	d06080e7          	jalr	-762(ra) # 8000132c <uvmunmap>
    8000162e:	bfd9                	j	80001604 <uvmfree+0xe>

0000000080001630 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001630:	c679                	beqz	a2,800016fe <uvmcopy+0xce>
{
    80001632:	715d                	addi	sp,sp,-80
    80001634:	e486                	sd	ra,72(sp)
    80001636:	e0a2                	sd	s0,64(sp)
    80001638:	fc26                	sd	s1,56(sp)
    8000163a:	f84a                	sd	s2,48(sp)
    8000163c:	f44e                	sd	s3,40(sp)
    8000163e:	f052                	sd	s4,32(sp)
    80001640:	ec56                	sd	s5,24(sp)
    80001642:	e85a                	sd	s6,16(sp)
    80001644:	e45e                	sd	s7,8(sp)
    80001646:	0880                	addi	s0,sp,80
    80001648:	8b2a                	mv	s6,a0
    8000164a:	8aae                	mv	s5,a1
    8000164c:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000164e:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001650:	4601                	li	a2,0
    80001652:	85ce                	mv	a1,s3
    80001654:	855a                	mv	a0,s6
    80001656:	00000097          	auipc	ra,0x0
    8000165a:	a28080e7          	jalr	-1496(ra) # 8000107e <walk>
    8000165e:	c531                	beqz	a0,800016aa <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001660:	6118                	ld	a4,0(a0)
    80001662:	00177793          	andi	a5,a4,1
    80001666:	cbb1                	beqz	a5,800016ba <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001668:	00a75593          	srli	a1,a4,0xa
    8000166c:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001670:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001674:	fffff097          	auipc	ra,0xfffff
    80001678:	4ee080e7          	jalr	1262(ra) # 80000b62 <kalloc>
    8000167c:	892a                	mv	s2,a0
    8000167e:	c939                	beqz	a0,800016d4 <uvmcopy+0xa4>
      goto err;
      
    memmove(mem, (char*)pa, PGSIZE);
    80001680:	6605                	lui	a2,0x1
    80001682:	85de                	mv	a1,s7
    80001684:	fffff097          	auipc	ra,0xfffff
    80001688:	772080e7          	jalr	1906(ra) # 80000df6 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000168c:	8726                	mv	a4,s1
    8000168e:	86ca                	mv	a3,s2
    80001690:	6605                	lui	a2,0x1
    80001692:	85ce                	mv	a1,s3
    80001694:	8556                	mv	a0,s5
    80001696:	00000097          	auipc	ra,0x0
    8000169a:	ad0080e7          	jalr	-1328(ra) # 80001166 <mappages>
    8000169e:	e515                	bnez	a0,800016ca <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800016a0:	6785                	lui	a5,0x1
    800016a2:	99be                	add	s3,s3,a5
    800016a4:	fb49e6e3          	bltu	s3,s4,80001650 <uvmcopy+0x20>
    800016a8:	a081                	j	800016e8 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800016aa:	00007517          	auipc	a0,0x7
    800016ae:	b1e50513          	addi	a0,a0,-1250 # 800081c8 <digits+0x178>
    800016b2:	fffff097          	auipc	ra,0xfffff
    800016b6:	e8e080e7          	jalr	-370(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    800016ba:	00007517          	auipc	a0,0x7
    800016be:	b2e50513          	addi	a0,a0,-1234 # 800081e8 <digits+0x198>
    800016c2:	fffff097          	auipc	ra,0xfffff
    800016c6:	e7e080e7          	jalr	-386(ra) # 80000540 <panic>
      kfree(mem);
    800016ca:	854a                	mv	a0,s2
    800016cc:	fffff097          	auipc	ra,0xfffff
    800016d0:	32e080e7          	jalr	814(ra) # 800009fa <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800016d4:	4685                	li	a3,1
    800016d6:	00c9d613          	srli	a2,s3,0xc
    800016da:	4581                	li	a1,0
    800016dc:	8556                	mv	a0,s5
    800016de:	00000097          	auipc	ra,0x0
    800016e2:	c4e080e7          	jalr	-946(ra) # 8000132c <uvmunmap>
  return -1;
    800016e6:	557d                	li	a0,-1
}
    800016e8:	60a6                	ld	ra,72(sp)
    800016ea:	6406                	ld	s0,64(sp)
    800016ec:	74e2                	ld	s1,56(sp)
    800016ee:	7942                	ld	s2,48(sp)
    800016f0:	79a2                	ld	s3,40(sp)
    800016f2:	7a02                	ld	s4,32(sp)
    800016f4:	6ae2                	ld	s5,24(sp)
    800016f6:	6b42                	ld	s6,16(sp)
    800016f8:	6ba2                	ld	s7,8(sp)
    800016fa:	6161                	addi	sp,sp,80
    800016fc:	8082                	ret
  return 0;
    800016fe:	4501                	li	a0,0
}
    80001700:	8082                	ret

0000000080001702 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001702:	1141                	addi	sp,sp,-16
    80001704:	e406                	sd	ra,8(sp)
    80001706:	e022                	sd	s0,0(sp)
    80001708:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000170a:	4601                	li	a2,0
    8000170c:	00000097          	auipc	ra,0x0
    80001710:	972080e7          	jalr	-1678(ra) # 8000107e <walk>
  if(pte == 0)
    80001714:	c901                	beqz	a0,80001724 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001716:	611c                	ld	a5,0(a0)
    80001718:	9bbd                	andi	a5,a5,-17
    8000171a:	e11c                	sd	a5,0(a0)
}
    8000171c:	60a2                	ld	ra,8(sp)
    8000171e:	6402                	ld	s0,0(sp)
    80001720:	0141                	addi	sp,sp,16
    80001722:	8082                	ret
    panic("uvmclear");
    80001724:	00007517          	auipc	a0,0x7
    80001728:	ae450513          	addi	a0,a0,-1308 # 80008208 <digits+0x1b8>
    8000172c:	fffff097          	auipc	ra,0xfffff
    80001730:	e14080e7          	jalr	-492(ra) # 80000540 <panic>

0000000080001734 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001734:	c6bd                	beqz	a3,800017a2 <copyout+0x6e>
{
    80001736:	715d                	addi	sp,sp,-80
    80001738:	e486                	sd	ra,72(sp)
    8000173a:	e0a2                	sd	s0,64(sp)
    8000173c:	fc26                	sd	s1,56(sp)
    8000173e:	f84a                	sd	s2,48(sp)
    80001740:	f44e                	sd	s3,40(sp)
    80001742:	f052                	sd	s4,32(sp)
    80001744:	ec56                	sd	s5,24(sp)
    80001746:	e85a                	sd	s6,16(sp)
    80001748:	e45e                	sd	s7,8(sp)
    8000174a:	e062                	sd	s8,0(sp)
    8000174c:	0880                	addi	s0,sp,80
    8000174e:	8b2a                	mv	s6,a0
    80001750:	8c2e                	mv	s8,a1
    80001752:	8a32                	mv	s4,a2
    80001754:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001756:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001758:	6a85                	lui	s5,0x1
    8000175a:	a015                	j	8000177e <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000175c:	9562                	add	a0,a0,s8
    8000175e:	0004861b          	sext.w	a2,s1
    80001762:	85d2                	mv	a1,s4
    80001764:	41250533          	sub	a0,a0,s2
    80001768:	fffff097          	auipc	ra,0xfffff
    8000176c:	68e080e7          	jalr	1678(ra) # 80000df6 <memmove>

    len -= n;
    80001770:	409989b3          	sub	s3,s3,s1
    src += n;
    80001774:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001776:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000177a:	02098263          	beqz	s3,8000179e <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    8000177e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001782:	85ca                	mv	a1,s2
    80001784:	855a                	mv	a0,s6
    80001786:	00000097          	auipc	ra,0x0
    8000178a:	99e080e7          	jalr	-1634(ra) # 80001124 <walkaddr>
    if(pa0 == 0)
    8000178e:	cd01                	beqz	a0,800017a6 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001790:	418904b3          	sub	s1,s2,s8
    80001794:	94d6                	add	s1,s1,s5
    80001796:	fc99f3e3          	bgeu	s3,s1,8000175c <copyout+0x28>
    8000179a:	84ce                	mv	s1,s3
    8000179c:	b7c1                	j	8000175c <copyout+0x28>
  }
  return 0;
    8000179e:	4501                	li	a0,0
    800017a0:	a021                	j	800017a8 <copyout+0x74>
    800017a2:	4501                	li	a0,0
}
    800017a4:	8082                	ret
      return -1;
    800017a6:	557d                	li	a0,-1
}
    800017a8:	60a6                	ld	ra,72(sp)
    800017aa:	6406                	ld	s0,64(sp)
    800017ac:	74e2                	ld	s1,56(sp)
    800017ae:	7942                	ld	s2,48(sp)
    800017b0:	79a2                	ld	s3,40(sp)
    800017b2:	7a02                	ld	s4,32(sp)
    800017b4:	6ae2                	ld	s5,24(sp)
    800017b6:	6b42                	ld	s6,16(sp)
    800017b8:	6ba2                	ld	s7,8(sp)
    800017ba:	6c02                	ld	s8,0(sp)
    800017bc:	6161                	addi	sp,sp,80
    800017be:	8082                	ret

00000000800017c0 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017c0:	caa5                	beqz	a3,80001830 <copyin+0x70>
{
    800017c2:	715d                	addi	sp,sp,-80
    800017c4:	e486                	sd	ra,72(sp)
    800017c6:	e0a2                	sd	s0,64(sp)
    800017c8:	fc26                	sd	s1,56(sp)
    800017ca:	f84a                	sd	s2,48(sp)
    800017cc:	f44e                	sd	s3,40(sp)
    800017ce:	f052                	sd	s4,32(sp)
    800017d0:	ec56                	sd	s5,24(sp)
    800017d2:	e85a                	sd	s6,16(sp)
    800017d4:	e45e                	sd	s7,8(sp)
    800017d6:	e062                	sd	s8,0(sp)
    800017d8:	0880                	addi	s0,sp,80
    800017da:	8b2a                	mv	s6,a0
    800017dc:	8a2e                	mv	s4,a1
    800017de:	8c32                	mv	s8,a2
    800017e0:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800017e2:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017e4:	6a85                	lui	s5,0x1
    800017e6:	a01d                	j	8000180c <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800017e8:	018505b3          	add	a1,a0,s8
    800017ec:	0004861b          	sext.w	a2,s1
    800017f0:	412585b3          	sub	a1,a1,s2
    800017f4:	8552                	mv	a0,s4
    800017f6:	fffff097          	auipc	ra,0xfffff
    800017fa:	600080e7          	jalr	1536(ra) # 80000df6 <memmove>

    len -= n;
    800017fe:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001802:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001804:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001808:	02098263          	beqz	s3,8000182c <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000180c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001810:	85ca                	mv	a1,s2
    80001812:	855a                	mv	a0,s6
    80001814:	00000097          	auipc	ra,0x0
    80001818:	910080e7          	jalr	-1776(ra) # 80001124 <walkaddr>
    if(pa0 == 0)
    8000181c:	cd01                	beqz	a0,80001834 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    8000181e:	418904b3          	sub	s1,s2,s8
    80001822:	94d6                	add	s1,s1,s5
    80001824:	fc99f2e3          	bgeu	s3,s1,800017e8 <copyin+0x28>
    80001828:	84ce                	mv	s1,s3
    8000182a:	bf7d                	j	800017e8 <copyin+0x28>
  }
  return 0;
    8000182c:	4501                	li	a0,0
    8000182e:	a021                	j	80001836 <copyin+0x76>
    80001830:	4501                	li	a0,0
}
    80001832:	8082                	ret
      return -1;
    80001834:	557d                	li	a0,-1
}
    80001836:	60a6                	ld	ra,72(sp)
    80001838:	6406                	ld	s0,64(sp)
    8000183a:	74e2                	ld	s1,56(sp)
    8000183c:	7942                	ld	s2,48(sp)
    8000183e:	79a2                	ld	s3,40(sp)
    80001840:	7a02                	ld	s4,32(sp)
    80001842:	6ae2                	ld	s5,24(sp)
    80001844:	6b42                	ld	s6,16(sp)
    80001846:	6ba2                	ld	s7,8(sp)
    80001848:	6c02                	ld	s8,0(sp)
    8000184a:	6161                	addi	sp,sp,80
    8000184c:	8082                	ret

000000008000184e <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000184e:	c2dd                	beqz	a3,800018f4 <copyinstr+0xa6>
{
    80001850:	715d                	addi	sp,sp,-80
    80001852:	e486                	sd	ra,72(sp)
    80001854:	e0a2                	sd	s0,64(sp)
    80001856:	fc26                	sd	s1,56(sp)
    80001858:	f84a                	sd	s2,48(sp)
    8000185a:	f44e                	sd	s3,40(sp)
    8000185c:	f052                	sd	s4,32(sp)
    8000185e:	ec56                	sd	s5,24(sp)
    80001860:	e85a                	sd	s6,16(sp)
    80001862:	e45e                	sd	s7,8(sp)
    80001864:	0880                	addi	s0,sp,80
    80001866:	8a2a                	mv	s4,a0
    80001868:	8b2e                	mv	s6,a1
    8000186a:	8bb2                	mv	s7,a2
    8000186c:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000186e:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001870:	6985                	lui	s3,0x1
    80001872:	a02d                	j	8000189c <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001874:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001878:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    8000187a:	37fd                	addiw	a5,a5,-1
    8000187c:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001880:	60a6                	ld	ra,72(sp)
    80001882:	6406                	ld	s0,64(sp)
    80001884:	74e2                	ld	s1,56(sp)
    80001886:	7942                	ld	s2,48(sp)
    80001888:	79a2                	ld	s3,40(sp)
    8000188a:	7a02                	ld	s4,32(sp)
    8000188c:	6ae2                	ld	s5,24(sp)
    8000188e:	6b42                	ld	s6,16(sp)
    80001890:	6ba2                	ld	s7,8(sp)
    80001892:	6161                	addi	sp,sp,80
    80001894:	8082                	ret
    srcva = va0 + PGSIZE;
    80001896:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    8000189a:	c8a9                	beqz	s1,800018ec <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    8000189c:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800018a0:	85ca                	mv	a1,s2
    800018a2:	8552                	mv	a0,s4
    800018a4:	00000097          	auipc	ra,0x0
    800018a8:	880080e7          	jalr	-1920(ra) # 80001124 <walkaddr>
    if(pa0 == 0)
    800018ac:	c131                	beqz	a0,800018f0 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800018ae:	417906b3          	sub	a3,s2,s7
    800018b2:	96ce                	add	a3,a3,s3
    800018b4:	00d4f363          	bgeu	s1,a3,800018ba <copyinstr+0x6c>
    800018b8:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800018ba:	955e                	add	a0,a0,s7
    800018bc:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800018c0:	daf9                	beqz	a3,80001896 <copyinstr+0x48>
    800018c2:	87da                	mv	a5,s6
      if(*p == '\0'){
    800018c4:	41650633          	sub	a2,a0,s6
    800018c8:	fff48593          	addi	a1,s1,-1
    800018cc:	95da                	add	a1,a1,s6
    while(n > 0){
    800018ce:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    800018d0:	00f60733          	add	a4,a2,a5
    800018d4:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdd120>
    800018d8:	df51                	beqz	a4,80001874 <copyinstr+0x26>
        *dst = *p;
    800018da:	00e78023          	sb	a4,0(a5)
      --max;
    800018de:	40f584b3          	sub	s1,a1,a5
      dst++;
    800018e2:	0785                	addi	a5,a5,1
    while(n > 0){
    800018e4:	fed796e3          	bne	a5,a3,800018d0 <copyinstr+0x82>
      dst++;
    800018e8:	8b3e                	mv	s6,a5
    800018ea:	b775                	j	80001896 <copyinstr+0x48>
    800018ec:	4781                	li	a5,0
    800018ee:	b771                	j	8000187a <copyinstr+0x2c>
      return -1;
    800018f0:	557d                	li	a0,-1
    800018f2:	b779                	j	80001880 <copyinstr+0x32>
  int got_null = 0;
    800018f4:	4781                	li	a5,0
  if(got_null){
    800018f6:	37fd                	addiw	a5,a5,-1
    800018f8:	0007851b          	sext.w	a0,a5
}
    800018fc:	8082                	ret

00000000800018fe <rr_scheduler>:
        (*sched_pointer)();
    }
}

void rr_scheduler(void)
{
    800018fe:	715d                	addi	sp,sp,-80
    80001900:	e486                	sd	ra,72(sp)
    80001902:	e0a2                	sd	s0,64(sp)
    80001904:	fc26                	sd	s1,56(sp)
    80001906:	f84a                	sd	s2,48(sp)
    80001908:	f44e                	sd	s3,40(sp)
    8000190a:	f052                	sd	s4,32(sp)
    8000190c:	ec56                	sd	s5,24(sp)
    8000190e:	e85a                	sd	s6,16(sp)
    80001910:	e45e                	sd	s7,8(sp)
    80001912:	e062                	sd	s8,0(sp)
    80001914:	0880                	addi	s0,sp,80
  asm volatile("mv %0, tp" : "=r" (x) );
    80001916:	8792                	mv	a5,tp
    int id = r_tp();
    80001918:	2781                	sext.w	a5,a5
    struct proc *p;
    struct cpu *c = mycpu();

    c->proc = 0;
    8000191a:	0000fa97          	auipc	s5,0xf
    8000191e:	3b6a8a93          	addi	s5,s5,950 # 80010cd0 <cpus>
    80001922:	00779713          	slli	a4,a5,0x7
    80001926:	00ea86b3          	add	a3,s5,a4
    8000192a:	0006b023          	sd	zero,0(a3) # fffffffffffff000 <end+0xffffffff7ffdd120>
                // Switch to chosen process.  It is the process's job
                // to release its lock and then reacquire it
                // before jumping back to us.
                p->state = RUNNING;
                c->proc = p;
                swtch(&c->context, &p->context);
    8000192e:	0721                	addi	a4,a4,8
    80001930:	9aba                	add	s5,s5,a4
                c->proc = p;
    80001932:	8936                	mv	s2,a3
                // check if we are still the right scheduler (or if schedset changed)
                if (sched_pointer != &rr_scheduler)
    80001934:	00007c17          	auipc	s8,0x7
    80001938:	054c0c13          	addi	s8,s8,84 # 80008988 <sched_pointer>
    8000193c:	00000b97          	auipc	s7,0x0
    80001940:	fc2b8b93          	addi	s7,s7,-62 # 800018fe <rr_scheduler>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001944:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001948:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000194c:	10079073          	csrw	sstatus,a5
        for (p = proc; p < &proc[NPROC]; p++)
    80001950:	0000f497          	auipc	s1,0xf
    80001954:	7b048493          	addi	s1,s1,1968 # 80011100 <proc>
            if (p->state == RUNNABLE)
    80001958:	498d                	li	s3,3
                p->state = RUNNING;
    8000195a:	4b11                	li	s6,4
        for (p = proc; p < &proc[NPROC]; p++)
    8000195c:	00015a17          	auipc	s4,0x15
    80001960:	1a4a0a13          	addi	s4,s4,420 # 80016b00 <tickslock>
    80001964:	a81d                	j	8000199a <rr_scheduler+0x9c>
                {
                    release(&p->lock);
    80001966:	8526                	mv	a0,s1
    80001968:	fffff097          	auipc	ra,0xfffff
    8000196c:	3ea080e7          	jalr	1002(ra) # 80000d52 <release>
                c->proc = 0;
            }
            release(&p->lock);
        }
    }
}
    80001970:	60a6                	ld	ra,72(sp)
    80001972:	6406                	ld	s0,64(sp)
    80001974:	74e2                	ld	s1,56(sp)
    80001976:	7942                	ld	s2,48(sp)
    80001978:	79a2                	ld	s3,40(sp)
    8000197a:	7a02                	ld	s4,32(sp)
    8000197c:	6ae2                	ld	s5,24(sp)
    8000197e:	6b42                	ld	s6,16(sp)
    80001980:	6ba2                	ld	s7,8(sp)
    80001982:	6c02                	ld	s8,0(sp)
    80001984:	6161                	addi	sp,sp,80
    80001986:	8082                	ret
            release(&p->lock);
    80001988:	8526                	mv	a0,s1
    8000198a:	fffff097          	auipc	ra,0xfffff
    8000198e:	3c8080e7          	jalr	968(ra) # 80000d52 <release>
        for (p = proc; p < &proc[NPROC]; p++)
    80001992:	16848493          	addi	s1,s1,360
    80001996:	fb4487e3          	beq	s1,s4,80001944 <rr_scheduler+0x46>
            acquire(&p->lock);
    8000199a:	8526                	mv	a0,s1
    8000199c:	fffff097          	auipc	ra,0xfffff
    800019a0:	302080e7          	jalr	770(ra) # 80000c9e <acquire>
            if (p->state == RUNNABLE)
    800019a4:	4c9c                	lw	a5,24(s1)
    800019a6:	ff3791e3          	bne	a5,s3,80001988 <rr_scheduler+0x8a>
                p->state = RUNNING;
    800019aa:	0164ac23          	sw	s6,24(s1)
                c->proc = p;
    800019ae:	00993023          	sd	s1,0(s2) # 1000 <_entry-0x7ffff000>
                swtch(&c->context, &p->context);
    800019b2:	06048593          	addi	a1,s1,96
    800019b6:	8556                	mv	a0,s5
    800019b8:	00001097          	auipc	ra,0x1
    800019bc:	fae080e7          	jalr	-82(ra) # 80002966 <swtch>
                if (sched_pointer != &rr_scheduler)
    800019c0:	000c3783          	ld	a5,0(s8)
    800019c4:	fb7791e3          	bne	a5,s7,80001966 <rr_scheduler+0x68>
                c->proc = 0;
    800019c8:	00093023          	sd	zero,0(s2)
    800019cc:	bf75                	j	80001988 <rr_scheduler+0x8a>

00000000800019ce <proc_mapstacks>:
{
    800019ce:	7139                	addi	sp,sp,-64
    800019d0:	fc06                	sd	ra,56(sp)
    800019d2:	f822                	sd	s0,48(sp)
    800019d4:	f426                	sd	s1,40(sp)
    800019d6:	f04a                	sd	s2,32(sp)
    800019d8:	ec4e                	sd	s3,24(sp)
    800019da:	e852                	sd	s4,16(sp)
    800019dc:	e456                	sd	s5,8(sp)
    800019de:	e05a                	sd	s6,0(sp)
    800019e0:	0080                	addi	s0,sp,64
    800019e2:	89aa                	mv	s3,a0
    for (p = proc; p < &proc[NPROC]; p++)
    800019e4:	0000f497          	auipc	s1,0xf
    800019e8:	71c48493          	addi	s1,s1,1820 # 80011100 <proc>
        uint64 va = KSTACK((int)(p - proc));
    800019ec:	8b26                	mv	s6,s1
    800019ee:	00006a97          	auipc	s5,0x6
    800019f2:	622a8a93          	addi	s5,s5,1570 # 80008010 <__func__.1+0x8>
    800019f6:	04000937          	lui	s2,0x4000
    800019fa:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    800019fc:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    800019fe:	00015a17          	auipc	s4,0x15
    80001a02:	102a0a13          	addi	s4,s4,258 # 80016b00 <tickslock>
        char *pa = kalloc();
    80001a06:	fffff097          	auipc	ra,0xfffff
    80001a0a:	15c080e7          	jalr	348(ra) # 80000b62 <kalloc>
    80001a0e:	862a                	mv	a2,a0
        if (pa == 0)
    80001a10:	c131                	beqz	a0,80001a54 <proc_mapstacks+0x86>
        uint64 va = KSTACK((int)(p - proc));
    80001a12:	416485b3          	sub	a1,s1,s6
    80001a16:	858d                	srai	a1,a1,0x3
    80001a18:	000ab783          	ld	a5,0(s5)
    80001a1c:	02f585b3          	mul	a1,a1,a5
    80001a20:	2585                	addiw	a1,a1,1
    80001a22:	00d5959b          	slliw	a1,a1,0xd
        kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001a26:	4719                	li	a4,6
    80001a28:	6685                	lui	a3,0x1
    80001a2a:	40b905b3          	sub	a1,s2,a1
    80001a2e:	854e                	mv	a0,s3
    80001a30:	fffff097          	auipc	ra,0xfffff
    80001a34:	7d6080e7          	jalr	2006(ra) # 80001206 <kvmmap>
    for (p = proc; p < &proc[NPROC]; p++)
    80001a38:	16848493          	addi	s1,s1,360
    80001a3c:	fd4495e3          	bne	s1,s4,80001a06 <proc_mapstacks+0x38>
}
    80001a40:	70e2                	ld	ra,56(sp)
    80001a42:	7442                	ld	s0,48(sp)
    80001a44:	74a2                	ld	s1,40(sp)
    80001a46:	7902                	ld	s2,32(sp)
    80001a48:	69e2                	ld	s3,24(sp)
    80001a4a:	6a42                	ld	s4,16(sp)
    80001a4c:	6aa2                	ld	s5,8(sp)
    80001a4e:	6b02                	ld	s6,0(sp)
    80001a50:	6121                	addi	sp,sp,64
    80001a52:	8082                	ret
            panic("kalloc");
    80001a54:	00006517          	auipc	a0,0x6
    80001a58:	7c450513          	addi	a0,a0,1988 # 80008218 <digits+0x1c8>
    80001a5c:	fffff097          	auipc	ra,0xfffff
    80001a60:	ae4080e7          	jalr	-1308(ra) # 80000540 <panic>

0000000080001a64 <procinit>:
{
    80001a64:	7139                	addi	sp,sp,-64
    80001a66:	fc06                	sd	ra,56(sp)
    80001a68:	f822                	sd	s0,48(sp)
    80001a6a:	f426                	sd	s1,40(sp)
    80001a6c:	f04a                	sd	s2,32(sp)
    80001a6e:	ec4e                	sd	s3,24(sp)
    80001a70:	e852                	sd	s4,16(sp)
    80001a72:	e456                	sd	s5,8(sp)
    80001a74:	e05a                	sd	s6,0(sp)
    80001a76:	0080                	addi	s0,sp,64
    initlock(&pid_lock, "nextpid");
    80001a78:	00006597          	auipc	a1,0x6
    80001a7c:	7a858593          	addi	a1,a1,1960 # 80008220 <digits+0x1d0>
    80001a80:	0000f517          	auipc	a0,0xf
    80001a84:	65050513          	addi	a0,a0,1616 # 800110d0 <pid_lock>
    80001a88:	fffff097          	auipc	ra,0xfffff
    80001a8c:	186080e7          	jalr	390(ra) # 80000c0e <initlock>
    initlock(&wait_lock, "wait_lock");
    80001a90:	00006597          	auipc	a1,0x6
    80001a94:	79858593          	addi	a1,a1,1944 # 80008228 <digits+0x1d8>
    80001a98:	0000f517          	auipc	a0,0xf
    80001a9c:	65050513          	addi	a0,a0,1616 # 800110e8 <wait_lock>
    80001aa0:	fffff097          	auipc	ra,0xfffff
    80001aa4:	16e080e7          	jalr	366(ra) # 80000c0e <initlock>
    for (p = proc; p < &proc[NPROC]; p++)
    80001aa8:	0000f497          	auipc	s1,0xf
    80001aac:	65848493          	addi	s1,s1,1624 # 80011100 <proc>
        initlock(&p->lock, "proc");
    80001ab0:	00006b17          	auipc	s6,0x6
    80001ab4:	788b0b13          	addi	s6,s6,1928 # 80008238 <digits+0x1e8>
        p->kstack = KSTACK((int)(p - proc));
    80001ab8:	8aa6                	mv	s5,s1
    80001aba:	00006a17          	auipc	s4,0x6
    80001abe:	556a0a13          	addi	s4,s4,1366 # 80008010 <__func__.1+0x8>
    80001ac2:	04000937          	lui	s2,0x4000
    80001ac6:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001ac8:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001aca:	00015997          	auipc	s3,0x15
    80001ace:	03698993          	addi	s3,s3,54 # 80016b00 <tickslock>
        initlock(&p->lock, "proc");
    80001ad2:	85da                	mv	a1,s6
    80001ad4:	8526                	mv	a0,s1
    80001ad6:	fffff097          	auipc	ra,0xfffff
    80001ada:	138080e7          	jalr	312(ra) # 80000c0e <initlock>
        p->state = UNUSED;
    80001ade:	0004ac23          	sw	zero,24(s1)
        p->kstack = KSTACK((int)(p - proc));
    80001ae2:	415487b3          	sub	a5,s1,s5
    80001ae6:	878d                	srai	a5,a5,0x3
    80001ae8:	000a3703          	ld	a4,0(s4)
    80001aec:	02e787b3          	mul	a5,a5,a4
    80001af0:	2785                	addiw	a5,a5,1
    80001af2:	00d7979b          	slliw	a5,a5,0xd
    80001af6:	40f907b3          	sub	a5,s2,a5
    80001afa:	e0bc                	sd	a5,64(s1)
    for (p = proc; p < &proc[NPROC]; p++)
    80001afc:	16848493          	addi	s1,s1,360
    80001b00:	fd3499e3          	bne	s1,s3,80001ad2 <procinit+0x6e>
}
    80001b04:	70e2                	ld	ra,56(sp)
    80001b06:	7442                	ld	s0,48(sp)
    80001b08:	74a2                	ld	s1,40(sp)
    80001b0a:	7902                	ld	s2,32(sp)
    80001b0c:	69e2                	ld	s3,24(sp)
    80001b0e:	6a42                	ld	s4,16(sp)
    80001b10:	6aa2                	ld	s5,8(sp)
    80001b12:	6b02                	ld	s6,0(sp)
    80001b14:	6121                	addi	sp,sp,64
    80001b16:	8082                	ret

0000000080001b18 <copy_array>:
{
    80001b18:	1141                	addi	sp,sp,-16
    80001b1a:	e422                	sd	s0,8(sp)
    80001b1c:	0800                	addi	s0,sp,16
    for (int i = 0; i < len; i++)
    80001b1e:	02c05163          	blez	a2,80001b40 <copy_array+0x28>
    80001b22:	87aa                	mv	a5,a0
    80001b24:	0505                	addi	a0,a0,1
    80001b26:	367d                	addiw	a2,a2,-1 # fff <_entry-0x7ffff001>
    80001b28:	1602                	slli	a2,a2,0x20
    80001b2a:	9201                	srli	a2,a2,0x20
    80001b2c:	00c506b3          	add	a3,a0,a2
        dst[i] = src[i];
    80001b30:	0007c703          	lbu	a4,0(a5)
    80001b34:	00e58023          	sb	a4,0(a1)
    for (int i = 0; i < len; i++)
    80001b38:	0785                	addi	a5,a5,1
    80001b3a:	0585                	addi	a1,a1,1
    80001b3c:	fed79ae3          	bne	a5,a3,80001b30 <copy_array+0x18>
}
    80001b40:	6422                	ld	s0,8(sp)
    80001b42:	0141                	addi	sp,sp,16
    80001b44:	8082                	ret

0000000080001b46 <cpuid>:
{
    80001b46:	1141                	addi	sp,sp,-16
    80001b48:	e422                	sd	s0,8(sp)
    80001b4a:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b4c:	8512                	mv	a0,tp
}
    80001b4e:	2501                	sext.w	a0,a0
    80001b50:	6422                	ld	s0,8(sp)
    80001b52:	0141                	addi	sp,sp,16
    80001b54:	8082                	ret

0000000080001b56 <mycpu>:
{
    80001b56:	1141                	addi	sp,sp,-16
    80001b58:	e422                	sd	s0,8(sp)
    80001b5a:	0800                	addi	s0,sp,16
    80001b5c:	8792                	mv	a5,tp
    struct cpu *c = &cpus[id];
    80001b5e:	2781                	sext.w	a5,a5
    80001b60:	079e                	slli	a5,a5,0x7
}
    80001b62:	0000f517          	auipc	a0,0xf
    80001b66:	16e50513          	addi	a0,a0,366 # 80010cd0 <cpus>
    80001b6a:	953e                	add	a0,a0,a5
    80001b6c:	6422                	ld	s0,8(sp)
    80001b6e:	0141                	addi	sp,sp,16
    80001b70:	8082                	ret

0000000080001b72 <myproc>:
{
    80001b72:	1101                	addi	sp,sp,-32
    80001b74:	ec06                	sd	ra,24(sp)
    80001b76:	e822                	sd	s0,16(sp)
    80001b78:	e426                	sd	s1,8(sp)
    80001b7a:	1000                	addi	s0,sp,32
    push_off();
    80001b7c:	fffff097          	auipc	ra,0xfffff
    80001b80:	0d6080e7          	jalr	214(ra) # 80000c52 <push_off>
    80001b84:	8792                	mv	a5,tp
    struct proc *p = c->proc;
    80001b86:	2781                	sext.w	a5,a5
    80001b88:	079e                	slli	a5,a5,0x7
    80001b8a:	0000f717          	auipc	a4,0xf
    80001b8e:	14670713          	addi	a4,a4,326 # 80010cd0 <cpus>
    80001b92:	97ba                	add	a5,a5,a4
    80001b94:	6384                	ld	s1,0(a5)
    pop_off();
    80001b96:	fffff097          	auipc	ra,0xfffff
    80001b9a:	15c080e7          	jalr	348(ra) # 80000cf2 <pop_off>
}
    80001b9e:	8526                	mv	a0,s1
    80001ba0:	60e2                	ld	ra,24(sp)
    80001ba2:	6442                	ld	s0,16(sp)
    80001ba4:	64a2                	ld	s1,8(sp)
    80001ba6:	6105                	addi	sp,sp,32
    80001ba8:	8082                	ret

0000000080001baa <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001baa:	1141                	addi	sp,sp,-16
    80001bac:	e406                	sd	ra,8(sp)
    80001bae:	e022                	sd	s0,0(sp)
    80001bb0:	0800                	addi	s0,sp,16
    static int first = 1;

    // Still holding p->lock from scheduler.
    release(&myproc()->lock);
    80001bb2:	00000097          	auipc	ra,0x0
    80001bb6:	fc0080e7          	jalr	-64(ra) # 80001b72 <myproc>
    80001bba:	fffff097          	auipc	ra,0xfffff
    80001bbe:	198080e7          	jalr	408(ra) # 80000d52 <release>

    if (first)
    80001bc2:	00007797          	auipc	a5,0x7
    80001bc6:	dbe7a783          	lw	a5,-578(a5) # 80008980 <first.1>
    80001bca:	eb89                	bnez	a5,80001bdc <forkret+0x32>
        // be run from main().
        first = 0;
        fsinit(ROOTDEV);
    }

    usertrapret();
    80001bcc:	00001097          	auipc	ra,0x1
    80001bd0:	e44080e7          	jalr	-444(ra) # 80002a10 <usertrapret>
}
    80001bd4:	60a2                	ld	ra,8(sp)
    80001bd6:	6402                	ld	s0,0(sp)
    80001bd8:	0141                	addi	sp,sp,16
    80001bda:	8082                	ret
        first = 0;
    80001bdc:	00007797          	auipc	a5,0x7
    80001be0:	da07a223          	sw	zero,-604(a5) # 80008980 <first.1>
        fsinit(ROOTDEV);
    80001be4:	4505                	li	a0,1
    80001be6:	00002097          	auipc	ra,0x2
    80001bea:	ca0080e7          	jalr	-864(ra) # 80003886 <fsinit>
    80001bee:	bff9                	j	80001bcc <forkret+0x22>

0000000080001bf0 <allocpid>:
{
    80001bf0:	1101                	addi	sp,sp,-32
    80001bf2:	ec06                	sd	ra,24(sp)
    80001bf4:	e822                	sd	s0,16(sp)
    80001bf6:	e426                	sd	s1,8(sp)
    80001bf8:	e04a                	sd	s2,0(sp)
    80001bfa:	1000                	addi	s0,sp,32
    acquire(&pid_lock);
    80001bfc:	0000f917          	auipc	s2,0xf
    80001c00:	4d490913          	addi	s2,s2,1236 # 800110d0 <pid_lock>
    80001c04:	854a                	mv	a0,s2
    80001c06:	fffff097          	auipc	ra,0xfffff
    80001c0a:	098080e7          	jalr	152(ra) # 80000c9e <acquire>
    pid = nextpid;
    80001c0e:	00007797          	auipc	a5,0x7
    80001c12:	d8278793          	addi	a5,a5,-638 # 80008990 <nextpid>
    80001c16:	4384                	lw	s1,0(a5)
    nextpid = nextpid + 1;
    80001c18:	0014871b          	addiw	a4,s1,1
    80001c1c:	c398                	sw	a4,0(a5)
    release(&pid_lock);
    80001c1e:	854a                	mv	a0,s2
    80001c20:	fffff097          	auipc	ra,0xfffff
    80001c24:	132080e7          	jalr	306(ra) # 80000d52 <release>
}
    80001c28:	8526                	mv	a0,s1
    80001c2a:	60e2                	ld	ra,24(sp)
    80001c2c:	6442                	ld	s0,16(sp)
    80001c2e:	64a2                	ld	s1,8(sp)
    80001c30:	6902                	ld	s2,0(sp)
    80001c32:	6105                	addi	sp,sp,32
    80001c34:	8082                	ret

0000000080001c36 <proc_pagetable>:
{
    80001c36:	1101                	addi	sp,sp,-32
    80001c38:	ec06                	sd	ra,24(sp)
    80001c3a:	e822                	sd	s0,16(sp)
    80001c3c:	e426                	sd	s1,8(sp)
    80001c3e:	e04a                	sd	s2,0(sp)
    80001c40:	1000                	addi	s0,sp,32
    80001c42:	892a                	mv	s2,a0
    pagetable = uvmcreate();
    80001c44:	fffff097          	auipc	ra,0xfffff
    80001c48:	7ac080e7          	jalr	1964(ra) # 800013f0 <uvmcreate>
    80001c4c:	84aa                	mv	s1,a0
    if (pagetable == 0)
    80001c4e:	c121                	beqz	a0,80001c8e <proc_pagetable+0x58>
    if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c50:	4729                	li	a4,10
    80001c52:	00005697          	auipc	a3,0x5
    80001c56:	3ae68693          	addi	a3,a3,942 # 80007000 <_trampoline>
    80001c5a:	6605                	lui	a2,0x1
    80001c5c:	040005b7          	lui	a1,0x4000
    80001c60:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001c62:	05b2                	slli	a1,a1,0xc
    80001c64:	fffff097          	auipc	ra,0xfffff
    80001c68:	502080e7          	jalr	1282(ra) # 80001166 <mappages>
    80001c6c:	02054863          	bltz	a0,80001c9c <proc_pagetable+0x66>
    if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001c70:	4719                	li	a4,6
    80001c72:	05893683          	ld	a3,88(s2)
    80001c76:	6605                	lui	a2,0x1
    80001c78:	020005b7          	lui	a1,0x2000
    80001c7c:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001c7e:	05b6                	slli	a1,a1,0xd
    80001c80:	8526                	mv	a0,s1
    80001c82:	fffff097          	auipc	ra,0xfffff
    80001c86:	4e4080e7          	jalr	1252(ra) # 80001166 <mappages>
    80001c8a:	02054163          	bltz	a0,80001cac <proc_pagetable+0x76>
}
    80001c8e:	8526                	mv	a0,s1
    80001c90:	60e2                	ld	ra,24(sp)
    80001c92:	6442                	ld	s0,16(sp)
    80001c94:	64a2                	ld	s1,8(sp)
    80001c96:	6902                	ld	s2,0(sp)
    80001c98:	6105                	addi	sp,sp,32
    80001c9a:	8082                	ret
        uvmfree(pagetable, 0);
    80001c9c:	4581                	li	a1,0
    80001c9e:	8526                	mv	a0,s1
    80001ca0:	00000097          	auipc	ra,0x0
    80001ca4:	956080e7          	jalr	-1706(ra) # 800015f6 <uvmfree>
        return 0;
    80001ca8:	4481                	li	s1,0
    80001caa:	b7d5                	j	80001c8e <proc_pagetable+0x58>
        uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cac:	4681                	li	a3,0
    80001cae:	4605                	li	a2,1
    80001cb0:	040005b7          	lui	a1,0x4000
    80001cb4:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001cb6:	05b2                	slli	a1,a1,0xc
    80001cb8:	8526                	mv	a0,s1
    80001cba:	fffff097          	auipc	ra,0xfffff
    80001cbe:	672080e7          	jalr	1650(ra) # 8000132c <uvmunmap>
        uvmfree(pagetable, 0);
    80001cc2:	4581                	li	a1,0
    80001cc4:	8526                	mv	a0,s1
    80001cc6:	00000097          	auipc	ra,0x0
    80001cca:	930080e7          	jalr	-1744(ra) # 800015f6 <uvmfree>
        return 0;
    80001cce:	4481                	li	s1,0
    80001cd0:	bf7d                	j	80001c8e <proc_pagetable+0x58>

0000000080001cd2 <proc_freepagetable>:
{
    80001cd2:	1101                	addi	sp,sp,-32
    80001cd4:	ec06                	sd	ra,24(sp)
    80001cd6:	e822                	sd	s0,16(sp)
    80001cd8:	e426                	sd	s1,8(sp)
    80001cda:	e04a                	sd	s2,0(sp)
    80001cdc:	1000                	addi	s0,sp,32
    80001cde:	84aa                	mv	s1,a0
    80001ce0:	892e                	mv	s2,a1
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ce2:	4681                	li	a3,0
    80001ce4:	4605                	li	a2,1
    80001ce6:	040005b7          	lui	a1,0x4000
    80001cea:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001cec:	05b2                	slli	a1,a1,0xc
    80001cee:	fffff097          	auipc	ra,0xfffff
    80001cf2:	63e080e7          	jalr	1598(ra) # 8000132c <uvmunmap>
    uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001cf6:	4681                	li	a3,0
    80001cf8:	4605                	li	a2,1
    80001cfa:	020005b7          	lui	a1,0x2000
    80001cfe:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001d00:	05b6                	slli	a1,a1,0xd
    80001d02:	8526                	mv	a0,s1
    80001d04:	fffff097          	auipc	ra,0xfffff
    80001d08:	628080e7          	jalr	1576(ra) # 8000132c <uvmunmap>
    uvmfree(pagetable, sz);
    80001d0c:	85ca                	mv	a1,s2
    80001d0e:	8526                	mv	a0,s1
    80001d10:	00000097          	auipc	ra,0x0
    80001d14:	8e6080e7          	jalr	-1818(ra) # 800015f6 <uvmfree>
}
    80001d18:	60e2                	ld	ra,24(sp)
    80001d1a:	6442                	ld	s0,16(sp)
    80001d1c:	64a2                	ld	s1,8(sp)
    80001d1e:	6902                	ld	s2,0(sp)
    80001d20:	6105                	addi	sp,sp,32
    80001d22:	8082                	ret

0000000080001d24 <freeproc>:
{
    80001d24:	1101                	addi	sp,sp,-32
    80001d26:	ec06                	sd	ra,24(sp)
    80001d28:	e822                	sd	s0,16(sp)
    80001d2a:	e426                	sd	s1,8(sp)
    80001d2c:	1000                	addi	s0,sp,32
    80001d2e:	84aa                	mv	s1,a0
    if (p->trapframe)
    80001d30:	6d28                	ld	a0,88(a0)
    80001d32:	c509                	beqz	a0,80001d3c <freeproc+0x18>
        kfree((void *)p->trapframe);
    80001d34:	fffff097          	auipc	ra,0xfffff
    80001d38:	cc6080e7          	jalr	-826(ra) # 800009fa <kfree>
    p->trapframe = 0;
    80001d3c:	0404bc23          	sd	zero,88(s1)
    if (p->pagetable)
    80001d40:	68a8                	ld	a0,80(s1)
    80001d42:	c511                	beqz	a0,80001d4e <freeproc+0x2a>
        proc_freepagetable(p->pagetable, p->sz);
    80001d44:	64ac                	ld	a1,72(s1)
    80001d46:	00000097          	auipc	ra,0x0
    80001d4a:	f8c080e7          	jalr	-116(ra) # 80001cd2 <proc_freepagetable>
    p->pagetable = 0;
    80001d4e:	0404b823          	sd	zero,80(s1)
    p->sz = 0;
    80001d52:	0404b423          	sd	zero,72(s1)
    p->pid = 0;
    80001d56:	0204a823          	sw	zero,48(s1)
    p->parent = 0;
    80001d5a:	0204bc23          	sd	zero,56(s1)
    p->name[0] = 0;
    80001d5e:	14048c23          	sb	zero,344(s1)
    p->chan = 0;
    80001d62:	0204b023          	sd	zero,32(s1)
    p->killed = 0;
    80001d66:	0204a423          	sw	zero,40(s1)
    p->xstate = 0;
    80001d6a:	0204a623          	sw	zero,44(s1)
    p->state = UNUSED;
    80001d6e:	0004ac23          	sw	zero,24(s1)
}
    80001d72:	60e2                	ld	ra,24(sp)
    80001d74:	6442                	ld	s0,16(sp)
    80001d76:	64a2                	ld	s1,8(sp)
    80001d78:	6105                	addi	sp,sp,32
    80001d7a:	8082                	ret

0000000080001d7c <allocproc>:
{
    80001d7c:	1101                	addi	sp,sp,-32
    80001d7e:	ec06                	sd	ra,24(sp)
    80001d80:	e822                	sd	s0,16(sp)
    80001d82:	e426                	sd	s1,8(sp)
    80001d84:	e04a                	sd	s2,0(sp)
    80001d86:	1000                	addi	s0,sp,32
    for (p = proc; p < &proc[NPROC]; p++)
    80001d88:	0000f497          	auipc	s1,0xf
    80001d8c:	37848493          	addi	s1,s1,888 # 80011100 <proc>
    80001d90:	00015917          	auipc	s2,0x15
    80001d94:	d7090913          	addi	s2,s2,-656 # 80016b00 <tickslock>
        acquire(&p->lock);
    80001d98:	8526                	mv	a0,s1
    80001d9a:	fffff097          	auipc	ra,0xfffff
    80001d9e:	f04080e7          	jalr	-252(ra) # 80000c9e <acquire>
        if (p->state == UNUSED)
    80001da2:	4c9c                	lw	a5,24(s1)
    80001da4:	cf81                	beqz	a5,80001dbc <allocproc+0x40>
            release(&p->lock);
    80001da6:	8526                	mv	a0,s1
    80001da8:	fffff097          	auipc	ra,0xfffff
    80001dac:	faa080e7          	jalr	-86(ra) # 80000d52 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001db0:	16848493          	addi	s1,s1,360
    80001db4:	ff2492e3          	bne	s1,s2,80001d98 <allocproc+0x1c>
    return 0;
    80001db8:	4481                	li	s1,0
    80001dba:	a889                	j	80001e0c <allocproc+0x90>
    p->pid = allocpid();
    80001dbc:	00000097          	auipc	ra,0x0
    80001dc0:	e34080e7          	jalr	-460(ra) # 80001bf0 <allocpid>
    80001dc4:	d888                	sw	a0,48(s1)
    p->state = USED;
    80001dc6:	4785                	li	a5,1
    80001dc8:	cc9c                	sw	a5,24(s1)
    if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001dca:	fffff097          	auipc	ra,0xfffff
    80001dce:	d98080e7          	jalr	-616(ra) # 80000b62 <kalloc>
    80001dd2:	892a                	mv	s2,a0
    80001dd4:	eca8                	sd	a0,88(s1)
    80001dd6:	c131                	beqz	a0,80001e1a <allocproc+0x9e>
    p->pagetable = proc_pagetable(p);
    80001dd8:	8526                	mv	a0,s1
    80001dda:	00000097          	auipc	ra,0x0
    80001dde:	e5c080e7          	jalr	-420(ra) # 80001c36 <proc_pagetable>
    80001de2:	892a                	mv	s2,a0
    80001de4:	e8a8                	sd	a0,80(s1)
    if (p->pagetable == 0)
    80001de6:	c531                	beqz	a0,80001e32 <allocproc+0xb6>
    memset(&p->context, 0, sizeof(p->context));
    80001de8:	07000613          	li	a2,112
    80001dec:	4581                	li	a1,0
    80001dee:	06048513          	addi	a0,s1,96
    80001df2:	fffff097          	auipc	ra,0xfffff
    80001df6:	fa8080e7          	jalr	-88(ra) # 80000d9a <memset>
    p->context.ra = (uint64)forkret;
    80001dfa:	00000797          	auipc	a5,0x0
    80001dfe:	db078793          	addi	a5,a5,-592 # 80001baa <forkret>
    80001e02:	f0bc                	sd	a5,96(s1)
    p->context.sp = p->kstack + PGSIZE;
    80001e04:	60bc                	ld	a5,64(s1)
    80001e06:	6705                	lui	a4,0x1
    80001e08:	97ba                	add	a5,a5,a4
    80001e0a:	f4bc                	sd	a5,104(s1)
}
    80001e0c:	8526                	mv	a0,s1
    80001e0e:	60e2                	ld	ra,24(sp)
    80001e10:	6442                	ld	s0,16(sp)
    80001e12:	64a2                	ld	s1,8(sp)
    80001e14:	6902                	ld	s2,0(sp)
    80001e16:	6105                	addi	sp,sp,32
    80001e18:	8082                	ret
        freeproc(p);
    80001e1a:	8526                	mv	a0,s1
    80001e1c:	00000097          	auipc	ra,0x0
    80001e20:	f08080e7          	jalr	-248(ra) # 80001d24 <freeproc>
        release(&p->lock);
    80001e24:	8526                	mv	a0,s1
    80001e26:	fffff097          	auipc	ra,0xfffff
    80001e2a:	f2c080e7          	jalr	-212(ra) # 80000d52 <release>
        return 0;
    80001e2e:	84ca                	mv	s1,s2
    80001e30:	bff1                	j	80001e0c <allocproc+0x90>
        freeproc(p);
    80001e32:	8526                	mv	a0,s1
    80001e34:	00000097          	auipc	ra,0x0
    80001e38:	ef0080e7          	jalr	-272(ra) # 80001d24 <freeproc>
        release(&p->lock);
    80001e3c:	8526                	mv	a0,s1
    80001e3e:	fffff097          	auipc	ra,0xfffff
    80001e42:	f14080e7          	jalr	-236(ra) # 80000d52 <release>
        return 0;
    80001e46:	84ca                	mv	s1,s2
    80001e48:	b7d1                	j	80001e0c <allocproc+0x90>

0000000080001e4a <userinit>:
{
    80001e4a:	1101                	addi	sp,sp,-32
    80001e4c:	ec06                	sd	ra,24(sp)
    80001e4e:	e822                	sd	s0,16(sp)
    80001e50:	e426                	sd	s1,8(sp)
    80001e52:	1000                	addi	s0,sp,32
    p = allocproc();
    80001e54:	00000097          	auipc	ra,0x0
    80001e58:	f28080e7          	jalr	-216(ra) # 80001d7c <allocproc>
    80001e5c:	84aa                	mv	s1,a0
    initproc = p;
    80001e5e:	00007797          	auipc	a5,0x7
    80001e62:	bea7bd23          	sd	a0,-1030(a5) # 80008a58 <initproc>
    uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001e66:	03400613          	li	a2,52
    80001e6a:	00007597          	auipc	a1,0x7
    80001e6e:	b3658593          	addi	a1,a1,-1226 # 800089a0 <initcode>
    80001e72:	6928                	ld	a0,80(a0)
    80001e74:	fffff097          	auipc	ra,0xfffff
    80001e78:	5aa080e7          	jalr	1450(ra) # 8000141e <uvmfirst>
    p->sz = PGSIZE;
    80001e7c:	6785                	lui	a5,0x1
    80001e7e:	e4bc                	sd	a5,72(s1)
    p->trapframe->epc = 0;     // user program counter
    80001e80:	6cb8                	ld	a4,88(s1)
    80001e82:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
    p->trapframe->sp = PGSIZE; // user stack pointer
    80001e86:	6cb8                	ld	a4,88(s1)
    80001e88:	fb1c                	sd	a5,48(a4)
    safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e8a:	4641                	li	a2,16
    80001e8c:	00006597          	auipc	a1,0x6
    80001e90:	3b458593          	addi	a1,a1,948 # 80008240 <digits+0x1f0>
    80001e94:	15848513          	addi	a0,s1,344
    80001e98:	fffff097          	auipc	ra,0xfffff
    80001e9c:	04c080e7          	jalr	76(ra) # 80000ee4 <safestrcpy>
    p->cwd = namei("/");
    80001ea0:	00006517          	auipc	a0,0x6
    80001ea4:	3b050513          	addi	a0,a0,944 # 80008250 <digits+0x200>
    80001ea8:	00002097          	auipc	ra,0x2
    80001eac:	408080e7          	jalr	1032(ra) # 800042b0 <namei>
    80001eb0:	14a4b823          	sd	a0,336(s1)
    p->state = RUNNABLE;
    80001eb4:	478d                	li	a5,3
    80001eb6:	cc9c                	sw	a5,24(s1)
    release(&p->lock);
    80001eb8:	8526                	mv	a0,s1
    80001eba:	fffff097          	auipc	ra,0xfffff
    80001ebe:	e98080e7          	jalr	-360(ra) # 80000d52 <release>
}
    80001ec2:	60e2                	ld	ra,24(sp)
    80001ec4:	6442                	ld	s0,16(sp)
    80001ec6:	64a2                	ld	s1,8(sp)
    80001ec8:	6105                	addi	sp,sp,32
    80001eca:	8082                	ret

0000000080001ecc <growproc>:
{
    80001ecc:	1101                	addi	sp,sp,-32
    80001ece:	ec06                	sd	ra,24(sp)
    80001ed0:	e822                	sd	s0,16(sp)
    80001ed2:	e426                	sd	s1,8(sp)
    80001ed4:	e04a                	sd	s2,0(sp)
    80001ed6:	1000                	addi	s0,sp,32
    80001ed8:	892a                	mv	s2,a0
    struct proc *p = myproc();
    80001eda:	00000097          	auipc	ra,0x0
    80001ede:	c98080e7          	jalr	-872(ra) # 80001b72 <myproc>
    80001ee2:	84aa                	mv	s1,a0
    sz = p->sz;
    80001ee4:	652c                	ld	a1,72(a0)
    if (n > 0)
    80001ee6:	01204c63          	bgtz	s2,80001efe <growproc+0x32>
    else if (n < 0)
    80001eea:	02094663          	bltz	s2,80001f16 <growproc+0x4a>
    p->sz = sz;
    80001eee:	e4ac                	sd	a1,72(s1)
    return 0;
    80001ef0:	4501                	li	a0,0
}
    80001ef2:	60e2                	ld	ra,24(sp)
    80001ef4:	6442                	ld	s0,16(sp)
    80001ef6:	64a2                	ld	s1,8(sp)
    80001ef8:	6902                	ld	s2,0(sp)
    80001efa:	6105                	addi	sp,sp,32
    80001efc:	8082                	ret
        if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001efe:	4691                	li	a3,4
    80001f00:	00b90633          	add	a2,s2,a1
    80001f04:	6928                	ld	a0,80(a0)
    80001f06:	fffff097          	auipc	ra,0xfffff
    80001f0a:	5d2080e7          	jalr	1490(ra) # 800014d8 <uvmalloc>
    80001f0e:	85aa                	mv	a1,a0
    80001f10:	fd79                	bnez	a0,80001eee <growproc+0x22>
            return -1;
    80001f12:	557d                	li	a0,-1
    80001f14:	bff9                	j	80001ef2 <growproc+0x26>
        sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001f16:	00b90633          	add	a2,s2,a1
    80001f1a:	6928                	ld	a0,80(a0)
    80001f1c:	fffff097          	auipc	ra,0xfffff
    80001f20:	574080e7          	jalr	1396(ra) # 80001490 <uvmdealloc>
    80001f24:	85aa                	mv	a1,a0
    80001f26:	b7e1                	j	80001eee <growproc+0x22>

0000000080001f28 <ps>:
{
    80001f28:	715d                	addi	sp,sp,-80
    80001f2a:	e486                	sd	ra,72(sp)
    80001f2c:	e0a2                	sd	s0,64(sp)
    80001f2e:	fc26                	sd	s1,56(sp)
    80001f30:	f84a                	sd	s2,48(sp)
    80001f32:	f44e                	sd	s3,40(sp)
    80001f34:	f052                	sd	s4,32(sp)
    80001f36:	ec56                	sd	s5,24(sp)
    80001f38:	e85a                	sd	s6,16(sp)
    80001f3a:	e45e                	sd	s7,8(sp)
    80001f3c:	e062                	sd	s8,0(sp)
    80001f3e:	0880                	addi	s0,sp,80
    80001f40:	84aa                	mv	s1,a0
    80001f42:	8bae                	mv	s7,a1
    void *result = (void *)myproc()->sz;
    80001f44:	00000097          	auipc	ra,0x0
    80001f48:	c2e080e7          	jalr	-978(ra) # 80001b72 <myproc>
        return result;
    80001f4c:	4901                	li	s2,0
    if (count == 0)
    80001f4e:	0c0b8563          	beqz	s7,80002018 <ps+0xf0>
    void *result = (void *)myproc()->sz;
    80001f52:	04853b03          	ld	s6,72(a0)
    if (growproc(count * sizeof(struct user_proc)) < 0)
    80001f56:	003b951b          	slliw	a0,s7,0x3
    80001f5a:	0175053b          	addw	a0,a0,s7
    80001f5e:	0025151b          	slliw	a0,a0,0x2
    80001f62:	00000097          	auipc	ra,0x0
    80001f66:	f6a080e7          	jalr	-150(ra) # 80001ecc <growproc>
    80001f6a:	12054f63          	bltz	a0,800020a8 <ps+0x180>
    struct user_proc loc_result[count];
    80001f6e:	003b9a13          	slli	s4,s7,0x3
    80001f72:	9a5e                	add	s4,s4,s7
    80001f74:	0a0a                	slli	s4,s4,0x2
    80001f76:	00fa0793          	addi	a5,s4,15
    80001f7a:	8391                	srli	a5,a5,0x4
    80001f7c:	0792                	slli	a5,a5,0x4
    80001f7e:	40f10133          	sub	sp,sp,a5
    80001f82:	8a8a                	mv	s5,sp
    struct proc *p = proc + start;
    80001f84:	16800793          	li	a5,360
    80001f88:	02f484b3          	mul	s1,s1,a5
    80001f8c:	0000f797          	auipc	a5,0xf
    80001f90:	17478793          	addi	a5,a5,372 # 80011100 <proc>
    80001f94:	94be                	add	s1,s1,a5
    if (p >= &proc[NPROC])
    80001f96:	00015797          	auipc	a5,0x15
    80001f9a:	b6a78793          	addi	a5,a5,-1174 # 80016b00 <tickslock>
        return result;
    80001f9e:	4901                	li	s2,0
    if (p >= &proc[NPROC])
    80001fa0:	06f4fc63          	bgeu	s1,a5,80002018 <ps+0xf0>
    acquire(&wait_lock);
    80001fa4:	0000f517          	auipc	a0,0xf
    80001fa8:	14450513          	addi	a0,a0,324 # 800110e8 <wait_lock>
    80001fac:	fffff097          	auipc	ra,0xfffff
    80001fb0:	cf2080e7          	jalr	-782(ra) # 80000c9e <acquire>
        if (localCount == count)
    80001fb4:	014a8913          	addi	s2,s5,20
    uint8 localCount = 0;
    80001fb8:	4981                	li	s3,0
    for (; p < &proc[NPROC]; p++)
    80001fba:	00015c17          	auipc	s8,0x15
    80001fbe:	b46c0c13          	addi	s8,s8,-1210 # 80016b00 <tickslock>
    80001fc2:	a851                	j	80002056 <ps+0x12e>
            loc_result[localCount].state = UNUSED;
    80001fc4:	00399793          	slli	a5,s3,0x3
    80001fc8:	97ce                	add	a5,a5,s3
    80001fca:	078a                	slli	a5,a5,0x2
    80001fcc:	97d6                	add	a5,a5,s5
    80001fce:	0007a023          	sw	zero,0(a5)
            release(&p->lock);
    80001fd2:	8526                	mv	a0,s1
    80001fd4:	fffff097          	auipc	ra,0xfffff
    80001fd8:	d7e080e7          	jalr	-642(ra) # 80000d52 <release>
    release(&wait_lock);
    80001fdc:	0000f517          	auipc	a0,0xf
    80001fe0:	10c50513          	addi	a0,a0,268 # 800110e8 <wait_lock>
    80001fe4:	fffff097          	auipc	ra,0xfffff
    80001fe8:	d6e080e7          	jalr	-658(ra) # 80000d52 <release>
    if (localCount < count)
    80001fec:	0179f963          	bgeu	s3,s7,80001ffe <ps+0xd6>
        loc_result[localCount].state = UNUSED; // if we reach the end of processes
    80001ff0:	00399793          	slli	a5,s3,0x3
    80001ff4:	97ce                	add	a5,a5,s3
    80001ff6:	078a                	slli	a5,a5,0x2
    80001ff8:	97d6                	add	a5,a5,s5
    80001ffa:	0007a023          	sw	zero,0(a5)
    void *result = (void *)myproc()->sz;
    80001ffe:	895a                	mv	s2,s6
    copyout(myproc()->pagetable, (uint64)result, (void *)loc_result, count * sizeof(struct user_proc));
    80002000:	00000097          	auipc	ra,0x0
    80002004:	b72080e7          	jalr	-1166(ra) # 80001b72 <myproc>
    80002008:	86d2                	mv	a3,s4
    8000200a:	8656                	mv	a2,s5
    8000200c:	85da                	mv	a1,s6
    8000200e:	6928                	ld	a0,80(a0)
    80002010:	fffff097          	auipc	ra,0xfffff
    80002014:	724080e7          	jalr	1828(ra) # 80001734 <copyout>
}
    80002018:	854a                	mv	a0,s2
    8000201a:	fb040113          	addi	sp,s0,-80
    8000201e:	60a6                	ld	ra,72(sp)
    80002020:	6406                	ld	s0,64(sp)
    80002022:	74e2                	ld	s1,56(sp)
    80002024:	7942                	ld	s2,48(sp)
    80002026:	79a2                	ld	s3,40(sp)
    80002028:	7a02                	ld	s4,32(sp)
    8000202a:	6ae2                	ld	s5,24(sp)
    8000202c:	6b42                	ld	s6,16(sp)
    8000202e:	6ba2                	ld	s7,8(sp)
    80002030:	6c02                	ld	s8,0(sp)
    80002032:	6161                	addi	sp,sp,80
    80002034:	8082                	ret
        release(&p->lock);
    80002036:	8526                	mv	a0,s1
    80002038:	fffff097          	auipc	ra,0xfffff
    8000203c:	d1a080e7          	jalr	-742(ra) # 80000d52 <release>
        localCount++;
    80002040:	2985                	addiw	s3,s3,1
    80002042:	0ff9f993          	zext.b	s3,s3
    for (; p < &proc[NPROC]; p++)
    80002046:	16848493          	addi	s1,s1,360
    8000204a:	f984f9e3          	bgeu	s1,s8,80001fdc <ps+0xb4>
        if (localCount == count)
    8000204e:	02490913          	addi	s2,s2,36
    80002052:	053b8d63          	beq	s7,s3,800020ac <ps+0x184>
        acquire(&p->lock);
    80002056:	8526                	mv	a0,s1
    80002058:	fffff097          	auipc	ra,0xfffff
    8000205c:	c46080e7          	jalr	-954(ra) # 80000c9e <acquire>
        if (p->state == UNUSED)
    80002060:	4c9c                	lw	a5,24(s1)
    80002062:	d3ad                	beqz	a5,80001fc4 <ps+0x9c>
        loc_result[localCount].state = p->state;
    80002064:	fef92623          	sw	a5,-20(s2)
        loc_result[localCount].killed = p->killed;
    80002068:	549c                	lw	a5,40(s1)
    8000206a:	fef92823          	sw	a5,-16(s2)
        loc_result[localCount].xstate = p->xstate;
    8000206e:	54dc                	lw	a5,44(s1)
    80002070:	fef92a23          	sw	a5,-12(s2)
        loc_result[localCount].pid = p->pid;
    80002074:	589c                	lw	a5,48(s1)
    80002076:	fef92c23          	sw	a5,-8(s2)
        copy_array(p->name, loc_result[localCount].name, 16);
    8000207a:	4641                	li	a2,16
    8000207c:	85ca                	mv	a1,s2
    8000207e:	15848513          	addi	a0,s1,344
    80002082:	00000097          	auipc	ra,0x0
    80002086:	a96080e7          	jalr	-1386(ra) # 80001b18 <copy_array>
        if (p->parent != 0) // init
    8000208a:	7c88                	ld	a0,56(s1)
    8000208c:	d54d                	beqz	a0,80002036 <ps+0x10e>
            acquire(&p->parent->lock);
    8000208e:	fffff097          	auipc	ra,0xfffff
    80002092:	c10080e7          	jalr	-1008(ra) # 80000c9e <acquire>
            loc_result[localCount].parent_id = p->parent->pid;
    80002096:	7c88                	ld	a0,56(s1)
    80002098:	591c                	lw	a5,48(a0)
    8000209a:	fef92e23          	sw	a5,-4(s2)
            release(&p->parent->lock);
    8000209e:	fffff097          	auipc	ra,0xfffff
    800020a2:	cb4080e7          	jalr	-844(ra) # 80000d52 <release>
    800020a6:	bf41                	j	80002036 <ps+0x10e>
        return result;
    800020a8:	4901                	li	s2,0
    800020aa:	b7bd                	j	80002018 <ps+0xf0>
    release(&wait_lock);
    800020ac:	0000f517          	auipc	a0,0xf
    800020b0:	03c50513          	addi	a0,a0,60 # 800110e8 <wait_lock>
    800020b4:	fffff097          	auipc	ra,0xfffff
    800020b8:	c9e080e7          	jalr	-866(ra) # 80000d52 <release>
    if (localCount < count)
    800020bc:	b789                	j	80001ffe <ps+0xd6>

00000000800020be <fork>:
{
    800020be:	7139                	addi	sp,sp,-64
    800020c0:	fc06                	sd	ra,56(sp)
    800020c2:	f822                	sd	s0,48(sp)
    800020c4:	f426                	sd	s1,40(sp)
    800020c6:	f04a                	sd	s2,32(sp)
    800020c8:	ec4e                	sd	s3,24(sp)
    800020ca:	e852                	sd	s4,16(sp)
    800020cc:	e456                	sd	s5,8(sp)
    800020ce:	0080                	addi	s0,sp,64
    struct proc *p = myproc();
    800020d0:	00000097          	auipc	ra,0x0
    800020d4:	aa2080e7          	jalr	-1374(ra) # 80001b72 <myproc>
    800020d8:	8aaa                	mv	s5,a0
    if ((np = allocproc()) == 0)
    800020da:	00000097          	auipc	ra,0x0
    800020de:	ca2080e7          	jalr	-862(ra) # 80001d7c <allocproc>
    800020e2:	10050c63          	beqz	a0,800021fa <fork+0x13c>
    800020e6:	8a2a                	mv	s4,a0
    if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    800020e8:	048ab603          	ld	a2,72(s5)
    800020ec:	692c                	ld	a1,80(a0)
    800020ee:	050ab503          	ld	a0,80(s5)
    800020f2:	fffff097          	auipc	ra,0xfffff
    800020f6:	53e080e7          	jalr	1342(ra) # 80001630 <uvmcopy>
    800020fa:	04054863          	bltz	a0,8000214a <fork+0x8c>
    np->sz = p->sz;
    800020fe:	048ab783          	ld	a5,72(s5)
    80002102:	04fa3423          	sd	a5,72(s4)
    *(np->trapframe) = *(p->trapframe);
    80002106:	058ab683          	ld	a3,88(s5)
    8000210a:	87b6                	mv	a5,a3
    8000210c:	058a3703          	ld	a4,88(s4)
    80002110:	12068693          	addi	a3,a3,288
    80002114:	0007b803          	ld	a6,0(a5)
    80002118:	6788                	ld	a0,8(a5)
    8000211a:	6b8c                	ld	a1,16(a5)
    8000211c:	6f90                	ld	a2,24(a5)
    8000211e:	01073023          	sd	a6,0(a4)
    80002122:	e708                	sd	a0,8(a4)
    80002124:	eb0c                	sd	a1,16(a4)
    80002126:	ef10                	sd	a2,24(a4)
    80002128:	02078793          	addi	a5,a5,32
    8000212c:	02070713          	addi	a4,a4,32
    80002130:	fed792e3          	bne	a5,a3,80002114 <fork+0x56>
    np->trapframe->a0 = 0;
    80002134:	058a3783          	ld	a5,88(s4)
    80002138:	0607b823          	sd	zero,112(a5)
    for (i = 0; i < NOFILE; i++)
    8000213c:	0d0a8493          	addi	s1,s5,208
    80002140:	0d0a0913          	addi	s2,s4,208
    80002144:	150a8993          	addi	s3,s5,336
    80002148:	a00d                	j	8000216a <fork+0xac>
        freeproc(np);
    8000214a:	8552                	mv	a0,s4
    8000214c:	00000097          	auipc	ra,0x0
    80002150:	bd8080e7          	jalr	-1064(ra) # 80001d24 <freeproc>
        release(&np->lock);
    80002154:	8552                	mv	a0,s4
    80002156:	fffff097          	auipc	ra,0xfffff
    8000215a:	bfc080e7          	jalr	-1028(ra) # 80000d52 <release>
        return -1;
    8000215e:	597d                	li	s2,-1
    80002160:	a059                	j	800021e6 <fork+0x128>
    for (i = 0; i < NOFILE; i++)
    80002162:	04a1                	addi	s1,s1,8
    80002164:	0921                	addi	s2,s2,8
    80002166:	01348b63          	beq	s1,s3,8000217c <fork+0xbe>
        if (p->ofile[i])
    8000216a:	6088                	ld	a0,0(s1)
    8000216c:	d97d                	beqz	a0,80002162 <fork+0xa4>
            np->ofile[i] = filedup(p->ofile[i]);
    8000216e:	00002097          	auipc	ra,0x2
    80002172:	7d8080e7          	jalr	2008(ra) # 80004946 <filedup>
    80002176:	00a93023          	sd	a0,0(s2)
    8000217a:	b7e5                	j	80002162 <fork+0xa4>
    np->cwd = idup(p->cwd);
    8000217c:	150ab503          	ld	a0,336(s5)
    80002180:	00002097          	auipc	ra,0x2
    80002184:	946080e7          	jalr	-1722(ra) # 80003ac6 <idup>
    80002188:	14aa3823          	sd	a0,336(s4)
    safestrcpy(np->name, p->name, sizeof(p->name));
    8000218c:	4641                	li	a2,16
    8000218e:	158a8593          	addi	a1,s5,344
    80002192:	158a0513          	addi	a0,s4,344
    80002196:	fffff097          	auipc	ra,0xfffff
    8000219a:	d4e080e7          	jalr	-690(ra) # 80000ee4 <safestrcpy>
    pid = np->pid;
    8000219e:	030a2903          	lw	s2,48(s4)
    release(&np->lock);
    800021a2:	8552                	mv	a0,s4
    800021a4:	fffff097          	auipc	ra,0xfffff
    800021a8:	bae080e7          	jalr	-1106(ra) # 80000d52 <release>
    acquire(&wait_lock);
    800021ac:	0000f497          	auipc	s1,0xf
    800021b0:	f3c48493          	addi	s1,s1,-196 # 800110e8 <wait_lock>
    800021b4:	8526                	mv	a0,s1
    800021b6:	fffff097          	auipc	ra,0xfffff
    800021ba:	ae8080e7          	jalr	-1304(ra) # 80000c9e <acquire>
    np->parent = p;
    800021be:	035a3c23          	sd	s5,56(s4)
    release(&wait_lock);
    800021c2:	8526                	mv	a0,s1
    800021c4:	fffff097          	auipc	ra,0xfffff
    800021c8:	b8e080e7          	jalr	-1138(ra) # 80000d52 <release>
    acquire(&np->lock);
    800021cc:	8552                	mv	a0,s4
    800021ce:	fffff097          	auipc	ra,0xfffff
    800021d2:	ad0080e7          	jalr	-1328(ra) # 80000c9e <acquire>
    np->state = RUNNABLE;
    800021d6:	478d                	li	a5,3
    800021d8:	00fa2c23          	sw	a5,24(s4)
    release(&np->lock);
    800021dc:	8552                	mv	a0,s4
    800021de:	fffff097          	auipc	ra,0xfffff
    800021e2:	b74080e7          	jalr	-1164(ra) # 80000d52 <release>
}
    800021e6:	854a                	mv	a0,s2
    800021e8:	70e2                	ld	ra,56(sp)
    800021ea:	7442                	ld	s0,48(sp)
    800021ec:	74a2                	ld	s1,40(sp)
    800021ee:	7902                	ld	s2,32(sp)
    800021f0:	69e2                	ld	s3,24(sp)
    800021f2:	6a42                	ld	s4,16(sp)
    800021f4:	6aa2                	ld	s5,8(sp)
    800021f6:	6121                	addi	sp,sp,64
    800021f8:	8082                	ret
        return -1;
    800021fa:	597d                	li	s2,-1
    800021fc:	b7ed                	j	800021e6 <fork+0x128>

00000000800021fe <scheduler>:
{
    800021fe:	1101                	addi	sp,sp,-32
    80002200:	ec06                	sd	ra,24(sp)
    80002202:	e822                	sd	s0,16(sp)
    80002204:	e426                	sd	s1,8(sp)
    80002206:	1000                	addi	s0,sp,32
        (*sched_pointer)();
    80002208:	00006497          	auipc	s1,0x6
    8000220c:	78048493          	addi	s1,s1,1920 # 80008988 <sched_pointer>
    80002210:	609c                	ld	a5,0(s1)
    80002212:	9782                	jalr	a5
    while (1)
    80002214:	bff5                	j	80002210 <scheduler+0x12>

0000000080002216 <sched>:
{
    80002216:	7179                	addi	sp,sp,-48
    80002218:	f406                	sd	ra,40(sp)
    8000221a:	f022                	sd	s0,32(sp)
    8000221c:	ec26                	sd	s1,24(sp)
    8000221e:	e84a                	sd	s2,16(sp)
    80002220:	e44e                	sd	s3,8(sp)
    80002222:	1800                	addi	s0,sp,48
    struct proc *p = myproc();
    80002224:	00000097          	auipc	ra,0x0
    80002228:	94e080e7          	jalr	-1714(ra) # 80001b72 <myproc>
    8000222c:	84aa                	mv	s1,a0
    if (!holding(&p->lock))
    8000222e:	fffff097          	auipc	ra,0xfffff
    80002232:	9f6080e7          	jalr	-1546(ra) # 80000c24 <holding>
    80002236:	c53d                	beqz	a0,800022a4 <sched+0x8e>
    80002238:	8792                	mv	a5,tp
    if (mycpu()->noff != 1)
    8000223a:	2781                	sext.w	a5,a5
    8000223c:	079e                	slli	a5,a5,0x7
    8000223e:	0000f717          	auipc	a4,0xf
    80002242:	a9270713          	addi	a4,a4,-1390 # 80010cd0 <cpus>
    80002246:	97ba                	add	a5,a5,a4
    80002248:	5fb8                	lw	a4,120(a5)
    8000224a:	4785                	li	a5,1
    8000224c:	06f71463          	bne	a4,a5,800022b4 <sched+0x9e>
    if (p->state == RUNNING)
    80002250:	4c98                	lw	a4,24(s1)
    80002252:	4791                	li	a5,4
    80002254:	06f70863          	beq	a4,a5,800022c4 <sched+0xae>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002258:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000225c:	8b89                	andi	a5,a5,2
    if (intr_get())
    8000225e:	ebbd                	bnez	a5,800022d4 <sched+0xbe>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002260:	8792                	mv	a5,tp
    intena = mycpu()->intena;
    80002262:	0000f917          	auipc	s2,0xf
    80002266:	a6e90913          	addi	s2,s2,-1426 # 80010cd0 <cpus>
    8000226a:	2781                	sext.w	a5,a5
    8000226c:	079e                	slli	a5,a5,0x7
    8000226e:	97ca                	add	a5,a5,s2
    80002270:	07c7a983          	lw	s3,124(a5)
    80002274:	8592                	mv	a1,tp
    swtch(&p->context, &mycpu()->context);
    80002276:	2581                	sext.w	a1,a1
    80002278:	059e                	slli	a1,a1,0x7
    8000227a:	05a1                	addi	a1,a1,8
    8000227c:	95ca                	add	a1,a1,s2
    8000227e:	06048513          	addi	a0,s1,96
    80002282:	00000097          	auipc	ra,0x0
    80002286:	6e4080e7          	jalr	1764(ra) # 80002966 <swtch>
    8000228a:	8792                	mv	a5,tp
    mycpu()->intena = intena;
    8000228c:	2781                	sext.w	a5,a5
    8000228e:	079e                	slli	a5,a5,0x7
    80002290:	993e                	add	s2,s2,a5
    80002292:	07392e23          	sw	s3,124(s2)
}
    80002296:	70a2                	ld	ra,40(sp)
    80002298:	7402                	ld	s0,32(sp)
    8000229a:	64e2                	ld	s1,24(sp)
    8000229c:	6942                	ld	s2,16(sp)
    8000229e:	69a2                	ld	s3,8(sp)
    800022a0:	6145                	addi	sp,sp,48
    800022a2:	8082                	ret
        panic("sched p->lock");
    800022a4:	00006517          	auipc	a0,0x6
    800022a8:	fb450513          	addi	a0,a0,-76 # 80008258 <digits+0x208>
    800022ac:	ffffe097          	auipc	ra,0xffffe
    800022b0:	294080e7          	jalr	660(ra) # 80000540 <panic>
        panic("sched locks");
    800022b4:	00006517          	auipc	a0,0x6
    800022b8:	fb450513          	addi	a0,a0,-76 # 80008268 <digits+0x218>
    800022bc:	ffffe097          	auipc	ra,0xffffe
    800022c0:	284080e7          	jalr	644(ra) # 80000540 <panic>
        panic("sched running");
    800022c4:	00006517          	auipc	a0,0x6
    800022c8:	fb450513          	addi	a0,a0,-76 # 80008278 <digits+0x228>
    800022cc:	ffffe097          	auipc	ra,0xffffe
    800022d0:	274080e7          	jalr	628(ra) # 80000540 <panic>
        panic("sched interruptible");
    800022d4:	00006517          	auipc	a0,0x6
    800022d8:	fb450513          	addi	a0,a0,-76 # 80008288 <digits+0x238>
    800022dc:	ffffe097          	auipc	ra,0xffffe
    800022e0:	264080e7          	jalr	612(ra) # 80000540 <panic>

00000000800022e4 <yield>:
{
    800022e4:	1101                	addi	sp,sp,-32
    800022e6:	ec06                	sd	ra,24(sp)
    800022e8:	e822                	sd	s0,16(sp)
    800022ea:	e426                	sd	s1,8(sp)
    800022ec:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    800022ee:	00000097          	auipc	ra,0x0
    800022f2:	884080e7          	jalr	-1916(ra) # 80001b72 <myproc>
    800022f6:	84aa                	mv	s1,a0
    acquire(&p->lock);
    800022f8:	fffff097          	auipc	ra,0xfffff
    800022fc:	9a6080e7          	jalr	-1626(ra) # 80000c9e <acquire>
    p->state = RUNNABLE;
    80002300:	478d                	li	a5,3
    80002302:	cc9c                	sw	a5,24(s1)
    sched();
    80002304:	00000097          	auipc	ra,0x0
    80002308:	f12080e7          	jalr	-238(ra) # 80002216 <sched>
    release(&p->lock);
    8000230c:	8526                	mv	a0,s1
    8000230e:	fffff097          	auipc	ra,0xfffff
    80002312:	a44080e7          	jalr	-1468(ra) # 80000d52 <release>
}
    80002316:	60e2                	ld	ra,24(sp)
    80002318:	6442                	ld	s0,16(sp)
    8000231a:	64a2                	ld	s1,8(sp)
    8000231c:	6105                	addi	sp,sp,32
    8000231e:	8082                	ret

0000000080002320 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002320:	7179                	addi	sp,sp,-48
    80002322:	f406                	sd	ra,40(sp)
    80002324:	f022                	sd	s0,32(sp)
    80002326:	ec26                	sd	s1,24(sp)
    80002328:	e84a                	sd	s2,16(sp)
    8000232a:	e44e                	sd	s3,8(sp)
    8000232c:	1800                	addi	s0,sp,48
    8000232e:	89aa                	mv	s3,a0
    80002330:	892e                	mv	s2,a1
    struct proc *p = myproc();
    80002332:	00000097          	auipc	ra,0x0
    80002336:	840080e7          	jalr	-1984(ra) # 80001b72 <myproc>
    8000233a:	84aa                	mv	s1,a0
    // Once we hold p->lock, we can be
    // guaranteed that we won't miss any wakeup
    // (wakeup locks p->lock),
    // so it's okay to release lk.

    acquire(&p->lock); // DOC: sleeplock1
    8000233c:	fffff097          	auipc	ra,0xfffff
    80002340:	962080e7          	jalr	-1694(ra) # 80000c9e <acquire>
    release(lk);
    80002344:	854a                	mv	a0,s2
    80002346:	fffff097          	auipc	ra,0xfffff
    8000234a:	a0c080e7          	jalr	-1524(ra) # 80000d52 <release>

    // Go to sleep.
    p->chan = chan;
    8000234e:	0334b023          	sd	s3,32(s1)
    p->state = SLEEPING;
    80002352:	4789                	li	a5,2
    80002354:	cc9c                	sw	a5,24(s1)

    sched();
    80002356:	00000097          	auipc	ra,0x0
    8000235a:	ec0080e7          	jalr	-320(ra) # 80002216 <sched>

    // Tidy up.
    p->chan = 0;
    8000235e:	0204b023          	sd	zero,32(s1)

    // Reacquire original lock.
    release(&p->lock);
    80002362:	8526                	mv	a0,s1
    80002364:	fffff097          	auipc	ra,0xfffff
    80002368:	9ee080e7          	jalr	-1554(ra) # 80000d52 <release>
    acquire(lk);
    8000236c:	854a                	mv	a0,s2
    8000236e:	fffff097          	auipc	ra,0xfffff
    80002372:	930080e7          	jalr	-1744(ra) # 80000c9e <acquire>
}
    80002376:	70a2                	ld	ra,40(sp)
    80002378:	7402                	ld	s0,32(sp)
    8000237a:	64e2                	ld	s1,24(sp)
    8000237c:	6942                	ld	s2,16(sp)
    8000237e:	69a2                	ld	s3,8(sp)
    80002380:	6145                	addi	sp,sp,48
    80002382:	8082                	ret

0000000080002384 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002384:	7139                	addi	sp,sp,-64
    80002386:	fc06                	sd	ra,56(sp)
    80002388:	f822                	sd	s0,48(sp)
    8000238a:	f426                	sd	s1,40(sp)
    8000238c:	f04a                	sd	s2,32(sp)
    8000238e:	ec4e                	sd	s3,24(sp)
    80002390:	e852                	sd	s4,16(sp)
    80002392:	e456                	sd	s5,8(sp)
    80002394:	0080                	addi	s0,sp,64
    80002396:	8a2a                	mv	s4,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    80002398:	0000f497          	auipc	s1,0xf
    8000239c:	d6848493          	addi	s1,s1,-664 # 80011100 <proc>
    {
        if (p != myproc())
        {
            acquire(&p->lock);
            if (p->state == SLEEPING && p->chan == chan)
    800023a0:	4989                	li	s3,2
            {
                p->state = RUNNABLE;
    800023a2:	4a8d                	li	s5,3
    for (p = proc; p < &proc[NPROC]; p++)
    800023a4:	00014917          	auipc	s2,0x14
    800023a8:	75c90913          	addi	s2,s2,1884 # 80016b00 <tickslock>
    800023ac:	a811                	j	800023c0 <wakeup+0x3c>
            }
            release(&p->lock);
    800023ae:	8526                	mv	a0,s1
    800023b0:	fffff097          	auipc	ra,0xfffff
    800023b4:	9a2080e7          	jalr	-1630(ra) # 80000d52 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    800023b8:	16848493          	addi	s1,s1,360
    800023bc:	03248663          	beq	s1,s2,800023e8 <wakeup+0x64>
        if (p != myproc())
    800023c0:	fffff097          	auipc	ra,0xfffff
    800023c4:	7b2080e7          	jalr	1970(ra) # 80001b72 <myproc>
    800023c8:	fea488e3          	beq	s1,a0,800023b8 <wakeup+0x34>
            acquire(&p->lock);
    800023cc:	8526                	mv	a0,s1
    800023ce:	fffff097          	auipc	ra,0xfffff
    800023d2:	8d0080e7          	jalr	-1840(ra) # 80000c9e <acquire>
            if (p->state == SLEEPING && p->chan == chan)
    800023d6:	4c9c                	lw	a5,24(s1)
    800023d8:	fd379be3          	bne	a5,s3,800023ae <wakeup+0x2a>
    800023dc:	709c                	ld	a5,32(s1)
    800023de:	fd4798e3          	bne	a5,s4,800023ae <wakeup+0x2a>
                p->state = RUNNABLE;
    800023e2:	0154ac23          	sw	s5,24(s1)
    800023e6:	b7e1                	j	800023ae <wakeup+0x2a>
        }
    }
}
    800023e8:	70e2                	ld	ra,56(sp)
    800023ea:	7442                	ld	s0,48(sp)
    800023ec:	74a2                	ld	s1,40(sp)
    800023ee:	7902                	ld	s2,32(sp)
    800023f0:	69e2                	ld	s3,24(sp)
    800023f2:	6a42                	ld	s4,16(sp)
    800023f4:	6aa2                	ld	s5,8(sp)
    800023f6:	6121                	addi	sp,sp,64
    800023f8:	8082                	ret

00000000800023fa <reparent>:
{
    800023fa:	7179                	addi	sp,sp,-48
    800023fc:	f406                	sd	ra,40(sp)
    800023fe:	f022                	sd	s0,32(sp)
    80002400:	ec26                	sd	s1,24(sp)
    80002402:	e84a                	sd	s2,16(sp)
    80002404:	e44e                	sd	s3,8(sp)
    80002406:	e052                	sd	s4,0(sp)
    80002408:	1800                	addi	s0,sp,48
    8000240a:	892a                	mv	s2,a0
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000240c:	0000f497          	auipc	s1,0xf
    80002410:	cf448493          	addi	s1,s1,-780 # 80011100 <proc>
            pp->parent = initproc;
    80002414:	00006a17          	auipc	s4,0x6
    80002418:	644a0a13          	addi	s4,s4,1604 # 80008a58 <initproc>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000241c:	00014997          	auipc	s3,0x14
    80002420:	6e498993          	addi	s3,s3,1764 # 80016b00 <tickslock>
    80002424:	a029                	j	8000242e <reparent+0x34>
    80002426:	16848493          	addi	s1,s1,360
    8000242a:	01348d63          	beq	s1,s3,80002444 <reparent+0x4a>
        if (pp->parent == p)
    8000242e:	7c9c                	ld	a5,56(s1)
    80002430:	ff279be3          	bne	a5,s2,80002426 <reparent+0x2c>
            pp->parent = initproc;
    80002434:	000a3503          	ld	a0,0(s4)
    80002438:	fc88                	sd	a0,56(s1)
            wakeup(initproc);
    8000243a:	00000097          	auipc	ra,0x0
    8000243e:	f4a080e7          	jalr	-182(ra) # 80002384 <wakeup>
    80002442:	b7d5                	j	80002426 <reparent+0x2c>
}
    80002444:	70a2                	ld	ra,40(sp)
    80002446:	7402                	ld	s0,32(sp)
    80002448:	64e2                	ld	s1,24(sp)
    8000244a:	6942                	ld	s2,16(sp)
    8000244c:	69a2                	ld	s3,8(sp)
    8000244e:	6a02                	ld	s4,0(sp)
    80002450:	6145                	addi	sp,sp,48
    80002452:	8082                	ret

0000000080002454 <exit>:
{
    80002454:	7179                	addi	sp,sp,-48
    80002456:	f406                	sd	ra,40(sp)
    80002458:	f022                	sd	s0,32(sp)
    8000245a:	ec26                	sd	s1,24(sp)
    8000245c:	e84a                	sd	s2,16(sp)
    8000245e:	e44e                	sd	s3,8(sp)
    80002460:	e052                	sd	s4,0(sp)
    80002462:	1800                	addi	s0,sp,48
    80002464:	8a2a                	mv	s4,a0
    struct proc *p = myproc();
    80002466:	fffff097          	auipc	ra,0xfffff
    8000246a:	70c080e7          	jalr	1804(ra) # 80001b72 <myproc>
    8000246e:	89aa                	mv	s3,a0
    if (p == initproc)
    80002470:	00006797          	auipc	a5,0x6
    80002474:	5e87b783          	ld	a5,1512(a5) # 80008a58 <initproc>
    80002478:	0d050493          	addi	s1,a0,208
    8000247c:	15050913          	addi	s2,a0,336
    80002480:	02a79363          	bne	a5,a0,800024a6 <exit+0x52>
        panic("init exiting");
    80002484:	00006517          	auipc	a0,0x6
    80002488:	e1c50513          	addi	a0,a0,-484 # 800082a0 <digits+0x250>
    8000248c:	ffffe097          	auipc	ra,0xffffe
    80002490:	0b4080e7          	jalr	180(ra) # 80000540 <panic>
            fileclose(f);
    80002494:	00002097          	auipc	ra,0x2
    80002498:	504080e7          	jalr	1284(ra) # 80004998 <fileclose>
            p->ofile[fd] = 0;
    8000249c:	0004b023          	sd	zero,0(s1)
    for (int fd = 0; fd < NOFILE; fd++)
    800024a0:	04a1                	addi	s1,s1,8
    800024a2:	01248563          	beq	s1,s2,800024ac <exit+0x58>
        if (p->ofile[fd])
    800024a6:	6088                	ld	a0,0(s1)
    800024a8:	f575                	bnez	a0,80002494 <exit+0x40>
    800024aa:	bfdd                	j	800024a0 <exit+0x4c>
    begin_op();
    800024ac:	00002097          	auipc	ra,0x2
    800024b0:	024080e7          	jalr	36(ra) # 800044d0 <begin_op>
    iput(p->cwd);
    800024b4:	1509b503          	ld	a0,336(s3)
    800024b8:	00002097          	auipc	ra,0x2
    800024bc:	806080e7          	jalr	-2042(ra) # 80003cbe <iput>
    end_op();
    800024c0:	00002097          	auipc	ra,0x2
    800024c4:	08e080e7          	jalr	142(ra) # 8000454e <end_op>
    p->cwd = 0;
    800024c8:	1409b823          	sd	zero,336(s3)
    acquire(&wait_lock);
    800024cc:	0000f497          	auipc	s1,0xf
    800024d0:	c1c48493          	addi	s1,s1,-996 # 800110e8 <wait_lock>
    800024d4:	8526                	mv	a0,s1
    800024d6:	ffffe097          	auipc	ra,0xffffe
    800024da:	7c8080e7          	jalr	1992(ra) # 80000c9e <acquire>
    reparent(p);
    800024de:	854e                	mv	a0,s3
    800024e0:	00000097          	auipc	ra,0x0
    800024e4:	f1a080e7          	jalr	-230(ra) # 800023fa <reparent>
    wakeup(p->parent);
    800024e8:	0389b503          	ld	a0,56(s3)
    800024ec:	00000097          	auipc	ra,0x0
    800024f0:	e98080e7          	jalr	-360(ra) # 80002384 <wakeup>
    acquire(&p->lock);
    800024f4:	854e                	mv	a0,s3
    800024f6:	ffffe097          	auipc	ra,0xffffe
    800024fa:	7a8080e7          	jalr	1960(ra) # 80000c9e <acquire>
    p->xstate = status;
    800024fe:	0349a623          	sw	s4,44(s3)
    p->state = ZOMBIE;
    80002502:	4795                	li	a5,5
    80002504:	00f9ac23          	sw	a5,24(s3)
    release(&wait_lock);
    80002508:	8526                	mv	a0,s1
    8000250a:	fffff097          	auipc	ra,0xfffff
    8000250e:	848080e7          	jalr	-1976(ra) # 80000d52 <release>
    sched();
    80002512:	00000097          	auipc	ra,0x0
    80002516:	d04080e7          	jalr	-764(ra) # 80002216 <sched>
    panic("zombie exit");
    8000251a:	00006517          	auipc	a0,0x6
    8000251e:	d9650513          	addi	a0,a0,-618 # 800082b0 <digits+0x260>
    80002522:	ffffe097          	auipc	ra,0xffffe
    80002526:	01e080e7          	jalr	30(ra) # 80000540 <panic>

000000008000252a <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    8000252a:	7179                	addi	sp,sp,-48
    8000252c:	f406                	sd	ra,40(sp)
    8000252e:	f022                	sd	s0,32(sp)
    80002530:	ec26                	sd	s1,24(sp)
    80002532:	e84a                	sd	s2,16(sp)
    80002534:	e44e                	sd	s3,8(sp)
    80002536:	1800                	addi	s0,sp,48
    80002538:	892a                	mv	s2,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    8000253a:	0000f497          	auipc	s1,0xf
    8000253e:	bc648493          	addi	s1,s1,-1082 # 80011100 <proc>
    80002542:	00014997          	auipc	s3,0x14
    80002546:	5be98993          	addi	s3,s3,1470 # 80016b00 <tickslock>
    {
        acquire(&p->lock);
    8000254a:	8526                	mv	a0,s1
    8000254c:	ffffe097          	auipc	ra,0xffffe
    80002550:	752080e7          	jalr	1874(ra) # 80000c9e <acquire>
        if (p->pid == pid)
    80002554:	589c                	lw	a5,48(s1)
    80002556:	01278d63          	beq	a5,s2,80002570 <kill+0x46>
                p->state = RUNNABLE;
            }
            release(&p->lock);
            return 0;
        }
        release(&p->lock);
    8000255a:	8526                	mv	a0,s1
    8000255c:	ffffe097          	auipc	ra,0xffffe
    80002560:	7f6080e7          	jalr	2038(ra) # 80000d52 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002564:	16848493          	addi	s1,s1,360
    80002568:	ff3491e3          	bne	s1,s3,8000254a <kill+0x20>
    }
    return -1;
    8000256c:	557d                	li	a0,-1
    8000256e:	a829                	j	80002588 <kill+0x5e>
            p->killed = 1;
    80002570:	4785                	li	a5,1
    80002572:	d49c                	sw	a5,40(s1)
            if (p->state == SLEEPING)
    80002574:	4c98                	lw	a4,24(s1)
    80002576:	4789                	li	a5,2
    80002578:	00f70f63          	beq	a4,a5,80002596 <kill+0x6c>
            release(&p->lock);
    8000257c:	8526                	mv	a0,s1
    8000257e:	ffffe097          	auipc	ra,0xffffe
    80002582:	7d4080e7          	jalr	2004(ra) # 80000d52 <release>
            return 0;
    80002586:	4501                	li	a0,0
}
    80002588:	70a2                	ld	ra,40(sp)
    8000258a:	7402                	ld	s0,32(sp)
    8000258c:	64e2                	ld	s1,24(sp)
    8000258e:	6942                	ld	s2,16(sp)
    80002590:	69a2                	ld	s3,8(sp)
    80002592:	6145                	addi	sp,sp,48
    80002594:	8082                	ret
                p->state = RUNNABLE;
    80002596:	478d                	li	a5,3
    80002598:	cc9c                	sw	a5,24(s1)
    8000259a:	b7cd                	j	8000257c <kill+0x52>

000000008000259c <setkilled>:

void setkilled(struct proc *p)
{
    8000259c:	1101                	addi	sp,sp,-32
    8000259e:	ec06                	sd	ra,24(sp)
    800025a0:	e822                	sd	s0,16(sp)
    800025a2:	e426                	sd	s1,8(sp)
    800025a4:	1000                	addi	s0,sp,32
    800025a6:	84aa                	mv	s1,a0
    acquire(&p->lock);
    800025a8:	ffffe097          	auipc	ra,0xffffe
    800025ac:	6f6080e7          	jalr	1782(ra) # 80000c9e <acquire>
    p->killed = 1;
    800025b0:	4785                	li	a5,1
    800025b2:	d49c                	sw	a5,40(s1)
    release(&p->lock);
    800025b4:	8526                	mv	a0,s1
    800025b6:	ffffe097          	auipc	ra,0xffffe
    800025ba:	79c080e7          	jalr	1948(ra) # 80000d52 <release>
}
    800025be:	60e2                	ld	ra,24(sp)
    800025c0:	6442                	ld	s0,16(sp)
    800025c2:	64a2                	ld	s1,8(sp)
    800025c4:	6105                	addi	sp,sp,32
    800025c6:	8082                	ret

00000000800025c8 <killed>:

int killed(struct proc *p)
{
    800025c8:	1101                	addi	sp,sp,-32
    800025ca:	ec06                	sd	ra,24(sp)
    800025cc:	e822                	sd	s0,16(sp)
    800025ce:	e426                	sd	s1,8(sp)
    800025d0:	e04a                	sd	s2,0(sp)
    800025d2:	1000                	addi	s0,sp,32
    800025d4:	84aa                	mv	s1,a0
    int k;

    acquire(&p->lock);
    800025d6:	ffffe097          	auipc	ra,0xffffe
    800025da:	6c8080e7          	jalr	1736(ra) # 80000c9e <acquire>
    k = p->killed;
    800025de:	0284a903          	lw	s2,40(s1)
    release(&p->lock);
    800025e2:	8526                	mv	a0,s1
    800025e4:	ffffe097          	auipc	ra,0xffffe
    800025e8:	76e080e7          	jalr	1902(ra) # 80000d52 <release>
    return k;
}
    800025ec:	854a                	mv	a0,s2
    800025ee:	60e2                	ld	ra,24(sp)
    800025f0:	6442                	ld	s0,16(sp)
    800025f2:	64a2                	ld	s1,8(sp)
    800025f4:	6902                	ld	s2,0(sp)
    800025f6:	6105                	addi	sp,sp,32
    800025f8:	8082                	ret

00000000800025fa <wait>:
{
    800025fa:	715d                	addi	sp,sp,-80
    800025fc:	e486                	sd	ra,72(sp)
    800025fe:	e0a2                	sd	s0,64(sp)
    80002600:	fc26                	sd	s1,56(sp)
    80002602:	f84a                	sd	s2,48(sp)
    80002604:	f44e                	sd	s3,40(sp)
    80002606:	f052                	sd	s4,32(sp)
    80002608:	ec56                	sd	s5,24(sp)
    8000260a:	e85a                	sd	s6,16(sp)
    8000260c:	e45e                	sd	s7,8(sp)
    8000260e:	e062                	sd	s8,0(sp)
    80002610:	0880                	addi	s0,sp,80
    80002612:	8b2a                	mv	s6,a0
    struct proc *p = myproc();
    80002614:	fffff097          	auipc	ra,0xfffff
    80002618:	55e080e7          	jalr	1374(ra) # 80001b72 <myproc>
    8000261c:	892a                	mv	s2,a0
    acquire(&wait_lock);
    8000261e:	0000f517          	auipc	a0,0xf
    80002622:	aca50513          	addi	a0,a0,-1334 # 800110e8 <wait_lock>
    80002626:	ffffe097          	auipc	ra,0xffffe
    8000262a:	678080e7          	jalr	1656(ra) # 80000c9e <acquire>
        havekids = 0;
    8000262e:	4b81                	li	s7,0
                if (pp->state == ZOMBIE)
    80002630:	4a15                	li	s4,5
                havekids = 1;
    80002632:	4a85                	li	s5,1
        for (pp = proc; pp < &proc[NPROC]; pp++)
    80002634:	00014997          	auipc	s3,0x14
    80002638:	4cc98993          	addi	s3,s3,1228 # 80016b00 <tickslock>
        sleep(p, &wait_lock); // DOC: wait-sleep
    8000263c:	0000fc17          	auipc	s8,0xf
    80002640:	aacc0c13          	addi	s8,s8,-1364 # 800110e8 <wait_lock>
        havekids = 0;
    80002644:	875e                	mv	a4,s7
        for (pp = proc; pp < &proc[NPROC]; pp++)
    80002646:	0000f497          	auipc	s1,0xf
    8000264a:	aba48493          	addi	s1,s1,-1350 # 80011100 <proc>
    8000264e:	a0bd                	j	800026bc <wait+0xc2>
                    pid = pp->pid;
    80002650:	0304a983          	lw	s3,48(s1)
                    if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002654:	000b0e63          	beqz	s6,80002670 <wait+0x76>
    80002658:	4691                	li	a3,4
    8000265a:	02c48613          	addi	a2,s1,44
    8000265e:	85da                	mv	a1,s6
    80002660:	05093503          	ld	a0,80(s2)
    80002664:	fffff097          	auipc	ra,0xfffff
    80002668:	0d0080e7          	jalr	208(ra) # 80001734 <copyout>
    8000266c:	02054563          	bltz	a0,80002696 <wait+0x9c>
                    freeproc(pp);
    80002670:	8526                	mv	a0,s1
    80002672:	fffff097          	auipc	ra,0xfffff
    80002676:	6b2080e7          	jalr	1714(ra) # 80001d24 <freeproc>
                    release(&pp->lock);
    8000267a:	8526                	mv	a0,s1
    8000267c:	ffffe097          	auipc	ra,0xffffe
    80002680:	6d6080e7          	jalr	1750(ra) # 80000d52 <release>
                    release(&wait_lock);
    80002684:	0000f517          	auipc	a0,0xf
    80002688:	a6450513          	addi	a0,a0,-1436 # 800110e8 <wait_lock>
    8000268c:	ffffe097          	auipc	ra,0xffffe
    80002690:	6c6080e7          	jalr	1734(ra) # 80000d52 <release>
                    return pid;
    80002694:	a0b5                	j	80002700 <wait+0x106>
                        release(&pp->lock);
    80002696:	8526                	mv	a0,s1
    80002698:	ffffe097          	auipc	ra,0xffffe
    8000269c:	6ba080e7          	jalr	1722(ra) # 80000d52 <release>
                        release(&wait_lock);
    800026a0:	0000f517          	auipc	a0,0xf
    800026a4:	a4850513          	addi	a0,a0,-1464 # 800110e8 <wait_lock>
    800026a8:	ffffe097          	auipc	ra,0xffffe
    800026ac:	6aa080e7          	jalr	1706(ra) # 80000d52 <release>
                        return -1;
    800026b0:	59fd                	li	s3,-1
    800026b2:	a0b9                	j	80002700 <wait+0x106>
        for (pp = proc; pp < &proc[NPROC]; pp++)
    800026b4:	16848493          	addi	s1,s1,360
    800026b8:	03348463          	beq	s1,s3,800026e0 <wait+0xe6>
            if (pp->parent == p)
    800026bc:	7c9c                	ld	a5,56(s1)
    800026be:	ff279be3          	bne	a5,s2,800026b4 <wait+0xba>
                acquire(&pp->lock);
    800026c2:	8526                	mv	a0,s1
    800026c4:	ffffe097          	auipc	ra,0xffffe
    800026c8:	5da080e7          	jalr	1498(ra) # 80000c9e <acquire>
                if (pp->state == ZOMBIE)
    800026cc:	4c9c                	lw	a5,24(s1)
    800026ce:	f94781e3          	beq	a5,s4,80002650 <wait+0x56>
                release(&pp->lock);
    800026d2:	8526                	mv	a0,s1
    800026d4:	ffffe097          	auipc	ra,0xffffe
    800026d8:	67e080e7          	jalr	1662(ra) # 80000d52 <release>
                havekids = 1;
    800026dc:	8756                	mv	a4,s5
    800026de:	bfd9                	j	800026b4 <wait+0xba>
        if (!havekids || killed(p))
    800026e0:	c719                	beqz	a4,800026ee <wait+0xf4>
    800026e2:	854a                	mv	a0,s2
    800026e4:	00000097          	auipc	ra,0x0
    800026e8:	ee4080e7          	jalr	-284(ra) # 800025c8 <killed>
    800026ec:	c51d                	beqz	a0,8000271a <wait+0x120>
            release(&wait_lock);
    800026ee:	0000f517          	auipc	a0,0xf
    800026f2:	9fa50513          	addi	a0,a0,-1542 # 800110e8 <wait_lock>
    800026f6:	ffffe097          	auipc	ra,0xffffe
    800026fa:	65c080e7          	jalr	1628(ra) # 80000d52 <release>
            return -1;
    800026fe:	59fd                	li	s3,-1
}
    80002700:	854e                	mv	a0,s3
    80002702:	60a6                	ld	ra,72(sp)
    80002704:	6406                	ld	s0,64(sp)
    80002706:	74e2                	ld	s1,56(sp)
    80002708:	7942                	ld	s2,48(sp)
    8000270a:	79a2                	ld	s3,40(sp)
    8000270c:	7a02                	ld	s4,32(sp)
    8000270e:	6ae2                	ld	s5,24(sp)
    80002710:	6b42                	ld	s6,16(sp)
    80002712:	6ba2                	ld	s7,8(sp)
    80002714:	6c02                	ld	s8,0(sp)
    80002716:	6161                	addi	sp,sp,80
    80002718:	8082                	ret
        sleep(p, &wait_lock); // DOC: wait-sleep
    8000271a:	85e2                	mv	a1,s8
    8000271c:	854a                	mv	a0,s2
    8000271e:	00000097          	auipc	ra,0x0
    80002722:	c02080e7          	jalr	-1022(ra) # 80002320 <sleep>
        havekids = 0;
    80002726:	bf39                	j	80002644 <wait+0x4a>

0000000080002728 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002728:	7179                	addi	sp,sp,-48
    8000272a:	f406                	sd	ra,40(sp)
    8000272c:	f022                	sd	s0,32(sp)
    8000272e:	ec26                	sd	s1,24(sp)
    80002730:	e84a                	sd	s2,16(sp)
    80002732:	e44e                	sd	s3,8(sp)
    80002734:	e052                	sd	s4,0(sp)
    80002736:	1800                	addi	s0,sp,48
    80002738:	84aa                	mv	s1,a0
    8000273a:	892e                	mv	s2,a1
    8000273c:	89b2                	mv	s3,a2
    8000273e:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    80002740:	fffff097          	auipc	ra,0xfffff
    80002744:	432080e7          	jalr	1074(ra) # 80001b72 <myproc>
    if (user_dst)
    80002748:	c08d                	beqz	s1,8000276a <either_copyout+0x42>
    {
        return copyout(p->pagetable, dst, src, len);
    8000274a:	86d2                	mv	a3,s4
    8000274c:	864e                	mv	a2,s3
    8000274e:	85ca                	mv	a1,s2
    80002750:	6928                	ld	a0,80(a0)
    80002752:	fffff097          	auipc	ra,0xfffff
    80002756:	fe2080e7          	jalr	-30(ra) # 80001734 <copyout>
    else
    {
        memmove((char *)dst, src, len);
        return 0;
    }
}
    8000275a:	70a2                	ld	ra,40(sp)
    8000275c:	7402                	ld	s0,32(sp)
    8000275e:	64e2                	ld	s1,24(sp)
    80002760:	6942                	ld	s2,16(sp)
    80002762:	69a2                	ld	s3,8(sp)
    80002764:	6a02                	ld	s4,0(sp)
    80002766:	6145                	addi	sp,sp,48
    80002768:	8082                	ret
        memmove((char *)dst, src, len);
    8000276a:	000a061b          	sext.w	a2,s4
    8000276e:	85ce                	mv	a1,s3
    80002770:	854a                	mv	a0,s2
    80002772:	ffffe097          	auipc	ra,0xffffe
    80002776:	684080e7          	jalr	1668(ra) # 80000df6 <memmove>
        return 0;
    8000277a:	8526                	mv	a0,s1
    8000277c:	bff9                	j	8000275a <either_copyout+0x32>

000000008000277e <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000277e:	7179                	addi	sp,sp,-48
    80002780:	f406                	sd	ra,40(sp)
    80002782:	f022                	sd	s0,32(sp)
    80002784:	ec26                	sd	s1,24(sp)
    80002786:	e84a                	sd	s2,16(sp)
    80002788:	e44e                	sd	s3,8(sp)
    8000278a:	e052                	sd	s4,0(sp)
    8000278c:	1800                	addi	s0,sp,48
    8000278e:	892a                	mv	s2,a0
    80002790:	84ae                	mv	s1,a1
    80002792:	89b2                	mv	s3,a2
    80002794:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    80002796:	fffff097          	auipc	ra,0xfffff
    8000279a:	3dc080e7          	jalr	988(ra) # 80001b72 <myproc>
    if (user_src)
    8000279e:	c08d                	beqz	s1,800027c0 <either_copyin+0x42>
    {
        return copyin(p->pagetable, dst, src, len);
    800027a0:	86d2                	mv	a3,s4
    800027a2:	864e                	mv	a2,s3
    800027a4:	85ca                	mv	a1,s2
    800027a6:	6928                	ld	a0,80(a0)
    800027a8:	fffff097          	auipc	ra,0xfffff
    800027ac:	018080e7          	jalr	24(ra) # 800017c0 <copyin>
    else
    {
        memmove(dst, (char *)src, len);
        return 0;
    }
}
    800027b0:	70a2                	ld	ra,40(sp)
    800027b2:	7402                	ld	s0,32(sp)
    800027b4:	64e2                	ld	s1,24(sp)
    800027b6:	6942                	ld	s2,16(sp)
    800027b8:	69a2                	ld	s3,8(sp)
    800027ba:	6a02                	ld	s4,0(sp)
    800027bc:	6145                	addi	sp,sp,48
    800027be:	8082                	ret
        memmove(dst, (char *)src, len);
    800027c0:	000a061b          	sext.w	a2,s4
    800027c4:	85ce                	mv	a1,s3
    800027c6:	854a                	mv	a0,s2
    800027c8:	ffffe097          	auipc	ra,0xffffe
    800027cc:	62e080e7          	jalr	1582(ra) # 80000df6 <memmove>
        return 0;
    800027d0:	8526                	mv	a0,s1
    800027d2:	bff9                	j	800027b0 <either_copyin+0x32>

00000000800027d4 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    800027d4:	715d                	addi	sp,sp,-80
    800027d6:	e486                	sd	ra,72(sp)
    800027d8:	e0a2                	sd	s0,64(sp)
    800027da:	fc26                	sd	s1,56(sp)
    800027dc:	f84a                	sd	s2,48(sp)
    800027de:	f44e                	sd	s3,40(sp)
    800027e0:	f052                	sd	s4,32(sp)
    800027e2:	ec56                	sd	s5,24(sp)
    800027e4:	e85a                	sd	s6,16(sp)
    800027e6:	e45e                	sd	s7,8(sp)
    800027e8:	0880                	addi	s0,sp,80
        [RUNNING] "run   ",
        [ZOMBIE] "zombie"};
    struct proc *p;
    char *state;

    printf("\n");
    800027ea:	00006517          	auipc	a0,0x6
    800027ee:	89e50513          	addi	a0,a0,-1890 # 80008088 <digits+0x38>
    800027f2:	ffffe097          	auipc	ra,0xffffe
    800027f6:	daa080e7          	jalr	-598(ra) # 8000059c <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    800027fa:	0000f497          	auipc	s1,0xf
    800027fe:	a5e48493          	addi	s1,s1,-1442 # 80011258 <proc+0x158>
    80002802:	00014917          	auipc	s2,0x14
    80002806:	45690913          	addi	s2,s2,1110 # 80016c58 <bcache+0x140>
    {
        if (p->state == UNUSED)
            continue;
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000280a:	4b15                	li	s6,5
            state = states[p->state];
        else
            state = "???";
    8000280c:	00006997          	auipc	s3,0x6
    80002810:	ab498993          	addi	s3,s3,-1356 # 800082c0 <digits+0x270>
        printf("%d <%s %s", p->pid, state, p->name);
    80002814:	00006a97          	auipc	s5,0x6
    80002818:	ab4a8a93          	addi	s5,s5,-1356 # 800082c8 <digits+0x278>
        printf("\n");
    8000281c:	00006a17          	auipc	s4,0x6
    80002820:	86ca0a13          	addi	s4,s4,-1940 # 80008088 <digits+0x38>
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002824:	00006b97          	auipc	s7,0x6
    80002828:	bb4b8b93          	addi	s7,s7,-1100 # 800083d8 <states.0>
    8000282c:	a00d                	j	8000284e <procdump+0x7a>
        printf("%d <%s %s", p->pid, state, p->name);
    8000282e:	ed86a583          	lw	a1,-296(a3)
    80002832:	8556                	mv	a0,s5
    80002834:	ffffe097          	auipc	ra,0xffffe
    80002838:	d68080e7          	jalr	-664(ra) # 8000059c <printf>
        printf("\n");
    8000283c:	8552                	mv	a0,s4
    8000283e:	ffffe097          	auipc	ra,0xffffe
    80002842:	d5e080e7          	jalr	-674(ra) # 8000059c <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    80002846:	16848493          	addi	s1,s1,360
    8000284a:	03248263          	beq	s1,s2,8000286e <procdump+0x9a>
        if (p->state == UNUSED)
    8000284e:	86a6                	mv	a3,s1
    80002850:	ec04a783          	lw	a5,-320(s1)
    80002854:	dbed                	beqz	a5,80002846 <procdump+0x72>
            state = "???";
    80002856:	864e                	mv	a2,s3
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002858:	fcfb6be3          	bltu	s6,a5,8000282e <procdump+0x5a>
    8000285c:	02079713          	slli	a4,a5,0x20
    80002860:	01d75793          	srli	a5,a4,0x1d
    80002864:	97de                	add	a5,a5,s7
    80002866:	6390                	ld	a2,0(a5)
    80002868:	f279                	bnez	a2,8000282e <procdump+0x5a>
            state = "???";
    8000286a:	864e                	mv	a2,s3
    8000286c:	b7c9                	j	8000282e <procdump+0x5a>
    }
}
    8000286e:	60a6                	ld	ra,72(sp)
    80002870:	6406                	ld	s0,64(sp)
    80002872:	74e2                	ld	s1,56(sp)
    80002874:	7942                	ld	s2,48(sp)
    80002876:	79a2                	ld	s3,40(sp)
    80002878:	7a02                	ld	s4,32(sp)
    8000287a:	6ae2                	ld	s5,24(sp)
    8000287c:	6b42                	ld	s6,16(sp)
    8000287e:	6ba2                	ld	s7,8(sp)
    80002880:	6161                	addi	sp,sp,80
    80002882:	8082                	ret

0000000080002884 <schedls>:

void schedls()
{
    80002884:	1141                	addi	sp,sp,-16
    80002886:	e406                	sd	ra,8(sp)
    80002888:	e022                	sd	s0,0(sp)
    8000288a:	0800                	addi	s0,sp,16
    printf("[ ]\tScheduler Name\tScheduler ID\n");
    8000288c:	00006517          	auipc	a0,0x6
    80002890:	a4c50513          	addi	a0,a0,-1460 # 800082d8 <digits+0x288>
    80002894:	ffffe097          	auipc	ra,0xffffe
    80002898:	d08080e7          	jalr	-760(ra) # 8000059c <printf>
    printf("====================================\n");
    8000289c:	00006517          	auipc	a0,0x6
    800028a0:	a6450513          	addi	a0,a0,-1436 # 80008300 <digits+0x2b0>
    800028a4:	ffffe097          	auipc	ra,0xffffe
    800028a8:	cf8080e7          	jalr	-776(ra) # 8000059c <printf>
    for (int i = 0; i < SCHEDC; i++)
    {
        if (available_schedulers[i].impl == sched_pointer)
    800028ac:	00006717          	auipc	a4,0x6
    800028b0:	13c73703          	ld	a4,316(a4) # 800089e8 <available_schedulers+0x10>
    800028b4:	00006797          	auipc	a5,0x6
    800028b8:	0d47b783          	ld	a5,212(a5) # 80008988 <sched_pointer>
    800028bc:	04f70663          	beq	a4,a5,80002908 <schedls+0x84>
        {
            printf("[*]\t");
        }
        else
        {
            printf("   \t");
    800028c0:	00006517          	auipc	a0,0x6
    800028c4:	a7050513          	addi	a0,a0,-1424 # 80008330 <digits+0x2e0>
    800028c8:	ffffe097          	auipc	ra,0xffffe
    800028cc:	cd4080e7          	jalr	-812(ra) # 8000059c <printf>
        }
        printf("%s\t%d\n", available_schedulers[i].name, available_schedulers[i].id);
    800028d0:	00006617          	auipc	a2,0x6
    800028d4:	12062603          	lw	a2,288(a2) # 800089f0 <available_schedulers+0x18>
    800028d8:	00006597          	auipc	a1,0x6
    800028dc:	10058593          	addi	a1,a1,256 # 800089d8 <available_schedulers>
    800028e0:	00006517          	auipc	a0,0x6
    800028e4:	a5850513          	addi	a0,a0,-1448 # 80008338 <digits+0x2e8>
    800028e8:	ffffe097          	auipc	ra,0xffffe
    800028ec:	cb4080e7          	jalr	-844(ra) # 8000059c <printf>
    }
    printf("\n*: current scheduler\n\n");
    800028f0:	00006517          	auipc	a0,0x6
    800028f4:	a5050513          	addi	a0,a0,-1456 # 80008340 <digits+0x2f0>
    800028f8:	ffffe097          	auipc	ra,0xffffe
    800028fc:	ca4080e7          	jalr	-860(ra) # 8000059c <printf>
}
    80002900:	60a2                	ld	ra,8(sp)
    80002902:	6402                	ld	s0,0(sp)
    80002904:	0141                	addi	sp,sp,16
    80002906:	8082                	ret
            printf("[*]\t");
    80002908:	00006517          	auipc	a0,0x6
    8000290c:	a2050513          	addi	a0,a0,-1504 # 80008328 <digits+0x2d8>
    80002910:	ffffe097          	auipc	ra,0xffffe
    80002914:	c8c080e7          	jalr	-884(ra) # 8000059c <printf>
    80002918:	bf65                	j	800028d0 <schedls+0x4c>

000000008000291a <schedset>:

void schedset(int id)
{
    8000291a:	1141                	addi	sp,sp,-16
    8000291c:	e406                	sd	ra,8(sp)
    8000291e:	e022                	sd	s0,0(sp)
    80002920:	0800                	addi	s0,sp,16
    if (id < 0 || SCHEDC <= id)
    80002922:	e90d                	bnez	a0,80002954 <schedset+0x3a>
    {
        printf("Scheduler unchanged: ID out of range\n");
        return;
    }
    sched_pointer = available_schedulers[id].impl;
    80002924:	00006797          	auipc	a5,0x6
    80002928:	0c47b783          	ld	a5,196(a5) # 800089e8 <available_schedulers+0x10>
    8000292c:	00006717          	auipc	a4,0x6
    80002930:	04f73e23          	sd	a5,92(a4) # 80008988 <sched_pointer>
    printf("Scheduler successfully changed to %s\n", available_schedulers[id].name);
    80002934:	00006597          	auipc	a1,0x6
    80002938:	0a458593          	addi	a1,a1,164 # 800089d8 <available_schedulers>
    8000293c:	00006517          	auipc	a0,0x6
    80002940:	a4450513          	addi	a0,a0,-1468 # 80008380 <digits+0x330>
    80002944:	ffffe097          	auipc	ra,0xffffe
    80002948:	c58080e7          	jalr	-936(ra) # 8000059c <printf>
    8000294c:	60a2                	ld	ra,8(sp)
    8000294e:	6402                	ld	s0,0(sp)
    80002950:	0141                	addi	sp,sp,16
    80002952:	8082                	ret
        printf("Scheduler unchanged: ID out of range\n");
    80002954:	00006517          	auipc	a0,0x6
    80002958:	a0450513          	addi	a0,a0,-1532 # 80008358 <digits+0x308>
    8000295c:	ffffe097          	auipc	ra,0xffffe
    80002960:	c40080e7          	jalr	-960(ra) # 8000059c <printf>
        return;
    80002964:	b7e5                	j	8000294c <schedset+0x32>

0000000080002966 <swtch>:
    80002966:	00153023          	sd	ra,0(a0)
    8000296a:	00253423          	sd	sp,8(a0)
    8000296e:	e900                	sd	s0,16(a0)
    80002970:	ed04                	sd	s1,24(a0)
    80002972:	03253023          	sd	s2,32(a0)
    80002976:	03353423          	sd	s3,40(a0)
    8000297a:	03453823          	sd	s4,48(a0)
    8000297e:	03553c23          	sd	s5,56(a0)
    80002982:	05653023          	sd	s6,64(a0)
    80002986:	05753423          	sd	s7,72(a0)
    8000298a:	05853823          	sd	s8,80(a0)
    8000298e:	05953c23          	sd	s9,88(a0)
    80002992:	07a53023          	sd	s10,96(a0)
    80002996:	07b53423          	sd	s11,104(a0)
    8000299a:	0005b083          	ld	ra,0(a1)
    8000299e:	0085b103          	ld	sp,8(a1)
    800029a2:	6980                	ld	s0,16(a1)
    800029a4:	6d84                	ld	s1,24(a1)
    800029a6:	0205b903          	ld	s2,32(a1)
    800029aa:	0285b983          	ld	s3,40(a1)
    800029ae:	0305ba03          	ld	s4,48(a1)
    800029b2:	0385ba83          	ld	s5,56(a1)
    800029b6:	0405bb03          	ld	s6,64(a1)
    800029ba:	0485bb83          	ld	s7,72(a1)
    800029be:	0505bc03          	ld	s8,80(a1)
    800029c2:	0585bc83          	ld	s9,88(a1)
    800029c6:	0605bd03          	ld	s10,96(a1)
    800029ca:	0685bd83          	ld	s11,104(a1)
    800029ce:	8082                	ret

00000000800029d0 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800029d0:	1141                	addi	sp,sp,-16
    800029d2:	e406                	sd	ra,8(sp)
    800029d4:	e022                	sd	s0,0(sp)
    800029d6:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800029d8:	00006597          	auipc	a1,0x6
    800029dc:	a3058593          	addi	a1,a1,-1488 # 80008408 <states.0+0x30>
    800029e0:	00014517          	auipc	a0,0x14
    800029e4:	12050513          	addi	a0,a0,288 # 80016b00 <tickslock>
    800029e8:	ffffe097          	auipc	ra,0xffffe
    800029ec:	226080e7          	jalr	550(ra) # 80000c0e <initlock>
}
    800029f0:	60a2                	ld	ra,8(sp)
    800029f2:	6402                	ld	s0,0(sp)
    800029f4:	0141                	addi	sp,sp,16
    800029f6:	8082                	ret

00000000800029f8 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800029f8:	1141                	addi	sp,sp,-16
    800029fa:	e422                	sd	s0,8(sp)
    800029fc:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029fe:	00003797          	auipc	a5,0x3
    80002a02:	5f278793          	addi	a5,a5,1522 # 80005ff0 <kernelvec>
    80002a06:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002a0a:	6422                	ld	s0,8(sp)
    80002a0c:	0141                	addi	sp,sp,16
    80002a0e:	8082                	ret

0000000080002a10 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002a10:	1141                	addi	sp,sp,-16
    80002a12:	e406                	sd	ra,8(sp)
    80002a14:	e022                	sd	s0,0(sp)
    80002a16:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002a18:	fffff097          	auipc	ra,0xfffff
    80002a1c:	15a080e7          	jalr	346(ra) # 80001b72 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a20:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002a24:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a26:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002a2a:	00004697          	auipc	a3,0x4
    80002a2e:	5d668693          	addi	a3,a3,1494 # 80007000 <_trampoline>
    80002a32:	00004717          	auipc	a4,0x4
    80002a36:	5ce70713          	addi	a4,a4,1486 # 80007000 <_trampoline>
    80002a3a:	8f15                	sub	a4,a4,a3
    80002a3c:	040007b7          	lui	a5,0x4000
    80002a40:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002a42:	07b2                	slli	a5,a5,0xc
    80002a44:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a46:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002a4a:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002a4c:	18002673          	csrr	a2,satp
    80002a50:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002a52:	6d30                	ld	a2,88(a0)
    80002a54:	6138                	ld	a4,64(a0)
    80002a56:	6585                	lui	a1,0x1
    80002a58:	972e                	add	a4,a4,a1
    80002a5a:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002a5c:	6d38                	ld	a4,88(a0)
    80002a5e:	00000617          	auipc	a2,0x0
    80002a62:	13060613          	addi	a2,a2,304 # 80002b8e <usertrap>
    80002a66:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002a68:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a6a:	8612                	mv	a2,tp
    80002a6c:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a6e:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a72:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a76:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a7a:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a7e:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a80:	6f18                	ld	a4,24(a4)
    80002a82:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a86:	6928                	ld	a0,80(a0)
    80002a88:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002a8a:	00004717          	auipc	a4,0x4
    80002a8e:	61270713          	addi	a4,a4,1554 # 8000709c <userret>
    80002a92:	8f15                	sub	a4,a4,a3
    80002a94:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002a96:	577d                	li	a4,-1
    80002a98:	177e                	slli	a4,a4,0x3f
    80002a9a:	8d59                	or	a0,a0,a4
    80002a9c:	9782                	jalr	a5
}
    80002a9e:	60a2                	ld	ra,8(sp)
    80002aa0:	6402                	ld	s0,0(sp)
    80002aa2:	0141                	addi	sp,sp,16
    80002aa4:	8082                	ret

0000000080002aa6 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002aa6:	1101                	addi	sp,sp,-32
    80002aa8:	ec06                	sd	ra,24(sp)
    80002aaa:	e822                	sd	s0,16(sp)
    80002aac:	e426                	sd	s1,8(sp)
    80002aae:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002ab0:	00014497          	auipc	s1,0x14
    80002ab4:	05048493          	addi	s1,s1,80 # 80016b00 <tickslock>
    80002ab8:	8526                	mv	a0,s1
    80002aba:	ffffe097          	auipc	ra,0xffffe
    80002abe:	1e4080e7          	jalr	484(ra) # 80000c9e <acquire>
  ticks++;
    80002ac2:	00006517          	auipc	a0,0x6
    80002ac6:	f9e50513          	addi	a0,a0,-98 # 80008a60 <ticks>
    80002aca:	411c                	lw	a5,0(a0)
    80002acc:	2785                	addiw	a5,a5,1
    80002ace:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002ad0:	00000097          	auipc	ra,0x0
    80002ad4:	8b4080e7          	jalr	-1868(ra) # 80002384 <wakeup>
  release(&tickslock);
    80002ad8:	8526                	mv	a0,s1
    80002ada:	ffffe097          	auipc	ra,0xffffe
    80002ade:	278080e7          	jalr	632(ra) # 80000d52 <release>
}
    80002ae2:	60e2                	ld	ra,24(sp)
    80002ae4:	6442                	ld	s0,16(sp)
    80002ae6:	64a2                	ld	s1,8(sp)
    80002ae8:	6105                	addi	sp,sp,32
    80002aea:	8082                	ret

0000000080002aec <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002aec:	1101                	addi	sp,sp,-32
    80002aee:	ec06                	sd	ra,24(sp)
    80002af0:	e822                	sd	s0,16(sp)
    80002af2:	e426                	sd	s1,8(sp)
    80002af4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002af6:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002afa:	00074d63          	bltz	a4,80002b14 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002afe:	57fd                	li	a5,-1
    80002b00:	17fe                	slli	a5,a5,0x3f
    80002b02:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002b04:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002b06:	06f70363          	beq	a4,a5,80002b6c <devintr+0x80>
  }
}
    80002b0a:	60e2                	ld	ra,24(sp)
    80002b0c:	6442                	ld	s0,16(sp)
    80002b0e:	64a2                	ld	s1,8(sp)
    80002b10:	6105                	addi	sp,sp,32
    80002b12:	8082                	ret
     (scause & 0xff) == 9){
    80002b14:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    80002b18:	46a5                	li	a3,9
    80002b1a:	fed792e3          	bne	a5,a3,80002afe <devintr+0x12>
    int irq = plic_claim();
    80002b1e:	00003097          	auipc	ra,0x3
    80002b22:	5da080e7          	jalr	1498(ra) # 800060f8 <plic_claim>
    80002b26:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002b28:	47a9                	li	a5,10
    80002b2a:	02f50763          	beq	a0,a5,80002b58 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002b2e:	4785                	li	a5,1
    80002b30:	02f50963          	beq	a0,a5,80002b62 <devintr+0x76>
    return 1;
    80002b34:	4505                	li	a0,1
    } else if(irq){
    80002b36:	d8f1                	beqz	s1,80002b0a <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002b38:	85a6                	mv	a1,s1
    80002b3a:	00006517          	auipc	a0,0x6
    80002b3e:	8d650513          	addi	a0,a0,-1834 # 80008410 <states.0+0x38>
    80002b42:	ffffe097          	auipc	ra,0xffffe
    80002b46:	a5a080e7          	jalr	-1446(ra) # 8000059c <printf>
      plic_complete(irq);
    80002b4a:	8526                	mv	a0,s1
    80002b4c:	00003097          	auipc	ra,0x3
    80002b50:	5d0080e7          	jalr	1488(ra) # 8000611c <plic_complete>
    return 1;
    80002b54:	4505                	li	a0,1
    80002b56:	bf55                	j	80002b0a <devintr+0x1e>
      uartintr();
    80002b58:	ffffe097          	auipc	ra,0xffffe
    80002b5c:	e52080e7          	jalr	-430(ra) # 800009aa <uartintr>
    80002b60:	b7ed                	j	80002b4a <devintr+0x5e>
      virtio_disk_intr();
    80002b62:	00004097          	auipc	ra,0x4
    80002b66:	a82080e7          	jalr	-1406(ra) # 800065e4 <virtio_disk_intr>
    80002b6a:	b7c5                	j	80002b4a <devintr+0x5e>
    if(cpuid() == 0){
    80002b6c:	fffff097          	auipc	ra,0xfffff
    80002b70:	fda080e7          	jalr	-38(ra) # 80001b46 <cpuid>
    80002b74:	c901                	beqz	a0,80002b84 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b76:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b7a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b7c:	14479073          	csrw	sip,a5
    return 2;
    80002b80:	4509                	li	a0,2
    80002b82:	b761                	j	80002b0a <devintr+0x1e>
      clockintr();
    80002b84:	00000097          	auipc	ra,0x0
    80002b88:	f22080e7          	jalr	-222(ra) # 80002aa6 <clockintr>
    80002b8c:	b7ed                	j	80002b76 <devintr+0x8a>

0000000080002b8e <usertrap>:
{
    80002b8e:	1101                	addi	sp,sp,-32
    80002b90:	ec06                	sd	ra,24(sp)
    80002b92:	e822                	sd	s0,16(sp)
    80002b94:	e426                	sd	s1,8(sp)
    80002b96:	e04a                	sd	s2,0(sp)
    80002b98:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b9a:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002b9e:	1007f793          	andi	a5,a5,256
    80002ba2:	e3b1                	bnez	a5,80002be6 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ba4:	00003797          	auipc	a5,0x3
    80002ba8:	44c78793          	addi	a5,a5,1100 # 80005ff0 <kernelvec>
    80002bac:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002bb0:	fffff097          	auipc	ra,0xfffff
    80002bb4:	fc2080e7          	jalr	-62(ra) # 80001b72 <myproc>
    80002bb8:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002bba:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bbc:	14102773          	csrr	a4,sepc
    80002bc0:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bc2:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002bc6:	47a1                	li	a5,8
    80002bc8:	02f70763          	beq	a4,a5,80002bf6 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002bcc:	00000097          	auipc	ra,0x0
    80002bd0:	f20080e7          	jalr	-224(ra) # 80002aec <devintr>
    80002bd4:	892a                	mv	s2,a0
    80002bd6:	c151                	beqz	a0,80002c5a <usertrap+0xcc>
  if(killed(p))
    80002bd8:	8526                	mv	a0,s1
    80002bda:	00000097          	auipc	ra,0x0
    80002bde:	9ee080e7          	jalr	-1554(ra) # 800025c8 <killed>
    80002be2:	c929                	beqz	a0,80002c34 <usertrap+0xa6>
    80002be4:	a099                	j	80002c2a <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002be6:	00006517          	auipc	a0,0x6
    80002bea:	84a50513          	addi	a0,a0,-1974 # 80008430 <states.0+0x58>
    80002bee:	ffffe097          	auipc	ra,0xffffe
    80002bf2:	952080e7          	jalr	-1710(ra) # 80000540 <panic>
    if(killed(p))
    80002bf6:	00000097          	auipc	ra,0x0
    80002bfa:	9d2080e7          	jalr	-1582(ra) # 800025c8 <killed>
    80002bfe:	e921                	bnez	a0,80002c4e <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002c00:	6cb8                	ld	a4,88(s1)
    80002c02:	6f1c                	ld	a5,24(a4)
    80002c04:	0791                	addi	a5,a5,4
    80002c06:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c08:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002c0c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c10:	10079073          	csrw	sstatus,a5
    syscall();
    80002c14:	00000097          	auipc	ra,0x0
    80002c18:	2d4080e7          	jalr	724(ra) # 80002ee8 <syscall>
  if(killed(p))
    80002c1c:	8526                	mv	a0,s1
    80002c1e:	00000097          	auipc	ra,0x0
    80002c22:	9aa080e7          	jalr	-1622(ra) # 800025c8 <killed>
    80002c26:	c911                	beqz	a0,80002c3a <usertrap+0xac>
    80002c28:	4901                	li	s2,0
    exit(-1);
    80002c2a:	557d                	li	a0,-1
    80002c2c:	00000097          	auipc	ra,0x0
    80002c30:	828080e7          	jalr	-2008(ra) # 80002454 <exit>
  if(which_dev == 2)
    80002c34:	4789                	li	a5,2
    80002c36:	04f90f63          	beq	s2,a5,80002c94 <usertrap+0x106>
  usertrapret();
    80002c3a:	00000097          	auipc	ra,0x0
    80002c3e:	dd6080e7          	jalr	-554(ra) # 80002a10 <usertrapret>
}
    80002c42:	60e2                	ld	ra,24(sp)
    80002c44:	6442                	ld	s0,16(sp)
    80002c46:	64a2                	ld	s1,8(sp)
    80002c48:	6902                	ld	s2,0(sp)
    80002c4a:	6105                	addi	sp,sp,32
    80002c4c:	8082                	ret
      exit(-1);
    80002c4e:	557d                	li	a0,-1
    80002c50:	00000097          	auipc	ra,0x0
    80002c54:	804080e7          	jalr	-2044(ra) # 80002454 <exit>
    80002c58:	b765                	j	80002c00 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c5a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002c5e:	5890                	lw	a2,48(s1)
    80002c60:	00005517          	auipc	a0,0x5
    80002c64:	7f050513          	addi	a0,a0,2032 # 80008450 <states.0+0x78>
    80002c68:	ffffe097          	auipc	ra,0xffffe
    80002c6c:	934080e7          	jalr	-1740(ra) # 8000059c <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c70:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c74:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c78:	00006517          	auipc	a0,0x6
    80002c7c:	80850513          	addi	a0,a0,-2040 # 80008480 <states.0+0xa8>
    80002c80:	ffffe097          	auipc	ra,0xffffe
    80002c84:	91c080e7          	jalr	-1764(ra) # 8000059c <printf>
    setkilled(p);
    80002c88:	8526                	mv	a0,s1
    80002c8a:	00000097          	auipc	ra,0x0
    80002c8e:	912080e7          	jalr	-1774(ra) # 8000259c <setkilled>
    80002c92:	b769                	j	80002c1c <usertrap+0x8e>
    yield();
    80002c94:	fffff097          	auipc	ra,0xfffff
    80002c98:	650080e7          	jalr	1616(ra) # 800022e4 <yield>
    80002c9c:	bf79                	j	80002c3a <usertrap+0xac>

0000000080002c9e <kerneltrap>:
{
    80002c9e:	7179                	addi	sp,sp,-48
    80002ca0:	f406                	sd	ra,40(sp)
    80002ca2:	f022                	sd	s0,32(sp)
    80002ca4:	ec26                	sd	s1,24(sp)
    80002ca6:	e84a                	sd	s2,16(sp)
    80002ca8:	e44e                	sd	s3,8(sp)
    80002caa:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cac:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cb0:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cb4:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002cb8:	1004f793          	andi	a5,s1,256
    80002cbc:	cb85                	beqz	a5,80002cec <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cbe:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002cc2:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002cc4:	ef85                	bnez	a5,80002cfc <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002cc6:	00000097          	auipc	ra,0x0
    80002cca:	e26080e7          	jalr	-474(ra) # 80002aec <devintr>
    80002cce:	cd1d                	beqz	a0,80002d0c <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002cd0:	4789                	li	a5,2
    80002cd2:	06f50a63          	beq	a0,a5,80002d46 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002cd6:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cda:	10049073          	csrw	sstatus,s1
}
    80002cde:	70a2                	ld	ra,40(sp)
    80002ce0:	7402                	ld	s0,32(sp)
    80002ce2:	64e2                	ld	s1,24(sp)
    80002ce4:	6942                	ld	s2,16(sp)
    80002ce6:	69a2                	ld	s3,8(sp)
    80002ce8:	6145                	addi	sp,sp,48
    80002cea:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002cec:	00005517          	auipc	a0,0x5
    80002cf0:	7b450513          	addi	a0,a0,1972 # 800084a0 <states.0+0xc8>
    80002cf4:	ffffe097          	auipc	ra,0xffffe
    80002cf8:	84c080e7          	jalr	-1972(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002cfc:	00005517          	auipc	a0,0x5
    80002d00:	7cc50513          	addi	a0,a0,1996 # 800084c8 <states.0+0xf0>
    80002d04:	ffffe097          	auipc	ra,0xffffe
    80002d08:	83c080e7          	jalr	-1988(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002d0c:	85ce                	mv	a1,s3
    80002d0e:	00005517          	auipc	a0,0x5
    80002d12:	7da50513          	addi	a0,a0,2010 # 800084e8 <states.0+0x110>
    80002d16:	ffffe097          	auipc	ra,0xffffe
    80002d1a:	886080e7          	jalr	-1914(ra) # 8000059c <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d1e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d22:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d26:	00005517          	auipc	a0,0x5
    80002d2a:	7d250513          	addi	a0,a0,2002 # 800084f8 <states.0+0x120>
    80002d2e:	ffffe097          	auipc	ra,0xffffe
    80002d32:	86e080e7          	jalr	-1938(ra) # 8000059c <printf>
    panic("kerneltrap");
    80002d36:	00005517          	auipc	a0,0x5
    80002d3a:	7da50513          	addi	a0,a0,2010 # 80008510 <states.0+0x138>
    80002d3e:	ffffe097          	auipc	ra,0xffffe
    80002d42:	802080e7          	jalr	-2046(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002d46:	fffff097          	auipc	ra,0xfffff
    80002d4a:	e2c080e7          	jalr	-468(ra) # 80001b72 <myproc>
    80002d4e:	d541                	beqz	a0,80002cd6 <kerneltrap+0x38>
    80002d50:	fffff097          	auipc	ra,0xfffff
    80002d54:	e22080e7          	jalr	-478(ra) # 80001b72 <myproc>
    80002d58:	4d18                	lw	a4,24(a0)
    80002d5a:	4791                	li	a5,4
    80002d5c:	f6f71de3          	bne	a4,a5,80002cd6 <kerneltrap+0x38>
    yield();
    80002d60:	fffff097          	auipc	ra,0xfffff
    80002d64:	584080e7          	jalr	1412(ra) # 800022e4 <yield>
    80002d68:	b7bd                	j	80002cd6 <kerneltrap+0x38>

0000000080002d6a <argraw>:
    return strlen(buf);
}

static uint64
argraw(int n)
{
    80002d6a:	1101                	addi	sp,sp,-32
    80002d6c:	ec06                	sd	ra,24(sp)
    80002d6e:	e822                	sd	s0,16(sp)
    80002d70:	e426                	sd	s1,8(sp)
    80002d72:	1000                	addi	s0,sp,32
    80002d74:	84aa                	mv	s1,a0
    struct proc *p = myproc();
    80002d76:	fffff097          	auipc	ra,0xfffff
    80002d7a:	dfc080e7          	jalr	-516(ra) # 80001b72 <myproc>
    switch (n)
    80002d7e:	4795                	li	a5,5
    80002d80:	0497e163          	bltu	a5,s1,80002dc2 <argraw+0x58>
    80002d84:	048a                	slli	s1,s1,0x2
    80002d86:	00005717          	auipc	a4,0x5
    80002d8a:	7c270713          	addi	a4,a4,1986 # 80008548 <states.0+0x170>
    80002d8e:	94ba                	add	s1,s1,a4
    80002d90:	409c                	lw	a5,0(s1)
    80002d92:	97ba                	add	a5,a5,a4
    80002d94:	8782                	jr	a5
    {
    case 0:
        return p->trapframe->a0;
    80002d96:	6d3c                	ld	a5,88(a0)
    80002d98:	7ba8                	ld	a0,112(a5)
    case 5:
        return p->trapframe->a5;
    }
    panic("argraw");
    return -1;
}
    80002d9a:	60e2                	ld	ra,24(sp)
    80002d9c:	6442                	ld	s0,16(sp)
    80002d9e:	64a2                	ld	s1,8(sp)
    80002da0:	6105                	addi	sp,sp,32
    80002da2:	8082                	ret
        return p->trapframe->a1;
    80002da4:	6d3c                	ld	a5,88(a0)
    80002da6:	7fa8                	ld	a0,120(a5)
    80002da8:	bfcd                	j	80002d9a <argraw+0x30>
        return p->trapframe->a2;
    80002daa:	6d3c                	ld	a5,88(a0)
    80002dac:	63c8                	ld	a0,128(a5)
    80002dae:	b7f5                	j	80002d9a <argraw+0x30>
        return p->trapframe->a3;
    80002db0:	6d3c                	ld	a5,88(a0)
    80002db2:	67c8                	ld	a0,136(a5)
    80002db4:	b7dd                	j	80002d9a <argraw+0x30>
        return p->trapframe->a4;
    80002db6:	6d3c                	ld	a5,88(a0)
    80002db8:	6bc8                	ld	a0,144(a5)
    80002dba:	b7c5                	j	80002d9a <argraw+0x30>
        return p->trapframe->a5;
    80002dbc:	6d3c                	ld	a5,88(a0)
    80002dbe:	6fc8                	ld	a0,152(a5)
    80002dc0:	bfe9                	j	80002d9a <argraw+0x30>
    panic("argraw");
    80002dc2:	00005517          	auipc	a0,0x5
    80002dc6:	75e50513          	addi	a0,a0,1886 # 80008520 <states.0+0x148>
    80002dca:	ffffd097          	auipc	ra,0xffffd
    80002dce:	776080e7          	jalr	1910(ra) # 80000540 <panic>

0000000080002dd2 <fetchaddr>:
{
    80002dd2:	1101                	addi	sp,sp,-32
    80002dd4:	ec06                	sd	ra,24(sp)
    80002dd6:	e822                	sd	s0,16(sp)
    80002dd8:	e426                	sd	s1,8(sp)
    80002dda:	e04a                	sd	s2,0(sp)
    80002ddc:	1000                	addi	s0,sp,32
    80002dde:	84aa                	mv	s1,a0
    80002de0:	892e                	mv	s2,a1
    struct proc *p = myproc();
    80002de2:	fffff097          	auipc	ra,0xfffff
    80002de6:	d90080e7          	jalr	-624(ra) # 80001b72 <myproc>
    if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002dea:	653c                	ld	a5,72(a0)
    80002dec:	02f4f863          	bgeu	s1,a5,80002e1c <fetchaddr+0x4a>
    80002df0:	00848713          	addi	a4,s1,8
    80002df4:	02e7e663          	bltu	a5,a4,80002e20 <fetchaddr+0x4e>
    if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002df8:	46a1                	li	a3,8
    80002dfa:	8626                	mv	a2,s1
    80002dfc:	85ca                	mv	a1,s2
    80002dfe:	6928                	ld	a0,80(a0)
    80002e00:	fffff097          	auipc	ra,0xfffff
    80002e04:	9c0080e7          	jalr	-1600(ra) # 800017c0 <copyin>
    80002e08:	00a03533          	snez	a0,a0
    80002e0c:	40a00533          	neg	a0,a0
}
    80002e10:	60e2                	ld	ra,24(sp)
    80002e12:	6442                	ld	s0,16(sp)
    80002e14:	64a2                	ld	s1,8(sp)
    80002e16:	6902                	ld	s2,0(sp)
    80002e18:	6105                	addi	sp,sp,32
    80002e1a:	8082                	ret
        return -1;
    80002e1c:	557d                	li	a0,-1
    80002e1e:	bfcd                	j	80002e10 <fetchaddr+0x3e>
    80002e20:	557d                	li	a0,-1
    80002e22:	b7fd                	j	80002e10 <fetchaddr+0x3e>

0000000080002e24 <fetchstr>:
{
    80002e24:	7179                	addi	sp,sp,-48
    80002e26:	f406                	sd	ra,40(sp)
    80002e28:	f022                	sd	s0,32(sp)
    80002e2a:	ec26                	sd	s1,24(sp)
    80002e2c:	e84a                	sd	s2,16(sp)
    80002e2e:	e44e                	sd	s3,8(sp)
    80002e30:	1800                	addi	s0,sp,48
    80002e32:	892a                	mv	s2,a0
    80002e34:	84ae                	mv	s1,a1
    80002e36:	89b2                	mv	s3,a2
    struct proc *p = myproc();
    80002e38:	fffff097          	auipc	ra,0xfffff
    80002e3c:	d3a080e7          	jalr	-710(ra) # 80001b72 <myproc>
    if (copyinstr(p->pagetable, buf, addr, max) < 0)
    80002e40:	86ce                	mv	a3,s3
    80002e42:	864a                	mv	a2,s2
    80002e44:	85a6                	mv	a1,s1
    80002e46:	6928                	ld	a0,80(a0)
    80002e48:	fffff097          	auipc	ra,0xfffff
    80002e4c:	a06080e7          	jalr	-1530(ra) # 8000184e <copyinstr>
    80002e50:	00054e63          	bltz	a0,80002e6c <fetchstr+0x48>
    return strlen(buf);
    80002e54:	8526                	mv	a0,s1
    80002e56:	ffffe097          	auipc	ra,0xffffe
    80002e5a:	0c0080e7          	jalr	192(ra) # 80000f16 <strlen>
}
    80002e5e:	70a2                	ld	ra,40(sp)
    80002e60:	7402                	ld	s0,32(sp)
    80002e62:	64e2                	ld	s1,24(sp)
    80002e64:	6942                	ld	s2,16(sp)
    80002e66:	69a2                	ld	s3,8(sp)
    80002e68:	6145                	addi	sp,sp,48
    80002e6a:	8082                	ret
        return -1;
    80002e6c:	557d                	li	a0,-1
    80002e6e:	bfc5                	j	80002e5e <fetchstr+0x3a>

0000000080002e70 <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    80002e70:	1101                	addi	sp,sp,-32
    80002e72:	ec06                	sd	ra,24(sp)
    80002e74:	e822                	sd	s0,16(sp)
    80002e76:	e426                	sd	s1,8(sp)
    80002e78:	1000                	addi	s0,sp,32
    80002e7a:	84ae                	mv	s1,a1
    *ip = argraw(n);
    80002e7c:	00000097          	auipc	ra,0x0
    80002e80:	eee080e7          	jalr	-274(ra) # 80002d6a <argraw>
    80002e84:	c088                	sw	a0,0(s1)
}
    80002e86:	60e2                	ld	ra,24(sp)
    80002e88:	6442                	ld	s0,16(sp)
    80002e8a:	64a2                	ld	s1,8(sp)
    80002e8c:	6105                	addi	sp,sp,32
    80002e8e:	8082                	ret

0000000080002e90 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    80002e90:	1101                	addi	sp,sp,-32
    80002e92:	ec06                	sd	ra,24(sp)
    80002e94:	e822                	sd	s0,16(sp)
    80002e96:	e426                	sd	s1,8(sp)
    80002e98:	1000                	addi	s0,sp,32
    80002e9a:	84ae                	mv	s1,a1
    *ip = argraw(n);
    80002e9c:	00000097          	auipc	ra,0x0
    80002ea0:	ece080e7          	jalr	-306(ra) # 80002d6a <argraw>
    80002ea4:	e088                	sd	a0,0(s1)
}
    80002ea6:	60e2                	ld	ra,24(sp)
    80002ea8:	6442                	ld	s0,16(sp)
    80002eaa:	64a2                	ld	s1,8(sp)
    80002eac:	6105                	addi	sp,sp,32
    80002eae:	8082                	ret

0000000080002eb0 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80002eb0:	7179                	addi	sp,sp,-48
    80002eb2:	f406                	sd	ra,40(sp)
    80002eb4:	f022                	sd	s0,32(sp)
    80002eb6:	ec26                	sd	s1,24(sp)
    80002eb8:	e84a                	sd	s2,16(sp)
    80002eba:	1800                	addi	s0,sp,48
    80002ebc:	84ae                	mv	s1,a1
    80002ebe:	8932                	mv	s2,a2
    uint64 addr;
    argaddr(n, &addr);
    80002ec0:	fd840593          	addi	a1,s0,-40
    80002ec4:	00000097          	auipc	ra,0x0
    80002ec8:	fcc080e7          	jalr	-52(ra) # 80002e90 <argaddr>
    return fetchstr(addr, buf, max);
    80002ecc:	864a                	mv	a2,s2
    80002ece:	85a6                	mv	a1,s1
    80002ed0:	fd843503          	ld	a0,-40(s0)
    80002ed4:	00000097          	auipc	ra,0x0
    80002ed8:	f50080e7          	jalr	-176(ra) # 80002e24 <fetchstr>
}
    80002edc:	70a2                	ld	ra,40(sp)
    80002ede:	7402                	ld	s0,32(sp)
    80002ee0:	64e2                	ld	s1,24(sp)
    80002ee2:	6942                	ld	s2,16(sp)
    80002ee4:	6145                	addi	sp,sp,48
    80002ee6:	8082                	ret

0000000080002ee8 <syscall>:
    [SYS_pfreepages] sys_pfreepages,
    [SYS_va2pa] sys_va2pa,
};

void syscall(void)
{
    80002ee8:	1101                	addi	sp,sp,-32
    80002eea:	ec06                	sd	ra,24(sp)
    80002eec:	e822                	sd	s0,16(sp)
    80002eee:	e426                	sd	s1,8(sp)
    80002ef0:	e04a                	sd	s2,0(sp)
    80002ef2:	1000                	addi	s0,sp,32
    int num;
    struct proc *p = myproc();
    80002ef4:	fffff097          	auipc	ra,0xfffff
    80002ef8:	c7e080e7          	jalr	-898(ra) # 80001b72 <myproc>
    80002efc:	84aa                	mv	s1,a0

    num = p->trapframe->a7;
    80002efe:	05853903          	ld	s2,88(a0)
    80002f02:	0a893783          	ld	a5,168(s2)
    80002f06:	0007869b          	sext.w	a3,a5
    if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80002f0a:	37fd                	addiw	a5,a5,-1
    80002f0c:	4765                	li	a4,25
    80002f0e:	00f76f63          	bltu	a4,a5,80002f2c <syscall+0x44>
    80002f12:	00369713          	slli	a4,a3,0x3
    80002f16:	00005797          	auipc	a5,0x5
    80002f1a:	64a78793          	addi	a5,a5,1610 # 80008560 <syscalls>
    80002f1e:	97ba                	add	a5,a5,a4
    80002f20:	639c                	ld	a5,0(a5)
    80002f22:	c789                	beqz	a5,80002f2c <syscall+0x44>
    {
        // Use num to lookup the system call function for num, call it,
        // and store its return value in p->trapframe->a0
        p->trapframe->a0 = syscalls[num]();
    80002f24:	9782                	jalr	a5
    80002f26:	06a93823          	sd	a0,112(s2)
    80002f2a:	a839                	j	80002f48 <syscall+0x60>
    }
    else
    {
        printf("%d %s: unknown sys call %d\n",
    80002f2c:	15848613          	addi	a2,s1,344
    80002f30:	588c                	lw	a1,48(s1)
    80002f32:	00005517          	auipc	a0,0x5
    80002f36:	5f650513          	addi	a0,a0,1526 # 80008528 <states.0+0x150>
    80002f3a:	ffffd097          	auipc	ra,0xffffd
    80002f3e:	662080e7          	jalr	1634(ra) # 8000059c <printf>
               p->pid, p->name, num);
        p->trapframe->a0 = -1;
    80002f42:	6cbc                	ld	a5,88(s1)
    80002f44:	577d                	li	a4,-1
    80002f46:	fbb8                	sd	a4,112(a5)
    }
}
    80002f48:	60e2                	ld	ra,24(sp)
    80002f4a:	6442                	ld	s0,16(sp)
    80002f4c:	64a2                	ld	s1,8(sp)
    80002f4e:	6902                	ld	s2,0(sp)
    80002f50:	6105                	addi	sp,sp,32
    80002f52:	8082                	ret

0000000080002f54 <sys_exit>:

extern uint64 FREE_PAGES; // kalloc.c keeps track of those

uint64
sys_exit(void)
{
    80002f54:	1101                	addi	sp,sp,-32
    80002f56:	ec06                	sd	ra,24(sp)
    80002f58:	e822                	sd	s0,16(sp)
    80002f5a:	1000                	addi	s0,sp,32
    int n;
    argint(0, &n);
    80002f5c:	fec40593          	addi	a1,s0,-20
    80002f60:	4501                	li	a0,0
    80002f62:	00000097          	auipc	ra,0x0
    80002f66:	f0e080e7          	jalr	-242(ra) # 80002e70 <argint>
    exit(n);
    80002f6a:	fec42503          	lw	a0,-20(s0)
    80002f6e:	fffff097          	auipc	ra,0xfffff
    80002f72:	4e6080e7          	jalr	1254(ra) # 80002454 <exit>
    return 0; // not reached
}
    80002f76:	4501                	li	a0,0
    80002f78:	60e2                	ld	ra,24(sp)
    80002f7a:	6442                	ld	s0,16(sp)
    80002f7c:	6105                	addi	sp,sp,32
    80002f7e:	8082                	ret

0000000080002f80 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002f80:	1141                	addi	sp,sp,-16
    80002f82:	e406                	sd	ra,8(sp)
    80002f84:	e022                	sd	s0,0(sp)
    80002f86:	0800                	addi	s0,sp,16
    return myproc()->pid;
    80002f88:	fffff097          	auipc	ra,0xfffff
    80002f8c:	bea080e7          	jalr	-1046(ra) # 80001b72 <myproc>
}
    80002f90:	5908                	lw	a0,48(a0)
    80002f92:	60a2                	ld	ra,8(sp)
    80002f94:	6402                	ld	s0,0(sp)
    80002f96:	0141                	addi	sp,sp,16
    80002f98:	8082                	ret

0000000080002f9a <sys_fork>:

uint64
sys_fork(void)
{
    80002f9a:	1141                	addi	sp,sp,-16
    80002f9c:	e406                	sd	ra,8(sp)
    80002f9e:	e022                	sd	s0,0(sp)
    80002fa0:	0800                	addi	s0,sp,16
    return fork();
    80002fa2:	fffff097          	auipc	ra,0xfffff
    80002fa6:	11c080e7          	jalr	284(ra) # 800020be <fork>
}
    80002faa:	60a2                	ld	ra,8(sp)
    80002fac:	6402                	ld	s0,0(sp)
    80002fae:	0141                	addi	sp,sp,16
    80002fb0:	8082                	ret

0000000080002fb2 <sys_wait>:

uint64
sys_wait(void)
{
    80002fb2:	1101                	addi	sp,sp,-32
    80002fb4:	ec06                	sd	ra,24(sp)
    80002fb6:	e822                	sd	s0,16(sp)
    80002fb8:	1000                	addi	s0,sp,32
    uint64 p;
    argaddr(0, &p);
    80002fba:	fe840593          	addi	a1,s0,-24
    80002fbe:	4501                	li	a0,0
    80002fc0:	00000097          	auipc	ra,0x0
    80002fc4:	ed0080e7          	jalr	-304(ra) # 80002e90 <argaddr>
    return wait(p);
    80002fc8:	fe843503          	ld	a0,-24(s0)
    80002fcc:	fffff097          	auipc	ra,0xfffff
    80002fd0:	62e080e7          	jalr	1582(ra) # 800025fa <wait>
}
    80002fd4:	60e2                	ld	ra,24(sp)
    80002fd6:	6442                	ld	s0,16(sp)
    80002fd8:	6105                	addi	sp,sp,32
    80002fda:	8082                	ret

0000000080002fdc <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002fdc:	7179                	addi	sp,sp,-48
    80002fde:	f406                	sd	ra,40(sp)
    80002fe0:	f022                	sd	s0,32(sp)
    80002fe2:	ec26                	sd	s1,24(sp)
    80002fe4:	1800                	addi	s0,sp,48
    uint64 addr;
    int n;

    argint(0, &n);
    80002fe6:	fdc40593          	addi	a1,s0,-36
    80002fea:	4501                	li	a0,0
    80002fec:	00000097          	auipc	ra,0x0
    80002ff0:	e84080e7          	jalr	-380(ra) # 80002e70 <argint>
    addr = myproc()->sz;
    80002ff4:	fffff097          	auipc	ra,0xfffff
    80002ff8:	b7e080e7          	jalr	-1154(ra) # 80001b72 <myproc>
    80002ffc:	6524                	ld	s1,72(a0)
    if (growproc(n) < 0)
    80002ffe:	fdc42503          	lw	a0,-36(s0)
    80003002:	fffff097          	auipc	ra,0xfffff
    80003006:	eca080e7          	jalr	-310(ra) # 80001ecc <growproc>
    8000300a:	00054863          	bltz	a0,8000301a <sys_sbrk+0x3e>
        return -1;
    return addr;
}
    8000300e:	8526                	mv	a0,s1
    80003010:	70a2                	ld	ra,40(sp)
    80003012:	7402                	ld	s0,32(sp)
    80003014:	64e2                	ld	s1,24(sp)
    80003016:	6145                	addi	sp,sp,48
    80003018:	8082                	ret
        return -1;
    8000301a:	54fd                	li	s1,-1
    8000301c:	bfcd                	j	8000300e <sys_sbrk+0x32>

000000008000301e <sys_sleep>:

uint64
sys_sleep(void)
{
    8000301e:	7139                	addi	sp,sp,-64
    80003020:	fc06                	sd	ra,56(sp)
    80003022:	f822                	sd	s0,48(sp)
    80003024:	f426                	sd	s1,40(sp)
    80003026:	f04a                	sd	s2,32(sp)
    80003028:	ec4e                	sd	s3,24(sp)
    8000302a:	0080                	addi	s0,sp,64
    int n;
    uint ticks0;

    argint(0, &n);
    8000302c:	fcc40593          	addi	a1,s0,-52
    80003030:	4501                	li	a0,0
    80003032:	00000097          	auipc	ra,0x0
    80003036:	e3e080e7          	jalr	-450(ra) # 80002e70 <argint>
    acquire(&tickslock);
    8000303a:	00014517          	auipc	a0,0x14
    8000303e:	ac650513          	addi	a0,a0,-1338 # 80016b00 <tickslock>
    80003042:	ffffe097          	auipc	ra,0xffffe
    80003046:	c5c080e7          	jalr	-932(ra) # 80000c9e <acquire>
    ticks0 = ticks;
    8000304a:	00006917          	auipc	s2,0x6
    8000304e:	a1692903          	lw	s2,-1514(s2) # 80008a60 <ticks>
    while (ticks - ticks0 < n)
    80003052:	fcc42783          	lw	a5,-52(s0)
    80003056:	cf9d                	beqz	a5,80003094 <sys_sleep+0x76>
        if (killed(myproc()))
        {
            release(&tickslock);
            return -1;
        }
        sleep(&ticks, &tickslock);
    80003058:	00014997          	auipc	s3,0x14
    8000305c:	aa898993          	addi	s3,s3,-1368 # 80016b00 <tickslock>
    80003060:	00006497          	auipc	s1,0x6
    80003064:	a0048493          	addi	s1,s1,-1536 # 80008a60 <ticks>
        if (killed(myproc()))
    80003068:	fffff097          	auipc	ra,0xfffff
    8000306c:	b0a080e7          	jalr	-1270(ra) # 80001b72 <myproc>
    80003070:	fffff097          	auipc	ra,0xfffff
    80003074:	558080e7          	jalr	1368(ra) # 800025c8 <killed>
    80003078:	ed15                	bnez	a0,800030b4 <sys_sleep+0x96>
        sleep(&ticks, &tickslock);
    8000307a:	85ce                	mv	a1,s3
    8000307c:	8526                	mv	a0,s1
    8000307e:	fffff097          	auipc	ra,0xfffff
    80003082:	2a2080e7          	jalr	674(ra) # 80002320 <sleep>
    while (ticks - ticks0 < n)
    80003086:	409c                	lw	a5,0(s1)
    80003088:	412787bb          	subw	a5,a5,s2
    8000308c:	fcc42703          	lw	a4,-52(s0)
    80003090:	fce7ece3          	bltu	a5,a4,80003068 <sys_sleep+0x4a>
    }
    release(&tickslock);
    80003094:	00014517          	auipc	a0,0x14
    80003098:	a6c50513          	addi	a0,a0,-1428 # 80016b00 <tickslock>
    8000309c:	ffffe097          	auipc	ra,0xffffe
    800030a0:	cb6080e7          	jalr	-842(ra) # 80000d52 <release>
    return 0;
    800030a4:	4501                	li	a0,0
}
    800030a6:	70e2                	ld	ra,56(sp)
    800030a8:	7442                	ld	s0,48(sp)
    800030aa:	74a2                	ld	s1,40(sp)
    800030ac:	7902                	ld	s2,32(sp)
    800030ae:	69e2                	ld	s3,24(sp)
    800030b0:	6121                	addi	sp,sp,64
    800030b2:	8082                	ret
            release(&tickslock);
    800030b4:	00014517          	auipc	a0,0x14
    800030b8:	a4c50513          	addi	a0,a0,-1460 # 80016b00 <tickslock>
    800030bc:	ffffe097          	auipc	ra,0xffffe
    800030c0:	c96080e7          	jalr	-874(ra) # 80000d52 <release>
            return -1;
    800030c4:	557d                	li	a0,-1
    800030c6:	b7c5                	j	800030a6 <sys_sleep+0x88>

00000000800030c8 <sys_kill>:

uint64
sys_kill(void)
{
    800030c8:	1101                	addi	sp,sp,-32
    800030ca:	ec06                	sd	ra,24(sp)
    800030cc:	e822                	sd	s0,16(sp)
    800030ce:	1000                	addi	s0,sp,32
    int pid;

    argint(0, &pid);
    800030d0:	fec40593          	addi	a1,s0,-20
    800030d4:	4501                	li	a0,0
    800030d6:	00000097          	auipc	ra,0x0
    800030da:	d9a080e7          	jalr	-614(ra) # 80002e70 <argint>
    return kill(pid);
    800030de:	fec42503          	lw	a0,-20(s0)
    800030e2:	fffff097          	auipc	ra,0xfffff
    800030e6:	448080e7          	jalr	1096(ra) # 8000252a <kill>
}
    800030ea:	60e2                	ld	ra,24(sp)
    800030ec:	6442                	ld	s0,16(sp)
    800030ee:	6105                	addi	sp,sp,32
    800030f0:	8082                	ret

00000000800030f2 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800030f2:	1101                	addi	sp,sp,-32
    800030f4:	ec06                	sd	ra,24(sp)
    800030f6:	e822                	sd	s0,16(sp)
    800030f8:	e426                	sd	s1,8(sp)
    800030fa:	1000                	addi	s0,sp,32
    uint xticks;

    acquire(&tickslock);
    800030fc:	00014517          	auipc	a0,0x14
    80003100:	a0450513          	addi	a0,a0,-1532 # 80016b00 <tickslock>
    80003104:	ffffe097          	auipc	ra,0xffffe
    80003108:	b9a080e7          	jalr	-1126(ra) # 80000c9e <acquire>
    xticks = ticks;
    8000310c:	00006497          	auipc	s1,0x6
    80003110:	9544a483          	lw	s1,-1708(s1) # 80008a60 <ticks>
    release(&tickslock);
    80003114:	00014517          	auipc	a0,0x14
    80003118:	9ec50513          	addi	a0,a0,-1556 # 80016b00 <tickslock>
    8000311c:	ffffe097          	auipc	ra,0xffffe
    80003120:	c36080e7          	jalr	-970(ra) # 80000d52 <release>
    return xticks;
}
    80003124:	02049513          	slli	a0,s1,0x20
    80003128:	9101                	srli	a0,a0,0x20
    8000312a:	60e2                	ld	ra,24(sp)
    8000312c:	6442                	ld	s0,16(sp)
    8000312e:	64a2                	ld	s1,8(sp)
    80003130:	6105                	addi	sp,sp,32
    80003132:	8082                	ret

0000000080003134 <sys_ps>:

void *
sys_ps(void)
{
    80003134:	1101                	addi	sp,sp,-32
    80003136:	ec06                	sd	ra,24(sp)
    80003138:	e822                	sd	s0,16(sp)
    8000313a:	1000                	addi	s0,sp,32
    int start = 0, count = 0;
    8000313c:	fe042623          	sw	zero,-20(s0)
    80003140:	fe042423          	sw	zero,-24(s0)
    argint(0, &start);
    80003144:	fec40593          	addi	a1,s0,-20
    80003148:	4501                	li	a0,0
    8000314a:	00000097          	auipc	ra,0x0
    8000314e:	d26080e7          	jalr	-730(ra) # 80002e70 <argint>
    argint(1, &count);
    80003152:	fe840593          	addi	a1,s0,-24
    80003156:	4505                	li	a0,1
    80003158:	00000097          	auipc	ra,0x0
    8000315c:	d18080e7          	jalr	-744(ra) # 80002e70 <argint>
    return ps((uint8)start, (uint8)count);
    80003160:	fe844583          	lbu	a1,-24(s0)
    80003164:	fec44503          	lbu	a0,-20(s0)
    80003168:	fffff097          	auipc	ra,0xfffff
    8000316c:	dc0080e7          	jalr	-576(ra) # 80001f28 <ps>
}
    80003170:	60e2                	ld	ra,24(sp)
    80003172:	6442                	ld	s0,16(sp)
    80003174:	6105                	addi	sp,sp,32
    80003176:	8082                	ret

0000000080003178 <sys_schedls>:

uint64 sys_schedls(void)
{
    80003178:	1141                	addi	sp,sp,-16
    8000317a:	e406                	sd	ra,8(sp)
    8000317c:	e022                	sd	s0,0(sp)
    8000317e:	0800                	addi	s0,sp,16
    schedls();
    80003180:	fffff097          	auipc	ra,0xfffff
    80003184:	704080e7          	jalr	1796(ra) # 80002884 <schedls>
    return 0;
}
    80003188:	4501                	li	a0,0
    8000318a:	60a2                	ld	ra,8(sp)
    8000318c:	6402                	ld	s0,0(sp)
    8000318e:	0141                	addi	sp,sp,16
    80003190:	8082                	ret

0000000080003192 <sys_schedset>:

uint64 sys_schedset(void)
{
    80003192:	1101                	addi	sp,sp,-32
    80003194:	ec06                	sd	ra,24(sp)
    80003196:	e822                	sd	s0,16(sp)
    80003198:	1000                	addi	s0,sp,32
    int id = 0;
    8000319a:	fe042623          	sw	zero,-20(s0)
    argint(0, &id);
    8000319e:	fec40593          	addi	a1,s0,-20
    800031a2:	4501                	li	a0,0
    800031a4:	00000097          	auipc	ra,0x0
    800031a8:	ccc080e7          	jalr	-820(ra) # 80002e70 <argint>
    schedset(id - 1);
    800031ac:	fec42503          	lw	a0,-20(s0)
    800031b0:	357d                	addiw	a0,a0,-1
    800031b2:	fffff097          	auipc	ra,0xfffff
    800031b6:	768080e7          	jalr	1896(ra) # 8000291a <schedset>
    return 0;
}
    800031ba:	4501                	li	a0,0
    800031bc:	60e2                	ld	ra,24(sp)
    800031be:	6442                	ld	s0,16(sp)
    800031c0:	6105                	addi	sp,sp,32
    800031c2:	8082                	ret

00000000800031c4 <sys_va2pa>:

extern struct proc proc[];

uint64 sys_va2pa(void)
{
    800031c4:	1101                	addi	sp,sp,-32
    800031c6:	ec06                	sd	ra,24(sp)
    800031c8:	e822                	sd	s0,16(sp)
    800031ca:	1000                	addi	s0,sp,32
    uint64 virtual_address;
    int process_id;

    argaddr(0, &virtual_address);
    800031cc:	fe840593          	addi	a1,s0,-24
    800031d0:	4501                	li	a0,0
    800031d2:	00000097          	auipc	ra,0x0
    800031d6:	cbe080e7          	jalr	-834(ra) # 80002e90 <argaddr>
    argint(1, &process_id);
    800031da:	fe440593          	addi	a1,s0,-28
    800031de:	4505                	li	a0,1
    800031e0:	00000097          	auipc	ra,0x0
    800031e4:	c90080e7          	jalr	-880(ra) # 80002e70 <argint>
    
    pagetable_t pagetable;

    if (process_id < 0) {
    800031e8:	fe442683          	lw	a3,-28(s0)
        pagetable = myproc()->pagetable;
    }
    else {
        struct proc *p;
        int found = 0;
        for (p = proc; p < &proc[NPROC]; p++) {
    800031ec:	0000e797          	auipc	a5,0xe
    800031f0:	f1478793          	addi	a5,a5,-236 # 80011100 <proc>
    800031f4:	00014617          	auipc	a2,0x14
    800031f8:	90c60613          	addi	a2,a2,-1780 # 80016b00 <tickslock>
    if (process_id < 0) {
    800031fc:	0006cb63          	bltz	a3,80003212 <sys_va2pa+0x4e>
            if (p->pid == process_id) {
    80003200:	5b98                	lw	a4,48(a5)
    80003202:	00d70e63          	beq	a4,a3,8000321e <sys_va2pa+0x5a>
        for (p = proc; p < &proc[NPROC]; p++) {
    80003206:	16878793          	addi	a5,a5,360
    8000320a:	fec79be3          	bne	a5,a2,80003200 <sys_va2pa+0x3c>
                break;
            }
        }
        // If found is 0, then the user has provided a non-existing pid
        if (found == 0) {
            return 0;
    8000320e:	4501                	li	a0,0
    80003210:	a831                	j	8000322c <sys_va2pa+0x68>
        pagetable = myproc()->pagetable;
    80003212:	fffff097          	auipc	ra,0xfffff
    80003216:	960080e7          	jalr	-1696(ra) # 80001b72 <myproc>
    8000321a:	6928                	ld	a0,80(a0)
    8000321c:	a011                	j	80003220 <sys_va2pa+0x5c>
                pagetable = p->pagetable;
    8000321e:	6ba8                	ld	a0,80(a5)
        }
    }
    uint64 physical_address = walkaddr(pagetable, virtual_address);
    80003220:	fe843583          	ld	a1,-24(s0)
    80003224:	ffffe097          	auipc	ra,0xffffe
    80003228:	f00080e7          	jalr	-256(ra) # 80001124 <walkaddr>
    return physical_address;
}
    8000322c:	60e2                	ld	ra,24(sp)
    8000322e:	6442                	ld	s0,16(sp)
    80003230:	6105                	addi	sp,sp,32
    80003232:	8082                	ret

0000000080003234 <sys_pfreepages>:

uint64 sys_pfreepages(void)
{
    80003234:	1141                	addi	sp,sp,-16
    80003236:	e406                	sd	ra,8(sp)
    80003238:	e022                	sd	s0,0(sp)
    8000323a:	0800                	addi	s0,sp,16
    printf("%d\n", FREE_PAGES);
    8000323c:	00005597          	auipc	a1,0x5
    80003240:	7fc5b583          	ld	a1,2044(a1) # 80008a38 <FREE_PAGES>
    80003244:	00005517          	auipc	a0,0x5
    80003248:	2fc50513          	addi	a0,a0,764 # 80008540 <states.0+0x168>
    8000324c:	ffffd097          	auipc	ra,0xffffd
    80003250:	350080e7          	jalr	848(ra) # 8000059c <printf>
    return 0;
    80003254:	4501                	li	a0,0
    80003256:	60a2                	ld	ra,8(sp)
    80003258:	6402                	ld	s0,0(sp)
    8000325a:	0141                	addi	sp,sp,16
    8000325c:	8082                	ret

000000008000325e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000325e:	7179                	addi	sp,sp,-48
    80003260:	f406                	sd	ra,40(sp)
    80003262:	f022                	sd	s0,32(sp)
    80003264:	ec26                	sd	s1,24(sp)
    80003266:	e84a                	sd	s2,16(sp)
    80003268:	e44e                	sd	s3,8(sp)
    8000326a:	e052                	sd	s4,0(sp)
    8000326c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000326e:	00005597          	auipc	a1,0x5
    80003272:	3ca58593          	addi	a1,a1,970 # 80008638 <syscalls+0xd8>
    80003276:	00014517          	auipc	a0,0x14
    8000327a:	8a250513          	addi	a0,a0,-1886 # 80016b18 <bcache>
    8000327e:	ffffe097          	auipc	ra,0xffffe
    80003282:	990080e7          	jalr	-1648(ra) # 80000c0e <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003286:	0001c797          	auipc	a5,0x1c
    8000328a:	89278793          	addi	a5,a5,-1902 # 8001eb18 <bcache+0x8000>
    8000328e:	0001c717          	auipc	a4,0x1c
    80003292:	af270713          	addi	a4,a4,-1294 # 8001ed80 <bcache+0x8268>
    80003296:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000329a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000329e:	00014497          	auipc	s1,0x14
    800032a2:	89248493          	addi	s1,s1,-1902 # 80016b30 <bcache+0x18>
    b->next = bcache.head.next;
    800032a6:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800032a8:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800032aa:	00005a17          	auipc	s4,0x5
    800032ae:	396a0a13          	addi	s4,s4,918 # 80008640 <syscalls+0xe0>
    b->next = bcache.head.next;
    800032b2:	2b893783          	ld	a5,696(s2)
    800032b6:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800032b8:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800032bc:	85d2                	mv	a1,s4
    800032be:	01048513          	addi	a0,s1,16
    800032c2:	00001097          	auipc	ra,0x1
    800032c6:	4c8080e7          	jalr	1224(ra) # 8000478a <initsleeplock>
    bcache.head.next->prev = b;
    800032ca:	2b893783          	ld	a5,696(s2)
    800032ce:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800032d0:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800032d4:	45848493          	addi	s1,s1,1112
    800032d8:	fd349de3          	bne	s1,s3,800032b2 <binit+0x54>
  }
}
    800032dc:	70a2                	ld	ra,40(sp)
    800032de:	7402                	ld	s0,32(sp)
    800032e0:	64e2                	ld	s1,24(sp)
    800032e2:	6942                	ld	s2,16(sp)
    800032e4:	69a2                	ld	s3,8(sp)
    800032e6:	6a02                	ld	s4,0(sp)
    800032e8:	6145                	addi	sp,sp,48
    800032ea:	8082                	ret

00000000800032ec <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800032ec:	7179                	addi	sp,sp,-48
    800032ee:	f406                	sd	ra,40(sp)
    800032f0:	f022                	sd	s0,32(sp)
    800032f2:	ec26                	sd	s1,24(sp)
    800032f4:	e84a                	sd	s2,16(sp)
    800032f6:	e44e                	sd	s3,8(sp)
    800032f8:	1800                	addi	s0,sp,48
    800032fa:	892a                	mv	s2,a0
    800032fc:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800032fe:	00014517          	auipc	a0,0x14
    80003302:	81a50513          	addi	a0,a0,-2022 # 80016b18 <bcache>
    80003306:	ffffe097          	auipc	ra,0xffffe
    8000330a:	998080e7          	jalr	-1640(ra) # 80000c9e <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000330e:	0001c497          	auipc	s1,0x1c
    80003312:	ac24b483          	ld	s1,-1342(s1) # 8001edd0 <bcache+0x82b8>
    80003316:	0001c797          	auipc	a5,0x1c
    8000331a:	a6a78793          	addi	a5,a5,-1430 # 8001ed80 <bcache+0x8268>
    8000331e:	02f48f63          	beq	s1,a5,8000335c <bread+0x70>
    80003322:	873e                	mv	a4,a5
    80003324:	a021                	j	8000332c <bread+0x40>
    80003326:	68a4                	ld	s1,80(s1)
    80003328:	02e48a63          	beq	s1,a4,8000335c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000332c:	449c                	lw	a5,8(s1)
    8000332e:	ff279ce3          	bne	a5,s2,80003326 <bread+0x3a>
    80003332:	44dc                	lw	a5,12(s1)
    80003334:	ff3799e3          	bne	a5,s3,80003326 <bread+0x3a>
      b->refcnt++;
    80003338:	40bc                	lw	a5,64(s1)
    8000333a:	2785                	addiw	a5,a5,1
    8000333c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000333e:	00013517          	auipc	a0,0x13
    80003342:	7da50513          	addi	a0,a0,2010 # 80016b18 <bcache>
    80003346:	ffffe097          	auipc	ra,0xffffe
    8000334a:	a0c080e7          	jalr	-1524(ra) # 80000d52 <release>
      acquiresleep(&b->lock);
    8000334e:	01048513          	addi	a0,s1,16
    80003352:	00001097          	auipc	ra,0x1
    80003356:	472080e7          	jalr	1138(ra) # 800047c4 <acquiresleep>
      return b;
    8000335a:	a8b9                	j	800033b8 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000335c:	0001c497          	auipc	s1,0x1c
    80003360:	a6c4b483          	ld	s1,-1428(s1) # 8001edc8 <bcache+0x82b0>
    80003364:	0001c797          	auipc	a5,0x1c
    80003368:	a1c78793          	addi	a5,a5,-1508 # 8001ed80 <bcache+0x8268>
    8000336c:	00f48863          	beq	s1,a5,8000337c <bread+0x90>
    80003370:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003372:	40bc                	lw	a5,64(s1)
    80003374:	cf81                	beqz	a5,8000338c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003376:	64a4                	ld	s1,72(s1)
    80003378:	fee49de3          	bne	s1,a4,80003372 <bread+0x86>
  panic("bget: no buffers");
    8000337c:	00005517          	auipc	a0,0x5
    80003380:	2cc50513          	addi	a0,a0,716 # 80008648 <syscalls+0xe8>
    80003384:	ffffd097          	auipc	ra,0xffffd
    80003388:	1bc080e7          	jalr	444(ra) # 80000540 <panic>
      b->dev = dev;
    8000338c:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003390:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003394:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003398:	4785                	li	a5,1
    8000339a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000339c:	00013517          	auipc	a0,0x13
    800033a0:	77c50513          	addi	a0,a0,1916 # 80016b18 <bcache>
    800033a4:	ffffe097          	auipc	ra,0xffffe
    800033a8:	9ae080e7          	jalr	-1618(ra) # 80000d52 <release>
      acquiresleep(&b->lock);
    800033ac:	01048513          	addi	a0,s1,16
    800033b0:	00001097          	auipc	ra,0x1
    800033b4:	414080e7          	jalr	1044(ra) # 800047c4 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800033b8:	409c                	lw	a5,0(s1)
    800033ba:	cb89                	beqz	a5,800033cc <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800033bc:	8526                	mv	a0,s1
    800033be:	70a2                	ld	ra,40(sp)
    800033c0:	7402                	ld	s0,32(sp)
    800033c2:	64e2                	ld	s1,24(sp)
    800033c4:	6942                	ld	s2,16(sp)
    800033c6:	69a2                	ld	s3,8(sp)
    800033c8:	6145                	addi	sp,sp,48
    800033ca:	8082                	ret
    virtio_disk_rw(b, 0);
    800033cc:	4581                	li	a1,0
    800033ce:	8526                	mv	a0,s1
    800033d0:	00003097          	auipc	ra,0x3
    800033d4:	fe2080e7          	jalr	-30(ra) # 800063b2 <virtio_disk_rw>
    b->valid = 1;
    800033d8:	4785                	li	a5,1
    800033da:	c09c                	sw	a5,0(s1)
  return b;
    800033dc:	b7c5                	j	800033bc <bread+0xd0>

00000000800033de <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800033de:	1101                	addi	sp,sp,-32
    800033e0:	ec06                	sd	ra,24(sp)
    800033e2:	e822                	sd	s0,16(sp)
    800033e4:	e426                	sd	s1,8(sp)
    800033e6:	1000                	addi	s0,sp,32
    800033e8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800033ea:	0541                	addi	a0,a0,16
    800033ec:	00001097          	auipc	ra,0x1
    800033f0:	472080e7          	jalr	1138(ra) # 8000485e <holdingsleep>
    800033f4:	cd01                	beqz	a0,8000340c <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800033f6:	4585                	li	a1,1
    800033f8:	8526                	mv	a0,s1
    800033fa:	00003097          	auipc	ra,0x3
    800033fe:	fb8080e7          	jalr	-72(ra) # 800063b2 <virtio_disk_rw>
}
    80003402:	60e2                	ld	ra,24(sp)
    80003404:	6442                	ld	s0,16(sp)
    80003406:	64a2                	ld	s1,8(sp)
    80003408:	6105                	addi	sp,sp,32
    8000340a:	8082                	ret
    panic("bwrite");
    8000340c:	00005517          	auipc	a0,0x5
    80003410:	25450513          	addi	a0,a0,596 # 80008660 <syscalls+0x100>
    80003414:	ffffd097          	auipc	ra,0xffffd
    80003418:	12c080e7          	jalr	300(ra) # 80000540 <panic>

000000008000341c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000341c:	1101                	addi	sp,sp,-32
    8000341e:	ec06                	sd	ra,24(sp)
    80003420:	e822                	sd	s0,16(sp)
    80003422:	e426                	sd	s1,8(sp)
    80003424:	e04a                	sd	s2,0(sp)
    80003426:	1000                	addi	s0,sp,32
    80003428:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000342a:	01050913          	addi	s2,a0,16
    8000342e:	854a                	mv	a0,s2
    80003430:	00001097          	auipc	ra,0x1
    80003434:	42e080e7          	jalr	1070(ra) # 8000485e <holdingsleep>
    80003438:	c92d                	beqz	a0,800034aa <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000343a:	854a                	mv	a0,s2
    8000343c:	00001097          	auipc	ra,0x1
    80003440:	3de080e7          	jalr	990(ra) # 8000481a <releasesleep>

  acquire(&bcache.lock);
    80003444:	00013517          	auipc	a0,0x13
    80003448:	6d450513          	addi	a0,a0,1748 # 80016b18 <bcache>
    8000344c:	ffffe097          	auipc	ra,0xffffe
    80003450:	852080e7          	jalr	-1966(ra) # 80000c9e <acquire>
  b->refcnt--;
    80003454:	40bc                	lw	a5,64(s1)
    80003456:	37fd                	addiw	a5,a5,-1
    80003458:	0007871b          	sext.w	a4,a5
    8000345c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000345e:	eb05                	bnez	a4,8000348e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003460:	68bc                	ld	a5,80(s1)
    80003462:	64b8                	ld	a4,72(s1)
    80003464:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003466:	64bc                	ld	a5,72(s1)
    80003468:	68b8                	ld	a4,80(s1)
    8000346a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000346c:	0001b797          	auipc	a5,0x1b
    80003470:	6ac78793          	addi	a5,a5,1708 # 8001eb18 <bcache+0x8000>
    80003474:	2b87b703          	ld	a4,696(a5)
    80003478:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000347a:	0001c717          	auipc	a4,0x1c
    8000347e:	90670713          	addi	a4,a4,-1786 # 8001ed80 <bcache+0x8268>
    80003482:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003484:	2b87b703          	ld	a4,696(a5)
    80003488:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000348a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000348e:	00013517          	auipc	a0,0x13
    80003492:	68a50513          	addi	a0,a0,1674 # 80016b18 <bcache>
    80003496:	ffffe097          	auipc	ra,0xffffe
    8000349a:	8bc080e7          	jalr	-1860(ra) # 80000d52 <release>
}
    8000349e:	60e2                	ld	ra,24(sp)
    800034a0:	6442                	ld	s0,16(sp)
    800034a2:	64a2                	ld	s1,8(sp)
    800034a4:	6902                	ld	s2,0(sp)
    800034a6:	6105                	addi	sp,sp,32
    800034a8:	8082                	ret
    panic("brelse");
    800034aa:	00005517          	auipc	a0,0x5
    800034ae:	1be50513          	addi	a0,a0,446 # 80008668 <syscalls+0x108>
    800034b2:	ffffd097          	auipc	ra,0xffffd
    800034b6:	08e080e7          	jalr	142(ra) # 80000540 <panic>

00000000800034ba <bpin>:

void
bpin(struct buf *b) {
    800034ba:	1101                	addi	sp,sp,-32
    800034bc:	ec06                	sd	ra,24(sp)
    800034be:	e822                	sd	s0,16(sp)
    800034c0:	e426                	sd	s1,8(sp)
    800034c2:	1000                	addi	s0,sp,32
    800034c4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800034c6:	00013517          	auipc	a0,0x13
    800034ca:	65250513          	addi	a0,a0,1618 # 80016b18 <bcache>
    800034ce:	ffffd097          	auipc	ra,0xffffd
    800034d2:	7d0080e7          	jalr	2000(ra) # 80000c9e <acquire>
  b->refcnt++;
    800034d6:	40bc                	lw	a5,64(s1)
    800034d8:	2785                	addiw	a5,a5,1
    800034da:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800034dc:	00013517          	auipc	a0,0x13
    800034e0:	63c50513          	addi	a0,a0,1596 # 80016b18 <bcache>
    800034e4:	ffffe097          	auipc	ra,0xffffe
    800034e8:	86e080e7          	jalr	-1938(ra) # 80000d52 <release>
}
    800034ec:	60e2                	ld	ra,24(sp)
    800034ee:	6442                	ld	s0,16(sp)
    800034f0:	64a2                	ld	s1,8(sp)
    800034f2:	6105                	addi	sp,sp,32
    800034f4:	8082                	ret

00000000800034f6 <bunpin>:

void
bunpin(struct buf *b) {
    800034f6:	1101                	addi	sp,sp,-32
    800034f8:	ec06                	sd	ra,24(sp)
    800034fa:	e822                	sd	s0,16(sp)
    800034fc:	e426                	sd	s1,8(sp)
    800034fe:	1000                	addi	s0,sp,32
    80003500:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003502:	00013517          	auipc	a0,0x13
    80003506:	61650513          	addi	a0,a0,1558 # 80016b18 <bcache>
    8000350a:	ffffd097          	auipc	ra,0xffffd
    8000350e:	794080e7          	jalr	1940(ra) # 80000c9e <acquire>
  b->refcnt--;
    80003512:	40bc                	lw	a5,64(s1)
    80003514:	37fd                	addiw	a5,a5,-1
    80003516:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003518:	00013517          	auipc	a0,0x13
    8000351c:	60050513          	addi	a0,a0,1536 # 80016b18 <bcache>
    80003520:	ffffe097          	auipc	ra,0xffffe
    80003524:	832080e7          	jalr	-1998(ra) # 80000d52 <release>
}
    80003528:	60e2                	ld	ra,24(sp)
    8000352a:	6442                	ld	s0,16(sp)
    8000352c:	64a2                	ld	s1,8(sp)
    8000352e:	6105                	addi	sp,sp,32
    80003530:	8082                	ret

0000000080003532 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003532:	1101                	addi	sp,sp,-32
    80003534:	ec06                	sd	ra,24(sp)
    80003536:	e822                	sd	s0,16(sp)
    80003538:	e426                	sd	s1,8(sp)
    8000353a:	e04a                	sd	s2,0(sp)
    8000353c:	1000                	addi	s0,sp,32
    8000353e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003540:	00d5d59b          	srliw	a1,a1,0xd
    80003544:	0001c797          	auipc	a5,0x1c
    80003548:	cb07a783          	lw	a5,-848(a5) # 8001f1f4 <sb+0x1c>
    8000354c:	9dbd                	addw	a1,a1,a5
    8000354e:	00000097          	auipc	ra,0x0
    80003552:	d9e080e7          	jalr	-610(ra) # 800032ec <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003556:	0074f713          	andi	a4,s1,7
    8000355a:	4785                	li	a5,1
    8000355c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003560:	14ce                	slli	s1,s1,0x33
    80003562:	90d9                	srli	s1,s1,0x36
    80003564:	00950733          	add	a4,a0,s1
    80003568:	05874703          	lbu	a4,88(a4)
    8000356c:	00e7f6b3          	and	a3,a5,a4
    80003570:	c69d                	beqz	a3,8000359e <bfree+0x6c>
    80003572:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003574:	94aa                	add	s1,s1,a0
    80003576:	fff7c793          	not	a5,a5
    8000357a:	8f7d                	and	a4,a4,a5
    8000357c:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003580:	00001097          	auipc	ra,0x1
    80003584:	126080e7          	jalr	294(ra) # 800046a6 <log_write>
  brelse(bp);
    80003588:	854a                	mv	a0,s2
    8000358a:	00000097          	auipc	ra,0x0
    8000358e:	e92080e7          	jalr	-366(ra) # 8000341c <brelse>
}
    80003592:	60e2                	ld	ra,24(sp)
    80003594:	6442                	ld	s0,16(sp)
    80003596:	64a2                	ld	s1,8(sp)
    80003598:	6902                	ld	s2,0(sp)
    8000359a:	6105                	addi	sp,sp,32
    8000359c:	8082                	ret
    panic("freeing free block");
    8000359e:	00005517          	auipc	a0,0x5
    800035a2:	0d250513          	addi	a0,a0,210 # 80008670 <syscalls+0x110>
    800035a6:	ffffd097          	auipc	ra,0xffffd
    800035aa:	f9a080e7          	jalr	-102(ra) # 80000540 <panic>

00000000800035ae <balloc>:
{
    800035ae:	711d                	addi	sp,sp,-96
    800035b0:	ec86                	sd	ra,88(sp)
    800035b2:	e8a2                	sd	s0,80(sp)
    800035b4:	e4a6                	sd	s1,72(sp)
    800035b6:	e0ca                	sd	s2,64(sp)
    800035b8:	fc4e                	sd	s3,56(sp)
    800035ba:	f852                	sd	s4,48(sp)
    800035bc:	f456                	sd	s5,40(sp)
    800035be:	f05a                	sd	s6,32(sp)
    800035c0:	ec5e                	sd	s7,24(sp)
    800035c2:	e862                	sd	s8,16(sp)
    800035c4:	e466                	sd	s9,8(sp)
    800035c6:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800035c8:	0001c797          	auipc	a5,0x1c
    800035cc:	c147a783          	lw	a5,-1004(a5) # 8001f1dc <sb+0x4>
    800035d0:	cff5                	beqz	a5,800036cc <balloc+0x11e>
    800035d2:	8baa                	mv	s7,a0
    800035d4:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800035d6:	0001cb17          	auipc	s6,0x1c
    800035da:	c02b0b13          	addi	s6,s6,-1022 # 8001f1d8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035de:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800035e0:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035e2:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800035e4:	6c89                	lui	s9,0x2
    800035e6:	a061                	j	8000366e <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    800035e8:	97ca                	add	a5,a5,s2
    800035ea:	8e55                	or	a2,a2,a3
    800035ec:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800035f0:	854a                	mv	a0,s2
    800035f2:	00001097          	auipc	ra,0x1
    800035f6:	0b4080e7          	jalr	180(ra) # 800046a6 <log_write>
        brelse(bp);
    800035fa:	854a                	mv	a0,s2
    800035fc:	00000097          	auipc	ra,0x0
    80003600:	e20080e7          	jalr	-480(ra) # 8000341c <brelse>
  bp = bread(dev, bno);
    80003604:	85a6                	mv	a1,s1
    80003606:	855e                	mv	a0,s7
    80003608:	00000097          	auipc	ra,0x0
    8000360c:	ce4080e7          	jalr	-796(ra) # 800032ec <bread>
    80003610:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003612:	40000613          	li	a2,1024
    80003616:	4581                	li	a1,0
    80003618:	05850513          	addi	a0,a0,88
    8000361c:	ffffd097          	auipc	ra,0xffffd
    80003620:	77e080e7          	jalr	1918(ra) # 80000d9a <memset>
  log_write(bp);
    80003624:	854a                	mv	a0,s2
    80003626:	00001097          	auipc	ra,0x1
    8000362a:	080080e7          	jalr	128(ra) # 800046a6 <log_write>
  brelse(bp);
    8000362e:	854a                	mv	a0,s2
    80003630:	00000097          	auipc	ra,0x0
    80003634:	dec080e7          	jalr	-532(ra) # 8000341c <brelse>
}
    80003638:	8526                	mv	a0,s1
    8000363a:	60e6                	ld	ra,88(sp)
    8000363c:	6446                	ld	s0,80(sp)
    8000363e:	64a6                	ld	s1,72(sp)
    80003640:	6906                	ld	s2,64(sp)
    80003642:	79e2                	ld	s3,56(sp)
    80003644:	7a42                	ld	s4,48(sp)
    80003646:	7aa2                	ld	s5,40(sp)
    80003648:	7b02                	ld	s6,32(sp)
    8000364a:	6be2                	ld	s7,24(sp)
    8000364c:	6c42                	ld	s8,16(sp)
    8000364e:	6ca2                	ld	s9,8(sp)
    80003650:	6125                	addi	sp,sp,96
    80003652:	8082                	ret
    brelse(bp);
    80003654:	854a                	mv	a0,s2
    80003656:	00000097          	auipc	ra,0x0
    8000365a:	dc6080e7          	jalr	-570(ra) # 8000341c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000365e:	015c87bb          	addw	a5,s9,s5
    80003662:	00078a9b          	sext.w	s5,a5
    80003666:	004b2703          	lw	a4,4(s6)
    8000366a:	06eaf163          	bgeu	s5,a4,800036cc <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    8000366e:	41fad79b          	sraiw	a5,s5,0x1f
    80003672:	0137d79b          	srliw	a5,a5,0x13
    80003676:	015787bb          	addw	a5,a5,s5
    8000367a:	40d7d79b          	sraiw	a5,a5,0xd
    8000367e:	01cb2583          	lw	a1,28(s6)
    80003682:	9dbd                	addw	a1,a1,a5
    80003684:	855e                	mv	a0,s7
    80003686:	00000097          	auipc	ra,0x0
    8000368a:	c66080e7          	jalr	-922(ra) # 800032ec <bread>
    8000368e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003690:	004b2503          	lw	a0,4(s6)
    80003694:	000a849b          	sext.w	s1,s5
    80003698:	8762                	mv	a4,s8
    8000369a:	faa4fde3          	bgeu	s1,a0,80003654 <balloc+0xa6>
      m = 1 << (bi % 8);
    8000369e:	00777693          	andi	a3,a4,7
    800036a2:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800036a6:	41f7579b          	sraiw	a5,a4,0x1f
    800036aa:	01d7d79b          	srliw	a5,a5,0x1d
    800036ae:	9fb9                	addw	a5,a5,a4
    800036b0:	4037d79b          	sraiw	a5,a5,0x3
    800036b4:	00f90633          	add	a2,s2,a5
    800036b8:	05864603          	lbu	a2,88(a2)
    800036bc:	00c6f5b3          	and	a1,a3,a2
    800036c0:	d585                	beqz	a1,800035e8 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036c2:	2705                	addiw	a4,a4,1
    800036c4:	2485                	addiw	s1,s1,1
    800036c6:	fd471ae3          	bne	a4,s4,8000369a <balloc+0xec>
    800036ca:	b769                	j	80003654 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    800036cc:	00005517          	auipc	a0,0x5
    800036d0:	fbc50513          	addi	a0,a0,-68 # 80008688 <syscalls+0x128>
    800036d4:	ffffd097          	auipc	ra,0xffffd
    800036d8:	ec8080e7          	jalr	-312(ra) # 8000059c <printf>
  return 0;
    800036dc:	4481                	li	s1,0
    800036de:	bfa9                	j	80003638 <balloc+0x8a>

00000000800036e0 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800036e0:	7179                	addi	sp,sp,-48
    800036e2:	f406                	sd	ra,40(sp)
    800036e4:	f022                	sd	s0,32(sp)
    800036e6:	ec26                	sd	s1,24(sp)
    800036e8:	e84a                	sd	s2,16(sp)
    800036ea:	e44e                	sd	s3,8(sp)
    800036ec:	e052                	sd	s4,0(sp)
    800036ee:	1800                	addi	s0,sp,48
    800036f0:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800036f2:	47ad                	li	a5,11
    800036f4:	02b7e863          	bltu	a5,a1,80003724 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    800036f8:	02059793          	slli	a5,a1,0x20
    800036fc:	01e7d593          	srli	a1,a5,0x1e
    80003700:	00b504b3          	add	s1,a0,a1
    80003704:	0504a903          	lw	s2,80(s1)
    80003708:	06091e63          	bnez	s2,80003784 <bmap+0xa4>
      addr = balloc(ip->dev);
    8000370c:	4108                	lw	a0,0(a0)
    8000370e:	00000097          	auipc	ra,0x0
    80003712:	ea0080e7          	jalr	-352(ra) # 800035ae <balloc>
    80003716:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000371a:	06090563          	beqz	s2,80003784 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    8000371e:	0524a823          	sw	s2,80(s1)
    80003722:	a08d                	j	80003784 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003724:	ff45849b          	addiw	s1,a1,-12
    80003728:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000372c:	0ff00793          	li	a5,255
    80003730:	08e7e563          	bltu	a5,a4,800037ba <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003734:	08052903          	lw	s2,128(a0)
    80003738:	00091d63          	bnez	s2,80003752 <bmap+0x72>
      addr = balloc(ip->dev);
    8000373c:	4108                	lw	a0,0(a0)
    8000373e:	00000097          	auipc	ra,0x0
    80003742:	e70080e7          	jalr	-400(ra) # 800035ae <balloc>
    80003746:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000374a:	02090d63          	beqz	s2,80003784 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000374e:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003752:	85ca                	mv	a1,s2
    80003754:	0009a503          	lw	a0,0(s3)
    80003758:	00000097          	auipc	ra,0x0
    8000375c:	b94080e7          	jalr	-1132(ra) # 800032ec <bread>
    80003760:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003762:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003766:	02049713          	slli	a4,s1,0x20
    8000376a:	01e75593          	srli	a1,a4,0x1e
    8000376e:	00b784b3          	add	s1,a5,a1
    80003772:	0004a903          	lw	s2,0(s1)
    80003776:	02090063          	beqz	s2,80003796 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    8000377a:	8552                	mv	a0,s4
    8000377c:	00000097          	auipc	ra,0x0
    80003780:	ca0080e7          	jalr	-864(ra) # 8000341c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003784:	854a                	mv	a0,s2
    80003786:	70a2                	ld	ra,40(sp)
    80003788:	7402                	ld	s0,32(sp)
    8000378a:	64e2                	ld	s1,24(sp)
    8000378c:	6942                	ld	s2,16(sp)
    8000378e:	69a2                	ld	s3,8(sp)
    80003790:	6a02                	ld	s4,0(sp)
    80003792:	6145                	addi	sp,sp,48
    80003794:	8082                	ret
      addr = balloc(ip->dev);
    80003796:	0009a503          	lw	a0,0(s3)
    8000379a:	00000097          	auipc	ra,0x0
    8000379e:	e14080e7          	jalr	-492(ra) # 800035ae <balloc>
    800037a2:	0005091b          	sext.w	s2,a0
      if(addr){
    800037a6:	fc090ae3          	beqz	s2,8000377a <bmap+0x9a>
        a[bn] = addr;
    800037aa:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800037ae:	8552                	mv	a0,s4
    800037b0:	00001097          	auipc	ra,0x1
    800037b4:	ef6080e7          	jalr	-266(ra) # 800046a6 <log_write>
    800037b8:	b7c9                	j	8000377a <bmap+0x9a>
  panic("bmap: out of range");
    800037ba:	00005517          	auipc	a0,0x5
    800037be:	ee650513          	addi	a0,a0,-282 # 800086a0 <syscalls+0x140>
    800037c2:	ffffd097          	auipc	ra,0xffffd
    800037c6:	d7e080e7          	jalr	-642(ra) # 80000540 <panic>

00000000800037ca <iget>:
{
    800037ca:	7179                	addi	sp,sp,-48
    800037cc:	f406                	sd	ra,40(sp)
    800037ce:	f022                	sd	s0,32(sp)
    800037d0:	ec26                	sd	s1,24(sp)
    800037d2:	e84a                	sd	s2,16(sp)
    800037d4:	e44e                	sd	s3,8(sp)
    800037d6:	e052                	sd	s4,0(sp)
    800037d8:	1800                	addi	s0,sp,48
    800037da:	89aa                	mv	s3,a0
    800037dc:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800037de:	0001c517          	auipc	a0,0x1c
    800037e2:	a1a50513          	addi	a0,a0,-1510 # 8001f1f8 <itable>
    800037e6:	ffffd097          	auipc	ra,0xffffd
    800037ea:	4b8080e7          	jalr	1208(ra) # 80000c9e <acquire>
  empty = 0;
    800037ee:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800037f0:	0001c497          	auipc	s1,0x1c
    800037f4:	a2048493          	addi	s1,s1,-1504 # 8001f210 <itable+0x18>
    800037f8:	0001d697          	auipc	a3,0x1d
    800037fc:	4a868693          	addi	a3,a3,1192 # 80020ca0 <log>
    80003800:	a039                	j	8000380e <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003802:	02090b63          	beqz	s2,80003838 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003806:	08848493          	addi	s1,s1,136
    8000380a:	02d48a63          	beq	s1,a3,8000383e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000380e:	449c                	lw	a5,8(s1)
    80003810:	fef059e3          	blez	a5,80003802 <iget+0x38>
    80003814:	4098                	lw	a4,0(s1)
    80003816:	ff3716e3          	bne	a4,s3,80003802 <iget+0x38>
    8000381a:	40d8                	lw	a4,4(s1)
    8000381c:	ff4713e3          	bne	a4,s4,80003802 <iget+0x38>
      ip->ref++;
    80003820:	2785                	addiw	a5,a5,1
    80003822:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003824:	0001c517          	auipc	a0,0x1c
    80003828:	9d450513          	addi	a0,a0,-1580 # 8001f1f8 <itable>
    8000382c:	ffffd097          	auipc	ra,0xffffd
    80003830:	526080e7          	jalr	1318(ra) # 80000d52 <release>
      return ip;
    80003834:	8926                	mv	s2,s1
    80003836:	a03d                	j	80003864 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003838:	f7f9                	bnez	a5,80003806 <iget+0x3c>
    8000383a:	8926                	mv	s2,s1
    8000383c:	b7e9                	j	80003806 <iget+0x3c>
  if(empty == 0)
    8000383e:	02090c63          	beqz	s2,80003876 <iget+0xac>
  ip->dev = dev;
    80003842:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003846:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000384a:	4785                	li	a5,1
    8000384c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003850:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003854:	0001c517          	auipc	a0,0x1c
    80003858:	9a450513          	addi	a0,a0,-1628 # 8001f1f8 <itable>
    8000385c:	ffffd097          	auipc	ra,0xffffd
    80003860:	4f6080e7          	jalr	1270(ra) # 80000d52 <release>
}
    80003864:	854a                	mv	a0,s2
    80003866:	70a2                	ld	ra,40(sp)
    80003868:	7402                	ld	s0,32(sp)
    8000386a:	64e2                	ld	s1,24(sp)
    8000386c:	6942                	ld	s2,16(sp)
    8000386e:	69a2                	ld	s3,8(sp)
    80003870:	6a02                	ld	s4,0(sp)
    80003872:	6145                	addi	sp,sp,48
    80003874:	8082                	ret
    panic("iget: no inodes");
    80003876:	00005517          	auipc	a0,0x5
    8000387a:	e4250513          	addi	a0,a0,-446 # 800086b8 <syscalls+0x158>
    8000387e:	ffffd097          	auipc	ra,0xffffd
    80003882:	cc2080e7          	jalr	-830(ra) # 80000540 <panic>

0000000080003886 <fsinit>:
fsinit(int dev) {
    80003886:	7179                	addi	sp,sp,-48
    80003888:	f406                	sd	ra,40(sp)
    8000388a:	f022                	sd	s0,32(sp)
    8000388c:	ec26                	sd	s1,24(sp)
    8000388e:	e84a                	sd	s2,16(sp)
    80003890:	e44e                	sd	s3,8(sp)
    80003892:	1800                	addi	s0,sp,48
    80003894:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003896:	4585                	li	a1,1
    80003898:	00000097          	auipc	ra,0x0
    8000389c:	a54080e7          	jalr	-1452(ra) # 800032ec <bread>
    800038a0:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800038a2:	0001c997          	auipc	s3,0x1c
    800038a6:	93698993          	addi	s3,s3,-1738 # 8001f1d8 <sb>
    800038aa:	02000613          	li	a2,32
    800038ae:	05850593          	addi	a1,a0,88
    800038b2:	854e                	mv	a0,s3
    800038b4:	ffffd097          	auipc	ra,0xffffd
    800038b8:	542080e7          	jalr	1346(ra) # 80000df6 <memmove>
  brelse(bp);
    800038bc:	8526                	mv	a0,s1
    800038be:	00000097          	auipc	ra,0x0
    800038c2:	b5e080e7          	jalr	-1186(ra) # 8000341c <brelse>
  if(sb.magic != FSMAGIC)
    800038c6:	0009a703          	lw	a4,0(s3)
    800038ca:	102037b7          	lui	a5,0x10203
    800038ce:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800038d2:	02f71263          	bne	a4,a5,800038f6 <fsinit+0x70>
  initlog(dev, &sb);
    800038d6:	0001c597          	auipc	a1,0x1c
    800038da:	90258593          	addi	a1,a1,-1790 # 8001f1d8 <sb>
    800038de:	854a                	mv	a0,s2
    800038e0:	00001097          	auipc	ra,0x1
    800038e4:	b4a080e7          	jalr	-1206(ra) # 8000442a <initlog>
}
    800038e8:	70a2                	ld	ra,40(sp)
    800038ea:	7402                	ld	s0,32(sp)
    800038ec:	64e2                	ld	s1,24(sp)
    800038ee:	6942                	ld	s2,16(sp)
    800038f0:	69a2                	ld	s3,8(sp)
    800038f2:	6145                	addi	sp,sp,48
    800038f4:	8082                	ret
    panic("invalid file system");
    800038f6:	00005517          	auipc	a0,0x5
    800038fa:	dd250513          	addi	a0,a0,-558 # 800086c8 <syscalls+0x168>
    800038fe:	ffffd097          	auipc	ra,0xffffd
    80003902:	c42080e7          	jalr	-958(ra) # 80000540 <panic>

0000000080003906 <iinit>:
{
    80003906:	7179                	addi	sp,sp,-48
    80003908:	f406                	sd	ra,40(sp)
    8000390a:	f022                	sd	s0,32(sp)
    8000390c:	ec26                	sd	s1,24(sp)
    8000390e:	e84a                	sd	s2,16(sp)
    80003910:	e44e                	sd	s3,8(sp)
    80003912:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003914:	00005597          	auipc	a1,0x5
    80003918:	dcc58593          	addi	a1,a1,-564 # 800086e0 <syscalls+0x180>
    8000391c:	0001c517          	auipc	a0,0x1c
    80003920:	8dc50513          	addi	a0,a0,-1828 # 8001f1f8 <itable>
    80003924:	ffffd097          	auipc	ra,0xffffd
    80003928:	2ea080e7          	jalr	746(ra) # 80000c0e <initlock>
  for(i = 0; i < NINODE; i++) {
    8000392c:	0001c497          	auipc	s1,0x1c
    80003930:	8f448493          	addi	s1,s1,-1804 # 8001f220 <itable+0x28>
    80003934:	0001d997          	auipc	s3,0x1d
    80003938:	37c98993          	addi	s3,s3,892 # 80020cb0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000393c:	00005917          	auipc	s2,0x5
    80003940:	dac90913          	addi	s2,s2,-596 # 800086e8 <syscalls+0x188>
    80003944:	85ca                	mv	a1,s2
    80003946:	8526                	mv	a0,s1
    80003948:	00001097          	auipc	ra,0x1
    8000394c:	e42080e7          	jalr	-446(ra) # 8000478a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003950:	08848493          	addi	s1,s1,136
    80003954:	ff3498e3          	bne	s1,s3,80003944 <iinit+0x3e>
}
    80003958:	70a2                	ld	ra,40(sp)
    8000395a:	7402                	ld	s0,32(sp)
    8000395c:	64e2                	ld	s1,24(sp)
    8000395e:	6942                	ld	s2,16(sp)
    80003960:	69a2                	ld	s3,8(sp)
    80003962:	6145                	addi	sp,sp,48
    80003964:	8082                	ret

0000000080003966 <ialloc>:
{
    80003966:	715d                	addi	sp,sp,-80
    80003968:	e486                	sd	ra,72(sp)
    8000396a:	e0a2                	sd	s0,64(sp)
    8000396c:	fc26                	sd	s1,56(sp)
    8000396e:	f84a                	sd	s2,48(sp)
    80003970:	f44e                	sd	s3,40(sp)
    80003972:	f052                	sd	s4,32(sp)
    80003974:	ec56                	sd	s5,24(sp)
    80003976:	e85a                	sd	s6,16(sp)
    80003978:	e45e                	sd	s7,8(sp)
    8000397a:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000397c:	0001c717          	auipc	a4,0x1c
    80003980:	86872703          	lw	a4,-1944(a4) # 8001f1e4 <sb+0xc>
    80003984:	4785                	li	a5,1
    80003986:	04e7fa63          	bgeu	a5,a4,800039da <ialloc+0x74>
    8000398a:	8aaa                	mv	s5,a0
    8000398c:	8bae                	mv	s7,a1
    8000398e:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003990:	0001ca17          	auipc	s4,0x1c
    80003994:	848a0a13          	addi	s4,s4,-1976 # 8001f1d8 <sb>
    80003998:	00048b1b          	sext.w	s6,s1
    8000399c:	0044d593          	srli	a1,s1,0x4
    800039a0:	018a2783          	lw	a5,24(s4)
    800039a4:	9dbd                	addw	a1,a1,a5
    800039a6:	8556                	mv	a0,s5
    800039a8:	00000097          	auipc	ra,0x0
    800039ac:	944080e7          	jalr	-1724(ra) # 800032ec <bread>
    800039b0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800039b2:	05850993          	addi	s3,a0,88
    800039b6:	00f4f793          	andi	a5,s1,15
    800039ba:	079a                	slli	a5,a5,0x6
    800039bc:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800039be:	00099783          	lh	a5,0(s3)
    800039c2:	c3a1                	beqz	a5,80003a02 <ialloc+0x9c>
    brelse(bp);
    800039c4:	00000097          	auipc	ra,0x0
    800039c8:	a58080e7          	jalr	-1448(ra) # 8000341c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800039cc:	0485                	addi	s1,s1,1
    800039ce:	00ca2703          	lw	a4,12(s4)
    800039d2:	0004879b          	sext.w	a5,s1
    800039d6:	fce7e1e3          	bltu	a5,a4,80003998 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    800039da:	00005517          	auipc	a0,0x5
    800039de:	d1650513          	addi	a0,a0,-746 # 800086f0 <syscalls+0x190>
    800039e2:	ffffd097          	auipc	ra,0xffffd
    800039e6:	bba080e7          	jalr	-1094(ra) # 8000059c <printf>
  return 0;
    800039ea:	4501                	li	a0,0
}
    800039ec:	60a6                	ld	ra,72(sp)
    800039ee:	6406                	ld	s0,64(sp)
    800039f0:	74e2                	ld	s1,56(sp)
    800039f2:	7942                	ld	s2,48(sp)
    800039f4:	79a2                	ld	s3,40(sp)
    800039f6:	7a02                	ld	s4,32(sp)
    800039f8:	6ae2                	ld	s5,24(sp)
    800039fa:	6b42                	ld	s6,16(sp)
    800039fc:	6ba2                	ld	s7,8(sp)
    800039fe:	6161                	addi	sp,sp,80
    80003a00:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003a02:	04000613          	li	a2,64
    80003a06:	4581                	li	a1,0
    80003a08:	854e                	mv	a0,s3
    80003a0a:	ffffd097          	auipc	ra,0xffffd
    80003a0e:	390080e7          	jalr	912(ra) # 80000d9a <memset>
      dip->type = type;
    80003a12:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003a16:	854a                	mv	a0,s2
    80003a18:	00001097          	auipc	ra,0x1
    80003a1c:	c8e080e7          	jalr	-882(ra) # 800046a6 <log_write>
      brelse(bp);
    80003a20:	854a                	mv	a0,s2
    80003a22:	00000097          	auipc	ra,0x0
    80003a26:	9fa080e7          	jalr	-1542(ra) # 8000341c <brelse>
      return iget(dev, inum);
    80003a2a:	85da                	mv	a1,s6
    80003a2c:	8556                	mv	a0,s5
    80003a2e:	00000097          	auipc	ra,0x0
    80003a32:	d9c080e7          	jalr	-612(ra) # 800037ca <iget>
    80003a36:	bf5d                	j	800039ec <ialloc+0x86>

0000000080003a38 <iupdate>:
{
    80003a38:	1101                	addi	sp,sp,-32
    80003a3a:	ec06                	sd	ra,24(sp)
    80003a3c:	e822                	sd	s0,16(sp)
    80003a3e:	e426                	sd	s1,8(sp)
    80003a40:	e04a                	sd	s2,0(sp)
    80003a42:	1000                	addi	s0,sp,32
    80003a44:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a46:	415c                	lw	a5,4(a0)
    80003a48:	0047d79b          	srliw	a5,a5,0x4
    80003a4c:	0001b597          	auipc	a1,0x1b
    80003a50:	7a45a583          	lw	a1,1956(a1) # 8001f1f0 <sb+0x18>
    80003a54:	9dbd                	addw	a1,a1,a5
    80003a56:	4108                	lw	a0,0(a0)
    80003a58:	00000097          	auipc	ra,0x0
    80003a5c:	894080e7          	jalr	-1900(ra) # 800032ec <bread>
    80003a60:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a62:	05850793          	addi	a5,a0,88
    80003a66:	40d8                	lw	a4,4(s1)
    80003a68:	8b3d                	andi	a4,a4,15
    80003a6a:	071a                	slli	a4,a4,0x6
    80003a6c:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003a6e:	04449703          	lh	a4,68(s1)
    80003a72:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003a76:	04649703          	lh	a4,70(s1)
    80003a7a:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003a7e:	04849703          	lh	a4,72(s1)
    80003a82:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003a86:	04a49703          	lh	a4,74(s1)
    80003a8a:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003a8e:	44f8                	lw	a4,76(s1)
    80003a90:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003a92:	03400613          	li	a2,52
    80003a96:	05048593          	addi	a1,s1,80
    80003a9a:	00c78513          	addi	a0,a5,12
    80003a9e:	ffffd097          	auipc	ra,0xffffd
    80003aa2:	358080e7          	jalr	856(ra) # 80000df6 <memmove>
  log_write(bp);
    80003aa6:	854a                	mv	a0,s2
    80003aa8:	00001097          	auipc	ra,0x1
    80003aac:	bfe080e7          	jalr	-1026(ra) # 800046a6 <log_write>
  brelse(bp);
    80003ab0:	854a                	mv	a0,s2
    80003ab2:	00000097          	auipc	ra,0x0
    80003ab6:	96a080e7          	jalr	-1686(ra) # 8000341c <brelse>
}
    80003aba:	60e2                	ld	ra,24(sp)
    80003abc:	6442                	ld	s0,16(sp)
    80003abe:	64a2                	ld	s1,8(sp)
    80003ac0:	6902                	ld	s2,0(sp)
    80003ac2:	6105                	addi	sp,sp,32
    80003ac4:	8082                	ret

0000000080003ac6 <idup>:
{
    80003ac6:	1101                	addi	sp,sp,-32
    80003ac8:	ec06                	sd	ra,24(sp)
    80003aca:	e822                	sd	s0,16(sp)
    80003acc:	e426                	sd	s1,8(sp)
    80003ace:	1000                	addi	s0,sp,32
    80003ad0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ad2:	0001b517          	auipc	a0,0x1b
    80003ad6:	72650513          	addi	a0,a0,1830 # 8001f1f8 <itable>
    80003ada:	ffffd097          	auipc	ra,0xffffd
    80003ade:	1c4080e7          	jalr	452(ra) # 80000c9e <acquire>
  ip->ref++;
    80003ae2:	449c                	lw	a5,8(s1)
    80003ae4:	2785                	addiw	a5,a5,1
    80003ae6:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ae8:	0001b517          	auipc	a0,0x1b
    80003aec:	71050513          	addi	a0,a0,1808 # 8001f1f8 <itable>
    80003af0:	ffffd097          	auipc	ra,0xffffd
    80003af4:	262080e7          	jalr	610(ra) # 80000d52 <release>
}
    80003af8:	8526                	mv	a0,s1
    80003afa:	60e2                	ld	ra,24(sp)
    80003afc:	6442                	ld	s0,16(sp)
    80003afe:	64a2                	ld	s1,8(sp)
    80003b00:	6105                	addi	sp,sp,32
    80003b02:	8082                	ret

0000000080003b04 <ilock>:
{
    80003b04:	1101                	addi	sp,sp,-32
    80003b06:	ec06                	sd	ra,24(sp)
    80003b08:	e822                	sd	s0,16(sp)
    80003b0a:	e426                	sd	s1,8(sp)
    80003b0c:	e04a                	sd	s2,0(sp)
    80003b0e:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003b10:	c115                	beqz	a0,80003b34 <ilock+0x30>
    80003b12:	84aa                	mv	s1,a0
    80003b14:	451c                	lw	a5,8(a0)
    80003b16:	00f05f63          	blez	a5,80003b34 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003b1a:	0541                	addi	a0,a0,16
    80003b1c:	00001097          	auipc	ra,0x1
    80003b20:	ca8080e7          	jalr	-856(ra) # 800047c4 <acquiresleep>
  if(ip->valid == 0){
    80003b24:	40bc                	lw	a5,64(s1)
    80003b26:	cf99                	beqz	a5,80003b44 <ilock+0x40>
}
    80003b28:	60e2                	ld	ra,24(sp)
    80003b2a:	6442                	ld	s0,16(sp)
    80003b2c:	64a2                	ld	s1,8(sp)
    80003b2e:	6902                	ld	s2,0(sp)
    80003b30:	6105                	addi	sp,sp,32
    80003b32:	8082                	ret
    panic("ilock");
    80003b34:	00005517          	auipc	a0,0x5
    80003b38:	bd450513          	addi	a0,a0,-1068 # 80008708 <syscalls+0x1a8>
    80003b3c:	ffffd097          	auipc	ra,0xffffd
    80003b40:	a04080e7          	jalr	-1532(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b44:	40dc                	lw	a5,4(s1)
    80003b46:	0047d79b          	srliw	a5,a5,0x4
    80003b4a:	0001b597          	auipc	a1,0x1b
    80003b4e:	6a65a583          	lw	a1,1702(a1) # 8001f1f0 <sb+0x18>
    80003b52:	9dbd                	addw	a1,a1,a5
    80003b54:	4088                	lw	a0,0(s1)
    80003b56:	fffff097          	auipc	ra,0xfffff
    80003b5a:	796080e7          	jalr	1942(ra) # 800032ec <bread>
    80003b5e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b60:	05850593          	addi	a1,a0,88
    80003b64:	40dc                	lw	a5,4(s1)
    80003b66:	8bbd                	andi	a5,a5,15
    80003b68:	079a                	slli	a5,a5,0x6
    80003b6a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003b6c:	00059783          	lh	a5,0(a1)
    80003b70:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003b74:	00259783          	lh	a5,2(a1)
    80003b78:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003b7c:	00459783          	lh	a5,4(a1)
    80003b80:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003b84:	00659783          	lh	a5,6(a1)
    80003b88:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003b8c:	459c                	lw	a5,8(a1)
    80003b8e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003b90:	03400613          	li	a2,52
    80003b94:	05b1                	addi	a1,a1,12
    80003b96:	05048513          	addi	a0,s1,80
    80003b9a:	ffffd097          	auipc	ra,0xffffd
    80003b9e:	25c080e7          	jalr	604(ra) # 80000df6 <memmove>
    brelse(bp);
    80003ba2:	854a                	mv	a0,s2
    80003ba4:	00000097          	auipc	ra,0x0
    80003ba8:	878080e7          	jalr	-1928(ra) # 8000341c <brelse>
    ip->valid = 1;
    80003bac:	4785                	li	a5,1
    80003bae:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003bb0:	04449783          	lh	a5,68(s1)
    80003bb4:	fbb5                	bnez	a5,80003b28 <ilock+0x24>
      panic("ilock: no type");
    80003bb6:	00005517          	auipc	a0,0x5
    80003bba:	b5a50513          	addi	a0,a0,-1190 # 80008710 <syscalls+0x1b0>
    80003bbe:	ffffd097          	auipc	ra,0xffffd
    80003bc2:	982080e7          	jalr	-1662(ra) # 80000540 <panic>

0000000080003bc6 <iunlock>:
{
    80003bc6:	1101                	addi	sp,sp,-32
    80003bc8:	ec06                	sd	ra,24(sp)
    80003bca:	e822                	sd	s0,16(sp)
    80003bcc:	e426                	sd	s1,8(sp)
    80003bce:	e04a                	sd	s2,0(sp)
    80003bd0:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003bd2:	c905                	beqz	a0,80003c02 <iunlock+0x3c>
    80003bd4:	84aa                	mv	s1,a0
    80003bd6:	01050913          	addi	s2,a0,16
    80003bda:	854a                	mv	a0,s2
    80003bdc:	00001097          	auipc	ra,0x1
    80003be0:	c82080e7          	jalr	-894(ra) # 8000485e <holdingsleep>
    80003be4:	cd19                	beqz	a0,80003c02 <iunlock+0x3c>
    80003be6:	449c                	lw	a5,8(s1)
    80003be8:	00f05d63          	blez	a5,80003c02 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003bec:	854a                	mv	a0,s2
    80003bee:	00001097          	auipc	ra,0x1
    80003bf2:	c2c080e7          	jalr	-980(ra) # 8000481a <releasesleep>
}
    80003bf6:	60e2                	ld	ra,24(sp)
    80003bf8:	6442                	ld	s0,16(sp)
    80003bfa:	64a2                	ld	s1,8(sp)
    80003bfc:	6902                	ld	s2,0(sp)
    80003bfe:	6105                	addi	sp,sp,32
    80003c00:	8082                	ret
    panic("iunlock");
    80003c02:	00005517          	auipc	a0,0x5
    80003c06:	b1e50513          	addi	a0,a0,-1250 # 80008720 <syscalls+0x1c0>
    80003c0a:	ffffd097          	auipc	ra,0xffffd
    80003c0e:	936080e7          	jalr	-1738(ra) # 80000540 <panic>

0000000080003c12 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003c12:	7179                	addi	sp,sp,-48
    80003c14:	f406                	sd	ra,40(sp)
    80003c16:	f022                	sd	s0,32(sp)
    80003c18:	ec26                	sd	s1,24(sp)
    80003c1a:	e84a                	sd	s2,16(sp)
    80003c1c:	e44e                	sd	s3,8(sp)
    80003c1e:	e052                	sd	s4,0(sp)
    80003c20:	1800                	addi	s0,sp,48
    80003c22:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003c24:	05050493          	addi	s1,a0,80
    80003c28:	08050913          	addi	s2,a0,128
    80003c2c:	a021                	j	80003c34 <itrunc+0x22>
    80003c2e:	0491                	addi	s1,s1,4
    80003c30:	01248d63          	beq	s1,s2,80003c4a <itrunc+0x38>
    if(ip->addrs[i]){
    80003c34:	408c                	lw	a1,0(s1)
    80003c36:	dde5                	beqz	a1,80003c2e <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003c38:	0009a503          	lw	a0,0(s3)
    80003c3c:	00000097          	auipc	ra,0x0
    80003c40:	8f6080e7          	jalr	-1802(ra) # 80003532 <bfree>
      ip->addrs[i] = 0;
    80003c44:	0004a023          	sw	zero,0(s1)
    80003c48:	b7dd                	j	80003c2e <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003c4a:	0809a583          	lw	a1,128(s3)
    80003c4e:	e185                	bnez	a1,80003c6e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003c50:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003c54:	854e                	mv	a0,s3
    80003c56:	00000097          	auipc	ra,0x0
    80003c5a:	de2080e7          	jalr	-542(ra) # 80003a38 <iupdate>
}
    80003c5e:	70a2                	ld	ra,40(sp)
    80003c60:	7402                	ld	s0,32(sp)
    80003c62:	64e2                	ld	s1,24(sp)
    80003c64:	6942                	ld	s2,16(sp)
    80003c66:	69a2                	ld	s3,8(sp)
    80003c68:	6a02                	ld	s4,0(sp)
    80003c6a:	6145                	addi	sp,sp,48
    80003c6c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003c6e:	0009a503          	lw	a0,0(s3)
    80003c72:	fffff097          	auipc	ra,0xfffff
    80003c76:	67a080e7          	jalr	1658(ra) # 800032ec <bread>
    80003c7a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003c7c:	05850493          	addi	s1,a0,88
    80003c80:	45850913          	addi	s2,a0,1112
    80003c84:	a021                	j	80003c8c <itrunc+0x7a>
    80003c86:	0491                	addi	s1,s1,4
    80003c88:	01248b63          	beq	s1,s2,80003c9e <itrunc+0x8c>
      if(a[j])
    80003c8c:	408c                	lw	a1,0(s1)
    80003c8e:	dde5                	beqz	a1,80003c86 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003c90:	0009a503          	lw	a0,0(s3)
    80003c94:	00000097          	auipc	ra,0x0
    80003c98:	89e080e7          	jalr	-1890(ra) # 80003532 <bfree>
    80003c9c:	b7ed                	j	80003c86 <itrunc+0x74>
    brelse(bp);
    80003c9e:	8552                	mv	a0,s4
    80003ca0:	fffff097          	auipc	ra,0xfffff
    80003ca4:	77c080e7          	jalr	1916(ra) # 8000341c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003ca8:	0809a583          	lw	a1,128(s3)
    80003cac:	0009a503          	lw	a0,0(s3)
    80003cb0:	00000097          	auipc	ra,0x0
    80003cb4:	882080e7          	jalr	-1918(ra) # 80003532 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003cb8:	0809a023          	sw	zero,128(s3)
    80003cbc:	bf51                	j	80003c50 <itrunc+0x3e>

0000000080003cbe <iput>:
{
    80003cbe:	1101                	addi	sp,sp,-32
    80003cc0:	ec06                	sd	ra,24(sp)
    80003cc2:	e822                	sd	s0,16(sp)
    80003cc4:	e426                	sd	s1,8(sp)
    80003cc6:	e04a                	sd	s2,0(sp)
    80003cc8:	1000                	addi	s0,sp,32
    80003cca:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ccc:	0001b517          	auipc	a0,0x1b
    80003cd0:	52c50513          	addi	a0,a0,1324 # 8001f1f8 <itable>
    80003cd4:	ffffd097          	auipc	ra,0xffffd
    80003cd8:	fca080e7          	jalr	-54(ra) # 80000c9e <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003cdc:	4498                	lw	a4,8(s1)
    80003cde:	4785                	li	a5,1
    80003ce0:	02f70363          	beq	a4,a5,80003d06 <iput+0x48>
  ip->ref--;
    80003ce4:	449c                	lw	a5,8(s1)
    80003ce6:	37fd                	addiw	a5,a5,-1
    80003ce8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003cea:	0001b517          	auipc	a0,0x1b
    80003cee:	50e50513          	addi	a0,a0,1294 # 8001f1f8 <itable>
    80003cf2:	ffffd097          	auipc	ra,0xffffd
    80003cf6:	060080e7          	jalr	96(ra) # 80000d52 <release>
}
    80003cfa:	60e2                	ld	ra,24(sp)
    80003cfc:	6442                	ld	s0,16(sp)
    80003cfe:	64a2                	ld	s1,8(sp)
    80003d00:	6902                	ld	s2,0(sp)
    80003d02:	6105                	addi	sp,sp,32
    80003d04:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d06:	40bc                	lw	a5,64(s1)
    80003d08:	dff1                	beqz	a5,80003ce4 <iput+0x26>
    80003d0a:	04a49783          	lh	a5,74(s1)
    80003d0e:	fbf9                	bnez	a5,80003ce4 <iput+0x26>
    acquiresleep(&ip->lock);
    80003d10:	01048913          	addi	s2,s1,16
    80003d14:	854a                	mv	a0,s2
    80003d16:	00001097          	auipc	ra,0x1
    80003d1a:	aae080e7          	jalr	-1362(ra) # 800047c4 <acquiresleep>
    release(&itable.lock);
    80003d1e:	0001b517          	auipc	a0,0x1b
    80003d22:	4da50513          	addi	a0,a0,1242 # 8001f1f8 <itable>
    80003d26:	ffffd097          	auipc	ra,0xffffd
    80003d2a:	02c080e7          	jalr	44(ra) # 80000d52 <release>
    itrunc(ip);
    80003d2e:	8526                	mv	a0,s1
    80003d30:	00000097          	auipc	ra,0x0
    80003d34:	ee2080e7          	jalr	-286(ra) # 80003c12 <itrunc>
    ip->type = 0;
    80003d38:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003d3c:	8526                	mv	a0,s1
    80003d3e:	00000097          	auipc	ra,0x0
    80003d42:	cfa080e7          	jalr	-774(ra) # 80003a38 <iupdate>
    ip->valid = 0;
    80003d46:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003d4a:	854a                	mv	a0,s2
    80003d4c:	00001097          	auipc	ra,0x1
    80003d50:	ace080e7          	jalr	-1330(ra) # 8000481a <releasesleep>
    acquire(&itable.lock);
    80003d54:	0001b517          	auipc	a0,0x1b
    80003d58:	4a450513          	addi	a0,a0,1188 # 8001f1f8 <itable>
    80003d5c:	ffffd097          	auipc	ra,0xffffd
    80003d60:	f42080e7          	jalr	-190(ra) # 80000c9e <acquire>
    80003d64:	b741                	j	80003ce4 <iput+0x26>

0000000080003d66 <iunlockput>:
{
    80003d66:	1101                	addi	sp,sp,-32
    80003d68:	ec06                	sd	ra,24(sp)
    80003d6a:	e822                	sd	s0,16(sp)
    80003d6c:	e426                	sd	s1,8(sp)
    80003d6e:	1000                	addi	s0,sp,32
    80003d70:	84aa                	mv	s1,a0
  iunlock(ip);
    80003d72:	00000097          	auipc	ra,0x0
    80003d76:	e54080e7          	jalr	-428(ra) # 80003bc6 <iunlock>
  iput(ip);
    80003d7a:	8526                	mv	a0,s1
    80003d7c:	00000097          	auipc	ra,0x0
    80003d80:	f42080e7          	jalr	-190(ra) # 80003cbe <iput>
}
    80003d84:	60e2                	ld	ra,24(sp)
    80003d86:	6442                	ld	s0,16(sp)
    80003d88:	64a2                	ld	s1,8(sp)
    80003d8a:	6105                	addi	sp,sp,32
    80003d8c:	8082                	ret

0000000080003d8e <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003d8e:	1141                	addi	sp,sp,-16
    80003d90:	e422                	sd	s0,8(sp)
    80003d92:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003d94:	411c                	lw	a5,0(a0)
    80003d96:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003d98:	415c                	lw	a5,4(a0)
    80003d9a:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003d9c:	04451783          	lh	a5,68(a0)
    80003da0:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003da4:	04a51783          	lh	a5,74(a0)
    80003da8:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003dac:	04c56783          	lwu	a5,76(a0)
    80003db0:	e99c                	sd	a5,16(a1)
}
    80003db2:	6422                	ld	s0,8(sp)
    80003db4:	0141                	addi	sp,sp,16
    80003db6:	8082                	ret

0000000080003db8 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003db8:	457c                	lw	a5,76(a0)
    80003dba:	0ed7e963          	bltu	a5,a3,80003eac <readi+0xf4>
{
    80003dbe:	7159                	addi	sp,sp,-112
    80003dc0:	f486                	sd	ra,104(sp)
    80003dc2:	f0a2                	sd	s0,96(sp)
    80003dc4:	eca6                	sd	s1,88(sp)
    80003dc6:	e8ca                	sd	s2,80(sp)
    80003dc8:	e4ce                	sd	s3,72(sp)
    80003dca:	e0d2                	sd	s4,64(sp)
    80003dcc:	fc56                	sd	s5,56(sp)
    80003dce:	f85a                	sd	s6,48(sp)
    80003dd0:	f45e                	sd	s7,40(sp)
    80003dd2:	f062                	sd	s8,32(sp)
    80003dd4:	ec66                	sd	s9,24(sp)
    80003dd6:	e86a                	sd	s10,16(sp)
    80003dd8:	e46e                	sd	s11,8(sp)
    80003dda:	1880                	addi	s0,sp,112
    80003ddc:	8b2a                	mv	s6,a0
    80003dde:	8bae                	mv	s7,a1
    80003de0:	8a32                	mv	s4,a2
    80003de2:	84b6                	mv	s1,a3
    80003de4:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003de6:	9f35                	addw	a4,a4,a3
    return 0;
    80003de8:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003dea:	0ad76063          	bltu	a4,a3,80003e8a <readi+0xd2>
  if(off + n > ip->size)
    80003dee:	00e7f463          	bgeu	a5,a4,80003df6 <readi+0x3e>
    n = ip->size - off;
    80003df2:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003df6:	0a0a8963          	beqz	s5,80003ea8 <readi+0xf0>
    80003dfa:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dfc:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003e00:	5c7d                	li	s8,-1
    80003e02:	a82d                	j	80003e3c <readi+0x84>
    80003e04:	020d1d93          	slli	s11,s10,0x20
    80003e08:	020ddd93          	srli	s11,s11,0x20
    80003e0c:	05890613          	addi	a2,s2,88
    80003e10:	86ee                	mv	a3,s11
    80003e12:	963a                	add	a2,a2,a4
    80003e14:	85d2                	mv	a1,s4
    80003e16:	855e                	mv	a0,s7
    80003e18:	fffff097          	auipc	ra,0xfffff
    80003e1c:	910080e7          	jalr	-1776(ra) # 80002728 <either_copyout>
    80003e20:	05850d63          	beq	a0,s8,80003e7a <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003e24:	854a                	mv	a0,s2
    80003e26:	fffff097          	auipc	ra,0xfffff
    80003e2a:	5f6080e7          	jalr	1526(ra) # 8000341c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e2e:	013d09bb          	addw	s3,s10,s3
    80003e32:	009d04bb          	addw	s1,s10,s1
    80003e36:	9a6e                	add	s4,s4,s11
    80003e38:	0559f763          	bgeu	s3,s5,80003e86 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003e3c:	00a4d59b          	srliw	a1,s1,0xa
    80003e40:	855a                	mv	a0,s6
    80003e42:	00000097          	auipc	ra,0x0
    80003e46:	89e080e7          	jalr	-1890(ra) # 800036e0 <bmap>
    80003e4a:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003e4e:	cd85                	beqz	a1,80003e86 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003e50:	000b2503          	lw	a0,0(s6)
    80003e54:	fffff097          	auipc	ra,0xfffff
    80003e58:	498080e7          	jalr	1176(ra) # 800032ec <bread>
    80003e5c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e5e:	3ff4f713          	andi	a4,s1,1023
    80003e62:	40ec87bb          	subw	a5,s9,a4
    80003e66:	413a86bb          	subw	a3,s5,s3
    80003e6a:	8d3e                	mv	s10,a5
    80003e6c:	2781                	sext.w	a5,a5
    80003e6e:	0006861b          	sext.w	a2,a3
    80003e72:	f8f679e3          	bgeu	a2,a5,80003e04 <readi+0x4c>
    80003e76:	8d36                	mv	s10,a3
    80003e78:	b771                	j	80003e04 <readi+0x4c>
      brelse(bp);
    80003e7a:	854a                	mv	a0,s2
    80003e7c:	fffff097          	auipc	ra,0xfffff
    80003e80:	5a0080e7          	jalr	1440(ra) # 8000341c <brelse>
      tot = -1;
    80003e84:	59fd                	li	s3,-1
  }
  return tot;
    80003e86:	0009851b          	sext.w	a0,s3
}
    80003e8a:	70a6                	ld	ra,104(sp)
    80003e8c:	7406                	ld	s0,96(sp)
    80003e8e:	64e6                	ld	s1,88(sp)
    80003e90:	6946                	ld	s2,80(sp)
    80003e92:	69a6                	ld	s3,72(sp)
    80003e94:	6a06                	ld	s4,64(sp)
    80003e96:	7ae2                	ld	s5,56(sp)
    80003e98:	7b42                	ld	s6,48(sp)
    80003e9a:	7ba2                	ld	s7,40(sp)
    80003e9c:	7c02                	ld	s8,32(sp)
    80003e9e:	6ce2                	ld	s9,24(sp)
    80003ea0:	6d42                	ld	s10,16(sp)
    80003ea2:	6da2                	ld	s11,8(sp)
    80003ea4:	6165                	addi	sp,sp,112
    80003ea6:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ea8:	89d6                	mv	s3,s5
    80003eaa:	bff1                	j	80003e86 <readi+0xce>
    return 0;
    80003eac:	4501                	li	a0,0
}
    80003eae:	8082                	ret

0000000080003eb0 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003eb0:	457c                	lw	a5,76(a0)
    80003eb2:	10d7e863          	bltu	a5,a3,80003fc2 <writei+0x112>
{
    80003eb6:	7159                	addi	sp,sp,-112
    80003eb8:	f486                	sd	ra,104(sp)
    80003eba:	f0a2                	sd	s0,96(sp)
    80003ebc:	eca6                	sd	s1,88(sp)
    80003ebe:	e8ca                	sd	s2,80(sp)
    80003ec0:	e4ce                	sd	s3,72(sp)
    80003ec2:	e0d2                	sd	s4,64(sp)
    80003ec4:	fc56                	sd	s5,56(sp)
    80003ec6:	f85a                	sd	s6,48(sp)
    80003ec8:	f45e                	sd	s7,40(sp)
    80003eca:	f062                	sd	s8,32(sp)
    80003ecc:	ec66                	sd	s9,24(sp)
    80003ece:	e86a                	sd	s10,16(sp)
    80003ed0:	e46e                	sd	s11,8(sp)
    80003ed2:	1880                	addi	s0,sp,112
    80003ed4:	8aaa                	mv	s5,a0
    80003ed6:	8bae                	mv	s7,a1
    80003ed8:	8a32                	mv	s4,a2
    80003eda:	8936                	mv	s2,a3
    80003edc:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003ede:	00e687bb          	addw	a5,a3,a4
    80003ee2:	0ed7e263          	bltu	a5,a3,80003fc6 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003ee6:	00043737          	lui	a4,0x43
    80003eea:	0ef76063          	bltu	a4,a5,80003fca <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003eee:	0c0b0863          	beqz	s6,80003fbe <writei+0x10e>
    80003ef2:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ef4:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003ef8:	5c7d                	li	s8,-1
    80003efa:	a091                	j	80003f3e <writei+0x8e>
    80003efc:	020d1d93          	slli	s11,s10,0x20
    80003f00:	020ddd93          	srli	s11,s11,0x20
    80003f04:	05848513          	addi	a0,s1,88
    80003f08:	86ee                	mv	a3,s11
    80003f0a:	8652                	mv	a2,s4
    80003f0c:	85de                	mv	a1,s7
    80003f0e:	953a                	add	a0,a0,a4
    80003f10:	fffff097          	auipc	ra,0xfffff
    80003f14:	86e080e7          	jalr	-1938(ra) # 8000277e <either_copyin>
    80003f18:	07850263          	beq	a0,s8,80003f7c <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003f1c:	8526                	mv	a0,s1
    80003f1e:	00000097          	auipc	ra,0x0
    80003f22:	788080e7          	jalr	1928(ra) # 800046a6 <log_write>
    brelse(bp);
    80003f26:	8526                	mv	a0,s1
    80003f28:	fffff097          	auipc	ra,0xfffff
    80003f2c:	4f4080e7          	jalr	1268(ra) # 8000341c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f30:	013d09bb          	addw	s3,s10,s3
    80003f34:	012d093b          	addw	s2,s10,s2
    80003f38:	9a6e                	add	s4,s4,s11
    80003f3a:	0569f663          	bgeu	s3,s6,80003f86 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003f3e:	00a9559b          	srliw	a1,s2,0xa
    80003f42:	8556                	mv	a0,s5
    80003f44:	fffff097          	auipc	ra,0xfffff
    80003f48:	79c080e7          	jalr	1948(ra) # 800036e0 <bmap>
    80003f4c:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003f50:	c99d                	beqz	a1,80003f86 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003f52:	000aa503          	lw	a0,0(s5)
    80003f56:	fffff097          	auipc	ra,0xfffff
    80003f5a:	396080e7          	jalr	918(ra) # 800032ec <bread>
    80003f5e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f60:	3ff97713          	andi	a4,s2,1023
    80003f64:	40ec87bb          	subw	a5,s9,a4
    80003f68:	413b06bb          	subw	a3,s6,s3
    80003f6c:	8d3e                	mv	s10,a5
    80003f6e:	2781                	sext.w	a5,a5
    80003f70:	0006861b          	sext.w	a2,a3
    80003f74:	f8f674e3          	bgeu	a2,a5,80003efc <writei+0x4c>
    80003f78:	8d36                	mv	s10,a3
    80003f7a:	b749                	j	80003efc <writei+0x4c>
      brelse(bp);
    80003f7c:	8526                	mv	a0,s1
    80003f7e:	fffff097          	auipc	ra,0xfffff
    80003f82:	49e080e7          	jalr	1182(ra) # 8000341c <brelse>
  }

  if(off > ip->size)
    80003f86:	04caa783          	lw	a5,76(s5)
    80003f8a:	0127f463          	bgeu	a5,s2,80003f92 <writei+0xe2>
    ip->size = off;
    80003f8e:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003f92:	8556                	mv	a0,s5
    80003f94:	00000097          	auipc	ra,0x0
    80003f98:	aa4080e7          	jalr	-1372(ra) # 80003a38 <iupdate>

  return tot;
    80003f9c:	0009851b          	sext.w	a0,s3
}
    80003fa0:	70a6                	ld	ra,104(sp)
    80003fa2:	7406                	ld	s0,96(sp)
    80003fa4:	64e6                	ld	s1,88(sp)
    80003fa6:	6946                	ld	s2,80(sp)
    80003fa8:	69a6                	ld	s3,72(sp)
    80003faa:	6a06                	ld	s4,64(sp)
    80003fac:	7ae2                	ld	s5,56(sp)
    80003fae:	7b42                	ld	s6,48(sp)
    80003fb0:	7ba2                	ld	s7,40(sp)
    80003fb2:	7c02                	ld	s8,32(sp)
    80003fb4:	6ce2                	ld	s9,24(sp)
    80003fb6:	6d42                	ld	s10,16(sp)
    80003fb8:	6da2                	ld	s11,8(sp)
    80003fba:	6165                	addi	sp,sp,112
    80003fbc:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003fbe:	89da                	mv	s3,s6
    80003fc0:	bfc9                	j	80003f92 <writei+0xe2>
    return -1;
    80003fc2:	557d                	li	a0,-1
}
    80003fc4:	8082                	ret
    return -1;
    80003fc6:	557d                	li	a0,-1
    80003fc8:	bfe1                	j	80003fa0 <writei+0xf0>
    return -1;
    80003fca:	557d                	li	a0,-1
    80003fcc:	bfd1                	j	80003fa0 <writei+0xf0>

0000000080003fce <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003fce:	1141                	addi	sp,sp,-16
    80003fd0:	e406                	sd	ra,8(sp)
    80003fd2:	e022                	sd	s0,0(sp)
    80003fd4:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003fd6:	4639                	li	a2,14
    80003fd8:	ffffd097          	auipc	ra,0xffffd
    80003fdc:	e92080e7          	jalr	-366(ra) # 80000e6a <strncmp>
}
    80003fe0:	60a2                	ld	ra,8(sp)
    80003fe2:	6402                	ld	s0,0(sp)
    80003fe4:	0141                	addi	sp,sp,16
    80003fe6:	8082                	ret

0000000080003fe8 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003fe8:	7139                	addi	sp,sp,-64
    80003fea:	fc06                	sd	ra,56(sp)
    80003fec:	f822                	sd	s0,48(sp)
    80003fee:	f426                	sd	s1,40(sp)
    80003ff0:	f04a                	sd	s2,32(sp)
    80003ff2:	ec4e                	sd	s3,24(sp)
    80003ff4:	e852                	sd	s4,16(sp)
    80003ff6:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003ff8:	04451703          	lh	a4,68(a0)
    80003ffc:	4785                	li	a5,1
    80003ffe:	00f71a63          	bne	a4,a5,80004012 <dirlookup+0x2a>
    80004002:	892a                	mv	s2,a0
    80004004:	89ae                	mv	s3,a1
    80004006:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004008:	457c                	lw	a5,76(a0)
    8000400a:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000400c:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000400e:	e79d                	bnez	a5,8000403c <dirlookup+0x54>
    80004010:	a8a5                	j	80004088 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004012:	00004517          	auipc	a0,0x4
    80004016:	71650513          	addi	a0,a0,1814 # 80008728 <syscalls+0x1c8>
    8000401a:	ffffc097          	auipc	ra,0xffffc
    8000401e:	526080e7          	jalr	1318(ra) # 80000540 <panic>
      panic("dirlookup read");
    80004022:	00004517          	auipc	a0,0x4
    80004026:	71e50513          	addi	a0,a0,1822 # 80008740 <syscalls+0x1e0>
    8000402a:	ffffc097          	auipc	ra,0xffffc
    8000402e:	516080e7          	jalr	1302(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004032:	24c1                	addiw	s1,s1,16
    80004034:	04c92783          	lw	a5,76(s2)
    80004038:	04f4f763          	bgeu	s1,a5,80004086 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000403c:	4741                	li	a4,16
    8000403e:	86a6                	mv	a3,s1
    80004040:	fc040613          	addi	a2,s0,-64
    80004044:	4581                	li	a1,0
    80004046:	854a                	mv	a0,s2
    80004048:	00000097          	auipc	ra,0x0
    8000404c:	d70080e7          	jalr	-656(ra) # 80003db8 <readi>
    80004050:	47c1                	li	a5,16
    80004052:	fcf518e3          	bne	a0,a5,80004022 <dirlookup+0x3a>
    if(de.inum == 0)
    80004056:	fc045783          	lhu	a5,-64(s0)
    8000405a:	dfe1                	beqz	a5,80004032 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000405c:	fc240593          	addi	a1,s0,-62
    80004060:	854e                	mv	a0,s3
    80004062:	00000097          	auipc	ra,0x0
    80004066:	f6c080e7          	jalr	-148(ra) # 80003fce <namecmp>
    8000406a:	f561                	bnez	a0,80004032 <dirlookup+0x4a>
      if(poff)
    8000406c:	000a0463          	beqz	s4,80004074 <dirlookup+0x8c>
        *poff = off;
    80004070:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004074:	fc045583          	lhu	a1,-64(s0)
    80004078:	00092503          	lw	a0,0(s2)
    8000407c:	fffff097          	auipc	ra,0xfffff
    80004080:	74e080e7          	jalr	1870(ra) # 800037ca <iget>
    80004084:	a011                	j	80004088 <dirlookup+0xa0>
  return 0;
    80004086:	4501                	li	a0,0
}
    80004088:	70e2                	ld	ra,56(sp)
    8000408a:	7442                	ld	s0,48(sp)
    8000408c:	74a2                	ld	s1,40(sp)
    8000408e:	7902                	ld	s2,32(sp)
    80004090:	69e2                	ld	s3,24(sp)
    80004092:	6a42                	ld	s4,16(sp)
    80004094:	6121                	addi	sp,sp,64
    80004096:	8082                	ret

0000000080004098 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004098:	711d                	addi	sp,sp,-96
    8000409a:	ec86                	sd	ra,88(sp)
    8000409c:	e8a2                	sd	s0,80(sp)
    8000409e:	e4a6                	sd	s1,72(sp)
    800040a0:	e0ca                	sd	s2,64(sp)
    800040a2:	fc4e                	sd	s3,56(sp)
    800040a4:	f852                	sd	s4,48(sp)
    800040a6:	f456                	sd	s5,40(sp)
    800040a8:	f05a                	sd	s6,32(sp)
    800040aa:	ec5e                	sd	s7,24(sp)
    800040ac:	e862                	sd	s8,16(sp)
    800040ae:	e466                	sd	s9,8(sp)
    800040b0:	e06a                	sd	s10,0(sp)
    800040b2:	1080                	addi	s0,sp,96
    800040b4:	84aa                	mv	s1,a0
    800040b6:	8b2e                	mv	s6,a1
    800040b8:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800040ba:	00054703          	lbu	a4,0(a0)
    800040be:	02f00793          	li	a5,47
    800040c2:	02f70363          	beq	a4,a5,800040e8 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800040c6:	ffffe097          	auipc	ra,0xffffe
    800040ca:	aac080e7          	jalr	-1364(ra) # 80001b72 <myproc>
    800040ce:	15053503          	ld	a0,336(a0)
    800040d2:	00000097          	auipc	ra,0x0
    800040d6:	9f4080e7          	jalr	-1548(ra) # 80003ac6 <idup>
    800040da:	8a2a                	mv	s4,a0
  while(*path == '/')
    800040dc:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    800040e0:	4cb5                	li	s9,13
  len = path - s;
    800040e2:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800040e4:	4c05                	li	s8,1
    800040e6:	a87d                	j	800041a4 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    800040e8:	4585                	li	a1,1
    800040ea:	4505                	li	a0,1
    800040ec:	fffff097          	auipc	ra,0xfffff
    800040f0:	6de080e7          	jalr	1758(ra) # 800037ca <iget>
    800040f4:	8a2a                	mv	s4,a0
    800040f6:	b7dd                	j	800040dc <namex+0x44>
      iunlockput(ip);
    800040f8:	8552                	mv	a0,s4
    800040fa:	00000097          	auipc	ra,0x0
    800040fe:	c6c080e7          	jalr	-916(ra) # 80003d66 <iunlockput>
      return 0;
    80004102:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004104:	8552                	mv	a0,s4
    80004106:	60e6                	ld	ra,88(sp)
    80004108:	6446                	ld	s0,80(sp)
    8000410a:	64a6                	ld	s1,72(sp)
    8000410c:	6906                	ld	s2,64(sp)
    8000410e:	79e2                	ld	s3,56(sp)
    80004110:	7a42                	ld	s4,48(sp)
    80004112:	7aa2                	ld	s5,40(sp)
    80004114:	7b02                	ld	s6,32(sp)
    80004116:	6be2                	ld	s7,24(sp)
    80004118:	6c42                	ld	s8,16(sp)
    8000411a:	6ca2                	ld	s9,8(sp)
    8000411c:	6d02                	ld	s10,0(sp)
    8000411e:	6125                	addi	sp,sp,96
    80004120:	8082                	ret
      iunlock(ip);
    80004122:	8552                	mv	a0,s4
    80004124:	00000097          	auipc	ra,0x0
    80004128:	aa2080e7          	jalr	-1374(ra) # 80003bc6 <iunlock>
      return ip;
    8000412c:	bfe1                	j	80004104 <namex+0x6c>
      iunlockput(ip);
    8000412e:	8552                	mv	a0,s4
    80004130:	00000097          	auipc	ra,0x0
    80004134:	c36080e7          	jalr	-970(ra) # 80003d66 <iunlockput>
      return 0;
    80004138:	8a4e                	mv	s4,s3
    8000413a:	b7e9                	j	80004104 <namex+0x6c>
  len = path - s;
    8000413c:	40998633          	sub	a2,s3,s1
    80004140:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80004144:	09acd863          	bge	s9,s10,800041d4 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80004148:	4639                	li	a2,14
    8000414a:	85a6                	mv	a1,s1
    8000414c:	8556                	mv	a0,s5
    8000414e:	ffffd097          	auipc	ra,0xffffd
    80004152:	ca8080e7          	jalr	-856(ra) # 80000df6 <memmove>
    80004156:	84ce                	mv	s1,s3
  while(*path == '/')
    80004158:	0004c783          	lbu	a5,0(s1)
    8000415c:	01279763          	bne	a5,s2,8000416a <namex+0xd2>
    path++;
    80004160:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004162:	0004c783          	lbu	a5,0(s1)
    80004166:	ff278de3          	beq	a5,s2,80004160 <namex+0xc8>
    ilock(ip);
    8000416a:	8552                	mv	a0,s4
    8000416c:	00000097          	auipc	ra,0x0
    80004170:	998080e7          	jalr	-1640(ra) # 80003b04 <ilock>
    if(ip->type != T_DIR){
    80004174:	044a1783          	lh	a5,68(s4)
    80004178:	f98790e3          	bne	a5,s8,800040f8 <namex+0x60>
    if(nameiparent && *path == '\0'){
    8000417c:	000b0563          	beqz	s6,80004186 <namex+0xee>
    80004180:	0004c783          	lbu	a5,0(s1)
    80004184:	dfd9                	beqz	a5,80004122 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004186:	865e                	mv	a2,s7
    80004188:	85d6                	mv	a1,s5
    8000418a:	8552                	mv	a0,s4
    8000418c:	00000097          	auipc	ra,0x0
    80004190:	e5c080e7          	jalr	-420(ra) # 80003fe8 <dirlookup>
    80004194:	89aa                	mv	s3,a0
    80004196:	dd41                	beqz	a0,8000412e <namex+0x96>
    iunlockput(ip);
    80004198:	8552                	mv	a0,s4
    8000419a:	00000097          	auipc	ra,0x0
    8000419e:	bcc080e7          	jalr	-1076(ra) # 80003d66 <iunlockput>
    ip = next;
    800041a2:	8a4e                	mv	s4,s3
  while(*path == '/')
    800041a4:	0004c783          	lbu	a5,0(s1)
    800041a8:	01279763          	bne	a5,s2,800041b6 <namex+0x11e>
    path++;
    800041ac:	0485                	addi	s1,s1,1
  while(*path == '/')
    800041ae:	0004c783          	lbu	a5,0(s1)
    800041b2:	ff278de3          	beq	a5,s2,800041ac <namex+0x114>
  if(*path == 0)
    800041b6:	cb9d                	beqz	a5,800041ec <namex+0x154>
  while(*path != '/' && *path != 0)
    800041b8:	0004c783          	lbu	a5,0(s1)
    800041bc:	89a6                	mv	s3,s1
  len = path - s;
    800041be:	8d5e                	mv	s10,s7
    800041c0:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800041c2:	01278963          	beq	a5,s2,800041d4 <namex+0x13c>
    800041c6:	dbbd                	beqz	a5,8000413c <namex+0xa4>
    path++;
    800041c8:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    800041ca:	0009c783          	lbu	a5,0(s3)
    800041ce:	ff279ce3          	bne	a5,s2,800041c6 <namex+0x12e>
    800041d2:	b7ad                	j	8000413c <namex+0xa4>
    memmove(name, s, len);
    800041d4:	2601                	sext.w	a2,a2
    800041d6:	85a6                	mv	a1,s1
    800041d8:	8556                	mv	a0,s5
    800041da:	ffffd097          	auipc	ra,0xffffd
    800041de:	c1c080e7          	jalr	-996(ra) # 80000df6 <memmove>
    name[len] = 0;
    800041e2:	9d56                	add	s10,s10,s5
    800041e4:	000d0023          	sb	zero,0(s10)
    800041e8:	84ce                	mv	s1,s3
    800041ea:	b7bd                	j	80004158 <namex+0xc0>
  if(nameiparent){
    800041ec:	f00b0ce3          	beqz	s6,80004104 <namex+0x6c>
    iput(ip);
    800041f0:	8552                	mv	a0,s4
    800041f2:	00000097          	auipc	ra,0x0
    800041f6:	acc080e7          	jalr	-1332(ra) # 80003cbe <iput>
    return 0;
    800041fa:	4a01                	li	s4,0
    800041fc:	b721                	j	80004104 <namex+0x6c>

00000000800041fe <dirlink>:
{
    800041fe:	7139                	addi	sp,sp,-64
    80004200:	fc06                	sd	ra,56(sp)
    80004202:	f822                	sd	s0,48(sp)
    80004204:	f426                	sd	s1,40(sp)
    80004206:	f04a                	sd	s2,32(sp)
    80004208:	ec4e                	sd	s3,24(sp)
    8000420a:	e852                	sd	s4,16(sp)
    8000420c:	0080                	addi	s0,sp,64
    8000420e:	892a                	mv	s2,a0
    80004210:	8a2e                	mv	s4,a1
    80004212:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004214:	4601                	li	a2,0
    80004216:	00000097          	auipc	ra,0x0
    8000421a:	dd2080e7          	jalr	-558(ra) # 80003fe8 <dirlookup>
    8000421e:	e93d                	bnez	a0,80004294 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004220:	04c92483          	lw	s1,76(s2)
    80004224:	c49d                	beqz	s1,80004252 <dirlink+0x54>
    80004226:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004228:	4741                	li	a4,16
    8000422a:	86a6                	mv	a3,s1
    8000422c:	fc040613          	addi	a2,s0,-64
    80004230:	4581                	li	a1,0
    80004232:	854a                	mv	a0,s2
    80004234:	00000097          	auipc	ra,0x0
    80004238:	b84080e7          	jalr	-1148(ra) # 80003db8 <readi>
    8000423c:	47c1                	li	a5,16
    8000423e:	06f51163          	bne	a0,a5,800042a0 <dirlink+0xa2>
    if(de.inum == 0)
    80004242:	fc045783          	lhu	a5,-64(s0)
    80004246:	c791                	beqz	a5,80004252 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004248:	24c1                	addiw	s1,s1,16
    8000424a:	04c92783          	lw	a5,76(s2)
    8000424e:	fcf4ede3          	bltu	s1,a5,80004228 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004252:	4639                	li	a2,14
    80004254:	85d2                	mv	a1,s4
    80004256:	fc240513          	addi	a0,s0,-62
    8000425a:	ffffd097          	auipc	ra,0xffffd
    8000425e:	c4c080e7          	jalr	-948(ra) # 80000ea6 <strncpy>
  de.inum = inum;
    80004262:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004266:	4741                	li	a4,16
    80004268:	86a6                	mv	a3,s1
    8000426a:	fc040613          	addi	a2,s0,-64
    8000426e:	4581                	li	a1,0
    80004270:	854a                	mv	a0,s2
    80004272:	00000097          	auipc	ra,0x0
    80004276:	c3e080e7          	jalr	-962(ra) # 80003eb0 <writei>
    8000427a:	1541                	addi	a0,a0,-16
    8000427c:	00a03533          	snez	a0,a0
    80004280:	40a00533          	neg	a0,a0
}
    80004284:	70e2                	ld	ra,56(sp)
    80004286:	7442                	ld	s0,48(sp)
    80004288:	74a2                	ld	s1,40(sp)
    8000428a:	7902                	ld	s2,32(sp)
    8000428c:	69e2                	ld	s3,24(sp)
    8000428e:	6a42                	ld	s4,16(sp)
    80004290:	6121                	addi	sp,sp,64
    80004292:	8082                	ret
    iput(ip);
    80004294:	00000097          	auipc	ra,0x0
    80004298:	a2a080e7          	jalr	-1494(ra) # 80003cbe <iput>
    return -1;
    8000429c:	557d                	li	a0,-1
    8000429e:	b7dd                	j	80004284 <dirlink+0x86>
      panic("dirlink read");
    800042a0:	00004517          	auipc	a0,0x4
    800042a4:	4b050513          	addi	a0,a0,1200 # 80008750 <syscalls+0x1f0>
    800042a8:	ffffc097          	auipc	ra,0xffffc
    800042ac:	298080e7          	jalr	664(ra) # 80000540 <panic>

00000000800042b0 <namei>:

struct inode*
namei(char *path)
{
    800042b0:	1101                	addi	sp,sp,-32
    800042b2:	ec06                	sd	ra,24(sp)
    800042b4:	e822                	sd	s0,16(sp)
    800042b6:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800042b8:	fe040613          	addi	a2,s0,-32
    800042bc:	4581                	li	a1,0
    800042be:	00000097          	auipc	ra,0x0
    800042c2:	dda080e7          	jalr	-550(ra) # 80004098 <namex>
}
    800042c6:	60e2                	ld	ra,24(sp)
    800042c8:	6442                	ld	s0,16(sp)
    800042ca:	6105                	addi	sp,sp,32
    800042cc:	8082                	ret

00000000800042ce <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800042ce:	1141                	addi	sp,sp,-16
    800042d0:	e406                	sd	ra,8(sp)
    800042d2:	e022                	sd	s0,0(sp)
    800042d4:	0800                	addi	s0,sp,16
    800042d6:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800042d8:	4585                	li	a1,1
    800042da:	00000097          	auipc	ra,0x0
    800042de:	dbe080e7          	jalr	-578(ra) # 80004098 <namex>
}
    800042e2:	60a2                	ld	ra,8(sp)
    800042e4:	6402                	ld	s0,0(sp)
    800042e6:	0141                	addi	sp,sp,16
    800042e8:	8082                	ret

00000000800042ea <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800042ea:	1101                	addi	sp,sp,-32
    800042ec:	ec06                	sd	ra,24(sp)
    800042ee:	e822                	sd	s0,16(sp)
    800042f0:	e426                	sd	s1,8(sp)
    800042f2:	e04a                	sd	s2,0(sp)
    800042f4:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800042f6:	0001d917          	auipc	s2,0x1d
    800042fa:	9aa90913          	addi	s2,s2,-1622 # 80020ca0 <log>
    800042fe:	01892583          	lw	a1,24(s2)
    80004302:	02892503          	lw	a0,40(s2)
    80004306:	fffff097          	auipc	ra,0xfffff
    8000430a:	fe6080e7          	jalr	-26(ra) # 800032ec <bread>
    8000430e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004310:	02c92683          	lw	a3,44(s2)
    80004314:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004316:	02d05863          	blez	a3,80004346 <write_head+0x5c>
    8000431a:	0001d797          	auipc	a5,0x1d
    8000431e:	9b678793          	addi	a5,a5,-1610 # 80020cd0 <log+0x30>
    80004322:	05c50713          	addi	a4,a0,92
    80004326:	36fd                	addiw	a3,a3,-1
    80004328:	02069613          	slli	a2,a3,0x20
    8000432c:	01e65693          	srli	a3,a2,0x1e
    80004330:	0001d617          	auipc	a2,0x1d
    80004334:	9a460613          	addi	a2,a2,-1628 # 80020cd4 <log+0x34>
    80004338:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000433a:	4390                	lw	a2,0(a5)
    8000433c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000433e:	0791                	addi	a5,a5,4
    80004340:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80004342:	fed79ce3          	bne	a5,a3,8000433a <write_head+0x50>
  }
  bwrite(buf);
    80004346:	8526                	mv	a0,s1
    80004348:	fffff097          	auipc	ra,0xfffff
    8000434c:	096080e7          	jalr	150(ra) # 800033de <bwrite>
  brelse(buf);
    80004350:	8526                	mv	a0,s1
    80004352:	fffff097          	auipc	ra,0xfffff
    80004356:	0ca080e7          	jalr	202(ra) # 8000341c <brelse>
}
    8000435a:	60e2                	ld	ra,24(sp)
    8000435c:	6442                	ld	s0,16(sp)
    8000435e:	64a2                	ld	s1,8(sp)
    80004360:	6902                	ld	s2,0(sp)
    80004362:	6105                	addi	sp,sp,32
    80004364:	8082                	ret

0000000080004366 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004366:	0001d797          	auipc	a5,0x1d
    8000436a:	9667a783          	lw	a5,-1690(a5) # 80020ccc <log+0x2c>
    8000436e:	0af05d63          	blez	a5,80004428 <install_trans+0xc2>
{
    80004372:	7139                	addi	sp,sp,-64
    80004374:	fc06                	sd	ra,56(sp)
    80004376:	f822                	sd	s0,48(sp)
    80004378:	f426                	sd	s1,40(sp)
    8000437a:	f04a                	sd	s2,32(sp)
    8000437c:	ec4e                	sd	s3,24(sp)
    8000437e:	e852                	sd	s4,16(sp)
    80004380:	e456                	sd	s5,8(sp)
    80004382:	e05a                	sd	s6,0(sp)
    80004384:	0080                	addi	s0,sp,64
    80004386:	8b2a                	mv	s6,a0
    80004388:	0001da97          	auipc	s5,0x1d
    8000438c:	948a8a93          	addi	s5,s5,-1720 # 80020cd0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004390:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004392:	0001d997          	auipc	s3,0x1d
    80004396:	90e98993          	addi	s3,s3,-1778 # 80020ca0 <log>
    8000439a:	a00d                	j	800043bc <install_trans+0x56>
    brelse(lbuf);
    8000439c:	854a                	mv	a0,s2
    8000439e:	fffff097          	auipc	ra,0xfffff
    800043a2:	07e080e7          	jalr	126(ra) # 8000341c <brelse>
    brelse(dbuf);
    800043a6:	8526                	mv	a0,s1
    800043a8:	fffff097          	auipc	ra,0xfffff
    800043ac:	074080e7          	jalr	116(ra) # 8000341c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043b0:	2a05                	addiw	s4,s4,1
    800043b2:	0a91                	addi	s5,s5,4
    800043b4:	02c9a783          	lw	a5,44(s3)
    800043b8:	04fa5e63          	bge	s4,a5,80004414 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800043bc:	0189a583          	lw	a1,24(s3)
    800043c0:	014585bb          	addw	a1,a1,s4
    800043c4:	2585                	addiw	a1,a1,1
    800043c6:	0289a503          	lw	a0,40(s3)
    800043ca:	fffff097          	auipc	ra,0xfffff
    800043ce:	f22080e7          	jalr	-222(ra) # 800032ec <bread>
    800043d2:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800043d4:	000aa583          	lw	a1,0(s5)
    800043d8:	0289a503          	lw	a0,40(s3)
    800043dc:	fffff097          	auipc	ra,0xfffff
    800043e0:	f10080e7          	jalr	-240(ra) # 800032ec <bread>
    800043e4:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800043e6:	40000613          	li	a2,1024
    800043ea:	05890593          	addi	a1,s2,88
    800043ee:	05850513          	addi	a0,a0,88
    800043f2:	ffffd097          	auipc	ra,0xffffd
    800043f6:	a04080e7          	jalr	-1532(ra) # 80000df6 <memmove>
    bwrite(dbuf);  // write dst to disk
    800043fa:	8526                	mv	a0,s1
    800043fc:	fffff097          	auipc	ra,0xfffff
    80004400:	fe2080e7          	jalr	-30(ra) # 800033de <bwrite>
    if(recovering == 0)
    80004404:	f80b1ce3          	bnez	s6,8000439c <install_trans+0x36>
      bunpin(dbuf);
    80004408:	8526                	mv	a0,s1
    8000440a:	fffff097          	auipc	ra,0xfffff
    8000440e:	0ec080e7          	jalr	236(ra) # 800034f6 <bunpin>
    80004412:	b769                	j	8000439c <install_trans+0x36>
}
    80004414:	70e2                	ld	ra,56(sp)
    80004416:	7442                	ld	s0,48(sp)
    80004418:	74a2                	ld	s1,40(sp)
    8000441a:	7902                	ld	s2,32(sp)
    8000441c:	69e2                	ld	s3,24(sp)
    8000441e:	6a42                	ld	s4,16(sp)
    80004420:	6aa2                	ld	s5,8(sp)
    80004422:	6b02                	ld	s6,0(sp)
    80004424:	6121                	addi	sp,sp,64
    80004426:	8082                	ret
    80004428:	8082                	ret

000000008000442a <initlog>:
{
    8000442a:	7179                	addi	sp,sp,-48
    8000442c:	f406                	sd	ra,40(sp)
    8000442e:	f022                	sd	s0,32(sp)
    80004430:	ec26                	sd	s1,24(sp)
    80004432:	e84a                	sd	s2,16(sp)
    80004434:	e44e                	sd	s3,8(sp)
    80004436:	1800                	addi	s0,sp,48
    80004438:	892a                	mv	s2,a0
    8000443a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000443c:	0001d497          	auipc	s1,0x1d
    80004440:	86448493          	addi	s1,s1,-1948 # 80020ca0 <log>
    80004444:	00004597          	auipc	a1,0x4
    80004448:	31c58593          	addi	a1,a1,796 # 80008760 <syscalls+0x200>
    8000444c:	8526                	mv	a0,s1
    8000444e:	ffffc097          	auipc	ra,0xffffc
    80004452:	7c0080e7          	jalr	1984(ra) # 80000c0e <initlock>
  log.start = sb->logstart;
    80004456:	0149a583          	lw	a1,20(s3)
    8000445a:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000445c:	0109a783          	lw	a5,16(s3)
    80004460:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004462:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004466:	854a                	mv	a0,s2
    80004468:	fffff097          	auipc	ra,0xfffff
    8000446c:	e84080e7          	jalr	-380(ra) # 800032ec <bread>
  log.lh.n = lh->n;
    80004470:	4d34                	lw	a3,88(a0)
    80004472:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004474:	02d05663          	blez	a3,800044a0 <initlog+0x76>
    80004478:	05c50793          	addi	a5,a0,92
    8000447c:	0001d717          	auipc	a4,0x1d
    80004480:	85470713          	addi	a4,a4,-1964 # 80020cd0 <log+0x30>
    80004484:	36fd                	addiw	a3,a3,-1
    80004486:	02069613          	slli	a2,a3,0x20
    8000448a:	01e65693          	srli	a3,a2,0x1e
    8000448e:	06050613          	addi	a2,a0,96
    80004492:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004494:	4390                	lw	a2,0(a5)
    80004496:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004498:	0791                	addi	a5,a5,4
    8000449a:	0711                	addi	a4,a4,4
    8000449c:	fed79ce3          	bne	a5,a3,80004494 <initlog+0x6a>
  brelse(buf);
    800044a0:	fffff097          	auipc	ra,0xfffff
    800044a4:	f7c080e7          	jalr	-132(ra) # 8000341c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800044a8:	4505                	li	a0,1
    800044aa:	00000097          	auipc	ra,0x0
    800044ae:	ebc080e7          	jalr	-324(ra) # 80004366 <install_trans>
  log.lh.n = 0;
    800044b2:	0001d797          	auipc	a5,0x1d
    800044b6:	8007ad23          	sw	zero,-2022(a5) # 80020ccc <log+0x2c>
  write_head(); // clear the log
    800044ba:	00000097          	auipc	ra,0x0
    800044be:	e30080e7          	jalr	-464(ra) # 800042ea <write_head>
}
    800044c2:	70a2                	ld	ra,40(sp)
    800044c4:	7402                	ld	s0,32(sp)
    800044c6:	64e2                	ld	s1,24(sp)
    800044c8:	6942                	ld	s2,16(sp)
    800044ca:	69a2                	ld	s3,8(sp)
    800044cc:	6145                	addi	sp,sp,48
    800044ce:	8082                	ret

00000000800044d0 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800044d0:	1101                	addi	sp,sp,-32
    800044d2:	ec06                	sd	ra,24(sp)
    800044d4:	e822                	sd	s0,16(sp)
    800044d6:	e426                	sd	s1,8(sp)
    800044d8:	e04a                	sd	s2,0(sp)
    800044da:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800044dc:	0001c517          	auipc	a0,0x1c
    800044e0:	7c450513          	addi	a0,a0,1988 # 80020ca0 <log>
    800044e4:	ffffc097          	auipc	ra,0xffffc
    800044e8:	7ba080e7          	jalr	1978(ra) # 80000c9e <acquire>
  while(1){
    if(log.committing){
    800044ec:	0001c497          	auipc	s1,0x1c
    800044f0:	7b448493          	addi	s1,s1,1972 # 80020ca0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800044f4:	4979                	li	s2,30
    800044f6:	a039                	j	80004504 <begin_op+0x34>
      sleep(&log, &log.lock);
    800044f8:	85a6                	mv	a1,s1
    800044fa:	8526                	mv	a0,s1
    800044fc:	ffffe097          	auipc	ra,0xffffe
    80004500:	e24080e7          	jalr	-476(ra) # 80002320 <sleep>
    if(log.committing){
    80004504:	50dc                	lw	a5,36(s1)
    80004506:	fbed                	bnez	a5,800044f8 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004508:	5098                	lw	a4,32(s1)
    8000450a:	2705                	addiw	a4,a4,1
    8000450c:	0007069b          	sext.w	a3,a4
    80004510:	0027179b          	slliw	a5,a4,0x2
    80004514:	9fb9                	addw	a5,a5,a4
    80004516:	0017979b          	slliw	a5,a5,0x1
    8000451a:	54d8                	lw	a4,44(s1)
    8000451c:	9fb9                	addw	a5,a5,a4
    8000451e:	00f95963          	bge	s2,a5,80004530 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004522:	85a6                	mv	a1,s1
    80004524:	8526                	mv	a0,s1
    80004526:	ffffe097          	auipc	ra,0xffffe
    8000452a:	dfa080e7          	jalr	-518(ra) # 80002320 <sleep>
    8000452e:	bfd9                	j	80004504 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004530:	0001c517          	auipc	a0,0x1c
    80004534:	77050513          	addi	a0,a0,1904 # 80020ca0 <log>
    80004538:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000453a:	ffffd097          	auipc	ra,0xffffd
    8000453e:	818080e7          	jalr	-2024(ra) # 80000d52 <release>
      break;
    }
  }
}
    80004542:	60e2                	ld	ra,24(sp)
    80004544:	6442                	ld	s0,16(sp)
    80004546:	64a2                	ld	s1,8(sp)
    80004548:	6902                	ld	s2,0(sp)
    8000454a:	6105                	addi	sp,sp,32
    8000454c:	8082                	ret

000000008000454e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000454e:	7139                	addi	sp,sp,-64
    80004550:	fc06                	sd	ra,56(sp)
    80004552:	f822                	sd	s0,48(sp)
    80004554:	f426                	sd	s1,40(sp)
    80004556:	f04a                	sd	s2,32(sp)
    80004558:	ec4e                	sd	s3,24(sp)
    8000455a:	e852                	sd	s4,16(sp)
    8000455c:	e456                	sd	s5,8(sp)
    8000455e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004560:	0001c497          	auipc	s1,0x1c
    80004564:	74048493          	addi	s1,s1,1856 # 80020ca0 <log>
    80004568:	8526                	mv	a0,s1
    8000456a:	ffffc097          	auipc	ra,0xffffc
    8000456e:	734080e7          	jalr	1844(ra) # 80000c9e <acquire>
  log.outstanding -= 1;
    80004572:	509c                	lw	a5,32(s1)
    80004574:	37fd                	addiw	a5,a5,-1
    80004576:	0007891b          	sext.w	s2,a5
    8000457a:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000457c:	50dc                	lw	a5,36(s1)
    8000457e:	e7b9                	bnez	a5,800045cc <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004580:	04091e63          	bnez	s2,800045dc <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004584:	0001c497          	auipc	s1,0x1c
    80004588:	71c48493          	addi	s1,s1,1820 # 80020ca0 <log>
    8000458c:	4785                	li	a5,1
    8000458e:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004590:	8526                	mv	a0,s1
    80004592:	ffffc097          	auipc	ra,0xffffc
    80004596:	7c0080e7          	jalr	1984(ra) # 80000d52 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000459a:	54dc                	lw	a5,44(s1)
    8000459c:	06f04763          	bgtz	a5,8000460a <end_op+0xbc>
    acquire(&log.lock);
    800045a0:	0001c497          	auipc	s1,0x1c
    800045a4:	70048493          	addi	s1,s1,1792 # 80020ca0 <log>
    800045a8:	8526                	mv	a0,s1
    800045aa:	ffffc097          	auipc	ra,0xffffc
    800045ae:	6f4080e7          	jalr	1780(ra) # 80000c9e <acquire>
    log.committing = 0;
    800045b2:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800045b6:	8526                	mv	a0,s1
    800045b8:	ffffe097          	auipc	ra,0xffffe
    800045bc:	dcc080e7          	jalr	-564(ra) # 80002384 <wakeup>
    release(&log.lock);
    800045c0:	8526                	mv	a0,s1
    800045c2:	ffffc097          	auipc	ra,0xffffc
    800045c6:	790080e7          	jalr	1936(ra) # 80000d52 <release>
}
    800045ca:	a03d                	j	800045f8 <end_op+0xaa>
    panic("log.committing");
    800045cc:	00004517          	auipc	a0,0x4
    800045d0:	19c50513          	addi	a0,a0,412 # 80008768 <syscalls+0x208>
    800045d4:	ffffc097          	auipc	ra,0xffffc
    800045d8:	f6c080e7          	jalr	-148(ra) # 80000540 <panic>
    wakeup(&log);
    800045dc:	0001c497          	auipc	s1,0x1c
    800045e0:	6c448493          	addi	s1,s1,1732 # 80020ca0 <log>
    800045e4:	8526                	mv	a0,s1
    800045e6:	ffffe097          	auipc	ra,0xffffe
    800045ea:	d9e080e7          	jalr	-610(ra) # 80002384 <wakeup>
  release(&log.lock);
    800045ee:	8526                	mv	a0,s1
    800045f0:	ffffc097          	auipc	ra,0xffffc
    800045f4:	762080e7          	jalr	1890(ra) # 80000d52 <release>
}
    800045f8:	70e2                	ld	ra,56(sp)
    800045fa:	7442                	ld	s0,48(sp)
    800045fc:	74a2                	ld	s1,40(sp)
    800045fe:	7902                	ld	s2,32(sp)
    80004600:	69e2                	ld	s3,24(sp)
    80004602:	6a42                	ld	s4,16(sp)
    80004604:	6aa2                	ld	s5,8(sp)
    80004606:	6121                	addi	sp,sp,64
    80004608:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000460a:	0001ca97          	auipc	s5,0x1c
    8000460e:	6c6a8a93          	addi	s5,s5,1734 # 80020cd0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004612:	0001ca17          	auipc	s4,0x1c
    80004616:	68ea0a13          	addi	s4,s4,1678 # 80020ca0 <log>
    8000461a:	018a2583          	lw	a1,24(s4)
    8000461e:	012585bb          	addw	a1,a1,s2
    80004622:	2585                	addiw	a1,a1,1
    80004624:	028a2503          	lw	a0,40(s4)
    80004628:	fffff097          	auipc	ra,0xfffff
    8000462c:	cc4080e7          	jalr	-828(ra) # 800032ec <bread>
    80004630:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004632:	000aa583          	lw	a1,0(s5)
    80004636:	028a2503          	lw	a0,40(s4)
    8000463a:	fffff097          	auipc	ra,0xfffff
    8000463e:	cb2080e7          	jalr	-846(ra) # 800032ec <bread>
    80004642:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004644:	40000613          	li	a2,1024
    80004648:	05850593          	addi	a1,a0,88
    8000464c:	05848513          	addi	a0,s1,88
    80004650:	ffffc097          	auipc	ra,0xffffc
    80004654:	7a6080e7          	jalr	1958(ra) # 80000df6 <memmove>
    bwrite(to);  // write the log
    80004658:	8526                	mv	a0,s1
    8000465a:	fffff097          	auipc	ra,0xfffff
    8000465e:	d84080e7          	jalr	-636(ra) # 800033de <bwrite>
    brelse(from);
    80004662:	854e                	mv	a0,s3
    80004664:	fffff097          	auipc	ra,0xfffff
    80004668:	db8080e7          	jalr	-584(ra) # 8000341c <brelse>
    brelse(to);
    8000466c:	8526                	mv	a0,s1
    8000466e:	fffff097          	auipc	ra,0xfffff
    80004672:	dae080e7          	jalr	-594(ra) # 8000341c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004676:	2905                	addiw	s2,s2,1
    80004678:	0a91                	addi	s5,s5,4
    8000467a:	02ca2783          	lw	a5,44(s4)
    8000467e:	f8f94ee3          	blt	s2,a5,8000461a <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004682:	00000097          	auipc	ra,0x0
    80004686:	c68080e7          	jalr	-920(ra) # 800042ea <write_head>
    install_trans(0); // Now install writes to home locations
    8000468a:	4501                	li	a0,0
    8000468c:	00000097          	auipc	ra,0x0
    80004690:	cda080e7          	jalr	-806(ra) # 80004366 <install_trans>
    log.lh.n = 0;
    80004694:	0001c797          	auipc	a5,0x1c
    80004698:	6207ac23          	sw	zero,1592(a5) # 80020ccc <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000469c:	00000097          	auipc	ra,0x0
    800046a0:	c4e080e7          	jalr	-946(ra) # 800042ea <write_head>
    800046a4:	bdf5                	j	800045a0 <end_op+0x52>

00000000800046a6 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800046a6:	1101                	addi	sp,sp,-32
    800046a8:	ec06                	sd	ra,24(sp)
    800046aa:	e822                	sd	s0,16(sp)
    800046ac:	e426                	sd	s1,8(sp)
    800046ae:	e04a                	sd	s2,0(sp)
    800046b0:	1000                	addi	s0,sp,32
    800046b2:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800046b4:	0001c917          	auipc	s2,0x1c
    800046b8:	5ec90913          	addi	s2,s2,1516 # 80020ca0 <log>
    800046bc:	854a                	mv	a0,s2
    800046be:	ffffc097          	auipc	ra,0xffffc
    800046c2:	5e0080e7          	jalr	1504(ra) # 80000c9e <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800046c6:	02c92603          	lw	a2,44(s2)
    800046ca:	47f5                	li	a5,29
    800046cc:	06c7c563          	blt	a5,a2,80004736 <log_write+0x90>
    800046d0:	0001c797          	auipc	a5,0x1c
    800046d4:	5ec7a783          	lw	a5,1516(a5) # 80020cbc <log+0x1c>
    800046d8:	37fd                	addiw	a5,a5,-1
    800046da:	04f65e63          	bge	a2,a5,80004736 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800046de:	0001c797          	auipc	a5,0x1c
    800046e2:	5e27a783          	lw	a5,1506(a5) # 80020cc0 <log+0x20>
    800046e6:	06f05063          	blez	a5,80004746 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800046ea:	4781                	li	a5,0
    800046ec:	06c05563          	blez	a2,80004756 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800046f0:	44cc                	lw	a1,12(s1)
    800046f2:	0001c717          	auipc	a4,0x1c
    800046f6:	5de70713          	addi	a4,a4,1502 # 80020cd0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800046fa:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800046fc:	4314                	lw	a3,0(a4)
    800046fe:	04b68c63          	beq	a3,a1,80004756 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004702:	2785                	addiw	a5,a5,1
    80004704:	0711                	addi	a4,a4,4
    80004706:	fef61be3          	bne	a2,a5,800046fc <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000470a:	0621                	addi	a2,a2,8
    8000470c:	060a                	slli	a2,a2,0x2
    8000470e:	0001c797          	auipc	a5,0x1c
    80004712:	59278793          	addi	a5,a5,1426 # 80020ca0 <log>
    80004716:	97b2                	add	a5,a5,a2
    80004718:	44d8                	lw	a4,12(s1)
    8000471a:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000471c:	8526                	mv	a0,s1
    8000471e:	fffff097          	auipc	ra,0xfffff
    80004722:	d9c080e7          	jalr	-612(ra) # 800034ba <bpin>
    log.lh.n++;
    80004726:	0001c717          	auipc	a4,0x1c
    8000472a:	57a70713          	addi	a4,a4,1402 # 80020ca0 <log>
    8000472e:	575c                	lw	a5,44(a4)
    80004730:	2785                	addiw	a5,a5,1
    80004732:	d75c                	sw	a5,44(a4)
    80004734:	a82d                	j	8000476e <log_write+0xc8>
    panic("too big a transaction");
    80004736:	00004517          	auipc	a0,0x4
    8000473a:	04250513          	addi	a0,a0,66 # 80008778 <syscalls+0x218>
    8000473e:	ffffc097          	auipc	ra,0xffffc
    80004742:	e02080e7          	jalr	-510(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    80004746:	00004517          	auipc	a0,0x4
    8000474a:	04a50513          	addi	a0,a0,74 # 80008790 <syscalls+0x230>
    8000474e:	ffffc097          	auipc	ra,0xffffc
    80004752:	df2080e7          	jalr	-526(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    80004756:	00878693          	addi	a3,a5,8
    8000475a:	068a                	slli	a3,a3,0x2
    8000475c:	0001c717          	auipc	a4,0x1c
    80004760:	54470713          	addi	a4,a4,1348 # 80020ca0 <log>
    80004764:	9736                	add	a4,a4,a3
    80004766:	44d4                	lw	a3,12(s1)
    80004768:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000476a:	faf609e3          	beq	a2,a5,8000471c <log_write+0x76>
  }
  release(&log.lock);
    8000476e:	0001c517          	auipc	a0,0x1c
    80004772:	53250513          	addi	a0,a0,1330 # 80020ca0 <log>
    80004776:	ffffc097          	auipc	ra,0xffffc
    8000477a:	5dc080e7          	jalr	1500(ra) # 80000d52 <release>
}
    8000477e:	60e2                	ld	ra,24(sp)
    80004780:	6442                	ld	s0,16(sp)
    80004782:	64a2                	ld	s1,8(sp)
    80004784:	6902                	ld	s2,0(sp)
    80004786:	6105                	addi	sp,sp,32
    80004788:	8082                	ret

000000008000478a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000478a:	1101                	addi	sp,sp,-32
    8000478c:	ec06                	sd	ra,24(sp)
    8000478e:	e822                	sd	s0,16(sp)
    80004790:	e426                	sd	s1,8(sp)
    80004792:	e04a                	sd	s2,0(sp)
    80004794:	1000                	addi	s0,sp,32
    80004796:	84aa                	mv	s1,a0
    80004798:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000479a:	00004597          	auipc	a1,0x4
    8000479e:	01658593          	addi	a1,a1,22 # 800087b0 <syscalls+0x250>
    800047a2:	0521                	addi	a0,a0,8
    800047a4:	ffffc097          	auipc	ra,0xffffc
    800047a8:	46a080e7          	jalr	1130(ra) # 80000c0e <initlock>
  lk->name = name;
    800047ac:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800047b0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800047b4:	0204a423          	sw	zero,40(s1)
}
    800047b8:	60e2                	ld	ra,24(sp)
    800047ba:	6442                	ld	s0,16(sp)
    800047bc:	64a2                	ld	s1,8(sp)
    800047be:	6902                	ld	s2,0(sp)
    800047c0:	6105                	addi	sp,sp,32
    800047c2:	8082                	ret

00000000800047c4 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800047c4:	1101                	addi	sp,sp,-32
    800047c6:	ec06                	sd	ra,24(sp)
    800047c8:	e822                	sd	s0,16(sp)
    800047ca:	e426                	sd	s1,8(sp)
    800047cc:	e04a                	sd	s2,0(sp)
    800047ce:	1000                	addi	s0,sp,32
    800047d0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800047d2:	00850913          	addi	s2,a0,8
    800047d6:	854a                	mv	a0,s2
    800047d8:	ffffc097          	auipc	ra,0xffffc
    800047dc:	4c6080e7          	jalr	1222(ra) # 80000c9e <acquire>
  while (lk->locked) {
    800047e0:	409c                	lw	a5,0(s1)
    800047e2:	cb89                	beqz	a5,800047f4 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800047e4:	85ca                	mv	a1,s2
    800047e6:	8526                	mv	a0,s1
    800047e8:	ffffe097          	auipc	ra,0xffffe
    800047ec:	b38080e7          	jalr	-1224(ra) # 80002320 <sleep>
  while (lk->locked) {
    800047f0:	409c                	lw	a5,0(s1)
    800047f2:	fbed                	bnez	a5,800047e4 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800047f4:	4785                	li	a5,1
    800047f6:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800047f8:	ffffd097          	auipc	ra,0xffffd
    800047fc:	37a080e7          	jalr	890(ra) # 80001b72 <myproc>
    80004800:	591c                	lw	a5,48(a0)
    80004802:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004804:	854a                	mv	a0,s2
    80004806:	ffffc097          	auipc	ra,0xffffc
    8000480a:	54c080e7          	jalr	1356(ra) # 80000d52 <release>
}
    8000480e:	60e2                	ld	ra,24(sp)
    80004810:	6442                	ld	s0,16(sp)
    80004812:	64a2                	ld	s1,8(sp)
    80004814:	6902                	ld	s2,0(sp)
    80004816:	6105                	addi	sp,sp,32
    80004818:	8082                	ret

000000008000481a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000481a:	1101                	addi	sp,sp,-32
    8000481c:	ec06                	sd	ra,24(sp)
    8000481e:	e822                	sd	s0,16(sp)
    80004820:	e426                	sd	s1,8(sp)
    80004822:	e04a                	sd	s2,0(sp)
    80004824:	1000                	addi	s0,sp,32
    80004826:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004828:	00850913          	addi	s2,a0,8
    8000482c:	854a                	mv	a0,s2
    8000482e:	ffffc097          	auipc	ra,0xffffc
    80004832:	470080e7          	jalr	1136(ra) # 80000c9e <acquire>
  lk->locked = 0;
    80004836:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000483a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000483e:	8526                	mv	a0,s1
    80004840:	ffffe097          	auipc	ra,0xffffe
    80004844:	b44080e7          	jalr	-1212(ra) # 80002384 <wakeup>
  release(&lk->lk);
    80004848:	854a                	mv	a0,s2
    8000484a:	ffffc097          	auipc	ra,0xffffc
    8000484e:	508080e7          	jalr	1288(ra) # 80000d52 <release>
}
    80004852:	60e2                	ld	ra,24(sp)
    80004854:	6442                	ld	s0,16(sp)
    80004856:	64a2                	ld	s1,8(sp)
    80004858:	6902                	ld	s2,0(sp)
    8000485a:	6105                	addi	sp,sp,32
    8000485c:	8082                	ret

000000008000485e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000485e:	7179                	addi	sp,sp,-48
    80004860:	f406                	sd	ra,40(sp)
    80004862:	f022                	sd	s0,32(sp)
    80004864:	ec26                	sd	s1,24(sp)
    80004866:	e84a                	sd	s2,16(sp)
    80004868:	e44e                	sd	s3,8(sp)
    8000486a:	1800                	addi	s0,sp,48
    8000486c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000486e:	00850913          	addi	s2,a0,8
    80004872:	854a                	mv	a0,s2
    80004874:	ffffc097          	auipc	ra,0xffffc
    80004878:	42a080e7          	jalr	1066(ra) # 80000c9e <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000487c:	409c                	lw	a5,0(s1)
    8000487e:	ef99                	bnez	a5,8000489c <holdingsleep+0x3e>
    80004880:	4481                	li	s1,0
  release(&lk->lk);
    80004882:	854a                	mv	a0,s2
    80004884:	ffffc097          	auipc	ra,0xffffc
    80004888:	4ce080e7          	jalr	1230(ra) # 80000d52 <release>
  return r;
}
    8000488c:	8526                	mv	a0,s1
    8000488e:	70a2                	ld	ra,40(sp)
    80004890:	7402                	ld	s0,32(sp)
    80004892:	64e2                	ld	s1,24(sp)
    80004894:	6942                	ld	s2,16(sp)
    80004896:	69a2                	ld	s3,8(sp)
    80004898:	6145                	addi	sp,sp,48
    8000489a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000489c:	0284a983          	lw	s3,40(s1)
    800048a0:	ffffd097          	auipc	ra,0xffffd
    800048a4:	2d2080e7          	jalr	722(ra) # 80001b72 <myproc>
    800048a8:	5904                	lw	s1,48(a0)
    800048aa:	413484b3          	sub	s1,s1,s3
    800048ae:	0014b493          	seqz	s1,s1
    800048b2:	bfc1                	j	80004882 <holdingsleep+0x24>

00000000800048b4 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800048b4:	1141                	addi	sp,sp,-16
    800048b6:	e406                	sd	ra,8(sp)
    800048b8:	e022                	sd	s0,0(sp)
    800048ba:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800048bc:	00004597          	auipc	a1,0x4
    800048c0:	f0458593          	addi	a1,a1,-252 # 800087c0 <syscalls+0x260>
    800048c4:	0001c517          	auipc	a0,0x1c
    800048c8:	52450513          	addi	a0,a0,1316 # 80020de8 <ftable>
    800048cc:	ffffc097          	auipc	ra,0xffffc
    800048d0:	342080e7          	jalr	834(ra) # 80000c0e <initlock>
}
    800048d4:	60a2                	ld	ra,8(sp)
    800048d6:	6402                	ld	s0,0(sp)
    800048d8:	0141                	addi	sp,sp,16
    800048da:	8082                	ret

00000000800048dc <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800048dc:	1101                	addi	sp,sp,-32
    800048de:	ec06                	sd	ra,24(sp)
    800048e0:	e822                	sd	s0,16(sp)
    800048e2:	e426                	sd	s1,8(sp)
    800048e4:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800048e6:	0001c517          	auipc	a0,0x1c
    800048ea:	50250513          	addi	a0,a0,1282 # 80020de8 <ftable>
    800048ee:	ffffc097          	auipc	ra,0xffffc
    800048f2:	3b0080e7          	jalr	944(ra) # 80000c9e <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800048f6:	0001c497          	auipc	s1,0x1c
    800048fa:	50a48493          	addi	s1,s1,1290 # 80020e00 <ftable+0x18>
    800048fe:	0001d717          	auipc	a4,0x1d
    80004902:	4a270713          	addi	a4,a4,1186 # 80021da0 <disk>
    if(f->ref == 0){
    80004906:	40dc                	lw	a5,4(s1)
    80004908:	cf99                	beqz	a5,80004926 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000490a:	02848493          	addi	s1,s1,40
    8000490e:	fee49ce3          	bne	s1,a4,80004906 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004912:	0001c517          	auipc	a0,0x1c
    80004916:	4d650513          	addi	a0,a0,1238 # 80020de8 <ftable>
    8000491a:	ffffc097          	auipc	ra,0xffffc
    8000491e:	438080e7          	jalr	1080(ra) # 80000d52 <release>
  return 0;
    80004922:	4481                	li	s1,0
    80004924:	a819                	j	8000493a <filealloc+0x5e>
      f->ref = 1;
    80004926:	4785                	li	a5,1
    80004928:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000492a:	0001c517          	auipc	a0,0x1c
    8000492e:	4be50513          	addi	a0,a0,1214 # 80020de8 <ftable>
    80004932:	ffffc097          	auipc	ra,0xffffc
    80004936:	420080e7          	jalr	1056(ra) # 80000d52 <release>
}
    8000493a:	8526                	mv	a0,s1
    8000493c:	60e2                	ld	ra,24(sp)
    8000493e:	6442                	ld	s0,16(sp)
    80004940:	64a2                	ld	s1,8(sp)
    80004942:	6105                	addi	sp,sp,32
    80004944:	8082                	ret

0000000080004946 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004946:	1101                	addi	sp,sp,-32
    80004948:	ec06                	sd	ra,24(sp)
    8000494a:	e822                	sd	s0,16(sp)
    8000494c:	e426                	sd	s1,8(sp)
    8000494e:	1000                	addi	s0,sp,32
    80004950:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004952:	0001c517          	auipc	a0,0x1c
    80004956:	49650513          	addi	a0,a0,1174 # 80020de8 <ftable>
    8000495a:	ffffc097          	auipc	ra,0xffffc
    8000495e:	344080e7          	jalr	836(ra) # 80000c9e <acquire>
  if(f->ref < 1)
    80004962:	40dc                	lw	a5,4(s1)
    80004964:	02f05263          	blez	a5,80004988 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004968:	2785                	addiw	a5,a5,1
    8000496a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000496c:	0001c517          	auipc	a0,0x1c
    80004970:	47c50513          	addi	a0,a0,1148 # 80020de8 <ftable>
    80004974:	ffffc097          	auipc	ra,0xffffc
    80004978:	3de080e7          	jalr	990(ra) # 80000d52 <release>
  return f;
}
    8000497c:	8526                	mv	a0,s1
    8000497e:	60e2                	ld	ra,24(sp)
    80004980:	6442                	ld	s0,16(sp)
    80004982:	64a2                	ld	s1,8(sp)
    80004984:	6105                	addi	sp,sp,32
    80004986:	8082                	ret
    panic("filedup");
    80004988:	00004517          	auipc	a0,0x4
    8000498c:	e4050513          	addi	a0,a0,-448 # 800087c8 <syscalls+0x268>
    80004990:	ffffc097          	auipc	ra,0xffffc
    80004994:	bb0080e7          	jalr	-1104(ra) # 80000540 <panic>

0000000080004998 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004998:	7139                	addi	sp,sp,-64
    8000499a:	fc06                	sd	ra,56(sp)
    8000499c:	f822                	sd	s0,48(sp)
    8000499e:	f426                	sd	s1,40(sp)
    800049a0:	f04a                	sd	s2,32(sp)
    800049a2:	ec4e                	sd	s3,24(sp)
    800049a4:	e852                	sd	s4,16(sp)
    800049a6:	e456                	sd	s5,8(sp)
    800049a8:	0080                	addi	s0,sp,64
    800049aa:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800049ac:	0001c517          	auipc	a0,0x1c
    800049b0:	43c50513          	addi	a0,a0,1084 # 80020de8 <ftable>
    800049b4:	ffffc097          	auipc	ra,0xffffc
    800049b8:	2ea080e7          	jalr	746(ra) # 80000c9e <acquire>
  if(f->ref < 1)
    800049bc:	40dc                	lw	a5,4(s1)
    800049be:	06f05163          	blez	a5,80004a20 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800049c2:	37fd                	addiw	a5,a5,-1
    800049c4:	0007871b          	sext.w	a4,a5
    800049c8:	c0dc                	sw	a5,4(s1)
    800049ca:	06e04363          	bgtz	a4,80004a30 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800049ce:	0004a903          	lw	s2,0(s1)
    800049d2:	0094ca83          	lbu	s5,9(s1)
    800049d6:	0104ba03          	ld	s4,16(s1)
    800049da:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800049de:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800049e2:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800049e6:	0001c517          	auipc	a0,0x1c
    800049ea:	40250513          	addi	a0,a0,1026 # 80020de8 <ftable>
    800049ee:	ffffc097          	auipc	ra,0xffffc
    800049f2:	364080e7          	jalr	868(ra) # 80000d52 <release>

  if(ff.type == FD_PIPE){
    800049f6:	4785                	li	a5,1
    800049f8:	04f90d63          	beq	s2,a5,80004a52 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800049fc:	3979                	addiw	s2,s2,-2
    800049fe:	4785                	li	a5,1
    80004a00:	0527e063          	bltu	a5,s2,80004a40 <fileclose+0xa8>
    begin_op();
    80004a04:	00000097          	auipc	ra,0x0
    80004a08:	acc080e7          	jalr	-1332(ra) # 800044d0 <begin_op>
    iput(ff.ip);
    80004a0c:	854e                	mv	a0,s3
    80004a0e:	fffff097          	auipc	ra,0xfffff
    80004a12:	2b0080e7          	jalr	688(ra) # 80003cbe <iput>
    end_op();
    80004a16:	00000097          	auipc	ra,0x0
    80004a1a:	b38080e7          	jalr	-1224(ra) # 8000454e <end_op>
    80004a1e:	a00d                	j	80004a40 <fileclose+0xa8>
    panic("fileclose");
    80004a20:	00004517          	auipc	a0,0x4
    80004a24:	db050513          	addi	a0,a0,-592 # 800087d0 <syscalls+0x270>
    80004a28:	ffffc097          	auipc	ra,0xffffc
    80004a2c:	b18080e7          	jalr	-1256(ra) # 80000540 <panic>
    release(&ftable.lock);
    80004a30:	0001c517          	auipc	a0,0x1c
    80004a34:	3b850513          	addi	a0,a0,952 # 80020de8 <ftable>
    80004a38:	ffffc097          	auipc	ra,0xffffc
    80004a3c:	31a080e7          	jalr	794(ra) # 80000d52 <release>
  }
}
    80004a40:	70e2                	ld	ra,56(sp)
    80004a42:	7442                	ld	s0,48(sp)
    80004a44:	74a2                	ld	s1,40(sp)
    80004a46:	7902                	ld	s2,32(sp)
    80004a48:	69e2                	ld	s3,24(sp)
    80004a4a:	6a42                	ld	s4,16(sp)
    80004a4c:	6aa2                	ld	s5,8(sp)
    80004a4e:	6121                	addi	sp,sp,64
    80004a50:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004a52:	85d6                	mv	a1,s5
    80004a54:	8552                	mv	a0,s4
    80004a56:	00000097          	auipc	ra,0x0
    80004a5a:	34c080e7          	jalr	844(ra) # 80004da2 <pipeclose>
    80004a5e:	b7cd                	j	80004a40 <fileclose+0xa8>

0000000080004a60 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004a60:	715d                	addi	sp,sp,-80
    80004a62:	e486                	sd	ra,72(sp)
    80004a64:	e0a2                	sd	s0,64(sp)
    80004a66:	fc26                	sd	s1,56(sp)
    80004a68:	f84a                	sd	s2,48(sp)
    80004a6a:	f44e                	sd	s3,40(sp)
    80004a6c:	0880                	addi	s0,sp,80
    80004a6e:	84aa                	mv	s1,a0
    80004a70:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004a72:	ffffd097          	auipc	ra,0xffffd
    80004a76:	100080e7          	jalr	256(ra) # 80001b72 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004a7a:	409c                	lw	a5,0(s1)
    80004a7c:	37f9                	addiw	a5,a5,-2
    80004a7e:	4705                	li	a4,1
    80004a80:	04f76763          	bltu	a4,a5,80004ace <filestat+0x6e>
    80004a84:	892a                	mv	s2,a0
    ilock(f->ip);
    80004a86:	6c88                	ld	a0,24(s1)
    80004a88:	fffff097          	auipc	ra,0xfffff
    80004a8c:	07c080e7          	jalr	124(ra) # 80003b04 <ilock>
    stati(f->ip, &st);
    80004a90:	fb840593          	addi	a1,s0,-72
    80004a94:	6c88                	ld	a0,24(s1)
    80004a96:	fffff097          	auipc	ra,0xfffff
    80004a9a:	2f8080e7          	jalr	760(ra) # 80003d8e <stati>
    iunlock(f->ip);
    80004a9e:	6c88                	ld	a0,24(s1)
    80004aa0:	fffff097          	auipc	ra,0xfffff
    80004aa4:	126080e7          	jalr	294(ra) # 80003bc6 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004aa8:	46e1                	li	a3,24
    80004aaa:	fb840613          	addi	a2,s0,-72
    80004aae:	85ce                	mv	a1,s3
    80004ab0:	05093503          	ld	a0,80(s2)
    80004ab4:	ffffd097          	auipc	ra,0xffffd
    80004ab8:	c80080e7          	jalr	-896(ra) # 80001734 <copyout>
    80004abc:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004ac0:	60a6                	ld	ra,72(sp)
    80004ac2:	6406                	ld	s0,64(sp)
    80004ac4:	74e2                	ld	s1,56(sp)
    80004ac6:	7942                	ld	s2,48(sp)
    80004ac8:	79a2                	ld	s3,40(sp)
    80004aca:	6161                	addi	sp,sp,80
    80004acc:	8082                	ret
  return -1;
    80004ace:	557d                	li	a0,-1
    80004ad0:	bfc5                	j	80004ac0 <filestat+0x60>

0000000080004ad2 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004ad2:	7179                	addi	sp,sp,-48
    80004ad4:	f406                	sd	ra,40(sp)
    80004ad6:	f022                	sd	s0,32(sp)
    80004ad8:	ec26                	sd	s1,24(sp)
    80004ada:	e84a                	sd	s2,16(sp)
    80004adc:	e44e                	sd	s3,8(sp)
    80004ade:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004ae0:	00854783          	lbu	a5,8(a0)
    80004ae4:	c3d5                	beqz	a5,80004b88 <fileread+0xb6>
    80004ae6:	84aa                	mv	s1,a0
    80004ae8:	89ae                	mv	s3,a1
    80004aea:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004aec:	411c                	lw	a5,0(a0)
    80004aee:	4705                	li	a4,1
    80004af0:	04e78963          	beq	a5,a4,80004b42 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004af4:	470d                	li	a4,3
    80004af6:	04e78d63          	beq	a5,a4,80004b50 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004afa:	4709                	li	a4,2
    80004afc:	06e79e63          	bne	a5,a4,80004b78 <fileread+0xa6>
    ilock(f->ip);
    80004b00:	6d08                	ld	a0,24(a0)
    80004b02:	fffff097          	auipc	ra,0xfffff
    80004b06:	002080e7          	jalr	2(ra) # 80003b04 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004b0a:	874a                	mv	a4,s2
    80004b0c:	5094                	lw	a3,32(s1)
    80004b0e:	864e                	mv	a2,s3
    80004b10:	4585                	li	a1,1
    80004b12:	6c88                	ld	a0,24(s1)
    80004b14:	fffff097          	auipc	ra,0xfffff
    80004b18:	2a4080e7          	jalr	676(ra) # 80003db8 <readi>
    80004b1c:	892a                	mv	s2,a0
    80004b1e:	00a05563          	blez	a0,80004b28 <fileread+0x56>
      f->off += r;
    80004b22:	509c                	lw	a5,32(s1)
    80004b24:	9fa9                	addw	a5,a5,a0
    80004b26:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004b28:	6c88                	ld	a0,24(s1)
    80004b2a:	fffff097          	auipc	ra,0xfffff
    80004b2e:	09c080e7          	jalr	156(ra) # 80003bc6 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004b32:	854a                	mv	a0,s2
    80004b34:	70a2                	ld	ra,40(sp)
    80004b36:	7402                	ld	s0,32(sp)
    80004b38:	64e2                	ld	s1,24(sp)
    80004b3a:	6942                	ld	s2,16(sp)
    80004b3c:	69a2                	ld	s3,8(sp)
    80004b3e:	6145                	addi	sp,sp,48
    80004b40:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004b42:	6908                	ld	a0,16(a0)
    80004b44:	00000097          	auipc	ra,0x0
    80004b48:	3c6080e7          	jalr	966(ra) # 80004f0a <piperead>
    80004b4c:	892a                	mv	s2,a0
    80004b4e:	b7d5                	j	80004b32 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004b50:	02451783          	lh	a5,36(a0)
    80004b54:	03079693          	slli	a3,a5,0x30
    80004b58:	92c1                	srli	a3,a3,0x30
    80004b5a:	4725                	li	a4,9
    80004b5c:	02d76863          	bltu	a4,a3,80004b8c <fileread+0xba>
    80004b60:	0792                	slli	a5,a5,0x4
    80004b62:	0001c717          	auipc	a4,0x1c
    80004b66:	1e670713          	addi	a4,a4,486 # 80020d48 <devsw>
    80004b6a:	97ba                	add	a5,a5,a4
    80004b6c:	639c                	ld	a5,0(a5)
    80004b6e:	c38d                	beqz	a5,80004b90 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004b70:	4505                	li	a0,1
    80004b72:	9782                	jalr	a5
    80004b74:	892a                	mv	s2,a0
    80004b76:	bf75                	j	80004b32 <fileread+0x60>
    panic("fileread");
    80004b78:	00004517          	auipc	a0,0x4
    80004b7c:	c6850513          	addi	a0,a0,-920 # 800087e0 <syscalls+0x280>
    80004b80:	ffffc097          	auipc	ra,0xffffc
    80004b84:	9c0080e7          	jalr	-1600(ra) # 80000540 <panic>
    return -1;
    80004b88:	597d                	li	s2,-1
    80004b8a:	b765                	j	80004b32 <fileread+0x60>
      return -1;
    80004b8c:	597d                	li	s2,-1
    80004b8e:	b755                	j	80004b32 <fileread+0x60>
    80004b90:	597d                	li	s2,-1
    80004b92:	b745                	j	80004b32 <fileread+0x60>

0000000080004b94 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004b94:	715d                	addi	sp,sp,-80
    80004b96:	e486                	sd	ra,72(sp)
    80004b98:	e0a2                	sd	s0,64(sp)
    80004b9a:	fc26                	sd	s1,56(sp)
    80004b9c:	f84a                	sd	s2,48(sp)
    80004b9e:	f44e                	sd	s3,40(sp)
    80004ba0:	f052                	sd	s4,32(sp)
    80004ba2:	ec56                	sd	s5,24(sp)
    80004ba4:	e85a                	sd	s6,16(sp)
    80004ba6:	e45e                	sd	s7,8(sp)
    80004ba8:	e062                	sd	s8,0(sp)
    80004baa:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004bac:	00954783          	lbu	a5,9(a0)
    80004bb0:	10078663          	beqz	a5,80004cbc <filewrite+0x128>
    80004bb4:	892a                	mv	s2,a0
    80004bb6:	8b2e                	mv	s6,a1
    80004bb8:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004bba:	411c                	lw	a5,0(a0)
    80004bbc:	4705                	li	a4,1
    80004bbe:	02e78263          	beq	a5,a4,80004be2 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004bc2:	470d                	li	a4,3
    80004bc4:	02e78663          	beq	a5,a4,80004bf0 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004bc8:	4709                	li	a4,2
    80004bca:	0ee79163          	bne	a5,a4,80004cac <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004bce:	0ac05d63          	blez	a2,80004c88 <filewrite+0xf4>
    int i = 0;
    80004bd2:	4981                	li	s3,0
    80004bd4:	6b85                	lui	s7,0x1
    80004bd6:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004bda:	6c05                	lui	s8,0x1
    80004bdc:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004be0:	a861                	j	80004c78 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004be2:	6908                	ld	a0,16(a0)
    80004be4:	00000097          	auipc	ra,0x0
    80004be8:	22e080e7          	jalr	558(ra) # 80004e12 <pipewrite>
    80004bec:	8a2a                	mv	s4,a0
    80004bee:	a045                	j	80004c8e <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004bf0:	02451783          	lh	a5,36(a0)
    80004bf4:	03079693          	slli	a3,a5,0x30
    80004bf8:	92c1                	srli	a3,a3,0x30
    80004bfa:	4725                	li	a4,9
    80004bfc:	0cd76263          	bltu	a4,a3,80004cc0 <filewrite+0x12c>
    80004c00:	0792                	slli	a5,a5,0x4
    80004c02:	0001c717          	auipc	a4,0x1c
    80004c06:	14670713          	addi	a4,a4,326 # 80020d48 <devsw>
    80004c0a:	97ba                	add	a5,a5,a4
    80004c0c:	679c                	ld	a5,8(a5)
    80004c0e:	cbdd                	beqz	a5,80004cc4 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004c10:	4505                	li	a0,1
    80004c12:	9782                	jalr	a5
    80004c14:	8a2a                	mv	s4,a0
    80004c16:	a8a5                	j	80004c8e <filewrite+0xfa>
    80004c18:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004c1c:	00000097          	auipc	ra,0x0
    80004c20:	8b4080e7          	jalr	-1868(ra) # 800044d0 <begin_op>
      ilock(f->ip);
    80004c24:	01893503          	ld	a0,24(s2)
    80004c28:	fffff097          	auipc	ra,0xfffff
    80004c2c:	edc080e7          	jalr	-292(ra) # 80003b04 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004c30:	8756                	mv	a4,s5
    80004c32:	02092683          	lw	a3,32(s2)
    80004c36:	01698633          	add	a2,s3,s6
    80004c3a:	4585                	li	a1,1
    80004c3c:	01893503          	ld	a0,24(s2)
    80004c40:	fffff097          	auipc	ra,0xfffff
    80004c44:	270080e7          	jalr	624(ra) # 80003eb0 <writei>
    80004c48:	84aa                	mv	s1,a0
    80004c4a:	00a05763          	blez	a0,80004c58 <filewrite+0xc4>
        f->off += r;
    80004c4e:	02092783          	lw	a5,32(s2)
    80004c52:	9fa9                	addw	a5,a5,a0
    80004c54:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004c58:	01893503          	ld	a0,24(s2)
    80004c5c:	fffff097          	auipc	ra,0xfffff
    80004c60:	f6a080e7          	jalr	-150(ra) # 80003bc6 <iunlock>
      end_op();
    80004c64:	00000097          	auipc	ra,0x0
    80004c68:	8ea080e7          	jalr	-1814(ra) # 8000454e <end_op>

      if(r != n1){
    80004c6c:	009a9f63          	bne	s5,s1,80004c8a <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004c70:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004c74:	0149db63          	bge	s3,s4,80004c8a <filewrite+0xf6>
      int n1 = n - i;
    80004c78:	413a04bb          	subw	s1,s4,s3
    80004c7c:	0004879b          	sext.w	a5,s1
    80004c80:	f8fbdce3          	bge	s7,a5,80004c18 <filewrite+0x84>
    80004c84:	84e2                	mv	s1,s8
    80004c86:	bf49                	j	80004c18 <filewrite+0x84>
    int i = 0;
    80004c88:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004c8a:	013a1f63          	bne	s4,s3,80004ca8 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004c8e:	8552                	mv	a0,s4
    80004c90:	60a6                	ld	ra,72(sp)
    80004c92:	6406                	ld	s0,64(sp)
    80004c94:	74e2                	ld	s1,56(sp)
    80004c96:	7942                	ld	s2,48(sp)
    80004c98:	79a2                	ld	s3,40(sp)
    80004c9a:	7a02                	ld	s4,32(sp)
    80004c9c:	6ae2                	ld	s5,24(sp)
    80004c9e:	6b42                	ld	s6,16(sp)
    80004ca0:	6ba2                	ld	s7,8(sp)
    80004ca2:	6c02                	ld	s8,0(sp)
    80004ca4:	6161                	addi	sp,sp,80
    80004ca6:	8082                	ret
    ret = (i == n ? n : -1);
    80004ca8:	5a7d                	li	s4,-1
    80004caa:	b7d5                	j	80004c8e <filewrite+0xfa>
    panic("filewrite");
    80004cac:	00004517          	auipc	a0,0x4
    80004cb0:	b4450513          	addi	a0,a0,-1212 # 800087f0 <syscalls+0x290>
    80004cb4:	ffffc097          	auipc	ra,0xffffc
    80004cb8:	88c080e7          	jalr	-1908(ra) # 80000540 <panic>
    return -1;
    80004cbc:	5a7d                	li	s4,-1
    80004cbe:	bfc1                	j	80004c8e <filewrite+0xfa>
      return -1;
    80004cc0:	5a7d                	li	s4,-1
    80004cc2:	b7f1                	j	80004c8e <filewrite+0xfa>
    80004cc4:	5a7d                	li	s4,-1
    80004cc6:	b7e1                	j	80004c8e <filewrite+0xfa>

0000000080004cc8 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004cc8:	7179                	addi	sp,sp,-48
    80004cca:	f406                	sd	ra,40(sp)
    80004ccc:	f022                	sd	s0,32(sp)
    80004cce:	ec26                	sd	s1,24(sp)
    80004cd0:	e84a                	sd	s2,16(sp)
    80004cd2:	e44e                	sd	s3,8(sp)
    80004cd4:	e052                	sd	s4,0(sp)
    80004cd6:	1800                	addi	s0,sp,48
    80004cd8:	84aa                	mv	s1,a0
    80004cda:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004cdc:	0005b023          	sd	zero,0(a1)
    80004ce0:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004ce4:	00000097          	auipc	ra,0x0
    80004ce8:	bf8080e7          	jalr	-1032(ra) # 800048dc <filealloc>
    80004cec:	e088                	sd	a0,0(s1)
    80004cee:	c551                	beqz	a0,80004d7a <pipealloc+0xb2>
    80004cf0:	00000097          	auipc	ra,0x0
    80004cf4:	bec080e7          	jalr	-1044(ra) # 800048dc <filealloc>
    80004cf8:	00aa3023          	sd	a0,0(s4)
    80004cfc:	c92d                	beqz	a0,80004d6e <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004cfe:	ffffc097          	auipc	ra,0xffffc
    80004d02:	e64080e7          	jalr	-412(ra) # 80000b62 <kalloc>
    80004d06:	892a                	mv	s2,a0
    80004d08:	c125                	beqz	a0,80004d68 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004d0a:	4985                	li	s3,1
    80004d0c:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004d10:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004d14:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004d18:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004d1c:	00004597          	auipc	a1,0x4
    80004d20:	ae458593          	addi	a1,a1,-1308 # 80008800 <syscalls+0x2a0>
    80004d24:	ffffc097          	auipc	ra,0xffffc
    80004d28:	eea080e7          	jalr	-278(ra) # 80000c0e <initlock>
  (*f0)->type = FD_PIPE;
    80004d2c:	609c                	ld	a5,0(s1)
    80004d2e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004d32:	609c                	ld	a5,0(s1)
    80004d34:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004d38:	609c                	ld	a5,0(s1)
    80004d3a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004d3e:	609c                	ld	a5,0(s1)
    80004d40:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004d44:	000a3783          	ld	a5,0(s4)
    80004d48:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004d4c:	000a3783          	ld	a5,0(s4)
    80004d50:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004d54:	000a3783          	ld	a5,0(s4)
    80004d58:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004d5c:	000a3783          	ld	a5,0(s4)
    80004d60:	0127b823          	sd	s2,16(a5)
  return 0;
    80004d64:	4501                	li	a0,0
    80004d66:	a025                	j	80004d8e <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004d68:	6088                	ld	a0,0(s1)
    80004d6a:	e501                	bnez	a0,80004d72 <pipealloc+0xaa>
    80004d6c:	a039                	j	80004d7a <pipealloc+0xb2>
    80004d6e:	6088                	ld	a0,0(s1)
    80004d70:	c51d                	beqz	a0,80004d9e <pipealloc+0xd6>
    fileclose(*f0);
    80004d72:	00000097          	auipc	ra,0x0
    80004d76:	c26080e7          	jalr	-986(ra) # 80004998 <fileclose>
  if(*f1)
    80004d7a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004d7e:	557d                	li	a0,-1
  if(*f1)
    80004d80:	c799                	beqz	a5,80004d8e <pipealloc+0xc6>
    fileclose(*f1);
    80004d82:	853e                	mv	a0,a5
    80004d84:	00000097          	auipc	ra,0x0
    80004d88:	c14080e7          	jalr	-1004(ra) # 80004998 <fileclose>
  return -1;
    80004d8c:	557d                	li	a0,-1
}
    80004d8e:	70a2                	ld	ra,40(sp)
    80004d90:	7402                	ld	s0,32(sp)
    80004d92:	64e2                	ld	s1,24(sp)
    80004d94:	6942                	ld	s2,16(sp)
    80004d96:	69a2                	ld	s3,8(sp)
    80004d98:	6a02                	ld	s4,0(sp)
    80004d9a:	6145                	addi	sp,sp,48
    80004d9c:	8082                	ret
  return -1;
    80004d9e:	557d                	li	a0,-1
    80004da0:	b7fd                	j	80004d8e <pipealloc+0xc6>

0000000080004da2 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004da2:	1101                	addi	sp,sp,-32
    80004da4:	ec06                	sd	ra,24(sp)
    80004da6:	e822                	sd	s0,16(sp)
    80004da8:	e426                	sd	s1,8(sp)
    80004daa:	e04a                	sd	s2,0(sp)
    80004dac:	1000                	addi	s0,sp,32
    80004dae:	84aa                	mv	s1,a0
    80004db0:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004db2:	ffffc097          	auipc	ra,0xffffc
    80004db6:	eec080e7          	jalr	-276(ra) # 80000c9e <acquire>
  if(writable){
    80004dba:	02090d63          	beqz	s2,80004df4 <pipeclose+0x52>
    pi->writeopen = 0;
    80004dbe:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004dc2:	21848513          	addi	a0,s1,536
    80004dc6:	ffffd097          	auipc	ra,0xffffd
    80004dca:	5be080e7          	jalr	1470(ra) # 80002384 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004dce:	2204b783          	ld	a5,544(s1)
    80004dd2:	eb95                	bnez	a5,80004e06 <pipeclose+0x64>
    release(&pi->lock);
    80004dd4:	8526                	mv	a0,s1
    80004dd6:	ffffc097          	auipc	ra,0xffffc
    80004dda:	f7c080e7          	jalr	-132(ra) # 80000d52 <release>
    kfree((char*)pi);
    80004dde:	8526                	mv	a0,s1
    80004de0:	ffffc097          	auipc	ra,0xffffc
    80004de4:	c1a080e7          	jalr	-998(ra) # 800009fa <kfree>
  } else
    release(&pi->lock);
}
    80004de8:	60e2                	ld	ra,24(sp)
    80004dea:	6442                	ld	s0,16(sp)
    80004dec:	64a2                	ld	s1,8(sp)
    80004dee:	6902                	ld	s2,0(sp)
    80004df0:	6105                	addi	sp,sp,32
    80004df2:	8082                	ret
    pi->readopen = 0;
    80004df4:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004df8:	21c48513          	addi	a0,s1,540
    80004dfc:	ffffd097          	auipc	ra,0xffffd
    80004e00:	588080e7          	jalr	1416(ra) # 80002384 <wakeup>
    80004e04:	b7e9                	j	80004dce <pipeclose+0x2c>
    release(&pi->lock);
    80004e06:	8526                	mv	a0,s1
    80004e08:	ffffc097          	auipc	ra,0xffffc
    80004e0c:	f4a080e7          	jalr	-182(ra) # 80000d52 <release>
}
    80004e10:	bfe1                	j	80004de8 <pipeclose+0x46>

0000000080004e12 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004e12:	711d                	addi	sp,sp,-96
    80004e14:	ec86                	sd	ra,88(sp)
    80004e16:	e8a2                	sd	s0,80(sp)
    80004e18:	e4a6                	sd	s1,72(sp)
    80004e1a:	e0ca                	sd	s2,64(sp)
    80004e1c:	fc4e                	sd	s3,56(sp)
    80004e1e:	f852                	sd	s4,48(sp)
    80004e20:	f456                	sd	s5,40(sp)
    80004e22:	f05a                	sd	s6,32(sp)
    80004e24:	ec5e                	sd	s7,24(sp)
    80004e26:	e862                	sd	s8,16(sp)
    80004e28:	1080                	addi	s0,sp,96
    80004e2a:	84aa                	mv	s1,a0
    80004e2c:	8aae                	mv	s5,a1
    80004e2e:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004e30:	ffffd097          	auipc	ra,0xffffd
    80004e34:	d42080e7          	jalr	-702(ra) # 80001b72 <myproc>
    80004e38:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004e3a:	8526                	mv	a0,s1
    80004e3c:	ffffc097          	auipc	ra,0xffffc
    80004e40:	e62080e7          	jalr	-414(ra) # 80000c9e <acquire>
  while(i < n){
    80004e44:	0b405663          	blez	s4,80004ef0 <pipewrite+0xde>
  int i = 0;
    80004e48:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004e4a:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004e4c:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004e50:	21c48b93          	addi	s7,s1,540
    80004e54:	a089                	j	80004e96 <pipewrite+0x84>
      release(&pi->lock);
    80004e56:	8526                	mv	a0,s1
    80004e58:	ffffc097          	auipc	ra,0xffffc
    80004e5c:	efa080e7          	jalr	-262(ra) # 80000d52 <release>
      return -1;
    80004e60:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004e62:	854a                	mv	a0,s2
    80004e64:	60e6                	ld	ra,88(sp)
    80004e66:	6446                	ld	s0,80(sp)
    80004e68:	64a6                	ld	s1,72(sp)
    80004e6a:	6906                	ld	s2,64(sp)
    80004e6c:	79e2                	ld	s3,56(sp)
    80004e6e:	7a42                	ld	s4,48(sp)
    80004e70:	7aa2                	ld	s5,40(sp)
    80004e72:	7b02                	ld	s6,32(sp)
    80004e74:	6be2                	ld	s7,24(sp)
    80004e76:	6c42                	ld	s8,16(sp)
    80004e78:	6125                	addi	sp,sp,96
    80004e7a:	8082                	ret
      wakeup(&pi->nread);
    80004e7c:	8562                	mv	a0,s8
    80004e7e:	ffffd097          	auipc	ra,0xffffd
    80004e82:	506080e7          	jalr	1286(ra) # 80002384 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004e86:	85a6                	mv	a1,s1
    80004e88:	855e                	mv	a0,s7
    80004e8a:	ffffd097          	auipc	ra,0xffffd
    80004e8e:	496080e7          	jalr	1174(ra) # 80002320 <sleep>
  while(i < n){
    80004e92:	07495063          	bge	s2,s4,80004ef2 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004e96:	2204a783          	lw	a5,544(s1)
    80004e9a:	dfd5                	beqz	a5,80004e56 <pipewrite+0x44>
    80004e9c:	854e                	mv	a0,s3
    80004e9e:	ffffd097          	auipc	ra,0xffffd
    80004ea2:	72a080e7          	jalr	1834(ra) # 800025c8 <killed>
    80004ea6:	f945                	bnez	a0,80004e56 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004ea8:	2184a783          	lw	a5,536(s1)
    80004eac:	21c4a703          	lw	a4,540(s1)
    80004eb0:	2007879b          	addiw	a5,a5,512
    80004eb4:	fcf704e3          	beq	a4,a5,80004e7c <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004eb8:	4685                	li	a3,1
    80004eba:	01590633          	add	a2,s2,s5
    80004ebe:	faf40593          	addi	a1,s0,-81
    80004ec2:	0509b503          	ld	a0,80(s3)
    80004ec6:	ffffd097          	auipc	ra,0xffffd
    80004eca:	8fa080e7          	jalr	-1798(ra) # 800017c0 <copyin>
    80004ece:	03650263          	beq	a0,s6,80004ef2 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004ed2:	21c4a783          	lw	a5,540(s1)
    80004ed6:	0017871b          	addiw	a4,a5,1
    80004eda:	20e4ae23          	sw	a4,540(s1)
    80004ede:	1ff7f793          	andi	a5,a5,511
    80004ee2:	97a6                	add	a5,a5,s1
    80004ee4:	faf44703          	lbu	a4,-81(s0)
    80004ee8:	00e78c23          	sb	a4,24(a5)
      i++;
    80004eec:	2905                	addiw	s2,s2,1
    80004eee:	b755                	j	80004e92 <pipewrite+0x80>
  int i = 0;
    80004ef0:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004ef2:	21848513          	addi	a0,s1,536
    80004ef6:	ffffd097          	auipc	ra,0xffffd
    80004efa:	48e080e7          	jalr	1166(ra) # 80002384 <wakeup>
  release(&pi->lock);
    80004efe:	8526                	mv	a0,s1
    80004f00:	ffffc097          	auipc	ra,0xffffc
    80004f04:	e52080e7          	jalr	-430(ra) # 80000d52 <release>
  return i;
    80004f08:	bfa9                	j	80004e62 <pipewrite+0x50>

0000000080004f0a <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004f0a:	715d                	addi	sp,sp,-80
    80004f0c:	e486                	sd	ra,72(sp)
    80004f0e:	e0a2                	sd	s0,64(sp)
    80004f10:	fc26                	sd	s1,56(sp)
    80004f12:	f84a                	sd	s2,48(sp)
    80004f14:	f44e                	sd	s3,40(sp)
    80004f16:	f052                	sd	s4,32(sp)
    80004f18:	ec56                	sd	s5,24(sp)
    80004f1a:	e85a                	sd	s6,16(sp)
    80004f1c:	0880                	addi	s0,sp,80
    80004f1e:	84aa                	mv	s1,a0
    80004f20:	892e                	mv	s2,a1
    80004f22:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004f24:	ffffd097          	auipc	ra,0xffffd
    80004f28:	c4e080e7          	jalr	-946(ra) # 80001b72 <myproc>
    80004f2c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004f2e:	8526                	mv	a0,s1
    80004f30:	ffffc097          	auipc	ra,0xffffc
    80004f34:	d6e080e7          	jalr	-658(ra) # 80000c9e <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f38:	2184a703          	lw	a4,536(s1)
    80004f3c:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f40:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f44:	02f71763          	bne	a4,a5,80004f72 <piperead+0x68>
    80004f48:	2244a783          	lw	a5,548(s1)
    80004f4c:	c39d                	beqz	a5,80004f72 <piperead+0x68>
    if(killed(pr)){
    80004f4e:	8552                	mv	a0,s4
    80004f50:	ffffd097          	auipc	ra,0xffffd
    80004f54:	678080e7          	jalr	1656(ra) # 800025c8 <killed>
    80004f58:	e949                	bnez	a0,80004fea <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f5a:	85a6                	mv	a1,s1
    80004f5c:	854e                	mv	a0,s3
    80004f5e:	ffffd097          	auipc	ra,0xffffd
    80004f62:	3c2080e7          	jalr	962(ra) # 80002320 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f66:	2184a703          	lw	a4,536(s1)
    80004f6a:	21c4a783          	lw	a5,540(s1)
    80004f6e:	fcf70de3          	beq	a4,a5,80004f48 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f72:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f74:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f76:	05505463          	blez	s5,80004fbe <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004f7a:	2184a783          	lw	a5,536(s1)
    80004f7e:	21c4a703          	lw	a4,540(s1)
    80004f82:	02f70e63          	beq	a4,a5,80004fbe <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004f86:	0017871b          	addiw	a4,a5,1
    80004f8a:	20e4ac23          	sw	a4,536(s1)
    80004f8e:	1ff7f793          	andi	a5,a5,511
    80004f92:	97a6                	add	a5,a5,s1
    80004f94:	0187c783          	lbu	a5,24(a5)
    80004f98:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f9c:	4685                	li	a3,1
    80004f9e:	fbf40613          	addi	a2,s0,-65
    80004fa2:	85ca                	mv	a1,s2
    80004fa4:	050a3503          	ld	a0,80(s4)
    80004fa8:	ffffc097          	auipc	ra,0xffffc
    80004fac:	78c080e7          	jalr	1932(ra) # 80001734 <copyout>
    80004fb0:	01650763          	beq	a0,s6,80004fbe <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004fb4:	2985                	addiw	s3,s3,1
    80004fb6:	0905                	addi	s2,s2,1
    80004fb8:	fd3a91e3          	bne	s5,s3,80004f7a <piperead+0x70>
    80004fbc:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004fbe:	21c48513          	addi	a0,s1,540
    80004fc2:	ffffd097          	auipc	ra,0xffffd
    80004fc6:	3c2080e7          	jalr	962(ra) # 80002384 <wakeup>
  release(&pi->lock);
    80004fca:	8526                	mv	a0,s1
    80004fcc:	ffffc097          	auipc	ra,0xffffc
    80004fd0:	d86080e7          	jalr	-634(ra) # 80000d52 <release>
  return i;
}
    80004fd4:	854e                	mv	a0,s3
    80004fd6:	60a6                	ld	ra,72(sp)
    80004fd8:	6406                	ld	s0,64(sp)
    80004fda:	74e2                	ld	s1,56(sp)
    80004fdc:	7942                	ld	s2,48(sp)
    80004fde:	79a2                	ld	s3,40(sp)
    80004fe0:	7a02                	ld	s4,32(sp)
    80004fe2:	6ae2                	ld	s5,24(sp)
    80004fe4:	6b42                	ld	s6,16(sp)
    80004fe6:	6161                	addi	sp,sp,80
    80004fe8:	8082                	ret
      release(&pi->lock);
    80004fea:	8526                	mv	a0,s1
    80004fec:	ffffc097          	auipc	ra,0xffffc
    80004ff0:	d66080e7          	jalr	-666(ra) # 80000d52 <release>
      return -1;
    80004ff4:	59fd                	li	s3,-1
    80004ff6:	bff9                	j	80004fd4 <piperead+0xca>

0000000080004ff8 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004ff8:	1141                	addi	sp,sp,-16
    80004ffa:	e422                	sd	s0,8(sp)
    80004ffc:	0800                	addi	s0,sp,16
    80004ffe:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80005000:	8905                	andi	a0,a0,1
    80005002:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80005004:	8b89                	andi	a5,a5,2
    80005006:	c399                	beqz	a5,8000500c <flags2perm+0x14>
      perm |= PTE_W;
    80005008:	00456513          	ori	a0,a0,4
    return perm;
}
    8000500c:	6422                	ld	s0,8(sp)
    8000500e:	0141                	addi	sp,sp,16
    80005010:	8082                	ret

0000000080005012 <exec>:

int
exec(char *path, char **argv)
{
    80005012:	de010113          	addi	sp,sp,-544
    80005016:	20113c23          	sd	ra,536(sp)
    8000501a:	20813823          	sd	s0,528(sp)
    8000501e:	20913423          	sd	s1,520(sp)
    80005022:	21213023          	sd	s2,512(sp)
    80005026:	ffce                	sd	s3,504(sp)
    80005028:	fbd2                	sd	s4,496(sp)
    8000502a:	f7d6                	sd	s5,488(sp)
    8000502c:	f3da                	sd	s6,480(sp)
    8000502e:	efde                	sd	s7,472(sp)
    80005030:	ebe2                	sd	s8,464(sp)
    80005032:	e7e6                	sd	s9,456(sp)
    80005034:	e3ea                	sd	s10,448(sp)
    80005036:	ff6e                	sd	s11,440(sp)
    80005038:	1400                	addi	s0,sp,544
    8000503a:	892a                	mv	s2,a0
    8000503c:	dea43423          	sd	a0,-536(s0)
    80005040:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005044:	ffffd097          	auipc	ra,0xffffd
    80005048:	b2e080e7          	jalr	-1234(ra) # 80001b72 <myproc>
    8000504c:	84aa                	mv	s1,a0

  begin_op();
    8000504e:	fffff097          	auipc	ra,0xfffff
    80005052:	482080e7          	jalr	1154(ra) # 800044d0 <begin_op>

  if((ip = namei(path)) == 0){
    80005056:	854a                	mv	a0,s2
    80005058:	fffff097          	auipc	ra,0xfffff
    8000505c:	258080e7          	jalr	600(ra) # 800042b0 <namei>
    80005060:	c93d                	beqz	a0,800050d6 <exec+0xc4>
    80005062:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005064:	fffff097          	auipc	ra,0xfffff
    80005068:	aa0080e7          	jalr	-1376(ra) # 80003b04 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000506c:	04000713          	li	a4,64
    80005070:	4681                	li	a3,0
    80005072:	e5040613          	addi	a2,s0,-432
    80005076:	4581                	li	a1,0
    80005078:	8556                	mv	a0,s5
    8000507a:	fffff097          	auipc	ra,0xfffff
    8000507e:	d3e080e7          	jalr	-706(ra) # 80003db8 <readi>
    80005082:	04000793          	li	a5,64
    80005086:	00f51a63          	bne	a0,a5,8000509a <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    8000508a:	e5042703          	lw	a4,-432(s0)
    8000508e:	464c47b7          	lui	a5,0x464c4
    80005092:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005096:	04f70663          	beq	a4,a5,800050e2 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000509a:	8556                	mv	a0,s5
    8000509c:	fffff097          	auipc	ra,0xfffff
    800050a0:	cca080e7          	jalr	-822(ra) # 80003d66 <iunlockput>
    end_op();
    800050a4:	fffff097          	auipc	ra,0xfffff
    800050a8:	4aa080e7          	jalr	1194(ra) # 8000454e <end_op>
  }
  return -1;
    800050ac:	557d                	li	a0,-1
}
    800050ae:	21813083          	ld	ra,536(sp)
    800050b2:	21013403          	ld	s0,528(sp)
    800050b6:	20813483          	ld	s1,520(sp)
    800050ba:	20013903          	ld	s2,512(sp)
    800050be:	79fe                	ld	s3,504(sp)
    800050c0:	7a5e                	ld	s4,496(sp)
    800050c2:	7abe                	ld	s5,488(sp)
    800050c4:	7b1e                	ld	s6,480(sp)
    800050c6:	6bfe                	ld	s7,472(sp)
    800050c8:	6c5e                	ld	s8,464(sp)
    800050ca:	6cbe                	ld	s9,456(sp)
    800050cc:	6d1e                	ld	s10,448(sp)
    800050ce:	7dfa                	ld	s11,440(sp)
    800050d0:	22010113          	addi	sp,sp,544
    800050d4:	8082                	ret
    end_op();
    800050d6:	fffff097          	auipc	ra,0xfffff
    800050da:	478080e7          	jalr	1144(ra) # 8000454e <end_op>
    return -1;
    800050de:	557d                	li	a0,-1
    800050e0:	b7f9                	j	800050ae <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    800050e2:	8526                	mv	a0,s1
    800050e4:	ffffd097          	auipc	ra,0xffffd
    800050e8:	b52080e7          	jalr	-1198(ra) # 80001c36 <proc_pagetable>
    800050ec:	8b2a                	mv	s6,a0
    800050ee:	d555                	beqz	a0,8000509a <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050f0:	e7042783          	lw	a5,-400(s0)
    800050f4:	e8845703          	lhu	a4,-376(s0)
    800050f8:	c735                	beqz	a4,80005164 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800050fa:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050fc:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005100:	6a05                	lui	s4,0x1
    80005102:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80005106:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    8000510a:	6d85                	lui	s11,0x1
    8000510c:	7d7d                	lui	s10,0xfffff
    8000510e:	ac3d                	j	8000534c <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005110:	00003517          	auipc	a0,0x3
    80005114:	6f850513          	addi	a0,a0,1784 # 80008808 <syscalls+0x2a8>
    80005118:	ffffb097          	auipc	ra,0xffffb
    8000511c:	428080e7          	jalr	1064(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005120:	874a                	mv	a4,s2
    80005122:	009c86bb          	addw	a3,s9,s1
    80005126:	4581                	li	a1,0
    80005128:	8556                	mv	a0,s5
    8000512a:	fffff097          	auipc	ra,0xfffff
    8000512e:	c8e080e7          	jalr	-882(ra) # 80003db8 <readi>
    80005132:	2501                	sext.w	a0,a0
    80005134:	1aa91963          	bne	s2,a0,800052e6 <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    80005138:	009d84bb          	addw	s1,s11,s1
    8000513c:	013d09bb          	addw	s3,s10,s3
    80005140:	1f74f663          	bgeu	s1,s7,8000532c <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    80005144:	02049593          	slli	a1,s1,0x20
    80005148:	9181                	srli	a1,a1,0x20
    8000514a:	95e2                	add	a1,a1,s8
    8000514c:	855a                	mv	a0,s6
    8000514e:	ffffc097          	auipc	ra,0xffffc
    80005152:	fd6080e7          	jalr	-42(ra) # 80001124 <walkaddr>
    80005156:	862a                	mv	a2,a0
    if(pa == 0)
    80005158:	dd45                	beqz	a0,80005110 <exec+0xfe>
      n = PGSIZE;
    8000515a:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    8000515c:	fd49f2e3          	bgeu	s3,s4,80005120 <exec+0x10e>
      n = sz - i;
    80005160:	894e                	mv	s2,s3
    80005162:	bf7d                	j	80005120 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005164:	4901                	li	s2,0
  iunlockput(ip);
    80005166:	8556                	mv	a0,s5
    80005168:	fffff097          	auipc	ra,0xfffff
    8000516c:	bfe080e7          	jalr	-1026(ra) # 80003d66 <iunlockput>
  end_op();
    80005170:	fffff097          	auipc	ra,0xfffff
    80005174:	3de080e7          	jalr	990(ra) # 8000454e <end_op>
  p = myproc();
    80005178:	ffffd097          	auipc	ra,0xffffd
    8000517c:	9fa080e7          	jalr	-1542(ra) # 80001b72 <myproc>
    80005180:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005182:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005186:	6785                	lui	a5,0x1
    80005188:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000518a:	97ca                	add	a5,a5,s2
    8000518c:	777d                	lui	a4,0xfffff
    8000518e:	8ff9                	and	a5,a5,a4
    80005190:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005194:	4691                	li	a3,4
    80005196:	6609                	lui	a2,0x2
    80005198:	963e                	add	a2,a2,a5
    8000519a:	85be                	mv	a1,a5
    8000519c:	855a                	mv	a0,s6
    8000519e:	ffffc097          	auipc	ra,0xffffc
    800051a2:	33a080e7          	jalr	826(ra) # 800014d8 <uvmalloc>
    800051a6:	8c2a                	mv	s8,a0
  ip = 0;
    800051a8:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800051aa:	12050e63          	beqz	a0,800052e6 <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    800051ae:	75f9                	lui	a1,0xffffe
    800051b0:	95aa                	add	a1,a1,a0
    800051b2:	855a                	mv	a0,s6
    800051b4:	ffffc097          	auipc	ra,0xffffc
    800051b8:	54e080e7          	jalr	1358(ra) # 80001702 <uvmclear>
  stackbase = sp - PGSIZE;
    800051bc:	7afd                	lui	s5,0xfffff
    800051be:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800051c0:	df043783          	ld	a5,-528(s0)
    800051c4:	6388                	ld	a0,0(a5)
    800051c6:	c925                	beqz	a0,80005236 <exec+0x224>
    800051c8:	e9040993          	addi	s3,s0,-368
    800051cc:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800051d0:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800051d2:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800051d4:	ffffc097          	auipc	ra,0xffffc
    800051d8:	d42080e7          	jalr	-702(ra) # 80000f16 <strlen>
    800051dc:	0015079b          	addiw	a5,a0,1
    800051e0:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800051e4:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    800051e8:	13596663          	bltu	s2,s5,80005314 <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800051ec:	df043d83          	ld	s11,-528(s0)
    800051f0:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800051f4:	8552                	mv	a0,s4
    800051f6:	ffffc097          	auipc	ra,0xffffc
    800051fa:	d20080e7          	jalr	-736(ra) # 80000f16 <strlen>
    800051fe:	0015069b          	addiw	a3,a0,1
    80005202:	8652                	mv	a2,s4
    80005204:	85ca                	mv	a1,s2
    80005206:	855a                	mv	a0,s6
    80005208:	ffffc097          	auipc	ra,0xffffc
    8000520c:	52c080e7          	jalr	1324(ra) # 80001734 <copyout>
    80005210:	10054663          	bltz	a0,8000531c <exec+0x30a>
    ustack[argc] = sp;
    80005214:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005218:	0485                	addi	s1,s1,1
    8000521a:	008d8793          	addi	a5,s11,8
    8000521e:	def43823          	sd	a5,-528(s0)
    80005222:	008db503          	ld	a0,8(s11)
    80005226:	c911                	beqz	a0,8000523a <exec+0x228>
    if(argc >= MAXARG)
    80005228:	09a1                	addi	s3,s3,8
    8000522a:	fb3c95e3          	bne	s9,s3,800051d4 <exec+0x1c2>
  sz = sz1;
    8000522e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005232:	4a81                	li	s5,0
    80005234:	a84d                	j	800052e6 <exec+0x2d4>
  sp = sz;
    80005236:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005238:	4481                	li	s1,0
  ustack[argc] = 0;
    8000523a:	00349793          	slli	a5,s1,0x3
    8000523e:	f9078793          	addi	a5,a5,-112
    80005242:	97a2                	add	a5,a5,s0
    80005244:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005248:	00148693          	addi	a3,s1,1
    8000524c:	068e                	slli	a3,a3,0x3
    8000524e:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005252:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005256:	01597663          	bgeu	s2,s5,80005262 <exec+0x250>
  sz = sz1;
    8000525a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000525e:	4a81                	li	s5,0
    80005260:	a059                	j	800052e6 <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005262:	e9040613          	addi	a2,s0,-368
    80005266:	85ca                	mv	a1,s2
    80005268:	855a                	mv	a0,s6
    8000526a:	ffffc097          	auipc	ra,0xffffc
    8000526e:	4ca080e7          	jalr	1226(ra) # 80001734 <copyout>
    80005272:	0a054963          	bltz	a0,80005324 <exec+0x312>
  p->trapframe->a1 = sp;
    80005276:	058bb783          	ld	a5,88(s7)
    8000527a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000527e:	de843783          	ld	a5,-536(s0)
    80005282:	0007c703          	lbu	a4,0(a5)
    80005286:	cf11                	beqz	a4,800052a2 <exec+0x290>
    80005288:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000528a:	02f00693          	li	a3,47
    8000528e:	a039                	j	8000529c <exec+0x28a>
      last = s+1;
    80005290:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005294:	0785                	addi	a5,a5,1
    80005296:	fff7c703          	lbu	a4,-1(a5)
    8000529a:	c701                	beqz	a4,800052a2 <exec+0x290>
    if(*s == '/')
    8000529c:	fed71ce3          	bne	a4,a3,80005294 <exec+0x282>
    800052a0:	bfc5                	j	80005290 <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    800052a2:	4641                	li	a2,16
    800052a4:	de843583          	ld	a1,-536(s0)
    800052a8:	158b8513          	addi	a0,s7,344
    800052ac:	ffffc097          	auipc	ra,0xffffc
    800052b0:	c38080e7          	jalr	-968(ra) # 80000ee4 <safestrcpy>
  oldpagetable = p->pagetable;
    800052b4:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    800052b8:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    800052bc:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800052c0:	058bb783          	ld	a5,88(s7)
    800052c4:	e6843703          	ld	a4,-408(s0)
    800052c8:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800052ca:	058bb783          	ld	a5,88(s7)
    800052ce:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800052d2:	85ea                	mv	a1,s10
    800052d4:	ffffd097          	auipc	ra,0xffffd
    800052d8:	9fe080e7          	jalr	-1538(ra) # 80001cd2 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800052dc:	0004851b          	sext.w	a0,s1
    800052e0:	b3f9                	j	800050ae <exec+0x9c>
    800052e2:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    800052e6:	df843583          	ld	a1,-520(s0)
    800052ea:	855a                	mv	a0,s6
    800052ec:	ffffd097          	auipc	ra,0xffffd
    800052f0:	9e6080e7          	jalr	-1562(ra) # 80001cd2 <proc_freepagetable>
  if(ip){
    800052f4:	da0a93e3          	bnez	s5,8000509a <exec+0x88>
  return -1;
    800052f8:	557d                	li	a0,-1
    800052fa:	bb55                	j	800050ae <exec+0x9c>
    800052fc:	df243c23          	sd	s2,-520(s0)
    80005300:	b7dd                	j	800052e6 <exec+0x2d4>
    80005302:	df243c23          	sd	s2,-520(s0)
    80005306:	b7c5                	j	800052e6 <exec+0x2d4>
    80005308:	df243c23          	sd	s2,-520(s0)
    8000530c:	bfe9                	j	800052e6 <exec+0x2d4>
    8000530e:	df243c23          	sd	s2,-520(s0)
    80005312:	bfd1                	j	800052e6 <exec+0x2d4>
  sz = sz1;
    80005314:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005318:	4a81                	li	s5,0
    8000531a:	b7f1                	j	800052e6 <exec+0x2d4>
  sz = sz1;
    8000531c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005320:	4a81                	li	s5,0
    80005322:	b7d1                	j	800052e6 <exec+0x2d4>
  sz = sz1;
    80005324:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005328:	4a81                	li	s5,0
    8000532a:	bf75                	j	800052e6 <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000532c:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005330:	e0843783          	ld	a5,-504(s0)
    80005334:	0017869b          	addiw	a3,a5,1
    80005338:	e0d43423          	sd	a3,-504(s0)
    8000533c:	e0043783          	ld	a5,-512(s0)
    80005340:	0387879b          	addiw	a5,a5,56
    80005344:	e8845703          	lhu	a4,-376(s0)
    80005348:	e0e6dfe3          	bge	a3,a4,80005166 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000534c:	2781                	sext.w	a5,a5
    8000534e:	e0f43023          	sd	a5,-512(s0)
    80005352:	03800713          	li	a4,56
    80005356:	86be                	mv	a3,a5
    80005358:	e1840613          	addi	a2,s0,-488
    8000535c:	4581                	li	a1,0
    8000535e:	8556                	mv	a0,s5
    80005360:	fffff097          	auipc	ra,0xfffff
    80005364:	a58080e7          	jalr	-1448(ra) # 80003db8 <readi>
    80005368:	03800793          	li	a5,56
    8000536c:	f6f51be3          	bne	a0,a5,800052e2 <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    80005370:	e1842783          	lw	a5,-488(s0)
    80005374:	4705                	li	a4,1
    80005376:	fae79de3          	bne	a5,a4,80005330 <exec+0x31e>
    if(ph.memsz < ph.filesz)
    8000537a:	e4043483          	ld	s1,-448(s0)
    8000537e:	e3843783          	ld	a5,-456(s0)
    80005382:	f6f4ede3          	bltu	s1,a5,800052fc <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005386:	e2843783          	ld	a5,-472(s0)
    8000538a:	94be                	add	s1,s1,a5
    8000538c:	f6f4ebe3          	bltu	s1,a5,80005302 <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    80005390:	de043703          	ld	a4,-544(s0)
    80005394:	8ff9                	and	a5,a5,a4
    80005396:	fbad                	bnez	a5,80005308 <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005398:	e1c42503          	lw	a0,-484(s0)
    8000539c:	00000097          	auipc	ra,0x0
    800053a0:	c5c080e7          	jalr	-932(ra) # 80004ff8 <flags2perm>
    800053a4:	86aa                	mv	a3,a0
    800053a6:	8626                	mv	a2,s1
    800053a8:	85ca                	mv	a1,s2
    800053aa:	855a                	mv	a0,s6
    800053ac:	ffffc097          	auipc	ra,0xffffc
    800053b0:	12c080e7          	jalr	300(ra) # 800014d8 <uvmalloc>
    800053b4:	dea43c23          	sd	a0,-520(s0)
    800053b8:	d939                	beqz	a0,8000530e <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800053ba:	e2843c03          	ld	s8,-472(s0)
    800053be:	e2042c83          	lw	s9,-480(s0)
    800053c2:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800053c6:	f60b83e3          	beqz	s7,8000532c <exec+0x31a>
    800053ca:	89de                	mv	s3,s7
    800053cc:	4481                	li	s1,0
    800053ce:	bb9d                	j	80005144 <exec+0x132>

00000000800053d0 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800053d0:	7179                	addi	sp,sp,-48
    800053d2:	f406                	sd	ra,40(sp)
    800053d4:	f022                	sd	s0,32(sp)
    800053d6:	ec26                	sd	s1,24(sp)
    800053d8:	e84a                	sd	s2,16(sp)
    800053da:	1800                	addi	s0,sp,48
    800053dc:	892e                	mv	s2,a1
    800053de:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800053e0:	fdc40593          	addi	a1,s0,-36
    800053e4:	ffffe097          	auipc	ra,0xffffe
    800053e8:	a8c080e7          	jalr	-1396(ra) # 80002e70 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800053ec:	fdc42703          	lw	a4,-36(s0)
    800053f0:	47bd                	li	a5,15
    800053f2:	02e7eb63          	bltu	a5,a4,80005428 <argfd+0x58>
    800053f6:	ffffc097          	auipc	ra,0xffffc
    800053fa:	77c080e7          	jalr	1916(ra) # 80001b72 <myproc>
    800053fe:	fdc42703          	lw	a4,-36(s0)
    80005402:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffdd13a>
    80005406:	078e                	slli	a5,a5,0x3
    80005408:	953e                	add	a0,a0,a5
    8000540a:	611c                	ld	a5,0(a0)
    8000540c:	c385                	beqz	a5,8000542c <argfd+0x5c>
    return -1;
  if(pfd)
    8000540e:	00090463          	beqz	s2,80005416 <argfd+0x46>
    *pfd = fd;
    80005412:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005416:	4501                	li	a0,0
  if(pf)
    80005418:	c091                	beqz	s1,8000541c <argfd+0x4c>
    *pf = f;
    8000541a:	e09c                	sd	a5,0(s1)
}
    8000541c:	70a2                	ld	ra,40(sp)
    8000541e:	7402                	ld	s0,32(sp)
    80005420:	64e2                	ld	s1,24(sp)
    80005422:	6942                	ld	s2,16(sp)
    80005424:	6145                	addi	sp,sp,48
    80005426:	8082                	ret
    return -1;
    80005428:	557d                	li	a0,-1
    8000542a:	bfcd                	j	8000541c <argfd+0x4c>
    8000542c:	557d                	li	a0,-1
    8000542e:	b7fd                	j	8000541c <argfd+0x4c>

0000000080005430 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005430:	1101                	addi	sp,sp,-32
    80005432:	ec06                	sd	ra,24(sp)
    80005434:	e822                	sd	s0,16(sp)
    80005436:	e426                	sd	s1,8(sp)
    80005438:	1000                	addi	s0,sp,32
    8000543a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000543c:	ffffc097          	auipc	ra,0xffffc
    80005440:	736080e7          	jalr	1846(ra) # 80001b72 <myproc>
    80005444:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005446:	0d050793          	addi	a5,a0,208
    8000544a:	4501                	li	a0,0
    8000544c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000544e:	6398                	ld	a4,0(a5)
    80005450:	cb19                	beqz	a4,80005466 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005452:	2505                	addiw	a0,a0,1
    80005454:	07a1                	addi	a5,a5,8
    80005456:	fed51ce3          	bne	a0,a3,8000544e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000545a:	557d                	li	a0,-1
}
    8000545c:	60e2                	ld	ra,24(sp)
    8000545e:	6442                	ld	s0,16(sp)
    80005460:	64a2                	ld	s1,8(sp)
    80005462:	6105                	addi	sp,sp,32
    80005464:	8082                	ret
      p->ofile[fd] = f;
    80005466:	01a50793          	addi	a5,a0,26
    8000546a:	078e                	slli	a5,a5,0x3
    8000546c:	963e                	add	a2,a2,a5
    8000546e:	e204                	sd	s1,0(a2)
      return fd;
    80005470:	b7f5                	j	8000545c <fdalloc+0x2c>

0000000080005472 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005472:	715d                	addi	sp,sp,-80
    80005474:	e486                	sd	ra,72(sp)
    80005476:	e0a2                	sd	s0,64(sp)
    80005478:	fc26                	sd	s1,56(sp)
    8000547a:	f84a                	sd	s2,48(sp)
    8000547c:	f44e                	sd	s3,40(sp)
    8000547e:	f052                	sd	s4,32(sp)
    80005480:	ec56                	sd	s5,24(sp)
    80005482:	e85a                	sd	s6,16(sp)
    80005484:	0880                	addi	s0,sp,80
    80005486:	8b2e                	mv	s6,a1
    80005488:	89b2                	mv	s3,a2
    8000548a:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000548c:	fb040593          	addi	a1,s0,-80
    80005490:	fffff097          	auipc	ra,0xfffff
    80005494:	e3e080e7          	jalr	-450(ra) # 800042ce <nameiparent>
    80005498:	84aa                	mv	s1,a0
    8000549a:	14050f63          	beqz	a0,800055f8 <create+0x186>
    return 0;

  ilock(dp);
    8000549e:	ffffe097          	auipc	ra,0xffffe
    800054a2:	666080e7          	jalr	1638(ra) # 80003b04 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800054a6:	4601                	li	a2,0
    800054a8:	fb040593          	addi	a1,s0,-80
    800054ac:	8526                	mv	a0,s1
    800054ae:	fffff097          	auipc	ra,0xfffff
    800054b2:	b3a080e7          	jalr	-1222(ra) # 80003fe8 <dirlookup>
    800054b6:	8aaa                	mv	s5,a0
    800054b8:	c931                	beqz	a0,8000550c <create+0x9a>
    iunlockput(dp);
    800054ba:	8526                	mv	a0,s1
    800054bc:	fffff097          	auipc	ra,0xfffff
    800054c0:	8aa080e7          	jalr	-1878(ra) # 80003d66 <iunlockput>
    ilock(ip);
    800054c4:	8556                	mv	a0,s5
    800054c6:	ffffe097          	auipc	ra,0xffffe
    800054ca:	63e080e7          	jalr	1598(ra) # 80003b04 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800054ce:	000b059b          	sext.w	a1,s6
    800054d2:	4789                	li	a5,2
    800054d4:	02f59563          	bne	a1,a5,800054fe <create+0x8c>
    800054d8:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdd164>
    800054dc:	37f9                	addiw	a5,a5,-2
    800054de:	17c2                	slli	a5,a5,0x30
    800054e0:	93c1                	srli	a5,a5,0x30
    800054e2:	4705                	li	a4,1
    800054e4:	00f76d63          	bltu	a4,a5,800054fe <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800054e8:	8556                	mv	a0,s5
    800054ea:	60a6                	ld	ra,72(sp)
    800054ec:	6406                	ld	s0,64(sp)
    800054ee:	74e2                	ld	s1,56(sp)
    800054f0:	7942                	ld	s2,48(sp)
    800054f2:	79a2                	ld	s3,40(sp)
    800054f4:	7a02                	ld	s4,32(sp)
    800054f6:	6ae2                	ld	s5,24(sp)
    800054f8:	6b42                	ld	s6,16(sp)
    800054fa:	6161                	addi	sp,sp,80
    800054fc:	8082                	ret
    iunlockput(ip);
    800054fe:	8556                	mv	a0,s5
    80005500:	fffff097          	auipc	ra,0xfffff
    80005504:	866080e7          	jalr	-1946(ra) # 80003d66 <iunlockput>
    return 0;
    80005508:	4a81                	li	s5,0
    8000550a:	bff9                	j	800054e8 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    8000550c:	85da                	mv	a1,s6
    8000550e:	4088                	lw	a0,0(s1)
    80005510:	ffffe097          	auipc	ra,0xffffe
    80005514:	456080e7          	jalr	1110(ra) # 80003966 <ialloc>
    80005518:	8a2a                	mv	s4,a0
    8000551a:	c539                	beqz	a0,80005568 <create+0xf6>
  ilock(ip);
    8000551c:	ffffe097          	auipc	ra,0xffffe
    80005520:	5e8080e7          	jalr	1512(ra) # 80003b04 <ilock>
  ip->major = major;
    80005524:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005528:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000552c:	4905                	li	s2,1
    8000552e:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005532:	8552                	mv	a0,s4
    80005534:	ffffe097          	auipc	ra,0xffffe
    80005538:	504080e7          	jalr	1284(ra) # 80003a38 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000553c:	000b059b          	sext.w	a1,s6
    80005540:	03258b63          	beq	a1,s2,80005576 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005544:	004a2603          	lw	a2,4(s4)
    80005548:	fb040593          	addi	a1,s0,-80
    8000554c:	8526                	mv	a0,s1
    8000554e:	fffff097          	auipc	ra,0xfffff
    80005552:	cb0080e7          	jalr	-848(ra) # 800041fe <dirlink>
    80005556:	06054f63          	bltz	a0,800055d4 <create+0x162>
  iunlockput(dp);
    8000555a:	8526                	mv	a0,s1
    8000555c:	fffff097          	auipc	ra,0xfffff
    80005560:	80a080e7          	jalr	-2038(ra) # 80003d66 <iunlockput>
  return ip;
    80005564:	8ad2                	mv	s5,s4
    80005566:	b749                	j	800054e8 <create+0x76>
    iunlockput(dp);
    80005568:	8526                	mv	a0,s1
    8000556a:	ffffe097          	auipc	ra,0xffffe
    8000556e:	7fc080e7          	jalr	2044(ra) # 80003d66 <iunlockput>
    return 0;
    80005572:	8ad2                	mv	s5,s4
    80005574:	bf95                	j	800054e8 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005576:	004a2603          	lw	a2,4(s4)
    8000557a:	00003597          	auipc	a1,0x3
    8000557e:	2ae58593          	addi	a1,a1,686 # 80008828 <syscalls+0x2c8>
    80005582:	8552                	mv	a0,s4
    80005584:	fffff097          	auipc	ra,0xfffff
    80005588:	c7a080e7          	jalr	-902(ra) # 800041fe <dirlink>
    8000558c:	04054463          	bltz	a0,800055d4 <create+0x162>
    80005590:	40d0                	lw	a2,4(s1)
    80005592:	00003597          	auipc	a1,0x3
    80005596:	29e58593          	addi	a1,a1,670 # 80008830 <syscalls+0x2d0>
    8000559a:	8552                	mv	a0,s4
    8000559c:	fffff097          	auipc	ra,0xfffff
    800055a0:	c62080e7          	jalr	-926(ra) # 800041fe <dirlink>
    800055a4:	02054863          	bltz	a0,800055d4 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    800055a8:	004a2603          	lw	a2,4(s4)
    800055ac:	fb040593          	addi	a1,s0,-80
    800055b0:	8526                	mv	a0,s1
    800055b2:	fffff097          	auipc	ra,0xfffff
    800055b6:	c4c080e7          	jalr	-948(ra) # 800041fe <dirlink>
    800055ba:	00054d63          	bltz	a0,800055d4 <create+0x162>
    dp->nlink++;  // for ".."
    800055be:	04a4d783          	lhu	a5,74(s1)
    800055c2:	2785                	addiw	a5,a5,1
    800055c4:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800055c8:	8526                	mv	a0,s1
    800055ca:	ffffe097          	auipc	ra,0xffffe
    800055ce:	46e080e7          	jalr	1134(ra) # 80003a38 <iupdate>
    800055d2:	b761                	j	8000555a <create+0xe8>
  ip->nlink = 0;
    800055d4:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800055d8:	8552                	mv	a0,s4
    800055da:	ffffe097          	auipc	ra,0xffffe
    800055de:	45e080e7          	jalr	1118(ra) # 80003a38 <iupdate>
  iunlockput(ip);
    800055e2:	8552                	mv	a0,s4
    800055e4:	ffffe097          	auipc	ra,0xffffe
    800055e8:	782080e7          	jalr	1922(ra) # 80003d66 <iunlockput>
  iunlockput(dp);
    800055ec:	8526                	mv	a0,s1
    800055ee:	ffffe097          	auipc	ra,0xffffe
    800055f2:	778080e7          	jalr	1912(ra) # 80003d66 <iunlockput>
  return 0;
    800055f6:	bdcd                	j	800054e8 <create+0x76>
    return 0;
    800055f8:	8aaa                	mv	s5,a0
    800055fa:	b5fd                	j	800054e8 <create+0x76>

00000000800055fc <sys_dup>:
{
    800055fc:	7179                	addi	sp,sp,-48
    800055fe:	f406                	sd	ra,40(sp)
    80005600:	f022                	sd	s0,32(sp)
    80005602:	ec26                	sd	s1,24(sp)
    80005604:	e84a                	sd	s2,16(sp)
    80005606:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005608:	fd840613          	addi	a2,s0,-40
    8000560c:	4581                	li	a1,0
    8000560e:	4501                	li	a0,0
    80005610:	00000097          	auipc	ra,0x0
    80005614:	dc0080e7          	jalr	-576(ra) # 800053d0 <argfd>
    return -1;
    80005618:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000561a:	02054363          	bltz	a0,80005640 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    8000561e:	fd843903          	ld	s2,-40(s0)
    80005622:	854a                	mv	a0,s2
    80005624:	00000097          	auipc	ra,0x0
    80005628:	e0c080e7          	jalr	-500(ra) # 80005430 <fdalloc>
    8000562c:	84aa                	mv	s1,a0
    return -1;
    8000562e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005630:	00054863          	bltz	a0,80005640 <sys_dup+0x44>
  filedup(f);
    80005634:	854a                	mv	a0,s2
    80005636:	fffff097          	auipc	ra,0xfffff
    8000563a:	310080e7          	jalr	784(ra) # 80004946 <filedup>
  return fd;
    8000563e:	87a6                	mv	a5,s1
}
    80005640:	853e                	mv	a0,a5
    80005642:	70a2                	ld	ra,40(sp)
    80005644:	7402                	ld	s0,32(sp)
    80005646:	64e2                	ld	s1,24(sp)
    80005648:	6942                	ld	s2,16(sp)
    8000564a:	6145                	addi	sp,sp,48
    8000564c:	8082                	ret

000000008000564e <sys_read>:
{
    8000564e:	7179                	addi	sp,sp,-48
    80005650:	f406                	sd	ra,40(sp)
    80005652:	f022                	sd	s0,32(sp)
    80005654:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005656:	fd840593          	addi	a1,s0,-40
    8000565a:	4505                	li	a0,1
    8000565c:	ffffe097          	auipc	ra,0xffffe
    80005660:	834080e7          	jalr	-1996(ra) # 80002e90 <argaddr>
  argint(2, &n);
    80005664:	fe440593          	addi	a1,s0,-28
    80005668:	4509                	li	a0,2
    8000566a:	ffffe097          	auipc	ra,0xffffe
    8000566e:	806080e7          	jalr	-2042(ra) # 80002e70 <argint>
  if(argfd(0, 0, &f) < 0)
    80005672:	fe840613          	addi	a2,s0,-24
    80005676:	4581                	li	a1,0
    80005678:	4501                	li	a0,0
    8000567a:	00000097          	auipc	ra,0x0
    8000567e:	d56080e7          	jalr	-682(ra) # 800053d0 <argfd>
    80005682:	87aa                	mv	a5,a0
    return -1;
    80005684:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005686:	0007cc63          	bltz	a5,8000569e <sys_read+0x50>
  return fileread(f, p, n);
    8000568a:	fe442603          	lw	a2,-28(s0)
    8000568e:	fd843583          	ld	a1,-40(s0)
    80005692:	fe843503          	ld	a0,-24(s0)
    80005696:	fffff097          	auipc	ra,0xfffff
    8000569a:	43c080e7          	jalr	1084(ra) # 80004ad2 <fileread>
}
    8000569e:	70a2                	ld	ra,40(sp)
    800056a0:	7402                	ld	s0,32(sp)
    800056a2:	6145                	addi	sp,sp,48
    800056a4:	8082                	ret

00000000800056a6 <sys_write>:
{
    800056a6:	7179                	addi	sp,sp,-48
    800056a8:	f406                	sd	ra,40(sp)
    800056aa:	f022                	sd	s0,32(sp)
    800056ac:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800056ae:	fd840593          	addi	a1,s0,-40
    800056b2:	4505                	li	a0,1
    800056b4:	ffffd097          	auipc	ra,0xffffd
    800056b8:	7dc080e7          	jalr	2012(ra) # 80002e90 <argaddr>
  argint(2, &n);
    800056bc:	fe440593          	addi	a1,s0,-28
    800056c0:	4509                	li	a0,2
    800056c2:	ffffd097          	auipc	ra,0xffffd
    800056c6:	7ae080e7          	jalr	1966(ra) # 80002e70 <argint>
  if(argfd(0, 0, &f) < 0)
    800056ca:	fe840613          	addi	a2,s0,-24
    800056ce:	4581                	li	a1,0
    800056d0:	4501                	li	a0,0
    800056d2:	00000097          	auipc	ra,0x0
    800056d6:	cfe080e7          	jalr	-770(ra) # 800053d0 <argfd>
    800056da:	87aa                	mv	a5,a0
    return -1;
    800056dc:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800056de:	0007cc63          	bltz	a5,800056f6 <sys_write+0x50>
  return filewrite(f, p, n);
    800056e2:	fe442603          	lw	a2,-28(s0)
    800056e6:	fd843583          	ld	a1,-40(s0)
    800056ea:	fe843503          	ld	a0,-24(s0)
    800056ee:	fffff097          	auipc	ra,0xfffff
    800056f2:	4a6080e7          	jalr	1190(ra) # 80004b94 <filewrite>
}
    800056f6:	70a2                	ld	ra,40(sp)
    800056f8:	7402                	ld	s0,32(sp)
    800056fa:	6145                	addi	sp,sp,48
    800056fc:	8082                	ret

00000000800056fe <sys_close>:
{
    800056fe:	1101                	addi	sp,sp,-32
    80005700:	ec06                	sd	ra,24(sp)
    80005702:	e822                	sd	s0,16(sp)
    80005704:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005706:	fe040613          	addi	a2,s0,-32
    8000570a:	fec40593          	addi	a1,s0,-20
    8000570e:	4501                	li	a0,0
    80005710:	00000097          	auipc	ra,0x0
    80005714:	cc0080e7          	jalr	-832(ra) # 800053d0 <argfd>
    return -1;
    80005718:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000571a:	02054463          	bltz	a0,80005742 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000571e:	ffffc097          	auipc	ra,0xffffc
    80005722:	454080e7          	jalr	1108(ra) # 80001b72 <myproc>
    80005726:	fec42783          	lw	a5,-20(s0)
    8000572a:	07e9                	addi	a5,a5,26
    8000572c:	078e                	slli	a5,a5,0x3
    8000572e:	953e                	add	a0,a0,a5
    80005730:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005734:	fe043503          	ld	a0,-32(s0)
    80005738:	fffff097          	auipc	ra,0xfffff
    8000573c:	260080e7          	jalr	608(ra) # 80004998 <fileclose>
  return 0;
    80005740:	4781                	li	a5,0
}
    80005742:	853e                	mv	a0,a5
    80005744:	60e2                	ld	ra,24(sp)
    80005746:	6442                	ld	s0,16(sp)
    80005748:	6105                	addi	sp,sp,32
    8000574a:	8082                	ret

000000008000574c <sys_fstat>:
{
    8000574c:	1101                	addi	sp,sp,-32
    8000574e:	ec06                	sd	ra,24(sp)
    80005750:	e822                	sd	s0,16(sp)
    80005752:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005754:	fe040593          	addi	a1,s0,-32
    80005758:	4505                	li	a0,1
    8000575a:	ffffd097          	auipc	ra,0xffffd
    8000575e:	736080e7          	jalr	1846(ra) # 80002e90 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005762:	fe840613          	addi	a2,s0,-24
    80005766:	4581                	li	a1,0
    80005768:	4501                	li	a0,0
    8000576a:	00000097          	auipc	ra,0x0
    8000576e:	c66080e7          	jalr	-922(ra) # 800053d0 <argfd>
    80005772:	87aa                	mv	a5,a0
    return -1;
    80005774:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005776:	0007ca63          	bltz	a5,8000578a <sys_fstat+0x3e>
  return filestat(f, st);
    8000577a:	fe043583          	ld	a1,-32(s0)
    8000577e:	fe843503          	ld	a0,-24(s0)
    80005782:	fffff097          	auipc	ra,0xfffff
    80005786:	2de080e7          	jalr	734(ra) # 80004a60 <filestat>
}
    8000578a:	60e2                	ld	ra,24(sp)
    8000578c:	6442                	ld	s0,16(sp)
    8000578e:	6105                	addi	sp,sp,32
    80005790:	8082                	ret

0000000080005792 <sys_link>:
{
    80005792:	7169                	addi	sp,sp,-304
    80005794:	f606                	sd	ra,296(sp)
    80005796:	f222                	sd	s0,288(sp)
    80005798:	ee26                	sd	s1,280(sp)
    8000579a:	ea4a                	sd	s2,272(sp)
    8000579c:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000579e:	08000613          	li	a2,128
    800057a2:	ed040593          	addi	a1,s0,-304
    800057a6:	4501                	li	a0,0
    800057a8:	ffffd097          	auipc	ra,0xffffd
    800057ac:	708080e7          	jalr	1800(ra) # 80002eb0 <argstr>
    return -1;
    800057b0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057b2:	10054e63          	bltz	a0,800058ce <sys_link+0x13c>
    800057b6:	08000613          	li	a2,128
    800057ba:	f5040593          	addi	a1,s0,-176
    800057be:	4505                	li	a0,1
    800057c0:	ffffd097          	auipc	ra,0xffffd
    800057c4:	6f0080e7          	jalr	1776(ra) # 80002eb0 <argstr>
    return -1;
    800057c8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057ca:	10054263          	bltz	a0,800058ce <sys_link+0x13c>
  begin_op();
    800057ce:	fffff097          	auipc	ra,0xfffff
    800057d2:	d02080e7          	jalr	-766(ra) # 800044d0 <begin_op>
  if((ip = namei(old)) == 0){
    800057d6:	ed040513          	addi	a0,s0,-304
    800057da:	fffff097          	auipc	ra,0xfffff
    800057de:	ad6080e7          	jalr	-1322(ra) # 800042b0 <namei>
    800057e2:	84aa                	mv	s1,a0
    800057e4:	c551                	beqz	a0,80005870 <sys_link+0xde>
  ilock(ip);
    800057e6:	ffffe097          	auipc	ra,0xffffe
    800057ea:	31e080e7          	jalr	798(ra) # 80003b04 <ilock>
  if(ip->type == T_DIR){
    800057ee:	04449703          	lh	a4,68(s1)
    800057f2:	4785                	li	a5,1
    800057f4:	08f70463          	beq	a4,a5,8000587c <sys_link+0xea>
  ip->nlink++;
    800057f8:	04a4d783          	lhu	a5,74(s1)
    800057fc:	2785                	addiw	a5,a5,1
    800057fe:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005802:	8526                	mv	a0,s1
    80005804:	ffffe097          	auipc	ra,0xffffe
    80005808:	234080e7          	jalr	564(ra) # 80003a38 <iupdate>
  iunlock(ip);
    8000580c:	8526                	mv	a0,s1
    8000580e:	ffffe097          	auipc	ra,0xffffe
    80005812:	3b8080e7          	jalr	952(ra) # 80003bc6 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005816:	fd040593          	addi	a1,s0,-48
    8000581a:	f5040513          	addi	a0,s0,-176
    8000581e:	fffff097          	auipc	ra,0xfffff
    80005822:	ab0080e7          	jalr	-1360(ra) # 800042ce <nameiparent>
    80005826:	892a                	mv	s2,a0
    80005828:	c935                	beqz	a0,8000589c <sys_link+0x10a>
  ilock(dp);
    8000582a:	ffffe097          	auipc	ra,0xffffe
    8000582e:	2da080e7          	jalr	730(ra) # 80003b04 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005832:	00092703          	lw	a4,0(s2)
    80005836:	409c                	lw	a5,0(s1)
    80005838:	04f71d63          	bne	a4,a5,80005892 <sys_link+0x100>
    8000583c:	40d0                	lw	a2,4(s1)
    8000583e:	fd040593          	addi	a1,s0,-48
    80005842:	854a                	mv	a0,s2
    80005844:	fffff097          	auipc	ra,0xfffff
    80005848:	9ba080e7          	jalr	-1606(ra) # 800041fe <dirlink>
    8000584c:	04054363          	bltz	a0,80005892 <sys_link+0x100>
  iunlockput(dp);
    80005850:	854a                	mv	a0,s2
    80005852:	ffffe097          	auipc	ra,0xffffe
    80005856:	514080e7          	jalr	1300(ra) # 80003d66 <iunlockput>
  iput(ip);
    8000585a:	8526                	mv	a0,s1
    8000585c:	ffffe097          	auipc	ra,0xffffe
    80005860:	462080e7          	jalr	1122(ra) # 80003cbe <iput>
  end_op();
    80005864:	fffff097          	auipc	ra,0xfffff
    80005868:	cea080e7          	jalr	-790(ra) # 8000454e <end_op>
  return 0;
    8000586c:	4781                	li	a5,0
    8000586e:	a085                	j	800058ce <sys_link+0x13c>
    end_op();
    80005870:	fffff097          	auipc	ra,0xfffff
    80005874:	cde080e7          	jalr	-802(ra) # 8000454e <end_op>
    return -1;
    80005878:	57fd                	li	a5,-1
    8000587a:	a891                	j	800058ce <sys_link+0x13c>
    iunlockput(ip);
    8000587c:	8526                	mv	a0,s1
    8000587e:	ffffe097          	auipc	ra,0xffffe
    80005882:	4e8080e7          	jalr	1256(ra) # 80003d66 <iunlockput>
    end_op();
    80005886:	fffff097          	auipc	ra,0xfffff
    8000588a:	cc8080e7          	jalr	-824(ra) # 8000454e <end_op>
    return -1;
    8000588e:	57fd                	li	a5,-1
    80005890:	a83d                	j	800058ce <sys_link+0x13c>
    iunlockput(dp);
    80005892:	854a                	mv	a0,s2
    80005894:	ffffe097          	auipc	ra,0xffffe
    80005898:	4d2080e7          	jalr	1234(ra) # 80003d66 <iunlockput>
  ilock(ip);
    8000589c:	8526                	mv	a0,s1
    8000589e:	ffffe097          	auipc	ra,0xffffe
    800058a2:	266080e7          	jalr	614(ra) # 80003b04 <ilock>
  ip->nlink--;
    800058a6:	04a4d783          	lhu	a5,74(s1)
    800058aa:	37fd                	addiw	a5,a5,-1
    800058ac:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800058b0:	8526                	mv	a0,s1
    800058b2:	ffffe097          	auipc	ra,0xffffe
    800058b6:	186080e7          	jalr	390(ra) # 80003a38 <iupdate>
  iunlockput(ip);
    800058ba:	8526                	mv	a0,s1
    800058bc:	ffffe097          	auipc	ra,0xffffe
    800058c0:	4aa080e7          	jalr	1194(ra) # 80003d66 <iunlockput>
  end_op();
    800058c4:	fffff097          	auipc	ra,0xfffff
    800058c8:	c8a080e7          	jalr	-886(ra) # 8000454e <end_op>
  return -1;
    800058cc:	57fd                	li	a5,-1
}
    800058ce:	853e                	mv	a0,a5
    800058d0:	70b2                	ld	ra,296(sp)
    800058d2:	7412                	ld	s0,288(sp)
    800058d4:	64f2                	ld	s1,280(sp)
    800058d6:	6952                	ld	s2,272(sp)
    800058d8:	6155                	addi	sp,sp,304
    800058da:	8082                	ret

00000000800058dc <sys_unlink>:
{
    800058dc:	7151                	addi	sp,sp,-240
    800058de:	f586                	sd	ra,232(sp)
    800058e0:	f1a2                	sd	s0,224(sp)
    800058e2:	eda6                	sd	s1,216(sp)
    800058e4:	e9ca                	sd	s2,208(sp)
    800058e6:	e5ce                	sd	s3,200(sp)
    800058e8:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800058ea:	08000613          	li	a2,128
    800058ee:	f3040593          	addi	a1,s0,-208
    800058f2:	4501                	li	a0,0
    800058f4:	ffffd097          	auipc	ra,0xffffd
    800058f8:	5bc080e7          	jalr	1468(ra) # 80002eb0 <argstr>
    800058fc:	18054163          	bltz	a0,80005a7e <sys_unlink+0x1a2>
  begin_op();
    80005900:	fffff097          	auipc	ra,0xfffff
    80005904:	bd0080e7          	jalr	-1072(ra) # 800044d0 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005908:	fb040593          	addi	a1,s0,-80
    8000590c:	f3040513          	addi	a0,s0,-208
    80005910:	fffff097          	auipc	ra,0xfffff
    80005914:	9be080e7          	jalr	-1602(ra) # 800042ce <nameiparent>
    80005918:	84aa                	mv	s1,a0
    8000591a:	c979                	beqz	a0,800059f0 <sys_unlink+0x114>
  ilock(dp);
    8000591c:	ffffe097          	auipc	ra,0xffffe
    80005920:	1e8080e7          	jalr	488(ra) # 80003b04 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005924:	00003597          	auipc	a1,0x3
    80005928:	f0458593          	addi	a1,a1,-252 # 80008828 <syscalls+0x2c8>
    8000592c:	fb040513          	addi	a0,s0,-80
    80005930:	ffffe097          	auipc	ra,0xffffe
    80005934:	69e080e7          	jalr	1694(ra) # 80003fce <namecmp>
    80005938:	14050a63          	beqz	a0,80005a8c <sys_unlink+0x1b0>
    8000593c:	00003597          	auipc	a1,0x3
    80005940:	ef458593          	addi	a1,a1,-268 # 80008830 <syscalls+0x2d0>
    80005944:	fb040513          	addi	a0,s0,-80
    80005948:	ffffe097          	auipc	ra,0xffffe
    8000594c:	686080e7          	jalr	1670(ra) # 80003fce <namecmp>
    80005950:	12050e63          	beqz	a0,80005a8c <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005954:	f2c40613          	addi	a2,s0,-212
    80005958:	fb040593          	addi	a1,s0,-80
    8000595c:	8526                	mv	a0,s1
    8000595e:	ffffe097          	auipc	ra,0xffffe
    80005962:	68a080e7          	jalr	1674(ra) # 80003fe8 <dirlookup>
    80005966:	892a                	mv	s2,a0
    80005968:	12050263          	beqz	a0,80005a8c <sys_unlink+0x1b0>
  ilock(ip);
    8000596c:	ffffe097          	auipc	ra,0xffffe
    80005970:	198080e7          	jalr	408(ra) # 80003b04 <ilock>
  if(ip->nlink < 1)
    80005974:	04a91783          	lh	a5,74(s2)
    80005978:	08f05263          	blez	a5,800059fc <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000597c:	04491703          	lh	a4,68(s2)
    80005980:	4785                	li	a5,1
    80005982:	08f70563          	beq	a4,a5,80005a0c <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005986:	4641                	li	a2,16
    80005988:	4581                	li	a1,0
    8000598a:	fc040513          	addi	a0,s0,-64
    8000598e:	ffffb097          	auipc	ra,0xffffb
    80005992:	40c080e7          	jalr	1036(ra) # 80000d9a <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005996:	4741                	li	a4,16
    80005998:	f2c42683          	lw	a3,-212(s0)
    8000599c:	fc040613          	addi	a2,s0,-64
    800059a0:	4581                	li	a1,0
    800059a2:	8526                	mv	a0,s1
    800059a4:	ffffe097          	auipc	ra,0xffffe
    800059a8:	50c080e7          	jalr	1292(ra) # 80003eb0 <writei>
    800059ac:	47c1                	li	a5,16
    800059ae:	0af51563          	bne	a0,a5,80005a58 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800059b2:	04491703          	lh	a4,68(s2)
    800059b6:	4785                	li	a5,1
    800059b8:	0af70863          	beq	a4,a5,80005a68 <sys_unlink+0x18c>
  iunlockput(dp);
    800059bc:	8526                	mv	a0,s1
    800059be:	ffffe097          	auipc	ra,0xffffe
    800059c2:	3a8080e7          	jalr	936(ra) # 80003d66 <iunlockput>
  ip->nlink--;
    800059c6:	04a95783          	lhu	a5,74(s2)
    800059ca:	37fd                	addiw	a5,a5,-1
    800059cc:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800059d0:	854a                	mv	a0,s2
    800059d2:	ffffe097          	auipc	ra,0xffffe
    800059d6:	066080e7          	jalr	102(ra) # 80003a38 <iupdate>
  iunlockput(ip);
    800059da:	854a                	mv	a0,s2
    800059dc:	ffffe097          	auipc	ra,0xffffe
    800059e0:	38a080e7          	jalr	906(ra) # 80003d66 <iunlockput>
  end_op();
    800059e4:	fffff097          	auipc	ra,0xfffff
    800059e8:	b6a080e7          	jalr	-1174(ra) # 8000454e <end_op>
  return 0;
    800059ec:	4501                	li	a0,0
    800059ee:	a84d                	j	80005aa0 <sys_unlink+0x1c4>
    end_op();
    800059f0:	fffff097          	auipc	ra,0xfffff
    800059f4:	b5e080e7          	jalr	-1186(ra) # 8000454e <end_op>
    return -1;
    800059f8:	557d                	li	a0,-1
    800059fa:	a05d                	j	80005aa0 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800059fc:	00003517          	auipc	a0,0x3
    80005a00:	e3c50513          	addi	a0,a0,-452 # 80008838 <syscalls+0x2d8>
    80005a04:	ffffb097          	auipc	ra,0xffffb
    80005a08:	b3c080e7          	jalr	-1220(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a0c:	04c92703          	lw	a4,76(s2)
    80005a10:	02000793          	li	a5,32
    80005a14:	f6e7f9e3          	bgeu	a5,a4,80005986 <sys_unlink+0xaa>
    80005a18:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a1c:	4741                	li	a4,16
    80005a1e:	86ce                	mv	a3,s3
    80005a20:	f1840613          	addi	a2,s0,-232
    80005a24:	4581                	li	a1,0
    80005a26:	854a                	mv	a0,s2
    80005a28:	ffffe097          	auipc	ra,0xffffe
    80005a2c:	390080e7          	jalr	912(ra) # 80003db8 <readi>
    80005a30:	47c1                	li	a5,16
    80005a32:	00f51b63          	bne	a0,a5,80005a48 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005a36:	f1845783          	lhu	a5,-232(s0)
    80005a3a:	e7a1                	bnez	a5,80005a82 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a3c:	29c1                	addiw	s3,s3,16
    80005a3e:	04c92783          	lw	a5,76(s2)
    80005a42:	fcf9ede3          	bltu	s3,a5,80005a1c <sys_unlink+0x140>
    80005a46:	b781                	j	80005986 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005a48:	00003517          	auipc	a0,0x3
    80005a4c:	e0850513          	addi	a0,a0,-504 # 80008850 <syscalls+0x2f0>
    80005a50:	ffffb097          	auipc	ra,0xffffb
    80005a54:	af0080e7          	jalr	-1296(ra) # 80000540 <panic>
    panic("unlink: writei");
    80005a58:	00003517          	auipc	a0,0x3
    80005a5c:	e1050513          	addi	a0,a0,-496 # 80008868 <syscalls+0x308>
    80005a60:	ffffb097          	auipc	ra,0xffffb
    80005a64:	ae0080e7          	jalr	-1312(ra) # 80000540 <panic>
    dp->nlink--;
    80005a68:	04a4d783          	lhu	a5,74(s1)
    80005a6c:	37fd                	addiw	a5,a5,-1
    80005a6e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005a72:	8526                	mv	a0,s1
    80005a74:	ffffe097          	auipc	ra,0xffffe
    80005a78:	fc4080e7          	jalr	-60(ra) # 80003a38 <iupdate>
    80005a7c:	b781                	j	800059bc <sys_unlink+0xe0>
    return -1;
    80005a7e:	557d                	li	a0,-1
    80005a80:	a005                	j	80005aa0 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005a82:	854a                	mv	a0,s2
    80005a84:	ffffe097          	auipc	ra,0xffffe
    80005a88:	2e2080e7          	jalr	738(ra) # 80003d66 <iunlockput>
  iunlockput(dp);
    80005a8c:	8526                	mv	a0,s1
    80005a8e:	ffffe097          	auipc	ra,0xffffe
    80005a92:	2d8080e7          	jalr	728(ra) # 80003d66 <iunlockput>
  end_op();
    80005a96:	fffff097          	auipc	ra,0xfffff
    80005a9a:	ab8080e7          	jalr	-1352(ra) # 8000454e <end_op>
  return -1;
    80005a9e:	557d                	li	a0,-1
}
    80005aa0:	70ae                	ld	ra,232(sp)
    80005aa2:	740e                	ld	s0,224(sp)
    80005aa4:	64ee                	ld	s1,216(sp)
    80005aa6:	694e                	ld	s2,208(sp)
    80005aa8:	69ae                	ld	s3,200(sp)
    80005aaa:	616d                	addi	sp,sp,240
    80005aac:	8082                	ret

0000000080005aae <sys_open>:

uint64
sys_open(void)
{
    80005aae:	7131                	addi	sp,sp,-192
    80005ab0:	fd06                	sd	ra,184(sp)
    80005ab2:	f922                	sd	s0,176(sp)
    80005ab4:	f526                	sd	s1,168(sp)
    80005ab6:	f14a                	sd	s2,160(sp)
    80005ab8:	ed4e                	sd	s3,152(sp)
    80005aba:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005abc:	f4c40593          	addi	a1,s0,-180
    80005ac0:	4505                	li	a0,1
    80005ac2:	ffffd097          	auipc	ra,0xffffd
    80005ac6:	3ae080e7          	jalr	942(ra) # 80002e70 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005aca:	08000613          	li	a2,128
    80005ace:	f5040593          	addi	a1,s0,-176
    80005ad2:	4501                	li	a0,0
    80005ad4:	ffffd097          	auipc	ra,0xffffd
    80005ad8:	3dc080e7          	jalr	988(ra) # 80002eb0 <argstr>
    80005adc:	87aa                	mv	a5,a0
    return -1;
    80005ade:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005ae0:	0a07c963          	bltz	a5,80005b92 <sys_open+0xe4>

  begin_op();
    80005ae4:	fffff097          	auipc	ra,0xfffff
    80005ae8:	9ec080e7          	jalr	-1556(ra) # 800044d0 <begin_op>

  if(omode & O_CREATE){
    80005aec:	f4c42783          	lw	a5,-180(s0)
    80005af0:	2007f793          	andi	a5,a5,512
    80005af4:	cfc5                	beqz	a5,80005bac <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005af6:	4681                	li	a3,0
    80005af8:	4601                	li	a2,0
    80005afa:	4589                	li	a1,2
    80005afc:	f5040513          	addi	a0,s0,-176
    80005b00:	00000097          	auipc	ra,0x0
    80005b04:	972080e7          	jalr	-1678(ra) # 80005472 <create>
    80005b08:	84aa                	mv	s1,a0
    if(ip == 0){
    80005b0a:	c959                	beqz	a0,80005ba0 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005b0c:	04449703          	lh	a4,68(s1)
    80005b10:	478d                	li	a5,3
    80005b12:	00f71763          	bne	a4,a5,80005b20 <sys_open+0x72>
    80005b16:	0464d703          	lhu	a4,70(s1)
    80005b1a:	47a5                	li	a5,9
    80005b1c:	0ce7ed63          	bltu	a5,a4,80005bf6 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005b20:	fffff097          	auipc	ra,0xfffff
    80005b24:	dbc080e7          	jalr	-580(ra) # 800048dc <filealloc>
    80005b28:	89aa                	mv	s3,a0
    80005b2a:	10050363          	beqz	a0,80005c30 <sys_open+0x182>
    80005b2e:	00000097          	auipc	ra,0x0
    80005b32:	902080e7          	jalr	-1790(ra) # 80005430 <fdalloc>
    80005b36:	892a                	mv	s2,a0
    80005b38:	0e054763          	bltz	a0,80005c26 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005b3c:	04449703          	lh	a4,68(s1)
    80005b40:	478d                	li	a5,3
    80005b42:	0cf70563          	beq	a4,a5,80005c0c <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005b46:	4789                	li	a5,2
    80005b48:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005b4c:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005b50:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005b54:	f4c42783          	lw	a5,-180(s0)
    80005b58:	0017c713          	xori	a4,a5,1
    80005b5c:	8b05                	andi	a4,a4,1
    80005b5e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005b62:	0037f713          	andi	a4,a5,3
    80005b66:	00e03733          	snez	a4,a4
    80005b6a:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005b6e:	4007f793          	andi	a5,a5,1024
    80005b72:	c791                	beqz	a5,80005b7e <sys_open+0xd0>
    80005b74:	04449703          	lh	a4,68(s1)
    80005b78:	4789                	li	a5,2
    80005b7a:	0af70063          	beq	a4,a5,80005c1a <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005b7e:	8526                	mv	a0,s1
    80005b80:	ffffe097          	auipc	ra,0xffffe
    80005b84:	046080e7          	jalr	70(ra) # 80003bc6 <iunlock>
  end_op();
    80005b88:	fffff097          	auipc	ra,0xfffff
    80005b8c:	9c6080e7          	jalr	-1594(ra) # 8000454e <end_op>

  return fd;
    80005b90:	854a                	mv	a0,s2
}
    80005b92:	70ea                	ld	ra,184(sp)
    80005b94:	744a                	ld	s0,176(sp)
    80005b96:	74aa                	ld	s1,168(sp)
    80005b98:	790a                	ld	s2,160(sp)
    80005b9a:	69ea                	ld	s3,152(sp)
    80005b9c:	6129                	addi	sp,sp,192
    80005b9e:	8082                	ret
      end_op();
    80005ba0:	fffff097          	auipc	ra,0xfffff
    80005ba4:	9ae080e7          	jalr	-1618(ra) # 8000454e <end_op>
      return -1;
    80005ba8:	557d                	li	a0,-1
    80005baa:	b7e5                	j	80005b92 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005bac:	f5040513          	addi	a0,s0,-176
    80005bb0:	ffffe097          	auipc	ra,0xffffe
    80005bb4:	700080e7          	jalr	1792(ra) # 800042b0 <namei>
    80005bb8:	84aa                	mv	s1,a0
    80005bba:	c905                	beqz	a0,80005bea <sys_open+0x13c>
    ilock(ip);
    80005bbc:	ffffe097          	auipc	ra,0xffffe
    80005bc0:	f48080e7          	jalr	-184(ra) # 80003b04 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005bc4:	04449703          	lh	a4,68(s1)
    80005bc8:	4785                	li	a5,1
    80005bca:	f4f711e3          	bne	a4,a5,80005b0c <sys_open+0x5e>
    80005bce:	f4c42783          	lw	a5,-180(s0)
    80005bd2:	d7b9                	beqz	a5,80005b20 <sys_open+0x72>
      iunlockput(ip);
    80005bd4:	8526                	mv	a0,s1
    80005bd6:	ffffe097          	auipc	ra,0xffffe
    80005bda:	190080e7          	jalr	400(ra) # 80003d66 <iunlockput>
      end_op();
    80005bde:	fffff097          	auipc	ra,0xfffff
    80005be2:	970080e7          	jalr	-1680(ra) # 8000454e <end_op>
      return -1;
    80005be6:	557d                	li	a0,-1
    80005be8:	b76d                	j	80005b92 <sys_open+0xe4>
      end_op();
    80005bea:	fffff097          	auipc	ra,0xfffff
    80005bee:	964080e7          	jalr	-1692(ra) # 8000454e <end_op>
      return -1;
    80005bf2:	557d                	li	a0,-1
    80005bf4:	bf79                	j	80005b92 <sys_open+0xe4>
    iunlockput(ip);
    80005bf6:	8526                	mv	a0,s1
    80005bf8:	ffffe097          	auipc	ra,0xffffe
    80005bfc:	16e080e7          	jalr	366(ra) # 80003d66 <iunlockput>
    end_op();
    80005c00:	fffff097          	auipc	ra,0xfffff
    80005c04:	94e080e7          	jalr	-1714(ra) # 8000454e <end_op>
    return -1;
    80005c08:	557d                	li	a0,-1
    80005c0a:	b761                	j	80005b92 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005c0c:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005c10:	04649783          	lh	a5,70(s1)
    80005c14:	02f99223          	sh	a5,36(s3)
    80005c18:	bf25                	j	80005b50 <sys_open+0xa2>
    itrunc(ip);
    80005c1a:	8526                	mv	a0,s1
    80005c1c:	ffffe097          	auipc	ra,0xffffe
    80005c20:	ff6080e7          	jalr	-10(ra) # 80003c12 <itrunc>
    80005c24:	bfa9                	j	80005b7e <sys_open+0xd0>
      fileclose(f);
    80005c26:	854e                	mv	a0,s3
    80005c28:	fffff097          	auipc	ra,0xfffff
    80005c2c:	d70080e7          	jalr	-656(ra) # 80004998 <fileclose>
    iunlockput(ip);
    80005c30:	8526                	mv	a0,s1
    80005c32:	ffffe097          	auipc	ra,0xffffe
    80005c36:	134080e7          	jalr	308(ra) # 80003d66 <iunlockput>
    end_op();
    80005c3a:	fffff097          	auipc	ra,0xfffff
    80005c3e:	914080e7          	jalr	-1772(ra) # 8000454e <end_op>
    return -1;
    80005c42:	557d                	li	a0,-1
    80005c44:	b7b9                	j	80005b92 <sys_open+0xe4>

0000000080005c46 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005c46:	7175                	addi	sp,sp,-144
    80005c48:	e506                	sd	ra,136(sp)
    80005c4a:	e122                	sd	s0,128(sp)
    80005c4c:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005c4e:	fffff097          	auipc	ra,0xfffff
    80005c52:	882080e7          	jalr	-1918(ra) # 800044d0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005c56:	08000613          	li	a2,128
    80005c5a:	f7040593          	addi	a1,s0,-144
    80005c5e:	4501                	li	a0,0
    80005c60:	ffffd097          	auipc	ra,0xffffd
    80005c64:	250080e7          	jalr	592(ra) # 80002eb0 <argstr>
    80005c68:	02054963          	bltz	a0,80005c9a <sys_mkdir+0x54>
    80005c6c:	4681                	li	a3,0
    80005c6e:	4601                	li	a2,0
    80005c70:	4585                	li	a1,1
    80005c72:	f7040513          	addi	a0,s0,-144
    80005c76:	fffff097          	auipc	ra,0xfffff
    80005c7a:	7fc080e7          	jalr	2044(ra) # 80005472 <create>
    80005c7e:	cd11                	beqz	a0,80005c9a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c80:	ffffe097          	auipc	ra,0xffffe
    80005c84:	0e6080e7          	jalr	230(ra) # 80003d66 <iunlockput>
  end_op();
    80005c88:	fffff097          	auipc	ra,0xfffff
    80005c8c:	8c6080e7          	jalr	-1850(ra) # 8000454e <end_op>
  return 0;
    80005c90:	4501                	li	a0,0
}
    80005c92:	60aa                	ld	ra,136(sp)
    80005c94:	640a                	ld	s0,128(sp)
    80005c96:	6149                	addi	sp,sp,144
    80005c98:	8082                	ret
    end_op();
    80005c9a:	fffff097          	auipc	ra,0xfffff
    80005c9e:	8b4080e7          	jalr	-1868(ra) # 8000454e <end_op>
    return -1;
    80005ca2:	557d                	li	a0,-1
    80005ca4:	b7fd                	j	80005c92 <sys_mkdir+0x4c>

0000000080005ca6 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005ca6:	7135                	addi	sp,sp,-160
    80005ca8:	ed06                	sd	ra,152(sp)
    80005caa:	e922                	sd	s0,144(sp)
    80005cac:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005cae:	fffff097          	auipc	ra,0xfffff
    80005cb2:	822080e7          	jalr	-2014(ra) # 800044d0 <begin_op>
  argint(1, &major);
    80005cb6:	f6c40593          	addi	a1,s0,-148
    80005cba:	4505                	li	a0,1
    80005cbc:	ffffd097          	auipc	ra,0xffffd
    80005cc0:	1b4080e7          	jalr	436(ra) # 80002e70 <argint>
  argint(2, &minor);
    80005cc4:	f6840593          	addi	a1,s0,-152
    80005cc8:	4509                	li	a0,2
    80005cca:	ffffd097          	auipc	ra,0xffffd
    80005cce:	1a6080e7          	jalr	422(ra) # 80002e70 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005cd2:	08000613          	li	a2,128
    80005cd6:	f7040593          	addi	a1,s0,-144
    80005cda:	4501                	li	a0,0
    80005cdc:	ffffd097          	auipc	ra,0xffffd
    80005ce0:	1d4080e7          	jalr	468(ra) # 80002eb0 <argstr>
    80005ce4:	02054b63          	bltz	a0,80005d1a <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005ce8:	f6841683          	lh	a3,-152(s0)
    80005cec:	f6c41603          	lh	a2,-148(s0)
    80005cf0:	458d                	li	a1,3
    80005cf2:	f7040513          	addi	a0,s0,-144
    80005cf6:	fffff097          	auipc	ra,0xfffff
    80005cfa:	77c080e7          	jalr	1916(ra) # 80005472 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005cfe:	cd11                	beqz	a0,80005d1a <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d00:	ffffe097          	auipc	ra,0xffffe
    80005d04:	066080e7          	jalr	102(ra) # 80003d66 <iunlockput>
  end_op();
    80005d08:	fffff097          	auipc	ra,0xfffff
    80005d0c:	846080e7          	jalr	-1978(ra) # 8000454e <end_op>
  return 0;
    80005d10:	4501                	li	a0,0
}
    80005d12:	60ea                	ld	ra,152(sp)
    80005d14:	644a                	ld	s0,144(sp)
    80005d16:	610d                	addi	sp,sp,160
    80005d18:	8082                	ret
    end_op();
    80005d1a:	fffff097          	auipc	ra,0xfffff
    80005d1e:	834080e7          	jalr	-1996(ra) # 8000454e <end_op>
    return -1;
    80005d22:	557d                	li	a0,-1
    80005d24:	b7fd                	j	80005d12 <sys_mknod+0x6c>

0000000080005d26 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005d26:	7135                	addi	sp,sp,-160
    80005d28:	ed06                	sd	ra,152(sp)
    80005d2a:	e922                	sd	s0,144(sp)
    80005d2c:	e526                	sd	s1,136(sp)
    80005d2e:	e14a                	sd	s2,128(sp)
    80005d30:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005d32:	ffffc097          	auipc	ra,0xffffc
    80005d36:	e40080e7          	jalr	-448(ra) # 80001b72 <myproc>
    80005d3a:	892a                	mv	s2,a0
  
  begin_op();
    80005d3c:	ffffe097          	auipc	ra,0xffffe
    80005d40:	794080e7          	jalr	1940(ra) # 800044d0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005d44:	08000613          	li	a2,128
    80005d48:	f6040593          	addi	a1,s0,-160
    80005d4c:	4501                	li	a0,0
    80005d4e:	ffffd097          	auipc	ra,0xffffd
    80005d52:	162080e7          	jalr	354(ra) # 80002eb0 <argstr>
    80005d56:	04054b63          	bltz	a0,80005dac <sys_chdir+0x86>
    80005d5a:	f6040513          	addi	a0,s0,-160
    80005d5e:	ffffe097          	auipc	ra,0xffffe
    80005d62:	552080e7          	jalr	1362(ra) # 800042b0 <namei>
    80005d66:	84aa                	mv	s1,a0
    80005d68:	c131                	beqz	a0,80005dac <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005d6a:	ffffe097          	auipc	ra,0xffffe
    80005d6e:	d9a080e7          	jalr	-614(ra) # 80003b04 <ilock>
  if(ip->type != T_DIR){
    80005d72:	04449703          	lh	a4,68(s1)
    80005d76:	4785                	li	a5,1
    80005d78:	04f71063          	bne	a4,a5,80005db8 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005d7c:	8526                	mv	a0,s1
    80005d7e:	ffffe097          	auipc	ra,0xffffe
    80005d82:	e48080e7          	jalr	-440(ra) # 80003bc6 <iunlock>
  iput(p->cwd);
    80005d86:	15093503          	ld	a0,336(s2)
    80005d8a:	ffffe097          	auipc	ra,0xffffe
    80005d8e:	f34080e7          	jalr	-204(ra) # 80003cbe <iput>
  end_op();
    80005d92:	ffffe097          	auipc	ra,0xffffe
    80005d96:	7bc080e7          	jalr	1980(ra) # 8000454e <end_op>
  p->cwd = ip;
    80005d9a:	14993823          	sd	s1,336(s2)
  return 0;
    80005d9e:	4501                	li	a0,0
}
    80005da0:	60ea                	ld	ra,152(sp)
    80005da2:	644a                	ld	s0,144(sp)
    80005da4:	64aa                	ld	s1,136(sp)
    80005da6:	690a                	ld	s2,128(sp)
    80005da8:	610d                	addi	sp,sp,160
    80005daa:	8082                	ret
    end_op();
    80005dac:	ffffe097          	auipc	ra,0xffffe
    80005db0:	7a2080e7          	jalr	1954(ra) # 8000454e <end_op>
    return -1;
    80005db4:	557d                	li	a0,-1
    80005db6:	b7ed                	j	80005da0 <sys_chdir+0x7a>
    iunlockput(ip);
    80005db8:	8526                	mv	a0,s1
    80005dba:	ffffe097          	auipc	ra,0xffffe
    80005dbe:	fac080e7          	jalr	-84(ra) # 80003d66 <iunlockput>
    end_op();
    80005dc2:	ffffe097          	auipc	ra,0xffffe
    80005dc6:	78c080e7          	jalr	1932(ra) # 8000454e <end_op>
    return -1;
    80005dca:	557d                	li	a0,-1
    80005dcc:	bfd1                	j	80005da0 <sys_chdir+0x7a>

0000000080005dce <sys_exec>:

uint64
sys_exec(void)
{
    80005dce:	7145                	addi	sp,sp,-464
    80005dd0:	e786                	sd	ra,456(sp)
    80005dd2:	e3a2                	sd	s0,448(sp)
    80005dd4:	ff26                	sd	s1,440(sp)
    80005dd6:	fb4a                	sd	s2,432(sp)
    80005dd8:	f74e                	sd	s3,424(sp)
    80005dda:	f352                	sd	s4,416(sp)
    80005ddc:	ef56                	sd	s5,408(sp)
    80005dde:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005de0:	e3840593          	addi	a1,s0,-456
    80005de4:	4505                	li	a0,1
    80005de6:	ffffd097          	auipc	ra,0xffffd
    80005dea:	0aa080e7          	jalr	170(ra) # 80002e90 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005dee:	08000613          	li	a2,128
    80005df2:	f4040593          	addi	a1,s0,-192
    80005df6:	4501                	li	a0,0
    80005df8:	ffffd097          	auipc	ra,0xffffd
    80005dfc:	0b8080e7          	jalr	184(ra) # 80002eb0 <argstr>
    80005e00:	87aa                	mv	a5,a0
    return -1;
    80005e02:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005e04:	0c07c363          	bltz	a5,80005eca <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005e08:	10000613          	li	a2,256
    80005e0c:	4581                	li	a1,0
    80005e0e:	e4040513          	addi	a0,s0,-448
    80005e12:	ffffb097          	auipc	ra,0xffffb
    80005e16:	f88080e7          	jalr	-120(ra) # 80000d9a <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005e1a:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005e1e:	89a6                	mv	s3,s1
    80005e20:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005e22:	02000a13          	li	s4,32
    80005e26:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005e2a:	00391513          	slli	a0,s2,0x3
    80005e2e:	e3040593          	addi	a1,s0,-464
    80005e32:	e3843783          	ld	a5,-456(s0)
    80005e36:	953e                	add	a0,a0,a5
    80005e38:	ffffd097          	auipc	ra,0xffffd
    80005e3c:	f9a080e7          	jalr	-102(ra) # 80002dd2 <fetchaddr>
    80005e40:	02054a63          	bltz	a0,80005e74 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005e44:	e3043783          	ld	a5,-464(s0)
    80005e48:	c3b9                	beqz	a5,80005e8e <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005e4a:	ffffb097          	auipc	ra,0xffffb
    80005e4e:	d18080e7          	jalr	-744(ra) # 80000b62 <kalloc>
    80005e52:	85aa                	mv	a1,a0
    80005e54:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005e58:	cd11                	beqz	a0,80005e74 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005e5a:	6605                	lui	a2,0x1
    80005e5c:	e3043503          	ld	a0,-464(s0)
    80005e60:	ffffd097          	auipc	ra,0xffffd
    80005e64:	fc4080e7          	jalr	-60(ra) # 80002e24 <fetchstr>
    80005e68:	00054663          	bltz	a0,80005e74 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005e6c:	0905                	addi	s2,s2,1
    80005e6e:	09a1                	addi	s3,s3,8
    80005e70:	fb491be3          	bne	s2,s4,80005e26 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e74:	f4040913          	addi	s2,s0,-192
    80005e78:	6088                	ld	a0,0(s1)
    80005e7a:	c539                	beqz	a0,80005ec8 <sys_exec+0xfa>
    kfree(argv[i]);
    80005e7c:	ffffb097          	auipc	ra,0xffffb
    80005e80:	b7e080e7          	jalr	-1154(ra) # 800009fa <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e84:	04a1                	addi	s1,s1,8
    80005e86:	ff2499e3          	bne	s1,s2,80005e78 <sys_exec+0xaa>
  return -1;
    80005e8a:	557d                	li	a0,-1
    80005e8c:	a83d                	j	80005eca <sys_exec+0xfc>
      argv[i] = 0;
    80005e8e:	0a8e                	slli	s5,s5,0x3
    80005e90:	fc0a8793          	addi	a5,s5,-64
    80005e94:	00878ab3          	add	s5,a5,s0
    80005e98:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005e9c:	e4040593          	addi	a1,s0,-448
    80005ea0:	f4040513          	addi	a0,s0,-192
    80005ea4:	fffff097          	auipc	ra,0xfffff
    80005ea8:	16e080e7          	jalr	366(ra) # 80005012 <exec>
    80005eac:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005eae:	f4040993          	addi	s3,s0,-192
    80005eb2:	6088                	ld	a0,0(s1)
    80005eb4:	c901                	beqz	a0,80005ec4 <sys_exec+0xf6>
    kfree(argv[i]);
    80005eb6:	ffffb097          	auipc	ra,0xffffb
    80005eba:	b44080e7          	jalr	-1212(ra) # 800009fa <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ebe:	04a1                	addi	s1,s1,8
    80005ec0:	ff3499e3          	bne	s1,s3,80005eb2 <sys_exec+0xe4>
  return ret;
    80005ec4:	854a                	mv	a0,s2
    80005ec6:	a011                	j	80005eca <sys_exec+0xfc>
  return -1;
    80005ec8:	557d                	li	a0,-1
}
    80005eca:	60be                	ld	ra,456(sp)
    80005ecc:	641e                	ld	s0,448(sp)
    80005ece:	74fa                	ld	s1,440(sp)
    80005ed0:	795a                	ld	s2,432(sp)
    80005ed2:	79ba                	ld	s3,424(sp)
    80005ed4:	7a1a                	ld	s4,416(sp)
    80005ed6:	6afa                	ld	s5,408(sp)
    80005ed8:	6179                	addi	sp,sp,464
    80005eda:	8082                	ret

0000000080005edc <sys_pipe>:

uint64
sys_pipe(void)
{
    80005edc:	7139                	addi	sp,sp,-64
    80005ede:	fc06                	sd	ra,56(sp)
    80005ee0:	f822                	sd	s0,48(sp)
    80005ee2:	f426                	sd	s1,40(sp)
    80005ee4:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005ee6:	ffffc097          	auipc	ra,0xffffc
    80005eea:	c8c080e7          	jalr	-884(ra) # 80001b72 <myproc>
    80005eee:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005ef0:	fd840593          	addi	a1,s0,-40
    80005ef4:	4501                	li	a0,0
    80005ef6:	ffffd097          	auipc	ra,0xffffd
    80005efa:	f9a080e7          	jalr	-102(ra) # 80002e90 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005efe:	fc840593          	addi	a1,s0,-56
    80005f02:	fd040513          	addi	a0,s0,-48
    80005f06:	fffff097          	auipc	ra,0xfffff
    80005f0a:	dc2080e7          	jalr	-574(ra) # 80004cc8 <pipealloc>
    return -1;
    80005f0e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005f10:	0c054463          	bltz	a0,80005fd8 <sys_pipe+0xfc>
  fd0 = -1;
    80005f14:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005f18:	fd043503          	ld	a0,-48(s0)
    80005f1c:	fffff097          	auipc	ra,0xfffff
    80005f20:	514080e7          	jalr	1300(ra) # 80005430 <fdalloc>
    80005f24:	fca42223          	sw	a0,-60(s0)
    80005f28:	08054b63          	bltz	a0,80005fbe <sys_pipe+0xe2>
    80005f2c:	fc843503          	ld	a0,-56(s0)
    80005f30:	fffff097          	auipc	ra,0xfffff
    80005f34:	500080e7          	jalr	1280(ra) # 80005430 <fdalloc>
    80005f38:	fca42023          	sw	a0,-64(s0)
    80005f3c:	06054863          	bltz	a0,80005fac <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f40:	4691                	li	a3,4
    80005f42:	fc440613          	addi	a2,s0,-60
    80005f46:	fd843583          	ld	a1,-40(s0)
    80005f4a:	68a8                	ld	a0,80(s1)
    80005f4c:	ffffb097          	auipc	ra,0xffffb
    80005f50:	7e8080e7          	jalr	2024(ra) # 80001734 <copyout>
    80005f54:	02054063          	bltz	a0,80005f74 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005f58:	4691                	li	a3,4
    80005f5a:	fc040613          	addi	a2,s0,-64
    80005f5e:	fd843583          	ld	a1,-40(s0)
    80005f62:	0591                	addi	a1,a1,4
    80005f64:	68a8                	ld	a0,80(s1)
    80005f66:	ffffb097          	auipc	ra,0xffffb
    80005f6a:	7ce080e7          	jalr	1998(ra) # 80001734 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005f6e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f70:	06055463          	bgez	a0,80005fd8 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005f74:	fc442783          	lw	a5,-60(s0)
    80005f78:	07e9                	addi	a5,a5,26
    80005f7a:	078e                	slli	a5,a5,0x3
    80005f7c:	97a6                	add	a5,a5,s1
    80005f7e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005f82:	fc042783          	lw	a5,-64(s0)
    80005f86:	07e9                	addi	a5,a5,26
    80005f88:	078e                	slli	a5,a5,0x3
    80005f8a:	94be                	add	s1,s1,a5
    80005f8c:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005f90:	fd043503          	ld	a0,-48(s0)
    80005f94:	fffff097          	auipc	ra,0xfffff
    80005f98:	a04080e7          	jalr	-1532(ra) # 80004998 <fileclose>
    fileclose(wf);
    80005f9c:	fc843503          	ld	a0,-56(s0)
    80005fa0:	fffff097          	auipc	ra,0xfffff
    80005fa4:	9f8080e7          	jalr	-1544(ra) # 80004998 <fileclose>
    return -1;
    80005fa8:	57fd                	li	a5,-1
    80005faa:	a03d                	j	80005fd8 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005fac:	fc442783          	lw	a5,-60(s0)
    80005fb0:	0007c763          	bltz	a5,80005fbe <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005fb4:	07e9                	addi	a5,a5,26
    80005fb6:	078e                	slli	a5,a5,0x3
    80005fb8:	97a6                	add	a5,a5,s1
    80005fba:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005fbe:	fd043503          	ld	a0,-48(s0)
    80005fc2:	fffff097          	auipc	ra,0xfffff
    80005fc6:	9d6080e7          	jalr	-1578(ra) # 80004998 <fileclose>
    fileclose(wf);
    80005fca:	fc843503          	ld	a0,-56(s0)
    80005fce:	fffff097          	auipc	ra,0xfffff
    80005fd2:	9ca080e7          	jalr	-1590(ra) # 80004998 <fileclose>
    return -1;
    80005fd6:	57fd                	li	a5,-1
}
    80005fd8:	853e                	mv	a0,a5
    80005fda:	70e2                	ld	ra,56(sp)
    80005fdc:	7442                	ld	s0,48(sp)
    80005fde:	74a2                	ld	s1,40(sp)
    80005fe0:	6121                	addi	sp,sp,64
    80005fe2:	8082                	ret
	...

0000000080005ff0 <kernelvec>:
    80005ff0:	7111                	addi	sp,sp,-256
    80005ff2:	e006                	sd	ra,0(sp)
    80005ff4:	e40a                	sd	sp,8(sp)
    80005ff6:	e80e                	sd	gp,16(sp)
    80005ff8:	ec12                	sd	tp,24(sp)
    80005ffa:	f016                	sd	t0,32(sp)
    80005ffc:	f41a                	sd	t1,40(sp)
    80005ffe:	f81e                	sd	t2,48(sp)
    80006000:	fc22                	sd	s0,56(sp)
    80006002:	e0a6                	sd	s1,64(sp)
    80006004:	e4aa                	sd	a0,72(sp)
    80006006:	e8ae                	sd	a1,80(sp)
    80006008:	ecb2                	sd	a2,88(sp)
    8000600a:	f0b6                	sd	a3,96(sp)
    8000600c:	f4ba                	sd	a4,104(sp)
    8000600e:	f8be                	sd	a5,112(sp)
    80006010:	fcc2                	sd	a6,120(sp)
    80006012:	e146                	sd	a7,128(sp)
    80006014:	e54a                	sd	s2,136(sp)
    80006016:	e94e                	sd	s3,144(sp)
    80006018:	ed52                	sd	s4,152(sp)
    8000601a:	f156                	sd	s5,160(sp)
    8000601c:	f55a                	sd	s6,168(sp)
    8000601e:	f95e                	sd	s7,176(sp)
    80006020:	fd62                	sd	s8,184(sp)
    80006022:	e1e6                	sd	s9,192(sp)
    80006024:	e5ea                	sd	s10,200(sp)
    80006026:	e9ee                	sd	s11,208(sp)
    80006028:	edf2                	sd	t3,216(sp)
    8000602a:	f1f6                	sd	t4,224(sp)
    8000602c:	f5fa                	sd	t5,232(sp)
    8000602e:	f9fe                	sd	t6,240(sp)
    80006030:	c6ffc0ef          	jal	ra,80002c9e <kerneltrap>
    80006034:	6082                	ld	ra,0(sp)
    80006036:	6122                	ld	sp,8(sp)
    80006038:	61c2                	ld	gp,16(sp)
    8000603a:	7282                	ld	t0,32(sp)
    8000603c:	7322                	ld	t1,40(sp)
    8000603e:	73c2                	ld	t2,48(sp)
    80006040:	7462                	ld	s0,56(sp)
    80006042:	6486                	ld	s1,64(sp)
    80006044:	6526                	ld	a0,72(sp)
    80006046:	65c6                	ld	a1,80(sp)
    80006048:	6666                	ld	a2,88(sp)
    8000604a:	7686                	ld	a3,96(sp)
    8000604c:	7726                	ld	a4,104(sp)
    8000604e:	77c6                	ld	a5,112(sp)
    80006050:	7866                	ld	a6,120(sp)
    80006052:	688a                	ld	a7,128(sp)
    80006054:	692a                	ld	s2,136(sp)
    80006056:	69ca                	ld	s3,144(sp)
    80006058:	6a6a                	ld	s4,152(sp)
    8000605a:	7a8a                	ld	s5,160(sp)
    8000605c:	7b2a                	ld	s6,168(sp)
    8000605e:	7bca                	ld	s7,176(sp)
    80006060:	7c6a                	ld	s8,184(sp)
    80006062:	6c8e                	ld	s9,192(sp)
    80006064:	6d2e                	ld	s10,200(sp)
    80006066:	6dce                	ld	s11,208(sp)
    80006068:	6e6e                	ld	t3,216(sp)
    8000606a:	7e8e                	ld	t4,224(sp)
    8000606c:	7f2e                	ld	t5,232(sp)
    8000606e:	7fce                	ld	t6,240(sp)
    80006070:	6111                	addi	sp,sp,256
    80006072:	10200073          	sret
    80006076:	00000013          	nop
    8000607a:	00000013          	nop
    8000607e:	0001                	nop

0000000080006080 <timervec>:
    80006080:	34051573          	csrrw	a0,mscratch,a0
    80006084:	e10c                	sd	a1,0(a0)
    80006086:	e510                	sd	a2,8(a0)
    80006088:	e914                	sd	a3,16(a0)
    8000608a:	6d0c                	ld	a1,24(a0)
    8000608c:	7110                	ld	a2,32(a0)
    8000608e:	6194                	ld	a3,0(a1)
    80006090:	96b2                	add	a3,a3,a2
    80006092:	e194                	sd	a3,0(a1)
    80006094:	4589                	li	a1,2
    80006096:	14459073          	csrw	sip,a1
    8000609a:	6914                	ld	a3,16(a0)
    8000609c:	6510                	ld	a2,8(a0)
    8000609e:	610c                	ld	a1,0(a0)
    800060a0:	34051573          	csrrw	a0,mscratch,a0
    800060a4:	30200073          	mret
	...

00000000800060aa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800060aa:	1141                	addi	sp,sp,-16
    800060ac:	e422                	sd	s0,8(sp)
    800060ae:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800060b0:	0c0007b7          	lui	a5,0xc000
    800060b4:	4705                	li	a4,1
    800060b6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800060b8:	c3d8                	sw	a4,4(a5)
}
    800060ba:	6422                	ld	s0,8(sp)
    800060bc:	0141                	addi	sp,sp,16
    800060be:	8082                	ret

00000000800060c0 <plicinithart>:

void
plicinithart(void)
{
    800060c0:	1141                	addi	sp,sp,-16
    800060c2:	e406                	sd	ra,8(sp)
    800060c4:	e022                	sd	s0,0(sp)
    800060c6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800060c8:	ffffc097          	auipc	ra,0xffffc
    800060cc:	a7e080e7          	jalr	-1410(ra) # 80001b46 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800060d0:	0085171b          	slliw	a4,a0,0x8
    800060d4:	0c0027b7          	lui	a5,0xc002
    800060d8:	97ba                	add	a5,a5,a4
    800060da:	40200713          	li	a4,1026
    800060de:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800060e2:	00d5151b          	slliw	a0,a0,0xd
    800060e6:	0c2017b7          	lui	a5,0xc201
    800060ea:	97aa                	add	a5,a5,a0
    800060ec:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    800060f0:	60a2                	ld	ra,8(sp)
    800060f2:	6402                	ld	s0,0(sp)
    800060f4:	0141                	addi	sp,sp,16
    800060f6:	8082                	ret

00000000800060f8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800060f8:	1141                	addi	sp,sp,-16
    800060fa:	e406                	sd	ra,8(sp)
    800060fc:	e022                	sd	s0,0(sp)
    800060fe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006100:	ffffc097          	auipc	ra,0xffffc
    80006104:	a46080e7          	jalr	-1466(ra) # 80001b46 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006108:	00d5151b          	slliw	a0,a0,0xd
    8000610c:	0c2017b7          	lui	a5,0xc201
    80006110:	97aa                	add	a5,a5,a0
  return irq;
}
    80006112:	43c8                	lw	a0,4(a5)
    80006114:	60a2                	ld	ra,8(sp)
    80006116:	6402                	ld	s0,0(sp)
    80006118:	0141                	addi	sp,sp,16
    8000611a:	8082                	ret

000000008000611c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000611c:	1101                	addi	sp,sp,-32
    8000611e:	ec06                	sd	ra,24(sp)
    80006120:	e822                	sd	s0,16(sp)
    80006122:	e426                	sd	s1,8(sp)
    80006124:	1000                	addi	s0,sp,32
    80006126:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006128:	ffffc097          	auipc	ra,0xffffc
    8000612c:	a1e080e7          	jalr	-1506(ra) # 80001b46 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006130:	00d5151b          	slliw	a0,a0,0xd
    80006134:	0c2017b7          	lui	a5,0xc201
    80006138:	97aa                	add	a5,a5,a0
    8000613a:	c3c4                	sw	s1,4(a5)
}
    8000613c:	60e2                	ld	ra,24(sp)
    8000613e:	6442                	ld	s0,16(sp)
    80006140:	64a2                	ld	s1,8(sp)
    80006142:	6105                	addi	sp,sp,32
    80006144:	8082                	ret

0000000080006146 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006146:	1141                	addi	sp,sp,-16
    80006148:	e406                	sd	ra,8(sp)
    8000614a:	e022                	sd	s0,0(sp)
    8000614c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000614e:	479d                	li	a5,7
    80006150:	04a7cc63          	blt	a5,a0,800061a8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006154:	0001c797          	auipc	a5,0x1c
    80006158:	c4c78793          	addi	a5,a5,-948 # 80021da0 <disk>
    8000615c:	97aa                	add	a5,a5,a0
    8000615e:	0187c783          	lbu	a5,24(a5)
    80006162:	ebb9                	bnez	a5,800061b8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006164:	00451693          	slli	a3,a0,0x4
    80006168:	0001c797          	auipc	a5,0x1c
    8000616c:	c3878793          	addi	a5,a5,-968 # 80021da0 <disk>
    80006170:	6398                	ld	a4,0(a5)
    80006172:	9736                	add	a4,a4,a3
    80006174:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80006178:	6398                	ld	a4,0(a5)
    8000617a:	9736                	add	a4,a4,a3
    8000617c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006180:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006184:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006188:	97aa                	add	a5,a5,a0
    8000618a:	4705                	li	a4,1
    8000618c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80006190:	0001c517          	auipc	a0,0x1c
    80006194:	c2850513          	addi	a0,a0,-984 # 80021db8 <disk+0x18>
    80006198:	ffffc097          	auipc	ra,0xffffc
    8000619c:	1ec080e7          	jalr	492(ra) # 80002384 <wakeup>
}
    800061a0:	60a2                	ld	ra,8(sp)
    800061a2:	6402                	ld	s0,0(sp)
    800061a4:	0141                	addi	sp,sp,16
    800061a6:	8082                	ret
    panic("free_desc 1");
    800061a8:	00002517          	auipc	a0,0x2
    800061ac:	6d050513          	addi	a0,a0,1744 # 80008878 <syscalls+0x318>
    800061b0:	ffffa097          	auipc	ra,0xffffa
    800061b4:	390080e7          	jalr	912(ra) # 80000540 <panic>
    panic("free_desc 2");
    800061b8:	00002517          	auipc	a0,0x2
    800061bc:	6d050513          	addi	a0,a0,1744 # 80008888 <syscalls+0x328>
    800061c0:	ffffa097          	auipc	ra,0xffffa
    800061c4:	380080e7          	jalr	896(ra) # 80000540 <panic>

00000000800061c8 <virtio_disk_init>:
{
    800061c8:	1101                	addi	sp,sp,-32
    800061ca:	ec06                	sd	ra,24(sp)
    800061cc:	e822                	sd	s0,16(sp)
    800061ce:	e426                	sd	s1,8(sp)
    800061d0:	e04a                	sd	s2,0(sp)
    800061d2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800061d4:	00002597          	auipc	a1,0x2
    800061d8:	6c458593          	addi	a1,a1,1732 # 80008898 <syscalls+0x338>
    800061dc:	0001c517          	auipc	a0,0x1c
    800061e0:	cec50513          	addi	a0,a0,-788 # 80021ec8 <disk+0x128>
    800061e4:	ffffb097          	auipc	ra,0xffffb
    800061e8:	a2a080e7          	jalr	-1494(ra) # 80000c0e <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800061ec:	100017b7          	lui	a5,0x10001
    800061f0:	4398                	lw	a4,0(a5)
    800061f2:	2701                	sext.w	a4,a4
    800061f4:	747277b7          	lui	a5,0x74727
    800061f8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800061fc:	14f71b63          	bne	a4,a5,80006352 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006200:	100017b7          	lui	a5,0x10001
    80006204:	43dc                	lw	a5,4(a5)
    80006206:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006208:	4709                	li	a4,2
    8000620a:	14e79463          	bne	a5,a4,80006352 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000620e:	100017b7          	lui	a5,0x10001
    80006212:	479c                	lw	a5,8(a5)
    80006214:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006216:	12e79e63          	bne	a5,a4,80006352 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000621a:	100017b7          	lui	a5,0x10001
    8000621e:	47d8                	lw	a4,12(a5)
    80006220:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006222:	554d47b7          	lui	a5,0x554d4
    80006226:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000622a:	12f71463          	bne	a4,a5,80006352 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000622e:	100017b7          	lui	a5,0x10001
    80006232:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006236:	4705                	li	a4,1
    80006238:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000623a:	470d                	li	a4,3
    8000623c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000623e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006240:	c7ffe6b7          	lui	a3,0xc7ffe
    80006244:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc87f>
    80006248:	8f75                	and	a4,a4,a3
    8000624a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000624c:	472d                	li	a4,11
    8000624e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006250:	5bbc                	lw	a5,112(a5)
    80006252:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006256:	8ba1                	andi	a5,a5,8
    80006258:	10078563          	beqz	a5,80006362 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000625c:	100017b7          	lui	a5,0x10001
    80006260:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006264:	43fc                	lw	a5,68(a5)
    80006266:	2781                	sext.w	a5,a5
    80006268:	10079563          	bnez	a5,80006372 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000626c:	100017b7          	lui	a5,0x10001
    80006270:	5bdc                	lw	a5,52(a5)
    80006272:	2781                	sext.w	a5,a5
  if(max == 0)
    80006274:	10078763          	beqz	a5,80006382 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006278:	471d                	li	a4,7
    8000627a:	10f77c63          	bgeu	a4,a5,80006392 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    8000627e:	ffffb097          	auipc	ra,0xffffb
    80006282:	8e4080e7          	jalr	-1820(ra) # 80000b62 <kalloc>
    80006286:	0001c497          	auipc	s1,0x1c
    8000628a:	b1a48493          	addi	s1,s1,-1254 # 80021da0 <disk>
    8000628e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006290:	ffffb097          	auipc	ra,0xffffb
    80006294:	8d2080e7          	jalr	-1838(ra) # 80000b62 <kalloc>
    80006298:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000629a:	ffffb097          	auipc	ra,0xffffb
    8000629e:	8c8080e7          	jalr	-1848(ra) # 80000b62 <kalloc>
    800062a2:	87aa                	mv	a5,a0
    800062a4:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800062a6:	6088                	ld	a0,0(s1)
    800062a8:	cd6d                	beqz	a0,800063a2 <virtio_disk_init+0x1da>
    800062aa:	0001c717          	auipc	a4,0x1c
    800062ae:	afe73703          	ld	a4,-1282(a4) # 80021da8 <disk+0x8>
    800062b2:	cb65                	beqz	a4,800063a2 <virtio_disk_init+0x1da>
    800062b4:	c7fd                	beqz	a5,800063a2 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    800062b6:	6605                	lui	a2,0x1
    800062b8:	4581                	li	a1,0
    800062ba:	ffffb097          	auipc	ra,0xffffb
    800062be:	ae0080e7          	jalr	-1312(ra) # 80000d9a <memset>
  memset(disk.avail, 0, PGSIZE);
    800062c2:	0001c497          	auipc	s1,0x1c
    800062c6:	ade48493          	addi	s1,s1,-1314 # 80021da0 <disk>
    800062ca:	6605                	lui	a2,0x1
    800062cc:	4581                	li	a1,0
    800062ce:	6488                	ld	a0,8(s1)
    800062d0:	ffffb097          	auipc	ra,0xffffb
    800062d4:	aca080e7          	jalr	-1334(ra) # 80000d9a <memset>
  memset(disk.used, 0, PGSIZE);
    800062d8:	6605                	lui	a2,0x1
    800062da:	4581                	li	a1,0
    800062dc:	6888                	ld	a0,16(s1)
    800062de:	ffffb097          	auipc	ra,0xffffb
    800062e2:	abc080e7          	jalr	-1348(ra) # 80000d9a <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800062e6:	100017b7          	lui	a5,0x10001
    800062ea:	4721                	li	a4,8
    800062ec:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800062ee:	4098                	lw	a4,0(s1)
    800062f0:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800062f4:	40d8                	lw	a4,4(s1)
    800062f6:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800062fa:	6498                	ld	a4,8(s1)
    800062fc:	0007069b          	sext.w	a3,a4
    80006300:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006304:	9701                	srai	a4,a4,0x20
    80006306:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000630a:	6898                	ld	a4,16(s1)
    8000630c:	0007069b          	sext.w	a3,a4
    80006310:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006314:	9701                	srai	a4,a4,0x20
    80006316:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000631a:	4705                	li	a4,1
    8000631c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000631e:	00e48c23          	sb	a4,24(s1)
    80006322:	00e48ca3          	sb	a4,25(s1)
    80006326:	00e48d23          	sb	a4,26(s1)
    8000632a:	00e48da3          	sb	a4,27(s1)
    8000632e:	00e48e23          	sb	a4,28(s1)
    80006332:	00e48ea3          	sb	a4,29(s1)
    80006336:	00e48f23          	sb	a4,30(s1)
    8000633a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000633e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006342:	0727a823          	sw	s2,112(a5)
}
    80006346:	60e2                	ld	ra,24(sp)
    80006348:	6442                	ld	s0,16(sp)
    8000634a:	64a2                	ld	s1,8(sp)
    8000634c:	6902                	ld	s2,0(sp)
    8000634e:	6105                	addi	sp,sp,32
    80006350:	8082                	ret
    panic("could not find virtio disk");
    80006352:	00002517          	auipc	a0,0x2
    80006356:	55650513          	addi	a0,a0,1366 # 800088a8 <syscalls+0x348>
    8000635a:	ffffa097          	auipc	ra,0xffffa
    8000635e:	1e6080e7          	jalr	486(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006362:	00002517          	auipc	a0,0x2
    80006366:	56650513          	addi	a0,a0,1382 # 800088c8 <syscalls+0x368>
    8000636a:	ffffa097          	auipc	ra,0xffffa
    8000636e:	1d6080e7          	jalr	470(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80006372:	00002517          	auipc	a0,0x2
    80006376:	57650513          	addi	a0,a0,1398 # 800088e8 <syscalls+0x388>
    8000637a:	ffffa097          	auipc	ra,0xffffa
    8000637e:	1c6080e7          	jalr	454(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006382:	00002517          	auipc	a0,0x2
    80006386:	58650513          	addi	a0,a0,1414 # 80008908 <syscalls+0x3a8>
    8000638a:	ffffa097          	auipc	ra,0xffffa
    8000638e:	1b6080e7          	jalr	438(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80006392:	00002517          	auipc	a0,0x2
    80006396:	59650513          	addi	a0,a0,1430 # 80008928 <syscalls+0x3c8>
    8000639a:	ffffa097          	auipc	ra,0xffffa
    8000639e:	1a6080e7          	jalr	422(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    800063a2:	00002517          	auipc	a0,0x2
    800063a6:	5a650513          	addi	a0,a0,1446 # 80008948 <syscalls+0x3e8>
    800063aa:	ffffa097          	auipc	ra,0xffffa
    800063ae:	196080e7          	jalr	406(ra) # 80000540 <panic>

00000000800063b2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800063b2:	7119                	addi	sp,sp,-128
    800063b4:	fc86                	sd	ra,120(sp)
    800063b6:	f8a2                	sd	s0,112(sp)
    800063b8:	f4a6                	sd	s1,104(sp)
    800063ba:	f0ca                	sd	s2,96(sp)
    800063bc:	ecce                	sd	s3,88(sp)
    800063be:	e8d2                	sd	s4,80(sp)
    800063c0:	e4d6                	sd	s5,72(sp)
    800063c2:	e0da                	sd	s6,64(sp)
    800063c4:	fc5e                	sd	s7,56(sp)
    800063c6:	f862                	sd	s8,48(sp)
    800063c8:	f466                	sd	s9,40(sp)
    800063ca:	f06a                	sd	s10,32(sp)
    800063cc:	ec6e                	sd	s11,24(sp)
    800063ce:	0100                	addi	s0,sp,128
    800063d0:	8aaa                	mv	s5,a0
    800063d2:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800063d4:	00c52d03          	lw	s10,12(a0)
    800063d8:	001d1d1b          	slliw	s10,s10,0x1
    800063dc:	1d02                	slli	s10,s10,0x20
    800063de:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800063e2:	0001c517          	auipc	a0,0x1c
    800063e6:	ae650513          	addi	a0,a0,-1306 # 80021ec8 <disk+0x128>
    800063ea:	ffffb097          	auipc	ra,0xffffb
    800063ee:	8b4080e7          	jalr	-1868(ra) # 80000c9e <acquire>
  for(int i = 0; i < 3; i++){
    800063f2:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800063f4:	44a1                	li	s1,8
      disk.free[i] = 0;
    800063f6:	0001cb97          	auipc	s7,0x1c
    800063fa:	9aab8b93          	addi	s7,s7,-1622 # 80021da0 <disk>
  for(int i = 0; i < 3; i++){
    800063fe:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006400:	0001cc97          	auipc	s9,0x1c
    80006404:	ac8c8c93          	addi	s9,s9,-1336 # 80021ec8 <disk+0x128>
    80006408:	a08d                	j	8000646a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000640a:	00fb8733          	add	a4,s7,a5
    8000640e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006412:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006414:	0207c563          	bltz	a5,8000643e <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80006418:	2905                	addiw	s2,s2,1
    8000641a:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    8000641c:	05690c63          	beq	s2,s6,80006474 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006420:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006422:	0001c717          	auipc	a4,0x1c
    80006426:	97e70713          	addi	a4,a4,-1666 # 80021da0 <disk>
    8000642a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000642c:	01874683          	lbu	a3,24(a4)
    80006430:	fee9                	bnez	a3,8000640a <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006432:	2785                	addiw	a5,a5,1
    80006434:	0705                	addi	a4,a4,1
    80006436:	fe979be3          	bne	a5,s1,8000642c <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000643a:	57fd                	li	a5,-1
    8000643c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000643e:	01205d63          	blez	s2,80006458 <virtio_disk_rw+0xa6>
    80006442:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006444:	000a2503          	lw	a0,0(s4)
    80006448:	00000097          	auipc	ra,0x0
    8000644c:	cfe080e7          	jalr	-770(ra) # 80006146 <free_desc>
      for(int j = 0; j < i; j++)
    80006450:	2d85                	addiw	s11,s11,1
    80006452:	0a11                	addi	s4,s4,4
    80006454:	ff2d98e3          	bne	s11,s2,80006444 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006458:	85e6                	mv	a1,s9
    8000645a:	0001c517          	auipc	a0,0x1c
    8000645e:	95e50513          	addi	a0,a0,-1698 # 80021db8 <disk+0x18>
    80006462:	ffffc097          	auipc	ra,0xffffc
    80006466:	ebe080e7          	jalr	-322(ra) # 80002320 <sleep>
  for(int i = 0; i < 3; i++){
    8000646a:	f8040a13          	addi	s4,s0,-128
{
    8000646e:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006470:	894e                	mv	s2,s3
    80006472:	b77d                	j	80006420 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006474:	f8042503          	lw	a0,-128(s0)
    80006478:	00a50713          	addi	a4,a0,10
    8000647c:	0712                	slli	a4,a4,0x4

  if(write)
    8000647e:	0001c797          	auipc	a5,0x1c
    80006482:	92278793          	addi	a5,a5,-1758 # 80021da0 <disk>
    80006486:	00e786b3          	add	a3,a5,a4
    8000648a:	01803633          	snez	a2,s8
    8000648e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006490:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006494:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006498:	f6070613          	addi	a2,a4,-160
    8000649c:	6394                	ld	a3,0(a5)
    8000649e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800064a0:	00870593          	addi	a1,a4,8
    800064a4:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    800064a6:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800064a8:	0007b803          	ld	a6,0(a5)
    800064ac:	9642                	add	a2,a2,a6
    800064ae:	46c1                	li	a3,16
    800064b0:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800064b2:	4585                	li	a1,1
    800064b4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    800064b8:	f8442683          	lw	a3,-124(s0)
    800064bc:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800064c0:	0692                	slli	a3,a3,0x4
    800064c2:	9836                	add	a6,a6,a3
    800064c4:	058a8613          	addi	a2,s5,88
    800064c8:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    800064cc:	0007b803          	ld	a6,0(a5)
    800064d0:	96c2                	add	a3,a3,a6
    800064d2:	40000613          	li	a2,1024
    800064d6:	c690                	sw	a2,8(a3)
  if(write)
    800064d8:	001c3613          	seqz	a2,s8
    800064dc:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800064e0:	00166613          	ori	a2,a2,1
    800064e4:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800064e8:	f8842603          	lw	a2,-120(s0)
    800064ec:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800064f0:	00250693          	addi	a3,a0,2
    800064f4:	0692                	slli	a3,a3,0x4
    800064f6:	96be                	add	a3,a3,a5
    800064f8:	58fd                	li	a7,-1
    800064fa:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800064fe:	0612                	slli	a2,a2,0x4
    80006500:	9832                	add	a6,a6,a2
    80006502:	f9070713          	addi	a4,a4,-112
    80006506:	973e                	add	a4,a4,a5
    80006508:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000650c:	6398                	ld	a4,0(a5)
    8000650e:	9732                	add	a4,a4,a2
    80006510:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006512:	4609                	li	a2,2
    80006514:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006518:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000651c:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006520:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006524:	6794                	ld	a3,8(a5)
    80006526:	0026d703          	lhu	a4,2(a3)
    8000652a:	8b1d                	andi	a4,a4,7
    8000652c:	0706                	slli	a4,a4,0x1
    8000652e:	96ba                	add	a3,a3,a4
    80006530:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006534:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006538:	6798                	ld	a4,8(a5)
    8000653a:	00275783          	lhu	a5,2(a4)
    8000653e:	2785                	addiw	a5,a5,1
    80006540:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006544:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006548:	100017b7          	lui	a5,0x10001
    8000654c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006550:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    80006554:	0001c917          	auipc	s2,0x1c
    80006558:	97490913          	addi	s2,s2,-1676 # 80021ec8 <disk+0x128>
  while(b->disk == 1) {
    8000655c:	4485                	li	s1,1
    8000655e:	00b79c63          	bne	a5,a1,80006576 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006562:	85ca                	mv	a1,s2
    80006564:	8556                	mv	a0,s5
    80006566:	ffffc097          	auipc	ra,0xffffc
    8000656a:	dba080e7          	jalr	-582(ra) # 80002320 <sleep>
  while(b->disk == 1) {
    8000656e:	004aa783          	lw	a5,4(s5)
    80006572:	fe9788e3          	beq	a5,s1,80006562 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006576:	f8042903          	lw	s2,-128(s0)
    8000657a:	00290713          	addi	a4,s2,2
    8000657e:	0712                	slli	a4,a4,0x4
    80006580:	0001c797          	auipc	a5,0x1c
    80006584:	82078793          	addi	a5,a5,-2016 # 80021da0 <disk>
    80006588:	97ba                	add	a5,a5,a4
    8000658a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000658e:	0001c997          	auipc	s3,0x1c
    80006592:	81298993          	addi	s3,s3,-2030 # 80021da0 <disk>
    80006596:	00491713          	slli	a4,s2,0x4
    8000659a:	0009b783          	ld	a5,0(s3)
    8000659e:	97ba                	add	a5,a5,a4
    800065a0:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800065a4:	854a                	mv	a0,s2
    800065a6:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800065aa:	00000097          	auipc	ra,0x0
    800065ae:	b9c080e7          	jalr	-1124(ra) # 80006146 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800065b2:	8885                	andi	s1,s1,1
    800065b4:	f0ed                	bnez	s1,80006596 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800065b6:	0001c517          	auipc	a0,0x1c
    800065ba:	91250513          	addi	a0,a0,-1774 # 80021ec8 <disk+0x128>
    800065be:	ffffa097          	auipc	ra,0xffffa
    800065c2:	794080e7          	jalr	1940(ra) # 80000d52 <release>
}
    800065c6:	70e6                	ld	ra,120(sp)
    800065c8:	7446                	ld	s0,112(sp)
    800065ca:	74a6                	ld	s1,104(sp)
    800065cc:	7906                	ld	s2,96(sp)
    800065ce:	69e6                	ld	s3,88(sp)
    800065d0:	6a46                	ld	s4,80(sp)
    800065d2:	6aa6                	ld	s5,72(sp)
    800065d4:	6b06                	ld	s6,64(sp)
    800065d6:	7be2                	ld	s7,56(sp)
    800065d8:	7c42                	ld	s8,48(sp)
    800065da:	7ca2                	ld	s9,40(sp)
    800065dc:	7d02                	ld	s10,32(sp)
    800065de:	6de2                	ld	s11,24(sp)
    800065e0:	6109                	addi	sp,sp,128
    800065e2:	8082                	ret

00000000800065e4 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800065e4:	1101                	addi	sp,sp,-32
    800065e6:	ec06                	sd	ra,24(sp)
    800065e8:	e822                	sd	s0,16(sp)
    800065ea:	e426                	sd	s1,8(sp)
    800065ec:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800065ee:	0001b497          	auipc	s1,0x1b
    800065f2:	7b248493          	addi	s1,s1,1970 # 80021da0 <disk>
    800065f6:	0001c517          	auipc	a0,0x1c
    800065fa:	8d250513          	addi	a0,a0,-1838 # 80021ec8 <disk+0x128>
    800065fe:	ffffa097          	auipc	ra,0xffffa
    80006602:	6a0080e7          	jalr	1696(ra) # 80000c9e <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006606:	10001737          	lui	a4,0x10001
    8000660a:	533c                	lw	a5,96(a4)
    8000660c:	8b8d                	andi	a5,a5,3
    8000660e:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006610:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006614:	689c                	ld	a5,16(s1)
    80006616:	0204d703          	lhu	a4,32(s1)
    8000661a:	0027d783          	lhu	a5,2(a5)
    8000661e:	04f70863          	beq	a4,a5,8000666e <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006622:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006626:	6898                	ld	a4,16(s1)
    80006628:	0204d783          	lhu	a5,32(s1)
    8000662c:	8b9d                	andi	a5,a5,7
    8000662e:	078e                	slli	a5,a5,0x3
    80006630:	97ba                	add	a5,a5,a4
    80006632:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006634:	00278713          	addi	a4,a5,2
    80006638:	0712                	slli	a4,a4,0x4
    8000663a:	9726                	add	a4,a4,s1
    8000663c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006640:	e721                	bnez	a4,80006688 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006642:	0789                	addi	a5,a5,2
    80006644:	0792                	slli	a5,a5,0x4
    80006646:	97a6                	add	a5,a5,s1
    80006648:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000664a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000664e:	ffffc097          	auipc	ra,0xffffc
    80006652:	d36080e7          	jalr	-714(ra) # 80002384 <wakeup>

    disk.used_idx += 1;
    80006656:	0204d783          	lhu	a5,32(s1)
    8000665a:	2785                	addiw	a5,a5,1
    8000665c:	17c2                	slli	a5,a5,0x30
    8000665e:	93c1                	srli	a5,a5,0x30
    80006660:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006664:	6898                	ld	a4,16(s1)
    80006666:	00275703          	lhu	a4,2(a4)
    8000666a:	faf71ce3          	bne	a4,a5,80006622 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000666e:	0001c517          	auipc	a0,0x1c
    80006672:	85a50513          	addi	a0,a0,-1958 # 80021ec8 <disk+0x128>
    80006676:	ffffa097          	auipc	ra,0xffffa
    8000667a:	6dc080e7          	jalr	1756(ra) # 80000d52 <release>
}
    8000667e:	60e2                	ld	ra,24(sp)
    80006680:	6442                	ld	s0,16(sp)
    80006682:	64a2                	ld	s1,8(sp)
    80006684:	6105                	addi	sp,sp,32
    80006686:	8082                	ret
      panic("virtio_disk_intr status");
    80006688:	00002517          	auipc	a0,0x2
    8000668c:	2d850513          	addi	a0,a0,728 # 80008960 <syscalls+0x400>
    80006690:	ffffa097          	auipc	ra,0xffffa
    80006694:	eb0080e7          	jalr	-336(ra) # 80000540 <panic>
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
