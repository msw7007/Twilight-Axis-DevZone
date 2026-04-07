/datum/advclass/mercenary/twilight_skaven_warpglobadier
	name = "Warpglobadier"
	tutorial = "Скавен-инженер, работающий с варп-огнём, ядовитым газом и нестабильными боеприпасами."
	allowed_sexes = list(MALE, FEMALE)
	allowed_races = RACES_ALL_KINDS
	outfit = /datum/outfit/job/roguetown/mercenary/twilight_skaven_warpglobadier
	maximum_possible_slots = 1
	min_pq = 25
	category_tags = list(CTAG_MERCENARY)
	traits_applied = list(TRAIT_MEDIUMARMOR)
	classes = list(
		"Warpglobadier" = "Безумный скавенский инженер. Делает варп-камень, крафтит глобосферы, заливает всё зелёным пламенем и в конце может устроить DOOM ROCKET."
	)
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
	extra_context = "Starts with a warp-sphere backpack and warp refinery blueprints."

/datum/outfit/job/roguetown/mercenary/twilight_skaven_warpglobadier/pre_equip(mob/living/carbon/human/H)
	..()

	backl = /obj/item/storage/backpack/rogue/skaven_warppack
	belt = /obj/item/storage/belt/rogue/pouch
	beltr = /obj/item/rogueweapon/huntingknife
	shoes = /obj/item/clothing/shoes/roguetown/boots
	gloves = /obj/item/clothing/gloves/roguetown/leather
	pants = /obj/item/clothing/under/roguetown/heavy_leather_pants
	shirt = /obj/item/clothing/suit/roguetown/armor/gambeson
	armor = /obj/item/clothing/suit/roguetown/armor/leather

	backpack_contents = list(
		/obj/item/paper/warp_refinery_blueprints = 1,
		/obj/item/warpstone = 1,
		/obj/item/ammo_casing/caseless/warp_sphere = 3
	)

/obj/item/paper/warp_refinery_blueprints
	name = "warp refinery blueprints"
	info = "Чертежи варп-перегонщика.\n\nПринимает очищенный люкс.\nКаждую минуту производит 1 варп-камень, если в буфере достаточно люкса.\n\nКрафт:\n- 3 варп-камня -> варп-огнемёт\n- 1 варп-камень -> 3 глобосферы\n- 10 варп-камней -> doom rocket"

/obj/item/warpstone
	name = "warpstone"
	desc = "Пульсирующий зелёный камень, от которого веет плохими решениями."
	icon = 'modular_twilight_axis/firearms/icons/ammo.dmi'
	icon_state = "musketball_proj"
	color = "#65ff55"
	w_class = WEIGHT_CLASS_SMALL
	sellprice = 25

/obj/item/ammo_casing/caseless/warp_sphere
	name = "warp sphere"
	desc = "Нестабильная глобосфера с варп-реактивом. Подходит и для броска, и для зарядки варп-огнемёта."
	icon = 'modular_twilight_axis/firearms/icons/ammo.dmi'
	icon_state = "musketball_proj"
	color = "#7dff65"
	caliber = "warp_sphere"
	projectile_type = /obj/projectile/bullet/warpflame_shot
	throwforce = 10
	w_class = WEIGHT_CLASS_SMALL

/obj/item/ammo_casing/caseless/warp_sphere/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	. = ..()
	var/turf/T = get_turf(src)
	if(T)
		new /obj/effect/warp_gas_cloud(T)
	qdel(src)

/obj/item/storage/backpack/rogue/skaven_warppack
	name = "warp pack"
	desc = "Специальный рюкзак на 9 глобосфер. Другой мусор туда не лезет."
	icon = 'modular_twilight_axis/firearms/icons/ammo.dmi'
	icon_state = "pouch1"
	slot_flags = ITEM_SLOT_BACK
	w_class = WEIGHT_CLASS_BULKY
	var/max_spheres = 9

/obj/item/storage/backpack/rogue/skaven_warppack/Initialize()
	. = ..()
	if(atom_storage)
		atom_storage.max_slots = max_spheres
		atom_storage.set_holdable(list(/obj/item/ammo_casing/caseless/warp_sphere))

