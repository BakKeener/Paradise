// To clarify:
// For use_to_pickup and allow_quick_gather functionality,
// see item/attackby() (/game/objects/items.dm, params)
// Do not remove this functionality without good reason, cough reagent_containers cough.
// -Sayu


/obj/item/storage
	name = "storage"
	icon = 'icons/obj/storage.dmi'
	flags_2 = BLOCKS_LIGHT_2
	/// No message on putting items in.
	var/silent = FALSE
	/// List of objects which this item can store (if set, it can't store anything else)
	var/list/can_hold = list()
	/// List of objects that can be stored, regardless of w_class
	var/list/w_class_override = list()
	/// List of objects which this item can't store (in effect only if can_hold isn't set)
	var/list/cant_hold = list()
	/// List of objects which this item overrides the cant_hold list (used to negate cant_hold on specific items. Ex: Allowing Smuggler's Satchels (subtype of backpack) to be stored inside bags of holding.)
	var/list/cant_hold_override = list()
	/// Max size of objects that this object can store (in effect only if can_hold isn't set)
	var/max_w_class = WEIGHT_CLASS_SMALL
	/// The sum of the w_classes of all the items in this storage item.
	var/max_combined_w_class = 14
	/// The number of storage slots in this container.
	var/storage_slots = 7
	var/atom/movable/screen/storage/boxes = null
	var/atom/movable/screen/close/closer = null

	/// Set this to make it possible to use this item in an inverse way, so you can have the item in your hand and click items on the floor to pick them up.
	var/use_to_pickup = FALSE
	/// Set this to make the storage item group contents of the same type and display them as a number.
	var/display_contents_with_number
	/// Set this variable to allow the object to have the 'empty' verb, which dumps all the contents on the floor.
	var/allow_quick_empty
	/// Set this variable to allow the object to have the 'toggle mode' verb, which quickly collects all items from a tile.
	var/allow_quick_gather
	/// Pick up one item at a time or everything on the tile
	var/pickup_all_on_tile = TRUE
	/// Sound played when used. `null` for no sound.
	var/use_sound = "rustle"
	/// What kind of [/obj/item/stack] can this be folded into. (e.g. Boxes and cardboard)
	var/foldable = null
	/// How much of the stack item do you get.
	var/foldable_amt = 0

	/// Lazy list of mobs which are currently viewing the storage inventory.
	var/list/mobs_viewing

	// Allow storage items of the same size to be put inside
	var/allow_same_size = FALSE

/obj/item/storage/Initialize(mapload)
	. = ..()
	can_hold = typecacheof(can_hold)
	cant_hold = typecacheof(cant_hold) - typecacheof(cant_hold_override)

	populate_contents()

	boxes = new /atom/movable/screen/storage()
	boxes.name = "storage"
	boxes.master = src
	boxes.icon_state = "block"
	boxes.screen_loc = "7,7 to 10,8"
	boxes.layer = HUD_LAYER
	boxes.plane = HUD_PLANE
	closer = new /atom/movable/screen/close()
	closer.master = src
	closer.icon_state = "backpack_close"
	closer.layer = ABOVE_HUD_LAYER
	closer.plane = ABOVE_HUD_PLANE
	orient2hud()

	ADD_TRAIT(src, TRAIT_ADJACENCY_TRANSPARENT, ROUNDSTART_TRAIT)
	RegisterSignal(src, COMSIG_ATOM_EXITED, PROC_REF(on_atom_exited))

/obj/item/storage/Destroy()
	for(var/obj/O in contents)
		O.mouse_opacity = initial(O.mouse_opacity)

	QDEL_NULL(boxes)
	QDEL_NULL(closer)
	LAZYCLEARLIST(mobs_viewing)
	return ..()

/obj/item/storage/examine(mob/user)
	. = ..()
	if(allow_quick_empty)
		. += "<span class='notice'>You can use [src] in hand to empty it's entire contents.</span>"
	if(allow_quick_gather)
		. += "<span class='notice'>You can <b>Alt-Shift-Click</b> [src] to switch it's gathering method.</span>"

