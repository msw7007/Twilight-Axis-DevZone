/************************************************************/
/* verminengineer.dm                                        */
/************************************************************/

/datum/component/storage/concrete/roguetown/backpack/vermin
	screen_max_rows = 3
	screen_max_columns = 3
	max_w_class = WEIGHT_CLASS_TINY
	not_while_equipped = FALSE

/datum/component/storage/concrete/roguetown/backpack/vermin/New(datum/P, ...)
	. = ..()
	set_holdable(list(
		/obj/item/ammo_casing/caseless/verminsphere
	))

/datum/job/roguetown/verminengineer
	title = "Verminengineer"
	department_flag = ANTAGONIST
	antag_job = TRUE
	faction = "Station"
	total_positions = 1
	spawn_positions = 1
	allowed_races = RACES_SHUNNED_UP_NO_AASIMAR
	tutorial = "Безумный подземный инженер, превращающий очищенный люкс в верминстоун, верминсферы и зелёное гибельное пламя."
	outfit = null
	outfit_female = null
	show_in_credits = TRUE
	display_order = JDO_HAG
	min_pq = 0
	max_pq = null
	announce_latejoin = FALSE
	wanderer_examine = TRUE
	advjob_examine = TRUE
	always_show_on_latechoices = TRUE
	job_reopens_slots_on_death = FALSE
	same_job_respawn_delay = 1 MINUTES

	job_subclasses = list(
		/datum/advclass/verminengineer
	)

/datum/job/roguetown/verminengineer/special_job_check(mob/dead/new_player/player)
	if(is_storyteller_soft_antag_blocked())
		return FALSE
	return ..()

/datum/job/roguetown/verminengineer/special_check_latejoin(client/C)
	if(is_storyteller_soft_antag_blocked())
		return FALSE
	return ..()

/datum/job/roguetown/verminengineer/after_spawn(mob/living/L, mob/M, latejoin = TRUE)
	..()
	if(!L)
		return

	var/mob/living/carbon/human/H = L
	if(H.mind && !H.mind.has_antag_datum(/datum/antagonist/verminengineer))
		var/datum/antagonist/new_antag = new /datum/antagonist/verminengineer()
		H.mind.add_antag_datum(new_antag)

/datum/advclass/verminengineer
	name = "Verminengineer"
	tutorial = "Подземный саботажник, использующий вермин-алхимию, ядовитый газ и зелёный огонь."
	allowed_sexes = list(MALE, FEMALE)
	allowed_races = RACES_ALL_KINDS
	outfit = /datum/outfit/job/roguetown/verminengineer
	traits_applied = list(TRAIT_MEDIUMARMOR)

	subclass_stats = list(
		STATKEY_STR = 1,
		STATKEY_PER = 2,
		STATKEY_INT = 3,
		STATKEY_CON = 1,
		STATKEY_SPD = 1,
		STATKEY_WIL = 1,
	)

	subclass_skills = list(
		/datum/skill/combat/twilight_firearms = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/craft/engineering = SKILL_LEVEL_EXPERT,
		/datum/skill/misc/athletics = SKILL_LEVEL_APPRENTICE,
		/datum/skill/misc/climbing = SKILL_LEVEL_APPRENTICE,
		/datum/skill/misc/reading = SKILL_LEVEL_APPRENTICE
	)

	classes = list(
		"Verminengineer" = "Подземный саботажник, использующий вермин-алхимию, ядовитый газ и зелёный огонь. Чем дольше живёт — тем страшнее становится."
	)

	extra_context = "Starts with a verminsphere backpack, refinery blueprints, and access to unstable vermin-alchemy."

/datum/outfit/job/roguetown/verminengineer/pre_equip(mob/living/carbon/human/H)
	..()

	backl = /obj/item/storage/backpack/rogue/vermin_pack
	belt = /obj/item/storage/belt/rogue/pouch
	beltr = /obj/item/rogueweapon/huntingknife
	shoes = /obj/item/clothing/shoes/roguetown/boots
	gloves = /obj/item/clothing/gloves/roguetown/leather
	pants = /obj/item/clothing/under/roguetown/heavy_leather_pants
	shirt = /obj/item/clothing/suit/roguetown/armor/gambeson
	armor = /obj/item/clothing/suit/roguetown/armor/leather

	backpack_contents = list(
		/obj/item/paper/vermin_refinery_blueprints = 1,
		/obj/item/verminstone = 1,
		/obj/item/ammo_casing/caseless/verminsphere = 3
	)

/datum/antagonist/verminengineer
	name = "Verminengineer"
	roundend_category = "verminengineers"
	antagpanel_category = "Verminengineer"
	show_in_antagpanel = TRUE

/datum/antagonist/verminengineer/on_gain()
	. = ..()
	if(!owner || !owner.current)
		return

	var/mob/living/carbon/human/H = owner.current
	greet()
	apply_innate_effects(H)

