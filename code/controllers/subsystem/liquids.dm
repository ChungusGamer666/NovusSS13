SUBSYSTEM_DEF(liquids)
	name = "Liquid Turfs"
	wait = 1 SECONDS
	flags = SS_KEEP_TIMING | SS_NO_INIT
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME

	var/list/active_turfs = list()
	var/list/currentrun_active_turfs = list()

	var/list/active_groups = list()

	var/list/active_immutables = list()

	var/list/evaporation_queue = list()
	var/evaporation_counter = 0 //Only process evaporation on intervals

	var/list/processing_fire = list()
	var/fire_counter = 0 //Only process fires on intervals

	var/list/singleton_immutables = list()

	var/run_type = SSLIQUIDS_RUN_TYPE_TURFS

/datum/controller/subsystem/liquids/proc/get_immutable(type)
	if(!singleton_immutables[type])
		var/atom/movable/turf_liquid/immutable/new_one = new type()
		singleton_immutables[type] = new_one
	return singleton_immutables[type]


/datum/controller/subsystem/liquids/stat_entry(msg)
	msg += "AT:[active_turfs.len]|AG:[active_groups.len]|AIM:[active_immutables.len]|EQ:[evaporation_queue.len]|PF:[processing_fire.len]"
	return ..()


/datum/controller/subsystem/liquids/fire(resumed = FALSE)
	if(run_type == SSLIQUIDS_RUN_TYPE_TURFS)
		if(!currentrun_active_turfs.len && active_turfs.len)
			currentrun_active_turfs = active_turfs.Copy()
		for(var/turf/active_turf as anything in currentrun_active_turfs)
			if(MC_TICK_CHECK)
				return
			active_turf.process_liquid_cell()
			currentrun_active_turfs -= active_turf //work off of index later
		if(!currentrun_active_turfs.len)
			run_type = SSLIQUIDS_RUN_TYPE_GROUPS
	if (run_type == SSLIQUIDS_RUN_TYPE_GROUPS)
		for(var/datum/liquid_group/group as anything in active_groups)
			if(group.dirty)
				group.share()
				group.dirty = FALSE
			else if(!group.amount_of_active_turfs)
				group.decay_counter++
				if(group.decay_counter >= LIQUID_GROUP_DECAY_TIME)
					//Perhaps check if any turfs in here can spread before removing it? It's not unlikely they would
					group.break_group()
			if(MC_TICK_CHECK)
				run_type = SSLIQUIDS_RUN_TYPE_IMMUTABLES //No currentrun here for now
				return
		run_type = SSLIQUIDS_RUN_TYPE_IMMUTABLES

	if(run_type == SSLIQUIDS_RUN_TYPE_IMMUTABLES)
		for(var/turf/active_turf as anything in active_immutables)
			active_turf.process_immutable_liquid()
		run_type = SSLIQUIDS_RUN_TYPE_EVAPORATION

	if(run_type == SSLIQUIDS_RUN_TYPE_EVAPORATION)
		evaporation_counter++
		if(evaporation_counter >= REQUIRED_EVAPORATION_PROCESSES)
			for(var/turf/active_turf in evaporation_queue)
				if(prob(EVAPORATION_CHANCE))
					active_turf.liquids.process_evaporation()
				if(MC_TICK_CHECK)
					return
			evaporation_counter = 0
		run_type = SSLIQUIDS_RUN_TYPE_FIRE

	if(run_type == SSLIQUIDS_RUN_TYPE_FIRE)
		fire_counter++
		if(fire_counter >= REQUIRED_FIRE_PROCESSES)
			for(var/t in processing_fire)
				var/turf/T = t
				T.liquids.process_fire()
			if(MC_TICK_CHECK)
				return
			fire_counter = 0
		run_type = SSLIQUIDS_RUN_TYPE_TURFS

/datum/controller/subsystem/liquids/proc/add_active_turf(turf/T)
	if(!active_turfs[T])
		active_turfs[T] = TRUE
		if(T.lgroup)
			T.lgroup.amount_of_active_turfs++

/datum/controller/subsystem/liquids/proc/remove_active_turf(turf/T)
	if(active_turfs[T])
		active_turfs -= T
		if(T.lgroup)
			T.lgroup.amount_of_active_turfs--
