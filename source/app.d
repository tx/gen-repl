import std.net.curl, std.stdio, std.json, std.process, std.string, std.getopt, std.algorithm;


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

// Define a struct to represent the Chat Completion response
struct ChatCompletion {
    string id;
    string object;
    int created;
    string model;
    Choice[] choices;
    Usage usage;
}

// Define structs for nested objects
struct Choice {
    int index;
    Message message;
    string finish_reason;
}

struct Message {
    string role;
    string content;
}

struct Usage {
    int prompt_tokens;
    int completion_tokens;
    int total_tokens;
}

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

// Function to manually parse JSON and populate the struct
void parseJSONToChatCompletion(JSONValue value, ref ChatCompletion chatCompletion) {
    chatCompletion.id = value["id"].get!string;
    chatCompletion.object = value["object"].get!string;
    chatCompletion.created = value["created"].get!int;
    chatCompletion.model = value["model"].get!string;

    // Parse choices array
    foreach (elem; value["choices"].array) {
        Choice choice;
        choice.index = elem["index"].get!int;
        choice.finish_reason = elem["finish_reason"].get!string;

        // Parse message object
        Message message;
        message.role = elem["message"]["role"].get!string;
        message.content = elem["message"]["content"].get!string;
        choice.message = message;

        chatCompletion.choices ~= choice;
    }

    // Parse usage object
    Usage usage;
    usage.prompt_tokens = value["usage"]["prompt_tokens"].get!int;
    usage.completion_tokens = value["usage"]["completion_tokens"].get!int;
    usage.total_tokens = value["usage"]["total_tokens"].get!int;
    chatCompletion.usage = usage;
}

// Function to prompt the user for input
string promptUser(const string prompt)
{
    writeln(prompt);
    return readln().strip();  // Read user input and remove leading/trailing whitespace
}

void openaiRequest(string providedIdentity, string userMessage, string modelName, string assistantContext = "")
{
    // Retrieve the API key from the environment variable
    string openaiApiKey = std.process.environment["OPENAI_API_KEY"];

    // API endpoint URL
    string apiUrl = "https://api.openai.com/v1/chat/completions";

    auto http = HTTP();

    // Request headers
    http.addRequestHeader("Content-Type", "application/json");
    http.addRequestHeader("Authorization", " Bearer " ~ openaiApiKey);

    // Convert the D associative array to a JSONValue
    auto requestBodyData = JSONValue(["model": modelName]);

    // Add Messages
    auto messages = [["role": "system", "content": providedIdentity],
                     ["role": "user", "content": userMessage]];
    requestBodyData["messages"] = JSONValue(messages);

    // Add assistant context if present
    if (!assistantContext.empty())
    {
      requestBodyData["messages"] ~= JSONValue(["role": "assistant", "content": assistantContext]);
    }

    // Convert the JSONValue to a string
    string requestBody = requestBodyData.toJSON();

    // Perform the HTTP POST request
    try
    {
        auto response = post(apiUrl, requestBody, http);
        auto jsonValue = parseJSON(response);
        // Parse the JSON response into ChatCompletion struct
        ChatCompletion chatCompletion;
        parseJSONToChatCompletion(jsonValue, chatCompletion);

        // Access the desired fields from the struct
        foreach (choice; chatCompletion.choices) {
            writeln("Response:\n", choice.message.content);
        }
    }
    catch (HTTPStatusException e)
    {
        // Handle the case where the request was not successful
        writeln("Error: HTTP ", e.status, "\n", e.msg);
    }
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
    openaiRequest(providedIdentity, "Please introduce yourself.", modelName, assistantContext);

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
                openaiRequest(providedIdentity, "Please introduce yourself.", modelName, assistantContext);
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
            openaiRequest(providedIdentity, userInput, modelName, assistantContext);
        }
    }

    writeln("Exiting program. Goodbye!");
}
