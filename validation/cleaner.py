import pandas as pd

def binaire_signe_to_int(bin_str):
    """Convertit une chaîne binaire 12 bits en entier signé (complément à 2)."""
    if 'U' in bin_str: return 0 # Gère les états indéfinis
    val = int(bin_str, 2)
    # Si le bit de poids fort (bit 11) est à 1, c'est un nombre négatif
    if val >= 2**11:
        val -= 2**12
    return val

def nettoyer_log_modelsim(input_file, output_file):
    data = []
    
    with open(input_file, 'r') as f:
        # On saute les premières lignes d'en-tête (le format list de ModelSim)
        lines = f.readlines()
        
        for line in lines:
            parts = line.split()
            # On vérifie qu'on a bien 4 colonnes (Temps, Delta, I, Q)
            if len(parts) == 4:
                # On tente de convertir I et Q, on ignore si ce n'est pas du binaire
                try:
                    i_val = binaire_signe_to_int(parts[2])
                    q_val = binaire_signe_to_int(parts[3])
                    data.append({'I': i_val, 'Q': q_val})
                except ValueError:
                    continue # Ignore les lignes corrompues ou avec des 'U'
    
    # Sauvegarde en CSV
    df = pd.DataFrame(data)
    df.to_csv(output_file, index=False)

# Utilisation
nettoyer_log_modelsim('data.txt', 'data.csv')