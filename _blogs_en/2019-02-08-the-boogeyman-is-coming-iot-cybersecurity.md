---
layout: blog-detail
comments: true
title: "The Boogeyman is coming: IoT cybersecurity"
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
image_src: /assets/uploads/2019/02/Puffin-security-blog-adrian-campazas-que-viene-el-coco-proteccion-y-ciberseguridad-en-iot-internet-of-things.jpg
image_height: 1280
image_width: 1920
author: Adrián Campazas
description: En este primer artículo que escribo quiero hablar del Coco de la ciberseguridad de los últimos tiempos que no es otro que el IOT (Internet of Things)
publish_time: 2019-02-08T09:20:30+00:00
modified_time: 2019-11-13T08:26:12+00:00
comments_value: 0
disqus_identifier: 1596
---
I could dedicate this article to interpret a painting signed by Francisco de Goya, but I am not an art expert, or you wouldn’t have visited this blog for that. In this first article I write I speak of cybersecurity in recent times, which is none other than cybersecurity **IoT (Internet of Things)**.

### **Why do so many IoT cybersecurity problems?**

The first reason is the lack of awareness by the manufacturers. They are unaware of the **vulnerabilities** that may exist in an IoT ecosystem and the complexity level of security that this ecosystem means. Another reason that is extremely common in the developing world and hopefully seems to be starting to reverse is that security does not give money. This statement is true, making sure your product does not give money, but can prevent lose everything. Unfortunately, the second part of the sentence is true only when we realize major security incidents occur. Hello!!!! **Wannacry**.

The second main reason is the lack of trained and specialized security profiles in this type of devices.

According to Gartner in 2020 there will be over 20 trillion **connected devices**. It a little scary, right?

#### Is IoT very critical?

It depends. We will take as a reference a bulb connected to an attacker makes a **denial-of-service attack**. Ehe attack result is that the bulb is off. Is it critical? For unless you suffer from scopophobia, it does not seem very serious. Now let’s take quite another reference that you think a pacemaker, what you already are beginning to give a little more fear to the result?

You could say “who would want to **hack** a pacemaker?” Okay, I’ll buy it, say a more everyday example, that you look like to watch babies, common in such devices is that an attacker is able to see and steal the images the device records. I will say, well, is not that great. It depends, if those pictures of your son/daughter end up in a child pornography ring, maybe it is.

This type of malicious actions can classify them as snapshots, which occurs when for example a manufacturer of intelligent speakers has not put emphasis on safety and your device has been compromised and used to attack massively to third-party platforms. Because the result is a **denial of service** to a reputable platform and a scandal in the press that shatters the image that had gained during many years of effort.

These are just some examples of what can happen if manufacturers do not put special emphasis on the **safety of their devices**.

In conclusion to this section, is safety critical? the answer is absolutely yes, companies must invest in safer designs, and conduct audits to their products to evaluate the safety of them.

Now that I’ve gotten a little fear in your body, we will see pieces make up the IoT ecosystem, which are the main vulnerabilities and how we can design an attack vector when performing an audit of these devices.

#### IoT ecosystem

When an attacker tries to establish potential vectors of attacks against a web application or a mobile app you will find the vector is the application itself and this establishes communications. When an attack against an **IoT attack surface** environment is much more extensive.

An **IoT** environment usually consists at least of the following components

*   Hardware
*   Web application to which the device is connected and often store the same information.
*   Mobile applications usually used to control the device.
*   Firmware
*   Communications

Such a complex environment implies that a vulnerability in any of these components can ruin the security of the entire device.

In addition to the components, each IoT device uses different protocols for the same task which greatly increases the fragmentation of the ecosystem and therefore makes it difficult for safety analysis.

In the next picture we can see some of the many protocols used in the IoT ecosystem:

![Tipos de protocolos usados en el ecosistema de IoT Internet of Things por Tara Salman](/assets/ewww/lazy/placeholder-802x372.png)

![Tipos de protocolos usados en el ecosistema de IoT Internet of Things por Tara Salman](/assets/uploads/2019/02/Tipos-de-protocolos-usados-en-el-ecosistema-de-IoT-Internet-of-Things-por-Tara-Salman.png)

### **Where do I start if I want to perform a security audit to an IoT device?**

When performing a security audit on a device IoT is essential to know what we’re facing. What components are involved in the device?, What tools need to use?

It is important to spend time to know what the attack surface will be. As we have seen, each device is different, and we know what we have in hand.

Technical issues aside, it is important to identify what is really critical in the device, such as an IP camera, the most critical thing that can happen is that an attacker is able to view images of what is being recorded. However, in a connected refrigerator that has an internal chamber, perhaps most critically will not see the images of this camera, if not an attacker can steal bank details the refrigerator stores to place orders automatically.

This also occurs in other types of audits, referring to a web audit even above SQL injection that allows steal data, the most critical for a bank is that an attacker is able to create money. This perhaps less technical approach is sometimes overlooked and from my point of view is a serious error by the auditor.

Now that we have more or less clear which are the parts that make up an IoT ecosystem, let’s go to analyze each way.

#### Hardware

An IoT device can be used for a multitude of tasks. When performing a test **device security**, the approach must be the same regardless of the device so far as hardware is concerned is used.

