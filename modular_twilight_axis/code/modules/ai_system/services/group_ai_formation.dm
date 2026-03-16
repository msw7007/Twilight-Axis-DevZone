// Group AI — formation slots around target.

/datum/group_ai_formation
	var/atom/target      = null
	var/orientation       = SOUTH
	var/list/slot_turfs   = list()
	var/list/slot_roles   = list()  // slot_id → allowed role flag
	var/list/guard_ring   = list()
	var/list/support_ring = list()

/datum/group_ai_formation/proc/setup(atom/T, direction)
	if(!T) return
	target      = T
	orientation = group_ai_sanitize_dir(direction)
	slot_turfs.Cut()
	slot_roles.Cut()
	guard_ring.Cut()
	support_ring.Cut()
	build_slots()
	build_rings()

/datum/group_ai_formation/proc/build_slots()
	var/turf/base = get_turf(target)
	if(!base) return
	var/front = orientation
	var/left  = group_ai_dir_left(front)
	var/right = group_ai_dir_right(front)
	var/back  = turn(front, 180)

	slot_turfs[GROUP_AI_SLOT_FRONT]       = get_step(base, front)
	slot_turfs[GROUP_AI_SLOT_FRONT_LEFT]  = get_step(get_step(base, front), left)
	slot_turfs[GROUP_AI_SLOT_FRONT_RIGHT] = get_step(get_step(base, front), right)
	slot_turfs[GROUP_AI_SLOT_LEFT]        = get_step(base, left)
	slot_turfs[GROUP_AI_SLOT_RIGHT]       = get_step(base, right)
	slot_turfs[GROUP_AI_SLOT_BACK]        = get_step(base, back)
	slot_turfs[GROUP_AI_SLOT_BACK_LEFT]   = get_step(get_step(base, back), left)
	slot_turfs[GROUP_AI_SLOT_BACK_RIGHT]  = get_step(get_step(base, back), right)

	// Per ТЗ: front=tank, front sides=mdd, back=control (kept open)
	slot_roles[GROUP_AI_SLOT_FRONT]       = GROUP_AI_ROLE_TANK
	slot_roles[GROUP_AI_SLOT_FRONT_LEFT]  = GROUP_AI_ROLE_MDD
	slot_roles[GROUP_AI_SLOT_FRONT_RIGHT] = GROUP_AI_ROLE_MDD
	slot_roles[GROUP_AI_SLOT_LEFT]        = GROUP_AI_ROLE_MDD
	slot_roles[GROUP_AI_SLOT_RIGHT]       = GROUP_AI_ROLE_MDD
	slot_roles[GROUP_AI_SLOT_BACK]        = GROUP_AI_ROLE_CONTROL
	slot_roles[GROUP_AI_SLOT_BACK_LEFT]   = GROUP_AI_ROLE_MDD
	slot_roles[GROUP_AI_SLOT_BACK_RIGHT]  = GROUP_AI_ROLE_MDD

/datum/group_ai_formation/proc/build_rings()
	var/turf/base = get_turf(target)
	if(!base) return
	for(var/dir in group_ai_cardinals())
		var/turf/two = get_step(get_step(base, dir), dir)
		if(group_ai_is_open_turf(two)) guard_ring += two
	for(var/dir in group_ai_cardinals())
		var/turf/three = get_step(get_step(get_step(base, dir), dir), dir)
		if(group_ai_is_open_turf(three)) support_ring += three