/obj/item/storage/backpack/rogue/skaven_warppack/examine(mob/user)
	. = ..()
	var/current = 0
	for(var/obj/item/ammo_casing/caseless/warp_sphere/S in contents)
		current++
	. += span_info("Внутри сфер: [current] / [max_spheres].")

/obj/item/storage/backpack/rogue/skaven_warppack/proc/count_spheres()
	var/current = 0
	for(var/obj/item/ammo_casing/caseless/warp_sphere/S in contents)
		current++
	return current

/obj/item/storage/backpack/rogue/skaven_warppack/proc/take_sphere()
	for(var/obj/item/ammo_casing/caseless/warp_sphere/S in contents)
		S.forceMove(drop_location())
		return S
	return null

/obj/projectile/bullet/warpflame_shot
	name = "warp flame"
	icon = 'modular_twilight_axis/firearms/icons/ammo.dmi'
	icon_state = "musketball_proj"
	color = "#66ff55"
	damage = 16
	damage_type = BURN
	range = 5
	speed = 0.2
	flag = "magic"
	armor_penetration = 10

/obj/projectile/bullet/warpflame_shot/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(isliving(target))
		var/mob/living/L = target
		L.adjust_fire_stacks(2)
		L.ignite_mob()
		if(hascall(L, "adjustToxLoss"))
			call(L, "adjustToxLoss")(4)
		if(prob(35))
			new /obj/effect/temp_visual/warp_fire_flash(get_turf(L))
	var/turf/T = get_turf(target)
	if(T && prob(35))
		new /obj/effect/warp_gas_cloud(T)

/obj/effect/temp_visual/warp_fire_flash
	name = "warp fire"
	icon = 'icons/effects/effects.dmi'
	icon_state = "mech_fire"
	color = "#66ff55"
	duration = 8
	layer = ABOVE_MOB_LAYER
	appearance_flags = RESET_TRANSFORM | PIXEL_SCALE

/obj/effect/temp_visual/warp_fire_particle
	name = "warp fire breath"
	icon = 'icons/effects/effects.dmi'
	icon_state = "mech_fire"
	color = "#66ff55"
	duration = 8
	layer = ABOVE_MOB_LAYER
	appearance_flags = RESET_TRANSFORM | PIXEL_SCALE

/obj/effect/temp_visual/warp_fire_particle/Initialize(mapload, direction)
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

/obj/effect/warp_gas_cloud
	name = "warp gas"
	desc = "Тошнотворное зелёное облако варп-газа."
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
	var/next_tick = 0

/obj/effect/warp_gas_cloud/Initialize()
	. = ..()
	next_tick = world.time + tick_interval
	addtimer(CALLBACK(src, PROC_REF(pulse)), 5)
	addtimer(CALLBACK(src, PROC_REF(cleanup)), lifetime)

/obj/effect/warp_gas_cloud/process()
	if(world.time < next_tick)
		return
	next_tick = world.time + tick_interval
	for(var/mob/living/L in loc)
		apply_gas_effect(L)

/obj/effect/warp_gas_cloud/Crossed(atom/movable/AM)
	. = ..()
	if(isliving(AM))
		apply_gas_effect(AM)

/obj/effect/warp_gas_cloud/proc/pulse()
	if(QDELETED(src))
		return
	alpha = rand(160, 220)
	addtimer(CALLBACK(src, PROC_REF(pulse)), 5)

/obj/effect/warp_gas_cloud/proc/apply_gas_effect(mob/living/L)
	if(hascall(L, "adjustToxLoss"))
		call(L, "adjustToxLoss")(3)
	L.adjust_fire_stacks(1)
	if(prob(20))
		L.ignite_mob()

/obj/effect/warp_gas_cloud/proc/cleanup()
	qdel(src)

