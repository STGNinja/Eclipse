const firebaseConfig = {
    apiKey: "AIzaSyArIKrfWt8d1GZAB9F6eA81PyF53ATNouA",
    authDomain: "eclipse-2a42b.firebaseapp.com",
    projectId: "eclipse-2a42b",
    storageBucket: "eclipse-2a42b.firebasestorage.app",
    messagingSenderId: "455724679534",
    appId: "1:455724679534:ios:b62d1ad2d90404d3a8817f"
};

document.addEventListener('DOMContentLoaded', () => {
    try { firebase.initializeApp(firebaseConfig); } catch (e) { console.error(e); }

    const urlParams = new URLSearchParams(window.location.search);
    const oobCode = urlParams.get('oobCode');
    const pwd = document.getElementById('new-password');
    const cfm = document.getElementById('confirm-password');
    const btn = document.getElementById('submit-btn');

    if (!oobCode) {
        showError("Invalid or expired link.");
    }

    // Live validation
    function validate() {
        if (pwd.value.length >= 6 && pwd.value === cfm.value) {
            btn.disabled = false;
        } else {
            btn.disabled = true;
        }
    }
    pwd.addEventListener('input', validate);
    cfm.addEventListener('input', validate);
});

function showError(msg) {
    const el = document.getElementById('error-message');
    el.style.display = 'block';
    el.innerText = msg;
}

async function handleReset(event) {
    event.preventDefault();
    const btn = document.getElementById('submit-btn');
    const password = document.getElementById('new-password').value;
    const urlParams = new URLSearchParams(window.location.search);
    const oobCode = urlParams.get('oobCode');

    btn.innerText = "Updating...";
    btn.disabled = true;
    document.getElementById('error-message').style.display = 'none';

    try {
        await firebase.auth().confirmPasswordReset(oobCode, password);
        document.getElementById('form-view').style.display = 'none';
        document.getElementById('success-view').style.display = 'flex';
    } catch (error) {
        showError(error.code === 'auth/invalid-action-code' ? "Link expired." : error.message);
        btn.innerText = "Update Password";
        btn.disabled = false;
    }
}
