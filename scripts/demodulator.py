import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import firwin, filtfilt


# --- 1. CONFIGURATION ---
FILE_PATH = 'scripts/out_data.csv'
SAMPLES_PER_SYMBOL = 16
FS = 100e6    # 100 MHz
FC = 6.25e6   # 6.25 MHz

# 1. Input
INPUT_STR = b'11000110011101011000011110111011'
input_bits = [int(b) for b in INPUT_STR.decode('utf-8')]
input_bits.reverse()

# 2. CHARGEMENT
df = pd.read_csv(FILE_PATH)
signal_if = df['sample'].values
t = np.arange(len(signal_if)) / FS

# 3. NCO
lo_cos = np.cos(2 * np.pi * FC * t)
lo_sin = np.sin(2 * np.pi * FC * t)

# 4. MIXER
i_raw = signal_if * lo_cos
q_raw = -signal_if * lo_sin

# 5. FILTRAGE PASSE-BAS (Pour enlever le 2*FC)
nyquist = FS / 2
cutoff = 10e6 / nyquist # On coupe au-dessus du signal utile (10MHz)
taps = firwin(101, cutoff)

i_filt = filtfilt(taps, 1.0, i_raw, padlen=50)
q_filt = filtfilt(taps, 1.0, q_raw, padlen=50)

# 6. DÉCIMATION (On prend le centre des symboles)
delay = 4
I_symb = i_filt[delay::SAMPLES_PER_SYMBOL]
Q_symb = q_filt[delay::SAMPLES_PER_SYMBOL]

# 7. DÉMODULATION
map_I = (I_symb > 0).astype(int)
map_Q = (Q_symb > 0).astype(int)

recovered_bits = np.zeros(len(map_I)*2)
for i in range(0, 2*len(map_I), 2):
    recovered_bits[i] = map_Q[i//2]
    recovered_bits[i+1] = map_I[i//2]

print(recovered_bits)
print(input_bits)


# 8. VISUALISATION 

# Création de la figure avec 3 lignes
fig, axs = plt.subplots(3, 1, figsize=(10, 8), constrained_layout=True)

# 1. Modulator input (Signal IF)
axs[0].step(t, signal_if, color='gray') # Zoom sur les 500 premiers points
axs[0].set_title("IF signal (FPGA output)")
axs[0].grid(True)

# 2. Symbols and Filter
axs[1].plot(i_filt, label="I_filt", alpha=0.6)
axs[1].plot(q_filt, label="Q_filt", alpha=0.6)
axs[1].scatter(np.arange(delay, len(i_filt), SAMPLES_PER_SYMBOL), I_symb, 
               color='blue', s=20, label="I_symb", zorder=5)
axs[1].scatter(np.arange(delay, len(q_filt), SAMPLES_PER_SYMBOL), Q_symb, 
               color='red', s=20, label="Q_symb", zorder=5)
axs[1].set_title("Filtering and sampling")
axs[1].legend(loc='upper right')
axs[1].grid(True)

# 3. Input/Output comparison
# Note: si tu as un décalage, ajuste recovered_bits[X:]
axs[2].step(range(len(input_bits)), input_bits, label='FPGA input', 
            color='blue', where='post', alpha=0.7, linewidth=2)
axs[2].step(range(len(recovered_bits)), [b + 0.1 for b in recovered_bits], label='Demodulator output)', 
            color='red', linestyle='--', where='post', alpha=0.7, linewidth=2)

axs[2].set_title("Demodulated data vs. Modulated data")
axs[2].set_yticks([0, 1])
axs[2].legend()
axs[2].grid(True)

plt.show()

# Constellation
plt.scatter(I_symb, Q_symb, s=20, alpha=0.6, color='blue', label='Reçu')
plt.title("Constellation au centre des symboles")
plt.grid(True)
plt.xlim(-1.2*np.max(np.abs(I_symb)), 1.2*np.max(np.abs(I_symb)))
plt.ylim(-1.2*np.max(np.abs(Q_symb)), 1.2*np.max(np.abs(Q_symb)))

plt.tight_layout()
plt.show()

# Highlight des erreurs (optionnel)
diff = np.array(input_bits) != np.array(recovered_bits)
if np.any(diff):
    plt.scatter(np.where(diff)[0], [0.5]*np.sum(diff), color='black', label='Erreur de bit !')
    print(f"Attention : {np.sum(diff)} erreurs détectées !")
else:
    print("Succès : Les bits sont parfaitement alignés.")