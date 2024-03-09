
user/_schedset:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char *argv[])
{
   0:	1141                	addi	sp,sp,-16
   2:	e406                	sd	ra,8(sp)
   4:	e022                	sd	s0,0(sp)
   6:	0800                	addi	s0,sp,16
    if (argc != 2)
   8:	4789                	li	a5,2
   a:	00f50f63          	beq	a0,a5,28 <main+0x28>
    {
        printf("Usage: schedset [SCHED ID]\n");
   e:	00001517          	auipc	a0,0x1
  12:	80250513          	addi	a0,a0,-2046 # 810 <malloc+0xf4>
  16:	00000097          	auipc	ra,0x0
  1a:	64e080e7          	jalr	1614(ra) # 664 <printf>
        exit(1);
  1e:	4505                	li	a0,1
  20:	00000097          	auipc	ra,0x0
  24:	2aa080e7          	jalr	682(ra) # 2ca <exit>
    }
    int schedid = (*argv[1]) - '0';
  28:	659c                	ld	a5,8(a1)
  2a:	0007c503          	lbu	a0,0(a5)
    schedset(schedid);
  2e:	fd05051b          	addiw	a0,a0,-48
  32:	00000097          	auipc	ra,0x0
  36:	348080e7          	jalr	840(ra) # 37a <schedset>
    exit(0);
  3a:	4501                	li	a0,0
  3c:	00000097          	auipc	ra,0x0
  40:	28e080e7          	jalr	654(ra) # 2ca <exit>

0000000000000044 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
  44:	1141                	addi	sp,sp,-16
  46:	e406                	sd	ra,8(sp)
  48:	e022                	sd	s0,0(sp)
  4a:	0800                	addi	s0,sp,16
  extern int main();
  main();
  4c:	00000097          	auipc	ra,0x0
  50:	fb4080e7          	jalr	-76(ra) # 0 <main>
  exit(0);
  54:	4501                	li	a0,0
  56:	00000097          	auipc	ra,0x0
  5a:	274080e7          	jalr	628(ra) # 2ca <exit>

000000000000005e <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
  5e:	1141                	addi	sp,sp,-16
  60:	e422                	sd	s0,8(sp)
  62:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  64:	87aa                	mv	a5,a0
  66:	0585                	addi	a1,a1,1
  68:	0785                	addi	a5,a5,1
  6a:	fff5c703          	lbu	a4,-1(a1)
  6e:	fee78fa3          	sb	a4,-1(a5)
  72:	fb75                	bnez	a4,66 <strcpy+0x8>
    ;
  return os;
}
  74:	6422                	ld	s0,8(sp)
  76:	0141                	addi	sp,sp,16
  78:	8082                	ret

000000000000007a <strcmp>:

int
strcmp(const char *p, const char *q)
{
  7a:	1141                	addi	sp,sp,-16
  7c:	e422                	sd	s0,8(sp)
  7e:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  80:	00054783          	lbu	a5,0(a0)
  84:	cb91                	beqz	a5,98 <strcmp+0x1e>
  86:	0005c703          	lbu	a4,0(a1)
  8a:	00f71763          	bne	a4,a5,98 <strcmp+0x1e>
    p++, q++;
  8e:	0505                	addi	a0,a0,1
  90:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  92:	00054783          	lbu	a5,0(a0)
  96:	fbe5                	bnez	a5,86 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  98:	0005c503          	lbu	a0,0(a1)
}
  9c:	40a7853b          	subw	a0,a5,a0
  a0:	6422                	ld	s0,8(sp)
  a2:	0141                	addi	sp,sp,16
  a4:	8082                	ret

00000000000000a6 <strlen>:

uint
strlen(const char *s)
{
  a6:	1141                	addi	sp,sp,-16
  a8:	e422                	sd	s0,8(sp)
  aa:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  ac:	00054783          	lbu	a5,0(a0)
  b0:	cf91                	beqz	a5,cc <strlen+0x26>
  b2:	0505                	addi	a0,a0,1
  b4:	87aa                	mv	a5,a0
  b6:	4685                	li	a3,1
  b8:	9e89                	subw	a3,a3,a0
  ba:	00f6853b          	addw	a0,a3,a5
  be:	0785                	addi	a5,a5,1
  c0:	fff7c703          	lbu	a4,-1(a5)
  c4:	fb7d                	bnez	a4,ba <strlen+0x14>
    ;
  return n;
}
  c6:	6422                	ld	s0,8(sp)
  c8:	0141                	addi	sp,sp,16
  ca:	8082                	ret
  for(n = 0; s[n]; n++)
  cc:	4501                	li	a0,0
  ce:	bfe5                	j	c6 <strlen+0x20>

00000000000000d0 <memset>:

void*
memset(void *dst, int c, uint n)
{
  d0:	1141                	addi	sp,sp,-16
  d2:	e422                	sd	s0,8(sp)
  d4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
  d6:	ca19                	beqz	a2,ec <memset+0x1c>
  d8:	87aa                	mv	a5,a0
  da:	1602                	slli	a2,a2,0x20
  dc:	9201                	srli	a2,a2,0x20
  de:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
  e2:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
  e6:	0785                	addi	a5,a5,1
  e8:	fee79de3          	bne	a5,a4,e2 <memset+0x12>
  }
  return dst;
}
  ec:	6422                	ld	s0,8(sp)
  ee:	0141                	addi	sp,sp,16
  f0:	8082                	ret

