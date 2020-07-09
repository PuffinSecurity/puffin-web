---
layout: es/blog-detail
comments: true
title: "MDR: La ultima barrera de defensa"
date: 2020-01-27T11:05:47+00:00
categories:
    - Cyber security
tags:
image_src: /assets/uploads/2020/01/mauina1-300x104.png
image_height: null
image_width: null
author: Adrián Campazas
description: La modernización y profesionalización de los cibercriminales ha provocado un nuevo paradigma en el mundo de la ciberseguridad. Las técnicas utilizadas para llevar a cabo sus objetivos ilícitos han evolucionado, por lo que nos encontramos ante un escenario en el que las soluciones tradicionales ya...
publish_time: 2020-01-27T11:05:47+00:00
modified_time: 2020-05-13T20:49:29+00:00
comments_value: 0
disqus_identifier: 3068
---
La modernización y profesionalización de los cibercriminales ha provocado un nuevo paradigma en el mundo de la ciberseguridad. Las técnicas utilizadas para llevar a cabo sus objetivos ilícitos han evolucionado, por lo que nos encontramos ante un escenario en el que las soluciones tradicionales ya no son capaces de proteger a sus clientes ya sean usuarios o empresas.

No existe la solución perfecta de ciberseguridad que detenga todas las amenazas a las que nos enfrentamos hoy en día. Cuando todos los sistemas de seguridad fallan (y van a fallar), como puede ser un antivirus, un IDS, un firewall, etc, existe una última barrera de protección, que es nuestro MDR. El MDR de PuffinSecurity es capaz de detectar en un tiempo minúsculo una amenaza  y responder ante ella.

El MDR está compuesto por dos partes: El agente Puffin que se ejecuta en cada endpoint monitorizado y el servidor que analiza los datos recibidos de los agentes y genera las alertas.

El agente puede ser ejecutado en sistemas Windows y Linux. La principal función del agente es recopilar diferentes tipos de datos del sistema y de las aplicaciones que ejecuta para posteriormente  enviarlas al servidor.

El servidor es el encargado de analizar los datos recibidos por parte de los agentes y de lanzar alertas cuando un evento coincide con una regla( por ejemplo, intrusión detectada, archivo modificado, posible rootkit, etc).

Bien, vamos a instalar el Servidor. Para ello nos descargamos la OVA de VirtualBox que incluye todo lo necesario para instalar nuestro servidor.

https://drive.google.com/file/d/1gQQoI53wrQCNyR-evm93ioG-5d4i2cxm/view?usp=sharing

Los requisitos  mínimos de esta máquina para que funcione correctamente son 16GB de RAM, disco duro SDD y 8 núcleos para gestionar unos 50 agentes conectados.

Nos la descargamos y la importamos

Iniciamos sesión con las siguientes credenciales:

*   **User:** root
*   **Password:** puffin-security

![](/assets/ewww/lazy/placeholder-300x104.png)

![](/assets/uploads/2020/01/mauina1-300x104.png)

Muy importante, debemos configurar la maquina con una IP estática en el router.

Un vez hemos iniciado sesión, debemos conocer que dirección IP  tiene la máquina en nuestra red. Lo hacemos utilizando el comando **ip address show****.**

![](/assets/ewww/lazy/placeholder-300x120.png)

![](/assets/uploads/2020/01/imagenip-300x120.png)

Ahora verificamos que la consola web de la máquina de PuffinSecurity sea accesible. Para ello vamos al navegador y escribimos la **https://<IP de la maquina de PuffinSecurity>**. Nos pedirá las credenciales de la consola que son las siguientes:

*   **User:** PuffinSecurity
*   **Password:** puffin-security

![](/assets/ewww/lazy/placeholder-300x148.png)

![](/assets/uploads/2020/01/kibana-300x148.png)

Ahora vamos a instalar los agentes, que serán los encargados de recopilar los datos y enviarlos al servidor.

