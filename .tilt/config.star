"""
Simple configuration parsing with .env file support for defaults
"""

def load_env_file():
    """Load environment variables from .env file if it exists"""
    env_path = ".tilt/.env"
    env_vars = {}
    
    if os.path.exists(env_path):
        # Read the .env file
        env_content = str(read_file(env_path))
        
        # Parse each line
        for line in env_content.split("\n"):
            line = line.strip()
            # Skip comments and empty lines
            if not line or line.startswith("#"):
                continue
            
            # Parse KEY=VALUE format
            if "=" in line:
                parts = line.split("=", 1)
                if len(parts) == 2:
                    key = parts[0].strip()
                    value = parts[1].strip()
                    # Remove quotes if present
                    if value.startswith('"') and value.endswith('"'):
                        value = value[1:-1]
                    elif value.startswith("'") and value.endswith("'"):
                        value = value[1:-1]
                    env_vars[key] = value
    
    return env_vars

def parse_config():
    """Parse Tilt CLI arguments with .env file defaults"""
    # Load .env file first for defaults
    env_vars = load_env_file()
    
    config.define_string_list("services", args=False, usage="Services to deploy")
    config.define_string("environment", args=False, usage="Environment to deploy")
    config.define_string("developer_id", args=False, usage="Developer ID for namespace")
    config.define_bool("debug", args=False, usage="Enable debug output")
    config.define_bool("build_local", args=False, usage="Build images locally")
    
    cfg = config.parse()
    
    # Parse services from comma-separated string if needed
    services = cfg.get("services", [])
    if services and len(services) == 1 and "," in services[0]:
        services = [s.strip() for s in services[0].split(",")]
    
    # Get environment from CLI or .env file
    environment = cfg.get("environment", "")
    if not environment and env_vars.get("TILT_ENVIRONMENT"):
        environment = env_vars.get("TILT_ENVIRONMENT")
    
    # Get developer_id with precedence: CLI > .env > $USER
    developer_id = cfg.get("developer_id", "")
    if not developer_id:
        developer_id = env_vars.get("TILT_DEVELOPER_ID", os.getenv("USER", "developer"))
    
    # Get debug flag with .env default
    debug = cfg.get("debug", False)
    if not debug and env_vars.get("TILT_DEBUG") == "true":
        debug = True
    
    # Get build_local flag with .env default
    build_local = cfg.get("build_local", None)
    if build_local == None:  # Not specified on CLI
        if env_vars.get("TILT_BUILD_LOCAL") == "false":
            build_local = False
        else:
            build_local = True  # Default to true
    
    return {
        "services": services,
        "environment": environment,
        "developer_id": developer_id,
        "debug": debug,
        "build_local": build_local
    }

def load_service_config():
    """Load service configuration from YAML"""
    config_path = ".tilt/service-config.yaml"
    if not os.path.exists(config_path):
        fail("Service configuration not found at {}".format(config_path))
    return read_yaml(config_path)

def load_environments():
    """Load environment definitions from YAML"""
    env_path = ".tilt/environments.yaml"
    if not os.path.exists(env_path):
        return {}
    
    data = read_yaml(env_path)
    return data.get("environments", {})