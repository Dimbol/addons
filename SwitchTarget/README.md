## SwitchTarget

The goal of this addon is to make meleeing more pleasant in busy events such as
Dynamis and Odyssey.

It changes "*engage enemy*" actions, e.g., from `/attack on <stnpc>`
to "*switch target*" actions when the player is, or was recently, engaged.

This is done because the behaviour of `/attack on` is subtly different from
changing target via the combat menu, and I wanted a more macro friendly version
without losing reliability.

Additionally, an incoming packet is injected so that the cursor moves to the new
target without the usual round-trip networking delay (often of a second or more.)
The method used is the same as the *SetTarget* addon, hence the similar naming.