/obj/item/storage/forceMove(atom/destination)
	. = ..()
	if(!ismob(destination.loc))
		for(var/mob/player in mobs_viewing)
			if(player == destination)
				continue
			hide_from(player)

/obj/item/storage/proc/removal_allowed_check(mob/user)
	return TRUE

/obj/item/storage/proc/dump_storage(mob/user, obj/item/storage/target)
	if(!length(contents) || user.restrained() || (HAS_TRAIT(user, TRAIT_HANDS_BLOCKED)) || !user.can_reach(target) || src == target)
		return
	for(var/obj/item/thing in contents)
		if(!target.can_be_inserted(thing))
			continue
		if(!do_after(user, 0.3 SECONDS, target = user))
			break
		playsound(loc, "rustle", 50, TRUE, -5)
		target.handle_item_insertion(thing, user)

/obj/item/storage/MouseDrop(obj/over_object, src_location, over_location, src_control, over_control, params)
	if(!ismob(usr)) //so monkeys can take off their backpacks -- Urist
		return
	var/mob/M = usr

	if(ismecha(M.loc) || M.incapacitated(FALSE, TRUE)) // Stops inventory actions in a mech as well as while being incapacitated
		return

	if(over_object == M && Adjacent(M)) // this must come before the screen objects only block
		if(M.s_active)
			M.s_active.close(M)
		open(M)
		return

	if(isstorage(over_object))
		var/obj/item/storage = over_object
		if(!storage.in_storage)
			dump_storage(M, over_object)
			return
	else if(ismodcontrol(over_object))
		var/obj/item/mod/control/mod = over_object
		dump_storage(M, mod.bag)
		return

	if((istype(over_object, /obj/structure/table) || isfloorturf(over_object)) && length(contents) \
		&& loc == M && !M.stat && !M.restrained() && !HAS_TRAIT(M, TRAIT_HANDS_BLOCKED) && over_object.Adjacent(M) && !istype(src, /obj/item/storage/lockbox)) // Worlds longest `if()`
		var/turf/T = get_turf(over_object)
		if(!removal_allowed_check(M))
			return

		if(isfloorturf(over_object))
			if(get_turf(M) != T)
				return // Can only empty containers onto the floor under you
			if(tgui_alert(M, "Empty [src] onto [T]?", "Confirm", list("Yes", "No")) != "Yes")
				return
			if(!(M && over_object && length(contents) && loc == M && !M.stat && !M.restrained() && !HAS_TRAIT(M, TRAIT_HANDS_BLOCKED) && get_turf(M) == T))
				return // Something happened while the player was thinking
		hide_from(M)
		M.face_atom(over_object)
		M.visible_message("<span class='notice'>[M] empties [src] onto [over_object].</span>",
			"<span class='notice'>You empty [src] onto [over_object].</span>")
		var/list/params_list = params2list(params)
		var/x_offset = text2num(params_list["icon-x"]) - 16
		var/y_offset = text2num(params_list["icon-y"]) - 16
		for(var/obj/item/I in contents)
			remove_from_storage(I, T)
			I.scatter_atom(x_offset, y_offset)
		update_icon() // For content-sensitive icons
		return

	if(!is_screen_atom(over_object))
		return ..()
	if(!(loc == M) || (loc && loc.loc == M))
		return
	if(!M.restrained() && !M.stat)
		switch(over_object.name)
			if("r_hand")
				if(!M.unequip(src))
					return
				M.put_in_r_hand(src)
			if("l_hand")
				if(!M.unequip(src))
					return
				M.put_in_l_hand(src)
		add_fingerprint(usr)
		return
	if(over_object == usr && in_range(src, usr) || usr.contents.Find(src))
		if(usr.s_active)
			usr.s_active.close(usr)
		open(usr)

/obj/item/storage/AltClick(mob/user)
	if(ishuman(user) && Adjacent(user) && !user.incapacitated(FALSE, TRUE))
		open(user)
		add_fingerprint(user)
	else if(isobserver(user))
		show_to(user)

