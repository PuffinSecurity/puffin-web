---
layout: es/blog-detail
comments: true
title: "La llave de todo, Firmware en dispositivos IoT"
date: 2019-02-25T07:44:52+00:00
categories:
    - Cyber security
    - IoT
tags:
    - bootloader
    - dispositivos IoT
    - firmware
    - kernel
image_src: /assets/uploads/2019/02/La-llave-de-todo-el-Firmware-de-dispositivos-IoT-e1563961483984.jpg
image_height: 467
image_width: 700
author: Ignacio Crespo Martínez
description: En este artículo nos adentraremos en el mundo del firmware en dispositivos IoT. Desde la perspectiva de seguridad, es el componente mas crítico.
publish_time: 2019-02-25T07:44:52+00:00
modified_time: 2019-03-01T08:13:48+00:00
comments_value: 0
disqus_identifier: 2623
---
En este artículo nos adentraremos en el [mundo de IoT](/cybersecurity-audit-assesment/internet-of-things/), centrándonos en el **firmware de los dispositivos IoT**. Cuando miramos desde la perspectiva de seguridad, es el componente más crítico de cualquier dispositivo. Casi todos los dispositivos que se nos puedan ocurrir ejecutan un firmware.

Incluso alguien que no tenga mucha experiencia en el manejo de electrónica o no haya trabajado con firmware, seguro que recuerda cuando le ha saltado una actualización de firmware de su smartphone o de su Smart Tv para **descargar la nueva versión**.

Un caso famoso de seguridad del firmware es la época en que surgió la **botnet** Mirai. Esta botnet infectaba los dispositivos accediendo a ellos a través del uso de las **credenciales por defecto**. Esto nos hace pensar en una pregunta, ¿Cómo podemos mantener a salvo los dispositivos IoT contra Mirai o que podemos hacer para que no sean vulnerables?

