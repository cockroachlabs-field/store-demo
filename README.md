# Store Demo
General purpose demo that highlights survivability across Data Centers, Cloud Providers and the Continental U.S. [power transmission grid](https://en.wikipedia.org/wiki/Continental_U.S._power_transmission_grid).

The project contains the following modules:

* [docker](docker/README.md) - for provisioning a local Docker cluster to run the demo
* [terraform](terraform/README.md) - for provisioning a production like cluster in the cloud to run the demo
* [loader](loader/README.md) - Springboot application responsible for creating and loading test data
* [runner](loader/README.md) - Springboot application responsible for executing the workload

## Notes

took `8847` seconds or roughly `2.5` hours to generate `450,000,000` account records with roughly `5,000,000` activations


http://localhost:8082/actuator/metrics/runner.available_balance
http://localhost:8082/actuator/metrics/runner.create_auth
http://localhost:8082/actuator/metrics/runner.update_auth


```bash
cockroach workload init tpcc --warehouses=400 --drop
```

```bash
cockroach workload run tpcc --ramp=5m --warehouses=400 --active-warehouses=400 --duration=15m --split --scatter
```

