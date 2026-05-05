#############################
# Romain Englebert May 2026 #
#############################


import pandas as pd
import re


def modelsim_to_csv(input_file, output_file):
    data = []
    
    regex = re.compile(r'([01]{12})')

    with open(input_file, 'r') as f:
        for line in f:
            match = regex.search(line)
            if match:
                bin_str = match.group(1)
                # Conversion binaire vers entier signé 12 bits
                val = int(bin_str, 2)
                if val >= 2**11: # Gestion du signe (complément à deux)
                    val -= 2**12
                data.append(val)
    
    df = pd.DataFrame(data, columns=['sample'])
    df.to_csv(output_file, index=False)
    print(f"Conversion terminée : {output_file}")


modelsim_to_csv("scripts/out_data.txt", "scripts/out_data.csv")