// USBadc.cpp :	Read adc in a loop and write results to file in argument
//					USBadc [-o filename] [-s serialnumber] [-d] [-b] [-h] [-i timeinterval]
//					-o filename: write to this file
//					-s serialnumber: get data from this device
//					-i interval between two samples in seconds
//					-b used in a batch, get a single value and exit
//					-d print out debug statements
//					-h help
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

#ifdef CLEWARELINUX
#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>
#else	// CCLINUX

#include "stdafx.h"
#endif	// CCLINUX
#include "USBaccess.h"

#ifdef CLEWARELINUX
#define Sleep(ms) usleep( (ms) * 1000 )
#endif	// CCLINUX

int 
main(int argc, char* argv[]) {
	CUSBaccess CWusb ;

	char *filename = 0 ;
	int doDebug = 0 ;
	int showHelp = 0 ;
	char *progname = *argv ;
	int serialnumber = -1 ;
	int devID = -1 ;
	int batch=0 ;
	int interval = 1200 ;
	FILE *out ;

	for (argc--, argv++ ; argc > 0 ; argc--, argv++) {
		if (**argv == '-') {
			switch (argv[0][1]) {
				case 'O':
				case 'o':
					if (argc == 1) {
						printf("missing filename\n") ;
						break ;
						}
					filename = *++argv ;
					argc-- ;
					break ;
				case 'S':
				case 's':
					if (argc == 1) {
						printf("missing serial number\n") ;
						break ;
						}
					argv++ ;
					argc-- ;
					if (sscanf(*argv, "%d", &serialnumber) != 1)
						printf("serial number illegal (%s)\n", *argv) ;
					break ;
				case 'I':
				case 'i':
					if (argc == 1) {
						printf("missing interval\n") ;
						break ;
						}
					argv++ ;
					argc-- ;
					if (sscanf(*argv, "%d", &interval) != 1)
						printf("interval illegal (%s)\n", *argv) ;
					else
						interval *= 1000 ;		// convert to ms
					break ;
				case 'D':
				case 'd':
					doDebug = 1 ;
					break ;
				case 'B':
				case 'b':
					batch = 1 ;
					break ;
				case 'H':
				case 'h':
					showHelp = 1 ;
					break ;
				case '?':
					showHelp = 1 ;
					break ;
				default:
					printf("unknown argument %s\n", *argv) ;
					showHelp = 1 ;
					break ;
				}
			}
		}

	if (showHelp) {
		printf(" USBadc : Read adc in a loop and write results to file in argument\n") ;
		printf("	USBadc [-o filename] [-s serialnumber] [-d] [-b] [-h] [-i timeinterval]\n") ;
		printf("		-o filename: write to this file\n") ;
		printf("		-s serialnumber: get data from this device\n") ;
		printf("		-i interval between two samples in seconds\n") ;
		printf("		-b used in a batch, get a single value and exit\n") ;
		printf("		-d print out debug statements\n") ;
		exit(1) ;
		}
	int USBcount = CWusb.OpenCleware() ;
	if (doDebug)
		printf("OpenCleware found %d devices\n", USBcount) ;

	for (devID=0 ; devID < USBcount ; devID++) {
		int devType = CWusb.GetUSBType(devID) ;
		if (		devType == CUSBaccess::ADC0800_DEVICE) {
			if (serialnumber < 0)
				break ;
			if (serialnumber == CWusb.GetSerialNumber(devID))
				break ;
			}
		}
	if (devID < 0 || devID >= USBcount) {
		printf("no valid device found\n") ;
		return 0 ;
		}

	if (filename != 0) {
		out = fopen(filename, "w") ;
		if (out == 0) {
			printf("failed to open %s\n", filename) ;
			return 0 ;
			}
		}
	else 
		out = stdout ;

	int devType = CWusb.GetUSBType(devID) ;
	if (devType == ADC0800_DEVICE) {
		if (doDebug)
			printf("use device %d, serial number %d\n", devID, CWusb.GetSerialNumber(devID)) ;
		if (!batch) {		// in batch, the device is typically active
//			CWusb.ResetDevice(devID) ;
//			Sleep(1500) ;		// wait a second to settle after reset
//x			CWusb.StartDevice(devID) ;
//x			Sleep(1200) ;		// wait for the first values
			}

		while (1) {			// forever
			double adcVal ;
			int	   zeit ;
#ifndef CLEWARELINUX
			time_t now ;
			time(&now) ;
			CTime Now = now ;
			CString s = Now.Format("%d.%m.%y %H:%M:%S") ;
#endif	// CLEWARELINUX 
			int retry ;
			for (retry = 5 ; retry > 0 ; retry--) {
				int seqNum = CWusb.SelectADC(devID, 0) ;
				if ( (adcVal = CWusb.GetADC(devID, 0, 0)) == -200.) {
//					CWusb.ResetDevice(devID) ;
//  				Sleep(1500) ;		// wait a second to settle after reset
					CWusb.StartDevice(devID) ;
					Sleep(1200) ;		// wait for the first values
					if (doDebug)
						printf("GetADC(%d, seq=%d) failed\n", devID, seqNum) ;
					}
				else
					break ;
				}

			if (retry == 0) {
				if (doDebug)
					printf("Get ADC failed - do reset an try again\n") ;
				CWusb.ResetDevice(devID) ;
				Sleep(2500) ;		// wait a bit to settle after reset
				continue ;
				}
#ifdef CLEWARELINUX
//			if (doDebug)
//				printf("time=% 6d : ", zeit) ;
			fprintf(out, "%.3lf\n", adcVal) ;
			fflush(out) ;
#else	// CLEWARELINUX 
			CString t ;
			if (doDebug)
				t.Format("time=% 6d -  %.3lf\n", zeit, adcVal) ;
			else
				t.Format("  -  %.3lf\n", adcVal) ;
			s += t ;
			const char *str = LPCTSTR(s) ;
			fputs(str, out) ;
			fflush(out) ;
#endif	// CLEWARELINUX 
			if (batch)
				break ;
			Sleep(interval) ;
			}
		}

	CWusb.CloseCleware() ;

	return 0;
	}

