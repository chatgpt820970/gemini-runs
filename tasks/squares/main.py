import os

output_dir = os.path.join(os.path.dirname(__file__), "output")
os.makedirs(output_dir, exist_ok=True)

output_file = os.path.join(output_dir, "result.txt")

with open(output_file, "w") as f:
    for i in range(1, 11):
        line = f"{i}^2 = {i**2}"
        print(line)
        f.write(line + "\n")