/obj/item/gun/ballistic/revolver/grenadelauncher/twilight_warpflamer
	name = "warpflamer"
	desc = "Нестабильный варп-огнемёт. Жрёт глобосферы как боеприпас."
	icon = 'modular_twilight_axis/firearms/icons/32.dmi'
	icon_state = "pistol2"
	item_state = "pistol2"
	var/icon_state_ready = "pistol2-1"
	var/default_icon_state = "pistol2"
	possible_item_intents = list(/datum/intent/shoot/twilight_warpflamer, /datum/intent/arc/twilight_warpflamer, INTENT_GENERIC)
	mag_type = /obj/item/ammo_box/magazine/internal/shot/twilight_warpflamer
	slot_flags = ITEM_SLOT_HIP
	w_class = WEIGHT_CLASS_BULKY
	spread = 8
	recoil = 2
	force = 8
	cartridge_wording = "warp sphere"
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

/obj/item/gun/ballistic/revolver/grenadelauncher/twilight_warpflamer/getonmobprop(tag)
	. = ..()
	if(tag)
		switch(tag)
			if("gen")
				return list("shrink" = 0.4,"sx" = -10,"sy" = -8,"nx" = 13,"ny" = -8,"wx" = -8,"wy" = -7,"ex" = 7,"ey" = -8,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 30,"sturn" = -30,"wturn" = -30,"eturn" = 30,"nflip" = 0,"sflip" = 8,"wflip" = 8,"eflip" = 0)
			if("onbelt")
				return list("shrink" = 0.3,"sx" = -2,"sy" = -5,"nx" = 4,"ny" = -5,"wx" = 0,"wy" = -5,"ex" = 2,"ey" = -5,"nturn" = 0,"sturn" = 0,"wturn" = 0,"eturn" = 0,"nflip" = 0,"sflip" = 0,"wflip" = 0,"eflip" = 0,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0)

/obj/item/gun/ballistic/revolver/grenadelauncher/twilight_warpflamer/shoot_with_empty_chamber()
	if(cocked)
		playsound(src.loc, 'modular_twilight_axis/firearms/sound/musketcock.ogg', 100, FALSE)
	cocked = FALSE
	update_icon()

/obj/item/gun/ballistic/revolver/grenadelauncher/twilight_warpflamer/attack_self(mob/living/user)
	if(!cocked)
		to_chat(user, span_info("I prime the warpflamer."))
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
			to_chat(user, span_warning("I crank the warpflamer into overload. This is a terrible idea."))
		else
			to_chat(user, span_notice("I return the warpflamer to a safer pressure level."))
	update_icon()

/obj/item/gun/ballistic/revolver/grenadelauncher/twilight_warpflamer/update_icon()
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

/obj/item/gun/ballistic/revolver/grenadelauncher/twilight_warpflamer/examine(mob/user)
	. = ..()
	. += span_info("Режимы: базовый поток варп-пламени и спрей.")
	if(overload)
		. += span_warning("Перегрузка включена.")

/obj/item/gun/ballistic/revolver/grenadelauncher/twilight_warpflamer/attackby(obj/item/A, mob/user, params)
	return ..()

/obj/item/gun/ballistic/revolver/grenadelauncher/twilight_warpflamer/proc/apply_overload_effects(mob/living/user)
	if(!overload)
		return
	if(hascall(user, "adjustToxLoss"))
		call(user, "adjustToxLoss")(2)
	user.adjust_fire_stacks(1)
	if(prob(25))
		user.ignite_mob()

/obj/item/gun/ballistic/revolver/grenadelauncher/twilight_warpflamer/proc/do_stream_fire(mob/living/user)
	var/damage_mult = overload ? 1.35 : 1
	var/duration = 3 SECONDS
	var/interval = 2
	var/max_ticks = max(1, round(duration / interval))

	spawn(0)
		for(var/i in 1 to max_ticks)
			if(!user || user.stat || user.incapacitated())
				break

			var/current_dir = user.dir
			var/turf/user_turf = get_turf(user)
			var/user_angle = dir2angle(current_dir)

			for(var/p in 1 to 6)
				new /obj/effect/temp_visual/warp_fire_particle(user_turf, current_dir)

			playsound(user_turf, 'sound/items/firelight.ogg', 40, TRUE)

			for(var/turf/T in view(3, user_turf))
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

						if(hascall(L, "adjustToxLoss"))
							call(L, "adjustToxLoss")(round(3 * damage_mult))

						if(prob(overload ? 35 : 20))
							new /obj/effect/warp_gas_cloud(T)

			if(overload)
				apply_overload_effects(user)

			sleep(interval)

