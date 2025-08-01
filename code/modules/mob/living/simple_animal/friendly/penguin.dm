//Penguins

/mob/living/simple_animal/pet/penguin
	name = "penguin"
	real_name = "penguin"
	response_help  = "pets"
	response_disarm = "bops"
	response_harm   = "kicks"
	speak = list("Gah Gah!", "NOOT NOOT!", "NOOT!", "Noot", "noot", "Prah!", "Grah!")
	speak_emote = list("squawks", "gakkers")
	emote_hear = list("squawk!", "gakkers!", "noots.","NOOTS!")
	emote_see = list("shakes its beak.", "flaps it's wings.","preens itself.")
	faction = list("penguin")
	see_in_dark = 5
	speak_chance = 1
	turns_per_move = 10
	icon = 'icons/mob/penguins.dmi'
	footstep_type = FOOTSTEP_MOB_BAREFOOT

/mob/living/simple_animal/pet/penguin/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/wears_collar)
	AddElement(/datum/element/waddling)

/mob/living/simple_animal/pet/penguin/emperor
	name = "Emperor penguin"
	desc = "Emperor of all he surveys."
	icon_state = "penguin"
	icon_living = "penguin"
	icon_dead = "penguin_dead"
	butcher_results = list()
	gold_core_spawnable = FRIENDLY_SPAWN

/mob/living/simple_animal/pet/penguin/eldrich
	name = "Albino penguin"
	desc = "Found in the depths of mountains."
	response_help  = "taps"
	response_disarm = "pokes"
	response_harm   = "flails at"
	icon_state = "penguin_elder"
	icon_living = "penguin_elder"
	icon_dead = "penguin_dead"
	speak = list("Gah Gah!", "Tekeli-li! Tekeli-li!", "Tekeli-li!", "Teke", "li")
	speak_emote = list("gibbers", "gakkers")
	emote_hear = list("whistles!", "gakkers!")
	emote_see = list("shakes its beak.", "flaps it's wings.","preens itself.")
	faction = list("penguin", "cult")

/mob/living/simple_animal/pet/penguin/emperor/shamebrero
	name = "Shamebrero penguin"
	desc = "Shameful of all he surveys."
	icon_state = "penguin_shamebrero"
	icon_living = "penguin_shamebrero"
	gold_core_spawnable = NO_SPAWN
	unique_pet = TRUE

/mob/living/simple_animal/pet/penguin/baby
	speak = list("gah", "noot noot", "noot!", "noot", "squeee!", "noo!")
	name = "Penguin chick"
	desc = "Can't fly and can barely waddles, but the prince of all chicks."
	icon_state = "penguin_baby"
	icon_living = "penguin_baby"
	icon_dead = "penguin_baby_dead"
	density = FALSE
	pass_flags = PASSMOB
