module gen_repl.game_objects;

import std.algorithm;
import std.array;
import std.json;
import std.random;
import std.stdio;
import std.string;

struct UserState {
  int locationIndex;
  int health;
  int defense;
  int attack;
  Item[] inventory;
}

struct UserAction {
  GameCommand command;
  string location;
  string item;
  string creature;
}

struct WorldState {
  bool isGameOver;
  string playerName;
  Creature[] creatures;
  Item[] items;
  Location[] map;
}

enum GameCommand {
  Quit,
  GoTo,
  Look,
  PickUp,
  Attack,
  Unknown,
}

struct Location {
  string name;
  string description;
  string[] exits;
  Item[] items;
  Creature[] creatures;
}

struct Item {
  string name;
  string description;
  int locationIndex;
}

struct Creature {
  string name;
  int health;
  int defense;
  int attack;
  Item[] inventory;
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

// Function to randomly populate items and/or creatures in locations
void populateMap(ref WorldState worldState)
{
  auto rnd = Random(42);
  // Tracks the items and creatures that have been added
  Item[] addedItems;
  Creature[] addedCreatures;
  while ( (addedItems.length < worldState.items.length || addedCreatures.length < worldState.creatures.length) && worldState.map.length > 0)
    {
      foreach (ref location; worldState.map)
        {
          // Randomly add items
          if (uniform(0, 10, rnd) % 2 == 0)
            {
              // Add a random item from the items array if not already added
              Item[] remainingItems = worldState.items.filter!(item => !addedItems.canFind(item)).array();
              if(!remainingItems.empty())
                {
                  auto randomItem = remainingItems.choice(rnd);
                  addedItems ~= randomItem;
                  location.items ~= randomItem;
                }
            }
          
          // Randomly add creatures
          if (uniform(0, 10, rnd) % 2 == 0)
            {
              // Add a random creature from the creatures array if not already added
              Creature[] remainingCreatures = worldState.creatures.filter!(creature => !addedCreatures.canFind(creature)).array();
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

UserAction parseUserAction(string userInput) {
  UserAction action;
  userInput = userInput.toLower();
  
  if (userInput == "quit" || userInput == "exit") {
    action.command = GameCommand.Quit;
  } else if (userInput.startsWith("go to ")) {
    action.command = GameCommand.GoTo;
  } else if (userInput == "look" || userInput == "examine" || userInput == "look around") {
    action.command = GameCommand.Look;
  } else if (userInput.startsWith("pick up ")) {
    action.command = GameCommand.PickUp;
  } else if (userInput.startsWith("attack ")) {
    action.command = GameCommand.Attack;
    // Extract creature and optional item
    auto parts = userInput[7..$].split(" with ");
    action.creature = parts[0].strip();
    if (parts.length > 1) {
      action.item = parts[1].strip();
    }
  } else {
    action.command = GameCommand.Unknown;
  }
  
  // Extract targets based on the command
  switch (action.command) {
  case GameCommand.GoTo:
    action.location = userInput[6..$].strip();
    break;
    
  case GameCommand.Look:
    // No specific targets for "look" command
    break;
    
  case GameCommand.PickUp:
    action.item = userInput[8..$].strip();
    break;
    
    // Add cases for other commands if needed
    
  default:
    // Unknown command, no specific targets
    break;
  }
  
  return action;
}
