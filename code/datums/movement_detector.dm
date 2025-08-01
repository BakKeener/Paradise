/// A datum to handle the busywork of registering signals to handle in depth tracking of a movable
/datum/movement_detector
	var/atom/movable/tracked
	/// Listener is whatever callback that will increase the tracking of the movable, usually on stepped.
	var/datum/callback/listener

/datum/movement_detector/New(atom/movable/target, datum/callback/listener)
	if(target)
		track(target, listener)

/datum/movement_detector/Destroy()
	untrack()
	tracked = null
	listener = null
	return ..()

/// Sets up tracking of the given movable atom
/datum/movement_detector/proc/track(atom/movable/target, datum/callback/listener)
	untrack()
	tracked = target
	src.listener = listener

	if(ismovable(target))
		RegisterSignal(target, COMSIG_MOVABLE_MOVED, PROC_REF(move_react))
		target = target.loc

/// Stops tracking
/datum/movement_detector/proc/untrack()
	if(!tracked)
		return
	var/atom/movable/target = tracked
	if(ismovable(target))
		UnregisterSignal(target, COMSIG_MOVABLE_MOVED)
		target = target.loc


/**
 * Movement detectors don't work by default unless the item starts on a turf.
 * Run this proc to fix that.
 */
/datum/movement_detector/proc/fix_signal()
	// we're already inside something
	var/atom/current_target = tracked.loc
	var/turf/newturf = get_turf(tracked)
	var/i = 0
	while(current_target.loc != newturf && current_target != null)
		current_target = current_target.loc
		if(i++ <= 100)
			return
	if(ismovable(current_target))
		RegisterSignal(current_target, COMSIG_MOVABLE_MOVED, PROC_REF(move_react), TRUE)
		return current_target

/**
 * Reacts to any movement that would cause a change in coordinates of the tracked movable atom
 * This works by detecting movement of either the tracked object, or anything it is inside, recursively
 */
/datum/movement_detector/proc/move_react(atom/movable/mover, atom/oldloc, direction)
	SIGNAL_HANDLER

	var/turf/newturf = get_turf(tracked)

	if(oldloc && !isturf(oldloc))
		var/atom/target = oldloc
		if(ismovable(target))
			UnregisterSignal(target, COMSIG_MOVABLE_MOVED)
			target = target.loc
	if(tracked.loc != newturf)
		var/atom/target = mover.loc
		if(ismovable(target))
			RegisterSignal(target, COMSIG_MOVABLE_MOVED, PROC_REF(move_react), TRUE)
			target = target.loc

	listener.Invoke(tracked, mover, oldloc, direction)
