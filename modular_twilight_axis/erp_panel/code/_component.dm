/datum/component/arousal/proc/spread_climax_to_partners(mob/living/carbon/human/source)
	if(!source)
		return

	var/list/sessions = return_sessions_with_user_tgui(source)
	if(!length(sessions))
		return

	var/list/affected = list()

	for(var/datum/sex_session_tgui/S in sessions)
		if(QDELETED(S))
			continue

		if(istype(S.user, /mob/living/carbon/human) && S.user != source)
			affected |= S.user

		if(istype(S.target, /mob/living/carbon/human) && S.target != source)
			affected |= S.target

		for(var/mob/living/carbon/human/M in S.partners)
			if(M != source)
				affected |= M

	for(var/mob/living/carbon/human/M in affected)
		if(QDELETED(M) || M.stat == DEAD)
			continue

		var/is_nympho = FALSE

		if(M.has_flaw(/datum/charflaw/addiction/lovefiend))
			is_nympho = TRUE

		var/bonus = is_nympho ? 20 : 10

		SEND_SIGNAL(M, COMSIG_SEX_ADJUST_AROUSAL, bonus)

/datum/component/arousal/after_ejaculation(intimate = FALSE, mob/living/carbon/human/user, mob/living/carbon/human/target)
	spread_climax_to_partners(user)

	.=..()

/datum/component/arousal/ejaculate()
	var/mob/living/mob = parent

	var/list/parent_sessions = return_sessions_with_user_tgui(parent)
	var/datum/sex_action_session/highest_priority = return_highest_priority_action_tgui(parent_sessions, parent)

	playsound(parent, 'sound/misc/mat/endout.ogg', 50, TRUE, ignore_walls = FALSE)

	if(!mob.getorganslot(ORGAN_SLOT_TESTICLES) && mob.getorganslot(ORGAN_SLOT_PENIS))
		mob.visible_message(span_love("[mob] climaxes, yet nothing is released!"))
		after_ejaculation(FALSE, parent)
		return

	if(!highest_priority)
		mob.visible_message(span_love("[mob] makes a mess!"))
		var/turf/turf = get_turf(parent)
		new /obj/effect/decal/cleanable/coom(turf)
		after_ejaculation(FALSE, parent)
		return

	var/datum/sex_action_session/S = highest_priority
	var/mob/living/carbon/human/U = S.session.user
	var/mob/living/carbon/human/T = S.session.target
	var/datum/sex_panel_action/A = S.action

	var/return_type = A.handle_climax_message(U, T)
	if(!return_type)
		mob.visible_message(span_love("[mob] makes a mess!"))
		var/turf/turf2 = get_turf(parent)
		new /obj/effect/decal/cleanable/coom(turf2)
		after_ejaculation(FALSE, U, T)
	else
		handle_climax(return_type, U, T)
		after_ejaculation(return_type == "into" || return_type == "oral", U, T)

	if(S.session.do_knot_action && A.can_knot)
		A.try_knot_on_climax(U, T)
