import os

app_js_path = "/Volumes/mcOS/derby2_flutter/admin_web/app.js"
index_html_path = "/Volumes/mcOS/derby2_flutter/admin_web/index.html"

# Ensure we just bind listeners instead of hoping window mapping works
addition = """
// =============================================
// Add Event Listeners for strict CSP/Module behavior
// =============================================
document.addEventListener("DOMContentLoaded", function() {
    const bindClick = (id, fn) => {
        const el = document.getElementById(id);
        if (el) el.addEventListener("click", fn);
    };

    bindClick("btn-dur-30", (e) => seleccionarDuracion(30, e.target));
    bindClick("btn-dur-180", (e) => seleccionarDuracion(180, e.target));
    bindClick("btn-dur-365", (e) => seleccionarDuracion(365, e.target));
    bindClick("btn-dur-3650", (e) => seleccionarDuracion(3650, e.target));

    bindClick("btn-goto-2", () => irPaso(2));
    bindClick("btn-atras-1", () => irPaso(1));
    bindClick("btn-goto-3", () => irPaso(3));
    bindClick("btn-copy-wa", copiarWhatsApp);
    bindClick("btn-nueva-lic", nuevaLicencia);
    bindClick("btn-cerrar-ses", cerrarSesion);
});
"""

with open(app_js_path, "r") as f:
    js_content = f.read()

if "Add Event Listeners for strict CSP/Module behavior" not in js_content:
    with open(app_js_path, "a") as f:
        f.write(addition)

print("Listeners injected into app.js")
