/obj/structure/artillery/mortar
	name = "mortar"
	desc = "A crude mortar. Requires a shell, powder charge, elevation, and an azimuth."
	icon = 'modular_twilight_axis/artillery/icons/artillery.dmi'
	icon_state = "mortar"

	anchored = FALSE
	density = TRUE

	var/broken = FALSE

	var/obj/item/artillery_shell/loaded_shell
	var/aim_azimuth = 0
	var/aim_elevation = ART_ELEVATION_DEFAULT

	/// powder (ounces)
	var/powder_ounces = 0 // 0..200

	/// list of charges: each entry is list("oz"=N, "potency"=P)
	var/list/powder_charges

	/// durability
	var/wear = 0 // 0..100
	var/safe_ounces = ART_MORTAR_SAFE_POWDER

	// calculator inputs (manual)
	var/calc_target_lat = 0.0
	var/calc_target_lon = 0.0

	var/calc_wind_dir = 0
	var/calc_wind_strength = 0
	var/calc_density = 1.0
	var/calc_humidity = 0.0

	var/calc_shell_mass = 10.0
	var/calc_shell_drift_mult = 1.0
	var/calc_shell_base_scatter = 2

	var/calc_powder_potency = 1.0
	var/calc_elevation = ART_ELEVATION_DEFAULT

	var/list/calc_result

/obj/structure/artillery/mortar/Initialize(mapload)
	. = ..()
	powder_charges = list()
	AddComponent(/datum/component/artillery_fcs)

/// Safe powder decreases with wear
/obj/structure/artillery/mortar/proc/get_safe_powder_max()
	return clamp(safe_ounces - round(wear / 2), 50, ART_MORTAR_POWDER_MAX)

/// Weighted average potency of loaded powder
/obj/structure/artillery/mortar/proc/get_powder_potency_avg()
	if(!length(powder_charges) || powder_ounces <= 0)
		return 1.0

	var/total = 0
	var/acc = 0.0
	for(var/list/entry in powder_charges)
		var/oz = entry["oz"]
		var/p = entry["potency"]
		if(isnull(oz) || isnull(p))
			continue
		total += oz
		acc += oz * p

	if(total <= 0)
		return 1.0
	return clamp(acc / total, 0.5, 2.0)

/// UI fire request
/obj/structure/artillery/mortar/proc/request_fire(mob/living/user)
	if(broken)
		to_chat(user, span_warning("It's broken."))
		return
	SEND_SIGNAL(src, COMSIG_ARTILLERY_FIRE, user)

/// Offload: spill ALL powder under user
/obj/structure/artillery/mortar/proc/offload_powder_to_ground(mob/living/user)
	if(powder_ounces <= 0)
		to_chat(user, span_warning("No powder to offload."))
		return FALSE

	var/turf/T = get_turf(user)
	if(!T)
		return FALSE

	var/avg_pot = get_powder_potency_avg()

	var/obj/effect/decal/cleanable/artillery_powder_spill/S = new(T)
	S.set_amount(powder_ounces, avg_pot)

	user.visible_message(span_notice("[user] pours powder onto the ground."),
		span_notice("You pour the powder onto the ground."))

	powder_ounces = 0
	powder_charges.Cut()
	return TRUE

/// Consume shot after successful fire
/obj/structure/artillery/mortar/proc/consume_shot(used_ounces)
	wear = clamp(wear + 1 + round(used_ounces / 25), 0, 100)
	powder_ounces = 0
	powder_charges.Cut()

/obj/structure/artillery/mortar/proc/apply_misfire(mob/user)
	powder_ounces = 0
	powder_charges.Cut()
	wear = clamp(wear + 2, 0, 100)

/// catastrophic burst
/obj/structure/artillery/mortar/proc/apply_catastrophic_burst(mob/user)
	var/turf/T = get_turf(src)
	var/power = clamp(powder_ounces / 60, 0.3, 7.0)
	do_artillery_explosion(T, power)

	if(loaded_shell)
		qdel(loaded_shell)
		loaded_shell = null

	powder_ounces = 0
	powder_charges.Cut()
	wear = clamp(wear + 35, 0, 100)
	if(wear >= 100)
		break_mortar()

