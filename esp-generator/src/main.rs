use tes3::esp::{AttributeId, AttributeId2, Effect, EffectId2, Faction, FactionData, FactionReaction, FactionRequirement, FileType, FixedString, Header, ObjectFlags, Plugin, SkillId, SkillId2, Spell, SpellData, SpellType, TES3Object};

fn phobia() -> TES3Object {
    let mut effects = vec![];
    for skill in [SkillId2::Acrobatics,
                  SkillId2::Alchemy,
                  SkillId2::Alteration,
                  SkillId2::Armorer,
                  SkillId2::Athletics,
                  SkillId2::Axe,
                  SkillId2::Block,
                  SkillId2::BluntWeapon,
                  SkillId2::Conjuration,
                  SkillId2::Destruction,
                  SkillId2::Enchant,
                  SkillId2::HandToHand,
                  SkillId2::HeavyArmor,
                  SkillId2::Illusion,
                  SkillId2::LightArmor,
                  SkillId2::LongBlade,
                  SkillId2::Marksman,
                  SkillId2::MediumArmor,
                  SkillId2::Mercantile,
                  SkillId2::Mysticism,
                  SkillId2::Restoration,
                  SkillId2::Security,
                  SkillId2::ShortBlade,
                  SkillId2::Sneak,
                  SkillId2::Spear,
                  SkillId2::Speechcraft,
                  SkillId2::Unarmored] {
        effects.push(Effect {
            magic_effect: EffectId2::DrainSkill,
            skill,
            attribute: AttributeId2::None,
            range: 0,
            area: 0,
            duration: 60, // 86400, // 1 day
            min_magnitude: 20,
            max_magnitude: 20,
        });
    }
    TES3Object::Spell(Spell {
        flags: ObjectFlags::empty(),
        id: "special_phobia".to_owned(),
        name: Some("Phobia".to_owned()),
        data: Some(SpellData {
            kind: SpellType::Spell,
            cost: 0,
            flags: 0,
        }),
        effects: Some(effects),
    })
}

fn night_person() -> TES3Object {
    let mut effects = vec![];
    for attribute in [AttributeId2::Intelligence,
                      AttributeId2::Willpower,
                      AttributeId2::Personality,
                      AttributeId2::Agility] {
        effects.push(Effect {
            magic_effect: EffectId2::FortifyAttribute,
            skill: SkillId2::None,
            attribute,
            range: 0,
            area: 0,
            duration: 0,
            min_magnitude: 10,
            max_magnitude: 10,
        })
    }
    TES3Object::Spell(Spell {
        flags: ObjectFlags::empty(),
        id: "special_night_person".to_owned(),
        name: Some("Night Person".to_owned()),
        data: Some(SpellData {
            kind: SpellType::Ability,
            cost: 0,
            flags: 0,
        }),
        effects: Some(effects),
    })
}

fn good_natured() -> TES3Object {
    let mut effects = vec![];
    for skill in [SkillId2::Spear,
                  SkillId2::Axe,
                  SkillId2::BluntWeapon,
                  SkillId2::LongBlade,
                  SkillId2::Marksman,
                  SkillId2::HandToHand,
                  SkillId2::ShortBlade,
                  SkillId2::Mysticism,
                  SkillId2::Destruction] {
        effects.push(Effect {
            magic_effect: EffectId2::DrainSkill,
            skill,
            attribute: AttributeId2::None,
            range: 0,
            area: 0,
            duration: 0,
            min_magnitude: 10,
            max_magnitude: 10,
        });
    }
    for skill in [SkillId2::HeavyArmor,
                  SkillId2::MediumArmor,
                  SkillId2::Acrobatics,
                  SkillId2::Armorer,
                  SkillId2::Block,
                  SkillId2::LightArmor,
                  SkillId2::Sneak,
                  SkillId2::Athletics,
                  SkillId2::Unarmored,
                  SkillId2::Mercantile,
                  SkillId2::Speechcraft,
                  SkillId2::Illusion,
                  SkillId2::Alchemy,
                  SkillId2::Conjuration,
                  SkillId2::Enchant,
                  SkillId2::Security,
                  SkillId2::Alteration,
                  SkillId2::Restoration] {
        effects.push(Effect {
            magic_effect: EffectId2::FortifySkill,
            skill,
            attribute: AttributeId2::None,
            range: 0,
            area: 0,
            duration: 0,
            min_magnitude: 5,
            max_magnitude: 5,
        });
    }
    TES3Object::Spell(Spell {
        flags: ObjectFlags::empty(),
        id: "special_good_natured".to_owned(),
        name: Some("Good Natured".to_owned()),
        data: Some(SpellData {
            kind: SpellType::Ability,
            cost: 0,
            flags: 0,
        }),
        effects: Some(effects)
    })
}

