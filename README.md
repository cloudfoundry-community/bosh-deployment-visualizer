# BOSH Deployment Visualizer

## Prerequisites

Please make sure the following tools are installed:

- [spruce](https://github.com/geofffranks/spruce)
- [jq](https://stedolan.github.io/jq/download/) (needs at least 1.6)
- [plantuml](http://plantuml.com/)

When using macOS these can be installed via brew:

```bash
brew tap starkandwayne/cf
brew install starkandwayne/cf/spruce
brew install jq plantuml
```

Last just clone the repo:

```bash
git clone https://github.com/cloudfoundry-community/bosh-deployment-visualizer ~/workspace/bosh-deployment-visualizer
```

## Using with cf-deployment

```bash
git clone https://github.com/cloudfoundry/cf-deployment ~/workspace/cf-deployment
~/workspace/bosh-deployment-visualizer/visualize.sh ~/workspace/cf-deployment/cf-deployment.yml
```

To view the result:

``` bash
open cf.png
```

![image](https://user-images.githubusercontent.com/4748380/52331329-27ed4480-29f8-11e9-9d71-2aa88a91ca6d.png)
