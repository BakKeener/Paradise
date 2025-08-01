#define AIUPLOAD_EMAG_COOLDOWN 60 SECONDS

/obj/machinery/computer/aiupload
	name = "\improper AI upload console"
	desc = "Used to upload laws to the AI."
	icon_screen = "command"
	icon_keyboard = "med_key"
	circuit = /obj/item/circuitboard/aiupload
	var/mob/living/silicon/ai/current = null
	var/opened = FALSE
	light_color = LIGHT_COLOR_WHITE
	/// sets the cooldown time between uploads when emag'd
	var/cooldown = 0
	/// holds the value for when the inherent_laws are counted in countlaws()
	var/found_laws = 0

//For emagging the console
/obj/machinery/computer/aiupload/emag_act(mob/user)
	if(emagged)
		return
	emagged = TRUE
	if(user)
		user.visible_message("<span class='warning'>Sparks fly out of [src]!</span>",
							"<span class='notice'>You emag [src], scrambling the computer's law encoding system.</span>")
	playsound(loc, 'sound/effects/sparks4.ogg', 50, TRUE)
	do_sparks(5, TRUE, src)
	circuit = /obj/item/circuitboard/aiupload_broken
	return TRUE

/obj/machinery/computer/aiupload/item_interaction(mob/living/user, obj/item/used, list/modifiers)
	var/obj/item/ai_module/module = used
	if(!istype(module))
		return ..()
	if(!check_valid_selection(user))
		return ITEM_INTERACT_COMPLETE
	if(!emagged) //non-emag law change
		module.install(src)
		return ITEM_INTERACT_COMPLETE

	apply_emag_laws(user)

	return ITEM_INTERACT_COMPLETE

/// checks to ensure there is a selected AI, and that it is on the same Z level
/obj/machinery/computer/aiupload/proc/check_valid_selection(mob/user)
	if(!current)//no AI selected
		to_chat(user, "<span class='danger'>No AI selected. Please choose a target before proceeding with upload.</span>")
		return FALSE
	var/turf/T = get_turf(current)
	if(!atoms_share_level(T, get_turf(src))) // off Z level
		to_chat(user, "<span class='danger'>Unable to establish a connection: You're too far away from the target silicon!</span>")
		return FALSE
	return TRUE

/// applies ion-like laws into either the inherent law or true ion law positions due to an emag'd AI upload being used
/obj/machinery/computer/aiupload/proc/apply_emag_laws(mob/user)
	if(world.time < cooldown) //if the cooldown isnt over
		to_chat(user, "<span class='danger'>The program seems to have frozen. It will need some time to process.</span>")
		return
	do_sparks(5, TRUE, src)
	found_laws = length(current.laws.inherent_laws)
	if(!emag_ion_check()) //creates an ion-like inherent law if the ion_laws arnt modified or added
		emag_inherent_law()

/// checks to see if an ion law is added or modified
/obj/machinery/computer/aiupload/proc/emag_ion_check()
	var/datum/ai_law/inherent/new_law = new(generate_ion_law())
	var/emag_law = new_law.law
	if(!length(current.laws.ion_laws))
		if(prob(80))  // 20% chance to generate an ion law if none exists
			return FALSE
		current.add_ion_law(generate_ion_law())
		cooldown = world.time + AIUPLOAD_EMAG_COOLDOWN
		return TRUE
	if(prob(90)) //10% chance to overwrite a current ion
		return FALSE
	current.laws.ion_laws[1].law = emag_law
	cooldown = world.time + AIUPLOAD_EMAG_COOLDOWN
	log_and_message_admins("has given [current] the ion law: [current.laws.ion_laws[1].law].")
	return TRUE

/// modifies one of the AI's laws to read like an ion law
/obj/machinery/computer/aiupload/proc/emag_inherent_law()
	if(!found_laws)
		return
	var/datum/ai_law/inherent/new_law = new(generate_ion_law())
	var/emag_law = new_law.law
	var/lawposition = rand(1, found_laws)
	current.laws.inherent_laws[lawposition].law = emag_law
	log_and_message_admins("has given [current] the emag'd inherent law: [current.laws.inherent_laws[lawposition].law].")
	current.show_laws()
	alert_silicons()
	cooldown = world.time + AIUPLOAD_EMAG_COOLDOWN

/// pushes an alert to the AI and its borgs about the law changes
/obj/machinery/computer/aiupload/proc/alert_silicons()
	current.show_laws()
	current.throw_alert("newlaw", /atom/movable/screen/alert/newlaw)
	for(var/mob/living/silicon/robot/borg in current.connected_robots)
		borg.cmd_show_laws()
		borg.throw_alert("newlaw", /atom/movable/screen/alert/newlaw)

/obj/machinery/computer/aiupload/attack_hand(mob/user)
	if(stat & NOPOWER)
		to_chat(user, "<span class='warning'>The upload computer has no power!</span>")
		return
	if(stat & BROKEN)
		to_chat(user, "<span class='warning'>The upload computer is broken!</span>")
		return

	current = select_active_ai(user)

	if(!current)
		to_chat(user, "<span class='warning'>No active AIs detected.</span>")
		return
	to_chat(user, "<span class='notice'>[current.name] selected for law changes.</span>")

/obj/machinery/computer/aiupload/attack_ghost(user)
	return TRUE

#undef AIUPLOAD_EMAG_COOLDOWN

// Why is this not a subtype
/obj/machinery/computer/borgupload
	name = "cyborg upload console"
	desc = "Used to upload laws to Cyborgs."
	icon_screen = "command"
	icon_keyboard = "med_key"
	circuit = /obj/item/circuitboard/borgupload
	var/mob/living/silicon/robot/current = null

/obj/machinery/computer/borgupload/item_interaction(mob/living/user, obj/item/used, list/modifiers)
	var/obj/item/ai_module/module = used
	if(istype(module))
		if(!current)//no borg selected
			to_chat(user, "<span class='danger'>No borg selected. Please chose a target before proceeding with upload.</span>")
			return ITEM_INTERACT_COMPLETE
		var/turf/T = get_turf(current)
		if(!atoms_share_level(T, src))
			to_chat(user, "<span class='danger'>Unable to establish a connection</span>: You're too far away from the target silicon!")
			return ITEM_INTERACT_COMPLETE
		module.install(src)
		return ITEM_INTERACT_COMPLETE

	return ..()

/obj/machinery/computer/borgupload/attack_hand(mob/user)
	if(stat & NOPOWER)
		to_chat(user, "<span class='warning'>The upload computer has no power!</span>")
		return
	if(stat & BROKEN)
		to_chat(user, "<span class='warning'>The upload computer is broken!</span>")
		return

	current = freeborg(user)

	if(!current)
		to_chat(user, "<span class='warning'>No free cyborgs detected.</span>")
		return
	to_chat(user, "<span class='notice'>[current.name] selected for law changes.</span>")

/obj/machinery/computer/borgupload/attack_ghost(user)
	return TRUE
