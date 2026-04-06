# vSphere CSI Driver Helm Chart

vSphere Container Storage Interface (CSI) driver for Kubernetes. This Helm chart deploys all required components to enable vSphere storage integration in your Kubernetes cluster.

## Components

| Component | Type | Description |
|-----------|------|-------------|
| CSIDriver | CSIDriver | Registers `csi.vsphere.vmware.com` driver |
| Controller | Deployment | CSI controller with attacher, resizer, provisioner, snapshotter, syncer sidecars |
| Node (Linux) | DaemonSet | CSI node plugin for Linux nodes |
| Node (Windows) | DaemonSet | CSI node plugin for Windows nodes (disabled by default) |
| StorageClass | StorageClass | Default StorageClass for vSphere volumes |
| RBAC | ClusterRole, Role, Bindings | Required permissions for controller and node |
| Feature States | ConfigMap | Internal feature flags |

## Compatibility

> **Note:** CSI driver v2.7.0 is the **last version** that supports vCenter 6.7. Later CSI versions (v3.x+) require vCenter 7.0 or above.

| Component | Supported Versions |
|-----------|-------------------|
| vCenter Server | 6.7 U3, 7.0, 7.0 U1/U2/U3, 8.0 |
| ESXi | 6.7 U3+, 7.0+ |
| Kubernetes | 1.22 – 1.26 |
| CSI Driver | v2.7.0 |

### vCenter 6.7 Specific Notes

- vCenter 6.7 **Update 3** or later is required (earlier 6.7 versions are not supported)
- `insecure-flag` must be set to `"true"` if the vCenter uses a self-signed certificate
- Some features may have limited functionality on vCenter 6.7:
  - Volume snapshots require vCenter 7.0+
  - Topology-aware provisioning requires vCenter 7.0+
- If running on vCenter 6.7, it is recommended to set the following feature states in `values.yaml`:
  ```yaml
  featureStates:
    block-volume-snapshot: "false"    # snapshots not supported on 6.7
    improved-volume-topology: "false" # limited topology support on 6.7
  ```

## Prerequisites

- Kubernetes 1.22+
- Helm 3.x
- VMware vCenter 6.7 U3+ or 7.0+
- ESXi 6.7 U3+ or 7.0+
- vCenter credentials

## Installation

### 1. Configure vSphere Connection

The chart automatically creates the `vsphere-config-secret` from `values.yaml`. Edit the `vSphereConfig` section with your vCenter credentials:

```yaml
vSphereConfig:
  global:
    clusterID: "my-cluster"
    clusterDistribution: "my-cluster"
  vcenter:
    server: "vcenter.example.com"
    insecureFlag: "true"
    user: "administrator@vsphere.local"
    password: "your-password"
    port: "443"
    datacenters: "your-datacenter"
```

This will generate the following `csi-vsphere.conf` inside the secret:

```ini
[Global]
cluster-id = "my-cluster"
cluster-distribution = "my-cluster"

[VirtualCenter "vcenter.example.com"]
insecure-flag = "true"
user = "administrator@vsphere.local"
password = "your-password"
port = "443"
datacenters = "your-datacenter"
```

### 2. Install the Chart

```bash
helm install vsphere-csi ./vsphere-csi -n vmware-system-csi --create-namespace
```

Or with custom values:

```bash
helm install vsphere-csi ./vsphere-csi -n vmware-system-csi -f my-values.yaml
```

## Uninstallation

```bash
helm uninstall vsphere-csi -n vmware-system-csi
```

## Configuration

### vSphere Connection

| Parameter | Description | Default |
|-----------|-------------|---------|
| `vSphereConfig.global.clusterID` | Cluster identifier | `art-asd` |
| `vSphereConfig.global.clusterDistribution` | Cluster distribution name | `art-asd` |
| `vSphereConfig.vcenter.server` | vCenter FQDN or IP | `vcenter.asd.com` |
| `vSphereConfig.vcenter.insecureFlag` | Skip TLS certificate verification | `true` |
| `vSphereConfig.vcenter.user` | vCenter username | `administrator@vsphere.local` |
| `vSphereConfig.vcenter.password` | vCenter password | `asdasd` |
| `vSphereConfig.vcenter.port` | vCenter port | `443` |
| `vSphereConfig.vcenter.datacenters` | Datacenter name(s) | `asdasd` |

### General

| Parameter | Description | Default |
|-----------|-------------|---------|
| `namespace` | Target namespace | `vmware-system-csi` |

### CSI Driver

