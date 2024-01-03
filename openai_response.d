import std.stdio;
import std.net.curl;
import std.json;

string promptSystemContent()
{
    writeln("\nEnter the system message:");
    return readln().strip();  // Read user input and remove leading/trailing whitespace
}

void openaiRequest(string systemMessage, string userMessage)
{
    // Retrieve the API key from the environment variable
    string openaiApiKey = std.process.environment["OPENAI_API_KEY"];

    // API endpoint URL
    string apiUrl = "https://api.openai.com/v1/chat/completions";

    // Request headers
    string[] headers = [
        "Content-Type: application/json",
        "Authorization: Bearer " ~ openaiApiKey
    ];

    // Request body in JSON format with user's message
    string requestBody = format(`
        {
            "model": "gpt-3.5-turbo",
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
    `, systemMessage, userMessage);

    // Perform the HTTP POST request
    auto response = curl.post(apiUrl, requestBody, headers);

    // Check if the request was successful (HTTP status code 2xx)
    if (response.statusCode >= 200 && response.statusCode < 300)
    {
        // Parse the JSON response
        Json json = response.bodyReader.jsonObject();

        // Access the desired fields from the JSON response
        writeln("Response:\n", json);
    }
    else
    {
        // Handle the case where the request was not successful
        writeln("Error: HTTP ", response.statusCode, "\n", response.bodyReader.readAll());
    }
}

void main()
{
    writeln("OpenAI Request REPL");
    writeln("-------------------");

    // Prompt the user for the system message
    string systemMessage = promptSystemContent();

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
        openaiRequest(systemMessage, userMessage);
    }
}
