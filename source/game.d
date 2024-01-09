module gen_repl.game;

import std.algorithm;
import std.stdio;
import std.string;
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
Creature enemyCreature;
string gameMap = `[
    {
        "name": "Forest",
        "description": "A dense forest with tall trees.",
        "exits": ["Cave", "River"],
        "items": [
            {"name": "Magic Wand", "description": "A powerful wand.", "locationIndex": 0}
        ],
        "creatures": [
            {
                "name": "Dragon",
                "health": 150,
                "defense": 15,
                "attack": 25,
                "inventory": [{"name": "Fire Breath", "description": "A powerful fire attack.", "locationIndex": 0}]
            }
        ]
    },
    {
        "name": "Cave",
        "description": "A dark cave with mysterious echoes.",
        "exits": ["Forest"],
        "items": [
            {"name": "Health Potion", "description": "Restores health.", "locationIndex": 1}
        ],
        "creatures": []
    },
    {
        "name": "River",
        "description": "A gentle river flowing through the landscape.",
        "exits": ["Forest"],
        "items": [
            {"name": "Map", "description": "A detailed map of the area.", "locationIndex": 2}
        ],
        "creatures": []
    }
]
`;

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
        item.locationIndex = itemObj["locationIndex"].get!int;

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

Location[] populateGameWorld(JSONValue locationsJSON)
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

        // Populate items
        auto itemsJSON = locationObj["items"];
        if (itemsJSON.type == JSONType.array)
           location.items = itemsJSON.toItems();

        // Populate creatures
        auto creaturesJSON = locationObj["creatures"];
        if (creaturesJSON.type == JSONType.array)
           location.creatures = creaturesJSON.toCreatures();

        world ~= location;
    }
    return world;
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
    writeln("You look in your pack and find the following:");
    foreach (item; userState.inventory)
    {
        writeln("\t", item.name, " - ", item.description);
    }
}

void displayCreatureInventory()
{
    writeln("The creature carries the following items:");
    foreach (item; enemyCreature.inventory)
    {
        writeln("\t", item.name, " - ", item.description);
    }
}

void displayStatus()
{
  // Display items in the location
  displayItems();
  // Display player's inventory
  displayInventory();
  // Display creature's inventory
  displayCreatureInventory();
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
    gameWorld = parseJSON(gameMap).populateGameWorld();
    worldState = WorldState(false, "");
    userState = UserState(0, 100, 10, 20, []); // Initial health, defense, attack values

    writeln("Welcome to the Text Adventure Game! What's your name? ");
    worldState.playerName = readln().strip();
    worldState.isGameOver = false;
    userState.locationIndex = 0;
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