Primero vamos a instalar el agente en Windows. Nos descargamos el agente del siguiente enlace.

https://drive.google.com/drive/folders/1-rPKgVPGvc7I0rMAdA-z\_Hy5cNEzVzqr?usp=sharing

Los requisitos que debe tener el sistema Windows en el que va a ser instalado son los siguientes:

1.  **Windows 7 SP1 o superior**
2.  **PowerShell versión 5.1 o superior**

Para comprobar la versión de powershell que tiene instalada en su ordenador, habrá una consola de powershell . Para ello busque **“powershell”** en el buscador de Windows y selecciones la opción que aparece en la siguiente imagen.

![](/assets/ewww/lazy/placeholder-300x261.png)

![](/assets/uploads/2020/01/buscarPS_1-300x261.png)

Escriba en la consola el comando **“get-host”** y aparecerá la versión que tiene instalada como se puede ver en la imagen siguiente.

![](/assets/ewww/lazy/placeholder-300x255.png)

![](/assets/uploads/2020/01/versión-ps_2-300x255.png)

Descomprimimos la carpeta que nos hemos descargado. Debería de haber dos archivos y una carpeta como se muestra en la imagen:

![](/assets/ewww/lazy/placeholder-300x150.png)

![](/assets/uploads/2020/01/Archivos-carpeta-Windows_3-300x150.png)

Vamos a instalar el agente. Para ello nos vamos a la carpeta donde hayamos guardado el instalador .msi que nos hemos descargado anteriormente y lo ejecutamos.

A continuación nos saldrá una ventana en que debemos aceptar los términos de la licencia y seleccionamos la opción de “Install” y comenzará la instalación.

![](/assets/ewww/lazy/placeholder-300x233.png)

![](/assets/uploads/2020/01/instalación1_4-300x233.png)

Una vez finalice la instalación, le damos al botón “Finish”. Importante que la opción “Run Agent configuration interface” este desmarcada como podemos ver en la siguiente imagen.

![](/assets/ewww/lazy/placeholder-300x236.png)

![](/assets/uploads/2020/01/Instalacion2_5-300x236.png)

A continuación, debemos instalar Sysmon, una herramienta de Microsoft que nos permitirá recolectar más información sobre el ordenador en el que está instalado el agente Puffin.

Lo primero vamos a obtener un fichero de configuración necesario en las instalación. Lo descargaremos de la siguiente URL: https://github.com/SwiftOnSecurity/sysmon-config

Una vez descargado, debemos de ajustar el archivo de configuración a los datos de nuestro servidor como podemos ver a continuación:

![](/assets/ewww/lazy/placeholder-300x62.png)

![](/assets/uploads/2020/01/configuraciónsysmon_6-300x62.png)

Para instalar la herramienta debemos abrir una consola de administrador. Para ello buscamos cmd en el buscador hacemos click derecho sobre la aplicación y seleccionamos la opción **“Ejecutar como administrador”**.

Una vez tenemos abierta la consola, nos vamos a la carpeta donde tenemos el programa Sysmon, que estará en la carpeta que nos hemos descargado**,** con el comando siguiente:

cd <ruta-carpeta-sysmon>

Una vez estemos dentro de esa carpeta, debemos ejecutar los siguientes comando:

Sysmon.exe -i sysmon.xml -accepteula

![](/assets/ewww/lazy/placeholder-300x91.png)

![](/assets/uploads/2020/01/sysmoninstall_7-300x91.png)

Con este comando sysmon se ha instalado en el sistema.

Ahora vamos a hacer que la herramienta se inicie automáticamente cada vez que arranque el sistema. Para ello ejecutamos el siguiente comando:

sc config Sysmon start= auto

![](/assets/ewww/lazy/placeholder-300x62.png)

![](/assets/uploads/2020/01/sysmon_inicio_8-300x62.png)

Ya tendríamos instalada y configurada la herramienta.