/**
  * Loops through any nested containers inside `src`, and returns a list of everything inside them.
  *
  * Currently checks for storage containers, gifts containing storage containers, and folders.
  */
/obj/item/storage/proc/return_inv()
	var/list/L = list()
	L += contents // Inventory of the main storage item

	for(var/obj/item/storage/S in src) // Inventory of nested storage items
		L += S.return_inv()
	for(var/obj/item/gift/G in src)
		L += G.gift
		if(isstorage(G.gift)) // If the gift contains a storage item
			var/obj/item/storage/S = G.gift
			L += S.return_inv()
	for(var/obj/item/folder/F in src)
		L += F.contents
	return L

/**
  * Shows `user` the contents of `src`, and activates any mouse trap style triggers.
  */
/obj/item/storage/proc/show_to(mob/user)
	if(!user.client)
		return
	if(user.s_active != src && !isobserver(user))
		for(var/obj/item/I in src)
			if(I.on_found(user)) // For mouse traps and such
				return // If something triggered, don't open the UI
	orient2hud(user) // this only needs to happen to make .contents show properly as screen objects.
	if(user.s_active)
		user.s_active.hide_from(user) // If there's already an interface open, close it.
	user.client.screen |= boxes
	user.client.screen |= closer
	user.client.screen |= contents
	user.s_active = src
	LAZYDISTINCTADD(mobs_viewing, user)

/**
  * Hides the current container interface from `user`.
  */
/obj/item/storage/proc/hide_from(mob/user)
	LAZYREMOVE(mobs_viewing, user) // Remove clientless mobs too
	if(!user.client)
		return
	user.client.screen -= boxes
	user.client.screen -= closer
	user.client.screen -= contents
	if(user.s_active == src)
		user.s_active = null

/**
  * Hides the current container interface from all viewers.
  */
/obj/item/storage/proc/hide_from_all()
	for(var/mob/M in mobs_viewing)
		hide_from(M)

/**
  * Checks all mobs currently viewing the storage inventory, and hides it if they shouldn't be able to see it.
  */
/obj/item/storage/proc/update_viewers()
	for(var/_M in mobs_viewing)
		var/mob/M = _M
		if(!QDELETED(M) && M.s_active == src && Adjacent(M))
			continue
		hide_from(M)
	for(var/obj/item/storage/child in src)
		child.update_viewers()

/obj/item/storage/Moved(atom/oldloc, dir, forced = FALSE)
	. = ..()
	update_viewers()

/obj/item/storage/proc/open(mob/user)
	if(isobserver(user))
		show_to(user)
		return
	if(use_sound && isliving(user))
		playsound(loc, use_sound, 50, TRUE, -5)

	if(user.s_active)
		user.s_active.close(user)
	show_to(user)

/obj/item/storage/proc/close(mob/user)
	hide_from(user)
	user.s_active = null

/**
  * Draws the inventory and places the items on it using custom positions.
  *
  * `tx` and `ty` are the upper left tile.
  * `mx` and `my` are the bottom right tile.
  *
  * The numbers are calculated from the bottom left, with the bottom left being `1,1`.
  */
/obj/item/storage/proc/orient_objs(tx, ty, mx, my)
	var/cx = tx
	var/cy = ty
	boxes.screen_loc = "[tx],[ty] to [mx],[my]"
	for(var/obj/O in contents)
		O.screen_loc = "[cx],[cy]"
		O.layer = ABOVE_HUD_LAYER
		O.plane = ABOVE_HUD_PLANE
		cx++
		if(cx > mx)
			cx = tx
			cy--
	closer.screen_loc = "[mx + 1],[my]"

