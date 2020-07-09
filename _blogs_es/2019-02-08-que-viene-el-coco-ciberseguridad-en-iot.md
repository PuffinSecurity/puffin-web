---
layout: es/blog-detail
comments: true
title: "Que viene el coco: ciberseguridad en IoT"
date: 2019-02-08T09:20:30+00:00
categories:
    - Cyber security
    - IoT
tags:
    - dispositivos IoT
    - hacking
    - Internet of Things
    - smart home
    - vulnerabilidades
    - Wifi
image_src: /assets/uploads/2019/02/Puffin-security-blog-adrian-campazas-que-viene-el-coco-proteccion-y-ciberseguridad-en-iot-internet-of-things-e1563961240804.jpg
image_height: 467
image_width: 700
author: Adrián Campazas
description: En este primer artículo que escribo quiero hablar del Coco de la ciberseguridad de los últimos tiempos que no es otro que el IOT (Internet of Things)
publish_time: 2019-02-08T09:20:30+00:00
modified_time: 2019-03-01T08:43:55+00:00
comments_value: 0
disqus_identifier: 1727
---
Podría dedicar este artículo a interpretar la estampa firmada por Francisco de Goya, pero ni yo soy experto en arte ni vosotros habéis visitado este blog para eso. En este primer artículo que escribo quiero hablar del Coco de la ciberseguridad de los últimos tiempos, que no es otro que la ciberseguridad en **IoT (Internet of Things).**

### **¿Por qué tantos problemas de ciberseguridad en IoT?**

El primer motivo es la falta de concienciación por parte de los fabricantes, estos no son conscientes de las **vulnerabilidades** que pueden existir en un ecosistema IoT y de la complejidad a nivel de seguridad que este ecosistema supone. Otra razón que es tremendamente habitual en el mundo del desarrollo y que con suerte parece que se está empezando a revertir es que  la seguridad no da dinero. Esta afirmación es cierta, hacer tu producto seguro no da dinero, pero puede evitar que lo pierdas todo. Lamentablemente de la segunda parte de la frase solo nos damos cuenta cuando ocurren grandes incidentes de seguridad. Hola **Wannacry** !!!!.

El segundo motivo principal  es la falta de perfiles formados en seguridad y especializados en este tipo de dispositivos.

Según Gartner en 2020 habrá más de 20 billones de **dispositivos conectados**. Da un poco de miedo ¿verdad?

