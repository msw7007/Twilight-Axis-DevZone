/datum/component/carry_small
	dupe_mode = COMPONENT_DUPE_UNIQUE

	var/mob/living/carrier
	var/mob/living/carried

	var/carry_hand = 1

	var/matrix/original_transform
	var/original_layer
	var/original_pixel_x
	var/original_pixel_y
	var/original_dir

	var/scale_factor = 0.75
	var/pixel_y_base = 4
	var/pixel_x_side = 5
	var/layer_delta = 0.2

/datum/component/carry_small/Initialize(mob/living/target, hand = 1)
	. = ..()
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE

	carrier = parent
	carried = target
	carry_hand = hand

	if(!can_start())
		return COMPONENT_INCOMPATIBLE

	apply_carry()

	RegisterSignal(carrier, COMSIG_ATOM_DIR_CHANGE, PROC_REF(on_carrier_dir_change))
	RegisterSignal(carrier, COMSIG_MOVABLE_MOVED, PROC_REF(on_carrier_moved))
	RegisterSignal(carrier, COMSIG_LIVING_CMODE_CHANGED, PROC_REF(on_cmode_changed))
	RegisterSignal(carried, COMSIG_LIVING_CMODE_CHANGED, PROC_REF(on_cmode_changed))
	RegisterSignal(carried, COMSIG_LIVING_RESIST, PROC_REF(on_carried_resist))
	RegisterSignal(carrier, COMSIG_LIVING_PULL_CHANGED, PROC_REF(on_pull_changed))
	RegisterSignal(carrier, COMSIG_PARENT_QDELETING, PROC_REF(on_parent_qdel))
	RegisterSignal(carried, COMSIG_PARENT_QDELETING, PROC_REF(on_parent_qdel))

/datum/component/carry_small/Destroy(force, ...)
	cleanup()
	return ..()

/datum/component/carry_small/proc/can_start()
	if(!carrier || !carried)
		return FALSE
	if(carrier == carried)
		return FALSE
	if(carrier.cmode || carried.cmode)
		return FALSE
	if(!carried.can_be_carried())
		return FALSE
	if(carrier.pulling != carried)
		return FALSE
	if(carried.buckled)
		return FALSE
	return TRUE

/datum/component/carry_small/proc/apply_carry()
	if(!do_buckle())
		qdel(src)
		return

	original_transform = carried.transform
	original_layer = carried.layer
	original_pixel_x = carried.pixel_x
	original_pixel_y = carried.pixel_y
	original_dir = carried.dir

	var/matrix/t
	if(original_transform)
		t = matrix(original_transform)
	else
		t = matrix()

	t.Scale(scale_factor, scale_factor)
	carried.transform = t

	update_visual()

/datum/component/carry_small/proc/cleanup()
	if(!carrier || !carried)
		return

	do_unbuckle()

	carried.transform = original_transform
	carried.layer = original_layer
	carried.pixel_x = original_pixel_x
	carried.pixel_y = original_pixel_y
	carried.setDir(original_dir)

	carrier = null
	carried = null

/datum/component/carry_small/proc/update_visual()
	if(!carrier || !carried)
		return

	var/is_right = (carry_hand == 1)
	var/side = is_right ? pixel_x_side : -pixel_x_side

	var/x = 0
	var/y = pixel_y_base

	switch(carrier.dir)
		if(SOUTH)
			x = side
			carried.setDir(is_right ? EAST : WEST)
		if(NORTH)
			x = -side
			carried.setDir(is_right ? WEST : EAST)
		if(EAST)
			x = side
			carried.setDir(is_right ? NORTH : SOUTH)
		if(WEST)
			x = -side
			carried.setDir(is_right ? SOUTH : NORTH)

	carried.pixel_x = x
	carried.pixel_y = y
	var/base_layer = carrier.layer
	if(carrier.dir == NORTH)
		carried.layer = base_layer - layer_delta
	else
		carried.layer = base_layer + layer_delta

/datum/component/carry_small/proc/on_carrier_dir_change(datum/source, old_dir, new_dir)
	SIGNAL_HANDLER
	update_visual()

/datum/component/carry_small/proc/on_carrier_moved(datum/source)
	SIGNAL_HANDLER
	update_visual()

/datum/component/carry_small/proc/on_cmode_changed(datum/source, new_cmode)
	SIGNAL_HANDLER
	if(new_cmode)
		qdel(src)

/datum/component/carry_small/proc/on_pull_changed(datum/source, new_pulling)
	SIGNAL_HANDLER
	if(new_pulling != carried)
		qdel(src)

/datum/component/carry_small/proc/on_carried_resist(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/component/carry_small/proc/on_parent_qdel(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/component/carry_small/proc/do_buckle()
	if(!carrier || !carried)
		return FALSE

	if(carried.buckled)
		return FALSE

	return carrier.buckle_mob(carried, TRUE, TRUE, FALSE, 0, 0)

/datum/component/carry_small/proc/do_unbuckle()
	if(!carried)
		return

	if(carried.buckled)
		var/atom/movable/buckler = carried.buckled
		buckler.unbuckle_mob(carried, TRUE)