/datum/antagonist/verminengineer/on_removal()
	if(owner && owner.current)
		var/mob/living/carbon/human/H = owner.current
		remove_innate_effects(H)
	. = ..()

/datum/antagonist/verminengineer/greet()
	if(!owner || !owner.current)
		return

	to_chat(owner.current, span_userdanger("You are a Verminengineer."))
	to_chat(owner.current, span_notice("Refine purified lux into Verminstone."))
	to_chat(owner.current, span_notice("Use Verminstone to craft Verminspheres, a Verminthrower, and an End Rocket."))
	to_chat(owner.current, span_warning("You are an enemy of the city. Sabotage, spread poison, and survive long enough to escalate."))

/datum/antagonist/verminengineer/apply_innate_effects(mob/living/carbon/human/H)
	if(!H)
		return

	H.faction |= "verminengineer"
	H.faction |= "hostile"
	H.faction -= "town"

/datum/antagonist/verminengineer/remove_innate_effects(mob/living/carbon/human/H)
	if(!H)
		return

	H.faction -= "verminengineer"

/obj/item/paper/vermin_refinery_blueprints
	name = "vermin refinery blueprints"
	info = "Чертежи вермин-перегонщика.\n\nПринимает очищенный люкс.\nКаждую минуту производит 1 верминстоун, если в буфере достаточно люкса.\n\nКрафт:\n- 3 верминстоуна -> верминтроуер\n- 1 верминстоун -> 3 верминсферы\n- 10 верминстоунов -> end rocket\n- 3 стали, 2 бревна, 2 доски -> end rocket rack"

/obj/item/verminstone
	name = "verminstone"
	desc = "Пульсирующий зелёный камень, от которого веет плохими решениями."
	icon = 'modular_twilight_axis/firearms/icons/ammo.dmi'
	icon_state = "musketball_proj"
	color = "#65ff55"
	w_class = WEIGHT_CLASS_SMALL
	sellprice = 25

/obj/item/ammo_casing/caseless/verminsphere
	name = "verminsphere"
	desc = "Нестабильная сфера с вермин-реактивом. При броске выпускает только ядовитый газ."
	icon = 'modular_twilight_axis/firearms/icons/ammo.dmi'
	icon_state = "musketball_proj"
	color = "#7dff65"
	throwforce = 10
	w_class = WEIGHT_CLASS_TINY

/obj/item/ammo_casing/caseless/verminsphere/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	. = ..()
	var/turf/T = get_turf(src)
	if(T)
		new /obj/effect/vermin_gas_cloud(T)
	qdel(src)

/obj/item/storage/backpack/rogue/vermin_pack
	name = "vermin pack"
	desc = "Специальный рюкзак на 9 верминсфер. Ничего иного он принимать не должен."
	icon = 'modular_twilight_axis/firearms/icons/ammo.dmi'
	icon_state = "pouch1"
	slot_flags = ITEM_SLOT_BACK_L|ITEM_SLOT_BACK_R
	w_class = WEIGHT_CLASS_BULKY
	component_type = /datum/component/storage/concrete/roguetown/backpack/vermin

/obj/item/storage/backpack/rogue/vermin_pack/examine(mob/user)
	. = ..()
	. += span_info("Внутри сфер: [count_spheres()] / 9.")

/obj/item/storage/backpack/rogue/vermin_pack/proc/count_spheres()
	var/current = 0
	for(var/obj/item/ammo_casing/caseless/verminsphere/S in contents)
		current++
	return current

/obj/item/storage/backpack/rogue/vermin_pack/proc/take_sphere(atom/newloc)
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	if(!STR)
		return null

	for(var/obj/item/ammo_casing/caseless/verminsphere/S in contents)
		var/atom/target_loc = newloc ? newloc : get_turf(src)
		STR.remove_from_storage(S, target_loc)
		return S

	return null

/obj/item/storage/backpack/rogue/vermin_pack/proc/take_multiple_spheres(count, atom/newloc)
	var/list/taken = list()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	if(!STR)
		return taken

	var/atom/target_loc = newloc ? newloc : get_turf(src)

	for(var/i in 1 to count)
		var/obj/item/ammo_casing/caseless/verminsphere/found = null
		for(var/obj/item/ammo_casing/caseless/verminsphere/S in contents)
			found = S
			break

		if(!found)
			break

		STR.remove_from_storage(found, target_loc)
		taken += found

	return taken

/obj/item/storage/backpack/rogue/vermin_pack/proc/has_spheres()
	return count_spheres() > 0

/obj/item/storage/backpack/rogue/vermin_pack/proc/has_at_least(count)
	return count_spheres() >= count

