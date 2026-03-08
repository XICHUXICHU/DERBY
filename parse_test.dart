void main() {
  var line = "1;EL ROSAL;005 VS ;010 VS ;006 VS ;";
  var parts = line.split(';');
  var anillos = parts.sublist(2).map((s) => s.replaceAll('VS', '').trim()).where((s) => s.isNotEmpty).toList();
  print(anillos);

  var line2 = ";PESO;1980;2025;2360;";
  var parts2 = line2.split(';');
  var pesos = parts2.sublist(2).map((s) => double.tryParse(s.trim()) ?? 0.0).where((p) => p > 0).toList();
  print(pesos);
}
