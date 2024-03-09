
user/_hello:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/types.h"
#include "user/user.h"

int main(int argc, char *argv[])
{
   0:	1141                	addi	sp,sp,-16
   2:	e406                	sd	ra,8(sp)
   4:	e022                	sd	s0,0(sp)
   6:	0800                	addi	s0,sp,16

    if(argc > 1) {
   8:	4785                	li	a5,1
   a:	02a7d063          	bge	a5,a0,2a <main+0x2a>
        printf("Hello %s, nice to meet you!\n", argv[1]);
   e:	658c                	ld	a1,8(a1)
  10:	00000517          	auipc	a0,0x0
  14:	7f050513          	addi	a0,a0,2032 # 800 <malloc+0xf4>
  18:	00000097          	auipc	ra,0x0
  1c:	63c080e7          	jalr	1596(ra) # 654 <printf>
    } else {
        printf("Hello World\n");
    }
    return 0;
  20:	4501                	li	a0,0
  22:	60a2                	ld	ra,8(sp)
  24:	6402                	ld	s0,0(sp)
  26:	0141                	addi	sp,sp,16
  28:	8082                	ret
        printf("Hello World\n");
  2a:	00000517          	auipc	a0,0x0
  2e:	7f650513          	addi	a0,a0,2038 # 820 <malloc+0x114>
  32:	00000097          	auipc	ra,0x0
  36:	622080e7          	jalr	1570(ra) # 654 <printf>
  3a:	b7dd                	j	20 <main+0x20>

000000000000003c <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
  3c:	1141                	addi	sp,sp,-16
  3e:	e406                	sd	ra,8(sp)
  40:	e022                	sd	s0,0(sp)
  42:	0800                	addi	s0,sp,16
  extern int main();
  main();
  44:	00000097          	auipc	ra,0x0
  48:	fbc080e7          	jalr	-68(ra) # 0 <main>
  exit(0);
  4c:	4501                	li	a0,0
  4e:	00000097          	auipc	ra,0x0
  52:	274080e7          	jalr	628(ra) # 2c2 <exit>

0000000000000056 <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
  56:	1141                	addi	sp,sp,-16
  58:	e422                	sd	s0,8(sp)
  5a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  5c:	87aa                	mv	a5,a0
  5e:	0585                	addi	a1,a1,1
  60:	0785                	addi	a5,a5,1
  62:	fff5c703          	lbu	a4,-1(a1)
  66:	fee78fa3          	sb	a4,-1(a5)
  6a:	fb75                	bnez	a4,5e <strcpy+0x8>
    ;
  return os;
}
  6c:	6422                	ld	s0,8(sp)
  6e:	0141                	addi	sp,sp,16
  70:	8082                	ret

0000000000000072 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  72:	1141                	addi	sp,sp,-16
  74:	e422                	sd	s0,8(sp)
  76:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  78:	00054783          	lbu	a5,0(a0)
  7c:	cb91                	beqz	a5,90 <strcmp+0x1e>
  7e:	0005c703          	lbu	a4,0(a1)
  82:	00f71763          	bne	a4,a5,90 <strcmp+0x1e>
    p++, q++;
  86:	0505                	addi	a0,a0,1
  88:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  8a:	00054783          	lbu	a5,0(a0)
  8e:	fbe5                	bnez	a5,7e <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  90:	0005c503          	lbu	a0,0(a1)
}
  94:	40a7853b          	subw	a0,a5,a0
  98:	6422                	ld	s0,8(sp)
  9a:	0141                	addi	sp,sp,16
  9c:	8082                	ret

000000000000009e <strlen>:

uint
strlen(const char *s)
{
  9e:	1141                	addi	sp,sp,-16
  a0:	e422                	sd	s0,8(sp)
  a2:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  a4:	00054783          	lbu	a5,0(a0)
  a8:	cf91                	beqz	a5,c4 <strlen+0x26>
  aa:	0505                	addi	a0,a0,1
  ac:	87aa                	mv	a5,a0
  ae:	4685                	li	a3,1
  b0:	9e89                	subw	a3,a3,a0
  b2:	00f6853b          	addw	a0,a3,a5
  b6:	0785                	addi	a5,a5,1
  b8:	fff7c703          	lbu	a4,-1(a5)
  bc:	fb7d                	bnez	a4,b2 <strlen+0x14>
    ;
  return n;
}
  be:	6422                	ld	s0,8(sp)
  c0:	0141                	addi	sp,sp,16
  c2:	8082                	ret
  for(n = 0; s[n]; n++)
  c4:	4501                	li	a0,0
  c6:	bfe5                	j	be <strlen+0x20>

00000000000000c8 <memset>:

void*
memset(void *dst, int c, uint n)
{
  c8:	1141                	addi	sp,sp,-16
  ca:	e422                	sd	s0,8(sp)
  cc:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
  ce:	ca19                	beqz	a2,e4 <memset+0x1c>
  d0:	87aa                	mv	a5,a0
  d2:	1602                	slli	a2,a2,0x20
  d4:	9201                	srli	a2,a2,0x20
  d6:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
  da:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
  de:	0785                	addi	a5,a5,1
  e0:	fee79de3          	bne	a5,a4,da <memset+0x12>
  }
  return dst;
}
  e4:	6422                	ld	s0,8(sp)
  e6:	0141                	addi	sp,sp,16
  e8:	8082                	ret

