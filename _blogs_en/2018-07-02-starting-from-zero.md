---
layout: blog-detail
comments: true
title: "Starting from zero?"
date: 2018-07-02T15:44:00+00:00
categories:
    - Exploiting
tags:
    - buffer overflow
    - buffer overrun
    - exploiting
    - intro
    - overflow
    - overrun
    - stack
    - stack based
    - stack overrun
    - stack smashing
image_src: /assets/uploads/2018/07/Puffin-Security-Empezando-desde-cero-exploiting-ciberseguridad.jpg
image_height: 1280
image_width: 1920
author: Yago Gutierrez
description: For some time, I&#8217;ve been reading blogs about exploiting that seems now at last my time has come to change the role. In this blog I will publish posts as a workshop &#8220;from scratch&#8221; the exploiting, and additionally I try often bring examples of vulnerabilities...
publish_time: 2018-07-02T15:44:00+00:00
modified_time: 2019-10-09T12:44:16+00:00
comments_value: 0
disqus_identifier: 624
---
For some time, I’ve been reading blogs about exploiting that seems now at last my time has come to change the role. In this blog I will publish posts as a workshop “from scratch” the exploiting, and additionally I try often bring examples of vulnerabilities (hereafter “vulns” if allowed me) in the rial guorld. This post is primarily an intro with to acquire basic ideas.

Anyway, let’s start by defining the exploiting. The exploiting is the set of techniques that seek to exploit errors (bugs) the programmer to manipulate the behavior of the program, these errors are mainly poor forecasting of potential data that can provide the user. One time I read a quote (from a certain P. Williams) which he reads

From the point of view of a programmer, the user is no more than a peripheral drumming when you are sent a read request.

This idea is possibly leading to the occurrence of these errors. For me, the user is a potential serial murderer with which we must be educated better and why we do what we ask, to some extent, so it is necessary to verify the data that provides the user always properly before handling.

Exploitation can be at many levels (you can exploit for example the web server binary itself, or exploit the webapp that manages that server, techniques such as SQLi and XSS belong to the latter world, as for us, we will enjoy only the world binary, more beautiful at least for me) and of course there are cases of extremely complex operation and others with simpler schemes. A more complexity, more fun.

To continue to understand the full meaning of every sentence you read, dear reader, perhaps as healthy as it is to know a little assembler (for now IA32, and go into AMD64 and maybe ARM/64, maybe even AVR) I know it can be scary but well tamed is quite docile, in addition nor excessive knowledge is required before any instruction that one unknown can always consult a manual (for instance, Intel). Similarly, you need to know C or C ++ and Assembler more depth (“asm” from now on).

These techniques carry exploited since before many of us were born, although I do not think it is possible to determine in which year began research in this field. In any case, surely the intelligence agencies and take the advantage when the public started with it (as has always happened, being the best example cryptography, especially the discovery of asymmetric cryptography). However, the most important milestone was possibly the November 2, 1988 when Robert Tappan Morris, seeing the disaster that was coming, executed his famous Morris worm, responsible for infecting 6,000 computers 60000 connected to the Internet at the time (still ARPANET) ie 10%, causing a damage of thousands of dollars.

Multiple viruses have been used since then to spread by exploiting the network, the latter being the most notorious case WannaCry, who operated the EternalBlue (already try).

Another really important event was the publication of the article Smashing the Stack for Fun and Profit by Aleph1 during 1996 in Phrack (a large electronic magazine about hacking and phreacking) which was the exploitation of the buffer overflow.

Anyway, let’s start at once, right?

A buffer overflow occurs when a program allows writing beyond the end of the memory space that was reserved to store the data you are receiving. It is generally understood that a buffer overflow is in the stack, while for those that occurred in the heap will be called heap overflow (very broad topic that we still have some way off). Synonyms for stack buffer overflow are smashing, buffer overrun, stack overflow and similar combinations.

Let’s see how a writing out of bounds can lead to **arbitrary code execution**. You have to understand that a `call asd` equivalent to performing a `push EIP; mov eip, asd`, and that a `ret` instruction is practically a `pop eip`. Therefore, if we take advantage of a buffer overflow to overwrite the saved reach EIP, running `ret` at the end of the function will be placed in EIP value we have placed there, gaining control program flow.

Normally a C function when it is compiled to assembler has a fixed pattern consisting of a prologue (keeps the stack frame of the above function and creates a new appropriate framework for local variables of the current function) code and an epilogue (restores the stack frame of the caller function), although the compiler adds certain instructions apart for reasons we do not want to analyze, exploit all that when we consider what we can change in our payload. Let’s see as an example the following code:  

    #include <stdio.h>

