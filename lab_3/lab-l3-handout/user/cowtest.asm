
user/_cowtest:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <testcase4>:

int global_array[16777216] = {0};
int global_var = 0;

void testcase4()
{
   0:	1101                	addi	sp,sp,-32
   2:	ec06                	sd	ra,24(sp)
   4:	e822                	sd	s0,16(sp)
   6:	e426                	sd	s1,8(sp)
   8:	e04a                	sd	s2,0(sp)
   a:	1000                	addi	s0,sp,32
    int pid;

    printf("\n----- Test case 4 -----\n");
   c:	00001517          	auipc	a0,0x1
  10:	d6450513          	addi	a0,a0,-668 # d70 <malloc+0xe8>
  14:	00001097          	auipc	ra,0x1
  18:	bbc080e7          	jalr	-1092(ra) # bd0 <printf>
    printf("[prnt] v1 --> ");
  1c:	00001517          	auipc	a0,0x1
  20:	d7450513          	addi	a0,a0,-652 # d90 <malloc+0x108>
  24:	00001097          	auipc	ra,0x1
  28:	bac080e7          	jalr	-1108(ra) # bd0 <printf>
    print_free_frame_cnt();
  2c:	00001097          	auipc	ra,0x1
  30:	8c2080e7          	jalr	-1854(ra) # 8ee <pfreepages>

    if ((pid = fork()) == 0)
  34:	00000097          	auipc	ra,0x0
  38:	7f2080e7          	jalr	2034(ra) # 826 <fork>
  3c:	c161                	beqz	a0,fc <testcase4+0xfc>
  3e:	84aa                	mv	s1,a0
        exit(0);
    }
    else
    {
        // parent
        printf("[prnt] v2 --> ");
  40:	00001517          	auipc	a0,0x1
  44:	e7050513          	addi	a0,a0,-400 # eb0 <malloc+0x228>
  48:	00001097          	auipc	ra,0x1
  4c:	b88080e7          	jalr	-1144(ra) # bd0 <printf>
        print_free_frame_cnt();
  50:	00001097          	auipc	ra,0x1
  54:	89e080e7          	jalr	-1890(ra) # 8ee <pfreepages>

        global_array[0] = 111;
  58:	00002917          	auipc	s2,0x2
  5c:	fb890913          	addi	s2,s2,-72 # 2010 <global_array>
  60:	06f00793          	li	a5,111
  64:	00f92023          	sw	a5,0(s2)
        printf("[prnt] modified one element in the 1st page, global_array[0]=%d\n", global_array[0]);
  68:	06f00593          	li	a1,111
  6c:	00001517          	auipc	a0,0x1
  70:	e5450513          	addi	a0,a0,-428 # ec0 <malloc+0x238>
  74:	00001097          	auipc	ra,0x1
  78:	b5c080e7          	jalr	-1188(ra) # bd0 <printf>

        printf("[prnt] v3 --> ");
  7c:	00001517          	auipc	a0,0x1
  80:	e8c50513          	addi	a0,a0,-372 # f08 <malloc+0x280>
  84:	00001097          	auipc	ra,0x1
  88:	b4c080e7          	jalr	-1204(ra) # bd0 <printf>
        print_free_frame_cnt();
  8c:	00001097          	auipc	ra,0x1
  90:	862080e7          	jalr	-1950(ra) # 8ee <pfreepages>
        printf("[prnt] pa3 --> 0x%x\n", va2pa((uint64)&global_array[0], 0));
  94:	4581                	li	a1,0
  96:	854a                	mv	a0,s2
  98:	00001097          	auipc	ra,0x1
  9c:	84e080e7          	jalr	-1970(ra) # 8e6 <va2pa>
  a0:	85aa                	mv	a1,a0
  a2:	00001517          	auipc	a0,0x1
  a6:	e7650513          	addi	a0,a0,-394 # f18 <malloc+0x290>
  aa:	00001097          	auipc	ra,0x1
  ae:	b26080e7          	jalr	-1242(ra) # bd0 <printf>
    }

    if (wait(0) != pid)
  b2:	4501                	li	a0,0
  b4:	00000097          	auipc	ra,0x0
  b8:	782080e7          	jalr	1922(ra) # 836 <wait>
  bc:	12951763          	bne	a0,s1,1ea <testcase4+0x1ea>
    {
        printf("wait() error!");
        exit(1);
    }

    printf("[prnt] global_array[0] --> %d\n", global_array[0]);
  c0:	00002597          	auipc	a1,0x2
  c4:	f505a583          	lw	a1,-176(a1) # 2010 <global_array>
  c8:	00001517          	auipc	a0,0x1
  cc:	e7850513          	addi	a0,a0,-392 # f40 <malloc+0x2b8>
  d0:	00001097          	auipc	ra,0x1
  d4:	b00080e7          	jalr	-1280(ra) # bd0 <printf>

    printf("[prnt] v7 --> ");
  d8:	00001517          	auipc	a0,0x1
  dc:	e8850513          	addi	a0,a0,-376 # f60 <malloc+0x2d8>
  e0:	00001097          	auipc	ra,0x1
  e4:	af0080e7          	jalr	-1296(ra) # bd0 <printf>
    print_free_frame_cnt();
  e8:	00001097          	auipc	ra,0x1
  ec:	806080e7          	jalr	-2042(ra) # 8ee <pfreepages>
}
  f0:	60e2                	ld	ra,24(sp)
  f2:	6442                	ld	s0,16(sp)
  f4:	64a2                	ld	s1,8(sp)
  f6:	6902                	ld	s2,0(sp)
  f8:	6105                	addi	sp,sp,32
  fa:	8082                	ret
        sleep(50);
  fc:	03200513          	li	a0,50
 100:	00000097          	auipc	ra,0x0
 104:	7be080e7          	jalr	1982(ra) # 8be <sleep>
        printf("[chld] pa1 --> 0x%x\n", va2pa((uint64)&global_array[0], 0));
 108:	00002497          	auipc	s1,0x2
 10c:	f0848493          	addi	s1,s1,-248 # 2010 <global_array>
 110:	4581                	li	a1,0
 112:	8526                	mv	a0,s1
 114:	00000097          	auipc	ra,0x0
 118:	7d2080e7          	jalr	2002(ra) # 8e6 <va2pa>
 11c:	85aa                	mv	a1,a0
 11e:	00001517          	auipc	a0,0x1
 122:	c8250513          	addi	a0,a0,-894 # da0 <malloc+0x118>
 126:	00001097          	auipc	ra,0x1
 12a:	aaa080e7          	jalr	-1366(ra) # bd0 <printf>
        printf("[chld] v4 --> ");
 12e:	00001517          	auipc	a0,0x1
 132:	c8a50513          	addi	a0,a0,-886 # db8 <malloc+0x130>
 136:	00001097          	auipc	ra,0x1
 13a:	a9a080e7          	jalr	-1382(ra) # bd0 <printf>
        print_free_frame_cnt();
 13e:	00000097          	auipc	ra,0x0
 142:	7b0080e7          	jalr	1968(ra) # 8ee <pfreepages>
        global_array[0] = 222;
 146:	0de00793          	li	a5,222
 14a:	c09c                	sw	a5,0(s1)
        printf("[chld] modified one element in the 1st page, global_array[0]=%d\n", global_array[0]);
 14c:	0de00593          	li	a1,222
 150:	00001517          	auipc	a0,0x1
 154:	c7850513          	addi	a0,a0,-904 # dc8 <malloc+0x140>
 158:	00001097          	auipc	ra,0x1
 15c:	a78080e7          	jalr	-1416(ra) # bd0 <printf>
        printf("[chld] pa2 --> 0x%x\n", va2pa((uint64)&global_array[0], 0));
 160:	4581                	li	a1,0
 162:	8526                	mv	a0,s1
 164:	00000097          	auipc	ra,0x0
 168:	782080e7          	jalr	1922(ra) # 8e6 <va2pa>
 16c:	85aa                	mv	a1,a0
 16e:	00001517          	auipc	a0,0x1
 172:	ca250513          	addi	a0,a0,-862 # e10 <malloc+0x188>
 176:	00001097          	auipc	ra,0x1
 17a:	a5a080e7          	jalr	-1446(ra) # bd0 <printf>
        printf("[chld] v5 --> ");
 17e:	00001517          	auipc	a0,0x1
 182:	caa50513          	addi	a0,a0,-854 # e28 <malloc+0x1a0>
 186:	00001097          	auipc	ra,0x1
 18a:	a4a080e7          	jalr	-1462(ra) # bd0 <printf>
        print_free_frame_cnt();
 18e:	00000097          	auipc	ra,0x0
 192:	760080e7          	jalr	1888(ra) # 8ee <pfreepages>
        global_array[2047] = 333;
 196:	14d00793          	li	a5,333
 19a:	00004717          	auipc	a4,0x4
 19e:	e6f72923          	sw	a5,-398(a4) # 400c <global_array+0x1ffc>
        printf("[chld] modified two elements in the 2nd page, global_array[2047]=%d\n", global_array[2047]);
 1a2:	14d00593          	li	a1,333
 1a6:	00001517          	auipc	a0,0x1
 1aa:	c9250513          	addi	a0,a0,-878 # e38 <malloc+0x1b0>
 1ae:	00001097          	auipc	ra,0x1
 1b2:	a22080e7          	jalr	-1502(ra) # bd0 <printf>
        printf("[chld] v6 --> ");
 1b6:	00001517          	auipc	a0,0x1
 1ba:	cca50513          	addi	a0,a0,-822 # e80 <malloc+0x1f8>
 1be:	00001097          	auipc	ra,0x1
 1c2:	a12080e7          	jalr	-1518(ra) # bd0 <printf>
        print_free_frame_cnt();
 1c6:	00000097          	auipc	ra,0x0
 1ca:	728080e7          	jalr	1832(ra) # 8ee <pfreepages>
        printf("[chld] global_array[0] --> %d\n", global_array[0]);
 1ce:	408c                	lw	a1,0(s1)
 1d0:	00001517          	auipc	a0,0x1
 1d4:	cc050513          	addi	a0,a0,-832 # e90 <malloc+0x208>
 1d8:	00001097          	auipc	ra,0x1
 1dc:	9f8080e7          	jalr	-1544(ra) # bd0 <printf>
        exit(0);
 1e0:	4501                	li	a0,0
 1e2:	00000097          	auipc	ra,0x0
 1e6:	64c080e7          	jalr	1612(ra) # 82e <exit>
        printf("wait() error!");
 1ea:	00001517          	auipc	a0,0x1
 1ee:	d4650513          	addi	a0,a0,-698 # f30 <malloc+0x2a8>
 1f2:	00001097          	auipc	ra,0x1
 1f6:	9de080e7          	jalr	-1570(ra) # bd0 <printf>
        exit(1);
 1fa:	4505                	li	a0,1
 1fc:	00000097          	auipc	ra,0x0
 200:	632080e7          	jalr	1586(ra) # 82e <exit>

