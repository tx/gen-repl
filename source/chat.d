/**
 * Module: gen_repl.chat
 *
 * This module contains functions and structs related to interacting with the OpenAI Chat API.
 */
module gen_repl.chat;

static import std.process;
import std.net.curl;
import std.stdio;
import std.string;
import std.json;

// Define a struct to represent the Chat Response
struct ChatResponse {
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

/**
 * Function: toChatResponse
 *
 * Manually parses JSON and populates the ChatResponse struct.
 *
 * Params:
 *   - value: JSONValue - The JSON data to be parsed.
 *
 * Returns:
 *   The populated ChatResponse struct.
 */
ChatResponse toChatResponse(JSONValue value) {
    ChatResponse chatResponse;
    chatResponse.id = value["id"].get!string;
    chatResponse.object = value["object"].get!string;
    chatResponse.created = value["created"].get!int;
    chatResponse.model = value["model"].get!string;

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

        chatResponse.choices ~= choice;
    }

    // Parse usage object
    Usage usage;
    usage.prompt_tokens = value["usage"]["prompt_tokens"].get!int;
    usage.completion_tokens = value["usage"]["completion_tokens"].get!int;
    usage.total_tokens = value["usage"]["total_tokens"].get!int;
    chatResponse.usage = usage;
    return chatResponse;
}

/**
 * Function: chatRequest
 *
 * Performs an OpenAI request and returns a ChatResponse.
 *
 * Params:
 *   - providedIdentity: string - The provided identity for the chat.
 *   - userMessage: string - The user's message.
 *   - modelName: string - The GPT model name.
 *   - assistantContext: string - The assistant's context (optional).
 *
 * Returns:
 *   The ChatResponse from the OpenAI API.
 */
ChatResponse chatRequest(string providedIdentity, string userMessage, string modelName, string assistantContext = "")
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
        // Parse the JSON response into ChatResponse struct
        ChatResponse chatResponse = jsonValue.toChatResponse();

        // Return the ChatResponse object directly
        return chatResponse;
    }
    catch (HTTPStatusException e)
    {
        // Handle the case where the request was not successful
        writeln("Error: HTTP ", e.status, "\n", e.msg);
    }

    // Return an empty ChatResponse object in case of an error
    return ChatResponse.init;
}
