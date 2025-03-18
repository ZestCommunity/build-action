# ZestCode Build Action
An automated build action for ZestCode projects.

## Usage:
### Example:
```yml
name: ZestCode Build Action Example

on:
  push:
    branches: "**"
  pull_request:
    branches: "**"

  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Run Build Action
        id: test
        uses: ZestCommunity/build-action@main
```
### Inputs:
> `write_job_summary` 
> - **Whether to output to GitHub's Job Summary**  
> - Required: False  
> - Default: True  

## Notes
This container was based on LemLib/pros-build. 