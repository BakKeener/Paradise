/obj/structure/statue
	name = "statue"
	desc = "Placeholder. Yell at Firecage if you SOMEHOW see this."
	icon = 'icons/obj/statue.dmi'
	icon_state = ""
	density = TRUE
	max_integrity = 100
	var/oreAmount = 5
	var/material_drop_type = /obj/item/stack/sheet/metal

/obj/structure/statue/attackby__legacy__attackchain(obj/item/W, mob/living/user, params)
	add_fingerprint(user)
	if(!(flags & NODECONSTRUCT))
		if(default_unfasten_wrench(user, W))
			return
		if(istype(W, /obj/item/gun/energy/plasmacutter))
			playsound(src, W.usesound, 100, 1)
			user.visible_message("[user] is slicing apart the [name]...", \
								"<span class='notice'>You are slicing apart the [name]...</span>")
			if(do_after(user, 40 * W.toolspeed, target = src))
				if(!loc)
					return
				user.visible_message("[user] slices apart the [name].", \
									"<span class='notice'>You slice apart the [name].</span>")
				deconstruct(TRUE)
			return
	return ..()

/obj/structure/statue/welder_act(mob/user, obj/item/I)
	if(anchored)
		return
	. = TRUE
	if(!I.tool_use_check(user, 0))
		return
	WELDER_ATTEMPT_SLICING_MESSAGE
	if(I.use_tool(src, user, 40, volume = I.tool_volume))
		WELDER_SLICING_SUCCESS_MESSAGE
		deconstruct(TRUE)

/obj/structure/statue/attack_hand(mob/living/user)
	user.changeNext_move(CLICK_CD_MELEE)
	add_fingerprint(user)
	user.visible_message("[user] rubs some dust off from the [name]'s surface.", \
						"<span class='notice'>You rub some dust off from the [name]'s surface.</span>")

/obj/structure/statue/deconstruct(disassembled = TRUE)
	if(!(flags & NODECONSTRUCT))
		if(material_drop_type)
			var/drop_amt = oreAmount
			if(!disassembled)
				drop_amt -= 2
			if(drop_amt > 0)
				new material_drop_type(get_turf(src), drop_amt)
	qdel(src)

/obj/structure/statue/uranium
	max_integrity = 300
	light_range = 2
	material_drop_type = /obj/item/stack/sheet/mineral/uranium
	var/last_event = 0
	var/active = FALSE

/obj/structure/statue/uranium/nuke
	name = "statue of a nuclear fission explosive"
	desc = "This is a grand statue of a Nuclear Explosive. It has a sickening green colour."
	icon_state = "nuke"

/obj/structure/statue/uranium/eng
	name = "statue of an engineer"
	desc = "This statue has a sickening green colour."
	icon_state = "eng"

/obj/statue/uranium/Initialize(mapload)
	. = ..()
	var/datum/component/inherent_radioactivity/radioactivity = AddComponent(/datum/component/inherent_radioactivity, 150, 0, 0, 1.5)
	START_PROCESSING(SSradiation, radioactivity)

/obj/structure/statue/plasma
	max_integrity = 200
	material_drop_type = /obj/item/stack/sheet/mineral/plasma
	desc = "This statue is suitably made from plasma."
	cares_about_temperature = TRUE

/obj/structure/statue/plasma/scientist
	name = "statue of a scientist"
	icon_state = "sci"

/obj/structure/statue/plasma/xeno
	name = "statue of a xenomorph"
	icon_state = "xeno"

/obj/structure/statue/plasma/temperature_expose(exposed_temperature, exposed_volume)
	..()
	if(exposed_temperature > 300)
		PlasmaBurn(exposed_temperature)

/obj/structure/statue/plasma/bullet_act(obj/item/projectile/P)
	if(!QDELETED(src)) //wasn't deleted by the projectile's effects.
		if(!P.nodamage && ((P.damage_type == BURN) || (P.damage_type == BRUTE)))
			if(P.firer)
				message_admins("[key_name_admin(P.firer)] ignited a plasma statue with [P.name] at [COORD(loc)]")
				log_game("[key_name(P.firer)] ignited a plasma statue with [P.name] at [COORD(loc)]")
				investigate_log("[key_name(P.firer)] ignited a plasma statue with [P.name] at [COORD(loc)]", INVESTIGATE_ATMOS)
			else
				message_admins("A plasma statue was ignited with [P.name] at [COORD(loc)]. No known firer.")
				log_game("A plasma statue was ignited with [P.name] at [COORD(loc)]. No known firer.")
			PlasmaBurn()
	..()

/obj/structure/statue/plasma/attackby__legacy__attackchain(obj/item/W, mob/user, params)
	if(W.get_heat() > 300)//If the temperature of the object is over 300, then ignite
		message_admins("[key_name_admin(user)] ignited a plasma statue at [COORD(loc)]")
		log_game("[key_name(user)] ignited plasma a statue at [COORD(loc)]")
		investigate_log("[key_name(user)] ignited a plasma statue at [COORD(loc)]", INVESTIGATE_ATMOS)
		ignite(W.get_heat())
		return
	return ..()

