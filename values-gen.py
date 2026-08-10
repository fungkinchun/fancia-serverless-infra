import json
import yaml
import os
import argparse
from pathlib import Path

def snake_to_camel(s: str) -> str:
    parts = s.split('_')
    return (
        parts[0].lower() + ''.join(p.capitalize() for p in parts[1:])
        if parts
        else s
    )

def camel_to_snake(s: str) -> str:
    result = []
    for char in s:
        if char.isupper() and result:
            result.append('_')
        result.append(char.lower())
    return ''.join(result)

def upper_snake_to_camel(s: str) -> str:
    parts = s.split('_')
    return ''.join(p.capitalize() for p in parts) if parts else s

def camel_to_upper_snake(s: str) -> str:
    result = []
    for char in s:
        if char.isupper() and result:
            result.append('_')
        result.append(char.upper())
    return ''.join(result)

def load_tf_outputs(path: Path):
    try:
        with open(path, 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"Error: Terraform outputs file not found at {path}")
        exit(1)
    except json.JSONDecodeError:
        print(f"Error: could not decode JSON from {path}")
        exit(1)

def get_desired_key(key: str, out_case: str) -> str:
    if out_case == 'camel':
        return snake_to_camel(key)
    elif out_case == 'snake':
        return camel_to_snake(key)
    elif out_case == 'upper_snake':
        return camel_to_upper_snake(key)
    return key

def main():
    parser = argparse.ArgumentParser(
        description='Generate Helm values from Terraform outputs (tf_outputs.json).'
    )
    parser.add_argument(
        '--var-file', type=Path, default=Path('tf_outputs.json'),
        help='Path to tf_outputs.json'
    )
    parser.add_argument(
        '--out-dir', type=Path, default=Path('.'),
        help='Path to output values.json and values.yaml (default: current directory)'
    )
    parser.add_argument(
        '--out-file', type=str, default='values', help='Base name for output files (default: values)'
    )
    parser.add_argument(
        '--out-case', choices=['camel', 'snake', 'upper_snake'], default='camel', help='Output case style for generated values (default: camel)'
    )
    args = parser.parse_args()

    input_path = Path(args.var_file)
    out_path = Path(args.out_dir)

    if input_path.is_file():
        tf_path = input_path
    else:
        print(f"Error: provided path does not exist: {input_path}")
        exit(1)

    tf_outputs = load_tf_outputs(tf_path)
    out_path.mkdir(parents=True, exist_ok=True)

    values = {}
    environment = os.environ.get('ENVIRONMENT')
    if not environment:
        print("Error: ENVIRONMENT variable is not set.")
        exit(1)
    try:
        tf_outputs = tf_outputs[environment]['value']
    except KeyError:
        print(f"Error: No Terraform outputs found for environment: {environment}")
        exit(1)

    values[get_desired_key('environment', args.out_case)] = environment
    keys_to_extract = ['projectName', 'awsAccountId', 'awsRegion', 'domainName', 'email', 'vpcId', 'acmCertificateArn', 'privateHostedZoneId', 'publicHostedZoneId', 'subnetIds']
    for key in keys_to_extract:
        upper_snake_key = camel_to_upper_snake(key)
        try:
            values[get_desired_key(key, args.out_case)] = os.environ[upper_snake_key]
        except KeyError:
            try:
                snake_key = camel_to_snake(key)
                values[get_desired_key(key, args.out_case)] = tf_outputs[snake_key]
            except Exception:
                if key == 'environment':
                    print(
                        f"Error: {upper_snake_key} not found in environment variables or tf_outputs. 'environment' is required to map other values."
                    )
                    exit(1)
                print(
                    f"Warning: {upper_snake_key} not found in environment variables or tf_outputs."
                )

    values[get_desired_key("repositories", args.out_case)] = []
    rds_name_map_key = f"rds_secret_name_map"
    if (
        rds_name_map_key in tf_outputs
        and isinstance(tf_outputs[rds_name_map_key], dict)
    ):
        for idx, (k, v) in enumerate(tf_outputs[rds_name_map_key].items()):
            values[get_desired_key("repositories", args.out_case)].append({
                get_desired_key("name", args.out_case): k,
                get_desired_key("databaseName", args.out_case): v["databaseName"],
                get_desired_key("databaseSecretName", args.out_case): v["databaseSecretName"],
                get_desired_key("port", args.out_case): 8080 + idx,
                get_desired_key("imageVersion", args.out_case): "latest",
                get_desired_key("isCron", args.out_case): v.get("isCron", False),
            })
    else:
        print(f"Warning: {rds_name_map_key} not found or not a map in tf_outputs.")

    values[get_desired_key("secrets", args.out_case)] = []
    credentials_name_map_key = f"credentials_name_map"
    if (
        credentials_name_map_key in tf_outputs
        and isinstance(tf_outputs[credentials_name_map_key], dict)
    ):
        for secret in tf_outputs[credentials_name_map_key].keys():
            values[get_desired_key("secrets", args.out_case)].append({
                get_desired_key("name", args.out_case): secret,
                get_desired_key("secretName", args.out_case): tf_outputs[credentials_name_map_key][secret]["secretName"],
                get_desired_key("namespace", args.out_case): tf_outputs[credentials_name_map_key][secret]["namespace"],
            })
    else:
        print(f"Warning: {credentials_name_map_key} not found or not a map in tf_outputs.")

    json_output = json.dumps(values, indent=2)
    json_path = out_path / f'{args.out_file}.json'
    with open(json_path, 'w') as f:
        f.write(json_output)
    print(f"values.json generated successfully at {json_path}.")

    yaml_output = yaml.dump(values, default_flow_style=False)
    yaml_path = out_path / f'{args.out_file}.yaml'
    with open(yaml_path, 'w') as f:
        f.write(yaml_output)
    print(f"values.yaml generated successfully at {yaml_path}.")

if __name__ == '__main__':
    main()