0000000000000204 <testcase3>:

void testcase3()
{
 204:	1101                	addi	sp,sp,-32
 206:	ec06                	sd	ra,24(sp)
 208:	e822                	sd	s0,16(sp)
 20a:	e426                	sd	s1,8(sp)
 20c:	1000                	addi	s0,sp,32
    int pid;

    printf("\n----- Test case 3 -----\n");
 20e:	00001517          	auipc	a0,0x1
 212:	d6250513          	addi	a0,a0,-670 # f70 <malloc+0x2e8>
 216:	00001097          	auipc	ra,0x1
 21a:	9ba080e7          	jalr	-1606(ra) # bd0 <printf>
    printf("[prnt] v1 --> ");
 21e:	00001517          	auipc	a0,0x1
 222:	b7250513          	addi	a0,a0,-1166 # d90 <malloc+0x108>
 226:	00001097          	auipc	ra,0x1
 22a:	9aa080e7          	jalr	-1622(ra) # bd0 <printf>
    print_free_frame_cnt();
 22e:	00000097          	auipc	ra,0x0
 232:	6c0080e7          	jalr	1728(ra) # 8ee <pfreepages>

    if ((pid = fork()) == 0)
 236:	00000097          	auipc	ra,0x0
 23a:	5f0080e7          	jalr	1520(ra) # 826 <fork>
 23e:	cd35                	beqz	a0,2ba <testcase3+0xb6>
 240:	84aa                	mv	s1,a0
        exit(0);
    }
    else
    {
        // parent
        printf("[prnt] v2 --> ");
 242:	00001517          	auipc	a0,0x1
 246:	c6e50513          	addi	a0,a0,-914 # eb0 <malloc+0x228>
 24a:	00001097          	auipc	ra,0x1
 24e:	986080e7          	jalr	-1658(ra) # bd0 <printf>
        print_free_frame_cnt();
 252:	00000097          	auipc	ra,0x0
 256:	69c080e7          	jalr	1692(ra) # 8ee <pfreepages>

        printf("[prnt] read global_var, global_var=%d\n", global_var);
 25a:	00002597          	auipc	a1,0x2
 25e:	da65a583          	lw	a1,-602(a1) # 2000 <global_var>
 262:	00001517          	auipc	a0,0x1
 266:	d5e50513          	addi	a0,a0,-674 # fc0 <malloc+0x338>
 26a:	00001097          	auipc	ra,0x1
 26e:	966080e7          	jalr	-1690(ra) # bd0 <printf>

        printf("[prnt] v3 --> ");
 272:	00001517          	auipc	a0,0x1
 276:	c9650513          	addi	a0,a0,-874 # f08 <malloc+0x280>
 27a:	00001097          	auipc	ra,0x1
 27e:	956080e7          	jalr	-1706(ra) # bd0 <printf>
        print_free_frame_cnt();
 282:	00000097          	auipc	ra,0x0
 286:	66c080e7          	jalr	1644(ra) # 8ee <pfreepages>
    }

    if (wait(0) != pid)
 28a:	4501                	li	a0,0
 28c:	00000097          	auipc	ra,0x0
 290:	5aa080e7          	jalr	1450(ra) # 836 <wait>
 294:	08951663          	bne	a0,s1,320 <testcase3+0x11c>
    {
        printf("wait() error!");
        exit(1);
    }

    printf("[prnt] v6 --> ");
 298:	00001517          	auipc	a0,0x1
 29c:	d5050513          	addi	a0,a0,-688 # fe8 <malloc+0x360>
 2a0:	00001097          	auipc	ra,0x1
 2a4:	930080e7          	jalr	-1744(ra) # bd0 <printf>
    print_free_frame_cnt();
 2a8:	00000097          	auipc	ra,0x0
 2ac:	646080e7          	jalr	1606(ra) # 8ee <pfreepages>
}
 2b0:	60e2                	ld	ra,24(sp)
 2b2:	6442                	ld	s0,16(sp)
 2b4:	64a2                	ld	s1,8(sp)
 2b6:	6105                	addi	sp,sp,32
 2b8:	8082                	ret
        sleep(50);
 2ba:	03200513          	li	a0,50
 2be:	00000097          	auipc	ra,0x0
 2c2:	600080e7          	jalr	1536(ra) # 8be <sleep>
        printf("[chld] v4 --> ");
 2c6:	00001517          	auipc	a0,0x1
 2ca:	af250513          	addi	a0,a0,-1294 # db8 <malloc+0x130>
 2ce:	00001097          	auipc	ra,0x1
 2d2:	902080e7          	jalr	-1790(ra) # bd0 <printf>
        print_free_frame_cnt();
 2d6:	00000097          	auipc	ra,0x0
 2da:	618080e7          	jalr	1560(ra) # 8ee <pfreepages>
        global_var = 100;
 2de:	06400793          	li	a5,100
 2e2:	00002717          	auipc	a4,0x2
 2e6:	d0f72f23          	sw	a5,-738(a4) # 2000 <global_var>
        printf("[chld] modified global_var, global_var=%d\n", global_var);
 2ea:	06400593          	li	a1,100
 2ee:	00001517          	auipc	a0,0x1
 2f2:	ca250513          	addi	a0,a0,-862 # f90 <malloc+0x308>
 2f6:	00001097          	auipc	ra,0x1
 2fa:	8da080e7          	jalr	-1830(ra) # bd0 <printf>
        printf("[chld] v5 --> ");
 2fe:	00001517          	auipc	a0,0x1
 302:	b2a50513          	addi	a0,a0,-1238 # e28 <malloc+0x1a0>
 306:	00001097          	auipc	ra,0x1
 30a:	8ca080e7          	jalr	-1846(ra) # bd0 <printf>
        print_free_frame_cnt();
 30e:	00000097          	auipc	ra,0x0
 312:	5e0080e7          	jalr	1504(ra) # 8ee <pfreepages>
        exit(0);
 316:	4501                	li	a0,0
 318:	00000097          	auipc	ra,0x0
 31c:	516080e7          	jalr	1302(ra) # 82e <exit>
        printf("wait() error!");
 320:	00001517          	auipc	a0,0x1
 324:	c1050513          	addi	a0,a0,-1008 # f30 <malloc+0x2a8>
 328:	00001097          	auipc	ra,0x1
 32c:	8a8080e7          	jalr	-1880(ra) # bd0 <printf>
        exit(1);
 330:	4505                	li	a0,1
 332:	00000097          	auipc	ra,0x0
 336:	4fc080e7          	jalr	1276(ra) # 82e <exit>

000000000000033a <testcase2>:

