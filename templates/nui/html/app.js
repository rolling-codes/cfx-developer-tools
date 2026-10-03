const app = document.getElementById('app');
const message = document.getElementById('message');

window.addEventListener('message', (event) => {
    const { action, ...data } = event.data;

    if (action === 'show') {
        app.classList.remove('hidden');
        if (data.message) message.textContent = data.message;
    } else if (action === 'hide') {
        app.classList.add('hidden');
    }
});

window.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') close();
});

function close() {
    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({}),
    });
}