00000000000000f2 <strchr>:

char*
strchr(const char *s, char c)
{
  f2:	1141                	addi	sp,sp,-16
  f4:	e422                	sd	s0,8(sp)
  f6:	0800                	addi	s0,sp,16
  for(; *s; s++)
  f8:	00054783          	lbu	a5,0(a0)
  fc:	cb99                	beqz	a5,112 <strchr+0x20>
    if(*s == c)
  fe:	00f58763          	beq	a1,a5,10c <strchr+0x1a>
  for(; *s; s++)
 102:	0505                	addi	a0,a0,1
 104:	00054783          	lbu	a5,0(a0)
 108:	fbfd                	bnez	a5,fe <strchr+0xc>
      return (char*)s;
  return 0;
 10a:	4501                	li	a0,0
}
 10c:	6422                	ld	s0,8(sp)
 10e:	0141                	addi	sp,sp,16
 110:	8082                	ret
  return 0;
 112:	4501                	li	a0,0
 114:	bfe5                	j	10c <strchr+0x1a>

0000000000000116 <gets>:

char*
gets(char *buf, int max)
{
 116:	711d                	addi	sp,sp,-96
 118:	ec86                	sd	ra,88(sp)
 11a:	e8a2                	sd	s0,80(sp)
 11c:	e4a6                	sd	s1,72(sp)
 11e:	e0ca                	sd	s2,64(sp)
 120:	fc4e                	sd	s3,56(sp)
 122:	f852                	sd	s4,48(sp)
 124:	f456                	sd	s5,40(sp)
 126:	f05a                	sd	s6,32(sp)
 128:	ec5e                	sd	s7,24(sp)
 12a:	1080                	addi	s0,sp,96
 12c:	8baa                	mv	s7,a0
 12e:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 130:	892a                	mv	s2,a0
 132:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 134:	4aa9                	li	s5,10
 136:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 138:	89a6                	mv	s3,s1
 13a:	2485                	addiw	s1,s1,1
 13c:	0344d863          	bge	s1,s4,16c <gets+0x56>
    cc = read(0, &c, 1);
 140:	4605                	li	a2,1
 142:	faf40593          	addi	a1,s0,-81
 146:	4501                	li	a0,0
 148:	00000097          	auipc	ra,0x0
 14c:	19a080e7          	jalr	410(ra) # 2e2 <read>
    if(cc < 1)
 150:	00a05e63          	blez	a0,16c <gets+0x56>
    buf[i++] = c;
 154:	faf44783          	lbu	a5,-81(s0)
 158:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 15c:	01578763          	beq	a5,s5,16a <gets+0x54>
 160:	0905                	addi	s2,s2,1
 162:	fd679be3          	bne	a5,s6,138 <gets+0x22>
  for(i=0; i+1 < max; ){
 166:	89a6                	mv	s3,s1
 168:	a011                	j	16c <gets+0x56>
 16a:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 16c:	99de                	add	s3,s3,s7
 16e:	00098023          	sb	zero,0(s3)
  return buf;
}
 172:	855e                	mv	a0,s7
 174:	60e6                	ld	ra,88(sp)
 176:	6446                	ld	s0,80(sp)
 178:	64a6                	ld	s1,72(sp)
 17a:	6906                	ld	s2,64(sp)
 17c:	79e2                	ld	s3,56(sp)
 17e:	7a42                	ld	s4,48(sp)
 180:	7aa2                	ld	s5,40(sp)
 182:	7b02                	ld	s6,32(sp)
 184:	6be2                	ld	s7,24(sp)
 186:	6125                	addi	sp,sp,96
 188:	8082                	ret

000000000000018a <stat>:

int
stat(const char *n, struct stat *st)
{
 18a:	1101                	addi	sp,sp,-32
 18c:	ec06                	sd	ra,24(sp)
 18e:	e822                	sd	s0,16(sp)
 190:	e426                	sd	s1,8(sp)
 192:	e04a                	sd	s2,0(sp)
 194:	1000                	addi	s0,sp,32
 196:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 198:	4581                	li	a1,0
 19a:	00000097          	auipc	ra,0x0
 19e:	170080e7          	jalr	368(ra) # 30a <open>
  if(fd < 0)
 1a2:	02054563          	bltz	a0,1cc <stat+0x42>
 1a6:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 1a8:	85ca                	mv	a1,s2
 1aa:	00000097          	auipc	ra,0x0
 1ae:	178080e7          	jalr	376(ra) # 322 <fstat>
 1b2:	892a                	mv	s2,a0
  close(fd);
 1b4:	8526                	mv	a0,s1
 1b6:	00000097          	auipc	ra,0x0
 1ba:	13c080e7          	jalr	316(ra) # 2f2 <close>
  return r;
}
 1be:	854a                	mv	a0,s2
 1c0:	60e2                	ld	ra,24(sp)
 1c2:	6442                	ld	s0,16(sp)
 1c4:	64a2                	ld	s1,8(sp)
 1c6:	6902                	ld	s2,0(sp)
 1c8:	6105                	addi	sp,sp,32
 1ca:	8082                	ret
    return -1;
 1cc:	597d                	li	s2,-1
 1ce:	bfc5                	j	1be <stat+0x34>

00000000000001d0 <atoi>:

int
atoi(const char *s)
{
 1d0:	1141                	addi	sp,sp,-16
 1d2:	e422                	sd	s0,8(sp)
 1d4:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 1d6:	00054683          	lbu	a3,0(a0)
 1da:	fd06879b          	addiw	a5,a3,-48
 1de:	0ff7f793          	zext.b	a5,a5
 1e2:	4625                	li	a2,9
 1e4:	02f66863          	bltu	a2,a5,214 <atoi+0x44>
 1e8:	872a                	mv	a4,a0
  n = 0;
 1ea:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 1ec:	0705                	addi	a4,a4,1
 1ee:	0025179b          	slliw	a5,a0,0x2
 1f2:	9fa9                	addw	a5,a5,a0
 1f4:	0017979b          	slliw	a5,a5,0x1
 1f8:	9fb5                	addw	a5,a5,a3
 1fa:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 1fe:	00074683          	lbu	a3,0(a4)
 202:	fd06879b          	addiw	a5,a3,-48
 206:	0ff7f793          	zext.b	a5,a5
 20a:	fef671e3          	bgeu	a2,a5,1ec <atoi+0x1c>
  return n;
}
 20e:	6422                	ld	s0,8(sp)
 210:	0141                	addi	sp,sp,16
 212:	8082                	ret
  n = 0;
 214:	4501                	li	a0,0
 216:	bfe5                	j	20e <atoi+0x3e>

0000000000000218 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 218:	1141                	addi	sp,sp,-16
 21a:	e422                	sd	s0,8(sp)
 21c:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 21e:	02b57463          	bgeu	a0,a1,246 <memmove+0x2e>
    while(n-- > 0)
 222:	00c05f63          	blez	a2,240 <memmove+0x28>
 226:	1602                	slli	a2,a2,0x20
 228:	9201                	srli	a2,a2,0x20
 22a:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 22e:	872a                	mv	a4,a0
      *dst++ = *src++;
 230:	0585                	addi	a1,a1,1
 232:	0705                	addi	a4,a4,1
 234:	fff5c683          	lbu	a3,-1(a1)
 238:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 23c:	fee79ae3          	bne	a5,a4,230 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 240:	6422                	ld	s0,8(sp)
 242:	0141                	addi	sp,sp,16
 244:	8082                	ret
    dst += n;
 246:	00c50733          	add	a4,a0,a2
    src += n;
 24a:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 24c:	fec05ae3          	blez	a2,240 <memmove+0x28>
 250:	fff6079b          	addiw	a5,a2,-1
 254:	1782                	slli	a5,a5,0x20
 256:	9381                	srli	a5,a5,0x20
 258:	fff7c793          	not	a5,a5
 25c:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 25e:	15fd                	addi	a1,a1,-1
 260:	177d                	addi	a4,a4,-1
 262:	0005c683          	lbu	a3,0(a1)
 266:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 26a:	fee79ae3          	bne	a5,a4,25e <memmove+0x46>
 26e:	bfc9                	j	240 <memmove+0x28>

0000000000000270 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 270:	1141                	addi	sp,sp,-16
 272:	e422                	sd	s0,8(sp)
 274:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 276:	ca05                	beqz	a2,2a6 <memcmp+0x36>
 278:	fff6069b          	addiw	a3,a2,-1
 27c:	1682                	slli	a3,a3,0x20
 27e:	9281                	srli	a3,a3,0x20
 280:	0685                	addi	a3,a3,1
 282:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 284:	00054783          	lbu	a5,0(a0)
 288:	0005c703          	lbu	a4,0(a1)
 28c:	00e79863          	bne	a5,a4,29c <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 290:	0505                	addi	a0,a0,1
    p2++;
 292:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 294:	fed518e3          	bne	a0,a3,284 <memcmp+0x14>
  }
  return 0;
 298:	4501                	li	a0,0
 29a:	a019                	j	2a0 <memcmp+0x30>
      return *p1 - *p2;
 29c:	40e7853b          	subw	a0,a5,a4
}
 2a0:	6422                	ld	s0,8(sp)
 2a2:	0141                	addi	sp,sp,16
 2a4:	8082                	ret
  return 0;
 2a6:	4501                	li	a0,0
 2a8:	bfe5                	j	2a0 <memcmp+0x30>

