import pandas as pd
import matplotlib.pyplot as plt

# Charger les données
df = pd.read_csv('data.csv')
print(df)
# Créer le graphique
plt.figure(figsize=(6, 6))
plt.scatter(df['I'], df['Q'], alpha=0.5) # alpha pour voir la densité
plt.axhline(0, color='black', linewidth=0.5)
plt.axvline(0, color='black', linewidth=0.5)
plt.title("Diagramme de Constellation")
plt.xlabel("I (In-phase)")
plt.ylabel("Q (Quadrature)")
plt.grid(True)
plt.axis('equal') # Important pour voir la géométrie réelle
plt.show()