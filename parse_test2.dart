void main() {
  var d = "1;EL ROSAL;005 VS ;010 VS ;006 VS ;";
  var rings = d.split(';').sublist(2).map((s) => s.replaceAll('VS', '').trim()).where((s) => s.isNotEmpty).toList();
  print(rings);
}
