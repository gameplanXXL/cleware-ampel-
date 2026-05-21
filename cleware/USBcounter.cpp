// USBcounter [-d]
// -d = debug
// -f = function call, just return the current value
// -r = reset counter
//
/* Copyright (C) 2001-2022 Copyright Cleware GmbH, Wilfried Söker
 
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 
*/

#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>
#include "USBaccess.h"

int 
main(int argc, char* argv[]) {
	CUSBaccess CWusb ;
	char *progname = *argv++ ;
	int debug = 0 ;
	int function = 0 ;
	int resetCounter = 0 ;
	int devID ;

	while (--argc >= 1 && *argv[0] == '-') {
		switch (argv[0][1] | 0x20) {
			case 'd':
				debug = 1 ;
				break ;
			case 'r':
				resetCounter = 1 ;
				break ;
			case 'f':
				function = 1 ;
				break ;
			}
		argc-- ;
		argv++ ;
		}

	int USBcount = CWusb.OpenCleware() ;

	if (debug)
		printf("OpenCleware found %d devices\n", USBcount) ;

	for (devID=0 ; devID < USBcount ; devID++) {
		int type = CWusb.GetUSBType(devID) ;
		int version = CWusb.GetVersion(devID) ;
		if (type == CUSBaccess::CONTACT00_DEVICE && version == 4)
			break ;
		if (type == CUSBaccess::COUNTER00_DEVICE)
			break ;
		}

	if (devID >= USBcount)
		printf("No appropriate device found\n") ;
	else {
		if (function == 0) {
			int count = -1 ;
			if (resetCounter)
				CWusb.SetCounter(devID, 0, CUSBaccess::COUNTER_0) ;
			while (1) {	
				int newCnt = CWusb.GetCounter(devID, CUSBaccess::COUNTER_0) ;
				if (newCnt != count) {
					printf("%d\n", newCnt) ;
					count = newCnt ;
					usleep(500000) ;		// wait 0.5 seconds
					}
				}
			}
		else {
			int newCnt = CWusb.GetCounter(devID, CUSBaccess::COUNTER_0) ;
			printf("%d", newCnt) ;
			}
		}

	CWusb.CloseCleware() ;

	return 0;
	}

