import os

os.makedirs("output", exist_ok=True)

with open("output/result.txt", "w") as f:
    for i in range(1, 11):
        line = f"{i}^2 = {i**2}"
        print(line)
        f.write(line + "\n")