Bien, ahora ya tenemos instalado el agente y Sysmon, vamos a proceder a registrarlo en el servidor. Para ello lo primero que tenemos que hacer es habilitar la ejecución de scripts de PowerShell. Para ello abrimos una consola de PowerShell con permisos de administrador.

Primero comprobamos si la ejecución de scripts esta habilitada con el comando

Get-ExecutionPolicy

Como podemos ver nos dice “Restricted”, por los que no está habilitado.

Por lo tanto, vamos a habilitarlo. Ejecutamos el comando:

Set-ExecutionPolicy Unrestricted

Y confirmamos con un “S”.

Volvemos a comprobar que la ejecución de scripts esta habilitada y vemos que si.

![](/assets/ewww/lazy/placeholder-300x257.png)

![](/assets/uploads/2020/01/habilitar-ejecución-_9-300x257.png)

Una vez tenemos habilitada la ejecución de script, nos vamos a la carpeta donde tenemos el archivo .ps1 que nos hemos descargado anteriormente y editamos el archivo con un editor, en este caso usamos Notepad++. Un vez dentro del editor cambiamos <Wazuh-Manager-IP> por la IP de nuestro servidor, que en nuestro caso es 192.168.1.124 , además debemos poner https en lugar de http y guardamos.

![](/assets/ewww/lazy/placeholder-300x66.png)

![](/assets/uploads/2020/01/config_10-300x66.png)

Ahora verificamos que nuestro agente se ha registrado correctamente en nuestro el servidor. Para ello vamos al navegador y escribimos la https://<IP de la maquina de PuffinSecurity>.

Nos vamos al menú que pone Puffin y en la pestaña de arriba seleccionamos Agentes y efectivamente podemos ver que ha sido registrado correctamente.

Ahora vamos a instalar el agente en Linux. Para ello nos lo bajamos del siguiente enlace.

https://drive.google.com/drive/folders/1HhTZJOXWiWrHu7UeucUDafw2OYmXWkX4?usp=sharing

A continuación, nos vamos a la carpeta donde hayamos guardado el instalador que nos hemos descargado anteriormente y los ejecutamos.

![](/assets/ewww/lazy/placeholder-300x210.png)

![](/assets/uploads/2020/01/installLinux-300x210.png)

Primero ejecutamos el instalador del agente, obtendremos una ventana en la que nos pondrá “instalar” e iniciaremos el proceso de instalación.

Después abrimos una terminal y ejecutamos el siguiente comando:

sudo -i

Este comando es para tener permisos de administrador.

