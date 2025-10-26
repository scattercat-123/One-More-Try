extends Node
var debug_mode = false  ## only for dev, for quickly chekcnig changes instead of playing the entire game..
var wave = 1
var total_waves = 10
var enemies_left = 0
var stamina_regen = 0.2
var player_dmg
var damage = 0
var extra_dmgee = 0
var player_health = 100
var max_health = 100
var has_died = false
var boss_1_health_value = 500
# powers:
var speed_boost=0
var extra_health = 0
var extra_range = 0
var extra_dmg = 0
var crit_hit = false
var lag = false
var risk_taker = false
var second_chance = false
var wavey = false
var extra_per_wavey = 0
var turtle = false
var LEGEND = false
var health_pack = 0
var boss_1_state = "none"