00000000000002aa <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 2aa:	1141                	addi	sp,sp,-16
 2ac:	e406                	sd	ra,8(sp)
 2ae:	e022                	sd	s0,0(sp)
 2b0:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 2b2:	00000097          	auipc	ra,0x0
 2b6:	f66080e7          	jalr	-154(ra) # 218 <memmove>
}
 2ba:	60a2                	ld	ra,8(sp)
 2bc:	6402                	ld	s0,0(sp)
 2be:	0141                	addi	sp,sp,16
 2c0:	8082                	ret

00000000000002c2 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 2c2:	4885                	li	a7,1
 ecall
 2c4:	00000073          	ecall
 ret
 2c8:	8082                	ret

00000000000002ca <exit>:
.global exit
exit:
 li a7, SYS_exit
 2ca:	4889                	li	a7,2
 ecall
 2cc:	00000073          	ecall
 ret
 2d0:	8082                	ret

00000000000002d2 <wait>:
.global wait
wait:
 li a7, SYS_wait
 2d2:	488d                	li	a7,3
 ecall
 2d4:	00000073          	ecall
 ret
 2d8:	8082                	ret

00000000000002da <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 2da:	4891                	li	a7,4
 ecall
 2dc:	00000073          	ecall
 ret
 2e0:	8082                	ret

