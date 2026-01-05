// ================================================
// artillery_shells.dm
// ================================================

/obj/item/artillery_shell
	name = "mortar shell"
	desc = "A heavy projectile."
	icon = 'modular_twilight_axis/artillery/icons/artillery.dmi'
	icon_state = "shell"

	var/mass = 10.0
	var/base_scatter = 2
	var/blast_mult = 1.0
	var/drift_mult = 1.0

	/// chem payload
	var/max_chem_volume = 50
	var/spillable = TRUE // lets you access contents
	/// optional: forbid spraying certain reagents, like your spell does
	var/list/forbidden_reagents = list(/datum/reagent/consumable/ethanol/beer/emberwine)

	var/mass_variance = 0.08      // +/- 8%
	var/scatter_variance = 1      // +/- 1
	var/blast_variance = 0.10     // +/- 10%
	var/drift_variance = 0.10     // +/- 10%

/// give shells reagents like a container
/obj/item/artillery_shell/Initialize(mapload)
	. = ..()
	if(max_chem_volume > 0)
		create_reagents(max_chem_volume)

	// --- per-shell randomization ---
	mass = max(0.1, mass * (1 + (rand(-round(mass_variance*100), round(mass_variance*100)) / 100)))
	base_scatter = max(0, base_scatter + rand(-scatter_variance, scatter_variance))
	blast_mult = max(0.1, blast_mult * (1 + (rand(-round(blast_variance*100), round(blast_variance*100)) / 100)))
	drift_mult = max(0.1, drift_mult * (1 + (rand(-round(drift_variance*100), round(drift_variance*100)) / 100)))

/obj/item/artillery_shell/examine(mob/user)
	. = ..()
	. += "Mass: [round(mass, 0.1)]."
	. += "Scatter: [base_scatter]."
	. += "Blast multiplier: [round(blast_mult, 0.01)]."
	. += "Drift multiplier: [round(drift_mult, 0.01)]."

	if(reagents)
		if(reagents.total_volume > 0)
			. += "Payload: [reagents.total_volume]/[max_chem_volume]."
		else
			. += "Payload: empty."

/// Quick helper: check forbidden reagents before we aerosolize
/obj/item/artillery_shell/proc/has_forbidden_reagents()
	if(!reagents || !length(forbidden_reagents))
		return FALSE
	for(var/path in forbidden_reagents)
		if(reagents.has_reagent(path))
			return TRUE
	return FALSE

/// Called on impact BEFORE shell is deleted
/obj/item/artillery_shell/proc/release_chem_cloud(turf/T)
	if(!T || !reagents)
		return FALSE
	if(reagents.total_volume <= 0)
		return FALSE

	if(has_forbidden_reagents())
		// Optional: just refuse to aerosolize forbidden payloads
		return FALSE

	var/datum/effect_system/smoke_spread/chem/smoke = new
	// Same style as aerosolize: intensity 1, direct turf, no silent?
	smoke.set_up(reagents, 1, T, FALSE)
	smoke.start()

	// Clear payload after starting
	reagents.clear_reagents()
	return TRUE

/obj/item/artillery_shell/heavy
	name = "heavy iron shell"
	//icon_state = "shell_heavy"
	mass = 16.0
	base_scatter = 1
	blast_mult = 1.25
	drift_mult = 0.7
	max_chem_volume = 30 // heavy = less internal volume if you want

/obj/item/artillery_shell/light
	name = "light stone shell"
	//icon_state = "shell_light"
	mass = 8.0
	base_scatter = 3
	blast_mult = 0.85
	drift_mult = 1.2
	max_chem_volume = 60

/obj/item/artillery_shell/canister
	name = "canister shot"
	//icon_state = "shell_canister"
	mass = 9.0
	base_scatter = 4
	blast_mult = 0.6
	drift_mult = 1.1
	max_chem_volume = 40
