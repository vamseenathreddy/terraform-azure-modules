output "cluster_id" {
  description = "AKS cluster resource ID."
  value       = azurerm_kubernetes_cluster.this.id
}

output "cluster_name" {
  description = "AKS cluster name."
  value       = azurerm_kubernetes_cluster.this.name
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL for workload identity federation."
  value       = azurerm_kubernetes_cluster.this.oidc_issuer_url
}

output "kubelet_identity_object_id" {
  description = "Object ID of the kubelet identity (grant AcrPull to this)."
  value       = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}

output "kube_config" {
  description = "Raw kubeconfig. Marked sensitive; prefer az aks get-credentials with Entra auth."
  value       = azurerm_kubernetes_cluster.this.kube_config_raw
  sensitive   = true
}
