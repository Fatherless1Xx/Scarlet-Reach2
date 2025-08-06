/datum/advclass/wretch/necromancer
	name = "Necromancer"
	tutorial = "You have been ostracized and hunted by society for your dark magics and perversion of life."
	allowed_sexes = list(MALE, FEMALE)
	allowed_races = RACES_ALL_KINDS
	outfit = /datum/outfit/job/roguetown/wretch/necromancer
	category_tags = list(CTAG_WRETCH)
	traits_applied = list(TRAIT_STEELHEARTED, TRAIT_OUTLANDER, TRAIT_ZOMBIE_IMMUNE, TRAIT_MAGEARMOR, TRAIT_GRAVEROBBER, TRAIT_OUTLAW, TRAIT_ARCYNE_T3, TRAIT_HERESIARCH, TRAIT_NOPAINSTUN)


/datum/outfit/job/roguetown/wretch/necromancer/pre_equip(mob/living/carbon/human/H)
	H.mind.current.faction += "[H.name]_faction"
	H.set_patron(/datum/patron/inhumen/zizo)
	head = /obj/item/clothing/head/roguetown/roguehood/black
	shoes = /obj/item/clothing/shoes/roguetown/boots/leather/reinforced
	pants = /obj/item/clothing/under/roguetown/heavy_leather_pants
	wrists = /obj/item/clothing/wrists/roguetown/bracers/leather/heavy
	shirt = /obj/item/clothing/suit/roguetown/armor/gambeson/heavy
	armor = /obj/item/clothing/suit/roguetown/shirt/robe/black
	belt = /obj/item/storage/belt/rogue/leather
	beltr = /obj/item/storage/belt/rogue/surgery_bag/full/physician
	neck = /obj/item/clothing/neck/roguetown/gorget
	beltl = /obj/item/rogueweapon/huntingknife
	backl = /obj/item/storage/backpack/rogue/satchel
	backr = /obj/item/rogueweapon/woodstaff/ruby
	backpack_contents = list(/obj/item/spellbook_unfinished/pre_arcyne = 1, /obj/item/roguegem/amethyst = 1, /obj/item/storage/belt/rogue/pouch/coins/poor = 1, /obj/item/flashlight/flare/torch/lantern/prelit = 1, /obj/item/necro_relics/necro_crystal = 2, /obj/item/reagent_containers/glass/bottle/rogue/manapot = 1)

	H.adjust_skillrank(/datum/skill/combat/polearms, 3, TRUE)
	H.adjust_skillrank(/datum/skill/misc/climbing, 3, TRUE)
	H.adjust_skillrank(/datum/skill/misc/athletics, 3, TRUE)
	H.adjust_skillrank(/datum/skill/combat/wrestling, 3, TRUE)
	H.adjust_skillrank(/datum/skill/combat/unarmed, 3, TRUE)
	H.adjust_skillrank(/datum/skill/misc/reading, 5, TRUE)
	H.adjust_skillrank(/datum/skill/craft/alchemy, 4, TRUE)
	H.adjust_skillrank(/datum/skill/magic/arcane, 4, TRUE)
	H.adjust_skillrank(/datum/skill/misc/medicine, 4, TRUE)
	H.dna.species.soundpack_m = new /datum/voicepack/male/wizard()
	H.cmode_music = 'sound/music/combat_cult.ogg'
	if(H.age == AGE_OLD)
		H.adjust_skillrank(/datum/skill/magic/arcane, 1, TRUE)
		H?.mind.adjust_spellpoints(6)
	H.change_stat("intelligence", 4) // Necromancer get the most +4 Int, +2 Perception just like Sorc (Adv Mage), and a bit of endurance / speed
	H.change_stat("perception", 2)
	H.change_stat("endurance", 1)
	H.change_stat("speed", 1)
	if(H.mind)
		H.mind.AddSpell(new /obj/effect/proc_holder/spell/targeted/touch/prestidigitation)
		H.mind.AddSpell(new /obj/effect/proc_holder/spell/invoked/eyebite)
		H.mind.AddSpell(new /obj/effect/proc_holder/spell/invoked/bonechill)
		H.mind.AddSpell(new /obj/effect/proc_holder/spell/invoked/minion_order)
		H.mind.AddSpell(new /obj/effect/proc_holder/spell/invoked/gravemark)
		H.mind.AddSpell(new /obj/effect/proc_holder/spell/invoked/raise_lesser_undead/necromancer)
		H.mind.AddSpell(new /obj/effect/proc_holder/spell/invoked/call_dreamfiend/necromancer)
		H.mind.AddSpell(new /obj/effect/proc_holder/spell/invoked/call_undead_volf)
	H?.mind.adjust_spellpoints(12)
	wretch_select_bounty(H)

