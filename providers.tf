provider "vault" {
  address = var.primary_addr
}

provider "vault" {
  alias   = "eu"
  address = var.eu_addr
  token   = var.eu_token
}