00000000000000ea <strchr>:

char*
strchr(const char *s, char c)
{
  ea:	1141                	addi	sp,sp,-16
  ec:	e422                	sd	s0,8(sp)
  ee:	0800                	addi	s0,sp,16
  for(; *s; s++)
  f0:	00054783          	lbu	a5,0(a0)
  f4:	cb99                	beqz	a5,10a <strchr+0x20>
    if(*s == c)
  f6:	00f58763          	beq	a1,a5,104 <strchr+0x1a>
  for(; *s; s++)
  fa:	0505                	addi	a0,a0,1
  fc:	00054783          	lbu	a5,0(a0)
 100:	fbfd                	bnez	a5,f6 <strchr+0xc>
      return (char*)s;
  return 0;
 102:	4501                	li	a0,0
}
 104:	6422                	ld	s0,8(sp)
 106:	0141                	addi	sp,sp,16
 108:	8082                	ret
  return 0;
 10a:	4501                	li	a0,0
 10c:	bfe5                	j	104 <strchr+0x1a>

000000000000010e <gets>:

char*
gets(char *buf, int max)
{
 10e:	711d                	addi	sp,sp,-96
 110:	ec86                	sd	ra,88(sp)
 112:	e8a2                	sd	s0,80(sp)
 114:	e4a6                	sd	s1,72(sp)
 116:	e0ca                	sd	s2,64(sp)
 118:	fc4e                	sd	s3,56(sp)
 11a:	f852                	sd	s4,48(sp)
 11c:	f456                	sd	s5,40(sp)
 11e:	f05a                	sd	s6,32(sp)
 120:	ec5e                	sd	s7,24(sp)
 122:	1080                	addi	s0,sp,96
 124:	8baa                	mv	s7,a0
 126:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 128:	892a                	mv	s2,a0
 12a:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 12c:	4aa9                	li	s5,10
 12e:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 130:	89a6                	mv	s3,s1
 132:	2485                	addiw	s1,s1,1
 134:	0344d863          	bge	s1,s4,164 <gets+0x56>
    cc = read(0, &c, 1);
 138:	4605                	li	a2,1
 13a:	faf40593          	addi	a1,s0,-81
 13e:	4501                	li	a0,0
 140:	00000097          	auipc	ra,0x0
 144:	19a080e7          	jalr	410(ra) # 2da <read>
    if(cc < 1)
 148:	00a05e63          	blez	a0,164 <gets+0x56>
    buf[i++] = c;
 14c:	faf44783          	lbu	a5,-81(s0)
 150:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 154:	01578763          	beq	a5,s5,162 <gets+0x54>
 158:	0905                	addi	s2,s2,1
 15a:	fd679be3          	bne	a5,s6,130 <gets+0x22>
  for(i=0; i+1 < max; ){
 15e:	89a6                	mv	s3,s1
 160:	a011                	j	164 <gets+0x56>
 162:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 164:	99de                	add	s3,s3,s7
 166:	00098023          	sb	zero,0(s3)
  return buf;
}
 16a:	855e                	mv	a0,s7
 16c:	60e6                	ld	ra,88(sp)
 16e:	6446                	ld	s0,80(sp)
 170:	64a6                	ld	s1,72(sp)
 172:	6906                	ld	s2,64(sp)
 174:	79e2                	ld	s3,56(sp)
 176:	7a42                	ld	s4,48(sp)
 178:	7aa2                	ld	s5,40(sp)
 17a:	7b02                	ld	s6,32(sp)
 17c:	6be2                	ld	s7,24(sp)
 17e:	6125                	addi	sp,sp,96
 180:	8082                	ret

0000000000000182 <stat>:

int
stat(const char *n, struct stat *st)
{
 182:	1101                	addi	sp,sp,-32
 184:	ec06                	sd	ra,24(sp)
 186:	e822                	sd	s0,16(sp)
 188:	e426                	sd	s1,8(sp)
 18a:	e04a                	sd	s2,0(sp)
 18c:	1000                	addi	s0,sp,32
 18e:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 190:	4581                	li	a1,0
 192:	00000097          	auipc	ra,0x0
 196:	170080e7          	jalr	368(ra) # 302 <open>
  if(fd < 0)
 19a:	02054563          	bltz	a0,1c4 <stat+0x42>
 19e:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 1a0:	85ca                	mv	a1,s2
 1a2:	00000097          	auipc	ra,0x0
 1a6:	178080e7          	jalr	376(ra) # 31a <fstat>
 1aa:	892a                	mv	s2,a0
  close(fd);
 1ac:	8526                	mv	a0,s1
 1ae:	00000097          	auipc	ra,0x0
 1b2:	13c080e7          	jalr	316(ra) # 2ea <close>
  return r;
}
 1b6:	854a                	mv	a0,s2
 1b8:	60e2                	ld	ra,24(sp)
 1ba:	6442                	ld	s0,16(sp)
 1bc:	64a2                	ld	s1,8(sp)
 1be:	6902                	ld	s2,0(sp)
 1c0:	6105                	addi	sp,sp,32
 1c2:	8082                	ret
    return -1;
 1c4:	597d                	li	s2,-1
 1c6:	bfc5                	j	1b6 <stat+0x34>

00000000000001c8 <atoi>:

int
atoi(const char *s)
{
 1c8:	1141                	addi	sp,sp,-16
 1ca:	e422                	sd	s0,8(sp)
 1cc:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 1ce:	00054683          	lbu	a3,0(a0)
 1d2:	fd06879b          	addiw	a5,a3,-48
 1d6:	0ff7f793          	zext.b	a5,a5
 1da:	4625                	li	a2,9
 1dc:	02f66863          	bltu	a2,a5,20c <atoi+0x44>
 1e0:	872a                	mv	a4,a0
  n = 0;
 1e2:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 1e4:	0705                	addi	a4,a4,1
 1e6:	0025179b          	slliw	a5,a0,0x2
 1ea:	9fa9                	addw	a5,a5,a0
 1ec:	0017979b          	slliw	a5,a5,0x1
 1f0:	9fb5                	addw	a5,a5,a3
 1f2:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 1f6:	00074683          	lbu	a3,0(a4)
 1fa:	fd06879b          	addiw	a5,a3,-48
 1fe:	0ff7f793          	zext.b	a5,a5
 202:	fef671e3          	bgeu	a2,a5,1e4 <atoi+0x1c>
  return n;
}
 206:	6422                	ld	s0,8(sp)
 208:	0141                	addi	sp,sp,16
 20a:	8082                	ret
  n = 0;
 20c:	4501                	li	a0,0
 20e:	bfe5                	j	206 <atoi+0x3e>

0000000000000210 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 210:	1141                	addi	sp,sp,-16
 212:	e422                	sd	s0,8(sp)
 214:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 216:	02b57463          	bgeu	a0,a1,23e <memmove+0x2e>
    while(n-- > 0)
 21a:	00c05f63          	blez	a2,238 <memmove+0x28>
 21e:	1602                	slli	a2,a2,0x20
 220:	9201                	srli	a2,a2,0x20
 222:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 226:	872a                	mv	a4,a0
      *dst++ = *src++;
 228:	0585                	addi	a1,a1,1
 22a:	0705                	addi	a4,a4,1
 22c:	fff5c683          	lbu	a3,-1(a1)
 230:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 234:	fee79ae3          	bne	a5,a4,228 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 238:	6422                	ld	s0,8(sp)
 23a:	0141                	addi	sp,sp,16
 23c:	8082                	ret
    dst += n;
 23e:	00c50733          	add	a4,a0,a2
    src += n;
 242:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 244:	fec05ae3          	blez	a2,238 <memmove+0x28>
 248:	fff6079b          	addiw	a5,a2,-1
 24c:	1782                	slli	a5,a5,0x20
 24e:	9381                	srli	a5,a5,0x20
 250:	fff7c793          	not	a5,a5
 254:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 256:	15fd                	addi	a1,a1,-1
 258:	177d                	addi	a4,a4,-1
 25a:	0005c683          	lbu	a3,0(a1)
 25e:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 262:	fee79ae3          	bne	a5,a4,256 <memmove+0x46>
 266:	bfc9                	j	238 <memmove+0x28>

0000000000000268 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 268:	1141                	addi	sp,sp,-16
 26a:	e422                	sd	s0,8(sp)
 26c:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 26e:	ca05                	beqz	a2,29e <memcmp+0x36>
 270:	fff6069b          	addiw	a3,a2,-1
 274:	1682                	slli	a3,a3,0x20
 276:	9281                	srli	a3,a3,0x20
 278:	0685                	addi	a3,a3,1
 27a:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 27c:	00054783          	lbu	a5,0(a0)
 280:	0005c703          	lbu	a4,0(a1)
 284:	00e79863          	bne	a5,a4,294 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 288:	0505                	addi	a0,a0,1
    p2++;
 28a:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 28c:	fed518e3          	bne	a0,a3,27c <memcmp+0x14>
  }
  return 0;
 290:	4501                	li	a0,0
 292:	a019                	j	298 <memcmp+0x30>
      return *p1 - *p2;
 294:	40e7853b          	subw	a0,a5,a4
}
 298:	6422                	ld	s0,8(sp)
 29a:	0141                	addi	sp,sp,16
 29c:	8082                	ret
  return 0;
 29e:	4501                	li	a0,0
 2a0:	bfe5                	j	298 <memcmp+0x30>