/obj/effect/vermin_gas_cloud
	name = "vermin gas"
	desc = "Тошнотворное зелёное облако вермин-газа."
	icon = 'icons/effects/96x96.dmi'
	icon_state = "smoke"
	color = "#55ff33"
	anchored = TRUE
	opacity = FALSE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = FLY_LAYER
	plane = GAME_PLANE_UPPER
	alpha = 200
	pixel_x = -32
	pixel_y = -32
	var/lifetime = 80
	var/tick_interval = 10
	var/end_time = 0

/obj/effect/vermin_gas_cloud/Initialize()
	. = ..()
	end_time = world.time + lifetime
	spawn(0)
		process_loop()

/obj/effect/vermin_gas_cloud/Crossed(atom/movable/AM)
	. = ..()
	if(isliving(AM))
		apply_gas_effect(AM)

/obj/effect/vermin_gas_cloud/proc/process_loop()
	while(!QDELETED(src) && world.time < end_time)
		alpha = rand(160, 220)
		for(var/mob/living/L in loc)
			apply_gas_effect(L)
		sleep(tick_interval)
	if(!QDELETED(src))
		qdel(src)

/obj/effect/vermin_gas_cloud/proc/apply_gas_effect(mob/living/L)
	L.adjustToxLoss(3)
	if(prob(10))
		L.adjust_fire_stacks(1)

/obj/effect/temp_visual/verminfire_particle
	name = "verminfire breath"
	icon = 'icons/effects/effects.dmi'
	icon_state = "mech_fire"
	color = "#66ff55"
	duration = 8
	layer = ABOVE_MOB_LAYER
	appearance_flags = RESET_TRANSFORM | PIXEL_SCALE

/obj/effect/temp_visual/verminfire_particle/Initialize(mapload, direction)
	. = ..()
	var/dist = 3
	var/p_x = 0
	var/p_y = 0
	var/side_variance = rand(-48, 48)
	var/forward_dist = 32 * dist

	switch(direction)
		if(NORTH)
			p_y = forward_dist
			p_x = side_variance
		if(SOUTH)
			p_y = -forward_dist
			p_x = side_variance
		if(EAST)
			p_x = forward_dist
			p_y = side_variance
		if(WEST)
			p_x = -forward_dist
			p_y = side_variance

	animate(src, pixel_x = p_x, pixel_y = p_y, alpha = 0, time = duration, easing = SINE_EASING)

/obj/effect/hotspot/verminfire
	icon = 'icons/effects/fire.dmi'
	icon_state = "1"
	light_color = "#66ff55"
	color = "#66ff55"
	temperature = 1000 + T0C
	firelevel = 1
	life = 20
	var/anim_dir = 1

/obj/effect/hotspot/verminfire/Initialize(mapload, starting_volume, starting_temperature, life, starting_level = 1)
	. = ..(mapload, starting_volume, starting_temperature, life)
	if(!isnull(starting_level))
		firelevel = clamp(starting_level, 1, 3)
	icon_state = "[firelevel]"
	color = "#66ff55"
	set_light(l_color = "#66ff55")

/obj/effect/hotspot/verminfire/update_color()
	color = "#66ff55"
	set_light(l_color = "#66ff55")

/obj/effect/hotspot/verminfire/process()
	if(just_spawned)
		just_spawned = FALSE
		return

	var/turf/open/location = loc
	if(!istype(location))
		qdel(src)
		return

	life--
	if(life <= 0)
		qdel(src)
		return

	step_fire_animation()
	perform_exposure()
	return

/obj/effect/hotspot/verminfire/proc/step_fire_animation()
	firelevel += anim_dir
	if(firelevel >= 3)
		firelevel = 3
		anim_dir = -1
	else if(firelevel <= 1)
		firelevel = 1
		anim_dir = 1
	icon_state = "[firelevel]"

/obj/effect/hotspot/verminfire/Crossed(atom/movable/AM, oldLoc)
	..()
	if(isliving(AM))
		var/mob/living/L = AM
		L.adjust_fire_stacks(max(1, firelevel))
		L.ignite_mob()

/obj/item/gun/ballistic/revolver/grenadelauncher/verminthrower
	name = "verminthrower"
	desc = "Нестабильный верминтроуер. Питается верминсферами."
	icon = 'modular_twilight_axis/firearms/icons/32.dmi'
	icon_state = "pistol2"
	item_state = "pistol2"
	var/icon_state_ready = "pistol2-1"
	var/default_icon_state = "pistol2"
	possible_item_intents = list(
		/datum/intent/shoot/verminthrower,
		/datum/intent/strike/verminthrower,
		/datum/intent/arc/verminthrower,
		INTENT_GENERIC
	)
	slot_flags = ITEM_SLOT_HIP
	w_class = WEIGHT_CLASS_BULKY
	force = 8
	load_sound = 'modular_twilight_axis/firearms/sound/musketload.ogg'
	fire_sound = 'modular_twilight_axis/firearms/sound/fyrepowder/arquefire.ogg'
	vary_fire_sound = TRUE
	fire_sound_volume = 150
	anvilrepair = null
	smeltresult = /obj/item/ingot/steel
	var/reload_time = 5
	var/cocked = FALSE
	var/overload = FALSE
	var/heat_stacks = 0
	var/max_heat_stacks = 10
	var/heat_decay_delay = 5 SECONDS

