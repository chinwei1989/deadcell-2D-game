class_name Layers
## Physics layer bit values. Names and order must match PHYSICS_LAYERS in
## res://dev/configure_project.gd (layer 1 = WORLD, layer 2 = ONE_WAY, ...).

const WORLD := 1 << 0
const ONE_WAY := 1 << 1
const PLAYER_BODY := 1 << 2
const ENEMY_BODY := 1 << 3
const PLAYER_ATTACK := 1 << 4
const ENEMY_ATTACK := 1 << 5
const PLAYER_HURTBOX := 1 << 6
const ENEMY_HURTBOX := 1 << 7
const PICKUPS := 1 << 8
const INTERACTABLES := 1 << 9
const HAZARDS := 1 << 10
const PROJECTILES := 1 << 11
const DEFLECTED := 1 << 12
