// Modern HUD Implementation
// Matching scoreboard.css colors and redesigned layout

let state = {
	vehicle: {
	  speed: 0,
	  rpm: 0,
	  gear: 'N',
	  fuel: 100,
	  damage: 100,
	  cruise: false,
	  seatbelt: false,
	  lights: 'off',
	  signals: 'off',
	  haveBelt: true
	},
	player: {
	  health: 100,
	  armor: 0,
	  hunger: 100,
	  thirst: 100,
	  stamina: 100,
	  oxygen: 100,
	  isUnderwater: false
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
	}
  };
  
  // Animation utilities
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
	}
  };
  
  // UI Components
const components = {
	// Player status
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
	
	// Vehicle components
	vehicleDisplay: document.getElementById('vehicle-display'),
	speedValue: document.getElementById('speed-value'),
	gearValue: document.getElementById('gear-value'),
	
	// Progress bars for gauges
	rpmProgress: document.getElementById('rpm-progress'),
	fuelProgress: document.getElementById('fuel-progress'),
	damageProgress: document.getElementById('damage-progress'),
	
	// Indicators
	signalLeft: document.getElementById('signal-left'),
	signalRight: document.getElementById('signal-right'),
	lightsIndicator: document.getElementById('lights-indicator'),
	seatbeltIndicator: document.getElementById('seatbelt-indicator'),
	cruiseIndicator: document.getElementById('cruise-indicator'),
	
	// Location display
	locationDisplay: document.getElementById('location-display'),
	timeValue: document.getElementById('time-value'),
	directionValue: document.getElementById('direction-value'),
	streetValue: document.getElementById('street-value'),
	postalValue: document.getElementById('postal-value')
};
  
  // Update HUD with current state
  function updateHUD() {
	// Update player status values
	if (components.healthValue) {
	  components.healthValue.textContent = Math.round(state.player.health);
	  components.healthIcon.classList.toggle('low', state.player.health < 25);
	}
	
	if (components.armorValue) {
	  components.armorValue.textContent = Math.round(state.player.armor);
	  // Hide armor when it's 0
	  components.armorIcon.style.display = state.player.armor > 0 ? 'flex' : 'none';
	}
	
	if (components.hungerValue) {
	  components.hungerValue.textContent = Math.round(state.player.hunger);
	  components.hungerIcon.classList.toggle('low', state.player.hunger < 25);
	}
	
	if (components.thirstValue) {
	  components.thirstValue.textContent = Math.round(state.player.thirst);
	  components.thirstIcon.classList.toggle('low', state.player.thirst < 25);
	}
	
	// Update stamina - show only when less than 100%
	if (components.staminaValue) {
	  components.staminaValue.textContent = Math.round(state.player.stamina);
	  components.staminaIcon.style.display = state.player.stamina < 100 ? 'flex' : 'none';
	  components.staminaIcon.classList.toggle('low', state.player.stamina < 25);
	}
	
	// Update oxygen - show only when underwater (explicitly checked)
	if (components.oxygenValue) {
	  components.oxygenValue.textContent = Math.round(state.player.oxygen);
	  components.oxygenIcon.style.display = state.player.isUnderwater ? 'flex' : 'none';
	  components.oxygenIcon.classList.toggle('low', state.player.oxygen < 25);
	}
	
	if (components.timeValue) {
	  components.timeValue.textContent = state.location.time;
	}
	
	// Update vehicle display if in vehicle
	if (state.vehicle.speed !== undefined) {
	  if (components.speedValue) {
		components.speedValue.textContent = Math.round(state.vehicle.speed);
	  }
	  
	  if (components.gearValue) {
		components.gearValue.textContent = state.vehicle.gear;
	  }
	  
	  // Update progress bars instead of text values
	  if (components.rpmProgress) {
		// Calculate RPM as percentage (0-10000 range)
		const rpmPercent = (state.vehicle.rpm / 10000) * 100;
		components.rpmProgress.style.width = `${rpmPercent}%`;
		components.rpmProgress.classList.toggle('high', rpmPercent > 80);
	  }
	  
	  if (components.fuelProgress) {
		components.fuelProgress.style.width = `${state.vehicle.fuel}%`;
		components.fuelProgress.classList.toggle('low', state.vehicle.fuel <= 20);
	  }
	  
	  if (components.damageProgress) {
		components.damageProgress.style.width = `${state.vehicle.damage}%`;
		components.damageProgress.classList.toggle('low', state.vehicle.damage <= 35);
	  }
	  
	  // Update indicators
	  if (components.cruiseIndicator) {
		components.cruiseIndicator.classList.toggle('active', state.vehicle.cruise === 'on');
	  }
	  
	  if (components.seatbeltIndicator) {
		components.seatbeltIndicator.classList.toggle('active', state.vehicle.seatbelt);
		components.seatbeltIndicator.style.display = state.vehicle.haveBelt ? 'flex' : 'none';
	  }
	  
	  if (components.lightsIndicator) {
		components.lightsIndicator.classList.remove('normal', 'high');
		
		if (state.vehicle.lights === 'normal' || state.vehicle.lights === 'high') {
		  components.lightsIndicator.classList.add(state.vehicle.lights);
		}
	  }
	  
	  // Update turn signals
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
	  
	  // Show vehicle display
	  if (components.vehicleDisplay) {
		animations.fadeIn(components.vehicleDisplay);
	  }
	} else {
	  // Hide vehicle display when not in vehicle
	  if (components.vehicleDisplay) {
		animations.fadeOut(components.vehicleDisplay);
	  }
	}
	
	// Update location display
	if (components.locationDisplay) {
	  if (state.settings.visible) {
		if (components.directionValue) components.directionValue.textContent = state.location.compass || 'N';
		if (components.streetValue) components.streetValue.textContent = state.location.street || 'Unknown';
		if (components.postalValue) components.postalValue.textContent = state.location.postal || '000';
		if (components.timeValue) components.timeValue.textContent = state.location.time;
		
		animations.fadeIn(components.locationDisplay);
	  } else {
		animations.fadeOut(components.locationDisplay);
	  }
	}
  }
  
  // Handle incoming messages from the game
  window.addEventListener('message', function(event) {
	const data = event.data;
	
	if (!data.name) return;
	
	switch (data.name) {
		case 'hudTick':
		state.player.health = data.health || 0;
		state.player.armor = data.armor || 0;
		state.player.hunger = data.hunger || 0;
		state.player.thirst = data.thirst || 0;
		state.player.stamina = data.stamina || 100;
		
		if (data.oxygen !== undefined) {
			state.player.oxygen = data.oxygen;
		}
		state.player.isUnderwater = data.isUnderwater || false;
		
		state.settings.visible = data.show !== false;
		
		fetch('https://hcyk_hud/getGameTime', {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json; charset=UTF-8',
			},
			body: JSON.stringify({ time: state.location.time })
		})
			.then(response => response.json())
			.then(timeData => {
				state.location.time = timeData.time;
				updateHUD();
			});
		
		break;
		
	  case 'updateCarhud':
		if (data.info) {
		  const info = data.info;
		  
		  if (info.updateVehicle) {
			if (info.status) {
			  // In vehicle
			  state.vehicle.speed = info.speed || 0;
			  state.vehicle.rpm = info.rpm || 0;
			  state.vehicle.gear = info.gear || 'N';
			  state.vehicle.fuel = info.fuel || 0;
			  state.vehicle.signals = info.signals || 'off';
			  state.vehicle.cruise = info.cruiser || 'off';
			  
			  // Update dashboard info
			  if (info.dash) {
				state.vehicle.seatbelt = info.dash.seatbelt || false;
				state.vehicle.haveBelt = info.dash.haveBelt !== false;
				state.vehicle.lights = info.dash.lights || 'off';
				state.vehicle.damage = info.dash.damage || 100;
			  }
			  
			  // Update location
			  if (info.location) {
				state.location.street = info.location;
				state.location.compass = info.compass || '';
				state.location.postal = info.postal || '';
			  }
			  
			  if (info.time) {
				state.location.time = info.time;
			  }
			  
			  // Update speedUnit if provided
			  if (info.config && info.config.speedUnit) {
				state.settings.speedUnit = info.config.speedUnit;
				document.querySelector('.speed-unit').textContent = info.config.speedUnit;
			  }
			} else {
			  state.vehicle.speed = undefined;
			  state.settings.streetHUDVisible = info.streets || false;
			  
			  if (info.streets) {
				state.location.street = info.location || '';
				state.location.compass = info.compass || '';
				state.location.postal = info.postal || '';
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
	}
  });
  
  document.addEventListener('DOMContentLoaded', function() {
	updateHUD();
  });
