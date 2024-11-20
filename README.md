# y_hud

![y_hud](https://github.com/user-attachments/assets/fadb9e1e-f0fe-4da4-b1d8-e54c52b1982e)

A beautiful and simple player & vehicle hud.

Supports [y_nitro](https://github.com/Ybox-Project/y_nitro).

# Features
- player HUD includes:
    - Uses gta's native hud for health / armor / oxygen
    - Circle progress for hunger, thirst, stress and voice level
        - The progress is updated by listening to the appropriate statebags
        - Fully integrated with pma-voice
    - "Compass" displaying heading & location
- vehicle HUD includes:
    - Speed (unit is configurable)
    - Fuel (with low fuel alerts)
    - Seatbelt (Green) & Harness (Blue)
    - Nitro if using y_nitro OR other compatible scripts (if that exists)
        - Nitro using the `nitro` statebag
        - Purge level using the `nitroPurge` statebag
    - Headlights & Turn signals
- Events to toggle hud / toggle cinematic mode
    - `qbx_hud:client:toggleCinematicMode`
    - `qbx_hud:client:togglehud`
        - `qbx_hud:client:showHud`
        - `qbx_hud:client:hideHud`

# Dependencies

- [ox_lib](https://github.com/overextended/ox_lib)
- [pma-voice](https://github.com/AvarianKnight/pma-voice)
- [qbx_core](https://github.com/Qbox-project/qbx_core)
