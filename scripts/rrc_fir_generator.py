import numpy as np
import matplotlib.pyplot as plt


def design_rrc(num_taps, osr, alpha):
    t = np.arange(num_taps) - (num_taps - 1) / 2
    t = t / osr
    h = np.zeros(num_taps)
    for i in range(num_taps):
        if t[i] == 0:
            h[i] = 1 - alpha + (4 * alpha / np.pi)
        elif abs(t[i]) == 1 / (4 * alpha):
            h[i] = (alpha / np.sqrt(2)) * ((1 + 2 / np.pi) * np.sin(np.pi / (4 * alpha)) + (1 - 2 / np.pi) * np.cos(np.pi / (4 * alpha)))
        else:
            h[i] = (np.sin(np.pi * t[i] * (1 - alpha)) + 4 * alpha * t[i] * np.cos(np.pi * t[i] * (1 + alpha))) / \
                   (np.pi * t[i] * (1 - (4 * alpha * t[i])**2))
    return h / np.sum(h)

# Paramètres
NUM_TAPS = 33
OSR = 4
ALPHA = 0.5
BIT_WIDTH = 16

# 1. Génération
h = design_rrc(NUM_TAPS, OSR, ALPHA)

# 2. Print
# Quantisation (Conversion en entiers 16 bits signés)
# On multiplie par 2^(BIT_WIDTH-1) - 1 pour utiliser toute la dynamique
max_val = 2**(BIT_WIDTH - 1) - 1
coeffs_int = np.round(h * max_val).astype(int)

# Affichage formaté pour VHDL
print(f"-- Coefficients RRC ({NUM_TAPS} taps, Alpha={ALPHA}, OSR={OSR})")
print("constant COEFFS : coeff_array := (")
for i, val in enumerate(coeffs_int):
    # Gestion du signe pour le format hexadécimal VHDL
    hex_val = f'x"{val & 0xFFFF:04X}"'
    
    # Formatage de ligne
    end = "," if i < NUM_TAPS - 1 else ");"
    print(f"    {hex_val}{end}", end="")
    
    if (i + 1) % 8 == 0:
        print("") # Saut de ligne tous les 8
print("\n")

# 3. Calcul FFT (Réponse fréquentielle)
# On ajoute des zéros (padding) pour une meilleure résolution spectrale
N_FFT = 1024
H_freq = np.fft.fftshift(np.fft.fft(h, N_FFT))
freq = np.linspace(-0.5, 0.5, N_FFT)

# 4. Affichage
plt.figure(figsize=(12, 6))

# Graphique Temps
plt.subplot(2, 1, 1)
plt.stem(h, basefmt=" ")
plt.title(f"Réponse Impulsionnelle (Impulse Response) - {NUM_TAPS} Taps")
plt.grid(True)

# Graphique Fréquence (FFT)
plt.subplot(2, 1, 2)
# Conversion en dB pour mieux voir l'atténuation
H_db = 20 * np.log10(np.abs(H_freq) / np.max(np.abs(H_freq)))
plt.plot(freq, H_db)
plt.title("Réponse en Fréquence (FFT) - Magnitude en dB")
plt.xlabel("Fréquence normalisée (fs)")
plt.ylabel("Magnitude (dB)")
plt.grid(True)
plt.ylim([-60, 5]) # Zoom sur la zone utile

plt.tight_layout()
plt.show()