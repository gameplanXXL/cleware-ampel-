# Use program USBio16 to send data to USB device
import os, time
i=1
while (i < 0x10000 ) :
  print("write ", i)
  cmd = "sudo ./USBswitchCmd -b %d" % i
  os.system(cmd)
  time.sleep(0.2)
  i = i +1
print("end")

