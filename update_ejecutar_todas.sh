#!/bin/bash
cat lib/application/usecases/generar_sorteo.dart | perl -0777 -pe 's/List<Ronda> ejecutarTodas\(\{.*?(?=  \/\/\/ (?:Distribuye|Calcula))//sq' > temp_generar_sorteo.dart