fn ability<S: Into<String>>(name: S, magic_effect: EffectId2, skill: SkillId2, attribute: AttributeId2, magnitude: u32) -> TES3Object {
    let name = name.into();
    let id = "special_".to_owned() + &name.to_lowercase().replace(" ", "_");
    TES3Object::Spell(Spell {
        flags: ObjectFlags::empty(),
        id,
        name: Some(name),
        data: Some(SpellData {
            kind: SpellType::Ability,
            cost: 0,
            flags: 0,
        }),
        effects: Some(vec![
            Effect {
                magic_effect,
                skill,
                attribute,
                range: 0,
                area: 0,
                duration: 0,
                min_magnitude: magnitude,
                max_magnitude: magnitude,
            }
        ]),
    })
}

fn element_to_effects(element: &str) -> (EffectId2, EffectId2) {
    match element {
        "Fire" => (EffectId2::ResistFire, EffectId2::WeaknessToFire),
        "Frost" => (EffectId2::ResistFrost, EffectId2::WeaknessToFrost),
        "Shock" => (EffectId2::ResistShock, EffectId2::WeaknessToShock),
        "Poison" => (EffectId2::ResistPoison, EffectId2::WeaknessToPoison),
        "Magicka" => (EffectId2::ResistMagicka, EffectId2::WeaknessToMagicka),
        _ => panic!("Unknown element {element}"),
    }
}

trait RichPlugin {
    fn add_ability<S: Into<String>>(&mut self, name: S, effect: EffectId2, skill: SkillId2, attribute: AttributeId2, magnitude: u32);

    fn add_skill_ability<S: Into<String>>(&mut self, name: S, effect: EffectId2, skill: SkillId2, magnitude: u32) {
        self.add_ability(name, effect, skill, AttributeId2::None, magnitude)
    }

    fn add_attr_ability<S: Into<String>>(&mut self, name: S, effect: EffectId2, attribute: AttributeId2, magnitude: u32) {
        self.add_ability(name, effect, SkillId2::None, attribute, magnitude)
    }

    fn add_base_ability<S: Into<String>>(&mut self, name: S, effect: EffectId2, magnitude: u32) {
        self.add_ability(name, effect, SkillId2::None, AttributeId2::None, magnitude)
    }
}

impl RichPlugin for Plugin {
    fn add_ability<S: Into<String>>(&mut self, name: S, effect: EffectId2, skill: SkillId2, attribute: AttributeId2, magnitude: u32) {
        self.objects.push(ability(name, effect, skill, attribute, magnitude))
    }
}

fn get_output_file() -> String {
    let mut args = std::env::args();
    let executable = args.next().expect("Executable name not found");
    args.next().unwrap_or_else({ ||
        panic!("Usage: {executable} <output_file>")
    })
}