void testcase2()
{
 33a:	1101                	addi	sp,sp,-32
 33c:	ec06                	sd	ra,24(sp)
 33e:	e822                	sd	s0,16(sp)
 340:	e426                	sd	s1,8(sp)
 342:	1000                	addi	s0,sp,32
    int pid;

    printf("\n----- Test case 2 -----\n");
 344:	00001517          	auipc	a0,0x1
 348:	cb450513          	addi	a0,a0,-844 # ff8 <malloc+0x370>
 34c:	00001097          	auipc	ra,0x1
 350:	884080e7          	jalr	-1916(ra) # bd0 <printf>
    printf("[prnt] v1 --> ");
 354:	00001517          	auipc	a0,0x1
 358:	a3c50513          	addi	a0,a0,-1476 # d90 <malloc+0x108>
 35c:	00001097          	auipc	ra,0x1
 360:	874080e7          	jalr	-1932(ra) # bd0 <printf>
    print_free_frame_cnt();
 364:	00000097          	auipc	ra,0x0
 368:	58a080e7          	jalr	1418(ra) # 8ee <pfreepages>

    if ((pid = fork()) == 0)
 36c:	00000097          	auipc	ra,0x0
 370:	4ba080e7          	jalr	1210(ra) # 826 <fork>
 374:	c531                	beqz	a0,3c0 <testcase2+0x86>
 376:	84aa                	mv	s1,a0
        exit(0);
    }
    else
    {
        // parent
        printf("[prnt] v2 --> ");
 378:	00001517          	auipc	a0,0x1
 37c:	b3850513          	addi	a0,a0,-1224 # eb0 <malloc+0x228>
 380:	00001097          	auipc	ra,0x1
 384:	850080e7          	jalr	-1968(ra) # bd0 <printf>
        print_free_frame_cnt();
 388:	00000097          	auipc	ra,0x0
 38c:	566080e7          	jalr	1382(ra) # 8ee <pfreepages>
    }

    if (wait(0) != pid)
 390:	4501                	li	a0,0
 392:	00000097          	auipc	ra,0x0
 396:	4a4080e7          	jalr	1188(ra) # 836 <wait>
 39a:	08951263          	bne	a0,s1,41e <testcase2+0xe4>
    {
        printf("wait() error!");
        exit(1);
    }

    printf("[prnt] v5 --> ");
 39e:	00001517          	auipc	a0,0x1
 3a2:	cb250513          	addi	a0,a0,-846 # 1050 <malloc+0x3c8>
 3a6:	00001097          	auipc	ra,0x1
 3aa:	82a080e7          	jalr	-2006(ra) # bd0 <printf>
    print_free_frame_cnt();
 3ae:	00000097          	auipc	ra,0x0
 3b2:	540080e7          	jalr	1344(ra) # 8ee <pfreepages>
}
 3b6:	60e2                	ld	ra,24(sp)
 3b8:	6442                	ld	s0,16(sp)
 3ba:	64a2                	ld	s1,8(sp)
 3bc:	6105                	addi	sp,sp,32
 3be:	8082                	ret
        sleep(50);
 3c0:	03200513          	li	a0,50
 3c4:	00000097          	auipc	ra,0x0
 3c8:	4fa080e7          	jalr	1274(ra) # 8be <sleep>
        printf("[chld] v3 --> ");
 3cc:	00001517          	auipc	a0,0x1
 3d0:	c4c50513          	addi	a0,a0,-948 # 1018 <malloc+0x390>
 3d4:	00000097          	auipc	ra,0x0
 3d8:	7fc080e7          	jalr	2044(ra) # bd0 <printf>
        print_free_frame_cnt();
 3dc:	00000097          	auipc	ra,0x0
 3e0:	512080e7          	jalr	1298(ra) # 8ee <pfreepages>
        printf("[chld] read global_var, global_var=%d\n", global_var);
 3e4:	00002597          	auipc	a1,0x2
 3e8:	c1c5a583          	lw	a1,-996(a1) # 2000 <global_var>
 3ec:	00001517          	auipc	a0,0x1
 3f0:	c3c50513          	addi	a0,a0,-964 # 1028 <malloc+0x3a0>
 3f4:	00000097          	auipc	ra,0x0
 3f8:	7dc080e7          	jalr	2012(ra) # bd0 <printf>
        printf("[chld] v4 --> ");
 3fc:	00001517          	auipc	a0,0x1
 400:	9bc50513          	addi	a0,a0,-1604 # db8 <malloc+0x130>
 404:	00000097          	auipc	ra,0x0
 408:	7cc080e7          	jalr	1996(ra) # bd0 <printf>
        print_free_frame_cnt();
 40c:	00000097          	auipc	ra,0x0
 410:	4e2080e7          	jalr	1250(ra) # 8ee <pfreepages>
        exit(0);
 414:	4501                	li	a0,0
 416:	00000097          	auipc	ra,0x0
 41a:	418080e7          	jalr	1048(ra) # 82e <exit>
        printf("wait() error!");
 41e:	00001517          	auipc	a0,0x1
 422:	b1250513          	addi	a0,a0,-1262 # f30 <malloc+0x2a8>
 426:	00000097          	auipc	ra,0x0
 42a:	7aa080e7          	jalr	1962(ra) # bd0 <printf>
        exit(1);
 42e:	4505                	li	a0,1
 430:	00000097          	auipc	ra,0x0
 434:	3fe080e7          	jalr	1022(ra) # 82e <exit>

0000000000000438 <testcase1>:

void testcase1()
{
 438:	1101                	addi	sp,sp,-32
 43a:	ec06                	sd	ra,24(sp)
 43c:	e822                	sd	s0,16(sp)
 43e:	e426                	sd	s1,8(sp)
 440:	1000                	addi	s0,sp,32
    int pid;

    printf("\n----- Test case 1 -----\n");
 442:	00001517          	auipc	a0,0x1
 446:	c1e50513          	addi	a0,a0,-994 # 1060 <malloc+0x3d8>
 44a:	00000097          	auipc	ra,0x0
 44e:	786080e7          	jalr	1926(ra) # bd0 <printf>
    printf("[prnt] v1 --> ");
 452:	00001517          	auipc	a0,0x1
 456:	93e50513          	addi	a0,a0,-1730 # d90 <malloc+0x108>
 45a:	00000097          	auipc	ra,0x0
 45e:	776080e7          	jalr	1910(ra) # bd0 <printf>
    print_free_frame_cnt();
 462:	00000097          	auipc	ra,0x0
 466:	48c080e7          	jalr	1164(ra) # 8ee <pfreepages>

    if ((pid = fork()) == 0)
 46a:	00000097          	auipc	ra,0x0
 46e:	3bc080e7          	jalr	956(ra) # 826 <fork>
 472:	c531                	beqz	a0,4be <testcase1+0x86>
 474:	84aa                	mv	s1,a0
        exit(0);
    }
    else
    {
        // parent
        printf("[prnt] v3 --> ");
 476:	00001517          	auipc	a0,0x1
 47a:	a9250513          	addi	a0,a0,-1390 # f08 <malloc+0x280>
 47e:	00000097          	auipc	ra,0x0
 482:	752080e7          	jalr	1874(ra) # bd0 <printf>
        print_free_frame_cnt();
 486:	00000097          	auipc	ra,0x0
 48a:	468080e7          	jalr	1128(ra) # 8ee <pfreepages>
    }

    if (wait(0) != pid)
 48e:	4501                	li	a0,0
 490:	00000097          	auipc	ra,0x0
 494:	3a6080e7          	jalr	934(ra) # 836 <wait>
 498:	04951a63          	bne	a0,s1,4ec <testcase1+0xb4>
    {
        printf("wait() error!");
        exit(1);
    }

    printf("[prnt] v4 --> ");
 49c:	00001517          	auipc	a0,0x1
 4a0:	bf450513          	addi	a0,a0,-1036 # 1090 <malloc+0x408>
 4a4:	00000097          	auipc	ra,0x0
 4a8:	72c080e7          	jalr	1836(ra) # bd0 <printf>
    print_free_frame_cnt();
 4ac:	00000097          	auipc	ra,0x0
 4b0:	442080e7          	jalr	1090(ra) # 8ee <pfreepages>
}
 4b4:	60e2                	ld	ra,24(sp)
 4b6:	6442                	ld	s0,16(sp)
 4b8:	64a2                	ld	s1,8(sp)
 4ba:	6105                	addi	sp,sp,32
 4bc:	8082                	ret
        sleep(50);
 4be:	03200513          	li	a0,50
 4c2:	00000097          	auipc	ra,0x0
 4c6:	3fc080e7          	jalr	1020(ra) # 8be <sleep>
        printf("[chld] v2 --> ");
 4ca:	00001517          	auipc	a0,0x1
 4ce:	bb650513          	addi	a0,a0,-1098 # 1080 <malloc+0x3f8>
 4d2:	00000097          	auipc	ra,0x0
 4d6:	6fe080e7          	jalr	1790(ra) # bd0 <printf>
        print_free_frame_cnt();
 4da:	00000097          	auipc	ra,0x0
 4de:	414080e7          	jalr	1044(ra) # 8ee <pfreepages>
        exit(0);
 4e2:	4501                	li	a0,0
 4e4:	00000097          	auipc	ra,0x0
 4e8:	34a080e7          	jalr	842(ra) # 82e <exit>
        printf("wait() error!");
 4ec:	00001517          	auipc	a0,0x1
 4f0:	a4450513          	addi	a0,a0,-1468 # f30 <malloc+0x2a8>
 4f4:	00000097          	auipc	ra,0x0
 4f8:	6dc080e7          	jalr	1756(ra) # bd0 <printf>
        exit(1);
 4fc:	4505                	li	a0,1
 4fe:	00000097          	auipc	ra,0x0
 502:	330080e7          	jalr	816(ra) # 82e <exit>

0000000000000506 <main>:

