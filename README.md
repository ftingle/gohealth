# Unicorns

The application serves for testing purposes only. It runs only in QA environment.

## Testing

### Kafka streaming

The service exposes these endpoints for testing Kafka streaming:
 - POST /kafka/greetings - produces Kafka messages in the text-plain format
                           e.g.: `curl -d 'hello' -H "Content-Type: text/plain" -X POST http://localhost:8080/kafka/greetings`
 - GET /kafka/greetings - consumes Kafka messages from the `unicorns-{dev/qa}.greeting` topic

In order to test the Kafka streaming locally:
 - Enable Kafka `spring.kafka.enabled=true` in the config: `/unicorns/unicorns-server/src/main/resources/application-dev.yml`
 - Run the application under the `dev` profile: `./gradlew bootRun --args='--spring.profiles.active=dev'` 
 - Register the schema against Schema Registry: `./gradlew schemasRegister --env=dev`
