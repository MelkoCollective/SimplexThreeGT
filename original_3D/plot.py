import matplotlib.pyplot as plt
import numpy as np
 
T, E, C = np.loadtxt('L3.txt', delimiter=' ', unpack=True)
 
plt.plot(T, C)
plt.title('Specific heat versus temperature')
plt.xlabel('T')
plt.ylabel('C')
plt.show()
