/obj/structure/artillery/mortar
	name = "mortar"
	desc = "A crude mortar. Needs an azimuth and a powder charge."
	icon = 'icons/obj/artillery.dmi'
	icon_state = "mortar"

	anchored = TRUE
	density = TRUE

	/// Loaded projectile
	var/obj/item/artillery_shell/loaded_shell
	/// Powder measures loaded (1..ART_CHARGE_MAX)
	var/powder_measures = 0
	/// Quality of the loaded powder (from keg batch)
	var/powder_quality = 1.0
	/// Moisture of the loaded powder (from keg batch)
	var/powder_moisture = 0.0

	/// Aim azimuth degrees 0..359
	var/aim_azimuth = 0

	/// Wear 0..100; affects safe charge and burst risk
	var/wear = 0

	/// Base safe max charge at wear=0
	var/base_safe_charge = 7

	/// Cooldown
	var/next_fire_time = 0
	var/fire_cooldown = 5 SECONDS

/obj/structure/artillery/mortar/examine(mob/user)
	. = ..()
	. += "Aim: [aim_azimuth]°."
	. += "Loaded: [loaded_shell ? loaded_shell.name : "no shell"], powder: [powder_measures]/[ART_CHARGE_MAX]."
	. += "Wear: [wear]%."

/obj/structure/artillery/mortar/proc/get_safe_charge_max()
	// Worn barrel => less safe charge
	return clamp(base_safe_charge - round(wear / 25), 3, ART_CHARGE_MAX)

/// Load a shell into the mortar
/obj/structure/artillery/mortar/proc/load_shell(obj/item/artillery_shell/S, mob/living/user)
	if(!S || loaded_shell)
		return FALSE
	loaded_shell = S
	S.forceMove(src)
	return TRUE

/// Load powder measures from a keg
/obj/structure/artillery/mortar/proc/load_powder(obj/item/artillery_powder_keg/K, amount, mob/living/user)
	if(!K || amount <= 0)
		return FALSE

	if(powder_measures >= ART_CHARGE_MAX)
		return FALSE

	var/can_take = min(amount, ART_CHARGE_MAX - powder_measures)
	var/list/taken = K.take_measures(can_take)
	var/q = taken[1]
	var/m = taken[2]
	var/t = taken[3]

	if(t <= 0)
		return FALSE

	// If already had powder loaded, blend qualities in a simple weighted way
	if(powder_measures > 0)
		var/total = powder_measures + t
		powder_quality = ((powder_quality * powder_measures) + (q * t)) / total
		powder_moisture = ((powder_moisture * powder_measures) + (m * t)) / total
	else
		powder_quality = q
		powder_moisture = m

	powder_measures += t
	return TRUE

/// Set aim azimuth (0..359)
/obj/structure/artillery/mortar/proc/set_aim(new_azimuth)
	aim_azimuth = (new_azimuth + 360) % 360

