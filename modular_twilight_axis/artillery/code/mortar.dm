// ================================================
// mortar.dm
// ================================================

/obj/structure/artillery/mortar
	name = "mortar"
	desc = "A crude mortar. Requires a shell, powder charge, and an azimuth."
	//icon = 'icons/obj/artillery.dmi'
	//icon_state = "mortar"

	anchored = FALSE
	density = TRUE
	// Pullable like a chest:
	// INTEGRATION: if your codebase has a proper flag/property, set it here.

	var/broken = FALSE

	// payload
	var/obj/item/artillery_shell/loaded_shell

	// aiming / charge
	var/aim_azimuth = 0

	var/powder_measures = 0
	var/powder_quality = 1.0
	var/powder_moisture = 0.0

	// durability
	var/wear = 0 // 0..100
	var/base_safe_charge = 7

/obj/structure/artillery/mortar/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/artillery_fcs)

/obj/structure/artillery/mortar/examine(mob/user)
	. = ..()
	. += "Aim: [aim_azimuth]°."
	. += "Loaded shell: [loaded_shell ? loaded_shell.name : "none"]."
	. += "Powder: [powder_measures]/[ART_CHARGE_MAX]. Wear: [wear]%."

/obj/structure/artillery/mortar/proc/get_safe_charge_max()
	// Worse barrel => less safe charge => easier burst
	return clamp(base_safe_charge - round(wear / 25), 3, ART_CHARGE_MAX)

/// Blend powder from keg into current charge
/obj/structure/artillery/mortar/proc/blend_powder(new_quality, new_moisture, added_measures)
	if(added_measures <= 0)
		return

	if(powder_measures > 0)
		var/total = powder_measures + added_measures
		powder_quality = ((powder_quality * powder_measures) + (new_quality * added_measures)) / total
		powder_moisture = ((powder_moisture * powder_measures) + (new_moisture * added_measures)) / total
	else
		powder_quality = new_quality
		powder_moisture = new_moisture

	powder_measures += added_measures
	powder_measures = clamp(powder_measures, 0, ART_CHARGE_MAX)

/// Shell loading by hand: click mortar with shell
/obj/structure/artillery/mortar/attackby(obj/item/I, mob/user, params)
	. = ..()
	if(broken)
		return

	if(istype(I, /obj/item/artillery_shell))
		if(loaded_shell)
			to_chat(user, span_warning("A shell is already loaded."))
			return
		loaded_shell = I
		I.forceMove(src)
		to_chat(user, span_notice("You load [I] into [src]."))
		return

/// Consume shot state after a successful impact
/obj/structure/artillery/mortar/proc/consume_shot(base_force)
	// charge affects wear
	wear = clamp(wear + 1 + round(base_force / 10), 0, 100)

	// consume powder
	powder_measures = 0

	// keep properties; or reset them—your call
	powder_quality = 1.0
	powder_moisture = 0.0

/// When misfire happens
/obj/structure/artillery/mortar/proc/apply_misfire(mob/user)
	// burn powder, keep shell (optional)
	powder_measures = 0
	wear = clamp(wear + 2, 0, 100)

/// When catastrophic burst happens (component is allowed to "damage mortar")
/obj/structure/artillery/mortar/proc/apply_catastrophic_burst(mob/user)
	var/turf/T = get_turf(src)
	do_artillery_explosion(T, 1.0)

	// Delete loaded shell, clear charge
	if(loaded_shell)
		qdel(loaded_shell)
		loaded_shell = null
	powder_measures = 0

	// Massive wear and potentially break
	wear = clamp(wear + 35, 0, 100)
	if(wear >= 100)
		break_mortar()

/// Break state (component can call this via apply_catastrophic_burst / future hooks)
/// You can also drop parts here.
/obj/structure/artillery/mortar/proc/break_mortar()
	broken = TRUE
	icon_state = "mortar_broken"
	desc = "A broken mortar. The barrel looks cracked."

/// Fire request (UI)
/// Component handles all math + risks
/obj/structure/artillery/mortar/proc/request_fire(mob/living/user)
	if(broken)
		to_chat(user, span_warning("It's broken."))
		return
	SEND_SIGNAL(src, COMSIG_ARTILLERY_FIRE, user)


/obj/structure/artillery/mortar_base
	name = "mortar base"
	desc = "A heavy base. Needs a barrel to assemble a mortar."
	//icon = 'icons/obj/artillery.dmi'
	//icon_state = "mortar_base"
	anchored = FALSE
	density = TRUE

	var/assemble_time = 4 SECONDS

/obj/item/mortar_barrel
	name = "mortar barrel"
	desc = "A heavy barrel used to assemble a mortar."
	//icon = 'icons/obj/artillery.dmi'
	//icon_state = "mortar_barrel"
	w_class = WEIGHT_CLASS_BULKY

/obj/structure/artillery/mortar_base/attackby(obj/item/I, mob/user, params)
	. = ..()
	if(!istype(I, /obj/item/mortar_barrel))
		return

	if(get_dist(user, src) > 1)
		to_chat(user, span_warning("You need to be closer."))
		return

	user.visible_message(span_notice("[user] begins assembling a mortar..."))

	if(!do_after(user, assemble_time, target = src))
		to_chat(user, span_warning("You stop assembling the mortar."))
		return

	// Validate that both still exist and user is still close
	if(QDELETED(src) || QDELETED(I) || get_dist(user, src) > 1)
		return

	var/turf/T = get_turf(src)
	if(!T)
		return

	user.visible_message(span_notice("[user] assembles a mortar."))

	new /obj/structure/artillery/mortar(T)

	qdel(I)
	qdel(src)