/obj/item/gun/ballistic/revolver/grenadelauncher/verminthrower/getonmobprop(tag)
	. = ..()
	if(tag)
		switch(tag)
			if("gen")
				return list("shrink" = 0.4,"sx" = -10,"sy" = -8,"nx" = 13,"ny" = -8,"wx" = -8,"wy" = -7,"ex" = 7,"ey" = -8,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 30,"sturn" = -30,"wturn" = -30,"eturn" = 30,"nflip" = 0,"sflip" = 8,"wflip" = 8,"eflip" = 0)
			if("onbelt")
				return list("shrink" = 0.3,"sx" = -2,"sy" = -5,"nx" = 4,"ny" = -5,"wx" = 0,"wy" = -5,"ex" = 2,"ey" = -5,"nturn" = 0,"sturn" = 0,"wturn" = 0,"eturn" = 0,"nflip" = 0,"sflip" = 0,"wflip" = 0,"eflip" = 0,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0)

/obj/item/gun/ballistic/revolver/grenadelauncher/verminthrower/attack_self(mob/living/user)
	if(!cocked)
		to_chat(user, span_info("I ready the verminthrower."))
		if(move_after(user, 0.5 SECONDS, target = user))
			cocked = TRUE
			playsound(user, 'modular_twilight_axis/firearms/sound/musketcock.ogg', 100, FALSE)
	else
		overload = !overload
		if(overload)
			to_chat(user, span_warning("I crank the verminthrower into overload."))
		else
			to_chat(user, span_notice("I return the verminthrower to a safer pressure level."))
	update_icon()

/obj/item/gun/ballistic/revolver/grenadelauncher/verminthrower/update_icon()
	..()
	if(cocked && icon_state_ready)
		icon_state = icon_state_ready
		item_state = icon_state_ready
	else
		icon_state = default_icon_state
		item_state = default_icon_state

	if(ismob(loc))
		var/mob/M = loc
		M.update_inv_hands()

/obj/item/gun/ballistic/revolver/grenadelauncher/verminthrower/examine(mob/user)
	. = ..()
	. += span_info("Режимы: конус (1 сфера), линия (2 сферы), широкий полукруг (2 сферы).")
	. += span_info("Heat: [heat_stacks] / [max_heat_stacks].")
	if(overload)
		. += span_warning("Перегрузка включена.")

/obj/item/gun/ballistic/revolver/grenadelauncher/verminthrower/proc/find_vermin_pack(mob/living/user)
	if(!user)
		return null
	for(var/obj/item/storage/backpack/rogue/vermin_pack/P in user.contents)
		return P
	return null

/obj/item/gun/ballistic/revolver/grenadelauncher/verminthrower/proc/get_required_spheres(mob/living/user)
	if(istype(user.used_intent, /datum/intent/strike/verminthrower))
		return 2
	if(istype(user.used_intent, /datum/intent/arc/verminthrower))
		return 2
	return 1

/obj/item/gun/ballistic/revolver/grenadelauncher/verminthrower/proc/consume_spheres_or_fail(mob/living/user, count)
	var/obj/item/storage/backpack/rogue/vermin_pack/P = find_vermin_pack(user)
	if(!P)
		to_chat(user, span_warning("I need a vermin pack with spheres."))
		return FALSE

	if(!P.has_at_least(count))
		to_chat(user, span_warning("I do not have enough verminspheres."))
		return FALSE

	var/list/taken = P.take_multiple_spheres(count, src)
	if(length(taken) < count)
		for(var/obj/item/I in taken)
			I.forceMove(P)
		to_chat(user, span_warning("I do not have enough verminspheres."))
		return FALSE

	for(var/obj/item/I in taken)
		qdel(I)

	return TRUE

/obj/item/gun/ballistic/revolver/grenadelauncher/verminthrower/proc/get_misfire_chance()
	if(heat_stacks <= 0)
		return 0

	var/per_stack = overload ? 7.5 : 5
	return min(100, round(heat_stacks * per_stack))

/obj/item/gun/ballistic/revolver/grenadelauncher/verminthrower/proc/add_heat_stacks(amount = 1)
	heat_stacks = min(max_heat_stacks, heat_stacks + amount)
	addtimer(CALLBACK(src, PROC_REF(decay_heat_stacks), amount), heat_decay_delay)

/obj/item/gun/ballistic/revolver/grenadelauncher/verminthrower/proc/decay_heat_stacks(amount = 1)
	if(QDELETED(src))
		return
	heat_stacks = max(0, heat_stacks - amount)

