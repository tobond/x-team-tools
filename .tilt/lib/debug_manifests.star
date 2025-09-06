"""
Debug manifest generation to identify YAML issues
"""

load('k8s_manifests.star', 'generate_k8s_manifests')

def debug_manifest_generation(service_name, service_config, namespace, image_name, global_config, developer_id):
    """Debug function to print generated YAML and identify issues"""

    print("🐛 DEBUG: Generating manifests for service: " + service_name)

    try:
        manifests = generate_k8s_manifests(
            service_name, service_config, namespace, image_name, global_config, developer_id
        )

        print("✅ DEBUG: Successfully generated manifests")
        print("📄 DEBUG: Generated YAML:")
        print("=" * 80)
        print(manifests)
        print("=" * 80)

        return manifests
    except Exception as e:
        print("❌ DEBUG: Error generating manifests: " + str(e))
        fail("Manifest generation failed: " + str(e))
