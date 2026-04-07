/datum/component/storage/concrete/roguetown/backpack/vermin
	screen_max_rows = 3
	screen_max_columns = 3
	max_w_class = WEIGHT_CLASS_SMALL
	not_while_equipped = TRUE

/datum/component/storage/concrete/roguetown/backpack/vermin/New(datum/P, ...)
	. = ..()
	can_hold = typecacheof(list(
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
	info = "Чертежи вермин-перегонщика.\n\nПринимает очищенный люкс.\nКаждую минуту производит 1 верминстоун, если в буфере достаточно люкса.\n\nКрафт:\n- 3 верминстоуна -> верминтроуер\n- 1 верминстоун -> 3 верминсферы\n- 10 верминстоунов -> end rocket"

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
	desc = "Нестабильная сфера с вермин-реактивом. Подходит и для броска, и для зарядки верминтроуера."
	icon = 'modular_twilight_axis/firearms/icons/ammo.dmi'
	icon_state = "musketball_proj"
	color = "#7dff65"
	caliber = "verminsphere"
	projectile_type = /obj/projectile/bullet/verminfire_shot
	throwforce = 10
	w_class = WEIGHT_CLASS_SMALL

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
	for(var/obj/item/ammo_casing/caseless/verminsphere/S in contents)
		if(newloc)
			S.forceMove(newloc)
		else
			S.forceMove(drop_location())
		return S
	return null

/obj/item/storage/backpack/rogue/vermin_pack/proc/has_spheres()
	return count_spheres() > 0

/obj/projectile/bullet/verminfire_shot
	name = "verminfire"
	icon = 'modular_twilight_axis/firearms/icons/ammo.dmi'
	icon_state = "musketball_proj"
	color = "#66ff55"
	damage = 16
	damage_type = BURN
	range = 5
	speed = 0.2
	flag = "magic"
	armor_penetration = 10

/obj/projectile/bullet/verminfire_shot/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(isliving(target))
		var/mob/living/L = target
		L.adjust_fire_stacks(2)
		L.ignite_mob()
		L.adjustToxLoss(4)
		if(prob(35))
			new /obj/effect/temp_visual/verminfire_flash(get_turf(L))

	var/turf/T = get_turf(target)
	if(T && prob(35))
		new /obj/effect/vermin_gas_cloud(T)

/obj/effect/temp_visual/verminfire_flash
	name = "verminfire"
	icon = 'icons/effects/effects.dmi'
	icon_state = "mech_fire"
	color = "#66ff55"
	duration = 8
	layer = ABOVE_MOB_LAYER
	appearance_flags = RESET_TRANSFORM | PIXEL_SCALE

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
	L.adjust_fire_stacks(1)
	if(prob(20))
		L.ignite_mob()

/obj/item/gun/ballistic/revolver/grenadelauncher/verminthrower
	name = "verminthrower"
	desc = "Нестабильный верминтроуер. Жрёт верминсферы как боеприпас."
	icon = 'modular_twilight_axis/firearms/icons/32.dmi'
	icon_state = "pistol2"
	item_state = "pistol2"
	var/icon_state_ready = "pistol2-1"
	var/default_icon_state = "pistol2"
	possible_item_intents = list(/datum/intent/shoot/verminthrower, /datum/intent/arc/verminthrower, INTENT_GENERIC)
	mag_type = /obj/item/ammo_box/magazine/internal/shot/verminthrower
	slot_flags = ITEM_SLOT_HIP
	w_class = WEIGHT_CLASS_BULKY
	spread = 8
	recoil = 2
	force = 8
	cartridge_wording = "verminsphere"
	load_sound = 'modular_twilight_axis/firearms/sound/musketload.ogg'
	fire_sound = 'modular_twilight_axis/firearms/sound/fyrepowder/arquefire.ogg'
	vary_fire_sound = TRUE
	fire_sound_volume = 150
	anvilrepair = null
	smeltresult = /obj/item/ingot/steel
	var/misfire_chance = 10
	var/reload_time = 5
	damfactor = 0.75
	var/critfactor = 0.5
	var/npcdamfactor = 1.5
	var/cocked = FALSE
	var/overload = FALSE

/obj/item/gun/ballistic/revolver/grenadelauncher/verminthrower/getonmobprop(tag)
	. = ..()
	if(tag)
		switch(tag)
			if("gen")
				return list("shrink" = 0.4,"sx" = -10,"sy" = -8,"nx" = 13,"ny" = -8,"wx" = -8,"wy" = -7,"ex" = 7,"ey" = -8,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 30,"sturn" = -30,"wturn" = -30,"eturn" = 30,"nflip" = 0,"sflip" = 8,"wflip" = 8,"eflip" = 0)
			if("onbelt")
				return list("shrink" = 0.3,"sx" = -2,"sy" = -5,"nx" = 4,"ny" = -5,"wx" = 0,"wy" = -5,"ex" = 2,"ey" = -5,"nturn" = 0,"sturn" = 0,"wturn" = 0,"eturn" = 0,"nflip" = 0,"sflip" = 0,"wflip" = 0,"eflip" = 0,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0)

/obj/item/gun/ballistic/revolver/grenadelauncher/verminthrower/shoot_with_empty_chamber()
	if(cocked)
		playsound(src.loc, 'modular_twilight_axis/firearms/sound/musketcock.ogg', 100, FALSE)
	cocked = FALSE
	update_icon()

/obj/item/gun/ballistic/revolver/grenadelauncher/verminthrower/attack_self(mob/living/user)
	if(!cocked)
		to_chat(user, span_info("I prime the verminthrower."))
		var/adj_reload_time = reload_time
		if(ishuman(user))
			var/mob/living/carbon/human/H = user
			var/skill = H.get_skill_level(/datum/skill/combat/twilight_firearms)
			if(skill)
				adj_reload_time = max(1, reload_time / skill)
		if(move_after(user, adj_reload_time SECONDS, target = user))
			cocked = TRUE
			playsound(user, 'modular_twilight_axis/firearms/sound/musketcock.ogg', 100, FALSE)
	else
		overload = !overload
		if(overload)
			to_chat(user, span_warning("I crank the verminthrower into overload. This is a terrible idea."))
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
	. += span_info("Режимы: базовый поток верминфайра и спрей.")
	if(overload)
		. += span_warning("Перегрузка включена.")

/obj/item/gun/ballistic/revolver/grenadelauncher/verminthrower/proc/apply_overload_effects(mob/living/user)
	if(!overload)
		return
	user.adjustToxLoss(2)
	user.adjust_fire_stacks(1)
	if(prob(25))
		user.ignite_mob()

/obj/item/gun/ballistic/revolver/grenadelauncher/verminthrower/proc/find_vermin_pack(mob/living/user)
	if(!user)
		return null
	for(var/obj/item/storage/backpack/rogue/vermin_pack/P in user.contents)
		return P
	return null

/obj/item/gun/ballistic/revolver/grenadelauncher/verminthrower/proc/try_auto_load_from_pack(mob/living/user)
	if(chambered)
		return TRUE

	var/obj/item/storage/backpack/rogue/vermin_pack/P = find_vermin_pack(user)
	if(!P || !P.has_spheres())
		return FALSE

	var/obj/item/ammo_casing/caseless/verminsphere/S = P.take_sphere(src)
	if(!S)
		return FALSE

	attackby(S, user, null)

	if(chambered)
		return TRUE

	S.forceMove(P)
	return FALSE

/obj/item/gun/ballistic/revolver/grenadelauncher/verminthrower/proc/consume_round_or_fail(mob/living/user)
	if(chambered)
		return TRUE
	if(try_auto_load_from_pack(user))
		return TRUE
	to_chat(user, span_warning("[src] has no verminsphere loaded."))
	return FALSE

/obj/item/gun/ballistic/revolver/grenadelauncher/verminthrower/proc/spend_chambered_round()
	if(chambered)
		qdel(chambered)
		chambered = null

/obj/item/gun/ballistic/revolver/grenadelauncher/verminthrower/proc/apply_stream_effect_to_mob(mob/living/user, mob/living/L, turf/T, damage_mult)
	if(L == user)
		return

	L.adjust_fire_stacks(overload ? 2 : 1)
	L.ignite_mob()
	L.adjustToxLoss(round(3 * damage_mult))

	if(prob(overload ? 35 : 20))
		new /obj/effect/vermin_gas_cloud(T)

/obj/item/gun/ballistic/revolver/grenadelauncher/verminthrower/proc/do_stream_fire(mob/living/user)
	var/damage_mult = overload ? 1.35 : 1
	var/duration = 3 SECONDS
	var/interval = 2
	var/max_ticks = max(1, round(duration / interval))

	for(var/i in 1 to max_ticks)
		if(!user || user.stat || user.incapacitated())
			break

		var/current_dir = user.dir
		var/turf/user_turf = get_turf(user)
		var/user_angle = dir2angle(current_dir)

		for(var/p in 1 to 6)
			new /obj/effect/temp_visual/verminfire_particle(user_turf, current_dir)

		playsound(user_turf, 'sound/items/firelight.ogg', 40, TRUE)

		for(var/turf/T in view(3, user_turf))
			var/dist = get_dist(user_turf, T)
			if(dist == 0)
				continue

			var/target_angle = Get_Angle(user_turf, T)
			var/angle_diff = abs(closer_angle_difference(user_angle, target_angle))

			if(angle_diff <= 30)
				for(var/mob/living/L in T.contents)
					apply_stream_effect_to_mob(user, L, T, damage_mult)

		if(overload)
			apply_overload_effects(user)

		sleep(interval)

/obj/item/gun/ballistic/revolver/grenadelauncher/verminthrower/proc/prepare_spray_fire(atom/target, mob/living/user)
	for(var/obj/item/ammo_casing/CB in get_ammo_list(FALSE, TRUE))
		var/obj/projectile/bullet/verminfire_shot/BB = CB.BB
		if(!istype(BB))
			continue
		BB.damage = overload ? 22 : 16
		BB.range = overload ? 6 : 5
		BB.armor_penetration = overload ? 18 : 10

	spread = overload ? 20 : 14
	if(overload)
		misfire_chance = 18
	else
		misfire_chance = initial(misfire_chance)

	if(prob(misfire_chance))
		to_chat(user, span_warning("[src] violently misfires!"))
		explosion(src, light_impact_range = 1, heavy_impact_range = 1, smoke = TRUE)
		qdel(src)
		return FALSE

	var/dir = get_dir(src, target)
	var/datum/effect_system/smoke_spread/smoke = new
	smoke.set_up(1, get_step(src, dir))
	smoke.start()

	if(overload)
		apply_overload_effects(user)

	return TRUE

/obj/item/gun/ballistic/revolver/grenadelauncher/verminthrower/process_fire(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 0)
	if(!cocked)
		to_chat(user, span_warning("The pressure chamber is not primed."))
		return

	if(!consume_round_or_fail(user))
		return

	cocked = FALSE
	update_icon()

	if(istype(user.used_intent, /datum/intent/arc/verminthrower))
		if(!prepare_spray_fire(target, user))
			return
		return ..()

	spend_chambered_round()
	do_stream_fire(user)

/obj/item/ammo_box/magazine/internal/shot/verminthrower
	ammo_type = /obj/item/ammo_casing/caseless/verminsphere
	caliber = "verminsphere"
	max_ammo = 1
	start_empty = TRUE

/datum/intent/shoot/verminthrower
	chargedrain = 0

/datum/intent/shoot/verminthrower/get_chargetime()
	if(mastermob && chargetime)
		var/newtime = chargetime + 55
		newtime -= (mastermob.get_skill_level(/datum/skill/combat/twilight_firearms) * 12)
		newtime -= mastermob.STAPER
		return max(1, newtime)
	return chargetime

/datum/intent/arc/verminthrower
	chargetime = 1
	chargedrain = 0

/datum/intent/arc/verminthrower/get_chargetime()
	if(mastermob && chargetime)
		var/newtime = chargetime + 70
		newtime -= (mastermob.get_skill_level(/datum/skill/combat/twilight_firearms) * 10)
		newtime -= mastermob.STAPER
		return max(1, newtime)
	return chargetime

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

/obj/item/artillery_shell/end_rocket
	name = "end rocket"
	icon = 'modular_twilight_axis/awful_artillery/icons/artillery.dmi'
	icon_state = "cannonball"
	color = "#74ff5d"
	w_class = WEIGHT_CLASS_BULKY

/obj/item/artillery_shell/end_rocket/shell_action()
	var/turf/T = GET_TURF_ABOVE(get_turf(src))
	if(!T)
		T = get_turf(src)

	while(GET_TURF_ABOVE(T))
		T = GET_TURF_ABOVE(T)

	if(!T)
		T = get_turf(src)

	while(GET_TURF_BELOW(T) && istype(T, /turf/open/transparent))
		T = GET_TURF_BELOW(T)

	for(var/mob/M in GLOB.player_list)
		M.playsound_local(src, 'modular_twilight_axis/awful_artillery/sound/far_explosion.ogg', 100, FALSE, pressure_affected = FALSE)

	if(T)
		explosion(T, 6, 12, 24, flame_range = 5, smoke = TRUE, ignorecap = TRUE)
		new /obj/effect/vermin_gas_cloud(T)

		for(var/turf/AT in range(2, T))
			if(prob(80))
				new /obj/effect/vermin_gas_cloud(AT)
			if(prob(60))
				new /obj/effect/temp_visual/verminfire_flash(AT)

		for(var/mob/living/L in range(2, T))
			L.adjust_fire_stacks(4)
			L.ignite_mob()
			L.adjustToxLoss(10)

	qdel(src)

/obj/structure/artillery/end_rocket_rack
	name = "end rocket rack"
	desc = "Пусковая установка End Rocket."
	icon = 'modular_twilight_axis/awful_artillery/icons/artillery.dmi'
	icon_state = "mortar"
	elevation = 50
	elevation_min = 35
	elevation_max = 70
	ammo_type = /obj/item/artillery_shell/end_rocket
	charge_min = 1
	charge_max = 3
	cooldown = 30 SECONDS
	base_velocity = 8
	charge_velocity_step = 20

/obj/structure/artillery/end_rocket_rack/fire_artillery(mob/user)
	for(var/mob/M in GLOB.player_list)
		to_chat(M, span_userdanger("NUCLEAR LAUNCH DETECTED."))
		M.playsound_local(src, 'modular_twilight_axis/awful_artillery/sound/launch.ogg', 100, FALSE, pressure_affected = FALSE)
	. = ..()

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

/datum/crafting_recipe/roguetown/engineering/end_rocket
	name = "end rocket"
	result = /obj/item/artillery_shell/end_rocket
	reqs = list(
		/obj/item/verminstone = 10
	)
	verbage_simple = "assemble"
	verbage = "assembles"
	craftdiff = 5
	time = 30 SECONDS

/datum/crafting_recipe/roguetown/engineering/end_rocket_rack
	name = "end rocket rack"
	result = /obj/structure/artillery/end_rocket_rack
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
