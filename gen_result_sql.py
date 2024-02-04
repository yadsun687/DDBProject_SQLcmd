import os

def concatenate_sql_files(directory, output_file):
    with open(output_file, 'a') as output:
        for root, _, files in os.walk(directory):
            for file in files:
                if file.endswith(".sql"):
                    file_path = os.path.join(root, file)
                    with open(file_path, 'r') as input_file:
                        output.write(input_file.read())
                        output.write('\n\n')  # Add a separator between files

if __name__ == "__main__":
    output_file_path = "result_sql.sql"
    
    os.remove(output_file_path) if os.path.exists(output_file_path) else None

    # Concatenate SQL files in the specified directories
    concatenate_sql_files("./functions", output_file_path)
    concatenate_sql_files("./procedures", output_file_path)
    concatenate_sql_files("./views", output_file_path)
    
    print(f"All SQL files have been concatenated into {output_file_path}.")