00000000000002e2 <read>:
.global read
read:
 li a7, SYS_read
 2e2:	4895                	li	a7,5
 ecall
 2e4:	00000073          	ecall
 ret
 2e8:	8082                	ret

00000000000002ea <write>:
.global write
write:
 li a7, SYS_write
 2ea:	48c1                	li	a7,16
 ecall
 2ec:	00000073          	ecall
 ret
 2f0:	8082                	ret

00000000000002f2 <close>:
.global close
close:
 li a7, SYS_close
 2f2:	48d5                	li	a7,21
 ecall
 2f4:	00000073          	ecall
 ret
 2f8:	8082                	ret

00000000000002fa <kill>:
.global kill
kill:
 li a7, SYS_kill
 2fa:	4899                	li	a7,6
 ecall
 2fc:	00000073          	ecall
 ret
 300:	8082                	ret

0000000000000302 <exec>:
.global exec
exec:
 li a7, SYS_exec
 302:	489d                	li	a7,7
 ecall
 304:	00000073          	ecall
 ret
 308:	8082                	ret

000000000000030a <open>:
.global open
open:
 li a7, SYS_open
 30a:	48bd                	li	a7,15
 ecall
 30c:	00000073          	ecall
 ret
 310:	8082                	ret

0000000000000312 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 312:	48c5                	li	a7,17
 ecall
 314:	00000073          	ecall
 ret
 318:	8082                	ret

000000000000031a <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 31a:	48c9                	li	a7,18
 ecall
 31c:	00000073          	ecall
 ret
 320:	8082                	ret

0000000000000322 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 322:	48a1                	li	a7,8
 ecall
 324:	00000073          	ecall
 ret
 328:	8082                	ret

000000000000032a <link>:
.global link
link:
 li a7, SYS_link
 32a:	48cd                	li	a7,19
 ecall
 32c:	00000073          	ecall
 ret
 330:	8082                	ret

0000000000000332 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 332:	48d1                	li	a7,20
 ecall
 334:	00000073          	ecall
 ret
 338:	8082                	ret

000000000000033a <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 33a:	48a5                	li	a7,9
 ecall
 33c:	00000073          	ecall
 ret
 340:	8082                	ret

0000000000000342 <dup>:
.global dup
dup:
 li a7, SYS_dup
 342:	48a9                	li	a7,10
 ecall
 344:	00000073          	ecall
 ret
 348:	8082                	ret

000000000000034a <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 34a:	48ad                	li	a7,11
 ecall
 34c:	00000073          	ecall
 ret
 350:	8082                	ret

0000000000000352 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 352:	48b1                	li	a7,12
 ecall
 354:	00000073          	ecall
 ret
 358:	8082                	ret

000000000000035a <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 35a:	48b5                	li	a7,13
 ecall
 35c:	00000073          	ecall
 ret
 360:	8082                	ret

0000000000000362 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 362:	48b9                	li	a7,14
 ecall
 364:	00000073          	ecall
 ret
 368:	8082                	ret

000000000000036a <ps>:
.global ps
ps:
 li a7, SYS_ps
 36a:	48d9                	li	a7,22
 ecall
 36c:	00000073          	ecall
 ret
 370:	8082                	ret

0000000000000372 <schedls>:
.global schedls
schedls:
 li a7, SYS_schedls
 372:	48dd                	li	a7,23
 ecall
 374:	00000073          	ecall
 ret
 378:	8082                	ret

000000000000037a <schedset>:
.global schedset
schedset:
 li a7, SYS_schedset
 37a:	48e1                	li	a7,24
 ecall
 37c:	00000073          	ecall
 ret
 380:	8082                	ret

0000000000000382 <yield>:
.global yield
yield:
 li a7, SYS_yield
 382:	48e5                	li	a7,25
 ecall
 384:	00000073          	ecall
 ret
 388:	8082                	ret

000000000000038a <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 38a:	1101                	addi	sp,sp,-32
 38c:	ec06                	sd	ra,24(sp)
 38e:	e822                	sd	s0,16(sp)
 390:	1000                	addi	s0,sp,32
 392:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 396:	4605                	li	a2,1
 398:	fef40593          	addi	a1,s0,-17
 39c:	00000097          	auipc	ra,0x0
 3a0:	f4e080e7          	jalr	-178(ra) # 2ea <write>
}
 3a4:	60e2                	ld	ra,24(sp)
 3a6:	6442                	ld	s0,16(sp)
 3a8:	6105                	addi	sp,sp,32
 3aa:	8082                	ret

