/* definitions for send2cc
 *
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

int cwLoop(char *serverName, int port, int debugEnabled) ;
void catchIOproblems(int sig) ;
typedef void (*sighandler_t)(int) ;

struct cwStruct {
	int tempTime ; 		  // time returned from USB-Temp
	int sleepTime ;      // time to wake up in ms
	int elapsedTime ;    // current time to wake up in ms
	int	devType ;
	int serialNumber ;
	int version ;
	} ;


enum {
	remoteData=10, remoteManualAction=11, remoteDisconnect=12, remoteInterval=13, remoteName=14
	} ;
