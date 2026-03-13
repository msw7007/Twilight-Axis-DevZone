/datum/group_ai_signal
	var/id
	var/source
	var/atom/target
	var/list/context
	var/time

/datum/group_ai_signal/New(_id, _source, atom/_target, list/_context)
	..()
	id = _id
	source = _source
	target = _target
	context = _context || list()
	time = world.time
