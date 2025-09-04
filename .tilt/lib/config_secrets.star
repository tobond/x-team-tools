"""
ConfigMap and Secret management for Tilt services
Handles creation and management of Kubernetes ConfigMaps and Secrets
"""

def create_service_configmap(service_name, service_config, namespace, debug_mode=False):
    """Create ConfigMap for service configuration using Tilt's configmap extension"""
    
    config_data = {}
    env_vars = service_config.get("env_vars", [])
    service_type = service_config.get("type", "generic")
    
    # Extract non-sensitive configuration from environment variables
    for env in env_vars:
        if env.get("from_configmap") and not env.get("sensitive", False):
            key = env.get("key", env["name"].lower())
            config_data[key] = env.get("value", "")
    
    # Add service-specific configuration
    config_data["SERVICE_TYPE"] = service_type
    config_data["SERVICE_NAME"] = service_name
    config_data["NAMESPACE"] = namespace
    
    # Add type-specific configuration
    config_data.update(_get_type_specific_config(service_type, service_config))
    
    if config_data:
        configmap_create(
            service_name + "-config",
            namespace=namespace,
            from_dict=config_data
        )
        
        if debug_mode:
            print("Created ConfigMap for service: " + service_name)
            print("ConfigMap data keys: " + str(list(config_data.keys())))

def create_service_secret(service_name, service_config, namespace, debug_mode=False):
    """Create Secret for sensitive service configuration using Tilt's secret extension with developer isolation"""
    
    secret_data = {}
    env_vars = service_config.get("env_vars", [])
    service_type = service_config.get("type", "generic")
    
    # Extract developer ID from namespace for isolation
    developer_id = namespace.replace("dev-", "") if namespace.startswith("dev-") else "default"
    
    # Extract sensitive configuration from environment variables
    for env in env_vars:
        if env.get("from_secret") or env.get("sensitive", False):
            key = env.get("key", env["name"].lower())
            secret_data[key] = env.get("value", "")
    
    # Add default secrets for different service types with developer isolation
    secret_data.update(_get_type_specific_secrets(service_type, developer_id))
    
    # Add developer-specific secrets
    secret_data.update(_get_developer_specific_secrets(developer_id, service_name))
    
    if secret_data:
        secret_create_generic(
            service_name + "-secret",
            namespace=namespace,
            from_dict=secret_data
        )
        
        if debug_mode:
            print("Created Secret for service: " + service_name)
            print("Secret data keys: " + str(list(secret_data.keys())))
            print("Developer isolation applied for: " + developer_id)

def _get_type_specific_config(service_type, service_config):
    """Get type-specific configuration for different service types"""
    
    config_data = {}
    
    if service_type == "python":
        config_data.update({
            "PYTHONPATH": "/app",
            "PYTHONUNBUFFERED": "1"
        })
    elif service_type == "java":
        config_data["JAVA_OPTS"] = service_config.get("java_opts", "-Xmx512m -Xms256m")
    elif service_type == "nodejs":
        config_data.update({
            "NODE_ENV": "development",
            "NPM_CONFIG_LOGLEVEL": "info"
        })
    elif service_type == "go":
        config_data.update({
            "CGO_ENABLED": "0",
            "GOOS": "linux"
        })
    elif service_type == "postgres":
        config_data.update({
            "postgres_db": service_config.get("env_vars", [{}])[0].get("value", "devdb"),
            "postgres_user": service_config.get("env_vars", [{}])[1].get("value", "devuser")
        })
    elif service_type == "redis":
        config_data.update({
            "redis_databases": "16",
            "redis_maxmemory": "128mb"
        })
    elif service_type == "rabbitmq":
        config_data.update({
            "rabbitmq_default_user": service_config.get("env_vars", [{}])[0].get("value", "devuser"),
            "rabbitmq_default_vhost": service_config.get("env_vars", [{}])[2].get("value", "dev")
        })
    elif service_type == "mock":
        config_data.update({
            "mock_port": str(service_config.get("ports", [8080])[0]),
            "mock_endpoints": str(len(service_config.get("mock_endpoints", [])))
        })
    
    return config_data

def _get_type_specific_secrets(service_type, developer_id="default"):
    """Get type-specific secrets for different service types with developer isolation"""
    
    secret_data = {}
    
    if service_type == "postgres":
        secret_data.update({
            "postgres_password": "devpass_" + developer_id,
            "postgres_user": "devuser_" + developer_id,
            "postgres_db": "devdb_" + developer_id.replace("-", "_")
        })
    elif service_type == "redis":
        secret_data.update({
            "redis_password": "devpass_" + developer_id
        })
    elif service_type == "rabbitmq":
        secret_data.update({
            "rabbitmq_default_pass": "devpass_" + developer_id,
            "rabbitmq_default_user": "devuser_" + developer_id,
            "rabbitmq_erlang_cookie": "dev_cookie_" + developer_id
        })
    elif service_type == "mock":
        secret_data.update({
            "mock_api_key": "dev_mock_key_" + developer_id,
            "mock_secret": "dev_mock_secret_" + developer_id
        })
    elif service_type == "python":
        # Add Python-specific secrets if needed
        secret_data.update({
            "api_key": "dev_api_key_" + developer_id,
            "secret_key": "dev_secret_" + developer_id
        })
    elif service_type == "java":
        # Add Java-specific secrets if needed
        secret_data.update({
            "datasource_password": "dev_db_pass_" + developer_id
        })
    elif service_type == "nodejs":
        # Add Node.js-specific secrets if needed
        secret_data.update({
            "session_secret": "dev_session_" + developer_id,
            "jwt_secret": "dev_jwt_" + developer_id
        })
    elif service_type == "go":
        # Add Go-specific secrets if needed
        secret_data.update({
            "auth_token": "dev_token_" + developer_id
        })
    
    return secret_data

