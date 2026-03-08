import re

with open('lib/engine/derby_engine.dart', 'r') as f:
    engine_content = f.read()

engine_content = engine_content.replace(
    "throw MatchingImposibleException(",
    "throw MatchingImposibleException(mensaje: "
)

engine_content = engine_content.replace(
    "peso: galloBaseReal.peso,",
    "pesoGramos: galloBaseReal.pesoGramos,"
)

engine_content = engine_content.replace(
    "galloBaseReal.peso}g",
    "galloBaseReal.pesoGramos}g"
)

with open('lib/engine/derby_engine.dart', 'w') as f:
    f.write(engine_content)

with open('test/engine/traza_11p_4r_test.dart', 'r') as f:
    test_content = f.read()

test_content = test_content.replace("peso: 2000", "pesoGramos: 2000")

with open('test/engine/traza_11p_4r_test.dart', 'w') as f:
    f.write(test_content)