int main(int argc, char *argv[])
{
 506:	1101                	addi	sp,sp,-32
 508:	ec06                	sd	ra,24(sp)
 50a:	e822                	sd	s0,16(sp)
 50c:	e426                	sd	s1,8(sp)
 50e:	1000                	addi	s0,sp,32
 510:	84ae                	mv	s1,a1
    if (argc < 2)
 512:	4785                	li	a5,1
 514:	02a7d763          	bge	a5,a0,542 <main+0x3c>
    {
        printf("Usage: cowtest test_id");
    }
    switch (atoi(argv[1]))
 518:	6488                	ld	a0,8(s1)
 51a:	00000097          	auipc	ra,0x0
 51e:	21a080e7          	jalr	538(ra) # 734 <atoi>
 522:	478d                	li	a5,3
 524:	06f50263          	beq	a0,a5,588 <main+0x82>
 528:	02a7c663          	blt	a5,a0,554 <main+0x4e>
 52c:	4785                	li	a5,1
 52e:	02f50b63          	beq	a0,a5,564 <main+0x5e>
 532:	4789                	li	a5,2
 534:	04f51f63          	bne	a0,a5,592 <main+0x8c>
    case 1:
        testcase1();
        break;

    case 2:
        testcase2();
 538:	00000097          	auipc	ra,0x0
 53c:	e02080e7          	jalr	-510(ra) # 33a <testcase2>
        break;
 540:	a035                	j	56c <main+0x66>
        printf("Usage: cowtest test_id");
 542:	00001517          	auipc	a0,0x1
 546:	b5e50513          	addi	a0,a0,-1186 # 10a0 <malloc+0x418>
 54a:	00000097          	auipc	ra,0x0
 54e:	686080e7          	jalr	1670(ra) # bd0 <printf>
 552:	b7d9                	j	518 <main+0x12>
    switch (atoi(argv[1]))
 554:	4791                	li	a5,4
 556:	02f51e63          	bne	a0,a5,592 <main+0x8c>
    case 3:
        testcase3();
        break;

    case 4:
        testcase4();
 55a:	00000097          	auipc	ra,0x0
 55e:	aa6080e7          	jalr	-1370(ra) # 0 <testcase4>
        break;
 562:	a029                	j	56c <main+0x66>
        testcase1();
 564:	00000097          	auipc	ra,0x0
 568:	ed4080e7          	jalr	-300(ra) # 438 <testcase1>

    default:
        printf("Error: No test with index %s\n", argv[1]);
        return 1;
    }
    printf("=======================\n\n");
 56c:	00001517          	auipc	a0,0x1
 570:	b6c50513          	addi	a0,a0,-1172 # 10d8 <malloc+0x450>
 574:	00000097          	auipc	ra,0x0
 578:	65c080e7          	jalr	1628(ra) # bd0 <printf>
    return 0;
 57c:	4501                	li	a0,0
 57e:	60e2                	ld	ra,24(sp)
 580:	6442                	ld	s0,16(sp)
 582:	64a2                	ld	s1,8(sp)
 584:	6105                	addi	sp,sp,32
 586:	8082                	ret
        testcase3();
 588:	00000097          	auipc	ra,0x0
 58c:	c7c080e7          	jalr	-900(ra) # 204 <testcase3>
        break;
 590:	bff1                	j	56c <main+0x66>
        printf("Error: No test with index %s\n", argv[1]);
 592:	648c                	ld	a1,8(s1)
 594:	00001517          	auipc	a0,0x1
 598:	b2450513          	addi	a0,a0,-1244 # 10b8 <malloc+0x430>
 59c:	00000097          	auipc	ra,0x0
 5a0:	634080e7          	jalr	1588(ra) # bd0 <printf>
        return 1;
 5a4:	4505                	li	a0,1
 5a6:	bfe1                	j	57e <main+0x78>

00000000000005a8 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
 5a8:	1141                	addi	sp,sp,-16
 5aa:	e406                	sd	ra,8(sp)
 5ac:	e022                	sd	s0,0(sp)
 5ae:	0800                	addi	s0,sp,16
  extern int main();
  main();
 5b0:	00000097          	auipc	ra,0x0
 5b4:	f56080e7          	jalr	-170(ra) # 506 <main>
  exit(0);
 5b8:	4501                	li	a0,0
 5ba:	00000097          	auipc	ra,0x0
 5be:	274080e7          	jalr	628(ra) # 82e <exit>

00000000000005c2 <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
 5c2:	1141                	addi	sp,sp,-16
 5c4:	e422                	sd	s0,8(sp)
 5c6:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 5c8:	87aa                	mv	a5,a0
 5ca:	0585                	addi	a1,a1,1
 5cc:	0785                	addi	a5,a5,1
 5ce:	fff5c703          	lbu	a4,-1(a1)
 5d2:	fee78fa3          	sb	a4,-1(a5)
 5d6:	fb75                	bnez	a4,5ca <strcpy+0x8>
    ;
  return os;
}
 5d8:	6422                	ld	s0,8(sp)
 5da:	0141                	addi	sp,sp,16
 5dc:	8082                	ret

00000000000005de <strcmp>:

int
strcmp(const char *p, const char *q)
{
 5de:	1141                	addi	sp,sp,-16
 5e0:	e422                	sd	s0,8(sp)
 5e2:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 5e4:	00054783          	lbu	a5,0(a0)
 5e8:	cb91                	beqz	a5,5fc <strcmp+0x1e>
 5ea:	0005c703          	lbu	a4,0(a1)
 5ee:	00f71763          	bne	a4,a5,5fc <strcmp+0x1e>
    p++, q++;
 5f2:	0505                	addi	a0,a0,1
 5f4:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 5f6:	00054783          	lbu	a5,0(a0)
 5fa:	fbe5                	bnez	a5,5ea <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 5fc:	0005c503          	lbu	a0,0(a1)
}
 600:	40a7853b          	subw	a0,a5,a0
 604:	6422                	ld	s0,8(sp)
 606:	0141                	addi	sp,sp,16
 608:	8082                	ret

000000000000060a <strlen>:

uint
strlen(const char *s)
{
 60a:	1141                	addi	sp,sp,-16
 60c:	e422                	sd	s0,8(sp)
 60e:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 610:	00054783          	lbu	a5,0(a0)
 614:	cf91                	beqz	a5,630 <strlen+0x26>
 616:	0505                	addi	a0,a0,1
 618:	87aa                	mv	a5,a0
 61a:	4685                	li	a3,1
 61c:	9e89                	subw	a3,a3,a0
 61e:	00f6853b          	addw	a0,a3,a5
 622:	0785                	addi	a5,a5,1
 624:	fff7c703          	lbu	a4,-1(a5)
 628:	fb7d                	bnez	a4,61e <strlen+0x14>
    ;
  return n;
}
 62a:	6422                	ld	s0,8(sp)
 62c:	0141                	addi	sp,sp,16
 62e:	8082                	ret
  for(n = 0; s[n]; n++)
 630:	4501                	li	a0,0
 632:	bfe5                	j	62a <strlen+0x20>

0000000000000634 <memset>:

void*
memset(void *dst, int c, uint n)
{
 634:	1141                	addi	sp,sp,-16
 636:	e422                	sd	s0,8(sp)
 638:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 63a:	ca19                	beqz	a2,650 <memset+0x1c>
 63c:	87aa                	mv	a5,a0
 63e:	1602                	slli	a2,a2,0x20
 640:	9201                	srli	a2,a2,0x20
 642:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 646:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 64a:	0785                	addi	a5,a5,1
 64c:	fee79de3          	bne	a5,a4,646 <memset+0x12>
  }
  return dst;
}
 650:	6422                	ld	s0,8(sp)
 652:	0141                	addi	sp,sp,16
 654:	8082                	ret

0000000000000656 <strchr>:

char*
strchr(const char *s, char c)
{
 656:	1141                	addi	sp,sp,-16
 658:	e422                	sd	s0,8(sp)
 65a:	0800                	addi	s0,sp,16
  for(; *s; s++)
 65c:	00054783          	lbu	a5,0(a0)
 660:	cb99                	beqz	a5,676 <strchr+0x20>
    if(*s == c)
 662:	00f58763          	beq	a1,a5,670 <strchr+0x1a>
  for(; *s; s++)
 666:	0505                	addi	a0,a0,1
 668:	00054783          	lbu	a5,0(a0)
 66c:	fbfd                	bnez	a5,662 <strchr+0xc>
      return (char*)s;
  return 0;
 66e:	4501                	li	a0,0
}
 670:	6422                	ld	s0,8(sp)
 672:	0141                	addi	sp,sp,16
 674:	8082                	ret
  return 0;
 676:	4501                	li	a0,0
 678:	bfe5                	j	670 <strchr+0x1a>

000000000000067a <gets>:

