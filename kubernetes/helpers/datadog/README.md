

- export API-KEY-DATADOG
```
export API-KEY-DATADOG="API KEY HERE"
echo $API-KEY-DATADOG
```

- create pods datadog-agent kubernetes
```
sed -i "s#api-key-datadog#`echo $API-KEY-DATADOG`#g" kubernetes/helpers/datadog/datadog-agent.yaml

kubectl create -f kubernetes/helpers/datadog/datadog-agent.yaml

```