//This proc draws out the inventory and places the items on it. It uses the standard position.
/obj/item/storage/proc/standard_orient_objs(rows, cols, list/datum/numbered_display/display_contents)
	var/cx = 4
	var/cy = 2 + rows
	boxes.screen_loc = "4:16,2:16 to [4 + cols]:16,[2 + rows]:16"

	if(display_contents_with_number)
		for(var/datum/numbered_display/ND in display_contents)
			ND.sample_object.mouse_opacity = MOUSE_OPACITY_OPAQUE
			ND.sample_object.screen_loc = "[cx]:16,[cy]:16"
			ND.sample_object.maptext = "<font color='white' face='Small Fonts'>[(ND.number > 1) ? "[ND.number]" : ""]</font>"
			ND.sample_object.layer = ABOVE_HUD_LAYER
			ND.sample_object.plane = ABOVE_HUD_PLANE
			cx++
			if(cx > (4 + cols))
				cx = 4
				cy--
	else
		for(var/obj/O in contents)
			O.mouse_opacity = MOUSE_OPACITY_OPAQUE //This is here so storage items that spawn with contents correctly have the "click around item to equip"
			O.screen_loc = "[cx]:16,[cy]:16"
			O.maptext = ""
			O.layer = ABOVE_HUD_LAYER
			O.plane = ABOVE_HUD_PLANE
			cx++
			if(cx > (4 + cols))
				cx = 4
				cy--
	closer.screen_loc = "[4 + cols + 1]:16,2:16"

/datum/numbered_display
	var/obj/item/sample_object
	var/number

/datum/numbered_display/New(obj/item/sample)
	if(!istype(sample))
		qdel(src)
		return
	sample_object = sample
	number = 1

//This proc determins the size of the inventory to be displayed. Please touch it only if you know what you're doing.
/obj/item/storage/proc/orient2hud(mob/user)
	var/adjusted_contents = length(contents)

	//Numbered contents display
	var/list/datum/numbered_display/numbered_contents
	if(display_contents_with_number)
		for(var/obj/O in contents)
			O.layer = initial(O.layer)
			O.plane = initial(O.plane)

		numbered_contents = list()
		adjusted_contents = 0
		for(var/obj/item/I in contents)
			var/found = FALSE
			for(var/datum/numbered_display/ND in numbered_contents)
				if(ND.sample_object.should_stack_with(I))
					ND.number++
					found = TRUE
					break
			if(!found)
				adjusted_contents++
				numbered_contents += new/datum/numbered_display(I)

	var/row_num = 0
	var/col_count = min(7, storage_slots) - 1
	if(adjusted_contents > 7)
		row_num = round((adjusted_contents - 1) / 7) // 7 is the maximum allowed width.
	standard_orient_objs(row_num, col_count, numbered_contents)

/**
  * Checks whether `I` can be inserted into the container.
  *
  * Returns `TRUE` if it can, and `FALSE` if it can't.
  * Arguments:
  * * obj/item/I - The item to insert
  * * stop_messages - Don't display a warning message if the item can't be inserted
  */
/obj/item/storage/proc/can_be_inserted(obj/item/I, stop_messages = FALSE)
	if(!istype(I) || (I.flags & ABSTRACT)) // Not an item
		return

	if(loc == I)
		return FALSE //Means the item is already in the storage item

	if(!I.can_enter_storage(src, usr))
		return FALSE

	if(length(contents) >= storage_slots)
		if(!stop_messages)
			to_chat(usr, "<span class='warning'>[I] won't fit in [src], make some space!</span>")
		return FALSE //Storage item is full

	if(length(can_hold))
		if(!is_type_in_typecache(I, can_hold))
			if(!stop_messages)
				to_chat(usr, "<span class='warning'>[src] cannot hold [I].</span>")
			return FALSE

	if(is_type_in_typecache(I, cant_hold)) //Check for specific items which this container can't hold.
		if(!stop_messages)
			to_chat(usr, "<span class='warning'>[src] cannot hold [I].</span>")
		return FALSE

	if(length(cant_hold) && isstorage(I)) //Checks nested storage contents for restricted objects, we don't want people sneaking the NAD in via boxes now, do we?
		var/obj/item/storage/S = I
		for(var/obj/A in S.return_inv())
			if(is_type_in_typecache(A, cant_hold))
				if(!stop_messages)
					to_chat(usr, "<span class='warning'>[src] rejects [I] because of its contents.</span>")
				return FALSE

	if(I.w_class > max_w_class)
		if(length(w_class_override))
			if(is_type_in_list(I, w_class_override))
				return TRUE
			else
				if(!stop_messages)
					to_chat(usr, "<span class='warning'>[I] is too big for [src].</span>")
				return FALSE
		else
			if(!stop_messages)
				to_chat(usr, "<span class='warning'>[I] is too big for [src].</span>")
			return FALSE

	var/sum_w_class = I.w_class
	for(var/obj/item/item in contents)
		sum_w_class += item.w_class //Adds up the combined w_classes which will be in the storage item if the item is added to it.

	if(sum_w_class > max_combined_w_class)
		if(!stop_messages)
			to_chat(usr, "<span class='warning'>[src] is full, make some space.</span>")
		return FALSE

	if(I.w_class >= w_class && isstorage(I))
		if(!allow_same_size)	//BoHs should be able to hold backpacks again. The override for putting a BoH in a BoH is in backpack.dm.
			if(!stop_messages)
				to_chat(usr, "<span class='warning'>[src] cannot hold [I] as it's a storage item of the same size.</span>")
			return FALSE //To prevent the stacking of same sized storage items.

	if(I.flags & NODROP) //SHOULD be handled in unEquip, but better safe than sorry.
		to_chat(usr, "<span class='warning'>[I] is stuck to your hand, you can't put it in [src]</span>")
		return FALSE

	return TRUE