/obj/structure/statue/plasma/welder_act(mob/user, obj/item/I)
	. = TRUE
	if(!I.use_tool(src, user, volume = I.tool_volume))
		return
	user.visible_message("<span class='danger'>[user] sets [src] on fire!</span>",\
						"<span class='danger'>[src] disintegrates into a cloud of plasma!</span>",\
						"<span class='warning'>You hear a 'whoompf' and a roar.</span>")
	message_admins("[key_name_admin(user)] ignited a plasma statue at [COORD(loc)]")
	log_game("[key_name(user)] ignited plasma a statue at [COORD(loc)]")
	investigate_log("[key_name(user)] ignited a plasma statue at [COORD(loc)]", INVESTIGATE_ATMOS)
	ignite(2500)

/obj/structure/statue/plasma/proc/PlasmaBurn()
	atmos_spawn_air(LINDA_SPAWN_HEAT | LINDA_SPAWN_TOXINS, 160)
	deconstruct(FALSE)

/obj/structure/statue/plasma/proc/ignite(exposed_temperature)
	if(exposed_temperature > 300)
		PlasmaBurn()

/obj/structure/statue/gold
	max_integrity = 300
	material_drop_type = /obj/item/stack/sheet/mineral/gold
	desc = "This is a highly valuable statue made from gold."

/obj/structure/statue/gold/hos
	name = "statue of the head of security"
	icon_state = "hos"

/obj/structure/statue/gold/hop
	name = "statue of the head of personnel"
	icon_state = "hop"

/obj/structure/statue/gold/cmo
	name = "statue of the chief medical officer"
	icon_state = "cmo"

/obj/structure/statue/gold/ce
	name = "statue of the chief engineer"
	icon_state = "ce"

/obj/structure/statue/gold/rd
	name = "statue of the research director"
	icon_state = "rd"

/obj/structure/statue/silver
	max_integrity = 300
	material_drop_type = /obj/item/stack/sheet/mineral/silver
	desc = "This is a valuable statue made from silver."

/obj/structure/statue/silver/md
	name = "statue of a medical doctor"
	icon_state = "md"

/obj/structure/statue/silver/janitor
	name = "statue of a janitor"
	icon_state = "jani"

/obj/structure/statue/silver/sec
	name = "statue of a security officer"
	icon_state = "sec"

/obj/structure/statue/silver/secborg
	name = "statue of a security cyborg"
	icon_state = "secborg"

/obj/structure/statue/silver/medborg
	name = "statue of a medical cyborg"
	icon_state = "medborg"

/obj/structure/statue/silver/corgi
	name = "statue of a corgi"
	icon_state = "corgi"

/obj/structure/statue/silver/monkey
	name = "statue of a monkey"
	icon_state = "monkey"

/obj/structure/statue/diamond
	max_integrity = 1000
	material_drop_type = /obj/item/stack/sheet/mineral/diamond
	desc = "This is a very expensive diamond statue."

/obj/structure/statue/diamond/captain
	name = "statue of THE captain"
	icon_state = "cap"

/obj/structure/statue/diamond/ai1
	name = "statue of the AI hologram"
	icon_state = "ai1"

/obj/structure/statue/diamond/ai2
	name = "statue of the AI core"
	icon_state = "ai2"

/obj/structure/statue/bananium
	max_integrity = 300
	material_drop_type = /obj/item/stack/sheet/mineral/bananium
	desc = "A bananium statue with a small engraving:'HOOOOOOONK'."
	var/spam_flag = 0

/obj/structure/statue/bananium/clown
	name = "statue of a clown"
	icon_state = "clown"

/obj/structure/statue/bananium/Bumped(atom/user)
	honk()
	..()

/obj/structure/statue/bananium/attackby__legacy__attackchain(obj/item/W, mob/user, params)
	honk()
	return ..()

/obj/structure/statue/bananium/attack_hand(mob/user)
	honk()
	..()

/obj/structure/statue/bananium/proc/honk()
	if(!spam_flag)
		spam_flag = 1
		playsound(loc, 'sound/items/bikehorn.ogg', 50, 1)
		spawn(20)
			spam_flag = 0

/obj/structure/statue/sandstone
	max_integrity = 50
	material_drop_type = /obj/item/stack/sheet/mineral/sandstone

/obj/structure/statue/sandstone/assistant
	name = "statue of an assistant"
	desc = "A cheap statue of sandstone for a greyshirt."
	icon_state = "assist"

/// call me when we add marble i guess
/obj/structure/statue/sandstone/venus
	name = "statue of a pure maiden"
	desc = "An ancient marble statue. The subject is depicted with a floor-length braid and is wielding a toolbox. By Jove, it's easily the most gorgeous depiction of a woman you've ever seen. The artist must truly be a master of his craft. Shame about the broken arm, though."
	icon = 'icons/obj/statuelarge.dmi'
	icon_state = "venus"
	oreAmount = 20

/obj/structure/statue/tranquillite
	max_integrity = 300
	material_drop_type = /obj/item/stack/sheet/mineral/tranquillite
	desc = "..."

/obj/structure/statue/tranquillite/mime
	name = "statue of a mime"
	icon_state = "mime"

