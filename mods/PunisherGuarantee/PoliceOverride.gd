extends "res://Scripts/Police.gd"

# Forces the police van into Boss mode so the Punisher spawn sequence runs
# every time the Police event fires, instead of a 50/50 coin flip.

func _ready() -> void:
    super()

    if currentState != State.Boss:
        currentState = State.Boss
        ActivateLights()
        var pg = get_node_or_null("/root/PunisherGuarantee")
        if pg and pg.has_method("_log"):
            pg._log("Police van forced to Boss mode")
