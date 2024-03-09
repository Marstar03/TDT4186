
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	90013103          	ld	sp,-1792(sp) # 80008900 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000054:	91070713          	addi	a4,a4,-1776 # 80008960 <timer_scratch>
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
    80000066:	c3e78793          	addi	a5,a5,-962 # 80005ca0 <timervec>
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
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdca2f>
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
int
consolewrite(int user_src, uint64 src, int n)
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

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	388080e7          	jalr	904(ra) # 800024b2 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	784080e7          	jalr	1924(ra) # 800008be <uartputc>
  for(i = 0; i < n; i++){
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
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
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
    8000018e:	91650513          	addi	a0,a0,-1770 # 80010aa0 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	90648493          	addi	s1,s1,-1786 # 80010aa0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	99690913          	addi	s2,s2,-1642 # 80010b38 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7ec080e7          	jalr	2028(ra) # 800019ac <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	134080e7          	jalr	308(ra) # 800022fc <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	e7e080e7          	jalr	-386(ra) # 80002054 <sleep>
    while(cons.r == cons.w){
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
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	24a080e7          	jalr	586(ra) # 8000245c <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	87a50513          	addi	a0,a0,-1926 # 80010aa0 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	86450513          	addi	a0,a0,-1948 # 80010aa0 <cons>
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
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	8cf72323          	sw	a5,-1850(a4) # 80010b38 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
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
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54e080e7          	jalr	1358(ra) # 800007ec <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	542080e7          	jalr	1346(ra) # 800007ec <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	538080e7          	jalr	1336(ra) # 800007ec <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	7d450513          	addi	a0,a0,2004 # 80010aa0 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	216080e7          	jalr	534(ra) # 80002508 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	7a650513          	addi	a0,a0,1958 # 80010aa0 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	78270713          	addi	a4,a4,1922 # 80010aa0 <cons>
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
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	75878793          	addi	a5,a5,1880 # 80010aa0 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7c27a783          	lw	a5,1986(a5) # 80010b38 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	71670713          	addi	a4,a4,1814 # 80010aa0 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	70648493          	addi	s1,s1,1798 # 80010aa0 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	6ca70713          	addi	a4,a4,1738 # 80010aa0 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	74f72a23          	sw	a5,1876(a4) # 80010b40 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	68e78793          	addi	a5,a5,1678 # 80010aa0 <cons>
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
    8000043a:	70c7a323          	sw	a2,1798(a5) # 80010b3c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	6fa50513          	addi	a0,a0,1786 # 80010b38 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	c72080e7          	jalr	-910(ra) # 800020b8 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	64050513          	addi	a0,a0,1600 # 80010aa0 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00020797          	auipc	a5,0x20
    8000047c:	7c078793          	addi	a5,a5,1984 # 80020c38 <devsw>
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
    80000550:	6007aa23          	sw	zero,1556(a5) # 80010b60 <pr+0x18>
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
    80000584:	3af72023          	sw	a5,928(a4) # 80008920 <panicked>
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
    800005c0:	5a4dad83          	lw	s11,1444(s11) # 80010b60 <pr+0x18>
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
    800005fe:	54e50513          	addi	a0,a0,1358 # 80010b48 <pr>
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
    8000075c:	3f050513          	addi	a0,a0,1008 # 80010b48 <pr>
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
    80000778:	3d448493          	addi	s1,s1,980 # 80010b48 <pr>
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
    800007d8:	39450513          	addi	a0,a0,916 # 80010b68 <uart_tx_lock>
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
    80000804:	1207a783          	lw	a5,288(a5) # 80008920 <panicked>
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
    8000083c:	0f07b783          	ld	a5,240(a5) # 80008928 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	0f073703          	ld	a4,240(a4) # 80008930 <uart_tx_w>
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
    80000866:	306a0a13          	addi	s4,s4,774 # 80010b68 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	0be48493          	addi	s1,s1,190 # 80008928 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	0be98993          	addi	s3,s3,190 # 80008930 <uart_tx_w>
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
    80000898:	824080e7          	jalr	-2012(ra) # 800020b8 <wakeup>
    
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
    800008d4:	29850513          	addi	a0,a0,664 # 80010b68 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	2fe080e7          	jalr	766(ra) # 80000bd6 <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	0407a783          	lw	a5,64(a5) # 80008920 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	04673703          	ld	a4,70(a4) # 80008930 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	0367b783          	ld	a5,54(a5) # 80008928 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	26a98993          	addi	s3,s3,618 # 80010b68 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	02248493          	addi	s1,s1,34 # 80008928 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	02290913          	addi	s2,s2,34 # 80008930 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00001097          	auipc	ra,0x1
    80000922:	736080e7          	jalr	1846(ra) # 80002054 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	23448493          	addi	s1,s1,564 # 80010b68 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	fee7b423          	sd	a4,-24(a5) # 80008930 <uart_tx_w>
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
    800009be:	1ae48493          	addi	s1,s1,430 # 80010b68 <uart_tx_lock>
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
    80000a00:	3d478793          	addi	a5,a5,980 # 80021dd0 <end>
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
    80000a20:	18490913          	addi	s2,s2,388 # 80010ba0 <kmem>
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
    80000abe:	0e650513          	addi	a0,a0,230 # 80010ba0 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00021517          	auipc	a0,0x21
    80000ad2:	30250513          	addi	a0,a0,770 # 80021dd0 <end>
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
    80000af4:	0b048493          	addi	s1,s1,176 # 80010ba0 <kmem>
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
    80000b0c:	09850513          	addi	a0,a0,152 # 80010ba0 <kmem>
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
    80000b38:	06c50513          	addi	a0,a0,108 # 80010ba0 <kmem>
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
    80000b74:	e20080e7          	jalr	-480(ra) # 80001990 <mycpu>
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
    80000ba6:	dee080e7          	jalr	-530(ra) # 80001990 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	de2080e7          	jalr	-542(ra) # 80001990 <mycpu>
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
    80000bca:	dca080e7          	jalr	-566(ra) # 80001990 <mycpu>
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
    80000c0a:	d8a080e7          	jalr	-630(ra) # 80001990 <mycpu>
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
    80000c36:	d5e080e7          	jalr	-674(ra) # 80001990 <mycpu>
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
    80000d46:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdd231>
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
    80000e84:	b00080e7          	jalr	-1280(ra) # 80001980 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	ab070713          	addi	a4,a4,-1360 # 80008938 <started>
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
    80000ea0:	ae4080e7          	jalr	-1308(ra) # 80001980 <cpuid>
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
    80000ec2:	83a080e7          	jalr	-1990(ra) # 800026f8 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	e1a080e7          	jalr	-486(ra) # 80005ce0 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	fd4080e7          	jalr	-44(ra) # 80001ea2 <scheduler>
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
    80000f32:	99e080e7          	jalr	-1634(ra) # 800018cc <procinit>
    trapinit();      // trap vectors
    80000f36:	00001097          	auipc	ra,0x1
    80000f3a:	79a080e7          	jalr	1946(ra) # 800026d0 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00001097          	auipc	ra,0x1
    80000f42:	7ba080e7          	jalr	1978(ra) # 800026f8 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	d84080e7          	jalr	-636(ra) # 80005cca <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	d92080e7          	jalr	-622(ra) # 80005ce0 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	f34080e7          	jalr	-204(ra) # 80002e8a <binit>
    iinit();         // inode table
    80000f5e:	00002097          	auipc	ra,0x2
    80000f62:	5d4080e7          	jalr	1492(ra) # 80003532 <iinit>
    fileinit();      // file table
    80000f66:	00003097          	auipc	ra,0x3
    80000f6a:	57a080e7          	jalr	1402(ra) # 800044e0 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	e7a080e7          	jalr	-390(ra) # 80005de8 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	d0e080e7          	jalr	-754(ra) # 80001c84 <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	9af72a23          	sw	a5,-1612(a4) # 80008938 <started>
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
    80000f9c:	9a87b783          	ld	a5,-1624(a5) # 80008940 <kernel_pagetable>
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
    80001016:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdd227>
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
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	608080e7          	jalr	1544(ra) # 80001836 <proc_mapstacks>
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
    80001258:	6ea7b623          	sd	a0,1772(a5) # 80008940 <kernel_pagetable>
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
    8000180c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdd230>
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

0000000080001836 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
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
    8000184a:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000184c:	0000f497          	auipc	s1,0xf
    80001850:	7a448493          	addi	s1,s1,1956 # 80010ff0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001854:	8b26                	mv	s6,s1
    80001856:	00006a97          	auipc	s5,0x6
    8000185a:	7aaa8a93          	addi	s5,s5,1962 # 80008000 <etext>
    8000185e:	04000937          	lui	s2,0x4000
    80001862:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001864:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001866:	00015a17          	auipc	s4,0x15
    8000186a:	18aa0a13          	addi	s4,s4,394 # 800169f0 <tickslock>
    char *pa = kalloc();
    8000186e:	fffff097          	auipc	ra,0xfffff
    80001872:	278080e7          	jalr	632(ra) # 80000ae6 <kalloc>
    80001876:	862a                	mv	a2,a0
    if(pa == 0)
    80001878:	c131                	beqz	a0,800018bc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    8000187a:	416485b3          	sub	a1,s1,s6
    8000187e:	858d                	srai	a1,a1,0x3
    80001880:	000ab783          	ld	a5,0(s5)
    80001884:	02f585b3          	mul	a1,a1,a5
    80001888:	2585                	addiw	a1,a1,1
    8000188a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000188e:	4719                	li	a4,6
    80001890:	6685                	lui	a3,0x1
    80001892:	40b905b3          	sub	a1,s2,a1
    80001896:	854e                	mv	a0,s3
    80001898:	00000097          	auipc	ra,0x0
    8000189c:	8a6080e7          	jalr	-1882(ra) # 8000113e <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a0:	16848493          	addi	s1,s1,360
    800018a4:	fd4495e3          	bne	s1,s4,8000186e <proc_mapstacks+0x38>
  }
}
    800018a8:	70e2                	ld	ra,56(sp)
    800018aa:	7442                	ld	s0,48(sp)
    800018ac:	74a2                	ld	s1,40(sp)
    800018ae:	7902                	ld	s2,32(sp)
    800018b0:	69e2                	ld	s3,24(sp)
    800018b2:	6a42                	ld	s4,16(sp)
    800018b4:	6aa2                	ld	s5,8(sp)
    800018b6:	6b02                	ld	s6,0(sp)
    800018b8:	6121                	addi	sp,sp,64
    800018ba:	8082                	ret
      panic("kalloc");
    800018bc:	00007517          	auipc	a0,0x7
    800018c0:	91c50513          	addi	a0,a0,-1764 # 800081d8 <digits+0x198>
    800018c4:	fffff097          	auipc	ra,0xfffff
    800018c8:	c7c080e7          	jalr	-900(ra) # 80000540 <panic>

00000000800018cc <procinit>:

// initialize the proc table.
void
procinit(void)
{
    800018cc:	7139                	addi	sp,sp,-64
    800018ce:	fc06                	sd	ra,56(sp)
    800018d0:	f822                	sd	s0,48(sp)
    800018d2:	f426                	sd	s1,40(sp)
    800018d4:	f04a                	sd	s2,32(sp)
    800018d6:	ec4e                	sd	s3,24(sp)
    800018d8:	e852                	sd	s4,16(sp)
    800018da:	e456                	sd	s5,8(sp)
    800018dc:	e05a                	sd	s6,0(sp)
    800018de:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018e0:	00007597          	auipc	a1,0x7
    800018e4:	90058593          	addi	a1,a1,-1792 # 800081e0 <digits+0x1a0>
    800018e8:	0000f517          	auipc	a0,0xf
    800018ec:	2d850513          	addi	a0,a0,728 # 80010bc0 <pid_lock>
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	256080e7          	jalr	598(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f8:	00007597          	auipc	a1,0x7
    800018fc:	8f058593          	addi	a1,a1,-1808 # 800081e8 <digits+0x1a8>
    80001900:	0000f517          	auipc	a0,0xf
    80001904:	2d850513          	addi	a0,a0,728 # 80010bd8 <wait_lock>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	23e080e7          	jalr	574(ra) # 80000b46 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001910:	0000f497          	auipc	s1,0xf
    80001914:	6e048493          	addi	s1,s1,1760 # 80010ff0 <proc>
      initlock(&p->lock, "proc");
    80001918:	00007b17          	auipc	s6,0x7
    8000191c:	8e0b0b13          	addi	s6,s6,-1824 # 800081f8 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001920:	8aa6                	mv	s5,s1
    80001922:	00006a17          	auipc	s4,0x6
    80001926:	6dea0a13          	addi	s4,s4,1758 # 80008000 <etext>
    8000192a:	04000937          	lui	s2,0x4000
    8000192e:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001930:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001932:	00015997          	auipc	s3,0x15
    80001936:	0be98993          	addi	s3,s3,190 # 800169f0 <tickslock>
      initlock(&p->lock, "proc");
    8000193a:	85da                	mv	a1,s6
    8000193c:	8526                	mv	a0,s1
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	208080e7          	jalr	520(ra) # 80000b46 <initlock>
      p->state = UNUSED;
    80001946:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    8000194a:	415487b3          	sub	a5,s1,s5
    8000194e:	878d                	srai	a5,a5,0x3
    80001950:	000a3703          	ld	a4,0(s4)
    80001954:	02e787b3          	mul	a5,a5,a4
    80001958:	2785                	addiw	a5,a5,1
    8000195a:	00d7979b          	slliw	a5,a5,0xd
    8000195e:	40f907b3          	sub	a5,s2,a5
    80001962:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001964:	16848493          	addi	s1,s1,360
    80001968:	fd3499e3          	bne	s1,s3,8000193a <procinit+0x6e>
  }
}
    8000196c:	70e2                	ld	ra,56(sp)
    8000196e:	7442                	ld	s0,48(sp)
    80001970:	74a2                	ld	s1,40(sp)
    80001972:	7902                	ld	s2,32(sp)
    80001974:	69e2                	ld	s3,24(sp)
    80001976:	6a42                	ld	s4,16(sp)
    80001978:	6aa2                	ld	s5,8(sp)
    8000197a:	6b02                	ld	s6,0(sp)
    8000197c:	6121                	addi	sp,sp,64
    8000197e:	8082                	ret

0000000080001980 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001980:	1141                	addi	sp,sp,-16
    80001982:	e422                	sd	s0,8(sp)
    80001984:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001986:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001988:	2501                	sext.w	a0,a0
    8000198a:	6422                	ld	s0,8(sp)
    8000198c:	0141                	addi	sp,sp,16
    8000198e:	8082                	ret

0000000080001990 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001990:	1141                	addi	sp,sp,-16
    80001992:	e422                	sd	s0,8(sp)
    80001994:	0800                	addi	s0,sp,16
    80001996:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001998:	2781                	sext.w	a5,a5
    8000199a:	079e                	slli	a5,a5,0x7
  return c;
}
    8000199c:	0000f517          	auipc	a0,0xf
    800019a0:	25450513          	addi	a0,a0,596 # 80010bf0 <cpus>
    800019a4:	953e                	add	a0,a0,a5
    800019a6:	6422                	ld	s0,8(sp)
    800019a8:	0141                	addi	sp,sp,16
    800019aa:	8082                	ret

00000000800019ac <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    800019ac:	1101                	addi	sp,sp,-32
    800019ae:	ec06                	sd	ra,24(sp)
    800019b0:	e822                	sd	s0,16(sp)
    800019b2:	e426                	sd	s1,8(sp)
    800019b4:	1000                	addi	s0,sp,32
  push_off();
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	1d4080e7          	jalr	468(ra) # 80000b8a <push_off>
    800019be:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c0:	2781                	sext.w	a5,a5
    800019c2:	079e                	slli	a5,a5,0x7
    800019c4:	0000f717          	auipc	a4,0xf
    800019c8:	1fc70713          	addi	a4,a4,508 # 80010bc0 <pid_lock>
    800019cc:	97ba                	add	a5,a5,a4
    800019ce:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	25a080e7          	jalr	602(ra) # 80000c2a <pop_off>
  return p;
}
    800019d8:	8526                	mv	a0,s1
    800019da:	60e2                	ld	ra,24(sp)
    800019dc:	6442                	ld	s0,16(sp)
    800019de:	64a2                	ld	s1,8(sp)
    800019e0:	6105                	addi	sp,sp,32
    800019e2:	8082                	ret

00000000800019e4 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019e4:	1141                	addi	sp,sp,-16
    800019e6:	e406                	sd	ra,8(sp)
    800019e8:	e022                	sd	s0,0(sp)
    800019ea:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019ec:	00000097          	auipc	ra,0x0
    800019f0:	fc0080e7          	jalr	-64(ra) # 800019ac <myproc>
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	296080e7          	jalr	662(ra) # 80000c8a <release>

  if (first) {
    800019fc:	00007797          	auipc	a5,0x7
    80001a00:	eb47a783          	lw	a5,-332(a5) # 800088b0 <first.2>
    80001a04:	eb89                	bnez	a5,80001a16 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a06:	00001097          	auipc	ra,0x1
    80001a0a:	d0a080e7          	jalr	-758(ra) # 80002710 <usertrapret>
}
    80001a0e:	60a2                	ld	ra,8(sp)
    80001a10:	6402                	ld	s0,0(sp)
    80001a12:	0141                	addi	sp,sp,16
    80001a14:	8082                	ret
    first = 0;
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	e807ad23          	sw	zero,-358(a5) # 800088b0 <first.2>
    fsinit(ROOTDEV);
    80001a1e:	4505                	li	a0,1
    80001a20:	00002097          	auipc	ra,0x2
    80001a24:	a92080e7          	jalr	-1390(ra) # 800034b2 <fsinit>
    80001a28:	bff9                	j	80001a06 <forkret+0x22>

0000000080001a2a <allocpid>:
{
    80001a2a:	1101                	addi	sp,sp,-32
    80001a2c:	ec06                	sd	ra,24(sp)
    80001a2e:	e822                	sd	s0,16(sp)
    80001a30:	e426                	sd	s1,8(sp)
    80001a32:	e04a                	sd	s2,0(sp)
    80001a34:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a36:	0000f917          	auipc	s2,0xf
    80001a3a:	18a90913          	addi	s2,s2,394 # 80010bc0 <pid_lock>
    80001a3e:	854a                	mv	a0,s2
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	196080e7          	jalr	406(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a48:	00007797          	auipc	a5,0x7
    80001a4c:	e6c78793          	addi	a5,a5,-404 # 800088b4 <nextpid>
    80001a50:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a52:	0014871b          	addiw	a4,s1,1
    80001a56:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	230080e7          	jalr	560(ra) # 80000c8a <release>
}
    80001a62:	8526                	mv	a0,s1
    80001a64:	60e2                	ld	ra,24(sp)
    80001a66:	6442                	ld	s0,16(sp)
    80001a68:	64a2                	ld	s1,8(sp)
    80001a6a:	6902                	ld	s2,0(sp)
    80001a6c:	6105                	addi	sp,sp,32
    80001a6e:	8082                	ret

0000000080001a70 <proc_pagetable>:
{
    80001a70:	1101                	addi	sp,sp,-32
    80001a72:	ec06                	sd	ra,24(sp)
    80001a74:	e822                	sd	s0,16(sp)
    80001a76:	e426                	sd	s1,8(sp)
    80001a78:	e04a                	sd	s2,0(sp)
    80001a7a:	1000                	addi	s0,sp,32
    80001a7c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a7e:	00000097          	auipc	ra,0x0
    80001a82:	8aa080e7          	jalr	-1878(ra) # 80001328 <uvmcreate>
    80001a86:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a88:	c121                	beqz	a0,80001ac8 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8a:	4729                	li	a4,10
    80001a8c:	00005697          	auipc	a3,0x5
    80001a90:	57468693          	addi	a3,a3,1396 # 80007000 <_trampoline>
    80001a94:	6605                	lui	a2,0x1
    80001a96:	040005b7          	lui	a1,0x4000
    80001a9a:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a9c:	05b2                	slli	a1,a1,0xc
    80001a9e:	fffff097          	auipc	ra,0xfffff
    80001aa2:	600080e7          	jalr	1536(ra) # 8000109e <mappages>
    80001aa6:	02054863          	bltz	a0,80001ad6 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aaa:	4719                	li	a4,6
    80001aac:	05893683          	ld	a3,88(s2)
    80001ab0:	6605                	lui	a2,0x1
    80001ab2:	020005b7          	lui	a1,0x2000
    80001ab6:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ab8:	05b6                	slli	a1,a1,0xd
    80001aba:	8526                	mv	a0,s1
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	5e2080e7          	jalr	1506(ra) # 8000109e <mappages>
    80001ac4:	02054163          	bltz	a0,80001ae6 <proc_pagetable+0x76>
}
    80001ac8:	8526                	mv	a0,s1
    80001aca:	60e2                	ld	ra,24(sp)
    80001acc:	6442                	ld	s0,16(sp)
    80001ace:	64a2                	ld	s1,8(sp)
    80001ad0:	6902                	ld	s2,0(sp)
    80001ad2:	6105                	addi	sp,sp,32
    80001ad4:	8082                	ret
    uvmfree(pagetable, 0);
    80001ad6:	4581                	li	a1,0
    80001ad8:	8526                	mv	a0,s1
    80001ada:	00000097          	auipc	ra,0x0
    80001ade:	a54080e7          	jalr	-1452(ra) # 8000152e <uvmfree>
    return 0;
    80001ae2:	4481                	li	s1,0
    80001ae4:	b7d5                	j	80001ac8 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ae6:	4681                	li	a3,0
    80001ae8:	4605                	li	a2,1
    80001aea:	040005b7          	lui	a1,0x4000
    80001aee:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001af0:	05b2                	slli	a1,a1,0xc
    80001af2:	8526                	mv	a0,s1
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	770080e7          	jalr	1904(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001afc:	4581                	li	a1,0
    80001afe:	8526                	mv	a0,s1
    80001b00:	00000097          	auipc	ra,0x0
    80001b04:	a2e080e7          	jalr	-1490(ra) # 8000152e <uvmfree>
    return 0;
    80001b08:	4481                	li	s1,0
    80001b0a:	bf7d                	j	80001ac8 <proc_pagetable+0x58>

0000000080001b0c <proc_freepagetable>:
{
    80001b0c:	1101                	addi	sp,sp,-32
    80001b0e:	ec06                	sd	ra,24(sp)
    80001b10:	e822                	sd	s0,16(sp)
    80001b12:	e426                	sd	s1,8(sp)
    80001b14:	e04a                	sd	s2,0(sp)
    80001b16:	1000                	addi	s0,sp,32
    80001b18:	84aa                	mv	s1,a0
    80001b1a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b1c:	4681                	li	a3,0
    80001b1e:	4605                	li	a2,1
    80001b20:	040005b7          	lui	a1,0x4000
    80001b24:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b26:	05b2                	slli	a1,a1,0xc
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	73c080e7          	jalr	1852(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b30:	4681                	li	a3,0
    80001b32:	4605                	li	a2,1
    80001b34:	020005b7          	lui	a1,0x2000
    80001b38:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b3a:	05b6                	slli	a1,a1,0xd
    80001b3c:	8526                	mv	a0,s1
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	726080e7          	jalr	1830(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b46:	85ca                	mv	a1,s2
    80001b48:	8526                	mv	a0,s1
    80001b4a:	00000097          	auipc	ra,0x0
    80001b4e:	9e4080e7          	jalr	-1564(ra) # 8000152e <uvmfree>
}
    80001b52:	60e2                	ld	ra,24(sp)
    80001b54:	6442                	ld	s0,16(sp)
    80001b56:	64a2                	ld	s1,8(sp)
    80001b58:	6902                	ld	s2,0(sp)
    80001b5a:	6105                	addi	sp,sp,32
    80001b5c:	8082                	ret

0000000080001b5e <freeproc>:
{
    80001b5e:	1101                	addi	sp,sp,-32
    80001b60:	ec06                	sd	ra,24(sp)
    80001b62:	e822                	sd	s0,16(sp)
    80001b64:	e426                	sd	s1,8(sp)
    80001b66:	1000                	addi	s0,sp,32
    80001b68:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b6a:	6d28                	ld	a0,88(a0)
    80001b6c:	c509                	beqz	a0,80001b76 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b6e:	fffff097          	auipc	ra,0xfffff
    80001b72:	e7a080e7          	jalr	-390(ra) # 800009e8 <kfree>
  p->trapframe = 0;
    80001b76:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b7a:	68a8                	ld	a0,80(s1)
    80001b7c:	c511                	beqz	a0,80001b88 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b7e:	64ac                	ld	a1,72(s1)
    80001b80:	00000097          	auipc	ra,0x0
    80001b84:	f8c080e7          	jalr	-116(ra) # 80001b0c <proc_freepagetable>
  p->pagetable = 0;
    80001b88:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b8c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b90:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b94:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b98:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b9c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba0:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba4:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ba8:	0004ac23          	sw	zero,24(s1)
}
    80001bac:	60e2                	ld	ra,24(sp)
    80001bae:	6442                	ld	s0,16(sp)
    80001bb0:	64a2                	ld	s1,8(sp)
    80001bb2:	6105                	addi	sp,sp,32
    80001bb4:	8082                	ret

0000000080001bb6 <allocproc>:
{
    80001bb6:	1101                	addi	sp,sp,-32
    80001bb8:	ec06                	sd	ra,24(sp)
    80001bba:	e822                	sd	s0,16(sp)
    80001bbc:	e426                	sd	s1,8(sp)
    80001bbe:	e04a                	sd	s2,0(sp)
    80001bc0:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bc2:	0000f497          	auipc	s1,0xf
    80001bc6:	42e48493          	addi	s1,s1,1070 # 80010ff0 <proc>
    80001bca:	00015917          	auipc	s2,0x15
    80001bce:	e2690913          	addi	s2,s2,-474 # 800169f0 <tickslock>
    acquire(&p->lock);
    80001bd2:	8526                	mv	a0,s1
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	002080e7          	jalr	2(ra) # 80000bd6 <acquire>
    if(p->state == UNUSED) {
    80001bdc:	4c9c                	lw	a5,24(s1)
    80001bde:	cf81                	beqz	a5,80001bf6 <allocproc+0x40>
      release(&p->lock);
    80001be0:	8526                	mv	a0,s1
    80001be2:	fffff097          	auipc	ra,0xfffff
    80001be6:	0a8080e7          	jalr	168(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bea:	16848493          	addi	s1,s1,360
    80001bee:	ff2492e3          	bne	s1,s2,80001bd2 <allocproc+0x1c>
  return 0;
    80001bf2:	4481                	li	s1,0
    80001bf4:	a889                	j	80001c46 <allocproc+0x90>
  p->pid = allocpid();
    80001bf6:	00000097          	auipc	ra,0x0
    80001bfa:	e34080e7          	jalr	-460(ra) # 80001a2a <allocpid>
    80001bfe:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c00:	4785                	li	a5,1
    80001c02:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c04:	fffff097          	auipc	ra,0xfffff
    80001c08:	ee2080e7          	jalr	-286(ra) # 80000ae6 <kalloc>
    80001c0c:	892a                	mv	s2,a0
    80001c0e:	eca8                	sd	a0,88(s1)
    80001c10:	c131                	beqz	a0,80001c54 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c12:	8526                	mv	a0,s1
    80001c14:	00000097          	auipc	ra,0x0
    80001c18:	e5c080e7          	jalr	-420(ra) # 80001a70 <proc_pagetable>
    80001c1c:	892a                	mv	s2,a0
    80001c1e:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c20:	c531                	beqz	a0,80001c6c <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c22:	07000613          	li	a2,112
    80001c26:	4581                	li	a1,0
    80001c28:	06048513          	addi	a0,s1,96
    80001c2c:	fffff097          	auipc	ra,0xfffff
    80001c30:	0a6080e7          	jalr	166(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c34:	00000797          	auipc	a5,0x0
    80001c38:	db078793          	addi	a5,a5,-592 # 800019e4 <forkret>
    80001c3c:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c3e:	60bc                	ld	a5,64(s1)
    80001c40:	6705                	lui	a4,0x1
    80001c42:	97ba                	add	a5,a5,a4
    80001c44:	f4bc                	sd	a5,104(s1)
}
    80001c46:	8526                	mv	a0,s1
    80001c48:	60e2                	ld	ra,24(sp)
    80001c4a:	6442                	ld	s0,16(sp)
    80001c4c:	64a2                	ld	s1,8(sp)
    80001c4e:	6902                	ld	s2,0(sp)
    80001c50:	6105                	addi	sp,sp,32
    80001c52:	8082                	ret
    freeproc(p);
    80001c54:	8526                	mv	a0,s1
    80001c56:	00000097          	auipc	ra,0x0
    80001c5a:	f08080e7          	jalr	-248(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c5e:	8526                	mv	a0,s1
    80001c60:	fffff097          	auipc	ra,0xfffff
    80001c64:	02a080e7          	jalr	42(ra) # 80000c8a <release>
    return 0;
    80001c68:	84ca                	mv	s1,s2
    80001c6a:	bff1                	j	80001c46 <allocproc+0x90>
    freeproc(p);
    80001c6c:	8526                	mv	a0,s1
    80001c6e:	00000097          	auipc	ra,0x0
    80001c72:	ef0080e7          	jalr	-272(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c76:	8526                	mv	a0,s1
    80001c78:	fffff097          	auipc	ra,0xfffff
    80001c7c:	012080e7          	jalr	18(ra) # 80000c8a <release>
    return 0;
    80001c80:	84ca                	mv	s1,s2
    80001c82:	b7d1                	j	80001c46 <allocproc+0x90>

0000000080001c84 <userinit>:
{
    80001c84:	1101                	addi	sp,sp,-32
    80001c86:	ec06                	sd	ra,24(sp)
    80001c88:	e822                	sd	s0,16(sp)
    80001c8a:	e426                	sd	s1,8(sp)
    80001c8c:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c8e:	00000097          	auipc	ra,0x0
    80001c92:	f28080e7          	jalr	-216(ra) # 80001bb6 <allocproc>
    80001c96:	84aa                	mv	s1,a0
  initproc = p;
    80001c98:	00007797          	auipc	a5,0x7
    80001c9c:	caa7b823          	sd	a0,-848(a5) # 80008948 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001ca0:	03400613          	li	a2,52
    80001ca4:	00007597          	auipc	a1,0x7
    80001ca8:	c1c58593          	addi	a1,a1,-996 # 800088c0 <initcode>
    80001cac:	6928                	ld	a0,80(a0)
    80001cae:	fffff097          	auipc	ra,0xfffff
    80001cb2:	6a8080e7          	jalr	1704(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001cb6:	6785                	lui	a5,0x1
    80001cb8:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cba:	6cb8                	ld	a4,88(s1)
    80001cbc:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cc0:	6cb8                	ld	a4,88(s1)
    80001cc2:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cc4:	4641                	li	a2,16
    80001cc6:	00006597          	auipc	a1,0x6
    80001cca:	53a58593          	addi	a1,a1,1338 # 80008200 <digits+0x1c0>
    80001cce:	15848513          	addi	a0,s1,344
    80001cd2:	fffff097          	auipc	ra,0xfffff
    80001cd6:	14a080e7          	jalr	330(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001cda:	00006517          	auipc	a0,0x6
    80001cde:	53650513          	addi	a0,a0,1334 # 80008210 <digits+0x1d0>
    80001ce2:	00002097          	auipc	ra,0x2
    80001ce6:	1fa080e7          	jalr	506(ra) # 80003edc <namei>
    80001cea:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cee:	478d                	li	a5,3
    80001cf0:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cf2:	8526                	mv	a0,s1
    80001cf4:	fffff097          	auipc	ra,0xfffff
    80001cf8:	f96080e7          	jalr	-106(ra) # 80000c8a <release>
}
    80001cfc:	60e2                	ld	ra,24(sp)
    80001cfe:	6442                	ld	s0,16(sp)
    80001d00:	64a2                	ld	s1,8(sp)
    80001d02:	6105                	addi	sp,sp,32
    80001d04:	8082                	ret

0000000080001d06 <growproc>:
{
    80001d06:	1101                	addi	sp,sp,-32
    80001d08:	ec06                	sd	ra,24(sp)
    80001d0a:	e822                	sd	s0,16(sp)
    80001d0c:	e426                	sd	s1,8(sp)
    80001d0e:	e04a                	sd	s2,0(sp)
    80001d10:	1000                	addi	s0,sp,32
    80001d12:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d14:	00000097          	auipc	ra,0x0
    80001d18:	c98080e7          	jalr	-872(ra) # 800019ac <myproc>
    80001d1c:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d1e:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d20:	01204c63          	bgtz	s2,80001d38 <growproc+0x32>
  } else if(n < 0){
    80001d24:	02094663          	bltz	s2,80001d50 <growproc+0x4a>
  p->sz = sz;
    80001d28:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d2a:	4501                	li	a0,0
}
    80001d2c:	60e2                	ld	ra,24(sp)
    80001d2e:	6442                	ld	s0,16(sp)
    80001d30:	64a2                	ld	s1,8(sp)
    80001d32:	6902                	ld	s2,0(sp)
    80001d34:	6105                	addi	sp,sp,32
    80001d36:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001d38:	4691                	li	a3,4
    80001d3a:	00b90633          	add	a2,s2,a1
    80001d3e:	6928                	ld	a0,80(a0)
    80001d40:	fffff097          	auipc	ra,0xfffff
    80001d44:	6d0080e7          	jalr	1744(ra) # 80001410 <uvmalloc>
    80001d48:	85aa                	mv	a1,a0
    80001d4a:	fd79                	bnez	a0,80001d28 <growproc+0x22>
      return -1;
    80001d4c:	557d                	li	a0,-1
    80001d4e:	bff9                	j	80001d2c <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d50:	00b90633          	add	a2,s2,a1
    80001d54:	6928                	ld	a0,80(a0)
    80001d56:	fffff097          	auipc	ra,0xfffff
    80001d5a:	672080e7          	jalr	1650(ra) # 800013c8 <uvmdealloc>
    80001d5e:	85aa                	mv	a1,a0
    80001d60:	b7e1                	j	80001d28 <growproc+0x22>

0000000080001d62 <fork>:
{
    80001d62:	7139                	addi	sp,sp,-64
    80001d64:	fc06                	sd	ra,56(sp)
    80001d66:	f822                	sd	s0,48(sp)
    80001d68:	f426                	sd	s1,40(sp)
    80001d6a:	f04a                	sd	s2,32(sp)
    80001d6c:	ec4e                	sd	s3,24(sp)
    80001d6e:	e852                	sd	s4,16(sp)
    80001d70:	e456                	sd	s5,8(sp)
    80001d72:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d74:	00000097          	auipc	ra,0x0
    80001d78:	c38080e7          	jalr	-968(ra) # 800019ac <myproc>
    80001d7c:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001d7e:	00000097          	auipc	ra,0x0
    80001d82:	e38080e7          	jalr	-456(ra) # 80001bb6 <allocproc>
    80001d86:	10050c63          	beqz	a0,80001e9e <fork+0x13c>
    80001d8a:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001d8c:	048ab603          	ld	a2,72(s5)
    80001d90:	692c                	ld	a1,80(a0)
    80001d92:	050ab503          	ld	a0,80(s5)
    80001d96:	fffff097          	auipc	ra,0xfffff
    80001d9a:	7d2080e7          	jalr	2002(ra) # 80001568 <uvmcopy>
    80001d9e:	04054863          	bltz	a0,80001dee <fork+0x8c>
  np->sz = p->sz;
    80001da2:	048ab783          	ld	a5,72(s5)
    80001da6:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001daa:	058ab683          	ld	a3,88(s5)
    80001dae:	87b6                	mv	a5,a3
    80001db0:	058a3703          	ld	a4,88(s4)
    80001db4:	12068693          	addi	a3,a3,288
    80001db8:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dbc:	6788                	ld	a0,8(a5)
    80001dbe:	6b8c                	ld	a1,16(a5)
    80001dc0:	6f90                	ld	a2,24(a5)
    80001dc2:	01073023          	sd	a6,0(a4)
    80001dc6:	e708                	sd	a0,8(a4)
    80001dc8:	eb0c                	sd	a1,16(a4)
    80001dca:	ef10                	sd	a2,24(a4)
    80001dcc:	02078793          	addi	a5,a5,32
    80001dd0:	02070713          	addi	a4,a4,32
    80001dd4:	fed792e3          	bne	a5,a3,80001db8 <fork+0x56>
  np->trapframe->a0 = 0;
    80001dd8:	058a3783          	ld	a5,88(s4)
    80001ddc:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001de0:	0d0a8493          	addi	s1,s5,208
    80001de4:	0d0a0913          	addi	s2,s4,208
    80001de8:	150a8993          	addi	s3,s5,336
    80001dec:	a00d                	j	80001e0e <fork+0xac>
    freeproc(np);
    80001dee:	8552                	mv	a0,s4
    80001df0:	00000097          	auipc	ra,0x0
    80001df4:	d6e080e7          	jalr	-658(ra) # 80001b5e <freeproc>
    release(&np->lock);
    80001df8:	8552                	mv	a0,s4
    80001dfa:	fffff097          	auipc	ra,0xfffff
    80001dfe:	e90080e7          	jalr	-368(ra) # 80000c8a <release>
    return -1;
    80001e02:	597d                	li	s2,-1
    80001e04:	a059                	j	80001e8a <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001e06:	04a1                	addi	s1,s1,8
    80001e08:	0921                	addi	s2,s2,8
    80001e0a:	01348b63          	beq	s1,s3,80001e20 <fork+0xbe>
    if(p->ofile[i])
    80001e0e:	6088                	ld	a0,0(s1)
    80001e10:	d97d                	beqz	a0,80001e06 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e12:	00002097          	auipc	ra,0x2
    80001e16:	760080e7          	jalr	1888(ra) # 80004572 <filedup>
    80001e1a:	00a93023          	sd	a0,0(s2)
    80001e1e:	b7e5                	j	80001e06 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e20:	150ab503          	ld	a0,336(s5)
    80001e24:	00002097          	auipc	ra,0x2
    80001e28:	8ce080e7          	jalr	-1842(ra) # 800036f2 <idup>
    80001e2c:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e30:	4641                	li	a2,16
    80001e32:	158a8593          	addi	a1,s5,344
    80001e36:	158a0513          	addi	a0,s4,344
    80001e3a:	fffff097          	auipc	ra,0xfffff
    80001e3e:	fe2080e7          	jalr	-30(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001e42:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e46:	8552                	mv	a0,s4
    80001e48:	fffff097          	auipc	ra,0xfffff
    80001e4c:	e42080e7          	jalr	-446(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001e50:	0000f497          	auipc	s1,0xf
    80001e54:	d8848493          	addi	s1,s1,-632 # 80010bd8 <wait_lock>
    80001e58:	8526                	mv	a0,s1
    80001e5a:	fffff097          	auipc	ra,0xfffff
    80001e5e:	d7c080e7          	jalr	-644(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001e62:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e66:	8526                	mv	a0,s1
    80001e68:	fffff097          	auipc	ra,0xfffff
    80001e6c:	e22080e7          	jalr	-478(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001e70:	8552                	mv	a0,s4
    80001e72:	fffff097          	auipc	ra,0xfffff
    80001e76:	d64080e7          	jalr	-668(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001e7a:	478d                	li	a5,3
    80001e7c:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001e80:	8552                	mv	a0,s4
    80001e82:	fffff097          	auipc	ra,0xfffff
    80001e86:	e08080e7          	jalr	-504(ra) # 80000c8a <release>
}
    80001e8a:	854a                	mv	a0,s2
    80001e8c:	70e2                	ld	ra,56(sp)
    80001e8e:	7442                	ld	s0,48(sp)
    80001e90:	74a2                	ld	s1,40(sp)
    80001e92:	7902                	ld	s2,32(sp)
    80001e94:	69e2                	ld	s3,24(sp)
    80001e96:	6a42                	ld	s4,16(sp)
    80001e98:	6aa2                	ld	s5,8(sp)
    80001e9a:	6121                	addi	sp,sp,64
    80001e9c:	8082                	ret
    return -1;
    80001e9e:	597d                	li	s2,-1
    80001ea0:	b7ed                	j	80001e8a <fork+0x128>

0000000080001ea2 <scheduler>:
{
    80001ea2:	7139                	addi	sp,sp,-64
    80001ea4:	fc06                	sd	ra,56(sp)
    80001ea6:	f822                	sd	s0,48(sp)
    80001ea8:	f426                	sd	s1,40(sp)
    80001eaa:	f04a                	sd	s2,32(sp)
    80001eac:	ec4e                	sd	s3,24(sp)
    80001eae:	e852                	sd	s4,16(sp)
    80001eb0:	e456                	sd	s5,8(sp)
    80001eb2:	e05a                	sd	s6,0(sp)
    80001eb4:	0080                	addi	s0,sp,64
    80001eb6:	8792                	mv	a5,tp
  int id = r_tp();
    80001eb8:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001eba:	00779a93          	slli	s5,a5,0x7
    80001ebe:	0000f717          	auipc	a4,0xf
    80001ec2:	d0270713          	addi	a4,a4,-766 # 80010bc0 <pid_lock>
    80001ec6:	9756                	add	a4,a4,s5
    80001ec8:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ecc:	0000f717          	auipc	a4,0xf
    80001ed0:	d2c70713          	addi	a4,a4,-724 # 80010bf8 <cpus+0x8>
    80001ed4:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001ed6:	498d                	li	s3,3
        p->state = RUNNING;
    80001ed8:	4b11                	li	s6,4
        c->proc = p;
    80001eda:	079e                	slli	a5,a5,0x7
    80001edc:	0000fa17          	auipc	s4,0xf
    80001ee0:	ce4a0a13          	addi	s4,s4,-796 # 80010bc0 <pid_lock>
    80001ee4:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ee6:	00015917          	auipc	s2,0x15
    80001eea:	b0a90913          	addi	s2,s2,-1270 # 800169f0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001eee:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001ef2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ef6:	10079073          	csrw	sstatus,a5
    80001efa:	0000f497          	auipc	s1,0xf
    80001efe:	0f648493          	addi	s1,s1,246 # 80010ff0 <proc>
    80001f02:	a811                	j	80001f16 <scheduler+0x74>
      release(&p->lock);
    80001f04:	8526                	mv	a0,s1
    80001f06:	fffff097          	auipc	ra,0xfffff
    80001f0a:	d84080e7          	jalr	-636(ra) # 80000c8a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f0e:	16848493          	addi	s1,s1,360
    80001f12:	fd248ee3          	beq	s1,s2,80001eee <scheduler+0x4c>
      acquire(&p->lock);
    80001f16:	8526                	mv	a0,s1
    80001f18:	fffff097          	auipc	ra,0xfffff
    80001f1c:	cbe080e7          	jalr	-834(ra) # 80000bd6 <acquire>
      if(p->state == RUNNABLE) {
    80001f20:	4c9c                	lw	a5,24(s1)
    80001f22:	ff3791e3          	bne	a5,s3,80001f04 <scheduler+0x62>
        p->state = RUNNING;
    80001f26:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f2a:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f2e:	06048593          	addi	a1,s1,96
    80001f32:	8556                	mv	a0,s5
    80001f34:	00000097          	auipc	ra,0x0
    80001f38:	732080e7          	jalr	1842(ra) # 80002666 <swtch>
        c->proc = 0;
    80001f3c:	020a3823          	sd	zero,48(s4)
    80001f40:	b7d1                	j	80001f04 <scheduler+0x62>

0000000080001f42 <sched>:
{
    80001f42:	7179                	addi	sp,sp,-48
    80001f44:	f406                	sd	ra,40(sp)
    80001f46:	f022                	sd	s0,32(sp)
    80001f48:	ec26                	sd	s1,24(sp)
    80001f4a:	e84a                	sd	s2,16(sp)
    80001f4c:	e44e                	sd	s3,8(sp)
    80001f4e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f50:	00000097          	auipc	ra,0x0
    80001f54:	a5c080e7          	jalr	-1444(ra) # 800019ac <myproc>
    80001f58:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f5a:	fffff097          	auipc	ra,0xfffff
    80001f5e:	c02080e7          	jalr	-1022(ra) # 80000b5c <holding>
    80001f62:	c93d                	beqz	a0,80001fd8 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f64:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f66:	2781                	sext.w	a5,a5
    80001f68:	079e                	slli	a5,a5,0x7
    80001f6a:	0000f717          	auipc	a4,0xf
    80001f6e:	c5670713          	addi	a4,a4,-938 # 80010bc0 <pid_lock>
    80001f72:	97ba                	add	a5,a5,a4
    80001f74:	0a87a703          	lw	a4,168(a5)
    80001f78:	4785                	li	a5,1
    80001f7a:	06f71763          	bne	a4,a5,80001fe8 <sched+0xa6>
  if(p->state == RUNNING)
    80001f7e:	4c98                	lw	a4,24(s1)
    80001f80:	4791                	li	a5,4
    80001f82:	06f70b63          	beq	a4,a5,80001ff8 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f86:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f8a:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f8c:	efb5                	bnez	a5,80002008 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f8e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f90:	0000f917          	auipc	s2,0xf
    80001f94:	c3090913          	addi	s2,s2,-976 # 80010bc0 <pid_lock>
    80001f98:	2781                	sext.w	a5,a5
    80001f9a:	079e                	slli	a5,a5,0x7
    80001f9c:	97ca                	add	a5,a5,s2
    80001f9e:	0ac7a983          	lw	s3,172(a5)
    80001fa2:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fa4:	2781                	sext.w	a5,a5
    80001fa6:	079e                	slli	a5,a5,0x7
    80001fa8:	0000f597          	auipc	a1,0xf
    80001fac:	c5058593          	addi	a1,a1,-944 # 80010bf8 <cpus+0x8>
    80001fb0:	95be                	add	a1,a1,a5
    80001fb2:	06048513          	addi	a0,s1,96
    80001fb6:	00000097          	auipc	ra,0x0
    80001fba:	6b0080e7          	jalr	1712(ra) # 80002666 <swtch>
    80001fbe:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fc0:	2781                	sext.w	a5,a5
    80001fc2:	079e                	slli	a5,a5,0x7
    80001fc4:	993e                	add	s2,s2,a5
    80001fc6:	0b392623          	sw	s3,172(s2)
}
    80001fca:	70a2                	ld	ra,40(sp)
    80001fcc:	7402                	ld	s0,32(sp)
    80001fce:	64e2                	ld	s1,24(sp)
    80001fd0:	6942                	ld	s2,16(sp)
    80001fd2:	69a2                	ld	s3,8(sp)
    80001fd4:	6145                	addi	sp,sp,48
    80001fd6:	8082                	ret
    panic("sched p->lock");
    80001fd8:	00006517          	auipc	a0,0x6
    80001fdc:	24050513          	addi	a0,a0,576 # 80008218 <digits+0x1d8>
    80001fe0:	ffffe097          	auipc	ra,0xffffe
    80001fe4:	560080e7          	jalr	1376(ra) # 80000540 <panic>
    panic("sched locks");
    80001fe8:	00006517          	auipc	a0,0x6
    80001fec:	24050513          	addi	a0,a0,576 # 80008228 <digits+0x1e8>
    80001ff0:	ffffe097          	auipc	ra,0xffffe
    80001ff4:	550080e7          	jalr	1360(ra) # 80000540 <panic>
    panic("sched running");
    80001ff8:	00006517          	auipc	a0,0x6
    80001ffc:	24050513          	addi	a0,a0,576 # 80008238 <digits+0x1f8>
    80002000:	ffffe097          	auipc	ra,0xffffe
    80002004:	540080e7          	jalr	1344(ra) # 80000540 <panic>
    panic("sched interruptible");
    80002008:	00006517          	auipc	a0,0x6
    8000200c:	24050513          	addi	a0,a0,576 # 80008248 <digits+0x208>
    80002010:	ffffe097          	auipc	ra,0xffffe
    80002014:	530080e7          	jalr	1328(ra) # 80000540 <panic>

0000000080002018 <yield>:
{
    80002018:	1101                	addi	sp,sp,-32
    8000201a:	ec06                	sd	ra,24(sp)
    8000201c:	e822                	sd	s0,16(sp)
    8000201e:	e426                	sd	s1,8(sp)
    80002020:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002022:	00000097          	auipc	ra,0x0
    80002026:	98a080e7          	jalr	-1654(ra) # 800019ac <myproc>
    8000202a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000202c:	fffff097          	auipc	ra,0xfffff
    80002030:	baa080e7          	jalr	-1110(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    80002034:	478d                	li	a5,3
    80002036:	cc9c                	sw	a5,24(s1)
  sched();
    80002038:	00000097          	auipc	ra,0x0
    8000203c:	f0a080e7          	jalr	-246(ra) # 80001f42 <sched>
  release(&p->lock);
    80002040:	8526                	mv	a0,s1
    80002042:	fffff097          	auipc	ra,0xfffff
    80002046:	c48080e7          	jalr	-952(ra) # 80000c8a <release>
}
    8000204a:	60e2                	ld	ra,24(sp)
    8000204c:	6442                	ld	s0,16(sp)
    8000204e:	64a2                	ld	s1,8(sp)
    80002050:	6105                	addi	sp,sp,32
    80002052:	8082                	ret

0000000080002054 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002054:	7179                	addi	sp,sp,-48
    80002056:	f406                	sd	ra,40(sp)
    80002058:	f022                	sd	s0,32(sp)
    8000205a:	ec26                	sd	s1,24(sp)
    8000205c:	e84a                	sd	s2,16(sp)
    8000205e:	e44e                	sd	s3,8(sp)
    80002060:	1800                	addi	s0,sp,48
    80002062:	89aa                	mv	s3,a0
    80002064:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002066:	00000097          	auipc	ra,0x0
    8000206a:	946080e7          	jalr	-1722(ra) # 800019ac <myproc>
    8000206e:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002070:	fffff097          	auipc	ra,0xfffff
    80002074:	b66080e7          	jalr	-1178(ra) # 80000bd6 <acquire>
  release(lk);
    80002078:	854a                	mv	a0,s2
    8000207a:	fffff097          	auipc	ra,0xfffff
    8000207e:	c10080e7          	jalr	-1008(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    80002082:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002086:	4789                	li	a5,2
    80002088:	cc9c                	sw	a5,24(s1)

  sched();
    8000208a:	00000097          	auipc	ra,0x0
    8000208e:	eb8080e7          	jalr	-328(ra) # 80001f42 <sched>

  // Tidy up.
  p->chan = 0;
    80002092:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002096:	8526                	mv	a0,s1
    80002098:	fffff097          	auipc	ra,0xfffff
    8000209c:	bf2080e7          	jalr	-1038(ra) # 80000c8a <release>
  acquire(lk);
    800020a0:	854a                	mv	a0,s2
    800020a2:	fffff097          	auipc	ra,0xfffff
    800020a6:	b34080e7          	jalr	-1228(ra) # 80000bd6 <acquire>
}
    800020aa:	70a2                	ld	ra,40(sp)
    800020ac:	7402                	ld	s0,32(sp)
    800020ae:	64e2                	ld	s1,24(sp)
    800020b0:	6942                	ld	s2,16(sp)
    800020b2:	69a2                	ld	s3,8(sp)
    800020b4:	6145                	addi	sp,sp,48
    800020b6:	8082                	ret

00000000800020b8 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800020b8:	7139                	addi	sp,sp,-64
    800020ba:	fc06                	sd	ra,56(sp)
    800020bc:	f822                	sd	s0,48(sp)
    800020be:	f426                	sd	s1,40(sp)
    800020c0:	f04a                	sd	s2,32(sp)
    800020c2:	ec4e                	sd	s3,24(sp)
    800020c4:	e852                	sd	s4,16(sp)
    800020c6:	e456                	sd	s5,8(sp)
    800020c8:	0080                	addi	s0,sp,64
    800020ca:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800020cc:	0000f497          	auipc	s1,0xf
    800020d0:	f2448493          	addi	s1,s1,-220 # 80010ff0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800020d4:	4989                	li	s3,2
        p->state = RUNNABLE;
    800020d6:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800020d8:	00015917          	auipc	s2,0x15
    800020dc:	91890913          	addi	s2,s2,-1768 # 800169f0 <tickslock>
    800020e0:	a811                	j	800020f4 <wakeup+0x3c>
      }
      release(&p->lock);
    800020e2:	8526                	mv	a0,s1
    800020e4:	fffff097          	auipc	ra,0xfffff
    800020e8:	ba6080e7          	jalr	-1114(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800020ec:	16848493          	addi	s1,s1,360
    800020f0:	03248663          	beq	s1,s2,8000211c <wakeup+0x64>
    if(p != myproc()){
    800020f4:	00000097          	auipc	ra,0x0
    800020f8:	8b8080e7          	jalr	-1864(ra) # 800019ac <myproc>
    800020fc:	fea488e3          	beq	s1,a0,800020ec <wakeup+0x34>
      acquire(&p->lock);
    80002100:	8526                	mv	a0,s1
    80002102:	fffff097          	auipc	ra,0xfffff
    80002106:	ad4080e7          	jalr	-1324(ra) # 80000bd6 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000210a:	4c9c                	lw	a5,24(s1)
    8000210c:	fd379be3          	bne	a5,s3,800020e2 <wakeup+0x2a>
    80002110:	709c                	ld	a5,32(s1)
    80002112:	fd4798e3          	bne	a5,s4,800020e2 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002116:	0154ac23          	sw	s5,24(s1)
    8000211a:	b7e1                	j	800020e2 <wakeup+0x2a>
    }
  }
}
    8000211c:	70e2                	ld	ra,56(sp)
    8000211e:	7442                	ld	s0,48(sp)
    80002120:	74a2                	ld	s1,40(sp)
    80002122:	7902                	ld	s2,32(sp)
    80002124:	69e2                	ld	s3,24(sp)
    80002126:	6a42                	ld	s4,16(sp)
    80002128:	6aa2                	ld	s5,8(sp)
    8000212a:	6121                	addi	sp,sp,64
    8000212c:	8082                	ret

000000008000212e <reparent>:
{
    8000212e:	7179                	addi	sp,sp,-48
    80002130:	f406                	sd	ra,40(sp)
    80002132:	f022                	sd	s0,32(sp)
    80002134:	ec26                	sd	s1,24(sp)
    80002136:	e84a                	sd	s2,16(sp)
    80002138:	e44e                	sd	s3,8(sp)
    8000213a:	e052                	sd	s4,0(sp)
    8000213c:	1800                	addi	s0,sp,48
    8000213e:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002140:	0000f497          	auipc	s1,0xf
    80002144:	eb048493          	addi	s1,s1,-336 # 80010ff0 <proc>
      pp->parent = initproc;
    80002148:	00007a17          	auipc	s4,0x7
    8000214c:	800a0a13          	addi	s4,s4,-2048 # 80008948 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002150:	00015997          	auipc	s3,0x15
    80002154:	8a098993          	addi	s3,s3,-1888 # 800169f0 <tickslock>
    80002158:	a029                	j	80002162 <reparent+0x34>
    8000215a:	16848493          	addi	s1,s1,360
    8000215e:	01348d63          	beq	s1,s3,80002178 <reparent+0x4a>
    if(pp->parent == p){
    80002162:	7c9c                	ld	a5,56(s1)
    80002164:	ff279be3          	bne	a5,s2,8000215a <reparent+0x2c>
      pp->parent = initproc;
    80002168:	000a3503          	ld	a0,0(s4)
    8000216c:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000216e:	00000097          	auipc	ra,0x0
    80002172:	f4a080e7          	jalr	-182(ra) # 800020b8 <wakeup>
    80002176:	b7d5                	j	8000215a <reparent+0x2c>
}
    80002178:	70a2                	ld	ra,40(sp)
    8000217a:	7402                	ld	s0,32(sp)
    8000217c:	64e2                	ld	s1,24(sp)
    8000217e:	6942                	ld	s2,16(sp)
    80002180:	69a2                	ld	s3,8(sp)
    80002182:	6a02                	ld	s4,0(sp)
    80002184:	6145                	addi	sp,sp,48
    80002186:	8082                	ret

0000000080002188 <exit>:
{
    80002188:	7179                	addi	sp,sp,-48
    8000218a:	f406                	sd	ra,40(sp)
    8000218c:	f022                	sd	s0,32(sp)
    8000218e:	ec26                	sd	s1,24(sp)
    80002190:	e84a                	sd	s2,16(sp)
    80002192:	e44e                	sd	s3,8(sp)
    80002194:	e052                	sd	s4,0(sp)
    80002196:	1800                	addi	s0,sp,48
    80002198:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000219a:	00000097          	auipc	ra,0x0
    8000219e:	812080e7          	jalr	-2030(ra) # 800019ac <myproc>
    800021a2:	89aa                	mv	s3,a0
  if(p == initproc)
    800021a4:	00006797          	auipc	a5,0x6
    800021a8:	7a47b783          	ld	a5,1956(a5) # 80008948 <initproc>
    800021ac:	0d050493          	addi	s1,a0,208
    800021b0:	15050913          	addi	s2,a0,336
    800021b4:	02a79363          	bne	a5,a0,800021da <exit+0x52>
    panic("init exiting");
    800021b8:	00006517          	auipc	a0,0x6
    800021bc:	0a850513          	addi	a0,a0,168 # 80008260 <digits+0x220>
    800021c0:	ffffe097          	auipc	ra,0xffffe
    800021c4:	380080e7          	jalr	896(ra) # 80000540 <panic>
      fileclose(f);
    800021c8:	00002097          	auipc	ra,0x2
    800021cc:	3fc080e7          	jalr	1020(ra) # 800045c4 <fileclose>
      p->ofile[fd] = 0;
    800021d0:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800021d4:	04a1                	addi	s1,s1,8
    800021d6:	01248563          	beq	s1,s2,800021e0 <exit+0x58>
    if(p->ofile[fd]){
    800021da:	6088                	ld	a0,0(s1)
    800021dc:	f575                	bnez	a0,800021c8 <exit+0x40>
    800021de:	bfdd                	j	800021d4 <exit+0x4c>
  begin_op();
    800021e0:	00002097          	auipc	ra,0x2
    800021e4:	f1c080e7          	jalr	-228(ra) # 800040fc <begin_op>
  iput(p->cwd);
    800021e8:	1509b503          	ld	a0,336(s3)
    800021ec:	00001097          	auipc	ra,0x1
    800021f0:	6fe080e7          	jalr	1790(ra) # 800038ea <iput>
  end_op();
    800021f4:	00002097          	auipc	ra,0x2
    800021f8:	f86080e7          	jalr	-122(ra) # 8000417a <end_op>
  p->cwd = 0;
    800021fc:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002200:	0000f497          	auipc	s1,0xf
    80002204:	9d848493          	addi	s1,s1,-1576 # 80010bd8 <wait_lock>
    80002208:	8526                	mv	a0,s1
    8000220a:	fffff097          	auipc	ra,0xfffff
    8000220e:	9cc080e7          	jalr	-1588(ra) # 80000bd6 <acquire>
  reparent(p);
    80002212:	854e                	mv	a0,s3
    80002214:	00000097          	auipc	ra,0x0
    80002218:	f1a080e7          	jalr	-230(ra) # 8000212e <reparent>
  wakeup(p->parent);
    8000221c:	0389b503          	ld	a0,56(s3)
    80002220:	00000097          	auipc	ra,0x0
    80002224:	e98080e7          	jalr	-360(ra) # 800020b8 <wakeup>
  acquire(&p->lock);
    80002228:	854e                	mv	a0,s3
    8000222a:	fffff097          	auipc	ra,0xfffff
    8000222e:	9ac080e7          	jalr	-1620(ra) # 80000bd6 <acquire>
  p->xstate = status;
    80002232:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002236:	4795                	li	a5,5
    80002238:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000223c:	8526                	mv	a0,s1
    8000223e:	fffff097          	auipc	ra,0xfffff
    80002242:	a4c080e7          	jalr	-1460(ra) # 80000c8a <release>
  sched();
    80002246:	00000097          	auipc	ra,0x0
    8000224a:	cfc080e7          	jalr	-772(ra) # 80001f42 <sched>
  panic("zombie exit");
    8000224e:	00006517          	auipc	a0,0x6
    80002252:	02250513          	addi	a0,a0,34 # 80008270 <digits+0x230>
    80002256:	ffffe097          	auipc	ra,0xffffe
    8000225a:	2ea080e7          	jalr	746(ra) # 80000540 <panic>

000000008000225e <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000225e:	7179                	addi	sp,sp,-48
    80002260:	f406                	sd	ra,40(sp)
    80002262:	f022                	sd	s0,32(sp)
    80002264:	ec26                	sd	s1,24(sp)
    80002266:	e84a                	sd	s2,16(sp)
    80002268:	e44e                	sd	s3,8(sp)
    8000226a:	1800                	addi	s0,sp,48
    8000226c:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000226e:	0000f497          	auipc	s1,0xf
    80002272:	d8248493          	addi	s1,s1,-638 # 80010ff0 <proc>
    80002276:	00014997          	auipc	s3,0x14
    8000227a:	77a98993          	addi	s3,s3,1914 # 800169f0 <tickslock>
    acquire(&p->lock);
    8000227e:	8526                	mv	a0,s1
    80002280:	fffff097          	auipc	ra,0xfffff
    80002284:	956080e7          	jalr	-1706(ra) # 80000bd6 <acquire>
    if(p->pid == pid){
    80002288:	589c                	lw	a5,48(s1)
    8000228a:	01278d63          	beq	a5,s2,800022a4 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000228e:	8526                	mv	a0,s1
    80002290:	fffff097          	auipc	ra,0xfffff
    80002294:	9fa080e7          	jalr	-1542(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002298:	16848493          	addi	s1,s1,360
    8000229c:	ff3491e3          	bne	s1,s3,8000227e <kill+0x20>
  }
  return -1;
    800022a0:	557d                	li	a0,-1
    800022a2:	a829                	j	800022bc <kill+0x5e>
      p->killed = 1;
    800022a4:	4785                	li	a5,1
    800022a6:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800022a8:	4c98                	lw	a4,24(s1)
    800022aa:	4789                	li	a5,2
    800022ac:	00f70f63          	beq	a4,a5,800022ca <kill+0x6c>
      release(&p->lock);
    800022b0:	8526                	mv	a0,s1
    800022b2:	fffff097          	auipc	ra,0xfffff
    800022b6:	9d8080e7          	jalr	-1576(ra) # 80000c8a <release>
      return 0;
    800022ba:	4501                	li	a0,0
}
    800022bc:	70a2                	ld	ra,40(sp)
    800022be:	7402                	ld	s0,32(sp)
    800022c0:	64e2                	ld	s1,24(sp)
    800022c2:	6942                	ld	s2,16(sp)
    800022c4:	69a2                	ld	s3,8(sp)
    800022c6:	6145                	addi	sp,sp,48
    800022c8:	8082                	ret
        p->state = RUNNABLE;
    800022ca:	478d                	li	a5,3
    800022cc:	cc9c                	sw	a5,24(s1)
    800022ce:	b7cd                	j	800022b0 <kill+0x52>

00000000800022d0 <setkilled>:

void
setkilled(struct proc *p)
{
    800022d0:	1101                	addi	sp,sp,-32
    800022d2:	ec06                	sd	ra,24(sp)
    800022d4:	e822                	sd	s0,16(sp)
    800022d6:	e426                	sd	s1,8(sp)
    800022d8:	1000                	addi	s0,sp,32
    800022da:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022dc:	fffff097          	auipc	ra,0xfffff
    800022e0:	8fa080e7          	jalr	-1798(ra) # 80000bd6 <acquire>
  p->killed = 1;
    800022e4:	4785                	li	a5,1
    800022e6:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800022e8:	8526                	mv	a0,s1
    800022ea:	fffff097          	auipc	ra,0xfffff
    800022ee:	9a0080e7          	jalr	-1632(ra) # 80000c8a <release>
}
    800022f2:	60e2                	ld	ra,24(sp)
    800022f4:	6442                	ld	s0,16(sp)
    800022f6:	64a2                	ld	s1,8(sp)
    800022f8:	6105                	addi	sp,sp,32
    800022fa:	8082                	ret

00000000800022fc <killed>:

int
killed(struct proc *p)
{
    800022fc:	1101                	addi	sp,sp,-32
    800022fe:	ec06                	sd	ra,24(sp)
    80002300:	e822                	sd	s0,16(sp)
    80002302:	e426                	sd	s1,8(sp)
    80002304:	e04a                	sd	s2,0(sp)
    80002306:	1000                	addi	s0,sp,32
    80002308:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    8000230a:	fffff097          	auipc	ra,0xfffff
    8000230e:	8cc080e7          	jalr	-1844(ra) # 80000bd6 <acquire>
  k = p->killed;
    80002312:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002316:	8526                	mv	a0,s1
    80002318:	fffff097          	auipc	ra,0xfffff
    8000231c:	972080e7          	jalr	-1678(ra) # 80000c8a <release>
  return k;
}
    80002320:	854a                	mv	a0,s2
    80002322:	60e2                	ld	ra,24(sp)
    80002324:	6442                	ld	s0,16(sp)
    80002326:	64a2                	ld	s1,8(sp)
    80002328:	6902                	ld	s2,0(sp)
    8000232a:	6105                	addi	sp,sp,32
    8000232c:	8082                	ret

000000008000232e <wait>:
{
    8000232e:	715d                	addi	sp,sp,-80
    80002330:	e486                	sd	ra,72(sp)
    80002332:	e0a2                	sd	s0,64(sp)
    80002334:	fc26                	sd	s1,56(sp)
    80002336:	f84a                	sd	s2,48(sp)
    80002338:	f44e                	sd	s3,40(sp)
    8000233a:	f052                	sd	s4,32(sp)
    8000233c:	ec56                	sd	s5,24(sp)
    8000233e:	e85a                	sd	s6,16(sp)
    80002340:	e45e                	sd	s7,8(sp)
    80002342:	e062                	sd	s8,0(sp)
    80002344:	0880                	addi	s0,sp,80
    80002346:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002348:	fffff097          	auipc	ra,0xfffff
    8000234c:	664080e7          	jalr	1636(ra) # 800019ac <myproc>
    80002350:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002352:	0000f517          	auipc	a0,0xf
    80002356:	88650513          	addi	a0,a0,-1914 # 80010bd8 <wait_lock>
    8000235a:	fffff097          	auipc	ra,0xfffff
    8000235e:	87c080e7          	jalr	-1924(ra) # 80000bd6 <acquire>
    havekids = 0;
    80002362:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    80002364:	4a15                	li	s4,5
        havekids = 1;
    80002366:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002368:	00014997          	auipc	s3,0x14
    8000236c:	68898993          	addi	s3,s3,1672 # 800169f0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002370:	0000fc17          	auipc	s8,0xf
    80002374:	868c0c13          	addi	s8,s8,-1944 # 80010bd8 <wait_lock>
    havekids = 0;
    80002378:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000237a:	0000f497          	auipc	s1,0xf
    8000237e:	c7648493          	addi	s1,s1,-906 # 80010ff0 <proc>
    80002382:	a0bd                	j	800023f0 <wait+0xc2>
          pid = pp->pid;
    80002384:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002388:	000b0e63          	beqz	s6,800023a4 <wait+0x76>
    8000238c:	4691                	li	a3,4
    8000238e:	02c48613          	addi	a2,s1,44
    80002392:	85da                	mv	a1,s6
    80002394:	05093503          	ld	a0,80(s2)
    80002398:	fffff097          	auipc	ra,0xfffff
    8000239c:	2d4080e7          	jalr	724(ra) # 8000166c <copyout>
    800023a0:	02054563          	bltz	a0,800023ca <wait+0x9c>
          freeproc(pp);
    800023a4:	8526                	mv	a0,s1
    800023a6:	fffff097          	auipc	ra,0xfffff
    800023aa:	7b8080e7          	jalr	1976(ra) # 80001b5e <freeproc>
          release(&pp->lock);
    800023ae:	8526                	mv	a0,s1
    800023b0:	fffff097          	auipc	ra,0xfffff
    800023b4:	8da080e7          	jalr	-1830(ra) # 80000c8a <release>
          release(&wait_lock);
    800023b8:	0000f517          	auipc	a0,0xf
    800023bc:	82050513          	addi	a0,a0,-2016 # 80010bd8 <wait_lock>
    800023c0:	fffff097          	auipc	ra,0xfffff
    800023c4:	8ca080e7          	jalr	-1846(ra) # 80000c8a <release>
          return pid;
    800023c8:	a0b5                	j	80002434 <wait+0x106>
            release(&pp->lock);
    800023ca:	8526                	mv	a0,s1
    800023cc:	fffff097          	auipc	ra,0xfffff
    800023d0:	8be080e7          	jalr	-1858(ra) # 80000c8a <release>
            release(&wait_lock);
    800023d4:	0000f517          	auipc	a0,0xf
    800023d8:	80450513          	addi	a0,a0,-2044 # 80010bd8 <wait_lock>
    800023dc:	fffff097          	auipc	ra,0xfffff
    800023e0:	8ae080e7          	jalr	-1874(ra) # 80000c8a <release>
            return -1;
    800023e4:	59fd                	li	s3,-1
    800023e6:	a0b9                	j	80002434 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023e8:	16848493          	addi	s1,s1,360
    800023ec:	03348463          	beq	s1,s3,80002414 <wait+0xe6>
      if(pp->parent == p){
    800023f0:	7c9c                	ld	a5,56(s1)
    800023f2:	ff279be3          	bne	a5,s2,800023e8 <wait+0xba>
        acquire(&pp->lock);
    800023f6:	8526                	mv	a0,s1
    800023f8:	ffffe097          	auipc	ra,0xffffe
    800023fc:	7de080e7          	jalr	2014(ra) # 80000bd6 <acquire>
        if(pp->state == ZOMBIE){
    80002400:	4c9c                	lw	a5,24(s1)
    80002402:	f94781e3          	beq	a5,s4,80002384 <wait+0x56>
        release(&pp->lock);
    80002406:	8526                	mv	a0,s1
    80002408:	fffff097          	auipc	ra,0xfffff
    8000240c:	882080e7          	jalr	-1918(ra) # 80000c8a <release>
        havekids = 1;
    80002410:	8756                	mv	a4,s5
    80002412:	bfd9                	j	800023e8 <wait+0xba>
    if(!havekids || killed(p)){
    80002414:	c719                	beqz	a4,80002422 <wait+0xf4>
    80002416:	854a                	mv	a0,s2
    80002418:	00000097          	auipc	ra,0x0
    8000241c:	ee4080e7          	jalr	-284(ra) # 800022fc <killed>
    80002420:	c51d                	beqz	a0,8000244e <wait+0x120>
      release(&wait_lock);
    80002422:	0000e517          	auipc	a0,0xe
    80002426:	7b650513          	addi	a0,a0,1974 # 80010bd8 <wait_lock>
    8000242a:	fffff097          	auipc	ra,0xfffff
    8000242e:	860080e7          	jalr	-1952(ra) # 80000c8a <release>
      return -1;
    80002432:	59fd                	li	s3,-1
}
    80002434:	854e                	mv	a0,s3
    80002436:	60a6                	ld	ra,72(sp)
    80002438:	6406                	ld	s0,64(sp)
    8000243a:	74e2                	ld	s1,56(sp)
    8000243c:	7942                	ld	s2,48(sp)
    8000243e:	79a2                	ld	s3,40(sp)
    80002440:	7a02                	ld	s4,32(sp)
    80002442:	6ae2                	ld	s5,24(sp)
    80002444:	6b42                	ld	s6,16(sp)
    80002446:	6ba2                	ld	s7,8(sp)
    80002448:	6c02                	ld	s8,0(sp)
    8000244a:	6161                	addi	sp,sp,80
    8000244c:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000244e:	85e2                	mv	a1,s8
    80002450:	854a                	mv	a0,s2
    80002452:	00000097          	auipc	ra,0x0
    80002456:	c02080e7          	jalr	-1022(ra) # 80002054 <sleep>
    havekids = 0;
    8000245a:	bf39                	j	80002378 <wait+0x4a>

000000008000245c <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000245c:	7179                	addi	sp,sp,-48
    8000245e:	f406                	sd	ra,40(sp)
    80002460:	f022                	sd	s0,32(sp)
    80002462:	ec26                	sd	s1,24(sp)
    80002464:	e84a                	sd	s2,16(sp)
    80002466:	e44e                	sd	s3,8(sp)
    80002468:	e052                	sd	s4,0(sp)
    8000246a:	1800                	addi	s0,sp,48
    8000246c:	84aa                	mv	s1,a0
    8000246e:	892e                	mv	s2,a1
    80002470:	89b2                	mv	s3,a2
    80002472:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002474:	fffff097          	auipc	ra,0xfffff
    80002478:	538080e7          	jalr	1336(ra) # 800019ac <myproc>
  if(user_dst){
    8000247c:	c08d                	beqz	s1,8000249e <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000247e:	86d2                	mv	a3,s4
    80002480:	864e                	mv	a2,s3
    80002482:	85ca                	mv	a1,s2
    80002484:	6928                	ld	a0,80(a0)
    80002486:	fffff097          	auipc	ra,0xfffff
    8000248a:	1e6080e7          	jalr	486(ra) # 8000166c <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000248e:	70a2                	ld	ra,40(sp)
    80002490:	7402                	ld	s0,32(sp)
    80002492:	64e2                	ld	s1,24(sp)
    80002494:	6942                	ld	s2,16(sp)
    80002496:	69a2                	ld	s3,8(sp)
    80002498:	6a02                	ld	s4,0(sp)
    8000249a:	6145                	addi	sp,sp,48
    8000249c:	8082                	ret
    memmove((char *)dst, src, len);
    8000249e:	000a061b          	sext.w	a2,s4
    800024a2:	85ce                	mv	a1,s3
    800024a4:	854a                	mv	a0,s2
    800024a6:	fffff097          	auipc	ra,0xfffff
    800024aa:	888080e7          	jalr	-1912(ra) # 80000d2e <memmove>
    return 0;
    800024ae:	8526                	mv	a0,s1
    800024b0:	bff9                	j	8000248e <either_copyout+0x32>

00000000800024b2 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024b2:	7179                	addi	sp,sp,-48
    800024b4:	f406                	sd	ra,40(sp)
    800024b6:	f022                	sd	s0,32(sp)
    800024b8:	ec26                	sd	s1,24(sp)
    800024ba:	e84a                	sd	s2,16(sp)
    800024bc:	e44e                	sd	s3,8(sp)
    800024be:	e052                	sd	s4,0(sp)
    800024c0:	1800                	addi	s0,sp,48
    800024c2:	892a                	mv	s2,a0
    800024c4:	84ae                	mv	s1,a1
    800024c6:	89b2                	mv	s3,a2
    800024c8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024ca:	fffff097          	auipc	ra,0xfffff
    800024ce:	4e2080e7          	jalr	1250(ra) # 800019ac <myproc>
  if(user_src){
    800024d2:	c08d                	beqz	s1,800024f4 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024d4:	86d2                	mv	a3,s4
    800024d6:	864e                	mv	a2,s3
    800024d8:	85ca                	mv	a1,s2
    800024da:	6928                	ld	a0,80(a0)
    800024dc:	fffff097          	auipc	ra,0xfffff
    800024e0:	21c080e7          	jalr	540(ra) # 800016f8 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024e4:	70a2                	ld	ra,40(sp)
    800024e6:	7402                	ld	s0,32(sp)
    800024e8:	64e2                	ld	s1,24(sp)
    800024ea:	6942                	ld	s2,16(sp)
    800024ec:	69a2                	ld	s3,8(sp)
    800024ee:	6a02                	ld	s4,0(sp)
    800024f0:	6145                	addi	sp,sp,48
    800024f2:	8082                	ret
    memmove(dst, (char*)src, len);
    800024f4:	000a061b          	sext.w	a2,s4
    800024f8:	85ce                	mv	a1,s3
    800024fa:	854a                	mv	a0,s2
    800024fc:	fffff097          	auipc	ra,0xfffff
    80002500:	832080e7          	jalr	-1998(ra) # 80000d2e <memmove>
    return 0;
    80002504:	8526                	mv	a0,s1
    80002506:	bff9                	j	800024e4 <either_copyin+0x32>

0000000080002508 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002508:	715d                	addi	sp,sp,-80
    8000250a:	e486                	sd	ra,72(sp)
    8000250c:	e0a2                	sd	s0,64(sp)
    8000250e:	fc26                	sd	s1,56(sp)
    80002510:	f84a                	sd	s2,48(sp)
    80002512:	f44e                	sd	s3,40(sp)
    80002514:	f052                	sd	s4,32(sp)
    80002516:	ec56                	sd	s5,24(sp)
    80002518:	e85a                	sd	s6,16(sp)
    8000251a:	e45e                	sd	s7,8(sp)
    8000251c:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000251e:	00006517          	auipc	a0,0x6
    80002522:	baa50513          	addi	a0,a0,-1110 # 800080c8 <digits+0x88>
    80002526:	ffffe097          	auipc	ra,0xffffe
    8000252a:	064080e7          	jalr	100(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000252e:	0000f497          	auipc	s1,0xf
    80002532:	c1a48493          	addi	s1,s1,-998 # 80011148 <proc+0x158>
    80002536:	00014917          	auipc	s2,0x14
    8000253a:	61290913          	addi	s2,s2,1554 # 80016b48 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000253e:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002540:	00006997          	auipc	s3,0x6
    80002544:	d4098993          	addi	s3,s3,-704 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002548:	00006a97          	auipc	s5,0x6
    8000254c:	d40a8a93          	addi	s5,s5,-704 # 80008288 <digits+0x248>
    printf("\n");
    80002550:	00006a17          	auipc	s4,0x6
    80002554:	b78a0a13          	addi	s4,s4,-1160 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002558:	00006b97          	auipc	s7,0x6
    8000255c:	d80b8b93          	addi	s7,s7,-640 # 800082d8 <states.1>
    80002560:	a00d                	j	80002582 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002562:	ed86a583          	lw	a1,-296(a3)
    80002566:	8556                	mv	a0,s5
    80002568:	ffffe097          	auipc	ra,0xffffe
    8000256c:	022080e7          	jalr	34(ra) # 8000058a <printf>
    printf("\n");
    80002570:	8552                	mv	a0,s4
    80002572:	ffffe097          	auipc	ra,0xffffe
    80002576:	018080e7          	jalr	24(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000257a:	16848493          	addi	s1,s1,360
    8000257e:	03248263          	beq	s1,s2,800025a2 <procdump+0x9a>
    if(p->state == UNUSED)
    80002582:	86a6                	mv	a3,s1
    80002584:	ec04a783          	lw	a5,-320(s1)
    80002588:	dbed                	beqz	a5,8000257a <procdump+0x72>
      state = "???";
    8000258a:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000258c:	fcfb6be3          	bltu	s6,a5,80002562 <procdump+0x5a>
    80002590:	02079713          	slli	a4,a5,0x20
    80002594:	01d75793          	srli	a5,a4,0x1d
    80002598:	97de                	add	a5,a5,s7
    8000259a:	6390                	ld	a2,0(a5)
    8000259c:	f279                	bnez	a2,80002562 <procdump+0x5a>
      state = "???";
    8000259e:	864e                	mv	a2,s3
    800025a0:	b7c9                	j	80002562 <procdump+0x5a>
  }
}
    800025a2:	60a6                	ld	ra,72(sp)
    800025a4:	6406                	ld	s0,64(sp)
    800025a6:	74e2                	ld	s1,56(sp)
    800025a8:	7942                	ld	s2,48(sp)
    800025aa:	79a2                	ld	s3,40(sp)
    800025ac:	7a02                	ld	s4,32(sp)
    800025ae:	6ae2                	ld	s5,24(sp)
    800025b0:	6b42                	ld	s6,16(sp)
    800025b2:	6ba2                	ld	s7,8(sp)
    800025b4:	6161                	addi	sp,sp,80
    800025b6:	8082                	ret

00000000800025b8 <printrunproc>:

void
printrunproc(void) {
    800025b8:	715d                	addi	sp,sp,-80
    800025ba:	e486                	sd	ra,72(sp)
    800025bc:	e0a2                	sd	s0,64(sp)
    800025be:	fc26                	sd	s1,56(sp)
    800025c0:	f84a                	sd	s2,48(sp)
    800025c2:	f44e                	sd	s3,40(sp)
    800025c4:	f052                	sd	s4,32(sp)
    800025c6:	ec56                	sd	s5,24(sp)
    800025c8:	e85a                	sd	s6,16(sp)
    800025ca:	e45e                	sd	s7,8(sp)
    800025cc:	0880                	addi	s0,sp,80
  };
  struct proc *p;
  // char *state;
  int state_nr;

  printf("\n");
    800025ce:	00006517          	auipc	a0,0x6
    800025d2:	afa50513          	addi	a0,a0,-1286 # 800080c8 <digits+0x88>
    800025d6:	ffffe097          	auipc	ra,0xffffe
    800025da:	fb4080e7          	jalr	-76(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025de:	0000f497          	auipc	s1,0xf
    800025e2:	b6a48493          	addi	s1,s1,-1174 # 80011148 <proc+0x158>
    800025e6:	00014997          	auipc	s3,0x14
    800025ea:	56298993          	addi	s3,s3,1378 # 80016b48 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025ee:	4b15                	li	s6,5
      // state = states[p->state];
      state_nr = p->state;
    else
      // state = "???";
      state_nr = -1;
    800025f0:	597d                	li	s2,-1
    // printf("%s (%d): %s", p->name, p->pid, state);
    printf("%s (%d): %d", p->name, p->pid, state_nr);
    800025f2:	00006a97          	auipc	s5,0x6
    800025f6:	ca6a8a93          	addi	s5,s5,-858 # 80008298 <digits+0x258>
    printf("\n");
    800025fa:	00006a17          	auipc	s4,0x6
    800025fe:	acea0a13          	addi	s4,s4,-1330 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002602:	00006b97          	auipc	s7,0x6
    80002606:	cd6b8b93          	addi	s7,s7,-810 # 800082d8 <states.1>
    8000260a:	a00d                	j	8000262c <printrunproc+0x74>
    printf("%s (%d): %d", p->name, p->pid, state_nr);
    8000260c:	ed85a603          	lw	a2,-296(a1)
    80002610:	8556                	mv	a0,s5
    80002612:	ffffe097          	auipc	ra,0xffffe
    80002616:	f78080e7          	jalr	-136(ra) # 8000058a <printf>
    printf("\n");
    8000261a:	8552                	mv	a0,s4
    8000261c:	ffffe097          	auipc	ra,0xffffe
    80002620:	f6e080e7          	jalr	-146(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002624:	16848493          	addi	s1,s1,360
    80002628:	03348463          	beq	s1,s3,80002650 <printrunproc+0x98>
    if(p->state == UNUSED)
    8000262c:	85a6                	mv	a1,s1
    8000262e:	ec04a783          	lw	a5,-320(s1)
    80002632:	dbed                	beqz	a5,80002624 <printrunproc+0x6c>
      state_nr = -1;
    80002634:	86ca                	mv	a3,s2
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002636:	fcfb6be3          	bltu	s6,a5,8000260c <printrunproc+0x54>
    8000263a:	02079693          	slli	a3,a5,0x20
    8000263e:	01d6d713          	srli	a4,a3,0x1d
    80002642:	975e                	add	a4,a4,s7
    80002644:	7b18                	ld	a4,48(a4)
      state_nr = -1;
    80002646:	86ca                	mv	a3,s2
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002648:	d371                	beqz	a4,8000260c <printrunproc+0x54>
      state_nr = p->state;
    8000264a:	0007869b          	sext.w	a3,a5
    8000264e:	bf7d                	j	8000260c <printrunproc+0x54>
  }
}
    80002650:	60a6                	ld	ra,72(sp)
    80002652:	6406                	ld	s0,64(sp)
    80002654:	74e2                	ld	s1,56(sp)
    80002656:	7942                	ld	s2,48(sp)
    80002658:	79a2                	ld	s3,40(sp)
    8000265a:	7a02                	ld	s4,32(sp)
    8000265c:	6ae2                	ld	s5,24(sp)
    8000265e:	6b42                	ld	s6,16(sp)
    80002660:	6ba2                	ld	s7,8(sp)
    80002662:	6161                	addi	sp,sp,80
    80002664:	8082                	ret

0000000080002666 <swtch>:
    80002666:	00153023          	sd	ra,0(a0)
    8000266a:	00253423          	sd	sp,8(a0)
    8000266e:	e900                	sd	s0,16(a0)
    80002670:	ed04                	sd	s1,24(a0)
    80002672:	03253023          	sd	s2,32(a0)
    80002676:	03353423          	sd	s3,40(a0)
    8000267a:	03453823          	sd	s4,48(a0)
    8000267e:	03553c23          	sd	s5,56(a0)
    80002682:	05653023          	sd	s6,64(a0)
    80002686:	05753423          	sd	s7,72(a0)
    8000268a:	05853823          	sd	s8,80(a0)
    8000268e:	05953c23          	sd	s9,88(a0)
    80002692:	07a53023          	sd	s10,96(a0)
    80002696:	07b53423          	sd	s11,104(a0)
    8000269a:	0005b083          	ld	ra,0(a1)
    8000269e:	0085b103          	ld	sp,8(a1)
    800026a2:	6980                	ld	s0,16(a1)
    800026a4:	6d84                	ld	s1,24(a1)
    800026a6:	0205b903          	ld	s2,32(a1)
    800026aa:	0285b983          	ld	s3,40(a1)
    800026ae:	0305ba03          	ld	s4,48(a1)
    800026b2:	0385ba83          	ld	s5,56(a1)
    800026b6:	0405bb03          	ld	s6,64(a1)
    800026ba:	0485bb83          	ld	s7,72(a1)
    800026be:	0505bc03          	ld	s8,80(a1)
    800026c2:	0585bc83          	ld	s9,88(a1)
    800026c6:	0605bd03          	ld	s10,96(a1)
    800026ca:	0685bd83          	ld	s11,104(a1)
    800026ce:	8082                	ret

00000000800026d0 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026d0:	1141                	addi	sp,sp,-16
    800026d2:	e406                	sd	ra,8(sp)
    800026d4:	e022                	sd	s0,0(sp)
    800026d6:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026d8:	00006597          	auipc	a1,0x6
    800026dc:	c6058593          	addi	a1,a1,-928 # 80008338 <states.0+0x30>
    800026e0:	00014517          	auipc	a0,0x14
    800026e4:	31050513          	addi	a0,a0,784 # 800169f0 <tickslock>
    800026e8:	ffffe097          	auipc	ra,0xffffe
    800026ec:	45e080e7          	jalr	1118(ra) # 80000b46 <initlock>
}
    800026f0:	60a2                	ld	ra,8(sp)
    800026f2:	6402                	ld	s0,0(sp)
    800026f4:	0141                	addi	sp,sp,16
    800026f6:	8082                	ret

00000000800026f8 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026f8:	1141                	addi	sp,sp,-16
    800026fa:	e422                	sd	s0,8(sp)
    800026fc:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026fe:	00003797          	auipc	a5,0x3
    80002702:	51278793          	addi	a5,a5,1298 # 80005c10 <kernelvec>
    80002706:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000270a:	6422                	ld	s0,8(sp)
    8000270c:	0141                	addi	sp,sp,16
    8000270e:	8082                	ret

0000000080002710 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002710:	1141                	addi	sp,sp,-16
    80002712:	e406                	sd	ra,8(sp)
    80002714:	e022                	sd	s0,0(sp)
    80002716:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002718:	fffff097          	auipc	ra,0xfffff
    8000271c:	294080e7          	jalr	660(ra) # 800019ac <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002720:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002724:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002726:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    8000272a:	00005697          	auipc	a3,0x5
    8000272e:	8d668693          	addi	a3,a3,-1834 # 80007000 <_trampoline>
    80002732:	00005717          	auipc	a4,0x5
    80002736:	8ce70713          	addi	a4,a4,-1842 # 80007000 <_trampoline>
    8000273a:	8f15                	sub	a4,a4,a3
    8000273c:	040007b7          	lui	a5,0x4000
    80002740:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002742:	07b2                	slli	a5,a5,0xc
    80002744:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002746:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000274a:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000274c:	18002673          	csrr	a2,satp
    80002750:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002752:	6d30                	ld	a2,88(a0)
    80002754:	6138                	ld	a4,64(a0)
    80002756:	6585                	lui	a1,0x1
    80002758:	972e                	add	a4,a4,a1
    8000275a:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000275c:	6d38                	ld	a4,88(a0)
    8000275e:	00000617          	auipc	a2,0x0
    80002762:	13060613          	addi	a2,a2,304 # 8000288e <usertrap>
    80002766:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002768:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000276a:	8612                	mv	a2,tp
    8000276c:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000276e:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002772:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002776:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000277a:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000277e:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002780:	6f18                	ld	a4,24(a4)
    80002782:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002786:	6928                	ld	a0,80(a0)
    80002788:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    8000278a:	00005717          	auipc	a4,0x5
    8000278e:	91270713          	addi	a4,a4,-1774 # 8000709c <userret>
    80002792:	8f15                	sub	a4,a4,a3
    80002794:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002796:	577d                	li	a4,-1
    80002798:	177e                	slli	a4,a4,0x3f
    8000279a:	8d59                	or	a0,a0,a4
    8000279c:	9782                	jalr	a5
}
    8000279e:	60a2                	ld	ra,8(sp)
    800027a0:	6402                	ld	s0,0(sp)
    800027a2:	0141                	addi	sp,sp,16
    800027a4:	8082                	ret

00000000800027a6 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800027a6:	1101                	addi	sp,sp,-32
    800027a8:	ec06                	sd	ra,24(sp)
    800027aa:	e822                	sd	s0,16(sp)
    800027ac:	e426                	sd	s1,8(sp)
    800027ae:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027b0:	00014497          	auipc	s1,0x14
    800027b4:	24048493          	addi	s1,s1,576 # 800169f0 <tickslock>
    800027b8:	8526                	mv	a0,s1
    800027ba:	ffffe097          	auipc	ra,0xffffe
    800027be:	41c080e7          	jalr	1052(ra) # 80000bd6 <acquire>
  ticks++;
    800027c2:	00006517          	auipc	a0,0x6
    800027c6:	18e50513          	addi	a0,a0,398 # 80008950 <ticks>
    800027ca:	411c                	lw	a5,0(a0)
    800027cc:	2785                	addiw	a5,a5,1
    800027ce:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027d0:	00000097          	auipc	ra,0x0
    800027d4:	8e8080e7          	jalr	-1816(ra) # 800020b8 <wakeup>
  release(&tickslock);
    800027d8:	8526                	mv	a0,s1
    800027da:	ffffe097          	auipc	ra,0xffffe
    800027de:	4b0080e7          	jalr	1200(ra) # 80000c8a <release>
}
    800027e2:	60e2                	ld	ra,24(sp)
    800027e4:	6442                	ld	s0,16(sp)
    800027e6:	64a2                	ld	s1,8(sp)
    800027e8:	6105                	addi	sp,sp,32
    800027ea:	8082                	ret

00000000800027ec <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800027ec:	1101                	addi	sp,sp,-32
    800027ee:	ec06                	sd	ra,24(sp)
    800027f0:	e822                	sd	s0,16(sp)
    800027f2:	e426                	sd	s1,8(sp)
    800027f4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027f6:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800027fa:	00074d63          	bltz	a4,80002814 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800027fe:	57fd                	li	a5,-1
    80002800:	17fe                	slli	a5,a5,0x3f
    80002802:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002804:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002806:	06f70363          	beq	a4,a5,8000286c <devintr+0x80>
  }
}
    8000280a:	60e2                	ld	ra,24(sp)
    8000280c:	6442                	ld	s0,16(sp)
    8000280e:	64a2                	ld	s1,8(sp)
    80002810:	6105                	addi	sp,sp,32
    80002812:	8082                	ret
     (scause & 0xff) == 9){
    80002814:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    80002818:	46a5                	li	a3,9
    8000281a:	fed792e3          	bne	a5,a3,800027fe <devintr+0x12>
    int irq = plic_claim();
    8000281e:	00003097          	auipc	ra,0x3
    80002822:	4fa080e7          	jalr	1274(ra) # 80005d18 <plic_claim>
    80002826:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002828:	47a9                	li	a5,10
    8000282a:	02f50763          	beq	a0,a5,80002858 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000282e:	4785                	li	a5,1
    80002830:	02f50963          	beq	a0,a5,80002862 <devintr+0x76>
    return 1;
    80002834:	4505                	li	a0,1
    } else if(irq){
    80002836:	d8f1                	beqz	s1,8000280a <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002838:	85a6                	mv	a1,s1
    8000283a:	00006517          	auipc	a0,0x6
    8000283e:	b0650513          	addi	a0,a0,-1274 # 80008340 <states.0+0x38>
    80002842:	ffffe097          	auipc	ra,0xffffe
    80002846:	d48080e7          	jalr	-696(ra) # 8000058a <printf>
      plic_complete(irq);
    8000284a:	8526                	mv	a0,s1
    8000284c:	00003097          	auipc	ra,0x3
    80002850:	4f0080e7          	jalr	1264(ra) # 80005d3c <plic_complete>
    return 1;
    80002854:	4505                	li	a0,1
    80002856:	bf55                	j	8000280a <devintr+0x1e>
      uartintr();
    80002858:	ffffe097          	auipc	ra,0xffffe
    8000285c:	140080e7          	jalr	320(ra) # 80000998 <uartintr>
    80002860:	b7ed                	j	8000284a <devintr+0x5e>
      virtio_disk_intr();
    80002862:	00004097          	auipc	ra,0x4
    80002866:	9a2080e7          	jalr	-1630(ra) # 80006204 <virtio_disk_intr>
    8000286a:	b7c5                	j	8000284a <devintr+0x5e>
    if(cpuid() == 0){
    8000286c:	fffff097          	auipc	ra,0xfffff
    80002870:	114080e7          	jalr	276(ra) # 80001980 <cpuid>
    80002874:	c901                	beqz	a0,80002884 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002876:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000287a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000287c:	14479073          	csrw	sip,a5
    return 2;
    80002880:	4509                	li	a0,2
    80002882:	b761                	j	8000280a <devintr+0x1e>
      clockintr();
    80002884:	00000097          	auipc	ra,0x0
    80002888:	f22080e7          	jalr	-222(ra) # 800027a6 <clockintr>
    8000288c:	b7ed                	j	80002876 <devintr+0x8a>

000000008000288e <usertrap>:
{
    8000288e:	1101                	addi	sp,sp,-32
    80002890:	ec06                	sd	ra,24(sp)
    80002892:	e822                	sd	s0,16(sp)
    80002894:	e426                	sd	s1,8(sp)
    80002896:	e04a                	sd	s2,0(sp)
    80002898:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000289a:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000289e:	1007f793          	andi	a5,a5,256
    800028a2:	e3b1                	bnez	a5,800028e6 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028a4:	00003797          	auipc	a5,0x3
    800028a8:	36c78793          	addi	a5,a5,876 # 80005c10 <kernelvec>
    800028ac:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028b0:	fffff097          	auipc	ra,0xfffff
    800028b4:	0fc080e7          	jalr	252(ra) # 800019ac <myproc>
    800028b8:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028ba:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028bc:	14102773          	csrr	a4,sepc
    800028c0:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028c2:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800028c6:	47a1                	li	a5,8
    800028c8:	02f70763          	beq	a4,a5,800028f6 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    800028cc:	00000097          	auipc	ra,0x0
    800028d0:	f20080e7          	jalr	-224(ra) # 800027ec <devintr>
    800028d4:	892a                	mv	s2,a0
    800028d6:	c151                	beqz	a0,8000295a <usertrap+0xcc>
  if(killed(p))
    800028d8:	8526                	mv	a0,s1
    800028da:	00000097          	auipc	ra,0x0
    800028de:	a22080e7          	jalr	-1502(ra) # 800022fc <killed>
    800028e2:	c929                	beqz	a0,80002934 <usertrap+0xa6>
    800028e4:	a099                	j	8000292a <usertrap+0x9c>
    panic("usertrap: not from user mode");
    800028e6:	00006517          	auipc	a0,0x6
    800028ea:	a7a50513          	addi	a0,a0,-1414 # 80008360 <states.0+0x58>
    800028ee:	ffffe097          	auipc	ra,0xffffe
    800028f2:	c52080e7          	jalr	-942(ra) # 80000540 <panic>
    if(killed(p))
    800028f6:	00000097          	auipc	ra,0x0
    800028fa:	a06080e7          	jalr	-1530(ra) # 800022fc <killed>
    800028fe:	e921                	bnez	a0,8000294e <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002900:	6cb8                	ld	a4,88(s1)
    80002902:	6f1c                	ld	a5,24(a4)
    80002904:	0791                	addi	a5,a5,4
    80002906:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002908:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000290c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002910:	10079073          	csrw	sstatus,a5
    syscall();
    80002914:	00000097          	auipc	ra,0x0
    80002918:	2d4080e7          	jalr	724(ra) # 80002be8 <syscall>
  if(killed(p))
    8000291c:	8526                	mv	a0,s1
    8000291e:	00000097          	auipc	ra,0x0
    80002922:	9de080e7          	jalr	-1570(ra) # 800022fc <killed>
    80002926:	c911                	beqz	a0,8000293a <usertrap+0xac>
    80002928:	4901                	li	s2,0
    exit(-1);
    8000292a:	557d                	li	a0,-1
    8000292c:	00000097          	auipc	ra,0x0
    80002930:	85c080e7          	jalr	-1956(ra) # 80002188 <exit>
  if(which_dev == 2)
    80002934:	4789                	li	a5,2
    80002936:	04f90f63          	beq	s2,a5,80002994 <usertrap+0x106>
  usertrapret();
    8000293a:	00000097          	auipc	ra,0x0
    8000293e:	dd6080e7          	jalr	-554(ra) # 80002710 <usertrapret>
}
    80002942:	60e2                	ld	ra,24(sp)
    80002944:	6442                	ld	s0,16(sp)
    80002946:	64a2                	ld	s1,8(sp)
    80002948:	6902                	ld	s2,0(sp)
    8000294a:	6105                	addi	sp,sp,32
    8000294c:	8082                	ret
      exit(-1);
    8000294e:	557d                	li	a0,-1
    80002950:	00000097          	auipc	ra,0x0
    80002954:	838080e7          	jalr	-1992(ra) # 80002188 <exit>
    80002958:	b765                	j	80002900 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000295a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000295e:	5890                	lw	a2,48(s1)
    80002960:	00006517          	auipc	a0,0x6
    80002964:	a2050513          	addi	a0,a0,-1504 # 80008380 <states.0+0x78>
    80002968:	ffffe097          	auipc	ra,0xffffe
    8000296c:	c22080e7          	jalr	-990(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002970:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002974:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002978:	00006517          	auipc	a0,0x6
    8000297c:	a3850513          	addi	a0,a0,-1480 # 800083b0 <states.0+0xa8>
    80002980:	ffffe097          	auipc	ra,0xffffe
    80002984:	c0a080e7          	jalr	-1014(ra) # 8000058a <printf>
    setkilled(p);
    80002988:	8526                	mv	a0,s1
    8000298a:	00000097          	auipc	ra,0x0
    8000298e:	946080e7          	jalr	-1722(ra) # 800022d0 <setkilled>
    80002992:	b769                	j	8000291c <usertrap+0x8e>
    yield();
    80002994:	fffff097          	auipc	ra,0xfffff
    80002998:	684080e7          	jalr	1668(ra) # 80002018 <yield>
    8000299c:	bf79                	j	8000293a <usertrap+0xac>

000000008000299e <kerneltrap>:
{
    8000299e:	7179                	addi	sp,sp,-48
    800029a0:	f406                	sd	ra,40(sp)
    800029a2:	f022                	sd	s0,32(sp)
    800029a4:	ec26                	sd	s1,24(sp)
    800029a6:	e84a                	sd	s2,16(sp)
    800029a8:	e44e                	sd	s3,8(sp)
    800029aa:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029ac:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029b0:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029b4:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800029b8:	1004f793          	andi	a5,s1,256
    800029bc:	cb85                	beqz	a5,800029ec <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029be:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800029c2:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800029c4:	ef85                	bnez	a5,800029fc <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800029c6:	00000097          	auipc	ra,0x0
    800029ca:	e26080e7          	jalr	-474(ra) # 800027ec <devintr>
    800029ce:	cd1d                	beqz	a0,80002a0c <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029d0:	4789                	li	a5,2
    800029d2:	06f50a63          	beq	a0,a5,80002a46 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029d6:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029da:	10049073          	csrw	sstatus,s1
}
    800029de:	70a2                	ld	ra,40(sp)
    800029e0:	7402                	ld	s0,32(sp)
    800029e2:	64e2                	ld	s1,24(sp)
    800029e4:	6942                	ld	s2,16(sp)
    800029e6:	69a2                	ld	s3,8(sp)
    800029e8:	6145                	addi	sp,sp,48
    800029ea:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800029ec:	00006517          	auipc	a0,0x6
    800029f0:	9e450513          	addi	a0,a0,-1564 # 800083d0 <states.0+0xc8>
    800029f4:	ffffe097          	auipc	ra,0xffffe
    800029f8:	b4c080e7          	jalr	-1204(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    800029fc:	00006517          	auipc	a0,0x6
    80002a00:	9fc50513          	addi	a0,a0,-1540 # 800083f8 <states.0+0xf0>
    80002a04:	ffffe097          	auipc	ra,0xffffe
    80002a08:	b3c080e7          	jalr	-1220(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002a0c:	85ce                	mv	a1,s3
    80002a0e:	00006517          	auipc	a0,0x6
    80002a12:	a0a50513          	addi	a0,a0,-1526 # 80008418 <states.0+0x110>
    80002a16:	ffffe097          	auipc	ra,0xffffe
    80002a1a:	b74080e7          	jalr	-1164(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a1e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a22:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a26:	00006517          	auipc	a0,0x6
    80002a2a:	a0250513          	addi	a0,a0,-1534 # 80008428 <states.0+0x120>
    80002a2e:	ffffe097          	auipc	ra,0xffffe
    80002a32:	b5c080e7          	jalr	-1188(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002a36:	00006517          	auipc	a0,0x6
    80002a3a:	a0a50513          	addi	a0,a0,-1526 # 80008440 <states.0+0x138>
    80002a3e:	ffffe097          	auipc	ra,0xffffe
    80002a42:	b02080e7          	jalr	-1278(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a46:	fffff097          	auipc	ra,0xfffff
    80002a4a:	f66080e7          	jalr	-154(ra) # 800019ac <myproc>
    80002a4e:	d541                	beqz	a0,800029d6 <kerneltrap+0x38>
    80002a50:	fffff097          	auipc	ra,0xfffff
    80002a54:	f5c080e7          	jalr	-164(ra) # 800019ac <myproc>
    80002a58:	4d18                	lw	a4,24(a0)
    80002a5a:	4791                	li	a5,4
    80002a5c:	f6f71de3          	bne	a4,a5,800029d6 <kerneltrap+0x38>
    yield();
    80002a60:	fffff097          	auipc	ra,0xfffff
    80002a64:	5b8080e7          	jalr	1464(ra) # 80002018 <yield>
    80002a68:	b7bd                	j	800029d6 <kerneltrap+0x38>

0000000080002a6a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a6a:	1101                	addi	sp,sp,-32
    80002a6c:	ec06                	sd	ra,24(sp)
    80002a6e:	e822                	sd	s0,16(sp)
    80002a70:	e426                	sd	s1,8(sp)
    80002a72:	1000                	addi	s0,sp,32
    80002a74:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a76:	fffff097          	auipc	ra,0xfffff
    80002a7a:	f36080e7          	jalr	-202(ra) # 800019ac <myproc>
  switch (n) {
    80002a7e:	4795                	li	a5,5
    80002a80:	0497e163          	bltu	a5,s1,80002ac2 <argraw+0x58>
    80002a84:	048a                	slli	s1,s1,0x2
    80002a86:	00006717          	auipc	a4,0x6
    80002a8a:	9f270713          	addi	a4,a4,-1550 # 80008478 <states.0+0x170>
    80002a8e:	94ba                	add	s1,s1,a4
    80002a90:	409c                	lw	a5,0(s1)
    80002a92:	97ba                	add	a5,a5,a4
    80002a94:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a96:	6d3c                	ld	a5,88(a0)
    80002a98:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a9a:	60e2                	ld	ra,24(sp)
    80002a9c:	6442                	ld	s0,16(sp)
    80002a9e:	64a2                	ld	s1,8(sp)
    80002aa0:	6105                	addi	sp,sp,32
    80002aa2:	8082                	ret
    return p->trapframe->a1;
    80002aa4:	6d3c                	ld	a5,88(a0)
    80002aa6:	7fa8                	ld	a0,120(a5)
    80002aa8:	bfcd                	j	80002a9a <argraw+0x30>
    return p->trapframe->a2;
    80002aaa:	6d3c                	ld	a5,88(a0)
    80002aac:	63c8                	ld	a0,128(a5)
    80002aae:	b7f5                	j	80002a9a <argraw+0x30>
    return p->trapframe->a3;
    80002ab0:	6d3c                	ld	a5,88(a0)
    80002ab2:	67c8                	ld	a0,136(a5)
    80002ab4:	b7dd                	j	80002a9a <argraw+0x30>
    return p->trapframe->a4;
    80002ab6:	6d3c                	ld	a5,88(a0)
    80002ab8:	6bc8                	ld	a0,144(a5)
    80002aba:	b7c5                	j	80002a9a <argraw+0x30>
    return p->trapframe->a5;
    80002abc:	6d3c                	ld	a5,88(a0)
    80002abe:	6fc8                	ld	a0,152(a5)
    80002ac0:	bfe9                	j	80002a9a <argraw+0x30>
  panic("argraw");
    80002ac2:	00006517          	auipc	a0,0x6
    80002ac6:	98e50513          	addi	a0,a0,-1650 # 80008450 <states.0+0x148>
    80002aca:	ffffe097          	auipc	ra,0xffffe
    80002ace:	a76080e7          	jalr	-1418(ra) # 80000540 <panic>

0000000080002ad2 <fetchaddr>:
{
    80002ad2:	1101                	addi	sp,sp,-32
    80002ad4:	ec06                	sd	ra,24(sp)
    80002ad6:	e822                	sd	s0,16(sp)
    80002ad8:	e426                	sd	s1,8(sp)
    80002ada:	e04a                	sd	s2,0(sp)
    80002adc:	1000                	addi	s0,sp,32
    80002ade:	84aa                	mv	s1,a0
    80002ae0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ae2:	fffff097          	auipc	ra,0xfffff
    80002ae6:	eca080e7          	jalr	-310(ra) # 800019ac <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002aea:	653c                	ld	a5,72(a0)
    80002aec:	02f4f863          	bgeu	s1,a5,80002b1c <fetchaddr+0x4a>
    80002af0:	00848713          	addi	a4,s1,8
    80002af4:	02e7e663          	bltu	a5,a4,80002b20 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002af8:	46a1                	li	a3,8
    80002afa:	8626                	mv	a2,s1
    80002afc:	85ca                	mv	a1,s2
    80002afe:	6928                	ld	a0,80(a0)
    80002b00:	fffff097          	auipc	ra,0xfffff
    80002b04:	bf8080e7          	jalr	-1032(ra) # 800016f8 <copyin>
    80002b08:	00a03533          	snez	a0,a0
    80002b0c:	40a00533          	neg	a0,a0
}
    80002b10:	60e2                	ld	ra,24(sp)
    80002b12:	6442                	ld	s0,16(sp)
    80002b14:	64a2                	ld	s1,8(sp)
    80002b16:	6902                	ld	s2,0(sp)
    80002b18:	6105                	addi	sp,sp,32
    80002b1a:	8082                	ret
    return -1;
    80002b1c:	557d                	li	a0,-1
    80002b1e:	bfcd                	j	80002b10 <fetchaddr+0x3e>
    80002b20:	557d                	li	a0,-1
    80002b22:	b7fd                	j	80002b10 <fetchaddr+0x3e>

0000000080002b24 <fetchstr>:
{
    80002b24:	7179                	addi	sp,sp,-48
    80002b26:	f406                	sd	ra,40(sp)
    80002b28:	f022                	sd	s0,32(sp)
    80002b2a:	ec26                	sd	s1,24(sp)
    80002b2c:	e84a                	sd	s2,16(sp)
    80002b2e:	e44e                	sd	s3,8(sp)
    80002b30:	1800                	addi	s0,sp,48
    80002b32:	892a                	mv	s2,a0
    80002b34:	84ae                	mv	s1,a1
    80002b36:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b38:	fffff097          	auipc	ra,0xfffff
    80002b3c:	e74080e7          	jalr	-396(ra) # 800019ac <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002b40:	86ce                	mv	a3,s3
    80002b42:	864a                	mv	a2,s2
    80002b44:	85a6                	mv	a1,s1
    80002b46:	6928                	ld	a0,80(a0)
    80002b48:	fffff097          	auipc	ra,0xfffff
    80002b4c:	c3e080e7          	jalr	-962(ra) # 80001786 <copyinstr>
    80002b50:	00054e63          	bltz	a0,80002b6c <fetchstr+0x48>
  return strlen(buf);
    80002b54:	8526                	mv	a0,s1
    80002b56:	ffffe097          	auipc	ra,0xffffe
    80002b5a:	2f8080e7          	jalr	760(ra) # 80000e4e <strlen>
}
    80002b5e:	70a2                	ld	ra,40(sp)
    80002b60:	7402                	ld	s0,32(sp)
    80002b62:	64e2                	ld	s1,24(sp)
    80002b64:	6942                	ld	s2,16(sp)
    80002b66:	69a2                	ld	s3,8(sp)
    80002b68:	6145                	addi	sp,sp,48
    80002b6a:	8082                	ret
    return -1;
    80002b6c:	557d                	li	a0,-1
    80002b6e:	bfc5                	j	80002b5e <fetchstr+0x3a>

0000000080002b70 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002b70:	1101                	addi	sp,sp,-32
    80002b72:	ec06                	sd	ra,24(sp)
    80002b74:	e822                	sd	s0,16(sp)
    80002b76:	e426                	sd	s1,8(sp)
    80002b78:	1000                	addi	s0,sp,32
    80002b7a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b7c:	00000097          	auipc	ra,0x0
    80002b80:	eee080e7          	jalr	-274(ra) # 80002a6a <argraw>
    80002b84:	c088                	sw	a0,0(s1)
}
    80002b86:	60e2                	ld	ra,24(sp)
    80002b88:	6442                	ld	s0,16(sp)
    80002b8a:	64a2                	ld	s1,8(sp)
    80002b8c:	6105                	addi	sp,sp,32
    80002b8e:	8082                	ret

0000000080002b90 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002b90:	1101                	addi	sp,sp,-32
    80002b92:	ec06                	sd	ra,24(sp)
    80002b94:	e822                	sd	s0,16(sp)
    80002b96:	e426                	sd	s1,8(sp)
    80002b98:	1000                	addi	s0,sp,32
    80002b9a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b9c:	00000097          	auipc	ra,0x0
    80002ba0:	ece080e7          	jalr	-306(ra) # 80002a6a <argraw>
    80002ba4:	e088                	sd	a0,0(s1)
}
    80002ba6:	60e2                	ld	ra,24(sp)
    80002ba8:	6442                	ld	s0,16(sp)
    80002baa:	64a2                	ld	s1,8(sp)
    80002bac:	6105                	addi	sp,sp,32
    80002bae:	8082                	ret

0000000080002bb0 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002bb0:	7179                	addi	sp,sp,-48
    80002bb2:	f406                	sd	ra,40(sp)
    80002bb4:	f022                	sd	s0,32(sp)
    80002bb6:	ec26                	sd	s1,24(sp)
    80002bb8:	e84a                	sd	s2,16(sp)
    80002bba:	1800                	addi	s0,sp,48
    80002bbc:	84ae                	mv	s1,a1
    80002bbe:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002bc0:	fd840593          	addi	a1,s0,-40
    80002bc4:	00000097          	auipc	ra,0x0
    80002bc8:	fcc080e7          	jalr	-52(ra) # 80002b90 <argaddr>
  return fetchstr(addr, buf, max);
    80002bcc:	864a                	mv	a2,s2
    80002bce:	85a6                	mv	a1,s1
    80002bd0:	fd843503          	ld	a0,-40(s0)
    80002bd4:	00000097          	auipc	ra,0x0
    80002bd8:	f50080e7          	jalr	-176(ra) # 80002b24 <fetchstr>
}
    80002bdc:	70a2                	ld	ra,40(sp)
    80002bde:	7402                	ld	s0,32(sp)
    80002be0:	64e2                	ld	s1,24(sp)
    80002be2:	6942                	ld	s2,16(sp)
    80002be4:	6145                	addi	sp,sp,48
    80002be6:	8082                	ret

0000000080002be8 <syscall>:
[SYS_runproc]   sys_runproc,
};

void
syscall(void)
{
    80002be8:	1101                	addi	sp,sp,-32
    80002bea:	ec06                	sd	ra,24(sp)
    80002bec:	e822                	sd	s0,16(sp)
    80002bee:	e426                	sd	s1,8(sp)
    80002bf0:	e04a                	sd	s2,0(sp)
    80002bf2:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002bf4:	fffff097          	auipc	ra,0xfffff
    80002bf8:	db8080e7          	jalr	-584(ra) # 800019ac <myproc>
    80002bfc:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002bfe:	05853903          	ld	s2,88(a0)
    80002c02:	0a893783          	ld	a5,168(s2)
    80002c06:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c0a:	37fd                	addiw	a5,a5,-1
    80002c0c:	475d                	li	a4,23
    80002c0e:	00f76f63          	bltu	a4,a5,80002c2c <syscall+0x44>
    80002c12:	00369713          	slli	a4,a3,0x3
    80002c16:	00006797          	auipc	a5,0x6
    80002c1a:	87a78793          	addi	a5,a5,-1926 # 80008490 <syscalls>
    80002c1e:	97ba                	add	a5,a5,a4
    80002c20:	639c                	ld	a5,0(a5)
    80002c22:	c789                	beqz	a5,80002c2c <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002c24:	9782                	jalr	a5
    80002c26:	06a93823          	sd	a0,112(s2)
    80002c2a:	a839                	j	80002c48 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c2c:	15848613          	addi	a2,s1,344
    80002c30:	588c                	lw	a1,48(s1)
    80002c32:	00006517          	auipc	a0,0x6
    80002c36:	82650513          	addi	a0,a0,-2010 # 80008458 <states.0+0x150>
    80002c3a:	ffffe097          	auipc	ra,0xffffe
    80002c3e:	950080e7          	jalr	-1712(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c42:	6cbc                	ld	a5,88(s1)
    80002c44:	577d                	li	a4,-1
    80002c46:	fbb8                	sd	a4,112(a5)
  }
}
    80002c48:	60e2                	ld	ra,24(sp)
    80002c4a:	6442                	ld	s0,16(sp)
    80002c4c:	64a2                	ld	s1,8(sp)
    80002c4e:	6902                	ld	s2,0(sp)
    80002c50:	6105                	addi	sp,sp,32
    80002c52:	8082                	ret

0000000080002c54 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c54:	1101                	addi	sp,sp,-32
    80002c56:	ec06                	sd	ra,24(sp)
    80002c58:	e822                	sd	s0,16(sp)
    80002c5a:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002c5c:	fec40593          	addi	a1,s0,-20
    80002c60:	4501                	li	a0,0
    80002c62:	00000097          	auipc	ra,0x0
    80002c66:	f0e080e7          	jalr	-242(ra) # 80002b70 <argint>
  exit(n);
    80002c6a:	fec42503          	lw	a0,-20(s0)
    80002c6e:	fffff097          	auipc	ra,0xfffff
    80002c72:	51a080e7          	jalr	1306(ra) # 80002188 <exit>
  return 0;  // not reached
}
    80002c76:	4501                	li	a0,0
    80002c78:	60e2                	ld	ra,24(sp)
    80002c7a:	6442                	ld	s0,16(sp)
    80002c7c:	6105                	addi	sp,sp,32
    80002c7e:	8082                	ret

0000000080002c80 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c80:	1141                	addi	sp,sp,-16
    80002c82:	e406                	sd	ra,8(sp)
    80002c84:	e022                	sd	s0,0(sp)
    80002c86:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c88:	fffff097          	auipc	ra,0xfffff
    80002c8c:	d24080e7          	jalr	-732(ra) # 800019ac <myproc>
}
    80002c90:	5908                	lw	a0,48(a0)
    80002c92:	60a2                	ld	ra,8(sp)
    80002c94:	6402                	ld	s0,0(sp)
    80002c96:	0141                	addi	sp,sp,16
    80002c98:	8082                	ret

0000000080002c9a <sys_fork>:

uint64
sys_fork(void)
{
    80002c9a:	1141                	addi	sp,sp,-16
    80002c9c:	e406                	sd	ra,8(sp)
    80002c9e:	e022                	sd	s0,0(sp)
    80002ca0:	0800                	addi	s0,sp,16
  return fork();
    80002ca2:	fffff097          	auipc	ra,0xfffff
    80002ca6:	0c0080e7          	jalr	192(ra) # 80001d62 <fork>
}
    80002caa:	60a2                	ld	ra,8(sp)
    80002cac:	6402                	ld	s0,0(sp)
    80002cae:	0141                	addi	sp,sp,16
    80002cb0:	8082                	ret

0000000080002cb2 <sys_wait>:

uint64
sys_wait(void)
{
    80002cb2:	1101                	addi	sp,sp,-32
    80002cb4:	ec06                	sd	ra,24(sp)
    80002cb6:	e822                	sd	s0,16(sp)
    80002cb8:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002cba:	fe840593          	addi	a1,s0,-24
    80002cbe:	4501                	li	a0,0
    80002cc0:	00000097          	auipc	ra,0x0
    80002cc4:	ed0080e7          	jalr	-304(ra) # 80002b90 <argaddr>
  return wait(p);
    80002cc8:	fe843503          	ld	a0,-24(s0)
    80002ccc:	fffff097          	auipc	ra,0xfffff
    80002cd0:	662080e7          	jalr	1634(ra) # 8000232e <wait>
}
    80002cd4:	60e2                	ld	ra,24(sp)
    80002cd6:	6442                	ld	s0,16(sp)
    80002cd8:	6105                	addi	sp,sp,32
    80002cda:	8082                	ret

0000000080002cdc <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002cdc:	7179                	addi	sp,sp,-48
    80002cde:	f406                	sd	ra,40(sp)
    80002ce0:	f022                	sd	s0,32(sp)
    80002ce2:	ec26                	sd	s1,24(sp)
    80002ce4:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002ce6:	fdc40593          	addi	a1,s0,-36
    80002cea:	4501                	li	a0,0
    80002cec:	00000097          	auipc	ra,0x0
    80002cf0:	e84080e7          	jalr	-380(ra) # 80002b70 <argint>
  addr = myproc()->sz;
    80002cf4:	fffff097          	auipc	ra,0xfffff
    80002cf8:	cb8080e7          	jalr	-840(ra) # 800019ac <myproc>
    80002cfc:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002cfe:	fdc42503          	lw	a0,-36(s0)
    80002d02:	fffff097          	auipc	ra,0xfffff
    80002d06:	004080e7          	jalr	4(ra) # 80001d06 <growproc>
    80002d0a:	00054863          	bltz	a0,80002d1a <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002d0e:	8526                	mv	a0,s1
    80002d10:	70a2                	ld	ra,40(sp)
    80002d12:	7402                	ld	s0,32(sp)
    80002d14:	64e2                	ld	s1,24(sp)
    80002d16:	6145                	addi	sp,sp,48
    80002d18:	8082                	ret
    return -1;
    80002d1a:	54fd                	li	s1,-1
    80002d1c:	bfcd                	j	80002d0e <sys_sbrk+0x32>

0000000080002d1e <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d1e:	7139                	addi	sp,sp,-64
    80002d20:	fc06                	sd	ra,56(sp)
    80002d22:	f822                	sd	s0,48(sp)
    80002d24:	f426                	sd	s1,40(sp)
    80002d26:	f04a                	sd	s2,32(sp)
    80002d28:	ec4e                	sd	s3,24(sp)
    80002d2a:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002d2c:	fcc40593          	addi	a1,s0,-52
    80002d30:	4501                	li	a0,0
    80002d32:	00000097          	auipc	ra,0x0
    80002d36:	e3e080e7          	jalr	-450(ra) # 80002b70 <argint>
  acquire(&tickslock);
    80002d3a:	00014517          	auipc	a0,0x14
    80002d3e:	cb650513          	addi	a0,a0,-842 # 800169f0 <tickslock>
    80002d42:	ffffe097          	auipc	ra,0xffffe
    80002d46:	e94080e7          	jalr	-364(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002d4a:	00006917          	auipc	s2,0x6
    80002d4e:	c0692903          	lw	s2,-1018(s2) # 80008950 <ticks>
  while(ticks - ticks0 < n){
    80002d52:	fcc42783          	lw	a5,-52(s0)
    80002d56:	cf9d                	beqz	a5,80002d94 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d58:	00014997          	auipc	s3,0x14
    80002d5c:	c9898993          	addi	s3,s3,-872 # 800169f0 <tickslock>
    80002d60:	00006497          	auipc	s1,0x6
    80002d64:	bf048493          	addi	s1,s1,-1040 # 80008950 <ticks>
    if(killed(myproc())){
    80002d68:	fffff097          	auipc	ra,0xfffff
    80002d6c:	c44080e7          	jalr	-956(ra) # 800019ac <myproc>
    80002d70:	fffff097          	auipc	ra,0xfffff
    80002d74:	58c080e7          	jalr	1420(ra) # 800022fc <killed>
    80002d78:	ed15                	bnez	a0,80002db4 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002d7a:	85ce                	mv	a1,s3
    80002d7c:	8526                	mv	a0,s1
    80002d7e:	fffff097          	auipc	ra,0xfffff
    80002d82:	2d6080e7          	jalr	726(ra) # 80002054 <sleep>
  while(ticks - ticks0 < n){
    80002d86:	409c                	lw	a5,0(s1)
    80002d88:	412787bb          	subw	a5,a5,s2
    80002d8c:	fcc42703          	lw	a4,-52(s0)
    80002d90:	fce7ece3          	bltu	a5,a4,80002d68 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002d94:	00014517          	auipc	a0,0x14
    80002d98:	c5c50513          	addi	a0,a0,-932 # 800169f0 <tickslock>
    80002d9c:	ffffe097          	auipc	ra,0xffffe
    80002da0:	eee080e7          	jalr	-274(ra) # 80000c8a <release>
  return 0;
    80002da4:	4501                	li	a0,0
}
    80002da6:	70e2                	ld	ra,56(sp)
    80002da8:	7442                	ld	s0,48(sp)
    80002daa:	74a2                	ld	s1,40(sp)
    80002dac:	7902                	ld	s2,32(sp)
    80002dae:	69e2                	ld	s3,24(sp)
    80002db0:	6121                	addi	sp,sp,64
    80002db2:	8082                	ret
      release(&tickslock);
    80002db4:	00014517          	auipc	a0,0x14
    80002db8:	c3c50513          	addi	a0,a0,-964 # 800169f0 <tickslock>
    80002dbc:	ffffe097          	auipc	ra,0xffffe
    80002dc0:	ece080e7          	jalr	-306(ra) # 80000c8a <release>
      return -1;
    80002dc4:	557d                	li	a0,-1
    80002dc6:	b7c5                	j	80002da6 <sys_sleep+0x88>

0000000080002dc8 <sys_kill>:

uint64
sys_kill(void)
{
    80002dc8:	1101                	addi	sp,sp,-32
    80002dca:	ec06                	sd	ra,24(sp)
    80002dcc:	e822                	sd	s0,16(sp)
    80002dce:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002dd0:	fec40593          	addi	a1,s0,-20
    80002dd4:	4501                	li	a0,0
    80002dd6:	00000097          	auipc	ra,0x0
    80002dda:	d9a080e7          	jalr	-614(ra) # 80002b70 <argint>
  return kill(pid);
    80002dde:	fec42503          	lw	a0,-20(s0)
    80002de2:	fffff097          	auipc	ra,0xfffff
    80002de6:	47c080e7          	jalr	1148(ra) # 8000225e <kill>
}
    80002dea:	60e2                	ld	ra,24(sp)
    80002dec:	6442                	ld	s0,16(sp)
    80002dee:	6105                	addi	sp,sp,32
    80002df0:	8082                	ret

0000000080002df2 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002df2:	1101                	addi	sp,sp,-32
    80002df4:	ec06                	sd	ra,24(sp)
    80002df6:	e822                	sd	s0,16(sp)
    80002df8:	e426                	sd	s1,8(sp)
    80002dfa:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002dfc:	00014517          	auipc	a0,0x14
    80002e00:	bf450513          	addi	a0,a0,-1036 # 800169f0 <tickslock>
    80002e04:	ffffe097          	auipc	ra,0xffffe
    80002e08:	dd2080e7          	jalr	-558(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80002e0c:	00006497          	auipc	s1,0x6
    80002e10:	b444a483          	lw	s1,-1212(s1) # 80008950 <ticks>
  release(&tickslock);
    80002e14:	00014517          	auipc	a0,0x14
    80002e18:	bdc50513          	addi	a0,a0,-1060 # 800169f0 <tickslock>
    80002e1c:	ffffe097          	auipc	ra,0xffffe
    80002e20:	e6e080e7          	jalr	-402(ra) # 80000c8a <release>
  return xticks;
}
    80002e24:	02049513          	slli	a0,s1,0x20
    80002e28:	9101                	srli	a0,a0,0x20
    80002e2a:	60e2                	ld	ra,24(sp)
    80002e2c:	6442                	ld	s0,16(sp)
    80002e2e:	64a2                	ld	s1,8(sp)
    80002e30:	6105                	addi	sp,sp,32
    80002e32:	8082                	ret

0000000080002e34 <sys_helloworld>:

uint64
sys_helloworld(void)
{
    80002e34:	1141                	addi	sp,sp,-16
    80002e36:	e406                	sd	ra,8(sp)
    80002e38:	e022                	sd	s0,0(sp)
    80002e3a:	0800                	addi	s0,sp,16
  printf("Hello World\n");
    80002e3c:	00005517          	auipc	a0,0x5
    80002e40:	71c50513          	addi	a0,a0,1820 # 80008558 <syscalls+0xc8>
    80002e44:	ffffd097          	auipc	ra,0xffffd
    80002e48:	746080e7          	jalr	1862(ra) # 8000058a <printf>
  return 0;
}
    80002e4c:	4501                	li	a0,0
    80002e4e:	60a2                	ld	ra,8(sp)
    80002e50:	6402                	ld	s0,0(sp)
    80002e52:	0141                	addi	sp,sp,16
    80002e54:	8082                	ret

0000000080002e56 <sys_curproc>:

uint64
sys_curproc(void)
{
    80002e56:	1141                	addi	sp,sp,-16
    80002e58:	e406                	sd	ra,8(sp)
    80002e5a:	e022                	sd	s0,0(sp)
    80002e5c:	0800                	addi	s0,sp,16
  procdump();
    80002e5e:	fffff097          	auipc	ra,0xfffff
    80002e62:	6aa080e7          	jalr	1706(ra) # 80002508 <procdump>
  return 0;
}
    80002e66:	4501                	li	a0,0
    80002e68:	60a2                	ld	ra,8(sp)
    80002e6a:	6402                	ld	s0,0(sp)
    80002e6c:	0141                	addi	sp,sp,16
    80002e6e:	8082                	ret

0000000080002e70 <sys_runproc>:

uint64
sys_runproc(void)
{
    80002e70:	1141                	addi	sp,sp,-16
    80002e72:	e406                	sd	ra,8(sp)
    80002e74:	e022                	sd	s0,0(sp)
    80002e76:	0800                	addi	s0,sp,16
  printrunproc();
    80002e78:	fffff097          	auipc	ra,0xfffff
    80002e7c:	740080e7          	jalr	1856(ra) # 800025b8 <printrunproc>
  return 0;
}
    80002e80:	4501                	li	a0,0
    80002e82:	60a2                	ld	ra,8(sp)
    80002e84:	6402                	ld	s0,0(sp)
    80002e86:	0141                	addi	sp,sp,16
    80002e88:	8082                	ret

0000000080002e8a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002e8a:	7179                	addi	sp,sp,-48
    80002e8c:	f406                	sd	ra,40(sp)
    80002e8e:	f022                	sd	s0,32(sp)
    80002e90:	ec26                	sd	s1,24(sp)
    80002e92:	e84a                	sd	s2,16(sp)
    80002e94:	e44e                	sd	s3,8(sp)
    80002e96:	e052                	sd	s4,0(sp)
    80002e98:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002e9a:	00005597          	auipc	a1,0x5
    80002e9e:	6ce58593          	addi	a1,a1,1742 # 80008568 <syscalls+0xd8>
    80002ea2:	00014517          	auipc	a0,0x14
    80002ea6:	b6650513          	addi	a0,a0,-1178 # 80016a08 <bcache>
    80002eaa:	ffffe097          	auipc	ra,0xffffe
    80002eae:	c9c080e7          	jalr	-868(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002eb2:	0001c797          	auipc	a5,0x1c
    80002eb6:	b5678793          	addi	a5,a5,-1194 # 8001ea08 <bcache+0x8000>
    80002eba:	0001c717          	auipc	a4,0x1c
    80002ebe:	db670713          	addi	a4,a4,-586 # 8001ec70 <bcache+0x8268>
    80002ec2:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002ec6:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002eca:	00014497          	auipc	s1,0x14
    80002ece:	b5648493          	addi	s1,s1,-1194 # 80016a20 <bcache+0x18>
    b->next = bcache.head.next;
    80002ed2:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002ed4:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002ed6:	00005a17          	auipc	s4,0x5
    80002eda:	69aa0a13          	addi	s4,s4,1690 # 80008570 <syscalls+0xe0>
    b->next = bcache.head.next;
    80002ede:	2b893783          	ld	a5,696(s2)
    80002ee2:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002ee4:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002ee8:	85d2                	mv	a1,s4
    80002eea:	01048513          	addi	a0,s1,16
    80002eee:	00001097          	auipc	ra,0x1
    80002ef2:	4c8080e7          	jalr	1224(ra) # 800043b6 <initsleeplock>
    bcache.head.next->prev = b;
    80002ef6:	2b893783          	ld	a5,696(s2)
    80002efa:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002efc:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f00:	45848493          	addi	s1,s1,1112
    80002f04:	fd349de3          	bne	s1,s3,80002ede <binit+0x54>
  }
}
    80002f08:	70a2                	ld	ra,40(sp)
    80002f0a:	7402                	ld	s0,32(sp)
    80002f0c:	64e2                	ld	s1,24(sp)
    80002f0e:	6942                	ld	s2,16(sp)
    80002f10:	69a2                	ld	s3,8(sp)
    80002f12:	6a02                	ld	s4,0(sp)
    80002f14:	6145                	addi	sp,sp,48
    80002f16:	8082                	ret

0000000080002f18 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f18:	7179                	addi	sp,sp,-48
    80002f1a:	f406                	sd	ra,40(sp)
    80002f1c:	f022                	sd	s0,32(sp)
    80002f1e:	ec26                	sd	s1,24(sp)
    80002f20:	e84a                	sd	s2,16(sp)
    80002f22:	e44e                	sd	s3,8(sp)
    80002f24:	1800                	addi	s0,sp,48
    80002f26:	892a                	mv	s2,a0
    80002f28:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002f2a:	00014517          	auipc	a0,0x14
    80002f2e:	ade50513          	addi	a0,a0,-1314 # 80016a08 <bcache>
    80002f32:	ffffe097          	auipc	ra,0xffffe
    80002f36:	ca4080e7          	jalr	-860(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f3a:	0001c497          	auipc	s1,0x1c
    80002f3e:	d864b483          	ld	s1,-634(s1) # 8001ecc0 <bcache+0x82b8>
    80002f42:	0001c797          	auipc	a5,0x1c
    80002f46:	d2e78793          	addi	a5,a5,-722 # 8001ec70 <bcache+0x8268>
    80002f4a:	02f48f63          	beq	s1,a5,80002f88 <bread+0x70>
    80002f4e:	873e                	mv	a4,a5
    80002f50:	a021                	j	80002f58 <bread+0x40>
    80002f52:	68a4                	ld	s1,80(s1)
    80002f54:	02e48a63          	beq	s1,a4,80002f88 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f58:	449c                	lw	a5,8(s1)
    80002f5a:	ff279ce3          	bne	a5,s2,80002f52 <bread+0x3a>
    80002f5e:	44dc                	lw	a5,12(s1)
    80002f60:	ff3799e3          	bne	a5,s3,80002f52 <bread+0x3a>
      b->refcnt++;
    80002f64:	40bc                	lw	a5,64(s1)
    80002f66:	2785                	addiw	a5,a5,1
    80002f68:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f6a:	00014517          	auipc	a0,0x14
    80002f6e:	a9e50513          	addi	a0,a0,-1378 # 80016a08 <bcache>
    80002f72:	ffffe097          	auipc	ra,0xffffe
    80002f76:	d18080e7          	jalr	-744(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80002f7a:	01048513          	addi	a0,s1,16
    80002f7e:	00001097          	auipc	ra,0x1
    80002f82:	472080e7          	jalr	1138(ra) # 800043f0 <acquiresleep>
      return b;
    80002f86:	a8b9                	j	80002fe4 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f88:	0001c497          	auipc	s1,0x1c
    80002f8c:	d304b483          	ld	s1,-720(s1) # 8001ecb8 <bcache+0x82b0>
    80002f90:	0001c797          	auipc	a5,0x1c
    80002f94:	ce078793          	addi	a5,a5,-800 # 8001ec70 <bcache+0x8268>
    80002f98:	00f48863          	beq	s1,a5,80002fa8 <bread+0x90>
    80002f9c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002f9e:	40bc                	lw	a5,64(s1)
    80002fa0:	cf81                	beqz	a5,80002fb8 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fa2:	64a4                	ld	s1,72(s1)
    80002fa4:	fee49de3          	bne	s1,a4,80002f9e <bread+0x86>
  panic("bget: no buffers");
    80002fa8:	00005517          	auipc	a0,0x5
    80002fac:	5d050513          	addi	a0,a0,1488 # 80008578 <syscalls+0xe8>
    80002fb0:	ffffd097          	auipc	ra,0xffffd
    80002fb4:	590080e7          	jalr	1424(ra) # 80000540 <panic>
      b->dev = dev;
    80002fb8:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002fbc:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002fc0:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002fc4:	4785                	li	a5,1
    80002fc6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fc8:	00014517          	auipc	a0,0x14
    80002fcc:	a4050513          	addi	a0,a0,-1472 # 80016a08 <bcache>
    80002fd0:	ffffe097          	auipc	ra,0xffffe
    80002fd4:	cba080e7          	jalr	-838(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80002fd8:	01048513          	addi	a0,s1,16
    80002fdc:	00001097          	auipc	ra,0x1
    80002fe0:	414080e7          	jalr	1044(ra) # 800043f0 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002fe4:	409c                	lw	a5,0(s1)
    80002fe6:	cb89                	beqz	a5,80002ff8 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002fe8:	8526                	mv	a0,s1
    80002fea:	70a2                	ld	ra,40(sp)
    80002fec:	7402                	ld	s0,32(sp)
    80002fee:	64e2                	ld	s1,24(sp)
    80002ff0:	6942                	ld	s2,16(sp)
    80002ff2:	69a2                	ld	s3,8(sp)
    80002ff4:	6145                	addi	sp,sp,48
    80002ff6:	8082                	ret
    virtio_disk_rw(b, 0);
    80002ff8:	4581                	li	a1,0
    80002ffa:	8526                	mv	a0,s1
    80002ffc:	00003097          	auipc	ra,0x3
    80003000:	fd6080e7          	jalr	-42(ra) # 80005fd2 <virtio_disk_rw>
    b->valid = 1;
    80003004:	4785                	li	a5,1
    80003006:	c09c                	sw	a5,0(s1)
  return b;
    80003008:	b7c5                	j	80002fe8 <bread+0xd0>

000000008000300a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000300a:	1101                	addi	sp,sp,-32
    8000300c:	ec06                	sd	ra,24(sp)
    8000300e:	e822                	sd	s0,16(sp)
    80003010:	e426                	sd	s1,8(sp)
    80003012:	1000                	addi	s0,sp,32
    80003014:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003016:	0541                	addi	a0,a0,16
    80003018:	00001097          	auipc	ra,0x1
    8000301c:	472080e7          	jalr	1138(ra) # 8000448a <holdingsleep>
    80003020:	cd01                	beqz	a0,80003038 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003022:	4585                	li	a1,1
    80003024:	8526                	mv	a0,s1
    80003026:	00003097          	auipc	ra,0x3
    8000302a:	fac080e7          	jalr	-84(ra) # 80005fd2 <virtio_disk_rw>
}
    8000302e:	60e2                	ld	ra,24(sp)
    80003030:	6442                	ld	s0,16(sp)
    80003032:	64a2                	ld	s1,8(sp)
    80003034:	6105                	addi	sp,sp,32
    80003036:	8082                	ret
    panic("bwrite");
    80003038:	00005517          	auipc	a0,0x5
    8000303c:	55850513          	addi	a0,a0,1368 # 80008590 <syscalls+0x100>
    80003040:	ffffd097          	auipc	ra,0xffffd
    80003044:	500080e7          	jalr	1280(ra) # 80000540 <panic>

0000000080003048 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003048:	1101                	addi	sp,sp,-32
    8000304a:	ec06                	sd	ra,24(sp)
    8000304c:	e822                	sd	s0,16(sp)
    8000304e:	e426                	sd	s1,8(sp)
    80003050:	e04a                	sd	s2,0(sp)
    80003052:	1000                	addi	s0,sp,32
    80003054:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003056:	01050913          	addi	s2,a0,16
    8000305a:	854a                	mv	a0,s2
    8000305c:	00001097          	auipc	ra,0x1
    80003060:	42e080e7          	jalr	1070(ra) # 8000448a <holdingsleep>
    80003064:	c92d                	beqz	a0,800030d6 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003066:	854a                	mv	a0,s2
    80003068:	00001097          	auipc	ra,0x1
    8000306c:	3de080e7          	jalr	990(ra) # 80004446 <releasesleep>

  acquire(&bcache.lock);
    80003070:	00014517          	auipc	a0,0x14
    80003074:	99850513          	addi	a0,a0,-1640 # 80016a08 <bcache>
    80003078:	ffffe097          	auipc	ra,0xffffe
    8000307c:	b5e080e7          	jalr	-1186(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003080:	40bc                	lw	a5,64(s1)
    80003082:	37fd                	addiw	a5,a5,-1
    80003084:	0007871b          	sext.w	a4,a5
    80003088:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000308a:	eb05                	bnez	a4,800030ba <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000308c:	68bc                	ld	a5,80(s1)
    8000308e:	64b8                	ld	a4,72(s1)
    80003090:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003092:	64bc                	ld	a5,72(s1)
    80003094:	68b8                	ld	a4,80(s1)
    80003096:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003098:	0001c797          	auipc	a5,0x1c
    8000309c:	97078793          	addi	a5,a5,-1680 # 8001ea08 <bcache+0x8000>
    800030a0:	2b87b703          	ld	a4,696(a5)
    800030a4:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800030a6:	0001c717          	auipc	a4,0x1c
    800030aa:	bca70713          	addi	a4,a4,-1078 # 8001ec70 <bcache+0x8268>
    800030ae:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800030b0:	2b87b703          	ld	a4,696(a5)
    800030b4:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800030b6:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800030ba:	00014517          	auipc	a0,0x14
    800030be:	94e50513          	addi	a0,a0,-1714 # 80016a08 <bcache>
    800030c2:	ffffe097          	auipc	ra,0xffffe
    800030c6:	bc8080e7          	jalr	-1080(ra) # 80000c8a <release>
}
    800030ca:	60e2                	ld	ra,24(sp)
    800030cc:	6442                	ld	s0,16(sp)
    800030ce:	64a2                	ld	s1,8(sp)
    800030d0:	6902                	ld	s2,0(sp)
    800030d2:	6105                	addi	sp,sp,32
    800030d4:	8082                	ret
    panic("brelse");
    800030d6:	00005517          	auipc	a0,0x5
    800030da:	4c250513          	addi	a0,a0,1218 # 80008598 <syscalls+0x108>
    800030de:	ffffd097          	auipc	ra,0xffffd
    800030e2:	462080e7          	jalr	1122(ra) # 80000540 <panic>

00000000800030e6 <bpin>:

void
bpin(struct buf *b) {
    800030e6:	1101                	addi	sp,sp,-32
    800030e8:	ec06                	sd	ra,24(sp)
    800030ea:	e822                	sd	s0,16(sp)
    800030ec:	e426                	sd	s1,8(sp)
    800030ee:	1000                	addi	s0,sp,32
    800030f0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030f2:	00014517          	auipc	a0,0x14
    800030f6:	91650513          	addi	a0,a0,-1770 # 80016a08 <bcache>
    800030fa:	ffffe097          	auipc	ra,0xffffe
    800030fe:	adc080e7          	jalr	-1316(ra) # 80000bd6 <acquire>
  b->refcnt++;
    80003102:	40bc                	lw	a5,64(s1)
    80003104:	2785                	addiw	a5,a5,1
    80003106:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003108:	00014517          	auipc	a0,0x14
    8000310c:	90050513          	addi	a0,a0,-1792 # 80016a08 <bcache>
    80003110:	ffffe097          	auipc	ra,0xffffe
    80003114:	b7a080e7          	jalr	-1158(ra) # 80000c8a <release>
}
    80003118:	60e2                	ld	ra,24(sp)
    8000311a:	6442                	ld	s0,16(sp)
    8000311c:	64a2                	ld	s1,8(sp)
    8000311e:	6105                	addi	sp,sp,32
    80003120:	8082                	ret

0000000080003122 <bunpin>:

void
bunpin(struct buf *b) {
    80003122:	1101                	addi	sp,sp,-32
    80003124:	ec06                	sd	ra,24(sp)
    80003126:	e822                	sd	s0,16(sp)
    80003128:	e426                	sd	s1,8(sp)
    8000312a:	1000                	addi	s0,sp,32
    8000312c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000312e:	00014517          	auipc	a0,0x14
    80003132:	8da50513          	addi	a0,a0,-1830 # 80016a08 <bcache>
    80003136:	ffffe097          	auipc	ra,0xffffe
    8000313a:	aa0080e7          	jalr	-1376(ra) # 80000bd6 <acquire>
  b->refcnt--;
    8000313e:	40bc                	lw	a5,64(s1)
    80003140:	37fd                	addiw	a5,a5,-1
    80003142:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003144:	00014517          	auipc	a0,0x14
    80003148:	8c450513          	addi	a0,a0,-1852 # 80016a08 <bcache>
    8000314c:	ffffe097          	auipc	ra,0xffffe
    80003150:	b3e080e7          	jalr	-1218(ra) # 80000c8a <release>
}
    80003154:	60e2                	ld	ra,24(sp)
    80003156:	6442                	ld	s0,16(sp)
    80003158:	64a2                	ld	s1,8(sp)
    8000315a:	6105                	addi	sp,sp,32
    8000315c:	8082                	ret

000000008000315e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000315e:	1101                	addi	sp,sp,-32
    80003160:	ec06                	sd	ra,24(sp)
    80003162:	e822                	sd	s0,16(sp)
    80003164:	e426                	sd	s1,8(sp)
    80003166:	e04a                	sd	s2,0(sp)
    80003168:	1000                	addi	s0,sp,32
    8000316a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000316c:	00d5d59b          	srliw	a1,a1,0xd
    80003170:	0001c797          	auipc	a5,0x1c
    80003174:	f747a783          	lw	a5,-140(a5) # 8001f0e4 <sb+0x1c>
    80003178:	9dbd                	addw	a1,a1,a5
    8000317a:	00000097          	auipc	ra,0x0
    8000317e:	d9e080e7          	jalr	-610(ra) # 80002f18 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003182:	0074f713          	andi	a4,s1,7
    80003186:	4785                	li	a5,1
    80003188:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000318c:	14ce                	slli	s1,s1,0x33
    8000318e:	90d9                	srli	s1,s1,0x36
    80003190:	00950733          	add	a4,a0,s1
    80003194:	05874703          	lbu	a4,88(a4)
    80003198:	00e7f6b3          	and	a3,a5,a4
    8000319c:	c69d                	beqz	a3,800031ca <bfree+0x6c>
    8000319e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800031a0:	94aa                	add	s1,s1,a0
    800031a2:	fff7c793          	not	a5,a5
    800031a6:	8f7d                	and	a4,a4,a5
    800031a8:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800031ac:	00001097          	auipc	ra,0x1
    800031b0:	126080e7          	jalr	294(ra) # 800042d2 <log_write>
  brelse(bp);
    800031b4:	854a                	mv	a0,s2
    800031b6:	00000097          	auipc	ra,0x0
    800031ba:	e92080e7          	jalr	-366(ra) # 80003048 <brelse>
}
    800031be:	60e2                	ld	ra,24(sp)
    800031c0:	6442                	ld	s0,16(sp)
    800031c2:	64a2                	ld	s1,8(sp)
    800031c4:	6902                	ld	s2,0(sp)
    800031c6:	6105                	addi	sp,sp,32
    800031c8:	8082                	ret
    panic("freeing free block");
    800031ca:	00005517          	auipc	a0,0x5
    800031ce:	3d650513          	addi	a0,a0,982 # 800085a0 <syscalls+0x110>
    800031d2:	ffffd097          	auipc	ra,0xffffd
    800031d6:	36e080e7          	jalr	878(ra) # 80000540 <panic>

00000000800031da <balloc>:
{
    800031da:	711d                	addi	sp,sp,-96
    800031dc:	ec86                	sd	ra,88(sp)
    800031de:	e8a2                	sd	s0,80(sp)
    800031e0:	e4a6                	sd	s1,72(sp)
    800031e2:	e0ca                	sd	s2,64(sp)
    800031e4:	fc4e                	sd	s3,56(sp)
    800031e6:	f852                	sd	s4,48(sp)
    800031e8:	f456                	sd	s5,40(sp)
    800031ea:	f05a                	sd	s6,32(sp)
    800031ec:	ec5e                	sd	s7,24(sp)
    800031ee:	e862                	sd	s8,16(sp)
    800031f0:	e466                	sd	s9,8(sp)
    800031f2:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800031f4:	0001c797          	auipc	a5,0x1c
    800031f8:	ed87a783          	lw	a5,-296(a5) # 8001f0cc <sb+0x4>
    800031fc:	cff5                	beqz	a5,800032f8 <balloc+0x11e>
    800031fe:	8baa                	mv	s7,a0
    80003200:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003202:	0001cb17          	auipc	s6,0x1c
    80003206:	ec6b0b13          	addi	s6,s6,-314 # 8001f0c8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000320a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000320c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000320e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003210:	6c89                	lui	s9,0x2
    80003212:	a061                	j	8000329a <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003214:	97ca                	add	a5,a5,s2
    80003216:	8e55                	or	a2,a2,a3
    80003218:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    8000321c:	854a                	mv	a0,s2
    8000321e:	00001097          	auipc	ra,0x1
    80003222:	0b4080e7          	jalr	180(ra) # 800042d2 <log_write>
        brelse(bp);
    80003226:	854a                	mv	a0,s2
    80003228:	00000097          	auipc	ra,0x0
    8000322c:	e20080e7          	jalr	-480(ra) # 80003048 <brelse>
  bp = bread(dev, bno);
    80003230:	85a6                	mv	a1,s1
    80003232:	855e                	mv	a0,s7
    80003234:	00000097          	auipc	ra,0x0
    80003238:	ce4080e7          	jalr	-796(ra) # 80002f18 <bread>
    8000323c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000323e:	40000613          	li	a2,1024
    80003242:	4581                	li	a1,0
    80003244:	05850513          	addi	a0,a0,88
    80003248:	ffffe097          	auipc	ra,0xffffe
    8000324c:	a8a080e7          	jalr	-1398(ra) # 80000cd2 <memset>
  log_write(bp);
    80003250:	854a                	mv	a0,s2
    80003252:	00001097          	auipc	ra,0x1
    80003256:	080080e7          	jalr	128(ra) # 800042d2 <log_write>
  brelse(bp);
    8000325a:	854a                	mv	a0,s2
    8000325c:	00000097          	auipc	ra,0x0
    80003260:	dec080e7          	jalr	-532(ra) # 80003048 <brelse>
}
    80003264:	8526                	mv	a0,s1
    80003266:	60e6                	ld	ra,88(sp)
    80003268:	6446                	ld	s0,80(sp)
    8000326a:	64a6                	ld	s1,72(sp)
    8000326c:	6906                	ld	s2,64(sp)
    8000326e:	79e2                	ld	s3,56(sp)
    80003270:	7a42                	ld	s4,48(sp)
    80003272:	7aa2                	ld	s5,40(sp)
    80003274:	7b02                	ld	s6,32(sp)
    80003276:	6be2                	ld	s7,24(sp)
    80003278:	6c42                	ld	s8,16(sp)
    8000327a:	6ca2                	ld	s9,8(sp)
    8000327c:	6125                	addi	sp,sp,96
    8000327e:	8082                	ret
    brelse(bp);
    80003280:	854a                	mv	a0,s2
    80003282:	00000097          	auipc	ra,0x0
    80003286:	dc6080e7          	jalr	-570(ra) # 80003048 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000328a:	015c87bb          	addw	a5,s9,s5
    8000328e:	00078a9b          	sext.w	s5,a5
    80003292:	004b2703          	lw	a4,4(s6)
    80003296:	06eaf163          	bgeu	s5,a4,800032f8 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    8000329a:	41fad79b          	sraiw	a5,s5,0x1f
    8000329e:	0137d79b          	srliw	a5,a5,0x13
    800032a2:	015787bb          	addw	a5,a5,s5
    800032a6:	40d7d79b          	sraiw	a5,a5,0xd
    800032aa:	01cb2583          	lw	a1,28(s6)
    800032ae:	9dbd                	addw	a1,a1,a5
    800032b0:	855e                	mv	a0,s7
    800032b2:	00000097          	auipc	ra,0x0
    800032b6:	c66080e7          	jalr	-922(ra) # 80002f18 <bread>
    800032ba:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032bc:	004b2503          	lw	a0,4(s6)
    800032c0:	000a849b          	sext.w	s1,s5
    800032c4:	8762                	mv	a4,s8
    800032c6:	faa4fde3          	bgeu	s1,a0,80003280 <balloc+0xa6>
      m = 1 << (bi % 8);
    800032ca:	00777693          	andi	a3,a4,7
    800032ce:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800032d2:	41f7579b          	sraiw	a5,a4,0x1f
    800032d6:	01d7d79b          	srliw	a5,a5,0x1d
    800032da:	9fb9                	addw	a5,a5,a4
    800032dc:	4037d79b          	sraiw	a5,a5,0x3
    800032e0:	00f90633          	add	a2,s2,a5
    800032e4:	05864603          	lbu	a2,88(a2)
    800032e8:	00c6f5b3          	and	a1,a3,a2
    800032ec:	d585                	beqz	a1,80003214 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032ee:	2705                	addiw	a4,a4,1
    800032f0:	2485                	addiw	s1,s1,1
    800032f2:	fd471ae3          	bne	a4,s4,800032c6 <balloc+0xec>
    800032f6:	b769                	j	80003280 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    800032f8:	00005517          	auipc	a0,0x5
    800032fc:	2c050513          	addi	a0,a0,704 # 800085b8 <syscalls+0x128>
    80003300:	ffffd097          	auipc	ra,0xffffd
    80003304:	28a080e7          	jalr	650(ra) # 8000058a <printf>
  return 0;
    80003308:	4481                	li	s1,0
    8000330a:	bfa9                	j	80003264 <balloc+0x8a>

000000008000330c <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000330c:	7179                	addi	sp,sp,-48
    8000330e:	f406                	sd	ra,40(sp)
    80003310:	f022                	sd	s0,32(sp)
    80003312:	ec26                	sd	s1,24(sp)
    80003314:	e84a                	sd	s2,16(sp)
    80003316:	e44e                	sd	s3,8(sp)
    80003318:	e052                	sd	s4,0(sp)
    8000331a:	1800                	addi	s0,sp,48
    8000331c:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000331e:	47ad                	li	a5,11
    80003320:	02b7e863          	bltu	a5,a1,80003350 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003324:	02059793          	slli	a5,a1,0x20
    80003328:	01e7d593          	srli	a1,a5,0x1e
    8000332c:	00b504b3          	add	s1,a0,a1
    80003330:	0504a903          	lw	s2,80(s1)
    80003334:	06091e63          	bnez	s2,800033b0 <bmap+0xa4>
      addr = balloc(ip->dev);
    80003338:	4108                	lw	a0,0(a0)
    8000333a:	00000097          	auipc	ra,0x0
    8000333e:	ea0080e7          	jalr	-352(ra) # 800031da <balloc>
    80003342:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003346:	06090563          	beqz	s2,800033b0 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    8000334a:	0524a823          	sw	s2,80(s1)
    8000334e:	a08d                	j	800033b0 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003350:	ff45849b          	addiw	s1,a1,-12
    80003354:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003358:	0ff00793          	li	a5,255
    8000335c:	08e7e563          	bltu	a5,a4,800033e6 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003360:	08052903          	lw	s2,128(a0)
    80003364:	00091d63          	bnez	s2,8000337e <bmap+0x72>
      addr = balloc(ip->dev);
    80003368:	4108                	lw	a0,0(a0)
    8000336a:	00000097          	auipc	ra,0x0
    8000336e:	e70080e7          	jalr	-400(ra) # 800031da <balloc>
    80003372:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003376:	02090d63          	beqz	s2,800033b0 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000337a:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000337e:	85ca                	mv	a1,s2
    80003380:	0009a503          	lw	a0,0(s3)
    80003384:	00000097          	auipc	ra,0x0
    80003388:	b94080e7          	jalr	-1132(ra) # 80002f18 <bread>
    8000338c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000338e:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003392:	02049713          	slli	a4,s1,0x20
    80003396:	01e75593          	srli	a1,a4,0x1e
    8000339a:	00b784b3          	add	s1,a5,a1
    8000339e:	0004a903          	lw	s2,0(s1)
    800033a2:	02090063          	beqz	s2,800033c2 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800033a6:	8552                	mv	a0,s4
    800033a8:	00000097          	auipc	ra,0x0
    800033ac:	ca0080e7          	jalr	-864(ra) # 80003048 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800033b0:	854a                	mv	a0,s2
    800033b2:	70a2                	ld	ra,40(sp)
    800033b4:	7402                	ld	s0,32(sp)
    800033b6:	64e2                	ld	s1,24(sp)
    800033b8:	6942                	ld	s2,16(sp)
    800033ba:	69a2                	ld	s3,8(sp)
    800033bc:	6a02                	ld	s4,0(sp)
    800033be:	6145                	addi	sp,sp,48
    800033c0:	8082                	ret
      addr = balloc(ip->dev);
    800033c2:	0009a503          	lw	a0,0(s3)
    800033c6:	00000097          	auipc	ra,0x0
    800033ca:	e14080e7          	jalr	-492(ra) # 800031da <balloc>
    800033ce:	0005091b          	sext.w	s2,a0
      if(addr){
    800033d2:	fc090ae3          	beqz	s2,800033a6 <bmap+0x9a>
        a[bn] = addr;
    800033d6:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800033da:	8552                	mv	a0,s4
    800033dc:	00001097          	auipc	ra,0x1
    800033e0:	ef6080e7          	jalr	-266(ra) # 800042d2 <log_write>
    800033e4:	b7c9                	j	800033a6 <bmap+0x9a>
  panic("bmap: out of range");
    800033e6:	00005517          	auipc	a0,0x5
    800033ea:	1ea50513          	addi	a0,a0,490 # 800085d0 <syscalls+0x140>
    800033ee:	ffffd097          	auipc	ra,0xffffd
    800033f2:	152080e7          	jalr	338(ra) # 80000540 <panic>

00000000800033f6 <iget>:
{
    800033f6:	7179                	addi	sp,sp,-48
    800033f8:	f406                	sd	ra,40(sp)
    800033fa:	f022                	sd	s0,32(sp)
    800033fc:	ec26                	sd	s1,24(sp)
    800033fe:	e84a                	sd	s2,16(sp)
    80003400:	e44e                	sd	s3,8(sp)
    80003402:	e052                	sd	s4,0(sp)
    80003404:	1800                	addi	s0,sp,48
    80003406:	89aa                	mv	s3,a0
    80003408:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000340a:	0001c517          	auipc	a0,0x1c
    8000340e:	cde50513          	addi	a0,a0,-802 # 8001f0e8 <itable>
    80003412:	ffffd097          	auipc	ra,0xffffd
    80003416:	7c4080e7          	jalr	1988(ra) # 80000bd6 <acquire>
  empty = 0;
    8000341a:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000341c:	0001c497          	auipc	s1,0x1c
    80003420:	ce448493          	addi	s1,s1,-796 # 8001f100 <itable+0x18>
    80003424:	0001d697          	auipc	a3,0x1d
    80003428:	76c68693          	addi	a3,a3,1900 # 80020b90 <log>
    8000342c:	a039                	j	8000343a <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000342e:	02090b63          	beqz	s2,80003464 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003432:	08848493          	addi	s1,s1,136
    80003436:	02d48a63          	beq	s1,a3,8000346a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000343a:	449c                	lw	a5,8(s1)
    8000343c:	fef059e3          	blez	a5,8000342e <iget+0x38>
    80003440:	4098                	lw	a4,0(s1)
    80003442:	ff3716e3          	bne	a4,s3,8000342e <iget+0x38>
    80003446:	40d8                	lw	a4,4(s1)
    80003448:	ff4713e3          	bne	a4,s4,8000342e <iget+0x38>
      ip->ref++;
    8000344c:	2785                	addiw	a5,a5,1
    8000344e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003450:	0001c517          	auipc	a0,0x1c
    80003454:	c9850513          	addi	a0,a0,-872 # 8001f0e8 <itable>
    80003458:	ffffe097          	auipc	ra,0xffffe
    8000345c:	832080e7          	jalr	-1998(ra) # 80000c8a <release>
      return ip;
    80003460:	8926                	mv	s2,s1
    80003462:	a03d                	j	80003490 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003464:	f7f9                	bnez	a5,80003432 <iget+0x3c>
    80003466:	8926                	mv	s2,s1
    80003468:	b7e9                	j	80003432 <iget+0x3c>
  if(empty == 0)
    8000346a:	02090c63          	beqz	s2,800034a2 <iget+0xac>
  ip->dev = dev;
    8000346e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003472:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003476:	4785                	li	a5,1
    80003478:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000347c:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003480:	0001c517          	auipc	a0,0x1c
    80003484:	c6850513          	addi	a0,a0,-920 # 8001f0e8 <itable>
    80003488:	ffffe097          	auipc	ra,0xffffe
    8000348c:	802080e7          	jalr	-2046(ra) # 80000c8a <release>
}
    80003490:	854a                	mv	a0,s2
    80003492:	70a2                	ld	ra,40(sp)
    80003494:	7402                	ld	s0,32(sp)
    80003496:	64e2                	ld	s1,24(sp)
    80003498:	6942                	ld	s2,16(sp)
    8000349a:	69a2                	ld	s3,8(sp)
    8000349c:	6a02                	ld	s4,0(sp)
    8000349e:	6145                	addi	sp,sp,48
    800034a0:	8082                	ret
    panic("iget: no inodes");
    800034a2:	00005517          	auipc	a0,0x5
    800034a6:	14650513          	addi	a0,a0,326 # 800085e8 <syscalls+0x158>
    800034aa:	ffffd097          	auipc	ra,0xffffd
    800034ae:	096080e7          	jalr	150(ra) # 80000540 <panic>

00000000800034b2 <fsinit>:
fsinit(int dev) {
    800034b2:	7179                	addi	sp,sp,-48
    800034b4:	f406                	sd	ra,40(sp)
    800034b6:	f022                	sd	s0,32(sp)
    800034b8:	ec26                	sd	s1,24(sp)
    800034ba:	e84a                	sd	s2,16(sp)
    800034bc:	e44e                	sd	s3,8(sp)
    800034be:	1800                	addi	s0,sp,48
    800034c0:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800034c2:	4585                	li	a1,1
    800034c4:	00000097          	auipc	ra,0x0
    800034c8:	a54080e7          	jalr	-1452(ra) # 80002f18 <bread>
    800034cc:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800034ce:	0001c997          	auipc	s3,0x1c
    800034d2:	bfa98993          	addi	s3,s3,-1030 # 8001f0c8 <sb>
    800034d6:	02000613          	li	a2,32
    800034da:	05850593          	addi	a1,a0,88
    800034de:	854e                	mv	a0,s3
    800034e0:	ffffe097          	auipc	ra,0xffffe
    800034e4:	84e080e7          	jalr	-1970(ra) # 80000d2e <memmove>
  brelse(bp);
    800034e8:	8526                	mv	a0,s1
    800034ea:	00000097          	auipc	ra,0x0
    800034ee:	b5e080e7          	jalr	-1186(ra) # 80003048 <brelse>
  if(sb.magic != FSMAGIC)
    800034f2:	0009a703          	lw	a4,0(s3)
    800034f6:	102037b7          	lui	a5,0x10203
    800034fa:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800034fe:	02f71263          	bne	a4,a5,80003522 <fsinit+0x70>
  initlog(dev, &sb);
    80003502:	0001c597          	auipc	a1,0x1c
    80003506:	bc658593          	addi	a1,a1,-1082 # 8001f0c8 <sb>
    8000350a:	854a                	mv	a0,s2
    8000350c:	00001097          	auipc	ra,0x1
    80003510:	b4a080e7          	jalr	-1206(ra) # 80004056 <initlog>
}
    80003514:	70a2                	ld	ra,40(sp)
    80003516:	7402                	ld	s0,32(sp)
    80003518:	64e2                	ld	s1,24(sp)
    8000351a:	6942                	ld	s2,16(sp)
    8000351c:	69a2                	ld	s3,8(sp)
    8000351e:	6145                	addi	sp,sp,48
    80003520:	8082                	ret
    panic("invalid file system");
    80003522:	00005517          	auipc	a0,0x5
    80003526:	0d650513          	addi	a0,a0,214 # 800085f8 <syscalls+0x168>
    8000352a:	ffffd097          	auipc	ra,0xffffd
    8000352e:	016080e7          	jalr	22(ra) # 80000540 <panic>

0000000080003532 <iinit>:
{
    80003532:	7179                	addi	sp,sp,-48
    80003534:	f406                	sd	ra,40(sp)
    80003536:	f022                	sd	s0,32(sp)
    80003538:	ec26                	sd	s1,24(sp)
    8000353a:	e84a                	sd	s2,16(sp)
    8000353c:	e44e                	sd	s3,8(sp)
    8000353e:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003540:	00005597          	auipc	a1,0x5
    80003544:	0d058593          	addi	a1,a1,208 # 80008610 <syscalls+0x180>
    80003548:	0001c517          	auipc	a0,0x1c
    8000354c:	ba050513          	addi	a0,a0,-1120 # 8001f0e8 <itable>
    80003550:	ffffd097          	auipc	ra,0xffffd
    80003554:	5f6080e7          	jalr	1526(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003558:	0001c497          	auipc	s1,0x1c
    8000355c:	bb848493          	addi	s1,s1,-1096 # 8001f110 <itable+0x28>
    80003560:	0001d997          	auipc	s3,0x1d
    80003564:	64098993          	addi	s3,s3,1600 # 80020ba0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003568:	00005917          	auipc	s2,0x5
    8000356c:	0b090913          	addi	s2,s2,176 # 80008618 <syscalls+0x188>
    80003570:	85ca                	mv	a1,s2
    80003572:	8526                	mv	a0,s1
    80003574:	00001097          	auipc	ra,0x1
    80003578:	e42080e7          	jalr	-446(ra) # 800043b6 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000357c:	08848493          	addi	s1,s1,136
    80003580:	ff3498e3          	bne	s1,s3,80003570 <iinit+0x3e>
}
    80003584:	70a2                	ld	ra,40(sp)
    80003586:	7402                	ld	s0,32(sp)
    80003588:	64e2                	ld	s1,24(sp)
    8000358a:	6942                	ld	s2,16(sp)
    8000358c:	69a2                	ld	s3,8(sp)
    8000358e:	6145                	addi	sp,sp,48
    80003590:	8082                	ret

0000000080003592 <ialloc>:
{
    80003592:	715d                	addi	sp,sp,-80
    80003594:	e486                	sd	ra,72(sp)
    80003596:	e0a2                	sd	s0,64(sp)
    80003598:	fc26                	sd	s1,56(sp)
    8000359a:	f84a                	sd	s2,48(sp)
    8000359c:	f44e                	sd	s3,40(sp)
    8000359e:	f052                	sd	s4,32(sp)
    800035a0:	ec56                	sd	s5,24(sp)
    800035a2:	e85a                	sd	s6,16(sp)
    800035a4:	e45e                	sd	s7,8(sp)
    800035a6:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800035a8:	0001c717          	auipc	a4,0x1c
    800035ac:	b2c72703          	lw	a4,-1236(a4) # 8001f0d4 <sb+0xc>
    800035b0:	4785                	li	a5,1
    800035b2:	04e7fa63          	bgeu	a5,a4,80003606 <ialloc+0x74>
    800035b6:	8aaa                	mv	s5,a0
    800035b8:	8bae                	mv	s7,a1
    800035ba:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800035bc:	0001ca17          	auipc	s4,0x1c
    800035c0:	b0ca0a13          	addi	s4,s4,-1268 # 8001f0c8 <sb>
    800035c4:	00048b1b          	sext.w	s6,s1
    800035c8:	0044d593          	srli	a1,s1,0x4
    800035cc:	018a2783          	lw	a5,24(s4)
    800035d0:	9dbd                	addw	a1,a1,a5
    800035d2:	8556                	mv	a0,s5
    800035d4:	00000097          	auipc	ra,0x0
    800035d8:	944080e7          	jalr	-1724(ra) # 80002f18 <bread>
    800035dc:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800035de:	05850993          	addi	s3,a0,88
    800035e2:	00f4f793          	andi	a5,s1,15
    800035e6:	079a                	slli	a5,a5,0x6
    800035e8:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800035ea:	00099783          	lh	a5,0(s3)
    800035ee:	c3a1                	beqz	a5,8000362e <ialloc+0x9c>
    brelse(bp);
    800035f0:	00000097          	auipc	ra,0x0
    800035f4:	a58080e7          	jalr	-1448(ra) # 80003048 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800035f8:	0485                	addi	s1,s1,1
    800035fa:	00ca2703          	lw	a4,12(s4)
    800035fe:	0004879b          	sext.w	a5,s1
    80003602:	fce7e1e3          	bltu	a5,a4,800035c4 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003606:	00005517          	auipc	a0,0x5
    8000360a:	01a50513          	addi	a0,a0,26 # 80008620 <syscalls+0x190>
    8000360e:	ffffd097          	auipc	ra,0xffffd
    80003612:	f7c080e7          	jalr	-132(ra) # 8000058a <printf>
  return 0;
    80003616:	4501                	li	a0,0
}
    80003618:	60a6                	ld	ra,72(sp)
    8000361a:	6406                	ld	s0,64(sp)
    8000361c:	74e2                	ld	s1,56(sp)
    8000361e:	7942                	ld	s2,48(sp)
    80003620:	79a2                	ld	s3,40(sp)
    80003622:	7a02                	ld	s4,32(sp)
    80003624:	6ae2                	ld	s5,24(sp)
    80003626:	6b42                	ld	s6,16(sp)
    80003628:	6ba2                	ld	s7,8(sp)
    8000362a:	6161                	addi	sp,sp,80
    8000362c:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    8000362e:	04000613          	li	a2,64
    80003632:	4581                	li	a1,0
    80003634:	854e                	mv	a0,s3
    80003636:	ffffd097          	auipc	ra,0xffffd
    8000363a:	69c080e7          	jalr	1692(ra) # 80000cd2 <memset>
      dip->type = type;
    8000363e:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003642:	854a                	mv	a0,s2
    80003644:	00001097          	auipc	ra,0x1
    80003648:	c8e080e7          	jalr	-882(ra) # 800042d2 <log_write>
      brelse(bp);
    8000364c:	854a                	mv	a0,s2
    8000364e:	00000097          	auipc	ra,0x0
    80003652:	9fa080e7          	jalr	-1542(ra) # 80003048 <brelse>
      return iget(dev, inum);
    80003656:	85da                	mv	a1,s6
    80003658:	8556                	mv	a0,s5
    8000365a:	00000097          	auipc	ra,0x0
    8000365e:	d9c080e7          	jalr	-612(ra) # 800033f6 <iget>
    80003662:	bf5d                	j	80003618 <ialloc+0x86>

0000000080003664 <iupdate>:
{
    80003664:	1101                	addi	sp,sp,-32
    80003666:	ec06                	sd	ra,24(sp)
    80003668:	e822                	sd	s0,16(sp)
    8000366a:	e426                	sd	s1,8(sp)
    8000366c:	e04a                	sd	s2,0(sp)
    8000366e:	1000                	addi	s0,sp,32
    80003670:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003672:	415c                	lw	a5,4(a0)
    80003674:	0047d79b          	srliw	a5,a5,0x4
    80003678:	0001c597          	auipc	a1,0x1c
    8000367c:	a685a583          	lw	a1,-1432(a1) # 8001f0e0 <sb+0x18>
    80003680:	9dbd                	addw	a1,a1,a5
    80003682:	4108                	lw	a0,0(a0)
    80003684:	00000097          	auipc	ra,0x0
    80003688:	894080e7          	jalr	-1900(ra) # 80002f18 <bread>
    8000368c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000368e:	05850793          	addi	a5,a0,88
    80003692:	40d8                	lw	a4,4(s1)
    80003694:	8b3d                	andi	a4,a4,15
    80003696:	071a                	slli	a4,a4,0x6
    80003698:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    8000369a:	04449703          	lh	a4,68(s1)
    8000369e:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    800036a2:	04649703          	lh	a4,70(s1)
    800036a6:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    800036aa:	04849703          	lh	a4,72(s1)
    800036ae:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800036b2:	04a49703          	lh	a4,74(s1)
    800036b6:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    800036ba:	44f8                	lw	a4,76(s1)
    800036bc:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800036be:	03400613          	li	a2,52
    800036c2:	05048593          	addi	a1,s1,80
    800036c6:	00c78513          	addi	a0,a5,12
    800036ca:	ffffd097          	auipc	ra,0xffffd
    800036ce:	664080e7          	jalr	1636(ra) # 80000d2e <memmove>
  log_write(bp);
    800036d2:	854a                	mv	a0,s2
    800036d4:	00001097          	auipc	ra,0x1
    800036d8:	bfe080e7          	jalr	-1026(ra) # 800042d2 <log_write>
  brelse(bp);
    800036dc:	854a                	mv	a0,s2
    800036de:	00000097          	auipc	ra,0x0
    800036e2:	96a080e7          	jalr	-1686(ra) # 80003048 <brelse>
}
    800036e6:	60e2                	ld	ra,24(sp)
    800036e8:	6442                	ld	s0,16(sp)
    800036ea:	64a2                	ld	s1,8(sp)
    800036ec:	6902                	ld	s2,0(sp)
    800036ee:	6105                	addi	sp,sp,32
    800036f0:	8082                	ret

00000000800036f2 <idup>:
{
    800036f2:	1101                	addi	sp,sp,-32
    800036f4:	ec06                	sd	ra,24(sp)
    800036f6:	e822                	sd	s0,16(sp)
    800036f8:	e426                	sd	s1,8(sp)
    800036fa:	1000                	addi	s0,sp,32
    800036fc:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800036fe:	0001c517          	auipc	a0,0x1c
    80003702:	9ea50513          	addi	a0,a0,-1558 # 8001f0e8 <itable>
    80003706:	ffffd097          	auipc	ra,0xffffd
    8000370a:	4d0080e7          	jalr	1232(ra) # 80000bd6 <acquire>
  ip->ref++;
    8000370e:	449c                	lw	a5,8(s1)
    80003710:	2785                	addiw	a5,a5,1
    80003712:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003714:	0001c517          	auipc	a0,0x1c
    80003718:	9d450513          	addi	a0,a0,-1580 # 8001f0e8 <itable>
    8000371c:	ffffd097          	auipc	ra,0xffffd
    80003720:	56e080e7          	jalr	1390(ra) # 80000c8a <release>
}
    80003724:	8526                	mv	a0,s1
    80003726:	60e2                	ld	ra,24(sp)
    80003728:	6442                	ld	s0,16(sp)
    8000372a:	64a2                	ld	s1,8(sp)
    8000372c:	6105                	addi	sp,sp,32
    8000372e:	8082                	ret

0000000080003730 <ilock>:
{
    80003730:	1101                	addi	sp,sp,-32
    80003732:	ec06                	sd	ra,24(sp)
    80003734:	e822                	sd	s0,16(sp)
    80003736:	e426                	sd	s1,8(sp)
    80003738:	e04a                	sd	s2,0(sp)
    8000373a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000373c:	c115                	beqz	a0,80003760 <ilock+0x30>
    8000373e:	84aa                	mv	s1,a0
    80003740:	451c                	lw	a5,8(a0)
    80003742:	00f05f63          	blez	a5,80003760 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003746:	0541                	addi	a0,a0,16
    80003748:	00001097          	auipc	ra,0x1
    8000374c:	ca8080e7          	jalr	-856(ra) # 800043f0 <acquiresleep>
  if(ip->valid == 0){
    80003750:	40bc                	lw	a5,64(s1)
    80003752:	cf99                	beqz	a5,80003770 <ilock+0x40>
}
    80003754:	60e2                	ld	ra,24(sp)
    80003756:	6442                	ld	s0,16(sp)
    80003758:	64a2                	ld	s1,8(sp)
    8000375a:	6902                	ld	s2,0(sp)
    8000375c:	6105                	addi	sp,sp,32
    8000375e:	8082                	ret
    panic("ilock");
    80003760:	00005517          	auipc	a0,0x5
    80003764:	ed850513          	addi	a0,a0,-296 # 80008638 <syscalls+0x1a8>
    80003768:	ffffd097          	auipc	ra,0xffffd
    8000376c:	dd8080e7          	jalr	-552(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003770:	40dc                	lw	a5,4(s1)
    80003772:	0047d79b          	srliw	a5,a5,0x4
    80003776:	0001c597          	auipc	a1,0x1c
    8000377a:	96a5a583          	lw	a1,-1686(a1) # 8001f0e0 <sb+0x18>
    8000377e:	9dbd                	addw	a1,a1,a5
    80003780:	4088                	lw	a0,0(s1)
    80003782:	fffff097          	auipc	ra,0xfffff
    80003786:	796080e7          	jalr	1942(ra) # 80002f18 <bread>
    8000378a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000378c:	05850593          	addi	a1,a0,88
    80003790:	40dc                	lw	a5,4(s1)
    80003792:	8bbd                	andi	a5,a5,15
    80003794:	079a                	slli	a5,a5,0x6
    80003796:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003798:	00059783          	lh	a5,0(a1)
    8000379c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800037a0:	00259783          	lh	a5,2(a1)
    800037a4:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800037a8:	00459783          	lh	a5,4(a1)
    800037ac:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800037b0:	00659783          	lh	a5,6(a1)
    800037b4:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800037b8:	459c                	lw	a5,8(a1)
    800037ba:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800037bc:	03400613          	li	a2,52
    800037c0:	05b1                	addi	a1,a1,12
    800037c2:	05048513          	addi	a0,s1,80
    800037c6:	ffffd097          	auipc	ra,0xffffd
    800037ca:	568080e7          	jalr	1384(ra) # 80000d2e <memmove>
    brelse(bp);
    800037ce:	854a                	mv	a0,s2
    800037d0:	00000097          	auipc	ra,0x0
    800037d4:	878080e7          	jalr	-1928(ra) # 80003048 <brelse>
    ip->valid = 1;
    800037d8:	4785                	li	a5,1
    800037da:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800037dc:	04449783          	lh	a5,68(s1)
    800037e0:	fbb5                	bnez	a5,80003754 <ilock+0x24>
      panic("ilock: no type");
    800037e2:	00005517          	auipc	a0,0x5
    800037e6:	e5e50513          	addi	a0,a0,-418 # 80008640 <syscalls+0x1b0>
    800037ea:	ffffd097          	auipc	ra,0xffffd
    800037ee:	d56080e7          	jalr	-682(ra) # 80000540 <panic>

00000000800037f2 <iunlock>:
{
    800037f2:	1101                	addi	sp,sp,-32
    800037f4:	ec06                	sd	ra,24(sp)
    800037f6:	e822                	sd	s0,16(sp)
    800037f8:	e426                	sd	s1,8(sp)
    800037fa:	e04a                	sd	s2,0(sp)
    800037fc:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800037fe:	c905                	beqz	a0,8000382e <iunlock+0x3c>
    80003800:	84aa                	mv	s1,a0
    80003802:	01050913          	addi	s2,a0,16
    80003806:	854a                	mv	a0,s2
    80003808:	00001097          	auipc	ra,0x1
    8000380c:	c82080e7          	jalr	-894(ra) # 8000448a <holdingsleep>
    80003810:	cd19                	beqz	a0,8000382e <iunlock+0x3c>
    80003812:	449c                	lw	a5,8(s1)
    80003814:	00f05d63          	blez	a5,8000382e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003818:	854a                	mv	a0,s2
    8000381a:	00001097          	auipc	ra,0x1
    8000381e:	c2c080e7          	jalr	-980(ra) # 80004446 <releasesleep>
}
    80003822:	60e2                	ld	ra,24(sp)
    80003824:	6442                	ld	s0,16(sp)
    80003826:	64a2                	ld	s1,8(sp)
    80003828:	6902                	ld	s2,0(sp)
    8000382a:	6105                	addi	sp,sp,32
    8000382c:	8082                	ret
    panic("iunlock");
    8000382e:	00005517          	auipc	a0,0x5
    80003832:	e2250513          	addi	a0,a0,-478 # 80008650 <syscalls+0x1c0>
    80003836:	ffffd097          	auipc	ra,0xffffd
    8000383a:	d0a080e7          	jalr	-758(ra) # 80000540 <panic>

000000008000383e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000383e:	7179                	addi	sp,sp,-48
    80003840:	f406                	sd	ra,40(sp)
    80003842:	f022                	sd	s0,32(sp)
    80003844:	ec26                	sd	s1,24(sp)
    80003846:	e84a                	sd	s2,16(sp)
    80003848:	e44e                	sd	s3,8(sp)
    8000384a:	e052                	sd	s4,0(sp)
    8000384c:	1800                	addi	s0,sp,48
    8000384e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003850:	05050493          	addi	s1,a0,80
    80003854:	08050913          	addi	s2,a0,128
    80003858:	a021                	j	80003860 <itrunc+0x22>
    8000385a:	0491                	addi	s1,s1,4
    8000385c:	01248d63          	beq	s1,s2,80003876 <itrunc+0x38>
    if(ip->addrs[i]){
    80003860:	408c                	lw	a1,0(s1)
    80003862:	dde5                	beqz	a1,8000385a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003864:	0009a503          	lw	a0,0(s3)
    80003868:	00000097          	auipc	ra,0x0
    8000386c:	8f6080e7          	jalr	-1802(ra) # 8000315e <bfree>
      ip->addrs[i] = 0;
    80003870:	0004a023          	sw	zero,0(s1)
    80003874:	b7dd                	j	8000385a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003876:	0809a583          	lw	a1,128(s3)
    8000387a:	e185                	bnez	a1,8000389a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000387c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003880:	854e                	mv	a0,s3
    80003882:	00000097          	auipc	ra,0x0
    80003886:	de2080e7          	jalr	-542(ra) # 80003664 <iupdate>
}
    8000388a:	70a2                	ld	ra,40(sp)
    8000388c:	7402                	ld	s0,32(sp)
    8000388e:	64e2                	ld	s1,24(sp)
    80003890:	6942                	ld	s2,16(sp)
    80003892:	69a2                	ld	s3,8(sp)
    80003894:	6a02                	ld	s4,0(sp)
    80003896:	6145                	addi	sp,sp,48
    80003898:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000389a:	0009a503          	lw	a0,0(s3)
    8000389e:	fffff097          	auipc	ra,0xfffff
    800038a2:	67a080e7          	jalr	1658(ra) # 80002f18 <bread>
    800038a6:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800038a8:	05850493          	addi	s1,a0,88
    800038ac:	45850913          	addi	s2,a0,1112
    800038b0:	a021                	j	800038b8 <itrunc+0x7a>
    800038b2:	0491                	addi	s1,s1,4
    800038b4:	01248b63          	beq	s1,s2,800038ca <itrunc+0x8c>
      if(a[j])
    800038b8:	408c                	lw	a1,0(s1)
    800038ba:	dde5                	beqz	a1,800038b2 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800038bc:	0009a503          	lw	a0,0(s3)
    800038c0:	00000097          	auipc	ra,0x0
    800038c4:	89e080e7          	jalr	-1890(ra) # 8000315e <bfree>
    800038c8:	b7ed                	j	800038b2 <itrunc+0x74>
    brelse(bp);
    800038ca:	8552                	mv	a0,s4
    800038cc:	fffff097          	auipc	ra,0xfffff
    800038d0:	77c080e7          	jalr	1916(ra) # 80003048 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800038d4:	0809a583          	lw	a1,128(s3)
    800038d8:	0009a503          	lw	a0,0(s3)
    800038dc:	00000097          	auipc	ra,0x0
    800038e0:	882080e7          	jalr	-1918(ra) # 8000315e <bfree>
    ip->addrs[NDIRECT] = 0;
    800038e4:	0809a023          	sw	zero,128(s3)
    800038e8:	bf51                	j	8000387c <itrunc+0x3e>

00000000800038ea <iput>:
{
    800038ea:	1101                	addi	sp,sp,-32
    800038ec:	ec06                	sd	ra,24(sp)
    800038ee:	e822                	sd	s0,16(sp)
    800038f0:	e426                	sd	s1,8(sp)
    800038f2:	e04a                	sd	s2,0(sp)
    800038f4:	1000                	addi	s0,sp,32
    800038f6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800038f8:	0001b517          	auipc	a0,0x1b
    800038fc:	7f050513          	addi	a0,a0,2032 # 8001f0e8 <itable>
    80003900:	ffffd097          	auipc	ra,0xffffd
    80003904:	2d6080e7          	jalr	726(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003908:	4498                	lw	a4,8(s1)
    8000390a:	4785                	li	a5,1
    8000390c:	02f70363          	beq	a4,a5,80003932 <iput+0x48>
  ip->ref--;
    80003910:	449c                	lw	a5,8(s1)
    80003912:	37fd                	addiw	a5,a5,-1
    80003914:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003916:	0001b517          	auipc	a0,0x1b
    8000391a:	7d250513          	addi	a0,a0,2002 # 8001f0e8 <itable>
    8000391e:	ffffd097          	auipc	ra,0xffffd
    80003922:	36c080e7          	jalr	876(ra) # 80000c8a <release>
}
    80003926:	60e2                	ld	ra,24(sp)
    80003928:	6442                	ld	s0,16(sp)
    8000392a:	64a2                	ld	s1,8(sp)
    8000392c:	6902                	ld	s2,0(sp)
    8000392e:	6105                	addi	sp,sp,32
    80003930:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003932:	40bc                	lw	a5,64(s1)
    80003934:	dff1                	beqz	a5,80003910 <iput+0x26>
    80003936:	04a49783          	lh	a5,74(s1)
    8000393a:	fbf9                	bnez	a5,80003910 <iput+0x26>
    acquiresleep(&ip->lock);
    8000393c:	01048913          	addi	s2,s1,16
    80003940:	854a                	mv	a0,s2
    80003942:	00001097          	auipc	ra,0x1
    80003946:	aae080e7          	jalr	-1362(ra) # 800043f0 <acquiresleep>
    release(&itable.lock);
    8000394a:	0001b517          	auipc	a0,0x1b
    8000394e:	79e50513          	addi	a0,a0,1950 # 8001f0e8 <itable>
    80003952:	ffffd097          	auipc	ra,0xffffd
    80003956:	338080e7          	jalr	824(ra) # 80000c8a <release>
    itrunc(ip);
    8000395a:	8526                	mv	a0,s1
    8000395c:	00000097          	auipc	ra,0x0
    80003960:	ee2080e7          	jalr	-286(ra) # 8000383e <itrunc>
    ip->type = 0;
    80003964:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003968:	8526                	mv	a0,s1
    8000396a:	00000097          	auipc	ra,0x0
    8000396e:	cfa080e7          	jalr	-774(ra) # 80003664 <iupdate>
    ip->valid = 0;
    80003972:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003976:	854a                	mv	a0,s2
    80003978:	00001097          	auipc	ra,0x1
    8000397c:	ace080e7          	jalr	-1330(ra) # 80004446 <releasesleep>
    acquire(&itable.lock);
    80003980:	0001b517          	auipc	a0,0x1b
    80003984:	76850513          	addi	a0,a0,1896 # 8001f0e8 <itable>
    80003988:	ffffd097          	auipc	ra,0xffffd
    8000398c:	24e080e7          	jalr	590(ra) # 80000bd6 <acquire>
    80003990:	b741                	j	80003910 <iput+0x26>

0000000080003992 <iunlockput>:
{
    80003992:	1101                	addi	sp,sp,-32
    80003994:	ec06                	sd	ra,24(sp)
    80003996:	e822                	sd	s0,16(sp)
    80003998:	e426                	sd	s1,8(sp)
    8000399a:	1000                	addi	s0,sp,32
    8000399c:	84aa                	mv	s1,a0
  iunlock(ip);
    8000399e:	00000097          	auipc	ra,0x0
    800039a2:	e54080e7          	jalr	-428(ra) # 800037f2 <iunlock>
  iput(ip);
    800039a6:	8526                	mv	a0,s1
    800039a8:	00000097          	auipc	ra,0x0
    800039ac:	f42080e7          	jalr	-190(ra) # 800038ea <iput>
}
    800039b0:	60e2                	ld	ra,24(sp)
    800039b2:	6442                	ld	s0,16(sp)
    800039b4:	64a2                	ld	s1,8(sp)
    800039b6:	6105                	addi	sp,sp,32
    800039b8:	8082                	ret

00000000800039ba <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800039ba:	1141                	addi	sp,sp,-16
    800039bc:	e422                	sd	s0,8(sp)
    800039be:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800039c0:	411c                	lw	a5,0(a0)
    800039c2:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800039c4:	415c                	lw	a5,4(a0)
    800039c6:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800039c8:	04451783          	lh	a5,68(a0)
    800039cc:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800039d0:	04a51783          	lh	a5,74(a0)
    800039d4:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800039d8:	04c56783          	lwu	a5,76(a0)
    800039dc:	e99c                	sd	a5,16(a1)
}
    800039de:	6422                	ld	s0,8(sp)
    800039e0:	0141                	addi	sp,sp,16
    800039e2:	8082                	ret

00000000800039e4 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039e4:	457c                	lw	a5,76(a0)
    800039e6:	0ed7e963          	bltu	a5,a3,80003ad8 <readi+0xf4>
{
    800039ea:	7159                	addi	sp,sp,-112
    800039ec:	f486                	sd	ra,104(sp)
    800039ee:	f0a2                	sd	s0,96(sp)
    800039f0:	eca6                	sd	s1,88(sp)
    800039f2:	e8ca                	sd	s2,80(sp)
    800039f4:	e4ce                	sd	s3,72(sp)
    800039f6:	e0d2                	sd	s4,64(sp)
    800039f8:	fc56                	sd	s5,56(sp)
    800039fa:	f85a                	sd	s6,48(sp)
    800039fc:	f45e                	sd	s7,40(sp)
    800039fe:	f062                	sd	s8,32(sp)
    80003a00:	ec66                	sd	s9,24(sp)
    80003a02:	e86a                	sd	s10,16(sp)
    80003a04:	e46e                	sd	s11,8(sp)
    80003a06:	1880                	addi	s0,sp,112
    80003a08:	8b2a                	mv	s6,a0
    80003a0a:	8bae                	mv	s7,a1
    80003a0c:	8a32                	mv	s4,a2
    80003a0e:	84b6                	mv	s1,a3
    80003a10:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003a12:	9f35                	addw	a4,a4,a3
    return 0;
    80003a14:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a16:	0ad76063          	bltu	a4,a3,80003ab6 <readi+0xd2>
  if(off + n > ip->size)
    80003a1a:	00e7f463          	bgeu	a5,a4,80003a22 <readi+0x3e>
    n = ip->size - off;
    80003a1e:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a22:	0a0a8963          	beqz	s5,80003ad4 <readi+0xf0>
    80003a26:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a28:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a2c:	5c7d                	li	s8,-1
    80003a2e:	a82d                	j	80003a68 <readi+0x84>
    80003a30:	020d1d93          	slli	s11,s10,0x20
    80003a34:	020ddd93          	srli	s11,s11,0x20
    80003a38:	05890613          	addi	a2,s2,88
    80003a3c:	86ee                	mv	a3,s11
    80003a3e:	963a                	add	a2,a2,a4
    80003a40:	85d2                	mv	a1,s4
    80003a42:	855e                	mv	a0,s7
    80003a44:	fffff097          	auipc	ra,0xfffff
    80003a48:	a18080e7          	jalr	-1512(ra) # 8000245c <either_copyout>
    80003a4c:	05850d63          	beq	a0,s8,80003aa6 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003a50:	854a                	mv	a0,s2
    80003a52:	fffff097          	auipc	ra,0xfffff
    80003a56:	5f6080e7          	jalr	1526(ra) # 80003048 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a5a:	013d09bb          	addw	s3,s10,s3
    80003a5e:	009d04bb          	addw	s1,s10,s1
    80003a62:	9a6e                	add	s4,s4,s11
    80003a64:	0559f763          	bgeu	s3,s5,80003ab2 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003a68:	00a4d59b          	srliw	a1,s1,0xa
    80003a6c:	855a                	mv	a0,s6
    80003a6e:	00000097          	auipc	ra,0x0
    80003a72:	89e080e7          	jalr	-1890(ra) # 8000330c <bmap>
    80003a76:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003a7a:	cd85                	beqz	a1,80003ab2 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003a7c:	000b2503          	lw	a0,0(s6)
    80003a80:	fffff097          	auipc	ra,0xfffff
    80003a84:	498080e7          	jalr	1176(ra) # 80002f18 <bread>
    80003a88:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a8a:	3ff4f713          	andi	a4,s1,1023
    80003a8e:	40ec87bb          	subw	a5,s9,a4
    80003a92:	413a86bb          	subw	a3,s5,s3
    80003a96:	8d3e                	mv	s10,a5
    80003a98:	2781                	sext.w	a5,a5
    80003a9a:	0006861b          	sext.w	a2,a3
    80003a9e:	f8f679e3          	bgeu	a2,a5,80003a30 <readi+0x4c>
    80003aa2:	8d36                	mv	s10,a3
    80003aa4:	b771                	j	80003a30 <readi+0x4c>
      brelse(bp);
    80003aa6:	854a                	mv	a0,s2
    80003aa8:	fffff097          	auipc	ra,0xfffff
    80003aac:	5a0080e7          	jalr	1440(ra) # 80003048 <brelse>
      tot = -1;
    80003ab0:	59fd                	li	s3,-1
  }
  return tot;
    80003ab2:	0009851b          	sext.w	a0,s3
}
    80003ab6:	70a6                	ld	ra,104(sp)
    80003ab8:	7406                	ld	s0,96(sp)
    80003aba:	64e6                	ld	s1,88(sp)
    80003abc:	6946                	ld	s2,80(sp)
    80003abe:	69a6                	ld	s3,72(sp)
    80003ac0:	6a06                	ld	s4,64(sp)
    80003ac2:	7ae2                	ld	s5,56(sp)
    80003ac4:	7b42                	ld	s6,48(sp)
    80003ac6:	7ba2                	ld	s7,40(sp)
    80003ac8:	7c02                	ld	s8,32(sp)
    80003aca:	6ce2                	ld	s9,24(sp)
    80003acc:	6d42                	ld	s10,16(sp)
    80003ace:	6da2                	ld	s11,8(sp)
    80003ad0:	6165                	addi	sp,sp,112
    80003ad2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ad4:	89d6                	mv	s3,s5
    80003ad6:	bff1                	j	80003ab2 <readi+0xce>
    return 0;
    80003ad8:	4501                	li	a0,0
}
    80003ada:	8082                	ret

0000000080003adc <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003adc:	457c                	lw	a5,76(a0)
    80003ade:	10d7e863          	bltu	a5,a3,80003bee <writei+0x112>
{
    80003ae2:	7159                	addi	sp,sp,-112
    80003ae4:	f486                	sd	ra,104(sp)
    80003ae6:	f0a2                	sd	s0,96(sp)
    80003ae8:	eca6                	sd	s1,88(sp)
    80003aea:	e8ca                	sd	s2,80(sp)
    80003aec:	e4ce                	sd	s3,72(sp)
    80003aee:	e0d2                	sd	s4,64(sp)
    80003af0:	fc56                	sd	s5,56(sp)
    80003af2:	f85a                	sd	s6,48(sp)
    80003af4:	f45e                	sd	s7,40(sp)
    80003af6:	f062                	sd	s8,32(sp)
    80003af8:	ec66                	sd	s9,24(sp)
    80003afa:	e86a                	sd	s10,16(sp)
    80003afc:	e46e                	sd	s11,8(sp)
    80003afe:	1880                	addi	s0,sp,112
    80003b00:	8aaa                	mv	s5,a0
    80003b02:	8bae                	mv	s7,a1
    80003b04:	8a32                	mv	s4,a2
    80003b06:	8936                	mv	s2,a3
    80003b08:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b0a:	00e687bb          	addw	a5,a3,a4
    80003b0e:	0ed7e263          	bltu	a5,a3,80003bf2 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b12:	00043737          	lui	a4,0x43
    80003b16:	0ef76063          	bltu	a4,a5,80003bf6 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b1a:	0c0b0863          	beqz	s6,80003bea <writei+0x10e>
    80003b1e:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b20:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b24:	5c7d                	li	s8,-1
    80003b26:	a091                	j	80003b6a <writei+0x8e>
    80003b28:	020d1d93          	slli	s11,s10,0x20
    80003b2c:	020ddd93          	srli	s11,s11,0x20
    80003b30:	05848513          	addi	a0,s1,88
    80003b34:	86ee                	mv	a3,s11
    80003b36:	8652                	mv	a2,s4
    80003b38:	85de                	mv	a1,s7
    80003b3a:	953a                	add	a0,a0,a4
    80003b3c:	fffff097          	auipc	ra,0xfffff
    80003b40:	976080e7          	jalr	-1674(ra) # 800024b2 <either_copyin>
    80003b44:	07850263          	beq	a0,s8,80003ba8 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b48:	8526                	mv	a0,s1
    80003b4a:	00000097          	auipc	ra,0x0
    80003b4e:	788080e7          	jalr	1928(ra) # 800042d2 <log_write>
    brelse(bp);
    80003b52:	8526                	mv	a0,s1
    80003b54:	fffff097          	auipc	ra,0xfffff
    80003b58:	4f4080e7          	jalr	1268(ra) # 80003048 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b5c:	013d09bb          	addw	s3,s10,s3
    80003b60:	012d093b          	addw	s2,s10,s2
    80003b64:	9a6e                	add	s4,s4,s11
    80003b66:	0569f663          	bgeu	s3,s6,80003bb2 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003b6a:	00a9559b          	srliw	a1,s2,0xa
    80003b6e:	8556                	mv	a0,s5
    80003b70:	fffff097          	auipc	ra,0xfffff
    80003b74:	79c080e7          	jalr	1948(ra) # 8000330c <bmap>
    80003b78:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003b7c:	c99d                	beqz	a1,80003bb2 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003b7e:	000aa503          	lw	a0,0(s5)
    80003b82:	fffff097          	auipc	ra,0xfffff
    80003b86:	396080e7          	jalr	918(ra) # 80002f18 <bread>
    80003b8a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b8c:	3ff97713          	andi	a4,s2,1023
    80003b90:	40ec87bb          	subw	a5,s9,a4
    80003b94:	413b06bb          	subw	a3,s6,s3
    80003b98:	8d3e                	mv	s10,a5
    80003b9a:	2781                	sext.w	a5,a5
    80003b9c:	0006861b          	sext.w	a2,a3
    80003ba0:	f8f674e3          	bgeu	a2,a5,80003b28 <writei+0x4c>
    80003ba4:	8d36                	mv	s10,a3
    80003ba6:	b749                	j	80003b28 <writei+0x4c>
      brelse(bp);
    80003ba8:	8526                	mv	a0,s1
    80003baa:	fffff097          	auipc	ra,0xfffff
    80003bae:	49e080e7          	jalr	1182(ra) # 80003048 <brelse>
  }

  if(off > ip->size)
    80003bb2:	04caa783          	lw	a5,76(s5)
    80003bb6:	0127f463          	bgeu	a5,s2,80003bbe <writei+0xe2>
    ip->size = off;
    80003bba:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003bbe:	8556                	mv	a0,s5
    80003bc0:	00000097          	auipc	ra,0x0
    80003bc4:	aa4080e7          	jalr	-1372(ra) # 80003664 <iupdate>

  return tot;
    80003bc8:	0009851b          	sext.w	a0,s3
}
    80003bcc:	70a6                	ld	ra,104(sp)
    80003bce:	7406                	ld	s0,96(sp)
    80003bd0:	64e6                	ld	s1,88(sp)
    80003bd2:	6946                	ld	s2,80(sp)
    80003bd4:	69a6                	ld	s3,72(sp)
    80003bd6:	6a06                	ld	s4,64(sp)
    80003bd8:	7ae2                	ld	s5,56(sp)
    80003bda:	7b42                	ld	s6,48(sp)
    80003bdc:	7ba2                	ld	s7,40(sp)
    80003bde:	7c02                	ld	s8,32(sp)
    80003be0:	6ce2                	ld	s9,24(sp)
    80003be2:	6d42                	ld	s10,16(sp)
    80003be4:	6da2                	ld	s11,8(sp)
    80003be6:	6165                	addi	sp,sp,112
    80003be8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bea:	89da                	mv	s3,s6
    80003bec:	bfc9                	j	80003bbe <writei+0xe2>
    return -1;
    80003bee:	557d                	li	a0,-1
}
    80003bf0:	8082                	ret
    return -1;
    80003bf2:	557d                	li	a0,-1
    80003bf4:	bfe1                	j	80003bcc <writei+0xf0>
    return -1;
    80003bf6:	557d                	li	a0,-1
    80003bf8:	bfd1                	j	80003bcc <writei+0xf0>

0000000080003bfa <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003bfa:	1141                	addi	sp,sp,-16
    80003bfc:	e406                	sd	ra,8(sp)
    80003bfe:	e022                	sd	s0,0(sp)
    80003c00:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c02:	4639                	li	a2,14
    80003c04:	ffffd097          	auipc	ra,0xffffd
    80003c08:	19e080e7          	jalr	414(ra) # 80000da2 <strncmp>
}
    80003c0c:	60a2                	ld	ra,8(sp)
    80003c0e:	6402                	ld	s0,0(sp)
    80003c10:	0141                	addi	sp,sp,16
    80003c12:	8082                	ret

0000000080003c14 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c14:	7139                	addi	sp,sp,-64
    80003c16:	fc06                	sd	ra,56(sp)
    80003c18:	f822                	sd	s0,48(sp)
    80003c1a:	f426                	sd	s1,40(sp)
    80003c1c:	f04a                	sd	s2,32(sp)
    80003c1e:	ec4e                	sd	s3,24(sp)
    80003c20:	e852                	sd	s4,16(sp)
    80003c22:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c24:	04451703          	lh	a4,68(a0)
    80003c28:	4785                	li	a5,1
    80003c2a:	00f71a63          	bne	a4,a5,80003c3e <dirlookup+0x2a>
    80003c2e:	892a                	mv	s2,a0
    80003c30:	89ae                	mv	s3,a1
    80003c32:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c34:	457c                	lw	a5,76(a0)
    80003c36:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c38:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c3a:	e79d                	bnez	a5,80003c68 <dirlookup+0x54>
    80003c3c:	a8a5                	j	80003cb4 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c3e:	00005517          	auipc	a0,0x5
    80003c42:	a1a50513          	addi	a0,a0,-1510 # 80008658 <syscalls+0x1c8>
    80003c46:	ffffd097          	auipc	ra,0xffffd
    80003c4a:	8fa080e7          	jalr	-1798(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003c4e:	00005517          	auipc	a0,0x5
    80003c52:	a2250513          	addi	a0,a0,-1502 # 80008670 <syscalls+0x1e0>
    80003c56:	ffffd097          	auipc	ra,0xffffd
    80003c5a:	8ea080e7          	jalr	-1814(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c5e:	24c1                	addiw	s1,s1,16
    80003c60:	04c92783          	lw	a5,76(s2)
    80003c64:	04f4f763          	bgeu	s1,a5,80003cb2 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c68:	4741                	li	a4,16
    80003c6a:	86a6                	mv	a3,s1
    80003c6c:	fc040613          	addi	a2,s0,-64
    80003c70:	4581                	li	a1,0
    80003c72:	854a                	mv	a0,s2
    80003c74:	00000097          	auipc	ra,0x0
    80003c78:	d70080e7          	jalr	-656(ra) # 800039e4 <readi>
    80003c7c:	47c1                	li	a5,16
    80003c7e:	fcf518e3          	bne	a0,a5,80003c4e <dirlookup+0x3a>
    if(de.inum == 0)
    80003c82:	fc045783          	lhu	a5,-64(s0)
    80003c86:	dfe1                	beqz	a5,80003c5e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003c88:	fc240593          	addi	a1,s0,-62
    80003c8c:	854e                	mv	a0,s3
    80003c8e:	00000097          	auipc	ra,0x0
    80003c92:	f6c080e7          	jalr	-148(ra) # 80003bfa <namecmp>
    80003c96:	f561                	bnez	a0,80003c5e <dirlookup+0x4a>
      if(poff)
    80003c98:	000a0463          	beqz	s4,80003ca0 <dirlookup+0x8c>
        *poff = off;
    80003c9c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003ca0:	fc045583          	lhu	a1,-64(s0)
    80003ca4:	00092503          	lw	a0,0(s2)
    80003ca8:	fffff097          	auipc	ra,0xfffff
    80003cac:	74e080e7          	jalr	1870(ra) # 800033f6 <iget>
    80003cb0:	a011                	j	80003cb4 <dirlookup+0xa0>
  return 0;
    80003cb2:	4501                	li	a0,0
}
    80003cb4:	70e2                	ld	ra,56(sp)
    80003cb6:	7442                	ld	s0,48(sp)
    80003cb8:	74a2                	ld	s1,40(sp)
    80003cba:	7902                	ld	s2,32(sp)
    80003cbc:	69e2                	ld	s3,24(sp)
    80003cbe:	6a42                	ld	s4,16(sp)
    80003cc0:	6121                	addi	sp,sp,64
    80003cc2:	8082                	ret

0000000080003cc4 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003cc4:	711d                	addi	sp,sp,-96
    80003cc6:	ec86                	sd	ra,88(sp)
    80003cc8:	e8a2                	sd	s0,80(sp)
    80003cca:	e4a6                	sd	s1,72(sp)
    80003ccc:	e0ca                	sd	s2,64(sp)
    80003cce:	fc4e                	sd	s3,56(sp)
    80003cd0:	f852                	sd	s4,48(sp)
    80003cd2:	f456                	sd	s5,40(sp)
    80003cd4:	f05a                	sd	s6,32(sp)
    80003cd6:	ec5e                	sd	s7,24(sp)
    80003cd8:	e862                	sd	s8,16(sp)
    80003cda:	e466                	sd	s9,8(sp)
    80003cdc:	e06a                	sd	s10,0(sp)
    80003cde:	1080                	addi	s0,sp,96
    80003ce0:	84aa                	mv	s1,a0
    80003ce2:	8b2e                	mv	s6,a1
    80003ce4:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003ce6:	00054703          	lbu	a4,0(a0)
    80003cea:	02f00793          	li	a5,47
    80003cee:	02f70363          	beq	a4,a5,80003d14 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003cf2:	ffffe097          	auipc	ra,0xffffe
    80003cf6:	cba080e7          	jalr	-838(ra) # 800019ac <myproc>
    80003cfa:	15053503          	ld	a0,336(a0)
    80003cfe:	00000097          	auipc	ra,0x0
    80003d02:	9f4080e7          	jalr	-1548(ra) # 800036f2 <idup>
    80003d06:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003d08:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003d0c:	4cb5                	li	s9,13
  len = path - s;
    80003d0e:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d10:	4c05                	li	s8,1
    80003d12:	a87d                	j	80003dd0 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003d14:	4585                	li	a1,1
    80003d16:	4505                	li	a0,1
    80003d18:	fffff097          	auipc	ra,0xfffff
    80003d1c:	6de080e7          	jalr	1758(ra) # 800033f6 <iget>
    80003d20:	8a2a                	mv	s4,a0
    80003d22:	b7dd                	j	80003d08 <namex+0x44>
      iunlockput(ip);
    80003d24:	8552                	mv	a0,s4
    80003d26:	00000097          	auipc	ra,0x0
    80003d2a:	c6c080e7          	jalr	-916(ra) # 80003992 <iunlockput>
      return 0;
    80003d2e:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d30:	8552                	mv	a0,s4
    80003d32:	60e6                	ld	ra,88(sp)
    80003d34:	6446                	ld	s0,80(sp)
    80003d36:	64a6                	ld	s1,72(sp)
    80003d38:	6906                	ld	s2,64(sp)
    80003d3a:	79e2                	ld	s3,56(sp)
    80003d3c:	7a42                	ld	s4,48(sp)
    80003d3e:	7aa2                	ld	s5,40(sp)
    80003d40:	7b02                	ld	s6,32(sp)
    80003d42:	6be2                	ld	s7,24(sp)
    80003d44:	6c42                	ld	s8,16(sp)
    80003d46:	6ca2                	ld	s9,8(sp)
    80003d48:	6d02                	ld	s10,0(sp)
    80003d4a:	6125                	addi	sp,sp,96
    80003d4c:	8082                	ret
      iunlock(ip);
    80003d4e:	8552                	mv	a0,s4
    80003d50:	00000097          	auipc	ra,0x0
    80003d54:	aa2080e7          	jalr	-1374(ra) # 800037f2 <iunlock>
      return ip;
    80003d58:	bfe1                	j	80003d30 <namex+0x6c>
      iunlockput(ip);
    80003d5a:	8552                	mv	a0,s4
    80003d5c:	00000097          	auipc	ra,0x0
    80003d60:	c36080e7          	jalr	-970(ra) # 80003992 <iunlockput>
      return 0;
    80003d64:	8a4e                	mv	s4,s3
    80003d66:	b7e9                	j	80003d30 <namex+0x6c>
  len = path - s;
    80003d68:	40998633          	sub	a2,s3,s1
    80003d6c:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003d70:	09acd863          	bge	s9,s10,80003e00 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003d74:	4639                	li	a2,14
    80003d76:	85a6                	mv	a1,s1
    80003d78:	8556                	mv	a0,s5
    80003d7a:	ffffd097          	auipc	ra,0xffffd
    80003d7e:	fb4080e7          	jalr	-76(ra) # 80000d2e <memmove>
    80003d82:	84ce                	mv	s1,s3
  while(*path == '/')
    80003d84:	0004c783          	lbu	a5,0(s1)
    80003d88:	01279763          	bne	a5,s2,80003d96 <namex+0xd2>
    path++;
    80003d8c:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d8e:	0004c783          	lbu	a5,0(s1)
    80003d92:	ff278de3          	beq	a5,s2,80003d8c <namex+0xc8>
    ilock(ip);
    80003d96:	8552                	mv	a0,s4
    80003d98:	00000097          	auipc	ra,0x0
    80003d9c:	998080e7          	jalr	-1640(ra) # 80003730 <ilock>
    if(ip->type != T_DIR){
    80003da0:	044a1783          	lh	a5,68(s4)
    80003da4:	f98790e3          	bne	a5,s8,80003d24 <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003da8:	000b0563          	beqz	s6,80003db2 <namex+0xee>
    80003dac:	0004c783          	lbu	a5,0(s1)
    80003db0:	dfd9                	beqz	a5,80003d4e <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003db2:	865e                	mv	a2,s7
    80003db4:	85d6                	mv	a1,s5
    80003db6:	8552                	mv	a0,s4
    80003db8:	00000097          	auipc	ra,0x0
    80003dbc:	e5c080e7          	jalr	-420(ra) # 80003c14 <dirlookup>
    80003dc0:	89aa                	mv	s3,a0
    80003dc2:	dd41                	beqz	a0,80003d5a <namex+0x96>
    iunlockput(ip);
    80003dc4:	8552                	mv	a0,s4
    80003dc6:	00000097          	auipc	ra,0x0
    80003dca:	bcc080e7          	jalr	-1076(ra) # 80003992 <iunlockput>
    ip = next;
    80003dce:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003dd0:	0004c783          	lbu	a5,0(s1)
    80003dd4:	01279763          	bne	a5,s2,80003de2 <namex+0x11e>
    path++;
    80003dd8:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003dda:	0004c783          	lbu	a5,0(s1)
    80003dde:	ff278de3          	beq	a5,s2,80003dd8 <namex+0x114>
  if(*path == 0)
    80003de2:	cb9d                	beqz	a5,80003e18 <namex+0x154>
  while(*path != '/' && *path != 0)
    80003de4:	0004c783          	lbu	a5,0(s1)
    80003de8:	89a6                	mv	s3,s1
  len = path - s;
    80003dea:	8d5e                	mv	s10,s7
    80003dec:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003dee:	01278963          	beq	a5,s2,80003e00 <namex+0x13c>
    80003df2:	dbbd                	beqz	a5,80003d68 <namex+0xa4>
    path++;
    80003df4:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003df6:	0009c783          	lbu	a5,0(s3)
    80003dfa:	ff279ce3          	bne	a5,s2,80003df2 <namex+0x12e>
    80003dfe:	b7ad                	j	80003d68 <namex+0xa4>
    memmove(name, s, len);
    80003e00:	2601                	sext.w	a2,a2
    80003e02:	85a6                	mv	a1,s1
    80003e04:	8556                	mv	a0,s5
    80003e06:	ffffd097          	auipc	ra,0xffffd
    80003e0a:	f28080e7          	jalr	-216(ra) # 80000d2e <memmove>
    name[len] = 0;
    80003e0e:	9d56                	add	s10,s10,s5
    80003e10:	000d0023          	sb	zero,0(s10)
    80003e14:	84ce                	mv	s1,s3
    80003e16:	b7bd                	j	80003d84 <namex+0xc0>
  if(nameiparent){
    80003e18:	f00b0ce3          	beqz	s6,80003d30 <namex+0x6c>
    iput(ip);
    80003e1c:	8552                	mv	a0,s4
    80003e1e:	00000097          	auipc	ra,0x0
    80003e22:	acc080e7          	jalr	-1332(ra) # 800038ea <iput>
    return 0;
    80003e26:	4a01                	li	s4,0
    80003e28:	b721                	j	80003d30 <namex+0x6c>

0000000080003e2a <dirlink>:
{
    80003e2a:	7139                	addi	sp,sp,-64
    80003e2c:	fc06                	sd	ra,56(sp)
    80003e2e:	f822                	sd	s0,48(sp)
    80003e30:	f426                	sd	s1,40(sp)
    80003e32:	f04a                	sd	s2,32(sp)
    80003e34:	ec4e                	sd	s3,24(sp)
    80003e36:	e852                	sd	s4,16(sp)
    80003e38:	0080                	addi	s0,sp,64
    80003e3a:	892a                	mv	s2,a0
    80003e3c:	8a2e                	mv	s4,a1
    80003e3e:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e40:	4601                	li	a2,0
    80003e42:	00000097          	auipc	ra,0x0
    80003e46:	dd2080e7          	jalr	-558(ra) # 80003c14 <dirlookup>
    80003e4a:	e93d                	bnez	a0,80003ec0 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e4c:	04c92483          	lw	s1,76(s2)
    80003e50:	c49d                	beqz	s1,80003e7e <dirlink+0x54>
    80003e52:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e54:	4741                	li	a4,16
    80003e56:	86a6                	mv	a3,s1
    80003e58:	fc040613          	addi	a2,s0,-64
    80003e5c:	4581                	li	a1,0
    80003e5e:	854a                	mv	a0,s2
    80003e60:	00000097          	auipc	ra,0x0
    80003e64:	b84080e7          	jalr	-1148(ra) # 800039e4 <readi>
    80003e68:	47c1                	li	a5,16
    80003e6a:	06f51163          	bne	a0,a5,80003ecc <dirlink+0xa2>
    if(de.inum == 0)
    80003e6e:	fc045783          	lhu	a5,-64(s0)
    80003e72:	c791                	beqz	a5,80003e7e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e74:	24c1                	addiw	s1,s1,16
    80003e76:	04c92783          	lw	a5,76(s2)
    80003e7a:	fcf4ede3          	bltu	s1,a5,80003e54 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e7e:	4639                	li	a2,14
    80003e80:	85d2                	mv	a1,s4
    80003e82:	fc240513          	addi	a0,s0,-62
    80003e86:	ffffd097          	auipc	ra,0xffffd
    80003e8a:	f58080e7          	jalr	-168(ra) # 80000dde <strncpy>
  de.inum = inum;
    80003e8e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e92:	4741                	li	a4,16
    80003e94:	86a6                	mv	a3,s1
    80003e96:	fc040613          	addi	a2,s0,-64
    80003e9a:	4581                	li	a1,0
    80003e9c:	854a                	mv	a0,s2
    80003e9e:	00000097          	auipc	ra,0x0
    80003ea2:	c3e080e7          	jalr	-962(ra) # 80003adc <writei>
    80003ea6:	1541                	addi	a0,a0,-16
    80003ea8:	00a03533          	snez	a0,a0
    80003eac:	40a00533          	neg	a0,a0
}
    80003eb0:	70e2                	ld	ra,56(sp)
    80003eb2:	7442                	ld	s0,48(sp)
    80003eb4:	74a2                	ld	s1,40(sp)
    80003eb6:	7902                	ld	s2,32(sp)
    80003eb8:	69e2                	ld	s3,24(sp)
    80003eba:	6a42                	ld	s4,16(sp)
    80003ebc:	6121                	addi	sp,sp,64
    80003ebe:	8082                	ret
    iput(ip);
    80003ec0:	00000097          	auipc	ra,0x0
    80003ec4:	a2a080e7          	jalr	-1494(ra) # 800038ea <iput>
    return -1;
    80003ec8:	557d                	li	a0,-1
    80003eca:	b7dd                	j	80003eb0 <dirlink+0x86>
      panic("dirlink read");
    80003ecc:	00004517          	auipc	a0,0x4
    80003ed0:	7b450513          	addi	a0,a0,1972 # 80008680 <syscalls+0x1f0>
    80003ed4:	ffffc097          	auipc	ra,0xffffc
    80003ed8:	66c080e7          	jalr	1644(ra) # 80000540 <panic>

0000000080003edc <namei>:

struct inode*
namei(char *path)
{
    80003edc:	1101                	addi	sp,sp,-32
    80003ede:	ec06                	sd	ra,24(sp)
    80003ee0:	e822                	sd	s0,16(sp)
    80003ee2:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003ee4:	fe040613          	addi	a2,s0,-32
    80003ee8:	4581                	li	a1,0
    80003eea:	00000097          	auipc	ra,0x0
    80003eee:	dda080e7          	jalr	-550(ra) # 80003cc4 <namex>
}
    80003ef2:	60e2                	ld	ra,24(sp)
    80003ef4:	6442                	ld	s0,16(sp)
    80003ef6:	6105                	addi	sp,sp,32
    80003ef8:	8082                	ret

0000000080003efa <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003efa:	1141                	addi	sp,sp,-16
    80003efc:	e406                	sd	ra,8(sp)
    80003efe:	e022                	sd	s0,0(sp)
    80003f00:	0800                	addi	s0,sp,16
    80003f02:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f04:	4585                	li	a1,1
    80003f06:	00000097          	auipc	ra,0x0
    80003f0a:	dbe080e7          	jalr	-578(ra) # 80003cc4 <namex>
}
    80003f0e:	60a2                	ld	ra,8(sp)
    80003f10:	6402                	ld	s0,0(sp)
    80003f12:	0141                	addi	sp,sp,16
    80003f14:	8082                	ret

0000000080003f16 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f16:	1101                	addi	sp,sp,-32
    80003f18:	ec06                	sd	ra,24(sp)
    80003f1a:	e822                	sd	s0,16(sp)
    80003f1c:	e426                	sd	s1,8(sp)
    80003f1e:	e04a                	sd	s2,0(sp)
    80003f20:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f22:	0001d917          	auipc	s2,0x1d
    80003f26:	c6e90913          	addi	s2,s2,-914 # 80020b90 <log>
    80003f2a:	01892583          	lw	a1,24(s2)
    80003f2e:	02892503          	lw	a0,40(s2)
    80003f32:	fffff097          	auipc	ra,0xfffff
    80003f36:	fe6080e7          	jalr	-26(ra) # 80002f18 <bread>
    80003f3a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f3c:	02c92683          	lw	a3,44(s2)
    80003f40:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f42:	02d05863          	blez	a3,80003f72 <write_head+0x5c>
    80003f46:	0001d797          	auipc	a5,0x1d
    80003f4a:	c7a78793          	addi	a5,a5,-902 # 80020bc0 <log+0x30>
    80003f4e:	05c50713          	addi	a4,a0,92
    80003f52:	36fd                	addiw	a3,a3,-1
    80003f54:	02069613          	slli	a2,a3,0x20
    80003f58:	01e65693          	srli	a3,a2,0x1e
    80003f5c:	0001d617          	auipc	a2,0x1d
    80003f60:	c6860613          	addi	a2,a2,-920 # 80020bc4 <log+0x34>
    80003f64:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003f66:	4390                	lw	a2,0(a5)
    80003f68:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f6a:	0791                	addi	a5,a5,4
    80003f6c:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80003f6e:	fed79ce3          	bne	a5,a3,80003f66 <write_head+0x50>
  }
  bwrite(buf);
    80003f72:	8526                	mv	a0,s1
    80003f74:	fffff097          	auipc	ra,0xfffff
    80003f78:	096080e7          	jalr	150(ra) # 8000300a <bwrite>
  brelse(buf);
    80003f7c:	8526                	mv	a0,s1
    80003f7e:	fffff097          	auipc	ra,0xfffff
    80003f82:	0ca080e7          	jalr	202(ra) # 80003048 <brelse>
}
    80003f86:	60e2                	ld	ra,24(sp)
    80003f88:	6442                	ld	s0,16(sp)
    80003f8a:	64a2                	ld	s1,8(sp)
    80003f8c:	6902                	ld	s2,0(sp)
    80003f8e:	6105                	addi	sp,sp,32
    80003f90:	8082                	ret

0000000080003f92 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f92:	0001d797          	auipc	a5,0x1d
    80003f96:	c2a7a783          	lw	a5,-982(a5) # 80020bbc <log+0x2c>
    80003f9a:	0af05d63          	blez	a5,80004054 <install_trans+0xc2>
{
    80003f9e:	7139                	addi	sp,sp,-64
    80003fa0:	fc06                	sd	ra,56(sp)
    80003fa2:	f822                	sd	s0,48(sp)
    80003fa4:	f426                	sd	s1,40(sp)
    80003fa6:	f04a                	sd	s2,32(sp)
    80003fa8:	ec4e                	sd	s3,24(sp)
    80003faa:	e852                	sd	s4,16(sp)
    80003fac:	e456                	sd	s5,8(sp)
    80003fae:	e05a                	sd	s6,0(sp)
    80003fb0:	0080                	addi	s0,sp,64
    80003fb2:	8b2a                	mv	s6,a0
    80003fb4:	0001da97          	auipc	s5,0x1d
    80003fb8:	c0ca8a93          	addi	s5,s5,-1012 # 80020bc0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fbc:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fbe:	0001d997          	auipc	s3,0x1d
    80003fc2:	bd298993          	addi	s3,s3,-1070 # 80020b90 <log>
    80003fc6:	a00d                	j	80003fe8 <install_trans+0x56>
    brelse(lbuf);
    80003fc8:	854a                	mv	a0,s2
    80003fca:	fffff097          	auipc	ra,0xfffff
    80003fce:	07e080e7          	jalr	126(ra) # 80003048 <brelse>
    brelse(dbuf);
    80003fd2:	8526                	mv	a0,s1
    80003fd4:	fffff097          	auipc	ra,0xfffff
    80003fd8:	074080e7          	jalr	116(ra) # 80003048 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fdc:	2a05                	addiw	s4,s4,1
    80003fde:	0a91                	addi	s5,s5,4
    80003fe0:	02c9a783          	lw	a5,44(s3)
    80003fe4:	04fa5e63          	bge	s4,a5,80004040 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fe8:	0189a583          	lw	a1,24(s3)
    80003fec:	014585bb          	addw	a1,a1,s4
    80003ff0:	2585                	addiw	a1,a1,1
    80003ff2:	0289a503          	lw	a0,40(s3)
    80003ff6:	fffff097          	auipc	ra,0xfffff
    80003ffa:	f22080e7          	jalr	-222(ra) # 80002f18 <bread>
    80003ffe:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004000:	000aa583          	lw	a1,0(s5)
    80004004:	0289a503          	lw	a0,40(s3)
    80004008:	fffff097          	auipc	ra,0xfffff
    8000400c:	f10080e7          	jalr	-240(ra) # 80002f18 <bread>
    80004010:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004012:	40000613          	li	a2,1024
    80004016:	05890593          	addi	a1,s2,88
    8000401a:	05850513          	addi	a0,a0,88
    8000401e:	ffffd097          	auipc	ra,0xffffd
    80004022:	d10080e7          	jalr	-752(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    80004026:	8526                	mv	a0,s1
    80004028:	fffff097          	auipc	ra,0xfffff
    8000402c:	fe2080e7          	jalr	-30(ra) # 8000300a <bwrite>
    if(recovering == 0)
    80004030:	f80b1ce3          	bnez	s6,80003fc8 <install_trans+0x36>
      bunpin(dbuf);
    80004034:	8526                	mv	a0,s1
    80004036:	fffff097          	auipc	ra,0xfffff
    8000403a:	0ec080e7          	jalr	236(ra) # 80003122 <bunpin>
    8000403e:	b769                	j	80003fc8 <install_trans+0x36>
}
    80004040:	70e2                	ld	ra,56(sp)
    80004042:	7442                	ld	s0,48(sp)
    80004044:	74a2                	ld	s1,40(sp)
    80004046:	7902                	ld	s2,32(sp)
    80004048:	69e2                	ld	s3,24(sp)
    8000404a:	6a42                	ld	s4,16(sp)
    8000404c:	6aa2                	ld	s5,8(sp)
    8000404e:	6b02                	ld	s6,0(sp)
    80004050:	6121                	addi	sp,sp,64
    80004052:	8082                	ret
    80004054:	8082                	ret

0000000080004056 <initlog>:
{
    80004056:	7179                	addi	sp,sp,-48
    80004058:	f406                	sd	ra,40(sp)
    8000405a:	f022                	sd	s0,32(sp)
    8000405c:	ec26                	sd	s1,24(sp)
    8000405e:	e84a                	sd	s2,16(sp)
    80004060:	e44e                	sd	s3,8(sp)
    80004062:	1800                	addi	s0,sp,48
    80004064:	892a                	mv	s2,a0
    80004066:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004068:	0001d497          	auipc	s1,0x1d
    8000406c:	b2848493          	addi	s1,s1,-1240 # 80020b90 <log>
    80004070:	00004597          	auipc	a1,0x4
    80004074:	62058593          	addi	a1,a1,1568 # 80008690 <syscalls+0x200>
    80004078:	8526                	mv	a0,s1
    8000407a:	ffffd097          	auipc	ra,0xffffd
    8000407e:	acc080e7          	jalr	-1332(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80004082:	0149a583          	lw	a1,20(s3)
    80004086:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004088:	0109a783          	lw	a5,16(s3)
    8000408c:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000408e:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004092:	854a                	mv	a0,s2
    80004094:	fffff097          	auipc	ra,0xfffff
    80004098:	e84080e7          	jalr	-380(ra) # 80002f18 <bread>
  log.lh.n = lh->n;
    8000409c:	4d34                	lw	a3,88(a0)
    8000409e:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800040a0:	02d05663          	blez	a3,800040cc <initlog+0x76>
    800040a4:	05c50793          	addi	a5,a0,92
    800040a8:	0001d717          	auipc	a4,0x1d
    800040ac:	b1870713          	addi	a4,a4,-1256 # 80020bc0 <log+0x30>
    800040b0:	36fd                	addiw	a3,a3,-1
    800040b2:	02069613          	slli	a2,a3,0x20
    800040b6:	01e65693          	srli	a3,a2,0x1e
    800040ba:	06050613          	addi	a2,a0,96
    800040be:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800040c0:	4390                	lw	a2,0(a5)
    800040c2:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800040c4:	0791                	addi	a5,a5,4
    800040c6:	0711                	addi	a4,a4,4
    800040c8:	fed79ce3          	bne	a5,a3,800040c0 <initlog+0x6a>
  brelse(buf);
    800040cc:	fffff097          	auipc	ra,0xfffff
    800040d0:	f7c080e7          	jalr	-132(ra) # 80003048 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800040d4:	4505                	li	a0,1
    800040d6:	00000097          	auipc	ra,0x0
    800040da:	ebc080e7          	jalr	-324(ra) # 80003f92 <install_trans>
  log.lh.n = 0;
    800040de:	0001d797          	auipc	a5,0x1d
    800040e2:	ac07af23          	sw	zero,-1314(a5) # 80020bbc <log+0x2c>
  write_head(); // clear the log
    800040e6:	00000097          	auipc	ra,0x0
    800040ea:	e30080e7          	jalr	-464(ra) # 80003f16 <write_head>
}
    800040ee:	70a2                	ld	ra,40(sp)
    800040f0:	7402                	ld	s0,32(sp)
    800040f2:	64e2                	ld	s1,24(sp)
    800040f4:	6942                	ld	s2,16(sp)
    800040f6:	69a2                	ld	s3,8(sp)
    800040f8:	6145                	addi	sp,sp,48
    800040fa:	8082                	ret

00000000800040fc <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800040fc:	1101                	addi	sp,sp,-32
    800040fe:	ec06                	sd	ra,24(sp)
    80004100:	e822                	sd	s0,16(sp)
    80004102:	e426                	sd	s1,8(sp)
    80004104:	e04a                	sd	s2,0(sp)
    80004106:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004108:	0001d517          	auipc	a0,0x1d
    8000410c:	a8850513          	addi	a0,a0,-1400 # 80020b90 <log>
    80004110:	ffffd097          	auipc	ra,0xffffd
    80004114:	ac6080e7          	jalr	-1338(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    80004118:	0001d497          	auipc	s1,0x1d
    8000411c:	a7848493          	addi	s1,s1,-1416 # 80020b90 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004120:	4979                	li	s2,30
    80004122:	a039                	j	80004130 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004124:	85a6                	mv	a1,s1
    80004126:	8526                	mv	a0,s1
    80004128:	ffffe097          	auipc	ra,0xffffe
    8000412c:	f2c080e7          	jalr	-212(ra) # 80002054 <sleep>
    if(log.committing){
    80004130:	50dc                	lw	a5,36(s1)
    80004132:	fbed                	bnez	a5,80004124 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004134:	5098                	lw	a4,32(s1)
    80004136:	2705                	addiw	a4,a4,1
    80004138:	0007069b          	sext.w	a3,a4
    8000413c:	0027179b          	slliw	a5,a4,0x2
    80004140:	9fb9                	addw	a5,a5,a4
    80004142:	0017979b          	slliw	a5,a5,0x1
    80004146:	54d8                	lw	a4,44(s1)
    80004148:	9fb9                	addw	a5,a5,a4
    8000414a:	00f95963          	bge	s2,a5,8000415c <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000414e:	85a6                	mv	a1,s1
    80004150:	8526                	mv	a0,s1
    80004152:	ffffe097          	auipc	ra,0xffffe
    80004156:	f02080e7          	jalr	-254(ra) # 80002054 <sleep>
    8000415a:	bfd9                	j	80004130 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000415c:	0001d517          	auipc	a0,0x1d
    80004160:	a3450513          	addi	a0,a0,-1484 # 80020b90 <log>
    80004164:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004166:	ffffd097          	auipc	ra,0xffffd
    8000416a:	b24080e7          	jalr	-1244(ra) # 80000c8a <release>
      break;
    }
  }
}
    8000416e:	60e2                	ld	ra,24(sp)
    80004170:	6442                	ld	s0,16(sp)
    80004172:	64a2                	ld	s1,8(sp)
    80004174:	6902                	ld	s2,0(sp)
    80004176:	6105                	addi	sp,sp,32
    80004178:	8082                	ret

000000008000417a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000417a:	7139                	addi	sp,sp,-64
    8000417c:	fc06                	sd	ra,56(sp)
    8000417e:	f822                	sd	s0,48(sp)
    80004180:	f426                	sd	s1,40(sp)
    80004182:	f04a                	sd	s2,32(sp)
    80004184:	ec4e                	sd	s3,24(sp)
    80004186:	e852                	sd	s4,16(sp)
    80004188:	e456                	sd	s5,8(sp)
    8000418a:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000418c:	0001d497          	auipc	s1,0x1d
    80004190:	a0448493          	addi	s1,s1,-1532 # 80020b90 <log>
    80004194:	8526                	mv	a0,s1
    80004196:	ffffd097          	auipc	ra,0xffffd
    8000419a:	a40080e7          	jalr	-1472(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    8000419e:	509c                	lw	a5,32(s1)
    800041a0:	37fd                	addiw	a5,a5,-1
    800041a2:	0007891b          	sext.w	s2,a5
    800041a6:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800041a8:	50dc                	lw	a5,36(s1)
    800041aa:	e7b9                	bnez	a5,800041f8 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800041ac:	04091e63          	bnez	s2,80004208 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800041b0:	0001d497          	auipc	s1,0x1d
    800041b4:	9e048493          	addi	s1,s1,-1568 # 80020b90 <log>
    800041b8:	4785                	li	a5,1
    800041ba:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800041bc:	8526                	mv	a0,s1
    800041be:	ffffd097          	auipc	ra,0xffffd
    800041c2:	acc080e7          	jalr	-1332(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800041c6:	54dc                	lw	a5,44(s1)
    800041c8:	06f04763          	bgtz	a5,80004236 <end_op+0xbc>
    acquire(&log.lock);
    800041cc:	0001d497          	auipc	s1,0x1d
    800041d0:	9c448493          	addi	s1,s1,-1596 # 80020b90 <log>
    800041d4:	8526                	mv	a0,s1
    800041d6:	ffffd097          	auipc	ra,0xffffd
    800041da:	a00080e7          	jalr	-1536(ra) # 80000bd6 <acquire>
    log.committing = 0;
    800041de:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800041e2:	8526                	mv	a0,s1
    800041e4:	ffffe097          	auipc	ra,0xffffe
    800041e8:	ed4080e7          	jalr	-300(ra) # 800020b8 <wakeup>
    release(&log.lock);
    800041ec:	8526                	mv	a0,s1
    800041ee:	ffffd097          	auipc	ra,0xffffd
    800041f2:	a9c080e7          	jalr	-1380(ra) # 80000c8a <release>
}
    800041f6:	a03d                	j	80004224 <end_op+0xaa>
    panic("log.committing");
    800041f8:	00004517          	auipc	a0,0x4
    800041fc:	4a050513          	addi	a0,a0,1184 # 80008698 <syscalls+0x208>
    80004200:	ffffc097          	auipc	ra,0xffffc
    80004204:	340080e7          	jalr	832(ra) # 80000540 <panic>
    wakeup(&log);
    80004208:	0001d497          	auipc	s1,0x1d
    8000420c:	98848493          	addi	s1,s1,-1656 # 80020b90 <log>
    80004210:	8526                	mv	a0,s1
    80004212:	ffffe097          	auipc	ra,0xffffe
    80004216:	ea6080e7          	jalr	-346(ra) # 800020b8 <wakeup>
  release(&log.lock);
    8000421a:	8526                	mv	a0,s1
    8000421c:	ffffd097          	auipc	ra,0xffffd
    80004220:	a6e080e7          	jalr	-1426(ra) # 80000c8a <release>
}
    80004224:	70e2                	ld	ra,56(sp)
    80004226:	7442                	ld	s0,48(sp)
    80004228:	74a2                	ld	s1,40(sp)
    8000422a:	7902                	ld	s2,32(sp)
    8000422c:	69e2                	ld	s3,24(sp)
    8000422e:	6a42                	ld	s4,16(sp)
    80004230:	6aa2                	ld	s5,8(sp)
    80004232:	6121                	addi	sp,sp,64
    80004234:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004236:	0001da97          	auipc	s5,0x1d
    8000423a:	98aa8a93          	addi	s5,s5,-1654 # 80020bc0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000423e:	0001da17          	auipc	s4,0x1d
    80004242:	952a0a13          	addi	s4,s4,-1710 # 80020b90 <log>
    80004246:	018a2583          	lw	a1,24(s4)
    8000424a:	012585bb          	addw	a1,a1,s2
    8000424e:	2585                	addiw	a1,a1,1
    80004250:	028a2503          	lw	a0,40(s4)
    80004254:	fffff097          	auipc	ra,0xfffff
    80004258:	cc4080e7          	jalr	-828(ra) # 80002f18 <bread>
    8000425c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000425e:	000aa583          	lw	a1,0(s5)
    80004262:	028a2503          	lw	a0,40(s4)
    80004266:	fffff097          	auipc	ra,0xfffff
    8000426a:	cb2080e7          	jalr	-846(ra) # 80002f18 <bread>
    8000426e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004270:	40000613          	li	a2,1024
    80004274:	05850593          	addi	a1,a0,88
    80004278:	05848513          	addi	a0,s1,88
    8000427c:	ffffd097          	auipc	ra,0xffffd
    80004280:	ab2080e7          	jalr	-1358(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    80004284:	8526                	mv	a0,s1
    80004286:	fffff097          	auipc	ra,0xfffff
    8000428a:	d84080e7          	jalr	-636(ra) # 8000300a <bwrite>
    brelse(from);
    8000428e:	854e                	mv	a0,s3
    80004290:	fffff097          	auipc	ra,0xfffff
    80004294:	db8080e7          	jalr	-584(ra) # 80003048 <brelse>
    brelse(to);
    80004298:	8526                	mv	a0,s1
    8000429a:	fffff097          	auipc	ra,0xfffff
    8000429e:	dae080e7          	jalr	-594(ra) # 80003048 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042a2:	2905                	addiw	s2,s2,1
    800042a4:	0a91                	addi	s5,s5,4
    800042a6:	02ca2783          	lw	a5,44(s4)
    800042aa:	f8f94ee3          	blt	s2,a5,80004246 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800042ae:	00000097          	auipc	ra,0x0
    800042b2:	c68080e7          	jalr	-920(ra) # 80003f16 <write_head>
    install_trans(0); // Now install writes to home locations
    800042b6:	4501                	li	a0,0
    800042b8:	00000097          	auipc	ra,0x0
    800042bc:	cda080e7          	jalr	-806(ra) # 80003f92 <install_trans>
    log.lh.n = 0;
    800042c0:	0001d797          	auipc	a5,0x1d
    800042c4:	8e07ae23          	sw	zero,-1796(a5) # 80020bbc <log+0x2c>
    write_head();    // Erase the transaction from the log
    800042c8:	00000097          	auipc	ra,0x0
    800042cc:	c4e080e7          	jalr	-946(ra) # 80003f16 <write_head>
    800042d0:	bdf5                	j	800041cc <end_op+0x52>

00000000800042d2 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800042d2:	1101                	addi	sp,sp,-32
    800042d4:	ec06                	sd	ra,24(sp)
    800042d6:	e822                	sd	s0,16(sp)
    800042d8:	e426                	sd	s1,8(sp)
    800042da:	e04a                	sd	s2,0(sp)
    800042dc:	1000                	addi	s0,sp,32
    800042de:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800042e0:	0001d917          	auipc	s2,0x1d
    800042e4:	8b090913          	addi	s2,s2,-1872 # 80020b90 <log>
    800042e8:	854a                	mv	a0,s2
    800042ea:	ffffd097          	auipc	ra,0xffffd
    800042ee:	8ec080e7          	jalr	-1812(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800042f2:	02c92603          	lw	a2,44(s2)
    800042f6:	47f5                	li	a5,29
    800042f8:	06c7c563          	blt	a5,a2,80004362 <log_write+0x90>
    800042fc:	0001d797          	auipc	a5,0x1d
    80004300:	8b07a783          	lw	a5,-1872(a5) # 80020bac <log+0x1c>
    80004304:	37fd                	addiw	a5,a5,-1
    80004306:	04f65e63          	bge	a2,a5,80004362 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000430a:	0001d797          	auipc	a5,0x1d
    8000430e:	8a67a783          	lw	a5,-1882(a5) # 80020bb0 <log+0x20>
    80004312:	06f05063          	blez	a5,80004372 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004316:	4781                	li	a5,0
    80004318:	06c05563          	blez	a2,80004382 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000431c:	44cc                	lw	a1,12(s1)
    8000431e:	0001d717          	auipc	a4,0x1d
    80004322:	8a270713          	addi	a4,a4,-1886 # 80020bc0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004326:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004328:	4314                	lw	a3,0(a4)
    8000432a:	04b68c63          	beq	a3,a1,80004382 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000432e:	2785                	addiw	a5,a5,1
    80004330:	0711                	addi	a4,a4,4
    80004332:	fef61be3          	bne	a2,a5,80004328 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004336:	0621                	addi	a2,a2,8
    80004338:	060a                	slli	a2,a2,0x2
    8000433a:	0001d797          	auipc	a5,0x1d
    8000433e:	85678793          	addi	a5,a5,-1962 # 80020b90 <log>
    80004342:	97b2                	add	a5,a5,a2
    80004344:	44d8                	lw	a4,12(s1)
    80004346:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004348:	8526                	mv	a0,s1
    8000434a:	fffff097          	auipc	ra,0xfffff
    8000434e:	d9c080e7          	jalr	-612(ra) # 800030e6 <bpin>
    log.lh.n++;
    80004352:	0001d717          	auipc	a4,0x1d
    80004356:	83e70713          	addi	a4,a4,-1986 # 80020b90 <log>
    8000435a:	575c                	lw	a5,44(a4)
    8000435c:	2785                	addiw	a5,a5,1
    8000435e:	d75c                	sw	a5,44(a4)
    80004360:	a82d                	j	8000439a <log_write+0xc8>
    panic("too big a transaction");
    80004362:	00004517          	auipc	a0,0x4
    80004366:	34650513          	addi	a0,a0,838 # 800086a8 <syscalls+0x218>
    8000436a:	ffffc097          	auipc	ra,0xffffc
    8000436e:	1d6080e7          	jalr	470(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    80004372:	00004517          	auipc	a0,0x4
    80004376:	34e50513          	addi	a0,a0,846 # 800086c0 <syscalls+0x230>
    8000437a:	ffffc097          	auipc	ra,0xffffc
    8000437e:	1c6080e7          	jalr	454(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    80004382:	00878693          	addi	a3,a5,8
    80004386:	068a                	slli	a3,a3,0x2
    80004388:	0001d717          	auipc	a4,0x1d
    8000438c:	80870713          	addi	a4,a4,-2040 # 80020b90 <log>
    80004390:	9736                	add	a4,a4,a3
    80004392:	44d4                	lw	a3,12(s1)
    80004394:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004396:	faf609e3          	beq	a2,a5,80004348 <log_write+0x76>
  }
  release(&log.lock);
    8000439a:	0001c517          	auipc	a0,0x1c
    8000439e:	7f650513          	addi	a0,a0,2038 # 80020b90 <log>
    800043a2:	ffffd097          	auipc	ra,0xffffd
    800043a6:	8e8080e7          	jalr	-1816(ra) # 80000c8a <release>
}
    800043aa:	60e2                	ld	ra,24(sp)
    800043ac:	6442                	ld	s0,16(sp)
    800043ae:	64a2                	ld	s1,8(sp)
    800043b0:	6902                	ld	s2,0(sp)
    800043b2:	6105                	addi	sp,sp,32
    800043b4:	8082                	ret

00000000800043b6 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800043b6:	1101                	addi	sp,sp,-32
    800043b8:	ec06                	sd	ra,24(sp)
    800043ba:	e822                	sd	s0,16(sp)
    800043bc:	e426                	sd	s1,8(sp)
    800043be:	e04a                	sd	s2,0(sp)
    800043c0:	1000                	addi	s0,sp,32
    800043c2:	84aa                	mv	s1,a0
    800043c4:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800043c6:	00004597          	auipc	a1,0x4
    800043ca:	31a58593          	addi	a1,a1,794 # 800086e0 <syscalls+0x250>
    800043ce:	0521                	addi	a0,a0,8
    800043d0:	ffffc097          	auipc	ra,0xffffc
    800043d4:	776080e7          	jalr	1910(ra) # 80000b46 <initlock>
  lk->name = name;
    800043d8:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800043dc:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043e0:	0204a423          	sw	zero,40(s1)
}
    800043e4:	60e2                	ld	ra,24(sp)
    800043e6:	6442                	ld	s0,16(sp)
    800043e8:	64a2                	ld	s1,8(sp)
    800043ea:	6902                	ld	s2,0(sp)
    800043ec:	6105                	addi	sp,sp,32
    800043ee:	8082                	ret

00000000800043f0 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800043f0:	1101                	addi	sp,sp,-32
    800043f2:	ec06                	sd	ra,24(sp)
    800043f4:	e822                	sd	s0,16(sp)
    800043f6:	e426                	sd	s1,8(sp)
    800043f8:	e04a                	sd	s2,0(sp)
    800043fa:	1000                	addi	s0,sp,32
    800043fc:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043fe:	00850913          	addi	s2,a0,8
    80004402:	854a                	mv	a0,s2
    80004404:	ffffc097          	auipc	ra,0xffffc
    80004408:	7d2080e7          	jalr	2002(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    8000440c:	409c                	lw	a5,0(s1)
    8000440e:	cb89                	beqz	a5,80004420 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004410:	85ca                	mv	a1,s2
    80004412:	8526                	mv	a0,s1
    80004414:	ffffe097          	auipc	ra,0xffffe
    80004418:	c40080e7          	jalr	-960(ra) # 80002054 <sleep>
  while (lk->locked) {
    8000441c:	409c                	lw	a5,0(s1)
    8000441e:	fbed                	bnez	a5,80004410 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004420:	4785                	li	a5,1
    80004422:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004424:	ffffd097          	auipc	ra,0xffffd
    80004428:	588080e7          	jalr	1416(ra) # 800019ac <myproc>
    8000442c:	591c                	lw	a5,48(a0)
    8000442e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004430:	854a                	mv	a0,s2
    80004432:	ffffd097          	auipc	ra,0xffffd
    80004436:	858080e7          	jalr	-1960(ra) # 80000c8a <release>
}
    8000443a:	60e2                	ld	ra,24(sp)
    8000443c:	6442                	ld	s0,16(sp)
    8000443e:	64a2                	ld	s1,8(sp)
    80004440:	6902                	ld	s2,0(sp)
    80004442:	6105                	addi	sp,sp,32
    80004444:	8082                	ret

0000000080004446 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004446:	1101                	addi	sp,sp,-32
    80004448:	ec06                	sd	ra,24(sp)
    8000444a:	e822                	sd	s0,16(sp)
    8000444c:	e426                	sd	s1,8(sp)
    8000444e:	e04a                	sd	s2,0(sp)
    80004450:	1000                	addi	s0,sp,32
    80004452:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004454:	00850913          	addi	s2,a0,8
    80004458:	854a                	mv	a0,s2
    8000445a:	ffffc097          	auipc	ra,0xffffc
    8000445e:	77c080e7          	jalr	1916(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    80004462:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004466:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000446a:	8526                	mv	a0,s1
    8000446c:	ffffe097          	auipc	ra,0xffffe
    80004470:	c4c080e7          	jalr	-948(ra) # 800020b8 <wakeup>
  release(&lk->lk);
    80004474:	854a                	mv	a0,s2
    80004476:	ffffd097          	auipc	ra,0xffffd
    8000447a:	814080e7          	jalr	-2028(ra) # 80000c8a <release>
}
    8000447e:	60e2                	ld	ra,24(sp)
    80004480:	6442                	ld	s0,16(sp)
    80004482:	64a2                	ld	s1,8(sp)
    80004484:	6902                	ld	s2,0(sp)
    80004486:	6105                	addi	sp,sp,32
    80004488:	8082                	ret

000000008000448a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000448a:	7179                	addi	sp,sp,-48
    8000448c:	f406                	sd	ra,40(sp)
    8000448e:	f022                	sd	s0,32(sp)
    80004490:	ec26                	sd	s1,24(sp)
    80004492:	e84a                	sd	s2,16(sp)
    80004494:	e44e                	sd	s3,8(sp)
    80004496:	1800                	addi	s0,sp,48
    80004498:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000449a:	00850913          	addi	s2,a0,8
    8000449e:	854a                	mv	a0,s2
    800044a0:	ffffc097          	auipc	ra,0xffffc
    800044a4:	736080e7          	jalr	1846(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800044a8:	409c                	lw	a5,0(s1)
    800044aa:	ef99                	bnez	a5,800044c8 <holdingsleep+0x3e>
    800044ac:	4481                	li	s1,0
  release(&lk->lk);
    800044ae:	854a                	mv	a0,s2
    800044b0:	ffffc097          	auipc	ra,0xffffc
    800044b4:	7da080e7          	jalr	2010(ra) # 80000c8a <release>
  return r;
}
    800044b8:	8526                	mv	a0,s1
    800044ba:	70a2                	ld	ra,40(sp)
    800044bc:	7402                	ld	s0,32(sp)
    800044be:	64e2                	ld	s1,24(sp)
    800044c0:	6942                	ld	s2,16(sp)
    800044c2:	69a2                	ld	s3,8(sp)
    800044c4:	6145                	addi	sp,sp,48
    800044c6:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800044c8:	0284a983          	lw	s3,40(s1)
    800044cc:	ffffd097          	auipc	ra,0xffffd
    800044d0:	4e0080e7          	jalr	1248(ra) # 800019ac <myproc>
    800044d4:	5904                	lw	s1,48(a0)
    800044d6:	413484b3          	sub	s1,s1,s3
    800044da:	0014b493          	seqz	s1,s1
    800044de:	bfc1                	j	800044ae <holdingsleep+0x24>

00000000800044e0 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800044e0:	1141                	addi	sp,sp,-16
    800044e2:	e406                	sd	ra,8(sp)
    800044e4:	e022                	sd	s0,0(sp)
    800044e6:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800044e8:	00004597          	auipc	a1,0x4
    800044ec:	20858593          	addi	a1,a1,520 # 800086f0 <syscalls+0x260>
    800044f0:	0001c517          	auipc	a0,0x1c
    800044f4:	7e850513          	addi	a0,a0,2024 # 80020cd8 <ftable>
    800044f8:	ffffc097          	auipc	ra,0xffffc
    800044fc:	64e080e7          	jalr	1614(ra) # 80000b46 <initlock>
}
    80004500:	60a2                	ld	ra,8(sp)
    80004502:	6402                	ld	s0,0(sp)
    80004504:	0141                	addi	sp,sp,16
    80004506:	8082                	ret

0000000080004508 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004508:	1101                	addi	sp,sp,-32
    8000450a:	ec06                	sd	ra,24(sp)
    8000450c:	e822                	sd	s0,16(sp)
    8000450e:	e426                	sd	s1,8(sp)
    80004510:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004512:	0001c517          	auipc	a0,0x1c
    80004516:	7c650513          	addi	a0,a0,1990 # 80020cd8 <ftable>
    8000451a:	ffffc097          	auipc	ra,0xffffc
    8000451e:	6bc080e7          	jalr	1724(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004522:	0001c497          	auipc	s1,0x1c
    80004526:	7ce48493          	addi	s1,s1,1998 # 80020cf0 <ftable+0x18>
    8000452a:	0001d717          	auipc	a4,0x1d
    8000452e:	76670713          	addi	a4,a4,1894 # 80021c90 <disk>
    if(f->ref == 0){
    80004532:	40dc                	lw	a5,4(s1)
    80004534:	cf99                	beqz	a5,80004552 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004536:	02848493          	addi	s1,s1,40
    8000453a:	fee49ce3          	bne	s1,a4,80004532 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000453e:	0001c517          	auipc	a0,0x1c
    80004542:	79a50513          	addi	a0,a0,1946 # 80020cd8 <ftable>
    80004546:	ffffc097          	auipc	ra,0xffffc
    8000454a:	744080e7          	jalr	1860(ra) # 80000c8a <release>
  return 0;
    8000454e:	4481                	li	s1,0
    80004550:	a819                	j	80004566 <filealloc+0x5e>
      f->ref = 1;
    80004552:	4785                	li	a5,1
    80004554:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004556:	0001c517          	auipc	a0,0x1c
    8000455a:	78250513          	addi	a0,a0,1922 # 80020cd8 <ftable>
    8000455e:	ffffc097          	auipc	ra,0xffffc
    80004562:	72c080e7          	jalr	1836(ra) # 80000c8a <release>
}
    80004566:	8526                	mv	a0,s1
    80004568:	60e2                	ld	ra,24(sp)
    8000456a:	6442                	ld	s0,16(sp)
    8000456c:	64a2                	ld	s1,8(sp)
    8000456e:	6105                	addi	sp,sp,32
    80004570:	8082                	ret

0000000080004572 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004572:	1101                	addi	sp,sp,-32
    80004574:	ec06                	sd	ra,24(sp)
    80004576:	e822                	sd	s0,16(sp)
    80004578:	e426                	sd	s1,8(sp)
    8000457a:	1000                	addi	s0,sp,32
    8000457c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000457e:	0001c517          	auipc	a0,0x1c
    80004582:	75a50513          	addi	a0,a0,1882 # 80020cd8 <ftable>
    80004586:	ffffc097          	auipc	ra,0xffffc
    8000458a:	650080e7          	jalr	1616(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    8000458e:	40dc                	lw	a5,4(s1)
    80004590:	02f05263          	blez	a5,800045b4 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004594:	2785                	addiw	a5,a5,1
    80004596:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004598:	0001c517          	auipc	a0,0x1c
    8000459c:	74050513          	addi	a0,a0,1856 # 80020cd8 <ftable>
    800045a0:	ffffc097          	auipc	ra,0xffffc
    800045a4:	6ea080e7          	jalr	1770(ra) # 80000c8a <release>
  return f;
}
    800045a8:	8526                	mv	a0,s1
    800045aa:	60e2                	ld	ra,24(sp)
    800045ac:	6442                	ld	s0,16(sp)
    800045ae:	64a2                	ld	s1,8(sp)
    800045b0:	6105                	addi	sp,sp,32
    800045b2:	8082                	ret
    panic("filedup");
    800045b4:	00004517          	auipc	a0,0x4
    800045b8:	14450513          	addi	a0,a0,324 # 800086f8 <syscalls+0x268>
    800045bc:	ffffc097          	auipc	ra,0xffffc
    800045c0:	f84080e7          	jalr	-124(ra) # 80000540 <panic>

00000000800045c4 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800045c4:	7139                	addi	sp,sp,-64
    800045c6:	fc06                	sd	ra,56(sp)
    800045c8:	f822                	sd	s0,48(sp)
    800045ca:	f426                	sd	s1,40(sp)
    800045cc:	f04a                	sd	s2,32(sp)
    800045ce:	ec4e                	sd	s3,24(sp)
    800045d0:	e852                	sd	s4,16(sp)
    800045d2:	e456                	sd	s5,8(sp)
    800045d4:	0080                	addi	s0,sp,64
    800045d6:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800045d8:	0001c517          	auipc	a0,0x1c
    800045dc:	70050513          	addi	a0,a0,1792 # 80020cd8 <ftable>
    800045e0:	ffffc097          	auipc	ra,0xffffc
    800045e4:	5f6080e7          	jalr	1526(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    800045e8:	40dc                	lw	a5,4(s1)
    800045ea:	06f05163          	blez	a5,8000464c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800045ee:	37fd                	addiw	a5,a5,-1
    800045f0:	0007871b          	sext.w	a4,a5
    800045f4:	c0dc                	sw	a5,4(s1)
    800045f6:	06e04363          	bgtz	a4,8000465c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800045fa:	0004a903          	lw	s2,0(s1)
    800045fe:	0094ca83          	lbu	s5,9(s1)
    80004602:	0104ba03          	ld	s4,16(s1)
    80004606:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000460a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000460e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004612:	0001c517          	auipc	a0,0x1c
    80004616:	6c650513          	addi	a0,a0,1734 # 80020cd8 <ftable>
    8000461a:	ffffc097          	auipc	ra,0xffffc
    8000461e:	670080e7          	jalr	1648(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    80004622:	4785                	li	a5,1
    80004624:	04f90d63          	beq	s2,a5,8000467e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004628:	3979                	addiw	s2,s2,-2
    8000462a:	4785                	li	a5,1
    8000462c:	0527e063          	bltu	a5,s2,8000466c <fileclose+0xa8>
    begin_op();
    80004630:	00000097          	auipc	ra,0x0
    80004634:	acc080e7          	jalr	-1332(ra) # 800040fc <begin_op>
    iput(ff.ip);
    80004638:	854e                	mv	a0,s3
    8000463a:	fffff097          	auipc	ra,0xfffff
    8000463e:	2b0080e7          	jalr	688(ra) # 800038ea <iput>
    end_op();
    80004642:	00000097          	auipc	ra,0x0
    80004646:	b38080e7          	jalr	-1224(ra) # 8000417a <end_op>
    8000464a:	a00d                	j	8000466c <fileclose+0xa8>
    panic("fileclose");
    8000464c:	00004517          	auipc	a0,0x4
    80004650:	0b450513          	addi	a0,a0,180 # 80008700 <syscalls+0x270>
    80004654:	ffffc097          	auipc	ra,0xffffc
    80004658:	eec080e7          	jalr	-276(ra) # 80000540 <panic>
    release(&ftable.lock);
    8000465c:	0001c517          	auipc	a0,0x1c
    80004660:	67c50513          	addi	a0,a0,1660 # 80020cd8 <ftable>
    80004664:	ffffc097          	auipc	ra,0xffffc
    80004668:	626080e7          	jalr	1574(ra) # 80000c8a <release>
  }
}
    8000466c:	70e2                	ld	ra,56(sp)
    8000466e:	7442                	ld	s0,48(sp)
    80004670:	74a2                	ld	s1,40(sp)
    80004672:	7902                	ld	s2,32(sp)
    80004674:	69e2                	ld	s3,24(sp)
    80004676:	6a42                	ld	s4,16(sp)
    80004678:	6aa2                	ld	s5,8(sp)
    8000467a:	6121                	addi	sp,sp,64
    8000467c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000467e:	85d6                	mv	a1,s5
    80004680:	8552                	mv	a0,s4
    80004682:	00000097          	auipc	ra,0x0
    80004686:	34c080e7          	jalr	844(ra) # 800049ce <pipeclose>
    8000468a:	b7cd                	j	8000466c <fileclose+0xa8>

000000008000468c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000468c:	715d                	addi	sp,sp,-80
    8000468e:	e486                	sd	ra,72(sp)
    80004690:	e0a2                	sd	s0,64(sp)
    80004692:	fc26                	sd	s1,56(sp)
    80004694:	f84a                	sd	s2,48(sp)
    80004696:	f44e                	sd	s3,40(sp)
    80004698:	0880                	addi	s0,sp,80
    8000469a:	84aa                	mv	s1,a0
    8000469c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000469e:	ffffd097          	auipc	ra,0xffffd
    800046a2:	30e080e7          	jalr	782(ra) # 800019ac <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800046a6:	409c                	lw	a5,0(s1)
    800046a8:	37f9                	addiw	a5,a5,-2
    800046aa:	4705                	li	a4,1
    800046ac:	04f76763          	bltu	a4,a5,800046fa <filestat+0x6e>
    800046b0:	892a                	mv	s2,a0
    ilock(f->ip);
    800046b2:	6c88                	ld	a0,24(s1)
    800046b4:	fffff097          	auipc	ra,0xfffff
    800046b8:	07c080e7          	jalr	124(ra) # 80003730 <ilock>
    stati(f->ip, &st);
    800046bc:	fb840593          	addi	a1,s0,-72
    800046c0:	6c88                	ld	a0,24(s1)
    800046c2:	fffff097          	auipc	ra,0xfffff
    800046c6:	2f8080e7          	jalr	760(ra) # 800039ba <stati>
    iunlock(f->ip);
    800046ca:	6c88                	ld	a0,24(s1)
    800046cc:	fffff097          	auipc	ra,0xfffff
    800046d0:	126080e7          	jalr	294(ra) # 800037f2 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800046d4:	46e1                	li	a3,24
    800046d6:	fb840613          	addi	a2,s0,-72
    800046da:	85ce                	mv	a1,s3
    800046dc:	05093503          	ld	a0,80(s2)
    800046e0:	ffffd097          	auipc	ra,0xffffd
    800046e4:	f8c080e7          	jalr	-116(ra) # 8000166c <copyout>
    800046e8:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800046ec:	60a6                	ld	ra,72(sp)
    800046ee:	6406                	ld	s0,64(sp)
    800046f0:	74e2                	ld	s1,56(sp)
    800046f2:	7942                	ld	s2,48(sp)
    800046f4:	79a2                	ld	s3,40(sp)
    800046f6:	6161                	addi	sp,sp,80
    800046f8:	8082                	ret
  return -1;
    800046fa:	557d                	li	a0,-1
    800046fc:	bfc5                	j	800046ec <filestat+0x60>

00000000800046fe <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800046fe:	7179                	addi	sp,sp,-48
    80004700:	f406                	sd	ra,40(sp)
    80004702:	f022                	sd	s0,32(sp)
    80004704:	ec26                	sd	s1,24(sp)
    80004706:	e84a                	sd	s2,16(sp)
    80004708:	e44e                	sd	s3,8(sp)
    8000470a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000470c:	00854783          	lbu	a5,8(a0)
    80004710:	c3d5                	beqz	a5,800047b4 <fileread+0xb6>
    80004712:	84aa                	mv	s1,a0
    80004714:	89ae                	mv	s3,a1
    80004716:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004718:	411c                	lw	a5,0(a0)
    8000471a:	4705                	li	a4,1
    8000471c:	04e78963          	beq	a5,a4,8000476e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004720:	470d                	li	a4,3
    80004722:	04e78d63          	beq	a5,a4,8000477c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004726:	4709                	li	a4,2
    80004728:	06e79e63          	bne	a5,a4,800047a4 <fileread+0xa6>
    ilock(f->ip);
    8000472c:	6d08                	ld	a0,24(a0)
    8000472e:	fffff097          	auipc	ra,0xfffff
    80004732:	002080e7          	jalr	2(ra) # 80003730 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004736:	874a                	mv	a4,s2
    80004738:	5094                	lw	a3,32(s1)
    8000473a:	864e                	mv	a2,s3
    8000473c:	4585                	li	a1,1
    8000473e:	6c88                	ld	a0,24(s1)
    80004740:	fffff097          	auipc	ra,0xfffff
    80004744:	2a4080e7          	jalr	676(ra) # 800039e4 <readi>
    80004748:	892a                	mv	s2,a0
    8000474a:	00a05563          	blez	a0,80004754 <fileread+0x56>
      f->off += r;
    8000474e:	509c                	lw	a5,32(s1)
    80004750:	9fa9                	addw	a5,a5,a0
    80004752:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004754:	6c88                	ld	a0,24(s1)
    80004756:	fffff097          	auipc	ra,0xfffff
    8000475a:	09c080e7          	jalr	156(ra) # 800037f2 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000475e:	854a                	mv	a0,s2
    80004760:	70a2                	ld	ra,40(sp)
    80004762:	7402                	ld	s0,32(sp)
    80004764:	64e2                	ld	s1,24(sp)
    80004766:	6942                	ld	s2,16(sp)
    80004768:	69a2                	ld	s3,8(sp)
    8000476a:	6145                	addi	sp,sp,48
    8000476c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000476e:	6908                	ld	a0,16(a0)
    80004770:	00000097          	auipc	ra,0x0
    80004774:	3c6080e7          	jalr	966(ra) # 80004b36 <piperead>
    80004778:	892a                	mv	s2,a0
    8000477a:	b7d5                	j	8000475e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000477c:	02451783          	lh	a5,36(a0)
    80004780:	03079693          	slli	a3,a5,0x30
    80004784:	92c1                	srli	a3,a3,0x30
    80004786:	4725                	li	a4,9
    80004788:	02d76863          	bltu	a4,a3,800047b8 <fileread+0xba>
    8000478c:	0792                	slli	a5,a5,0x4
    8000478e:	0001c717          	auipc	a4,0x1c
    80004792:	4aa70713          	addi	a4,a4,1194 # 80020c38 <devsw>
    80004796:	97ba                	add	a5,a5,a4
    80004798:	639c                	ld	a5,0(a5)
    8000479a:	c38d                	beqz	a5,800047bc <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000479c:	4505                	li	a0,1
    8000479e:	9782                	jalr	a5
    800047a0:	892a                	mv	s2,a0
    800047a2:	bf75                	j	8000475e <fileread+0x60>
    panic("fileread");
    800047a4:	00004517          	auipc	a0,0x4
    800047a8:	f6c50513          	addi	a0,a0,-148 # 80008710 <syscalls+0x280>
    800047ac:	ffffc097          	auipc	ra,0xffffc
    800047b0:	d94080e7          	jalr	-620(ra) # 80000540 <panic>
    return -1;
    800047b4:	597d                	li	s2,-1
    800047b6:	b765                	j	8000475e <fileread+0x60>
      return -1;
    800047b8:	597d                	li	s2,-1
    800047ba:	b755                	j	8000475e <fileread+0x60>
    800047bc:	597d                	li	s2,-1
    800047be:	b745                	j	8000475e <fileread+0x60>

00000000800047c0 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800047c0:	715d                	addi	sp,sp,-80
    800047c2:	e486                	sd	ra,72(sp)
    800047c4:	e0a2                	sd	s0,64(sp)
    800047c6:	fc26                	sd	s1,56(sp)
    800047c8:	f84a                	sd	s2,48(sp)
    800047ca:	f44e                	sd	s3,40(sp)
    800047cc:	f052                	sd	s4,32(sp)
    800047ce:	ec56                	sd	s5,24(sp)
    800047d0:	e85a                	sd	s6,16(sp)
    800047d2:	e45e                	sd	s7,8(sp)
    800047d4:	e062                	sd	s8,0(sp)
    800047d6:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800047d8:	00954783          	lbu	a5,9(a0)
    800047dc:	10078663          	beqz	a5,800048e8 <filewrite+0x128>
    800047e0:	892a                	mv	s2,a0
    800047e2:	8b2e                	mv	s6,a1
    800047e4:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800047e6:	411c                	lw	a5,0(a0)
    800047e8:	4705                	li	a4,1
    800047ea:	02e78263          	beq	a5,a4,8000480e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047ee:	470d                	li	a4,3
    800047f0:	02e78663          	beq	a5,a4,8000481c <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800047f4:	4709                	li	a4,2
    800047f6:	0ee79163          	bne	a5,a4,800048d8 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800047fa:	0ac05d63          	blez	a2,800048b4 <filewrite+0xf4>
    int i = 0;
    800047fe:	4981                	li	s3,0
    80004800:	6b85                	lui	s7,0x1
    80004802:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004806:	6c05                	lui	s8,0x1
    80004808:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    8000480c:	a861                	j	800048a4 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000480e:	6908                	ld	a0,16(a0)
    80004810:	00000097          	auipc	ra,0x0
    80004814:	22e080e7          	jalr	558(ra) # 80004a3e <pipewrite>
    80004818:	8a2a                	mv	s4,a0
    8000481a:	a045                	j	800048ba <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000481c:	02451783          	lh	a5,36(a0)
    80004820:	03079693          	slli	a3,a5,0x30
    80004824:	92c1                	srli	a3,a3,0x30
    80004826:	4725                	li	a4,9
    80004828:	0cd76263          	bltu	a4,a3,800048ec <filewrite+0x12c>
    8000482c:	0792                	slli	a5,a5,0x4
    8000482e:	0001c717          	auipc	a4,0x1c
    80004832:	40a70713          	addi	a4,a4,1034 # 80020c38 <devsw>
    80004836:	97ba                	add	a5,a5,a4
    80004838:	679c                	ld	a5,8(a5)
    8000483a:	cbdd                	beqz	a5,800048f0 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000483c:	4505                	li	a0,1
    8000483e:	9782                	jalr	a5
    80004840:	8a2a                	mv	s4,a0
    80004842:	a8a5                	j	800048ba <filewrite+0xfa>
    80004844:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004848:	00000097          	auipc	ra,0x0
    8000484c:	8b4080e7          	jalr	-1868(ra) # 800040fc <begin_op>
      ilock(f->ip);
    80004850:	01893503          	ld	a0,24(s2)
    80004854:	fffff097          	auipc	ra,0xfffff
    80004858:	edc080e7          	jalr	-292(ra) # 80003730 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000485c:	8756                	mv	a4,s5
    8000485e:	02092683          	lw	a3,32(s2)
    80004862:	01698633          	add	a2,s3,s6
    80004866:	4585                	li	a1,1
    80004868:	01893503          	ld	a0,24(s2)
    8000486c:	fffff097          	auipc	ra,0xfffff
    80004870:	270080e7          	jalr	624(ra) # 80003adc <writei>
    80004874:	84aa                	mv	s1,a0
    80004876:	00a05763          	blez	a0,80004884 <filewrite+0xc4>
        f->off += r;
    8000487a:	02092783          	lw	a5,32(s2)
    8000487e:	9fa9                	addw	a5,a5,a0
    80004880:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004884:	01893503          	ld	a0,24(s2)
    80004888:	fffff097          	auipc	ra,0xfffff
    8000488c:	f6a080e7          	jalr	-150(ra) # 800037f2 <iunlock>
      end_op();
    80004890:	00000097          	auipc	ra,0x0
    80004894:	8ea080e7          	jalr	-1814(ra) # 8000417a <end_op>

      if(r != n1){
    80004898:	009a9f63          	bne	s5,s1,800048b6 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000489c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800048a0:	0149db63          	bge	s3,s4,800048b6 <filewrite+0xf6>
      int n1 = n - i;
    800048a4:	413a04bb          	subw	s1,s4,s3
    800048a8:	0004879b          	sext.w	a5,s1
    800048ac:	f8fbdce3          	bge	s7,a5,80004844 <filewrite+0x84>
    800048b0:	84e2                	mv	s1,s8
    800048b2:	bf49                	j	80004844 <filewrite+0x84>
    int i = 0;
    800048b4:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800048b6:	013a1f63          	bne	s4,s3,800048d4 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800048ba:	8552                	mv	a0,s4
    800048bc:	60a6                	ld	ra,72(sp)
    800048be:	6406                	ld	s0,64(sp)
    800048c0:	74e2                	ld	s1,56(sp)
    800048c2:	7942                	ld	s2,48(sp)
    800048c4:	79a2                	ld	s3,40(sp)
    800048c6:	7a02                	ld	s4,32(sp)
    800048c8:	6ae2                	ld	s5,24(sp)
    800048ca:	6b42                	ld	s6,16(sp)
    800048cc:	6ba2                	ld	s7,8(sp)
    800048ce:	6c02                	ld	s8,0(sp)
    800048d0:	6161                	addi	sp,sp,80
    800048d2:	8082                	ret
    ret = (i == n ? n : -1);
    800048d4:	5a7d                	li	s4,-1
    800048d6:	b7d5                	j	800048ba <filewrite+0xfa>
    panic("filewrite");
    800048d8:	00004517          	auipc	a0,0x4
    800048dc:	e4850513          	addi	a0,a0,-440 # 80008720 <syscalls+0x290>
    800048e0:	ffffc097          	auipc	ra,0xffffc
    800048e4:	c60080e7          	jalr	-928(ra) # 80000540 <panic>
    return -1;
    800048e8:	5a7d                	li	s4,-1
    800048ea:	bfc1                	j	800048ba <filewrite+0xfa>
      return -1;
    800048ec:	5a7d                	li	s4,-1
    800048ee:	b7f1                	j	800048ba <filewrite+0xfa>
    800048f0:	5a7d                	li	s4,-1
    800048f2:	b7e1                	j	800048ba <filewrite+0xfa>

00000000800048f4 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800048f4:	7179                	addi	sp,sp,-48
    800048f6:	f406                	sd	ra,40(sp)
    800048f8:	f022                	sd	s0,32(sp)
    800048fa:	ec26                	sd	s1,24(sp)
    800048fc:	e84a                	sd	s2,16(sp)
    800048fe:	e44e                	sd	s3,8(sp)
    80004900:	e052                	sd	s4,0(sp)
    80004902:	1800                	addi	s0,sp,48
    80004904:	84aa                	mv	s1,a0
    80004906:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004908:	0005b023          	sd	zero,0(a1)
    8000490c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004910:	00000097          	auipc	ra,0x0
    80004914:	bf8080e7          	jalr	-1032(ra) # 80004508 <filealloc>
    80004918:	e088                	sd	a0,0(s1)
    8000491a:	c551                	beqz	a0,800049a6 <pipealloc+0xb2>
    8000491c:	00000097          	auipc	ra,0x0
    80004920:	bec080e7          	jalr	-1044(ra) # 80004508 <filealloc>
    80004924:	00aa3023          	sd	a0,0(s4)
    80004928:	c92d                	beqz	a0,8000499a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000492a:	ffffc097          	auipc	ra,0xffffc
    8000492e:	1bc080e7          	jalr	444(ra) # 80000ae6 <kalloc>
    80004932:	892a                	mv	s2,a0
    80004934:	c125                	beqz	a0,80004994 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004936:	4985                	li	s3,1
    80004938:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000493c:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004940:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004944:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004948:	00004597          	auipc	a1,0x4
    8000494c:	de858593          	addi	a1,a1,-536 # 80008730 <syscalls+0x2a0>
    80004950:	ffffc097          	auipc	ra,0xffffc
    80004954:	1f6080e7          	jalr	502(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004958:	609c                	ld	a5,0(s1)
    8000495a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000495e:	609c                	ld	a5,0(s1)
    80004960:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004964:	609c                	ld	a5,0(s1)
    80004966:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000496a:	609c                	ld	a5,0(s1)
    8000496c:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004970:	000a3783          	ld	a5,0(s4)
    80004974:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004978:	000a3783          	ld	a5,0(s4)
    8000497c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004980:	000a3783          	ld	a5,0(s4)
    80004984:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004988:	000a3783          	ld	a5,0(s4)
    8000498c:	0127b823          	sd	s2,16(a5)
  return 0;
    80004990:	4501                	li	a0,0
    80004992:	a025                	j	800049ba <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004994:	6088                	ld	a0,0(s1)
    80004996:	e501                	bnez	a0,8000499e <pipealloc+0xaa>
    80004998:	a039                	j	800049a6 <pipealloc+0xb2>
    8000499a:	6088                	ld	a0,0(s1)
    8000499c:	c51d                	beqz	a0,800049ca <pipealloc+0xd6>
    fileclose(*f0);
    8000499e:	00000097          	auipc	ra,0x0
    800049a2:	c26080e7          	jalr	-986(ra) # 800045c4 <fileclose>
  if(*f1)
    800049a6:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800049aa:	557d                	li	a0,-1
  if(*f1)
    800049ac:	c799                	beqz	a5,800049ba <pipealloc+0xc6>
    fileclose(*f1);
    800049ae:	853e                	mv	a0,a5
    800049b0:	00000097          	auipc	ra,0x0
    800049b4:	c14080e7          	jalr	-1004(ra) # 800045c4 <fileclose>
  return -1;
    800049b8:	557d                	li	a0,-1
}
    800049ba:	70a2                	ld	ra,40(sp)
    800049bc:	7402                	ld	s0,32(sp)
    800049be:	64e2                	ld	s1,24(sp)
    800049c0:	6942                	ld	s2,16(sp)
    800049c2:	69a2                	ld	s3,8(sp)
    800049c4:	6a02                	ld	s4,0(sp)
    800049c6:	6145                	addi	sp,sp,48
    800049c8:	8082                	ret
  return -1;
    800049ca:	557d                	li	a0,-1
    800049cc:	b7fd                	j	800049ba <pipealloc+0xc6>

00000000800049ce <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800049ce:	1101                	addi	sp,sp,-32
    800049d0:	ec06                	sd	ra,24(sp)
    800049d2:	e822                	sd	s0,16(sp)
    800049d4:	e426                	sd	s1,8(sp)
    800049d6:	e04a                	sd	s2,0(sp)
    800049d8:	1000                	addi	s0,sp,32
    800049da:	84aa                	mv	s1,a0
    800049dc:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800049de:	ffffc097          	auipc	ra,0xffffc
    800049e2:	1f8080e7          	jalr	504(ra) # 80000bd6 <acquire>
  if(writable){
    800049e6:	02090d63          	beqz	s2,80004a20 <pipeclose+0x52>
    pi->writeopen = 0;
    800049ea:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800049ee:	21848513          	addi	a0,s1,536
    800049f2:	ffffd097          	auipc	ra,0xffffd
    800049f6:	6c6080e7          	jalr	1734(ra) # 800020b8 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800049fa:	2204b783          	ld	a5,544(s1)
    800049fe:	eb95                	bnez	a5,80004a32 <pipeclose+0x64>
    release(&pi->lock);
    80004a00:	8526                	mv	a0,s1
    80004a02:	ffffc097          	auipc	ra,0xffffc
    80004a06:	288080e7          	jalr	648(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004a0a:	8526                	mv	a0,s1
    80004a0c:	ffffc097          	auipc	ra,0xffffc
    80004a10:	fdc080e7          	jalr	-36(ra) # 800009e8 <kfree>
  } else
    release(&pi->lock);
}
    80004a14:	60e2                	ld	ra,24(sp)
    80004a16:	6442                	ld	s0,16(sp)
    80004a18:	64a2                	ld	s1,8(sp)
    80004a1a:	6902                	ld	s2,0(sp)
    80004a1c:	6105                	addi	sp,sp,32
    80004a1e:	8082                	ret
    pi->readopen = 0;
    80004a20:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a24:	21c48513          	addi	a0,s1,540
    80004a28:	ffffd097          	auipc	ra,0xffffd
    80004a2c:	690080e7          	jalr	1680(ra) # 800020b8 <wakeup>
    80004a30:	b7e9                	j	800049fa <pipeclose+0x2c>
    release(&pi->lock);
    80004a32:	8526                	mv	a0,s1
    80004a34:	ffffc097          	auipc	ra,0xffffc
    80004a38:	256080e7          	jalr	598(ra) # 80000c8a <release>
}
    80004a3c:	bfe1                	j	80004a14 <pipeclose+0x46>

0000000080004a3e <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a3e:	711d                	addi	sp,sp,-96
    80004a40:	ec86                	sd	ra,88(sp)
    80004a42:	e8a2                	sd	s0,80(sp)
    80004a44:	e4a6                	sd	s1,72(sp)
    80004a46:	e0ca                	sd	s2,64(sp)
    80004a48:	fc4e                	sd	s3,56(sp)
    80004a4a:	f852                	sd	s4,48(sp)
    80004a4c:	f456                	sd	s5,40(sp)
    80004a4e:	f05a                	sd	s6,32(sp)
    80004a50:	ec5e                	sd	s7,24(sp)
    80004a52:	e862                	sd	s8,16(sp)
    80004a54:	1080                	addi	s0,sp,96
    80004a56:	84aa                	mv	s1,a0
    80004a58:	8aae                	mv	s5,a1
    80004a5a:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004a5c:	ffffd097          	auipc	ra,0xffffd
    80004a60:	f50080e7          	jalr	-176(ra) # 800019ac <myproc>
    80004a64:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004a66:	8526                	mv	a0,s1
    80004a68:	ffffc097          	auipc	ra,0xffffc
    80004a6c:	16e080e7          	jalr	366(ra) # 80000bd6 <acquire>
  while(i < n){
    80004a70:	0b405663          	blez	s4,80004b1c <pipewrite+0xde>
  int i = 0;
    80004a74:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a76:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004a78:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a7c:	21c48b93          	addi	s7,s1,540
    80004a80:	a089                	j	80004ac2 <pipewrite+0x84>
      release(&pi->lock);
    80004a82:	8526                	mv	a0,s1
    80004a84:	ffffc097          	auipc	ra,0xffffc
    80004a88:	206080e7          	jalr	518(ra) # 80000c8a <release>
      return -1;
    80004a8c:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004a8e:	854a                	mv	a0,s2
    80004a90:	60e6                	ld	ra,88(sp)
    80004a92:	6446                	ld	s0,80(sp)
    80004a94:	64a6                	ld	s1,72(sp)
    80004a96:	6906                	ld	s2,64(sp)
    80004a98:	79e2                	ld	s3,56(sp)
    80004a9a:	7a42                	ld	s4,48(sp)
    80004a9c:	7aa2                	ld	s5,40(sp)
    80004a9e:	7b02                	ld	s6,32(sp)
    80004aa0:	6be2                	ld	s7,24(sp)
    80004aa2:	6c42                	ld	s8,16(sp)
    80004aa4:	6125                	addi	sp,sp,96
    80004aa6:	8082                	ret
      wakeup(&pi->nread);
    80004aa8:	8562                	mv	a0,s8
    80004aaa:	ffffd097          	auipc	ra,0xffffd
    80004aae:	60e080e7          	jalr	1550(ra) # 800020b8 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004ab2:	85a6                	mv	a1,s1
    80004ab4:	855e                	mv	a0,s7
    80004ab6:	ffffd097          	auipc	ra,0xffffd
    80004aba:	59e080e7          	jalr	1438(ra) # 80002054 <sleep>
  while(i < n){
    80004abe:	07495063          	bge	s2,s4,80004b1e <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004ac2:	2204a783          	lw	a5,544(s1)
    80004ac6:	dfd5                	beqz	a5,80004a82 <pipewrite+0x44>
    80004ac8:	854e                	mv	a0,s3
    80004aca:	ffffe097          	auipc	ra,0xffffe
    80004ace:	832080e7          	jalr	-1998(ra) # 800022fc <killed>
    80004ad2:	f945                	bnez	a0,80004a82 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004ad4:	2184a783          	lw	a5,536(s1)
    80004ad8:	21c4a703          	lw	a4,540(s1)
    80004adc:	2007879b          	addiw	a5,a5,512
    80004ae0:	fcf704e3          	beq	a4,a5,80004aa8 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ae4:	4685                	li	a3,1
    80004ae6:	01590633          	add	a2,s2,s5
    80004aea:	faf40593          	addi	a1,s0,-81
    80004aee:	0509b503          	ld	a0,80(s3)
    80004af2:	ffffd097          	auipc	ra,0xffffd
    80004af6:	c06080e7          	jalr	-1018(ra) # 800016f8 <copyin>
    80004afa:	03650263          	beq	a0,s6,80004b1e <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004afe:	21c4a783          	lw	a5,540(s1)
    80004b02:	0017871b          	addiw	a4,a5,1
    80004b06:	20e4ae23          	sw	a4,540(s1)
    80004b0a:	1ff7f793          	andi	a5,a5,511
    80004b0e:	97a6                	add	a5,a5,s1
    80004b10:	faf44703          	lbu	a4,-81(s0)
    80004b14:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b18:	2905                	addiw	s2,s2,1
    80004b1a:	b755                	j	80004abe <pipewrite+0x80>
  int i = 0;
    80004b1c:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004b1e:	21848513          	addi	a0,s1,536
    80004b22:	ffffd097          	auipc	ra,0xffffd
    80004b26:	596080e7          	jalr	1430(ra) # 800020b8 <wakeup>
  release(&pi->lock);
    80004b2a:	8526                	mv	a0,s1
    80004b2c:	ffffc097          	auipc	ra,0xffffc
    80004b30:	15e080e7          	jalr	350(ra) # 80000c8a <release>
  return i;
    80004b34:	bfa9                	j	80004a8e <pipewrite+0x50>

0000000080004b36 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b36:	715d                	addi	sp,sp,-80
    80004b38:	e486                	sd	ra,72(sp)
    80004b3a:	e0a2                	sd	s0,64(sp)
    80004b3c:	fc26                	sd	s1,56(sp)
    80004b3e:	f84a                	sd	s2,48(sp)
    80004b40:	f44e                	sd	s3,40(sp)
    80004b42:	f052                	sd	s4,32(sp)
    80004b44:	ec56                	sd	s5,24(sp)
    80004b46:	e85a                	sd	s6,16(sp)
    80004b48:	0880                	addi	s0,sp,80
    80004b4a:	84aa                	mv	s1,a0
    80004b4c:	892e                	mv	s2,a1
    80004b4e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004b50:	ffffd097          	auipc	ra,0xffffd
    80004b54:	e5c080e7          	jalr	-420(ra) # 800019ac <myproc>
    80004b58:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b5a:	8526                	mv	a0,s1
    80004b5c:	ffffc097          	auipc	ra,0xffffc
    80004b60:	07a080e7          	jalr	122(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b64:	2184a703          	lw	a4,536(s1)
    80004b68:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b6c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b70:	02f71763          	bne	a4,a5,80004b9e <piperead+0x68>
    80004b74:	2244a783          	lw	a5,548(s1)
    80004b78:	c39d                	beqz	a5,80004b9e <piperead+0x68>
    if(killed(pr)){
    80004b7a:	8552                	mv	a0,s4
    80004b7c:	ffffd097          	auipc	ra,0xffffd
    80004b80:	780080e7          	jalr	1920(ra) # 800022fc <killed>
    80004b84:	e949                	bnez	a0,80004c16 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b86:	85a6                	mv	a1,s1
    80004b88:	854e                	mv	a0,s3
    80004b8a:	ffffd097          	auipc	ra,0xffffd
    80004b8e:	4ca080e7          	jalr	1226(ra) # 80002054 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b92:	2184a703          	lw	a4,536(s1)
    80004b96:	21c4a783          	lw	a5,540(s1)
    80004b9a:	fcf70de3          	beq	a4,a5,80004b74 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b9e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ba0:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ba2:	05505463          	blez	s5,80004bea <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004ba6:	2184a783          	lw	a5,536(s1)
    80004baa:	21c4a703          	lw	a4,540(s1)
    80004bae:	02f70e63          	beq	a4,a5,80004bea <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004bb2:	0017871b          	addiw	a4,a5,1
    80004bb6:	20e4ac23          	sw	a4,536(s1)
    80004bba:	1ff7f793          	andi	a5,a5,511
    80004bbe:	97a6                	add	a5,a5,s1
    80004bc0:	0187c783          	lbu	a5,24(a5)
    80004bc4:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004bc8:	4685                	li	a3,1
    80004bca:	fbf40613          	addi	a2,s0,-65
    80004bce:	85ca                	mv	a1,s2
    80004bd0:	050a3503          	ld	a0,80(s4)
    80004bd4:	ffffd097          	auipc	ra,0xffffd
    80004bd8:	a98080e7          	jalr	-1384(ra) # 8000166c <copyout>
    80004bdc:	01650763          	beq	a0,s6,80004bea <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004be0:	2985                	addiw	s3,s3,1
    80004be2:	0905                	addi	s2,s2,1
    80004be4:	fd3a91e3          	bne	s5,s3,80004ba6 <piperead+0x70>
    80004be8:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004bea:	21c48513          	addi	a0,s1,540
    80004bee:	ffffd097          	auipc	ra,0xffffd
    80004bf2:	4ca080e7          	jalr	1226(ra) # 800020b8 <wakeup>
  release(&pi->lock);
    80004bf6:	8526                	mv	a0,s1
    80004bf8:	ffffc097          	auipc	ra,0xffffc
    80004bfc:	092080e7          	jalr	146(ra) # 80000c8a <release>
  return i;
}
    80004c00:	854e                	mv	a0,s3
    80004c02:	60a6                	ld	ra,72(sp)
    80004c04:	6406                	ld	s0,64(sp)
    80004c06:	74e2                	ld	s1,56(sp)
    80004c08:	7942                	ld	s2,48(sp)
    80004c0a:	79a2                	ld	s3,40(sp)
    80004c0c:	7a02                	ld	s4,32(sp)
    80004c0e:	6ae2                	ld	s5,24(sp)
    80004c10:	6b42                	ld	s6,16(sp)
    80004c12:	6161                	addi	sp,sp,80
    80004c14:	8082                	ret
      release(&pi->lock);
    80004c16:	8526                	mv	a0,s1
    80004c18:	ffffc097          	auipc	ra,0xffffc
    80004c1c:	072080e7          	jalr	114(ra) # 80000c8a <release>
      return -1;
    80004c20:	59fd                	li	s3,-1
    80004c22:	bff9                	j	80004c00 <piperead+0xca>

0000000080004c24 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004c24:	1141                	addi	sp,sp,-16
    80004c26:	e422                	sd	s0,8(sp)
    80004c28:	0800                	addi	s0,sp,16
    80004c2a:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004c2c:	8905                	andi	a0,a0,1
    80004c2e:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004c30:	8b89                	andi	a5,a5,2
    80004c32:	c399                	beqz	a5,80004c38 <flags2perm+0x14>
      perm |= PTE_W;
    80004c34:	00456513          	ori	a0,a0,4
    return perm;
}
    80004c38:	6422                	ld	s0,8(sp)
    80004c3a:	0141                	addi	sp,sp,16
    80004c3c:	8082                	ret

0000000080004c3e <exec>:

int
exec(char *path, char **argv)
{
    80004c3e:	de010113          	addi	sp,sp,-544
    80004c42:	20113c23          	sd	ra,536(sp)
    80004c46:	20813823          	sd	s0,528(sp)
    80004c4a:	20913423          	sd	s1,520(sp)
    80004c4e:	21213023          	sd	s2,512(sp)
    80004c52:	ffce                	sd	s3,504(sp)
    80004c54:	fbd2                	sd	s4,496(sp)
    80004c56:	f7d6                	sd	s5,488(sp)
    80004c58:	f3da                	sd	s6,480(sp)
    80004c5a:	efde                	sd	s7,472(sp)
    80004c5c:	ebe2                	sd	s8,464(sp)
    80004c5e:	e7e6                	sd	s9,456(sp)
    80004c60:	e3ea                	sd	s10,448(sp)
    80004c62:	ff6e                	sd	s11,440(sp)
    80004c64:	1400                	addi	s0,sp,544
    80004c66:	892a                	mv	s2,a0
    80004c68:	dea43423          	sd	a0,-536(s0)
    80004c6c:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004c70:	ffffd097          	auipc	ra,0xffffd
    80004c74:	d3c080e7          	jalr	-708(ra) # 800019ac <myproc>
    80004c78:	84aa                	mv	s1,a0

  begin_op();
    80004c7a:	fffff097          	auipc	ra,0xfffff
    80004c7e:	482080e7          	jalr	1154(ra) # 800040fc <begin_op>

  if((ip = namei(path)) == 0){
    80004c82:	854a                	mv	a0,s2
    80004c84:	fffff097          	auipc	ra,0xfffff
    80004c88:	258080e7          	jalr	600(ra) # 80003edc <namei>
    80004c8c:	c93d                	beqz	a0,80004d02 <exec+0xc4>
    80004c8e:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004c90:	fffff097          	auipc	ra,0xfffff
    80004c94:	aa0080e7          	jalr	-1376(ra) # 80003730 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c98:	04000713          	li	a4,64
    80004c9c:	4681                	li	a3,0
    80004c9e:	e5040613          	addi	a2,s0,-432
    80004ca2:	4581                	li	a1,0
    80004ca4:	8556                	mv	a0,s5
    80004ca6:	fffff097          	auipc	ra,0xfffff
    80004caa:	d3e080e7          	jalr	-706(ra) # 800039e4 <readi>
    80004cae:	04000793          	li	a5,64
    80004cb2:	00f51a63          	bne	a0,a5,80004cc6 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004cb6:	e5042703          	lw	a4,-432(s0)
    80004cba:	464c47b7          	lui	a5,0x464c4
    80004cbe:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004cc2:	04f70663          	beq	a4,a5,80004d0e <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004cc6:	8556                	mv	a0,s5
    80004cc8:	fffff097          	auipc	ra,0xfffff
    80004ccc:	cca080e7          	jalr	-822(ra) # 80003992 <iunlockput>
    end_op();
    80004cd0:	fffff097          	auipc	ra,0xfffff
    80004cd4:	4aa080e7          	jalr	1194(ra) # 8000417a <end_op>
  }
  return -1;
    80004cd8:	557d                	li	a0,-1
}
    80004cda:	21813083          	ld	ra,536(sp)
    80004cde:	21013403          	ld	s0,528(sp)
    80004ce2:	20813483          	ld	s1,520(sp)
    80004ce6:	20013903          	ld	s2,512(sp)
    80004cea:	79fe                	ld	s3,504(sp)
    80004cec:	7a5e                	ld	s4,496(sp)
    80004cee:	7abe                	ld	s5,488(sp)
    80004cf0:	7b1e                	ld	s6,480(sp)
    80004cf2:	6bfe                	ld	s7,472(sp)
    80004cf4:	6c5e                	ld	s8,464(sp)
    80004cf6:	6cbe                	ld	s9,456(sp)
    80004cf8:	6d1e                	ld	s10,448(sp)
    80004cfa:	7dfa                	ld	s11,440(sp)
    80004cfc:	22010113          	addi	sp,sp,544
    80004d00:	8082                	ret
    end_op();
    80004d02:	fffff097          	auipc	ra,0xfffff
    80004d06:	478080e7          	jalr	1144(ra) # 8000417a <end_op>
    return -1;
    80004d0a:	557d                	li	a0,-1
    80004d0c:	b7f9                	j	80004cda <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d0e:	8526                	mv	a0,s1
    80004d10:	ffffd097          	auipc	ra,0xffffd
    80004d14:	d60080e7          	jalr	-672(ra) # 80001a70 <proc_pagetable>
    80004d18:	8b2a                	mv	s6,a0
    80004d1a:	d555                	beqz	a0,80004cc6 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d1c:	e7042783          	lw	a5,-400(s0)
    80004d20:	e8845703          	lhu	a4,-376(s0)
    80004d24:	c735                	beqz	a4,80004d90 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d26:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d28:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004d2c:	6a05                	lui	s4,0x1
    80004d2e:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004d32:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004d36:	6d85                	lui	s11,0x1
    80004d38:	7d7d                	lui	s10,0xfffff
    80004d3a:	ac3d                	j	80004f78 <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d3c:	00004517          	auipc	a0,0x4
    80004d40:	9fc50513          	addi	a0,a0,-1540 # 80008738 <syscalls+0x2a8>
    80004d44:	ffffb097          	auipc	ra,0xffffb
    80004d48:	7fc080e7          	jalr	2044(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d4c:	874a                	mv	a4,s2
    80004d4e:	009c86bb          	addw	a3,s9,s1
    80004d52:	4581                	li	a1,0
    80004d54:	8556                	mv	a0,s5
    80004d56:	fffff097          	auipc	ra,0xfffff
    80004d5a:	c8e080e7          	jalr	-882(ra) # 800039e4 <readi>
    80004d5e:	2501                	sext.w	a0,a0
    80004d60:	1aa91963          	bne	s2,a0,80004f12 <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    80004d64:	009d84bb          	addw	s1,s11,s1
    80004d68:	013d09bb          	addw	s3,s10,s3
    80004d6c:	1f74f663          	bgeu	s1,s7,80004f58 <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    80004d70:	02049593          	slli	a1,s1,0x20
    80004d74:	9181                	srli	a1,a1,0x20
    80004d76:	95e2                	add	a1,a1,s8
    80004d78:	855a                	mv	a0,s6
    80004d7a:	ffffc097          	auipc	ra,0xffffc
    80004d7e:	2e2080e7          	jalr	738(ra) # 8000105c <walkaddr>
    80004d82:	862a                	mv	a2,a0
    if(pa == 0)
    80004d84:	dd45                	beqz	a0,80004d3c <exec+0xfe>
      n = PGSIZE;
    80004d86:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004d88:	fd49f2e3          	bgeu	s3,s4,80004d4c <exec+0x10e>
      n = sz - i;
    80004d8c:	894e                	mv	s2,s3
    80004d8e:	bf7d                	j	80004d4c <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d90:	4901                	li	s2,0
  iunlockput(ip);
    80004d92:	8556                	mv	a0,s5
    80004d94:	fffff097          	auipc	ra,0xfffff
    80004d98:	bfe080e7          	jalr	-1026(ra) # 80003992 <iunlockput>
  end_op();
    80004d9c:	fffff097          	auipc	ra,0xfffff
    80004da0:	3de080e7          	jalr	990(ra) # 8000417a <end_op>
  p = myproc();
    80004da4:	ffffd097          	auipc	ra,0xffffd
    80004da8:	c08080e7          	jalr	-1016(ra) # 800019ac <myproc>
    80004dac:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004dae:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004db2:	6785                	lui	a5,0x1
    80004db4:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80004db6:	97ca                	add	a5,a5,s2
    80004db8:	777d                	lui	a4,0xfffff
    80004dba:	8ff9                	and	a5,a5,a4
    80004dbc:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004dc0:	4691                	li	a3,4
    80004dc2:	6609                	lui	a2,0x2
    80004dc4:	963e                	add	a2,a2,a5
    80004dc6:	85be                	mv	a1,a5
    80004dc8:	855a                	mv	a0,s6
    80004dca:	ffffc097          	auipc	ra,0xffffc
    80004dce:	646080e7          	jalr	1606(ra) # 80001410 <uvmalloc>
    80004dd2:	8c2a                	mv	s8,a0
  ip = 0;
    80004dd4:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004dd6:	12050e63          	beqz	a0,80004f12 <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004dda:	75f9                	lui	a1,0xffffe
    80004ddc:	95aa                	add	a1,a1,a0
    80004dde:	855a                	mv	a0,s6
    80004de0:	ffffd097          	auipc	ra,0xffffd
    80004de4:	85a080e7          	jalr	-1958(ra) # 8000163a <uvmclear>
  stackbase = sp - PGSIZE;
    80004de8:	7afd                	lui	s5,0xfffff
    80004dea:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004dec:	df043783          	ld	a5,-528(s0)
    80004df0:	6388                	ld	a0,0(a5)
    80004df2:	c925                	beqz	a0,80004e62 <exec+0x224>
    80004df4:	e9040993          	addi	s3,s0,-368
    80004df8:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004dfc:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004dfe:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004e00:	ffffc097          	auipc	ra,0xffffc
    80004e04:	04e080e7          	jalr	78(ra) # 80000e4e <strlen>
    80004e08:	0015079b          	addiw	a5,a0,1
    80004e0c:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e10:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004e14:	13596663          	bltu	s2,s5,80004f40 <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e18:	df043d83          	ld	s11,-528(s0)
    80004e1c:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004e20:	8552                	mv	a0,s4
    80004e22:	ffffc097          	auipc	ra,0xffffc
    80004e26:	02c080e7          	jalr	44(ra) # 80000e4e <strlen>
    80004e2a:	0015069b          	addiw	a3,a0,1
    80004e2e:	8652                	mv	a2,s4
    80004e30:	85ca                	mv	a1,s2
    80004e32:	855a                	mv	a0,s6
    80004e34:	ffffd097          	auipc	ra,0xffffd
    80004e38:	838080e7          	jalr	-1992(ra) # 8000166c <copyout>
    80004e3c:	10054663          	bltz	a0,80004f48 <exec+0x30a>
    ustack[argc] = sp;
    80004e40:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e44:	0485                	addi	s1,s1,1
    80004e46:	008d8793          	addi	a5,s11,8
    80004e4a:	def43823          	sd	a5,-528(s0)
    80004e4e:	008db503          	ld	a0,8(s11)
    80004e52:	c911                	beqz	a0,80004e66 <exec+0x228>
    if(argc >= MAXARG)
    80004e54:	09a1                	addi	s3,s3,8
    80004e56:	fb3c95e3          	bne	s9,s3,80004e00 <exec+0x1c2>
  sz = sz1;
    80004e5a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e5e:	4a81                	li	s5,0
    80004e60:	a84d                	j	80004f12 <exec+0x2d4>
  sp = sz;
    80004e62:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e64:	4481                	li	s1,0
  ustack[argc] = 0;
    80004e66:	00349793          	slli	a5,s1,0x3
    80004e6a:	f9078793          	addi	a5,a5,-112
    80004e6e:	97a2                	add	a5,a5,s0
    80004e70:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004e74:	00148693          	addi	a3,s1,1
    80004e78:	068e                	slli	a3,a3,0x3
    80004e7a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004e7e:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004e82:	01597663          	bgeu	s2,s5,80004e8e <exec+0x250>
  sz = sz1;
    80004e86:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e8a:	4a81                	li	s5,0
    80004e8c:	a059                	j	80004f12 <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004e8e:	e9040613          	addi	a2,s0,-368
    80004e92:	85ca                	mv	a1,s2
    80004e94:	855a                	mv	a0,s6
    80004e96:	ffffc097          	auipc	ra,0xffffc
    80004e9a:	7d6080e7          	jalr	2006(ra) # 8000166c <copyout>
    80004e9e:	0a054963          	bltz	a0,80004f50 <exec+0x312>
  p->trapframe->a1 = sp;
    80004ea2:	058bb783          	ld	a5,88(s7)
    80004ea6:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004eaa:	de843783          	ld	a5,-536(s0)
    80004eae:	0007c703          	lbu	a4,0(a5)
    80004eb2:	cf11                	beqz	a4,80004ece <exec+0x290>
    80004eb4:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004eb6:	02f00693          	li	a3,47
    80004eba:	a039                	j	80004ec8 <exec+0x28a>
      last = s+1;
    80004ebc:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004ec0:	0785                	addi	a5,a5,1
    80004ec2:	fff7c703          	lbu	a4,-1(a5)
    80004ec6:	c701                	beqz	a4,80004ece <exec+0x290>
    if(*s == '/')
    80004ec8:	fed71ce3          	bne	a4,a3,80004ec0 <exec+0x282>
    80004ecc:	bfc5                	j	80004ebc <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    80004ece:	4641                	li	a2,16
    80004ed0:	de843583          	ld	a1,-536(s0)
    80004ed4:	158b8513          	addi	a0,s7,344
    80004ed8:	ffffc097          	auipc	ra,0xffffc
    80004edc:	f44080e7          	jalr	-188(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    80004ee0:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004ee4:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004ee8:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004eec:	058bb783          	ld	a5,88(s7)
    80004ef0:	e6843703          	ld	a4,-408(s0)
    80004ef4:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004ef6:	058bb783          	ld	a5,88(s7)
    80004efa:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004efe:	85ea                	mv	a1,s10
    80004f00:	ffffd097          	auipc	ra,0xffffd
    80004f04:	c0c080e7          	jalr	-1012(ra) # 80001b0c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f08:	0004851b          	sext.w	a0,s1
    80004f0c:	b3f9                	j	80004cda <exec+0x9c>
    80004f0e:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004f12:	df843583          	ld	a1,-520(s0)
    80004f16:	855a                	mv	a0,s6
    80004f18:	ffffd097          	auipc	ra,0xffffd
    80004f1c:	bf4080e7          	jalr	-1036(ra) # 80001b0c <proc_freepagetable>
  if(ip){
    80004f20:	da0a93e3          	bnez	s5,80004cc6 <exec+0x88>
  return -1;
    80004f24:	557d                	li	a0,-1
    80004f26:	bb55                	j	80004cda <exec+0x9c>
    80004f28:	df243c23          	sd	s2,-520(s0)
    80004f2c:	b7dd                	j	80004f12 <exec+0x2d4>
    80004f2e:	df243c23          	sd	s2,-520(s0)
    80004f32:	b7c5                	j	80004f12 <exec+0x2d4>
    80004f34:	df243c23          	sd	s2,-520(s0)
    80004f38:	bfe9                	j	80004f12 <exec+0x2d4>
    80004f3a:	df243c23          	sd	s2,-520(s0)
    80004f3e:	bfd1                	j	80004f12 <exec+0x2d4>
  sz = sz1;
    80004f40:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f44:	4a81                	li	s5,0
    80004f46:	b7f1                	j	80004f12 <exec+0x2d4>
  sz = sz1;
    80004f48:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f4c:	4a81                	li	s5,0
    80004f4e:	b7d1                	j	80004f12 <exec+0x2d4>
  sz = sz1;
    80004f50:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f54:	4a81                	li	s5,0
    80004f56:	bf75                	j	80004f12 <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004f58:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f5c:	e0843783          	ld	a5,-504(s0)
    80004f60:	0017869b          	addiw	a3,a5,1
    80004f64:	e0d43423          	sd	a3,-504(s0)
    80004f68:	e0043783          	ld	a5,-512(s0)
    80004f6c:	0387879b          	addiw	a5,a5,56
    80004f70:	e8845703          	lhu	a4,-376(s0)
    80004f74:	e0e6dfe3          	bge	a3,a4,80004d92 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004f78:	2781                	sext.w	a5,a5
    80004f7a:	e0f43023          	sd	a5,-512(s0)
    80004f7e:	03800713          	li	a4,56
    80004f82:	86be                	mv	a3,a5
    80004f84:	e1840613          	addi	a2,s0,-488
    80004f88:	4581                	li	a1,0
    80004f8a:	8556                	mv	a0,s5
    80004f8c:	fffff097          	auipc	ra,0xfffff
    80004f90:	a58080e7          	jalr	-1448(ra) # 800039e4 <readi>
    80004f94:	03800793          	li	a5,56
    80004f98:	f6f51be3          	bne	a0,a5,80004f0e <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    80004f9c:	e1842783          	lw	a5,-488(s0)
    80004fa0:	4705                	li	a4,1
    80004fa2:	fae79de3          	bne	a5,a4,80004f5c <exec+0x31e>
    if(ph.memsz < ph.filesz)
    80004fa6:	e4043483          	ld	s1,-448(s0)
    80004faa:	e3843783          	ld	a5,-456(s0)
    80004fae:	f6f4ede3          	bltu	s1,a5,80004f28 <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004fb2:	e2843783          	ld	a5,-472(s0)
    80004fb6:	94be                	add	s1,s1,a5
    80004fb8:	f6f4ebe3          	bltu	s1,a5,80004f2e <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    80004fbc:	de043703          	ld	a4,-544(s0)
    80004fc0:	8ff9                	and	a5,a5,a4
    80004fc2:	fbad                	bnez	a5,80004f34 <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004fc4:	e1c42503          	lw	a0,-484(s0)
    80004fc8:	00000097          	auipc	ra,0x0
    80004fcc:	c5c080e7          	jalr	-932(ra) # 80004c24 <flags2perm>
    80004fd0:	86aa                	mv	a3,a0
    80004fd2:	8626                	mv	a2,s1
    80004fd4:	85ca                	mv	a1,s2
    80004fd6:	855a                	mv	a0,s6
    80004fd8:	ffffc097          	auipc	ra,0xffffc
    80004fdc:	438080e7          	jalr	1080(ra) # 80001410 <uvmalloc>
    80004fe0:	dea43c23          	sd	a0,-520(s0)
    80004fe4:	d939                	beqz	a0,80004f3a <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004fe6:	e2843c03          	ld	s8,-472(s0)
    80004fea:	e2042c83          	lw	s9,-480(s0)
    80004fee:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004ff2:	f60b83e3          	beqz	s7,80004f58 <exec+0x31a>
    80004ff6:	89de                	mv	s3,s7
    80004ff8:	4481                	li	s1,0
    80004ffa:	bb9d                	j	80004d70 <exec+0x132>

0000000080004ffc <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004ffc:	7179                	addi	sp,sp,-48
    80004ffe:	f406                	sd	ra,40(sp)
    80005000:	f022                	sd	s0,32(sp)
    80005002:	ec26                	sd	s1,24(sp)
    80005004:	e84a                	sd	s2,16(sp)
    80005006:	1800                	addi	s0,sp,48
    80005008:	892e                	mv	s2,a1
    8000500a:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    8000500c:	fdc40593          	addi	a1,s0,-36
    80005010:	ffffe097          	auipc	ra,0xffffe
    80005014:	b60080e7          	jalr	-1184(ra) # 80002b70 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005018:	fdc42703          	lw	a4,-36(s0)
    8000501c:	47bd                	li	a5,15
    8000501e:	02e7eb63          	bltu	a5,a4,80005054 <argfd+0x58>
    80005022:	ffffd097          	auipc	ra,0xffffd
    80005026:	98a080e7          	jalr	-1654(ra) # 800019ac <myproc>
    8000502a:	fdc42703          	lw	a4,-36(s0)
    8000502e:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffdd24a>
    80005032:	078e                	slli	a5,a5,0x3
    80005034:	953e                	add	a0,a0,a5
    80005036:	611c                	ld	a5,0(a0)
    80005038:	c385                	beqz	a5,80005058 <argfd+0x5c>
    return -1;
  if(pfd)
    8000503a:	00090463          	beqz	s2,80005042 <argfd+0x46>
    *pfd = fd;
    8000503e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005042:	4501                	li	a0,0
  if(pf)
    80005044:	c091                	beqz	s1,80005048 <argfd+0x4c>
    *pf = f;
    80005046:	e09c                	sd	a5,0(s1)
}
    80005048:	70a2                	ld	ra,40(sp)
    8000504a:	7402                	ld	s0,32(sp)
    8000504c:	64e2                	ld	s1,24(sp)
    8000504e:	6942                	ld	s2,16(sp)
    80005050:	6145                	addi	sp,sp,48
    80005052:	8082                	ret
    return -1;
    80005054:	557d                	li	a0,-1
    80005056:	bfcd                	j	80005048 <argfd+0x4c>
    80005058:	557d                	li	a0,-1
    8000505a:	b7fd                	j	80005048 <argfd+0x4c>

000000008000505c <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000505c:	1101                	addi	sp,sp,-32
    8000505e:	ec06                	sd	ra,24(sp)
    80005060:	e822                	sd	s0,16(sp)
    80005062:	e426                	sd	s1,8(sp)
    80005064:	1000                	addi	s0,sp,32
    80005066:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005068:	ffffd097          	auipc	ra,0xffffd
    8000506c:	944080e7          	jalr	-1724(ra) # 800019ac <myproc>
    80005070:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005072:	0d050793          	addi	a5,a0,208
    80005076:	4501                	li	a0,0
    80005078:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000507a:	6398                	ld	a4,0(a5)
    8000507c:	cb19                	beqz	a4,80005092 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000507e:	2505                	addiw	a0,a0,1
    80005080:	07a1                	addi	a5,a5,8
    80005082:	fed51ce3          	bne	a0,a3,8000507a <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005086:	557d                	li	a0,-1
}
    80005088:	60e2                	ld	ra,24(sp)
    8000508a:	6442                	ld	s0,16(sp)
    8000508c:	64a2                	ld	s1,8(sp)
    8000508e:	6105                	addi	sp,sp,32
    80005090:	8082                	ret
      p->ofile[fd] = f;
    80005092:	01a50793          	addi	a5,a0,26
    80005096:	078e                	slli	a5,a5,0x3
    80005098:	963e                	add	a2,a2,a5
    8000509a:	e204                	sd	s1,0(a2)
      return fd;
    8000509c:	b7f5                	j	80005088 <fdalloc+0x2c>

000000008000509e <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000509e:	715d                	addi	sp,sp,-80
    800050a0:	e486                	sd	ra,72(sp)
    800050a2:	e0a2                	sd	s0,64(sp)
    800050a4:	fc26                	sd	s1,56(sp)
    800050a6:	f84a                	sd	s2,48(sp)
    800050a8:	f44e                	sd	s3,40(sp)
    800050aa:	f052                	sd	s4,32(sp)
    800050ac:	ec56                	sd	s5,24(sp)
    800050ae:	e85a                	sd	s6,16(sp)
    800050b0:	0880                	addi	s0,sp,80
    800050b2:	8b2e                	mv	s6,a1
    800050b4:	89b2                	mv	s3,a2
    800050b6:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800050b8:	fb040593          	addi	a1,s0,-80
    800050bc:	fffff097          	auipc	ra,0xfffff
    800050c0:	e3e080e7          	jalr	-450(ra) # 80003efa <nameiparent>
    800050c4:	84aa                	mv	s1,a0
    800050c6:	14050f63          	beqz	a0,80005224 <create+0x186>
    return 0;

  ilock(dp);
    800050ca:	ffffe097          	auipc	ra,0xffffe
    800050ce:	666080e7          	jalr	1638(ra) # 80003730 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800050d2:	4601                	li	a2,0
    800050d4:	fb040593          	addi	a1,s0,-80
    800050d8:	8526                	mv	a0,s1
    800050da:	fffff097          	auipc	ra,0xfffff
    800050de:	b3a080e7          	jalr	-1222(ra) # 80003c14 <dirlookup>
    800050e2:	8aaa                	mv	s5,a0
    800050e4:	c931                	beqz	a0,80005138 <create+0x9a>
    iunlockput(dp);
    800050e6:	8526                	mv	a0,s1
    800050e8:	fffff097          	auipc	ra,0xfffff
    800050ec:	8aa080e7          	jalr	-1878(ra) # 80003992 <iunlockput>
    ilock(ip);
    800050f0:	8556                	mv	a0,s5
    800050f2:	ffffe097          	auipc	ra,0xffffe
    800050f6:	63e080e7          	jalr	1598(ra) # 80003730 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800050fa:	000b059b          	sext.w	a1,s6
    800050fe:	4789                	li	a5,2
    80005100:	02f59563          	bne	a1,a5,8000512a <create+0x8c>
    80005104:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdd274>
    80005108:	37f9                	addiw	a5,a5,-2
    8000510a:	17c2                	slli	a5,a5,0x30
    8000510c:	93c1                	srli	a5,a5,0x30
    8000510e:	4705                	li	a4,1
    80005110:	00f76d63          	bltu	a4,a5,8000512a <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005114:	8556                	mv	a0,s5
    80005116:	60a6                	ld	ra,72(sp)
    80005118:	6406                	ld	s0,64(sp)
    8000511a:	74e2                	ld	s1,56(sp)
    8000511c:	7942                	ld	s2,48(sp)
    8000511e:	79a2                	ld	s3,40(sp)
    80005120:	7a02                	ld	s4,32(sp)
    80005122:	6ae2                	ld	s5,24(sp)
    80005124:	6b42                	ld	s6,16(sp)
    80005126:	6161                	addi	sp,sp,80
    80005128:	8082                	ret
    iunlockput(ip);
    8000512a:	8556                	mv	a0,s5
    8000512c:	fffff097          	auipc	ra,0xfffff
    80005130:	866080e7          	jalr	-1946(ra) # 80003992 <iunlockput>
    return 0;
    80005134:	4a81                	li	s5,0
    80005136:	bff9                	j	80005114 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005138:	85da                	mv	a1,s6
    8000513a:	4088                	lw	a0,0(s1)
    8000513c:	ffffe097          	auipc	ra,0xffffe
    80005140:	456080e7          	jalr	1110(ra) # 80003592 <ialloc>
    80005144:	8a2a                	mv	s4,a0
    80005146:	c539                	beqz	a0,80005194 <create+0xf6>
  ilock(ip);
    80005148:	ffffe097          	auipc	ra,0xffffe
    8000514c:	5e8080e7          	jalr	1512(ra) # 80003730 <ilock>
  ip->major = major;
    80005150:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005154:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005158:	4905                	li	s2,1
    8000515a:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    8000515e:	8552                	mv	a0,s4
    80005160:	ffffe097          	auipc	ra,0xffffe
    80005164:	504080e7          	jalr	1284(ra) # 80003664 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005168:	000b059b          	sext.w	a1,s6
    8000516c:	03258b63          	beq	a1,s2,800051a2 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005170:	004a2603          	lw	a2,4(s4)
    80005174:	fb040593          	addi	a1,s0,-80
    80005178:	8526                	mv	a0,s1
    8000517a:	fffff097          	auipc	ra,0xfffff
    8000517e:	cb0080e7          	jalr	-848(ra) # 80003e2a <dirlink>
    80005182:	06054f63          	bltz	a0,80005200 <create+0x162>
  iunlockput(dp);
    80005186:	8526                	mv	a0,s1
    80005188:	fffff097          	auipc	ra,0xfffff
    8000518c:	80a080e7          	jalr	-2038(ra) # 80003992 <iunlockput>
  return ip;
    80005190:	8ad2                	mv	s5,s4
    80005192:	b749                	j	80005114 <create+0x76>
    iunlockput(dp);
    80005194:	8526                	mv	a0,s1
    80005196:	ffffe097          	auipc	ra,0xffffe
    8000519a:	7fc080e7          	jalr	2044(ra) # 80003992 <iunlockput>
    return 0;
    8000519e:	8ad2                	mv	s5,s4
    800051a0:	bf95                	j	80005114 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800051a2:	004a2603          	lw	a2,4(s4)
    800051a6:	00003597          	auipc	a1,0x3
    800051aa:	5b258593          	addi	a1,a1,1458 # 80008758 <syscalls+0x2c8>
    800051ae:	8552                	mv	a0,s4
    800051b0:	fffff097          	auipc	ra,0xfffff
    800051b4:	c7a080e7          	jalr	-902(ra) # 80003e2a <dirlink>
    800051b8:	04054463          	bltz	a0,80005200 <create+0x162>
    800051bc:	40d0                	lw	a2,4(s1)
    800051be:	00003597          	auipc	a1,0x3
    800051c2:	5a258593          	addi	a1,a1,1442 # 80008760 <syscalls+0x2d0>
    800051c6:	8552                	mv	a0,s4
    800051c8:	fffff097          	auipc	ra,0xfffff
    800051cc:	c62080e7          	jalr	-926(ra) # 80003e2a <dirlink>
    800051d0:	02054863          	bltz	a0,80005200 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    800051d4:	004a2603          	lw	a2,4(s4)
    800051d8:	fb040593          	addi	a1,s0,-80
    800051dc:	8526                	mv	a0,s1
    800051de:	fffff097          	auipc	ra,0xfffff
    800051e2:	c4c080e7          	jalr	-948(ra) # 80003e2a <dirlink>
    800051e6:	00054d63          	bltz	a0,80005200 <create+0x162>
    dp->nlink++;  // for ".."
    800051ea:	04a4d783          	lhu	a5,74(s1)
    800051ee:	2785                	addiw	a5,a5,1
    800051f0:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800051f4:	8526                	mv	a0,s1
    800051f6:	ffffe097          	auipc	ra,0xffffe
    800051fa:	46e080e7          	jalr	1134(ra) # 80003664 <iupdate>
    800051fe:	b761                	j	80005186 <create+0xe8>
  ip->nlink = 0;
    80005200:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005204:	8552                	mv	a0,s4
    80005206:	ffffe097          	auipc	ra,0xffffe
    8000520a:	45e080e7          	jalr	1118(ra) # 80003664 <iupdate>
  iunlockput(ip);
    8000520e:	8552                	mv	a0,s4
    80005210:	ffffe097          	auipc	ra,0xffffe
    80005214:	782080e7          	jalr	1922(ra) # 80003992 <iunlockput>
  iunlockput(dp);
    80005218:	8526                	mv	a0,s1
    8000521a:	ffffe097          	auipc	ra,0xffffe
    8000521e:	778080e7          	jalr	1912(ra) # 80003992 <iunlockput>
  return 0;
    80005222:	bdcd                	j	80005114 <create+0x76>
    return 0;
    80005224:	8aaa                	mv	s5,a0
    80005226:	b5fd                	j	80005114 <create+0x76>

0000000080005228 <sys_dup>:
{
    80005228:	7179                	addi	sp,sp,-48
    8000522a:	f406                	sd	ra,40(sp)
    8000522c:	f022                	sd	s0,32(sp)
    8000522e:	ec26                	sd	s1,24(sp)
    80005230:	e84a                	sd	s2,16(sp)
    80005232:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005234:	fd840613          	addi	a2,s0,-40
    80005238:	4581                	li	a1,0
    8000523a:	4501                	li	a0,0
    8000523c:	00000097          	auipc	ra,0x0
    80005240:	dc0080e7          	jalr	-576(ra) # 80004ffc <argfd>
    return -1;
    80005244:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005246:	02054363          	bltz	a0,8000526c <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    8000524a:	fd843903          	ld	s2,-40(s0)
    8000524e:	854a                	mv	a0,s2
    80005250:	00000097          	auipc	ra,0x0
    80005254:	e0c080e7          	jalr	-500(ra) # 8000505c <fdalloc>
    80005258:	84aa                	mv	s1,a0
    return -1;
    8000525a:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000525c:	00054863          	bltz	a0,8000526c <sys_dup+0x44>
  filedup(f);
    80005260:	854a                	mv	a0,s2
    80005262:	fffff097          	auipc	ra,0xfffff
    80005266:	310080e7          	jalr	784(ra) # 80004572 <filedup>
  return fd;
    8000526a:	87a6                	mv	a5,s1
}
    8000526c:	853e                	mv	a0,a5
    8000526e:	70a2                	ld	ra,40(sp)
    80005270:	7402                	ld	s0,32(sp)
    80005272:	64e2                	ld	s1,24(sp)
    80005274:	6942                	ld	s2,16(sp)
    80005276:	6145                	addi	sp,sp,48
    80005278:	8082                	ret

000000008000527a <sys_read>:
{
    8000527a:	7179                	addi	sp,sp,-48
    8000527c:	f406                	sd	ra,40(sp)
    8000527e:	f022                	sd	s0,32(sp)
    80005280:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005282:	fd840593          	addi	a1,s0,-40
    80005286:	4505                	li	a0,1
    80005288:	ffffe097          	auipc	ra,0xffffe
    8000528c:	908080e7          	jalr	-1784(ra) # 80002b90 <argaddr>
  argint(2, &n);
    80005290:	fe440593          	addi	a1,s0,-28
    80005294:	4509                	li	a0,2
    80005296:	ffffe097          	auipc	ra,0xffffe
    8000529a:	8da080e7          	jalr	-1830(ra) # 80002b70 <argint>
  if(argfd(0, 0, &f) < 0)
    8000529e:	fe840613          	addi	a2,s0,-24
    800052a2:	4581                	li	a1,0
    800052a4:	4501                	li	a0,0
    800052a6:	00000097          	auipc	ra,0x0
    800052aa:	d56080e7          	jalr	-682(ra) # 80004ffc <argfd>
    800052ae:	87aa                	mv	a5,a0
    return -1;
    800052b0:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800052b2:	0007cc63          	bltz	a5,800052ca <sys_read+0x50>
  return fileread(f, p, n);
    800052b6:	fe442603          	lw	a2,-28(s0)
    800052ba:	fd843583          	ld	a1,-40(s0)
    800052be:	fe843503          	ld	a0,-24(s0)
    800052c2:	fffff097          	auipc	ra,0xfffff
    800052c6:	43c080e7          	jalr	1084(ra) # 800046fe <fileread>
}
    800052ca:	70a2                	ld	ra,40(sp)
    800052cc:	7402                	ld	s0,32(sp)
    800052ce:	6145                	addi	sp,sp,48
    800052d0:	8082                	ret

00000000800052d2 <sys_write>:
{
    800052d2:	7179                	addi	sp,sp,-48
    800052d4:	f406                	sd	ra,40(sp)
    800052d6:	f022                	sd	s0,32(sp)
    800052d8:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800052da:	fd840593          	addi	a1,s0,-40
    800052de:	4505                	li	a0,1
    800052e0:	ffffe097          	auipc	ra,0xffffe
    800052e4:	8b0080e7          	jalr	-1872(ra) # 80002b90 <argaddr>
  argint(2, &n);
    800052e8:	fe440593          	addi	a1,s0,-28
    800052ec:	4509                	li	a0,2
    800052ee:	ffffe097          	auipc	ra,0xffffe
    800052f2:	882080e7          	jalr	-1918(ra) # 80002b70 <argint>
  if(argfd(0, 0, &f) < 0)
    800052f6:	fe840613          	addi	a2,s0,-24
    800052fa:	4581                	li	a1,0
    800052fc:	4501                	li	a0,0
    800052fe:	00000097          	auipc	ra,0x0
    80005302:	cfe080e7          	jalr	-770(ra) # 80004ffc <argfd>
    80005306:	87aa                	mv	a5,a0
    return -1;
    80005308:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000530a:	0007cc63          	bltz	a5,80005322 <sys_write+0x50>
  return filewrite(f, p, n);
    8000530e:	fe442603          	lw	a2,-28(s0)
    80005312:	fd843583          	ld	a1,-40(s0)
    80005316:	fe843503          	ld	a0,-24(s0)
    8000531a:	fffff097          	auipc	ra,0xfffff
    8000531e:	4a6080e7          	jalr	1190(ra) # 800047c0 <filewrite>
}
    80005322:	70a2                	ld	ra,40(sp)
    80005324:	7402                	ld	s0,32(sp)
    80005326:	6145                	addi	sp,sp,48
    80005328:	8082                	ret

000000008000532a <sys_close>:
{
    8000532a:	1101                	addi	sp,sp,-32
    8000532c:	ec06                	sd	ra,24(sp)
    8000532e:	e822                	sd	s0,16(sp)
    80005330:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005332:	fe040613          	addi	a2,s0,-32
    80005336:	fec40593          	addi	a1,s0,-20
    8000533a:	4501                	li	a0,0
    8000533c:	00000097          	auipc	ra,0x0
    80005340:	cc0080e7          	jalr	-832(ra) # 80004ffc <argfd>
    return -1;
    80005344:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005346:	02054463          	bltz	a0,8000536e <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000534a:	ffffc097          	auipc	ra,0xffffc
    8000534e:	662080e7          	jalr	1634(ra) # 800019ac <myproc>
    80005352:	fec42783          	lw	a5,-20(s0)
    80005356:	07e9                	addi	a5,a5,26
    80005358:	078e                	slli	a5,a5,0x3
    8000535a:	953e                	add	a0,a0,a5
    8000535c:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005360:	fe043503          	ld	a0,-32(s0)
    80005364:	fffff097          	auipc	ra,0xfffff
    80005368:	260080e7          	jalr	608(ra) # 800045c4 <fileclose>
  return 0;
    8000536c:	4781                	li	a5,0
}
    8000536e:	853e                	mv	a0,a5
    80005370:	60e2                	ld	ra,24(sp)
    80005372:	6442                	ld	s0,16(sp)
    80005374:	6105                	addi	sp,sp,32
    80005376:	8082                	ret

0000000080005378 <sys_fstat>:
{
    80005378:	1101                	addi	sp,sp,-32
    8000537a:	ec06                	sd	ra,24(sp)
    8000537c:	e822                	sd	s0,16(sp)
    8000537e:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005380:	fe040593          	addi	a1,s0,-32
    80005384:	4505                	li	a0,1
    80005386:	ffffe097          	auipc	ra,0xffffe
    8000538a:	80a080e7          	jalr	-2038(ra) # 80002b90 <argaddr>
  if(argfd(0, 0, &f) < 0)
    8000538e:	fe840613          	addi	a2,s0,-24
    80005392:	4581                	li	a1,0
    80005394:	4501                	li	a0,0
    80005396:	00000097          	auipc	ra,0x0
    8000539a:	c66080e7          	jalr	-922(ra) # 80004ffc <argfd>
    8000539e:	87aa                	mv	a5,a0
    return -1;
    800053a0:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800053a2:	0007ca63          	bltz	a5,800053b6 <sys_fstat+0x3e>
  return filestat(f, st);
    800053a6:	fe043583          	ld	a1,-32(s0)
    800053aa:	fe843503          	ld	a0,-24(s0)
    800053ae:	fffff097          	auipc	ra,0xfffff
    800053b2:	2de080e7          	jalr	734(ra) # 8000468c <filestat>
}
    800053b6:	60e2                	ld	ra,24(sp)
    800053b8:	6442                	ld	s0,16(sp)
    800053ba:	6105                	addi	sp,sp,32
    800053bc:	8082                	ret

00000000800053be <sys_link>:
{
    800053be:	7169                	addi	sp,sp,-304
    800053c0:	f606                	sd	ra,296(sp)
    800053c2:	f222                	sd	s0,288(sp)
    800053c4:	ee26                	sd	s1,280(sp)
    800053c6:	ea4a                	sd	s2,272(sp)
    800053c8:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053ca:	08000613          	li	a2,128
    800053ce:	ed040593          	addi	a1,s0,-304
    800053d2:	4501                	li	a0,0
    800053d4:	ffffd097          	auipc	ra,0xffffd
    800053d8:	7dc080e7          	jalr	2012(ra) # 80002bb0 <argstr>
    return -1;
    800053dc:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053de:	10054e63          	bltz	a0,800054fa <sys_link+0x13c>
    800053e2:	08000613          	li	a2,128
    800053e6:	f5040593          	addi	a1,s0,-176
    800053ea:	4505                	li	a0,1
    800053ec:	ffffd097          	auipc	ra,0xffffd
    800053f0:	7c4080e7          	jalr	1988(ra) # 80002bb0 <argstr>
    return -1;
    800053f4:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053f6:	10054263          	bltz	a0,800054fa <sys_link+0x13c>
  begin_op();
    800053fa:	fffff097          	auipc	ra,0xfffff
    800053fe:	d02080e7          	jalr	-766(ra) # 800040fc <begin_op>
  if((ip = namei(old)) == 0){
    80005402:	ed040513          	addi	a0,s0,-304
    80005406:	fffff097          	auipc	ra,0xfffff
    8000540a:	ad6080e7          	jalr	-1322(ra) # 80003edc <namei>
    8000540e:	84aa                	mv	s1,a0
    80005410:	c551                	beqz	a0,8000549c <sys_link+0xde>
  ilock(ip);
    80005412:	ffffe097          	auipc	ra,0xffffe
    80005416:	31e080e7          	jalr	798(ra) # 80003730 <ilock>
  if(ip->type == T_DIR){
    8000541a:	04449703          	lh	a4,68(s1)
    8000541e:	4785                	li	a5,1
    80005420:	08f70463          	beq	a4,a5,800054a8 <sys_link+0xea>
  ip->nlink++;
    80005424:	04a4d783          	lhu	a5,74(s1)
    80005428:	2785                	addiw	a5,a5,1
    8000542a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000542e:	8526                	mv	a0,s1
    80005430:	ffffe097          	auipc	ra,0xffffe
    80005434:	234080e7          	jalr	564(ra) # 80003664 <iupdate>
  iunlock(ip);
    80005438:	8526                	mv	a0,s1
    8000543a:	ffffe097          	auipc	ra,0xffffe
    8000543e:	3b8080e7          	jalr	952(ra) # 800037f2 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005442:	fd040593          	addi	a1,s0,-48
    80005446:	f5040513          	addi	a0,s0,-176
    8000544a:	fffff097          	auipc	ra,0xfffff
    8000544e:	ab0080e7          	jalr	-1360(ra) # 80003efa <nameiparent>
    80005452:	892a                	mv	s2,a0
    80005454:	c935                	beqz	a0,800054c8 <sys_link+0x10a>
  ilock(dp);
    80005456:	ffffe097          	auipc	ra,0xffffe
    8000545a:	2da080e7          	jalr	730(ra) # 80003730 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000545e:	00092703          	lw	a4,0(s2)
    80005462:	409c                	lw	a5,0(s1)
    80005464:	04f71d63          	bne	a4,a5,800054be <sys_link+0x100>
    80005468:	40d0                	lw	a2,4(s1)
    8000546a:	fd040593          	addi	a1,s0,-48
    8000546e:	854a                	mv	a0,s2
    80005470:	fffff097          	auipc	ra,0xfffff
    80005474:	9ba080e7          	jalr	-1606(ra) # 80003e2a <dirlink>
    80005478:	04054363          	bltz	a0,800054be <sys_link+0x100>
  iunlockput(dp);
    8000547c:	854a                	mv	a0,s2
    8000547e:	ffffe097          	auipc	ra,0xffffe
    80005482:	514080e7          	jalr	1300(ra) # 80003992 <iunlockput>
  iput(ip);
    80005486:	8526                	mv	a0,s1
    80005488:	ffffe097          	auipc	ra,0xffffe
    8000548c:	462080e7          	jalr	1122(ra) # 800038ea <iput>
  end_op();
    80005490:	fffff097          	auipc	ra,0xfffff
    80005494:	cea080e7          	jalr	-790(ra) # 8000417a <end_op>
  return 0;
    80005498:	4781                	li	a5,0
    8000549a:	a085                	j	800054fa <sys_link+0x13c>
    end_op();
    8000549c:	fffff097          	auipc	ra,0xfffff
    800054a0:	cde080e7          	jalr	-802(ra) # 8000417a <end_op>
    return -1;
    800054a4:	57fd                	li	a5,-1
    800054a6:	a891                	j	800054fa <sys_link+0x13c>
    iunlockput(ip);
    800054a8:	8526                	mv	a0,s1
    800054aa:	ffffe097          	auipc	ra,0xffffe
    800054ae:	4e8080e7          	jalr	1256(ra) # 80003992 <iunlockput>
    end_op();
    800054b2:	fffff097          	auipc	ra,0xfffff
    800054b6:	cc8080e7          	jalr	-824(ra) # 8000417a <end_op>
    return -1;
    800054ba:	57fd                	li	a5,-1
    800054bc:	a83d                	j	800054fa <sys_link+0x13c>
    iunlockput(dp);
    800054be:	854a                	mv	a0,s2
    800054c0:	ffffe097          	auipc	ra,0xffffe
    800054c4:	4d2080e7          	jalr	1234(ra) # 80003992 <iunlockput>
  ilock(ip);
    800054c8:	8526                	mv	a0,s1
    800054ca:	ffffe097          	auipc	ra,0xffffe
    800054ce:	266080e7          	jalr	614(ra) # 80003730 <ilock>
  ip->nlink--;
    800054d2:	04a4d783          	lhu	a5,74(s1)
    800054d6:	37fd                	addiw	a5,a5,-1
    800054d8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054dc:	8526                	mv	a0,s1
    800054de:	ffffe097          	auipc	ra,0xffffe
    800054e2:	186080e7          	jalr	390(ra) # 80003664 <iupdate>
  iunlockput(ip);
    800054e6:	8526                	mv	a0,s1
    800054e8:	ffffe097          	auipc	ra,0xffffe
    800054ec:	4aa080e7          	jalr	1194(ra) # 80003992 <iunlockput>
  end_op();
    800054f0:	fffff097          	auipc	ra,0xfffff
    800054f4:	c8a080e7          	jalr	-886(ra) # 8000417a <end_op>
  return -1;
    800054f8:	57fd                	li	a5,-1
}
    800054fa:	853e                	mv	a0,a5
    800054fc:	70b2                	ld	ra,296(sp)
    800054fe:	7412                	ld	s0,288(sp)
    80005500:	64f2                	ld	s1,280(sp)
    80005502:	6952                	ld	s2,272(sp)
    80005504:	6155                	addi	sp,sp,304
    80005506:	8082                	ret

0000000080005508 <sys_unlink>:
{
    80005508:	7151                	addi	sp,sp,-240
    8000550a:	f586                	sd	ra,232(sp)
    8000550c:	f1a2                	sd	s0,224(sp)
    8000550e:	eda6                	sd	s1,216(sp)
    80005510:	e9ca                	sd	s2,208(sp)
    80005512:	e5ce                	sd	s3,200(sp)
    80005514:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005516:	08000613          	li	a2,128
    8000551a:	f3040593          	addi	a1,s0,-208
    8000551e:	4501                	li	a0,0
    80005520:	ffffd097          	auipc	ra,0xffffd
    80005524:	690080e7          	jalr	1680(ra) # 80002bb0 <argstr>
    80005528:	18054163          	bltz	a0,800056aa <sys_unlink+0x1a2>
  begin_op();
    8000552c:	fffff097          	auipc	ra,0xfffff
    80005530:	bd0080e7          	jalr	-1072(ra) # 800040fc <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005534:	fb040593          	addi	a1,s0,-80
    80005538:	f3040513          	addi	a0,s0,-208
    8000553c:	fffff097          	auipc	ra,0xfffff
    80005540:	9be080e7          	jalr	-1602(ra) # 80003efa <nameiparent>
    80005544:	84aa                	mv	s1,a0
    80005546:	c979                	beqz	a0,8000561c <sys_unlink+0x114>
  ilock(dp);
    80005548:	ffffe097          	auipc	ra,0xffffe
    8000554c:	1e8080e7          	jalr	488(ra) # 80003730 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005550:	00003597          	auipc	a1,0x3
    80005554:	20858593          	addi	a1,a1,520 # 80008758 <syscalls+0x2c8>
    80005558:	fb040513          	addi	a0,s0,-80
    8000555c:	ffffe097          	auipc	ra,0xffffe
    80005560:	69e080e7          	jalr	1694(ra) # 80003bfa <namecmp>
    80005564:	14050a63          	beqz	a0,800056b8 <sys_unlink+0x1b0>
    80005568:	00003597          	auipc	a1,0x3
    8000556c:	1f858593          	addi	a1,a1,504 # 80008760 <syscalls+0x2d0>
    80005570:	fb040513          	addi	a0,s0,-80
    80005574:	ffffe097          	auipc	ra,0xffffe
    80005578:	686080e7          	jalr	1670(ra) # 80003bfa <namecmp>
    8000557c:	12050e63          	beqz	a0,800056b8 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005580:	f2c40613          	addi	a2,s0,-212
    80005584:	fb040593          	addi	a1,s0,-80
    80005588:	8526                	mv	a0,s1
    8000558a:	ffffe097          	auipc	ra,0xffffe
    8000558e:	68a080e7          	jalr	1674(ra) # 80003c14 <dirlookup>
    80005592:	892a                	mv	s2,a0
    80005594:	12050263          	beqz	a0,800056b8 <sys_unlink+0x1b0>
  ilock(ip);
    80005598:	ffffe097          	auipc	ra,0xffffe
    8000559c:	198080e7          	jalr	408(ra) # 80003730 <ilock>
  if(ip->nlink < 1)
    800055a0:	04a91783          	lh	a5,74(s2)
    800055a4:	08f05263          	blez	a5,80005628 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800055a8:	04491703          	lh	a4,68(s2)
    800055ac:	4785                	li	a5,1
    800055ae:	08f70563          	beq	a4,a5,80005638 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800055b2:	4641                	li	a2,16
    800055b4:	4581                	li	a1,0
    800055b6:	fc040513          	addi	a0,s0,-64
    800055ba:	ffffb097          	auipc	ra,0xffffb
    800055be:	718080e7          	jalr	1816(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055c2:	4741                	li	a4,16
    800055c4:	f2c42683          	lw	a3,-212(s0)
    800055c8:	fc040613          	addi	a2,s0,-64
    800055cc:	4581                	li	a1,0
    800055ce:	8526                	mv	a0,s1
    800055d0:	ffffe097          	auipc	ra,0xffffe
    800055d4:	50c080e7          	jalr	1292(ra) # 80003adc <writei>
    800055d8:	47c1                	li	a5,16
    800055da:	0af51563          	bne	a0,a5,80005684 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800055de:	04491703          	lh	a4,68(s2)
    800055e2:	4785                	li	a5,1
    800055e4:	0af70863          	beq	a4,a5,80005694 <sys_unlink+0x18c>
  iunlockput(dp);
    800055e8:	8526                	mv	a0,s1
    800055ea:	ffffe097          	auipc	ra,0xffffe
    800055ee:	3a8080e7          	jalr	936(ra) # 80003992 <iunlockput>
  ip->nlink--;
    800055f2:	04a95783          	lhu	a5,74(s2)
    800055f6:	37fd                	addiw	a5,a5,-1
    800055f8:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800055fc:	854a                	mv	a0,s2
    800055fe:	ffffe097          	auipc	ra,0xffffe
    80005602:	066080e7          	jalr	102(ra) # 80003664 <iupdate>
  iunlockput(ip);
    80005606:	854a                	mv	a0,s2
    80005608:	ffffe097          	auipc	ra,0xffffe
    8000560c:	38a080e7          	jalr	906(ra) # 80003992 <iunlockput>
  end_op();
    80005610:	fffff097          	auipc	ra,0xfffff
    80005614:	b6a080e7          	jalr	-1174(ra) # 8000417a <end_op>
  return 0;
    80005618:	4501                	li	a0,0
    8000561a:	a84d                	j	800056cc <sys_unlink+0x1c4>
    end_op();
    8000561c:	fffff097          	auipc	ra,0xfffff
    80005620:	b5e080e7          	jalr	-1186(ra) # 8000417a <end_op>
    return -1;
    80005624:	557d                	li	a0,-1
    80005626:	a05d                	j	800056cc <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005628:	00003517          	auipc	a0,0x3
    8000562c:	14050513          	addi	a0,a0,320 # 80008768 <syscalls+0x2d8>
    80005630:	ffffb097          	auipc	ra,0xffffb
    80005634:	f10080e7          	jalr	-240(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005638:	04c92703          	lw	a4,76(s2)
    8000563c:	02000793          	li	a5,32
    80005640:	f6e7f9e3          	bgeu	a5,a4,800055b2 <sys_unlink+0xaa>
    80005644:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005648:	4741                	li	a4,16
    8000564a:	86ce                	mv	a3,s3
    8000564c:	f1840613          	addi	a2,s0,-232
    80005650:	4581                	li	a1,0
    80005652:	854a                	mv	a0,s2
    80005654:	ffffe097          	auipc	ra,0xffffe
    80005658:	390080e7          	jalr	912(ra) # 800039e4 <readi>
    8000565c:	47c1                	li	a5,16
    8000565e:	00f51b63          	bne	a0,a5,80005674 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005662:	f1845783          	lhu	a5,-232(s0)
    80005666:	e7a1                	bnez	a5,800056ae <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005668:	29c1                	addiw	s3,s3,16
    8000566a:	04c92783          	lw	a5,76(s2)
    8000566e:	fcf9ede3          	bltu	s3,a5,80005648 <sys_unlink+0x140>
    80005672:	b781                	j	800055b2 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005674:	00003517          	auipc	a0,0x3
    80005678:	10c50513          	addi	a0,a0,268 # 80008780 <syscalls+0x2f0>
    8000567c:	ffffb097          	auipc	ra,0xffffb
    80005680:	ec4080e7          	jalr	-316(ra) # 80000540 <panic>
    panic("unlink: writei");
    80005684:	00003517          	auipc	a0,0x3
    80005688:	11450513          	addi	a0,a0,276 # 80008798 <syscalls+0x308>
    8000568c:	ffffb097          	auipc	ra,0xffffb
    80005690:	eb4080e7          	jalr	-332(ra) # 80000540 <panic>
    dp->nlink--;
    80005694:	04a4d783          	lhu	a5,74(s1)
    80005698:	37fd                	addiw	a5,a5,-1
    8000569a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000569e:	8526                	mv	a0,s1
    800056a0:	ffffe097          	auipc	ra,0xffffe
    800056a4:	fc4080e7          	jalr	-60(ra) # 80003664 <iupdate>
    800056a8:	b781                	j	800055e8 <sys_unlink+0xe0>
    return -1;
    800056aa:	557d                	li	a0,-1
    800056ac:	a005                	j	800056cc <sys_unlink+0x1c4>
    iunlockput(ip);
    800056ae:	854a                	mv	a0,s2
    800056b0:	ffffe097          	auipc	ra,0xffffe
    800056b4:	2e2080e7          	jalr	738(ra) # 80003992 <iunlockput>
  iunlockput(dp);
    800056b8:	8526                	mv	a0,s1
    800056ba:	ffffe097          	auipc	ra,0xffffe
    800056be:	2d8080e7          	jalr	728(ra) # 80003992 <iunlockput>
  end_op();
    800056c2:	fffff097          	auipc	ra,0xfffff
    800056c6:	ab8080e7          	jalr	-1352(ra) # 8000417a <end_op>
  return -1;
    800056ca:	557d                	li	a0,-1
}
    800056cc:	70ae                	ld	ra,232(sp)
    800056ce:	740e                	ld	s0,224(sp)
    800056d0:	64ee                	ld	s1,216(sp)
    800056d2:	694e                	ld	s2,208(sp)
    800056d4:	69ae                	ld	s3,200(sp)
    800056d6:	616d                	addi	sp,sp,240
    800056d8:	8082                	ret

00000000800056da <sys_open>:

uint64
sys_open(void)
{
    800056da:	7131                	addi	sp,sp,-192
    800056dc:	fd06                	sd	ra,184(sp)
    800056de:	f922                	sd	s0,176(sp)
    800056e0:	f526                	sd	s1,168(sp)
    800056e2:	f14a                	sd	s2,160(sp)
    800056e4:	ed4e                	sd	s3,152(sp)
    800056e6:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800056e8:	f4c40593          	addi	a1,s0,-180
    800056ec:	4505                	li	a0,1
    800056ee:	ffffd097          	auipc	ra,0xffffd
    800056f2:	482080e7          	jalr	1154(ra) # 80002b70 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800056f6:	08000613          	li	a2,128
    800056fa:	f5040593          	addi	a1,s0,-176
    800056fe:	4501                	li	a0,0
    80005700:	ffffd097          	auipc	ra,0xffffd
    80005704:	4b0080e7          	jalr	1200(ra) # 80002bb0 <argstr>
    80005708:	87aa                	mv	a5,a0
    return -1;
    8000570a:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000570c:	0a07c963          	bltz	a5,800057be <sys_open+0xe4>

  begin_op();
    80005710:	fffff097          	auipc	ra,0xfffff
    80005714:	9ec080e7          	jalr	-1556(ra) # 800040fc <begin_op>

  if(omode & O_CREATE){
    80005718:	f4c42783          	lw	a5,-180(s0)
    8000571c:	2007f793          	andi	a5,a5,512
    80005720:	cfc5                	beqz	a5,800057d8 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005722:	4681                	li	a3,0
    80005724:	4601                	li	a2,0
    80005726:	4589                	li	a1,2
    80005728:	f5040513          	addi	a0,s0,-176
    8000572c:	00000097          	auipc	ra,0x0
    80005730:	972080e7          	jalr	-1678(ra) # 8000509e <create>
    80005734:	84aa                	mv	s1,a0
    if(ip == 0){
    80005736:	c959                	beqz	a0,800057cc <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005738:	04449703          	lh	a4,68(s1)
    8000573c:	478d                	li	a5,3
    8000573e:	00f71763          	bne	a4,a5,8000574c <sys_open+0x72>
    80005742:	0464d703          	lhu	a4,70(s1)
    80005746:	47a5                	li	a5,9
    80005748:	0ce7ed63          	bltu	a5,a4,80005822 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000574c:	fffff097          	auipc	ra,0xfffff
    80005750:	dbc080e7          	jalr	-580(ra) # 80004508 <filealloc>
    80005754:	89aa                	mv	s3,a0
    80005756:	10050363          	beqz	a0,8000585c <sys_open+0x182>
    8000575a:	00000097          	auipc	ra,0x0
    8000575e:	902080e7          	jalr	-1790(ra) # 8000505c <fdalloc>
    80005762:	892a                	mv	s2,a0
    80005764:	0e054763          	bltz	a0,80005852 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005768:	04449703          	lh	a4,68(s1)
    8000576c:	478d                	li	a5,3
    8000576e:	0cf70563          	beq	a4,a5,80005838 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005772:	4789                	li	a5,2
    80005774:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005778:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000577c:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005780:	f4c42783          	lw	a5,-180(s0)
    80005784:	0017c713          	xori	a4,a5,1
    80005788:	8b05                	andi	a4,a4,1
    8000578a:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000578e:	0037f713          	andi	a4,a5,3
    80005792:	00e03733          	snez	a4,a4
    80005796:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000579a:	4007f793          	andi	a5,a5,1024
    8000579e:	c791                	beqz	a5,800057aa <sys_open+0xd0>
    800057a0:	04449703          	lh	a4,68(s1)
    800057a4:	4789                	li	a5,2
    800057a6:	0af70063          	beq	a4,a5,80005846 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800057aa:	8526                	mv	a0,s1
    800057ac:	ffffe097          	auipc	ra,0xffffe
    800057b0:	046080e7          	jalr	70(ra) # 800037f2 <iunlock>
  end_op();
    800057b4:	fffff097          	auipc	ra,0xfffff
    800057b8:	9c6080e7          	jalr	-1594(ra) # 8000417a <end_op>

  return fd;
    800057bc:	854a                	mv	a0,s2
}
    800057be:	70ea                	ld	ra,184(sp)
    800057c0:	744a                	ld	s0,176(sp)
    800057c2:	74aa                	ld	s1,168(sp)
    800057c4:	790a                	ld	s2,160(sp)
    800057c6:	69ea                	ld	s3,152(sp)
    800057c8:	6129                	addi	sp,sp,192
    800057ca:	8082                	ret
      end_op();
    800057cc:	fffff097          	auipc	ra,0xfffff
    800057d0:	9ae080e7          	jalr	-1618(ra) # 8000417a <end_op>
      return -1;
    800057d4:	557d                	li	a0,-1
    800057d6:	b7e5                	j	800057be <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800057d8:	f5040513          	addi	a0,s0,-176
    800057dc:	ffffe097          	auipc	ra,0xffffe
    800057e0:	700080e7          	jalr	1792(ra) # 80003edc <namei>
    800057e4:	84aa                	mv	s1,a0
    800057e6:	c905                	beqz	a0,80005816 <sys_open+0x13c>
    ilock(ip);
    800057e8:	ffffe097          	auipc	ra,0xffffe
    800057ec:	f48080e7          	jalr	-184(ra) # 80003730 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800057f0:	04449703          	lh	a4,68(s1)
    800057f4:	4785                	li	a5,1
    800057f6:	f4f711e3          	bne	a4,a5,80005738 <sys_open+0x5e>
    800057fa:	f4c42783          	lw	a5,-180(s0)
    800057fe:	d7b9                	beqz	a5,8000574c <sys_open+0x72>
      iunlockput(ip);
    80005800:	8526                	mv	a0,s1
    80005802:	ffffe097          	auipc	ra,0xffffe
    80005806:	190080e7          	jalr	400(ra) # 80003992 <iunlockput>
      end_op();
    8000580a:	fffff097          	auipc	ra,0xfffff
    8000580e:	970080e7          	jalr	-1680(ra) # 8000417a <end_op>
      return -1;
    80005812:	557d                	li	a0,-1
    80005814:	b76d                	j	800057be <sys_open+0xe4>
      end_op();
    80005816:	fffff097          	auipc	ra,0xfffff
    8000581a:	964080e7          	jalr	-1692(ra) # 8000417a <end_op>
      return -1;
    8000581e:	557d                	li	a0,-1
    80005820:	bf79                	j	800057be <sys_open+0xe4>
    iunlockput(ip);
    80005822:	8526                	mv	a0,s1
    80005824:	ffffe097          	auipc	ra,0xffffe
    80005828:	16e080e7          	jalr	366(ra) # 80003992 <iunlockput>
    end_op();
    8000582c:	fffff097          	auipc	ra,0xfffff
    80005830:	94e080e7          	jalr	-1714(ra) # 8000417a <end_op>
    return -1;
    80005834:	557d                	li	a0,-1
    80005836:	b761                	j	800057be <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005838:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000583c:	04649783          	lh	a5,70(s1)
    80005840:	02f99223          	sh	a5,36(s3)
    80005844:	bf25                	j	8000577c <sys_open+0xa2>
    itrunc(ip);
    80005846:	8526                	mv	a0,s1
    80005848:	ffffe097          	auipc	ra,0xffffe
    8000584c:	ff6080e7          	jalr	-10(ra) # 8000383e <itrunc>
    80005850:	bfa9                	j	800057aa <sys_open+0xd0>
      fileclose(f);
    80005852:	854e                	mv	a0,s3
    80005854:	fffff097          	auipc	ra,0xfffff
    80005858:	d70080e7          	jalr	-656(ra) # 800045c4 <fileclose>
    iunlockput(ip);
    8000585c:	8526                	mv	a0,s1
    8000585e:	ffffe097          	auipc	ra,0xffffe
    80005862:	134080e7          	jalr	308(ra) # 80003992 <iunlockput>
    end_op();
    80005866:	fffff097          	auipc	ra,0xfffff
    8000586a:	914080e7          	jalr	-1772(ra) # 8000417a <end_op>
    return -1;
    8000586e:	557d                	li	a0,-1
    80005870:	b7b9                	j	800057be <sys_open+0xe4>

0000000080005872 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005872:	7175                	addi	sp,sp,-144
    80005874:	e506                	sd	ra,136(sp)
    80005876:	e122                	sd	s0,128(sp)
    80005878:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000587a:	fffff097          	auipc	ra,0xfffff
    8000587e:	882080e7          	jalr	-1918(ra) # 800040fc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005882:	08000613          	li	a2,128
    80005886:	f7040593          	addi	a1,s0,-144
    8000588a:	4501                	li	a0,0
    8000588c:	ffffd097          	auipc	ra,0xffffd
    80005890:	324080e7          	jalr	804(ra) # 80002bb0 <argstr>
    80005894:	02054963          	bltz	a0,800058c6 <sys_mkdir+0x54>
    80005898:	4681                	li	a3,0
    8000589a:	4601                	li	a2,0
    8000589c:	4585                	li	a1,1
    8000589e:	f7040513          	addi	a0,s0,-144
    800058a2:	fffff097          	auipc	ra,0xfffff
    800058a6:	7fc080e7          	jalr	2044(ra) # 8000509e <create>
    800058aa:	cd11                	beqz	a0,800058c6 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058ac:	ffffe097          	auipc	ra,0xffffe
    800058b0:	0e6080e7          	jalr	230(ra) # 80003992 <iunlockput>
  end_op();
    800058b4:	fffff097          	auipc	ra,0xfffff
    800058b8:	8c6080e7          	jalr	-1850(ra) # 8000417a <end_op>
  return 0;
    800058bc:	4501                	li	a0,0
}
    800058be:	60aa                	ld	ra,136(sp)
    800058c0:	640a                	ld	s0,128(sp)
    800058c2:	6149                	addi	sp,sp,144
    800058c4:	8082                	ret
    end_op();
    800058c6:	fffff097          	auipc	ra,0xfffff
    800058ca:	8b4080e7          	jalr	-1868(ra) # 8000417a <end_op>
    return -1;
    800058ce:	557d                	li	a0,-1
    800058d0:	b7fd                	j	800058be <sys_mkdir+0x4c>

00000000800058d2 <sys_mknod>:

uint64
sys_mknod(void)
{
    800058d2:	7135                	addi	sp,sp,-160
    800058d4:	ed06                	sd	ra,152(sp)
    800058d6:	e922                	sd	s0,144(sp)
    800058d8:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800058da:	fffff097          	auipc	ra,0xfffff
    800058de:	822080e7          	jalr	-2014(ra) # 800040fc <begin_op>
  argint(1, &major);
    800058e2:	f6c40593          	addi	a1,s0,-148
    800058e6:	4505                	li	a0,1
    800058e8:	ffffd097          	auipc	ra,0xffffd
    800058ec:	288080e7          	jalr	648(ra) # 80002b70 <argint>
  argint(2, &minor);
    800058f0:	f6840593          	addi	a1,s0,-152
    800058f4:	4509                	li	a0,2
    800058f6:	ffffd097          	auipc	ra,0xffffd
    800058fa:	27a080e7          	jalr	634(ra) # 80002b70 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058fe:	08000613          	li	a2,128
    80005902:	f7040593          	addi	a1,s0,-144
    80005906:	4501                	li	a0,0
    80005908:	ffffd097          	auipc	ra,0xffffd
    8000590c:	2a8080e7          	jalr	680(ra) # 80002bb0 <argstr>
    80005910:	02054b63          	bltz	a0,80005946 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005914:	f6841683          	lh	a3,-152(s0)
    80005918:	f6c41603          	lh	a2,-148(s0)
    8000591c:	458d                	li	a1,3
    8000591e:	f7040513          	addi	a0,s0,-144
    80005922:	fffff097          	auipc	ra,0xfffff
    80005926:	77c080e7          	jalr	1916(ra) # 8000509e <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000592a:	cd11                	beqz	a0,80005946 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000592c:	ffffe097          	auipc	ra,0xffffe
    80005930:	066080e7          	jalr	102(ra) # 80003992 <iunlockput>
  end_op();
    80005934:	fffff097          	auipc	ra,0xfffff
    80005938:	846080e7          	jalr	-1978(ra) # 8000417a <end_op>
  return 0;
    8000593c:	4501                	li	a0,0
}
    8000593e:	60ea                	ld	ra,152(sp)
    80005940:	644a                	ld	s0,144(sp)
    80005942:	610d                	addi	sp,sp,160
    80005944:	8082                	ret
    end_op();
    80005946:	fffff097          	auipc	ra,0xfffff
    8000594a:	834080e7          	jalr	-1996(ra) # 8000417a <end_op>
    return -1;
    8000594e:	557d                	li	a0,-1
    80005950:	b7fd                	j	8000593e <sys_mknod+0x6c>

0000000080005952 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005952:	7135                	addi	sp,sp,-160
    80005954:	ed06                	sd	ra,152(sp)
    80005956:	e922                	sd	s0,144(sp)
    80005958:	e526                	sd	s1,136(sp)
    8000595a:	e14a                	sd	s2,128(sp)
    8000595c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000595e:	ffffc097          	auipc	ra,0xffffc
    80005962:	04e080e7          	jalr	78(ra) # 800019ac <myproc>
    80005966:	892a                	mv	s2,a0
  
  begin_op();
    80005968:	ffffe097          	auipc	ra,0xffffe
    8000596c:	794080e7          	jalr	1940(ra) # 800040fc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005970:	08000613          	li	a2,128
    80005974:	f6040593          	addi	a1,s0,-160
    80005978:	4501                	li	a0,0
    8000597a:	ffffd097          	auipc	ra,0xffffd
    8000597e:	236080e7          	jalr	566(ra) # 80002bb0 <argstr>
    80005982:	04054b63          	bltz	a0,800059d8 <sys_chdir+0x86>
    80005986:	f6040513          	addi	a0,s0,-160
    8000598a:	ffffe097          	auipc	ra,0xffffe
    8000598e:	552080e7          	jalr	1362(ra) # 80003edc <namei>
    80005992:	84aa                	mv	s1,a0
    80005994:	c131                	beqz	a0,800059d8 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005996:	ffffe097          	auipc	ra,0xffffe
    8000599a:	d9a080e7          	jalr	-614(ra) # 80003730 <ilock>
  if(ip->type != T_DIR){
    8000599e:	04449703          	lh	a4,68(s1)
    800059a2:	4785                	li	a5,1
    800059a4:	04f71063          	bne	a4,a5,800059e4 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800059a8:	8526                	mv	a0,s1
    800059aa:	ffffe097          	auipc	ra,0xffffe
    800059ae:	e48080e7          	jalr	-440(ra) # 800037f2 <iunlock>
  iput(p->cwd);
    800059b2:	15093503          	ld	a0,336(s2)
    800059b6:	ffffe097          	auipc	ra,0xffffe
    800059ba:	f34080e7          	jalr	-204(ra) # 800038ea <iput>
  end_op();
    800059be:	ffffe097          	auipc	ra,0xffffe
    800059c2:	7bc080e7          	jalr	1980(ra) # 8000417a <end_op>
  p->cwd = ip;
    800059c6:	14993823          	sd	s1,336(s2)
  return 0;
    800059ca:	4501                	li	a0,0
}
    800059cc:	60ea                	ld	ra,152(sp)
    800059ce:	644a                	ld	s0,144(sp)
    800059d0:	64aa                	ld	s1,136(sp)
    800059d2:	690a                	ld	s2,128(sp)
    800059d4:	610d                	addi	sp,sp,160
    800059d6:	8082                	ret
    end_op();
    800059d8:	ffffe097          	auipc	ra,0xffffe
    800059dc:	7a2080e7          	jalr	1954(ra) # 8000417a <end_op>
    return -1;
    800059e0:	557d                	li	a0,-1
    800059e2:	b7ed                	j	800059cc <sys_chdir+0x7a>
    iunlockput(ip);
    800059e4:	8526                	mv	a0,s1
    800059e6:	ffffe097          	auipc	ra,0xffffe
    800059ea:	fac080e7          	jalr	-84(ra) # 80003992 <iunlockput>
    end_op();
    800059ee:	ffffe097          	auipc	ra,0xffffe
    800059f2:	78c080e7          	jalr	1932(ra) # 8000417a <end_op>
    return -1;
    800059f6:	557d                	li	a0,-1
    800059f8:	bfd1                	j	800059cc <sys_chdir+0x7a>

00000000800059fa <sys_exec>:

uint64
sys_exec(void)
{
    800059fa:	7145                	addi	sp,sp,-464
    800059fc:	e786                	sd	ra,456(sp)
    800059fe:	e3a2                	sd	s0,448(sp)
    80005a00:	ff26                	sd	s1,440(sp)
    80005a02:	fb4a                	sd	s2,432(sp)
    80005a04:	f74e                	sd	s3,424(sp)
    80005a06:	f352                	sd	s4,416(sp)
    80005a08:	ef56                	sd	s5,408(sp)
    80005a0a:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005a0c:	e3840593          	addi	a1,s0,-456
    80005a10:	4505                	li	a0,1
    80005a12:	ffffd097          	auipc	ra,0xffffd
    80005a16:	17e080e7          	jalr	382(ra) # 80002b90 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005a1a:	08000613          	li	a2,128
    80005a1e:	f4040593          	addi	a1,s0,-192
    80005a22:	4501                	li	a0,0
    80005a24:	ffffd097          	auipc	ra,0xffffd
    80005a28:	18c080e7          	jalr	396(ra) # 80002bb0 <argstr>
    80005a2c:	87aa                	mv	a5,a0
    return -1;
    80005a2e:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005a30:	0c07c363          	bltz	a5,80005af6 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005a34:	10000613          	li	a2,256
    80005a38:	4581                	li	a1,0
    80005a3a:	e4040513          	addi	a0,s0,-448
    80005a3e:	ffffb097          	auipc	ra,0xffffb
    80005a42:	294080e7          	jalr	660(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a46:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a4a:	89a6                	mv	s3,s1
    80005a4c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a4e:	02000a13          	li	s4,32
    80005a52:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a56:	00391513          	slli	a0,s2,0x3
    80005a5a:	e3040593          	addi	a1,s0,-464
    80005a5e:	e3843783          	ld	a5,-456(s0)
    80005a62:	953e                	add	a0,a0,a5
    80005a64:	ffffd097          	auipc	ra,0xffffd
    80005a68:	06e080e7          	jalr	110(ra) # 80002ad2 <fetchaddr>
    80005a6c:	02054a63          	bltz	a0,80005aa0 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005a70:	e3043783          	ld	a5,-464(s0)
    80005a74:	c3b9                	beqz	a5,80005aba <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005a76:	ffffb097          	auipc	ra,0xffffb
    80005a7a:	070080e7          	jalr	112(ra) # 80000ae6 <kalloc>
    80005a7e:	85aa                	mv	a1,a0
    80005a80:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005a84:	cd11                	beqz	a0,80005aa0 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005a86:	6605                	lui	a2,0x1
    80005a88:	e3043503          	ld	a0,-464(s0)
    80005a8c:	ffffd097          	auipc	ra,0xffffd
    80005a90:	098080e7          	jalr	152(ra) # 80002b24 <fetchstr>
    80005a94:	00054663          	bltz	a0,80005aa0 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005a98:	0905                	addi	s2,s2,1
    80005a9a:	09a1                	addi	s3,s3,8
    80005a9c:	fb491be3          	bne	s2,s4,80005a52 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005aa0:	f4040913          	addi	s2,s0,-192
    80005aa4:	6088                	ld	a0,0(s1)
    80005aa6:	c539                	beqz	a0,80005af4 <sys_exec+0xfa>
    kfree(argv[i]);
    80005aa8:	ffffb097          	auipc	ra,0xffffb
    80005aac:	f40080e7          	jalr	-192(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ab0:	04a1                	addi	s1,s1,8
    80005ab2:	ff2499e3          	bne	s1,s2,80005aa4 <sys_exec+0xaa>
  return -1;
    80005ab6:	557d                	li	a0,-1
    80005ab8:	a83d                	j	80005af6 <sys_exec+0xfc>
      argv[i] = 0;
    80005aba:	0a8e                	slli	s5,s5,0x3
    80005abc:	fc0a8793          	addi	a5,s5,-64
    80005ac0:	00878ab3          	add	s5,a5,s0
    80005ac4:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005ac8:	e4040593          	addi	a1,s0,-448
    80005acc:	f4040513          	addi	a0,s0,-192
    80005ad0:	fffff097          	auipc	ra,0xfffff
    80005ad4:	16e080e7          	jalr	366(ra) # 80004c3e <exec>
    80005ad8:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ada:	f4040993          	addi	s3,s0,-192
    80005ade:	6088                	ld	a0,0(s1)
    80005ae0:	c901                	beqz	a0,80005af0 <sys_exec+0xf6>
    kfree(argv[i]);
    80005ae2:	ffffb097          	auipc	ra,0xffffb
    80005ae6:	f06080e7          	jalr	-250(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005aea:	04a1                	addi	s1,s1,8
    80005aec:	ff3499e3          	bne	s1,s3,80005ade <sys_exec+0xe4>
  return ret;
    80005af0:	854a                	mv	a0,s2
    80005af2:	a011                	j	80005af6 <sys_exec+0xfc>
  return -1;
    80005af4:	557d                	li	a0,-1
}
    80005af6:	60be                	ld	ra,456(sp)
    80005af8:	641e                	ld	s0,448(sp)
    80005afa:	74fa                	ld	s1,440(sp)
    80005afc:	795a                	ld	s2,432(sp)
    80005afe:	79ba                	ld	s3,424(sp)
    80005b00:	7a1a                	ld	s4,416(sp)
    80005b02:	6afa                	ld	s5,408(sp)
    80005b04:	6179                	addi	sp,sp,464
    80005b06:	8082                	ret

0000000080005b08 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b08:	7139                	addi	sp,sp,-64
    80005b0a:	fc06                	sd	ra,56(sp)
    80005b0c:	f822                	sd	s0,48(sp)
    80005b0e:	f426                	sd	s1,40(sp)
    80005b10:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b12:	ffffc097          	auipc	ra,0xffffc
    80005b16:	e9a080e7          	jalr	-358(ra) # 800019ac <myproc>
    80005b1a:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005b1c:	fd840593          	addi	a1,s0,-40
    80005b20:	4501                	li	a0,0
    80005b22:	ffffd097          	auipc	ra,0xffffd
    80005b26:	06e080e7          	jalr	110(ra) # 80002b90 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005b2a:	fc840593          	addi	a1,s0,-56
    80005b2e:	fd040513          	addi	a0,s0,-48
    80005b32:	fffff097          	auipc	ra,0xfffff
    80005b36:	dc2080e7          	jalr	-574(ra) # 800048f4 <pipealloc>
    return -1;
    80005b3a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b3c:	0c054463          	bltz	a0,80005c04 <sys_pipe+0xfc>
  fd0 = -1;
    80005b40:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b44:	fd043503          	ld	a0,-48(s0)
    80005b48:	fffff097          	auipc	ra,0xfffff
    80005b4c:	514080e7          	jalr	1300(ra) # 8000505c <fdalloc>
    80005b50:	fca42223          	sw	a0,-60(s0)
    80005b54:	08054b63          	bltz	a0,80005bea <sys_pipe+0xe2>
    80005b58:	fc843503          	ld	a0,-56(s0)
    80005b5c:	fffff097          	auipc	ra,0xfffff
    80005b60:	500080e7          	jalr	1280(ra) # 8000505c <fdalloc>
    80005b64:	fca42023          	sw	a0,-64(s0)
    80005b68:	06054863          	bltz	a0,80005bd8 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b6c:	4691                	li	a3,4
    80005b6e:	fc440613          	addi	a2,s0,-60
    80005b72:	fd843583          	ld	a1,-40(s0)
    80005b76:	68a8                	ld	a0,80(s1)
    80005b78:	ffffc097          	auipc	ra,0xffffc
    80005b7c:	af4080e7          	jalr	-1292(ra) # 8000166c <copyout>
    80005b80:	02054063          	bltz	a0,80005ba0 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005b84:	4691                	li	a3,4
    80005b86:	fc040613          	addi	a2,s0,-64
    80005b8a:	fd843583          	ld	a1,-40(s0)
    80005b8e:	0591                	addi	a1,a1,4
    80005b90:	68a8                	ld	a0,80(s1)
    80005b92:	ffffc097          	auipc	ra,0xffffc
    80005b96:	ada080e7          	jalr	-1318(ra) # 8000166c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005b9a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b9c:	06055463          	bgez	a0,80005c04 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005ba0:	fc442783          	lw	a5,-60(s0)
    80005ba4:	07e9                	addi	a5,a5,26
    80005ba6:	078e                	slli	a5,a5,0x3
    80005ba8:	97a6                	add	a5,a5,s1
    80005baa:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005bae:	fc042783          	lw	a5,-64(s0)
    80005bb2:	07e9                	addi	a5,a5,26
    80005bb4:	078e                	slli	a5,a5,0x3
    80005bb6:	94be                	add	s1,s1,a5
    80005bb8:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005bbc:	fd043503          	ld	a0,-48(s0)
    80005bc0:	fffff097          	auipc	ra,0xfffff
    80005bc4:	a04080e7          	jalr	-1532(ra) # 800045c4 <fileclose>
    fileclose(wf);
    80005bc8:	fc843503          	ld	a0,-56(s0)
    80005bcc:	fffff097          	auipc	ra,0xfffff
    80005bd0:	9f8080e7          	jalr	-1544(ra) # 800045c4 <fileclose>
    return -1;
    80005bd4:	57fd                	li	a5,-1
    80005bd6:	a03d                	j	80005c04 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005bd8:	fc442783          	lw	a5,-60(s0)
    80005bdc:	0007c763          	bltz	a5,80005bea <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005be0:	07e9                	addi	a5,a5,26
    80005be2:	078e                	slli	a5,a5,0x3
    80005be4:	97a6                	add	a5,a5,s1
    80005be6:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005bea:	fd043503          	ld	a0,-48(s0)
    80005bee:	fffff097          	auipc	ra,0xfffff
    80005bf2:	9d6080e7          	jalr	-1578(ra) # 800045c4 <fileclose>
    fileclose(wf);
    80005bf6:	fc843503          	ld	a0,-56(s0)
    80005bfa:	fffff097          	auipc	ra,0xfffff
    80005bfe:	9ca080e7          	jalr	-1590(ra) # 800045c4 <fileclose>
    return -1;
    80005c02:	57fd                	li	a5,-1
}
    80005c04:	853e                	mv	a0,a5
    80005c06:	70e2                	ld	ra,56(sp)
    80005c08:	7442                	ld	s0,48(sp)
    80005c0a:	74a2                	ld	s1,40(sp)
    80005c0c:	6121                	addi	sp,sp,64
    80005c0e:	8082                	ret

0000000080005c10 <kernelvec>:
    80005c10:	7111                	addi	sp,sp,-256
    80005c12:	e006                	sd	ra,0(sp)
    80005c14:	e40a                	sd	sp,8(sp)
    80005c16:	e80e                	sd	gp,16(sp)
    80005c18:	ec12                	sd	tp,24(sp)
    80005c1a:	f016                	sd	t0,32(sp)
    80005c1c:	f41a                	sd	t1,40(sp)
    80005c1e:	f81e                	sd	t2,48(sp)
    80005c20:	fc22                	sd	s0,56(sp)
    80005c22:	e0a6                	sd	s1,64(sp)
    80005c24:	e4aa                	sd	a0,72(sp)
    80005c26:	e8ae                	sd	a1,80(sp)
    80005c28:	ecb2                	sd	a2,88(sp)
    80005c2a:	f0b6                	sd	a3,96(sp)
    80005c2c:	f4ba                	sd	a4,104(sp)
    80005c2e:	f8be                	sd	a5,112(sp)
    80005c30:	fcc2                	sd	a6,120(sp)
    80005c32:	e146                	sd	a7,128(sp)
    80005c34:	e54a                	sd	s2,136(sp)
    80005c36:	e94e                	sd	s3,144(sp)
    80005c38:	ed52                	sd	s4,152(sp)
    80005c3a:	f156                	sd	s5,160(sp)
    80005c3c:	f55a                	sd	s6,168(sp)
    80005c3e:	f95e                	sd	s7,176(sp)
    80005c40:	fd62                	sd	s8,184(sp)
    80005c42:	e1e6                	sd	s9,192(sp)
    80005c44:	e5ea                	sd	s10,200(sp)
    80005c46:	e9ee                	sd	s11,208(sp)
    80005c48:	edf2                	sd	t3,216(sp)
    80005c4a:	f1f6                	sd	t4,224(sp)
    80005c4c:	f5fa                	sd	t5,232(sp)
    80005c4e:	f9fe                	sd	t6,240(sp)
    80005c50:	d4ffc0ef          	jal	ra,8000299e <kerneltrap>
    80005c54:	6082                	ld	ra,0(sp)
    80005c56:	6122                	ld	sp,8(sp)
    80005c58:	61c2                	ld	gp,16(sp)
    80005c5a:	7282                	ld	t0,32(sp)
    80005c5c:	7322                	ld	t1,40(sp)
    80005c5e:	73c2                	ld	t2,48(sp)
    80005c60:	7462                	ld	s0,56(sp)
    80005c62:	6486                	ld	s1,64(sp)
    80005c64:	6526                	ld	a0,72(sp)
    80005c66:	65c6                	ld	a1,80(sp)
    80005c68:	6666                	ld	a2,88(sp)
    80005c6a:	7686                	ld	a3,96(sp)
    80005c6c:	7726                	ld	a4,104(sp)
    80005c6e:	77c6                	ld	a5,112(sp)
    80005c70:	7866                	ld	a6,120(sp)
    80005c72:	688a                	ld	a7,128(sp)
    80005c74:	692a                	ld	s2,136(sp)
    80005c76:	69ca                	ld	s3,144(sp)
    80005c78:	6a6a                	ld	s4,152(sp)
    80005c7a:	7a8a                	ld	s5,160(sp)
    80005c7c:	7b2a                	ld	s6,168(sp)
    80005c7e:	7bca                	ld	s7,176(sp)
    80005c80:	7c6a                	ld	s8,184(sp)
    80005c82:	6c8e                	ld	s9,192(sp)
    80005c84:	6d2e                	ld	s10,200(sp)
    80005c86:	6dce                	ld	s11,208(sp)
    80005c88:	6e6e                	ld	t3,216(sp)
    80005c8a:	7e8e                	ld	t4,224(sp)
    80005c8c:	7f2e                	ld	t5,232(sp)
    80005c8e:	7fce                	ld	t6,240(sp)
    80005c90:	6111                	addi	sp,sp,256
    80005c92:	10200073          	sret
    80005c96:	00000013          	nop
    80005c9a:	00000013          	nop
    80005c9e:	0001                	nop

0000000080005ca0 <timervec>:
    80005ca0:	34051573          	csrrw	a0,mscratch,a0
    80005ca4:	e10c                	sd	a1,0(a0)
    80005ca6:	e510                	sd	a2,8(a0)
    80005ca8:	e914                	sd	a3,16(a0)
    80005caa:	6d0c                	ld	a1,24(a0)
    80005cac:	7110                	ld	a2,32(a0)
    80005cae:	6194                	ld	a3,0(a1)
    80005cb0:	96b2                	add	a3,a3,a2
    80005cb2:	e194                	sd	a3,0(a1)
    80005cb4:	4589                	li	a1,2
    80005cb6:	14459073          	csrw	sip,a1
    80005cba:	6914                	ld	a3,16(a0)
    80005cbc:	6510                	ld	a2,8(a0)
    80005cbe:	610c                	ld	a1,0(a0)
    80005cc0:	34051573          	csrrw	a0,mscratch,a0
    80005cc4:	30200073          	mret
	...

0000000080005cca <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005cca:	1141                	addi	sp,sp,-16
    80005ccc:	e422                	sd	s0,8(sp)
    80005cce:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005cd0:	0c0007b7          	lui	a5,0xc000
    80005cd4:	4705                	li	a4,1
    80005cd6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005cd8:	c3d8                	sw	a4,4(a5)
}
    80005cda:	6422                	ld	s0,8(sp)
    80005cdc:	0141                	addi	sp,sp,16
    80005cde:	8082                	ret

0000000080005ce0 <plicinithart>:

void
plicinithart(void)
{
    80005ce0:	1141                	addi	sp,sp,-16
    80005ce2:	e406                	sd	ra,8(sp)
    80005ce4:	e022                	sd	s0,0(sp)
    80005ce6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ce8:	ffffc097          	auipc	ra,0xffffc
    80005cec:	c98080e7          	jalr	-872(ra) # 80001980 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005cf0:	0085171b          	slliw	a4,a0,0x8
    80005cf4:	0c0027b7          	lui	a5,0xc002
    80005cf8:	97ba                	add	a5,a5,a4
    80005cfa:	40200713          	li	a4,1026
    80005cfe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d02:	00d5151b          	slliw	a0,a0,0xd
    80005d06:	0c2017b7          	lui	a5,0xc201
    80005d0a:	97aa                	add	a5,a5,a0
    80005d0c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005d10:	60a2                	ld	ra,8(sp)
    80005d12:	6402                	ld	s0,0(sp)
    80005d14:	0141                	addi	sp,sp,16
    80005d16:	8082                	ret

0000000080005d18 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d18:	1141                	addi	sp,sp,-16
    80005d1a:	e406                	sd	ra,8(sp)
    80005d1c:	e022                	sd	s0,0(sp)
    80005d1e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d20:	ffffc097          	auipc	ra,0xffffc
    80005d24:	c60080e7          	jalr	-928(ra) # 80001980 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d28:	00d5151b          	slliw	a0,a0,0xd
    80005d2c:	0c2017b7          	lui	a5,0xc201
    80005d30:	97aa                	add	a5,a5,a0
  return irq;
}
    80005d32:	43c8                	lw	a0,4(a5)
    80005d34:	60a2                	ld	ra,8(sp)
    80005d36:	6402                	ld	s0,0(sp)
    80005d38:	0141                	addi	sp,sp,16
    80005d3a:	8082                	ret

0000000080005d3c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d3c:	1101                	addi	sp,sp,-32
    80005d3e:	ec06                	sd	ra,24(sp)
    80005d40:	e822                	sd	s0,16(sp)
    80005d42:	e426                	sd	s1,8(sp)
    80005d44:	1000                	addi	s0,sp,32
    80005d46:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d48:	ffffc097          	auipc	ra,0xffffc
    80005d4c:	c38080e7          	jalr	-968(ra) # 80001980 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d50:	00d5151b          	slliw	a0,a0,0xd
    80005d54:	0c2017b7          	lui	a5,0xc201
    80005d58:	97aa                	add	a5,a5,a0
    80005d5a:	c3c4                	sw	s1,4(a5)
}
    80005d5c:	60e2                	ld	ra,24(sp)
    80005d5e:	6442                	ld	s0,16(sp)
    80005d60:	64a2                	ld	s1,8(sp)
    80005d62:	6105                	addi	sp,sp,32
    80005d64:	8082                	ret

0000000080005d66 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005d66:	1141                	addi	sp,sp,-16
    80005d68:	e406                	sd	ra,8(sp)
    80005d6a:	e022                	sd	s0,0(sp)
    80005d6c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005d6e:	479d                	li	a5,7
    80005d70:	04a7cc63          	blt	a5,a0,80005dc8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005d74:	0001c797          	auipc	a5,0x1c
    80005d78:	f1c78793          	addi	a5,a5,-228 # 80021c90 <disk>
    80005d7c:	97aa                	add	a5,a5,a0
    80005d7e:	0187c783          	lbu	a5,24(a5)
    80005d82:	ebb9                	bnez	a5,80005dd8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005d84:	00451693          	slli	a3,a0,0x4
    80005d88:	0001c797          	auipc	a5,0x1c
    80005d8c:	f0878793          	addi	a5,a5,-248 # 80021c90 <disk>
    80005d90:	6398                	ld	a4,0(a5)
    80005d92:	9736                	add	a4,a4,a3
    80005d94:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80005d98:	6398                	ld	a4,0(a5)
    80005d9a:	9736                	add	a4,a4,a3
    80005d9c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005da0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005da4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005da8:	97aa                	add	a5,a5,a0
    80005daa:	4705                	li	a4,1
    80005dac:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80005db0:	0001c517          	auipc	a0,0x1c
    80005db4:	ef850513          	addi	a0,a0,-264 # 80021ca8 <disk+0x18>
    80005db8:	ffffc097          	auipc	ra,0xffffc
    80005dbc:	300080e7          	jalr	768(ra) # 800020b8 <wakeup>
}
    80005dc0:	60a2                	ld	ra,8(sp)
    80005dc2:	6402                	ld	s0,0(sp)
    80005dc4:	0141                	addi	sp,sp,16
    80005dc6:	8082                	ret
    panic("free_desc 1");
    80005dc8:	00003517          	auipc	a0,0x3
    80005dcc:	9e050513          	addi	a0,a0,-1568 # 800087a8 <syscalls+0x318>
    80005dd0:	ffffa097          	auipc	ra,0xffffa
    80005dd4:	770080e7          	jalr	1904(ra) # 80000540 <panic>
    panic("free_desc 2");
    80005dd8:	00003517          	auipc	a0,0x3
    80005ddc:	9e050513          	addi	a0,a0,-1568 # 800087b8 <syscalls+0x328>
    80005de0:	ffffa097          	auipc	ra,0xffffa
    80005de4:	760080e7          	jalr	1888(ra) # 80000540 <panic>

0000000080005de8 <virtio_disk_init>:
{
    80005de8:	1101                	addi	sp,sp,-32
    80005dea:	ec06                	sd	ra,24(sp)
    80005dec:	e822                	sd	s0,16(sp)
    80005dee:	e426                	sd	s1,8(sp)
    80005df0:	e04a                	sd	s2,0(sp)
    80005df2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005df4:	00003597          	auipc	a1,0x3
    80005df8:	9d458593          	addi	a1,a1,-1580 # 800087c8 <syscalls+0x338>
    80005dfc:	0001c517          	auipc	a0,0x1c
    80005e00:	fbc50513          	addi	a0,a0,-68 # 80021db8 <disk+0x128>
    80005e04:	ffffb097          	auipc	ra,0xffffb
    80005e08:	d42080e7          	jalr	-702(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e0c:	100017b7          	lui	a5,0x10001
    80005e10:	4398                	lw	a4,0(a5)
    80005e12:	2701                	sext.w	a4,a4
    80005e14:	747277b7          	lui	a5,0x74727
    80005e18:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e1c:	14f71b63          	bne	a4,a5,80005f72 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005e20:	100017b7          	lui	a5,0x10001
    80005e24:	43dc                	lw	a5,4(a5)
    80005e26:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e28:	4709                	li	a4,2
    80005e2a:	14e79463          	bne	a5,a4,80005f72 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e2e:	100017b7          	lui	a5,0x10001
    80005e32:	479c                	lw	a5,8(a5)
    80005e34:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005e36:	12e79e63          	bne	a5,a4,80005f72 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e3a:	100017b7          	lui	a5,0x10001
    80005e3e:	47d8                	lw	a4,12(a5)
    80005e40:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e42:	554d47b7          	lui	a5,0x554d4
    80005e46:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e4a:	12f71463          	bne	a4,a5,80005f72 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e4e:	100017b7          	lui	a5,0x10001
    80005e52:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e56:	4705                	li	a4,1
    80005e58:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e5a:	470d                	li	a4,3
    80005e5c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e5e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005e60:	c7ffe6b7          	lui	a3,0xc7ffe
    80005e64:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc98f>
    80005e68:	8f75                	and	a4,a4,a3
    80005e6a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e6c:	472d                	li	a4,11
    80005e6e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005e70:	5bbc                	lw	a5,112(a5)
    80005e72:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005e76:	8ba1                	andi	a5,a5,8
    80005e78:	10078563          	beqz	a5,80005f82 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e7c:	100017b7          	lui	a5,0x10001
    80005e80:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005e84:	43fc                	lw	a5,68(a5)
    80005e86:	2781                	sext.w	a5,a5
    80005e88:	10079563          	bnez	a5,80005f92 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005e8c:	100017b7          	lui	a5,0x10001
    80005e90:	5bdc                	lw	a5,52(a5)
    80005e92:	2781                	sext.w	a5,a5
  if(max == 0)
    80005e94:	10078763          	beqz	a5,80005fa2 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80005e98:	471d                	li	a4,7
    80005e9a:	10f77c63          	bgeu	a4,a5,80005fb2 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    80005e9e:	ffffb097          	auipc	ra,0xffffb
    80005ea2:	c48080e7          	jalr	-952(ra) # 80000ae6 <kalloc>
    80005ea6:	0001c497          	auipc	s1,0x1c
    80005eaa:	dea48493          	addi	s1,s1,-534 # 80021c90 <disk>
    80005eae:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005eb0:	ffffb097          	auipc	ra,0xffffb
    80005eb4:	c36080e7          	jalr	-970(ra) # 80000ae6 <kalloc>
    80005eb8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005eba:	ffffb097          	auipc	ra,0xffffb
    80005ebe:	c2c080e7          	jalr	-980(ra) # 80000ae6 <kalloc>
    80005ec2:	87aa                	mv	a5,a0
    80005ec4:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005ec6:	6088                	ld	a0,0(s1)
    80005ec8:	cd6d                	beqz	a0,80005fc2 <virtio_disk_init+0x1da>
    80005eca:	0001c717          	auipc	a4,0x1c
    80005ece:	dce73703          	ld	a4,-562(a4) # 80021c98 <disk+0x8>
    80005ed2:	cb65                	beqz	a4,80005fc2 <virtio_disk_init+0x1da>
    80005ed4:	c7fd                	beqz	a5,80005fc2 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80005ed6:	6605                	lui	a2,0x1
    80005ed8:	4581                	li	a1,0
    80005eda:	ffffb097          	auipc	ra,0xffffb
    80005ede:	df8080e7          	jalr	-520(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005ee2:	0001c497          	auipc	s1,0x1c
    80005ee6:	dae48493          	addi	s1,s1,-594 # 80021c90 <disk>
    80005eea:	6605                	lui	a2,0x1
    80005eec:	4581                	li	a1,0
    80005eee:	6488                	ld	a0,8(s1)
    80005ef0:	ffffb097          	auipc	ra,0xffffb
    80005ef4:	de2080e7          	jalr	-542(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    80005ef8:	6605                	lui	a2,0x1
    80005efa:	4581                	li	a1,0
    80005efc:	6888                	ld	a0,16(s1)
    80005efe:	ffffb097          	auipc	ra,0xffffb
    80005f02:	dd4080e7          	jalr	-556(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f06:	100017b7          	lui	a5,0x10001
    80005f0a:	4721                	li	a4,8
    80005f0c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005f0e:	4098                	lw	a4,0(s1)
    80005f10:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005f14:	40d8                	lw	a4,4(s1)
    80005f16:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005f1a:	6498                	ld	a4,8(s1)
    80005f1c:	0007069b          	sext.w	a3,a4
    80005f20:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005f24:	9701                	srai	a4,a4,0x20
    80005f26:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005f2a:	6898                	ld	a4,16(s1)
    80005f2c:	0007069b          	sext.w	a3,a4
    80005f30:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005f34:	9701                	srai	a4,a4,0x20
    80005f36:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005f3a:	4705                	li	a4,1
    80005f3c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80005f3e:	00e48c23          	sb	a4,24(s1)
    80005f42:	00e48ca3          	sb	a4,25(s1)
    80005f46:	00e48d23          	sb	a4,26(s1)
    80005f4a:	00e48da3          	sb	a4,27(s1)
    80005f4e:	00e48e23          	sb	a4,28(s1)
    80005f52:	00e48ea3          	sb	a4,29(s1)
    80005f56:	00e48f23          	sb	a4,30(s1)
    80005f5a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005f5e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f62:	0727a823          	sw	s2,112(a5)
}
    80005f66:	60e2                	ld	ra,24(sp)
    80005f68:	6442                	ld	s0,16(sp)
    80005f6a:	64a2                	ld	s1,8(sp)
    80005f6c:	6902                	ld	s2,0(sp)
    80005f6e:	6105                	addi	sp,sp,32
    80005f70:	8082                	ret
    panic("could not find virtio disk");
    80005f72:	00003517          	auipc	a0,0x3
    80005f76:	86650513          	addi	a0,a0,-1946 # 800087d8 <syscalls+0x348>
    80005f7a:	ffffa097          	auipc	ra,0xffffa
    80005f7e:	5c6080e7          	jalr	1478(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80005f82:	00003517          	auipc	a0,0x3
    80005f86:	87650513          	addi	a0,a0,-1930 # 800087f8 <syscalls+0x368>
    80005f8a:	ffffa097          	auipc	ra,0xffffa
    80005f8e:	5b6080e7          	jalr	1462(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80005f92:	00003517          	auipc	a0,0x3
    80005f96:	88650513          	addi	a0,a0,-1914 # 80008818 <syscalls+0x388>
    80005f9a:	ffffa097          	auipc	ra,0xffffa
    80005f9e:	5a6080e7          	jalr	1446(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80005fa2:	00003517          	auipc	a0,0x3
    80005fa6:	89650513          	addi	a0,a0,-1898 # 80008838 <syscalls+0x3a8>
    80005faa:	ffffa097          	auipc	ra,0xffffa
    80005fae:	596080e7          	jalr	1430(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80005fb2:	00003517          	auipc	a0,0x3
    80005fb6:	8a650513          	addi	a0,a0,-1882 # 80008858 <syscalls+0x3c8>
    80005fba:	ffffa097          	auipc	ra,0xffffa
    80005fbe:	586080e7          	jalr	1414(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80005fc2:	00003517          	auipc	a0,0x3
    80005fc6:	8b650513          	addi	a0,a0,-1866 # 80008878 <syscalls+0x3e8>
    80005fca:	ffffa097          	auipc	ra,0xffffa
    80005fce:	576080e7          	jalr	1398(ra) # 80000540 <panic>

0000000080005fd2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005fd2:	7119                	addi	sp,sp,-128
    80005fd4:	fc86                	sd	ra,120(sp)
    80005fd6:	f8a2                	sd	s0,112(sp)
    80005fd8:	f4a6                	sd	s1,104(sp)
    80005fda:	f0ca                	sd	s2,96(sp)
    80005fdc:	ecce                	sd	s3,88(sp)
    80005fde:	e8d2                	sd	s4,80(sp)
    80005fe0:	e4d6                	sd	s5,72(sp)
    80005fe2:	e0da                	sd	s6,64(sp)
    80005fe4:	fc5e                	sd	s7,56(sp)
    80005fe6:	f862                	sd	s8,48(sp)
    80005fe8:	f466                	sd	s9,40(sp)
    80005fea:	f06a                	sd	s10,32(sp)
    80005fec:	ec6e                	sd	s11,24(sp)
    80005fee:	0100                	addi	s0,sp,128
    80005ff0:	8aaa                	mv	s5,a0
    80005ff2:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005ff4:	00c52d03          	lw	s10,12(a0)
    80005ff8:	001d1d1b          	slliw	s10,s10,0x1
    80005ffc:	1d02                	slli	s10,s10,0x20
    80005ffe:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006002:	0001c517          	auipc	a0,0x1c
    80006006:	db650513          	addi	a0,a0,-586 # 80021db8 <disk+0x128>
    8000600a:	ffffb097          	auipc	ra,0xffffb
    8000600e:	bcc080e7          	jalr	-1076(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006012:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006014:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006016:	0001cb97          	auipc	s7,0x1c
    8000601a:	c7ab8b93          	addi	s7,s7,-902 # 80021c90 <disk>
  for(int i = 0; i < 3; i++){
    8000601e:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006020:	0001cc97          	auipc	s9,0x1c
    80006024:	d98c8c93          	addi	s9,s9,-616 # 80021db8 <disk+0x128>
    80006028:	a08d                	j	8000608a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000602a:	00fb8733          	add	a4,s7,a5
    8000602e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006032:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006034:	0207c563          	bltz	a5,8000605e <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80006038:	2905                	addiw	s2,s2,1
    8000603a:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    8000603c:	05690c63          	beq	s2,s6,80006094 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006040:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006042:	0001c717          	auipc	a4,0x1c
    80006046:	c4e70713          	addi	a4,a4,-946 # 80021c90 <disk>
    8000604a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000604c:	01874683          	lbu	a3,24(a4)
    80006050:	fee9                	bnez	a3,8000602a <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006052:	2785                	addiw	a5,a5,1
    80006054:	0705                	addi	a4,a4,1
    80006056:	fe979be3          	bne	a5,s1,8000604c <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000605a:	57fd                	li	a5,-1
    8000605c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000605e:	01205d63          	blez	s2,80006078 <virtio_disk_rw+0xa6>
    80006062:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006064:	000a2503          	lw	a0,0(s4)
    80006068:	00000097          	auipc	ra,0x0
    8000606c:	cfe080e7          	jalr	-770(ra) # 80005d66 <free_desc>
      for(int j = 0; j < i; j++)
    80006070:	2d85                	addiw	s11,s11,1
    80006072:	0a11                	addi	s4,s4,4
    80006074:	ff2d98e3          	bne	s11,s2,80006064 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006078:	85e6                	mv	a1,s9
    8000607a:	0001c517          	auipc	a0,0x1c
    8000607e:	c2e50513          	addi	a0,a0,-978 # 80021ca8 <disk+0x18>
    80006082:	ffffc097          	auipc	ra,0xffffc
    80006086:	fd2080e7          	jalr	-46(ra) # 80002054 <sleep>
  for(int i = 0; i < 3; i++){
    8000608a:	f8040a13          	addi	s4,s0,-128
{
    8000608e:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006090:	894e                	mv	s2,s3
    80006092:	b77d                	j	80006040 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006094:	f8042503          	lw	a0,-128(s0)
    80006098:	00a50713          	addi	a4,a0,10
    8000609c:	0712                	slli	a4,a4,0x4

  if(write)
    8000609e:	0001c797          	auipc	a5,0x1c
    800060a2:	bf278793          	addi	a5,a5,-1038 # 80021c90 <disk>
    800060a6:	00e786b3          	add	a3,a5,a4
    800060aa:	01803633          	snez	a2,s8
    800060ae:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800060b0:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    800060b4:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800060b8:	f6070613          	addi	a2,a4,-160
    800060bc:	6394                	ld	a3,0(a5)
    800060be:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800060c0:	00870593          	addi	a1,a4,8
    800060c4:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    800060c6:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800060c8:	0007b803          	ld	a6,0(a5)
    800060cc:	9642                	add	a2,a2,a6
    800060ce:	46c1                	li	a3,16
    800060d0:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800060d2:	4585                	li	a1,1
    800060d4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    800060d8:	f8442683          	lw	a3,-124(s0)
    800060dc:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800060e0:	0692                	slli	a3,a3,0x4
    800060e2:	9836                	add	a6,a6,a3
    800060e4:	058a8613          	addi	a2,s5,88
    800060e8:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    800060ec:	0007b803          	ld	a6,0(a5)
    800060f0:	96c2                	add	a3,a3,a6
    800060f2:	40000613          	li	a2,1024
    800060f6:	c690                	sw	a2,8(a3)
  if(write)
    800060f8:	001c3613          	seqz	a2,s8
    800060fc:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006100:	00166613          	ori	a2,a2,1
    80006104:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006108:	f8842603          	lw	a2,-120(s0)
    8000610c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006110:	00250693          	addi	a3,a0,2
    80006114:	0692                	slli	a3,a3,0x4
    80006116:	96be                	add	a3,a3,a5
    80006118:	58fd                	li	a7,-1
    8000611a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000611e:	0612                	slli	a2,a2,0x4
    80006120:	9832                	add	a6,a6,a2
    80006122:	f9070713          	addi	a4,a4,-112
    80006126:	973e                	add	a4,a4,a5
    80006128:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000612c:	6398                	ld	a4,0(a5)
    8000612e:	9732                	add	a4,a4,a2
    80006130:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006132:	4609                	li	a2,2
    80006134:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006138:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000613c:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006140:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006144:	6794                	ld	a3,8(a5)
    80006146:	0026d703          	lhu	a4,2(a3)
    8000614a:	8b1d                	andi	a4,a4,7
    8000614c:	0706                	slli	a4,a4,0x1
    8000614e:	96ba                	add	a3,a3,a4
    80006150:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006154:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006158:	6798                	ld	a4,8(a5)
    8000615a:	00275783          	lhu	a5,2(a4)
    8000615e:	2785                	addiw	a5,a5,1
    80006160:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006164:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006168:	100017b7          	lui	a5,0x10001
    8000616c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006170:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    80006174:	0001c917          	auipc	s2,0x1c
    80006178:	c4490913          	addi	s2,s2,-956 # 80021db8 <disk+0x128>
  while(b->disk == 1) {
    8000617c:	4485                	li	s1,1
    8000617e:	00b79c63          	bne	a5,a1,80006196 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006182:	85ca                	mv	a1,s2
    80006184:	8556                	mv	a0,s5
    80006186:	ffffc097          	auipc	ra,0xffffc
    8000618a:	ece080e7          	jalr	-306(ra) # 80002054 <sleep>
  while(b->disk == 1) {
    8000618e:	004aa783          	lw	a5,4(s5)
    80006192:	fe9788e3          	beq	a5,s1,80006182 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006196:	f8042903          	lw	s2,-128(s0)
    8000619a:	00290713          	addi	a4,s2,2
    8000619e:	0712                	slli	a4,a4,0x4
    800061a0:	0001c797          	auipc	a5,0x1c
    800061a4:	af078793          	addi	a5,a5,-1296 # 80021c90 <disk>
    800061a8:	97ba                	add	a5,a5,a4
    800061aa:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800061ae:	0001c997          	auipc	s3,0x1c
    800061b2:	ae298993          	addi	s3,s3,-1310 # 80021c90 <disk>
    800061b6:	00491713          	slli	a4,s2,0x4
    800061ba:	0009b783          	ld	a5,0(s3)
    800061be:	97ba                	add	a5,a5,a4
    800061c0:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800061c4:	854a                	mv	a0,s2
    800061c6:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800061ca:	00000097          	auipc	ra,0x0
    800061ce:	b9c080e7          	jalr	-1124(ra) # 80005d66 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800061d2:	8885                	andi	s1,s1,1
    800061d4:	f0ed                	bnez	s1,800061b6 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800061d6:	0001c517          	auipc	a0,0x1c
    800061da:	be250513          	addi	a0,a0,-1054 # 80021db8 <disk+0x128>
    800061de:	ffffb097          	auipc	ra,0xffffb
    800061e2:	aac080e7          	jalr	-1364(ra) # 80000c8a <release>
}
    800061e6:	70e6                	ld	ra,120(sp)
    800061e8:	7446                	ld	s0,112(sp)
    800061ea:	74a6                	ld	s1,104(sp)
    800061ec:	7906                	ld	s2,96(sp)
    800061ee:	69e6                	ld	s3,88(sp)
    800061f0:	6a46                	ld	s4,80(sp)
    800061f2:	6aa6                	ld	s5,72(sp)
    800061f4:	6b06                	ld	s6,64(sp)
    800061f6:	7be2                	ld	s7,56(sp)
    800061f8:	7c42                	ld	s8,48(sp)
    800061fa:	7ca2                	ld	s9,40(sp)
    800061fc:	7d02                	ld	s10,32(sp)
    800061fe:	6de2                	ld	s11,24(sp)
    80006200:	6109                	addi	sp,sp,128
    80006202:	8082                	ret

0000000080006204 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006204:	1101                	addi	sp,sp,-32
    80006206:	ec06                	sd	ra,24(sp)
    80006208:	e822                	sd	s0,16(sp)
    8000620a:	e426                	sd	s1,8(sp)
    8000620c:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000620e:	0001c497          	auipc	s1,0x1c
    80006212:	a8248493          	addi	s1,s1,-1406 # 80021c90 <disk>
    80006216:	0001c517          	auipc	a0,0x1c
    8000621a:	ba250513          	addi	a0,a0,-1118 # 80021db8 <disk+0x128>
    8000621e:	ffffb097          	auipc	ra,0xffffb
    80006222:	9b8080e7          	jalr	-1608(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006226:	10001737          	lui	a4,0x10001
    8000622a:	533c                	lw	a5,96(a4)
    8000622c:	8b8d                	andi	a5,a5,3
    8000622e:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006230:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006234:	689c                	ld	a5,16(s1)
    80006236:	0204d703          	lhu	a4,32(s1)
    8000623a:	0027d783          	lhu	a5,2(a5)
    8000623e:	04f70863          	beq	a4,a5,8000628e <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006242:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006246:	6898                	ld	a4,16(s1)
    80006248:	0204d783          	lhu	a5,32(s1)
    8000624c:	8b9d                	andi	a5,a5,7
    8000624e:	078e                	slli	a5,a5,0x3
    80006250:	97ba                	add	a5,a5,a4
    80006252:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006254:	00278713          	addi	a4,a5,2
    80006258:	0712                	slli	a4,a4,0x4
    8000625a:	9726                	add	a4,a4,s1
    8000625c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006260:	e721                	bnez	a4,800062a8 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006262:	0789                	addi	a5,a5,2
    80006264:	0792                	slli	a5,a5,0x4
    80006266:	97a6                	add	a5,a5,s1
    80006268:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000626a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000626e:	ffffc097          	auipc	ra,0xffffc
    80006272:	e4a080e7          	jalr	-438(ra) # 800020b8 <wakeup>

    disk.used_idx += 1;
    80006276:	0204d783          	lhu	a5,32(s1)
    8000627a:	2785                	addiw	a5,a5,1
    8000627c:	17c2                	slli	a5,a5,0x30
    8000627e:	93c1                	srli	a5,a5,0x30
    80006280:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006284:	6898                	ld	a4,16(s1)
    80006286:	00275703          	lhu	a4,2(a4)
    8000628a:	faf71ce3          	bne	a4,a5,80006242 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000628e:	0001c517          	auipc	a0,0x1c
    80006292:	b2a50513          	addi	a0,a0,-1238 # 80021db8 <disk+0x128>
    80006296:	ffffb097          	auipc	ra,0xffffb
    8000629a:	9f4080e7          	jalr	-1548(ra) # 80000c8a <release>
}
    8000629e:	60e2                	ld	ra,24(sp)
    800062a0:	6442                	ld	s0,16(sp)
    800062a2:	64a2                	ld	s1,8(sp)
    800062a4:	6105                	addi	sp,sp,32
    800062a6:	8082                	ret
      panic("virtio_disk_intr status");
    800062a8:	00002517          	auipc	a0,0x2
    800062ac:	5e850513          	addi	a0,a0,1512 # 80008890 <syscalls+0x400>
    800062b0:	ffffa097          	auipc	ra,0xffffa
    800062b4:	290080e7          	jalr	656(ra) # 80000540 <panic>
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