char*
gets(char *buf, int max)
{
 67a:	711d                	addi	sp,sp,-96
 67c:	ec86                	sd	ra,88(sp)
 67e:	e8a2                	sd	s0,80(sp)
 680:	e4a6                	sd	s1,72(sp)
 682:	e0ca                	sd	s2,64(sp)
 684:	fc4e                	sd	s3,56(sp)
 686:	f852                	sd	s4,48(sp)
 688:	f456                	sd	s5,40(sp)
 68a:	f05a                	sd	s6,32(sp)
 68c:	ec5e                	sd	s7,24(sp)
 68e:	1080                	addi	s0,sp,96
 690:	8baa                	mv	s7,a0
 692:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 694:	892a                	mv	s2,a0
 696:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 698:	4aa9                	li	s5,10
 69a:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 69c:	89a6                	mv	s3,s1
 69e:	2485                	addiw	s1,s1,1
 6a0:	0344d863          	bge	s1,s4,6d0 <gets+0x56>
    cc = read(0, &c, 1);
 6a4:	4605                	li	a2,1
 6a6:	faf40593          	addi	a1,s0,-81
 6aa:	4501                	li	a0,0
 6ac:	00000097          	auipc	ra,0x0
 6b0:	19a080e7          	jalr	410(ra) # 846 <read>
    if(cc < 1)
 6b4:	00a05e63          	blez	a0,6d0 <gets+0x56>
    buf[i++] = c;
 6b8:	faf44783          	lbu	a5,-81(s0)
 6bc:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 6c0:	01578763          	beq	a5,s5,6ce <gets+0x54>
 6c4:	0905                	addi	s2,s2,1
 6c6:	fd679be3          	bne	a5,s6,69c <gets+0x22>
  for(i=0; i+1 < max; ){
 6ca:	89a6                	mv	s3,s1
 6cc:	a011                	j	6d0 <gets+0x56>
 6ce:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 6d0:	99de                	add	s3,s3,s7
 6d2:	00098023          	sb	zero,0(s3)
  return buf;
}
 6d6:	855e                	mv	a0,s7
 6d8:	60e6                	ld	ra,88(sp)
 6da:	6446                	ld	s0,80(sp)
 6dc:	64a6                	ld	s1,72(sp)
 6de:	6906                	ld	s2,64(sp)
 6e0:	79e2                	ld	s3,56(sp)
 6e2:	7a42                	ld	s4,48(sp)
 6e4:	7aa2                	ld	s5,40(sp)
 6e6:	7b02                	ld	s6,32(sp)
 6e8:	6be2                	ld	s7,24(sp)
 6ea:	6125                	addi	sp,sp,96
 6ec:	8082                	ret

00000000000006ee <stat>:

int
stat(const char *n, struct stat *st)
{
 6ee:	1101                	addi	sp,sp,-32
 6f0:	ec06                	sd	ra,24(sp)
 6f2:	e822                	sd	s0,16(sp)
 6f4:	e426                	sd	s1,8(sp)
 6f6:	e04a                	sd	s2,0(sp)
 6f8:	1000                	addi	s0,sp,32
 6fa:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 6fc:	4581                	li	a1,0
 6fe:	00000097          	auipc	ra,0x0
 702:	170080e7          	jalr	368(ra) # 86e <open>
  if(fd < 0)
 706:	02054563          	bltz	a0,730 <stat+0x42>
 70a:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 70c:	85ca                	mv	a1,s2
 70e:	00000097          	auipc	ra,0x0
 712:	178080e7          	jalr	376(ra) # 886 <fstat>
 716:	892a                	mv	s2,a0
  close(fd);
 718:	8526                	mv	a0,s1
 71a:	00000097          	auipc	ra,0x0
 71e:	13c080e7          	jalr	316(ra) # 856 <close>
  return r;
}
 722:	854a                	mv	a0,s2
 724:	60e2                	ld	ra,24(sp)
 726:	6442                	ld	s0,16(sp)
 728:	64a2                	ld	s1,8(sp)
 72a:	6902                	ld	s2,0(sp)
 72c:	6105                	addi	sp,sp,32
 72e:	8082                	ret
    return -1;
 730:	597d                	li	s2,-1
 732:	bfc5                	j	722 <stat+0x34>

0000000000000734 <atoi>:

int
atoi(const char *s)
{
 734:	1141                	addi	sp,sp,-16
 736:	e422                	sd	s0,8(sp)
 738:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 73a:	00054683          	lbu	a3,0(a0)
 73e:	fd06879b          	addiw	a5,a3,-48
 742:	0ff7f793          	zext.b	a5,a5
 746:	4625                	li	a2,9
 748:	02f66863          	bltu	a2,a5,778 <atoi+0x44>
 74c:	872a                	mv	a4,a0
  n = 0;
 74e:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 750:	0705                	addi	a4,a4,1
 752:	0025179b          	slliw	a5,a0,0x2
 756:	9fa9                	addw	a5,a5,a0
 758:	0017979b          	slliw	a5,a5,0x1
 75c:	9fb5                	addw	a5,a5,a3
 75e:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 762:	00074683          	lbu	a3,0(a4)
 766:	fd06879b          	addiw	a5,a3,-48
 76a:	0ff7f793          	zext.b	a5,a5
 76e:	fef671e3          	bgeu	a2,a5,750 <atoi+0x1c>
  return n;
}
 772:	6422                	ld	s0,8(sp)
 774:	0141                	addi	sp,sp,16
 776:	8082                	ret
  n = 0;
 778:	4501                	li	a0,0
 77a:	bfe5                	j	772 <atoi+0x3e>

000000000000077c <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 77c:	1141                	addi	sp,sp,-16
 77e:	e422                	sd	s0,8(sp)
 780:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 782:	02b57463          	bgeu	a0,a1,7aa <memmove+0x2e>
    while(n-- > 0)
 786:	00c05f63          	blez	a2,7a4 <memmove+0x28>
 78a:	1602                	slli	a2,a2,0x20
 78c:	9201                	srli	a2,a2,0x20
 78e:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 792:	872a                	mv	a4,a0
      *dst++ = *src++;
 794:	0585                	addi	a1,a1,1
 796:	0705                	addi	a4,a4,1
 798:	fff5c683          	lbu	a3,-1(a1)
 79c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 7a0:	fee79ae3          	bne	a5,a4,794 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 7a4:	6422                	ld	s0,8(sp)
 7a6:	0141                	addi	sp,sp,16
 7a8:	8082                	ret
    dst += n;
 7aa:	00c50733          	add	a4,a0,a2
    src += n;
 7ae:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 7b0:	fec05ae3          	blez	a2,7a4 <memmove+0x28>
 7b4:	fff6079b          	addiw	a5,a2,-1
 7b8:	1782                	slli	a5,a5,0x20
 7ba:	9381                	srli	a5,a5,0x20
 7bc:	fff7c793          	not	a5,a5
 7c0:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 7c2:	15fd                	addi	a1,a1,-1
 7c4:	177d                	addi	a4,a4,-1
 7c6:	0005c683          	lbu	a3,0(a1)
 7ca:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 7ce:	fee79ae3          	bne	a5,a4,7c2 <memmove+0x46>
 7d2:	bfc9                	j	7a4 <memmove+0x28>

00000000000007d4 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 7d4:	1141                	addi	sp,sp,-16
 7d6:	e422                	sd	s0,8(sp)
 7d8:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 7da:	ca05                	beqz	a2,80a <memcmp+0x36>
 7dc:	fff6069b          	addiw	a3,a2,-1
 7e0:	1682                	slli	a3,a3,0x20
 7e2:	9281                	srli	a3,a3,0x20
 7e4:	0685                	addi	a3,a3,1
 7e6:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 7e8:	00054783          	lbu	a5,0(a0)
 7ec:	0005c703          	lbu	a4,0(a1)
 7f0:	00e79863          	bne	a5,a4,800 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 7f4:	0505                	addi	a0,a0,1
    p2++;
 7f6:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 7f8:	fed518e3          	bne	a0,a3,7e8 <memcmp+0x14>
  }
  return 0;
 7fc:	4501                	li	a0,0
 7fe:	a019                	j	804 <memcmp+0x30>
      return *p1 - *p2;
 800:	40e7853b          	subw	a0,a5,a4
}
 804:	6422                	ld	s0,8(sp)
 806:	0141                	addi	sp,sp,16
 808:	8082                	ret
  return 0;
 80a:	4501                	li	a0,0
 80c:	bfe5                	j	804 <memcmp+0x30>

000000000000080e <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 80e:	1141                	addi	sp,sp,-16
 810:	e406                	sd	ra,8(sp)
 812:	e022                	sd	s0,0(sp)
 814:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 816:	00000097          	auipc	ra,0x0
 81a:	f66080e7          	jalr	-154(ra) # 77c <memmove>
}
 81e:	60a2                	ld	ra,8(sp)
 820:	6402                	ld	s0,0(sp)
 822:	0141                	addi	sp,sp,16
 824:	8082                	ret

0000000000000826 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 826:	4885                	li	a7,1
 ecall
 828:	00000073          	ecall
 ret
 82c:	8082                	ret

000000000000082e <exit>:
.global exit
exit:
 li a7, SYS_exit
 82e:	4889                	li	a7,2
 ecall
 830:	00000073          	ecall
 ret
 834:	8082                	ret

0000000000000836 <wait>:
.global wait
wait:
 li a7, SYS_wait
 836:	488d                	li	a7,3
 ecall
 838:	00000073          	ecall
 ret
 83c:	8082                	ret

000000000000083e <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 83e:	4891                	li	a7,4
 ecall
 840:	00000073          	ecall
 ret
 844:	8082                	ret

