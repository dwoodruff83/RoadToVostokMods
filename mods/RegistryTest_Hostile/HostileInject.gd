extends "res://Scripts/Database.gd"

# Bare hostile extension. No registered items, no _get override.
# Simulates a naive item-adding mod that did the wrong thing — extended
# Database.gd directly without using the registry's coordinated API.
#
# This is intentionally minimal. The point is to clobber whatever script
# was previously on /root/Database (which would normally be DatabaseInject
# from RTVModItemRegistry) so we can observe how the registry handles
# being overwritten by a non-cooperating sibling.
