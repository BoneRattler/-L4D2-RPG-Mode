# -L4D2-RPG-Mode

## Level
Every Survivor starts at level 0 and can level to a maximum of 100.
Each level, survivors receive (by default) 5 Status Points and 1 Skill point.

## Status Points
Every Level, survivors receive status points which can be used to increase attributes.

The 5 attributes are:
* Strength: Increases damage
* Agility: Increases move speed and jump height
* Health: Increases max health
* Endurance: Decreases damage from infected, at higher levels adds damage reflection
* Intelligence: Increases potency of skills

## Skills
RPG Mode contains a plethora of skills which can be activated by assigning them to your **Zoom** key using the menu.
Only **one** skill can be assigned at a time, and assignment can be changed on the fly. Skills come in 2 flavors, **Passive** and **Active**.
**Passive** skills are active at all times and are specified here, **Active** skills must be activated by pressing **Zoom**.

There are 2 skills common to all classes,
they are:
* Healing: Restores health to the player
* EarthQuake: Kills all common infected in a radius

More skills exist that require certain classes, but they will be discussed in the relative class's section.

## Classes
2 requirements must be met to select a class:
* Level - You must be level **15** before you can select any class
* Stats - You must meet the class's requirement for **Status points**

The status points required to select each class can be viewed in the info section of the menu.

Currently 3 classes are implemented:
* Engineer
  * Stat Requirement: 65 INT
  * Skills:
    * Fortify Weapon: (Passive) Increases attack speed
    * Making Ammo: Adds ammunition to clip relative to level
* Soldier
  * Stat Requirement:
  * Skills:
    * Sprint: Temporarily doubles move speed
    * Infinite Ammo: No ammo consumption
    * Trained Health: (Passive) Increases the effectiveness of status points in health, and provides extra resistances
* Bionic Weapon
  * Stat Requirement:
  * Skills:
    * Bionic Shield: Temporarily take no damage, also increases attack speed
Each class also adds bonus status points upon selection.

## Admin Commands
2 Commands exist for admin use:
* sm_giveexp [name] [amount of exp to give]
* sm_givelv [name] [amount of levels to give]

Admins cannot award over maximum exp/level. The commands will not work if attempting to add over max.
