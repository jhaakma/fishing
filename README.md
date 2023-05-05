# Fishing
A Fishing mod for Morrowind

## To do
- Casting - DONE
- Fish trail - DONE
- Custom ripple animation - DONE
- Fish and meat models - DONE
- Fillet mechanic
- Animate fishing line
- Catch preview - DONE
- Fishing rods
- Fishing lure/bait
- Fishing skill
- Convert vanilla fishing rods to weapon
- Fishing "hotspots"
- Niches 
  - region - DONE
  - time of day - DONE
  - interior/exteriors - DONE
  - depth - DONE
  - weather?
- Integrate fish speed
- "Quality" fish variants

## Fishing Rods
| Name                 | Description                                                                                                  |
| -------------------- | ------------------------------------------------------------------------------------------------------------ |
| Wooden Fishing Pole  | Little more than a stick with a string attached. Crafted from wood, resin and plant fibre.                   |
| Chitin Fishing Rod   | An affordable fishing rod made of flexible chitin, popular with the Ashlanders.                              |
| Heavy Fishing Rod    | A fishing rod made of heavy steel that can stand against even the mightiest of fish.                         |
| Glass Fishing Rod    | Light, flexible, but very strong, this fishing rod is unmatched.                                             |
| Dwemer Fishing Rod   | With it's dwemer metal fishing line, this rod is capable of fishing in lava pools.                           |

## Bait/lures
| Name            | Crafting Components  | Description                                                                                                     |
| --------------  | -------------------- | --------------------------------------------------------------------------------------------------------------- |
| Crab bait       | Crab meat            | This bait is especially effective at luring the fish found in the swamps.                                       |
| Scaley lure     | Slaughterfish scales | This lure reflects sunlight, making it most effective during the day.                                           |
| Spinner         | Racer plumes         | This lure spins in the water, making it very effective at attracting freshwater fish in lakes and rivers.       |
| Glow bait    | Glowbugs             | This lure glow in the dark, making it very effective at night time.                                             |
| Jelly bait      | Scrib jelly          | The smell of this bait allows it to attract fish even in the murky, ash-ridden waters of Vvardenfell.           |
| Iridescent lure | Pearls               | This lure is very shiny, making it most effective during the day.                                               |
| Scrap Sinker    | Dwemer scrap metal   | This heavy sinker drags along the ocean floor, good for catching debris and occasional treasure.                |

## Fish
| Name                 | Location      | Description                                                                                                    |
| -------------------- | ------------- | -------------------------------------------------------------------------------------------------------------- |
| Slaughterfish        | Everywhere    | The most common fish in Vvardehfell. Their shiny scales can be crafted into an effective lure.                 |
| Ashclaw              | Volcanic      | A fish with long, claw-like fins that it uses to cling to rocks and other underwater surfaces.                 |
| Marrowfish           | West Gash     | A bony fish with glowing red eyes and a spine that runs along its back.                                       |


## Reeling mechanic

When a fish is snagged, it will fight against the player until it tires out. The player must reel in the fish by holding down left-click, while keeping just enough tension on the line to prevent it from snapping. If the player reels in too fast, the line will snap. If the player reels in too slow, the fish will escape.

While reeling in, the fish will occasionally pull the line in a random direction, potentially adding or reducing tension. The player must react to this by reeling or releasing the line.

An indicator at the top of the screen shows how much tension is on the line, and how exhausted the fish is. When the exhaustion bar is empty, the fish is caught.

### Fish AI
```
pick_position()
    - while no position
        - pick distance
        - pick direction
        - if clear, set position
move_to_position()
    - while not at position
        - generate ripple
        - increase exhaustion based on tension levels
        - if tension > max tension, break line
        - if tension < 0, escape
        - if exhaustion > max exhaustion, caught
        - move towards position
        - update tension 
            - increase tension if moving away from player
            - increase tension if player has mouse button down
            - decrease tension if player has mouse button up
wait()
    - wait for random time
    - pick new position
```
