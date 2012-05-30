---------------------------------------------
DaisyWorks Desktop App
---------------------------------------------

##License
This software is made available under the GNU LGPL (v3.0).  A copy of this license is
provided in the root directory of this project as LICENSE.txt or you may view an
online version at http://www.gnu.org/licenses/gpl-3.0.html

##Introduction
--------------------------------------------
The [DaisyWorks Desktop App](http://daisyworks.com/downloads.html) is a GUI desktop application for managing / interacting
with the [Daisy Bluetooth 1T](http://daisyworks.com/products.html).  The application is built using
Adobe Air and Java.  Air represents the bulk of the application and the user interface.
Java is used because there is no way to talk to Bluetooth through the Air SDK.

Air communicates via Java through Object Remoting / AMF which is a binary over-the-wire
protocol for remote services.

http://opensource.adobe.com/wiki/display/blazeds/BlazeDS

On the Java side, we instantiate our own embedded Jetty server and programatically
configure the WAR.  

http://jetty.codehaus.org/jetty/

We use Spring-Flex (with its BlazeDS support) to expose services from the War.

http://www.springsource.org/spring-flex

This architecture allows cross-platform support for Windows, Mac, and Linux, since
both Air and Java can all run fine on these three platforms (today...)

To make the installation and user experience easier, we embed the JRE inside the 
installer for Windows and Linux.  This avoids having the user download and install
Java themselves, and avoids most runtime errors caused by not finding the Java
executable, or having a corrupt Java installation.  It also ensures we have fully
tested with the JRE we ship.

For Mac OS, there is no re-distributable JRE.  The OS (through 10.6.x) ships with
Java.  This may change in the future, and we'll have to re-evaluate but for now,
we expect it to be there, and the application will find it and use it at runtime.

++Build Pre-requisites
--------------------------------------------

Adobe Build tools allow you to create a native application installer for each platform,
which is nice.  What is not so nice is that you must actually *build on that platform*
to get each respective installer file.  Thus, to build a Windows setup.exe, you have to
build on Windows, etc.

 * Sun/Oracle JDK - install and use the Sun/Oracle JDK; The Ant build scripts use the
`<os>` tag and this supposedly requires tools.jar which is not present in OpenJDK.

 * Ant (using 1.7 or later) - I would just use all Maven, but the flex-mojos/maven support
for the Air stuff (e.g. native installers) is poorly supported, as well as FlashBuilder
project support.  So, the top-level stuff is all Ant, and the Air application is Ant, while
the Java server side is maven (just cuz' it is easier).

 * Maven (using 2.2.x or later) 

 * Flex SDK - You have to download and install the latest Flex SDK, unzip it somewhere:

You can download the Flex SDK here:

http://opensource.adobe.com/wiki/display/flexsdk/Download+Flex+4.5

```
$ mkdir -p /home/me/flex-sdks/flex_sdk_4.5.0.20967/
$ unzip flex_sdk_4.5.0.20967.zip -d /home/me/flex-sdks/flex_sdk_4.5.0.20967
```

As of this writing, we are using 4.5.0.20967 Adobe Flex SDK -- not the Open Source Flex SDK.

 * Air 2.6 SDK - You must have 2.6 or later to be able to build.

You can download the Air 2.6 SDK here:

http://www.adobe.com/products/air/sdk/

For Linux, you can't go above 2.6 since Adobe stopped supporting it...bastards.

http://airdownload.adobe.com/air/lin/download/2.6/AdobeAIRSDK.tbz2

Now, unzip it into the same directory as the Flex SDK
```
$ unzip AdobeAirSDK.zip -d /home/me/flex-sdks/flex_sdk_4.5.0.20967
```
!!! IMPORTANT !!! It *must* unzip / overlay directly on top of it -- it has a similar directory
structure.  If you get the path wrong, it won't work.  

##How To Build
--------------------------------------------

```
$ cp build.properties.sample build.properties
$ vi build.properties
$ ant
```

##TODO
--------------------------------------------

The JRE that we include for Windows / Linux is the full enchilada.  We should trim it back to the 
absolute bare binary essentials for runtime.  It blows up the size of the installer mega-fold.

Also need to fix the Linux JRE bundle because the uid/gid get blown away and the main executable
can no longer be launched.  Also, if you try to run the .deb installer it has a whole bunch of
warnings and says the package is of poor quality (mainly b/c of these uid/gid issues).


###BLUETOOTH
--------------------------------------------

Bluetooth is a fickle animal with lots of different hardware and software stack implementations
on different operating systems and architectures.  This section provides some brief documentation
on what we've tested the application on and what steps were necessary to make it work (if any)

The implementation relies on the open source Java Bluecove libraries.  Here are some relative links.

* http://bluecove.org
* http://code.google.com/p/bluecove
* http://snapshot.bluecove.org/


####Windows 7 on AMD64
-------------------
Should work out of the box

Tested with SMC BT10 USB/Bluetooth Adapter: http://www.smc.com/index.cfm?event=viewProduct&cid=5&scid=103&localeCode=EN_USA&pid=1370

####Ubuntu 11.04 on i5 x86_64 and AMD64
-------------------
On 64-bit Ubuntu you will need to install the native libs for Bluetooth dev.  I'm not sure if we 
could really bundle these.  They should be installed by the user as an extra step, unfortunately
to better ensure it will work.  This command should do it:

```
sudo apt-get install libbluetooth-dev
```
Tested with Targus ACB10US1 USB/Bluetooth Adapter: http://www.targus.com/us/productdetail.aspx?sku=ACB10US1

####Mac OS X 10.6 i7 x86_64
-------------------
Should work out of the box; tested with built-in bluetooth for Mac Book Pro


#####DEPRECATED
----------------------------------------------

This was old advice related to Linux builds.  If you download the Flex SDK and the latest Air SDK and unzip 
them as per the instructions below, this shouldn't be necessary..so ignore it.  It is here for 
historical purposes.

!!! IMPORTANT !!! If you are going to build on Linux, it can be a little trickier.  I went
through a lot of headache to get this to work properly.  I posted to the Adobe Forums
here:

http://forums.adobe.com/message/3354091#3354091

Just downloading the Flex 4 SDK and running ant doesn't work.  I would get an error.  So, do 
this stuff instead:

Download this Flex 4 SDK =>

http://fpdownload.adobe.com/pub/flex/sdk/builds/flex4/flex_sdk_4.1.0.16076.zip

Unzip it somewhere, e.g. /home/<you>/flex-sdk/flex_sdk_4.1.0.16076

Download this Air 2 SDK =>

http://airdownload.adobe.com/air/lin/download/latest/AdobeAIRSDK.tbz2

Unzip it on top of the same directory, e.g. /home/<you>/flex-sdk/flex_sdk_4.1.0.16076

Now, when you build in Linux, the Ant build script *should* work.  It does for me on 
Ubuntu 11.04 Desktop AMD64, with 64-bit Sun JDK.