00000000000002a2 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 2a2:	1141                	addi	sp,sp,-16
 2a4:	e406                	sd	ra,8(sp)
 2a6:	e022                	sd	s0,0(sp)
 2a8:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 2aa:	00000097          	auipc	ra,0x0
 2ae:	f66080e7          	jalr	-154(ra) # 210 <memmove>
}
 2b2:	60a2                	ld	ra,8(sp)
 2b4:	6402                	ld	s0,0(sp)
 2b6:	0141                	addi	sp,sp,16
 2b8:	8082                	ret

00000000000002ba <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 2ba:	4885                	li	a7,1
 ecall
 2bc:	00000073          	ecall
 ret
 2c0:	8082                	ret

00000000000002c2 <exit>:
.global exit
exit:
 li a7, SYS_exit
 2c2:	4889                	li	a7,2
 ecall
 2c4:	00000073          	ecall
 ret
 2c8:	8082                	ret

00000000000002ca <wait>:
.global wait
wait:
 li a7, SYS_wait
 2ca:	488d                	li	a7,3
 ecall
 2cc:	00000073          	ecall
 ret
 2d0:	8082                	ret

00000000000002d2 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 2d2:	4891                	li	a7,4
 ecall
 2d4:	00000073          	ecall
 ret
 2d8:	8082                	ret

