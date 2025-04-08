let state = {
  vehicle: {
    speed: 0,
    rpm: 0,
    gear: 'N',
    fuel: 100,
    damage: 100,
    cruise: 'off',
    seatbelt: false,
    lights: 'off',
    signals: 'off',
    haveBelt: true,
    sirenState: 0,
    isEmergency: false,
    skidding: false // Add this new property
  },
  player: {
    health: 100,
    armor: 0,
    hunger: 100,
    thirst: 100,
    stamina: 100,
    oxygen: 100,
    isUnderwater: false,
    isTalking: false,
    voiceRange: 66,
    isTalkingOnRadio: false
  },
  location: {
    street: '',
    postal: '',
    compass: '',
    time: ''
  },
  settings: {
    speedUnit: 'MPH',
    visible: true,
    streetHUDVisible: false
  },
  effects: {
    oxygen: false,
    hunger: false,
    thirst: false
  }
};

const animations = {
  fadeIn: (element, duration = 300) => {
    if (!element) return;
    element.style.transition = `opacity ${duration}ms ease-in-out, transform ${duration}ms ease-in-out`;
    element.style.opacity = '1';
    element.style.transform = 'translateY(0)';
    element.classList.remove('hidden');
  },
  
  fadeOut: (element, duration = 300) => {
    if (!element) return;
    element.style.transition = `opacity ${duration}ms ease-in-out, transform ${duration}ms ease-in-out`;
    element.style.opacity = '0';
    element.style.transform = 'translateY(10px)';
    element.classList.add('hidden');
  },
  toggleStatusIcon: (element, show, duration = 300) => {
    if (!element) return;
    
    // Přidána ochrana proti opakovaným voláním se stejným stavem
    if (show && element.style.display === 'flex' && !element.classList.contains('disappearing')) return;
    if (!show && (element.style.display === 'none' || element.classList.contains('disappearing'))) return;
    
    if (show) {
      element.classList.remove('disappearing');
      element.style.display = 'flex';
      void element.offsetWidth; // Force reflow
      element.classList.add('appearing');
      
      setTimeout(() => {
        element.classList.remove('show-hide');
      }, duration);
    } else {
      element.classList.remove('appearing');
      element.classList.add('disappearing');
      
      setTimeout(() => {
        if (element.classList.contains('disappearing')) {
          element.style.display = 'none';
          element.classList.remove('disappearing');
        }
      }, duration);
    }
  }
};

// Aktualizace komponent
const components = {
  // Existující komponenty
  healthIcon: document.getElementById('health-icon'),
  healthValue: document.getElementById('health-value'),
  armorIcon: document.getElementById('armor-icon'),
  armorValue: document.getElementById('armor-value'),
  hungerIcon: document.getElementById('hunger-icon'),
  hungerValue: document.getElementById('hunger-value'),
  thirstIcon: document.getElementById('thirst-icon'),
  thirstValue: document.getElementById('thirst-value'),
  staminaIcon: document.getElementById('stamina-icon'),
  staminaValue: document.getElementById('stamina-value'),
  oxygenIcon: document.getElementById('oxygen-icon'),
  oxygenValue: document.getElementById('oxygen-value'),
  microphoneIcon: document.getElementById('microphone-icon'),
  microphoneValue: document.getElementById('microphone-value'),
  
  // Opravené komponenty se stejnou strukturou jako ostatní
  radioIcon: document.getElementById('radio-icon'),
  radioValue: document.getElementById('radio-value'),
  
  // Zbytek existujících komponent...
  vehicleDisplay: document.getElementById('vehicle-display'),
  speedValue: document.getElementById('speed-value'),
  gearValue: document.getElementById('gear-value'),
  
  rpmProgress: document.getElementById('rpm-progress'),
  fuelProgress: document.getElementById('fuel-progress'),
  damageProgress: document.getElementById('damage-progress'),
  
  rpmValue: document.getElementById('rpm-value'),
  fuelValue: document.getElementById('fuel-value'),
  damageValue: document.getElementById('damage-value'),
  
  signalLeft: document.getElementById('signal-left'),
  signalRight: document.getElementById('signal-right'),
  lightsIndicator: document.getElementById('lights-indicator'),
  seatbeltIndicator: document.getElementById('seatbelt-indicator'),
  cruiseIndicator: document.getElementById('cruise-indicator'),
  
  locationDisplay: document.getElementById('location-display'),
  timeValue: document.getElementById('time-value'),
  directionValue: document.getElementById('direction-value'),
  streetValue: document.getElementById('street-value'),
  postalValue: document.getElementById('postal-value'),
  
  sirenIndicator: document.getElementById('siren-indicator')
};

