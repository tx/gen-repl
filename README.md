# Gen-REPL

Gen-REPL is a GPT (Generative Pre-trained Transformer) based REPL (Read-Eval-Print Loop) application that interacts with the OpenAI API.

## Description

This project utilizes the GPT model to create an interactive REPL, allowing users to engage in conversations with the GPT model through the OpenAI API.

### Generated Code Acknowledgment
The code for this project was generated by ChatGPT with guidance, testing, and fixes provided by the user.

Explore the detailed development and interaction history of this project by following [this conversation link](https://chat.openai.com/share/8bdebe9d-932f-415e-8e2b-7b471603e56c).

## Build Instructions

Before building and running the project, ensure you have [DUB](https://code.dlang.org/download) (D package manager) installed.

### Build Steps

1. Clone the repository:

   ```bash
   git clone https://github.com/your-username/gen-repl.git
   ```

2. Navigate to the project directory:

   ```bash
   cd gen-repl
   ```

3. Build the project using DUB:

   ```bash
   dub build
   ```

### Running the Application

Once the build is successful, you can run the application:

```bash
./gen-repl [-m=<model-name>]
```

#### Command-Line Parameters

- `-m` or `--model`: Specify the GPT model name (default is "gpt-3.5-turbo").

## Configuration

Ensure that you have set the `OPENAI_API_KEY` environment variable with your OpenAI API key before running the application.

## Commands

- `:quit`: Exit the program.
- `:help`: Display available commands.
- `:identity`: Change the provided identity.
- `:context`: Set assistant context.

## Example Usage

1. Run the application:

   ```bash
   ./gen-repl
   ```

2. Follow the prompts to set your identity:

   ```
   Who am I?
   You are snoop dogg.
   ```

3. Engage in a conversation:

   ```
   Enter your command or message (type ':help' for available commands):
   Succinctly explain linear regression in 16 bars.
   ```

   ```
   Response:
   Linear regression, baby, let me break it down
   Predictin' outcomes, no need to clown
   It's a statistical technique that's so slick
   Fittin' a line to data, real quick

   Y equals MX plus B, that's the game
   M is the slope, B is the intercept, it's not lame
   We analyze the relationship, smooth and tight
   Predictin' future values, day and night

   Least squares method is what we use
   Minimizing errors, with no excuse
   Findin' the best fit line, you see
   Straight line, no curves, it's plain to see

   R-squared tells us how close we be
   To the data points, accuracy, you'll agree
   Linear regression, it's the OG
   Predictin' like a boss, that's the key
   ```

4. Use commands like `:quit` to exit the program.

*README generated by ChatGPT.*
