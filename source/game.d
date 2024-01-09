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

// Add the UserState struct
struct UserState {
    int locationIndex;
    Item[] inventory;  // Collection of items the player has picked up
}

// Add the WorldState struct
struct WorldState {
    bool isGameOver;
    string playerName;
}

// Initialize the world state
WorldState worldState = WorldState(false, "");

// Initialize the user state
UserState userState = UserState(0, []);

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

// Define a function to start the text adventure game
bool startTextAdventureGame()
{
    // Prompt the user for their name
    write("Welcome to the Text Adventure Game! What's your name? ");
    worldState.playerName = readln().strip();

    // Set initial game state
    worldState.isGameOver = false;
    userState.locationIndex = 0;

    // Display initial message
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
        // Display items in the location
        displayItems();
        // Display player's inventory
        displayInventory();
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
