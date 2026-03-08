import subprocess

def get_diff():
    result = subprocess.run(['git', 'diff', 'HEAD', 'lib/application/usecases/generar_sorteo.dart'], capture_output=True, text=True)
    with open('diff_output.txt', 'w') as f:
        f.write(result.stdout)
get_diff()
