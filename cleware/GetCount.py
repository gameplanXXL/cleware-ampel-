# Use program USBio16 to send data to USB device
import os, time, subprocess
i=1
count = 0
while (i < 0x10000 ) :
  cmd = "sudo ./USBcounter -f"
  result = subprocess.check_output(cmd, shell=True) ;
  count = int(result.decode('UTF-8'))
  print(i, "# count=", count)
  time.sleep(1)
  i = i +1
print("end")

