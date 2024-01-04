import std.net.curl, std.stdio, std.json, std.process, std.string, std.getopt;

string promptSystemContent()
{
    writeln("\nEnter the system message:");
    return readln().strip();  // Read user input and remove leading/trailing whitespace
}

void openaiRequest(string systemMessage, string userMessage, string modelName)
{
    // Retrieve the API key from the environment variable
    string openaiApiKey = std.process.environment["OPENAI_API_KEY"];

    // API endpoint URL
    string apiUrl = "https://api.openai.com/v1/chat/completions";

    auto http = HTTP();

    // Request headers
    http.addRequestHeader("Content-Type", "application/json");
    http.addRequestHeader("Authorization", " Bearer " ~ openaiApiKey);

    // Request body in JSON format with system and user messages
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
                    "content": "Please introduce yourself."
                },
                {
                    "role": "user",
                    "content": "%s"
                }
            ]
        }
    `, modelName, systemMessage, userMessage);

    // Perform the HTTP POST request
    try
    {
        auto response = post(apiUrl, requestBody, http);

        // Check if the request was successful (HTTP status code 2xx)
        if (http.statusLine.code >= 200 && http.statusLine.code < 300)
        {
            // Parse the JSON response
            auto json = parseJSON(response);

            // Access the desired fields from the JSON response
            foreach (choice; json["choices"].array) {
                writeln("Response:\n", choice["message"].object["content"].str);
            }
        }
        else
        {
            // Handle the case where the request was not successful
            writeln("Error: HTTP ", http.statusLine.code, "\n", response);
        }
    }
    catch (HTTPStatusException e)
    {
        // Handle the exception (e.g., print the status code)
        writeln("HTTPStatusException: ", e.status);
    }
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

    // Prompt the user for the system message
    string systemMessage = promptSystemContent();

    // Automatically issue a request with a default userMessage
    openaiRequest(systemMessage, "Please introduce yourself.", modelName);

    // Enter the REPL loop for user messages
    while (true)
    {
        // Prompt the user for input
        writeln("\nEnter your message (or type 'exit' to quit):");
        string userMessage = readln().strip();  // Read user input and remove leading/trailing whitespace

        // Check if the user wants to exit the REPL
        if (userMessage == "exit")
            break;

        // Perform the OpenAI request with the system and user messages
        openaiRequest(systemMessage, userMessage, modelName);
    }
}