[¿Cómo podemos mantener a salvo los dispositivos IoT contra Mirai o que podemos hacer para que no sean vulnerables? #internetofthings #IoT #firmware #botnet](https://twitter.com/intent/tweet?url=https%3A%2F%2Fwww.puffinsecurity.com%2Fes%2Fla-llave-de-todo-el-firmware-en-dispositivos-iot%2F&text=%C2%BFC%C3%B3mo%20podemos%20mantener%20a%20salvo%20los%20dispositivos%20IoT%20contra%20Mirai%20o%20que%20podemos%20hacer%20para%20que%20no%20sean%20vulnerables%3F%20%23internetofthings%20%23IoT%20%23firmware%20%23botnet&via=puffinsecurity&related=puffinsecurity) [Clic para tuitear](https://twitter.com/intent/tweet?url=https%3A%2F%2Fwww.puffinsecurity.com%2Fes%2Fla-llave-de-todo-el-firmware-en-dispositivos-iot%2F&text=%C2%BFC%C3%B3mo%20podemos%20mantener%20a%20salvo%20los%20dispositivos%20IoT%20contra%20Mirai%20o%20que%20podemos%20hacer%20para%20que%20no%20sean%20vulnerables%3F%20%23internetofthings%20%23IoT%20%23firmware%20%23botnet&via=puffinsecurity&related=puffinsecurity)

Una de las soluciones podría ser la de ir verificando manualmente cada una de las credenciales de inicio de sesión de los diferentes servicios que están en ejecución. Pero eso sería un proceso muy tedioso, además de poco escalable ¿verdad?

Aquí es donde las “habilidades” de seguridad del firmware deben entrar en acción, ya que no podemos hacer ese proceso para cada uno de los millones de dispositivos IoT que existen en la actualidad.

**Pero entonces…**

### **¿Qué es el firmware en un dispositivo IoT?**

El firmware es una pieza de código que reside en la parte no volátil del dispositivo que permite y hace posible que el dispositivo realice las funciones para lo cual fue creado. Consta de varios componentes, como pueden ser el kernel, el bootloader, el sistema de archivos y recursos adicionales. Además, el firmware hace que varios **componentes de hardware** funcionen correctamente.

Sabiendo cuales son los diferentes componentes, vamos a explicarlos un poquito.

1.  **Bootloader**: es responsable de numerosas tareas, como la inicialización de varios componentes de hardware críticos y la asignación de los recursos necesarios.
2.  **Kernel**: es uno de los componentes principales de todo el dispositivo integrado. Hablando a un nivel muy general, un kernel es simplemente una capa intermedia entre el hardware y el software.
3.  **Sistema de archivos**: es donde se almacenan todos los archivos individuales necesarios para la ejecución del dispositivo. Esto también incluye componentes tales como servidores web y servicios de red.

[El firmware es una pieza de código que permite que el dispositivo realice las funciones para lo cual fue creado. #IoT #internetofthings #firmware #hacking #ciberseguridad](https://twitter.com/intent/tweet?url=https%3A%2F%2Fwww.puffinsecurity.com%2Fes%2Fla-llave-de-todo-el-firmware-en-dispositivos-iot%2F&text=El%20firmware%20es%20una%20pieza%20de%20c%C3%B3digo%20que%20permite%20que%20el%20dispositivo%20realice%20las%20funciones%20para%20lo%20cual%20fue%20creado.%20%23IoT%20%23internetofthings%20%23firmware%20%23hacking%20%23ciberseguridad&via=puffinsecurity&related=puffinsecurity) [Clic para tuitear](https://twitter.com/intent/tweet?url=https%3A%2F%2Fwww.puffinsecurity.com%2Fes%2Fla-llave-de-todo-el-firmware-en-dispositivos-iot%2F&text=El%20firmware%20es%20una%20pieza%20de%20c%C3%B3digo%20que%20permite%20que%20el%20dispositivo%20realice%20las%20funciones%20para%20lo%20cual%20fue%20creado.%20%23IoT%20%23internetofthings%20%23firmware%20%23hacking%20%23ciberseguridad&via=puffinsecurity&related=puffinsecurity)

### **¿Cómo es el proceso de arranque de un dispositivo IoT?**

1.  El bootloader inicia los componentes necesarios de hardware y sistema para el arranque.
2.  El bootloader se pasa a la dirección física del kernel, así como a la carga del árbol de dispositivos.
3.  El kernel se carga desde la dirección anterior, y luego inicia todos los procesos requeridos y los servicios adicionales para que el dispositivo funcione.
4.  Bootloader muere tan pronto como el kernel está cargado.
5.  El sistema de archivos raíz es montado.
6.  Tan pronto como se monta el sistema de archivos raíz, el kernel de Linux genera un programa llamado init.

Esto también significa que, si tenemos acceso al **bootloader** o si podemos cargar nuestro bootloader personalizado al dispositivo de destino, podremos controlar el funcionamiento completo del dispositivo, incluso haciendo que el dispositivo use un **kernel modificado** en lugar del original. Uno de los casos de uso más importantes de poder extraer el sistema de archivos del firmware es **poder buscar valores confidenciales dentro del firmware**.  Desde el punto de vista de un investigador de seguridad, esto es lo que se debe buscar en el sistema de archivos:

1.  Credenciales codificadas
2.  URLs sensibles.
3.  Logs de acceso
4.  API y claves de cifrado.
5.  Algoritmos de cifrado.
6.  Las rutas de acceso locales.
7.  Detalles del entorno.
8.  Mecanismos de autenticación y autorización.

[Si tenemos acceso al bootloader podremos controlar el funcionamiento completo del dispositivo IoT, incluso haciendo que use un kernel modificado #iot #ciberseguridad #bootloader](https://twitter.com/intent/tweet?url=https%3A%2F%2Fwww.puffinsecurity.com%2Fes%2Fla-llave-de-todo-el-firmware-en-dispositivos-iot%2F&text=Si%20tenemos%20acceso%20al%20bootloader%20podremos%20controlar%20el%20funcionamiento%20completo%20del%20dispositivo%20IoT%2C%20incluso%20haciendo%20que%20use%20un%20kernel%20modificado%20%23iot%20%23ciberseguridad%20%23bootloader&via=puffinsecurity&related=puffinsecurity) [Clic para tuitear](https://twitter.com/intent/tweet?url=https%3A%2F%2Fwww.puffinsecurity.com%2Fes%2Fla-llave-de-todo-el-firmware-en-dispositivos-iot%2F&text=Si%20tenemos%20acceso%20al%20bootloader%20podremos%20controlar%20el%20funcionamiento%20completo%20del%20dispositivo%20IoT%2C%20incluso%20haciendo%20que%20use%20un%20kernel%20modificado%20%23iot%20%23ciberseguridad%20%23bootloader&via=puffinsecurity&related=puffinsecurity)

### **¿Cómo podemos analizar el firmware?**

Como hemos visto antes, el firmware contiene varias secciones incrustadas dentro de él.

Por lo tanto, el primer paso para analizar un firmware y obtener una visión más profunda de él, es identificar las diferentes secciones que funcionan juntas para hacer el firmware completo. El firmware no deja de ser una **pieza binaria de datos**, que cuando es abierto con un editor hexadecimal, se revelan las diferentes secciones que contiene ese binario, que se identifican observando los bytes de firma de cada sección individualmente.

#### Tipos de archivos de firmware IoT

Antes de comenzar a analizar un firmware de manera real, debemos primero entender que cosas vamos a esperar ver cuando comencemos nuestro análisis del firmware. El componente en el que nos vamos a centrar en este articulo es el sistema de archivos. El **sistema de archivos de un dispositivo IoT** puede ser de diferentes tipos, en función de los requisitos del fabricante y la función a la que este destinado el dispositivo.

Cada tipo de sistema de archivos tiene su propio encabezado de firma exclusivo, que luego usaremos para identificar la ubicación del comienzo del sistema de archivos en el binario del firmware.

Los sistemas de **archivos más comunes** que solemos encontrar en los **dispositivos IoT** serían los siguientes:

*   Squashfs
*   Cramfs
*   JFFS2
*   YAFFS2
*   ext2

Además de los diferentes sistemas de archivos que hay, también existen diferentes tipos de compresión que son usados. Gracias a la utilización de la **compresión del sistema de archivos** conseguimos ahorrar espacio de almacenamiento en el dispositivo IoT, lo cual es muy valioso cuando se trata de este tipo de dispositivos. Las compresiones más comunes que solemos encontrar en los dispositivos IoT son las que se enumeran a continuación:

1.  LZMA
2.  Gzip
3.  Zip
4.  Zlib
5.  ARJ

#### ¿Cómo hacernos con el firmware de un dispositivo IoT?

Dependiendo de que sistema de archivos y que tipo de compresión se utilicen en el dispositivo a analizar, se utilizarán un conjunto de herramientas diferentes. Ahora, antes de **extraer el firmware de un dispositivo** y profundizar en él, debemos comprender cuáles son las diversas formas por las que podemos acceder al firmware de un dispositivo IoT.

Lo primero que debemos aprender para realizar el análisis de un firmware, es **cómo hacernos con el firmware del dispositivo**. Esto dependerá del dispositivo del cual queremos conseguirlo.

La primera forma, la más fácil y común de obtener el firmware del dispositivo, es buscarlo en Internet. Muchos fabricantes deciden poner el archivo binario del firmware para que pueda ser descargado, ya sea en la sección de soporte del dispositivo o mismamente en la sección de descargas. También es muy común **encontrar el firmware** en diferentes foros de discusión. Por poner un ejemplo, en el sitio web de TP-Link, si buscamos alguno de los dispositivos que la marca ofrece en el mercado, existe alta probabilidad que encontremos un enlace para descargar el firmware del dispositivo.

La segunda forma de obtener el firmware es un enfoque en el que necesitamos acceso físico al dispositivo. De esta manera, debemos utilizar diferentes **técnicas de explotación de hardware** para poder volcar el firmware de la memoria del dispositivo. Dependiendo del dispositivo, el nivel de protección puede variar e igual debemos utilizar otras técnicas de explotación de hardware para obtener el binario del firmware. En algunas ocasiones encontraremos que se puede obtener el binario simplemente volcándolo a través de una conexión UART, en algunos casos puede ser que tengamos que usar JTAG o en otros casos tendremos que volcarlo desde el chip flash.

[¿Cómo hacernos con el firmware de un dispositivo IoT? #ciberseguridad #IoT #firmware](https://twitter.com/intent/tweet?url=https%3A%2F%2Fwww.puffinsecurity.com%2Fes%2Fla-llave-de-todo-el-firmware-en-dispositivos-iot%2F&text=%C2%BFC%C3%B3mo%20hacernos%20con%20el%20firmware%20de%20un%20dispositivo%20IoT%3F%20%23ciberseguridad%20%23IoT%20%23firmware&via=puffinsecurity&related=puffinsecurity) [Clic para tuitear](https://twitter.com/intent/tweet?url=https%3A%2F%2Fwww.puffinsecurity.com%2Fes%2Fla-llave-de-todo-el-firmware-en-dispositivos-iot%2F&text=%C2%BFC%C3%B3mo%20hacernos%20con%20el%20firmware%20de%20un%20dispositivo%20IoT%3F%20%23ciberseguridad%20%23IoT%20%23firmware&via=puffinsecurity&related=puffinsecurity)

La tercera manera de obtener el firmware es mediante el “**sniffing OTA**”, es decir, obtener el binario mientras el dispositivo realiza una actualización del firmware. En este proceso debemos configurar el interceptor de red para el dispositivo, de tal manera que cuando el dispositivo solicite descargar la nueva imagen del firmware, extraerla de la captura de red que hemos realizado. Está claro que esta técnica puede tener complicación, como en el caso de que el archivo que se está descargando no sea el firmware completo, sino un pequeño paquete de actualización, o que no tengamos configurado el proxy de manera continua para interceptar el tráfico.

La última técnica para poder obtener el binario del firmware es la de **reversear una aplicación**. Este método implica que debemos analizar la Web y las aplicaciones móviles del dispositivo IoT, y a partir de ahí, descubrir una forma de obtener el firmware.

Una vez que tenemos el binario del firmware, una de las cosas más importantes que podemos hacer es **extraer el sistema de archivos de la imagen del binario.**

Para ello, utilizamos la herramienta Binwalk, que nos permite automatizar el proceso de extraer el sistema de archivos de un binario de un firmware. Lo que hace es comparar la firma que está presente en el binario del firmware con las que están guardadas en su base de datos e identifica mediante este proceso cuáles son las diferentes secciones que se encuentran presentes en el binario.

[Una vez descargado el firmware, usaremos Binwalk para ver las diferentes secciones del binario. #ciberseguridad #IoT #firmware #binwalk](https://twitter.com/intent/tweet?url=https%3A%2F%2Fwww.puffinsecurity.com%2Fes%2Fla-llave-de-todo-el-firmware-en-dispositivos-iot%2F&text=Una%20vez%20descargado%20el%20firmware%2C%20usaremos%20Binwalk%20para%20ver%20las%20diferentes%20secciones%20del%20binario.%20%23ciberseguridad%20%23IoT%20%23firmware%20%23binwalk&via=puffinsecurity&related=puffinsecurity) [Clic para tuitear](https://twitter.com/intent/tweet?url=https%3A%2F%2Fwww.puffinsecurity.com%2Fes%2Fla-llave-de-todo-el-firmware-en-dispositivos-iot%2F&text=Una%20vez%20descargado%20el%20firmware%2C%20usaremos%20Binwalk%20para%20ver%20las%20diferentes%20secciones%20del%20binario.%20%23ciberseguridad%20%23IoT%20%23firmware%20%23binwalk&via=puffinsecurity&related=puffinsecurity)

Lo primero que debemos hacer es configurar la herramienta. Lo vamos a hacer en una instancia de Ubuntu. Para ello nos descargamos y configuramos la herramienta:

git clone https://github.com/ReFirmLabs/binwalk.git  
cd binwalk/  
sudo python setup.py install

Una vez tenemos Binwallk instalado, es el momento de descargar un nuevo firmware. En este caso el que vamos a utilizar es Damn Vulnerable Router Firmware. Nos los descargamos:

wget –no-check-certificate https://github.com/praetorian-inc/DVRF/blob/master/Firmware/DVRF\_v03.bin?raw=true

Una vez que nos hemos descargado el firmware, vamos a usar **Binwalk** y ver la diferentes secciones que están presentes en el binario.

binwalk -t DVRF.bin

\-t le indica a BinWalk que formatee el texto de la salida en un formato agradable.

Una vez ejecutado el comando, este nos debería devolver lo siguiente:

![Binwalk screenshot -t](/assets/ewww/lazy/placeholder-1048x239.png)

![Binwalk screenshot -t](/assets/uploads/2019/02/binwalk.jpg)

Como podemos ver, la herramienta nos dice que hay 4 secciones en el binario.

1.  BIN-Header
2.  Firmware header
3.  gzip compressed data
4.  Squashfs filesystem

Ahora vamos a comprobar si el binario está encriptado o solamente está comprimido. Para ello realizamos un análisis de la entropía del binario. Para ello ejecutamos:

binwalk -E DVRF.bin

Nos devolverá un gráfico como el siguiente.

![Entropia del binario](/assets/ewww/lazy/placeholder-611x458.png)

![Entropia del binario](/assets/uploads/2019/02/entropia-del-binario.png)

Como podemos observar, el grafico nos muestra una línea con algunas pequeñas variaciones, lo que nos indica que los datos solamente están comprimidos y no encriptados.

Si nos hubiese mostrado una línea completamente plana, indicaría que los datos están encriptados. Así que ya sabemos que la imagen del firmware no tiene los datos encriptados.

A continuación, una vez que sabemos esto, vamos a **extraer el sistema de archivos de la imagen del firmware**. Para ello utilizaremos:

binwalk -e DVRF.bin

Aunque la salida nos parezca igual que la anterior pero menos agradable, en este caso, también se ha generado un nuevo directorio que contiene el sistema de archivos extraído. El directorio generado por **binwalk** se nombra con el nombre del firmware, se le añade un guion bajo (\_) al principio y se le pone la extensión ‘.extracted’.

![Binwalk -e](/assets/ewww/lazy/placeholder-1058x226.png)

![Binwalk -e](/assets/uploads/2019/02/binwalk-e.jpg)

Si entramos en el directorio encontraremos:

1.  squashfs
2.  piggy
3.  squashfs-root

Si nos adentramos dentro de la **carpeta squash-root**, nos encontramos con todo el sistema de archivos de la imagen del firmware, como se puede ver.

![IoT firmware files](/assets/ewww/lazy/placeholder-604x325.png)

![IoT firmware files](/assets/uploads/2019/02/IoT-firmware-files.png.jpg)

Como hemos visto, utilizar **Binwalk** hace que sea extremadamente fácil extraer el sistema de archivos de un binario de firmware.

En el siguiente articulo seguiremos viendo como analizar el firmware.