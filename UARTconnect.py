import serial
import numpy as np
import matplotlib.pyplot as plt

# Function created to turn 2-digit integers into BCD bytes
def to_bcd(x):
    tens = int(np.floor(x / 10)) * 16
    ones = x - int(np.floor(x / 10))*10
    print(int(np.floor(x / 10)))
    total = tens + ones
    return total.to_bytes(1, 'big')
    
serialPort = serial.Serial(port = "COM4", baudrate = 9600, bytesize = 8)
serialPort.open()
        
 #%%

from datetime import datetime

now = datetime.now()
serialPort.write(to_bcd(now.hour))
plt.pause(0.2)          # Delay so system can run before another signal is sent

now = datetime.now()
serialPort.write(to_bcd(now.minute))
plt.pause(0.2)

now = datetime.now()
serialPort.write(to_bcd(now.second))


#%%

serialPort.close()
