#############################
# Romain Englebert May 2026 #
#############################


import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# 1. Charger les données (ajuste le nom du fichier et les colonnes)
df = pd.read_csv('scripts/iqfir_data.csv') # Assure-toi que tu as des colonnes 'I' et 'Q'
I = df['I'].values
Q = df['Q'].values

# Création du signal complexe
signal_iq = I + 1j * Q

# 2. Setup de la figure
fig, axs = plt.subplots(1, 3, figsize=(18, 5))

# --- Plot A: Temps (Signaux I et Q) ---
axs[0].step(np.arange(0, len(I), 1), I, label='I', alpha=0.7)
axs[0].step(np.arange(0, len(I), 1), Q, label='Q', alpha=0.7)
axs[0].set_title("Time")
axs[0].legend()
axs[0].grid(True)

# --- Plot B: FFT (Spectre en dB) ---
# Application d'une fenêtre de Hann pour réduire les lobes secondaires
window = np.hanning(len(signal_iq))
fft_data = np.fft.fftshift(np.fft.fft(signal_iq * window))
freqs = np.fft.fftshift(np.fft.fftfreq(len(signal_iq)))
fft_db = 10 * np.log10(np.abs(fft_data)**2 + 1e-12)
fft_db -= np.max(fft_db) # Normalisation à 0dB

axs[1].plot(freqs, fft_db)
axs[1].set_title("PSD")
axs[1].set_xlabel("Normalized (f_s)")
axs[1].set_ylabel("dB")
axs[1].set_ylim(-60, 5)
axs[1].grid(True)

# --- Plot C: Constellation (IQ) ---
# On prend un point par symbole (ici, un point toutes les 16 samples)
# Si tu es suréchantillonné, tu peux essayer de trouver le pic du symbole
# ou simplement afficher tout pour voir l'ouverture de l'œil
axs[2].scatter(I/16, Q/16, s=3, alpha=0.6, color='purple')
axs[2].set_title("Constellation I/Q")
axs[2].set_xlabel("I")
axs[2].set_ylabel("Q")
axs[2].grid(True)
axs[2].set_aspect('equal') # Important pour voir la forme réelle

plt.tight_layout()
plt.show()