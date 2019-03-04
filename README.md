# Store Demo
General purpose demo that highlights survivability across Data Centers, Cloud Providers and the Continental U.S. [power transmission grid](https://en.wikipedia.org/wiki/Continental_U.S._power_transmission_grid).

The project contains the following modules:

* [docker](docker/README.md) - for provisioning a local Docker cluster to run the demo
* [terraform](terraform/README.md) - for provisioning a production like cluster in the cloud to run the demo
* [loader](loader/README.md) - Spring Boot application responsible for creating and loading test data
* [runner](loader/README.md) - Spring Boot application responsible for executing the workload
