# Gen-REPL

Gen-REPL is a GPT (Generative Pre-trained Transformer) based REPL (Read-Eval-Print Loop) application that interacts with the OpenAI API.

## Description

This project utilizes the GPT model to create an interactive REPL, allowing users to engage in conversations with the GPT model through the OpenAI API.

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

## Author

- Morgan Lowtech

## License

This project is licensed under the BSD-1-Clause License - see the [LICENSE](LICENSE) file for details.

---

*README generated by ChatGPT.*
