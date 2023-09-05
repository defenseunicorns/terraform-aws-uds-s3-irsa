locals {
  loki_name_prefix           = "${var.name_prefix}-loki-${lower(random_id.default.hex)}"
  tags = merge(
    var.tags,
    {
      RootTFModule = replace(basename(path.cwd), "_", "-") # tag names based on the directory name
      GithubRepo   = "github.com/defenseunicorns/delivery-aws-iac"
    }
  )
}