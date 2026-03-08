[![GitHub CI](../../actions/workflows/main.yml/badge.svg)](../../actions/workflows/main.yml)

- A [docker-containerized](https://registry.hub.docker.com/r/cyberdojo/languages-start-points) micro-service for [https://cyber-dojo.org](http://cyber-dojo.org).
- The data source for the `choose a language & test-framework` page.
- Demonstrates a [Kosli](https://www.kosli.com/) instrumented [GitHub CI workflow](https://app.kosli.com/cyber-dojo/flows/languages-start-points-ci/trails/) 
  deploying, with Continuous Compliance, to its [staging](https://app.kosli.com/cyber-dojo/environments/aws-beta/snapshots/) AWS environment.
- Deployment to its [production](https://app.kosli.com/cyber-dojo/environments/aws-prod/snapshots/) AWS environment is via a separate [promotion workflow](https://github.com/cyber-dojo/aws-prod-co-promotion).
- Uses attestation patterns from https://www.kosli.com/blog/using-kosli-attest-in-github-action-workflows-some-tips/

![Screenshot](https://github.com/cyber-dojo/languages-start-points/blob/main/docs/screen_shot.png)

***

A languages-start-points image provides an API for the language+test+frameworks
you choose from when setting up a practice session in cyber-dojo.
For example, in the image above, `Python 3.14.3, pytest 9.0.2` is selected.

The source for the Python,pytest start point is in the GitHub repo
[cyber-dojo-languages/python-pytest](https://github.com/cyber-dojo-languages/python-pytest)

The following cyber-dojo [CLI](https://github.com/cyber-dojo/commander/blob/master/cyber-dojo) command creates a languages-start-points image called `only-python-pytest` that serves only this start-point, at commit `921f17a`:
 
```bash
   $ cyber-dojo start-point create only-python-pytest \
       --languages \
         921f17a@https://github.com/cyber-dojo-start-points/python-pytest
   ...
   Successfully created only-python-pytest
```

The `--languages` flag can be repeated. For example, the following command creates a
languages-start-points image called `ruby-ruby-ruby` serving start-points for three Ruby test-frameworks:

```bash
   $ cyber-dojo start-point create ruby-ruby-ruby \
        --languages \
          e889c83@https://github.com/cyber-dojo-start-points/ruby-approval \
          c1b2910@https://github.com/cyber-dojo-start-points/ruby-cucumber \
          6b72590@https://github.com/cyber-dojo-start-points/ruby-minitest
   ...
   Successfully created ruby-ruby-ruby
```

The next example creates a languages-start-points image called `csharp-nunit-dev` from a local clone of 
[https://github.com/cyber-dojo-start-points/csharp-nunit](https://github.com/cyber-dojo-start-points/csharp-nunit):

```bash
   $ cyber-dojo start-point create csharp-nunit-dev \
      --languages \
        5ac141d@file:///Users/jonjagger/repos/cyber-dojo-start-points/csharp-nunit
   ...
   Successfully created create csharp-nunit-dev
```

To bring up a cyber-dojo server (http://localhost:80) using this image:

```bash
   $ cyber-dojo up --languages=csharp-nunit-dev
   ...
```

[https://cyber-dojo.org](https://cyber-dojo.org) serves a _lot_ of languages-start-points. Their git-repo-urls are in this repo's
[git_repo_urls.tagged](git_repo_urls.tagged) file:

```bash
   $ cat git_repo_urls.tagged
   62d4547@https://github.com/cyber-dojo-start-points/bash-bats
   ededcb8@https://github.com/cyber-dojo-start-points/bash-shunit2
   6011b21@https://github.com/cyber-dojo-start-points/bash-unit
   ...
   9b73fe9@https://github.com/cyber-dojo-start-points/php-unit
   640e4df@https://github.com/cyber-dojo-start-points/prolog-plunit
   ee92da2@https://github.com/cyber-dojo-start-points/python-approval-pytest
   ...
```

```bash
  $ cyber-dojo start-point create cyberdojo/languages-start-points \
      --languages \
        $(cat git_repo_urls.tagged)

  Successfully created cyberdojo/languages-start-points
```

The script `bin/concat_all_start_points.sh` creates the file
The `git_repo_urls.tagged` by reading all `data/*/git_repo.url` files.

***

Main workflow

- Add any new start-points to the ALL_START_POINTS array in [bin/all_start_points.sh](bin/all_start_points.sh)
- Run `make all_start_points` to create an up-to-date version of [git_repo_urls.tagged](git_repo_urls.tagged) which lists all the [cyber-dojo-start-points](https://github.com/cyber-dojo-start-points) repositories (each start-point repo contributes one `manifest.json` to the image).
- You can also update `git_repo_urls.tagged` via the [.github/workflows/refresh.yml](.github/workflows/refresh.yml) workflow.
  - This creates a branch that you can then merge into main.
- If you only have one start-point to update:
  - Run `./bin/update_one_start_point.sh [NAME]`
  - This updates file `data/[NAME]/git_repo.url` 
  - Then run `make concat_all_start_points`
- Run the `make image` to build the image from `git_repo_urls.tagged` for local development/testing.
- Create a branch, add, commit, push.

***

![cyber-dojo.org home page](https://github.com/cyber-dojo/cyber-dojo/blob/master/shared/home_page_snapshot.png)