/**
  * Handles items being inserted into a storage container.
  *
  * This doesn't perform any checks of whether an item can be inserted. That's done by [/obj/item/storage/proc/can_be_inserted]
  * Arguments:
  * * obj/item/I - The item to be inserted
  * * mob/user - The mob performing the insertion
  * * prevent_warning - Stop the insertion message being displayed. Intended for cases when you are inserting multiple items at once.
  */
/obj/item/storage/proc/handle_item_insertion(obj/item/I, mob/user, prevent_warning = FALSE)
	if(!istype(I))
		return FALSE
	if(user)
		if(!Adjacent(user) && !isnewplayer(user))
			return FALSE
		if(!user.unequip(I))
			return FALSE
		user.update_icons()	//update our overlays
	if(QDELING(I))
		return FALSE
	if(silent || HAS_TRAIT(I, TRAIT_SILENT_INSERTION))
		prevent_warning = TRUE
	I.forceMove(src)
	if(QDELING(I))
		return FALSE
	I.on_enter_storage(src)

	for(var/_M in mobs_viewing)
		var/mob/M = _M
		if((M.s_active == src) && M.client)
			M.client.screen += I
	if(user)
		if(user.client && user.s_active != src)
			user.client.screen -= I
		if(length(user.observers))
			for(var/mob/observer in user.observers)
				if(observer.client && observer.s_active != src)
					observer.client.screen -= I
		I.dropped(user, TRUE)
	if(user)
		add_fingerprint(user)

	if(!prevent_warning)
		// the item's user will always get a notification
		to_chat(user, "<span class='notice'>You put [I] into [src].</span>")

		// if the item less than normal sized, only people within 1 tile get the message, otherwise, everybody in view gets it
		if(I.w_class < WEIGHT_CLASS_NORMAL)
			for(var/mob/M in orange(1, user))
				if(in_range(M, user))
					M.show_message("<span class='notice'>[user] puts [I] into [src].</span>")
		else
			// restrict player list to include only those in view
			for(var/mob/M in oviewers(7, user))
				M.show_message("<span class='notice'>[user] puts [I] into [src].</span>")
	orient2hud(user)
	if(user)
		if(user.s_active)
			user.s_active.show_to(user)

	I.mouse_opacity = MOUSE_OPACITY_OPAQUE //So you can click on the area around the item to equip it, instead of having to pixel hunt
	I.in_inventory = TRUE
	update_icon()
	return TRUE

/obj/item/storage/proc/on_atom_exited(datum/source, atom/exited, direction)
	return remove_from_storage(exited, exited.loc)

/**
  * Handles the removal of an item from a storage container.
  *
  * Arguments:
  * * obj/item/I - The item to be removed
  * * atom/new_location - The location to send the item to.
  */
