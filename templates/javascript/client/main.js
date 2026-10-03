setTick(async () => {
    await Delay(1000);

    const playerPed = PlayerPedId();
    // client loop — keep expensive work outside setTick, use Delay to yield
});

onNet('myResource:clientAction', (data) => {
    // handle server → client event
    console.log('received clientAction', JSON.stringify(data));
});
