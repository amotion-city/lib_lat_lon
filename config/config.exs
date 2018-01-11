use Mix.Config

### EXTERNALS
config :porcelain, driver: Porcelain.Driver.Basic

### ENV-SPECIFIC
if File.exists?("#{Mix.env()}.exs"), do: import_config("#{Mix.env()}.exs")
