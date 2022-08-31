import numpy as np
import matplotlib.pyplot as plt

with open('data.txt') as f:
    lines = f.readlines()
    T = [line.split()[0] for line in lines]
    E = [line.split()[1] for line in lines]
    C = [line.split()[2] for line in lines]

fig = plt.figure()

ax1 = fig.add_subplot(111)

ax1.set_title("D=3 S=3 ")    
ax1.set_xlabel('T')
ax1.set_ylabel('C')

ax1.plot(T,C, c='r', label='Specific Heat')

leg = ax1.legend()

plt.show()
