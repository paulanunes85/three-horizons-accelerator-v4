// =============================================================================
// THREE HORIZONS ACCELERATOR - RHDH MODULE TESTS
// =============================================================================
//
// Unit and integration tests for the Terraform RHDH (Red Hat Developer Hub) module.
//
// Run with: go test -v -run TestRHDH ./modules/
//
// =============================================================================

package modules

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestRHDHModuleBasic tests basic RHDH configuration
func TestRHDHModuleBasic(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/rhdh",
		Vars: map[string]interface{}{
			"customer_name":             "testrhdh",
			"environment":               "dev",
			"location":                  "brazilsouth",
			"resource_group_name":       "rg-test-rhdh",
			"namespace":                 "rhdh",
			"base_url":                  "https://developer.test.example.com",
			"postgresql_host":           "pg-test.postgres.database.azure.com",
			"postgresql_password":       "test-password-123",
			"github_org":                "test-org",
			"github_app_id":             "12345",
			"github_app_client_id":      "client-id-test",
			"github_app_client_secret":  "client-secret-test",
			"github_app_private_key":    "-----BEGIN RSA PRIVATE KEY-----\ntest\n-----END RSA PRIVATE KEY-----",
			"github_app_webhook_secret": "webhook-secret-test",
			"argocd_url":                "https://argocd.test.example.com",
			"argocd_auth_token":         "argocd-token-test",
			"azure_tenant_id":           "00000000-0000-0000-0000-000000000000",
			"azure_client_id":           "00000000-0000-0000-0000-000000000001",
			"azure_client_secret":       "azure-secret-test",
			"key_vault_name":            "kv-test-rhdh",
			"aks_oidc_issuer_url":       "https://oidc.test.example.com",
			"subnet_id":                 "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet",
			"tags": map[string]interface{}{
				"Environment": "test",
				"ManagedBy":   "Terratest",
			},
		},
		NoColor: true,
	})

	terraform.Init(t, terraformOptions)
	terraform.Validate(t, terraformOptions)

	planOutput := terraform.Plan(t, terraformOptions)

	// Verify RHDH Helm release is planned
	assert.Contains(t, planOutput, "helm_release")
}

// TestRHDHModulePlugins tests plugin configuration
func TestRHDHModulePlugins(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../../terraform/modules/rhdh",
		Vars: map[string]interface{}{
			"customer_name":             "plugintest",
			"environment":               "dev",
			"location":                  "brazilsouth",
			"resource_group_name":       "rg-test-rhdh-plugins",
			"namespace":                 "rhdh",
			"base_url":                  "https://developer.test.example.com",
			"postgresql_host":           "pg-test.postgres.database.azure.com",
			"postgresql_password":       "test-password-123",
			"github_org":                "test-org",
			"github_app_id":             "12345",
			"github_app_client_id":      "client-id-test",
			"github_app_client_secret":  "client-secret-test",
			"github_app_private_key":    "-----BEGIN RSA PRIVATE KEY-----\ntest\n-----END RSA PRIVATE KEY-----",
			"github_app_webhook_secret": "webhook-secret-test",
			"argocd_url":                "https://argocd.test.example.com",
			"argocd_auth_token":         "argocd-token-test",
			"azure_tenant_id":           "00000000-0000-0000-0000-000000000000",
			"azure_client_id":           "00000000-0000-0000-0000-000000000001",
			"azure_client_secret":       "azure-secret-test",
			"key_vault_name":            "kv-test-rhdh-plugins",
			"aks_oidc_issuer_url":       "https://oidc.test.example.com",
			"subnet_id":                 "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet",
			"enable_techdocs":           true,
			"enable_search":             true,
			"enable_kubernetes_plugin":  true,
			"additional_plugins":        []string{"@backstage/plugin-catalog-import", "@backstage/plugin-api-docs"},
		},
		NoColor: true,
	})

	terraform.Init(t, terraformOptions)
	planOutput := terraform.Plan(t, terraformOptions)

	// Verify RHDH with plugins is planned
	assert.Contains(t, planOutput, "rhdh")
}

// TestRHDHModuleReplicas tests replica configuration
func TestRHDHModuleReplicas(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name     string
		replicas int
	}{
		{"single_replica", 1},
		{"dual_replicas", 2},
		{"ha_replicas", 3},
	}

	for _, tc := range testCases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../../../terraform/modules/rhdh",
				Vars: map[string]interface{}{
					"customer_name":             "replicatest",
					"environment":               "prod",
					"location":                  "brazilsouth",
					"resource_group_name":       "rg-test-rhdh-replicas",
					"namespace":                 "rhdh",
					"base_url":                  "https://developer.test.example.com",
					"postgresql_host":           "pg-test.postgres.database.azure.com",
					"postgresql_password":       "test-password-123",
					"github_org":                "test-org",
					"github_app_id":             "12345",
					"github_app_client_id":      "client-id-test",
					"github_app_client_secret":  "client-secret-test",
					"github_app_private_key":    "-----BEGIN RSA PRIVATE KEY-----\ntest\n-----END RSA PRIVATE KEY-----",
					"github_app_webhook_secret": "webhook-secret-test",
					"argocd_url":                "https://argocd.test.example.com",
					"argocd_auth_token":         "argocd-token-test",
					"azure_tenant_id":           "00000000-0000-0000-0000-000000000000",
					"azure_client_id":           "00000000-0000-0000-0000-000000000001",
					"azure_client_secret":       "azure-secret-test",
					"key_vault_name":            "kv-test-rhdh-replicas",
					"aks_oidc_issuer_url":       "https://oidc.test.example.com",
					"subnet_id":                 "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet",
					"replicas":                  tc.replicas,
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			terraform.Plan(t, terraformOptions)
		})
	}
}

// TestRHDHModuleEnvironments tests different environments
func TestRHDHModuleEnvironments(t *testing.T) {
	t.Parallel()

	environments := []string{"dev", "staging", "prod"}

	for _, env := range environments {
		env := env
		t.Run(env, func(t *testing.T) {
			t.Parallel()

			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../../../terraform/modules/rhdh",
				Vars: map[string]interface{}{
					"customer_name":             "envtest",
					"environment":               env,
					"location":                  "brazilsouth",
					"resource_group_name":       "rg-test-rhdh-" + env,
					"namespace":                 "rhdh",
					"base_url":                  "https://developer." + env + ".example.com",
					"postgresql_host":           "pg-" + env + ".postgres.database.azure.com",
					"postgresql_password":       "test-password-123",
					"github_org":                "test-org",
					"github_app_id":             "12345",
					"github_app_client_id":      "client-id-test",
					"github_app_client_secret":  "client-secret-test",
					"github_app_private_key":    "-----BEGIN RSA PRIVATE KEY-----\ntest\n-----END RSA PRIVATE KEY-----",
					"github_app_webhook_secret": "webhook-secret-test",
					"argocd_url":                "https://argocd." + env + ".example.com",
					"argocd_auth_token":         "argocd-token-test",
					"azure_tenant_id":           "00000000-0000-0000-0000-000000000000",
					"azure_client_id":           "00000000-0000-0000-0000-000000000001",
					"azure_client_secret":       "azure-secret-test",
					"key_vault_name":            "kv-test-rhdh-" + env,
					"aks_oidc_issuer_url":       "https://oidc.test.example.com",
					"subnet_id":                 "/subscriptions/00000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet",
				},
				NoColor: true,
			})

			terraform.Init(t, terraformOptions)
			planOutput := terraform.Plan(t, terraformOptions)

			assert.Contains(t, planOutput, env)
		})
	}
}