00000000000002da <read>:
.global read
read:
 li a7, SYS_read
 2da:	4895                	li	a7,5
 ecall
 2dc:	00000073          	ecall
 ret
 2e0:	8082                	ret

00000000000002e2 <write>:
.global write
write:
 li a7, SYS_write
 2e2:	48c1                	li	a7,16
 ecall
 2e4:	00000073          	ecall
 ret
 2e8:	8082                	ret

00000000000002ea <close>:
.global close
close:
 li a7, SYS_close
 2ea:	48d5                	li	a7,21
 ecall
 2ec:	00000073          	ecall
 ret
 2f0:	8082                	ret

00000000000002f2 <kill>:
.global kill
kill:
 li a7, SYS_kill
 2f2:	4899                	li	a7,6
 ecall
 2f4:	00000073          	ecall
 ret
 2f8:	8082                	ret

00000000000002fa <exec>:
.global exec
exec:
 li a7, SYS_exec
 2fa:	489d                	li	a7,7
 ecall
 2fc:	00000073          	ecall
 ret
 300:	8082                	ret

0000000000000302 <open>:
.global open
open:
 li a7, SYS_open
 302:	48bd                	li	a7,15
 ecall
 304:	00000073          	ecall
 ret
 308:	8082                	ret

000000000000030a <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 30a:	48c5                	li	a7,17
 ecall
 30c:	00000073          	ecall
 ret
 310:	8082                	ret

0000000000000312 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 312:	48c9                	li	a7,18
 ecall
 314:	00000073          	ecall
 ret
 318:	8082                	ret

000000000000031a <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 31a:	48a1                	li	a7,8
 ecall
 31c:	00000073          	ecall
 ret
 320:	8082                	ret

0000000000000322 <link>:
.global link
link:
 li a7, SYS_link
 322:	48cd                	li	a7,19
 ecall
 324:	00000073          	ecall
 ret
 328:	8082                	ret

000000000000032a <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 32a:	48d1                	li	a7,20
 ecall
 32c:	00000073          	ecall
 ret
 330:	8082                	ret

0000000000000332 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 332:	48a5                	li	a7,9
 ecall
 334:	00000073          	ecall
 ret
 338:	8082                	ret

000000000000033a <dup>:
.global dup
dup:
 li a7, SYS_dup
 33a:	48a9                	li	a7,10
 ecall
 33c:	00000073          	ecall
 ret
 340:	8082                	ret

0000000000000342 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 342:	48ad                	li	a7,11
 ecall
 344:	00000073          	ecall
 ret
 348:	8082                	ret

000000000000034a <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 34a:	48b1                	li	a7,12
 ecall
 34c:	00000073          	ecall
 ret
 350:	8082                	ret

0000000000000352 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 352:	48b5                	li	a7,13
 ecall
 354:	00000073          	ecall
 ret
 358:	8082                	ret

000000000000035a <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 35a:	48b9                	li	a7,14
 ecall
 35c:	00000073          	ecall
 ret
 360:	8082                	ret

0000000000000362 <helloworld>:
.global helloworld
helloworld:
 li a7, SYS_helloworld
 362:	48d9                	li	a7,22
 ecall
 364:	00000073          	ecall
 ret
 368:	8082                	ret

000000000000036a <curproc>:
.global curproc
curproc:
 li a7, SYS_curproc
 36a:	48dd                	li	a7,23
 ecall
 36c:	00000073          	ecall
 ret
 370:	8082                	ret

0000000000000372 <runproc>:
.global runproc
runproc:
 li a7, SYS_runproc
 372:	48e1                	li	a7,24
 ecall
 374:	00000073          	ecall
 ret
 378:	8082                	ret

000000000000037a <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 37a:	1101                	addi	sp,sp,-32
 37c:	ec06                	sd	ra,24(sp)
 37e:	e822                	sd	s0,16(sp)
 380:	1000                	addi	s0,sp,32
 382:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 386:	4605                	li	a2,1
 388:	fef40593          	addi	a1,s0,-17
 38c:	00000097          	auipc	ra,0x0
 390:	f56080e7          	jalr	-170(ra) # 2e2 <write>
}
 394:	60e2                	ld	ra,24(sp)
 396:	6442                	ld	s0,16(sp)
 398:	6105                	addi	sp,sp,32
 39a:	8082                	ret

