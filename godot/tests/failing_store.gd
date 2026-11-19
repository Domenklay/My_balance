extends "res://src/store.gd"

# Explicit storage-failure simulation: no real files are touched.
# Used to ensure app state rolls back when disk writes fail.
func save() -> bool:
    return false