00000000000003ac <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 3ac:	7139                	addi	sp,sp,-64
 3ae:	fc06                	sd	ra,56(sp)
 3b0:	f822                	sd	s0,48(sp)
 3b2:	f426                	sd	s1,40(sp)
 3b4:	f04a                	sd	s2,32(sp)
 3b6:	ec4e                	sd	s3,24(sp)
 3b8:	0080                	addi	s0,sp,64
 3ba:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 3bc:	c299                	beqz	a3,3c2 <printint+0x16>
 3be:	0805c963          	bltz	a1,450 <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 3c2:	2581                	sext.w	a1,a1
  neg = 0;
 3c4:	4881                	li	a7,0
 3c6:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 3ca:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 3cc:	2601                	sext.w	a2,a2
 3ce:	00000517          	auipc	a0,0x0
 3d2:	4c250513          	addi	a0,a0,1218 # 890 <digits>
 3d6:	883a                	mv	a6,a4
 3d8:	2705                	addiw	a4,a4,1
 3da:	02c5f7bb          	remuw	a5,a1,a2
 3de:	1782                	slli	a5,a5,0x20
 3e0:	9381                	srli	a5,a5,0x20
 3e2:	97aa                	add	a5,a5,a0
 3e4:	0007c783          	lbu	a5,0(a5)
 3e8:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 3ec:	0005879b          	sext.w	a5,a1
 3f0:	02c5d5bb          	divuw	a1,a1,a2
 3f4:	0685                	addi	a3,a3,1
 3f6:	fec7f0e3          	bgeu	a5,a2,3d6 <printint+0x2a>
  if(neg)
 3fa:	00088c63          	beqz	a7,412 <printint+0x66>
    buf[i++] = '-';
 3fe:	fd070793          	addi	a5,a4,-48
 402:	00878733          	add	a4,a5,s0
 406:	02d00793          	li	a5,45
 40a:	fef70823          	sb	a5,-16(a4)
 40e:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 412:	02e05863          	blez	a4,442 <printint+0x96>
 416:	fc040793          	addi	a5,s0,-64
 41a:	00e78933          	add	s2,a5,a4
 41e:	fff78993          	addi	s3,a5,-1
 422:	99ba                	add	s3,s3,a4
 424:	377d                	addiw	a4,a4,-1
 426:	1702                	slli	a4,a4,0x20
 428:	9301                	srli	a4,a4,0x20
 42a:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 42e:	fff94583          	lbu	a1,-1(s2)
 432:	8526                	mv	a0,s1
 434:	00000097          	auipc	ra,0x0
 438:	f56080e7          	jalr	-170(ra) # 38a <putc>
  while(--i >= 0)
 43c:	197d                	addi	s2,s2,-1
 43e:	ff3918e3          	bne	s2,s3,42e <printint+0x82>
}
 442:	70e2                	ld	ra,56(sp)
 444:	7442                	ld	s0,48(sp)
 446:	74a2                	ld	s1,40(sp)
 448:	7902                	ld	s2,32(sp)
 44a:	69e2                	ld	s3,24(sp)
 44c:	6121                	addi	sp,sp,64
 44e:	8082                	ret
    x = -xx;
 450:	40b005bb          	negw	a1,a1
    neg = 1;
 454:	4885                	li	a7,1
    x = -xx;
 456:	bf85                	j	3c6 <printint+0x1a>

