---
title: "Integrating a deployment counter to your CI/CD pipeline"
date: 2023-08-03T16:16:39-03:00
categories: [ "CI/CD", "DevOps", "Azure"]
---

I was reading a blog by Chad Carlson about [Measuring Deployment Success with GitHub Actions](https://platform.sh/blog/measuring-the-success-of-a-deployment-with-githubactions/) and I noticed a stylish deployment counter featured at the bottom of their website, highlighting their platform's successful deployments. While a PaaS provider like [platform.sh](https://platform.sh) will have many more deployments than my personal website, i feelt inspired to create a similar counter and integrate it into my CI/CD pipeline.

For some context, my website is a static website built using hugo and hosted on Azure as a Static Web App. The entire codebase resides in a GitHub repository, and I've set up a streamlined CI/CD pipeline to trigger deployment to Azure upon a specific event, successful commits.

For my approach, I'll use Github Actions to create a workflow that increments a counter that will keeps track of all of my successful deployments.

This counter will be called `deployment_counter.txt`, will contain an integer and will be located inside folder called `counter`.

First, let's take a look at the finished workflow:

{{< highlight yml >}}
name: Update Deployment Counter

on:
  workflow_run:
    workflows: [Azure Static Web Apps CI/CD]
    branches: [main]
    types:
      - completed

jobs:
  update_counter:
    runs-on: ubuntu-latest
    if: ${{ github.event.workflow_run.conclusion == 'success' }}
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v2

      - name: Increment Counter
        id: increment_counter
        run: ./scripts/counter.sh

      - name: Update resources
        uses: test-room-7/action-update-file@v1
        with:
            file-path: counter/deployment_counter.txt
            commit-msg: Update counter
            github-token: ${{ secrets.ACTIONSCOUNTER_TOKEN }}
{{< /highlight>}}

 
##### Now lets analize the yml file that defines the workflow:


{{< highlight yml >}}
name: Update Deployment Counter
{{< /highlight >}}
The name of the workflow as it will appear in the "Actions" tab of the GitHub repository.

---

{{< highlight yml >}}
on:
{{< /highlight >}}
Specifies the trigger for this workflow.

---


{{< highlight yml >}}
on:
  workflow_run:
    workflows: [Azure Static Web Apps CI/CD]
    branches: [main]
{{< /highlight >}}
When using the `workflow_run` event, you can specify what branches the triggering workflow must run on in order to trigger your workflow.

For example, this workflow will only run when the workflow named `Azure Static Web Apps CI/CD` runs on a branch whose name starts with `main`.

The workflow `Azure Static Web Apps CI/CD`  monitors the repository for changes. As commits are pushed to the `main` branch, the application is built from the `app_location` folder and files in the `output_location` are served to the public web.


---


{{< highlight yml >}}
types:
  - completed
{{< /highlight >}}
Will make sure that the workflow runs when check suite activity occurs. A check suite is a collection of the check runs created for a specific commit.

---


{{< highlight yml >}}
jobs:
{{< /highlight >}}
Groups together all the jobs that run in the `Update deployment counter` workflow.

---


{{< highlight yml >}}
update_counter:
{{< /highlight >}}
Defines a job named `update_counter`. The child keys will define properties of the job.

---


{{< highlight yml >}}
runs-on: ubuntu-latest
{{< /highlight >}}
Configures the job to run on the latest version of an Ubuntu Linux runner. This means that the job will execute on a fresh virtual machine hosted by GitHub.

---


{{< highlight yml >}}
if: ${{ github.event.workflow_run.conclusion == 'success' }}
{{< /highlight >}}
Will run the `steps` based on the result of the triggering workflow. In this case, this workflow will run based on the successful conclusion of the `Azure Static Web Apps CI/CD` workflow.

## Avoiding an infinite loop

You may have realized that when the `Azure Static Web Apps CI/CD` workflow is triggered due to a successful change in the repository, it, in turn, fires off the `Update Deployment Counter` workflow. The latter is responsible for updating the text file that logs successful deployments. However, this update acts as an event in itself, triggering the `Azure Static Web Apps CI/CD` workflow yet again, thus creating an infinite loop.

Thankfully, github actions gives us many tools to use in our workflows.

Let’s take a look to a snippet of the `Azure Static Web Apps CI/CD` workflow:

{{< highlight yml >}}
name: Azure Static Web Apps CI/CD

on:
  push:
    paths-ignore: counter/deployment_counter.txt
    branches:
      - main
  pull_request:
    paths-ignore: counter/deployment_counter.txt
    types: [opened, synchronize, reopened, closed]
    branches:
      - main
{{< /highlight >}}

Here I used the `paths-ignore` filter to specify a path that will be ignored by the workflow. Meaning that any changes made to `deployment_counter.txt` will not be considered an event and therefore the workflow will not be triggered.

You can see the counter implemented on [my home page](https://pablodip.me/)

&nbsp; 
