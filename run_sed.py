import re

with open("lib/application/usecases/generar_sorteo.dart", "r") as f:
    text = f.read()

# Add import
if "import 'dart:math'" not in text:
    text = "import 'dart:math' as math;\n" + text

# Use regex to find the block
pattern = r"List<List<Enfrentamiento>> fightsPorRonda.*?(?=\s*for\s*\(\s*int\s*i\s*=\s*0;\s*i\s*<\s*nRondas;\s*i\+\+\s*\)\s*{\s*rondasGeneradas\.add)"
match = re.search(pattern, text, re.DOTALL)

if match:
    new_logic = """List<List<Enfrentamiento>> fightsPorRonda = List.generate(nRondas, (_) => []);
    
    // Optimizador Simulated Annealing explícito (Simula Tuums y elimina descansos)
    final _rnd = math.Random(DateTime.now().millisecondsSinceEpoch);
    List<int> colors = List.filled(pares.length, 0);
    for (int i = 0; i < colors.length; i++) colors[i] = _rnd.nextInt(nRondas);
    
    double calcScore(List<int> c) {
      double cost = 0;
      final Set<int> allPartidos = {};
      for (final p in pares) {
        allPartidos.add(p.a.partidoIimport re

with open("libdd
with optid    text = f.read()

# Add import
if "import 'dart:math'" not in teis
# Add impots = List.if "import da    text = "import 'dart:math' as mpa
# Use regex to find the block
pattern = r"List<idopattern = r"List<List<Enfrenidmatch = re.search(pattern, text, re.DOTALL)

if match:
    new_logic = """List<List<Enfrentamiento>> fightsPorRonda = List.generate(nRondas, (_) => [  
if match:
    new_logic = """List<List<En= 1    new_(c    
    // Optimizador Simulated Annealingn la misma ronda
          }
          if (counts[r] >    {
    final _rnd = math.Random(DateTime.now().millisecondsSinceeferir R1 sobre R4
         List<int> colors = List.filled(pares.length, 0);
    for (int isc    for (int i = 0; i < colors.length; i++) colors[Ro    
    double calcScore(List<int> c) {
      double cost = 0;
      final Ssp   o       double cost = 0;
      findo
       final Set<int>         for (final p in pares) {
      ou        allPartidos.add(p.a.por
with open("libdd
with optid    text = f.reaors);
    
    doubl
# Add import
if "import 'datemif "import 
 # Add impots = List.if "import da ; # Use regex to find the block
pattern = r"List<idopattern =      int oldC = colors[idx];
        int 
if match:
    new_logic = """List<List<Enfrentamiento>> fightsPorRonda = List.generate(nRonx]     new_  if match:
    new_logic = """List<List<En= 1    new_(c    
    // Optimizador Simulated Annealior    new_co    // Optimizador Simulated Annealingn la mism            }
          if (counts[r] >    {
    finath.e          or    final _rnd = math.Random(           List<int> colors = List.filled(pares.length, 0);
    for (int isc          for (int isc    for (int i = 0; i < colors.length;n re    double calcScore(List<int> c) {
      double cost = 0;
      final S i      double cost = 0;
      finalPo      final Ssp   o  am      findo
       final Set<int>        co       finoc      ou        allPartidos.add(p.a.por
with open("li: with open("libdd
with optid    text = umwith optid    ter    
    doubl
# Add import
if ));
  # Add im    text = text # Add impots = List.if "imc pattern = r"List<idopattern =      int oldC = colors[idx];
      rar_sorteo.dart", "w") as f:
        f.write(text)
    print(if match:
 ES    new_gex")
else:
    print("MATCH FAILED. regex did not match.")
