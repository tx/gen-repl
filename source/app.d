/**
 * Module: gen_repl.main
 *
 * This module contains the main functionality for the OpenAI Request REPL application.
 */
module gen_repl.main;

static import std.process;
import std.stdio;
import std.string;
import std.getopt;

import gen_repl.chat;  // Import the chat module
import gen_repl.game;  // Import the game module

// Constants for GPT prompts
const string GPT_PROMPT_INTRO = "Please introduce yourself.";


// Constants for user prompts
const string USER_PROMPT_IDENTITY = "\nWho am I?\n> ";
const string USER_PROMPT_INITIAL = "\nWhat would you like to do?\n> ";
const string USER_PROMPT_CONTEXT = "\nEnter assistant context (leave blank if none)>\n";
const string USER_PROMPT_COMMAND = "\n> ";

// Constants for commands
const string COMMAND_QUIT = ":quit";
const string COMMAND_HELP = ":help";
const string COMMAND_IDENTITY = ":identity";
const string COMMAND_CONTEXT = ":context";
const string COMMAND_GAME = ":game";

/**
 * Function: promptUser
 *
 * Prompts the user for input and returns the stripped input.
 *
 * Params:
 *   - prompt: const string - The prompt message.
 *
 * Returns:
 *   The user input after stripping leading/trailing whitespace.
 */
string promptUser(const string prompt)
{
  writeln(prompt);
  return readln().strip();  // Read user input and remove leading/trailing whitespace
}

/**
 * Function: printHelp
 *
 * Prints the available commands and their descriptions.
 */
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

void playGame(string modelName)
{
  auto inProgress = playTextAdventureGame(modelName);
  while (inProgress)
    {
      displayLocation();
      string gameInput = promptUser("> ");
      inProgress = handleGameInput(gameInput);
    }
}

void repl(string modelName)
{
  // Prompt the user for the initial providedIdentity
  string providedIdentity = promptUser(USER_PROMPT_IDENTITY);

      // Assistant context
      string assistantContext;

      // Automatically issue a request with a default userMessage
      chatRequest(providedIdentity, GPT_PROMPT_INTRO, modelName, assistantContext);

      // Enter the REPL loop for user commands and messages
      while (true)
        {
          // Prompt the user for input
          string userInput = promptUser(USER_PROMPT_COMMAND);

          // Process user commands
          if (userInput.length > 0 && userInput[0] == ':')
            {
              if (userInput == COMMAND_QUIT)
                {
                  writeln("Goodbye!");
                  break; // Exit the REPL loop
                }
              else if (userInput == COMMAND_HELP)
                {
                  printHelp(); // Display available commands
                }
              else if (userInput == COMMAND_IDENTITY)
                {
                  // Prompt the user for a new providedIdentity
                  providedIdentity = promptUser(USER_PROMPT_IDENTITY);
                  // Automatically issue a request with a default userMessage
                  chatRequest(providedIdentity, GPT_PROMPT_INTRO, modelName, assistantContext);
                }
              else if (userInput == COMMAND_CONTEXT)
                {
                  // Prompt the user for assistant context
                  assistantContext = promptUser(USER_PROMPT_CONTEXT);
                  writeln("\nAssistant context updated successfully.");
                }
              else if (userInput == COMMAND_GAME)
                {
                  playGame(modelName);
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
}

/**
 * Function: main
 *
 * The main entry point for the OpenAI Request REPL application.
 *
 * Params:
 *   - args: string[] - Command-line arguments.
 */
void main(string[] args)
{
    // Command line options
    string modelName = "gpt-3.5-turbo";
    bool showHelp = false;  // Flag to indicate whether to show help
    try {
      auto helpInformation = getopt(args, "model",  &modelName, "help", &showHelp);
      showHelp = showHelp || helpInformation.helpWanted;
    } catch (std.getopt.GetOptException goe)
      {
        writeln("Unknown option!");
        showHelp = true;
      }
    if (showHelp )
    {
        writeln("OpenAI Request REPL");
        writeln("-------------------");
        writeln("Usage: gen_repl [--model=<model_name>] [--help]");
        writeln("\nOptions:");
        writeln("  --model=<model_name>   Set the GPT model name (default: gpt-3.5-turbo)");
        writeln("  -h --help              Display this help message");
        return;
    }

    // Check if OPENAI_API_KEY is set
    if (std.process.environment.get("OPENAI_API_KEY") is null)
    {
        writeln("Error: OPENAI_API_KEY environment variable is not set.");
        return;
    }

    writeln("Gen-REPL");
    writeln("-------------------");
    writeln("Welcome! We can either chat or play a game.");
    if (promptUser(USER_PROMPT_INITIAL).toLower().indexOf("game") >= 0)
    {
      writeln("I'll start the game!");
      playGame(modelName);
    }
    else {
      writeln("Let's chat!");
      repl(modelName);
    }
}