/obj/item/storage/proc/remove_from_storage(obj/item/I, atom/new_location)
	if(!istype(I))
		return FALSE

	for(var/_M in mobs_viewing)
		var/mob/M = _M
		if((M.s_active == src) && M.client)
			M.client.screen -= I

	if(new_location)
		if(ismob(loc))
			I.dropped(usr, TRUE)
		if(ismob(new_location))
			I.layer = ABOVE_HUD_LAYER
			I.plane = ABOVE_HUD_PLANE
		else
			I.layer = initial(I.layer)
			I.plane = initial(I.plane)
		I.forceMove(new_location)
	else
		I.forceMove(get_turf(src))

	if(usr)
		orient2hud(usr)
		if(usr.s_active)
			usr.s_active.show_to(usr)
	if(I.maptext)
		I.maptext = ""
	I.on_exit_storage(src)
	I.mouse_opacity = initial(I.mouse_opacity)
	update_icon()
	return TRUE

/obj/item/storage/deconstruct(disassembled = TRUE)
	var/drop_loc = loc
	if(ismob(loc))
		drop_loc = get_turf(src)
	for(var/obj/item/I in contents)
		remove_from_storage(I, drop_loc)
	qdel(src)

//This proc is called when you want to place an item into the storage item.
/obj/item/storage/attackby__legacy__attackchain(obj/item/I, mob/user, params)
	..()
	if(istype(I, /obj/item/hand_labeler))
		var/obj/item/hand_labeler/labeler = I
		if(labeler.mode)
			return FALSE
	if(user.a_intent != INTENT_HELP && issimulatedturf(loc)) // Stops you from putting your baton in the storage on accident
		return FALSE
	. = TRUE //no afterattack
	if(isrobot(user))
		return //Robots can't interact with storage items.

	if(!can_be_inserted(I))
		if(length(contents) >= storage_slots) //don't use items on the backpack if they don't fit
			return TRUE
		return FALSE

	handle_item_insertion(I, user)

/obj/item/storage/attack_hand(mob/user)
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		if(!H.get_active_hand())
			if(H.l_store == src)	//Prevents opening if it's in a pocket.
				H.put_in_hands(src)
				H.l_store = null
				return
			if(H.r_store == src)
				H.put_in_hands(src)
				H.r_store = null
				return

	orient2hud(user)
	if(loc == user)
		if(user.s_active)
			user.s_active.close(user)
		open(user)
	else
		..()
	add_fingerprint(user)

/obj/item/storage/equipped(mob/user, slot, initial)
	. = ..()
	update_viewers()

/obj/item/storage/attack_ghost(mob/user)
	if(isobserver(user))
		// Revenants don't get to play with the toys.
		show_to(user)
	return ..()

/obj/item/storage/AltShiftClick(mob/living/carbon/human/user)

	pickup_all_on_tile = !pickup_all_on_tile
	switch(pickup_all_on_tile)
		if(TRUE)
			to_chat(usr, "[src] now picks up all items in a tile at once.")
		if(FALSE)
			to_chat(usr, "[src] now picks up one item at a time.")

/obj/item/storage/proc/drop_inventory(user)
	var/turf/T = get_turf(src)
	hide_from(user)
	for(var/obj/item/I in contents)
		remove_from_storage(I, T)
		I.scatter_atom()
		CHECK_TICK

/**
  * Populates the container with items
  *
  * Override with whatever you want to put in the container
  */
/obj/item/storage/proc/populate_contents()
	return // Override

/obj/item/storage/emp_act(severity)
	..()
	for(var/I in contents)
		var/atom/A = I
		A.emp_act(severity)

/obj/item/storage/hear_talk(mob/living/M, list/message_pieces)
	..()
	for(var/obj/O in contents)
		O.hear_talk(M, message_pieces)

/obj/item/storage/hear_message(mob/living/M, msg)
	..()
	for(var/obj/O in contents)
		O.hear_message(M, msg)

/obj/item/storage/attack_self__legacy__attackchain(mob/user)
	//Clicking on itself will empty it, if allow_quick_empty is TRUE
	if(allow_quick_empty && user.is_in_active_hand(src))
		drop_inventory(user)

	else if(foldable)
		fold(user)

