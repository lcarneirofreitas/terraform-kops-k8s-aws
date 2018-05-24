
- start minikube

```
minikube start
```

- create deployment rabbitmq
```
kubectl apply -f rabbitmq-deployment.yaml
```

- create service rabbitmq
```
kubectl apply -f rabbitmq-service.yaml
```

- create producer messages
```
kubectl apply -f producer-deployment.yaml
```

- create consumer messages
```
kubectl apply -f consumer-deployment.yaml
```

- access admin rabbitmq port-forward kubernetes
```
kubectl port-forward deployment/rabbitmq 15672:15672

http://127.0.0.1:15672

user: guest
pass: guest
```

- get logs pod consumer and producer
```
kubectl logs -f producer-64b6945654-sw4xw
```

- remove consumer pod
```
kubectl scale deployment consumer --replicas=0
```

- add consumer pod
```
kubectl scale deployment consumer --replicas=1
```

- update version image pod
```
kubectl set image deployments/consumer consumer=lcarneirofreitas/consumer:v2
```





# referencias
https://kubernetes.io/docs/tutorials/hello-minikube/

# redis exemplos
https://kubernetes.io/docs/tutorials/stateless-application/guestbook/

# port-forward para acessar admin rabbitmq
kubectl port-forward rabbitmq-566bfd8f45-j6fp4 15672:15672


