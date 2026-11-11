import os

os.makedirs("output", exist_ok=True)

results = []
for i in range(1, 11):
    line = f"Square of {i} is {i**2}"
    print(line)
    results.append(line)

with open("output/result.txt", "w") as f:
    f.write("\n".join(results) + "\n")