// Create cinematic bars
function createCinematicBars() {
  // Create top bar
  const topBar = document.createElement('div');
  topBar.className = 'cinematic-bars cinematic-top';
  document.body.appendChild(topBar);
  
  // Create bottom bar
  const bottomBar = document.createElement('div');
  bottomBar.className = 'cinematic-bars cinematic-bottom';
  document.body.appendChild(bottomBar);
  
  // Add to components if needed
  components.cinematicTopBar = topBar;
  components.cinematicBottomBar = bottomBar;
}

// Create screen effects elements
function createScreenEffects() {
  // Create oxygen effect
  const oxygenEffect = document.createElement('div');
  oxygenEffect.className = 'oxygen-effect';
  oxygenEffect.id = 'oxygen-effect';
  document.body.appendChild(oxygenEffect);
  
  // Create hunger effect
  const hungerEffect = document.createElement('div');
  hungerEffect.className = 'hunger-effect';
  hungerEffect.id = 'hunger-effect';
  document.body.appendChild(hungerEffect);
  
  // Create thirst effect
  const thirstEffect = document.createElement('div');
  thirstEffect.className = 'thirst-effect';
  thirstEffect.id = 'thirst-effect';
  document.body.appendChild(thirstEffect);
  
  // Add cinematic bars
  createCinematicBars();
  
  // Add to components
  components.oxygenEffect = oxygenEffect;
  components.hungerEffect = hungerEffect;
  components.thirstEffect = thirstEffect;
}

// Update the updateHUD function to respect cinematic mode

