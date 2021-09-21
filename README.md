# Semaphore CI Integration for BuildPulse [![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/Workshop64/buildpulse-semaphore/master/LICENSE)

Connect your [Semaphore][semaphoreci.com] workflows to [BuildPulse][buildpulse.io] to help you identify and eliminate flaky tests.

## Usage

1. Locate the BuildPulse credentials for your account at [buildpulse.io][]
2. In your organization settings on [semaphoreci.com][], [create a secret](https://docs.semaphoreci.com/essentials/using-secrets/#creating-and-managing-secrets) named `buildpulse-credentials`
3. In the `buildpulse-credentials` secret, add two environment variables:
    - One named `BUILDPULSE_ACCESS_KEY_ID` with the value set to the `BUILDPULSE_ACCESS_KEY_ID` for your account
    - One named `BUILDPULSE_SECRET_ACCESS_KEY` with the value set to the `BUILDPULSE_SECRET_ACCESS_KEY` for your account
4. Add the following `epilogue` clause and `secrets` clause to your Semaphore workflow file:

    ```yaml
    blocks:
      - name: Run tests
        task:
          jobs:
            - name: Run tests
              commands:
                - checkout
                - echo "Run your tests and generate XML reports for your test results"
          epilogue:
            always: # Run these commands even when the tests fail
              commands:
                # Upload test results to BuildPulse for flaky test detection
                - curl -fsSL https://github.com/buildpulse/test-reporter/releases/latest/download/test_reporter_linux_amd64 > ./buildpulse-test-reporter
                - chmod +x ./buildpulse-test-reporter
                - ./buildpulse-test-reporter submit <path> --account-id <buildpulse-account-id> --repository-id <buildpulse-repository-id>
          secrets:
            - name: buildpulse-credentials
    ```

5. In your workflow file, replace `<path>` with the actual path containing the XML reports for your test results
6. Also in your workflow file, replace `<buildpulse-account-id>` and `<buildpulse-repository-id>` with your account ID and repository ID from [buildpulse.io][]

[buildpulse.io]: https://buildpulse.io
[semaphoreci.com]: https://semaphoreci.com
