import { initializeApp } from "https://www.gstatic.com/firebasejs/10.9.0/firebase-app.js";
import { getAuth, signInWithEmailAndPassword, onAuthStateChanged, signOut } from "https://www.gstatic.com/firebasejs/10.9.0/firebase-auth.js";
import { getFirestore, doc, setDoc } from "https://www.gstatic.com/firebasejs/10.9.0/firebase-firestore.js";

const firebaseConfig = {
  apiKey: "AIzaSyCPJDRLdiBW2J3gUDUUOynA-yVBJM-HKSI",
  authDomain: "derby2-6f83a.firebaseapp.com",
  projectId: "derby2-6f83a",
  storageBucket: "derby2-6f83a.firebasestorage.app",
  messagingSenderId: "256476163158",
  appId: "1:256476163158:web:70afbc7dd7d6771a929ff7",
};

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);

const loginScreen = document.getElementById("login-screen");
const dashScreen = document.getElementById("dashboard-screen");
const errorMsg = document.getElementById("error-msg");

// === Estado ===
let diasSeleccionados = 0;
let ultimoCodigo = '';
let ultimaExpiracion = '';
let ultimoClienteNombre = '';

// =============================================
// Todas las funciones definidas localmente
// =============================================

function irPaso(paso) {
    if (paso === 2 && diasSeleccionados === 0) return;
    if (paso === 3) {
        const nombre = document.getElementById("client-name").value.trim();
        if (!nombre) {
            document.getElementById("form-error").innerText = "El nombre del cliente es obligatorio.";
            return;
        }
        document.getElementById("form-error").innerText = "";
        generarLicencia();
    }
    document.getElementById("step1").classList.toggle("hidden", paso !== 1);
    document.getElementById("step2").classList.toggle("hidden", paso !== 2);
    document.getElementById("step3").classList.toggle("hidden", paso !== 3);

    document.getElementById("step1-dot").className = "step " + (paso === 1 ? 'active' : (paso > 1 ? 'done' : ''));
    document.getElementById("step2-dot").className = "step " + (paso === 2 ? 'active' : (paso > 2 ? 'done' : ''));
    document.getElementById("step3-dot").className = "step " + (paso === 3 ? 'active' : '');
}

function seleccionarDuracion(dias, btn) {
    diasSeleccionados = dias;
    document.querySelectorAll('.duration-btn').forEach(function(b) { b.classList.remove('selected'); });
    btn.classList.add('selected');
    document.getElementById("btn-next1").disabled = false;
}

function generarCodigoSeguro(tipo) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    const arr = new Uint8Array(16);
    crypto.getRandomValues(arr);
    let code = '';
    for (let i = 0; i < 16; i++) {
        code += chars[arr[i] % chars.length];
    }
    return "DERB-" + tipo + "-" + code.slice(0,4) + "-" + code.slice(4,8) + "-" + code.slice(8,12) + "-" + code.slice(12,16);
}

async function generarLicencia() {
    document.getElementById("result-loading").classList.remove("hidden");
    document.getElementById("result-box").classList.add("hidden");

    let tipo = "PRO";
    if (diasSeleccionados === 30) tipo = "1M";
    if (diasSeleccionados === 180) tipo = "6M";
    if (diasSeleccionados === 365) tipo = "1A";
    if (diasSeleccionados === 3650) tipo = "INF";

    const codigo = generarCodigoSeguro(tipo);

    const expiryDate = new Date();
    expiryDate.setDate(expiryDate.getDate() + diasSeleccionados);

    const clientName = document.getElementById("client-name").value.trim();
    const clientPhone = document.getElementById("client-phone").value.trim();
    const clientEmail = document.getElementById("client-email2").value.trim();
    const clientRanch = document.getElementById("client-ranch").value.trim();
    const clientNotes = document.getElementById("client-notes").value.trim();

    try {
        await setDoc(doc(db, "Licenses", codigo), {
            hardware_id: "",
            status: "active",
            expiry_date: expiryDate,
            duration_days: diasSeleccionados,
            created_at: new Date(),
            client_name: clientName,
            client_phone: clientPhone,
            client_email: clientEmail,
            client_ranch: clientRanch,
            client_notes: clientNotes,
        });

        ultimoCodigo = codigo;
        ultimoClienteNombre = clientName;
        let fechaFormat = expiryDate.toLocaleDateString('es-ES');
        if (diasSeleccionados === 3650) fechaFormat = "De por vida";
        ultimaExpiracion = fechaFormat;

        document.getElementById("result-loading").classList.add("hidden");
        document.getElementById("result-box").classList.remove("hidden");
        document.getElementById("code-text").innerText = codigo;
        document.getElementById("expiry-text").innerText = "Valido hasta: " + fechaFormat;
        document.getElementById("result-client-name").innerText = "👤 " + clientName;

    } catch (e) {
        document.getElementById("result-loading").classList.add("hidden");
        alert("Error al generar: " + e.message);
    }
}