function updateHUD() {
  // Check if cinematic mode is active - don't update UI elements if it is
  if (document.body.classList.contains('cinematic-active')) {
    return;
  }
  
  if (components.healthValue) {
    components.healthValue.textContent = Math.round(state.player.health);
    components.healthIcon.classList.toggle('low', state.player.health < 25);
  }
  
  if (components.armorValue) {
    components.armorValue.textContent = Math.round(state.player.armor);
    animations.toggleStatusIcon(components.armorIcon, state.player.armor > 0);
  }
  
  if (components.hungerValue) {
    components.hungerValue.textContent = Math.round(state.player.hunger);
    components.hungerIcon.classList.toggle('low', state.player.hunger < 25);
    
    // Toggle hunger effect
    if (components.hungerEffect) {
      components.hungerEffect.classList.toggle('active', state.player.hunger < 15);
    }
  }
  
  if (components.thirstValue) {
    components.thirstValue.textContent = Math.round(state.player.thirst);
    components.thirstIcon.classList.toggle('low', state.player.thirst < 25);
    
    // Toggle thirst effect
    if (components.thirstEffect) {
      components.thirstEffect.classList.toggle('active', state.player.thirst < 15);
    }
  }
  
  if (components.staminaValue) {
    components.staminaValue.textContent = Math.round(state.player.stamina);
    animations.toggleStatusIcon(components.staminaIcon, state.player.stamina < 100);
    components.staminaIcon.classList.toggle('low', state.player.stamina < 25);
  }
  
  if (components.oxygenValue) {
    components.oxygenValue.textContent = Math.round(state.player.oxygen);
    animations.toggleStatusIcon(components.oxygenIcon, state.player.isUnderwater);
    components.oxygenIcon.classList.toggle('low', state.player.oxygen < 25);
    
    // Toggle oxygen effect
    if (components.oxygenEffect) {
      components.oxygenEffect.classList.toggle('active', state.player.isUnderwater && state.player.oxygen < 25);
    }
  }
  
  if (components.microphoneIcon) {
    animations.toggleStatusIcon(components.microphoneIcon, state.player.isTalking);
    components.microphoneIcon.classList.toggle('active', state.player.isTalking);
    
    if (components.microphoneValue) {
      components.microphoneValue.textContent = state.player.voiceRange;
    }
  }
  
  if (components.timeValue) {
    components.timeValue.textContent = state.location.time;
  }
  
  if (state.vehicle.speed !== undefined) {
    if (components.speedValue) {
      components.speedValue.textContent = Math.round(state.vehicle.speed);
    }
    
    if (components.gearValue) {
      components.gearValue.textContent = state.vehicle.gear;
    }
    
    if (components.rpmProgress) {
      const rpmPercent = (state.vehicle.rpm / 10000) * 100;
      components.rpmProgress.style.width = `${rpmPercent}%`;
      components.rpmProgress.classList.toggle('high', rpmPercent > 80);
      
      if (components.rpmValue) {
        components.rpmValue.textContent = state.vehicle.rpm.toLocaleString();
        components.rpmValue.classList.toggle('high', rpmPercent > 80);
      }
    }
    
    if (components.fuelProgress) {
      components.fuelProgress.style.width = `${state.vehicle.fuel}%`;
      components.fuelProgress.classList.toggle('low', state.vehicle.fuel <= 20);
      
      if (components.fuelValue) {
        components.fuelValue.textContent = "(" + Math.round(state.vehicle.fuel) + "%)";
        components.fuelValue.classList.toggle('low', state.vehicle.fuel <= 20);
      }
    }
    
    if (components.damageProgress) {
      components.damageProgress.style.width = `${state.vehicle.damage}%`;
      components.damageProgress.classList.toggle('low', state.vehicle.damage <= 35);
      
      if (components.damageValue) {
        components.damageValue.textContent = "(" + Math.round(state.vehicle.damage) + "%)";
        components.damageValue.classList.toggle('low', state.vehicle.damage <= 35);
      }
    }
    
    if (components.cruiseIndicator) {
      components.cruiseIndicator.classList.toggle('active', state.vehicle.cruise === 'on');
    }
    
    if (components.seatbeltIndicator) {
      components.seatbeltIndicator.classList.toggle('active', state.vehicle.seatbelt);
      // Vždy zobrazit, když je hráč ve vozidle, které má pásy
      components.seatbeltIndicator.style.display = state.vehicle.haveBelt ? 'flex' : 'none';
    }
    
    if (components.lightsIndicator) {
      components.lightsIndicator.classList.remove('normal', 'high');
      
      if (state.vehicle.lights === 'normal' || state.vehicle.lights === 'high') {
        components.lightsIndicator.classList.add(state.vehicle.lights);
      }
    }
    
    if (components.signalLeft && components.signalRight) {
      components.signalLeft.classList.remove('active', 'blinking');
      components.signalRight.classList.remove('active', 'blinking');
      
      switch (state.vehicle.signals) {
        case 'left':
          components.signalLeft.classList.add('active', 'blinking');
          break;
        case 'right':
          components.signalRight.classList.add('active', 'blinking');
          break;
        case 'both':
          components.signalLeft.classList.add('active', 'blinking');
          components.signalRight.classList.add('active', 'blinking');
          break;
      }
    }
    
    if (components.vehicleDisplay) {
      animations.fadeIn(components.vehicleDisplay);
    }
    
    const statusBox = document.querySelector('.status-box');
    if (statusBox) {
      statusBox.classList.add('in-vehicle');
    }
    
    // Show location display when in vehicle
    if (components.locationDisplay) {
      animations.fadeIn(components.locationDisplay);
    }
  } else {
    if (components.vehicleDisplay) {
      animations.fadeOut(components.vehicleDisplay);
    }
    
    const statusBox = document.querySelector('.status-box');
    if (statusBox) {
      statusBox.classList.remove('in-vehicle');
    }
    
    // Hide location display when not in vehicle unless streets are toggled on
    if (components.locationDisplay && !state.settings.streetHUDVisible) {
      animations.fadeOut(components.locationDisplay);
    }
  }
  
  if (components.locationDisplay) {
    if ((state.vehicle.speed !== undefined || state.settings.streetHUDVisible) && state.settings.visible) {
      if (components.directionValue) components.directionValue.textContent = state.location.compass || 'N';
      if (components.streetValue) components.streetValue.textContent = state.location.street || 'Unknown';
      if (components.postalValue) components.postalValue.textContent = state.location.postal || '000';
      if (components.timeValue) components.timeValue.textContent = state.location.time;
      
      animations.fadeIn(components.locationDisplay);
    } else {
      animations.fadeOut(components.locationDisplay);
    }
  }

  if (components.radioValue) {
    components.radioValue.textContent = state.player.radioChannel || '0';
    animations.toggleStatusIcon(components.radioIcon, state.player.radioChannel > 0);
  }
  
  // Aktualizace sirény - zobrazit pouze v emergency vozidlech
  if (components.sirenIndicator) {
    if (state.vehicle.isEmergency) {
      components.sirenIndicator.style.display = 'flex';
      components.sirenIndicator.classList.remove('siren-only', 'siren-with-sound');
      
      if (state.vehicle.sirenState === 1) {
        components.sirenIndicator.classList.add('siren-only');
      } else if (state.vehicle.sirenState >= 2) {
        components.sirenIndicator.classList.add('siren-with-sound');
      }
    } else {
      components.sirenIndicator.style.display = 'none';
    }
  }
}

