// Completely New HUD Implementation
// Modern, minimalist design without progress bars

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
	  thirst: 100
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
	
	// Vehicle components
	vehicleDisplay: document.getElementById('vehicle-display'),
	speedValue: document.getElementById('speed-value'),
	gearValue: document.getElementById('gear-value'),
	rpmValue: document.getElementById('rpm-value'),
	fuelGauge: document.getElementById('fuel-gauge'),
	fuelValue: document.getElementById('fuel-value'),
	damageGauge: document.getElementById('damage-gauge'),
	damageValue: document.getElementById('damage-value'),
	
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
	  components.armorIcon.style.opacity = state.player.armor > 0 ? '1' : '0.5';
	}
	
	if (components.hungerValue) {
	  components.hungerValue.textContent = Math.round(state.player.hunger);
	  components.hungerIcon.classList.toggle('low', state.player.hunger < 25);
	}
	
	if (components.thirstValue) {
	  components.thirstValue.textContent = Math.round(state.player.thirst);
	  components.thirstIcon.classList.toggle('low', state.player.thirst < 25);
	}
	
	// Update vehicle display if in vehicle
	if (state.vehicle.speed !== undefined) {
	  if (components.speedValue) {
		components.speedValue.textContent = Math.round(state.vehicle.speed);
	  }
	  
	  if (components.gearValue) {
		components.gearValue.textContent = state.vehicle.gear;
	  }
	  
	  if (components.rpmValue) {
		// Format RPM value to be more readable (e.g., "3.5" instead of "3500")
		const rpmFormatted = (state.vehicle.rpm / 1000).toFixed(1);
		components.rpmValue.textContent = rpmFormatted;
	  }
	  
	  if (components.fuelValue && components.fuelGauge) {
		components.fuelValue.textContent = Math.round(state.vehicle.fuel);
		components.fuelGauge.classList.toggle('low', state.vehicle.fuel <= 20);
	  }
	  
	  if (components.damageValue && components.damageGauge) {
		components.damageValue.textContent = Math.round(state.vehicle.damage);
		components.damageGauge.classList.toggle('low', state.vehicle.damage <= 35);
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
	  // Only show location if in vehicle or street display is enabled
	  if ((state.vehicle.speed !== undefined || state.settings.streetHUDVisible) && state.settings.visible) {
		if (components.timeValue) components.timeValue.textContent = state.location.time || '00:00';
		if (components.directionValue) components.directionValue.textContent = state.location.compass || 'N';
		if (components.streetValue) components.streetValue.textContent = state.location.street || 'Unknown';
		if (components.postalValue) components.postalValue.textContent = state.location.postal || '000';
		
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
		// Update player stats
		state.player.health = data.health || 0;
		state.player.armor = data.armor || 0;
		state.player.hunger = data.hunger || 0;
		state.player.thirst = data.thirst || 0;
		state.settings.visible = data.show !== false;
		
		updateHUD();
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
				state.location.time = info.time || '';
			  }
			} else {
			  // Out of vehicle
			  state.vehicle.speed = undefined;
			  
			  // If streets display is enabled
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
		
	  case 'updatePosition':
		// Update minimap position if needed
		if (components.locationDisplay) {
		  // We can keep the location centered or adjust based on minimap position
		  // components.locationDisplay.style.left = `${data.minimapX + (data.minimapWidth / 2)}px`;
		}
		break;
	}
  });
  
  // Initialize HUD on page load
  document.addEventListener('DOMContentLoaded', function() {
	console.log('Completely New HUD initialized');
	updateHUD();
  });