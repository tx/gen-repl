module gen_repl.game_objects;

import std.json;
import std.stdio;

struct UserState {
    int locationIndex;
    int health;
    int defense;
    int attack;
    Item[] inventory;
}

struct WorldState {
    bool isGameOver;
    string playerName;
    Location[] map;
}

enum GameCommand {
    Quit,
    GoTo,
    Look,
    PickUp,
    Unknown,
}

struct Location {
    string name;
    string description;
    string[] exits;
    Item[] items;
    Creature[] creatures;
}

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

struct Item {
    string name;
    string description;
    int locationIndex;
}

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

struct Creature {
    string name;
    int health;
    int defense;
    int attack;
    Item[] inventory;
}

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
