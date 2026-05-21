# use standard libraries. if libhid is requested, use MakefileLibhid

USBACCESSFILES = USBaccessBasic.o USBaccess.o
USBACCESSHEADER = USBaccessDevTypes.h USBaccess.h USBaccessBasic.h

all: Example USBswitchCmd ListDevTypes USBio16 send2cc USBtemp USBadc USBcounter USBcontact

USBaccess.a: $(USBACCESSFILES) $(USBACCESSHEADER)
	gcc -g -DCLEWARELINUX -Wall -fPIC -c USBaccessBasic.c $(CFLAGS) -o USBaccessBasic.o
	g++ -g -DCLEWARELINUX -Wall -fPIC -c USBaccess.cpp $(CFLAGS) -o USBaccess.o
	gcc USBaccessBasic.o USBaccess.o -shared -o USBaccess.so
	ld $(USBACCESSFILES)  $(LDFLAGS) -Ur -o USBaccess.obj
	ar rc USBaccess.a USBaccess.obj

Example:  Example.cpp $(USBACCESSFILES) $(USBACCESSHEADER)
	gcc -g -DCLEWARELINUX -c USBaccessBasic.c $(CFLAGS) -o USBaccessBasic.o
	g++ -g -DCLEWARELINUX -c USBaccess.cpp $(CFLAGS) -o USBaccess.o
	g++ -g -DCLEWARELINUX -c Example.cpp $(CFLAGS) -o Example.o
	g++ -g $(USBACCESSFILES)  Example.o -o Example

USBswitchCmd:  USBswitchCmd.cpp $(USBACCESSFILES) $(USBACCESSHEADER)
	gcc -g -DCLEWARELINUX -c USBaccessBasic.c -o USBaccessBasic.o
	g++ -g -DCLEWARELINUX -c USBaccess.cpp -o USBaccess.o
	g++ -g -DCLEWARELINUX -c USBswitchCmd.cpp -o USBswitchCmd.o
	g++ -g $(USBACCESSFILES)  $(LDFLAGS) USBswitchCmd.o -o USBswitchCmd

USBcounter:  USBcounter.cpp $(USBACCESSFILES) $(USBACCESSHEADER)
	gcc -g -DCLEWARELINUX -c USBaccessBasic.c -o USBaccessBasic.o
	g++ -g -DCLEWARELINUX -c USBaccess.cpp -o USBaccess.o
	g++ -g -DCLEWARELINUX -c USBcounter.cpp -o USBcounter.o
	g++ -g $(USBACCESSFILES)  $(LDFLAGS) USBcounter.o -o USBcounter
	
USBio16: USBio16.cpp $(USBACCESSFILES) $(USBACCESSHEADER)
	gcc -g -DCLEWARELINUX -c USBaccessBasic.c -o USBaccessBasic.o
	g++ -g -DCLEWARELINUX -c USBaccess.cpp -o USBaccess.o
	g++ -g -DCLEWARELINUX -c USBio16.cpp -o USBio16.o
	g++ -g $(USBACCESSFILES) USBio16.o -o USBio16
	
USBcontact: USBcontact.cpp $(USBACCESSFILES) $(USBACCESSHEADER)
	gcc -g -DCLEWARELINUX -c USBaccessBasic.c -o USBaccessBasic.o
	g++ -g -DCLEWARELINUX -c USBaccess.cpp -o USBaccess.o
	g++ -g -DCLEWARELINUX -c USBcontact.cpp -o USBcontact.o
	g++ -g $(USBACCESSFILES) USBcontact.o -o USBcontact
	
USBbuttonTime: USBbuttonTime.cpp $(USBACCESSFILES) $(USBACCESSHEADER)
	gcc -g -DCLEWARELINUX -c USBaccessBasic.c -o USBaccessBasic.o
	g++ -g -DCLEWARELINUX -c USBaccess.cpp -o USBaccess.o
	g++ -g -DCLEWARELINUX -c USBbuttonTime.cpp -o USBbuttonTime.o
	g++ -g $(USBACCESSFILES) USBbuttonTime.o -o USBbuttonTime
	
USBadc: USBadc.cpp $(USBACCESSFILES) $(USBACCESSHEADER)
	gcc -g -DCLEWARELINUX -c USBaccessBasic.c -o USBaccessBasic.o
	g++ -g -DCLEWARELINUX -c USBaccess.cpp -o USBaccess.o
	g++ -g -DCLEWARELINUX -c USBadc.cpp -o USBadc.o
	g++ -g $(USBACCESSFILES) USBadc.o -o USBadc
	
USBtemp: USBtemp.cpp $(USBACCESSFILES) $(USBACCESSHEADER)
	gcc -g -DCLEWARELINUX -c USBaccessBasic.c -o USBaccessBasic.o
	g++ -g -DCLEWARELINUX -c USBaccess.cpp -o USBaccess.o
	g++ -g -DCLEWARELINUX -c USBtemp.cpp -o USBtemp.o
	g++ -g $(USBACCESSFILES) USBtemp.o -o USBtemp
		
send2cc: send2cc.cpp cwLoop.cpp send2cc.h $(USBACCESSFILES) $(USBACCESSHEADER)
	gcc -g -DCLEWARELINUX -c USBaccessBasic.c -o USBaccessBasic.o
	g++ -g -DCLEWARELINUX -c USBaccess.cpp -o USBaccess.o
	g++ -g -DCLEWARELINUX -c cwLoop.cpp -o cwLoop.o
	g++ -g -DCLEWARELINUX -c send2cc.cpp -o send2cc.o
	g++ -g $(USBACCESSFILES) send2cc.o cwLoop.o -o send2cc

ListDevTypes:  ListDevTypes.cpp $(USBACCESSFILES) $(USBACCESSHEADER)
	gcc -g -DCLEWARELINUX -c USBaccessBasic.c $(CFLAGS) -o USBaccessBasic.o
	g++ -g -DCLEWARELINUX -c USBaccess.cpp $(CFLAGS) -o USBaccess.o
	g++ -g -DCLEWARELINUX -c ListDevTypes.cpp $(CFLAGS) -o ListDevTypes.o
	g++ -g $(USBACCESSFILES)  ListDevTypes.o $(LDFLAGS) -o ListDevTypes


