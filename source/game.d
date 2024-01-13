module gen_repl.game;

import std.algorithm;
import std.range;
import std.stdio;
import std.string;
import std.random;
import std.getopt;
import std.json;
import painlessjson;

import gen_repl.chat;
import gen_repl.game_data;
import gen_repl.game_objects;

WorldState worldState;
UserState userState;
auto rnd = Random(42);

// Gamemaster Config
string modelName; 
const gameMasterIdentity = "You are a creative, humorous and sarcastic gamemaster guiding the user through a text adventure game. You posses great knowledge about games as well as the topics of the game scenario. You address the user in the second person and speak colorfully and with vivid imagery.";
const string scenario = "Guide your players through an offbeat office adventure! Set in a marketing tech consultancy, junior developers navigate surreal challenges with tools like the Java Dagger and encounter creatures such as Code Gremlins and Buzzword Banshees. Create an absurd atmosphere, weave humorous narratives, and keep the team entertained in this unique office fantasy!";

// Function to randomly populate items and/or creatures in locations
void populate(Location[] locations, Item[] items, Creature[] creatures)
{
  // Tracks the items and creatures that have been added
  Item[] addedItems;
  Creature[] addedCreatures;
  while ( (addedItems.length < items.length || addedCreatures.length < creatures.length) && locations.length > 0)
    {
      foreach (ref location; locations)
        {
          // Randomly add items
          if (uniform(0, 10, rnd) % 2 == 0)
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
          if (uniform(0, 10, rnd) % 2 == 0)
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

void displayItems()
{
  auto items = worldState.map[userState.locationIndex].items;
  gameMasterPrompt("Briefly describe the room and iteratively the items the user sees in the room", toJSON(items).toString());
}

void displayLocation()
{
  Location location = worldState.map[userState.locationIndex];
}

void displayInventory()
{
  if(userState.inventory.empty())
    {
      writeln("\nYour backpack is empty.");
    }
  else {
    writeln("\nYou have the following your backpack:");
    foreach (item; userState.inventory)
      {
        writeln("\t", item.name, " - ", item.description);
      }
  }
}

void displayCreatures()
{
  if(!worldState.map[userState.locationIndex].creatures.empty())
    {
      writeln("\nYou are not alone...");
      gameMasterPrompt("The user has already seen one or more creatues in the room, remind them that they are present.", toJSON(worldState.map[userState.locationIndex].creatures).toString());
    }
}

void displayStatus()
{
  // Display items in the location
  displayItems();
  // Display player's inventory
  displayInventory();
}

void gameMasterPrompt(string prompt, string context="") {
  auto response = chatRequest(gameMasterIdentity, prompt, modelName, context);
  foreach (choice; response.choices)
    {
      writeln("\n" ~ choice.message.content);
    }
}
void gameMasterPrompt(string prompt, JSONValue context) {
  return gameMasterPrompt(prompt, context.toString());
}

bool pickUpItem(string itemName)
{
  foreach (i, item; worldState.map[userState.locationIndex].items)
    {
      if (item.name.toLower() == itemName)
        {
          // Add the item to the player's inventory
          userState.inventory ~= item;
          gameMasterPrompt("Inform the user they've placed the item in their pack.", toJSON(item).toString());            
          worldState.map[userState.locationIndex].items = worldState.map[userState.locationIndex].items.remove(i);
          return true;
        }
    }
  writeln("No '", itemName, "' in this location.");
  return false;
}

// Dummy function to start the text adventure game
bool playTextAdventureGame(string model)
{
  modelName = model;
  worldState = WorldState(false, "");
  userState = UserState(0, 100, 10, 20, []); // Initial health, defense, attack values
  gameMasterPrompt("The user is beginning the game described in the scenario, please welcome them to the game and be sure to ask their name.", "This is the game scenario: " ~ scenario);
  
  write("\n> ");
  worldState.playerName = readln().strip();
  worldState.isGameOver = false;
  
  worldState.map = parseJSON(locationsJSON).toLocations();
  Item[] items = parseJSON(itemsJSON).toItems();
  Creature[] creatures = parseJSON(creaturesJSON).toCreatures();
  // Randomly populate items and creatures in locations
  worldState.map.populate(items, creatures);
  
  writeln("\nHello, ", worldState.playerName, "! Let the adventure begin!");
  userState.locationIndex = 0;
  auto location = worldState.map[userState.locationIndex];
  gameMasterPrompt("The user starts at the location: " ~ location.name ~
                   ". Imaginatively but succinctly describe it to them, including" ~
                   " listing the exits and any items in the room. If there is a creature" ~
                   " in the room describe it with urgency, otherwise say there is nobody" ~
                   " else there.", toJSON(location).toString());
  return true;
}

bool handleGameInput(string userInput) {
  const UserAction action = parseUserAction(userInput);
  switch (action.command) {
  case GameCommand.Quit:
    writeln("Goodbye, ", worldState.playerName, "!");
    worldState.isGameOver = true;
    return false;
    
  case GameCommand.GoTo:
    moveToLocation(action.location);
    return true;
    
  case GameCommand.Look:
    displayLocation();
    displayStatus();
    return true;
    
  case GameCommand.PickUp:
    pickUpItem(action.item);
    return true;
  case GameCommand.Attack:
    attackCreature(action.creature, action.item);
    return true;
  default:
    writeln("I don't understand that.");
    return true;
  }
}

void attackCreature(string creature, string item = "") {
  //FIXME
  auto creatureJSON = toJSON(worldState.map[userState.locationIndex].creatures);
  auto locationJSON = toJSON(worldState.map[userState.locationIndex]);
  worldState.map[userState.locationIndex].creatures = [];
  if ( item == "" )
    {
      gameMasterPrompt("Dramatically inform the user they've slain the " ~ creature ~ "!",
                       "Creature:\n" ~ creatureJSON.toString() ~ "\n\n" ~ "Location:\n" ~ locationJSON.toString());
    }
  else {
    gameMasterPrompt("Dramatically inform the user they've slain the " ~ creature ~ " using their trusty " ~ item ~ "!",
                     "Creature:\n" ~ creatureJSON.toString() ~ "\n\n" ~ "Location:\n" ~ locationJSON.toString());
  }
  // Actual attack logic TBD
}

void moveToLocation(string destination)
{
  // Find the index of the destination location
  int destinationIndex = -1;
  foreach (i, location; worldState.map)
    {
      if (location.name.toLower() == destination)
        {
          destinationIndex = cast(int)i;
          break;
        }
    }
  
  // Check if the destination exists and is reachable from the current location
  if (destinationIndex != -1 && worldState.map[destinationIndex].exits.find(destination))
    {
      // Move to the new location
      userState.locationIndex = destinationIndex; 
      gameMasterPrompt("The user has travelled to the location: " ~ worldState.map[destinationIndex].name ~
                       ". Imaginatively but succinctly describe it to them, including listing the exits and any items in the room. You may describe decorative items, but do not describe items not included in the items array as interactive. If there is a creature in the room describe it with urgency, otherwise say there is nobody else there.", toJSON(worldState.map[destinationIndex]).toString());        
    }
  else
    {
      writeln("Cannot go to '", destination, "'.");
    }  
}
