A system for obfuscating and translating fictional languages in Lua. It is intended for use in the game Shards Online, but as most of the code is referentially transparent it could be ported to other games using Lua.

This system is inspired by NWN language systems which performed simple letter substitution. It differs in a few ways:
* Whether or not a language is known is not binary, but expressed as a skill. More complex words require more skill to read, write, speak and understand.
* Multi-letter substitution is possible, as well as whole-word substitution.
* Creatures can learn languages by listening to them and speaking them.

The goal is to obfuscate unknown words in a manner which makes them sound like whatever language is being spoken, while leaving known words unmolested. String and whole-word substitution lets us do this without the overhead of a real translator.

Todo:
* Handle spoken and written languages differently.
* Handle mis-translations and mis-speaking.
* Add some commonly-used languages, such as elvish.
* Tie it into Shards itself, when available.
  * Handle learning.
  * Use a similar module layout and test suite to whatever Shards uses.

This repository will not be integrated with Shards itself until the alpha NDA has dropped.

Usage:
`busted tests` to run the test suite.