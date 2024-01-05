import std.net.curl, std.stdio, std.json, std.process, std.string, std.getopt;

// Constants for user prompts
const string PROMPT_IDENTITY = "\nWho am I?";
const string PROMPT_CONTEXT = "\nEnter assistant context (leave blank if none):";
const string PROMPT_COMMAND = "\nEnter your command or message (type ':help' for available commands):";

// Constants for commands
const string COMMAND_QUIT = ":quit";
const string COMMAND_HELP = ":help";
const string COMMAND_IDENTITY = ":identity";
const string COMMAND_CONTEXT = ":context";

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

string promptProvidedIdentity()
{
    writeln(PROMPT_IDENTITY);
    return readln().strip();  // Read user input and remove leading/trailing whitespace
}

string promptAssistantContext()
{
    writeln(PROMPT_CONTEXT);
    return readln().strip();  // Read user input and remove leading/trailing whitespace
}
string toJSONString(string s)
{
  return '"' ~ s.replace('"',"\\\"") ~ '"';
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

    // Request body in JSON format with providedIdentity, user message, and assistant context if present
    string requestBody;

    if (assistantContext.length > 0)
    {
        auto escapedIdentity = providedIdentity.toJSONString();
        auto escapedUserMessage = userMessage.toJSONString();
        auto escapedAssistantContext = assistantContext.toJSONString();
        auto escapedModelName = modelName.toJSONString();

        requestBody = format(`
            {
                "model": %s,
                "messages": [
                    {
                        "role": "system",
                        "content": %s
                    },
                    {
                        "role": "user",
                        "content": %s
                    },
                    {
                        "role": "assistant",
                        "content": %s
                    }
                ]
            }
        `, escapedModelName, escapedIdentity, escapedUserMessage, escapedAssistantContext);
    }
    else
    {
        auto escapedIdentity = providedIdentity.toJSONString();
        auto escapedUserMessage = userMessage.toJSONString();
        auto escapedModelName = modelName.toJSONString();

        requestBody = format(`
            {
                "model": %s,
                "messages": [
                    {
                        "role": "system",
                        "content": %s
                    },
                    {
                        "role": "user",
                        "content": %s
                    }
                ]
            }
        `, escapedModelName, escapedIdentity, escapedUserMessage);
    }

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

    // Assistant context
    string assistantContext;

    // Automatically issue a request with a default userMessage
    openaiRequest(providedIdentity, "Please introduce yourself.", modelName, assistantContext);

    // Enter the REPL loop for user commands and messages
    while (true)
    {
        // Prompt the user for input
        writeln(PROMPT_COMMAND);
        string userInput = readln().strip();  // Read user input and remove leading/trailing whitespace

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
                providedIdentity = promptProvidedIdentity();
                // Automatically issue a request with a default userMessage
                openaiRequest(providedIdentity, "Please introduce yourself.", modelName, assistantContext);
            }
            else if (userInput == COMMAND_CONTEXT)
            {
                // Prompt the user for assistant context
                writeln(PROMPT_CONTEXT);
                assistantContext = readln().strip();
                writeln("\nAssistant context updated successfully.");
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