/obj/item/gun/ballistic/revolver/grenadelauncher/verminthrower/proc/can_fire_now(mob/living/user)
	if(!cocked)
		to_chat(user, span_warning("The pressure chamber is not primed."))
		return FALSE

	var/required = get_required_spheres(user)
	if(!consume_spheres_or_fail(user, required))
		return FALSE

	var/misfire_chance_final = get_misfire_chance()
	if(misfire_chance_final > 0 && prob(misfire_chance_final))
		to_chat(user, span_warning("[src] violently misfires!"))
		user.adjust_fire_stacks(3)
		user.ignite_mob()
		explosion(src, light_impact_range = 1, heavy_impact_range = 1, smoke = TRUE)
		qdel(src)
		return FALSE

	cocked = FALSE
	update_icon()
	return TRUE

/obj/item/gun/ballistic/revolver/grenadelauncher/verminthrower/proc/spawn_vermin_fire(turf/open/T, level = 1, fire_life = 20)
	if(!istype(T))
		return

	var/obj/effect/hotspot/verminfire/F = locate(/obj/effect/hotspot/verminfire) in T
	if(F)
		F.life = max(F.life, fire_life)
		F.firelevel = max(F.firelevel, clamp(level, 1, 3))
		F.icon_state = "[F.firelevel]"
		return

	new /obj/effect/hotspot/verminfire(T, 125, 1000 + T0C, fire_life, level)

/obj/item/gun/ballistic/revolver/grenadelauncher/verminthrower/afterattack(atom/target, mob/living/user, proximity_flag, click_parameters)
	. = ..()
	if(!user || user.stat || user.incapacitated())
		return
	if(!target)
		return
	if(!can_fire_now(user))
		return

	var/fire_dir = get_dir(user, target)
	if(fire_dir)
		user.setDir(fire_dir)

	if(istype(user.used_intent, /datum/intent/strike/verminthrower))
		add_heat_stacks(2)
		do_line_fire(user, fire_dir)
		return

	if(istype(user.used_intent, /datum/intent/arc/verminthrower))
		add_heat_stacks(2)
		do_wide_spray_fire(user, fire_dir)
		return

	add_heat_stacks(1)
	do_cone_fire(user, fire_dir)

/obj/item/gun/ballistic/revolver/grenadelauncher/verminthrower/proc/do_cone_fire(mob/living/user, fire_dir)
	var/damage_mult = overload ? 1.35 : 1
	var/duration = 5 SECONDS
	var/interval = 2
	var/max_ticks = max(1, round(duration / interval))

	spawn(0)
		for(var/i in 1 to max_ticks)
			if(!user || user.stat || user.incapacitated())
				break

			var/turf/user_turf = get_turf(user)
			var/user_angle = dir2angle(fire_dir)

			for(var/p in 1 to 6)
				new /obj/effect/temp_visual/verminfire_particle(user_turf, fire_dir)

			playsound(user_turf, 'sound/items/firelight.ogg', 40, TRUE)

			for(var/turf/open/T in view(3, user_turf))
				var/dist = get_dist(user_turf, T)
				if(dist == 0)
					continue

				var/target_angle = Get_Angle(user_turf, T)
				var/angle_diff = abs(closer_angle_difference(user_angle, target_angle))

				if(angle_diff <= 30)
					for(var/mob/living/L in T.contents)
						if(L == user)
							continue
						L.adjust_fire_stacks(overload ? 2 : 1)
						L.ignite_mob()
						L.adjustToxLoss(round(3 * damage_mult))

			sleep(interval)

/obj/item/gun/ballistic/revolver/grenadelauncher/verminthrower/proc/do_line_fire(mob/living/user, fire_dir)
	var/turf/open/T = get_turf(user)
	if(!istype(T))
		return

	playsound(get_turf(user), fire_sound, fire_sound_volume, vary_fire_sound)

	for(var/i in 1 to 10)
		T = get_step(T, fire_dir)
		if(!istype(T))
			break

		spawn_vermin_fire(T, overload ? 3 : 2, 18)

		for(var/mob/living/L in T.contents)
			if(L == user)
				continue
			L.adjust_fire_stacks(overload ? 3 : 2)
			L.ignite_mob()
			L.adjustToxLoss(overload ? 6 : 4)

/obj/item/gun/ballistic/revolver/grenadelauncher/verminthrower/proc/do_wide_spray_fire(mob/living/user, fire_dir)
	var/damage_mult = overload ? 1.15 : 1
	var/turf/user_turf = get_turf(user)
	var/user_angle = dir2angle(fire_dir)

	playsound(user_turf, 'sound/items/firelight.ogg', 50, TRUE)

	for(var/turf/open/T in view(3, user_turf))
		var/dist = get_dist(user_turf, T)
		if(dist == 0)
			continue

		var/target_angle = Get_Angle(user_turf, T)
		var/angle_diff = abs(closer_angle_difference(user_angle, target_angle))

		if(angle_diff <= 75)
			spawn_vermin_fire(T, overload ? 2 : 1, 15)

			for(var/mob/living/L in T.contents)
				if(L == user)
					continue
				L.adjust_fire_stacks(overload ? 2 : 1)
				L.ignite_mob()
				L.adjustToxLoss(round(2 * damage_mult))

