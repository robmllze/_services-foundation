# Services Module

## About

The [Foundation](https://github.com/robmllze/foundation) template is divided into several modules. This helps separate concerns and makes it easier to manage the codebase.

This is the Foundation's Services Module. It defines the app's service environment and all essential services and functionalities for working with data and other resources within the app.

It comprises of the following:

- **Create Service Environment**: A function that creates the app's service environment.
- **Data Helpers**: Helper classes related to specific data models.
- **Data Services**: Services related to specific data models.
- **Data Utils**: Utilities related to specific data models and services.
- **Service Brokers**: Services that broker with the chosen back-end services.
- **System Services**: Services that utilize system resources, such as location.

TODO: Move filters/sorting to data package.

## Notes

- Rename `_services-foundation` to `_services` before using it in your project.
