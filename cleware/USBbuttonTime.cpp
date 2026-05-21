/* USBbuttonTime [-n device] [-d]
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
 *   1.1    01.08.2023	Adapted to new Contact version with timer
 *                      When program starts, the timer will be reset, then we wait for key strokes, end with ^C
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
		printf("%s version %s\n", progName, versionString) ;

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

		if (version < 96) {
			if (debug)
				printf("USB-Contact Version=%d is the wrong version\n", version) ;
			continue ;
			}
		break ;		// only one Contact supported now
		}
		
	if (devID >= USBcount)
		printf("USBcontact not found\n") ;
	else {	
		unsigned long int value=0, mask=0 ;
		unsigned long int Lvalue=-1, Lmask=-1 ;
		int m_time1=0 ;
		int m_time2=0 ;
		int m_theWinnerIs = -1 ;
		
		int ok = CWusb.ResetDevice(devID) ;
/*	if (ok <= 0) {
			if (debug)
				printf("USB-Contact first Reset failed\n") ;
			usleep(2000000) ;
			ok = CWusb.ResetDevice(devID) ;
			if (ok <= 0 && debug)
				printf("USB-Contact second Reset failed\n") ;
			}
*/
		usleep(500000) ;
		if (debug) {
			printf("USB-Contact was reset, start round now\n") ;
		//	printf("Timer 1 = %d, Timer 2 = %d\n", CWusb.GetOnlineOnTime(devID), CWusb.GetOnlineOnCount(devID)) ;
			}

		while (1) {
			static int random = 0 ;
			unsigned long state, mask ;
			CWusb.GetMultiSwitch(devID, &mask, &state, 0) ;
			if (m_time1 == 0 && ( (state & 1) || ((state & 1) == 0 && (mask & 1))) ) {		// button 1 was detected for the first time
				m_time1 = CWusb.GetOnlineOnTime(devID) ;
				printf("Button 1 Timer = %d ms\n", m_time1) ;
				}
			if (m_time2 == 0 && ( (state & 2) || ((state & 2) == 0 && (mask & 2))) ) {		// button 2 was detected for the first time
				m_time2 = CWusb.GetOnlineOnCount(devID) ;
				printf("Button 2 Timer = %d ms\n", m_time2) ;
				}
			if (m_theWinnerIs == -1 && (m_time1 != 0 || m_time2 != 0)) {		// winner detected
				if (m_time1 == 0)
					m_theWinnerIs = 1 ;
				else if (m_time2 == 0)
					m_theWinnerIs = 0 ;
				else if (m_time1 < m_time2)
					m_theWinnerIs = 0 ;
				else if (m_time1 > m_time2)
					m_theWinnerIs = 1 ;
				if (m_theWinnerIs < 0) {	// same time !!
					printf("undecided condition, pick random vote\n") ;
					m_theWinnerIs= random ;
					}
				if (m_theWinnerIs == 0) {
					printf("Button 1 first\n") ;
					}
				else if (m_theWinnerIs == 1) {
					printf("Button 2 first\r\n") ;
					}
				}
			if (++random > 1)
				random = 0 ;
			if (m_time1 != 0 && m_time2 != 0)
				break ;	// both buttons were pressed, end program
			usleep(500000) ;
			}
		}


	CWusb.CloseCleware() ;

	return state ;
	}