000000000000039c <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 39c:	7139                	addi	sp,sp,-64
 39e:	fc06                	sd	ra,56(sp)
 3a0:	f822                	sd	s0,48(sp)
 3a2:	f426                	sd	s1,40(sp)
 3a4:	f04a                	sd	s2,32(sp)
 3a6:	ec4e                	sd	s3,24(sp)
 3a8:	0080                	addi	s0,sp,64
 3aa:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 3ac:	c299                	beqz	a3,3b2 <printint+0x16>
 3ae:	0805c963          	bltz	a1,440 <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 3b2:	2581                	sext.w	a1,a1
  neg = 0;
 3b4:	4881                	li	a7,0
 3b6:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 3ba:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 3bc:	2601                	sext.w	a2,a2
 3be:	00000517          	auipc	a0,0x0
 3c2:	4d250513          	addi	a0,a0,1234 # 890 <digits>
 3c6:	883a                	mv	a6,a4
 3c8:	2705                	addiw	a4,a4,1
 3ca:	02c5f7bb          	remuw	a5,a1,a2
 3ce:	1782                	slli	a5,a5,0x20
 3d0:	9381                	srli	a5,a5,0x20
 3d2:	97aa                	add	a5,a5,a0
 3d4:	0007c783          	lbu	a5,0(a5)
 3d8:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 3dc:	0005879b          	sext.w	a5,a1
 3e0:	02c5d5bb          	divuw	a1,a1,a2
 3e4:	0685                	addi	a3,a3,1
 3e6:	fec7f0e3          	bgeu	a5,a2,3c6 <printint+0x2a>
  if(neg)
 3ea:	00088c63          	beqz	a7,402 <printint+0x66>
    buf[i++] = '-';
 3ee:	fd070793          	addi	a5,a4,-48
 3f2:	00878733          	add	a4,a5,s0
 3f6:	02d00793          	li	a5,45
 3fa:	fef70823          	sb	a5,-16(a4)
 3fe:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 402:	02e05863          	blez	a4,432 <printint+0x96>
 406:	fc040793          	addi	a5,s0,-64
 40a:	00e78933          	add	s2,a5,a4
 40e:	fff78993          	addi	s3,a5,-1
 412:	99ba                	add	s3,s3,a4
 414:	377d                	addiw	a4,a4,-1
 416:	1702                	slli	a4,a4,0x20
 418:	9301                	srli	a4,a4,0x20
 41a:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 41e:	fff94583          	lbu	a1,-1(s2)
 422:	8526                	mv	a0,s1
 424:	00000097          	auipc	ra,0x0
 428:	f56080e7          	jalr	-170(ra) # 37a <putc>
  while(--i >= 0)
 42c:	197d                	addi	s2,s2,-1
 42e:	ff3918e3          	bne	s2,s3,41e <printint+0x82>
}
 432:	70e2                	ld	ra,56(sp)
 434:	7442                	ld	s0,48(sp)
 436:	74a2                	ld	s1,40(sp)
 438:	7902                	ld	s2,32(sp)
 43a:	69e2                	ld	s3,24(sp)
 43c:	6121                	addi	sp,sp,64
 43e:	8082                	ret
    x = -xx;
 440:	40b005bb          	negw	a1,a1
    neg = 1;
 444:	4885                	li	a7,1
    x = -xx;
 446:	bf85                	j	3b6 <printint+0x1a>

