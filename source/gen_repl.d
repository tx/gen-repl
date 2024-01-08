module gen_repl.main;

static import std.process;
import std.algorithm;
import std.stdio;
import std.string;
import std.getopt;

import gen_repl.chat;  // Import the chat module

// Constants for user prompts
const string PROMPT_IDENTITY = "\nWho am I?";
const string PROMPT_CONTEXT = "\nEnter assistant context (leave blank if none):";
const string PROMPT_COMMAND = "\nEnter your command or message (type ':help' for available commands):";

// Constants for commands
const string COMMAND_QUIT = ":quit";
const string COMMAND_HELP = ":help";
const string COMMAND_IDENTITY = ":identity";
const string COMMAND_CONTEXT = ":context";
const string COMMAND_GAME = ":game";

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

// Function to prompt the user for input
string promptUser(const string prompt)
{
    writeln(prompt);
    return readln().strip();  // Read user input and remove leading/trailing whitespace
}

void printHelp()
{
    // Hard-coded strings for help command
    writeln("\nAvailable Commands:");
    writeln(COMMAND_QUIT, "         - Quit the program");
    writeln(COMMAND_HELP, "         - Display available commands");
    writeln(COMMAND_IDENTITY, "     - Change the provided identity");
    writeln(COMMAND_CONTEXT, "      - Set assistant context");
    writeln(COMMAND_GAME, "         - Play a game");
}

void main(string[] args)
{
    // Command line options
    string modelName = "gpt-3.5-turbo";

    getopt(args, "m|model", &modelName);

    // Check if OPENAI_API_KEY is set
    if (std.process.environment.get("OPENAI_API_KEY") is null)
    {
        writeln("Error: OPENAI_API_KEY environment variable is not set.");
        return;
    }

    writeln("OpenAI Request REPL");
    writeln("-------------------");

    // Prompt the user for the initial providedIdentity
    string providedIdentity = promptUser(PROMPT_IDENTITY);

    // Assistant context
    string assistantContext;

    // Automatically issue a request with a default userMessage
    chatRequest(providedIdentity, "Please introduce yourself.", modelName, assistantContext);

    // Enter the REPL loop for user commands and messages
    while (true)
    {
        // Prompt the user for input
        string userInput = promptUser(PROMPT_COMMAND);

        // Process user commands
        if (userInput.length > 0 && userInput[0] == ':')
        {
            if (userInput == COMMAND_QUIT)
            {
                break; // Exit the REPL loop
            }
            else if (userInput == COMMAND_HELP)
            {
                printHelp(); // Display available commands
            }
            else if (userInput == COMMAND_IDENTITY)
            {
                // Prompt the user for a new providedIdentity
                providedIdentity = promptUser(PROMPT_IDENTITY);
                // Automatically issue a request with a default userMessage
                chatRequest(providedIdentity, "Please introduce yourself.", modelName, assistantContext);
            }
            else if (userInput == COMMAND_CONTEXT)
            {
                // Prompt the user for assistant context
                assistantContext = promptUser(PROMPT_CONTEXT);
                writeln("\nAssistant context updated successfully.");
            }
            else if (userInput == COMMAND_GAME)
              {
                auto inProgress = startTextAdventureGame();
                while (inProgress)
                  {
                    displayLocation();
                    string gameInput = promptUser("Enter your command:");
                    inProgress = handleGameInput(gameInput);
                  }
                // Display game outcome and return to the main REPL loop
              }
            else
            {
                writeln("Error: Unknown command. Type '", COMMAND_HELP, "' for available commands.");
            }
        }
        else
        {
            // Assume other input is a user message
            // Perform the OpenAI request with the providedIdentity, user message, and assistant context
            ChatResponse chatResponse = chatRequest(providedIdentity, userInput, modelName, assistantContext);

            // Access the desired fields from the struct and write to the terminal
            foreach (choice; chatResponse.choices)
            {
                writeln("Response:\n", choice.message.content);
            }
        }
    }

    writeln("Exiting program. Goodbye!");
}
