# ArgoCD

## Pre-requisites
* Helm
* Kubectl

```bash
brew install helm
brew install kubectl
```

### CleanUp

You may want to delete old resources\
Follow up after this [steps](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack#uninstall-helm-chart)

```bash
kubectl delete crd alertmanagerconfigs.monitoring.coreos.com
kubectl delete crd alertmanagers.monitoring.coreos.com
kubectl delete crd podmonitors.monitoring.coreos.com
kubectl delete crd probes.monitoring.coreos.com
kubectl delete crd prometheuses.monitoring.coreos.com
kubectl delete crd prometheusrules.monitoring.coreos.com
kubectl delete crd servicemonitors.monitoring.coreos.com
kubectl delete crd thanosrulers.monitoring.coreos.com
kubectl delete crd applications.argoproj.io
kubectl delete crd applicationsets.argoproj.io
kubectl delete crd appprojects.argoproj.io
helm del -n argocd argocd
```

### Installation
We will install the argoCD via Helm\
We choose this argoCD [distribution](https://artifacthub.io/packages/helm/argo/argo-cd)\
The helm chart can be found [here](https://github.com/argoproj/argo-helm/tree/main/charts/argo-cd)

We would like to expose two sets of [Argo CD metrics](https://argo-cd.readthedocs.io/en/release-1.8/operator-manual/metrics/#application-metrics)\
Therefore, we will enable:
 * Application Metrics : `controller.metrics.enabled=true`
 * API Server Metrics : `server.metrics.enabled=true`

Let's install:
```bash
kubectl create namespace argocd
helm repo add argo https://argoproj.github.io/argo-helm
helm upgrade -i argocd --namespace argocd --set redis.exporter.enabled=true --set redis.metrics.enabled=true --set server.metrics.enabled=true --set controller.metrics.enabled=true argo/argo-cd
```

### Get the credentials

Username: `admin`
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### Connect our main repository to argoCD

The Application CRD is the Kubernetes resource object representing a deployed application instance in an environment\
Let's apply it:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: workshop
  namespace: argocd
spec:
  destination:
    namespace: argocd
    server: https://kubernetes.default.svc
  project: default
  source:
    path: argoCD/
    repoURL: https://github.com/naturalett/continuous-delivery
    targetRevision: main
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF
```

### Access the server UI
```bash
kubectl port-forward service/argocd-server -n argocd 8080:443
```
Connect: [http://localhost:8080](http://localhost:8080)

## Prometheus (Automatic Workflow - Just read and watch the  installation)

### Install Prometheus using argoCD
We will install the full stack: kube-prometheus-stack

The full stack will come with:
  * Prometheus
  * Grafana dashboard
  * etc

We will disable the default node-exporter and we will add its helm chart separately 



**We are using `Option 2`**

### Option 1 - Apply the CRD

```bash
cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: prometheus
  namespace: argocd
spec:
  destination:
    name: in-cluster
    namespace: argocd
  project: default
  source:
    repoURL: https://prometheus-community.github.io/helm-charts
    targetRevision: 44.3.0
    chart: kube-prometheus-stack
EOF
```

### Option 2 - Define the installation declaratively
This option is already applied based on CRD that we deployed earlier\
You can check the [Application YAML](https://github.com/naturalett/continuous-delivery/blob/main/argoCD/kube-prometheus-stack/application.yaml)

Prometheus expose metrics to /metrics.
In Grafana we will define a Prometheus data source. In addition, we have more metrics that we want to display in Grafana therefore we will [scrape them in Prometheus](https://github.com/naturalett/continuous-delivery/blob/main/argoCD/prometheus/application.yaml#L20-L31)

### Prometheus Node Exporter
The application is defined [declaratively](https://github.com/naturalett/continuous-delivery/blob/main/argoCD/prometheus-node-exporter/application.yaml)

### Prometheus Operator CRDs
Related issue: Fix prometheus CRD being too big [#4439](https://github.com/prometheus-operator/prometheus-operator/issues/4439#issuecomment-1030198014)

We deployed a [Prometheus CRDs](https://github.com/naturalett/continuous-delivery/blob/main/argoCD/prometheus-operator-crds/application.yaml)

### Access the server UI
```bash
kubectl port-forward service/kube-prometheus-stack-prometheus -n argocd 9090:9090
```
Connect: [http://localhost:9090](http://localhost:9090)


## Grafana

## Get Grafana password
Username: `admin`
```bash
kubectl get secret -n argocd kube-prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

### Access the server UI
```bash
kubectl port-forward service/kube-prometheus-stack-grafana -n argocd 9092:80
```

### Grafana Dashboard
For dashboard we created a [configMap](https://github.com/naturalett/continuous-delivery/blob/main/argoCD/grafana/dashboards/argo-cd.yaml) and applied it with using the [kustomization](https://github.com/naturalett/continuous-delivery/blob/main/argoCD/kustomization.yaml#L8) then we [attached it](https://github.com/naturalett/continuous-delivery/blob/main/argoCD/prometheus/application.yaml#L21-L25) during the deployment of Grafana\
As well, we scrap the metrics that got exposed by the argoCD

Connect: [http://localhost:9092](http://localhost:9092)



## Fire up an Alert
Run the following script:
```bash
https://github.com/naturalett/continuous-delivery/blob/main/trigger_alert.sh
```

### Access the server UI
```bash
kubectl port-forward service/alertmanager-operated -n argocd 9093:9093
```
Connect: [http://localhost:9093](http://localhost:9093)


Watch the alert:
```bash
kubectl port-forward service/alertmanager-operated 9093:9093
```
