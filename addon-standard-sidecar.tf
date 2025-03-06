
resource "null_resource" "Install_CCM_Linode" {
depends_on = [ module.talos_linode_clusters, module.talos_aws_clusters ]

provisioner "local-exec" {
  command = "sleep 180"
}

count = length(local.linode_clusters)
  provisioner "local-exec" {
    command = <<EOT
      helm repo add ccm-linode https://linode.github.io/linode-cloud-controller-manager/ --kubeconfig ${module.talos_linode_clusters[count.index].path_to_kubeconfig_file}
      helm repo update ccm-linode --kubeconfig ${module.talos_linode_clusters[count.index].path_to_kubeconfig_file}
      helm install ccm-linode --set apiToken=${local.linode_clusters[count.index].linode_token},region=${local.linode_clusters[count.index].region} ccm-linode/ccm-linode  --kubeconfig ${module.talos_linode_clusters[count.index].path_to_kubeconfig_file}
    EOT
  }
}
resource "null_resource" "Install_Gateway_API" {
  depends_on = [ null_resource.Install_CCM_Linode ]

  count = length(local.linode_clusters)
  provisioner "local-exec" {
    command = <<EOT
      kubectl get crd gateways.gateway.networking.k8s.io --kubeconfig ${module.talos_linode_clusters[count.index].path_to_kubeconfig_file} &> /dev/null || \
      { kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/standard-install.yaml --kubeconfig ${module.talos_linode_clusters[count.index].path_to_kubeconfig_file}; } 
    EOT
  }
}

resource "null_resource" "Label_default_namespace" {
depends_on = [ null_resource.Install_Gateway_API ]

count = length(local.linode_clusters)
  provisioner "local-exec" {
    command = <<EOT
      kubectl label namespace default istio-injection=enabled --kubeconfig ${module.talos_linode_clusters[count.index].path_to_kubeconfig_file}
     kubectl get namespaces --no-headers  --kubeconfig ${module.talos_linode_clusters[count.index].path_to_kubeconfig_file} | awk '{print $1}' | xargs -I {} kubectl label namespace {} istio-cni=enabled --overwrite --kubeconfig ${module.talos_linode_clusters[count.index].path_to_kubeconfig_file}

    EOT
  }
}
resource "null_resource" "create_istio_namespace" {
  depends_on = [ null_resource.Label_default_namespace ]
  count = length(local.linode_clusters)

  provisioner "local-exec" {
    command = <<EOT
      kubectl create namespace istio-system --kubeconfig ${module.talos_linode_clusters[count.index].path_to_kubeconfig_file}
    EOT
  }
}

resource "null_resource" "CSR_and_reset" {
depends_on = [ null_resource.create_istio_namespace ]

provisioner "local-exec" {
  command = "sleep 60"
}

count = length(local.linode_clusters)
  provisioner "local-exec" {
    command = <<EOT
      kubectl get csr --kubeconfig ${module.talos_linode_clusters[count.index].path_to_kubeconfig_file} | awk '$6=="Pending" {print $1}'| xargs kubectl certificate approve --kubeconfig ${module.talos_linode_clusters[count.index].path_to_kubeconfig_file}
      kubectl label namespace istio-system pod-security.kubernetes.io/enforce=privileged --overwrite --kubeconfig ${module.talos_linode_clusters[count.index].path_to_kubeconfig_file}
      kubectl delete pod -l  app.kubernetes.io/part-of=istio -n istio-system --kubeconfig ${module.talos_linode_clusters[count.index].path_to_kubeconfig_file}
    EOT
  }
}

resource "null_resource" "Install_Istio" {
depends_on = [ null_resource.CSR_and_reset ]

count = length(local.linode_clusters)
  provisioner "local-exec" {
    command = <<EOT
      helm install istio-base istio/base -n istio-system --set defaultRevision=default --create-namespace --kubeconfig ${module.talos_linode_clusters[count.index].path_to_kubeconfig_file}
      helm install istio-cni istio/cni -n istio-system --wait --kubeconfig ${module.talos_linode_clusters[count.index].path_to_kubeconfig_file}
      helm install istiod istio/istiod -n istio-system --set pilot.cni.enabled=true --wait --kubeconfig ${module.talos_linode_clusters[count.index].path_to_kubeconfig_file}
      sleep 20
      kubectl run echoserver --image=k8s.gcr.io/echoserver:1.10 --restart=Never --port=8080 -l app=echoserver --kubeconfig ${module.talos_linode_clusters[count.index].path_to_kubeconfig_file}
      kubectl create service loadbalancer echoserver --tcp=5005:8080 --kubeconfig ${module.talos_linode_clusters[count.index].path_to_kubeconfig_file}
      kubectl get pods -A --kubeconfig ./kubeconfig| awk '{print $2}' | xargs kubectl delete pod -n istio-system --kubeconfig ${module.talos_linode_clusters[count.index].path_to_kubeconfig_file}

    EOT
  }
}