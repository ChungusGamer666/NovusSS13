/obj/effect/decal/cleanable/blood/hitsplatter
	name = "blood splatter"
	icon_state = "hitsplatter1"
	random_icon_states = list("hitsplatter1", "hitsplatter2", "hitsplatter3")
	pass_flags = PASSTABLE | PASSGRILLE
	/// The turf we just came from, so we can back up when we hit a wall
	var/turf/prev_loc
	/// How many tiles/items/people we can paint red
	var/splatter_strength = 3
	/// Hitsplatter angle
	var/angle = 0
	/// Type of squirt decals we should try to create when moving
	var/squirt_type = /obj/effect/decal/cleanable/blood/splatter/stacking/squirt

/obj/effect/decal/cleanable/blood/hitsplatter/Initialize(mapload, splatter_strength, angle)
	. = ..()
	prev_loc = loc //Just so we are sure prev_loc exists
	if(splatter_strength)
		src.splatter_strength = splatter_strength
	if(angle)
		src.angle = angle

/// Set the splatter up to fly through the air until it rounds out of steam or hits something
/obj/effect/decal/cleanable/blood/hitsplatter/proc/fly_towards(turf/target_turf, range)
	var/delay = 2
	var/datum/move_loop/loop = SSmove_manager.move_towards(src, target_turf, delay, timeout = delay * range, priority = MOVEMENT_ABOVE_SPACE_PRIORITY, flags = MOVEMENT_LOOP_START_FAST)
	RegisterSignal(loop, COMSIG_MOVELOOP_PREPROCESS_CHECK, PROC_REF(pre_move))
	RegisterSignal(loop, COMSIG_MOVELOOP_POSTPROCESS, PROC_REF(post_move))
	RegisterSignal(loop, COMSIG_QDELETING, PROC_REF(loop_done))

/obj/effect/decal/cleanable/blood/hitsplatter/proc/pre_move(datum/move_loop/source)
	SIGNAL_HANDLER
	prev_loc = loc

/obj/effect/decal/cleanable/blood/hitsplatter/proc/post_move(datum/move_loop/source)
	SIGNAL_HANDLER
	var/list/blood_dna_info = GET_ATOM_BLOOD_DNA(src)
	for(var/atom/iter_atom in get_turf(src))
		if(splatter_strength <= 0)
			break

		if(isitem(iter_atom))
			iter_atom.add_blood_DNA(blood_dna_info)
			splatter_strength--
		else if(ishuman(iter_atom))
			var/mob/living/carbon/human/splashed_human = iter_atom
			if(!splashed_human.is_eyes_covered())
				splashed_human.adjust_eye_blur(3)
				to_chat(splashed_human, span_userdanger("You're blinded by a spray of blood!"))
			if(splashed_human.glasses)
				splashed_human.glasses.add_blood_DNA(blood_dna_info)
				splashed_human.update_worn_glasses() //updates mob overlays to show the new blood (no refresh)
			if(splashed_human.wear_mask)
				splashed_human.wear_mask.add_blood_DNA(blood_dna_info)
				splashed_human.update_worn_mask() //updates mob overlays to show the new blood (no refresh)
			if(splashed_human.wear_suit)
				splashed_human.wear_suit.add_blood_DNA(blood_dna_info)
				splashed_human.update_worn_oversuit() //updates mob overlays to show the new blood (no refresh)
			if(splashed_human.w_uniform)
				splashed_human.w_uniform.add_blood_DNA(blood_dna_info)
				splashed_human.update_worn_undersuit() //updates mob overlays to show the new blood (no refresh)
			splatter_strength--
	if(splatter_strength <= 0) // we used all the puff so we delete it.
		qdel(src)
		return

	if(!isturf(loc))
		return

	var/obj/effect/decal/cleanable/splatter
	if(!ispath(squirt_type, /obj/effect/decal/cleanable/blood/splatter/stacking))
		splatter = new squirt_type(loc)
	else
		var/obj/effect/decal/cleanable/blood/splatter/stacking/stacker = locate(/obj/effect/decal/cleanable/blood/splatter/stacking) in loc
		var/angle = prev_loc != loc ? angle2dir(get_dir(prev_loc, loc)) : src.angle
		if(!stacker)
			stacker = new squirt_type(loc, angle)
			stacker.bloodiness = src.bloodiness
			stacker.update_appearance(UPDATE_ICON)
			stacker.alpha = 0
			animate(stacker, alpha = 255, time = 2)
		else
			var/obj/effect/decal/cleanable/blood/splatter/stacking/other_splatter = new squirt_type(null, angle)
			other_splatter.forceMove(loc)
			other_splatter.bloodiness = src.bloodiness
			other_splatter.update_appearance(UPDATE_ICON)
			other_splatter.alpha = 0
			animate(other_splatter, alpha = stacker.alpha, time = 2)
			animate(other_splatter, color = stacker.color, time = 2)
			addtimer(CALLBACK(other_splatter, TYPE_PROC_REF(/obj/effect/decal/cleanable/blood/splatter/stacking, delayed_merge), stacker), 2)
		splatter = stacker
	var/list/our_blood_dna = GET_ATOM_BLOOD_DNA(src)
	if(our_blood_dna)
		splatter.add_blood_DNA(our_blood_dna)
	qdel(src)

/obj/effect/decal/cleanable/blood/hitsplatter/proc/loop_done(datum/source)
	SIGNAL_HANDLER
	if(!QDELETED(src))
		qdel(src)

/obj/effect/decal/cleanable/blood/hitsplatter/Bump(atom/bumped_atom)
	. = ..()
	if(!iswallturf(bumped_atom) && !istype(bumped_atom, /obj/structure/window))
		qdel(src)
		return

	if(istype(bumped_atom, /obj/structure/window))
		var/obj/structure/window/bumped_window = bumped_atom
		if(!bumped_window.fulltile)
			qdel(src)
			return

	if(iswallturf(bumped_atom) && isopenturf(loc))
		//Adjust pixel offset to make splatters appear on the wall
		var/obj/effect/decal/cleanable/blood/splatter/over_window/final_splatter = new(loc)
		final_splatter.add_blood_DNA(GET_ATOM_BLOOD_DNA(src))
		var/dir_to_wall = get_dir(src, bumped_atom)
		final_splatter.pixel_x = (dir_to_wall & EAST ? world.icon_size : (dir_to_wall & WEST ? -world.icon_size : 0))
		final_splatter.pixel_y = (dir_to_wall & NORTH ? world.icon_size : (dir_to_wall & SOUTH ? -world.icon_size : 0))
		final_splatter.alpha = 0
		animate(final_splatter, alpha = initial(final_splatter.alpha), time = 2)
	else if(istype(bumped_atom, /obj/structure/window))
		//special window case
		var/obj/structure/window/window = bumped_atom
		window.become_bloodied()
	else
		bumped_atom.add_blood_DNA(GET_ATOM_BLOOD_DNA(src))
	qdel(src)