def _get_developer_specific_secrets(developer_id, service_name):
    """Get developer-specific secrets for isolation and personalization"""
    
    secret_data = {
        "developer_id": developer_id,
        "developer_token": "dev_token_" + developer_id + "_" + service_name,
        "environment_id": "local_" + developer_id,
        "isolation_key": "isolation_" + developer_id
    }
    
    # Load developer-specific secrets from file if exists
    developer_secrets_file = ".tilt/secrets/" + developer_id + ".yaml"
    if os.path.exists(developer_secrets_file):
        try:
            developer_secrets = read_yaml(developer_secrets_file)
            if isinstance(developer_secrets, dict):
                secret_data.update(developer_secrets.get("secrets", {}))
        except:
            # If file exists but can't be read, continue with defaults
            pass
    
    return secret_data

def create_developer_secret_template(developer_id, namespace, debug_mode=False):
    """Create a template for developer-specific secrets"""
    
    local_resource(
        'create-secret-template-' + developer_id,
        cmd='''
        echo "=== Developer Secret Template ({developer_id}) ==="
        echo "Creating secret template for developer isolation"
        echo ""
        
        # Create secrets directory if it doesn't exist
        mkdir -p .tilt/secrets
        
        # Create developer-specific secret template
        SECRET_FILE=".tilt/secrets/{developer_id}.yaml"
        
        if [ ! -f "$SECRET_FILE" ]; then
            cat > "$SECRET_FILE" << 'EOF'
# Developer-specific secrets for {developer_id}
# This file is used for secure local secret management
# Add your personal development secrets here

secrets:
  # Database credentials
  database_password: "your_dev_db_password"
  database_user: "{developer_id}_user"
  
  # API keys and tokens
  external_api_key: "your_dev_api_key"
  auth_token: "your_dev_auth_token"
  
  # Service-specific secrets
  jwt_secret: "your_jwt_secret_for_local_dev"
  encryption_key: "your_encryption_key"
  
  # Third-party service credentials
  aws_access_key: "your_local_aws_key"
  aws_secret_key: "your_local_aws_secret"
  
  # Custom secrets for your services
  custom_secret_1: "value1"
  custom_secret_2: "value2"

# Configuration for secret management
config:
  auto_rotate: false
  backup_enabled: true
  encryption_enabled: false
EOF
            
            echo "✅ Created secret template: $SECRET_FILE"
            echo ""
            echo "📝 IMPORTANT: Edit this file to add your personal development secrets"
            echo "🔒 This file should contain only LOCAL development secrets"
            echo "⚠️  Never commit production secrets to this file"
            echo ""
        else
            echo "Secret template already exists: $SECRET_FILE"
        fi
        
        echo "=== Secret Template Setup Complete ==="
        '''.format(developer_id=developer_id),
        deps=[],
        labels=['secrets', 'template', developer_id],
        auto_init=False,
        trigger_mode=TRIGGER_MODE_MANUAL
    )

def setup_secret_management_monitoring(developer_id, namespace, debug_mode=False):
    """Setup monitoring for secret management and security"""
    
    local_resource(
        'secret-management-' + developer_id,
        cmd='''
        echo "=== Secret Management Status ({developer_id}) ==="
        echo "Namespace: {namespace}"
        echo "Timestamp: $(date)"
        echo ""
        
        echo "=== Secret Resources ==="
        kubectl get secrets -n {namespace} -o wide 2>/dev/null || echo "No secrets found"
        echo ""
        
        echo "=== Secret Template Status ==="
        SECRET_FILE=".tilt/secrets/{developer_id}.yaml"
        if [ -f "$SECRET_FILE" ]; then
            echo "✅ Developer secret template exists: $SECRET_FILE"
            echo "Last modified: $(stat -c %y "$SECRET_FILE" 2>/dev/null || stat -f %Sm "$SECRET_FILE" 2>/dev/null || echo 'unknown')"
        else
            echo "⚠️  No developer secret template found"
            echo "💡 Run 'create-secret-template-{developer_id}' to create one"
        fi
        echo ""
        
        echo "=== Security Validation ==="
        
        # Check for secrets with default values
        echo "Checking for default/weak secrets..."
        WEAK_SECRETS=0
        
        for secret in $(kubectl get secrets -n {namespace} --no-headers -o custom-columns=":metadata.name" 2>/dev/null); do
            if kubectl get secret "$secret" -n {namespace} -o jsonpath='{{.data}}' 2>/dev/null | grep -q "ZGV2cGFzcw=="; then
                echo "⚠️  Secret '$secret' may contain default password"
                WEAK_SECRETS=$((WEAK_SECRETS + 1))
            fi
        done
        
        if [ "$WEAK_SECRETS" -eq 0 ]; then
            echo "✅ No obvious weak secrets detected"
        else
            echo "⚠️  Found $WEAK_SECRETS potentially weak secrets"
        fi
        
        echo ""
        echo "=== Secret Management Complete ==="
        '''.format(developer_id=developer_id, namespace=namespace),
        deps=[],
        labels=['secrets', 'monitoring', 'security', developer_id],
        auto_init=False,
        trigger_mode=TRIGGER_MODE_MANUAL
    )