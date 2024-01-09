module gen_repl.game;

import std.algorithm;
import std.range;
import std.stdio;
import std.string;
import std.random;
import std.getopt;
import std.json; // Import the JSON module

import gen_repl.chat;

// Add the Item struct
struct Item {
    string name;
    string description;
    int locationIndex;  // Index of the location where the item is placed
}

// Update the Location struct to include items
struct Location {
    string name;
    string description;
    string[] exits;
    Item[] items;  // Array of items in the location
    Creature[] creatures;
}

// Add the Creature struct
struct Creature {
    string name;
    int health;
    int defense;
    int attack;
    Item[] inventory;  // Array of items the creature carries, with locationIndex
}

// Add the UserState struct
struct UserState {
    int locationIndex;
    int health;
    int defense;
    int attack;
    Item[] inventory;  // Collection of items the player has picked up, with locationIndex
}

// Add the WorldState struct
struct WorldState {
    bool isGameOver;
    string playerName;
}

Location[] gameWorld;
WorldState worldState;
UserState userState;
auto rnd = Random(42);

string itemsJSON = `[
    {"name": "Java Dagger", "description": "A dagger with Java syntax engraved."},
    {"name": "Agile Throwing Star", "description": "Throw it with the speed of an agile sprint."},
    {"name": "CSS Whip", "description": "A whip made of cascading style sheets."},
    {"name": "Marketing Spellbook", "description": "Unleashes the power of persuasive marketing spells."},
    {"name": "JavaScript Staff", "description": "A staff infused with the chaotic energy of JavaScript."},
    {"name": "Debugging Grenade", "description": "Throws a grenade that explodes into debugging tools."},
    {"name": "Caffeine Sword", "description": "A sword forged from the pure essence of caffeine."},
    {"name": "Meeting Room Portal Scroll", "description": "Opens a portal to the dreaded meeting room."},
    {"name": "Stress Ball Scepter", "description": "Squeeze it to release stress or cast stress-inducing spells."},
    {"name": "Post-it Note Darts", "description": "Throw darts made of sticky notes."},
    {"name": "Python Whistle", "description": "Summons the power of the Python programming language."},
    {"name": "HTML Shield", "description": "A shield made of HTML elements for front-end defense."},
    {"name": "JIRA Boomerang", "description": "Throws a boomerang that always comes back with more tasks."},
    {"name": "SQL Scroll of Querying", "description": "Unrolls a scroll with powerful SQL queries."},
    {"name": "Emoji Wand", "description": "Casts spells using the magic of emojis."},
    {"name": "Remote Control Gauntlet", "description": "Controls devices from a distance with the power of the remote."},
]`;

string creaturesJSON = `[
    {
        "name": "Code Gremlin",
        "description": "A mischievous creature that wreaks havoc in your code.",
        "health": 120,
        "defense": 10,
        "attack": 20,
        "inventory": [{"name": "Syntax Error Scroll", "description": "Unleashes confusing syntax errors on your foes."}]
    },
    {
        "name": "Buzzword Banshee",
        "description": "A spectral being that haunts your meetings with buzzwords.",
        "health": 140,
        "defense": 12,
        "attack": 22,
        "inventory": [{"name": "Marketing Jargon Shield", "description": "Deflects buzzwords with a touch of sarcasm."}]
    },
    {
        "name": "Deadline Lich",
        "description": "An undead creature obsessed with imposing deadlines.",
        "health": 160,
        "defense": 15,
        "attack": 25,
        "inventory": [{"name": "Procrastination Amulet", "description": "Delays the inevitable with style."}]
    },
    {
        "name": "Coffee Zombie",
        "description": "A creature fueled by decaf, spreading lethargy in its wake.",
        "health": 130,
        "defense": 11,
        "attack": 21,
        "inventory": [{"name": "Decaf Dagger", "description": "Strikes fear into the hearts of caffeine lovers."}]
    },
    {
        "name": "Pixel Pixie",
        "description": "A small, pixelated creature causing graphical glitches.",
        "health": 110,
        "defense": 9,
        "attack": 19,
        "inventory": [{"name": "Glitchy Wand", "description": "Casts spells of minor inconveniences."}]
    },
    {
        "name": "Project Manager Ogre",
        "description": "A massive ogre that thrives on project timelines and Gantt charts.",
        "health": 180,
        "defense": 18,
        "attack": 28,
        "inventory": [{"name": "Gantt Chart Shield", "description": "Blocks your progress with strategic planning."}]
    },
    {
        "name": "Email Imp",
        "description": "A mischievous imp that floods your inbox with irrelevant messages.",
        "health": 100,
        "defense": 8,
        "attack": 18,
        "inventory": [{"name": "Spam Scroll", "description": "Floods your inbox with irrelevant messages."}]
    },
    {
        "name": "Paperclip Golem",
        "description": "A massive golem made of animated paperclips.",
        "health": 150,
        "defense": 14,
        "attack": 24,
        "inventory": [{"name": "Clippy Hammer", "description": "Annoyingly helpful in unexpected situations."}]
    }
]`;

