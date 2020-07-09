---
layout: blog-detail
comments: true
title: "The key to everything: Firmware on IoT devices"
date: 2019-02-25T07:50:41+00:00
categories:
    - Cyber security
    - IoT
tags:
    - dispositivos IoT
image_src: /assets/uploads/2019/02/La-llave-de-todo-el-Firmware-de-dispositivos-IoT.jpg
image_height: 1280
image_width: 1920
author: Ignacio Crespo Martínez
description: In this article we will enter the IoT world, focusing on the firmware of IoT devices. When we look from a perspective of security, it is the most critical component of any device. Almost any device that can come across to us execute a firmware....
publish_time: 2019-02-25T07:50:41+00:00
modified_time: 2019-10-09T12:04:18+00:00
comments_value: 0
---
In this article we will enter the [IoT world](/cybersecurity-audit-assesment/internet-of-things/), focusing on the **firmware of IoT devices**. When we look from a perspective of security, it is the most critical component of any device. Almost any device that can come across to us execute a firmware.

Even someone who does not have much experience in handling electronics or did not work with firmware, surely remembers when he skipped a firmware update from your smartphone or your Smart TV to **download the new version**.

A famous case of firmware security is the time when Mirai **botnet** emerged. This botnet infected devices accessing them through the use of **default credentials**. This makes us think of a question, how can we keep safe the IoT devices against Mirai or we can do so that they are not vulnerable?

One solution might be to go manually checking each logon credentials of the various services that are running. But that would be a very tedious process, as well as not really scalable, right?

This is where the security firmware “skills” must take action, and we cannot do this process for each of the millions of IoT devices that exist today.

**But then…**

### **What is an IoT device firmware?**

The firmware is a piece of code that resides in a non-volatile part of the device that allows and enables the device to perform the functions for which it was created. It consists of several components, such as the kernel, bootloader, filesystem and additional resources. In addition, the firmware makes various hardware components work properly.

Knowing which different components are, let’s explain a little.

1.  1.  **Bootloader**: It is responsible for numerous tasks such as the initialization of several critical hardware components and allocating the necessary resources.
    2.  **Kernel**: It is one of the main components of the entire integrated device. Speaking at a very general level, a kernel is simply an intermediate layer between the hardware and software.
    3.  **File System**: Is where all the individual files required for performance of the device are stored. This also includes components such as web servers and network services.

### **How is the process of starting an IoT device?**

1.  1.  The bootloader initiates the necessary hardware and system startup.
    2.  The bootloader is passed to the physical address of the kernel and the load device tree.
    3.  The kernel is loaded from the previous address, and then starts all processes required and additional services for the device to work.
    4.  Bootloader dies as soon as the kernel is loaded.
    5.  The root file system is mounted.
    6.  As soon as the root filesystem is mounted, a kernel generates a program called in it.

This also means that if we have access to the **bootloader** or if we can load our custom bootloader to the target device, we can control the entire operation of the device – making the device even use a **modified kernel** instead of the original. One case of major use to extract the firmware file system is to seek confidential values ​​within the firmware. From the point of view of a security researcher, this is what you should look in the file system:

1.  1.  Encrypted credentials
    2.  Sensitive URLs.
    3.  Access Logs
    4.  API and encryption keys.
    5.  Encryption algorithms.
    6.  Local access routes.
    7.  Environment details.
    8.  Authentication and authorization mechanisms.

### **How can we analyze the firmware?**

As we saw earlier, the firmware contains several sections embedded within it.

Therefore, the first step to analyze a firmware and get a deeper view of it, is to identify the different sections that work together to make a full firmware. The firmware is no longer a binary piece of data, which when opened with a hexadecimal editor, the different sections containing the binary, identified by observing the signature bytes of each section individually disclosed.

#### Firmware file types IoT

Before starting to analyze a real firmware, we must first understand what things are going to expect to see when we start our analysis of the firmware. The component in which we will focus in this article is the file system. The file system of an IoT device can be of different types, depending on the manufacturer’s requirements and the function that the device is intended.

Each type of file system has its own unique signature header, then we use it to identify the location of the file system beginning in the binary firmware.

The most **common file systems** that usually found in the **IoT devices** are as follows:

*   *   squashfs
    *   cramfs
    *   JFFS2
    *   yaffs2
    *   ext2

In addition to different file systems there, there are also different types of compression are used. By using **compression file system** we save storage space on the IoT device, which is very valuable when it comes to this type of device. The most common compression we usually find in IoT devices are listed below:

1.  1.  LZMA
    2.  gzip
    3.  Zip
    4.  zlib
    5.  ARJ

