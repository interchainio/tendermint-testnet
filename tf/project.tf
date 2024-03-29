resource "digitalocean_project" "tm-testnet" {
  name        = "tm-testnet"
  description = "A project to test the Tendermint codebase."
  resources   = concat([for node in digitalocean_droplet.testnet-node: node.urn], [digitalocean_droplet.testnet-prometheus.urn], [digitalocean_droplet.testnet-load-runner.urn], [for node in digitalocean_droplet.ephemeral-node: node.urn])
}