function copiarWhatsApp() {
    const msg = "¡Hola " + ultimoClienteNombre + "! Tu licencia para *Derby Pro* está lista.\n\n" +
        "🔑 *Clave de Activación:*\n" + ultimoCodigo + "\n\n" +
        "📅 *Válido hasta:* " + ultimaExpiracion + "\n\n" +
        "⚠️ _Recuerda que al ingresar esta clave, quedará vinculada únicamente a esa computadora._\n\n" +
        "Si necesitas ayuda con la instalación, no dudes en escribirme.";

    navigator.clipboard.writeText(msg).then(function() {
        alert("✅ Mensaje copiado al portapapeles. ¡Pégalo en WhatsApp!");
    }).catch(function() {
        prompt("Copia este mensaje:", msg);
    });
}

function nuevaLicencia() {
    diasSeleccionados = 0;
    ultimoCodigo = '';
    ultimaExpiracion = '';
    ultimoClienteNombre = '';
    document.querySelectorAll('.duration-btn').forEach(function(b) { b.classList.remove('selected'); });
    document.getElementById("btn-next1").disabled = true;
    document.getElementById("client-name").value = '';
    document.getElementById("client-phone").value = '';
    document.getElementById("client-email2").value = '';
    document.getElementById("client-ranch").value = '';
    document.getElementById("client-notes").value = '';
    document.getElementById("form-error").innerText = '';
    document.getElementById("result-box").classList.add("hidden");
    document.getElementById("result-loading").classList.remove("hidden");
    irPaso(1);
}

function cerrarSesion() {
    signOut(auth);
}

// =============================================
// Exponer al HTML (onclick)
// =============================================
window.irPaso = irPaso;
window.seleccionarDuracion = seleccionarDuracion;
window.copiarWhatsApp = copiarWhatsApp;
window.nuevaLicencia = nuevaLicencia;
window.cerrarSesion = cerrarSesion;

// =============================================
// Auth listener
// =============================================
onAuthStateChanged(auth, function(user) {
    if (user) {
        loginScreen.classList.add("hidden");
        dashScreen.classList.remove("hidden");
        nuevaLicencia();
    } else {
        dashScreen.classList.add("hidden");
        loginScreen.classList.remove("hidden");
    }
});

document.getElementById("btn-login").addEventListener("click", async function() {
    const email = document.getElementById("email").value.trim();
    const pwd = document.getElementById("password").value;
    errorMsg.innerText = "";
    if (!email || !pwd) { errorMsg.innerText = "Llena ambos campos."; return; }
    try {
        await signInWithEmailAndPassword(auth, email, pwd);
    } catch (e) {
        errorMsg.innerText = "Credenciales incorrectas.";
    }
});
// =============================================
// Add Event Listeners for strict CSP/Module behavior
// =============================================
document.addEventListener("DOMContentLoaded", function() {
    const bindClick = (id, fn) => {
        const el = document.getElementById(id);
        if (el) el.addEventListener("click", fn);
    };

    bindClick("btn-dur-30", (e) => seleccionarDuracion(30, e.currentTarget));
    bindClick("btn-dur-180", (e) => seleccionarDuracion(180, e.currentTarget));
    bindClick("btn-dur-365", (e) => seleccionarDuracion(365, e.currentTarget));
    bindClick("btn-dur-3650", (e) => seleccionarDuracion(3650, e.currentTarget));

    bindClick("btn-next1", () => irPaso(2));
    bindClick("btn-atras-1", () => irPaso(1));
    bindClick("btn-goto-3", () => irPaso(3));
    bindClick("btn-copy-wa", copiarWhatsApp);
    bindClick("btn-nueva-lic", nuevaLicencia);
    bindClick("btn-cerrar-ses", cerrarSesion);
});