Nos vamos a la dirección **/var/ossec/etc/** de la siguiente manera:

cd /var/ossec/etc/

Una vez estamos en esa carpeta abrimos el archivo denominado **ossec.conf** con el editor que prefiera, en este caso vamos a hacerlos con nano.

nano ossec.conf

Abrimos el archivo y cambiamos donde pone **MANGER\_IP** por la dirección de nuestro servidor. Guardamos y salimos.

![](/assets/ewww/lazy/placeholder-300x157.png)

![](/assets/uploads/2020/01/ossec-config-300x157.png)

 Ahora solo queda el último paso, el de registrarlo en el servidor.

Bien, ahora que ya tenemos instalado el agente y la API, vamos a proceder a registrarlo en el servidor. Lo primero que hacemos es editar el script que nos hemos descargado y cambiar la **API\_IP** por la IP de nuestro servidor. 

![](/assets/ewww/lazy/placeholder-300x155.png)

![](/assets/uploads/2020/01/config13-300x155.png)

A continuación, desde terminal, nos vamos a la carpeta donde tenemos el script y le damos permisos de ejecución con el comando:

chmod +x <script>

Una vez hecho esto, ejecutamos el script con permisos de administrador de la subiente manera:

sudo ./<script>

Una vez ejecutado debería aparecer algo parecido a la imagen siguiente y ya estaría registrado el agente.

![](/assets/ewww/lazy/placeholder-300x79.png)

![](/assets/uploads/2020/01/imag14-300x79.png)

Una vez finalizado este proceso, comenzaremos a trabajar con la segunda máquina que incluye la ova que hemos descargado.

Esta máquina incluye The hive y Cortex que tienen la siguiente funcionalidad:

**The hive**: Permite analizar los eventos recopilados e incluso automatizar operaciones a través de una API-REST, utilizaremos The hive para gestionar todas las alertas obtenidas de los agentes que instalamos anteriormente

**Cortex**: Incluye diversas herramientas de análisis. Además permite incluir nuevas herramientas pudiendo crear una Suite. Multitud de herramientas, analizadores y responders ya esta desarrollados por la comunidad por lo que ya tenemos mucho trabaja avanzado.

Se recomienda alojar Thehive-Cortex en una máquina con 8GB de RAM y 8 núcleos de procesamiento como mínimo.

Lo primero que debemos hacer una vez tengamos la máquina creada y nos hayamos autenticado correctamente es actualizar los analizadores.

**CONTRASEÑAS:**

ssh máquina:  thehive / puffinsecurity-thehive

Credenciales web The hive: admin / puffin-security

Credenciales web Cortex: thehive / puffinsecurity-cortex

Para ellos nos moveremos a la carpeta Cortex-Analyzers contenida en opt y realizaremos git pull.

*   cd/opt/Cortex-Analyzers
*   sudo git pull

**AÑADIR PLANTILLAS** 

Los analizadores mostraran sus resultados en función de unas plantillas pre-diseñadas que deberemos descargar si queremos visualizar los resultados.

Para ello las descargamos de GitHub:

https://github.com/TheHive-Project/Cortex-Analyzers/tree/master/thehive-templates

Vamos a TheHive, nos logeamos y en la pestaña Admin/Reports importamos las plantillas:

![](/assets/ewww/lazy/placeholder-300x93.png)

![](/assets/uploads/2020/01/1-300x93.jpg)

También podemos modificar las plantillas a nuestro gusto en código HTML

![](/assets/ewww/lazy/placeholder-300x213.png)

![](/assets/uploads/2020/01/2-300x213.jpg)

**INSTALAR ANALIZADORES**

Todos los analizadores incluidos, vienen pre-instalados, simplemente debemos de habilitarlos en la pestaña organizations/Analyzers dentro de Cortex  
Algunos analizadores necesitan de una configuración específica para que puedan funcionar, el propio analizador a la hora de habilitarlo solicitara la información que necesite.

![](/assets/ewww/lazy/placeholder-300x102.png)

![](/assets/uploads/2020/01/3-300x102.png)

Ejemplo de configurar un analizador:

![](/assets/ewww/lazy/placeholder-300x277.png)

![](/assets/uploads/2020/01/4-300x277.png)

**LANZAR ANALIZADORES DESDE THEHIVE**

Para lanzar los analizadores tendremos que ir a TheHive y crear un nuevo caso a partir de una alerta previamente registrada en Wazuh y comunicada con ElastAlert (VER DOCUMENTACIÓN DE ELASTALERT).  
Dentro del caso buscamos los observables que se hallan registrados (hash, ips , dominios etc), seleccionamos el observable que queramos analizar y pulsamos en Action->Run analyzers. Podremos seleccionarlos todos, uno , o el número que queramos.

![](/assets/ewww/lazy/placeholder-300x148.png)

![](/assets/uploads/2020/01/5-300x148.jpg)

![](/assets/ewww/lazy/placeholder-300x86.png)

![](/assets/uploads/2020/01/6-300x86.jpg)

**PLANTILLAS DE TAREAS**

TheHive es un sistema preparado para que multiples analistas convivan, por lo que tiene implementado la opción de crear plantillas de tareas de forma que cuando se habrá automáticamente un conjunto de tareas que cada analista puede ir asignándose.  
Ejemplo:  
Creamos una plantillas con 3 tareas analizar la ip, la url y el hash de un incidente, al utilizar esta plantilla se abre un registro de tareas pendientes:

![](/assets/ewww/lazy/placeholder-300x168.png)

![](/assets/uploads/2020/01/7-300x168.jpg)

![](/assets/ewww/lazy/placeholder-300x176.png)

![](/assets/uploads/2020/01/8-300x176.jpg)

![](/assets/ewww/lazy/placeholder-300x100.png)

![](/assets/uploads/2020/01/9-300x100.jpg)

**RESPONDERS**

Un responder es un “programa” que responde ante algo, es decir que un analista puede ejecutar en ciertas circunstancias para realizar una tarea.  
El ejemplo más claro y útil para nosotros son los correos electrónicos, un responder lo configuramos para que se envíen correos automáticamente después de realizar una acción.  
Un responder cuenta con 3 partes si se desarrolla en Python (lenguaje recomendado):

– Programa .py  
– Json  
– Python requirements (Dependencias que necesita nuestro programa)

El Json tiene que tener una estructura pre-establecida para que Cortex pueda reconocerlo.

Los responders por defecto van en : /opt/Cortex-Analyzers/Responders/.

Esta ruta es configurable y se establece en /etc/cortex/application.conf.

Si modificamos esta ruta, debemos de reiniciar la máquina para que los cambios se apliquen.

Ejemplo del JSON de un responder:

![](/assets/ewww/lazy/placeholder-300x245.png)

![](/assets/uploads/2020/01/10-300x245.jpg)

OJO!!: Todo responder va a asociado a un TLP y PAP, si la alerta tiene un  
TLP o PAP menor que el que el responder tiene asignado este no  
aparecerá. Si pones el TLP y PAP del responder en RED(Máximo) aparecerá  
siempre.

![](/assets/ewww/lazy/placeholder-300x14.png)

![](/assets/uploads/2020/01/11-300x14.png)

La configuración de los responders dentro de Cortex se realiza en Organization-> Responders y Organization-> Responders Config.  
OJO: Organization-> Responders tiene una mayor jerarquía que Responders Config por lo que si cambiamos el Config pero el Responders no se modifica, los cambios no se aplicaran.

![](/assets/ewww/lazy/placeholder-300x60.png)

![](/assets/uploads/2020/01/12-300x60.png)

![](/assets/ewww/lazy/placeholder-300x240.png)

![](/assets/uploads/2020/01/13-300x240.png)

Si creamos un Mailer, para enviar correos a través de google, tendremos que tener habilitado dentro de la cuenta de google que envía el uso de aplicaciones poco seguras.

Cuando un responder se ejecuta correctamente o falla podremos verlo tanto en TheHive como en Cortex, salvando las distancias ya que Cortex muestra más información sobre todo si falla:

![](/assets/ewww/lazy/placeholder-300x62.png)

![](/assets/uploads/2020/01/14-300x62.png)

**EJEMPLO DE RESPONDER: MAILER**

![](/assets/ewww/lazy/placeholder-300x23.png)

![](/assets/uploads/2020/01/15-300x23.png)

Esta es la carpeta donde están nuestros Mailers, tenemos 3, AccionRequerida,  
IncidenteSolventado y InformarCLiente.

Un analista lo vería en thehive así:

![](/assets/ewww/lazy/placeholder-300x147.png)

![](/assets/uploads/2020/01/16-300x147.png)

Esta pinta tiene en Cortex:

![](/assets/ewww/lazy/placeholder-300x81.png)

![](/assets/uploads/2020/01/17-300x81.png)

Este es el codigo del mailer InformearIncidente

JSON:

![](/assets/ewww/lazy/placeholder-243x300.png)

![](/assets/uploads/2020/01/18-243x300.png)

Es importante que el nombre del responder sea el mismo que el de la carpeta que lo contiene.

El dateTypeList, muestra en que momentos se puede utilizar el responder.

.py

![](/assets/ewww/lazy/placeholder-300x211.png)

![](/assets/uploads/2020/01/19-300x211.png)