fn main() {
    let output_file = get_output_file();

    let mut plugin = Plugin::new();

    plugin.objects.push(TES3Object::Header(Header {
        flags: ObjectFlags::empty(),
        version: 1.0,
        file_type: FileType::Esp,
        author: FixedString("Elsky".to_string()),
        description: FixedString("".to_string()),
        num_objects: 0,
        masters: None,
    }));

    for element in ["Fire", "Frost", "Shock", "Poison", "Magicka"] {
        let (resist_effect, weakness_effect) = element_to_effects(element);
        plugin.add_base_ability(format!("Immunity to {element}"), resist_effect, 100);
        plugin.add_base_ability(format!("High Resistance to {element}"), resist_effect, 75);
        plugin.add_base_ability(format!("Resistance to {element}"), resist_effect, 50);
        plugin.add_base_ability(format!("Low Resistance to {element}"), resist_effect, 25);
        plugin.add_base_ability(format!("Small Weakness to {element}"), weakness_effect, 25);
        plugin.add_base_ability(format!("Weakness to {element}"), weakness_effect, 50);
        plugin.add_base_ability(format!("Great Weakness to {element}"), weakness_effect, 75);
        plugin.add_base_ability(format!("Critical Weakness to {element}"), weakness_effect, 100);
    }

    plugin.add_attr_ability("Robust", EffectId2::FortifyAttribute, AttributeId2::Endurance, 10);
    plugin.add_attr_ability("Fragile", EffectId2::DamageAttribute, AttributeId2::Endurance, 10);
    plugin.add_attr_ability("Strong", EffectId2::FortifyAttribute, AttributeId2::Strength, 10);
    plugin.add_attr_ability("Weak", EffectId2::DamageAttribute, AttributeId2::Strength, 10);
    plugin.add_attr_ability("Agile", EffectId2::FortifyAttribute, AttributeId2::Agility, 10);
    plugin.add_attr_ability("Clumsy", EffectId2::DamageAttribute, AttributeId2::Agility, 10);
    plugin.add_attr_ability("Fast", EffectId2::FortifyAttribute, AttributeId2::Speed, 10);
    plugin.add_attr_ability("Slow", EffectId2::DamageAttribute, AttributeId2::Speed, 10);
    plugin.add_attr_ability("Charismatic", EffectId2::FortifyAttribute, AttributeId2::Personality, 10);
    plugin.add_attr_ability("Uncharismatic", EffectId2::DamageAttribute, AttributeId2::Personality, 10);
    plugin.add_attr_ability("Intelligent", EffectId2::FortifyAttribute, AttributeId2::Intelligence, 10);
    plugin.add_attr_ability("Stupid", EffectId2::DamageAttribute, AttributeId2::Intelligence, 10);
    plugin.add_attr_ability("Resolute", EffectId2::FortifyAttribute, AttributeId2::Willpower, 10);
    plugin.add_attr_ability("Irresolute", EffectId2::DamageAttribute, AttributeId2::Willpower, 10);
    plugin.add_attr_ability("Lucky", EffectId2::FortifyAttribute, AttributeId2::Luck, 10);
    plugin.add_attr_ability("Unlucky", EffectId2::DamageAttribute, AttributeId2::Luck, 10);

    plugin.add_base_ability("Regenerative", EffectId2::RestoreHealth, 1);
    plugin.add_base_ability("Relentless", EffectId2::RestoreFatigue, 4);
    plugin.add_base_ability("Recharging", EffectId2::RestoreMagicka, 1);

    for (name, skill) in [("Heavy Armor", SkillId2::HeavyArmor),
                          ("Medium Armor", SkillId2::MediumArmor),
                          ("Spear", SkillId2::Spear),
                          ("Acrobatics", SkillId2::Acrobatics),
                          ("Armorer", SkillId2::Armorer),
                          ("Axe", SkillId2::Axe),
                          ("Blunt Weapon", SkillId2::BluntWeapon),
                          ("Long Blade", SkillId2::LongBlade),
                          ("Block", SkillId2::Block),
                          ("Light Armor", SkillId2::LightArmor),
                          ("Marksman", SkillId2::Marksman),
                          ("Sneak", SkillId2::Sneak),
                          ("Athletic", SkillId2::Athletics),
                          ("HandToHand", SkillId2::HandToHand),
                          ("Short Blade", SkillId2::ShortBlade),
                          ("Unarmored", SkillId2::Unarmored),
                          ("Illusion", SkillId2::Illusion),
                          ("Mercantile", SkillId2::Mercantile),
                          ("Speechcraft", SkillId2::Speechcraft),
                          ("Alchemy", SkillId2::Alchemy),
                          ("Conjuration", SkillId2::Conjuration),
                          ("Enchant", SkillId2::Enchant),
                          ("Security", SkillId2::Security),
                          ("Alteration", SkillId2::Alteration),
                          ("Destruction", SkillId2::Destruction),
                          ("Mysticism", SkillId2::Mysticism),
                          ("Restoration", SkillId2::Restoration)] {
        plugin.add_skill_ability(format!("Proficient in {name}"), EffectId2::FortifySkill, skill, 20);
        plugin.add_skill_ability(format!("Inept at {name}"), EffectId2::DamageSkill, skill, 100);    
    }

    plugin.add_base_ability("Shadowborn", EffectId2::Chameleon, 20);
    plugin.add_base_ability("Dodger", EffectId2::Sanctuary, 20);

    plugin.objects.push(phobia());
    plugin.objects.push(night_person());
    plugin.objects.push(good_natured());

    plugin.save_path(output_file).unwrap()
}