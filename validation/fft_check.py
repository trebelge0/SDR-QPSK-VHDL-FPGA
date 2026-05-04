import numpy as np
import matplotlib.pyplot as plt
import pandas as pd

# Charger les données
df = pd.read_csv('data.csv')
fs = 1e6 # Remplace par ta fréquence d'échantillonnage réelle

# Créer un signal complexe
iq_signal = df['I'] + 1j * df['Q']

# Fenêtrage pour éviter les fuites spectrales (Hanning)
window = np.hanning(len(iq_signal))
iq_windowed = iq_signal * window

# Calcul FFT
fft_data = np.fft.fftshift(np.fft.fft(iq_windowed))
freqs = np.linspace(-fs/2, fs/2, len(fft_data))

# Magnitude en dB
magnitude_db = 20 * np.log10(np.abs(fft_data) / np.max(np.abs(fft_data)))

# Affichage
plt.figure(figsize=(10, 5))
plt.plot(freqs, magnitude_db)
plt.title("Densité Spectrale de Puissance (FFT)")
plt.xlabel("Fréquence (Hz)")
plt.ylabel("Magnitude (dB)")
plt.grid(True)
plt.ylim([-80, 5]) # Zoom sur le bas du spectre
plt.show()