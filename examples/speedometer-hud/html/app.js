const hud        = document.getElementById('hud');
const speedValue = document.getElementById('speed-value');
const speedUnit  = document.getElementById('speed-unit');
const gearValue  = document.getElementById('gear-value');
const rpmBar     = document.getElementById('rpm-bar');

let useKph = true;

window.addEventListener('message', (event) => {
    const data = event.data;

    switch (data.action) {
        case 'show':
            hud.classList.remove('hidden');
            break;

        case 'hide':
            hud.classList.add('hidden');
            break;

        case 'update': {
            speedValue.textContent = useKph ? data.speedKph : data.speedMph;
            speedUnit.textContent  = useKph ? 'KPH' : 'MPH';

            const gear = data.gear;
            gearValue.textContent = gear === 0 ? 'R' : (gear > 8 ? 'N' : gear);

            const pct = Math.min(data.rpm, 100);
            rpmBar.style.width = pct + '%';
            rpmBar.style.background = pct > 85 ? '#ef5350' : pct > 65 ? '#ffb300' : '#4fc3f7';
            break;
        }
    }
});

// Toggle KPH/MPH on click
hud.addEventListener('click', () => {
    useKph = !useKph;
});