int print(char\* arg)  
{  
printf(arg);  
return 123;  
}

int main()  
{  
print(“Hola, soy un programa de mier… prueban”);  
return 0;  
}

After compiled (`gcc test.c -o test`) the following code in asm (extracted by `objdump -d test -Mintel`) is obtained

    08048492 <print>:
     8048492:       55                      push   ebp
     8048493:       89 e5                   mov    ebp,esp
     8048495:       53                      push   ebx
     8048496:       83 ec 04                sub    esp,0x4
     8048499:       e8 59 00 00 00          call   80484f7 <__x86.get_pc_thunk.ax>
     804849e:       05 62 1b 00 00          add    eax,0x1b62
     80484a3:       83 ec 0c                sub    esp,0xc
     80484a6:       ff 75 08                push   DWORD PTR [ebp+0x8]
     80484a9:       89 c3                   mov    ebx,eax
     80484ab:       e8 a0 fe ff ff          call   8048350 <printf@plt>
     80484b0:       83 c4 10                add    esp,0x10
     80484b3:       b8 7b 00 00 00          mov    eax,0x7b
     80484b8:       8b 5d fc                mov    ebx,DWORD PTR [ebp-0x4]
     80484bb:       c9                      leave  
     80484bc:       c3                      ret

We proceed to analyze

`push ebp  
mov ebp,esp`  
Prologue, the former ebp is saved, and placed in ebp value esp.

`push ebx`  
For some reason the program to save the value of ebx modifies before they recover before leaving the function.

`sub esp,0x4`  
Prologue is finished creating the stack frame with a space between ebp and esp wait decreasing function of space needed for local variable or what it is. The framework is now 4 bytes.

`call 80484f7 <__x86.get_pc_thunk.ax>`  
This gets in eax the address of the next instruction to be executed, it would be like a `mov eax, eip`, but it turns out that instruction is illegal.

`add eax,0x1b62`  
Related to the above statement, we’ll see what they do and how they relate.

`sub esp,0xc`  
For some reason the frame is enlarged by 12 bytes.

`push DWORD PTR [ebp+0x8]`  
Access to the argument of the function in which we find as the calling convention [cdecl](https://en.wikipedia.org/wiki/X86_calling_conventions) (While x86\_64 employed fastcall).

`mov ebx,eax`  
Finally, the compilers perform often nonsense.

`call 8048350 <printf@plt>`  
Finally called printf(), passing as an argument the string that has happened to us as an argument (the argument is already pushed, as we have seen for two instructions).

`add esp,0x10`  
Get rid of the frame.

`mov eax,0x7b`  
Equivalent to `return 123;`, as the functions return value in eax.

`mov ebx,DWORD PTR [ebp-0x4]`  
The value of ebx recovers previously saved.

`leave`  
Equivalent to `mov esp, ebp ; pop ebp`  
It´s the epilogue function, the frame is restored.

`ret`  
We return to the caller function.

We could have analyzed the main () function, however this feature is specialist.

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

The problem is that strcpy copy without limit until finding a value ‘x00’ (NULL).  
We can see through a debugger like gdb how to get control program flow to overdo the size of buf, introduce 500 A’s knowing that buf has a size 128.

``  
$ gcc b.c -o vuln -fno-stack-protector -D_FORTIFY_SOURCE=0 -m32  
$ gdb -q ./vuln  
Reading symbols from ./vuln...(no debugging symbols found)...done.  
(gdb) run `perl -e 'print "A"x500'`  
Starting program: /home/arget/vuln `perl -e 'print "A"x500'`  
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA  
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA  
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA  
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA  
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA  
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA  
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA``

Program received signal SIGSEGV, Segmentation fault.  
0x41414141 in ?? ()  
(gdb)

As you can see, there is a moment that the program attempted to execute code 0x41414141, 41 is in hexadecim0al the character ‘A’, showing that we walked the saved return address being collected by the `ret` instruction. In the next post we will see how to take advantage of this control.

At Puffin Security, we use the ELITE SECURITY CONSULTING methodology so you can rest assured that your organization will have the highest level of security. 

Complete the form, and we'll be in touch as soon as possible

[![Lets Audit Button](/assets/uploads/2023/01/Puffin-security-blog-button-lest-audit-2.jpg 'lets Audit Button')](https://www.puffinsecurity.com/contact-us)