The most typical vulnerabilities that can be found in an embedded device are:

*   Exposed Ports exposed.
*   Insecure authentication mechanism ports that are exposed
*   Dumpee firmware enabled via JTAG or faking chips
*   Attacks based on external media

#### Firmware, Software and Applications

After the analysis of the following hardware component that must analyze is the software, firmware and applications that control the device both web and at the level of mobile devices.

At this point, traditional techniques are applied in [pentesting](/). We are talking about reverse engineering (reversing) both binaries that make up the system, normally developed architectures MIPS or ARM as are the architectures most commonly used in IoT devices such as mobile application that can get to reveal many secrets and vulnerabilities.

Let’s start by **mobile applications**. They are as a rule responsible for controlling smart devices, the two platforms prevailing in this market are Android and IOS.

Daily multitude of attacks on mobile applications that expose sensitive information of the device, the operation of the user or uses are made.

Mobile devices are a common entry point to the backend web applications and databases that are behind. Is a common mistake of many companies perform security audits of their Web applications and ignore mobile devices working on the same backend and can put all security at risk.

In future articles we will try different techniques and vulnerabilities found on mobile devices and of course can endanger the safety of the entire ecosystem of an IoT device at risk.

**Web control panel**: It allows the user to monitor the device, analyze information and manage the device as far as concerned security permits. If the web application is vulnerable, an attacker could access information without authorization – as well as accessing information from other users, etc.

**Insecure network interfaces**: This section refers to the revision of the ports that a device may have open. There are often seen as misconfigured ports that do not require authentication or hide vulnerable and outdated protocols. Many devices use vulnerable versions of SNMP or FTP.

**Firmware**: The firmware is the jewel in the crown of any IoT device and which holds the keys of the kingdom. Almost anything can be extracted from the firmware. I will continue to deepen on this in future articles to deal with different vulnerabilities and techniques which are used to discover important information within the firmware.

##### In short, these are the main vulnerabilities that can be found in different parts of this section:

**FIRMWARE MODIFICATION  
**Possibly the most dangerous things you can do, if we are able to modify the firmware could enable a ssh service or launch a shell. Such vulnerabilities are caused due to unsafe signatures or not integrity check.

**INFORMATION THEFT  
**It is concerned about the large number of hardcore encryption keys in the firmware of the devices that today we can still find. Anyone with a minimal knowledge in reversing might discover those keys easily. In addition, within the firmware we can find private keys, passwords URLs etc.

In addition to the vulnerabilities already mentioned, is also concern that an attacker can extract the file system device

**Mobile apps**:

*   Dumpee source code,
*   insecure authentication
*   Runtime attacks
*   Using third-party libraries or SDK vulnerable.

**Web applications**:

*   Injections client side.
*   insecure authentication
*   Theft of sensitive information
*   XSS
*   Cross Site Request Forgery

These are some of the vulnerabilities that can be found in the firmware or applications that use the IoT devices. Unfortunately, I have only named a few as there are many more. We must be aware that an IoT device using an app developed for Android, for example, inherits all possible vulnerabilities that can undergo an application on this platform. The same goes for a web application or IOS app.

### Communications: Apps and mobile devices

Development companies of IoT devices do not usually pay close attention to such communications. The protocols used in IoT devices are generally the following: 4G / WIFI, Bluetooth Low Energy (BLE) ZigBee, Wave, 6LoWPAN and LORA, among others. To audit these communications in some cases we need to use special hardware.

The three categories are often exploited are:

*   Software Defined Radio (SDR)
*   ZigBee exploitation
*   BLE (Bluetooth Low Energy) Explotation.

The most common vulnerabilities that can be found in radio communications are:

*   Man In The Middle
*   ReplayBased attacks
*   Insecure CRC verification
*   Jamming based attacks
*   TWO
*   Lack of encryption
*   Life Comunication Packet Interception and modification.

#### Nostalgia time

##### Take home an automation device or Smart Home

Perhaps the simplest example of intelligent connected device is a light switch.

This is the outline of a traditional key:

![El funcionamiento de IoT es similar a como funciona una llave de luz](/assets/ewww/lazy/placeholder-516x438.png)

![El funcionamiento de IoT es similar a como funciona una llave de luz](/assets/uploads/2019/02/ciberseguridad-internet-of-things-iluminacion-como-funciona-una-llave-de-luz.jpg)

As we can see the attack vector of this device is likely to be a power surge or short circuit.

This is the smart key scheme developed by Sonoff and is priced at about 15 euros.

![IOT system smart home devices wifi mobile APP](/assets/ewww/lazy/placeholder-666x360.png)

![IOT system smart home devices wifi mobile APP](/assets/uploads/2019/02/IOT-system-smart-home-devices-wifi-mobile-APP.jpg)

As we can see different elements come into play that can be possible attack vectors to begin communications. We can see both mobile applications available for both Android and IOS within the cloud. Our own mobile applications, hardware device, the firmware is that gives life to the system and its communications with the cloud through the local router. And all this for a simple light switch.

The example is very simple but as we see the degree of complexity in a simple connected light switch is high when compared to the traditional key.

This new ecosystem highlights the need for manufacturers to develop their products thinking of the safety of them and besides that perform tests and check the condition of the product before it can come the bogeyman to visit us.