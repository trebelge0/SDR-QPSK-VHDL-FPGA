#############################
# Romain Englebert May 2026 #
#############################

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# 1. Charger les données
df = pd.read_csv('scripts/out_data.csv')
signal = df['sample'].values

# 2. Préparation du spectre
# Application d'une fenêtre de Hann pour réduire les lobes secondaires
window = np.hanning(len(signal))
fft_data = np.fft.fft(signal * window)

# Centrer le spectre (déplace la fréquence 0 au milieu)
fft_shifted = np.fft.fftshift(fft_data)
freqs = np.fft.fftshift(np.fft.fftfreq(len(signal)))

# Conversion en dB pour une lecture plus naturelle
# (On ajoute une petite valeur pour éviter le log(0))
mag_db = 20 * np.log10(np.abs(fft_shifted) + 1e-12)

# 3. Plot du Spectre
plt.figure(figsize=(12, 6))
plt.plot(freqs, mag_db)
plt.title("Spectre en fréquence (Centré)")
plt.xlabel("Fréquence normalisée (f/fs)")
plt.ylabel("Magnitude (dB)")
plt.grid(True, which='both', linestyle='--', alpha=0.7)
plt.axvline(x=0, color='red', linestyle='-', linewidth=0.5) # Marquer le centre
plt.show()