window.addEventListener('message', function(event) {
  const data = event.data;
  
  if (!data.name) return;
  
  switch (data.name) {
    case 'hudTick':
      // Vždy aktualizujeme hodnoty, i když jsou stejné jako předchozí
      if (data.health !== undefined) state.player.health = data.health;
      if (data.armor !== undefined) state.player.armor = data.armor;
      if (data.hunger !== undefined) state.player.hunger = data.hunger;
      if (data.thirst !== undefined) state.player.thirst = data.thirst;
      if (data.stamina !== undefined) state.player.stamina = data.stamina;
      if (data.oxygen !== undefined) state.player.oxygen = data.oxygen;
      if (data.isUnderwater !== undefined) state.player.isUnderwater = data.isUnderwater;
      
      state.settings.visible = data.show !== false;
      
      // Force immediate update
      updateHUD();
      break;
      
    case 'updateCarhud':
      if (data.info) {
        const info = data.info;
        
        if (info.updateVehicle) {
          if (info.status) {
            state.vehicle.speed = info.speed || 0;
            state.vehicle.rpm = info.rpm || 0;
            state.vehicle.gear = info.gear || 'N';
            state.vehicle.fuel = info.fuel || 0;
            state.vehicle.signals = info.signals || 'off';
            state.vehicle.cruise = info.cruiser || 'off';
            state.vehicle.sirenState = info.sirenState || 0;
            state.vehicle.isEmergency = info.isEmergency || false;
            state.vehicle.skidding = info.skidding || false; // Add skidding state handling
            
            // Okamžitá aktualizace UI po změně stavu
            updateHUD();
            
            if (info.dash) {
              state.vehicle.seatbelt = info.dash.seatbelt || false;
              state.vehicle.haveBelt = info.dash.haveBelt !== false;
              state.vehicle.lights = info.dash.lights || 'off';
              state.vehicle.damage = info.dash.damage || 100;
            }
            
            if (info.location) {
              state.location.street = info.location;
              state.location.compass = info.compass || '';
              state.location.postal = info.postal || '';
            }
            
            if (info.time) {
              state.location.time = info.time;
            }
            
            if (info.config && info.config.speedUnit) {
              state.settings.speedUnit = info.config.speedUnit;
              const speedUnitElement = document.querySelector('.speed-unit');
              if (speedUnitElement) {
                speedUnitElement.textContent = info.config.speedUnit;
              }
            }
          } else {
            state.vehicle.speed = undefined;
            state.settings.streetHUDVisible = info.streets || false;
            
            if (info.streets) {
              state.location.street = info.location || '';
              state.location.compass = info.compass || '';
              state.location.postal = info.postal || '';
              state.location.time = info.time || '';
            }
          }
        }
        
        updateHUD();
      }
      break;
      
    case 'hideHud':
      state.settings.visible = data.show !== false;
      
      if (state.settings.visible) {
        document.body.style.opacity = '1';
      } else {
        document.body.style.opacity = '0';
      }
      
      updateHUD();
      break;
      
    case 'voiceState':
      state.player.isTalking = data.isTalking !== undefined ? data.isTalking : state.player.isTalking;
      
      if (data.voiceRange !== undefined) {
        state.player.voiceRange = data.voiceRange;
      }
      
      if (data.isTalkingOnRadio !== undefined) {
        state.player.isTalkingOnRadio = data.isTalkingOnRadio;
      }
      
      updateHUD();
      break;

    case 'bigmap':
      if (data.active) {
        const statusBox = document.querySelector('.status-box');
        if (statusBox) {
          statusBox.classList.add('bigmap-active');
        }
      } else {
        const statusBox = document.querySelector('.status-box');
        if (statusBox) {
          statusBox.classList.remove('bigmap-active');
        }
      }
      break;

    case 'cinematicMode':
      if (data.enabled) {
        document.body.classList.add('cinematic-active');
        // Hide radar using the existing NUI callback
        fetch('https://hcyk_hud/hideRadar', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: JSON.stringify({})
        });
      } else {
        document.body.classList.remove('cinematic-active');
        // Let the regular HUD update function handle showing elements again
        updateHUD();
      }
      break;

    case 'smoothControl':
      state.vehicle.smoothActive = data.active;
      
      const speedContainer = document.querySelector('.speed-info');
      if (speedContainer) {
        updateSpeedBoxClasses(speedContainer);
      }
      break;

    // Vylepšit zobrazení cruise control 
    case 'cruiseControl':
      state.vehicle.cruiseActive = data.active;
      
      const speedContainerCruise = document.querySelector('.speed-info');
      if (speedContainerCruise) {
        updateSpeedBoxClasses(speedContainerCruise);
      }
      break;

    case 'skiddingState':
      state.vehicle.skidding = data.isSkidding; // Add skidding state
      
      const speedContainerSkidding = document.querySelector('.speed-info');
      if (speedContainerSkidding) {
        updateSpeedBoxClasses(speedContainerSkidding);
      }
      break;
  }
});

