# [helm-charts](https://github.com/dominik-ba/helm-chart-template)

# A starter Helm Charts

This cahrt can be used if you don't need or want to create your own chart or it can be used to kickstart your own chart.
Although `helm create my-name` creates a starter chart for you, it is very limited.

The code is provided as-is with no warranties.

## Usage

[Helm](https://helm.sh) must be installed to use the charts.  Please refer to
Helm's [documentation](https://helm.sh/docs) to get started.

Once Helm has been set up correctly, add the repo as follows:

    helm repo add template https://dominik-ba.github.io/helm-chart-template

If you had already added this repo earlier, run `helm repo update` to retrieve
the latest versions of the packages.  You can then run `helm search repo
template` to see the charts.

To install the a specific chart:

    helm install <release-name> template/helm-chart-template

To uninstall the chart:

    helm delete <release-name>

## License

MIT
