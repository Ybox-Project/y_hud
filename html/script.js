let maxSpeedCounter = 350;

document.addEventListener("DOMContentLoaded", function () {
    window.addEventListener("message", function (event) {
        if (event.data.update == true) {
            const Data = event.data.data;
            for (let i = 0; i < Data.length; i++) {
                const dataItem = Data[i];
                switch (dataItem.type) {
                    case 'compass':
                        setCompass(dataItem.show, dataItem.heading, dataItem.street, dataItem.street2);
                        break;
                    case 'vehiclehud':
                        document.getElementsByClassName('vehicle-hud')[0].style.opacity = dataItem.show ? 1 : 0;
                        break;
                    case 'speed':
                        setSpeed(dataItem.speed);
                        break;
                    case 'speedmax':
                        maxSpeedCounter = dataItem.speed * 1.2; // 20% margin just in case / for style (feels weird if it's at the limit? maybe just a personal thing)
                        break;
                    case 'gauge':
                        if (dataItem.name === 'purge') {
                            setGaugeProgress(dataItem.value, dataItem.name);
                        }
                        setGauge(dataItem.value, dataItem.name, dataItem.show);
                        break;
                    case 'dashboardlights':
                        setDashboardLight(dataItem);
                        break;
                    case 'progress':
                        let options = {};
                        switch (dataItem.name) {
                            case 'hunger':
                                options.stroke = dataItem.value < 30;
                            case 'thirst':
                                options.stroke = dataItem.value < 30;
                            case 'stress':
                                options.stroke = dataItem.value > 75;
                            case 'voice':
                                options.stroke = dataItem.state == 1 ? '#FF935A' : dataItem.state == 2 ? '#5A93FF' : null;
                        }
                        setProgress(dataItem.value, `progress-${dataItem.name}`, options);
                        break;
                    case 'seatbelt':
                        setSeatbelt(dataItem.value, dataItem.harness);
                        break;
                    case 'showHud':
                        document.getElementsByTagName('body')[0].style.opacity = dataItem.value ? 1 : 0;
                        break;
                }
            }
        }
    });
});

function setProgress(percent, className, options) {
    let circle = document.getElementById(className);
    if (circle === undefined) return;
    if (percent !== undefined) {
        Math.min(100, Math.max(0, percent));
        let circumference = circle.r.baseVal.value * 2 * Math.PI;
        //Why 0.81? i don't know, but it works
        let offset = circumference - ((percent / 100) * 0.81) * circumference;

        circle.style.strokeDasharray = circumference;
        circle.style.strokeDashoffset = offset;
    }
    if (options !== undefined) {
        for (var key in options) {
            circle.style[key] = options[key] || null;
        }
    }
}

function setSeatbelt(toggle, harness) {
    if (toggle === undefined) return;
    document.getElementById('seatbelt').style.color = harness && '#5555aaff' || toggle && '#55aa55ff' || null;
}

function setSpeed(speed) {
    if (typeof speed !== 'number') return;
    speed = Math.round(speed);
    document.getElementById('speed').innerHTML = speed;

    if (speed > maxSpeedCounter) speed = maxSpeedCounter; // Can definitely happen since the fInitialDriveMaxFlatVel is not a hard limit
    setSpeedProgress(speed/maxSpeedCounter);
}

function setGaugeProgress(percentage, name) {
    let circle = document.getElementById('progress-' + name);
    if (!circle) return;
    let circumference = circle.r.baseVal.value * 2 * Math.PI;
    let offset = circumference - (percentage / 100 * 0.7) * circumference;

    circle.style.strokeDasharray = [circumference, circumference];
    circle.style.strokeDashoffset = offset;

    if (name === 'fuel') {
        document.getElementById('progress-fuel').style.stroke = percentage > 30 ? '#ffffff' : percentage > 15 ? '#f39c12' : '#a40000';
    }
}

function setGauge(percentage, name, show) {
    if (percentage === undefined) return;
    let gauge = document.getElementById(name);
    if (gauge === undefined) return;
    if (show !== undefined) {
        document.getElementById(name).style.display = show ? 'block' : 'none';
    }
    percentage = Math.min(100, Math.max(0, percentage));

    setGaugeProgress(percentage, name);
}

function setSpeedProgress(speedometerFraction) {
    if (speedometerFraction === undefined) return;
    if (speedometerFraction > 100) speedometerFraction = 100;
    let circle = document.getElementById('progress-speed');
    if (circle === undefined) return;
    let circumference = circle.r.baseVal.value * 2 * Math.PI;
    //let offset = circumference - (speedometerFraction / 100 * 0.7) * circumference;
    //
    let strokeDasharray = ((250 / 360) * speedometerFraction) * circumference;

    circle.style.strokeDasharray = [strokeDasharray, circumference - strokeDasharray];
    //circle.style.strokeDashoffset = offset;
}

function setCompass(show, heading, street, zone) {
    if (show) document.getElementsByClassName("compass-hud")[0].style.opacity = show ? 1 : 0;
    if (heading) document.getElementById('azimuth').innerHTML = heading;
    if (street) document.getElementById('street').innerHTML = street;
    if (zone) document.getElementById('zone').innerHTML = zone;
}

function setDashboardLight(data) {
    if (data.indicatorL !== undefined) {
        if (data.indicatorL) {
            document.getElementById('indicatorL').classList.add('indicator-active');
        } else {
            document.getElementById('indicatorL').classList.remove('indicator-active');
        }
    }
    if (data.indicatorR !== undefined) {
        if (data.indicatorR) {
            document.getElementById('indicatorR').classList.add('indicator-active');
        } else {
            document.getElementById('indicatorR').classList.remove('indicator-active');
        }
    }
    if (data.lowbeam !== undefined) {
        document.getElementById('lowbeam').style.fill = data.lowbeam && '#0984e3' || '';
        document.getElementById('lowbeam').style.opacity = data.lowbeam && '1.0' || '0.2';
        if (data.lowbeam && !data.highbeam) {
            data.highbeam = true;
        }
    }
    if (data.highbeam !== undefined) {
        document.getElementById('highbeam').style.fill = data.highbeam && '#2ecc71' || '';
        document.getElementById('highbeam').style.opacity = data.highbeam && '1.0' || '0.2';
    }
}
