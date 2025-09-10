"""
Test Plugin Architecture
Validation test for the plugin architecture implementation
"""

def test_plugin_architecture():
    """
    Test the plugin architecture with a Python service.
    This function validates that the plugin system works correctly.
    """
    
    print("🧪 Testing Plugin Architecture...")
    
    # Test 1: Initialize framework
    print("Test 1: Framework Initialization")
    try:
        from init import initialize_plugin_framework
        init_result = initialize_plugin_framework()
        
        if init_result["initialized"]:
            print("  ✅ Framework initialized successfully")
        else:
            print("  ❌ Framework initialization failed")
            return False
    except Exception as e:
        print("  ❌ Framework initialization error: {}".format(str(e)))
        return False
    
    # Test 2: Service registration
    print("Test 2: Service Plugin Registration")
    try:
        from registry.service_registry import is_service_type_supported, get_registered_service_types
        
        registered_types = get_registered_service_types()
        if "python" in registered_types:
            print("  ✅ Python service plugin registered")
        else:
            print("  ❌ Python service plugin not registered")
            print("  Registered types: {}".format(registered_types))
            return False
            
    except Exception as e:
        print("  ❌ Service registration test error: {}".format(str(e)))
        return False
    
    # Test 3: Build strategy registration
    print("Test 3: Build Strategy Registration")
    try:
        from registry.build_registry import get_registered_build_strategies
        
        registered_strategies = get_registered_build_strategies()
        if "live_update" in registered_strategies:
            print("  ✅ Live update build strategy registered")
        else:
            print("  ❌ Live update build strategy not registered")
            print("  Registered strategies: {}".format(registered_strategies))
            return False
            
    except Exception as e:
        print("  ❌ Build strategy registration test error: {}".format(str(e)))
        return False
    
    # Test 4: Service validation
    print("Test 4: Service Configuration Validation")
    try:
        from registry.service_registry import validate_service_config
        
        test_config = {
            "type": "python",
            "build_context": "./test-service",
            "ports": [8000],
            "env_vars": [
                {"name": "PYTHONUNBUFFERED", "value": "1"}
            ]
        }
        
        validation_result = validate_service_config("python", test_config)
        if validation_result["valid"]:
            print("  ✅ Python service configuration validation passed")
        else:
            print("  ❌ Python service configuration validation failed")
            print("  Errors: {}".format(validation_result["errors"]))
            return False
            
    except Exception as e:
        print("  ❌ Service validation test error: {}".format(str(e)))
        return False
    
    # Test 5: Build strategy selection
    print("Test 5: Build Strategy Selection")
    try:
        from registry.build_registry import select_build_strategy
        
        test_config = {
            "type": "python", 
            "build_context": "./test-service"
        }
        
        selected_strategy = select_build_strategy("python", test_config)
        if selected_strategy and selected_strategy["name"] == "live_update":
            print("  ✅ Build strategy selection works correctly")
        else:
            print("  ❌ Build strategy selection failed")
            if selected_strategy:
                print("  Selected: {}".format(selected_strategy["name"]))
            return False
            
    except Exception as e:
        print("  ❌ Build strategy selection test error: {}".format(str(e)))
        return False
    
    # Test 6: Default configuration
    print("Test 6: Default Configuration")
    try:
        from registry.service_registry import get_service_default_config
        
        default_config = get_service_default_config("python")
        if default_config and default_config.get("type") == "python":
            print("  ✅ Default configuration retrieval works")
        else:
            print("  ❌ Default configuration retrieval failed")
            return False
            
    except Exception as e:
        print("  ❌ Default configuration test error: {}".format(str(e)))
        return False
    
    print("✅ All plugin architecture tests passed!")
    return True

def create_test_results_dashboard():
    """Create dashboard showing test results."""
    
    # Run tests and capture results
    test_passed = test_plugin_architecture()
    
    status = "PASSED" if test_passed else "FAILED"
    status_emoji = "✅" if test_passed else "❌"
    
    dashboard_cmd = '''echo "🧪 PLUGIN ARCHITECTURE TESTS
=============================
Overall Status: {} {}

Test Coverage:
• Framework Initialization: {}
• Service Plugin Registration: {}  
• Build Strategy Registration: {}
• Service Configuration Validation: {}
• Build Strategy Selection: {}
• Default Configuration: {}

💡 Run tests validate plugin architecture functionality"'''.format(
        status_emoji, status,
        "✅" if test_passed else "❌",
        "✅" if test_passed else "❌",
        "✅" if test_passed else "❌", 
        "✅" if test_passed else "❌",
        "✅" if test_passed else "❌",
        "✅" if test_passed else "❌"
    )
    
    local_resource(
        'plugin-architecture-tests',
        cmd=dashboard_cmd,
        labels=['framework', 'testing']
    )

def run_integration_test():
    """
    Run integration test with actual service deployment.
    """
    
    print("🔧 Running Plugin Architecture Integration Test...")
    
    # Test configuration
    test_service_config = {
        "test-python-service": {
            "type": "python",
            "build_context": "./services/ai-agentic-test-app",  # Use existing service
            "ports": [8000],
            "env_vars": [
                {"name": "PYTHONUNBUFFERED", "value": "1"},
                {"name": "ENV", "value": "test"}
            ],
            "health_check": {
                "path": "/health",
                "port": 8000
            }
        }
    }
    
    try:
        # Test the full validation and deployment pipeline
        from validation.config_validator import validate_service_list
        from init import validate_and_deploy_services
        
        # Validate configuration
        validation_result = validate_service_list(test_service_config)
        if not validation_result["valid"]:
            print("  ❌ Integration test configuration validation failed")
            return False
        
        print("  ✅ Integration test ready (validation passed)")
        
        # Note: We don't actually deploy in the test to avoid side effects
        # In a real integration test, we would call validate_and_deploy_services
        
        return True
        
    except Exception as e:
        print("  ❌ Integration test error: {}".format(str(e)))
        return False