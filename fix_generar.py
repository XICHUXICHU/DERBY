import re

with open('lib/application/usecases/generar_sorteo.dart', 'r') as f:
    text = f.read()

text = text.replace("int dA = (totalFights[a.a.partidoId] ?? 0) + (totalFights[b.b.partidoId] ?? 0);",
                    "int dA = (totalFights[a.a.partidoId] ?? 0) + (totalFights[a.b.partidoId] ?? 0);")

text = text.replace("int dB = (totalFights[b.a.partidoId] ?? 0) + (totalFights[b.b.partidoId] ?? 0);",
                    "int dB = (totalFights[b.a.partidoId] ?? 0) + (totalFights[b.b.partidoId] ?? 0);")

with open('lib/application/usecases/generar_sorteo.dart', 'w') as f:
    f.write(text)