/obj/structure/artillery/mortar/proc/break_mortar()
	broken = TRUE
	icon_state = "mortar_broken"
	desc = "A broken mortar. The barrel looks cracked."

/obj/structure/artillery/mortar/examine(mob/user)
	. = ..()
	. += "Aim: [aim_azimuth]° / [aim_elevation]°."
	. += "Loaded shell: [loaded_shell ? loaded_shell.name : "none"]."
	. += "Powder: [powder_ounces]/[ART_MORTAR_POWDER_MAX] oz. Safe: [get_safe_powder_max()] oz. Wear: [wear]%."
	. += "Powder quality (avg): [round(get_powder_potency_avg(), 0.01)]."

/// Load shell / load powder handful
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

	if(istype(I, /obj/item/artillery/powder_handful))
		var/obj/item/artillery/powder_handful/H = I
		if(!H.reagents)
			return

		var/avail = H.reagents.get_reagent_amount(ART_POWDER_REAGENT)
		if(avail <= 0)
			to_chat(user, span_warning("It's empty."))
			return

		var/can_take = ART_MORTAR_POWDER_MAX - powder_ounces
		if(can_take <= 0)
			to_chat(user, span_warning("The mortar is already full of powder."))
			return

		var/take = min(avail, can_take)
		H.reagents.remove_reagent(ART_POWDER_REAGENT, take)
		powder_ounces += take

		var/pot = clamp(H.powder_potency, 0.5, 2.0)
		powder_charges += list(list("oz" = take, "potency" = pot))

		to_chat(user, span_notice("You load [take] oz of powder into [src]."))

		if(H.reagents.get_reagent_amount(ART_POWDER_REAGENT) <= 0)
			qdel(H)
		return

/obj/structure/artillery/mortar/proc/offload_shell(mob/living/user)
	if(!loaded_shell)
		to_chat(user, span_warning("No shell loaded."))
		return FALSE

	var/turf/T = get_turf(src)
	if(!T)
		return FALSE

	loaded_shell.forceMove(T)
	user.visible_message(
		span_notice("[user] unloads a shell from [src]."),
		span_notice("You unload [loaded_shell] from [src].")
	)

	loaded_shell = null
	return TRUE

/obj/structure/artillery/mortar/proc/detach_barrel(mob/living/user)
	if(!user)
		return FALSE

	if(loaded_shell || powder_ounces > 0)
		to_chat(user, span_warning("You should unload the shell and powder before removing the barrel."))

	var/turf/T = get_turf(src)
	if(!T)
		return FALSE

	new /obj/structure/artillery/mortar_base(T)

	var/obj/item/mortar_barrel/B = new(T)
	B.wear = clamp(wear, 0, 100)

	user.visible_message(
		span_notice("[user] removes the barrel from [src]."),
		span_notice("You remove the barrel from [src].")
	)

	if(loaded_shell)
		loaded_shell.forceMove(T)
		loaded_shell = null

	qdel(src)
	return TRUE