/datum/intent/shoot/verminthrower
	chargetime = 5
	chargedrain = 0

/datum/intent/shoot/verminthrower/get_chargetime()
	return 5

/datum/intent/strike/verminthrower
	chargetime = 5
	chargedrain = 0

/datum/intent/strike/verminthrower/get_chargetime()
	return 5

/datum/intent/arc/verminthrower
	chargetime = 5
	chargedrain = 0

/datum/intent/arc/verminthrower/get_chargetime()
	return 5

/obj/machinery/vermin_refinery
	name = "vermin refinery"
	desc = "Перерабатывает очищенный люкс в верминстоун. Опасно шумит и светится нездоровым зелёным."
	icon = 'modular_twilight_axis/awful_artillery/icons/artillery.dmi'
	icon_state = "mortar_base"
	density = TRUE
	anchored = TRUE
	var/stored_lux = 0
	var/lux_per_stone = 5
	var/cycle_time = 1 MINUTES

/obj/machinery/vermin_refinery/Initialize()
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(process_cycle)), cycle_time)

/obj/machinery/vermin_refinery/examine(mob/user)
	. = ..()
	. += span_info("Stored lux: [stored_lux].")
	. += span_info("Every minute it tries to produce 1 verminstone.")

/obj/machinery/vermin_refinery/proc/is_valid_lux_item(obj/item/I)
	if(!I)
		return FALSE
	if(findtext(lowertext(I.name), "lux"))
		return TRUE
	if("purified" in I.vars && I.vars["purified"])
		return TRUE
	return FALSE

/obj/machinery/vermin_refinery/attackby(obj/item/I, mob/user, params)
	if(is_valid_lux_item(I))
		stored_lux++
		to_chat(user, span_notice("I feed [I] into [src]."))
		qdel(I)
		return
	return ..()

/obj/machinery/vermin_refinery/proc/process_cycle()
	if(QDELETED(src))
		return

	if(stored_lux >= lux_per_stone)
		stored_lux -= lux_per_stone
		new /obj/item/verminstone(get_turf(src))
		playsound(src, 'modular_twilight_axis/awful_artillery/sound/loading.ogg', 75, FALSE)

	addtimer(CALLBACK(src, PROC_REF(process_cycle)), cycle_time)

/mob/living/var/list/vermin_linked_racks

/mob/living/proc/add_vermin_rack(obj/structure/vermin_rocket_rack/R)
	if(!R)
		return
	if(!vermin_linked_racks)
		vermin_linked_racks = list()
	if(!(R in vermin_linked_racks))
		vermin_linked_racks += R

/mob/living/proc/remove_vermin_rack(obj/structure/vermin_rocket_rack/R)
	if(!vermin_linked_racks || !R)
		return
	vermin_linked_racks -= R

/mob/living/proc/get_first_loaded_vermin_rack()
	if(!vermin_linked_racks)
		return null

	for(var/obj/structure/vermin_rocket_rack/R in vermin_linked_racks.Copy())
		if(QDELETED(R))
			vermin_linked_racks -= R
			continue
		if(R.loaded_rocket)
			return R

	return null

/mob/living/proc/ensure_vermin_launch_spell()
	var/datum/action/cooldown/spell/verminengineer_launch/existing = locate() in actions
	if(existing)
		return

	var/datum/action/cooldown/spell/verminengineer_launch/S = new
	S.Grant(src)

/datum/action/cooldown/spell/verminengineer_launch
	name = "Launch End Rocket"
	desc = "Указать примерную точку падения первой заряженной вермин-ракетной установки."
	button_icon = 'icons/mob/actions/mage_kinesis.dmi'
	button_icon_state = "gravity"
	sound = 'modular_twilight_axis/awful_artillery/sound/launch.ogg'
	spell_color = COLOR_LIME
	glow_intensity = GLOW_INTENSITY_MEDIUM

	click_to_activate = TRUE
	cast_range = SPELL_RANGE_GROUND

	charge_required = TRUE
	charge_time = CHARGETIME_MAJOR
	charge_drain = 1
	charge_slowdown = CHARGING_SLOWDOWN_MEDIUM
	charge_sound = 'sound/magic/charging.ogg'
	cooldown_time = 5 SECONDS

	weapon_cast_penalized = FALSE
	spell_requirements = SPELL_REQUIRES_HUMAN | SPELL_REQUIRES_SAME_Z