0000000000000458 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 458:	7119                	addi	sp,sp,-128
 45a:	fc86                	sd	ra,120(sp)
 45c:	f8a2                	sd	s0,112(sp)
 45e:	f4a6                	sd	s1,104(sp)
 460:	f0ca                	sd	s2,96(sp)
 462:	ecce                	sd	s3,88(sp)
 464:	e8d2                	sd	s4,80(sp)
 466:	e4d6                	sd	s5,72(sp)
 468:	e0da                	sd	s6,64(sp)
 46a:	fc5e                	sd	s7,56(sp)
 46c:	f862                	sd	s8,48(sp)
 46e:	f466                	sd	s9,40(sp)
 470:	f06a                	sd	s10,32(sp)
 472:	ec6e                	sd	s11,24(sp)
 474:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 476:	0005c903          	lbu	s2,0(a1)
 47a:	18090f63          	beqz	s2,618 <vprintf+0x1c0>
 47e:	8aaa                	mv	s5,a0
 480:	8b32                	mv	s6,a2
 482:	00158493          	addi	s1,a1,1
  state = 0;
 486:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 488:	02500a13          	li	s4,37
 48c:	4c55                	li	s8,21
 48e:	00000c97          	auipc	s9,0x0
 492:	3aac8c93          	addi	s9,s9,938 # 838 <malloc+0x11c>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
        s = va_arg(ap, char*);
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 496:	02800d93          	li	s11,40
  putc(fd, 'x');
 49a:	4d41                	li	s10,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 49c:	00000b97          	auipc	s7,0x0
 4a0:	3f4b8b93          	addi	s7,s7,1012 # 890 <digits>
 4a4:	a839                	j	4c2 <vprintf+0x6a>
        putc(fd, c);
 4a6:	85ca                	mv	a1,s2
 4a8:	8556                	mv	a0,s5
 4aa:	00000097          	auipc	ra,0x0
 4ae:	ee0080e7          	jalr	-288(ra) # 38a <putc>
 4b2:	a019                	j	4b8 <vprintf+0x60>
    } else if(state == '%'){
 4b4:	01498d63          	beq	s3,s4,4ce <vprintf+0x76>
  for(i = 0; fmt[i]; i++){
 4b8:	0485                	addi	s1,s1,1
 4ba:	fff4c903          	lbu	s2,-1(s1)
 4be:	14090d63          	beqz	s2,618 <vprintf+0x1c0>
    if(state == 0){
 4c2:	fe0999e3          	bnez	s3,4b4 <vprintf+0x5c>
      if(c == '%'){
 4c6:	ff4910e3          	bne	s2,s4,4a6 <vprintf+0x4e>
        state = '%';
 4ca:	89d2                	mv	s3,s4
 4cc:	b7f5                	j	4b8 <vprintf+0x60>
      if(c == 'd'){
 4ce:	11490c63          	beq	s2,s4,5e6 <vprintf+0x18e>
 4d2:	f9d9079b          	addiw	a5,s2,-99
 4d6:	0ff7f793          	zext.b	a5,a5
 4da:	10fc6e63          	bltu	s8,a5,5f6 <vprintf+0x19e>
 4de:	f9d9079b          	addiw	a5,s2,-99
 4e2:	0ff7f713          	zext.b	a4,a5
 4e6:	10ec6863          	bltu	s8,a4,5f6 <vprintf+0x19e>
 4ea:	00271793          	slli	a5,a4,0x2
 4ee:	97e6                	add	a5,a5,s9
 4f0:	439c                	lw	a5,0(a5)
 4f2:	97e6                	add	a5,a5,s9
 4f4:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 4f6:	008b0913          	addi	s2,s6,8
 4fa:	4685                	li	a3,1
 4fc:	4629                	li	a2,10
 4fe:	000b2583          	lw	a1,0(s6)
 502:	8556                	mv	a0,s5
 504:	00000097          	auipc	ra,0x0
 508:	ea8080e7          	jalr	-344(ra) # 3ac <printint>
 50c:	8b4a                	mv	s6,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 50e:	4981                	li	s3,0
 510:	b765                	j	4b8 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 512:	008b0913          	addi	s2,s6,8
 516:	4681                	li	a3,0
 518:	4629                	li	a2,10
 51a:	000b2583          	lw	a1,0(s6)
 51e:	8556                	mv	a0,s5
 520:	00000097          	auipc	ra,0x0
 524:	e8c080e7          	jalr	-372(ra) # 3ac <printint>
 528:	8b4a                	mv	s6,s2
      state = 0;
 52a:	4981                	li	s3,0
 52c:	b771                	j	4b8 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 52e:	008b0913          	addi	s2,s6,8
 532:	4681                	li	a3,0
 534:	866a                	mv	a2,s10
 536:	000b2583          	lw	a1,0(s6)
 53a:	8556                	mv	a0,s5
 53c:	00000097          	auipc	ra,0x0
 540:	e70080e7          	jalr	-400(ra) # 3ac <printint>
 544:	8b4a                	mv	s6,s2
      state = 0;
 546:	4981                	li	s3,0
 548:	bf85                	j	4b8 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 54a:	008b0793          	addi	a5,s6,8
 54e:	f8f43423          	sd	a5,-120(s0)
 552:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 556:	03000593          	li	a1,48
 55a:	8556                	mv	a0,s5
 55c:	00000097          	auipc	ra,0x0
 560:	e2e080e7          	jalr	-466(ra) # 38a <putc>
  putc(fd, 'x');
 564:	07800593          	li	a1,120
 568:	8556                	mv	a0,s5
 56a:	00000097          	auipc	ra,0x0
 56e:	e20080e7          	jalr	-480(ra) # 38a <putc>
 572:	896a                	mv	s2,s10
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 574:	03c9d793          	srli	a5,s3,0x3c
 578:	97de                	add	a5,a5,s7
 57a:	0007c583          	lbu	a1,0(a5)
 57e:	8556                	mv	a0,s5
 580:	00000097          	auipc	ra,0x0
 584:	e0a080e7          	jalr	-502(ra) # 38a <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 588:	0992                	slli	s3,s3,0x4
 58a:	397d                	addiw	s2,s2,-1
 58c:	fe0914e3          	bnez	s2,574 <vprintf+0x11c>
        printptr(fd, va_arg(ap, uint64));
 590:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 594:	4981                	li	s3,0
 596:	b70d                	j	4b8 <vprintf+0x60>
        s = va_arg(ap, char*);
 598:	008b0913          	addi	s2,s6,8
 59c:	000b3983          	ld	s3,0(s6)
        if(s == 0)
 5a0:	02098163          	beqz	s3,5c2 <vprintf+0x16a>
        while(*s != 0){
 5a4:	0009c583          	lbu	a1,0(s3)
 5a8:	c5ad                	beqz	a1,612 <vprintf+0x1ba>
          putc(fd, *s);
 5aa:	8556                	mv	a0,s5
 5ac:	00000097          	auipc	ra,0x0
 5b0:	dde080e7          	jalr	-546(ra) # 38a <putc>
          s++;
 5b4:	0985                	addi	s3,s3,1
        while(*s != 0){
 5b6:	0009c583          	lbu	a1,0(s3)
 5ba:	f9e5                	bnez	a1,5aa <vprintf+0x152>
        s = va_arg(ap, char*);
 5bc:	8b4a                	mv	s6,s2
      state = 0;
 5be:	4981                	li	s3,0
 5c0:	bde5                	j	4b8 <vprintf+0x60>
          s = "(null)";
 5c2:	00000997          	auipc	s3,0x0
 5c6:	26e98993          	addi	s3,s3,622 # 830 <malloc+0x114>
        while(*s != 0){
 5ca:	85ee                	mv	a1,s11
 5cc:	bff9                	j	5aa <vprintf+0x152>
        putc(fd, va_arg(ap, uint));
 5ce:	008b0913          	addi	s2,s6,8
 5d2:	000b4583          	lbu	a1,0(s6)
 5d6:	8556                	mv	a0,s5
 5d8:	00000097          	auipc	ra,0x0
 5dc:	db2080e7          	jalr	-590(ra) # 38a <putc>
 5e0:	8b4a                	mv	s6,s2
      state = 0;
 5e2:	4981                	li	s3,0
 5e4:	bdd1                	j	4b8 <vprintf+0x60>
        putc(fd, c);
 5e6:	85d2                	mv	a1,s4
 5e8:	8556                	mv	a0,s5
 5ea:	00000097          	auipc	ra,0x0
 5ee:	da0080e7          	jalr	-608(ra) # 38a <putc>
      state = 0;
 5f2:	4981                	li	s3,0
 5f4:	b5d1                	j	4b8 <vprintf+0x60>
        putc(fd, '%');
 5f6:	85d2                	mv	a1,s4
 5f8:	8556                	mv	a0,s5
 5fa:	00000097          	auipc	ra,0x0
 5fe:	d90080e7          	jalr	-624(ra) # 38a <putc>
        putc(fd, c);
 602:	85ca                	mv	a1,s2
 604:	8556                	mv	a0,s5
 606:	00000097          	auipc	ra,0x0
 60a:	d84080e7          	jalr	-636(ra) # 38a <putc>
      state = 0;
 60e:	4981                	li	s3,0
 610:	b565                	j	4b8 <vprintf+0x60>
        s = va_arg(ap, char*);
 612:	8b4a                	mv	s6,s2
      state = 0;
 614:	4981                	li	s3,0
 616:	b54d                	j	4b8 <vprintf+0x60>
    }
  }
}
 618:	70e6                	ld	ra,120(sp)
 61a:	7446                	ld	s0,112(sp)
 61c:	74a6                	ld	s1,104(sp)
 61e:	7906                	ld	s2,96(sp)
 620:	69e6                	ld	s3,88(sp)
 622:	6a46                	ld	s4,80(sp)
 624:	6aa6                	ld	s5,72(sp)
 626:	6b06                	ld	s6,64(sp)
 628:	7be2                	ld	s7,56(sp)
 62a:	7c42                	ld	s8,48(sp)
 62c:	7ca2                	ld	s9,40(sp)
 62e:	7d02                	ld	s10,32(sp)
 630:	6de2                	ld	s11,24(sp)
 632:	6109                	addi	sp,sp,128
 634:	8082                	ret

0000000000000636 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 636:	715d                	addi	sp,sp,-80
 638:	ec06                	sd	ra,24(sp)
 63a:	e822                	sd	s0,16(sp)
 63c:	1000                	addi	s0,sp,32
 63e:	e010                	sd	a2,0(s0)
 640:	e414                	sd	a3,8(s0)
 642:	e818                	sd	a4,16(s0)
 644:	ec1c                	sd	a5,24(s0)
 646:	03043023          	sd	a6,32(s0)
 64a:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 64e:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 652:	8622                	mv	a2,s0
 654:	00000097          	auipc	ra,0x0
 658:	e04080e7          	jalr	-508(ra) # 458 <vprintf>
}
 65c:	60e2                	ld	ra,24(sp)
 65e:	6442                	ld	s0,16(sp)
 660:	6161                	addi	sp,sp,80
 662:	8082                	ret

0000000000000664 <printf>:

void
printf(const char *fmt, ...)
{
 664:	711d                	addi	sp,sp,-96
 666:	ec06                	sd	ra,24(sp)
 668:	e822                	sd	s0,16(sp)
 66a:	1000                	addi	s0,sp,32
 66c:	e40c                	sd	a1,8(s0)
 66e:	e810                	sd	a2,16(s0)
 670:	ec14                	sd	a3,24(s0)
 672:	f018                	sd	a4,32(s0)
 674:	f41c                	sd	a5,40(s0)
 676:	03043823          	sd	a6,48(s0)
 67a:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 67e:	00840613          	addi	a2,s0,8
 682:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 686:	85aa                	mv	a1,a0
 688:	4505                	li	a0,1
 68a:	00000097          	auipc	ra,0x0
 68e:	dce080e7          	jalr	-562(ra) # 458 <vprintf>
}
 692:	60e2                	ld	ra,24(sp)
 694:	6442                	ld	s0,16(sp)
 696:	6125                	addi	sp,sp,96
 698:	8082                	ret

000000000000069a <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 69a:	1141                	addi	sp,sp,-16
 69c:	e422                	sd	s0,8(sp)
 69e:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 6a0:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6a4:	00001797          	auipc	a5,0x1
 6a8:	95c7b783          	ld	a5,-1700(a5) # 1000 <freep>
 6ac:	a02d                	j	6d6 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 6ae:	4618                	lw	a4,8(a2)
 6b0:	9f2d                	addw	a4,a4,a1
 6b2:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 6b6:	6398                	ld	a4,0(a5)
 6b8:	6310                	ld	a2,0(a4)
 6ba:	a83d                	j	6f8 <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 6bc:	ff852703          	lw	a4,-8(a0)
 6c0:	9f31                	addw	a4,a4,a2
 6c2:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 6c4:	ff053683          	ld	a3,-16(a0)
 6c8:	a091                	j	70c <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6ca:	6398                	ld	a4,0(a5)
 6cc:	00e7e463          	bltu	a5,a4,6d4 <free+0x3a>
 6d0:	00e6ea63          	bltu	a3,a4,6e4 <free+0x4a>
{
 6d4:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6d6:	fed7fae3          	bgeu	a5,a3,6ca <free+0x30>
 6da:	6398                	ld	a4,0(a5)
 6dc:	00e6e463          	bltu	a3,a4,6e4 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6e0:	fee7eae3          	bltu	a5,a4,6d4 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 6e4:	ff852583          	lw	a1,-8(a0)
 6e8:	6390                	ld	a2,0(a5)
 6ea:	02059813          	slli	a6,a1,0x20
 6ee:	01c85713          	srli	a4,a6,0x1c
 6f2:	9736                	add	a4,a4,a3
 6f4:	fae60de3          	beq	a2,a4,6ae <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 6f8:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 6fc:	4790                	lw	a2,8(a5)
 6fe:	02061593          	slli	a1,a2,0x20
 702:	01c5d713          	srli	a4,a1,0x1c
 706:	973e                	add	a4,a4,a5
 708:	fae68ae3          	beq	a3,a4,6bc <free+0x22>
    p->s.ptr = bp->s.ptr;
 70c:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 70e:	00001717          	auipc	a4,0x1
 712:	8ef73923          	sd	a5,-1806(a4) # 1000 <freep>
}
 716:	6422                	ld	s0,8(sp)
 718:	0141                	addi	sp,sp,16
 71a:	8082                	ret

000000000000071c <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 71c:	7139                	addi	sp,sp,-64
 71e:	fc06                	sd	ra,56(sp)
 720:	f822                	sd	s0,48(sp)
 722:	f426                	sd	s1,40(sp)
 724:	f04a                	sd	s2,32(sp)
 726:	ec4e                	sd	s3,24(sp)
 728:	e852                	sd	s4,16(sp)
 72a:	e456                	sd	s5,8(sp)
 72c:	e05a                	sd	s6,0(sp)
 72e:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 730:	02051493          	slli	s1,a0,0x20
 734:	9081                	srli	s1,s1,0x20
 736:	04bd                	addi	s1,s1,15
 738:	8091                	srli	s1,s1,0x4
 73a:	0014899b          	addiw	s3,s1,1
 73e:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 740:	00001517          	auipc	a0,0x1
 744:	8c053503          	ld	a0,-1856(a0) # 1000 <freep>
 748:	c515                	beqz	a0,774 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 74a:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 74c:	4798                	lw	a4,8(a5)
 74e:	02977f63          	bgeu	a4,s1,78c <malloc+0x70>
 752:	8a4e                	mv	s4,s3
 754:	0009871b          	sext.w	a4,s3
 758:	6685                	lui	a3,0x1
 75a:	00d77363          	bgeu	a4,a3,760 <malloc+0x44>
 75e:	6a05                	lui	s4,0x1
 760:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 764:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 768:	00001917          	auipc	s2,0x1
 76c:	89890913          	addi	s2,s2,-1896 # 1000 <freep>
  if(p == (char*)-1)
 770:	5afd                	li	s5,-1
 772:	a895                	j	7e6 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 774:	00001797          	auipc	a5,0x1
 778:	89c78793          	addi	a5,a5,-1892 # 1010 <base>
 77c:	00001717          	auipc	a4,0x1
 780:	88f73223          	sd	a5,-1916(a4) # 1000 <freep>
 784:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 786:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 78a:	b7e1                	j	752 <malloc+0x36>
      if(p->s.size == nunits)
 78c:	02e48c63          	beq	s1,a4,7c4 <malloc+0xa8>
        p->s.size -= nunits;
 790:	4137073b          	subw	a4,a4,s3
 794:	c798                	sw	a4,8(a5)
        p += p->s.size;
 796:	02071693          	slli	a3,a4,0x20
 79a:	01c6d713          	srli	a4,a3,0x1c
 79e:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 7a0:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 7a4:	00001717          	auipc	a4,0x1
 7a8:	84a73e23          	sd	a0,-1956(a4) # 1000 <freep>
      return (void*)(p + 1);
 7ac:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 7b0:	70e2                	ld	ra,56(sp)
 7b2:	7442                	ld	s0,48(sp)
 7b4:	74a2                	ld	s1,40(sp)
 7b6:	7902                	ld	s2,32(sp)
 7b8:	69e2                	ld	s3,24(sp)
 7ba:	6a42                	ld	s4,16(sp)
 7bc:	6aa2                	ld	s5,8(sp)
 7be:	6b02                	ld	s6,0(sp)
 7c0:	6121                	addi	sp,sp,64
 7c2:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 7c4:	6398                	ld	a4,0(a5)
 7c6:	e118                	sd	a4,0(a0)
 7c8:	bff1                	j	7a4 <malloc+0x88>
  hp->s.size = nu;
 7ca:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 7ce:	0541                	addi	a0,a0,16
 7d0:	00000097          	auipc	ra,0x0
 7d4:	eca080e7          	jalr	-310(ra) # 69a <free>
  return freep;
 7d8:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 7dc:	d971                	beqz	a0,7b0 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7de:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7e0:	4798                	lw	a4,8(a5)
 7e2:	fa9775e3          	bgeu	a4,s1,78c <malloc+0x70>
    if(p == freep)
 7e6:	00093703          	ld	a4,0(s2)
 7ea:	853e                	mv	a0,a5
 7ec:	fef719e3          	bne	a4,a5,7de <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 7f0:	8552                	mv	a0,s4
 7f2:	00000097          	auipc	ra,0x0
 7f6:	b60080e7          	jalr	-1184(ra) # 352 <sbrk>
  if(p == (char*)-1)
 7fa:	fd5518e3          	bne	a0,s5,7ca <malloc+0xae>
        return 0;
 7fe:	4501                	li	a0,0
 800:	bf45                	j	7b0 <malloc+0x94>