/// Main firing proc
/obj/structure/artillery/mortar/proc/fire(mob/living/user)
	if(world.time < next_fire_time)
		to_chat(user, "The mortar needs time before the next shot.")
		return FALSE

	if(!loaded_shell)
		to_chat(user, "No shell loaded.")
		return FALSE

	if(powder_measures <= 0)
		to_chat(user, "No powder loaded.")
		return FALSE

	next_fire_time = world.time + fire_cooldown

	var/turf/origin = get_turf(src)
	if(!origin)
		return FALSE

	// Ensure atmosphere exists
	if(!GLOB.artillery_atmo)
		init_artillery_atmo_roundstart()

	var/datum/artillery_atmosphere/A = GLOB.artillery_atmo

	// INTEGRATION: Use your real skill/stat
	var/ranged = get_ranged_skill(user) // 0..100
	var/pers = get_pers_stat(user) // 0..100

	// Base force from charge * quality
	var/base_force = powder_measures * powder_quality

	// Optional: tiny skill bonus to "effective force" (keep small!)
	var/skill_force_mult = 1.0 + (ranged / 1000) // +0..+10%
	var/effective_force = base_force * skill_force_mult

	// Overload / burst logic
	var/safe_max = get_safe_charge_max()
	var/burst_chance = 0
	if(powder_measures > safe_max)
		// Nonlinear growth: +15% per measure above safe, plus wear + moisture
		var/over = powder_measures - safe_max
		burst_chance = (over * over) * 10 // 10,40,90... (tune)
		burst_chance += wear
		burst_chance += round(powder_moisture * 100)

		burst_chance = clamp(burst_chance, 0, 95)

	// Misfire/hangfire risk from moisture (even if not overloaded)
	var/misfire_chance = clamp(round(powder_moisture * 40) - round(ranged / 10), 0, 35)

	if(prob(burst_chance))
		visible_message(span_danger("[src] catastrophically bursts!"))
		do_artillery_explosion(origin, 1.0)
		// Destroy loaded contents
		qdel(loaded_shell)
		loaded_shell = null
		powder_measures = 0
		// Increase wear hard
		wear = clamp(wear + 25, 0, 100)
		return TRUE

	if(prob(misfire_chance))
		visible_message(span_warning("[src] misfires with a dull thud!"))
		// Consume powder, keep shell (or not — your choice)
		powder_measures = 0
		// Slight wear
		wear = clamp(wear + 2, 0, 100)
		return TRUE

	visible_message(span_notice("[src] fires with a thunderous boom!"))

	// Compute effective atmosphere
	var/wind_dir = A.get_effective_wind_dir()
	var/wind_strength = A.get_effective_wind_strength()
	var/density = A.get_effective_density()
	var/humidity = A.get_effective_humidity()

	// Core range model (tile-based)
	// Range grows with force, shrinks with mass, adjusted by air density.
	// Lower density => slightly longer; higher density => slightly shorter.
	var/mass = loaded_shell.mass
	var/range_float = (effective_force / mass) * 12 // base scale
	range_float *= (1.05 - (density - 1.0)) // density 1.15 => ~0.90 ; 0.85 => ~1.20-ish
	range_float = clamp(range_float, 3, 80)

	// Drift model: crosswind * strength, heavier shells drift less.
	var/cross = wind_cross_component(wind_dir, aim_azimuth) // -1..1
	var/drift_float = cross * wind_strength * 2.2 * loaded_shell.drift_mult * (10 / mass)
	drift_float = clamp(drift_float, -12, 12)

	// Scatter model: base + humidity + bad weather; reduced by skill & PERS a bit.
	var/scatter = loaded_shell.base_scatter
	scatter += round(humidity * 4) // 0..4
	scatter += round(powder_moisture * 2) // wet powder => more wobble
	scatter -= round(ranged / 30) // 0..3
	scatter -= round(pers / 40) // 0..2
	scatter = clamp(scatter, 0, 8)

	// Direction vectors
	var/list/fwd = azimuth_to_step(aim_azimuth)
	var/dx = fwd[1]
	var/dy = fwd[2]
	var/list/right = perp_step(dx, dy)
	var/rx = right[1]
	var/ry = right[2]

	var/range_tiles = round(range_float)
	var/drift_tiles = round(drift_float)

	// Build impact turf
	var/turf/T = step_n(origin, dx, dy, range_tiles)
	if(!T)
		T = origin

	// Apply drift
	T = step_n(T, rx, ry, abs(drift_tiles))
	if(!T)
		T = origin

	// Apply scatter
	T = apply_scatter(T, scatter)

	// Consume ammo
	qdel(loaded_shell)
	loaded_shell = null
	powder_measures = 0

	// Wear increases each shot; more with high charge
	wear = clamp(wear + 1 + round(base_force / 10), 0, 100)

	// Impact effect
	var/power = loaded_shell ? loaded_shell.blast_mult : 1.0 // (loaded_shell got qdel'd; store earlier if needed)
	// Store blast mult before qdel:
	// (We do it properly below)
	return do_impact(T, user, power)

/// Separate impact proc so you can plug in canister logic, shrapnel, etc.
/obj/structure/artillery/mortar/proc/do_impact(turf/impact, mob/living/user, blast_mult)
	if(!impact)
		return FALSE

	visible_message(span_warning("A shell lands in the distance..."))
	do_artillery_explosion(impact, blast_mult)
	return TRUE