0000000000000846 <read>:
.global read
read:
 li a7, SYS_read
 846:	4895                	li	a7,5
 ecall
 848:	00000073          	ecall
 ret
 84c:	8082                	ret

000000000000084e <write>:
.global write
write:
 li a7, SYS_write
 84e:	48c1                	li	a7,16
 ecall
 850:	00000073          	ecall
 ret
 854:	8082                	ret

0000000000000856 <close>:
.global close
close:
 li a7, SYS_close
 856:	48d5                	li	a7,21
 ecall
 858:	00000073          	ecall
 ret
 85c:	8082                	ret

000000000000085e <kill>:
.global kill
kill:
 li a7, SYS_kill
 85e:	4899                	li	a7,6
 ecall
 860:	00000073          	ecall
 ret
 864:	8082                	ret

0000000000000866 <exec>:
.global exec
exec:
 li a7, SYS_exec
 866:	489d                	li	a7,7
 ecall
 868:	00000073          	ecall
 ret
 86c:	8082                	ret

000000000000086e <open>:
.global open
open:
 li a7, SYS_open
 86e:	48bd                	li	a7,15
 ecall
 870:	00000073          	ecall
 ret
 874:	8082                	ret

0000000000000876 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 876:	48c5                	li	a7,17
 ecall
 878:	00000073          	ecall
 ret
 87c:	8082                	ret

000000000000087e <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 87e:	48c9                	li	a7,18
 ecall
 880:	00000073          	ecall
 ret
 884:	8082                	ret

0000000000000886 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 886:	48a1                	li	a7,8
 ecall
 888:	00000073          	ecall
 ret
 88c:	8082                	ret

000000000000088e <link>:
.global link
link:
 li a7, SYS_link
 88e:	48cd                	li	a7,19
 ecall
 890:	00000073          	ecall
 ret
 894:	8082                	ret

0000000000000896 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 896:	48d1                	li	a7,20
 ecall
 898:	00000073          	ecall
 ret
 89c:	8082                	ret

000000000000089e <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 89e:	48a5                	li	a7,9
 ecall
 8a0:	00000073          	ecall
 ret
 8a4:	8082                	ret

00000000000008a6 <dup>:
.global dup
dup:
 li a7, SYS_dup
 8a6:	48a9                	li	a7,10
 ecall
 8a8:	00000073          	ecall
 ret
 8ac:	8082                	ret

00000000000008ae <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 8ae:	48ad                	li	a7,11
 ecall
 8b0:	00000073          	ecall
 ret
 8b4:	8082                	ret

00000000000008b6 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 8b6:	48b1                	li	a7,12
 ecall
 8b8:	00000073          	ecall
 ret
 8bc:	8082                	ret

00000000000008be <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 8be:	48b5                	li	a7,13
 ecall
 8c0:	00000073          	ecall
 ret
 8c4:	8082                	ret

00000000000008c6 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 8c6:	48b9                	li	a7,14
 ecall
 8c8:	00000073          	ecall
 ret
 8cc:	8082                	ret

00000000000008ce <ps>:
.global ps
ps:
 li a7, SYS_ps
 8ce:	48d9                	li	a7,22
 ecall
 8d0:	00000073          	ecall
 ret
 8d4:	8082                	ret

00000000000008d6 <schedls>:
.global schedls
schedls:
 li a7, SYS_schedls
 8d6:	48dd                	li	a7,23
 ecall
 8d8:	00000073          	ecall
 ret
 8dc:	8082                	ret

00000000000008de <schedset>:
.global schedset
schedset:
 li a7, SYS_schedset
 8de:	48e1                	li	a7,24
 ecall
 8e0:	00000073          	ecall
 ret
 8e4:	8082                	ret

00000000000008e6 <va2pa>:
.global va2pa
va2pa:
 li a7, SYS_va2pa
 8e6:	48e9                	li	a7,26
 ecall
 8e8:	00000073          	ecall
 ret
 8ec:	8082                	ret

00000000000008ee <pfreepages>:
.global pfreepages
pfreepages:
 li a7, SYS_pfreepages
 8ee:	48e5                	li	a7,25
 ecall
 8f0:	00000073          	ecall
 ret
 8f4:	8082                	ret

00000000000008f6 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 8f6:	1101                	addi	sp,sp,-32
 8f8:	ec06                	sd	ra,24(sp)
 8fa:	e822                	sd	s0,16(sp)
 8fc:	1000                	addi	s0,sp,32
 8fe:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 902:	4605                	li	a2,1
 904:	fef40593          	addi	a1,s0,-17
 908:	00000097          	auipc	ra,0x0
 90c:	f46080e7          	jalr	-186(ra) # 84e <write>
}
 910:	60e2                	ld	ra,24(sp)
 912:	6442                	ld	s0,16(sp)
 914:	6105                	addi	sp,sp,32
 916:	8082                	ret

0000000000000918 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 918:	7139                	addi	sp,sp,-64
 91a:	fc06                	sd	ra,56(sp)
 91c:	f822                	sd	s0,48(sp)
 91e:	f426                	sd	s1,40(sp)
 920:	f04a                	sd	s2,32(sp)
 922:	ec4e                	sd	s3,24(sp)
 924:	0080                	addi	s0,sp,64
 926:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 928:	c299                	beqz	a3,92e <printint+0x16>
 92a:	0805c963          	bltz	a1,9bc <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 92e:	2581                	sext.w	a1,a1
  neg = 0;
 930:	4881                	li	a7,0
 932:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 936:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 938:	2601                	sext.w	a2,a2
 93a:	00001517          	auipc	a0,0x1
 93e:	81e50513          	addi	a0,a0,-2018 # 1158 <digits>
 942:	883a                	mv	a6,a4
 944:	2705                	addiw	a4,a4,1
 946:	02c5f7bb          	remuw	a5,a1,a2
 94a:	1782                	slli	a5,a5,0x20
 94c:	9381                	srli	a5,a5,0x20
 94e:	97aa                	add	a5,a5,a0
 950:	0007c783          	lbu	a5,0(a5)
 954:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 958:	0005879b          	sext.w	a5,a1
 95c:	02c5d5bb          	divuw	a1,a1,a2
 960:	0685                	addi	a3,a3,1
 962:	fec7f0e3          	bgeu	a5,a2,942 <printint+0x2a>
  if(neg)
 966:	00088c63          	beqz	a7,97e <printint+0x66>
    buf[i++] = '-';
 96a:	fd070793          	addi	a5,a4,-48
 96e:	00878733          	add	a4,a5,s0
 972:	02d00793          	li	a5,45
 976:	fef70823          	sb	a5,-16(a4)
 97a:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 97e:	02e05863          	blez	a4,9ae <printint+0x96>
 982:	fc040793          	addi	a5,s0,-64
 986:	00e78933          	add	s2,a5,a4
 98a:	fff78993          	addi	s3,a5,-1
 98e:	99ba                	add	s3,s3,a4
 990:	377d                	addiw	a4,a4,-1
 992:	1702                	slli	a4,a4,0x20
 994:	9301                	srli	a4,a4,0x20
 996:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 99a:	fff94583          	lbu	a1,-1(s2)
 99e:	8526                	mv	a0,s1
 9a0:	00000097          	auipc	ra,0x0
 9a4:	f56080e7          	jalr	-170(ra) # 8f6 <putc>
  while(--i >= 0)
 9a8:	197d                	addi	s2,s2,-1
 9aa:	ff3918e3          	bne	s2,s3,99a <printint+0x82>
}
 9ae:	70e2                	ld	ra,56(sp)
 9b0:	7442                	ld	s0,48(sp)
 9b2:	74a2                	ld	s1,40(sp)
 9b4:	7902                	ld	s2,32(sp)
 9b6:	69e2                	ld	s3,24(sp)
 9b8:	6121                	addi	sp,sp,64
 9ba:	8082                	ret
    x = -xx;
 9bc:	40b005bb          	negw	a1,a1
    neg = 1;
 9c0:	4885                	li	a7,1
    x = -xx;
 9c2:	bf85                	j	932 <printint+0x1a>

