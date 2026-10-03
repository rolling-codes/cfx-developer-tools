onNet('myResource:serverEvent', (data) => {
    const src = global.source;
    if (!src || src <= 0) return;

    // server logic here
    console.log(`Player ${src} triggered serverEvent`);
});

on('onResourceStart', (resourceName) => {
    if (GetCurrentResourceName() !== resourceName) return;
    console.log(`${resourceName} started`);
});
