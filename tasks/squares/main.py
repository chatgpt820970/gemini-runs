import os

os.makedirs('output', exist_ok=True)

with open('output/result.txt', 'w') as f:
    for i in range(1, 11):
        square = i ** 2
        text = f"{i}^2 = {square}"
        print(text)
        f.write(text + "\n")