00000000000009c4 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 9c4:	7119                	addi	sp,sp,-128
 9c6:	fc86                	sd	ra,120(sp)
 9c8:	f8a2                	sd	s0,112(sp)
 9ca:	f4a6                	sd	s1,104(sp)
 9cc:	f0ca                	sd	s2,96(sp)
 9ce:	ecce                	sd	s3,88(sp)
 9d0:	e8d2                	sd	s4,80(sp)
 9d2:	e4d6                	sd	s5,72(sp)
 9d4:	e0da                	sd	s6,64(sp)
 9d6:	fc5e                	sd	s7,56(sp)
 9d8:	f862                	sd	s8,48(sp)
 9da:	f466                	sd	s9,40(sp)
 9dc:	f06a                	sd	s10,32(sp)
 9de:	ec6e                	sd	s11,24(sp)
 9e0:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 9e2:	0005c903          	lbu	s2,0(a1)
 9e6:	18090f63          	beqz	s2,b84 <vprintf+0x1c0>
 9ea:	8aaa                	mv	s5,a0
 9ec:	8b32                	mv	s6,a2
 9ee:	00158493          	addi	s1,a1,1
  state = 0;
 9f2:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 9f4:	02500a13          	li	s4,37
 9f8:	4c55                	li	s8,21
 9fa:	00000c97          	auipc	s9,0x0
 9fe:	706c8c93          	addi	s9,s9,1798 # 1100 <malloc+0x478>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
        s = va_arg(ap, char*);
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 a02:	02800d93          	li	s11,40
  putc(fd, 'x');
 a06:	4d41                	li	s10,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 a08:	00000b97          	auipc	s7,0x0
 a0c:	750b8b93          	addi	s7,s7,1872 # 1158 <digits>
 a10:	a839                	j	a2e <vprintf+0x6a>
        putc(fd, c);
 a12:	85ca                	mv	a1,s2
 a14:	8556                	mv	a0,s5
 a16:	00000097          	auipc	ra,0x0
 a1a:	ee0080e7          	jalr	-288(ra) # 8f6 <putc>
 a1e:	a019                	j	a24 <vprintf+0x60>
    } else if(state == '%'){
 a20:	01498d63          	beq	s3,s4,a3a <vprintf+0x76>
  for(i = 0; fmt[i]; i++){
 a24:	0485                	addi	s1,s1,1
 a26:	fff4c903          	lbu	s2,-1(s1)
 a2a:	14090d63          	beqz	s2,b84 <vprintf+0x1c0>
    if(state == 0){
 a2e:	fe0999e3          	bnez	s3,a20 <vprintf+0x5c>
      if(c == '%'){
 a32:	ff4910e3          	bne	s2,s4,a12 <vprintf+0x4e>
        state = '%';
 a36:	89d2                	mv	s3,s4
 a38:	b7f5                	j	a24 <vprintf+0x60>
      if(c == 'd'){
 a3a:	11490c63          	beq	s2,s4,b52 <vprintf+0x18e>
 a3e:	f9d9079b          	addiw	a5,s2,-99
 a42:	0ff7f793          	zext.b	a5,a5
 a46:	10fc6e63          	bltu	s8,a5,b62 <vprintf+0x19e>
 a4a:	f9d9079b          	addiw	a5,s2,-99
 a4e:	0ff7f713          	zext.b	a4,a5
 a52:	10ec6863          	bltu	s8,a4,b62 <vprintf+0x19e>
 a56:	00271793          	slli	a5,a4,0x2
 a5a:	97e6                	add	a5,a5,s9
 a5c:	439c                	lw	a5,0(a5)
 a5e:	97e6                	add	a5,a5,s9
 a60:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 a62:	008b0913          	addi	s2,s6,8
 a66:	4685                	li	a3,1
 a68:	4629                	li	a2,10
 a6a:	000b2583          	lw	a1,0(s6)
 a6e:	8556                	mv	a0,s5
 a70:	00000097          	auipc	ra,0x0
 a74:	ea8080e7          	jalr	-344(ra) # 918 <printint>
 a78:	8b4a                	mv	s6,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 a7a:	4981                	li	s3,0
 a7c:	b765                	j	a24 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 a7e:	008b0913          	addi	s2,s6,8
 a82:	4681                	li	a3,0
 a84:	4629                	li	a2,10
 a86:	000b2583          	lw	a1,0(s6)
 a8a:	8556                	mv	a0,s5
 a8c:	00000097          	auipc	ra,0x0
 a90:	e8c080e7          	jalr	-372(ra) # 918 <printint>
 a94:	8b4a                	mv	s6,s2
      state = 0;
 a96:	4981                	li	s3,0
 a98:	b771                	j	a24 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 a9a:	008b0913          	addi	s2,s6,8
 a9e:	4681                	li	a3,0
 aa0:	866a                	mv	a2,s10
 aa2:	000b2583          	lw	a1,0(s6)
 aa6:	8556                	mv	a0,s5
 aa8:	00000097          	auipc	ra,0x0
 aac:	e70080e7          	jalr	-400(ra) # 918 <printint>
 ab0:	8b4a                	mv	s6,s2
      state = 0;
 ab2:	4981                	li	s3,0
 ab4:	bf85                	j	a24 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 ab6:	008b0793          	addi	a5,s6,8
 aba:	f8f43423          	sd	a5,-120(s0)
 abe:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 ac2:	03000593          	li	a1,48
 ac6:	8556                	mv	a0,s5
 ac8:	00000097          	auipc	ra,0x0
 acc:	e2e080e7          	jalr	-466(ra) # 8f6 <putc>
  putc(fd, 'x');
 ad0:	07800593          	li	a1,120
 ad4:	8556                	mv	a0,s5
 ad6:	00000097          	auipc	ra,0x0
 ada:	e20080e7          	jalr	-480(ra) # 8f6 <putc>
 ade:	896a                	mv	s2,s10
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 ae0:	03c9d793          	srli	a5,s3,0x3c
 ae4:	97de                	add	a5,a5,s7
 ae6:	0007c583          	lbu	a1,0(a5)
 aea:	8556                	mv	a0,s5
 aec:	00000097          	auipc	ra,0x0
 af0:	e0a080e7          	jalr	-502(ra) # 8f6 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 af4:	0992                	slli	s3,s3,0x4
 af6:	397d                	addiw	s2,s2,-1
 af8:	fe0914e3          	bnez	s2,ae0 <vprintf+0x11c>
        printptr(fd, va_arg(ap, uint64));
 afc:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 b00:	4981                	li	s3,0
 b02:	b70d                	j	a24 <vprintf+0x60>
        s = va_arg(ap, char*);
 b04:	008b0913          	addi	s2,s6,8
 b08:	000b3983          	ld	s3,0(s6)
        if(s == 0)
 b0c:	02098163          	beqz	s3,b2e <vprintf+0x16a>
        while(*s != 0){
 b10:	0009c583          	lbu	a1,0(s3)
 b14:	c5ad                	beqz	a1,b7e <vprintf+0x1ba>
          putc(fd, *s);
 b16:	8556                	mv	a0,s5
 b18:	00000097          	auipc	ra,0x0
 b1c:	dde080e7          	jalr	-546(ra) # 8f6 <putc>
          s++;
 b20:	0985                	addi	s3,s3,1
        while(*s != 0){
 b22:	0009c583          	lbu	a1,0(s3)
 b26:	f9e5                	bnez	a1,b16 <vprintf+0x152>
        s = va_arg(ap, char*);
 b28:	8b4a                	mv	s6,s2
      state = 0;
 b2a:	4981                	li	s3,0
 b2c:	bde5                	j	a24 <vprintf+0x60>
          s = "(null)";
 b2e:	00000997          	auipc	s3,0x0
 b32:	5ca98993          	addi	s3,s3,1482 # 10f8 <malloc+0x470>
        while(*s != 0){
 b36:	85ee                	mv	a1,s11
 b38:	bff9                	j	b16 <vprintf+0x152>
        putc(fd, va_arg(ap, uint));
 b3a:	008b0913          	addi	s2,s6,8
 b3e:	000b4583          	lbu	a1,0(s6)
 b42:	8556                	mv	a0,s5
 b44:	00000097          	auipc	ra,0x0
 b48:	db2080e7          	jalr	-590(ra) # 8f6 <putc>
 b4c:	8b4a                	mv	s6,s2
      state = 0;
 b4e:	4981                	li	s3,0
 b50:	bdd1                	j	a24 <vprintf+0x60>
        putc(fd, c);
 b52:	85d2                	mv	a1,s4
 b54:	8556                	mv	a0,s5
 b56:	00000097          	auipc	ra,0x0
 b5a:	da0080e7          	jalr	-608(ra) # 8f6 <putc>
      state = 0;
 b5e:	4981                	li	s3,0
 b60:	b5d1                	j	a24 <vprintf+0x60>
        putc(fd, '%');
 b62:	85d2                	mv	a1,s4
 b64:	8556                	mv	a0,s5
 b66:	00000097          	auipc	ra,0x0
 b6a:	d90080e7          	jalr	-624(ra) # 8f6 <putc>
        putc(fd, c);
 b6e:	85ca                	mv	a1,s2
 b70:	8556                	mv	a0,s5
 b72:	00000097          	auipc	ra,0x0
 b76:	d84080e7          	jalr	-636(ra) # 8f6 <putc>
      state = 0;
 b7a:	4981                	li	s3,0
 b7c:	b565                	j	a24 <vprintf+0x60>
        s = va_arg(ap, char*);
 b7e:	8b4a                	mv	s6,s2
      state = 0;
 b80:	4981                	li	s3,0
 b82:	b54d                	j	a24 <vprintf+0x60>
    }
  }
}
 b84:	70e6                	ld	ra,120(sp)
 b86:	7446                	ld	s0,112(sp)
 b88:	74a6                	ld	s1,104(sp)
 b8a:	7906                	ld	s2,96(sp)
 b8c:	69e6                	ld	s3,88(sp)
 b8e:	6a46                	ld	s4,80(sp)
 b90:	6aa6                	ld	s5,72(sp)
 b92:	6b06                	ld	s6,64(sp)
 b94:	7be2                	ld	s7,56(sp)
 b96:	7c42                	ld	s8,48(sp)
 b98:	7ca2                	ld	s9,40(sp)
 b9a:	7d02                	ld	s10,32(sp)
 b9c:	6de2                	ld	s11,24(sp)
 b9e:	6109                	addi	sp,sp,128
 ba0:	8082                	ret

0000000000000ba2 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 ba2:	715d                	addi	sp,sp,-80
 ba4:	ec06                	sd	ra,24(sp)
 ba6:	e822                	sd	s0,16(sp)
 ba8:	1000                	addi	s0,sp,32
 baa:	e010                	sd	a2,0(s0)
 bac:	e414                	sd	a3,8(s0)
 bae:	e818                	sd	a4,16(s0)
 bb0:	ec1c                	sd	a5,24(s0)
 bb2:	03043023          	sd	a6,32(s0)
 bb6:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 bba:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 bbe:	8622                	mv	a2,s0
 bc0:	00000097          	auipc	ra,0x0
 bc4:	e04080e7          	jalr	-508(ra) # 9c4 <vprintf>
}
 bc8:	60e2                	ld	ra,24(sp)
 bca:	6442                	ld	s0,16(sp)
 bcc:	6161                	addi	sp,sp,80
 bce:	8082                	ret

0000000000000bd0 <printf>:

void
printf(const char *fmt, ...)
{
 bd0:	711d                	addi	sp,sp,-96
 bd2:	ec06                	sd	ra,24(sp)
 bd4:	e822                	sd	s0,16(sp)
 bd6:	1000                	addi	s0,sp,32
 bd8:	e40c                	sd	a1,8(s0)
 bda:	e810                	sd	a2,16(s0)
 bdc:	ec14                	sd	a3,24(s0)
 bde:	f018                	sd	a4,32(s0)
 be0:	f41c                	sd	a5,40(s0)
 be2:	03043823          	sd	a6,48(s0)
 be6:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 bea:	00840613          	addi	a2,s0,8
 bee:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 bf2:	85aa                	mv	a1,a0
 bf4:	4505                	li	a0,1
 bf6:	00000097          	auipc	ra,0x0
 bfa:	dce080e7          	jalr	-562(ra) # 9c4 <vprintf>
}
 bfe:	60e2                	ld	ra,24(sp)
 c00:	6442                	ld	s0,16(sp)
 c02:	6125                	addi	sp,sp,96
 c04:	8082                	ret

0000000000000c06 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 c06:	1141                	addi	sp,sp,-16
 c08:	e422                	sd	s0,8(sp)
 c0a:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 c0c:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 c10:	00001797          	auipc	a5,0x1
 c14:	3f87b783          	ld	a5,1016(a5) # 2008 <freep>
 c18:	a02d                	j	c42 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 c1a:	4618                	lw	a4,8(a2)
 c1c:	9f2d                	addw	a4,a4,a1
 c1e:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 c22:	6398                	ld	a4,0(a5)
 c24:	6310                	ld	a2,0(a4)
 c26:	a83d                	j	c64 <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 c28:	ff852703          	lw	a4,-8(a0)
 c2c:	9f31                	addw	a4,a4,a2
 c2e:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 c30:	ff053683          	ld	a3,-16(a0)
 c34:	a091                	j	c78 <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 c36:	6398                	ld	a4,0(a5)
 c38:	00e7e463          	bltu	a5,a4,c40 <free+0x3a>
 c3c:	00e6ea63          	bltu	a3,a4,c50 <free+0x4a>
{
 c40:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 c42:	fed7fae3          	bgeu	a5,a3,c36 <free+0x30>
 c46:	6398                	ld	a4,0(a5)
 c48:	00e6e463          	bltu	a3,a4,c50 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 c4c:	fee7eae3          	bltu	a5,a4,c40 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 c50:	ff852583          	lw	a1,-8(a0)
 c54:	6390                	ld	a2,0(a5)
 c56:	02059813          	slli	a6,a1,0x20
 c5a:	01c85713          	srli	a4,a6,0x1c
 c5e:	9736                	add	a4,a4,a3
 c60:	fae60de3          	beq	a2,a4,c1a <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 c64:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 c68:	4790                	lw	a2,8(a5)
 c6a:	02061593          	slli	a1,a2,0x20
 c6e:	01c5d713          	srli	a4,a1,0x1c
 c72:	973e                	add	a4,a4,a5
 c74:	fae68ae3          	beq	a3,a4,c28 <free+0x22>
    p->s.ptr = bp->s.ptr;
 c78:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 c7a:	00001717          	auipc	a4,0x1
 c7e:	38f73723          	sd	a5,910(a4) # 2008 <freep>
}
 c82:	6422                	ld	s0,8(sp)
 c84:	0141                	addi	sp,sp,16
 c86:	8082                	ret

0000000000000c88 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 c88:	7139                	addi	sp,sp,-64
 c8a:	fc06                	sd	ra,56(sp)
 c8c:	f822                	sd	s0,48(sp)
 c8e:	f426                	sd	s1,40(sp)
 c90:	f04a                	sd	s2,32(sp)
 c92:	ec4e                	sd	s3,24(sp)
 c94:	e852                	sd	s4,16(sp)
 c96:	e456                	sd	s5,8(sp)
 c98:	e05a                	sd	s6,0(sp)
 c9a:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 c9c:	02051493          	slli	s1,a0,0x20
 ca0:	9081                	srli	s1,s1,0x20
 ca2:	04bd                	addi	s1,s1,15
 ca4:	8091                	srli	s1,s1,0x4
 ca6:	0014899b          	addiw	s3,s1,1
 caa:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 cac:	00001517          	auipc	a0,0x1
 cb0:	35c53503          	ld	a0,860(a0) # 2008 <freep>
 cb4:	c515                	beqz	a0,ce0 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 cb6:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 cb8:	4798                	lw	a4,8(a5)
 cba:	02977f63          	bgeu	a4,s1,cf8 <malloc+0x70>
 cbe:	8a4e                	mv	s4,s3
 cc0:	0009871b          	sext.w	a4,s3
 cc4:	6685                	lui	a3,0x1
 cc6:	00d77363          	bgeu	a4,a3,ccc <malloc+0x44>
 cca:	6a05                	lui	s4,0x1
 ccc:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 cd0:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 cd4:	00001917          	auipc	s2,0x1
 cd8:	33490913          	addi	s2,s2,820 # 2008 <freep>
  if(p == (char*)-1)
 cdc:	5afd                	li	s5,-1
 cde:	a895                	j	d52 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 ce0:	04001797          	auipc	a5,0x4001
 ce4:	33078793          	addi	a5,a5,816 # 4002010 <base>
 ce8:	00001717          	auipc	a4,0x1
 cec:	32f73023          	sd	a5,800(a4) # 2008 <freep>
 cf0:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 cf2:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 cf6:	b7e1                	j	cbe <malloc+0x36>
      if(p->s.size == nunits)
 cf8:	02e48c63          	beq	s1,a4,d30 <malloc+0xa8>
        p->s.size -= nunits;
 cfc:	4137073b          	subw	a4,a4,s3
 d00:	c798                	sw	a4,8(a5)
        p += p->s.size;
 d02:	02071693          	slli	a3,a4,0x20
 d06:	01c6d713          	srli	a4,a3,0x1c
 d0a:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 d0c:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 d10:	00001717          	auipc	a4,0x1
 d14:	2ea73c23          	sd	a0,760(a4) # 2008 <freep>
      return (void*)(p + 1);
 d18:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 d1c:	70e2                	ld	ra,56(sp)
 d1e:	7442                	ld	s0,48(sp)
 d20:	74a2                	ld	s1,40(sp)
 d22:	7902                	ld	s2,32(sp)
 d24:	69e2                	ld	s3,24(sp)
 d26:	6a42                	ld	s4,16(sp)
 d28:	6aa2                	ld	s5,8(sp)
 d2a:	6b02                	ld	s6,0(sp)
 d2c:	6121                	addi	sp,sp,64
 d2e:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 d30:	6398                	ld	a4,0(a5)
 d32:	e118                	sd	a4,0(a0)
 d34:	bff1                	j	d10 <malloc+0x88>
  hp->s.size = nu;
 d36:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 d3a:	0541                	addi	a0,a0,16
 d3c:	00000097          	auipc	ra,0x0
 d40:	eca080e7          	jalr	-310(ra) # c06 <free>
  return freep;
 d44:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 d48:	d971                	beqz	a0,d1c <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 d4a:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 d4c:	4798                	lw	a4,8(a5)
 d4e:	fa9775e3          	bgeu	a4,s1,cf8 <malloc+0x70>
    if(p == freep)
 d52:	00093703          	ld	a4,0(s2)
 d56:	853e                	mv	a0,a5
 d58:	fef719e3          	bne	a4,a5,d4a <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 d5c:	8552                	mv	a0,s4
 d5e:	00000097          	auipc	ra,0x0
 d62:	b58080e7          	jalr	-1192(ra) # 8b6 <sbrk>
  if(p == (char*)-1)
 d66:	fd5518e3          	bne	a0,s5,d36 <malloc+0xae>
        return 0;
 d6a:	4501                	li	a0,0
 d6c:	bf45                	j	d1c <malloc+0x94>