/obj/item/gun/ballistic/revolver/grenadelauncher/twilight_warpflamer/proc/do_spray_fire(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 0)
	for(var/obj/item/ammo_casing/CB in get_ammo_list(FALSE, TRUE))
		var/obj/projectile/bullet/warpflame_shot/BB = CB.BB
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
		return

	var/dir = get_dir(src, target)
	var/datum/effect_system/smoke_spread/smoke = new
	smoke.set_up(1, get_step(src, dir))
	smoke.start()

	if(overload)
		apply_overload_effects(user)

	..()

/obj/item/gun/ballistic/revolver/grenadelauncher/twilight_warpflamer/process_fire(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 0)
	if(!cocked)
		to_chat(user, span_warning("The pressure chamber is not primed."))
		return

	cocked = FALSE
	update_icon()

	if(istype(user.used_intent, /datum/intent/arc/twilight_warpflamer))
		do_spray_fire(target, user, message, params, zone_override, bonus_spread)
	else
		do_stream_fire(user)

/obj/item/ammo_box/magazine/internal/shot/twilight_warpflamer
	ammo_type = /obj/item/ammo_casing/caseless/warp_sphere
	caliber = "warp_sphere"
	max_ammo = 1
	start_empty = TRUE

/datum/intent/shoot/twilight_warpflamer
	chargedrain = 0

/datum/intent/shoot/twilight_warpflamer/get_chargetime()
	if(mastermob && chargetime)
		var/newtime = chargetime + 55
		newtime -= (mastermob.get_skill_level(/datum/skill/combat/twilight_firearms) * 12)
		newtime -= mastermob.STAPER
		return max(1, newtime)
	return chargetime

/datum/intent/arc/twilight_warpflamer
	chargetime = 1
	chargedrain = 0

/datum/intent/arc/twilight_warpflamer/get_chargetime()
	if(mastermob && chargetime)
		var/newtime = chargetime + 70
		newtime -= (mastermob.get_skill_level(/datum/skill/combat/twilight_firearms) * 10)
		newtime -= mastermob.STAPER
		return max(1, newtime)
	return chargetime

/obj/machinery/warp_refinery
	name = "warp refinery"
	desc = "Перерабатывает очищенный люкс в варп-камни. Опасно шумит и светится нездоровым зелёным."
	icon = 'modular_twilight_axis/awful_artillery/icons/artillery.dmi'
	icon_state = "mortar_base"
	density = TRUE
	anchored = TRUE
	var/stored_lux = 0
	var/lux_per_stone = 5
	var/cycle_time = 1 MINUTES

/obj/machinery/warp_refinery/Initialize()
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(process_cycle)), cycle_time)

/obj/machinery/warp_refinery/examine(mob/user)
	. = ..()
	. += span_info("Stored lux: [stored_lux].")
	. += span_info("Every minute it tries to produce 1 warpstone.")

/obj/machinery/warp_refinery/proc/is_valid_lux_item(obj/item/I)
	if(!I)
		return FALSE
	if(findtext(lowertext(I.name), "lux"))
		return TRUE
	if("purified" in I.vars && I.vars["purified"])
		return TRUE
	return FALSE

/obj/machinery/warp_refinery/attackby(obj/item/I, mob/user, params)
	if(is_valid_lux_item(I))
		stored_lux++
		to_chat(user, span_notice("I feed [I] into [src]."))
		qdel(I)
		return
	return ..()

/obj/machinery/warp_refinery/proc/process_cycle()
	if(QDELETED(src))
		return
	if(stored_lux >= lux_per_stone)
		stored_lux -= lux_per_stone
		new /obj/item/warpstone(get_turf(src))
		playsound(src, 'modular_twilight_axis/awful_artillery/sound/loading.ogg', 75, FALSE)
	addtimer(CALLBACK(src, PROC_REF(process_cycle)), cycle_time)

