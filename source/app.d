import std.net.curl, std.stdio, std.json, std.process, std.string, std.getopt;

string promptProvidedIdentity()
{
    writeln("\nWho am I?");
    return readln().strip();  // Read user input and remove leading/trailing whitespace
}

void openaiRequest(string providedIdentity, string userMessage, string modelName)
{
    // Retrieve the API key from the environment variable
    string openaiApiKey = std.process.environment["OPENAI_API_KEY"];

    // API endpoint URL
    string apiUrl = "https://api.openai.com/v1/chat/completions";

    auto http = HTTP();

    // Request headers
    http.addRequestHeader("Content-Type", "application/json");
    http.addRequestHeader("Authorization", " Bearer " ~ openaiApiKey);

    // Request body in JSON format with providedIdentity and user messages
    string requestBody = format(`
        {
            "model": "%s",
            "messages": [
                {
                    "role": "system",
                    "content": "%s"
                },
                {
                    "role": "user",
                    "content": "%s"
                }
            ]
        }
    `, modelName, providedIdentity, userMessage);

    // Perform the HTTP POST request
    try
    {
        auto response = post(apiUrl, requestBody, http);

        // Parse the JSON response
        auto json = parseJSON(response);

        // Access the desired fields from the JSON response
        foreach (choice; json["choices"].array) {
            writeln("Response:\n", choice["message"].object["content"].str);
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
    writeln("\nAvailable Commands:");
    writeln(":quit         - Quit the program");
    writeln(":help         - Display available commands");
    writeln(":identity     - Change the provided identity");
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
    string providedIdentity = promptProvidedIdentity();

    // Automatically issue a request with a default userMessage
    openaiRequest(providedIdentity, "Please introduce yourself.", modelName);

    // Enter the REPL loop for user commands and messages
    while (true)
    {
        // Prompt the user for input
        writeln("\nEnter your command or message (type ':help' for available commands):");
        string userInput = readln().strip();  // Read user input and remove leading/trailing whitespace

        // Process user commands
        if (userInput.length > 0 && userInput[0] == ':')
        {
            // Commands start with ':'
            string command = userInput[1..$];  // Exclude the leading ':'

            if (command == "quit")
            {
                break; // Exit the REPL loop
            }
            else if (command == "help")
            {
                printHelp(); // Display available commands
            }
            else if (command == "identity")
            {
                // Prompt the user for a new providedIdentity
                providedIdentity = promptProvidedIdentity();
                // Automatically issue a request with a default userMessage
                openaiRequest(providedIdentity, "Please introduce yourself.", modelName);
            }
            else
            {
                writeln("Error: Unknown command. Type ':help' for available commands.");
            }
        }
        else
        {
            // Assume other input is a user message
            // Perform the OpenAI request with the providedIdentity and user message
            openaiRequest(providedIdentity, userInput, modelName);
        }
    }
    
    writeln("Exiting program. Goodbye!");
}
