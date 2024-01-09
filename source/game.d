module gen_repl.game;

import std.algorithm;
import std.stdio;
import std.string;
import std.getopt;

import gen_repl.chat;  // Import the chat module

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
}

// Update the gameWorld with items
Location[] gameWorld = [
    Location("Forest", "A dense forest with tall trees.", ["Cave", "River"], [Item("Magic Wand", "A powerful wand.", 0)]),
    Location("Cave", "A dark cave with mysterious echoes.", ["Forest"], [Item("Health Potion", "Restores health.", 1)]),
    Location("River", "A gentle river flowing through the landscape.", ["Forest"], [Item("Map", "A detailed map of the area.", 2)])
];

// Add functions to handle items
void displayItems()
{
    writeln("Items in the current location:");
    foreach (item; gameWorld[currentLocationIndex].items)
    {
        writeln("\t", item.name, " - ", item.description);
    }
}

bool pickUpItem(string itemName)
{
    foreach (i, item; gameWorld[currentLocationIndex].items)
    {
        if (item.name.toLower() == itemName)
        {
            // Add the item to the player's inventory
            writeln("Picked up ", item.name, ".");
            // Optionally, you can remove the item from the location
            gameWorld[currentLocationIndex].items = gameWorld[currentLocationIndex].items.remove(i);
            return true;
        }
    }
    writeln("Cannot find '", itemName, "' in this location.");
    return false;
}

// Current location index
int currentLocationIndex = 0;


// Define a function to start the text adventure game
bool startTextAdventureGame()
{
  currentLocationIndex = 0;
  displayLocation();
  return true;
}

void displayLocation()
{
  writeln("You are in " ~ gameWorld[currentLocationIndex].description);
}

bool handleGameInput(string userInput)
{
    // Convert the input to lowercase for case-insensitive matching
    userInput = userInput.toLower();

    // Handle game-specific commands
    if (userInput == "quit" || userInput == "exit")
    {
      writeln("Goodbye!");
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
        writeln("Available exits: \n\t", gameWorld[currentLocationIndex].exits.join(", "));
        // Display items in the location
        displayItems();
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
    if (destinationIndex != -1 && gameWorld[currentLocationIndex].exits.find(destination))
    {
        // Move to the new location
        currentLocationIndex = destinationIndex;
        writeln("Moved to ", gameWorld[currentLocationIndex].name);
    }
    else
    {
        writeln("Cannot go to '", destination, "'.");
    }
}