0000000000000448 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 448:	7119                	addi	sp,sp,-128
 44a:	fc86                	sd	ra,120(sp)
 44c:	f8a2                	sd	s0,112(sp)
 44e:	f4a6                	sd	s1,104(sp)
 450:	f0ca                	sd	s2,96(sp)
 452:	ecce                	sd	s3,88(sp)
 454:	e8d2                	sd	s4,80(sp)
 456:	e4d6                	sd	s5,72(sp)
 458:	e0da                	sd	s6,64(sp)
 45a:	fc5e                	sd	s7,56(sp)
 45c:	f862                	sd	s8,48(sp)
 45e:	f466                	sd	s9,40(sp)
 460:	f06a                	sd	s10,32(sp)
 462:	ec6e                	sd	s11,24(sp)
 464:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 466:	0005c903          	lbu	s2,0(a1)
 46a:	18090f63          	beqz	s2,608 <vprintf+0x1c0>
 46e:	8aaa                	mv	s5,a0
 470:	8b32                	mv	s6,a2
 472:	00158493          	addi	s1,a1,1
  state = 0;
 476:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 478:	02500a13          	li	s4,37
 47c:	4c55                	li	s8,21
 47e:	00000c97          	auipc	s9,0x0
 482:	3bac8c93          	addi	s9,s9,954 # 838 <malloc+0x12c>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
        s = va_arg(ap, char*);
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 486:	02800d93          	li	s11,40
  putc(fd, 'x');
 48a:	4d41                	li	s10,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 48c:	00000b97          	auipc	s7,0x0
 490:	404b8b93          	addi	s7,s7,1028 # 890 <digits>
 494:	a839                	j	4b2 <vprintf+0x6a>
        putc(fd, c);
 496:	85ca                	mv	a1,s2
 498:	8556                	mv	a0,s5
 49a:	00000097          	auipc	ra,0x0
 49e:	ee0080e7          	jalr	-288(ra) # 37a <putc>
 4a2:	a019                	j	4a8 <vprintf+0x60>
    } else if(state == '%'){
 4a4:	01498d63          	beq	s3,s4,4be <vprintf+0x76>
  for(i = 0; fmt[i]; i++){
 4a8:	0485                	addi	s1,s1,1
 4aa:	fff4c903          	lbu	s2,-1(s1)
 4ae:	14090d63          	beqz	s2,608 <vprintf+0x1c0>
    if(state == 0){
 4b2:	fe0999e3          	bnez	s3,4a4 <vprintf+0x5c>
      if(c == '%'){
 4b6:	ff4910e3          	bne	s2,s4,496 <vprintf+0x4e>
        state = '%';
 4ba:	89d2                	mv	s3,s4
 4bc:	b7f5                	j	4a8 <vprintf+0x60>
      if(c == 'd'){
 4be:	11490c63          	beq	s2,s4,5d6 <vprintf+0x18e>
 4c2:	f9d9079b          	addiw	a5,s2,-99
 4c6:	0ff7f793          	zext.b	a5,a5
 4ca:	10fc6e63          	bltu	s8,a5,5e6 <vprintf+0x19e>
 4ce:	f9d9079b          	addiw	a5,s2,-99
 4d2:	0ff7f713          	zext.b	a4,a5
 4d6:	10ec6863          	bltu	s8,a4,5e6 <vprintf+0x19e>
 4da:	00271793          	slli	a5,a4,0x2
 4de:	97e6                	add	a5,a5,s9
 4e0:	439c                	lw	a5,0(a5)
 4e2:	97e6                	add	a5,a5,s9
 4e4:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 4e6:	008b0913          	addi	s2,s6,8
 4ea:	4685                	li	a3,1
 4ec:	4629                	li	a2,10
 4ee:	000b2583          	lw	a1,0(s6)
 4f2:	8556                	mv	a0,s5
 4f4:	00000097          	auipc	ra,0x0
 4f8:	ea8080e7          	jalr	-344(ra) # 39c <printint>
 4fc:	8b4a                	mv	s6,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 4fe:	4981                	li	s3,0
 500:	b765                	j	4a8 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 502:	008b0913          	addi	s2,s6,8
 506:	4681                	li	a3,0
 508:	4629                	li	a2,10
 50a:	000b2583          	lw	a1,0(s6)
 50e:	8556                	mv	a0,s5
 510:	00000097          	auipc	ra,0x0
 514:	e8c080e7          	jalr	-372(ra) # 39c <printint>
 518:	8b4a                	mv	s6,s2
      state = 0;
 51a:	4981                	li	s3,0
 51c:	b771                	j	4a8 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 51e:	008b0913          	addi	s2,s6,8
 522:	4681                	li	a3,0
 524:	866a                	mv	a2,s10
 526:	000b2583          	lw	a1,0(s6)
 52a:	8556                	mv	a0,s5
 52c:	00000097          	auipc	ra,0x0
 530:	e70080e7          	jalr	-400(ra) # 39c <printint>
 534:	8b4a                	mv	s6,s2
      state = 0;
 536:	4981                	li	s3,0
 538:	bf85                	j	4a8 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 53a:	008b0793          	addi	a5,s6,8
 53e:	f8f43423          	sd	a5,-120(s0)
 542:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 546:	03000593          	li	a1,48
 54a:	8556                	mv	a0,s5
 54c:	00000097          	auipc	ra,0x0
 550:	e2e080e7          	jalr	-466(ra) # 37a <putc>
  putc(fd, 'x');
 554:	07800593          	li	a1,120
 558:	8556                	mv	a0,s5
 55a:	00000097          	auipc	ra,0x0
 55e:	e20080e7          	jalr	-480(ra) # 37a <putc>
 562:	896a                	mv	s2,s10
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 564:	03c9d793          	srli	a5,s3,0x3c
 568:	97de                	add	a5,a5,s7
 56a:	0007c583          	lbu	a1,0(a5)
 56e:	8556                	mv	a0,s5
 570:	00000097          	auipc	ra,0x0
 574:	e0a080e7          	jalr	-502(ra) # 37a <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 578:	0992                	slli	s3,s3,0x4
 57a:	397d                	addiw	s2,s2,-1
 57c:	fe0914e3          	bnez	s2,564 <vprintf+0x11c>
        printptr(fd, va_arg(ap, uint64));
 580:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 584:	4981                	li	s3,0
 586:	b70d                	j	4a8 <vprintf+0x60>
        s = va_arg(ap, char*);
 588:	008b0913          	addi	s2,s6,8
 58c:	000b3983          	ld	s3,0(s6)
        if(s == 0)
 590:	02098163          	beqz	s3,5b2 <vprintf+0x16a>
        while(*s != 0){
 594:	0009c583          	lbu	a1,0(s3)
 598:	c5ad                	beqz	a1,602 <vprintf+0x1ba>
          putc(fd, *s);
 59a:	8556                	mv	a0,s5
 59c:	00000097          	auipc	ra,0x0
 5a0:	dde080e7          	jalr	-546(ra) # 37a <putc>
          s++;
 5a4:	0985                	addi	s3,s3,1
        while(*s != 0){
 5a6:	0009c583          	lbu	a1,0(s3)
 5aa:	f9e5                	bnez	a1,59a <vprintf+0x152>
        s = va_arg(ap, char*);
 5ac:	8b4a                	mv	s6,s2
      state = 0;
 5ae:	4981                	li	s3,0
 5b0:	bde5                	j	4a8 <vprintf+0x60>
          s = "(null)";
 5b2:	00000997          	auipc	s3,0x0
 5b6:	27e98993          	addi	s3,s3,638 # 830 <malloc+0x124>
        while(*s != 0){
 5ba:	85ee                	mv	a1,s11
 5bc:	bff9                	j	59a <vprintf+0x152>
        putc(fd, va_arg(ap, uint));
 5be:	008b0913          	addi	s2,s6,8
 5c2:	000b4583          	lbu	a1,0(s6)
 5c6:	8556                	mv	a0,s5
 5c8:	00000097          	auipc	ra,0x0
 5cc:	db2080e7          	jalr	-590(ra) # 37a <putc>
 5d0:	8b4a                	mv	s6,s2
      state = 0;
 5d2:	4981                	li	s3,0
 5d4:	bdd1                	j	4a8 <vprintf+0x60>
        putc(fd, c);
 5d6:	85d2                	mv	a1,s4
 5d8:	8556                	mv	a0,s5
 5da:	00000097          	auipc	ra,0x0
 5de:	da0080e7          	jalr	-608(ra) # 37a <putc>
      state = 0;
 5e2:	4981                	li	s3,0
 5e4:	b5d1                	j	4a8 <vprintf+0x60>
        putc(fd, '%');
 5e6:	85d2                	mv	a1,s4
 5e8:	8556                	mv	a0,s5
 5ea:	00000097          	auipc	ra,0x0
 5ee:	d90080e7          	jalr	-624(ra) # 37a <putc>
        putc(fd, c);
 5f2:	85ca                	mv	a1,s2
 5f4:	8556                	mv	a0,s5
 5f6:	00000097          	auipc	ra,0x0
 5fa:	d84080e7          	jalr	-636(ra) # 37a <putc>
      state = 0;
 5fe:	4981                	li	s3,0
 600:	b565                	j	4a8 <vprintf+0x60>
        s = va_arg(ap, char*);
 602:	8b4a                	mv	s6,s2
      state = 0;
 604:	4981                	li	s3,0
 606:	b54d                	j	4a8 <vprintf+0x60>
    }
  }
}
 608:	70e6                	ld	ra,120(sp)
 60a:	7446                	ld	s0,112(sp)
 60c:	74a6                	ld	s1,104(sp)
 60e:	7906                	ld	s2,96(sp)
 610:	69e6                	ld	s3,88(sp)
 612:	6a46                	ld	s4,80(sp)
 614:	6aa6                	ld	s5,72(sp)
 616:	6b06                	ld	s6,64(sp)
 618:	7be2                	ld	s7,56(sp)
 61a:	7c42                	ld	s8,48(sp)
 61c:	7ca2                	ld	s9,40(sp)
 61e:	7d02                	ld	s10,32(sp)
 620:	6de2                	ld	s11,24(sp)
 622:	6109                	addi	sp,sp,128
 624:	8082                	ret

0000000000000626 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 626:	715d                	addi	sp,sp,-80
 628:	ec06                	sd	ra,24(sp)
 62a:	e822                	sd	s0,16(sp)
 62c:	1000                	addi	s0,sp,32
 62e:	e010                	sd	a2,0(s0)
 630:	e414                	sd	a3,8(s0)
 632:	e818                	sd	a4,16(s0)
 634:	ec1c                	sd	a5,24(s0)
 636:	03043023          	sd	a6,32(s0)
 63a:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 63e:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 642:	8622                	mv	a2,s0
 644:	00000097          	auipc	ra,0x0
 648:	e04080e7          	jalr	-508(ra) # 448 <vprintf>
}
 64c:	60e2                	ld	ra,24(sp)
 64e:	6442                	ld	s0,16(sp)
 650:	6161                	addi	sp,sp,80
 652:	8082                	ret

0000000000000654 <printf>:

void
printf(const char *fmt, ...)
{
 654:	711d                	addi	sp,sp,-96
 656:	ec06                	sd	ra,24(sp)
 658:	e822                	sd	s0,16(sp)
 65a:	1000                	addi	s0,sp,32
 65c:	e40c                	sd	a1,8(s0)
 65e:	e810                	sd	a2,16(s0)
 660:	ec14                	sd	a3,24(s0)
 662:	f018                	sd	a4,32(s0)
 664:	f41c                	sd	a5,40(s0)
 666:	03043823          	sd	a6,48(s0)
 66a:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 66e:	00840613          	addi	a2,s0,8
 672:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 676:	85aa                	mv	a1,a0
 678:	4505                	li	a0,1
 67a:	00000097          	auipc	ra,0x0
 67e:	dce080e7          	jalr	-562(ra) # 448 <vprintf>
}
 682:	60e2                	ld	ra,24(sp)
 684:	6442                	ld	s0,16(sp)
 686:	6125                	addi	sp,sp,96
 688:	8082                	ret

000000000000068a <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 68a:	1141                	addi	sp,sp,-16
 68c:	e422                	sd	s0,8(sp)
 68e:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 690:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 694:	00001797          	auipc	a5,0x1
 698:	96c7b783          	ld	a5,-1684(a5) # 1000 <freep>
 69c:	a02d                	j	6c6 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 69e:	4618                	lw	a4,8(a2)
 6a0:	9f2d                	addw	a4,a4,a1
 6a2:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 6a6:	6398                	ld	a4,0(a5)
 6a8:	6310                	ld	a2,0(a4)
 6aa:	a83d                	j	6e8 <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 6ac:	ff852703          	lw	a4,-8(a0)
 6b0:	9f31                	addw	a4,a4,a2
 6b2:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 6b4:	ff053683          	ld	a3,-16(a0)
 6b8:	a091                	j	6fc <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6ba:	6398                	ld	a4,0(a5)
 6bc:	00e7e463          	bltu	a5,a4,6c4 <free+0x3a>
 6c0:	00e6ea63          	bltu	a3,a4,6d4 <free+0x4a>
{
 6c4:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6c6:	fed7fae3          	bgeu	a5,a3,6ba <free+0x30>
 6ca:	6398                	ld	a4,0(a5)
 6cc:	00e6e463          	bltu	a3,a4,6d4 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6d0:	fee7eae3          	bltu	a5,a4,6c4 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 6d4:	ff852583          	lw	a1,-8(a0)
 6d8:	6390                	ld	a2,0(a5)
 6da:	02059813          	slli	a6,a1,0x20
 6de:	01c85713          	srli	a4,a6,0x1c
 6e2:	9736                	add	a4,a4,a3
 6e4:	fae60de3          	beq	a2,a4,69e <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 6e8:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 6ec:	4790                	lw	a2,8(a5)
 6ee:	02061593          	slli	a1,a2,0x20
 6f2:	01c5d713          	srli	a4,a1,0x1c
 6f6:	973e                	add	a4,a4,a5
 6f8:	fae68ae3          	beq	a3,a4,6ac <free+0x22>
    p->s.ptr = bp->s.ptr;
 6fc:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 6fe:	00001717          	auipc	a4,0x1
 702:	90f73123          	sd	a5,-1790(a4) # 1000 <freep>
}
 706:	6422                	ld	s0,8(sp)
 708:	0141                	addi	sp,sp,16
 70a:	8082                	ret

000000000000070c <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 70c:	7139                	addi	sp,sp,-64
 70e:	fc06                	sd	ra,56(sp)
 710:	f822                	sd	s0,48(sp)
 712:	f426                	sd	s1,40(sp)
 714:	f04a                	sd	s2,32(sp)
 716:	ec4e                	sd	s3,24(sp)
 718:	e852                	sd	s4,16(sp)
 71a:	e456                	sd	s5,8(sp)
 71c:	e05a                	sd	s6,0(sp)
 71e:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 720:	02051493          	slli	s1,a0,0x20
 724:	9081                	srli	s1,s1,0x20
 726:	04bd                	addi	s1,s1,15
 728:	8091                	srli	s1,s1,0x4
 72a:	0014899b          	addiw	s3,s1,1
 72e:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 730:	00001517          	auipc	a0,0x1
 734:	8d053503          	ld	a0,-1840(a0) # 1000 <freep>
 738:	c515                	beqz	a0,764 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 73a:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 73c:	4798                	lw	a4,8(a5)
 73e:	02977f63          	bgeu	a4,s1,77c <malloc+0x70>
 742:	8a4e                	mv	s4,s3
 744:	0009871b          	sext.w	a4,s3
 748:	6685                	lui	a3,0x1
 74a:	00d77363          	bgeu	a4,a3,750 <malloc+0x44>
 74e:	6a05                	lui	s4,0x1
 750:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 754:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 758:	00001917          	auipc	s2,0x1
 75c:	8a890913          	addi	s2,s2,-1880 # 1000 <freep>
  if(p == (char*)-1)
 760:	5afd                	li	s5,-1
 762:	a895                	j	7d6 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 764:	00001797          	auipc	a5,0x1
 768:	8ac78793          	addi	a5,a5,-1876 # 1010 <base>
 76c:	00001717          	auipc	a4,0x1
 770:	88f73a23          	sd	a5,-1900(a4) # 1000 <freep>
 774:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 776:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 77a:	b7e1                	j	742 <malloc+0x36>
      if(p->s.size == nunits)
 77c:	02e48c63          	beq	s1,a4,7b4 <malloc+0xa8>
        p->s.size -= nunits;
 780:	4137073b          	subw	a4,a4,s3
 784:	c798                	sw	a4,8(a5)
        p += p->s.size;
 786:	02071693          	slli	a3,a4,0x20
 78a:	01c6d713          	srli	a4,a3,0x1c
 78e:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 790:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 794:	00001717          	auipc	a4,0x1
 798:	86a73623          	sd	a0,-1940(a4) # 1000 <freep>
      return (void*)(p + 1);
 79c:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 7a0:	70e2                	ld	ra,56(sp)
 7a2:	7442                	ld	s0,48(sp)
 7a4:	74a2                	ld	s1,40(sp)
 7a6:	7902                	ld	s2,32(sp)
 7a8:	69e2                	ld	s3,24(sp)
 7aa:	6a42                	ld	s4,16(sp)
 7ac:	6aa2                	ld	s5,8(sp)
 7ae:	6b02                	ld	s6,0(sp)
 7b0:	6121                	addi	sp,sp,64
 7b2:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 7b4:	6398                	ld	a4,0(a5)
 7b6:	e118                	sd	a4,0(a0)
 7b8:	bff1                	j	794 <malloc+0x88>
  hp->s.size = nu;
 7ba:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 7be:	0541                	addi	a0,a0,16
 7c0:	00000097          	auipc	ra,0x0
 7c4:	eca080e7          	jalr	-310(ra) # 68a <free>
  return freep;
 7c8:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 7cc:	d971                	beqz	a0,7a0 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7ce:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7d0:	4798                	lw	a4,8(a5)
 7d2:	fa9775e3          	bgeu	a4,s1,77c <malloc+0x70>
    if(p == freep)
 7d6:	00093703          	ld	a4,0(s2)
 7da:	853e                	mv	a0,a5
 7dc:	fef719e3          	bne	a4,a5,7ce <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 7e0:	8552                	mv	a0,s4
 7e2:	00000097          	auipc	ra,0x0
 7e6:	b68080e7          	jalr	-1176(ra) # 34a <sbrk>
  if(p == (char*)-1)
 7ea:	fd5518e3          	bne	a0,s5,7ba <malloc+0xae>
        return 0;
 7ee:	4501                	li	a0,0
 7f0:	bf45                	j	7a0 <malloc+0x94>