// --------------------
// Calculator: apply incoming params
// --------------------
/obj/structure/artillery/mortar/proc/apply_calc_params(list/params)
	if(!params)
		return

	var/tlat = text2num(params["target_lat"])
	var/tlon = text2num(params["target_lon"])

	var/wd = text2num(params["wind_dir"])
	var/ws = text2num(params["wind_strength"])
	var/de = text2num(params["air_density"] || params["density"])
	var/hu = text2num(params["humidity"])

	var/mass = text2num(params["shell_mass"])
	var/dm = text2num(params["drift_mult"] || params["shell_drift_mult"])
	var/bs = text2num(params["base_scatter"] || params["shell_base_scatter"])

	var/pot = text2num(params["powder_potency"])
	var/elev = text2num(params["elevation"])

	if(!isnull(tlat)) calc_target_lat = tlat
	if(!isnull(tlon)) calc_target_lon = tlon

	if(!isnull(wd)) calc_wind_dir = (round(wd) + 360) % 360
	if(!isnull(ws)) calc_wind_strength = clamp(round(ws), 0, ART_WIND_MAX)
	if(!isnull(de)) calc_density = clamp(de, 0.7, 1.3)
	if(!isnull(hu)) calc_humidity = clamp(hu, 0, 1)

	if(!isnull(mass)) calc_shell_mass = max(0.1, mass)
	if(!isnull(dm))   calc_shell_drift_mult = max(0.1, dm)
	if(!isnull(bs))   calc_shell_base_scatter = max(0, round(bs))

	if(!isnull(pot))  calc_powder_potency = clamp(pot, 0.5, 2.0)
	if(!isnull(elev)) calc_elevation = clamp(round(elev), ART_ELEVATION_MIN, ART_ELEVATION_MAX)

// --------------------
// TGUI hooks
// --------------------
/obj/structure/artillery/mortar/attack_hand(mob/user)
	. = ..()
	if(.)
		return
	ui_interact(user)
	return TRUE

/obj/structure/artillery/mortar/ui_state(mob/user)
	return GLOB.physical_state

/obj/structure/artillery/mortar/ui_interact(mob/user, datum/tgui/ui)
	if(!user || !isliving(user))
		return
	if(broken)
		to_chat(user, span_warning("The mortar is broken."))
		return
	if(get_dist(user, src) > 1)
		to_chat(user, span_warning("You need to be closer."))
		return

	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "MortarArtillery", name)
		ui.open()

/obj/structure/artillery/mortar/ui_data(mob/user)
	var/list/data = list()

	data["aim_azimuth"] = aim_azimuth
	data["aim_elevation"] = aim_elevation
	data["elev_min"] = ART_ELEVATION_MIN
	data["elev_max"] = ART_ELEVATION_MAX

	data["powder_ounces"] = powder_ounces
	data["powder_max"] = ART_MORTAR_POWDER_MAX
	data["wear"] = wear
	data["safe_max"] = get_safe_powder_max()
	data["powder_potency_avg"] = round(get_powder_potency_avg(), 0.01)

	data["shell_name"] = loaded_shell ? loaded_shell.name : null
	data["has_shell"] = loaded_shell ? TRUE : FALSE
	data["broken"] = broken

	// calculator inputs (stored)
	data["calc_target_lat"] = calc_target_lat
	data["calc_target_lon"] = calc_target_lon

	data["calc_wind_dir"] = calc_wind_dir
	data["calc_wind_strength"] = calc_wind_strength
	data["calc_density"] = calc_density
	data["calc_humidity"] = calc_humidity

	data["calc_shell_mass"] = calc_shell_mass
	data["calc_shell_drift_mult"] = calc_shell_drift_mult
	data["calc_shell_base_scatter"] = calc_shell_base_scatter

	data["calc_powder_potency"] = calc_powder_potency
	data["calc_elevation"] = calc_elevation

	data["calc_result"] = calc_result

	return data

/obj/structure/artillery/mortar/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	var/mob/living/user = usr
	if(!user)
		return TRUE

	if(broken)
		return TRUE

	if(get_dist(user, src) > 1)
		to_chat(user, span_warning("You need to be closer."))
		return TRUE

	switch(action)
		if("set_azimuth")
			var/value = text2num(params["value"])
			if(!isnull(value))
				aim_azimuth = (round(value) + 360) % 360
			return TRUE

		if("set_elevation")
			var/value2 = text2num(params["value"])
			if(!isnull(value2))
				aim_elevation = clamp(round(value2), ART_ELEVATION_MIN, ART_ELEVATION_MAX)
			return TRUE

		if("offload_powder")
			offload_powder_to_ground(user)
			return TRUE

		if("offload_shell")
			offload_shell(user)
			return TRUE

		if("detach_barrel")
			detach_barrel(user)
			return TRUE
		if("remove_barrel")
			detach_barrel(user)
			return TRUE

		if("calc_solution")
			apply_calc_params(params)

			var/datum/component/artillery_fcs/C = GetComponent(/datum/component/artillery_fcs)
			if(!C)
				calc_result = list("ok" = FALSE, "notes" = "No FCS component.")
				return TRUE

			calc_result = C.calc_solution_from_coords(
				user,
				get_turf(src),
				calc_target_lat,
				calc_target_lon,
				calc_wind_dir,
				calc_wind_strength,
				calc_density,
				calc_humidity,
				calc_shell_mass,
				calc_shell_drift_mult,
				calc_shell_base_scatter,
				calc_powder_potency,
				calc_elevation
			)
			return TRUE

		if("fire")
			request_fire(user)
			return TRUE

	return TRUE

