class_name Hound
extends EnemyBase
## Fast robot dog (PLAN.md section 9.1). Runs at the player, telegraphs, then lunges.
## Teaches parrying: a parried lunge breaks its posture, opening it to an execution.
## States: idle → approach → windup → lunge → recover → approach...


func _ai(delta: float) -> void:
	apply_gravity(delta)
	match state:
		&"idle":
			run_toward(0.0, delta)
			if distance_to_target() <= data.aggro_range:
				set_state(&"approach")
		&"approach":
			if distance_to_target() > data.aggro_range * 1.5:
				set_state(&"idle")
				return
			face(direction_to_target())
			if absf(target.global_position.x - global_position.x) <= data.attack_range:
				set_state(&"windup")
				Audio.play(&"hound_windup", -8.0)
			else:
				run_toward(facing, delta)
		&"windup":
			velocity.x = move_toward(velocity.x, 0.0, data.acceleration * 2.0 * delta)
			telegraph()
			if state_past_frames(data.windup_frames):
				set_state(&"lunge")
				velocity = Vector2(facing * data.lunge_speed, -data.lunge_hop)
				attack_hitbox.reset_hits()
		&"lunge":
			attack_hitbox.active = not state_past_frames(data.active_frames)
			if attack_hitbox.active:
				attack_hitbox.process_hits()
			elif is_on_floor():
				set_state(&"recover")
		&"recover":
			run_toward(0.0, delta)
			if state_past_frames(data.recovery_frames):
				set_state(&"approach")
