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


def camel_to_upper_snake(s: str) -> str:
    result = []
    for char in s:
        if char.isupper() and result:
            result.append('_')
        result.append(char.upper())
    return ''.join(result)


def load_json(path: Path, label: str):
    try:
        with open(path, 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"Error: {label} file not found at {path}")
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


def resolve_value(key: str, secret: dict, tf_outputs: dict):
    upper_snake_key = camel_to_upper_snake(key)
    snake_key = camel_to_snake(key)
    if upper_snake_key in os.environ:
        return os.environ[upper_snake_key]
    if snake_key in secret:
        return secret[snake_key]
    if key in secret:
        return secret[key]
    if snake_key in tf_outputs:
        return tf_outputs[snake_key]
    raise KeyError(key)


def build_repositories(secret: dict, tf_outputs: dict, out_case: str):
    rds_name_map = tf_outputs.get('rds_secret_name_map')
    if not isinstance(rds_name_map, dict):
        print('Warning: rds_secret_name_map not found or not a map in tf_outputs.')
        return []

    secret_repos = secret.get('repositories') or secret.get('Repositories') or []
    if not secret_repos:
        print('Warning: secret has no repositories list; is_cron/schedule cannot be applied.')
        return []

    # Re-running on already-generated tfvars loses secret fields like is_service.
    if all(
        ('database_secret_name' in r or 'databaseSecretName' in r) for r in secret_repos
    ) and not any(('is_service' in r or 'isService' in r) for r in secret_repos):
        print(
            'Warning: input looks like previously generated tfvars '
            '(database_secret_name present, is_service missing). '
            'Re-download Secrets Manager JSON before running values-gen.'
        )

    secret_by_name = {}
    for repo in secret_repos:
        name = repo.get('name') or repo.get('Name')
        if name:
            secret_by_name[name] = repo

    repositories = []
    for repo in secret_repos:
        name = repo.get('name') or repo.get('Name')
        if not name or name not in rds_name_map:
            continue

        rds = rds_name_map[name]
        if 'is_cron' in repo:
            is_cron = bool(repo['is_cron'])
        elif 'isCron' in repo:
            is_cron = bool(repo['isCron'])
        else:
            is_cron = False

        port = repo.get('port', repo.get('Port'))
        if port is None:
            port = 8080 + len(repositories)

        schedule = repo.get('schedule', repo.get('Schedule'))
        handler = repo.get('handler', repo.get('Handler'))

        entry = {
            get_desired_key('name', out_case): name,
            get_desired_key('databaseName', out_case): rds['databaseName'],
            get_desired_key('databaseSecretName', out_case): rds['databaseSecretName'],
            get_desired_key('port', out_case): port,
            get_desired_key('imageVersion', out_case): 'latest',
            get_desired_key('isCron', out_case): is_cron,
        }
        if schedule:
            entry[get_desired_key('schedule', out_case)] = schedule
        if handler:
            entry[get_desired_key('handler', out_case)] = handler

        print(f'repository {name}: is_cron={is_cron} schedule={schedule!r} port={port}')
        repositories.append(entry)

    for name, rds in rds_name_map.items():
        if name in secret_by_name:
            continue
        entry = {
            get_desired_key('name', out_case): name,
            get_desired_key('databaseName', out_case): rds['databaseName'],
            get_desired_key('databaseSecretName', out_case): rds['databaseSecretName'],
            get_desired_key('port', out_case): 8080 + len(repositories),
            get_desired_key('imageVersion', out_case): 'latest',
            get_desired_key('isCron', out_case): False,
        }
        print(f'repository {name}: not in secret repositories; is_cron=false')
        repositories.append(entry)

    return repositories


def main():
    parser = argparse.ArgumentParser(
        description='Generate Terraform tfvars by combining Secrets Manager JSON with Terraform outputs.'
    )
    parser.add_argument(
        '--var-file', type=Path, default=Path('tf_outputs.json'),
        help='Path to tf_outputs.json'
    )
    parser.add_argument(
        '--secret-file', type=Path, default=Path('terraform.tfvars.json'),
        help='Path to Secrets Manager JSON downloaded as terraform.tfvars.json'
    )
    parser.add_argument(
        '--out-dir', type=Path, default=Path('.'),
        help='Output directory'
    )
    parser.add_argument(
        '--out-file', type=str, default='values',
        help='Base name for output files'
    )
    parser.add_argument(
        '--out-case', choices=['camel', 'snake', 'upper_snake'], default='camel',
        help='Output case style'
    )
    args = parser.parse_args()

    if not args.var_file.is_file():
        print(f"Error: provided path does not exist: {args.var_file}")
        exit(1)
    if not args.secret_file.is_file():
        print(f"Error: secret file does not exist: {args.secret_file}")
        exit(1)

    tf_outputs_raw = load_json(args.var_file, 'Terraform outputs')
    secret = load_json(args.secret_file, 'Secret')
    args.out_dir.mkdir(parents=True, exist_ok=True)

    environment = os.environ.get('ENVIRONMENT') or secret.get('environment')
    if not environment:
        print("Error: ENVIRONMENT variable is not set and secret has no environment.")
        exit(1)
    try:
        tf_outputs = tf_outputs_raw[environment]['value']
    except KeyError:
        print(f"Error: No Terraform outputs found for environment: {environment}")
        exit(1)

    values = {
        get_desired_key('environment', args.out_case): environment,
    }

    keys_to_extract = [
        'projectName',
        'awsAccountId',
        'awsRegion',
        'domainName',
        'email',
        'vpcId',
        'acmCertificateArn',
        'privateHostedZoneId',
        'publicHostedZoneId',
        'subnetIds',
    ]
    for key in keys_to_extract:
        try:
            values[get_desired_key(key, args.out_case)] = resolve_value(key, secret, tf_outputs)
        except KeyError:
            print(
                f"Warning: {camel_to_upper_snake(key)} not found in environment, secret, or tf_outputs."
            )

    values[get_desired_key('repositories', args.out_case)] = build_repositories(
        secret, tf_outputs, args.out_case
    )

    secrets_list = []
    credentials_name_map = tf_outputs.get('credentials_name_map')
    if isinstance(credentials_name_map, dict):
        for secret_name, cred in credentials_name_map.items():
            secrets_list.append({
                get_desired_key('name', args.out_case): secret_name,
                get_desired_key('secretName', args.out_case): cred['secretName'],
                get_desired_key('namespace', args.out_case): cred['namespace'],
            })
    else:
        print('Warning: credentials_name_map not found or not a map in tf_outputs.')

    values[get_desired_key('secrets', args.out_case)] = secrets_list

    json_path = args.out_dir / f'{args.out_file}.json'
    with open(json_path, 'w') as f:
        json.dump(values, f, indent=2)
        f.write('\n')
    print(f'values.json generated successfully at {json_path}.')

    yaml_path = args.out_dir / f'{args.out_file}.yaml'
    with open(yaml_path, 'w') as f:
        yaml.dump(values, f, default_flow_style=False, sort_keys=False)
    print(f'values.yaml generated successfully at {yaml_path}.')


if __name__ == '__main__':
    main()