| Parameter | Description | Default |
|-----------|-------------|---------|
| `csiDriver.name` | CSI driver name | `csi.vsphere.vmware.com` |
| `csiDriver.attachRequired` | Whether attach is required | `true` |
| `csiDriver.podInfoOnMount` | Inject pod info on mount | `false` |

### Controller

| Parameter | Description | Default |
|-----------|-------------|---------|
| `controller.replicas` | Number of controller replicas | `1` |
| `controller.nodeSelector` | Controller node selector | `{}` |
| `controller.tolerations` | Controller tolerations | master, control-plane, etcd |
| `controller.dnsPolicy` | DNS policy | `Default` |
| `controller.driver.image.repository` | Controller driver image | `rancher/mirrored-cloud-provider-vsphere-csi-release-driver` |
| `controller.driver.image.tag` | Controller driver image tag | `v2.7.0` |
| `controller.driver.loggerLevel` | Log level (PRODUCTION/DEVELOPMENT) | `PRODUCTION` |
| `controller.syncer.image.repository` | Syncer image | `rancher/mirrored-cloud-provider-vsphere-csi-release-syncer` |
| `controller.syncer.image.tag` | Syncer image tag | `v2.7.0` |
| `controller.syncer.fullSyncIntervalMinutes` | Full sync interval | `30` |
| `controller.vSphereConfigSecret` | Name of vSphere config secret | `vsphere-config-secret` |

### Controller Sidecars

| Parameter | Description | Default |
|-----------|-------------|---------|
| `controller.sidecars.attacher.image.tag` | CSI attacher tag | `v3.5.0` |
| `controller.sidecars.resizer.image.tag` | CSI resizer tag | `v1.5.0` |
| `controller.sidecars.provisioner.image.tag` | CSI provisioner tag | `v3.2.1` |
| `controller.sidecars.snapshotter.image.tag` | CSI snapshotter tag | `v6.0.1` |
| `controller.sidecars.livenessProbe.image.tag` | Liveness probe tag | `v2.7.0` |

### Node (Linux)

| Parameter | Description | Default |
|-----------|-------------|---------|
| `node.enabled` | Enable Linux node DaemonSet | `true` |
| `node.hostNetwork` | Use host networking | `true` |
| `node.maxVolumesPerNode` | Max volumes per node | `59` |
| `node.driver.image.tag` | Node driver image tag | `v2.7.0` |
| `node.driver.loggerLevel` | Log level | `PRODUCTION` |

### Node (Windows)

| Parameter | Description | Default |
|-----------|-------------|---------|
| `nodeWindows.enabled` | Enable Windows node DaemonSet | `false` |
| `nodeWindows.maxVolumesPerNode` | Max volumes per node | `59` |
| `nodeWindows.driver.logLevel` | Log level | `DEBUG` |

### StorageClass

| Parameter | Description | Default |
|-----------|-------------|---------|
| `storageClass.enabled` | Create StorageClass | `true` |
| `storageClass.name` | StorageClass name | `vsphere-csi-sc` |
| `storageClass.isDefault` | Set as default StorageClass | `true` |
| `storageClass.allowVolumeExpansion` | Allow volume expansion | `true` |
| `storageClass.reclaimPolicy` | Reclaim policy | `Delete` |
| `storageClass.parameters.datastoreurl` | vSphere datastore URL | `ds:///vmfs/volumes/...` |

### Feature States

All feature flags are configurable under `featureStates`:

| Feature | Default |
|---------|---------|
| `csi-migration` | `true` |
| `csi-auth-check` | `true` |
| `online-volume-extend` | `true` |
| `trigger-csi-fullsync` | `false` |
| `async-query-volume` | `true` |
| `improved-csi-idempotency` | `true` |
| `improved-volume-topology` | `true` |
| `block-volume-snapshot` | `true` |
| `csi-windows-support` | `false` |
| `use-csinode-id` | `true` |
| `list-volumes` | `false` |
| `pv-to-backingdiskobjectid-mapping` | `false` |
| `cnsmgr-suspend-create-volume` | `true` |
| `topology-preferential-datastores` | `true` |
| `max-pvscsi-targets-per-vm` | `true` |

## Verification

After installation, verify the components are running:

```bash
# Check controller
kubectl get deployment vsphere-csi-controller -n vmware-system-csi

# Check node DaemonSet
kubectl get daemonset vsphere-csi-node -n vmware-system-csi

# Check CSIDriver
kubectl get csidriver csi.vsphere.vmware.com

# Check StorageClass
kubectl get storageclass vsphere-csi-sc

# Check pods
kubectl get pods -n vmware-system-csi
```

## License

This chart is provided as-is for deploying the VMware vSphere CSI driver.