/obj/effect/proc_holder/spell/invoked/call_undead_volf
	name = "Summon Undead Volf"
	overlay_state = "eyebite" // reuse for now, or make a new one if you want
	range = 7
	charging_slowdown = 1
	chargetime = 10
	sound = 'sound/foley/bubb (1).ogg'
	invocation = "From the grave, hunt!"
	invocation_type = "shout"
	associated_skill = /datum/skill/magic/arcane
	antimagic_allowed = TRUE
	recharge_time = 30 SECONDS
	var/mob/living/simple_animal/hostile/retaliate/rogue/wolf_undead/summoned

/obj/effect/proc_holder/spell/invoked/call_undead_volf/proc/find_and_consume_bone(mob/living/user)
	// Check all items on the user's person
	for(var/obj/item/I in user.GetAllContents())
		if(istype(I, /obj/item/natural/bone))
			qdel(I)
			return TRUE
	return FALSE

/obj/effect/proc_holder/spell/invoked/call_undead_volf/cast(list/targets, mob/living/user)
	. = ..()
	var/turf/T = get_turf(targets[1])
	if(!isopenturf(T))
		to_chat(user, span_warning("The targeted location is blocked. My call fails to draw an undead volf."))
		return FALSE

	// Check for and consume a bone
	if(!find_and_consume_bone(user))
		to_chat(user, span_warning("You must have a bone somewhere on your person to cast this spell!"))
		return FALSE

	if(!user.mind.has_spell(/obj/effect/proc_holder/spell/invoked/minion_order))
		user.mind.AddSpell(new /obj/effect/proc_holder/spell/invoked/minion_order)
	QDEL_NULL(summoned)
	summoned = new /mob/living/simple_animal/hostile/retaliate/rogue/wolf_undead(T, user, TRUE)
	
	// Assign the wolf to the caster's faction
	var/faction_tag = "[user.mind.current.real_name]_faction"
	if(summoned)
		summoned.faction |= faction_tag
	return TRUE

/obj/effect/proc_holder/spell/invoked/call_dreamfiend/necromancer
	name = "Summon Dreamfiend"
	overlay_state = "dreamfiend"
	range = 7
	no_early_release = TRUE
	charging_slowdown = 1
	chargetime = 10
	sound = 'sound/foley/bubb (1).ogg'
	invocation = "From the dream, consume!"
	invocation_type = "shout"
	recharge_time = 30 SECONDS
	miracle = FALSE
	devotion_cost = 0
	var/necro_inner_tele_radius = 1
	var/necro_outer_tele_radius = 2
	var/necro_include_dense = FALSE
	var/necro_include_teleport_restricted = FALSE

/obj/effect/proc_holder/spell/invoked/call_dreamfiend/necromancer/cast(list/targets, mob/living/user)
	var/mob/living/carbon/target = targets[1]
	if(!istype(target))
		to_chat(user, span_warning("This spell only works on creatures capable of dreaming!"))
		revert_cast()
		return FALSE
	
	if(!summon_dreamfiend(
		target = target,
		user = user,
		F = /mob/living/simple_animal/hostile/rogue/dreamfiend,
		outer_tele_radius = necro_outer_tele_radius,
		inner_tele_radius = necro_inner_tele_radius,
		include_dense = necro_include_dense,
		include_teleport_restricted = necro_include_teleport_restricted
	))
		to_chat(user, span_warning("No valid space to manifest the dreamfiend!"))
		revert_cast()
		return FALSE
	
	// Assign the dreamfiend to the caster's faction and enable AI
	var/faction_tag = "[user.mind.current.real_name]_faction"
	for(var/mob/living/simple_animal/hostile/rogue/dreamfiend/D in range(5, target))
		D.faction |= faction_tag
		// Enable AI specifically for necromancer's dreamfiend
		D.can_have_ai = TRUE
		D.AIStatus = AI_ON
		break
	return TRUE