/datum/action/cooldown/spell/verminengineer_launch/cast(atom/cast_on)
	. = ..()
	var/mob/living/user = owner
	if(!istype(user))
		return FALSE

	var/turf/T = get_turf(cast_on)
	if(!T)
		return FALSE

	var/obj/structure/vermin_rocket_rack/R = user.get_first_loaded_vermin_rack()
	if(!R)
		to_chat(user, span_warning("У меня нет загруженной ракетной установки."))
		return FALSE

	return R.launch_to_target(user, T)

/obj/item/end_rocket
	name = "end rocket"
	desc = "Нестабильная вермин-ракета. Лучше не стоять рядом, когда её запускают."
	icon = 'modular_twilight_axis/awful_artillery/icons/artillery.dmi'
	icon_state = "cannonball"
	color = "#74ff5d"
	w_class = WEIGHT_CLASS_BULKY

/obj/item/end_rocket/proc/shell_action(turf/impact_turf)
	if(!impact_turf)
		impact_turf = get_turf(src)
	if(!impact_turf)
		return

	explosion(impact_turf, 2, 4, 8, flame_range = 0, smoke = TRUE, ignorecap = TRUE)
	new /obj/effect/vermin_gas_cloud(impact_turf)

	var/radius = 4.5
	var/radius_sq = radius * radius

	for(var/turf/open/T in range(5, impact_turf))
		var/dx = T.x - impact_turf.x
		var/dy = T.y - impact_turf.y

		if((dx * dx) + (dy * dy) > radius_sq)
			continue

		var/dist_sq = (dx * dx) + (dy * dy)

		if(prob(70))
			new /obj/effect/vermin_gas_cloud(T)

		var/fire_level = 1
		if(dist_sq <= 2.25)
			fire_level = 3
		else if(dist_sq <= 12.25)
			fire_level = 2

		var/obj/effect/hotspot/verminfire/F = locate(/obj/effect/hotspot/verminfire) in T
		if(F)
			F.life = max(F.life, 20)
			F.firelevel = max(F.firelevel, fire_level)
			F.icon_state = "[F.firelevel]"
		else
			new /obj/effect/hotspot/verminfire(T, 125, 1000 + T0C, 20, fire_level)

	for(var/mob/living/L in range(5, impact_turf))
		var/turf/LT = get_turf(L)
		if(!LT)
			continue

		var/dx = LT.x - impact_turf.x
		var/dy = LT.y - impact_turf.y

		if((dx * dx) + (dy * dy) > radius_sq)
			continue

		L.adjust_fire_stacks(4)
		L.ignite_mob()
		L.adjustToxLoss(10)

	qdel(src)

/obj/structure/vermin_rocket_rack
	name = "end rocket rack"
	desc = "Примитивная вермин-ракетная установка. Наводится вручную через выданный спелл."
	icon = 'modular_twilight_axis/awful_artillery/icons/artillery.dmi'
	icon_state = "mortar"
	anchored = TRUE
	density = TRUE
	var/obj/item/end_rocket/loaded_rocket = null
	var/mob/living/owner_loader = null

/obj/structure/vermin_rocket_rack/examine(mob/user)
	. = ..()
	if(loaded_rocket)
		. += span_notice("Внутри уже заряжена ракета.")
	else
		. += span_info("Установка пуста.")

/obj/structure/vermin_rocket_rack/Destroy()
	if(owner_loader)
		owner_loader.remove_vermin_rack(src)
	owner_loader = null
	loaded_rocket = null
	return ..()

/obj/structure/vermin_rocket_rack/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/end_rocket))
		if(loaded_rocket)
			to_chat(user, span_warning("Установка уже заряжена."))
			return

		if(!do_after(user, 20, target = src))
			return

		I.forceMove(src)
		loaded_rocket = I
		owner_loader = user

		if(isliving(user))
			var/mob/living/L = user
			L.add_vermin_rack(src)
			L.ensure_vermin_launch_spell()

		to_chat(user, span_notice("Я заряжаю ракету в [src]."))
		playsound(src, 'modular_twilight_axis/awful_artillery/sound/loading.ogg', 100, FALSE)
		return

	return ..()

/obj/structure/vermin_rocket_rack/proc/get_scatter_for_distance(dist)
	if(dist <= 0)
		return 0
	return round(dist / 10)

/obj/structure/vermin_rocket_rack/proc/get_scattered_target(turf/original_target)
	if(!original_target)
		return null

	var/scatter = get_scatter_for_distance(get_dist(src, original_target))
	if(scatter <= 0)
		return original_target

	var/final_x = original_target.x + rand(-scatter, scatter)
	var/final_y = original_target.y + rand(-scatter, scatter)

	final_x = max(1, min(world.maxx, final_x))
	final_y = max(1, min(world.maxy, final_y))

	var/turf/final_target = locate(final_x, final_y, original_target.z)
	if(!final_target)
		return original_target

	return final_target