/obj/structure/statue/tranquillite/mime/AltClick(mob/user)//has 4 dirs
	if(user.incapacitated())
		to_chat(user, "<span class='warning'>You can't do that right now!</span>")
		return
	if(!Adjacent(user))
		return
	if(anchored)
		to_chat(user, "It is fastened to the floor!")
		return
	setDir(turn(dir, 90))

/obj/structure/statue/plastitanium
	max_integrity = 600
	material_drop_type = /obj/item/stack/sheet/mineral/plastitanium

/obj/structure/statue/plastitanium/kidanstatue
	name = "kidan warrior statue"
	desc = "A beautifully carved and menacing statue of a Kidan warrior made out of plastitanium. It looks very heavy."
	icon_state = "kidan"

/obj/structure/statue/chickenstatue
	name = "bronze chickenman statue"
	desc = "An antique and oriental-looking statue of a Chickenman made of bronze."
	icon_state = "chicken"
	anchored = TRUE
	oreAmount = 0

/obj/structure/statue/soviet_mulebot
	name = "OXENbot"
	desc = "Like a MULEbot, but more socialist and less functional."
	icon = 'icons/obj/aibots.dmi'
	icon_state = "mulebot0"
	anchored = TRUE
	oreAmount = 10

////////////////////////////////

/obj/structure/snowman
	name = "snowman"
	desc = "Seems someone made a snowman here."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "snowman"
	anchored = TRUE
	density = TRUE
	max_integrity = 50

/obj/structure/snowman/built
	desc = "Just like the ones you remember from childhood!"

/obj/structure/snowman/built/Destroy()
	new /obj/item/food/grown/carrot(drop_location())
	new /obj/item/grown/log(drop_location())
	new /obj/item/grown/log(drop_location())
	return ..()

/obj/structure/snowman/built/attackby__legacy__attackchain(obj/item/I, mob/user)
	if(istype(I, /obj/item/snowball) && obj_integrity < max_integrity)
		to_chat(user, "<span class='notice'>You patch some of the damage on [src] with [I].</span>")
		obj_integrity = max_integrity
		qdel(I)
	else
		return ..()

/obj/structure/snowman/built/fire_act(datum/gas_mixture/air, exposed_temperature, exposed_volume, global_overlay = TRUE)
	..()
	qdel(src)

/obj/structure/statue/cyberiad
	name = "NSS Cyberiad"
	desc = "A giant model of the Cyberiad science station. Judging by the differences in design, the station has been rebuilt several times."
	icon = 'icons/obj/station_statue.dmi'
	icon_state = "center"
	flags = NODECONSTRUCT
	anchored = TRUE
	max_integrity = 500
	oreAmount = 0

/obj/structure/statue/cyberiad/Destroy()
	. = ..()
	// Delete all the nearby cyberiad statue parts
	for(var/obj/structure/statue/cyberiad/bigass_statue in range(2))
		qdel(bigass_statue)

// Top layer of the statue is not dense
/obj/structure/statue/cyberiad/north
	icon_state = "north"
	density = FALSE
	layer = ABOVE_ALL_MOB_LAYER

/obj/structure/statue/cyberiad/north/west
	icon_state = "nw"

/obj/structure/statue/cyberiad/north/east
	icon_state = "ne"

/obj/structure/statue/cyberiad/north/Initialize(mapload)
	. = ..()
	if(GetExactComponent(/datum/component/largetransparency)) //already have it, lets yeet
		return
	AddComponent(/datum/component/largetransparency, -1, -2, 2, 2)

// Adds transparency to said top layer when the player gets behind or near it
/obj/structure/statue/cyberiad/north/west/Initialize(mapload)
	AddComponent(/datum/component/largetransparency, 0, -2, 2, 2)
	return ..()

/obj/structure/statue/cyberiad/north/east/Initialize(mapload)
	AddComponent(/datum/component/largetransparency, -2, -2, 2, 2)
	return ..()

/obj/structure/statue/cyberiad/center
	density = FALSE
	layer = ABOVE_ALL_MOB_LAYER

/obj/structure/statue/cyberiad/center/west
	icon_state = "west"

/obj/structure/statue/cyberiad/center/east
	icon_state = "east"

/obj/structure/statue/cyberiad/center/Initialize(mapload)
	. = ..()
	if(GetExactComponent(/datum/component/largetransparency)) //already have it, lets yeet
		return
	AddComponent(/datum/component/largetransparency, -1, -1, 2, 2)

// Adds transparency to said top layer when the player gets behind or near it
/obj/structure/statue/cyberiad/center/west/Initialize(mapload)
	AddComponent(/datum/component/largetransparency, 0, -1, 2, 2)
	return ..()

/obj/structure/statue/cyberiad/center/east/Initialize(mapload)
	AddComponent(/datum/component/largetransparency, -2, -1, 2, 2)
	return ..()

/obj/structure/statue/cyberiad/south
	icon_state = "south"

/obj/structure/statue/cyberiad/south/west
	icon_state = "sw"

/obj/structure/statue/cyberiad/south/east
	icon_state = "se"