#### How to get hold of the firmware of a device IoT?

Depending on what file system and type of compression used in the device to analyze a set of different tools they will be used. Now, before **removing the firmware of a device** and delve into it, we must understand what the various ways in which we can access the firmware of a device IoT are.

The first thing to learn to perform a firmware analysis, is **how to get hold of the device firmware**. This depends on the device which we want to achieve.

The first way, the easiest and most common to get the device firmware is look on the Internet. Many manufacturers decide to put the firmware binary file that can be downloaded, either section of the device support or either in the download section. It is also very common to find the firmware in different discussion forums. For instance, on the website of TP-Link, if we look for any of the devices that the brand offers on the market, there is high probability that we find a link to download the firmware of the device.

The second way to get the firmware is an approach where we need physical access to the device. Thus, we must use different hardware exploitation techniques to dump the firmware of the device memory. Depending on the device, the level of protection can vary and the same must use other techniques to exploit hardware for binary firmware. Sometimes find that you can get the binary simply pouring it through a UART connection, in some cases you might have to use JTAG or in other cases we have to dump it from the flash chip.

The third way to get the firmware is by “**sniffing OTA**“, ie get binary while the device performs a firmware update. In this process we set up the interceptor network for the device, so that when the device requests to download the new firmware image, remove it from the network capture we have done. Clearly, this technique can have complications such as in the event that the file is downloading firmware is not complete, but a small update package, or we do not have configured the proxy continuously to intercept traffic.

The last technique to obtain the binary firmware is to **reverse an application**. This method implies that we analyze the Web and mobile applications of an IoT device, and from there, find a way to get the firmware.

Once you have the firmware binary, one of the most important things we can do it is extracting the file system image binary.

To do this, we use the Binwalk tool that allows us to automate the process of extracting the file system of a binary firmware. What it does is compare the signature that is present in the binary firmware that are stored in its database and identified through this process what are the different sections that are present in the binary.

The first thing to do is configure the tool. We’re going to do in an instance of Ubuntu. To do this we download and configure the tool:

git clone https://github.com/ReFirmLabs/binwalk.git  
binwalk cd /  
sudo python setup.py install

Once we installed Binwallk, it’s time to download a new firmware. In this case we will use Damn Vulnerable Router Firmware. We then downloaded:

wget –no-check-certificate https://github.com/praetorian-inc/DVRF/blob/master/Firmware/DVRF\_v03.bin?raw=true

Once we have downloaded the firmware, we will use **Binwalk** and see the different sections that are present in the binary.

binwalk -t DVRF.bin

\-t tells BinWalk to format the output text in a nice format.

Once executed the command, this should return us the following:

![Binwalk screenshot -t](/assets/ewww/lazy/placeholder-1048x239.png)

![Binwalk screenshot -t](/assets/uploads/2019/02/binwalk.jpg)

As we can see, the tool tells us that there are 4 sections in binary.

1.  1.  BIN-Header
    2.  firmware header
    3.  gzip compressed data
    4.  squashfs filesystem

Now let’s check if the binary is encrypted or is only compressed. We carry out an analysis of the binary entropy. To do this run:

binwalk -E DVRF.bin

We will return a graph like this.

![Entropia del binario](/assets/ewww/lazy/placeholder-611x458.png)

![Entropia del binario](/assets/uploads/2019/02/entropia-del-binario.png)

As we can see, the graph shows a line with some minor variations which indicates that the data is only compressed and not encrypted.

If we had shown a completely flat line, it indicates that the data is encrypted. So, we know that the firmware image has no encrypted data.

Then once we know this, we will extract the file system firmware image. We will use:

binwalk -e DVRF.bin

Although the output appears to us as above but less nice, in this case, has also generated a new directory containing the extracted file system. The directory is named **binwalk** generated with firmware name, add an underscore (\_) at first and puts the extension ‘.extracted’.

![Binwalk -e](/assets/ewww/lazy/placeholder-1058x226.png)

![Binwalk -e](/assets/uploads/2019/02/binwalk-e.jpg)

Entering the directory will find:

1.  1.  squashfs
    2.  piggy
    3.  squashfs-root

If we go into the **squash-root folder**, we found all the file system firmware image, as you can see.

![IoT firmware files](/assets/ewww/lazy/placeholder-604x325.png)

![IoT firmware files](/assets/uploads/2019/02/IoT-firmware-files.png.jpg)

As we have seen, using **Binwalk** makes it extremely easy to extract the file system of a binary firmware.

In the next article we will see how to analyze the firmware.