/obj/structure/vermin_rocket_rack/proc/launch_to_target(mob/living/user, turf/original_target)
	if(!loaded_rocket)
		to_chat(user, span_warning("[src] не заряжена."))
		return FALSE

	if(!original_target)
		to_chat(user, span_warning("Не удалось определить цель."))
		return FALSE

	var/turf/final_target = get_scattered_target(original_target)
	if(!final_target)
		to_chat(user, span_warning("Не удалось определить финальную точку падения."))
		return FALSE

	for(var/mob/M in GLOB.player_list)
		to_chat(M, span_userdanger("NUCLEAR LAUNCH DETECTED."))
		M.playsound_local(src, 'modular_twilight_axis/awful_artillery/sound/launch.ogg', 100, FALSE, pressure_affected = FALSE)

	var/obj/item/end_rocket/R = loaded_rocket
	loaded_rocket = null

	if(owner_loader)
		owner_loader.remove_vermin_rack(src)
	owner_loader = null

	var/x_mid = src.x + ((final_target.x - src.x) * 0.5)
	var/y_mid = src.y + ((final_target.y - src.y) * 0.5)
	var/z_mid = src.z + ((final_target.z - src.z) * 0.5)
	var/turf/turf_mid = locate(floor(x_mid), floor(y_mid), floor(z_mid))
	if(turf_mid)
		playsound(turf_mid, 'modular_twilight_axis/awful_artillery/sound/flyby.ogg', 100, FALSE, 50)

	R.forceMove(final_target)
	R.shell_action(final_target)

	visible_message(span_danger("[src] launches an End Rocket!"))
	log_game("[user] launched [src] toward [final_target.x],[final_target.y],[final_target.z]")
	message_admins("End Rocket launched from [ADMIN_VERBOSEJMP(src)] toward [ADMIN_VERBOSEJMP(final_target)] by [key_name_admin(user)]")

	return TRUE

/datum/crafting_recipe/roguetown/engineering/verminthrower
	name = "verminthrower"
	result = /obj/item/gun/ballistic/revolver/grenadelauncher/verminthrower
	reqs = list(
		/obj/item/verminstone = 3,
		/obj/item/ingot/steel = 1,
		/obj/item/natural/wood/plank = 1
	)
	verbage_simple = "assemble"
	verbage = "assembles"
	craftdiff = 4
	time = 15 SECONDS

/datum/crafting_recipe/roguetown/engineering/verminspheres
	name = "verminspheres x3"
	result = /obj/item/ammo_casing/caseless/verminsphere
	reqs = list(
		/obj/item/verminstone = 1
	)
	verbage_simple = "shape"
	verbage = "shapes"
	craftdiff = 2
	time = 5 SECONDS

/datum/crafting_recipe/roguetown/engineering/verminspheres/proc/make_result(mob/user, turf/location)
	new /obj/item/ammo_casing/caseless/verminsphere(location)
	new /obj/item/ammo_casing/caseless/verminsphere(location)

/datum/crafting_recipe/roguetown/engineering/vermin_refinery
	name = "vermin refinery"
	result = /obj/machinery/vermin_refinery
	reqs = list(
		/obj/item/ingot/steel = 2,
		/obj/item/grown/log/tree = 2,
		/obj/item/natural/wood/plank = 2
	)
	verbage_simple = "assemble"
	verbage = "assembles"
	craftdiff = 3
	time = 20 SECONDS

/datum/crafting_recipe/roguetown/engineering/end_rocket
	name = "end rocket"
	result = /obj/item/end_rocket
	reqs = list(
		/obj/item/verminstone = 10
	)
	verbage_simple = "assemble"
	verbage = "assembles"
	craftdiff = 5
	time = 30 SECONDS

/datum/crafting_recipe/roguetown/engineering/end_rocket_rack
	name = "end rocket rack"
	result = /obj/structure/vermin_rocket_rack
	reqs = list(
		/obj/item/ingot/steel = 3,
		/obj/item/grown/log/tree = 2,
		/obj/item/natural/wood/plank = 2
	)
	verbage_simple = "assemble"
	verbage = "assembles"
	craftdiff = 4
	time = 20 SECONDS

/proc/verminengineerslot_calc()
	var/list/result = list()
	if(is_storyteller_soft_antag_blocked())
		result["final_slots"] = 0
		return result
	result["final_slots"] = 1
	return result

/proc/verminengineerslot_update()
	var/datum/job/vermin_job = SSjob.GetJob("Verminengineer")
	if(!vermin_job)
		return
	var/list/scaling = verminengineerslot_calc()
	var/slots = max(0, scaling["final_slots"])
	vermin_job.total_positions = max(vermin_job.current_positions, slots)
	vermin_job.spawn_positions = max(vermin_job.current_positions, slots)
