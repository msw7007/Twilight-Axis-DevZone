/datum/reagent/artillery_powder
	name = "Black Powder"
	description = "Finely ground explosive powder."
	color = "#2b2b2e"

/// -------------------------
/// Powder barrel (STRUCTURE)
/// -------------------------
/obj/structure/artillery/powder_barrel
	name = "powder barrel"
	desc = "A stout barrel filled with black powder."
	icon = 'modular_twilight_axis/artillery/icons/artillery.dmi'
	icon_state = "powder_keg"

	anchored = FALSE
	density = TRUE

	var/detonated = FALSE
	var/powder_potency = 1.0

/obj/structure/artillery/powder_barrel/Initialize(mapload)
	. = ..()
	powder_potency = rand(round(ART_POWDER_POTENCY_MIN*100), round(ART_POWDER_POTENCY_MAX*100)) / 100
	create_reagents(ART_POWDER_BARREL_MAX)
	reagents.add_reagent(ART_POWDER_REAGENT, ART_POWDER_BARREL_MAX)

/// ПКМ / secondary hand (как в tg). Если у вас другой хук — скажи, подгоню.
/obj/structure/artillery/powder_barrel/attack_right(mob/user)
	. = ..()
	if(.)
		return
	if(!user || !isliving(user))
		return
	take_handful(user)
	return TRUE

/obj/structure/artillery/powder_barrel/proc/take_handful(mob/living/user)
	if(!reagents || reagents.get_reagent_amount(ART_POWDER_REAGENT) <= 0)
		to_chat(user, span_warning("The barrel is empty."))
		return

	var/amount = input(user, "How much powder to take? (1-[ART_POWDER_HAND_MAX])", "Take Powder", 10) as num|null
	if(isnull(amount))
		return

	amount = clamp(round(amount), 1, ART_POWDER_HAND_MAX)

	var/available = reagents.get_reagent_amount(ART_POWDER_REAGENT)
	amount = min(amount, available)
	if(amount <= 0)
		to_chat(user, span_warning("The barrel is empty."))
		return

	var/obj/item/artillery/powder_handful/H = new(get_turf(user))
	H.powder_potency = powder_potency
	H.reagents.add_reagent(ART_POWDER_REAGENT, amount)
	reagents.remove_reagent(ART_POWDER_REAGENT, amount)

	if(user.put_in_hands(H))
		to_chat(user, span_notice("You take [amount] oz of powder."))
	else
		to_chat(user, span_notice("You take [amount] oz of powder and drop it."))
		H.forceMove(get_turf(user))

/obj/structure/artillery/powder_barrel/fire_act(exposed_temperature, exposed_volume)
	. = ..()
	if(detonated)
		return
	detonate()

/obj/structure/artillery/powder_barrel/temperature_expose(exposed_temperature, exposed_volume)
	. = ..()
	if(detonated)
		return
	if(exposed_temperature >= 450)
		detonate()

/obj/structure/artillery/powder_barrel/proc/detonate()
	if(detonated)
		return
	detonated = TRUE

	var/turf/T = get_turf(src)
	var/amt = reagents ? reagents.get_reagent_amount(ART_POWDER_REAGENT) : 0
	if(!T || amt <= 0)
		qdel(src)
		return

	visible_message(span_danger("[src] detonates!"))
	do_powder_detonation(T, amt)
	qdel(src)


/// -------------------------
/// Powder handful (ITEM)
/// -------------------------
/obj/item/artillery/powder_handful
	name = "handful of powder"
	desc = "A small pile of black powder. Extremely flammable."
	icon = 'modular_twilight_axis/artillery/icons/artillery.dmi'
	icon_state = "powder_handful"

	w_class = WEIGHT_CLASS_TINY
	var/detonated = FALSE
	var/powder_potency = 1.0

/obj/item/artillery/powder_handful/Initialize(mapload)
	. = ..()
	create_reagents(ART_POWDER_HAND_MAX)

/obj/item/artillery/powder_handful/fire_act(exposed_temperature, exposed_volume)
	. = ..()
	if(detonated)
		return
	detonate()

/obj/item/artillery/powder_handful/temperature_expose(exposed_temperature, exposed_volume)
	. = ..()
	if(detonated)
		return
	if(exposed_temperature >= 450)
		detonate()

/obj/item/artillery/powder_handful/proc/detonate()
	if(detonated)
		return
	detonated = TRUE

	var/turf/T = get_turf(src)
	var/amt = reagents ? reagents.get_reagent_amount(ART_POWDER_REAGENT) : 0
	if(!T || amt <= 0)
		qdel(src)
		return

	visible_message(span_danger("The powder detonates!"))
	do_powder_detonation(T, amt)
	qdel(src)


/// -------------------------
/// Powder spill (GROUND)
/// -------------------------
/obj/effect/decal/cleanable/artillery_powder_spill
	name = "powder spill"
	desc = "Loose black powder scattered on the ground."
	icon = 'modular_twilight_axis/artillery/icons/artillery.dmi'
	icon_state = "powder_spill"
	mouse_opacity = MOUSE_OPACITY_ICON

	var/detonated = FALSE
	var/powder_potency = 1.0

/obj/effect/decal/cleanable/artillery_powder_spill/proc/set_amount(amount, potency = 1.0)
	amount = max(0, round(amount))
	if(amount <= 0)
		qdel(src)
		return
	powder_potency = clamp(potency, 0.5, 2.0)
	create_reagents(amount)
	reagents.add_reagent(ART_POWDER_REAGENT, amount)

/// Нормально детонит от огня/температуры
/obj/effect/decal/cleanable/artillery_powder_spill/fire_act(exposed_temperature, exposed_volume)
	. = ..()
	if(detonated)
		return
	detonate()

/obj/effect/decal/cleanable/artillery_powder_spill/temperature_expose(exposed_temperature, exposed_volume)
	. = ..()
	if(detonated)
		return
	if(exposed_temperature >= 450)
		detonate()

/obj/effect/decal/cleanable/artillery_powder_spill/proc/detonate()
	if(detonated)
		return
	detonated = TRUE

	var/turf/T = get_turf(src)
	var/amt = reagents ? reagents.get_reagent_amount(ART_POWDER_REAGENT) : 0
	if(!T || amt <= 0)
		qdel(src)
		return

	visible_message(span_danger("The spilled powder detonates!"))
	do_powder_detonation(T, amt, powder_potency)
	qdel(src)
