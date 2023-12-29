/// Blood drip subtype meant to be thrown around as a particle
/obj/effect/decal/cleanable/blood/particle
	name = "blood droplet"
	icon_state = "drip5" //using drip5 since the others tend to blend in with pipes & wires.
	random_icon_states = list("drip1","drip2","drip3","drip4","drip5")
	plane = GAME_PLANE
	layer = BELOW_MOB_LAYER
	should_dry = FALSE
	bloodiness = BLOOD_AMOUNT_PER_DECAL * 0.1
	mergeable_decal = FALSE
	/// Splatter type we create when we bounce on the floor
	var/obj/effect/decal/cleanable/splatter_type_floor = /obj/effect/decal/cleanable/blood/splatter/stacking
	/// Splatter type we create when we bump on a wall
	var/obj/effect/decal/cleanable/splatter_type_wall = /obj/effect/decal/cleanable/blood/splatter/over_window
	/// Whether or not we transfer our pixel_x and pixel_y to the splatter, only works for floor splatters though
	var/messy_splatter = TRUE

/obj/effect/decal/cleanable/blood/particle/can_bloodcrawl_in()
	return FALSE

/obj/effect/decal/cleanable/blood/particle/proc/start_movement(movement_angle)
	var/datum/component/movable_physics/movable_physics = GetComponent(/datum/component/movable_physics)
	if(!movable_physics)
		movable_physics = initialize_physics()
	if(!isnull(movement_angle))
		movable_physics.set_angle(movement_angle)

/obj/effect/decal/cleanable/blood/particle/proc/initialize_physics()
	return AddComponent(/datum/component/movable_physics, \
		horizontal_velocity = rand(1 * 100, 5.5 * 100) * 0.01, \
		vertical_velocity = rand(4 * 100, 4.5 * 100) * 0.01, \
		horizontal_friction = rand(0.05 * 100, 0.1 * 100) * 0.01, \
		vertical_friction = 10 * 0.05, \
		z_floor = 0, \
		bounce_callback = CALLBACK(src, PROC_REF(on_bounce)), \
		bump_callback = CALLBACK(src, PROC_REF(on_bump)), \
	)

/obj/effect/decal/cleanable/blood/particle/proc/on_bounce()
	if(!isturf(loc) || !splatter_type_floor)
		qdel(src)
		return
	var/obj/effect/decal/cleanable/splatter
	if(!ispath(splatter_type_floor, /obj/effect/decal/cleanable/blood/splatter/stacking))
		splatter = new splatter_type_floor(loc)
		if(messy_splatter)
			splatter.pixel_x = src.pixel_x
			splatter.pixel_y = src.pixel_y
	else
		var/obj/effect/decal/cleanable/blood/splatter/stacking/stacker = locate(/obj/effect/decal/cleanable/blood/splatter/stacking) in loc
		if(!stacker)
			stacker = new splatter_type_floor(loc, messy_splatter ? src.pixel_x : 0, messy_splatter ? src.pixel_y : 0)
			stacker.bloodiness = src.bloodiness
			stacker.update_appearance(UPDATE_ICON)
			stacker.alpha = 0
			animate(stacker, alpha = 255, time = 2)
		else
			var/obj/effect/decal/cleanable/blood/splatter/stacking/other_splatter = new splatter_type_floor(null, messy_splatter ? src.pixel_x : 0, messy_splatter ? src.pixel_y : 0)
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

/obj/effect/decal/cleanable/blood/particle/proc/on_bump(atom/bumped_atom)
	if(!isturf(loc) || !splatter_type_wall)
		return
	if(iswallturf(bumped_atom))
		//Adjust pixel offset to make splatters appear on the wall
		var/obj/effect/decal/cleanable/blood/splatter/over_window/final_splatter = new splatter_type_wall(loc)
		var/dir_to_wall = get_dir(src, bumped_atom)
		final_splatter.pixel_x = (dir_to_wall & EAST ? world.icon_size : (dir_to_wall & WEST ? -world.icon_size : 0))
		final_splatter.pixel_y = (dir_to_wall & NORTH ? world.icon_size : (dir_to_wall & SOUTH ? -world.icon_size : 0))
		final_splatter.alpha = 0
		animate(final_splatter, alpha = initial(final_splatter.alpha), time = 2)
		var/list/blood_dna = GET_ATOM_BLOOD_DNA(src)
		if(blood_dna)
			final_splatter.add_blood_DNA(blood_dna)
	else if(istype(bumped_atom, /obj/structure/window))
		var/obj/structure/window/the_window = bumped_atom
		the_window.become_bloodied()
	qdel(src)