[Según @Gartner\_inc en 2020 habrá más de 20 billones de dispositivos conectados. https://buff.ly/2ROg8U0 Hablando de seguridad IoT da un poco de miedo ¿verdad? #IoT #ciberseguridad #digital #smarthome #seguridad](https://twitter.com/intent/tweet?url=https%3A%2F%2Fwww.puffinsecurity.com%2Fes%2Fque-viene-el-coco-ciberseguridad-en-iot%2F&text=Seg%C3%BAn%20%40Gartner_inc%20en%202020%20habr%C3%A1%20m%C3%A1s%20de%2020%20billones%20de%20dispositivos%20conectados.%20https%3A%2F%2Fbuff.ly%2F2ROg8U0%20Hablando%20de%20seguridad%20IoT%20da%20un%20poco%20de%20miedo%20%C2%BFverdad%3F%20%23IoT%20%23ciberseguridad%20%23digital%20%23smarthome%20%23seguridad&related) [Clic para tuitear](https://twitter.com/intent/tweet?url=https%3A%2F%2Fwww.puffinsecurity.com%2Fes%2Fque-viene-el-coco-ciberseguridad-en-iot%2F&text=Seg%C3%BAn%20%40Gartner_inc%20en%202020%20habr%C3%A1%20m%C3%A1s%20de%2020%20billones%20de%20dispositivos%20conectados.%20https%3A%2F%2Fbuff.ly%2F2ROg8U0%20Hablando%20de%20seguridad%20IoT%20da%20un%20poco%20de%20miedo%20%C2%BFverdad%3F%20%23IoT%20%23ciberseguridad%20%23digital%20%23smarthome%20%23seguridad&related)

#### **¿Esto del IoT es muy crítico?**

Pues depende, vamos a coger como referencia una bombilla conectada a la que un atacante realiza un **ataque de denegación de servicio**, el resultado del ataque es que la bombilla se apaga, ¿es crítico? Pues a menos que sufras de escotofobia no parece muy grave. Ahora vamos a tomar otra referencia muy distinta, que os parece un marcapasos, ¿A que ya os está empezando a dar un poquito más de miedo el resultado?

Me diréis bueno Adrián que extremista eres, ¿quien iba a querer **Hackear** un marcapasos? Vale, os lo compro, pongamos otro ejemplo más cotidiano, que os parece un vigila bebés, lo común en ese tipo de dispositivos es que un atacante sea capaz de ver y robar las imágenes que graba el aparato. Me diréis, bueno, no es para tanto. Pues depende, si esas imágenes de vuestro hijo/hija terminan en una red de pornografía infantil quizá si que lo sea.

Este tipo de acciones maliciosas podemos calificarlas como instantáneas, que ocurre cuando por ejemplo un fabricante de altavoces inteligentes no ha puesto hincapié en la seguridad y su dispositivo ha sido comprometido y utilizado para atacar masivamente a plataformas de terceros. Pues el resultado es una **denegación de servicio** a una plataforma de renombre y un escándalo en prensa que destroza la imagen que había ganado durante tantos años de esfuerzo la empresa de altavoces.

Estos son solo algunos ejemplos de lo que puede pasar si los fabricantes no ponen especial hincapié en la **seguridad de sus dispositivos**.

Como conclusión a este apartado, ¿la seguridad es crítica? la respuesta es rotundamente si, las empresas deben apostar por diseños seguros, y [realizar auditorías a sus productos](/?page_id=702) para poder evaluar la seguridad de los mismos.

Ahora que os he metido un poco el miedo en el cuerpo, vamos a ver **piezas conforman el ecosistema IoT**, cuales son sus principales vulnerabilidades y como podemos diseñar un vector de ataque a la hora de realizar una auditoría a este tipo de dispositivos.

[Hackear un dispositivo como un vigila bebés, significa que un atacante pueda robar las imágenes que graba y que terminen en una red de pornografía infantil https://buff.ly/2ROg8U0 #iot #ciberseguridad #privacidad #cibercrimen](https://twitter.com/intent/tweet?url=https%3A%2F%2Fwww.puffinsecurity.com%2Fes%2Fque-viene-el-coco-ciberseguridad-en-iot%2F&text=Hackear%20un%20dispositivo%20como%20un%20vigila%20beb%C3%A9s%2C%20significa%20que%20un%20atacante%20pueda%20robar%20las%20im%C3%A1genes%20que%20graba%20y%20que%20terminen%20en%20una%20red%20de%20pornograf%C3%ADa%20infantil%20https%3A%2F%2Fbuff.ly%2F2ROg8U0%20%23iot%20%23ciberseguridad%20%23privacidad%20%23cibercrimen&related) [Clic para tuitear](https://twitter.com/intent/tweet?url=https%3A%2F%2Fwww.puffinsecurity.com%2Fes%2Fque-viene-el-coco-ciberseguridad-en-iot%2F&text=Hackear%20un%20dispositivo%20como%20un%20vigila%20beb%C3%A9s%2C%20significa%20que%20un%20atacante%20pueda%20robar%20las%20im%C3%A1genes%20que%20graba%20y%20que%20terminen%20en%20una%20red%20de%20pornograf%C3%ADa%20infantil%20https%3A%2F%2Fbuff.ly%2F2ROg8U0%20%23iot%20%23ciberseguridad%20%23privacidad%20%23cibercrimen&related)

#### **El ecosistema IoT**

Cuando un atacante trata de establecer los posibles vectores de ataques contra un aplicativo web o contra una aplicación móvil se va a encontrar que el vector es el propio aplicativo y las comunicaciones que este establece. A la hora de realizar un **ataque contra un entorno IoT** la superficie de ataque es mucho más extensa.

Un **entorno IoT** suele como mínimo estar formado por los siguientes componentes

*   Hardware
*   Aplicación Web a la que se conecta el dispositivo y suele almacenar la información del mismo.
*   Aplicaciones Móviles que habitualmente se utilizan para controlar el dispositivo.
*   Firmware
*   Comunicaciones

Un entorno tan complejo implica que **una vulnerabilidad en cualquier de estos componentes puede arruinar la seguridad de todo el dispositivo.**

Además de los componentes, **cada dispositivo IoT utiliza protocolos diferentes** para la misma tarea lo que aumenta considerablemente la fragmentación del ecosistema y por lo tanto dificulta la tarea de análisis de seguridad.

En la siguiente imagen podemos ver algunos de los muchos protocolos utilizados en el ecosistema IoT:

![Tipos de protocolos usados en el ecosistema de IoT Internet of Things por Tara Salman](/assets/ewww/lazy/placeholder-802x372.png)

![Tipos de protocolos usados en el ecosistema de IoT Internet of Things por Tara Salman](/assets/uploads/2019/02/Tipos-de-protocolos-usados-en-el-ecosistema-de-IoT-Internet-of-Things-por-Tara-Salman.png)

[Un entorno IoT suele componerse de Hardware, App móvil, dispositivo, Firmware y comunicaciones, una vulnerabilidad en cualquier de estos componentes puede arruinar la seguridad de todo el dispositivo. https://buff.ly/2ROg8U0 #ciberseguridad #IoT…](https://twitter.com/intent/tweet?url=https%3A%2F%2Fwww.puffinsecurity.com%2Fes%2Fque-viene-el-coco-ciberseguridad-en-iot%2F&text=Un%20entorno%20IoT%20suele%20componerse%20de%20Hardware%2C%20App%20m%C3%B3vil%2C%20dispositivo%2C%20Firmware%20y%20comunicaciones%2C%20una%20vulnerabilidad%20en%20cualquier%20de%20estos%20componentes%20puede%20arruinar%20la%20seguridad%20de%20todo%20el%20dispositivo.%20https%3A%2F%2Fbuff.ly%2F2ROg8U0%20%23ciberseguridad%20%23IoT%E2%80%A6&related) [Clic para tuitear](https://twitter.com/intent/tweet?url=https%3A%2F%2Fwww.puffinsecurity.com%2Fes%2Fque-viene-el-coco-ciberseguridad-en-iot%2F&text=Un%20entorno%20IoT%20suele%20componerse%20de%20Hardware%2C%20App%20m%C3%B3vil%2C%20dispositivo%2C%20Firmware%20y%20comunicaciones%2C%20una%20vulnerabilidad%20en%20cualquier%20de%20estos%20componentes%20puede%20arruinar%20la%20seguridad%20de%20todo%20el%20dispositivo.%20https%3A%2F%2Fbuff.ly%2F2ROg8U0%20%23ciberseguridad%20%23IoT%E2%80%A6&related)

### **¿Por dónde empiezo si quiero realizar una auditoría de seguridad a un dispositivo IoT?**

A la hora de realizar una auditoría de seguridad  en un  dispositivo IoT, es fundamental saber a que nos estamos enfrentado. ¿Qué componentes están involucrados en el dispositivo?, ¿Que herramientas necesitaremos utilizar?

Es importante dedicar tiempo para conocer cual va a ser la **superficie de ataque**. Como hemos visto, cada dispositivo es un mundo y debemos saber que es lo que tenemos entre manos.

Temas técnicos aparte, es importante identificar que es lo realmente crítico en el dispositivo, por ejemplo en una cámara ip, lo más crítico que puede pasar es que un atacante sea capaz de ver las imágenes de lo que se está grabando. Sin embargo en un frigorífico conectado que cuente con una  cámara interna, lo más crítico quizá no será ver las imágenes de dicha cámara, si no que **un atacante pueda robar los datos bancarios** que el frigorífico almacena para realizar pedidos automáticamente.

[En un frigorífico con una cámara, lo más crítico no será las imágenes, sino que un atacante pueda robar los datos bancarios que almacena para realizar pedidos. https://buff.ly/2ROg8U0 #IoT #ciberseguridad #cibercrimen](https://twitter.com/intent/tweet?url=https%3A%2F%2Fwww.puffinsecurity.com%2Fes%2Fque-viene-el-coco-ciberseguridad-en-iot%2F&text=En%20un%20frigor%C3%ADfico%20con%20una%20c%C3%A1mara%2C%20lo%20m%C3%A1s%20cr%C3%ADtico%20no%20ser%C3%A1%20las%20im%C3%A1genes%2C%20sino%20que%20un%20atacante%20pueda%20robar%20los%20datos%20bancarios%20que%20almacena%20para%20realizar%20pedidos.%20https%3A%2F%2Fbuff.ly%2F2ROg8U0%20%23IoT%20%23ciberseguridad%20%23cibercrimen%20&via=@puffinsecurity&related=@puffinsecurity) [Clic para tuitear](https://twitter.com/intent/tweet?url=https%3A%2F%2Fwww.puffinsecurity.com%2Fes%2Fque-viene-el-coco-ciberseguridad-en-iot%2F&text=En%20un%20frigor%C3%ADfico%20con%20una%20c%C3%A1mara%2C%20lo%20m%C3%A1s%20cr%C3%ADtico%20no%20ser%C3%A1%20las%20im%C3%A1genes%2C%20sino%20que%20un%20atacante%20pueda%20robar%20los%20datos%20bancarios%20que%20almacena%20para%20realizar%20pedidos.%20https%3A%2F%2Fbuff.ly%2F2ROg8U0%20%23IoT%20%23ciberseguridad%20%23cibercrimen%20&via=@puffinsecurity&related=@puffinsecurity)

Esto ocurre también en otro tipo de auditorías, en referencia a una auditoría web incluso por encima de una **inyección de SQL** que permita robar datos, lo más crítico para una entidad bancaria es que un atacante sea capaz de crear dinero. Este enfoque quizá menos técnico en algunas ocasiones es pasado por alto y desde mi punto de vista es un error grave por parte del auditor.

Ahora que ya tenemos más o menos claro cuales son las partes que conforman un ecosistema IoT, vamos a ir analizando cada una de ellas de forma un poco más exhaustiva.

#### **Hardware**

Un dispositivo IoT puede ser utilizado para multitud de tareas. A la hora de realizar un test de **seguridad del dispositivo**, la aproximación ha de ser la misma independientemente de para que se utilice  el dispositivo en lo que a hardware se refiere.

Las vulnerabilidades más típicas que podemos encontrar en un dispositivo embebido son:

*   Puertos expuestos.
*   Mecanismos de autenticación inseguros en los puertos que se encuentran expuestos
*   Dumpeo del firmware habilitado mediante JTAG o chips de flaseo
*   Ataques basados en medios externos

#### **Firmware, Software y aplicaciones**

Después del análisis del hardware el siguiente componente que debemos analizar es el software, el firmware y las aplicaciones que controlan el dispositivo tanto a nivel web como a nivel de dispositivos móviles.

En este punto se aplican técnicas tradicionales utilizadas en [pentesting](/), estamos hablando de ingeniería inversa (reversing) tanto de los binarios que componen el sistema, normalmente desarrollados para arquitecturas MIPS o ARM ya que son las arquitecturas más utilizadas en dispositivos IoT,  como de aplicaciones móviles que pueden llegar a  revelar multitud de secretos y vulnerabilidades.

Comencemos por las **aplicaciones móviles.** Son por norma general las encargadas de controlar los dispositivos inteligentes, las dos plataformas que reinan en este mercado son Android e IOS.

Diariamente se realizan multitud de ataques contra aplicaciones móviles que dejan al descubierto información sensible del dispositivo, del funcionamiento del mismo o del usuario que lo utiliza.

Los dispositivos móviles son un punto de entrada muy común al backend de los aplicativos web y a las bases de datos que se encuentran detrás. Es un error común de muchas empresas realizar auditorías de seguridad de sus aplicativos web e ignorar los dispositivos móviles que trabajan sobre el mismo backend y que pueden poner en riesgo toda la seguridad.

[Diariamente multitud de #ataques contra aplicaciones móviles dejan al descubierto información sensible del dispositivo, del funcionamiento del mismo o del usuario que lo utiliza. https://buff.ly/2ROg8U0 #ciberseguridad #App #mobile](https://twitter.com/intent/tweet?url=https%3A%2F%2Fwww.puffinsecurity.com%2Fes%2Fque-viene-el-coco-ciberseguridad-en-iot%2F&text=Diariamente%20multitud%20de%20%23ataques%20contra%20aplicaciones%20m%C3%B3viles%20dejan%20al%20descubierto%20informaci%C3%B3n%20sensible%20del%20dispositivo%2C%20del%20funcionamiento%20del%20mismo%20o%20del%20usuario%20que%20lo%20utiliza.%20https%3A%2F%2Fbuff.ly%2F2ROg8U0%20%23ciberseguridad%20%23App%20%23mobile&via=puffinsecurity&related=puffinsecurity) [Clic para tuitear](https://twitter.com/intent/tweet?url=https%3A%2F%2Fwww.puffinsecurity.com%2Fes%2Fque-viene-el-coco-ciberseguridad-en-iot%2F&text=Diariamente%20multitud%20de%20%23ataques%20contra%20aplicaciones%20m%C3%B3viles%20dejan%20al%20descubierto%20informaci%C3%B3n%20sensible%20del%20dispositivo%2C%20del%20funcionamiento%20del%20mismo%20o%20del%20usuario%20que%20lo%20utiliza.%20https%3A%2F%2Fbuff.ly%2F2ROg8U0%20%23ciberseguridad%20%23App%20%23mobile&via=puffinsecurity&related=puffinsecurity)

En próximos artículos trataremos diferentes técnicas y **vulnerabilidades** que se encuentran en dispositivos móviles y que por supuesto pueden poner en riesgo la seguridad de todo el ecosistema de un dispositivo IoT.

**Panel de control web:** Permite al usuario monitorizar el dispositivo, analizar la información y gestionar el dispositivo en lo que a permisos de seguridad se refiere. En caso de que la aplicación web sea vulnerable, un atacante podría acceder a información sin autorización. Acceder a información de otros usuarios. Etc.

**Interfaces de red inseguras:** Este apartado hace referencia a la revisión de los puertos que un dispositivo pueda tener abiertos. Se suelen ver a menudo puertos mal configurados que no requieran una autenticación o que escondan protocolos vulnerables y desactualizados. Multitud de dispositivos utilizan versiones vulnerables de SNMP o FTP.

**Firmware:** El firmware es la joya de la corona de cualquier dispositivo IoT y el que guarda las llaves del reino. Casi cualquier cosa puede ser extraído del firmware. Seguiré profundizando sobre esto en futuros artículos para tratar diferentes vulnerabilidades y técnicas que se utilizan para descubrir información importante dentro del firmware.

[Aunque los dispositivos móviles son un punto de entrada muy común al backend... es un error común realizar auditorías de seguridad de una #App e ignorarlos https://buff.ly/2ROg8U0 #ciberseguridad](https://twitter.com/intent/tweet?url=https%3A%2F%2Fwww.puffinsecurity.com%2Fes%2Fque-viene-el-coco-ciberseguridad-en-iot%2F&text=Aunque%20los%20dispositivos%20m%C3%B3viles%20son%20un%20punto%20de%20entrada%20muy%20com%C3%BAn%20al%20backend...%20es%20un%20error%20com%C3%BAn%20realizar%20auditor%C3%ADas%20de%20seguridad%20de%20una%20%23App%20e%20ignorarlos%20https%3A%2F%2Fbuff.ly%2F2ROg8U0%20%23ciberseguridad&related) [Clic para tuitear](https://twitter.com/intent/tweet?url=https%3A%2F%2Fwww.puffinsecurity.com%2Fes%2Fque-viene-el-coco-ciberseguridad-en-iot%2F&text=Aunque%20los%20dispositivos%20m%C3%B3viles%20son%20un%20punto%20de%20entrada%20muy%20com%C3%BAn%20al%20backend...%20es%20un%20error%20com%C3%BAn%20realizar%20auditor%C3%ADas%20de%20seguridad%20de%20una%20%23App%20e%20ignorarlos%20https%3A%2F%2Fbuff.ly%2F2ROg8U0%20%23ciberseguridad&related)

##### Como resumen, estas son las vulnerabilidades principales que podemos encontrar en los distintos puntos de este apartado:

**MODIFICACIÓN DEL FIRMWARE  
**Posiblemente de las cosas más peligrosas que se pueden hacer, si somos capaces de modificar el firmware podríamos habilitar un servicio ssh o lanzar una Shell. Este tipo de vulnerabilidades son causadas debido a **Firmas inseguras o a la no verificación de integridad.**

**ROBO DE INFORMACIÓN  
**Es preocupante la gran cantidad de **claves de cifrado hardcodeadas** en el firmware de los dispositivos que a día de hoy podemos seguir encontrando. Cualquiera con un conocimiento mínimo en reversing podría descubrir esas claves con facilidad. Además dentro del firmware podemos encontrar claves privadas, contraseñas de usuario URLs etc.

Además de las vulnerabilidades ya comentadas, también es preocupante que un atacante pueda extraer el sistema de archivos del dispositivo

 **Aplicaciones móviles:**

*   Dumpeo del código fuente,
*   Autenticación insegura
*   Ataques en tiempo de ejecución
*   Uso de librerías de terceros o SDK vulnerables.

 **Aplicaciones web:  
**

*   Inyecciones del lado del cliente.
*   Autenticación insegura
*   Robo de información sensible
*   XSS
*   Cross Site Request Forgery

Estas son algunas de las vulnerabilidades que podemos encontrar en el firmware o en las aplicaciones que utilizan los dispositivos IoT, por desgracia solo he nombrado unas pocas ya que hay muchas más. Tenemos que ser conscientes que un dispositivo IoT que utiliza una app por ejemplo desarrollada para Android, hereda todas las posibles vulnerabilidades que pueda sufrir una aplicación en esta plataforma. Lo mismo pasa con una aplicación web o una app IOS.

[Tenemos que ser conscientes que un dispositivo #IoT hereda todas las posibles vulnerabilidades que pueda sufrir una aplicación en esa plataforma ya sea #Android o #IOS https://buff.ly/2ROg8U0 #ciberseguridad #brecha #seguridad](https://twitter.com/intent/tweet?url=https%3A%2F%2Fwww.puffinsecurity.com%2Fes%2Fque-viene-el-coco-ciberseguridad-en-iot%2F&text=Tenemos%20que%20ser%20conscientes%20que%20un%20dispositivo%20%23IoT%20hereda%20todas%20las%20posibles%20vulnerabilidades%20que%20pueda%20sufrir%20una%20aplicaci%C3%B3n%20en%20esa%20plataforma%20ya%20sea%20%23Android%20o%20%23IOS%20https%3A%2F%2Fbuff.ly%2F2ROg8U0%20%23ciberseguridad%20%23brecha%20%23seguridad&via=@puffinsecurity&related=@puffinsecurity) [Clic para tuitear](https://twitter.com/intent/tweet?url=https%3A%2F%2Fwww.puffinsecurity.com%2Fes%2Fque-viene-el-coco-ciberseguridad-en-iot%2F&text=Tenemos%20que%20ser%20conscientes%20que%20un%20dispositivo%20%23IoT%20hereda%20todas%20las%20posibles%20vulnerabilidades%20que%20pueda%20sufrir%20una%20aplicaci%C3%B3n%20en%20esa%20plataforma%20ya%20sea%20%23Android%20o%20%23IOS%20https%3A%2F%2Fbuff.ly%2F2ROg8U0%20%23ciberseguridad%20%23brecha%20%23seguridad&via=@puffinsecurity&related=@puffinsecurity)

### **Comunicaciones: Apps y dispositivos móviles**

Las compañías desarrolladoras de dispositivos IoT no suelen poner mucha atención en este tipo de comunicaciones. Los protocolos utilizados en dispositivos IoT suelen ser los siguientes: 4G/WIFI, Bluetooh Low Energy (BLE) ZigBee, Wave, 6LoWPAN y LORA entre otros. Para poder auditar estas comunicaciones en algunos casos necesitaremos hacer uso de hardware especial.

Las tres categorías que suelen ser explotadas son:

*   Software Defined Radio(SDR)
*   ZigBee exploitation
*   BLE(Bluetooth Low Energy) Explotation.

Las vulnerabilidades más comunes que podemos encontrar en las comunicaciones de radio son:

*   Man In The Middle
*   ReplayBased attacks
*   Insecure CRC verification
*   Jamming based attacks
*   DOS
*   Lack of encryption
*   Life Packet Comunication interceptión y modificación.

#### **Tiempo de nostalgia**

##### **Tomemos un dispositivo de domótica o Smart Home**

Quizá el ejemplo más sencillo de dispositivo inteligente conectado es una llave de la luz.

Este es el esquema de una llave tradicional:

![El funcionamiento de IoT es similar a como funciona una llave de luz](/assets/ewww/lazy/placeholder-516x438.png)

![El funcionamiento de IoT es similar a como funciona una llave de luz](/assets/uploads/2019/02/ciberseguridad-internet-of-things-iluminacion-como-funciona-una-llave-de-luz.jpg)

Como podemos ver el vector de ataque de este dispositivo es muy posible que sea una subida de tensión o un corto circuito.

Este es el esquema de la llave inteligente desarrollada por Sonoff y que tiene un precio de unos 15 euros. 

![IOT system smart home devices wifi mobile APP](/assets/ewww/lazy/placeholder-666x360.png)

![IOT system smart home devices wifi mobile APP](/assets/uploads/2019/02/IOT-system-smart-home-devices-wifi-mobile-APP.jpg)

Como podemos ver entran en juego diferentes elementos que pueden ser posibles vectores de ataque, para empezar podemos ver las comunicaciones tanto de las **aplicaciones móviles** disponibles tanto para Android como para IOS con la nube. Las propias aplicaciones móviles, el dispositivo Hardware, el firmware que da vida al sistema y sus comunicaciones con la nube a través del router local. Y todo esto para una simple llave de la luz.

El ejemplo es muy sencillo pero como podemos ver el grado de complejidad de una simple llave de la luz conectada es elevado si lo comparamos con la llave tradicional.

Este nuevo ecosistema pone de manifiesto **la necesidad de que los fabricantes desarrollen sus productos pensando en la seguridad de los mismos** y además de eso realicen pruebas y comprueben el estado del producto antes de que pueda venir el coco a hacer una visita.

[El propio ecosistema de #IoT pone de manifiesto la necesidad de que los fabricantes desarrollen sus productos pensando en la #seguridad de los mismos https://buff.ly/2ROg8U0 #IoT #ciberseguridad](https://twitter.com/intent/tweet?url=https%3A%2F%2Fwww.puffinsecurity.com%2Fes%2Fque-viene-el-coco-ciberseguridad-en-iot%2F&text=El%20propio%20ecosistema%20de%20%23IoT%20pone%20de%20manifiesto%20la%20necesidad%20de%20que%20los%20fabricantes%20desarrollen%20sus%20productos%20pensando%20en%20la%20%23seguridad%20de%20los%20mismos%20https%3A%2F%2Fbuff.ly%2F2ROg8U0%20%23IoT%20%23ciberseguridad&via=@puffinsecurity&related=@puffinsecurity) [Clic para tuitear](https://twitter.com/intent/tweet?url=https%3A%2F%2Fwww.puffinsecurity.com%2Fes%2Fque-viene-el-coco-ciberseguridad-en-iot%2F&text=El%20propio%20ecosistema%20de%20%23IoT%20pone%20de%20manifiesto%20la%20necesidad%20de%20que%20los%20fabricantes%20desarrollen%20sus%20productos%20pensando%20en%20la%20%23seguridad%20de%20los%20mismos%20https%3A%2F%2Fbuff.ly%2F2ROg8U0%20%23IoT%20%23ciberseguridad&via=@puffinsecurity&related=@puffinsecurity)