/obj/item/artillery_shell/doom_rocket
	name = "doom rocket"
	icon = 'modular_twilight_axis/awful_artillery/icons/artillery.dmi'
	icon_state = "cannonball"
	color = "#74ff5d"
	w_class = WEIGHT_CLASS_BULKY

/obj/item/artillery_shell/doom_rocket/shell_action()
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
		new /obj/effect/warp_gas_cloud(T)

		for(var/turf/AT in range(2, T))
			if(prob(80))
				new /obj/effect/warp_gas_cloud(AT)
			if(prob(60))
				new /obj/effect/temp_visual/warp_fire_flash(AT)

		for(var/mob/living/L in range(2, T))
			L.adjust_fire_stacks(4)
			L.ignite_mob()
			if(hascall(L, "adjustToxLoss"))
				call(L, "adjustToxLoss")(10)

	qdel(src)

/obj/structure/artillery/doom_rocket_rack
	name = "doom rocket rack"
	desc = "Пусковая установка для ракеты Судного Дня. Слишком громкая, слишком заметная и слишком по-скавенски."
	icon = 'modular_twilight_axis/awful_artillery/icons/artillery.dmi'
	icon_state = "mortar"
	elevation = 50
	elevation_min = 35
	elevation_max = 70
	ammo_type = /obj/item/artillery_shell/doom_rocket
	charge_min = 1
	charge_max = 3
	cooldown = 30 SECONDS
	base_velocity = 8
	charge_velocity_step = 20

/obj/structure/artillery/doom_rocket_rack/fire_artillery(mob/user)
	for(var/mob/M in GLOB.player_list)
		to_chat(M, span_userdanger("NUCLEAR LAUNCH DETECTED."))
		M.playsound_local(src, 'modular_twilight_axis/awful_artillery/sound/launch.ogg', 100, FALSE, pressure_affected = FALSE)
	. = ..()

/datum/crafting_recipe/roguetown/engineering/warp_refinery
	name = "warp refinery"
	result = /obj/machinery/warp_refinery
	reqs = list(
		/obj/item/ingot/steel = 2,
		/obj/item/grown/log/tree = 2,
		/obj/item/natural/wood/plank = 2
	)
	verbage_simple = "assemble"
	verbage = "assembles"
	craftdiff = 3
	time = 20 SECONDS

/datum/crafting_recipe/roguetown/engineering/twilight_warpflamer
	name = "warpflamer"
	result = /obj/item/gun/ballistic/revolver/grenadelauncher/twilight_warpflamer
	reqs = list(
		/obj/item/warpstone = 3,
		/obj/item/ingot/steel = 1,
		/obj/item/natural/wood/plank = 1
	)
	verbage_simple = "assemble"
	verbage = "assembles"
	craftdiff = 4
	time = 15 SECONDS

/datum/crafting_recipe/roguetown/engineering/warp_spheres
	name = "warp spheres x3"
	result = /obj/item/ammo_casing/caseless/warp_sphere
	reqs = list(
		/obj/item/warpstone = 1
	)
	verbage_simple = "shape"
	verbage = "shapes"
	craftdiff = 2
	time = 5 SECONDS

/datum/crafting_recipe/roguetown/engineering/warp_spheres/make_result(mob/user, turf/location)
	. = ..()
	new /obj/item/ammo_casing/caseless/warp_sphere(location)
	new /obj/item/ammo_casing/caseless/warp_sphere(location)

/datum/crafting_recipe/roguetown/engineering/doom_rocket
	name = "doom rocket"
	result = /obj/item/artillery_shell/doom_rocket
	reqs = list(
		/obj/item/warpstone = 10
	)
	verbage_simple = "assemble"
	verbage = "assembles"
	craftdiff = 5
	time = 30 SECONDS

/datum/crafting_recipe/roguetown/engineering/doom_rocket_rack
	name = "doom rocket rack"
	result = /obj/structure/artillery/doom_rocket_rack
	reqs = list(
		/obj/item/ingot/steel = 3,
		/obj/item/grown/log/tree = 2,
		/obj/item/natural/wood/plank = 2
	)
	verbage_simple = "assemble"
	verbage = "assembles"
	craftdiff = 4
	time = 20 SECONDS