string locationsJSON = `[
    {
        "name": "Your Desk",
        "description": "A cubicle filled with comics and despair.",
        "exits": ["Meeting Room", "Kitchen"]
    },
    {
        "name": "Meeting Room",
        "description": "Where dreams of productivity go to die.",
        "exits": ["Your Desk", "Conference Room"]
    },
    {
        "name": "Kitchen",
        "description": "The sacred ground of caffeine worship and snack rituals.",
        "exits": ["Your Desk", "Break Room"]
    },
    {
        "name": "Conference Room",
        "description": "A place for endless discussions without resolutions.",
        "exits": ["Meeting Room"]
    },
    {
        "name": "Break Room",
        "description": "Escape here for a brief moment of sanity.",
        "exits": ["Kitchen"]
    },
    {
        "name": "Server Room Dungeon",
        "description": "Navigate through cables and server racks in this mysterious dungeon.",
        "exits": ["Meeting Room"]
    },
    {
        "name": "Code Review Cavern",
        "description": "A cavern echoing with the sounds of code scrutiny.",
        "exits": ["Your Desk"]
    },
    {
        "name": "Boss's Lair",
        "description": "Enter at your own risk. The lair of the ultimate decision-maker.",
        "exits": ["Conference Room", "Server Room Dungeon"]
    }
]`;

// Dummy function to parse items from JSON
Item[] toItems(JSONValue itemsJSON)
{
    Item[] items;
    foreach (itemJSON; itemsJSON.array)
    {
        auto itemObj = itemJSON.object;
        Item item;

        item.name = itemObj["name"].str;
        item.description = itemObj["description"].str;

        items ~= item;
    }

    return items;
}

// Dummy function to parse creatures from JSON
Creature[] toCreatures(JSONValue creaturesJSON)
{
    Creature[] creatures;
    foreach (creatureJSON; creaturesJSON.array)
    {
        auto creatureObj = creatureJSON.object;
        Creature creature;

        creature.name = creatureObj["name"].str;
        creature.health = creatureObj["health"].get!int;
        creature.defense = creatureObj["defense"].get!int;
        creature.attack = creatureObj["attack"].get!int;

        // Populate inventory
        auto inventoryJSON = creatureObj["inventory"];
        if (inventoryJSON.type == JSONType.array)
           creature.inventory = inventoryJSON.toItems();

        creatures ~= creature;
    }

    return creatures;
}

// Dummy function to parse locations from JSON
Location[] toLocations(JSONValue locationsJSON)
{
    Location[] world = [];
    if (locationsJSON.type != JSONType.array)
    {
        writeln("Error: Invalid JSON structure for locations.");
        return world;
    }

    foreach (locationJSON; locationsJSON.array)
    {
        auto locationObj = locationJSON.object;
        Location location;
        location.name = locationObj["name"].str;
        location.description = locationObj["description"].str;
        foreach (exit; locationObj["exits"].array) {
          location.exits ~= exit.get!string;
        }

        world ~= location;
    }
    return world;
}

// Function to randomly populate items and/or creatures in locations
void randomPopulateLocations(Location[] locations, Item[] items, Creature[] creatures)
{
    // Tracks the items and creatures that have been added
    Item[] addedItems;
    Creature[] addedCreatures;
    while ( addedItems.length < items.length || addedCreatures.length < creatures.length )
      {
        foreach (ref location; locations)
          {
            // Randomly add items
            if (uniform(0, 100, rnd) % 2 == 0)
              {
                // Add a random item from the items array if not already added
                Item[] remainingItems = items.filter!(item => !addedItems.canFind(item)).array();
                if(!remainingItems.empty())
                  {
                    auto randomItem = remainingItems.choice(rnd);
                    addedItems ~= randomItem;
                    location.items ~= randomItem;
                  }
              }
            
            // Randomly add creatures
            if (uniform(0, 100, rnd) % 2 == 0)
              {
                // Add a random creature from the creatures array if not already added
                Creature[] remainingCreatures = creatures.filter!(creature => !addedCreatures.canFind(creature)).array();
                if(!remainingCreatures.empty())
                  {
                    auto randomCreature = remainingCreatures.choice(rnd);
                    addedCreatures ~= randomCreature;
                    location.creatures ~= randomCreature;
                  }
              }
          }
      }
}

