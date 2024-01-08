module gen_repl.game;

import std.algorithm;
import std.stdio;
import std.string;
import std.getopt;

import gen_repl.chat;  // Import the chat module

// Define some dummy game data
struct Location {
    string name;
    string description;
    string[] exits;
}

Location[] gameWorld = [
    Location("Forest", "A dense forest with tall trees.", ["Cave", "River"]),
    Location("Cave", "A dark cave with mysterious echoes.", ["Forest"]),
    Location("River", "A gentle river flowing through the landscape.", ["Forest"])
];

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
    if (userInput == "look" || userInput == "examine")
    {
        // Display current location description
        writeln("Current Location: \n\t", gameWorld[currentLocationIndex].name);
        // List available exits
        writeln("Available exits: \n\t", gameWorld[currentLocationIndex].exits.join(", "));
        return true;
    }
    else if (userInput == "quit" || userInput == "exit")
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
