# Only one time
Put all configurations in an appropriate repository.

1. Install `kubectl`, ask for config, and put it in `~/.kube` directory locally. Do not push it to the repository ;)
1. Create namespace:
    - see examples in `microk8s/namespaces/` (remember to change the name),
    - run locally: `kubectl create -f microk8s/namespace/your-ns.yaml`.
1. Create PersistentVolumeClaim:
    - see examples in `microk8s/persistenVC/` (remember to change name and namespace; storage doesn't play a big role),
    - run locally: `kubectl create -f microk8s/persistentVolumeClaim/your-nfs-pvc.yaml`.
1. Create rbac (I'm not sure about this step - try without it, check if it works and update this instruction afterwards):
    - see examples in `microk8s/rbac/` (remember to change namespaces),
    - run locally: `kubectl create -f microk8s/rbac/your-default-rbac.yaml`.
1. Start Ubuntu with nextflow:
    - see examples in `microk8s/deployment/20min-ns/` (remember to change namespaces, claimName and ports to an unoccupied one; port is necessary?),
    - run locally: `kubectl create -f microk8s/deployment/your-dir/ubuntu.yaml`,
    - (mountPath can't be just `/`, but you should not change it nonetheless),
    - copy `nextflow.config` into your mount path: `/mnt/slow/microk8s/labpgx-nfs/your-ns/workspace/` and fill it with your names.

### Nextflow docker image
It's docker image with nextflow, required configuration, and other tools. How to build the image (instructions for myself):
- go to `docker` directory,
- `docker build -t ubuntu-nextflow .`,
- `docker tag ubuntu-nextflow:latest nothingbuttherain/ubuntu-nextflow`,
- `docker push nothingbuttherain/ubuntu-nextflow`.

# Every time you want to carry out an analysis:
1. Log in to the pod running Ubuntu with nextflow: `kubectl exec --namespace your-ns --stdin --tty nextflow -- /bin/bash`.
1. Run your workflow or an example one: `nextflow run nextflow-io/hello -c /workspace/nextflow.config` (do not forget to specify the path to the nextflow config `-c`).
1. Wait for pods to do their job.

# Troubleshooting
1. calico unauthorized: `kubectl rollout restart daemonset/calico-node -n kube-system`
1. Sometimes default resources aren't sufficient. If that's the case, use: https://nf-co.re/usage/configuration#tuning-workflow-resources