// Add functions to handle items
void displayItems()
{
    writeln("Items in the current location:");
    foreach (item; gameWorld[userState.locationIndex].items)
    {
        writeln("\t", item.name, " - ", item.description);
    }
}

void displayLocation()
{
    writeln("You are in " ~ gameWorld[userState.locationIndex].description.toLower());
}

void displayInventory()
{
  if(userState.inventory.empty())
    {
      writeln("Your backpack is empty.");
    }
  else {
      writeln("You look in your pack and find the following:");
      foreach (item; userState.inventory)
        {
          writeln("\t", item.name, " - ", item.description);
        }
  }
}

void displayCreatures()
{
  if(!gameWorld[userState.locationIndex].creatures.empty())
    {
      writeln("You are not alone...");
      foreach (enemyCreature; gameWorld[userState.locationIndex].creatures)
        {
          writeln("\tYou see a ", enemyCreature.name, "!");
        }
    }
}

void displayStatus()
{
  // Display items in the location
  displayItems();
  // Display player's inventory
  displayInventory();
  // Display creature's inventory
  displayCreatures();
}

bool pickUpItem(string itemName)
{
    foreach (i, item; gameWorld[userState.locationIndex].items)
    {
        if (item.name.toLower() == itemName)
        {
            // Add the item to the player's inventory
            userState.inventory ~= item;
            writeln("Picked up ", item.name, ".");
            // Optionally, you can remove the item from the location
            gameWorld[userState.locationIndex].items = gameWorld[userState.locationIndex].items.remove(i);
            return true;
        }
    }
    writeln("Cannot find '", itemName, "' in this location.");
    return false;
}

// Dummy function to start the text adventure game
bool startTextAdventureGame()
{
    gameWorld = toLocations(parseJSON(locationsJSON));
    worldState = WorldState(false, "");
    userState = UserState(0, 100, 10, 20, []); // Initial health, defense, attack values

    writeln("Welcome to the Text Adventure Game! What's your name? ");
    worldState.playerName = readln().strip();
    worldState.isGameOver = false;
    userState.locationIndex = 0;

    // Parse items and creatures from JSON
    Item[] items = toItems(parseJSON(itemsJSON));
    Creature[] creatures = toCreatures(parseJSON(creaturesJSON));

    // Randomly populate items and creatures in locations
    randomPopulateLocations(gameWorld, items, creatures);

    writeln("Hello, ", worldState.playerName, "! Let the adventure begin!");
    return true;
}

bool handleGameInput(string userInput)
{
    // Convert the input to lowercase for case-insensitive matching
    userInput = userInput.toLower();

    // Handle game-specific commands
    if (userInput == "quit" || userInput == "exit")
    {
        writeln("Goodbye, ", worldState.playerName, "!");
        worldState.isGameOver = true;
        return false;
    }
    else if (userInput.startsWith("go to "))
    {
        // Handle "go to [location]" command
        string destination = userInput[6..$].strip();
        moveToLocation(destination);
        return true;
    }
    else if (userInput == "look" || userInput == "examine" || userInput == "look around")
    {
        // Display current location description
        displayLocation();
        // List available exits
        writeln("Available exits: \n\t", gameWorld[userState.locationIndex].exits.join(", "));
        // Display player's status
        displayStatus();
        return true;
    }
    else if (userInput.startsWith("pick up "))
    {
        // Handle "pick up [item]" command
        string itemName = userInput[8..$].strip();
        pickUpItem(itemName);
        return true;
    }
    else
    {
        writeln("I don't understand that.");
        return true;
    }
}

void moveToLocation(string destination)
{
    // Find the index of the destination location
    int destinationIndex = -1;
    foreach (i, location; gameWorld)
    {
        if (location.name.toLower() == destination)
        {
            destinationIndex = cast(int)i;
            break;
        }
    }

    // Check if the destination exists and is reachable from the current location
    if (destinationIndex != -1 && gameWorld[destinationIndex].exits.find(destination))
    {
        // Move to the new location
        userState.locationIndex = destinationIndex;
        writeln("Moved to ", gameWorld[destinationIndex].name);
    }
    else
    {
        writeln("Cannot go to '", destination, "'.");
    }
}
