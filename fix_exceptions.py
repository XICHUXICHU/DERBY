with open('lib/engine/derby_engine.dart', 'r') as f:
    content = f.read()

content = content.replace("mensaje: mensaje: ", "mensaje: ")
content = content.replace("throw MatchingImposibleException(mensaje: 'No hay gallos base", "throw MatchingImposibleException(mensaje: 'No hay gallos base")
# Wait, replacing "mensaje: mensaje:" would leave "throw MatchingImposibleException(mensaje:"
# Let's just do:
content = content.replace("mensaje: mensaje:", "mensaje:")

with open('lib/engine/derby_engine.dart', 'w') as f:
    f.write(content)
