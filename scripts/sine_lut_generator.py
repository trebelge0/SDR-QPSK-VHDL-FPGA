
# Romain Englebert May 2026

import math


DATA_WIDTH = 12
TABLE_SIZE = 1024 
amplitude = 2**(DATA_WIDTH - 1) - 1

print("constant SINE_LUT : array(0 to 1023) of signed(11 downto 0) := (")
for i in range(TABLE_SIZE):
    val = int(amplitude * math.sin(math.pi / 2 * i / (TABLE_SIZE - 1)))
    hex_val = f'x"{val & 0xFFF:03X}"' 
    comma = "," if i < TABLE_SIZE - 1 else ");"
    print(f"    {hex_val}{comma} ", end="")
    
    if (i + 1) % 8 == 0:
        print("")