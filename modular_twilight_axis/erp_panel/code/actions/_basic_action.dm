/datum/sex_action_panel
	/// Action name
	var/name = "Generic Action"
	/// Can be action present in panel
	abstract_type = TRUE
	/// Can action use penis knot
	var/can_knot = TRUE
	/// Sex organ requred to init action
	var/required_init
	/// Sex organ required to target
	var/required_target
	/// Armor slot that prevent action
	var/armor_slot_lock
	/// Whether this action can continue indefinitely
	var/continous = TRUE
	/// How long each iteration takes
	var/interaction_timer = 3 SECONDS
	/// How much stamina each iteration takes
	var/stamina_cost = 0.5
	/// Whether to check if user is incapacitated
	var/check_incapacitated = TRUE
	/// need to be on same tile
	var/check_same_tile = TRUE
	/// Whether this requires a grab
	var/require_grab = FALSE
	/// Minimum grab state required
	var/required_grab_state = GRAB_PASSIVE
	/// List of active sex process with characters
	var/list/datum/sex_session_lock/sex_locks = list()

/datum/sex_action_panel/proc/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(abstract_type)
		return FALSE
	return TRUE

/datum/sex_action_panel/proc/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	SHOULD_CALL_PARENT(TRUE)
	return TRUE

/datum/sex_action_panel/proc/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return null

/datum/sex_action_panel/proc/get_start_sound(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return null

/datum/sex_action_panel/proc/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return

/datum/sex_action_panel/proc/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	SHOULD_CALL_PARENT(TRUE)
	unlock_sex_object(user, target)

	var/message = get_finish_message(user, target)
	if(message)
		user.visible_message(message)

	return

/// Override this to provide the message shown when the action finishes (e.g., withdrawal message)
/datum/sex_action_panel/proc/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return null

/datum/sex_action_panel/proc/lock_sex_object(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return FALSE

/datum/sex_action_panel/proc/unlock_sex_object(mob/living/carbon/human/user, mob/living/carbon/human/target)
	for(var/datum/sex_session_lock/lock as anything in sex_locks)
		qdel(lock)
	sex_locks.Cut()

/datum/sex_action_panel/proc/check_sex_lock(mob/locked, organ_slot, obj/item/item)
	if(!organ_slot && !item)
		return FALSE
	for(var/datum/sex_session_lock/lock as anything in GLOB.locked_sex_objects)
		if(lock in sex_locks)
			continue
		if(lock.locked_host != locked)
			continue
		if(lock.locked_item != item && lock.locked_organ_slot != organ_slot)
			continue
		return TRUE
	return FALSE

/datum/sex_action_panel/proc/handle_climax_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return

/datum/sex_action_panel/proc/get_knot_count()
	return 0

/datum/sex_action_panel/proc/try_knot_on_climax(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(!can_knot)
		return FALSE

	var/datum/sex_session/session = get_sex_session(user, target)
	if(!session)
		return FALSE
	return SEND_SIGNAL(user, COMSIG_SEX_TRY_KNOT, target, session.force, get_knot_count())

/datum/sex_action_panel/proc/do_onomatopoeia(mob/living/carbon/human/user)
	user.balloon_alert_to_viewers("Plap!", x_offset = rand(-15, 15), y_offset = rand(0, 25))

/datum/sex_action_panel/proc/show_sex_effects(mob/living/carbon/human/user)
	for(var/i in 1 to rand(1, 3))
		if(!user.cmode) // Combat mode
			new /obj/effect/temp_visual/heart/sex_effects(get_turf(user))
		else
			new /obj/effect/temp_visual/heart/sex_effects/red_heart(get_turf(user))