/obj/item/mortar_barrel
	name = "mortar barrel"
	desc = "A heavy barrel used to assemble a mortar."
	icon = 'modular_twilight_axis/artillery/icons/artillery.dmi'
	icon_state = "mortar_barrel"
	w_class = WEIGHT_CLASS_BULKY

	/// 0..100, same meaning as mortar.wear
	var/wear = 0

/obj/item/mortar_barrel/examine(mob/user)
	. = ..()
	. += "Barrel wear: [wear]%."

/// INTEGRATION: подгони под свой молот/инструменты.
/obj/item/mortar_barrel/proc/is_hammer(obj/item/I)
	if(!I)
		return FALSE
	if(istype(I, /obj/item/rogueweapon/hammer)) 
		return TRUE
	return FALSE

/obj/item/mortar_barrel/attackby(obj/item/I, mob/user, params)
	. = ..()
	if(.)
		return

	if(!isliving(user))
		return

	if(!is_hammer(I))
		return

	if(wear <= 0)
		to_chat(user, span_notice("The barrel is already in perfect condition."))
		return

	user.visible_message(
		span_notice("[user] starts hammering dents out of [src]..."),
		span_notice("You start hammering dents out of [src]...")
	)

	if(!do_after(user, 3 SECONDS, target = src))
		to_chat(user, span_warning("You stop repairing the barrel."))
		return

	wear = max(wear - 8, 0)
	to_chat(user, span_notice("You repair the barrel. Wear is now [wear]%."))

/obj/structure/artillery/mortar_base
	name = "mortar base"
	desc = "A heavy base. Needs a barrel to assemble a mortar."
	icon = 'modular_twilight_axis/artillery/icons/artillery.dmi'
	icon_state = "mortar_base"
	anchored = FALSE
	density = TRUE

	var/assemble_time = 4 SECONDS

/obj/structure/artillery/mortar_base/attackby(obj/item/I, mob/user, params)
	. = ..()
	// НЕ ранний return по (.) — иначе можешь случайно убить сборку
	if(!istype(I, /obj/item/mortar_barrel))
		return

	if(!user || !isliving(user))
		return

	if(get_dist(user, src) > 1)
		to_chat(user, span_warning("You need to be closer."))
		return

	if(user.get_active_held_item() != I)
		to_chat(user, span_warning("You need to hold the barrel to assemble the mortar."))
		return

	var/obj/item/mortar_barrel/B = I

	user.visible_message(
		span_notice("[user] begins assembling a mortar..."),
		span_notice("You begin assembling the mortar...")
	)

	if(!do_after(user, assemble_time, target = src))
		to_chat(user, span_warning("You stop assembling the mortar."))
		return

	if(QDELETED(src) || QDELETED(B))
		return

	if(get_dist(user, src) > 1 || user.get_active_held_item() != B)
		return

	var/turf/T = get_turf(src)
	if(!T)
		return

	var/obj/structure/artillery/mortar/M = new(T)
	// переносим wear ствола
	M.wear = clamp(B.wear, 0, 100)

	user.visible_message(
		span_notice("[user] assembles a mortar."),
		span_notice("You assemble the mortar.")
	)

	qdel(B)
	qdel(src)
