/* USBcontact [-n device] [-d]
 *           -n device   use device with this serial number
 *           -d          print debug infos
 *           -v          print version
 *           -h          print command usage
 *
/* Copyright (C) 2023 Copyright Cleware GmbH, Wilfried Söker
 
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
 *
 * Version     Date     Comment
 *   1.0    27.06.2023	Initial coding
 *
 */

#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>
#include "USBaccess.h"

int 
main(int argc, char* argv[]) {
	CUSBaccess CWusb ;
	int debug = 0 ;
	int state = -1 ;		// 0=off, 1=on
	int printVersion = 0 ;
	int printHelp = 0 ;
	int serialNumber = -1 ;
	char *progName = *argv ;
	int ok = 1 ;
#	define versionString "1.0"

	for (argc--, argv++ ; argc > 0 && ok ; argc--, argv++) {
		if (argv[0][0] == '-') {
			switch (argv[0][1]) {
				case 'd':
				case 'D':
					debug = 1 ;
					break ;
				case 'v':
				case 'V':
					printVersion = 1 ;
					break ;
				case 'h':
				case 'H':
					printHelp = 1 ;
					break ;
				case 'n':
				case 'N':
					if (argc == 1) {
						printf("missing serial number %s\n", *argv) ;
						ok = 0 ;
						break ;
						}
					printf("serial number ignored - will be implemented later\n") ;
					argc-- ;
					argv++ ;
					break ;
				default:
					printf("illegal argument %s\n", *argv) ;
					ok = 0 ;
					break ;
				}
			}
		else {
			printf("illegal argument %s\n", *argv) ;
			ok = 0 ;
			}
		}

	if (!ok)
		return -1 ;

	if (printHelp) {
		printf("Usage: %s [-n device] [0 | 1] [-d]\n", progName) ;
		printf("       -n device   use device with this serial number\n") ;
		printf("       -d          print debug infos\n") ;
		printf("       -v          print version\n") ;
 		printf("       -h          print command usage\n") ;
		}

	if (printVersion)
		printf("%s vesion %s\n", progName, versionString) ;

	int USBcount = CWusb.OpenCleware() ;
	if (debug)
		printf("OpenCleware found %d devices\n", USBcount) ;

	int devID ;
	for (devID=0 ; devID < USBcount ; devID++) {
		int version = CWusb.GetVersion(devID) ;
		if (debug)
			printf("Device %d: Type=%d, Version=%d, SerNum=%d\n", devID,
						CWusb.GetUSBType(devID), version,
						CWusb.GetSerialNumber(devID)) ;
		if (CWusb.GetUSBType(devID) != CUSBaccess::CONTACT00_DEVICE || version < 6)
			continue ;

		if (debug) {
			int direction = CWusb.GetMultiConfig(devID) ;
			printf("Channel directions are 0x%04x (Bit=1 -> Input)\n", direction) ;
			if ( (direction & 1) != 1) {
				CWusb.SetMultiConfig(devID, 0xffff) ;		// all channels set to input
				CWusb.ResetDevice(devID) ;							// reset will store result permanently in device
				printf("Channel 1 not Input , start reconfiguration\n") ;
				usleep(500000) ;
				}
			}
		unsigned long int value=0, mask=0 ;
		unsigned long int Lvalue=-1, Lmask=-1 ;
		while (1) {
			ok = CWusb.GetMultiSwitch(devID, &mask, &value, 0) ;
			if (ok < 0) {
				printf("GetMultiSwitch failed (%d)\n", ok) ;
				state = -1 ;
				break ;
				}
			if (Lvalue != value || Lmask != mask) {
				printf("read gets value=0x%04x, mask=0x%04x, seq=%d\n", (unsigned int)value, (unsigned int)mask, ok) ;
				Lvalue = value ;
				Lmask = mask ;
				}
			usleep(500000) ;
			}
			
		break ;		// only one switch supported now
		}

	if (devID >= USBcount)
		printf("USBcontact not found\n") ;

	CWusb.CloseCleware() ;

	return state ;
	}

