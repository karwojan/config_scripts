import os

try:
    import requests
except ModuleNotFoundError:
    # just do nothing
    pass

import vim

SYSTEMS = {
    "python": """\
You are a helpful assitant for python software developers. You speak with python code
only, do not use any marks, like "```python", just code. Use python 3.10. Remember about
type hints for function arguments and returned values. When you are asked to change, fix
or refactor a piece of code, keep the formatting as given, especially indentations."""
}

def _prompt(system: str, instruction: str, data: str | None = None) -> str:
    if data is not None:
        instruction += ":\n"
        instruction += data
    response = requests.post(
        url="https://api.openai.com/v1/chat/completions",
        headers={"Authorization": f"Bearer {os.environ['OPENAI_API_TOKEN']}"},
        json={
            "model": "gpt-3.5-turbo-1106",
            "messages": [
                {
                    "role": "system",
                    "content": f"{SYSTEMS[system]}",
                },
                {
                    "role": "user",
                    "content": f"{instruction}",
                },
            ]
        }
    )
    response.raise_for_status()
    return response.json()["choices"][0]["message"]["content"]

def _getpos(expr: str):
    _, start_row, start_col, _ = vim.eval(f"getpos(\"{expr}\")")
    return int(start_row) - 1, int(start_col) - 1

def prompt(system: str, instruction: str, is_selected: bool, replace: bool) -> None:
    window = vim.current.window
    buffer = window.buffer

    if is_selected:
        start_row, start_col = _getpos("'<")
        end_row, end_col = _getpos("'>")
        data = buffer[start_row:end_row + 1]
        data[-1] = data[-1][:end_col+1]
        data[0] = data[0][start_col:]
        data = "\n".join(data)

        response = _prompt(system, instruction, data)

        if replace:
            output = buffer[start_row][:start_col]
            output += response
            output += buffer[end_row][end_col+1:]
            buffer[start_row:end_row + 1] = output.split("\n")
        else:
            buffer.append(response.split("\n"), window.cursor[0])
    else:
        response = _prompt(system, instruction)
        buffer.append(response.split("\n"), window.cursor[0])