/obj/item/storage/proc/fold(mob/user)
	if(length(contents))
		to_chat(user, "<span class='warning'>You can't fold this [name] with items still inside!</span>")
		return
	if(!ispath(foldable))
		return

	var/found = FALSE
	for(var/mob/M in range(1))
		if(M.s_active == src) // Close any open UI windows first
			close(M)
		if(M == user)
			found = TRUE
	if(!found)	// User is too far away
		return

	to_chat(user, "<span class='notice'>You fold [src] flat.</span>")
	var/obj/item/stack/I = new foldable(get_turf(src), foldable_amt)
	user.put_in_hands(I)
	qdel(src)

/**
  * Returns the storage depth of an atom up to the area level.
  *
  * The storage depth is the number of storage items the atom is contained in.
  * Returns `-1` if the atom was not found in a container.
  */
/atom/proc/storage_depth(atom/container)
	var/depth = 0
	var/atom/cur_atom = src

	while(cur_atom && !(cur_atom in container.contents))
		if(isarea(cur_atom))
			return -1
		if(isstorage(cur_atom.loc))
			depth++
		cur_atom = cur_atom.loc

	if(!cur_atom)
		return -1	//inside something with a null loc.

	return depth

/**
  * Like [/atom/proc/storage_depth], but returns the depth to the nearest turf.
  *
  * Returns `-1` if there's no top level turf. (A loc was null somewhere, or a non-turf atom's loc was an area somehow.)
  */
/atom/proc/storage_depth_turf()
	var/depth = 0
	var/atom/cur_atom = src

	while(cur_atom && !isturf(cur_atom))
		if(isarea(cur_atom))
			return -1
		if(isstorage(cur_atom.loc))
			depth++
		cur_atom = cur_atom.loc

	if(!cur_atom)
		return -1	//inside something with a null loc.

	return depth

/obj/item/storage/serialize()
	var/data = ..()
	var/list/content_list = list()
	data["content"] = content_list
	data["slots"] = storage_slots
	data["max_w_class"] = max_w_class
	data["max_c_w_class"] = max_combined_w_class
	for(var/thing in contents)
		var/atom/movable/AM = thing
		// This code does not watch out for infinite loops
		// But then again a tesseract would destroy the server anyways
		// Also I wish I could just insert a list instead of it reading it the wrong way
		content_list.len++
		content_list[length(content_list)] = AM.serialize()
	return data

/obj/item/storage/deserialize(list/data)
	if(isnum(data["slots"]))
		storage_slots = data["slots"]
	if(isnum(data["max_w_class"]))
		max_w_class = data["max_w_class"]
	if(isnum(data["max_c_w_class"]))
		max_combined_w_class = data["max_c_w_class"]
	for(var/thing in contents)
		qdel(thing) // out with the old
	for(var/thing in data["content"])
		if(islist(thing))
			list_to_object(thing, src)
		else if(thing == null)
			stack_trace("Null entry found in storage/deserialize.")
		else
			stack_trace("Non-list thing found in storage/deserialize (Thing: [thing])")
	..()

/obj/item/storage/AllowDrop()
	return TRUE

/obj/item/storage/ex_act(severity)
	for(var/atom/A in contents)
		A.ex_act(severity)
		CHECK_TICK
	..()

/obj/item/storage/proc/can_items_stack(obj/item/item_1, obj/item/item_2)
	if(!item_1 || !item_2)
		return

	return item_1.type == item_2.type && item_1.name == item_2.name

/obj/item/storage/proc/swap_items(obj/item/item_1, obj/item/item_2, mob/user = null)
	if(!(item_1.loc == src && item_2.loc == src))
		return

	var/index_1 = contents.Find(item_1)
	var/index_2 = contents.Find(item_2)

	var/list/new_contents = contents.Copy()
	new_contents.Swap(index_1, index_2)
	contents = new_contents

	if(user && user.s_active == src)
		orient2hud(user)
		show_to(user)
