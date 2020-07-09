---
layout: es/blog-detail
comments: true
title: "Empezando desde ¿cero?"
date: 2018-07-02T15:44:00+00:00
categories:
    - Exploiting
tags:
    - buffer overflow
    - stack overrun
    - stack smashing
image_src: /assets/uploads/2018/07/Puffin-Security-Empezando-desde-cero-exploiting-ciberseguridad-e1563961416652.jpg
image_height: 467
image_width: 700
author: Yago Gutierrez
description: Desde hace tiempo vengo leyendo blogs acerca del exploiting, parece que hoy al fin ha llegado mi hora de cambiar el rol. En este blog publicaré posts a modo de cursillo «desde cero» del exploiting, y adicionalmente intentaré traer frecuentemente ejemplos de vulnerabilidades (de ahora...
publish_time: 2018-07-02T15:44:00+00:00
modified_time: 2019-02-18T09:09:26+00:00
comments_value: 0
---
Desde hace tiempo vengo leyendo blogs acerca del exploiting, parece que hoy al fin ha llegado mi hora de cambiar el rol. En este blog publicaré posts a modo de cursillo «desde cero» del exploiting, y adicionalmente intentaré traer frecuentemente ejemplos de vulnerabilidades (de ahora en adelante «vulns» si se me permite) en el rial guorld.  
Este post será principalmente una intro con la que adquirir las ideas básicas.

En fin, comencemos por definir el exploiting. El exploiting es el conjunto de técnicas que buscan aprovechar errores (bugs) del programador para manipular el comportamiento del programa, estos errores son principalmente una mala previsión de los posibles datos que puede proporcionar el usuario.  
Una vez leí una cita (de un tal P. Williams) que decía así

> Desde el punto de vista de un programador, el usuario no es más que un periférico que teclea cuando se le envía una petición de lectura.

Es posiblemente esta idea la que lleve a la aparición de estos errores. Para mí, el usuario es más bien un potencial asesino en serie con el que tenemos que ser educados y por eso hacemos lo que pida, **hasta cierto punto**, por lo que es necesario verificar siempre correctamente los datos que nos proporciona el usuario antes de manejarlos.

La explotación puede ser a muchos niveles (puedes explotar por ejemplo el servidor web, el binario en sí, o explotar la webapp que maneja ese servidor, técnicas como SQLi y XSS pertenecen a este último mundo, en cuanto a nosotros, disfrutaremos únicamente del mundo de los binarios, más hermoso al menos para mí) y desde luego existen casos de explotación extremadamente complejos y otros con esquemas más sencillos. A más complejidad, más diversión.

Para continuar entendiendo el significado completo de cada frase que leas, querido lector, quizá lo más saludable sea saber un poco de ensamblador (por ahora IA32, ya entraremos en AMD64 y quizá ARM/64, puede que hasta AVR) sé que puede dar miedo, pero bien domado es bastante dócil, además tampoco se requiere un conocimiento excesivo, ante cualquier instrucción que uno desconozca siempre se puede consultar un manual (por poner un ejemplo, el de Intel mismamente). Del mismo modo es necesario saber C o C++ y en más profundidad que ensamblador («asm» de ahora en adelante) .

Estas técnicas llevan explotándose desde antes de que muchos de nosotros naciéramos, si bien no creo que sea posible determinar en qué año comenzó la investigación en este campo. En cualquier caso, seguramente las agencias de inteligencia ya llevasen la ventaja cuando el público comenzó con ello (como ha pasado siempre, siendo la criptografía el mejor ejemplo, principalmente el descubrimiento de la criptografía asimétrica). Sin embargo posiblemente el hito más importante fue el 2 de noviembre de 1988 cuando Robert Tappan Morris, sin ver el desastre que se venía, ejecutó su famoso gusano Morris, responsable de infectar 6000 computadores de los 60000 conectados a la Internet del momento (todavía ARPANET) es decir, un 10%, causando un daño de miles de millones de dólares. Este gusano tenía una capacidad de replicación extrema gracias a que se propagaba explotando una vuln en el programa fingerd, consistente en un buffer overflow (esto lo hablaremos más tarde).

Múltiples virus han empleado desde entonces el exploiting para extenderse por la red, siendo el último caso más sonado el WannaCry, quien explotaba el EternalBlue (que ya trataremos).

Otro suceso realmente importante fue la publicación del artículo Smashing the Stack for Fun and Profit por Aleph1 durante 1996 en Phrack (una gran revista electrónica sobre hacking y phreacking) donde se trataba la explotación del buffer overflow.

En fin, empecemos de una vez, ¿no?

Un buffer overflow ocurre en el momento que un programa permite la escritura más allá del final del espacio de memoria que tenía reservado para almacenar los datos que está recibiendo. Por lo general se sobreentiende que un buffer overflow es en el stack, mientras que para los ocurridos en el heap se llamarán heap overflow (tema muy extenso que todavía nos queda algo lejos). Sinónimos de buffer overflow son stack smashing, buffer overrun, stack overflow y combinaciones similares.

Veamos cómo una escritura fuera de límites puede conducir a una **ejecución arbitraria de código**. Hay que entender que un `call asd` equivale a realizar un `push eip ; mov eip, asd`, y que una instrucción `ret` es prácticamente un `pop eip`. Por tanto, si logramos aprovechar un buffer overflow para llegar a sobrescribir el eip guardado, al ejecutar `ret` al final de la función se colocará en eip el valor que hayamos colocado ahí, obteniendo el control del flujo del programa.

Normalmente una función en C cuando es compilada al ensamblador tiene un esquema fijo, consistente en un prólogo (guarda el marco de pila de la función anterior y crea un nuevo marco apropiado para las variables locales de la función actual), el código y un epílogo (restaura el marco de pila al de la función caller), si bien el compilador añade ciertas instrucciones aparte por motivos que no nos interesa analizar, lo único que cuando explotemos debemos tener en cuenta lo que puedan modificar en nuestro payload.  
Veamos un ejemplo, el siguiente código  

    #include <stdio.h>

int imprimir(char\* arg)  
{  
printf(arg);  
return 123;  
}

int main()  
{  
imprimir(«Hola, soy un programa de mier… prueban»);  
return 0;  
}

Tras compilarse (`gcc prueba.c -o prueba`) se obtendrá el siguiente código en asm (extraído mediante `objdump -d prueba -Mintel`)  

    08048492 <imprimir>:
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

Procedamos a analizarlo

`push ebp  
mov ebp,esp`  
Prólogo, se guarda el ebp anterior, y se coloca en ebp el valor de esp.

`push ebx`  
Por algún motivo el programa desea guardar el valor de ebx antes de que se modifique  
para recuperarlo antes de salir de la función.

`sub esp,0x4`  
Prólogo, se termina de crear el marco del stack dejando un espacio entre ebp y esp disminuyendo esp  
en función del espacio que se necesite para las variable locales o lo que sea.  
El marco es ahora de 4 bytes.

`call 80484f7 <__x86.get_pc_thunk.ax>`  
Esta función obtiene en eax la dirección de la próxima instrucción a ejecutar, sería como un `mov eax, eip`, pero resulta que esa instrucción es ilegal.

`add eax,0x1b62`  
Relacionado con la anterior instrucción, ya veremos para qué sirven y cómo se relacionan.

`sub esp,0xc`  
Por algún motivo se agranda el marco en 12 bytes.

`push DWORD PTR [ebp+0x8]`  
Se accede al argumento de la función en la que nos encontramos según la convención de llamada [cdecl](https://en.wikipedia.org/wiki/X86_calling_conventions) (mientras que en x86\_64 se emplea fastcall).

`mov ebx,eax`  
¿? En fin, los compiladores muchas veces realizan sinsentidos.

`call 8048350 <printf@plt>`  
Finalmente se llama a printf(), pasando como argumento la cadena que se nos ha pasado a nosotros como argumento (el argumento ya está pusheado, como ya hemos visto hace dos instrucciones).

`add esp,0x10`  
Deshacemos parte del marco.

`mov eax,0x7b`  
Equivale a `return 123;`, pues las funciones devuelven en eax su valor de retorno.

`mov ebx,DWORD PTR [ebp-0x4]`  
Se recupera el valor de ebx guardado previamente.

`leave`  
Equivale a `mov esp, ebp ; pop ebp`  
Es el epílogo, de la función, se restaura el marco.

`ret`  
Volvemos a la función caller.

Podríamos haber analizado la función main(), sin embargo esta función es especialita.

Ahora vamos a ver una función explotable al fin xD  

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

El problema es que strcpy copia sin límite hasta encontrar un valor ‘x00’ (NULL).  
Podemos ver mediante un debugger como gdb cómo obtenemos el control del flujo del programa al excedernos del tamaño de buf, introduciremos 500 A’s sabiendo que buf tiene un tamaño de 128.  
``  
$ gcc b.c -o vuln -fno-stack-protector -D_FORTIFY_SOURCE=0 -m32  
$ gdb -q ./vuln  
Reading symbols from ./vuln...(no debugging symbols found)...done.  
(gdb) run `perl -e 'print "A"x500'`  
Starting program: /home/arget/vuln `perl -e 'print "A"x500'`  
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA``

Program received signal SIGSEGV, Segmentation fault.  
0x41414141 in ?? ()  
(gdb)

Como se puede ver, hay un momento que el programa ha intentado ejecutar código en 0x41414141, 41 es en hexadecim0al el carácter ‘A’, demostrando que hemos pisado la dirección de retorno guardada siendo recogida por la instrucción `ret`. En el próximo post veremos cómo aprovechar este control.