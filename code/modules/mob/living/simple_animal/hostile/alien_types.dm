/mob/living/simple_animal/hostile/alien
	name = "alien hunter"
	desc = "Hiss!"
	icon = 'icons/mob/alien.dmi'
	icon_state = "alienh_running"
	icon_living = "alienh_running"
	icon_dead = "alienh_dead"
	icon_gib = "syndicate_gib"
	gender = FEMALE
	speed = 0
	butcher_results = list(/obj/item/food/monstermeat/xenomeat= 3, /obj/item/stack/sheet/animalhide/xeno = 1)
	maxHealth = 125
	health = 125
	harm_intent_damage = 5
	obj_damage = 60
	melee_damage_lower = 25
	melee_damage_upper = 25
	attacktext = "slashes"
	speak_emote = list("hisses")
	bubble_icon = "alien"
	a_intent = INTENT_HARM
	attack_sound = 'sound/weapons/bladeslice.ogg'
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	unsuitable_atmos_damage = 15
	heat_damage_per_tick = 20
	faction = list("alien")
	minbodytemp = 0
	see_in_dark = 8
	lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE
	death_sound = 'sound/voice/hiss6.ogg'
	deathmessage = "lets out a waning guttural screech, green blood bubbling from its maw..."
	footstep_type = FOOTSTEP_MOB_CLAW
	loot = list(/obj/effect/decal/cleanable/blood/gibs/xeno/limb, /obj/effect/decal/cleanable/blood/gibs/xeno/core, /obj/effect/decal/cleanable/blood/xeno/splatter, /obj/effect/decal/cleanable/blood/gibs/xeno/body, /obj/effect/decal/cleanable/blood/gibs/xeno/down)

/mob/living/simple_animal/hostile/alien/ListTargetsLazy()
	return ListTargets()

/mob/living/simple_animal/hostile/alien/Aggro()
	. = ..()
	if(target)
		playsound(loc, 'sound/voice/hiss4.ogg', 70, TRUE)

/mob/living/simple_animal/hostile/alien/drone
	name = "alien drone"
	icon_state = "aliend_running"
	icon_living = "aliend_running"
	icon_dead = "aliend_dead"
	melee_damage_lower = 15
	melee_damage_upper = 15
	var/plant_cooldown = 30
	var/plants_off = 0

/mob/living/simple_animal/hostile/alien/drone/handle_automated_action()
	if(!..()) //AIStatus is off
		return
	plant_cooldown--
	if(AIStatus == AI_IDLE)
		if(!plants_off && prob(10) && plant_cooldown<=0)
			plant_cooldown = initial(plant_cooldown)
			SpreadPlants()

/mob/living/simple_animal/hostile/alien/sentinel
	name = "alien sentinel"
	icon_state = "aliens_running"
	icon_living = "aliens_running"
	icon_dead = "aliens_dead"
	health = 150
	maxHealth = 150
	melee_damage_lower = 15
	melee_damage_upper = 15
	ranged = TRUE
	retreat_distance = 5
	minimum_distance = 5
	projectiletype = /obj/item/projectile/neurotox
	projectilesound = 'sound/weapons/pierce.ogg'

/mob/living/simple_animal/hostile/alien/queen
	name = "alien queen"
	icon_state = "alienq_running"
	icon_living = "alienq_running"
	icon_dead = "alienq_dead"
	health = 250
	maxHealth = 250
	melee_damage_lower = 15
	melee_damage_upper = 15
	ranged = TRUE
	retreat_distance = 5
	minimum_distance = 5
	move_to_delay = 4
	butcher_results = list(/obj/item/food/monstermeat/xenomeat= 4, /obj/item/stack/sheet/animalhide/xeno = 1)
	projectiletype = /obj/item/projectile/neurotox
	projectilesound = 'sound/weapons/pierce.ogg'
	status_flags = 0
	var/sterile = 1
	var/plants_off = 0
	var/egg_cooldown = 30
	var/plant_cooldown = 30

/mob/living/simple_animal/hostile/alien/queen/handle_automated_action()
	if(!..())
		return
	egg_cooldown--
	plant_cooldown--
	if(AIStatus == AI_IDLE)
		if(!plants_off && prob(10) && plant_cooldown<=0)
			plant_cooldown = initial(plant_cooldown)
			SpreadPlants()
		if(!sterile && prob(10) && egg_cooldown<=0)
			egg_cooldown = initial(egg_cooldown)
			LayEggs()

/mob/living/simple_animal/hostile/alien/proc/SpreadPlants()
	if(!isturf(loc) || isspaceturf(loc))
		return
	if(locate(/obj/structure/alien/weeds/node) in get_turf(src))
		return
	visible_message("<span class='alertalien'>[src] has planted some alien weeds!</span>")
	new /obj/structure/alien/weeds/node(loc)

/mob/living/simple_animal/hostile/alien/proc/LayEggs()
	if(!isturf(loc) || isspaceturf(loc))
		return
	if(locate(/obj/structure/alien/egg) in get_turf(src))
		return
	visible_message("<span class='alertalien'>[src] has laid an egg!</span>")
	new /obj/structure/alien/egg(loc)

/mob/living/simple_animal/hostile/alien/queen/large
	name = "alien empress"
	icon = 'icons/mob/alienlarge.dmi'
	icon_state = "queen_s"
	icon_living = "queen_s"
	icon_dead = "queen_dead"
	bubble_icon = "alienroyal"
	maxHealth = 400
	health = 400
	butcher_results = list(/obj/item/food/monstermeat/xenomeat= 10, /obj/item/stack/sheet/animalhide/xeno = 2)
	mob_size = MOB_SIZE_LARGE

/obj/item/projectile/neurotox
	name = "neurotoxin"
	damage = 30
	icon_state = "toxin"

/mob/living/simple_animal/hostile/alien/maid
	name = "lusty xenomorph maid"
	melee_damage_lower = 0
	melee_damage_upper = 0
	a_intent = INTENT_HELP
	friendly = "caresses"
	obj_damage = 0
	environment_smash = ENVIRONMENT_SMASH_NONE
	gold_core_spawnable = HOSTILE_SPAWN
	icon_state = "maid"
	icon_living = "maid"
	icon_dead = "maid_dead"
	var/cleanspeed = 15

/mob/living/simple_animal/hostile/alien/maid/AttackingTarget()
	if(ishuman(target))
		var/atom/movable/H = target
		H.clean_blood()
		visible_message("<span class='notice'>\The [src] polishes \the [target].</span>")
		return TRUE
	target.cleaning_act(src, src, cleanspeed, text_description = ".") //LXM is both the user and the cleaning implement itself. Wow!

/mob/living/simple_animal/hostile/alien/maid/can_clean()
	return TRUE

/mob/living/simple_animal/hostile/alien/lavaland
	maxbodytemp = INFINITY

/mob/living/simple_animal/hostile/alien/drone/lavaland
	maxbodytemp = INFINITY

/mob/living/simple_animal/hostile/alien/sentinel/lavaland
	maxbodytemp = INFINITY

/mob/living/simple_animal/hostile/alien/queen/large/lavaland
	maxbodytemp = INFINITY