// Vylepšená funkce pro aktualizaci stavů cruise/smooth/skidding

function updateSpeedBoxClasses(element) {
  // Nejprve odstraníme všechny třídy
  element.classList.remove('smooth-active', 'cruise-active', 'dual-active', 'skidding-active');
  
  // Poté přidáme odpovídající třídu podle stavů
  if (state.vehicle.smoothActive && state.vehicle.cruiseActive) {
    element.classList.add('dual-active');
  } else if (state.vehicle.smoothActive) {
    element.classList.add('smooth-active');
  } else if (state.vehicle.cruiseActive) {
    element.classList.add('cruise-active');
  }
  
  // Add skidding class
  element.classList.toggle('skidding-active', state.vehicle.skidding);
}

document.addEventListener('DOMContentLoaded', function() {
  createScreenEffects();
  updateHUD();
  
  // Inicializace stavů pro cruise a smooth
  state.vehicle.smoothActive = false;
  state.vehicle.cruiseActive = false;
  
  // Aplikovat případné persistentní stavy z Lua
  fetch('https://hcyk_hud/getUIData', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: JSON.stringify({ currentData: state })
  })
  .then(response => response.json())
  .then(uiData => {
    // Update time
    state.location.time = uiData.time;
    
    // Update control states
    if (uiData.controls) {
      state.vehicle.throttleControlActive = uiData.controls.smoothActive;
      state.vehicle.cruiseControlActive = uiData.controls.cruiseActive;
    }
    
    const speedContainer = document.querySelector('.speed-info');
    if (speedContainer) {
      updateSpeedBoxClasses(speedContainer);
    }
    
    updateHUD();
  })
  .catch(error => {
    console.error('Error fetching UI data:', error);
    updateHUD();
  });
  
  // Get initial UI data
  fetch('https://hcyk_hud/getUIData', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: JSON.stringify({})
  })
    .then(response => response.json())
    .then(uiData => {
      state.location.time = uiData.time;
      
      if (uiData.controls) {
        state.vehicle.throttleControlActive = uiData.controls.smoothActive;
        state.vehicle.cruiseControlActive = uiData.controls.cruiseActive;
      }
      
      updateHUD();
    })
    .catch(() => {
      updateHUD();
    });
});